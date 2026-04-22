#!/usr/bin/env bash
#
# Error path and negative-case tests for ioc-runner.
# Requires only a mock con binary via IOC_RUNNER_CON_TOOL.
# Does not require EPICS, procServ, or a running systemd service.

set -e

declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g MAGENTA='\033[0;35m'
declare -g BLUE='\033[0;34m'
declare -g YELLOW='\033[0;33m'
declare -g NC='\033[0m'

declare -g TEST_TOTAL=0
declare -g TEST_PASSED=0
declare -g TEST_FAILED=0
declare -g SCRIPT_ERROR=0
declare -g -a FAILED_DETAILS=()

declare -g SC_RPATH
declare -g SC_TOP
SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"

declare -g RUNNER_SCRIPT="${SC_TOP}/../bin/ioc-runner"

# Extract CRASH_LOG_PATTERNS from runner script via zero-fork parameter expansion.
# Source-and-execute is not viable: the runner auto-dispatches commands at module bottom.
declare -g CRASH_LOG_PATTERNS=""
declare _line
while IFS= read -r _line; do
    if [[ "${_line}" == 'declare -g CRASH_LOG_PATTERNS='* ]]; then
        CRASH_LOG_PATTERNS="${_line#*\"}"
        CRASH_LOG_PATTERNS="${CRASH_LOG_PATTERNS%\"}"
        break
    fi
done < "${RUNNER_SCRIPT}"
unset _line


declare -g MOCK_CON_BIN
declare -g TEST_TMPDIR

# --- Interrupt & Exit Handling ---
function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        SCRIPT_ERROR=1
        printf "\n${RED}%s${NC}\n" "[ABORT] Script terminated unexpectedly. (Exit code: ${exit_code})"
    fi
    _cleanup
    print_summary
}
trap _handle_exit EXIT
trap 'exit 1' SIGINT

# ==============================================================================
# Utilities
# ==============================================================================

function _log {
    local level="$1"
    local message="$2"
    local color="$NC"

    case "$level" in
        "INFO")    color="$BLUE" ;;
        "SUCCESS") color="$GREEN" ;;
        "WARN")    color="$YELLOW" ;;
        "ERROR")   color="$RED" ;;
    esac

    printf "${color}[%-7s] %s${NC}\n" "$level" "$message"
}

function print_divider {
    printf "${BLUE}%s${NC}\n" "===================================================================================================="
}

function print_sub_divider {
    printf "${BLUE}%s${NC}\n" "----------------------------------------------------------------------------------------------------"
}

function print_summary {
    printf "\n"
    printf "${BLUE}%s${NC}\n" "===================================================================================================="
    printf "${BLUE}%s${NC}\n" "                                   ERROR HANDLING TEST SUMMARY                                      "
    printf "${BLUE}%s${NC}\n" "===================================================================================================="

    printf "  %-20s : %d\n" "Total Assertions" "${TEST_TOTAL}"
    printf "${GREEN}  %-20s : %d${NC}\n" "Passed" "${TEST_PASSED}"

    if [[ ${TEST_FAILED} -gt 0 ]]; then
        printf "${RED}  %-20s : %d${NC}\n" "Failed" "${TEST_FAILED}"
    else
        printf "  %-20s : %d\n" "Failed" "0"
    fi

    if [[ ${SCRIPT_ERROR} -gt 0 ]]; then
        printf "${MAGENTA}  %-20s : %d${NC}\n" "Script Errors" "${SCRIPT_ERROR}"
    else
        printf "  %-20s : %d\n" "Script Errors" "0"
    fi

    if [[ ${TEST_FAILED} -gt 0 ]]; then
        printf "\n${RED}%s${NC}\n" "--- [ FAILED ASSERTIONS ] ---"
        for detail in "${FAILED_DETAILS[@]}"; do
            printf "${RED}  * %s${NC}\n" "$detail"
        done
        printf "${RED}%s${NC}\n" "-----------------------------"
    elif [[ ${SCRIPT_ERROR} -eq 0 ]]; then
        printf "\n${GREEN}%s${NC}\n" "[SUCCESS] All error handling tests completed perfectly!"
    fi

    printf "${BLUE}%s${NC}\n\n" "===================================================================================================="
}

# Validates string equality between expected and actual states, tracking aggregate test metrics.
function verify_state {
    local expected="$1"
    local actual="$2"
    local step_name="$3"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    if [[ "${expected}" == "${actual}" ]]; then
        printf "${GREEN}[ PASS ]${NC} %s\n" "${step_name}"
        TEST_PASSED=$((TEST_PASSED + 1))
    else
        printf "${RED}[ FAIL ]${NC} %s\n" "${step_name}" >&2
        printf "  ${YELLOW}Expected : %s${NC}\n" "${expected}" >&2
        printf "  ${YELLOW}Actual   : %s${NC}\n" "${actual}" >&2
        TEST_FAILED=$((TEST_FAILED + 1))
        FAILED_DETAILS+=("${step_name} (Expected: ${expected}, Actual: ${actual})")
    fi
}

