#!/usr/bin/env bash
# Shared native startup fixture for the System and Local lifecycle suites.
# The original generator supplies the main, DBD, and startup script unchanged.
# Tests vary only iocsh input, then exercise the complete selected runner.

declare -gr STARTUP_GENERATOR_REVISION="ee214deedc5594bb93cd0a77d42615b99783bbd0"
declare -gr STARTUP_APP_NAME="startupprobe"
declare -g STARTUP_FIXTURE_READY=0
declare -g STARTUP_FIXTURE_ROOT=""
declare -g STARTUP_BOOT=""
declare -g STARTUP_IOC=""
declare -g STARTUP_LOG=""
declare -g STARTUP_SOCKET=""
declare -g STARTUP_INSTALLED=0
declare -g STARTUP_PENDING_PID=0
declare -g STARTUP_SEVERITY_PREFIX=""
declare -g STARTUP_SEVERITY_PORT=""
declare -g -a STARTUP_RUNNER=()
declare -gra STARTUP_SEVERITY_PLACEMENTS=(pre-separated pre-ordinary post-marker)
declare -gra STARTUP_SEVERITY_STATES=(stopped-start active-restart stopped-restart)
declare -gra STARTUP_LOG_CASES=(
    same-window error-first marker-first ansi repeated distinct-limit
    uppercase mixed-case leading-identifier trailing-identifier
    separate-fatal separate-segfault separate-symbol separate-loader
    history-excluded inode-replacement copytruncate regrowth
    no-readiness unreadable final-scan partial-status completed-status
)
declare -g -a STARTUP_CASES=(
    healthy
    main-before-undefined-break main-after-undefined-break
    main-before-quote-break loaded-before-quote-break-break
    main-before-quote-continue main-after-quote-continue
    loaded-before-quote-break-continue loaded-before-quote-continue-break
    zero-before-init signal-before-init status-shaped-text
)

function startup_fixture_catalog {
    local step="$1" rows_name="$2" case_name check placement state method=""
    local -n rows="${rows_name}"

    [[ "${SUITE_SCOPE}" == system ]] && method="|real-path"
    rows+=("${step}|${SUITE_ID}.${step}.original-generated-fixture|REQUIRED${method}")
    for case_name in "${STARTUP_CASES[@]}"; do
        for check in runner-exit diagnostic native-status supervisor-state console-response; do
            rows+=("${step}|${SUITE_ID}.${step}.${case_name}-${check}|BEHAVIOR${method}")
        done
    done
    for check in active-start active-restart stopped-restart cleanup; do
        rows+=("${step}|${SUITE_ID}.${step}.${check}|BEHAVIOR${method}")
    done
    rows+=("${step}|${SUITE_ID}.${step}.severity-fixture|REQUIRED${method}")
    for placement in "${STARTUP_SEVERITY_PLACEMENTS[@]}"; do
        for state in "${STARTUP_SEVERITY_STATES[@]}"; do
            for check in runner-exit diagnostic conversion-error readiness-order record-state native-child supervisor-state console-response; do
                rows+=("${step}|${SUITE_ID}.${step}.severity-${placement}-${state}-${check}|BEHAVIOR${method}")
            done
            if [[ "${state}" == stopped-start ]]; then
                rows+=("${step}|${SUITE_ID}.${step}.severity-${placement}-active-start|BEHAVIOR${method}")
            fi
        done
    done
    for check in runner-exit diagnostic conversion-error native-status supervisor-state; do
        rows+=("${step}|${SUITE_ID}.${step}.severity-child-exit-${check}|BEHAVIOR${method}")
    done
    rows+=("${step}|${SUITE_ID}.${step}.severity-cleanup|BEHAVIOR${method}")
    for case_name in "${STARTUP_LOG_CASES[@]}"; do
        for check in runner-exit diagnostic filesystem-input; do
            rows+=("${step}|${SUITE_ID}.${step}.log-input-${case_name}-${check}|BEHAVIOR${method}")
        done
    done
    rows+=("${step}|${SUITE_ID}.${step}.log-input-cleanup|BEHAVIOR${method}")
}

