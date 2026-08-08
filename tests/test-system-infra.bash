#!/usr/bin/env bash
#
# Integration tests for system infrastructure.
# Validates the installed system components without modifying them.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
umask 077
unset BASH_ENV ENV CDPATH GIT_DIR GIT_WORK_TREE

declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g BLUE='\033[0;34m'
declare -g YELLOW='\033[0;33m'
declare -g NC='\033[0m'

declare -gr SUITE_ID="system-infra"
declare -gr SUITE_SCOPE="system"
declare -gr SUITE_RUNNER="none"
declare -gr SUITE_CATEGORY="installed-conformance"
declare -g SC_PATH="${BASH_SOURCE[0]}"
declare -g SC_TOP=""
declare -g REPORT_DIR=""
declare -g REPORT_READY=0
declare -g SUDOERS_EXISTS=0
declare -g LOGROTATE_EXISTS=0
declare -g -a SYSTEM_INFRA_CHECK_IDS=()

if [[ "${SC_PATH}" != /* ]]; then
    SC_PATH="${PWD}/${SC_PATH}"
fi
SC_TOP="${SC_PATH%/*}"
# shellcheck source=lib/test-reporting.bash
source "${SC_TOP}/lib/test-reporting.bash"

# Set by the regex-deny probe when it creates an ephemeral ioc-group
# member; cleared after the normal cleanup path. A pre-existing account
# with the same name is reused without deletion, so this stays empty.
declare -g C57_CREATED_USER=""

declare -g SYSTEM_USER="ioc-srv"
declare -g SYSTEM_GROUP="ioc"
declare -g CONF_DIR="/etc/procServ.d"
declare -g SUDOERS_FILE="/etc/sudoers.d/10-epics-ioc"
declare -g SYSTEMD_TEMPLATE="/etc/systemd/system/epics-@.service"
declare -g LOGROTATE_FILE="/etc/logrotate.d/procserv"
declare -g SYSTEM_LOG_DIR="${IOC_RUNNER_SYSTEM_LOG_DIR:-/var/log/procserv}"
declare -g RUNNER_SCRIPT_DEST="/usr/local/bin/ioc-runner"
declare -g BASH_COMPLETION_DEST="/etc/bash_completion.d/ioc-runner"

declare -g PERM_CONF_DIR="2770"
declare -g PERM_SUDOERS="0440"
declare -g PERM_SYSTEMD_TEMPLATE="0644"
declare -g PERM_LOGROTATE="0644"
declare -g PERM_RUNNER_SCRIPT="0755"
declare -g PERM_BASH_COMPLETION="0644"

declare -g OWNER_CONF_DIR="root:${SYSTEM_GROUP}"
declare -g OWNER_SYSTEM="root:root"

function _handle_exit {
    local exit_code=$?
    local final_status="${exit_code}"

    trap - EXIT
    if [[ -n "${C57_CREATED_USER:-}" ]]; then
        userdel "${C57_CREATED_USER}" 2>/dev/null || true
        C57_CREATED_USER=""
    fi
    if (( REPORT_READY )); then
        report_finalize "${exit_code}" || final_status=1
    fi
    if [[ -n "${REPORT_DIR}" && "${REPORT_DIR}" == /tmp/ioc-runner-system-infra-report.* &&
          -d "${REPORT_DIR}" && ! -L "${REPORT_DIR}" ]]; then
        "${REPORT_RM_BIN:-/bin/rm}" -rf -- "${REPORT_DIR}" || final_status=1
    fi
    exit "${final_status}"
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

function verify_state {
    local expected="$1"
    local actual="$2"
    local check_id="$3"
    local reason=""

    if [[ "${expected}" == "${actual}" ]]; then
        printf "${GREEN}[ PASS ]${NC} %s\n" "${check_id}"
        report_record "${check_id}" PASS
    else
        printf "${RED}[ FAIL ]${NC} %s\n" "${check_id}" >&2
        printf "  ${YELLOW}Expected : %s${NC}\n" "${expected}" >&2
        printf "  ${YELLOW}Actual   : %s${NC}\n" "${actual}" >&2
        reason="expected ${expected}, actual ${actual}"
        report_record "${check_id}" FAIL "${reason}"
    fi
}

function register_catalog_check {
    local check_id="$1"
    local step_id="$2"
    local check_kind="$3"
    local test_method="$4"
    local description="$5"

    report_register_check "${check_id}" "${step_id}" "${SUITE_CATEGORY}" \
        "${check_kind}" "${test_method}" "${description}"
    SYSTEM_INFRA_CHECK_IDS+=("${check_id}")
}

function register_reporting_catalog {
    report_register_step P00 "Verify invocation boundary"
    report_register_step S01 "Verify service accounts and groups"
    report_register_step S02 "Verify installed files and permissions"
    report_register_step S03 "Verify sudoers policy syntax"
    report_register_step S04 "Verify logrotate policy"
    report_register_step S05 "Verify sudoers include directive ordering"
    report_register_step S06 "Verify anchored sudoers authorization"

    register_catalog_check "${SUITE_ID}.P00.root-required" P00 REQUIRED direct-inspection "Effective user is root."
    register_catalog_check "${SUITE_ID}.S01.ioc-group-exists" S01 BEHAVIOR direct-inspection "System group ioc exists."
    register_catalog_check "${SUITE_ID}.S01.ioc-service-user-exists" S01 BEHAVIOR direct-inspection "System user ioc-srv exists."
    register_catalog_check "${SUITE_ID}.S02.conf-dir.exists" S02 REQUIRED direct-inspection "/etc/procServ.d exists."
    register_catalog_check "${SUITE_ID}.S02.conf-dir.owner" S02 BEHAVIOR direct-inspection "Configuration directory owner is root:ioc."
    register_catalog_check "${SUITE_ID}.S02.conf-dir.permission" S02 BEHAVIOR direct-inspection "Configuration directory permission is 2770."
    register_catalog_check "${SUITE_ID}.S02.sudoers-policy.exists" S02 REQUIRED direct-inspection "Sudoers policy exists."
    register_catalog_check "${SUITE_ID}.S02.sudoers-policy.owner" S02 BEHAVIOR direct-inspection "Sudoers policy owner is root:root."
    register_catalog_check "${SUITE_ID}.S02.sudoers-policy.permission" S02 BEHAVIOR direct-inspection "Sudoers policy permission is 0440."
    register_catalog_check "${SUITE_ID}.S02.systemd-template.exists" S02 REQUIRED direct-inspection "Systemd template exists."
    register_catalog_check "${SUITE_ID}.S02.systemd-template.owner" S02 BEHAVIOR direct-inspection "Systemd template owner is root:root."
    register_catalog_check "${SUITE_ID}.S02.systemd-template.permission" S02 BEHAVIOR direct-inspection "Systemd template permission is 0644."
    register_catalog_check "${SUITE_ID}.S02.logrotate-policy.exists" S02 REQUIRED direct-inspection "Logrotate policy exists."
    register_catalog_check "${SUITE_ID}.S02.logrotate-policy.owner" S02 BEHAVIOR direct-inspection "Logrotate policy owner is root:root."
    register_catalog_check "${SUITE_ID}.S02.logrotate-policy.permission" S02 BEHAVIOR direct-inspection "Logrotate policy permission is 0644."
    register_catalog_check "${SUITE_ID}.S02.installed-runner.exists" S02 REQUIRED direct-inspection "Installed runner exists."
    register_catalog_check "${SUITE_ID}.S02.installed-runner.owner" S02 BEHAVIOR direct-inspection "Installed runner owner is root:root."
    register_catalog_check "${SUITE_ID}.S02.installed-runner.permission" S02 BEHAVIOR direct-inspection "Installed runner permission is 0755."
    register_catalog_check "${SUITE_ID}.S02.bash-completion.exists" S02 REQUIRED direct-inspection "Bash completion exists."
    register_catalog_check "${SUITE_ID}.S02.bash-completion.owner" S02 BEHAVIOR direct-inspection "Bash completion owner is root:root."
    register_catalog_check "${SUITE_ID}.S02.bash-completion.permission" S02 BEHAVIOR direct-inspection "Bash completion permission is 0644."
    register_catalog_check "${SUITE_ID}.S03.sudoers-syntax-valid" S03 BEHAVIOR real-path "Deployed sudoers policy passes visudo validation."
    register_catalog_check "${SUITE_ID}.S04.logrotate-syntax-valid" S04 BEHAVIOR real-path "Deployed logrotate policy passes debug validation."
    register_catalog_check "${SUITE_ID}.S04.log-glob-pinned" S04 BEHAVIOR direct-inspection "Policy contains the configured log directory glob."
    register_catalog_check "${SUITE_ID}.S04.su-directive-pinned" S04 BEHAVIOR direct-inspection "Policy contains su root ioc."
    register_catalog_check "${SUITE_ID}.S04.copytruncate-pinned" S04 BEHAVIOR direct-inspection "Policy contains copytruncate."
    register_catalog_check "${SUITE_ID}.S04.compress-pinned" S04 BEHAVIOR direct-inspection "Policy contains compress."
    register_catalog_check "${SUITE_ID}.S04.weekly-pinned" S04 BEHAVIOR direct-inspection "Policy contains weekly."
    register_catalog_check "${SUITE_ID}.S04.rotate-eight-pinned" S04 BEHAVIOR direct-inspection "Policy contains rotate 8."
    register_catalog_check "${SUITE_ID}.S04.nodateext-pinned" S04 BEHAVIOR direct-inspection "Policy contains nodateext."
    register_catalog_check "${SUITE_ID}.S05.include-directive-exists" S05 REQUIRED direct-inspection "Main sudoers policy contains the sudoers.d include directive."
    register_catalog_check "${SUITE_ID}.S05.include-directive-final" S05 BEHAVIOR direct-inspection "No active rule follows the include directive."
    register_catalog_check "${SUITE_ID}.S06.regex-policy-applicable" S06 APPLICABILITY direct-inspection "Deployed sudoers policy uses anchored regex commands."
    register_catalog_check "${SUITE_ID}.S06.probe-user-available" S06 PREREQUISITE direct-inspection "A safe ioc-group probe user is available."
    register_catalog_check "${SUITE_ID}.S06.bad-name-denied" S06 BEHAVIOR real-path "Anchored policy denies an out-of-model service name."
    register_catalog_check "${SUITE_ID}.S06.good-name-allowed" S06 BEHAVIOR real-path "Anchored policy allows a valid service name."
    report_close_catalog
}

function read_os_release_value {
    local wanted="$1"
    local key=""
    local value=""

    while IFS='=' read -r key value || [[ -n "${key:-}" ]]; do
        if [[ "${key}" == "${wanted}" ]]; then
            value="${value#\"}"
            value="${value%\"}"
            printf '%s' "${value}"
            return 0
        fi
    done < /etc/os-release
    return 1
}

function initialize_reporting {
    local os_name="unknown"
    local os_version="0"
    local os_id=""
    local arch_id="${EPICS_HOST_ARCH:-unknown}"
    local run_id="${SUITE_ID}.$$.${BASHPID}"

    if [[ -r /etc/os-release ]]; then
        os_name=$(read_os_release_value ID || true)
        os_version=$(read_os_release_value VERSION_ID || true)
    fi
    os_name="${os_name:-unknown}"
    os_version="${os_version%%.*}"
    os_version="${os_version:-0}"
    os_id="${os_name}-${os_version}"
    REPORT_DIR=$(mktemp -d /tmp/ioc-runner-system-infra-report.XXXXXX)
    report_init "${SUITE_ID}" "${run_id}" "${SUITE_SCOPE}" "${SUITE_RUNNER}" \
        "${os_id}" "${arch_id}" "${REPORT_DIR}"
    REPORT_READY=1
    register_reporting_catalog
}

function close_after_root_failure {
    local check_id=""

    for check_id in "${SYSTEM_INFRA_CHECK_IDS[@]:1}"; do
        report_record "${check_id}" SKIP "requires ${SUITE_ID}.P00.root-required"
    done
}

function verify_perm {
    local path="$1"
    local expected_owner="$2"
    local expected_perm="$3"
    local check_prefix="$4"
    local actual_owner=""
    local actual_perm=""

    if [[ ! -e "${path}" ]]; then
        verify_state "exists" "not_found" "${check_prefix}.exists"
        report_record "${check_prefix}.owner" SKIP "requires ${check_prefix}.exists"
        report_record "${check_prefix}.permission" SKIP "requires ${check_prefix}.exists"
        return
    fi

    verify_state "exists" "exists" "${check_prefix}.exists"
    actual_owner=$(stat -c "%U:%G" "${path}")
    actual_perm=$(stat -c "%a" "${path}")

    expected_perm=$(printf "%04o" "0${expected_perm}")
    actual_perm=$(printf "%04o" "0${actual_perm}")

    verify_state "${expected_owner}" "${actual_owner}" "${check_prefix}.owner"
    verify_state "${expected_perm}" "${actual_perm}" "${check_prefix}.permission"
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

    verify_state "true" "${group_exists}" "${SUITE_ID}.S01.ioc-group-exists"
    verify_state "true" "${user_exists}" "${SUITE_ID}.S01.ioc-service-user-exists"
}

function test_infrastructure_files {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify Infrastructure Files and Permissions"
    print_sub_divider

    verify_perm "${CONF_DIR}" "${OWNER_CONF_DIR}" "${PERM_CONF_DIR}" "${SUITE_ID}.S02.conf-dir"
    verify_perm "${SUDOERS_FILE}" "${OWNER_SYSTEM}" "${PERM_SUDOERS}" "${SUITE_ID}.S02.sudoers-policy"
    verify_perm "${SYSTEMD_TEMPLATE}" "${OWNER_SYSTEM}" "${PERM_SYSTEMD_TEMPLATE}" \
        "${SUITE_ID}.S02.systemd-template"
    verify_perm "${LOGROTATE_FILE}" "${OWNER_SYSTEM}" "${PERM_LOGROTATE}" \
        "${SUITE_ID}.S02.logrotate-policy"
    verify_perm "${RUNNER_SCRIPT_DEST}" "${OWNER_SYSTEM}" "${PERM_RUNNER_SCRIPT}" \
        "${SUITE_ID}.S02.installed-runner"
    verify_perm "${BASH_COMPLETION_DEST}" "${OWNER_SYSTEM}" "${PERM_BASH_COMPLETION}" \
        "${SUITE_ID}.S02.bash-completion"
    [[ -f "${SUDOERS_FILE}" ]] && SUDOERS_EXISTS=1
    [[ -f "${LOGROTATE_FILE}" ]] && LOGROTATE_EXISTS=1
}

function test_sudoers_syntax {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify Sudoers Policy Syntax"
    print_sub_divider

    local syntax_ok="false"

    if (( ! SUDOERS_EXISTS )); then
        report_record "${SUITE_ID}.S03.sudoers-syntax-valid" SKIP \
            "requires ${SUITE_ID}.S02.sudoers-policy.exists"
        return
    fi
    if visudo -cf "${SUDOERS_FILE}" >/dev/null 2>&1; then
        syntax_ok="true"
    fi
    verify_state "true" "${syntax_ok}" "${SUITE_ID}.S03.sudoers-syntax-valid"
}

function test_logrotate_syntax {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify Logrotate Policy"
    print_sub_divider

    local syntax_ok="false"
    local check_id=""
    local directive=""
    local present="false"
    local index=0
    local -a directives=(
        "${SYSTEM_LOG_DIR}/*.log"
        "su root ${SYSTEM_GROUP}"
        "copytruncate"
        "compress"
        "weekly"
        "rotate 8"
        "nodateext"
    )
    local -a check_ids=(
        "${SUITE_ID}.S04.log-glob-pinned"
        "${SUITE_ID}.S04.su-directive-pinned"
        "${SUITE_ID}.S04.copytruncate-pinned"
        "${SUITE_ID}.S04.compress-pinned"
        "${SUITE_ID}.S04.weekly-pinned"
        "${SUITE_ID}.S04.rotate-eight-pinned"
        "${SUITE_ID}.S04.nodateext-pinned"
    )

    if (( ! LOGROTATE_EXISTS )); then
        report_record "${SUITE_ID}.S04.logrotate-syntax-valid" SKIP \
            "requires ${SUITE_ID}.S02.logrotate-policy.exists"
        for check_id in "${check_ids[@]}"; do
            report_record "${check_id}" SKIP "requires ${SUITE_ID}.S02.logrotate-policy.exists"
        done
        return
    fi
    if logrotate -d "${LOGROTATE_FILE}" >/dev/null 2>&1; then
        syntax_ok="true"
    fi
    verify_state "true" "${syntax_ok}" "${SUITE_ID}.S04.logrotate-syntax-valid"

    # Pin the #15 acceptance directives. logrotate -d passes even if e.g.
    # copytruncate is dropped, so assert the contract directives explicitly;
    # copytruncate is mandatory because procServ does not reopen on SIGHUP,
    # and nodateext keeps the <name>.log.N.gz numbering the acceptance cites.
    for index in "${!directives[@]}"; do
        directive="${directives[${index}]}"
        present="false"
        if grep -qF "${directive}" "${LOGROTATE_FILE}"; then
            present="true"
        fi
        verify_state "true" "${present}" "${check_ids[${index}]}"
    done
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

    idr_line=$(grep -nE '^[[:space:]]*[#@]includedir[[:space:]]+/etc/sudoers\.d' "${main_sudoers}" | tail -1 | cut -d: -f1 || true)

    if [[ -z "${idr_line}" ]]; then
        verify_state "true" "false" "${SUITE_ID}.S05.include-directive-exists"
        report_record "${SUITE_ID}.S05.include-directive-final" SKIP \
            "requires ${SUITE_ID}.S05.include-directive-exists"
        return
    fi
    verify_state "true" "true" "${SUITE_ID}.S05.include-directive-exists"

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

    verify_state "true" "${ordering_ok}" "${SUITE_ID}.S05.include-directive-final"
}

function test_sudoers_regex_denies_bad_name {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify Sudoers Anchored Regex Denies Out-of-Model Names"
    print_sub_divider

    if [[ ! -f "${SUDOERS_FILE}" ]]; then
        report_record "${SUITE_ID}.S06.regex-policy-applicable" SKIP \
            "requires ${SUITE_ID}.S02.sudoers-policy.exists"
        report_record "${SUITE_ID}.S06.probe-user-available" SKIP \
            "requires ${SUITE_ID}.S02.sudoers-policy.exists"
        report_record "${SUITE_ID}.S06.bad-name-denied" SKIP \
            "requires ${SUITE_ID}.S02.sudoers-policy.exists"
        report_record "${SUITE_ID}.S06.good-name-allowed" SKIP \
            "requires ${SUITE_ID}.S02.sudoers-policy.exists"
        return
    fi

    # The anchored-regex emission begins each verb with '^'. Hosts whose
    # installed sudo is < 1.9.10 (or whose policy hasn't been refreshed
    # since the OS-agnostic generator landed) use fnmatch globs by
    # design; the deny semantic the probe checks does not apply there.
    # See docs/PERMISSION_MODEL.md residual-risk subsection.
    if ! grep -qE '\^(start|stop|restart|status|enable|disable) epics-@' "${SUDOERS_FILE}"; then
        _log "INFO" "SKIP: deployed sudoers uses glob fallback; regex-deny probe does not apply."
        report_record "${SUITE_ID}.S06.regex-policy-applicable" NA \
            "deployed sudoers policy uses glob commands"
        report_record "${SUITE_ID}.S06.probe-user-available" NA \
            "requires ${SUITE_ID}.S06.regex-policy-applicable"
        report_record "${SUITE_ID}.S06.bad-name-denied" NA \
            "requires ${SUITE_ID}.S06.regex-policy-applicable"
        report_record "${SUITE_ID}.S06.good-name-allowed" NA \
            "requires ${SUITE_ID}.S06.regex-policy-applicable"
        return
    fi
    report_record "${SUITE_ID}.S06.regex-policy-applicable" PASS

    local test_user="epics-c57-iocmember"

    if id -u "${test_user}" >/dev/null 2>&1; then
        _log "INFO" "Pre-existing user '${test_user}' detected; reusing without cleanup on exit."
    else
        if ! useradd -M -N -G "${SYSTEM_GROUP}" "${test_user}" >/dev/null 2>&1; then
            report_record "${SUITE_ID}.S06.probe-user-available" SKIP \
                "cannot create ephemeral ioc-group probe user"
            report_record "${SUITE_ID}.S06.bad-name-denied" SKIP \
                "requires ${SUITE_ID}.S06.probe-user-available"
            report_record "${SUITE_ID}.S06.good-name-allowed" SKIP \
                "requires ${SUITE_ID}.S06.probe-user-available"
            return
        fi
        C57_CREATED_USER="${test_user}"
    fi
    report_record "${SUITE_ID}.S06.probe-user-available" PASS

    # Resolve the systemctl path from the deployed policy so the probe
    # argv matches the policy line verbatim (Debian uses /usr/bin,
    # Rocky often uses /bin via usrmerge).
    local systemctl_bin
    systemctl_bin=$(grep -oE '/[^[:space:],]*systemctl' "${SUDOERS_FILE}" | head -1)
    if [[ -z "${systemctl_bin}" ]]; then
        systemctl_bin="/usr/bin/systemctl"
    fi

    local bad_deny="false"
    if ! runuser -u "${test_user}" -- sudo -n -l "${systemctl_bin}" start 'epics-@bad name.service' >/dev/null 2>&1; then
        bad_deny="true"
    fi
    verify_state "true" "${bad_deny}" "${SUITE_ID}.S06.bad-name-denied"

    local good_allow="false"
    if runuser -u "${test_user}" -- sudo -n -l "${systemctl_bin}" start 'epics-@goodname.service' >/dev/null 2>&1; then
        good_allow="true"
    fi
    verify_state "true" "${good_allow}" "${SUITE_ID}.S06.good-name-allowed"

    if [[ -n "${C57_CREATED_USER:-}" ]]; then
        userdel "${C57_CREATED_USER}" 2>/dev/null || true
        C57_CREATED_USER=""
    fi
}

function run_all_tests {
    local -a pipeline=(
        "test_service_accounts"
        "test_infrastructure_files"
        "test_sudoers_syntax"
        "test_logrotate_syntax"
        "test_sudoers_includedir_order"
        "test_sudoers_regex_denies_bad_name"
    )
    local step=1
    local func=""
    local root_invocation="false"

    initialize_reporting
    [[ ${EUID} -eq 0 ]] && root_invocation="true"
    verify_state "true" "${root_invocation}" "${SUITE_ID}.P00.root-required"
    if [[ "${root_invocation}" != "true" ]]; then
        close_after_root_failure
        return
    fi
    for func in "${pipeline[@]}"; do
        "${func}" "${step}"
        step=$((step + 1))
    done
}

run_all_tests