function verify_exit_code {
    local expected_exit="$1"
    local actual_exit="$2"
    local step_name="$3"

    TEST_TOTAL=$((TEST_TOTAL + 1))

    if [[ "${expected_exit}" == "${actual_exit}" ]]; then
        printf "${GREEN}[ PASS ]${NC} %s\n" "${step_name}"
        TEST_PASSED=$((TEST_PASSED + 1))
    else
        printf "${RED}[ FAIL ]${NC} %s\n" "${step_name}" >&2
        printf "  ${YELLOW}Expected exit : %s${NC}\n" "${expected_exit}" >&2
        printf "  ${YELLOW}Actual exit   : %s${NC}\n" "${actual_exit}" >&2
        TEST_FAILED=$((TEST_FAILED + 1))
        FAILED_DETAILS+=("${step_name} (Expected exit: ${expected_exit}, Actual exit: ${actual_exit})")
    fi
}

function _run {
    local cmd=("$@")
    local exit_code
    "${cmd[@]}" >/dev/null 2>&1; exit_code=$?; true
    printf "%d" "${exit_code}"
}

# Asserts whether a fixture string matches CRASH_LOG_PATTERNS under the same
# flags used by do_start_restart in ioc-runner (grep -qiE).
function verify_match {
    local expected="$1"
    local fixture="$2"
    local step_name="$3"
    local actual="nomatch"

    if printf "%s\n" "${fixture}" | grep -qiE "${CRASH_LOG_PATTERNS}"; then
        actual="match"
    fi
    verify_state "${expected}" "${actual}" "${step_name}"
}

# ==============================================================================
# Setup & Teardown
# ==============================================================================

function _setup {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Setup Mock Environment"
    print_sub_divider

    TEST_TMPDIR=$(mktemp -d)

    # Create a mock con binary that exits successfully without doing anything.
    MOCK_CON_BIN="${TEST_TMPDIR}/con"
    printf "#!/usr/bin/env bash\nexit 0\n" > "${MOCK_CON_BIN}"
    chmod +x "${MOCK_CON_BIN}"

    export IOC_RUNNER_CON_TOOL="${MOCK_CON_BIN}"

    _log "SUCCESS" "Mock environment ready at ${TEST_TMPDIR}"
}

function _cleanup {
    if [[ -d "${TEST_TMPDIR}" ]]; then
        rm -rf "${TEST_TMPDIR}"
    fi
}

# ==============================================================================
# Test Steps
# ==============================================================================
function test_usage {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Usage and Help"
    print_sub_divider

    local exit_code

    exit_code=$(_run bash "${RUNNER_SCRIPT}" --help)
    verify_exit_code "0" "${exit_code}" "--help exits 0"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" -h)
    verify_exit_code "0" "${exit_code}" "-h exits 0"

    exit_code=$(_run bash "${RUNNER_SCRIPT}")
    verify_exit_code "0" "${exit_code}" "no arguments exits 0"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" unknown_command)
    verify_exit_code "1" "${exit_code}" "unknown command exits 1"

    # Validates that -V reports the script's own repo identity regardless of CWD.
    local version_out
    local cwd_unrelated="${TEST_TMPDIR}/unrelated_dir"
    mkdir -p "${cwd_unrelated}"
    version_out=$(cd "${cwd_unrelated}" && bash "${RUNNER_SCRIPT}" -V 2>/dev/null)
    exit_code=$?
    verify_exit_code "0" "${exit_code}" "'-V' exits 0 from unrelated CWD"

    local has_version="false"
    if [[ "${version_out}" == *"epics-ioc-runner version"* ]]; then has_version="true"; fi
    verify_state "true" "${has_version}" "'-V' produces valid version output from unrelated CWD"

    # Validates that -v/-vv are rejected when paired with any command other than list.
    exit_code=$(_run bash "${RUNNER_SCRIPT}" -v start dummy_ioc)
    verify_exit_code "1" "${exit_code}" "'-v start' exits 1 (verbose restricted to list)"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" -vv status dummy_ioc)
    verify_exit_code "1" "${exit_code}" "'-vv status' exits 1 (verbose restricted to list)"

    exit_code=$(IOC_RUNNER_LOCAL_RUN_DIR="${TEST_TMPDIR}/empty_run" _run bash "${RUNNER_SCRIPT}" --local -v list)
    verify_exit_code "0" "${exit_code}" "'--local -v list' exits 0 (verbose valid for list)"
}

function test_missing_target {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Missing Target Name Errors"
    print_sub_divider

    local exit_code
    local cmd

    for cmd in start stop restart status enable disable; do
        exit_code=$(_run bash "${RUNNER_SCRIPT}" "${cmd}")
        verify_exit_code "1" "${exit_code}" "'${cmd}' without target exits 1"
    done

    exit_code=$(_run bash "${RUNNER_SCRIPT}" remove)
    verify_exit_code "1" "${exit_code}" "'remove' without target exits 1"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" attach)
    verify_exit_code "1" "${exit_code}" "'attach' without target exits 1"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" view)
    verify_exit_code "1" "${exit_code}" "'view' without target exits 1"
}

