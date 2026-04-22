#!/usr/bin/env bash
#
# Integration tests for system infrastructure.
# Validates the installed system components without modifying them.

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

declare -g SYSTEM_USER="ioc-srv"
declare -g SYSTEM_GROUP="ioc"
declare -g CONF_DIR="/etc/procServ.d"
declare -g SUDOERS_FILE="/etc/sudoers.d/10-epics-ioc"
declare -g SYSTEMD_TEMPLATE="/etc/systemd/system/epics-@.service"
declare -g RUNNER_SCRIPT_DEST="/usr/local/bin/ioc-runner"
declare -g BASH_COMPLETION_DEST="/etc/bash_completion.d/ioc-runner"

declare -g PERM_CONF_DIR="2770"
declare -g PERM_SUDOERS="0440"
declare -g PERM_SYSTEMD_TEMPLATE="0644"
declare -g PERM_RUNNER_SCRIPT="0755"
declare -g PERM_BASH_COMPLETION="0644"

declare -g OWNER_CONF_DIR="root:${SYSTEM_GROUP}"
declare -g OWNER_SYSTEM="root:root"

if [[ $EUID -ne 0 ]]; then
    printf "${RED}%s${NC}\n" "Error: This script must be run as root (or via sudo)." >&2
    printf "%s\n" "Usage: sudo bash $(basename "$0")" >&2
    exit 1
fi

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        SCRIPT_ERROR=1
        printf "\n${RED}%s${NC}\n" "[ABORT] Script terminated unexpectedly. (Exit code: ${exit_code})"
    fi
    print_summary
}
trap _handle_exit EXIT
trap 'exit 1' SIGINT

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
    print_divider
    printf "${BLUE}%s${NC}\n" "                                  SYSTEM INFRA TEST SUMMARY                                         "
    print_divider

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

function verify_perm {
    local path="$1"
    local expected_owner="$2"
    local expected_perm="$3"

    if [[ ! -e "${path}" ]]; then
        verify_state "exists" "not_found" "File or directory exists: ${path}"
        return
    fi

    local actual_owner
    local actual_perm

    actual_owner=$(stat -c "%U:%G" "${path}")
    actual_perm=$(stat -c "%a" "${path}")

    expected_perm=$(printf "%04o" "0${expected_perm}")
    actual_perm=$(printf "%04o" "0${actual_perm}")

    verify_state "${expected_owner}" "${actual_owner}" "Owner of ${path} is ${expected_owner}"
    verify_state "${expected_perm}"  "${actual_perm}"  "Permission of ${path} is ${expected_perm}"
}

function test_service_accounts {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify Service Accounts and Groups"
    print_sub_divider

    local group_exists="false"
    local user_exists="false"
    if getent group "${SYSTEM_GROUP}" >/dev/null; then group_exists="true"; fi
    if id -u "${SYSTEM_USER}" >/dev/null 2>&1; then user_exists="true"; fi

    verify_state "true" "${group_exists}" "Group '${SYSTEM_GROUP}' exists"
    verify_state "true" "${user_exists}"  "User '${SYSTEM_USER}' exists"
}

function test_infrastructure_files {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify Infrastructure Files and Permissions"
    print_sub_divider

    verify_perm "${CONF_DIR}"             "${OWNER_CONF_DIR}" "${PERM_CONF_DIR}"
    verify_perm "${SUDOERS_FILE}"         "${OWNER_SYSTEM}"   "${PERM_SUDOERS}"
    verify_perm "${SYSTEMD_TEMPLATE}"     "${OWNER_SYSTEM}"   "${PERM_SYSTEMD_TEMPLATE}"
    verify_perm "${RUNNER_SCRIPT_DEST}"   "${OWNER_SYSTEM}"   "${PERM_RUNNER_SCRIPT}"
    verify_perm "${BASH_COMPLETION_DEST}" "${OWNER_SYSTEM}"   "${PERM_BASH_COMPLETION}"
}

function test_sudoers_syntax {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify Sudoers Policy Syntax"
    print_sub_divider

    local syntax_ok="false"
    if [[ -f "${SUDOERS_FILE}" ]] && visudo -cf "${SUDOERS_FILE}" >/dev/null 2>&1; then
        syntax_ok="true"
    fi
    verify_state "true" "${syntax_ok}" "Sudoers file syntax is valid"
}

function test_sudoers_includedir_order {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify Sudoers Include Directive Ordering"
    print_sub_divider

    local main_sudoers="/etc/sudoers"
    local idr_line
    local trailing
    local ordering_ok="false"

    idr_line=$(grep -nE '^[[:space:]]*[#@]includedir[[:space:]]+/etc/sudoers\.d' "${main_sudoers}" | tail -1 | cut -d: -f1)

    if [[ -z "${idr_line}" ]]; then
        verify_state "true" "false" "includedir directive exists in ${main_sudoers}"
        return
    fi

    trailing=$(tail -n +$((idr_line + 1)) "${main_sudoers}" | grep -E '^[[:space:]]*([^#[:space:]]|[#@]include)' || true)

    if [[ -z "${trailing}" ]]; then
        ordering_ok="true"
    else
        _log "ERROR" "Active rules follow the includedir directive in ${main_sudoers}."
        _log "ERROR" "Drop-in policies (e.g. ${SUDOERS_FILE}) will be overridden."
        _log "ERROR" "Move the includedir directive to the END of ${main_sudoers} using visudo."
        printf "%s\n" "${trailing}" | while IFS= read -r line; do
            _log "ERROR" "  offending: ${line}"
        done
    fi

    verify_state "true" "${ordering_ok}" "includedir is the final active directive in ${main_sudoers}"
}

function run_all_tests {
    local -a pipeline=(
        "test_service_accounts"
        "test_infrastructure_files"
        "test_sudoers_syntax"
        "test_sudoers_includedir_order"
    )
    local step=1
    local func
    for func in "${pipeline[@]}"; do
        "${func}" "${step}"
        step=$((step + 1))
    done
}

run_all_tests
