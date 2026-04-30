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

function test_git_context_resolution {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify Git Context Resolution for Version Injection"
    print_sub_divider

    # Locate the source repo's bin/ directory relative to this test file.
    local script_dir
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    local repo_bin="${script_dir}/../bin"

    # Baseline: the repo's actual short HEAD obtained via -C.
    local expected_hash
    expected_hash=$(git -C "${repo_bin}" rev-parse --short HEAD 2>/dev/null || printf "unknown")

    # Mimic setup-system-infra.bash: call git -C from an unrelated CWD.
    # Without -C the call would consult /tmp's (non-)git context and fail.
    local resolved_hash
    resolved_hash=$(cd /tmp && git -C "${repo_bin}" rev-parse --short HEAD 2>/dev/null || printf "unknown")

    verify_state "${expected_hash}" "${resolved_hash}" "git -C resolves repo hash from unrelated CWD"
}

function test_setup_script_dir_resolution {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify Setup Script Directory Resolution"
    print_sub_divider

    local script_dir
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    local setup_script="${script_dir}/../bin/setup-system-infra.bash"
    local repo_bin
    repo_bin="$(cd "${script_dir}/../bin" && pwd)"

    if [[ ! -f "${setup_script}" ]]; then
        verify_state "exists" "not_found" "setup-system-infra.bash exists at expected location"
        return
    fi

    # Regression guard: SC_DIR must not be derived via 'readlink -f'.
    # Under NFS root_squash, sudo cannot canonicalize parent directories,
    # so readlink -f silently returns an empty string and SC_DIR falls
    # back to the caller's CWD. STEPS 1-4 do not consume SC_DIR, so the
    # script proceeds to mutate /etc state and only fails at STEP 5,
    # leaving the host partially configured.
    local readlink_in_sc_dir="false"
    if grep -qE '^[[:space:]]*SC_DIR=.*readlink[[:space:]]+-f' "${setup_script}"; then
        readlink_in_sc_dir="true"
    fi
    verify_state "false" "${readlink_in_sc_dir}" "SC_DIR resolution does not depend on 'readlink -f'"

    # Behavioral: replicate the script's SC_DIR strategy
    # ('dirname "${BASH_SOURCE[0]}"') across plausible invocation forms
    # and confirm the resolved directory locates the sibling ioc-runner.
    # For a directly invoked (non-sourced) script, $0 equals BASH_SOURCE[0].
    local probe='sc_dir="$(dirname "$0")"; [[ -f "${sc_dir}/ioc-runner" ]] && printf found || printf missing'

    local check_a
    check_a=$(cd "${repo_bin}/.." && bash -c "${probe}" "bin/setup-system-infra.bash")
    verify_state "found" "${check_a}" "SC_DIR locates ioc-runner when invoked as bin/... from repo root"

    local check_b
    check_b=$(cd "${repo_bin}" && bash -c "${probe}" "./setup-system-infra.bash")
    verify_state "found" "${check_b}" "SC_DIR locates ioc-runner when invoked as ./... from bin/"

    local check_c
    check_c=$(cd /tmp && bash -c "${probe}" "${repo_bin}/setup-system-infra.bash")
    verify_state "found" "${check_c}" "SC_DIR locates ioc-runner when invoked via absolute path from unrelated CWD"
}

function test_setup_version_injection_guards {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify Setup Version Injection Guards"
    print_sub_divider

    local script_dir
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    local setup_script="${script_dir}/../bin/setup-system-infra.bash"

    if [[ ! -f "${setup_script}" ]]; then
        verify_state "exists" "not_found" "setup-system-infra.bash exists at expected location"
        return
    fi

    # Regression guard: version-injection block must drop privileges to
    # the invoking user (SUDO_USER) when running under sudo. safe.directory
    # does not help on NFS root_squash mounts where root cannot even stat
    # the work tree (failure precedes git's ownership check). Tracked as #42.
    local sudo_user_ref="false"
    if grep -qE 'SUDO_USER' "${setup_script}"; then
        sudo_user_ref="true"
    fi
    verify_state "true" "${sudo_user_ref}" "version injection references SUDO_USER for privilege drop"

    local sudo_u_drop="false"
    if grep -qE 'sudo[[:space:]]+-u[[:space:]]' "${setup_script}"; then
        sudo_u_drop="true"
    fi
    verify_state "true" "${sudo_u_drop}" "version injection uses sudo -u for privilege drop"

    # Regression guard: the dirty marker must be gated on a real hash so a
    # failed diff-index does not yield 'unknown-dirty'. Tracked as #42.
    local unknown_guard="false"
    if grep -qE '\[\[[[:space:]]*"\$\{current_git_hash\}"[[:space:]]*!=[[:space:]]*"unknown"' "${setup_script}"; then
        unknown_guard="true"
    fi
    verify_state "true" "${unknown_guard}" "dirty marker is gated on non-unknown current_git_hash"
}

