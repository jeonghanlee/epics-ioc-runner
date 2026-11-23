#!/usr/bin/env bash
# Shared loader-line reporting checks for the System and Local lifecycle
# suites (#169). A start whose child exits nonzero during startup prints the
# log lines of that start that begin with "iocsh.bash: " or "iocsh_elf.bash: ",
# at most LOADER_LINE_LIMIT, then the number of further such lines.
#
# Two children run under the complete selected runner. The fixture child is a
# shell script that prints a known set of loader-prefixed and other lines and
# exits 78; only the external child is replaced. The real loader is the
# iocsh.bash beside EPICS_BASE, refusing a module that is not installed.

declare -gr LOADER_LINE_LIMIT=10
declare -gr LOADER_FIXTURE_EXIT=78
declare -gr LOADER_MISSING_MODULE="nosuchmodule_loaderprobe"
declare -g -a LOADER_RUNNER=()

function loader_lines_catalog {
    local step="$1" rows_name="$2" check method="" prerequisite_method=""
    local -n rows="${rows_name}"

    if [[ "${SUITE_SCOPE}" == system ]]; then
        method="|real-path"
        prerequisite_method="|direct-inspection"
    fi
    for check in fixture-start-exits-1 fixture-reports-exit-code \
        fixture-prints-first-ten-loader-lines fixture-prints-further-line-count \
        fixture-omits-lines-beyond-ten fixture-omits-other-lines \
        fixture-output-has-no-carriage-return fixture-keeps-log-hint fixture-cleanup; do
        rows+=("${step}|${SUITE_ID}.${step}.${check}|BEHAVIOR${method}")
    done
    rows+=("${step}|${SUITE_ID}.${step}.loader-available|PREREQUISITE${prerequisite_method}")
    for check in loader-refusal-prints-log-loader-line loader-refusal-line-has-no-error-word \
        loader-cleanup; do
        rows+=("${step}|${SUITE_ID}.${step}.${check}|BEHAVIOR${method}")
    done
}

# Writes the probe configuration for an existing probe directory, gives the
# directory the system workspace ownership in system mode, then installs it.
function _loader_probe_install {
    local name="$1" dir="$2" cmd="$3" args="$4"
    local conf="${WORKSPACE}/${name}.conf"

    {
        if [[ "${SUITE_SCOPE}" == system ]]; then
            printf 'IOC_USER="%s"\nIOC_GROUP="%s"\n' "${SYSTEM_USER}" "${SYSTEM_GROUP}"
        else
            printf 'IOC_USER="%s"\nIOC_GROUP="%s"\n' "$(id -un)" "$(id -gn)"
        fi
        printf 'IOC_CHDIR="%s"\nIOC_PORT=""\nIOC_CMD="%s"\n' "${dir}" "${cmd}"
        if [[ -n "${args}" ]]; then
            printf 'IOC_ARGS="%s"\n' "${args}"
        fi
    } > "${conf}"
    if [[ "${SUITE_SCOPE}" == system ]]; then
        chown -R "${OWNER_WORKSPACE}" "${dir}"
        chmod 2775 "${dir}"
    fi
    "${LOADER_RUNNER[@]}" -f install "${conf}" >/dev/null 2>&1
}

# Stops and removes one probe IOC; prints "true" when no configuration and no
# active unit remain.
function _loader_probe_remove {
    local name="$1" state

    "${LOADER_RUNNER[@]}" stop "${name}" >/dev/null 2>&1 || true
    "${LOADER_RUNNER[@]}" -f remove "${name}" >/dev/null 2>&1 || true
    state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${name}.service" 2>/dev/null || true)
    if [[ ! -e "${CONF_DIR}/${name}.conf" && "${state}" != "active" ]]; then
        printf 'true'
    else
        printf 'false'
    fi
}

