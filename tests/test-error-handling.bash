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
        verify_exit_code "0" "${exit_code}" "Differential artifact prompts user and exits gracefully"
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

function run_all_tests {
    local -a pipeline=(
        "_setup"
        "test_usage"
        "test_missing_target"
        "test_generate_logic"
        "test_install_logic"
        "test_generate_errors"
        "test_install_errors"
        "test_validation_errors"
        "test_attach_errors"
        "test_list_empty"
        "test_inspect_errors"
    )
    local step=1
    local func
    for func in "${pipeline[@]}"; do
        "${func}" "${step}"
        step=$((step + 1))
    done
}

run_all_tests