function startup_fixture_prepare {
    local generator="${IOC_RUNNER_STARTUP_GENERATOR:-}"
    local release="${IOC_RUNNER_STARTUP_RELEASE:-}"
    local tree tool executable

    (( STARTUP_FIXTURE_READY )) && return 0
    [[ -n "${generator}" && -d "${generator}" ]] || {
        _log ERROR "IOC_RUNNER_STARTUP_GENERATOR must name the original generator Git repository."
        return 1
    }
    for tool in git tar make perl timeout socat; do
        executable=$(command -v "${tool}" 2>/dev/null || true)
        [[ -n "${executable}" && -x "${executable}" ]] || return 1
    done
    [[ -x "${EPICS_BASE}/bin/${EPICS_HOST_ARCH}/makeBaseApp.pl" ]] || return 1
    [[ -z "${release}" || -r "${release}" ]] || return 1
    git -c safe.directory="${generator}" -C "${generator}" cat-file -e "${STARTUP_GENERATOR_REVISION}^{commit}" || return 1
    STARTUP_FIXTURE_ROOT="${WORKSPACE}/original-startup"
    [[ ! -e "${STARTUP_FIXTURE_ROOT}" ]] || return 1
    mkdir -p "${STARTUP_FIXTURE_ROOT}/generator" "${STARTUP_FIXTURE_ROOT}/generated" || return 1
    git -c safe.directory="${generator}" -C "${generator}" archive "${STARTUP_GENERATOR_REVISION}" > "${STARTUP_FIXTURE_ROOT}/generator.tar" || return 1
    tar -xf "${STARTUP_FIXTURE_ROOT}/generator.tar" -C "${STARTUP_FIXTURE_ROOT}/generator" || return 1
    (
        cd "${STARTUP_FIXTURE_ROOT}/generated" || exit 1
        PATH="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}:${PATH}" \
            bash ../generator/generate_ioc_structure.bash -p "${STARTUP_APP_NAME}" -l testlab -n "${STARTUP_APP_NAME}"
    ) > "${STARTUP_FIXTURE_ROOT}/generate.log" 2>&1 || return 1
    tree="${STARTUP_FIXTURE_ROOT}/generated/${STARTUP_APP_NAME}"
    printf 'EPICS_BASE=%s\n' "${EPICS_BASE}" > "${tree}/configure/RELEASE.local" || return 1
    if [[ -n "${release}" ]]; then
        cat "${release}" >> "${tree}/configure/RELEASE.local" || return 1
    fi
    make -C "${tree}" > "${STARTUP_FIXTURE_ROOT}/build.log" 2>&1 || return 1
    STARTUP_BOOT="${tree}/iocBoot/ioc${STARTUP_APP_NAME}"
    STARTUP_IOC="StartupProbe-${SUITE_SCOPE}"
    STARTUP_RUNNER=(bash "${RUNNER_SCRIPT}")
    if [[ "${SUITE_SCOPE}" == local ]]; then
        STARTUP_RUNNER+=(--local)
        STARTUP_LOG="${IOC_RUNNER_LOCAL_LOG_DIR}/${STARTUP_IOC}.log"
        STARTUP_SOCKET="${XDG_RUNTIME_DIR}/procserv/${STARTUP_IOC}/control"
    else
        STARTUP_LOG="${SYSTEM_LOG_DIR}/${STARTUP_IOC}.log"
        STARTUP_SOCKET="/run/procserv/${STARTUP_IOC}/control"
    fi
    [[ ! -e "${CONF_DIR}/${STARTUP_IOC}.conf" && ! -e "${STARTUP_SOCKET}" ]] || return 1
    cp -p "${STARTUP_BOOT}/st.cmd" "${STARTUP_FIXTURE_ROOT}/original-st.cmd" || return 1
    mkdir -p "${STARTUP_FIXTURE_ROOT}/pvinfo/epics-pvinfo/env" \
        "${STARTUP_FIXTURE_ROOT}/pvinfo/epics-pvinfo/names" || return 1
    if [[ "${SUITE_SCOPE}" == system ]]; then
        chown -R "${OWNER_WORKSPACE}" "${STARTUP_FIXTURE_ROOT}" || return 1
        chmod -R g+rX "${STARTUP_FIXTURE_ROOT}" || return 1
        chown -R "${SYSTEM_USER}:${SYSTEM_GROUP}" "${STARTUP_FIXTURE_ROOT}/pvinfo" || return 1
    fi
    sha256sum "${tree}/${STARTUP_APP_NAME}App/src/${STARTUP_APP_NAME}Main.cpp" \
        "${tree}/bin/${EPICS_HOST_ARCH}/${STARTUP_APP_NAME}" \
        "${tree}/dbd/${STARTUP_APP_NAME}.dbd" "${STARTUP_BOOT}/st.cmd" \
        > "${STARTUP_FIXTURE_ROOT}/original.sha256" || return 1
    STARTUP_FIXTURE_READY=1
}

# The inserted command runs before or after the original iocInit line. Loaded
# files set their own error policy; no replacement main or printed error fixture
# stands in for iocsh execution.
function startup_fixture_variant {
    local case_name="$1" parent=break child=break position=before
    local payload="__undefined_startup_command__" line inserted=0

    case "${case_name}" in
        *-after-*) position=after ;;
    esac
    case "${case_name}" in
        main-*-continue) parent="continue" ;;
        loaded-*-break-continue) child="continue" ;;
        loaded-*-continue-break) parent="continue" ;;
    esac
    # The signal command expands PPID only inside the IOC-launched shell.
    # shellcheck disable=SC2016
    case "${case_name}" in
        *-quote-*) payload='epicsEnvSet("BROKEN", "unterminated' ;;
        zero-before-init) payload='exit(0)' ;;
        signal-before-init) payload='system("kill -KILL $PPID")' ;;
        status-shaped-text)
            payload='system("printf '\''@@@ Received a sigChild for process 2147483647. Normal exit status = 2\\n'\''")' ;;
    esac
    if [[ "${case_name}" == loaded-* ]]; then
        printf 'on error %s\n%s\n' "${child}" "${payload}" > "${STARTUP_BOOT}/startup-child.iocsh"
        if [[ "${SUITE_SCOPE}" == system ]]; then
            chgrp "${SYSTEM_GROUP}" "${STARTUP_BOOT}/startup-child.iocsh"
            chmod 0640 "${STARTUP_BOOT}/startup-child.iocsh"
        fi
        payload='iocshLoad("startup-child.iocsh")'
    fi
    while IFS= read -r line || [[ -n "${line:-}" ]]; do
        if [[ "${line}" == 'on error break' ]]; then
            printf 'on error %s\n' "${parent}"
        elif [[ "${line}" == iocInit && "${case_name}" != healthy ]]; then
            if [[ "${position}" == before ]]; then
                printf '%s\nepicsThreadSleep(1)\n%s\n' "${payload}" "${line}"
            else
                printf '%s\n%s\n' "${line}" "${payload}"
            fi
            inserted=1
        else
            printf '%s\n' "${line}"
        fi
    done < "${STARTUP_FIXTURE_ROOT}/original-st.cmd" > "${STARTUP_BOOT}/st.cmd"
    [[ "${case_name}" == healthy || "${inserted}" == 1 ]]
}