function test_metadata_field_naming {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify Version Metadata Field Naming"
    print_sub_divider

    local script_dir
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    local runner_script="${script_dir}/../bin/ioc-runner"
    local setup_script="${script_dir}/../bin/setup-system-infra.bash"

    if [[ ! -f "${runner_script}" ]] || [[ ! -f "${setup_script}" ]]; then
        verify_state "exists" "not_found" "ioc-runner and setup-system-infra.bash exist at expected locations"
        return
    fi

    # Regression guard: ioc-runner must declare the renamed metadata
    # fields. The legacy RUNNER_BUILD_DATE is dropped because its value
    # was the install moment, not the commit moment. Tracked as #43.
    local commit_decl="false"
    if grep -qE '^declare -g RUNNER_COMMIT_DATE=' "${runner_script}"; then
        commit_decl="true"
    fi
    verify_state "true" "${commit_decl}" "ioc-runner declares RUNNER_COMMIT_DATE"

    local install_decl="false"
    if grep -qE '^declare -g RUNNER_INSTALL_DATE=' "${runner_script}"; then
        install_decl="true"
    fi
    verify_state "true" "${install_decl}" "ioc-runner declares RUNNER_INSTALL_DATE"

    # Negative guard: no residue of the deprecated RUNNER_BUILD_DATE
    # name in either source. A sed line in setup-system-infra.bash that
    # still targets RUNNER_BUILD_DATE would silently no-op against the
    # renamed declaration and leave install date as 'unreleased'.
    local build_residue="false"
    if grep -qE 'RUNNER_BUILD_DATE|build date:' "${runner_script}" "${setup_script}"; then
        build_residue="true"
    fi
    verify_state "false" "${build_residue}" "no RUNNER_BUILD_DATE or build date label residue in source"

    # Regression guard: setup-system-infra.bash must inject both new
    # fields via sed; otherwise the deployed CLI keeps 'unreleased'
    # placeholders.
    local commit_inject="false"
    if grep -qE 'sed.*RUNNER_COMMIT_DATE' "${setup_script}"; then
        commit_inject="true"
    fi
    verify_state "true" "${commit_inject}" "setup-system-infra.bash injects RUNNER_COMMIT_DATE via sed"

    local install_inject="false"
    if grep -qE 'sed.*RUNNER_INSTALL_DATE' "${setup_script}"; then
        install_inject="true"
    fi
    verify_state "true" "${install_inject}" "setup-system-infra.bash injects RUNNER_INSTALL_DATE via sed"
}

function test_runner_version_path_resolution {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify Runner -V Live-Hash Path Resolution"
    print_sub_divider

    local script_dir
    script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
    local runner_script="${script_dir}/../bin/ioc-runner"

    if [[ ! -f "${runner_script}" ]]; then
        verify_state "exists" "not_found" "ioc-runner exists at expected location"
        return
    fi

    # Regression guard: the -V live-hash branch must not derive script_dir
    # via 'readlink -f'. realpath silently returns empty under NFS
    # root_squash + sudo, falling back to '.' (caller's CWD), which then
    # makes 'git -C "."' fail and the live-hash output regress to
    # 'unknown'. Same assumption as #38; tracked as #39.
    local readlink_in_v_handler="false"
    if grep -qE '^[[:space:]]*script_dir=.*readlink[[:space:]]+-f' "${runner_script}"; then
        readlink_in_v_handler="true"
    fi
    verify_state "false" "${readlink_in_v_handler}" "ioc-runner -V handler does not derive script_dir via 'readlink -f'"
}

function run_all_tests {
    local -a pipeline=(
        "test_service_accounts"
        "test_infrastructure_files"
        "test_sudoers_syntax"
        "test_sudoers_includedir_order"
        "test_git_context_resolution"
        "test_setup_script_dir_resolution"
        "test_setup_version_injection_guards"
        "test_metadata_field_naming"
        "test_runner_version_path_resolution"
    )
    local step=1
    local func
    for func in "${pipeline[@]}"; do
        "${func}" "${step}"
        step=$((step + 1))
    done
}

run_all_tests
