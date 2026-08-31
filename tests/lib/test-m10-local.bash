#!/usr/bin/env bash
# Real-path M10 reliability coverage for the local lifecycle suite.

function _m10_local_snapshot {
    local unit="$1"
    local pid=""
    local stat_line=""
    local stat_tail=""
    local -a stat_fields=()

    pid=$(systemctl --user show "${unit}" --property=MainPID --value 2>/dev/null || true)
    [[ "${pid}" =~ ^[1-9][0-9]*$ && -r "/proc/${pid}/stat" ]] || return 1
    stat_line=$(<"/proc/${pid}/stat")
    stat_tail="${stat_line##*) }"
    read -r -a stat_fields <<< "${stat_tail}"
    [[ ${#stat_fields[@]} -ge 20 && "${stat_fields[19]}" =~ ^[0-9]+$ ]] || return 1
    printf '%s:%s' "${pid}" "${stat_fields[19]}"
}

function _m10_wait_for_output {
    local output_file="$1"
    local pattern="$2"
    local attempt=0

    while (( attempt < 5000 )); do
        if grep -Fq -- "${pattern}" "${output_file}" 2>/dev/null; then
            return 0
        fi
        if [[ "${M10_INSPECT_PID}" =~ ^[1-9][0-9]*$ ]] &&
           ! kill -0 "${M10_INSPECT_PID}" 2>/dev/null; then
            return 1
        fi
        sleep 0.001
        attempt=$((attempt + 1))
    done
    return 1
}

function _m10_wait_for_snapshot_change {
    local unit="$1"
    local original="$2"
    local result_name="$3"
    local current=""
    local attempt=0

    while (( attempt < 100 )); do
        current=$(_m10_local_snapshot "${unit}" 2>/dev/null || true)
        if [[ -n "${current}" && "${current}" != "${original}" ]]; then
            printf -v "${result_name}" '%s' "${current}"
            return 0
        fi
        sleep 0.1
        attempt=$((attempt + 1))
    done
    return 1
}

function _m10_fill_local_filesystem {
    local fixture="$1"

    rm -f -- "${fixture}/m10-fill"
    dd if=/dev/zero of="${fixture}/m10-fill" bs=1M status=none 2>/dev/null || true
    sync -f "${fixture}/m10-fill" 2>/dev/null || true
}

function test_m10_reliability {
    local step="$1"
    local fixture="${IOC_RUNNER_M10_LOG_FIXTURE:-}"
    local log_dir="${fixture}/logs"
    local ioc_dir="${WORKSPACE}/m10-local-ioc"
    local conf_file="${WORKSPACE}/${M10_IOC_NAME}.conf"
    local procserv_source=""
    local procserv_copy="${WORKSPACE}/m10-procServ"
    local procserv_stage="${WORKSPACE}/m10-procServ.next"
    local unit="epics-@${M10_IOC_NAME}.service"
    local dropin_file=""
    local saved_dropin_dir=""
    local output_file="${WORKSPACE}/m10-inspect.out"
    local output=""
    local before=""
    local after=""
    local race_snapshot=""
    local rc=0
    local state=""
    local result="false"

    print_divider
    _log "INFO" "STEP ${step}: M10 Log-Path and Executable-Identity Reliability"
    print_sub_divider

    if [[ "${fixture}" == /* && -d "${fixture}" && -w "${fixture}" ]] &&
       [[ $(findmnt -n -o FSTYPE --target "${fixture}" 2>/dev/null || true) == "tmpfs" ]]; then
        result="true"
    fi
    verify_state "true" "${result}" "The gate supplied a writable tmpfs fixture"
    if [[ "${result}" != "true" ]]; then
        close_current_remaining SKIP "requires ${SUITE_ID}.S37.tmpfs-fixture-ready"
        return 0
    fi

    procserv_source=$(command -v procServ 2>/dev/null || true)
    result="false"
    if [[ -x "${procserv_source}" ]] && cp -- "${procserv_source}" "${procserv_copy}" &&
       chmod 0755 "${procserv_copy}"; then
        result="true"
    fi
    verify_state "true" "${result}" "An isolated executable procServ copy is ready"
    if [[ "${result}" != "true" ]]; then
        close_current_remaining SKIP "requires ${SUITE_ID}.S37.procserv-copy-ready"
        return 0
    fi

    mkdir -p "${ioc_dir}" "${log_dir}"
    cat > "${ioc_dir}/st.cmd" <<'EOF'
#!/usr/bin/env bash
printf 'All initialization complete\n'
while :; do
    sleep 60
done
EOF
    chmod 0755 "${ioc_dir}/st.cmd"
    cat > "${conf_file}" <<EOF
IOC_NAME="${M10_IOC_NAME}"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${ioc_dir}"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF

    rc=0
    bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}" >/dev/null 2>&1 || rc=$?
    M10_DROPIN_DIR="${SYSTEMD_USER_DIR}/${unit}.d"
    saved_dropin_dir="${M10_DROPIN_DIR}"
    dropin_file="${M10_DROPIN_DIR}/90-m10-reliability.conf"
    mkdir -p "${M10_DROPIN_DIR}"
    cat > "${dropin_file}" <<EOF
[Service]
ExecStart=
ExecStart=${procserv_copy} --foreground --logfile=${log_dir}/%i.log --name=%i --ignore=^D^C^] --autorestartcmd='' --chdir=\${IOC_CHDIR} --port=\${IOC_PORT} \${IOC_CMD}
EOF
    systemctl --user daemon-reload
    # shellcheck disable=SC2034  # Read by the parent suite's EXIT handler.
    M10_CLEANUP_REQUIRED=1
    result="false"
    if (( rc == 0 )) && [[ -f "${CONF_DIR}/${M10_IOC_NAME}.conf" ]]; then
        result="true"
    fi
    verify_state "true" "${result}" "The dedicated reliability IOC is installed"

    _m10_fill_local_filesystem "${fixture}"
    rc=0
    output=$(bash "${RUNNER_SCRIPT}" --local start "${M10_IOC_NAME}" 2>&1) || rc=$?
    result="false"
    if (( rc != 0 )) && [[ "${output}" == *"log-path probe failed"* ]]; then result="true"; fi
    verify_state "true" "${result}" "A full filesystem blocks start before systemd"
    state=$(systemctl --user is-active "${unit}" 2>/dev/null || true)
    verify_state "inactive" "${state}" "The blocked start leaves the unit inactive"

    rm -f -- "${fixture}/m10-fill"
    rc=0
    bash "${RUNNER_SCRIPT}" --local start "${M10_IOC_NAME}" >/dev/null 2>&1 || rc=$?
    before=$(_m10_local_snapshot "${unit}" 2>/dev/null || true)
    result="false"
    if (( rc == 0 )) && [[ -n "${before}" ]]; then result="true"; fi
    verify_state "true" "${result}" "Restored capacity permits a real active start"

    _m10_fill_local_filesystem "${fixture}"
    rc=0
    output=$(bash "${RUNNER_SCRIPT}" --local restart "${M10_IOC_NAME}" 2>&1) || rc=$?
    result="false"
    if (( rc != 0 )) && [[ "${output}" == *"log-path probe failed"* ]]; then result="true"; fi
    verify_state "true" "${result}" "A full filesystem blocks restart before systemd"
    after=$(_m10_local_snapshot "${unit}" 2>/dev/null || true)
    verify_state "${before}" "${after}" "The blocked restart preserves MainPID:starttime"

    rc=0
    output=$(bash "${RUNNER_SCRIPT}" --local inspect "${M10_IOC_NAME}" 2>&1) || rc=$?
    result="false"
    if (( rc == 0 )) && [[ "${output}" == *"inspect continued: log-path probe failed"* ]]; then
        result="true"
    fi
    verify_state "true" "${result}" "Inspect warns and succeeds on a full filesystem"
    after=$(_m10_local_snapshot "${unit}" 2>/dev/null || true)
    verify_state "${before}" "${after}" "The warning-only inspect preserves MainPID:starttime"
    result="true"
    if find "${log_dir}" -maxdepth 1 -name '.ioc-runner-probe.*' -print -quit | grep -q .; then
        result="false"
    fi
    verify_state "true" "${result}" "A failed log-path probe leaves no temporary file"

    rm -f -- "${fixture}/m10-fill"
    rc=0
    bash "${RUNNER_SCRIPT}" --local restart "${M10_IOC_NAME}" >/dev/null 2>&1 || rc=$?
    after=$(_m10_local_snapshot "${unit}" 2>/dev/null || true)
    result="false"
    if (( rc == 0 )) && [[ -n "${after}" && "${after}" != "${before}" ]]; then result="true"; fi
    verify_state "true" "${result}" "Restored capacity permits restart with a new MainPID:starttime"
    before="${after}"

    rc=0
    output=$(bash "${RUNNER_SCRIPT}" --local inspect "${M10_IOC_NAME}" 2>&1) || rc=$?
    result="false"
    if (( rc == 0 )) && [[ "${output}" == *"Executable identity matches: ${procserv_copy}"* ]]; then
        result="true"
    fi
    verify_state "true" "${result}" "Baseline inspect matches the configured executable identity"
    after=$(_m10_local_snapshot "${unit}" 2>/dev/null || true)
    verify_state "${before}" "${after}" "Baseline inspect preserves MainPID:starttime"

    cp -- "${procserv_source}" "${procserv_stage}"
    chmod 0755 "${procserv_stage}"
    mv -f -- "${procserv_stage}" "${procserv_copy}"
    rc=0
    output=$(bash "${RUNNER_SCRIPT}" --local inspect "${M10_IOC_NAME}" 2>&1) || rc=$?
    result="false"
    if (( rc == 0 )) &&
       [[ "${output}" == *"active procServ executable is deleted"* ||
          "${output}" == *"active procServ executable differs from the configured path"* ]]; then
        result="true"
    fi
    verify_state "true" "${result}" "Executable replacement produces a drift warning"
    after=$(_m10_local_snapshot "${unit}" 2>/dev/null || true)
    verify_state "${before}" "${after}" "Drift inspection preserves MainPID:starttime"

    : > "${output_file}"
    bash "${RUNNER_SCRIPT}" --local inspect "${M10_IOC_NAME}" > "${output_file}" 2>&1 &
    M10_INSPECT_PID=$!
    result="false"
    if _m10_wait_for_output "${output_file}" "Target Socket:" &&
       kill -STOP "${M10_INSPECT_PID}" 2>/dev/null; then
        result="true"
    fi
    verify_state "true" "${result}" "Race inspection reaches the documented synchronization line"
    race_snapshot=""
    rc=0
    if [[ "${result}" == "true" ]]; then
        systemctl --user restart "${unit}"
        _m10_wait_for_snapshot_change "${unit}" "${before}" race_snapshot || true
        kill -CONT "${M10_INSPECT_PID}" 2>/dev/null || true
        wait "${M10_INSPECT_PID}" || rc=$?
        M10_INSPECT_PID=""
    fi
    result="false"
    if (( rc == 0 )) && [[ -n "${race_snapshot}" && "${race_snapshot}" != "${before}" ]]; then
        result="true"
    fi
    verify_state "true" "${result}" "Exactly one restart produces one new MainPID:starttime"
    output=$(<"${output_file}")
    result="false"
    if [[ "${output}" == *"inspection snapshot became unstable"* &&
          "${output}" != *"active procServ executable is deleted"* &&
          "${output}" != *"active procServ executable differs"* ]]; then
        result="true"
    fi
    verify_state "true" "${result}" "A changed snapshot reports unstable rather than drift"

    before=$(_m10_local_snapshot "${unit}" 2>/dev/null || true)
    : > "${output_file}"
    bash "${RUNNER_SCRIPT}" --local inspect "${M10_IOC_NAME}" > "${output_file}" 2>&1 &
    M10_INSPECT_PID=$!
    result="false"
    if _m10_wait_for_output "${output_file}" "Target Socket:" &&
       kill -STOP "${M10_INSPECT_PID}" 2>/dev/null; then
        result="true"
    fi
    verify_state "true" "${result}" "Cleanup probe reaches the synchronization line"
    sleep 1
    _m10_terminate_inspect
    result="true"
    if [[ -n "${M10_INSPECT_PID}" ]]; then result="false"; fi
    verify_state "true" "${result}" "Timeout cleanup resumes, terminates, and reaps inspect"
    after=$(_m10_local_snapshot "${unit}" 2>/dev/null || true)
    verify_state "${before}" "${after}" "Timeout cleanup performs no restart"

    result="false"
    if _cleanup_m10_local && [[ ! -e "${CONF_DIR}/${M10_IOC_NAME}.conf" ]] &&
       [[ ! -e "${saved_dropin_dir}" ]]; then
        result="true"
    fi
    verify_state "true" "${result}" "The M10 local fixture leaves no service or drop-in residue"
}
