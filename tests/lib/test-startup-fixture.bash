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
declare -g -a STARTUP_RUNNER=()
declare -g -a STARTUP_CASES=(
    healthy
    main-before-undefined-break main-after-undefined-break
    main-before-quote-break loaded-before-quote-break-break
    main-before-quote-continue main-after-quote-continue
    loaded-before-quote-break-continue loaded-before-quote-continue-break
    zero-before-init signal-before-init status-shaped-text
)

function startup_fixture_catalog {
    local step="$1" rows_name="$2" case_name check method=""
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
}