# Validates the zero-fork path expansion, interactive overwrite protections, and CI/CD bypass mechanisms.
function test_generate_logic {
    local step="$1"
    local exit_code
    local test_dir="${TEST_TMPDIR}/valid_ioc"

    print_divider
    _log "INFO" "STEP ${step}: Generate Logic and Diff Engine"
    print_sub_divider

    mkdir -p "${test_dir}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    local conf_file="${test_dir}/valid_ioc.conf"

    # Evaluates relative path expansion and automatic startup script resolution.
    (
        cd "${test_dir}" || exit 1
        exit_code=$(_run bash "${RUNNER_SCRIPT}" --local generate .)
        verify_exit_code "0" "${exit_code}" "Generate native dot path resolves successfully"
    )

    local conf_exists="false"
    if [[ -f "${conf_file}" ]]; then conf_exists="true"; fi
    verify_state "true" "${conf_exists}" "Configuration artifact created dynamically"

    # Evaluates the internal cmp -s integration bypassing identical configuration files.
    (
        cd "${test_dir}" || exit 1
        exit_code=$(_run bash "${RUNNER_SCRIPT}" --local generate .)
        verify_exit_code "0" "${exit_code}" "Identical artifact natively bypasses overwrite and exits 0"
    )

    # Evaluates the ANSI diff engine and interactive prompt behavior using a mocked non-interactive shell.
    printf "\n# Modified\n" >> "${conf_file}"
    (
        cd "${test_dir}" || exit 1
        exit_code=$(_run bash -c "bash \"${RUNNER_SCRIPT}\" --local generate . < /dev/null")
        verify_exit_code "1" "${exit_code}" "Differential artifact prompt exits 1 on EOF"
    )

    # Evaluates the forced overwrite bypass mechanism for automation pipelines.
    (
        cd "${test_dir}" || exit 1
        exit_code=$(_run bash "${RUNNER_SCRIPT}" --local -f generate .)
        verify_exit_code "0" "${exit_code}" "Forced overwrite ignores diff constraint and exits 0"
    )
}

function test_generate_errors {
    local step="$1"
    local exit_code
    local dummy_dir="${TEST_TMPDIR}/dummy_gen"
    local bad_name_dir="${TEST_TMPDIR}/bad name ioc"

    print_divider
    _log "INFO" "STEP ${step}: Generate Error Paths"
    print_sub_divider

    mkdir -p "${dummy_dir}"
    mkdir -p "${bad_name_dir}"

    # Validates path resolution rejecting illegal characters before native evaluation
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local generate "${bad_name_dir}")
    verify_exit_code "1" "${exit_code}" "Generate with invalid directory name exits 1"

    # Validates script discovery aborting when zero executables exist
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local generate "${dummy_dir}")
    verify_exit_code "1" "${exit_code}" "Generate with no executable scripts exits 1"

    # Validates interactive prompt aborting safely under non-interactive stdin
    touch "${dummy_dir}/st1.cmd" "${dummy_dir}/st2.cmd"
    chmod +x "${dummy_dir}/st1.cmd" "${dummy_dir}/st2.cmd"
    exit_code=$(_run bash -c "bash \"${RUNNER_SCRIPT}\" --local generate \"${dummy_dir}\" < /dev/null")
    verify_exit_code "1" "${exit_code}" "Generate with multiple candidates aborts interactively"

    # Validates CI/CD bypass flag safely handling multiple candidates
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local -f generate "${dummy_dir}")
    verify_exit_code "0" "${exit_code}" "Generate with force flag resolves multiple candidates and exits 0"

    # Validates that multi-candidate cmd selection refuses to proceed on EOF.
    local multi_cmd_dir="${TEST_TMPDIR}/multi_cmd_ioc"
    mkdir -p "${multi_cmd_dir}"
    touch "${multi_cmd_dir}/st.cmd" "${multi_cmd_dir}/alt.cmd"
    chmod +x "${multi_cmd_dir}/st.cmd" "${multi_cmd_dir}/alt.cmd"

    exit_code=$(_run bash -c "bash \"${RUNNER_SCRIPT}\" --local generate \"${multi_cmd_dir}\" < /dev/null")
    verify_exit_code "1" "${exit_code}" "Multiple cmd candidates without input exits 1 (no default)"
    # Validates EOF path on the overwrite prompt when an existing, differing
    # .conf forces the interactive diff-preview branch (not the identical-bypass).
    local overwrite_dir="${TEST_TMPDIR}/overwrite_eof_ioc"
    mkdir -p "${overwrite_dir}"
    touch "${overwrite_dir}/st.cmd"
    chmod +x "${overwrite_dir}/st.cmd"

    # Seed an initial conf, then tamper with it so regeneration hits the diff path.
    ( cd "${overwrite_dir}" && bash "${RUNNER_SCRIPT}" --local -f generate . >/dev/null 2>&1 )
    local existing_conf="${overwrite_dir}/overwrite_eof_ioc.conf"
    printf "# tampered marker\n" >> "${existing_conf}"

    local pre_sum post_sum preserved="false"
    pre_sum=$(md5sum "${existing_conf}" | awk '{print $1}')

    exit_code=$(_run bash -c "bash \"${RUNNER_SCRIPT}\" --local generate \"${overwrite_dir}\" < /dev/null")
    verify_exit_code "1" "${exit_code}" "Generate overwrite prompt exits 1 on EOF"

    post_sum=$(md5sum "${existing_conf}" | awk '{print $1}')
    [[ "${pre_sum}" == "${post_sum}" ]] && preserved="true"
    verify_state "true" "${preserved}" "Generate EOF abort preserves existing conf unchanged"

}

