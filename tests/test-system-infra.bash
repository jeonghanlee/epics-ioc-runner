#!/usr/bin/env bash
#
# Integration tests for setup-system-infra.bash.
# Tests non-root rejection as a normal user.
# All remaining tests require root privileges and are intended for CI via sudo.

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

declare -g INFRA_SCRIPT="${SC_TOP}/../bin/setup-system-infra.bash"

declare -g SYSTEM_USER="ioc-srv"
declare -g SYSTEM_GROUP="ioc"
declare -g CONF_DIR="/etc/procServ.d"
declare -g SUDOERS_FILE="/etc/sudoers.d/10-epics-ioc"
declare -g SYSTEMD_TEMPLATE="/etc/systemd/system/epics-@.service"
declare -g RUNNER_SCRIPT_DEST="/usr/local/bin/ioc-runner"
declare -g BACKUP_DIR="/var/backups/epics-ioc-runner"

declare -g TEST_TMPDIR


if [[ $EUID -ne 0 ]]; then
    printf "${RED}%s${NC}\n" "Error: This script must be run as root (or via sudo)." >&2
    printf "%s\n" "Usage: sudo bash $(basename "$0")" >&2
    exit 1
fi


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
    printf "${BLUE}%s${NC}\n" "                                  SYSTEM INFRA TEST SUMMARY                                        "
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
        printf "\n${GREEN}%s${NC}\n" "[SUCCESS] All system infra tests completed perfectly!"
    fi

    printf "${BLUE}%s${NC}\n\n" "===================================================================================================="
}

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
    "${cmd[@]}" >/dev/null 2>&1; local exit_code=$?; true
    printf "%d" "${exit_code}"
}