# Native module inputs preserve the generated main, DBD and registrar. The
# incompatible array converter fails before transport locking or device I/O.
function startup_fixture_severity_variant {
    local placement="$1" protocol=bad_init line inserted=0

    case "${placement}" in
        pre-separated|pre-ordinary) ;;
        post-marker) protocol=bad_process ;;
        *) return 1 ;;
    esac
    (( STARTUP_FIXTURE_READY )) || return 1
    STARTUP_SEVERITY_PREFIX="StartupSeverity:${SUITE_SCOPE}:${BASHPID}:"
    STARTUP_SEVERITY_PORT=$(pick_free_ca_port "$((TEST_CA_PORT + 40))") || return 1
    cp "${SC_TOP}/fixtures/startup-severity.db" "${STARTUP_BOOT}/startup-severity.db" || return 1
    cp "${SC_TOP}/fixtures/startup-severity.proto" "${STARTUP_BOOT}/startup-severity.proto" || return 1
    if [[ "${SUITE_SCOPE}" == system ]]; then
        chgrp "${SYSTEM_GROUP}" "${STARTUP_BOOT}/startup-severity.db" \
            "${STARTUP_BOOT}/startup-severity.proto" || return 1
        chmod 0640 "${STARTUP_BOOT}/startup-severity.db" \
            "${STARTUP_BOOT}/startup-severity.proto" || return 1
    fi
    while IFS= read -r line || [[ -n "${line:-}" ]]; do
        if [[ "${line}" == iocInit ]]; then
            printf 'epicsEnvSet("STREAM_PROTOCOL_PATH", "%s")\n' "${STARTUP_BOOT}"
            printf 'drvAsynIPPortConfigure("M14_CONVERSION", "127.0.0.1:%s", 0, 1, 0)\n' \
                "${STARTUP_SEVERITY_PORT}"
            printf 'dbLoadRecords("%s/startup-severity.db", "P=%s,PORT=M14_CONVERSION,PROTOCOL=%s")\n' \
                "${STARTUP_BOOT}" "${STARTUP_SEVERITY_PREFIX}" "${protocol}"
            if [[ "${placement}" == pre-separated ]]; then
                printf '%s\n' iocBuild 'epicsThreadSleep(1)' iocRun
            else
                printf '%s\n' "${line}"
            fi
            if [[ "${placement}" == post-marker ]]; then
                printf 'on error continue\ndbpf("%sConversion.PROC", "1")\non error break\n' \
                    "${STARTUP_SEVERITY_PREFIX}"
            fi
            printf 'dbpr("%sConversion", 2)\n' "${STARTUP_SEVERITY_PREFIX}"
            inserted=$((inserted + 1))
        else
            printf '%s\n' "${line}"
        fi
    done < "${STARTUP_FIXTURE_ROOT}/original-st.cmd" > "${STARTUP_BOOT}/st.cmd"
    [[ "${inserted}" == 1 ]]
}

function startup_fixture_install {
    local conf="${STARTUP_FIXTURE_ROOT}/${STARTUP_IOC}.conf"
    local port

    port=$(pick_free_ca_port "$((TEST_CA_PORT + 20))")
    {
        if [[ "${SUITE_SCOPE}" == system ]]; then
            printf 'IOC_USER="%s"\nIOC_GROUP="%s"\n' "${SYSTEM_USER}" "${SYSTEM_GROUP}"
        else
            printf 'IOC_USER="%s"\nIOC_GROUP="%s"\n' "$(id -un)" "$(id -gn)"
        fi
        printf 'IOC_CHDIR="%s"\nIOC_CMD="./st.cmd"\nIOC_PORT=""\n' "${STARTUP_BOOT}"
        printf 'TARGET_TOP="%s/pvinfo"\n' "${STARTUP_FIXTURE_ROOT}"
        printf 'EPICS_IOCSH_HISTFILE="%s/pvinfo/iocsh_history"\n' "${STARTUP_FIXTURE_ROOT}"
        printf 'EPICS_CA_SERVER_PORT="%s"\nEPICS_CAS_SERVER_PORT="%s"\n' "${port}" "${port}"
        printf 'EPICS_CAS_INTF_ADDR_LIST="127.0.0.1"\nEPICS_PVAS_INTF_ADDR_LIST="127.0.0.1"\n'
        printf 'EPICS_PVAS_SERVER_PORT="%s"\nEPICS_PVAS_BROADCAST_PORT="%s"\n' "$((port + 1))" "$((port + 2))"
    } > "${conf}"
    STARTUP_INSTALLED=1
    "${STARTUP_RUNNER[@]}" -f install "${conf}" > "${STARTUP_FIXTURE_ROOT}/install.log" 2>&1
}