# Validates directory-based artifact resolution and target routing functionality.
function test_install_logic {
    local step="$1"
    local exit_code
    local test_dir="${TEST_TMPDIR}/install_ioc"
    local mock_conf_dir="${TEST_TMPDIR}/mock_etc"
    local mock_sysd_dir="${TEST_TMPDIR}/mock_sysd"

    print_divider
    _log "INFO" "STEP ${step}: Install Routing and Resolution"
    print_sub_divider

    mkdir -p "${test_dir}" "${mock_conf_dir}" "${mock_sysd_dir}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    # Pre-generates the artifact for the installation pipeline evaluation.
    ( cd "${test_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1 )

    # Evaluates implicit artifact location and syntax validation prior to routing.
    (
        cd "${test_dir}" || exit 1
        exit_code=$(IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" _run bash "${RUNNER_SCRIPT}" --local -f install .)
        verify_exit_code "0" "${exit_code}" "Directory-based installation resolves artifact correctly"
    )

    local installed_conf="${mock_conf_dir}/install_ioc.conf"
    local install_exists="false"
    if [[ -f "${installed_conf}" ]]; then install_exists="true"; fi
    verify_state "true" "${install_exists}" "Artifact successfully routed to configuration directory"

    # Validates EOF path on install overwrite prompt: exits 0 AND preserves
    # the existing conf. A tamper marker is injected BEFORE the EOF attempt so
    # that even a byte-identical reinstall would be detectable (cp+sed-strip+
    # append would drop the marker).
    local eof_marker="# T5_EOF_PRESERVE_MARKER"
    printf "%s\n" "${eof_marker}" >> "${installed_conf}"

    (
        cd "${test_dir}" || exit 1
        exit_code=$(IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
        _run bash -c "bash \"${RUNNER_SCRIPT}\" --local install . < /dev/null")
        verify_exit_code "1" "${exit_code}" "Install overwrite prompt exits 1 on EOF"
    )

    local preserved="false"
    if [[ -f "${installed_conf}" ]] && grep -qF "${eof_marker}" "${installed_conf}" 2>/dev/null; then
        preserved="true"
    fi
    verify_state "true" "${preserved}" "Install EOF abort preserves existing conf (marker retained)"
}

function test_install_errors {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Install Error Paths"
    print_sub_divider

    local exit_code
    local fake_conf="${TEST_TMPDIR}/test.conf"
    printf "IOC_NAME=test\n" > "${fake_conf}"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local -f install "${TEST_TMPDIR}/nonexistent.conf")
    verify_exit_code "1" "${exit_code}" "'install' with missing conf file exits 1"

    exit_code=$(IOC_RUNNER_SYSTEMD_DIR="${TEST_TMPDIR}" _run bash "${RUNNER_SCRIPT}" -f install "${fake_conf}")
    verify_exit_code "1" "${exit_code}" "'install' with missing system template exits 1"

    local dummy_dir="${TEST_TMPDIR}/dummy_install"
    mkdir -p "${dummy_dir}"
    touch "${dummy_dir}/wrong_name.conf"

    # Validates strict naming constraint mapping during directory-based installation
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local install "${dummy_dir}")
    verify_exit_code "1" "${exit_code}" "Install directory with mismatched conf name exits 1"

}