# Runs a script as root via sudo with the given KEY=VALUE environment variables
# written to a temporary file and sourced inside the sudo shell.
function _run_as_root {
    local tmp_env
    tmp_env=$(mktemp)

    local key value
    while [[ $# -gt 0 && "$1" == *"="* ]]; do
        key="${1%%=*}"
        value="${1#*=}"
        printf "export %s='%s'\n" "${key}" "${value}" >> "${tmp_env}"
        shift
    done

    local cmd=("$@")
    sudo bash -c "source '${tmp_env}' && bash ${cmd[*]}" >/dev/null 2>&1; local exit_code=$?; true
    rm -f "${tmp_env}"
    printf "%d" "${exit_code}"
}

function verify_perm {
    local path="$1"
    local expected_owner="$2"
    local expected_perm="$3"

    local actual_owner
    local actual_perm

    actual_owner=$(stat -c "%U:%G" "${path}")
    actual_perm=$(stat -c "%a" "${path}")

    # Normalize to 4-digit octal for comparison
    expected_perm=$(printf "%04o" "0${expected_perm}")
    actual_perm=$(printf "%04o" "0${actual_perm}")

    verify_state "${expected_owner}" "${actual_owner}" "Owner of ${path} is ${expected_owner}"
    verify_state "${expected_perm}"  "${actual_perm}"  "Permission of ${path} is ${expected_perm}"
}

# ==============================================================================
# Setup & Teardown
# ==============================================================================

function _setup {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Setup Test Environment"
    print_sub_divider

    TEST_TMPDIR=$(mktemp -d)

    # Create a mock ioc-runner source script.
    printf "#!/usr/bin/env bash\n" > "${TEST_TMPDIR}/ioc-runner"
    chmod +x "${TEST_TMPDIR}/ioc-runner"

    _log "SUCCESS" "Test environment ready at ${TEST_TMPDIR}"
}

function _cleanup {
    if [[ -d "${TEST_TMPDIR}" ]]; then
        rm -rf "${TEST_TMPDIR}"
    fi
}

# ==============================================================================
# Test Steps
# ==============================================================================

function test_non_root_rejection {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Non-root Rejection"
    print_sub_divider

    local exit_code
    local current_user="${SUDO_USER:-$(id -un)}"
    exit_code=$(_run sudo -u "${current_user}" bash "${INFRA_SCRIPT}")
    verify_exit_code "1" "${exit_code}" "Execution as non-root user exits 1"
}

function test_missing_procserv {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Missing procServ Error Path"
    print_sub_divider

    local exit_code
    exit_code=$(_run_as_root \
        "IOC_RUNNER_PROCSERV_PATH=${TEST_TMPDIR}/nonexistent" \
        "IOC_RUNNER_SCRIPT_SRC=${TEST_TMPDIR}/ioc-runner" \
        "${INFRA_SCRIPT}")
    verify_exit_code "1" "${exit_code}" "Missing procServ exits 1"
}

function test_missing_runner_script {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Missing ioc-runner Source Error Path"
    print_sub_divider

    local exit_code
    exit_code=$(_run_as_root \
        "IOC_RUNNER_SCRIPT_SRC=${TEST_TMPDIR}/nonexistent" \
        "${INFRA_SCRIPT}")
    verify_exit_code "1" "${exit_code}" "Missing ioc-runner source exits 1"
}

function test_successful_install {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Successful Installation"
    print_sub_divider

    local exit_code
    exit_code=$(_run_as_root \
        "IOC_RUNNER_SCRIPT_SRC=${TEST_TMPDIR}/ioc-runner" \
        "${INFRA_SCRIPT}")
    verify_exit_code "0" "${exit_code}" "Successful installation exits 0"

    # Verify group and user
    local group_exists="false"
    local user_exists="false"
    if getent group "${SYSTEM_GROUP}" >/dev/null; then group_exists="true"; fi
    if id -u "${SYSTEM_USER}" >/dev/null 2>&1; then user_exists="true"; fi

    verify_state "true" "${group_exists}" "Group '${SYSTEM_GROUP}' exists"
    verify_state "true" "${user_exists}"  "User '${SYSTEM_USER}' exists"

    # Verify deployed files and permissions
    verify_perm "${CONF_DIR}"           "root:${SYSTEM_GROUP}" "2770"
    verify_perm "${SUDOERS_FILE}"       "root:root"            "0440"
    verify_perm "${SYSTEMD_TEMPLATE}"   "root:root"            "0644"
    verify_perm "${RUNNER_SCRIPT_DEST}" "root:root"            "0755"
        
}

function test_idempotency {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Idempotency (Second Run)"
    print_sub_divider

    local exit_code
    exit_code=$(_run_as_root \
        "IOC_RUNNER_SCRIPT_SRC=${TEST_TMPDIR}/ioc-runner" \
        "${INFRA_SCRIPT}")
    verify_exit_code "0" "${exit_code}" "Second run exits 0"

    # Verify no duplicate group or user entries
    local group_count user_count
    group_count=$(getent group "${SYSTEM_GROUP}" | wc -l)
    user_count=$(getent passwd "${SYSTEM_USER}" | wc -l)

    verify_state "1" "${group_count}" "Group '${SYSTEM_GROUP}' has no duplicates"
    verify_state "1" "${user_count}"  "User '${SYSTEM_USER}' has no duplicates"

    # Verify single file instances
    local conf_count sudoers_count template_count runner_count
    conf_count=$(find "${CONF_DIR}"           -maxdepth 0 | wc -l)
    sudoers_count=$(find "${SUDOERS_FILE}"     -maxdepth 0 | wc -l)
    template_count=$(find "${SYSTEMD_TEMPLATE}" -maxdepth 0 | wc -l)
    runner_count=$(find "${RUNNER_SCRIPT_DEST}" -maxdepth 0 | wc -l)

    verify_state "1" "${conf_count}"     "No duplicate ${CONF_DIR}"
    verify_state "1" "${sudoers_count}"  "No duplicate ${SUDOERS_FILE}"
    verify_state "1" "${template_count}" "No duplicate ${SYSTEMD_TEMPLATE}"
    verify_state "1" "${runner_count}"   "No duplicate ${RUNNER_SCRIPT_DEST}"
}

function test_backup_rotation {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Backup Rotation (Keeps 3 Most Recent)"
    print_sub_divider

    # Run the script multiple times to trigger backup rotation.
    local i
    for i in $(seq 1 5); do
        _log "INFO" "Running iteration ${i}/5 to trigger backup rotation..."
        local ignored
        ignored=$(_run_as_root \
            "IOC_RUNNER_SCRIPT_SRC=${TEST_TMPDIR}/ioc-runner" \
            "${INFRA_SCRIPT}")
        sleep 1
    done

    local sudoers_bak_count template_bak_count runner_bak_count
    sudoers_bak_count=$(find "${BACKUP_DIR}" -maxdepth 1 -name "$(basename "${SUDOERS_FILE}").*.bak"      | wc -l)
    template_bak_count=$(find "${BACKUP_DIR}" -maxdepth 1 -name "$(basename "${SYSTEMD_TEMPLATE}").*.bak" | wc -l)
    runner_bak_count=$(find "${BACKUP_DIR}"   -maxdepth 1 -name "$(basename "${RUNNER_SCRIPT_DEST}").*.bak" | wc -l)

    verify_state "true" "$([[ ${sudoers_bak_count}  -le 3 ]] && printf 'true' || printf 'false')" \
        "Sudoers backups kept at most 3 (found: ${sudoers_bak_count})"
    verify_state "true" "$([[ ${template_bak_count} -le 3 ]] && printf 'true' || printf 'false')" \
        "Template backups kept at most 3 (found: ${template_bak_count})"
    verify_state "true" "$([[ ${runner_bak_count}   -le 3 ]] && printf 'true' || printf 'false')" \
        "Runner backups kept at most 3 (found: ${runner_bak_count})"
}

function run_all_tests {
    _setup                    1
    test_non_root_rejection   2
    test_missing_procserv     3
    test_missing_runner_script 4
    test_successful_install   5
    test_idempotency          6
    test_backup_rotation      7
}

run_all_tests