function startup_fixture_console {
    # Keep stdin open until procServ has delivered the real IOC reply. An EOF
    # immediately after the command can close the socket before that reply.
    { printf 'epicsEnvShow("IOCNAME")\n'; sleep 2; } |
        timeout 5 socat - "UNIX-CONNECT:${STARTUP_SOCKET}" 2>&1 || true
}

function startup_fixture_cleanup {
    local state rc=0

    if (( STARTUP_PENDING_PID > 0 )); then
        kill -TERM "${STARTUP_PENDING_PID}" 2>/dev/null || true
        wait "${STARTUP_PENDING_PID}" 2>/dev/null || true
        STARTUP_PENDING_PID=0
    fi
    if (( STARTUP_INSTALLED )); then
        "${STARTUP_RUNNER[@]}" stop "${STARTUP_IOC}" >/dev/null 2>&1 || rc=1
        "${STARTUP_RUNNER[@]}" -f remove "${STARTUP_IOC}" >/dev/null 2>&1 || rc=1
        state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${STARTUP_IOC}.service" 2>/dev/null || true)
        [[ "${state}" != active && ! -e "${STARTUP_SOCKET}" && ! -e "${CONF_DIR}/${STARTUP_IOC}.conf" ]] || rc=1
        (( rc == 0 )) && STARTUP_INSTALLED=0
    fi
    if (( STARTUP_FIXTURE_READY )); then
        cp -p "${STARTUP_FIXTURE_ROOT}/original-st.cmd" "${STARTUP_BOOT}/st.cmd" || rc=1
        rm -f "${STARTUP_BOOT}/startup-child.iocsh" || rc=1
    fi
    return "${rc}"
}

function test_generated_startup {
    local step="$1" case_name output rc want diagnostic native state response ok command
    local evidence log_offset runner_pid attempt

    _log INFO "STEP ${step}: Original Generated IOC Startup"
    if ! startup_fixture_prepare; then
        verify_state true false "Original generated fixture is available"
        close_current_remaining SKIP "original generator or native build prerequisite failed"
        return 0
    fi
    verify_state true true "Original generated fixture is available"
    startup_fixture_install
    for case_name in "${STARTUP_CASES[@]}"; do
        startup_fixture_variant "${case_name}"
        evidence="${STARTUP_FIXTURE_ROOT}/${case_name}"
        cp "${STARTUP_BOOT}/st.cmd" "${evidence}.cmd"
        rc=0
        log_offset=$(stat -c %s "${STARTUP_LOG}" 2>/dev/null || printf 0)
        if [[ "${case_name}" == zero-before-init ]]; then
            # Startup-file exit returns to the original main's interactive shell.
            # A real console exit then lets that unchanged main terminate with 0.
            "${STARTUP_RUNNER[@]}" start "${STARTUP_IOC}" > "${evidence}.stdout" 2> "${evidence}.stderr" &
            runner_pid=$!
            STARTUP_PENDING_PID="${runner_pid}"
            for (( attempt=0; attempt<20; attempt++ )); do
                response=$(startup_fixture_console)
                [[ "${response}" == *"IOCNAME=${STARTUP_APP_NAME}"* ]] && break
                sleep 0.1
            done
            { printf 'exit\n'; sleep 0.5; } |
                timeout 3 socat - "UNIX-CONNECT:${STARTUP_SOCKET}" > "${evidence}.exit-console" 2>&1 || true
            wait "${runner_pid}" || rc=$?
            STARTUP_PENDING_PID=0
        else
            "${STARTUP_RUNNER[@]}" start "${STARTUP_IOC}" > "${evidence}.stdout" 2> "${evidence}.stderr" || rc=$?
        fi
        output=$(cat "${evidence}.stdout" "${evidence}.stderr")
        native=$(tail -c "+$((log_offset + 1))" "${STARTUP_LOG}")
        printf '%s\n' "${native}" > "${evidence}.log"
        state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${STARTUP_IOC}.service" 2>/dev/null || true)
        response=$(startup_fixture_console)
        printf '%s\n' "${response}" > "${evidence}.console"
        want=0
        diagnostic=false
        ok=false
        case "${case_name}" in
            main-*-break|loaded-*-break-break)
                want=1
                [[ "${output}" == *"exited during startup (exit code 2)"* ]] && diagnostic=true
                [[ "${native}" == *"Normal exit status = 2"* ]] && ok=true
                ;;
            zero-before-init)
                [[ "${output}" == *"did not report initialization complete"* &&
                   "${output}" != *"successfully started"* && "${output}" != *"Error: IOC"* ]] && diagnostic=true
                [[ "${native}" == *"Normal exit status = 0"* &&
                   "${native}" != *"All initialization complete"* ]] && ok=true
                ;;
            signal-before-init)
                want=1
                [[ "${output}" == *"crash-looping"* && "${output}" != *"exit code"* ]] && diagnostic=true
                [[ "${native}" == *"killed by signal 9"* ]] && ok=true
                ;;
            *)
                [[ "${output}" != *"Error: IOC"* && "${output}" != *"exit code"* ]] && diagnostic=true
                [[ "${native}" == *"All initialization complete"* ]] && ok=true
                ;;
        esac
        if [[ "${case_name}" == *-quote-* && "${native}" != *"Unbalanced quote"* ]]; then
            ok=false
        fi
        if [[ "${case_name}" == main-after-*-break && "${native}" != *"All initialization complete"* ]]; then
            ok=false
        fi
        if [[ "${case_name}" == main-before-*-break || "${case_name}" == loaded-*-break-break ]]; then
            [[ "${native}" != *"All initialization complete"* ]] || ok=false
        fi
        verify_state "${want}" "${rc}" "${case_name}: runner exit"
        verify_state true "${diagnostic}" "${case_name}: startup diagnostic"
        verify_state true "${ok}" "${case_name}: native child evidence"
        verify_state active "${state}" "${case_name}: supervisor remains active"
        ok=false
        [[ "${response}" == *"IOCNAME=${STARTUP_APP_NAME}"* ]] && ok=true
        if (( want == 0 )); then
            verify_state true "${ok}" "${case_name}: IOC responds"
        else
            verify_state false "${ok}" "${case_name}: terminated IOC does not respond"
        fi
        "${STARTUP_RUNNER[@]}" stop "${STARTUP_IOC}" >/dev/null
    done
    startup_fixture_variant healthy
    "${STARTUP_RUNNER[@]}" start "${STARTUP_IOC}" >/dev/null
    for command in start restart restart; do
        rc=0
        "${STARTUP_RUNNER[@]}" "${command}" "${STARTUP_IOC}" > "${STARTUP_FIXTURE_ROOT}/control-${CURRENT_STEP_CHECK_INDEX}.log" 2>&1 || rc=$?
        verify_state 0 "${rc}" "Healthy ${command} preserves startup success"
        if [[ "${command}" == restart ]]; then
            "${STARTUP_RUNNER[@]}" stop "${STARTUP_IOC}" >/dev/null
        fi
    done
    rc=0
    startup_fixture_cleanup || rc=$?
    verify_state 0 "${rc}" "Generated IOC registration and socket removed"
    test_generated_startup_severity
}