# Validates the IOC_CHDIR write-access precheck inserted in do_install for system mode.
# Uses a PATH-injected stub sudo to control probe exit codes without requiring a real
# ioc-srv account or elevated privileges. Five paths are covered:
#   1. Probe fails + EOF       → exit 1
#   2. Probe fails + explicit N → exit 0
#   3. Probe fails + explicit Y → install proceeds (exit 0)
#   4. Probe fails + FORCE_OVERWRITE → warning on stderr, install proceeds (exit 0)
#   5. Probe passes            → no warning emitted, install proceeds (exit 0)
function test_chdir_precheck {
    local step="$1"
    local exit_code

    print_divider
    _log "INFO" "STEP ${step}: IOC_CHDIR Write-Access Precheck"
    print_sub_divider

    local mock_bin_fail="${TEST_TMPDIR}/precheck_bin_fail"
    local mock_bin_pass="${TEST_TMPDIR}/precheck_bin_pass"
    local test_dir="${TEST_TMPDIR}/precheck_ioc"
    local test_conf="${test_dir}/precheck_ioc.conf"
    local stderr_cap="${TEST_TMPDIR}/precheck_stderr"

    mkdir -p "${mock_bin_fail}" "${mock_bin_pass}" "${test_dir}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    # Stub sudo: returns 1 for "-n -u <user> test -w <path>" probe, 0 for all other
    # invocations (e.g. daemon-reload). The -n flag is stripped before pattern matching
    # because it is a non-interactive marker, not part of the command identity.
    cat > "${mock_bin_fail}/sudo" <<'STUB'
#!/usr/bin/env bash
filtered=()
for arg in "$@"; do
    [[ "${arg}" == "-n" ]] && continue
    filtered+=("${arg}")
done
if [[ "${filtered[0]}" == "-u" && "${filtered[2]}" == "test" && "${filtered[3]}" == "-w" ]]; then
    exit 1
fi
exit 0
STUB
    chmod +x "${mock_bin_fail}/sudo"

    # Stub sudo that always exits 0 (simulates: TARGET_SYSTEM_USER can write to chdir).
    printf '#!/usr/bin/env bash\nexit 0\n' > "${mock_bin_pass}/sudo"
    chmod +x "${mock_bin_pass}/sudo"

    # Valid system-mode conf. IOC_USER and IOC_GROUP match TARGET_SYSTEM_USER/GROUP
    # literals hardcoded in ioc-runner. IOC_PORT must match process_ioc_port output
    # for the default SYSTEM_RUN_DIR (/run/procserv).
    cat > "${test_conf}" <<EOF
IOC_NAME="precheck_ioc"
IOC_USER="ioc-srv"
IOC_GROUP="ioc"
IOC_CHDIR="${test_dir}"
IOC_PORT="unix:ioc-srv:ioc:0660:/run/procserv/precheck_ioc/control"
IOC_CMD="./st.cmd"
EOF

    # Each test case uses its own sysd/conf pair to avoid triggering the overwrite
    # prompt (which would consume the stdin token intended for the precheck prompt).
    local sysd conf

    # Case 1: probe fails, EOF → exit 1
    sysd="${TEST_TMPDIR}/precheck_s1"; conf="${TEST_TMPDIR}/precheck_c1"
    mkdir -p "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    exit_code=$(PATH="${mock_bin_fail}:${PATH}" \
        IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        _run bash -c "bash \"${RUNNER_SCRIPT}\" install \"${test_conf}\" < /dev/null")
    verify_exit_code "1" "${exit_code}" "Precheck: probe fails, EOF → exit 1"

    # Case 2: probe fails, explicit N → exit 0
    sysd="${TEST_TMPDIR}/precheck_s2"; conf="${TEST_TMPDIR}/precheck_c2"
    mkdir -p "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    exit_code=$(PATH="${mock_bin_fail}:${PATH}" \
        IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        _run bash -c "printf 'n\n' | bash \"${RUNNER_SCRIPT}\" install \"${test_conf}\"")
    verify_exit_code "0" "${exit_code}" "Precheck: probe fails, explicit N → exit 0"

    # Case 3: probe fails, explicit Y → install proceeds and conf is deployed
    sysd="${TEST_TMPDIR}/precheck_s3"; conf="${TEST_TMPDIR}/precheck_c3"
    mkdir -p "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    exit_code=$(PATH="${mock_bin_fail}:${PATH}" \
        IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        _run bash -c "printf 'y\n' | bash \"${RUNNER_SCRIPT}\" install \"${test_conf}\"")
    verify_exit_code "0" "${exit_code}" "Precheck: probe fails, explicit Y → install proceeds (exit 0)"
    local installed3_exists="false"
    [[ -f "${conf}/precheck_ioc.conf" ]] && installed3_exists="true"
    verify_state "true" "${installed3_exists}" "Precheck: Y path installs conf file"

    # Case 4: probe fails, FORCE_OVERWRITE → warning on stderr, no prompt, install proceeds
    sysd="${TEST_TMPDIR}/precheck_s4"; conf="${TEST_TMPDIR}/precheck_c4"
    mkdir -p "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    local ec4=0
    PATH="${mock_bin_fail}:${PATH}" \
        IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        bash "${RUNNER_SCRIPT}" -f install "${test_conf}" >/dev/null 2>"${stderr_cap}" \
        || ec4=$?
    verify_exit_code "0" "${ec4}" "Precheck: FORCE_OVERWRITE → exit 0"
    local has_warning4="false"
    grep -q "Warning: IOC_CHDIR" "${stderr_cap}" 2>/dev/null && has_warning4="true"
    verify_state "true" "${has_warning4}" "Precheck: FORCE_OVERWRITE emits warning to stderr"
    local installed4_exists="false"
    [[ -f "${conf}/precheck_ioc.conf" ]] && installed4_exists="true"
    verify_state "true" "${installed4_exists}" "Precheck: FORCE_OVERWRITE installs conf"

    # Case 5: probe passes → no warning emitted, install proceeds silently
    sysd="${TEST_TMPDIR}/precheck_s5"; conf="${TEST_TMPDIR}/precheck_c5"
    mkdir -p "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    local ec5=0
    PATH="${mock_bin_pass}:${PATH}" \
        IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        bash "${RUNNER_SCRIPT}" -f install "${test_conf}" >/dev/null 2>"${stderr_cap}" \
        || ec5=$?
    verify_exit_code "0" "${ec5}" "Precheck: probe passes → exit 0"
    local has_warning5="false"
    grep -q "Warning: IOC_CHDIR" "${stderr_cap}" 2>/dev/null && has_warning5="true"
    verify_state "false" "${has_warning5}" "Precheck: probe passes → no warning emitted"
    local installed5_exists="false"
    [[ -f "${conf}/precheck_ioc.conf" ]] && installed5_exists="true"
    verify_state "true" "${installed5_exists}" "Precheck: probe passes → conf installed"
}

# Validates that ss -lx failure aborts do_list under set -eo pipefail.
# find is replaced by a PATH stub that emits one fake socket entry in the
# null-delimited format expected by do_list, ensuring ss -lx is actually
# reached. ss is replaced by a stub that exits 1 to simulate unavailability.
function test_ss_failure_aborts_list {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: ss Failure Aborts list Under pipefail"
    print_sub_divider

    local mock_bin="${TEST_TMPDIR}/ss_fail_bin"
    local mock_run="${TEST_TMPDIR}/ss_fail_run"
    local fake_sock="${mock_run}/test_ioc/control"

    mkdir -p "${mock_bin}" "${mock_run}/test_ioc"

    # Stub find: outputs one null-delimited socket entry regardless of arguments,
    # bypassing the -type s filesystem check without requiring a real socket file.
    cat > "${mock_bin}/find" <<STUB
#!/usr/bin/env bash
printf '%s\0%s\0%s\0' "${fake_sock}" "2024-01-01 12:00" "srwxrwxr-x"
STUB
    chmod +x "${mock_bin}/find"

    # Stub ss: always exits 1 to simulate the utility being absent or broken.
    printf '#!/usr/bin/env bash\nexit 1\n' > "${mock_bin}/ss"
    chmod +x "${mock_bin}/ss"

    local exit_code
    exit_code=$(PATH="${mock_bin}:${PATH}" \
        IOC_RUNNER_LOCAL_RUN_DIR="${mock_run}" \
        _run bash "${RUNNER_SCRIPT}" --local list)
    verify_exit_code "1" "${exit_code}" "ss -lx failure aborts list (exit 1 under pipefail)"
}

