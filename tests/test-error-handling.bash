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
    "${cmd[@]}" >/dev/null 2>&1; local exit_code=$?; true
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

function test_install_errors {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Install Error Paths"
    print_sub_divider

    local exit_code
    local fake_conf="${TEST_TMPDIR}/test.conf"
    printf "IOC_NAME=test\n" > "${fake_conf}"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local install "${TEST_TMPDIR}/nonexistent.conf")
    verify_exit_code "1" "${exit_code}" "'install' with missing conf file exits 1"

    exit_code=$(IOC_RUNNER_SYSTEMD_DIR="${TEST_TMPDIR}" _run bash "${RUNNER_SCRIPT}" install "${fake_conf}")
    verify_exit_code "1" "${exit_code}" "'install' with missing system template exits 1"
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
IOC_CMD="rm -rf /"
EOF
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local install "${bad_conf}")
    verify_exit_code "1" "${exit_code}" "Install with illegal characters in CMD exits 1"

    # 2. Identity mismatch check (Wrong user)
    cat <<EOF > "${bad_conf}"
IOC_NAME="test"
IOC_USER="fake_user_999"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${dummy_dir}"
IOC_CMD="./st.cmd"
EOF
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local install "${bad_conf}")
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
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local install "${bad_conf}")
    verify_exit_code "1" "${exit_code}" "Install without directory execute permission exits 1"
    chmod +x "${dummy_dir}" # Restore for cleanup
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

function run_all_tests {
    _setup                  1
    test_usage              2
    test_missing_target     3
    test_install_errors     4
    test_validation_errors  5
    test_attach_errors      6
    test_list_empty         7
}

run_all_tests
