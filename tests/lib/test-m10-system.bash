#!/usr/bin/env bash
# Real-path M10 reliability coverage for the system lifecycle suite.

function _m10_system_runner {
    IOC_RUNNER_SYSTEM_USER="${M10_SERVICE_USER}" bash "${RUNNER_SCRIPT}" "$@"
}

function _m10_system_operator_runner {
    runuser -u "${M10_OPERATOR_USER}" -- env \
        IOC_RUNNER_SYSTEM_USER="${M10_SERVICE_USER}" bash "${RUNNER_SCRIPT}" "$@"
}

function _m10_system_start_inspect {
    local output_file="$1"

    IOC_RUNNER_SYSTEM_USER="${M10_SERVICE_USER}" \
        bash "${RUNNER_SCRIPT}" inspect "${M10_SYSTEM_IOC_NAME}" > "${output_file}" 2>&1 &
    M10_SYSTEM_INSPECT_PID=$!
}

function _m10_system_snapshot {
    local unit="$1"
    local pid=""
    local stat_line=""
    local stat_tail=""
    local -a stat_fields=()

    pid=$(systemctl show "${unit}" --property=MainPID --value 2>/dev/null || true)
    [[ "${pid}" =~ ^[1-9][0-9]*$ && -r "/proc/${pid}/stat" ]] || return 1
    stat_line=$(<"/proc/${pid}/stat")
    stat_tail="${stat_line##*) }"
    read -r -a stat_fields <<< "${stat_tail}"
    [[ ${#stat_fields[@]} -ge 20 && "${stat_fields[19]}" =~ ^[0-9]+$ ]] || return 1
    printf '%s:%s' "${pid}" "${stat_fields[19]}"
}

function _m10_system_terminate_inspect {
    local attempt=0

    [[ "${M10_SYSTEM_INSPECT_PID}" =~ ^[1-9][0-9]*$ ]] || return 0
    if kill -0 "${M10_SYSTEM_INSPECT_PID}" 2>/dev/null; then
        kill -CONT "${M10_SYSTEM_INSPECT_PID}" 2>/dev/null || true
        kill -TERM "${M10_SYSTEM_INSPECT_PID}" 2>/dev/null || true
        while (( attempt < 20 )) && kill -0 "${M10_SYSTEM_INSPECT_PID}" 2>/dev/null; do
            sleep 0.1
            attempt=$((attempt + 1))
        done
        kill -KILL "${M10_SYSTEM_INSPECT_PID}" 2>/dev/null || true
    fi
    wait "${M10_SYSTEM_INSPECT_PID}" 2>/dev/null || true
    M10_SYSTEM_INSPECT_PID=""
}

function _cleanup_m10_system {
    local cleanup_rc=0

    _m10_system_terminate_inspect
    if (( M10_SYSTEM_CLEANUP_REQUIRED )); then
        systemctl stop "epics-@${M10_SYSTEM_IOC_NAME}.service" >/dev/null 2>&1 || true
        if [[ -e "${CONF_DIR}/${M10_SYSTEM_IOC_NAME}.conf" ||
              -L "${CONF_DIR}/${M10_SYSTEM_IOC_NAME}.conf" ]]; then
            _m10_system_runner remove "${M10_SYSTEM_IOC_NAME}" >/dev/null 2>&1 || cleanup_rc=1
        fi
        if [[ -n "${M10_SYSTEM_DROPIN_DIR}" ]]; then
            rm -rf -- "${M10_SYSTEM_DROPIN_DIR}" || cleanup_rc=1
        fi
        if [[ -n "${M10_SYSTEM_PROCSERV_COPY}" ]]; then
            rm -f -- "${M10_SYSTEM_PROCSERV_COPY}" \
                "${M10_SYSTEM_PROCSERV_COPY}.next" || cleanup_rc=1
        fi
        systemctl daemon-reload >/dev/null 2>&1 || cleanup_rc=1
        if [[ -n "${M10_SYSTEM_MOUNT_DIR}" ]]; then
            umount -- "${M10_SYSTEM_MOUNT_DIR}" >/dev/null 2>&1 || cleanup_rc=1
            rmdir -- "${M10_SYSTEM_MOUNT_DIR}" >/dev/null 2>&1 || cleanup_rc=1
        fi
    fi
    if (( M10_OPERATOR_USER_CREATED )) && id "${M10_OPERATOR_USER}" >/dev/null 2>&1; then
        userdel "${M10_OPERATOR_USER}" >/dev/null 2>&1 || cleanup_rc=1
    fi
    if (( M10_SERVICE_USER_CREATED )) && id "${M10_SERVICE_USER}" >/dev/null 2>&1; then
        userdel "${M10_SERVICE_USER}" >/dev/null 2>&1 || cleanup_rc=1
    fi
    if (( cleanup_rc == 0 )); then
        M10_SYSTEM_CLEANUP_REQUIRED=0
        M10_OPERATOR_USER_CREATED=0
        M10_SERVICE_USER_CREATED=0
        M10_SYSTEM_DROPIN_DIR=""
        M10_SYSTEM_MOUNT_DIR=""
        M10_SYSTEM_PROCSERV_COPY=""
    fi
    return "${cleanup_rc}"
}

function _m10_system_wait_output {
    local output_file="$1"
    local pattern="$2"
    local attempt=0

    while (( attempt < 5000 )); do
        grep -Fq -- "${pattern}" "${output_file}" 2>/dev/null && return 0
        if [[ "${M10_SYSTEM_INSPECT_PID}" =~ ^[1-9][0-9]*$ ]] &&
           ! kill -0 "${M10_SYSTEM_INSPECT_PID}" 2>/dev/null; then
            return 1
        fi
        sleep 0.001
        attempt=$((attempt + 1))
    done
    return 1
}

function _m10_system_wait_inspect_stopped {
    local pid="$1"
    local key=""
    local state=""
    local attempt=0

    while (( attempt < 100 )); do
        [[ -r "/proc/${pid}/status" ]] || return 1
        state=""
        while read -r key state _; do
            [[ "${key}" == "State:" ]] && break
        done < "/proc/${pid}/status"
        if [[ "${state}" == "T" || "${state}" == "t" ]]; then
            return 0
        fi
        sleep 0.01
        attempt=$((attempt + 1))
    done
    return 1
}

function _m10_system_wait_snapshot_change {
    local unit="$1"
    local original="$2"
    local result_name="$3"
    local current=""
    local attempt=0

    while (( attempt < 100 )); do
        current=$(_m10_system_snapshot "${unit}" 2>/dev/null || true)
        if [[ -n "${current}" && "${current}" != "${original}" ]]; then
            printf -v "${result_name}" '%s' "${current}"
            return 0
        fi
        sleep 0.1
        attempt=$((attempt + 1))
    done
    return 1
}

function _m10_fill_system_filesystem {
    local fixture="$1"

    rm -f -- "${fixture}/m10-fill"
    dd if=/dev/zero of="${fixture}/m10-fill" bs=1M status=none 2>/dev/null || true
    sync -f "${fixture}/m10-fill" 2>/dev/null || true
}

function test_m10_system_reliability {
    local step="$1"
    local fixture=""
    local log_dir=""
    local ioc_dir="${WORKSPACE}/m10-system-ioc"
    local conf_file="${WORKSPACE}/${M10_SYSTEM_IOC_NAME}.conf"
    local procserv_source=""
    local procserv_copy=""
    local procserv_stage=""
    local unit="epics-@${M10_SYSTEM_IOC_NAME}.service"
    local dropin_file=""
    local saved_dropin_dir=""
    local saved_mount_dir=""
    local saved_procserv_copy=""
    local output_file="${WORKSPACE}/m10-system-inspect.out"
    local output=""
    local before=""
    local after=""
    local race_snapshot=""
    local rc=0
    local state=""
    local result="false"

    print_divider
    _log "INFO" "STEP ${step}: M10 System Log-Path and Executable-Identity Reliability"
    print_sub_divider

    if id "${M10_SERVICE_USER}" >/dev/null 2>&1 || id "${M10_OPERATOR_USER}" >/dev/null 2>&1; then
        record_current_state SKIP "dedicated M10 identity name already exists"
        close_current_remaining SKIP "requires ${SUITE_ID}.S34.identity-names-available"
        return 0
    fi
    record_current_state PASS
    useradd -M -N -s /usr/sbin/nologin "${M10_SERVICE_USER}"
    M10_SERVICE_USER_CREATED=1
    useradd -M -N -G "${SYSTEM_GROUP}" -s /bin/bash "${M10_OPERATOR_USER}"
    M10_OPERATOR_USER_CREATED=1
    result="false"
    if [[ $(id -gn "${M10_SERVICE_USER}") != "${SYSTEM_GROUP}" ]]; then result="true"; fi
    verify_state "true" "${result}" "The service passwd primary group differs from the unit Group"

    M10_SYSTEM_MOUNT_DIR=$(mktemp -d /tmp/ioc-runner-m10-system.XXXXXX)
    saved_mount_dir="${M10_SYSTEM_MOUNT_DIR}"
    mount -t tmpfs -o nodev,nosuid,noexec,size=4m tmpfs "${M10_SYSTEM_MOUNT_DIR}"
    fixture="${M10_SYSTEM_MOUNT_DIR}/data"
    log_dir="${fixture}/logs"
    install -d -o root -g "${SYSTEM_GROUP}" -m 2770 "${fixture}" "${log_dir}"
    M10_SYSTEM_CLEANUP_REQUIRED=1
    result="false"
    if [[ $(findmnt -n -o FSTYPE --target "${fixture}" 2>/dev/null || true) == "tmpfs" ]]; then
        result="true"
    fi
    verify_state "true" "${result}" "A size-limited tmpfs fixture is mounted"

    M10_SYSTEM_PROCSERV_COPY="/usr/local/bin/ioc-runner-m10-procServ-${BASHPID}"
    procserv_copy="${M10_SYSTEM_PROCSERV_COPY}"
    procserv_stage="${procserv_copy}.next"
    saved_procserv_copy="${procserv_copy}"
    procserv_source=$(command -v procServ 2>/dev/null || true)
    result="false"
    if [[ -x "${procserv_source}" ]] && cp -- "${procserv_source}" "${procserv_copy}" &&
       chmod 0755 "${procserv_copy}"; then
        result="true"
    fi
    verify_state "true" "${result}" "An isolated executable procServ copy is ready"
    if [[ "${result}" != "true" ]]; then
        close_current_remaining SKIP "requires ${SUITE_ID}.S34.procserv-copy-ready"
        return 0
    fi

    install -d -o root -g "${SYSTEM_GROUP}" -m 2775 "${ioc_dir}"
    cat > "${ioc_dir}/st.cmd" <<'EOF'
#!/usr/bin/env bash
printf 'All initialization complete\n'
while :; do
    sleep 60
done
EOF
    chown root:"${SYSTEM_GROUP}" "${ioc_dir}/st.cmd"
    chmod 0755 "${ioc_dir}/st.cmd"
    cat > "${conf_file}" <<EOF
IOC_NAME="${M10_SYSTEM_IOC_NAME}"
IOC_USER="${M10_SERVICE_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${ioc_dir}"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF
    rc=0
    _m10_system_runner -f install "${conf_file}" >/dev/null 2>&1 || rc=$?
    M10_SYSTEM_DROPIN_DIR="${SYSTEMD_DIR}/${unit}.d"
    saved_dropin_dir="${M10_SYSTEM_DROPIN_DIR}"
    dropin_file="${M10_SYSTEM_DROPIN_DIR}/90-m10-reliability.conf"
    mkdir -p "${M10_SYSTEM_DROPIN_DIR}"
    cat > "${dropin_file}" <<EOF
[Service]
User=${M10_SERVICE_USER}
Group=${SYSTEM_GROUP}
ExecStart=
ExecStart=${procserv_copy} --foreground --logfile=${log_dir}/%i.log --name=%i --ignore=^D^C^] --autorestartcmd='' --chdir=\${IOC_CHDIR} --port=\${IOC_PORT} \${IOC_CMD}
EOF
    systemctl daemon-reload
    result="false"
    if (( rc == 0 )) && [[ -f "${CONF_DIR}/${M10_SYSTEM_IOC_NAME}.conf" ]]; then result="true"; fi
    verify_state "true" "${result}" "The dedicated system reliability IOC is installed"

    _m10_fill_system_filesystem "${fixture}"
    rc=0
    output=$(_m10_system_operator_runner start "${M10_SYSTEM_IOC_NAME}" 2>&1) || rc=$?
    result="false"
    if (( rc != 0 )) && [[ "${output}" == *"log-path probe failed"* ]]; then result="true"; fi
    verify_state "true" "${result}" "An ordinary operator is blocked before a full-filesystem start"
    state=$(systemctl is-active "${unit}" 2>/dev/null || true)
    verify_state "inactive" "${state}" "The blocked system start leaves the unit inactive"

    rm -f -- "${fixture}/m10-fill"
    rc=0
    _m10_system_operator_runner start "${M10_SYSTEM_IOC_NAME}" >/dev/null 2>&1 || rc=$?
    before=$(_m10_system_snapshot "${unit}" 2>/dev/null || true)
    result="false"; if (( rc == 0 )) && [[ -n "${before}" ]]; then result="true"; fi
    verify_state "true" "${result}" "Restored capacity permits an operator start"

    _m10_fill_system_filesystem "${fixture}"
    rc=0
    output=$(_m10_system_operator_runner restart "${M10_SYSTEM_IOC_NAME}" 2>&1) || rc=$?
    result="false"; if (( rc != 0 )) && [[ "${output}" == *"log-path probe failed"* ]]; then result="true"; fi
    verify_state "true" "${result}" "An ordinary operator is blocked before a full-filesystem restart"
    after=$(_m10_system_snapshot "${unit}" 2>/dev/null || true)
    verify_state "${before}" "${after}" "The blocked system restart preserves MainPID:starttime"

    rc=0
    output=$(_m10_system_runner inspect "${M10_SYSTEM_IOC_NAME}" 2>&1) || rc=$?
    result="false"
    if (( rc == 0 )) && [[ "${output}" == *"inspect continued: log-path probe failed"* ]]; then result="true"; fi
    verify_state "true" "${result}" "Root inspect warns and succeeds on a full filesystem"
    after=$(_m10_system_snapshot "${unit}" 2>/dev/null || true)
    verify_state "${before}" "${after}" "The warning-only system inspect preserves MainPID:starttime"
    result="true"
    if find "${log_dir}" -maxdepth 1 -name '.ioc-runner-probe.*' -print -quit | grep -q .; then result="false"; fi
    verify_state "true" "${result}" "A failed service-identity probe leaves no temporary file"

    rm -f -- "${fixture}/m10-fill"
    rc=0
    _m10_system_operator_runner restart "${M10_SYSTEM_IOC_NAME}" >/dev/null 2>&1 || rc=$?
    after=$(_m10_system_snapshot "${unit}" 2>/dev/null || true)
    result="false"; if (( rc == 0 )) && [[ -n "${after}" && "${after}" != "${before}" ]]; then result="true"; fi
    verify_state "true" "${result}" "Restored capacity permits operator restart with a new MainPID:starttime"
    before="${after}"

    rc=0
    output=$(_m10_system_runner inspect "${M10_SYSTEM_IOC_NAME}" 2>&1) || rc=$?
    result="false"
    if (( rc == 0 )) && [[ "${output}" == *"Executable identity matches: ${procserv_copy}"* ]] &&
       [[ "${output}" != *"log-path probe failed"* ]]; then result="true"; fi
    verify_state "true" "${result}" "Inspect uses effective User and Group and matches the executable"
    after=$(_m10_system_snapshot "${unit}" 2>/dev/null || true)
    verify_state "${before}" "${after}" "Baseline system inspect preserves MainPID:starttime"

    cp -- "${procserv_source}" "${procserv_stage}"
    chmod 0755 "${procserv_stage}"
    mv -f -- "${procserv_stage}" "${procserv_copy}"
    rc=0
    output=$(_m10_system_runner inspect "${M10_SYSTEM_IOC_NAME}" 2>&1) || rc=$?
    result="false"
    if (( rc == 0 )) && [[ "${output}" == *"active procServ executable is deleted"* ||
       "${output}" == *"active procServ executable differs from the configured path"* ]]; then result="true"; fi
    verify_state "true" "${result}" "Executable replacement produces a system drift warning"
    after=$(_m10_system_snapshot "${unit}" 2>/dev/null || true)
    verify_state "${before}" "${after}" "System drift inspection preserves MainPID:starttime"

    : > "${output_file}"
    _m10_system_start_inspect "${output_file}"
    result="false"
    if _m10_system_wait_output "${output_file}" "Target Socket:" &&
       kill -STOP "${M10_SYSTEM_INSPECT_PID}" 2>/dev/null &&
       _m10_system_wait_inspect_stopped "${M10_SYSTEM_INSPECT_PID}"; then
        result="true"
    fi
    verify_state "true" "${result}" "System race inspection reaches the synchronization line"
    race_snapshot=""; rc=0
    if [[ "${result}" == "true" ]]; then
        systemctl restart "${unit}"
        _m10_system_wait_snapshot_change "${unit}" "${before}" race_snapshot || true
        kill -CONT "${M10_SYSTEM_INSPECT_PID}" 2>/dev/null || true
        wait "${M10_SYSTEM_INSPECT_PID}" || rc=$?
        M10_SYSTEM_INSPECT_PID=""
    fi
    result="false"
    if (( rc == 0 )) && [[ -n "${race_snapshot}" && "${race_snapshot}" != "${before}" ]]; then result="true"; fi
    verify_state "true" "${result}" "Exactly one system restart produces one new MainPID:starttime"
    output=$(<"${output_file}")
    result="false"
    if [[ "${output}" == *"inspection snapshot became unstable"* &&
          "${output}" != *"active procServ executable is deleted"* &&
          "${output}" != *"active procServ executable differs"* ]]; then result="true"; fi
    verify_state "true" "${result}" "The system race reports unstable rather than drift"

    before=$(_m10_system_snapshot "${unit}" 2>/dev/null || true)
    : > "${output_file}"
    _m10_system_start_inspect "${output_file}"
    result="false"
    if _m10_system_wait_output "${output_file}" "Target Socket:" &&
       kill -STOP "${M10_SYSTEM_INSPECT_PID}" 2>/dev/null &&
       _m10_system_wait_inspect_stopped "${M10_SYSTEM_INSPECT_PID}"; then
        result="true"
    fi
    verify_state "true" "${result}" "System cleanup probe reaches the synchronization line"
    sleep 1
    _m10_system_terminate_inspect
    result="true"; [[ -n "${M10_SYSTEM_INSPECT_PID}" ]] && result="false"
    verify_state "true" "${result}" "System timeout cleanup resumes, terminates, and reaps inspect"
    after=$(_m10_system_snapshot "${unit}" 2>/dev/null || true)
    verify_state "${before}" "${after}" "System timeout cleanup performs no restart"

    result="false"
    if _cleanup_m10_system && [[ ! -e "${CONF_DIR}/${M10_SYSTEM_IOC_NAME}.conf" ]] &&
       [[ ! -e "${saved_dropin_dir}" && ! -e "${saved_mount_dir}" ]] &&
       [[ ! -e "${saved_procserv_copy}" && ! -e "${saved_procserv_copy}.next" ]]; then result="true"; fi
    verify_state "true" "${result}" \
        "The system M10 fixture leaves no service, executable, mount, drop-in, or identity residue"
}