# Validates that the new namespaced env vars (IOC_RUNNER_LOCAL_*) route install
# targets independently of the legacy unified IOC_RUNNER_*_DIR overrides.
function test_env_var_namespacing {
    local step="$1"
    local exit_code
    local test_dir="${TEST_TMPDIR}/ns_ioc"
    local ns_conf_dir="${TEST_TMPDIR}/ns_conf"
    local ns_sysd_dir="${TEST_TMPDIR}/ns_sysd"
    local legacy_conf_dir="${TEST_TMPDIR}/legacy_conf"
    local legacy_sysd_dir="${TEST_TMPDIR}/legacy_sysd"

    print_divider
    _log "INFO" "STEP ${step}: Env Var Namespacing and Precedence"
    print_sub_divider

    mkdir -p "${test_dir}" "${ns_conf_dir}" "${ns_sysd_dir}" \
             "${legacy_conf_dir}" "${legacy_sysd_dir}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    ( cd "${test_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1 )

    # Case 1: Namespaced IOC_RUNNER_LOCAL_* variables route install to ns dirs.
    (
        cd "${test_dir}" || exit 1
        exit_code=$(IOC_RUNNER_LOCAL_CONF_DIR="${ns_conf_dir}" \
                    IOC_RUNNER_LOCAL_SYSTEMD_DIR="${ns_sysd_dir}" \
                    _run bash "${RUNNER_SCRIPT}" --local -f install .)
        verify_exit_code "0" "${exit_code}" "IOC_RUNNER_LOCAL_* routes --local install"
    )

    local ns_installed="${ns_conf_dir}/ns_ioc.conf"
    local ns_exists="false"
    [[ -f "${ns_installed}" ]] && ns_exists="true"
    verify_state "true" "${ns_exists}" "IOC_RUNNER_LOCAL_CONF_DIR resolves to namespaced path"

}

# Validates that unified legacy IOC_RUNNER_*_DIR vars consistently
# override their namespaced IOC_RUNNER_{LOCAL,SYSTEM}_*_DIR counterparts
# for CONF_DIR, SYSTEMD_DIR, and RUN_DIR (via IOC_PORT path resolution).
function test_env_var_precedence {
    local step="$1"
    local exit_code
    local test_dir="${TEST_TMPDIR}/prec_ioc"
    local unified_conf="${TEST_TMPDIR}/prec_unified_conf"
    local unified_sysd="${TEST_TMPDIR}/prec_unified_sysd"
    local unified_run="${TEST_TMPDIR}/prec_unified_run"
    local ns_conf="${TEST_TMPDIR}/prec_ns_conf"
    local ns_sysd="${TEST_TMPDIR}/prec_ns_sysd"
    local ns_run="${TEST_TMPDIR}/prec_ns_run"

    print_divider
    _log "INFO" "STEP ${step}: Env Var Precedence (unified > namespaced)"
    print_sub_divider

    mkdir -p "${test_dir}" "${unified_conf}" "${unified_sysd}" "${unified_run}" \
             "${ns_conf}" "${ns_sysd}" "${ns_run}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    ( cd "${test_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1 )

    # Install with contradicting unified + namespaced vars across all three pairs.
    (
        cd "${test_dir}" || exit 1
        exit_code=$(IOC_RUNNER_CONF_DIR="${unified_conf}" \
                    IOC_RUNNER_SYSTEMD_DIR="${unified_sysd}" \
                    IOC_RUNNER_RUN_DIR="${unified_run}" \
                    IOC_RUNNER_LOCAL_CONF_DIR="${ns_conf}" \
                    IOC_RUNNER_LOCAL_SYSTEMD_DIR="${ns_sysd}" \
                    IOC_RUNNER_LOCAL_RUN_DIR="${ns_run}" \
                    _run bash "${RUNNER_SCRIPT}" --local -f install .)
        verify_exit_code "0" "${exit_code}" "Install succeeds with full precedence matrix"
    )

    # CONF_DIR precedence: conf file lands in unified, not namespaced.
    local conf_in_unified="false" conf_in_ns="false"
    [[ -f "${unified_conf}/prec_ioc.conf" ]] && conf_in_unified="true"
    [[ -f "${ns_conf}/prec_ioc.conf" ]] && conf_in_ns="true"
    verify_state "true"  "${conf_in_unified}" "CONF_DIR: unified var wins"
    verify_state "false" "${conf_in_ns}"      "CONF_DIR: namespaced var ignored"

    # RUN_DIR precedence: installed conf's IOC_PORT path points into unified_run,
    # not ns_run (process_ioc_port composes the path from RUN_DIR).
    local port_line="" port_in_unified="false" port_in_ns="false"
    port_line=$(grep '^IOC_PORT=' "${unified_conf}/prec_ioc.conf" 2>/dev/null || true)
    [[ "${port_line}" == *"${unified_run}/prec_ioc/control"* ]] && port_in_unified="true"
    [[ "${port_line}" == *"${ns_run}/prec_ioc/control"* ]] && port_in_ns="true"
    verify_state "true"  "${port_in_unified}" "RUN_DIR: unified var wins in IOC_PORT"
    verify_state "false" "${port_in_ns}"      "RUN_DIR: namespaced var ignored in IOC_PORT"

    # SYSTEMD_DIR precedence: local template landed in unified, not namespaced.
    local tpl_in_unified="false" tpl_in_ns="false"
    [[ -f "${unified_sysd}/epics-@.service" ]] && tpl_in_unified="true"
    [[ -f "${ns_sysd}/epics-@.service" ]] && tpl_in_ns="true"
    verify_state "true"  "${tpl_in_unified}" "SYSTEMD_DIR: unified var wins"
    verify_state "false" "${tpl_in_ns}"      "SYSTEMD_DIR: namespaced var ignored"
}