function test_loader_lines {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Loader Lines on a Refused Start (#169)"
    print_sub_divider

    local fixture_ioc="LoaderLines-${SUITE_SCOPE}"
    local loader_ioc="LoaderRefusal-${SUITE_SCOPE}"
    local fixture_dir="${WORKSPACE}/loader_lines_ioc"
    local loader_dir="${WORKSPACE}/loader_refusal_ioc"
    local loader="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}/iocsh.bash"
    local tree="${EPICS_BASE%/base}"
    local log_dir="${SYSTEM_LOG_DIR:-}"
    local output rc=0 ok index printed expected log_line
    local -a fixture_lines=()

    LOADER_RUNNER=(bash "${RUNNER_SCRIPT}")
    if [[ "${SUITE_SCOPE}" == local ]]; then
        LOADER_RUNNER+=(--local)
        log_dir="${IOC_RUNNER_LOCAL_LOG_DIR}"
    fi

    # Twelve loader-prefixed lines: the sixth comes from the ELF inspection
    # script. A prefix that does not open the line and an ordinary line are
    # interleaved and must not be selected.
    for index in 01 02 03 04 05 06 07 08 09 10 11 12; do
        if [[ "${index}" == 06 ]]; then
            fixture_lines+=("iocsh_elf.bash: loader probe line ${index}")
        else
            fixture_lines+=("iocsh.bash: loader probe line ${index}")
        fi
    done
    mkdir -p "${fixture_dir}"
    {
        printf '#!/bin/sh\n'
        for index in "${!fixture_lines[@]}"; do
            printf "printf '%%s\\\\n' '%s'\n" "${fixture_lines[${index}]}"
            if (( index == 2 )); then
                printf "printf '%%s\\\\n' 'ordinary probe text'\n"
                printf "printf '%%s\\\\n' '  iocsh.bash: indented probe text'\n"
            fi
        done
        printf 'exit %s\n' "${LOADER_FIXTURE_EXIT}"
    } > "${fixture_dir}/st.cmd"
    chmod 0775 "${fixture_dir}/st.cmd"

    _loader_probe_install "${fixture_ioc}" "${fixture_dir}" "./st.cmd" "" || true
    output=$("${LOADER_RUNNER[@]}" start "${fixture_ioc}" 2>&1) || rc=$?
    printf '%s\n' "${output}" > "${WORKSPACE}/${fixture_ioc}.start"

    verify_state 1 "${rc}" "Fixture child: start exits 1"
    ok=false
    [[ "${output}" == *"exited during startup (exit code ${LOADER_FIXTURE_EXIT})"* ]] && ok=true
    verify_state true "${ok}" "Fixture child: exit code is reported"

    printed=$(grep -E '^    iocsh(_elf)?\.bash: ' <<< "${output}" || true)
    expected=$(printf '    %s\n' "${fixture_lines[@]:0:${LOADER_LINE_LIMIT}}")
    expected="${expected%$'\n'}"
    verify_state "${expected}" "${printed}" "Fixture child: the first ten loader lines are printed in order"
    ok=false
    [[ "${output}" == *"    (2 further loader line(s) in the log)"* ]] && ok=true
    verify_state true "${ok}" "Fixture child: the number of further loader lines is printed"

    ok=false
    if [[ "${output}" == *"${fixture_lines[9]}"* && "${output}" != *"${fixture_lines[10]}"* \
        && "${output}" != *"${fixture_lines[11]}"* ]]; then
        ok=true
    fi
    verify_state true "${ok}" "Fixture child: lines beyond the tenth are not printed"
    ok=false
    if [[ "${output}" == *"${fixture_lines[0]}"* && "${output}" != *"ordinary probe text"* \
        && "${output}" != *"indented probe text"* ]]; then
        ok=true
    fi
    verify_state true "${ok}" "Fixture child: lines without a leading loader prefix are not printed"
    ok=false
    [[ "${output}" == *"${fixture_lines[0]}"* && "${output}" != *$'\r'* ]] && ok=true
    verify_state true "${ok}" "Fixture child: printed lines carry no carriage return"
    ok=false
    if [[ "${output}" == *"-> Check logs: ioc-runner "*"log ${fixture_ioc}"* \
        && "${output}" == *"(log file: ${log_dir}/${fixture_ioc}.log)"* ]]; then
        ok=true
    fi
    verify_state true "${ok}" "Fixture child: the log file hint is kept"
    verify_state true "$(_loader_probe_remove "${fixture_ioc}")" "Fixture child: cleanup is complete"

    if [[ ! -x "${loader}" || ! -r "${tree}/setEpicsEnv.bash" ]]; then
        _log "WARN" "No loader at ${loader} with ${tree}/setEpicsEnv.bash; skipping the real loader refusal."
        record_current_state SKIP "the EPICS tree has no iocsh.bash loader or no setEpicsEnv.bash"
        close_current_remaining SKIP "requires ${SUITE_ID}.${CURRENT_STEP_ID}.loader-available"
        return 0
    fi
    record_current_state PASS

    mkdir -p "${loader_dir}"
    printf 'module %s\n' "${LOADER_MISSING_MODULE}" > "${loader_dir}/st.cmd"
    _loader_probe_install "${loader_ioc}" "${loader_dir}" "${loader}" "-e ${tree} st.cmd" || true
    rc=0
    output=$("${LOADER_RUNNER[@]}" start "${loader_ioc}" 2>&1) || rc=$?
    printf '%s\n' "${output}" > "${WORKSPACE}/${loader_ioc}.start"
    log_line=$(grep -a -m1 -E '^iocsh(_elf)?\.bash: ' "${log_dir}/${loader_ioc}.log" 2>/dev/null | tr -d '\r' || true)

    ok=false
    [[ "${rc}" == 1 && -n "${log_line}" && "${output}" == *$'\n'"    ${log_line}"* ]] && ok=true
    verify_state true "${ok}" "Real loader: start exits 1 and prints the loader line of the log"
    ok=false
    [[ -n "${log_line}" && "${log_line}" != *ERROR* && "${output}" == *"    ${log_line}"* ]] && ok=true
    verify_state true "${ok}" "Real loader: the printed refusal line has no ERROR word"
    verify_state true "$(_loader_probe_remove "${loader_ioc}")" "Real loader: cleanup is complete"
}