# The module's failed output and the IOC's ability to serve commands are
# separate observations. Every call runs the selected complete CLI.
function test_generated_startup_severity {
    local placement state action evidence log_offset rc output native response record
    local before_marker child_pid executable ok available=false

    executable="${STARTUP_FIXTURE_ROOT}/generated/${STARTUP_APP_NAME}/bin/${EPICS_HOST_ARCH}/${STARTUP_APP_NAME}"
    if grep -qF devaaoStream "${STARTUP_FIXTURE_ROOT}/generated/${STARTUP_APP_NAME}/dbd/${STARTUP_APP_NAME}.dbd"; then
        available=true
    fi
    verify_state true "${available}" "Original IOC includes native StreamDevice array support"
    if [[ "${available}" != true ]]; then
        close_current_remaining SKIP "native StreamDevice fixture is unavailable"
        return 0
    fi
    startup_fixture_install
    for placement in "${STARTUP_SEVERITY_PLACEMENTS[@]}"; do
        for state in "${STARTUP_SEVERITY_STATES[@]}"; do
            action=restart
            [[ "${state}" != stopped-start ]] || action=start
            if [[ "${state}" == active-restart ]]; then
                startup_fixture_variant healthy
                "${STARTUP_RUNNER[@]}" start "${STARTUP_IOC}" > "${STARTUP_FIXTURE_ROOT}/severity-${placement}-old-child.log" 2>&1
            fi
            startup_fixture_severity_variant "${placement}"
            evidence="${STARTUP_FIXTURE_ROOT}/severity-${placement}-${state}"
            cp -p "${STARTUP_BOOT}/st.cmd" "${evidence}.cmd"
            log_offset=$(stat -c %s "${STARTUP_LOG}" 2>/dev/null || printf 0)
            rc=0
            timeout 60 "${STARTUP_RUNNER[@]}" "${action}" "${STARTUP_IOC}" > "${evidence}.stdout" 2> "${evidence}.stderr" || rc=$?
            printf '%s\n' "${rc}" > "${evidence}.exit"
            output=$(cat "${evidence}.stdout" "${evidence}.stderr")
            response=$(startup_fixture_console)
            printf '%s\n' "${response}" > "${evidence}.console"
            { printf 'dbpr("%sConversion", 2)\n' "${STARTUP_SEVERITY_PREFIX}"; sleep 2; } |
                timeout 5 socat - "UNIX-CONNECT:${STARTUP_SOCKET}" > "${evidence}.record" 2>&1 || true
            record=$(cat "${evidence}.record")
            native=$(tail -c "+$((log_offset + 1))" "${STARTUP_LOG}")
            printf '%s\n' "${native}" > "${evidence}.log"
            verify_state 0 "${rc}" "${placement} ${state}: runner exit"
            ok=false
            [[ "${output}" == *"initialization completed with error logs"* &&
               "${output}" == *"can't convert from DBF_DOUBLE to string"* &&
               "${output}" == *"Check the affected IOC functions"* &&
               "${output}" != *"successfully started"* ]] && ok=true
            verify_state true "${ok}" "${placement} ${state}: retained error diagnostic"
            ok=false
            [[ "${native}" == *"sevr=fatal writeData ${STARTUP_SEVERITY_PREFIX}Conversion: can't convert from DBF_DOUBLE to string"* ]] && ok=true
            verify_state true "${ok}" "${placement} ${state}: genuine failed conversion"
            before_marker="${native%%All initialization complete*}"
            ok=false
            if [[ "${native}" == *"All initialization complete"* ]]; then
                if [[ "${placement}" == post-marker ]]; then
                    [[ "${before_marker}" != *"can't convert from DBF_DOUBLE to string"* ]] && ok=true
                else
                    [[ "${before_marker}" == *"can't convert from DBF_DOUBLE to string"* ]] && ok=true
                fi
            fi
            verify_state true "${ok}" "${placement} ${state}: native readiness ordering"
            ok=false
            if [[ "${record}" == *"NORD: 1"* && "${record}" == *"PACT: 0"* && "${record}" == *"SEVR: INVALID"* ]]; then
                if [[ "${placement}" == post-marker ]]; then
                    [[ "${record}" == *"STAT: CALC"* ]] && ok=true
                else
                    [[ "${record}" == *"STAT: UDF"* ]] && ok=true
                fi
            fi
            verify_state true "${ok}" "${placement} ${state}: actual record fields"
            child_pid=$(awk '{ sub(/\r$/, "") } /^@@@ The PID of new child "[^"]*" is: [1-9][0-9]*$/ { pid=$NF } END { print pid }' <<< "${native}")
            ok=false
            if [[ "${child_pid}" =~ ^[1-9][0-9]*$ ]] && kill -0 "${child_pid}" 2>/dev/null &&
                [[ "$(readlink "/proc/${child_pid}/exe" 2>/dev/null || true)" == "${executable}" ]]; then
                ok=true
            fi
            verify_state true "${ok}" "${placement} ${state}: original native child remains alive"
            verify_state active "$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${STARTUP_IOC}.service" 2>/dev/null || true)" \
                "${placement} ${state}: supervisor remains active"
            ok=false
            [[ "${response}" == *"IOCNAME=${STARTUP_APP_NAME}"* ]] && ok=true
            verify_state true "${ok}" "${placement} ${state}: IOC console responds"
            if [[ "${state}" == stopped-start ]]; then
                rc=0
                timeout 60 "${STARTUP_RUNNER[@]}" start "${STARTUP_IOC}" > "${evidence}.active-start" 2>&1 || rc=$?
                output=$(cat "${evidence}.active-start")
                ok=false
                [[ "${rc}" == 0 && "${output}" == *"is already running"* &&
                   "${output}" != *"initialization completed with error logs"* ]] && ok=true
                verify_state true "${ok}" "${placement}: active start excludes historical severity"
            fi
            "${STARTUP_RUNNER[@]}" stop "${STARTUP_IOC}" > "${evidence}.stop" 2>&1
        done
    done

    startup_fixture_severity_variant post-marker
    printf '%s\n' '__undefined_startup_command__' >> "${STARTUP_BOOT}/st.cmd"
    evidence="${STARTUP_FIXTURE_ROOT}/severity-child-exit"
    cp -p "${STARTUP_BOOT}/st.cmd" "${evidence}.cmd"
    log_offset=$(stat -c %s "${STARTUP_LOG}" 2>/dev/null || printf 0)
    rc=0
    timeout 60 "${STARTUP_RUNNER[@]}" start "${STARTUP_IOC}" > "${evidence}.stdout" 2> "${evidence}.stderr" || rc=$?
    output=$(cat "${evidence}.stdout" "${evidence}.stderr")
    native=$(tail -c "+$((log_offset + 1))" "${STARTUP_LOG}")
    printf '%s\n' "${native}" > "${evidence}.log"
    verify_state 1 "${rc}" "Severity followed by genuine child failure returns failure"
    ok=false
    [[ "${output}" == *"exited during startup (exit code 2)"* &&
       "${output}" != *"initialization completed with error logs"* ]] && ok=true
    verify_state true "${ok}" "Native child exit has priority over severity and readiness"
    ok=false
    [[ "${native}" == *"can't convert from DBF_DOUBLE to string"* ]] && ok=true
    verify_state true "${ok}" "Genuine conversion precedes child termination"
    ok=false
    [[ "${native}" == *"All initialization complete"* && "${native}" == *"Normal exit status = 2"* ]] && ok=true
    verify_state true "${ok}" "Original main records nonzero exit after readiness"
    verify_state active "$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${STARTUP_IOC}.service" 2>/dev/null || true)" \
        "Supervisor remains active after genuine child exit"
    rc=0
    startup_fixture_cleanup || rc=$?
    verify_state 0 "${rc}" "Severity fixture registration and socket removed"
    test_startup_log_inputs
}