# Validates the bash completion script by sourcing it in isolated subshells
# and invoking _ioc_runner_completions with synthesized COMP_WORDS/COMP_CWORD.
# Targets the env-var refactor to ensure completion picks up namespaced vars.
function test_completion {
    local step="$1"
    local comp_script="${SC_TOP}/../bin/ioc-runner-completion.bash"

    print_divider
    _log "INFO" "STEP ${step}: Bash Completion Smoke Tests"
    print_sub_divider

    if [[ ! -f "${comp_script}" ]]; then
        _log "ERROR" "Completion script not found at ${comp_script}"
        (( TEST_FAILED++ )) || true
        return
    fi

    local sys_conf="${TEST_TMPDIR}/comp_sys"
    local loc_conf="${TEST_TMPDIR}/comp_loc"
    local unified_conf="${TEST_TMPDIR}/comp_unified"
    mkdir -p "${sys_conf}" "${loc_conf}" "${unified_conf}"
    touch "${sys_conf}/sys_ioc.conf" \
          "${loc_conf}/loc_ioc.conf" \
          "${unified_conf}/unified_ioc.conf"

    local got

    # S1: bare "ioc-runner <TAB>" -> top-level commands are offered.
    got=$(
        # shellcheck source=/dev/null
        source "${comp_script}"
        COMP_WORDS=(ioc-runner "")
        COMP_CWORD=1
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}" | grep -cxE '(generate|install|list)' || true
    )
    verify_state "3" "${got}" "Bare invocation offers generate/install/list"

    # S2: "ioc-runner -<TAB>" -> global options are offered.
    got=$(
        source "${comp_script}"
        COMP_WORDS=(ioc-runner "-")
        COMP_CWORD=1
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}" | grep -cxE '(--local|-V|--version|-h)' || true
    )
    verify_state "4" "${got}" "Dash prefix offers global options"

    # S3: system mode reads IOC_RUNNER_SYSTEM_CONF_DIR.
    got=$(
        source "${comp_script}"
        unset IOC_RUNNER_CONF_DIR
        export IOC_RUNNER_SYSTEM_CONF_DIR="${sys_conf}"
        COMP_WORDS=(ioc-runner start "")
        COMP_CWORD=2
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}"
    )
    verify_state "sys_ioc" "${got}" "System mode reads IOC_RUNNER_SYSTEM_CONF_DIR"

    # S4: --local mode reads IOC_RUNNER_LOCAL_CONF_DIR.
    got=$(
        source "${comp_script}"
        unset IOC_RUNNER_CONF_DIR
        export IOC_RUNNER_LOCAL_CONF_DIR="${loc_conf}"
        COMP_WORDS=(ioc-runner --local start "")
        COMP_CWORD=3
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}"
    )
    verify_state "loc_ioc" "${got}" "--local mode reads IOC_RUNNER_LOCAL_CONF_DIR"

    # S5: unified IOC_RUNNER_CONF_DIR overrides LOCAL_CONF_DIR in completion.
    got=$(
        source "${comp_script}"
        export IOC_RUNNER_CONF_DIR="${unified_conf}"
        export IOC_RUNNER_LOCAL_CONF_DIR="${loc_conf}"
        COMP_WORDS=(ioc-runner --local start "")
        COMP_CWORD=3
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}"
    )
    verify_state "unified_ioc" "${got}" "IOC_RUNNER_CONF_DIR overrides LOCAL var in completion"

    # S6: "list <TAB>" -> verbosity flags.
    got=$(
        source "${comp_script}"
        COMP_WORDS=(ioc-runner list "")
        COMP_CWORD=2
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}" | grep -cxE '(-v|-vv)' || true
    )
    verify_state "2" "${got}" "'list' command suggests -v and -vv"

    # S7: prefix filter "st<TAB>" narrows to start/stop/status.
    got=$(
        source "${comp_script}"
        COMP_WORDS=(ioc-runner "st")
        COMP_CWORD=1
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}" | grep -cxE '(start|stop|status)' || true
    )
    verify_state "3" "${got}" "'st' prefix narrows to start/stop/status"

    # S8: nonexistent conf dir yields empty completion, not an error.
    got=$(
        source "${comp_script}"
        unset IOC_RUNNER_CONF_DIR
        export IOC_RUNNER_SYSTEM_CONF_DIR="${TEST_TMPDIR}/does_not_exist"
        COMP_WORDS=(ioc-runner start "")
        COMP_CWORD=2
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s" "${#COMPREPLY[@]}"
    )
    verify_state "0" "${got}" "Missing conf_dir yields empty COMPREPLY"
}


function test_validation_errors {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Configuration Validation Errors"
    print_sub_divider

    local exit_code
    local bad_conf="${TEST_TMPDIR}/bad_validation.conf"
    local dummy_dir="${TEST_TMPDIR}/dummy_ioc"
    mkdir -p "${dummy_dir}"

    # 1. Illegal characters check
    cat <<EOF > "${bad_conf}"
IOC_NAME="test"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${dummy_dir}"
IOC_CMD="rm -rf /; echo hacked"
EOF
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local -f install "${bad_conf}")
    verify_exit_code "1" "${exit_code}" "Install with illegal characters in CMD exits 1"

    # 2. Identity mismatch check (Wrong user)
    cat <<EOF > "${bad_conf}"
IOC_NAME="test"
IOC_USER="fake_user_999"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${dummy_dir}"
IOC_CMD="./st.cmd"
EOF
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local -f install "${bad_conf}")
    verify_exit_code "1" "${exit_code}" "Install with wrong local user exits 1"

# 3. Missing execute permission check
    chmod -x "${dummy_dir}"
    cat <<EOF > "${bad_conf}"
IOC_NAME="test"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${dummy_dir}"
IOC_CMD="./st.cmd"
EOF
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local -f install "${bad_conf}")
    verify_exit_code "1" "${exit_code}" "Install without directory execute permission exits 1"
    chmod +x "${dummy_dir}"

    # 4. Missing required key check (IOC_CMD absent)
    cat <<EOF > "${bad_conf}"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${dummy_dir}"
IOC_PORT=""
EOF
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local -f install "${bad_conf}")
    verify_exit_code "1" "${exit_code}" "Install with missing required key (IOC_CMD) exits 1"
}

function test_attach_errors {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Attach Error Paths"
    print_sub_divider

    local exit_code

    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local attach "nonexistent_ioc")
    verify_exit_code "1" "${exit_code}" "'attach' with missing conf exits 1"
}

function test_list_empty {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: List with No Active Sockets"
    print_sub_divider

    local exit_code

    exit_code=$(IOC_RUNNER_RUN_DIR="${TEST_TMPDIR}/empty_run" _run bash "${RUNNER_SCRIPT}" --local list)
    verify_exit_code "0" "${exit_code}" "'list' with no active sockets exits 0"
}

function test_inspect_errors {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Inspect Error Paths"
    print_sub_divider

    local exit_code

    exit_code=$(_run bash "${RUNNER_SCRIPT}" inspect "dummy_ioc")
    verify_exit_code "1" "${exit_code}" "'inspect' without root privileges exits 1"
}


function test_crash_pattern_matching {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Crash Log Pattern Matching"
    print_sub_divider

    # Issue #4: iocsh parser, dynamic linker, and startup path failures
    verify_match "match"   "ERROR st.cmd line 52: Unbalanced quote."             "Pattern: Unbalanced quote"
    verify_match "match"   "Invalid directory path: /opt/ioc/missing"            "Pattern: Invalid directory path"
    verify_match "match"   "Can't open db/example.db"                            "Pattern: Can't open"
    verify_match "match"   "iocsh: cannot open '/etc/protocol/foo.proto'"        "Pattern: cannot open"
    verify_match "match"   "symbol lookup error: undefined symbol: epicsRingNew" "Pattern: undefined symbol"
    verify_match "match"   "/opt/ioc/iocBoot/iocX/st.cmd: No such file or directory" "Pattern: No such file or directory"

    # Issue #5: case-insensitive matching across casing variants
    verify_match "match"   "ERROR: device timeout"                  "Case-insensitive: ERROR (upper)"
    verify_match "match"   "Error: cannot allocate"                 "Case-insensitive: Error (title)"
    verify_match "match"   "error: nullptr deref"                   "Case-insensitive: error (lower)"
    verify_match "match"   "FATAL: aborting"                        "Case-insensitive: FATAL (upper)"
    verify_match "match"   "fatal allocation failure"               "Case-insensitive: fatal (lower)"

    # Regression: pre-existing patterns continue to match
    verify_match "match"   "procServ: Restarting child"             "Regression: Restarting child"
    verify_match "match"   "Segmentation fault (core dumped)"       "Regression: Segmentation fault"

    # Negative: routine startup lines must not trigger crash detection
    verify_match "nomatch" "iocInit: All initialization complete"   "Negative: iocInit complete line"
    verify_match "nomatch" "## EPICS R7.0.7 banner"                 "Negative: EPICS banner"
    verify_match "nomatch" "Starting iocsh.bash"                    "Negative: startup banner"
}



function run_all_tests {
    local -a pipeline=(
        "_setup"
        "test_usage"
        "test_missing_target"
        "test_generate_logic"
        "test_install_logic"
        "test_generate_errors"
        "test_install_errors"
        "test_chdir_precheck"
        "test_ss_failure_aborts_list"
        "test_env_var_namespacing"
        "test_env_var_precedence"
        "test_completion"
        "test_validation_errors"
        "test_attach_errors"
        "test_list_empty"
        "test_inspect_errors"
        "test_crash_pattern_matching"
    )
    local step=1
    local func
    for func in "${pipeline[@]}"; do
        "${func}" "${step}"
        step=$((step + 1))
    done
}

run_all_tests