# The wrapper controls only the external log file. The actual generated IOC,
# systemd service, procServ and complete runner execute for every case.
function startup_fixture_log_wrapper {
    local target="$1"

    cat > "${target}" <<'STARTUP_TAIL'
#!/usr/bin/env bash
set -euo pipefail
if [[ $# != 3 || "$1" != -c || "$3" != "$STARTUP_INPUT_LOG" ]]; then
    exec /usr/bin/tail "$@"
fi
root="$STARTUP_INPUT_FRAMES"
count=0
[[ ! -f "$root/count" ]] || read -r count < "$root/count"
count=$((count + 1))
if (( count == 1 )); then
    ready=0
    for (( attempt=0; attempt<150; attempt++ )); do
        if /usr/bin/grep -qF 'All initialization complete' "$STARTUP_INPUT_LOG"; then
            ready=1
            break
        fi
        /usr/bin/sleep 0.1
    done
    (( ready == 1 )) || exit 2
    /usr/bin/cp "$STARTUP_INPUT_LOG" "$root/original-native.log"
    /usr/bin/awk -v record_path="$root/child-record" -v pid_path="$root/child-pid" \
        '{ sub(/\r$/, "") } /^@@@ The PID of new child "[^"]*" is: [1-9][0-9]*$/ { line=$0; pid=$NF } END { print line > record_path; print pid > pid_path }' \
        "$root/original-native.log"
fi
if [[ -f "$root/$count.frame" ]]; then
    action=rewrite
    [[ ! -f "$root/$count.action" ]] || read -r action < "$root/$count.action"
    before_inode=$(/usr/bin/stat -c %i "$STARTUP_INPUT_LOG")
    before_size=$(/usr/bin/stat -c %s "$STARTUP_INPUT_LOG")
    if [[ "$action" == unlink ]]; then
        /usr/bin/rm -- "$STARTUP_INPUT_LOG"
        printf '%s %s %s absent absent %s\n' "$count" "$before_inode" "$before_size" "$action" >> "$root/trace"
    else
        if [[ "$action" == replace ]]; then
            /usr/bin/mv -- "$STARTUP_INPUT_LOG" "$root/replaced.log"
        fi
        read -r child < "$root/child-pid"
        {
            /usr/bin/cat "$root/child-record"
            /usr/bin/sed "s/@CHILD@/$child/g" "$root/$count.frame"
        } > "$STARTUP_INPUT_LOG"
        if [[ "$action" == replace ]]; then
            /usr/bin/chown --reference="$root/replaced.log" "$STARTUP_INPUT_LOG"
            /usr/bin/chmod --reference="$root/replaced.log" "$STARTUP_INPUT_LOG"
        fi
        after_inode=$(/usr/bin/stat -c %i "$STARTUP_INPUT_LOG")
        after_size=$(/usr/bin/stat -c %s "$STARTUP_INPUT_LOG")
        printf '%s %s %s %s %s %s\n' "$count" "$before_inode" "$before_size" "$after_inode" "$after_size" "$action" >> "$root/trace"
    fi
fi
printf '%s\n' "$count" > "$root/count"
exec /usr/bin/tail "$@"
STARTUP_TAIL
    chmod 0755 "${target}"
}

# Controlled filesystem inputs cover scanner ordering and persistence; their
# text is not evidence that a native module emitted an error. Native cases above
# use production timing. These inputs use the existing clock-test overrides.
function test_startup_log_inputs {
    local case_name frames wrapper evidence first second severity action rc output want
    local ok input_ok diagnostic dwell count inode_before inode_after size_before size_after
    local marker='iocRun: All initialization complete'
    local base_severity='sevr=fatal controlled component error'
    local -a input_runner=()

    startup_fixture_variant healthy
    startup_fixture_install
    wrapper="${STARTUP_FIXTURE_ROOT}/log-input-bin"
    mkdir -p "${wrapper}"
    startup_fixture_log_wrapper "${wrapper}/tail"
    for case_name in "${STARTUP_LOG_CASES[@]}"; do
        frames="${STARTUP_FIXTURE_ROOT}/log-input-${case_name}"
        mkdir -p "${frames}"
        first="${base_severity}"$'\n'"${marker}"$'\n'
        second=""
        severity="${base_severity}"
        action=rewrite
        want=0
        diagnostic=qualified
        dwell=1
        case "${case_name}" in
            error-first)
                first="${base_severity}"$'\n'
                second="${first}${marker}"$'\n'
                ;;
            marker-first|final-scan)
                first="${marker}"$'\n'
                second="${first}${base_severity}"$'\n'
                [[ "${case_name}" != final-scan ]] || dwell=0
                ;;
            ansi) first=$'\033[31;1msevr=fatal\033[0m controlled component error\n'"${marker}"$'\n' ;;
            repeated) first='sevr=fatal sevr=fatal controlled component error'$'\n'"${marker}"$'\n'; severity='sevr=fatal sevr=fatal' ;;
            distinct-limit)
                first='sevr=fatal detail-one'$'\n''sevr=fatal detail-one'$'\n''sevr=fatal detail-two'$'\n''sevr=fatal detail-three'$'\n''sevr=fatal detail-four'$'\n'"${marker}"$'\n'
                severity='sevr=fatal detail-one'
                ;;
            uppercase) first='SEVR=FATAL controlled component error'$'\n'"${marker}"$'\n'; want=1; diagnostic=fatal ;;
            mixed-case) first='Sevr=fatal controlled component error'$'\n'"${marker}"$'\n'; want=1; diagnostic=fatal ;;
            leading-identifier) first='xsevr=fatal controlled component error'$'\n'"${marker}"$'\n'; want=1; diagnostic=fatal ;;
            trailing-identifier) first='sevr=fatal_suffix controlled component error'$'\n'"${marker}"$'\n'; severity='sevr=fatal_suffix' ;;
            separate-fatal) first="${base_severity} FATAL: independent failure"$'\n'"${marker}"$'\n'; want=1; diagnostic=fatal ;;
            separate-segfault) first="${base_severity} Segmentation fault"$'\n'"${marker}"$'\n'; want=1; diagnostic=fatal ;;
            separate-symbol) first="${base_severity} undefined symbol: missing"$'\n'"${marker}"$'\n'; want=1; diagnostic=fatal ;;
            separate-loader) first="${base_severity} error while loading shared libraries"$'\n'"${marker}"$'\n'; want=1; diagnostic=fatal ;;
            history-excluded)
                first=$'\033[31;1mERROR\033[0m Permission denied (13) loading '\''/private/iocsh_history'\'' sevr=fatal'$'\n'"${marker}"$'\n'
                diagnostic=healthy
                ;;
            inode-replacement|copytruncate|regrowth)
                second="${marker}"$'\n'
                if [[ "${case_name}" != copytruncate ]]; then
                    printf -v second '%4096s\n%s\n' X "${marker}"
                fi
                [[ "${case_name}" != inode-replacement ]] || action=replace
                ;;
            no-readiness) first="${base_severity}"$'\n'; diagnostic=unconfirmed ;;
            unreadable)
                first="${base_severity}"$'\n'
                second=$'\n'
                action="unlink"
                diagnostic=unreadable
                ;;
            partial-status|completed-status)
                first+="@@@ Received a sigChild for process @CHILD@. Normal exit status = 2"
                if [[ "${case_name}" == completed-status ]]; then
                    second="${first}"$'\n'
                    want=1
                    diagnostic="child-exit"
                fi
                ;;
        esac
        printf '%s' "${first}" > "${frames}/1.frame"
        if [[ -n "${second}" ]]; then
            printf '%s' "${second}" > "${frames}/2.frame"
            printf '%s\n' "${action}" > "${frames}/2.action"
        fi
        if [[ "${SUITE_SCOPE}" == system ]]; then
            install -o "${SYSTEM_USER}" -g "${SYSTEM_GROUP}" -m 0644 /dev/null "${STARTUP_LOG}"
        else
            : > "${STARTUP_LOG}"
        fi
        evidence="${frames}/runner"
        input_runner=(env "PATH=${wrapper}:${PATH}" "STARTUP_INPUT_LOG=${STARTUP_LOG}"
            "STARTUP_INPUT_FRAMES=${frames}" IOC_RUNNER_TEST_MAX_INIT_TIMEOUT=5
            "IOC_RUNNER_TEST_CONFIRM_DWELL=${dwell}" IOC_RUNNER_TEST_POLL_INTERVAL=0.1)
        rc=0
        timeout 60 "${input_runner[@]}" "${STARTUP_RUNNER[@]}" start "${STARTUP_IOC}" > "${evidence}.stdout" 2> "${evidence}.stderr" || rc=$?
        printf '%s\n' "${rc}" > "${evidence}.exit"
        output=$(cat "${evidence}.stdout" "${evidence}.stderr")
        verify_state "${want}" "${rc}" "${case_name}: whole runner exit"
        ok=false
        case "${diagnostic}" in
            qualified)
                [[ "${output}" == *"initialization completed with error logs"* && "${output}" == *"${severity}"* &&
                   "${output}" != *"successfully started"* ]] && ok=true
                ;;
            healthy) [[ "${output}" == *"successfully started"* && "${output}" != *"error logs"* ]] && ok=true ;;
            fatal) [[ "${output}" == *"failed to initialize"* && "${output}" != *"initialization completed"* ]] && ok=true ;;
            child-exit) [[ "${output}" == *"exited during startup (exit code 2)"* && "${output}" != *"initialization completed"* ]] && ok=true ;;
            unconfirmed) [[ "${output}" == *"did not report initialization complete"* && "${output}" == *"${severity}"* && "${output}" != *"initialization completed"* ]] && ok=true ;;
            unreadable) [[ "${output}" == *"startup log could not be read"* && "${output}" == *"${severity}"* && "${output}" != *"initialization completed"* ]] && ok=true ;;
        esac
        if [[ "${case_name}" == distinct-limit ]]; then
            [[ "${output}" == *"detail-two"* && "${output}" == *"detail-three"* &&
               "${output}" != *"detail-four"* ]] || ok=false
            count=$(grep -cF 'sevr=fatal detail-one' "${evidence}.stderr" || true)
            [[ "${count}" == 1 ]] || ok=false
        fi
        verify_state true "${ok}" "${case_name}: operator diagnostic"
        input_ok=false
        if [[ -s "${frames}/trace" && -s "${frames}/original-native.log" && -s "${frames}/child-pid" ]]; then
            input_ok=true
            if [[ -n "${second}" ]]; then
                read -r count < "${frames}/count"
                (( count >= 2 )) || input_ok=false
                read -r _ inode_before size_before inode_after size_after _ < <(tail -n1 "${frames}/trace")
                case "${case_name}" in
                    inode-replacement) [[ "${inode_before}" != "${inode_after}" && "${size_after}" -gt "${size_before}" ]] || input_ok=false ;;
                    copytruncate) [[ "${inode_before}" == "${inode_after}" && "${size_after}" -lt "${size_before}" ]] || input_ok=false ;;
                    regrowth) [[ "${inode_before}" == "${inode_after}" && "${size_after}" -gt "${size_before}" ]] || input_ok=false ;;
                    unreadable) [[ "${inode_after}" == absent && ! -e "${STARTUP_LOG}" ]] || input_ok=false ;;
                esac
            fi
        fi
        verify_state true "${input_ok}" "${case_name}: actual controlled filesystem input"
        "${STARTUP_RUNNER[@]}" stop "${STARTUP_IOC}" > "${frames}/stop.log" 2>&1
    done
    rc=0
    startup_fixture_cleanup || rc=$?
    verify_state 0 "${rc}" "Controlled log fixture registration and socket removed"
}
