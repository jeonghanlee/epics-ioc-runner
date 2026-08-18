#!/usr/bin/env bash
#
# Automated lifecycle test for EPICS system-wide IOC management.
# This script uses the actual ServiceTestIOC repository to verify
# the install, start, view, list, enable, disable, and remove workflows.
# It validates the systemd template unit (@.service) architecture at the system level.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
umask 077
unset BASH_ENV ENV CDPATH GIT_DIR GIT_WORK_TREE

declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g BLUE='\033[0;34m'
declare -g YELLOW='\033[0;33m'
declare -g NC='\033[0m'

declare -g CAMONITOR_COUNT=5
declare -g CAMONITOR_TIMEOUT=10

if [[ -z "${EPICS_HOST_ARCH:-}" ]]; then
    export EPICS_HOST_ARCH="linux-x86_64"
fi

# Monitor isolation reads system journal output. Mark unavailable so the
# dependent step skips with a WARN rather than aborting the run.
declare -g JOURNAL_AVAILABLE="false"

declare -g SC_TOP
# Capture an absolute SC_TOP without readlink/realpath/cd-pwd; later
# steps cd into a workspace, so a relative path would fail to resolve
# back to the source tree. ${PWD} reflects the invoker's CWD at script
# start, set by the kernel and not subject to NFS root_squash.
SC_TOP="$(dirname "${BASH_SOURCE[0]}")"
[[ "${SC_TOP}" != /* ]] && SC_TOP="${PWD}/${SC_TOP}"

declare -gr SUITE_ID="system-lifecycle"
declare -gr SUITE_SCOPE="system"
declare -gr SUITE_CATEGORY="lifecycle-behavior"
declare -g SUITE_RUNNER="source"
declare -g REPORT_DIR=""
declare -g REPORT_READY=0
declare -g CURRENT_STEP_ID=""
declare -g CURRENT_STEP_CHECK_INDEX=0
declare -g SUITE_ASSERTION_FAILED=0
declare -g SYSTEM_INFRA_READY=0
declare -g -a SYSTEM_CATALOG_ROWS=(
    "P00|system-lifecycle.P00.epics-base-set|REQUIRED|direct-inspection"
    "P00|system-lifecycle.P00.lsof-available|REQUIRED|direct-inspection"
    "P00|system-lifecycle.P00.root-invocation|REQUIRED|direct-inspection"
    "P00|system-lifecycle.P00.selected-runner-executable|REQUIRED|direct-inspection"
    "S01|system-lifecycle.S01.system-configuration-directory-exists-conf-dir|REQUIRED|direct-inspection"
    "S01|system-lifecycle.S01.system-configuration-directory-is-writable-by-current-user|REQUIRED|direct-inspection"
    "S01|system-lifecycle.S01.system-template-unit-exists-systemd-dir-epics-service|REQUIRED|direct-inspection"
    "S05|system-lifecycle.S05.manual-configuration-artifact-created|BEHAVIOR|real-path"
    "S06|system-lifecycle.S06.explicit-file-installation-succeeded|BEHAVIOR|real-path"
    "S07|system-lifecycle.S07.deployed-configuration-safely-removed|BEHAVIOR|real-path"
    "S08|system-lifecycle.S08.directory-based-installation-succeeded|BEHAVIOR|real-path"
    "S09|system-lifecycle.S09.deployed-configuration-safely-removed|BEHAVIOR|real-path"
    "S10|system-lifecycle.S10.workspace-configuration-artifact-removed|BEHAVIOR|real-path"
    "S11|system-lifecycle.S11.configuration-artifact-auto-generated-natively|BEHAVIOR|real-path"
    "S12|system-lifecycle.S12.explicit-file-installation-succeeded|BEHAVIOR|real-path"
    "S13|system-lifecycle.S13.deployed-configuration-safely-removed|BEHAVIOR|real-path"
    "S14|system-lifecycle.S14.directory-based-installation-succeeded|BEHAVIOR|real-path"
    "S15|system-lifecycle.S15.service-active|BEHAVIOR|real-path"
    "S16|system-lifecycle.S16.status-output-shows-active-active|BEHAVIOR|real-path"
    "S17|system-lifecycle.S17.view-output-renders-the-configuration-ioc-cmd|BEHAVIOR|real-path"
    "S18|system-lifecycle.S18.service-remains-active-after-restart|BEHAVIOR|real-path"
    "S19|system-lifecycle.S19.service-is-inactive-after-stop|BEHAVIOR|real-path"
    "S19|system-lifecycle.S19.service-is-active-after-restart-following-stop|BEHAVIOR|real-path"
    "S20|system-lifecycle.S20.unix-domain-socket-explicitly-created|BEHAVIOR|real-path"
    "S20|system-lifecycle.S20.ioc-name-appears-in-list-output|BEHAVIOR|real-path"
    "S20|system-lifecycle.S20.uds-socket-path-appears-in-list-output|BEHAVIOR|real-path"
    "S20|system-lifecycle.S20.list-v-output-contains-pid-column|BEHAVIOR|real-path"
    "S20|system-lifecycle.S20.list-v-output-contains-cpu-column|BEHAVIOR|real-path"
    "S20|system-lifecycle.S20.list-v-output-contains-mem-column|BEHAVIOR|real-path"
    "S20|system-lifecycle.S20.list-vv-output-contains-recv-q-column|BEHAVIOR|real-path"
    "S20|system-lifecycle.S20.list-vv-output-contains-send-q-column|BEHAVIOR|real-path"
    "S20|system-lifecycle.S20.list-vv-output-contains-perm-column|BEHAVIOR|real-path"
    "S21|system-lifecycle.S21.parsed-list-v|BEHAVIOR|real-path"
    "S21|system-lifecycle.S21.parsed-v-list|BEHAVIOR|real-path"
    "S22|system-lifecycle.S22.uds-socket-has-correct-permissions-srw-rw|BEHAVIOR|direct-inspection"
    "S22|system-lifecycle.S22.con-available|REQUIRED|direct-inspection"
    "S22|system-lifecycle.S22.uds-socket-is-in-listening-state|BEHAVIOR|direct-inspection"
    "S23|system-lifecycle.S23.camonitor-available|REQUIRED|direct-inspection"
    "S23|system-lifecycle.S23.expected-updates-observed|BEHAVIOR|real-path"
    "S24|system-lifecycle.S24.inspect-command-successfully-retrieved-server-netlink-context|BEHAVIOR|real-path"
    "S24|system-lifecycle.S24.inspect-section-1-references-the-target-socket-path|BEHAVIOR|real-path"
    "S24|system-lifecycle.S24.inspect-section-1-excludes-unrelated-systemd-uds-entries|BEHAVIOR|real-path"
    "S25|system-lifecycle.S25.system-journal-available|PREREQUISITE|direct-inspection"
    "S25|system-lifecycle.S25.journal-channel-visible-for-unit-positive-control|BEHAVIOR|real-path"
    "S25|system-lifecycle.S25.input-securely-blocked-in-monitor-mode|BEHAVIOR|real-path"
    "S26|system-lifecycle.S26.softioc-available|PREREQUISITE|direct-inspection"
    "S26|system-lifecycle.S26.leading-boundary-identifier-adjacent-exits-zero|BEHAVIOR|real-path"
    "S26|system-lifecycle.S26.leading-boundary-identifier-adjacent-avoids-failed-verdict|BEHAVIOR|real-path"
    "S26|system-lifecycle.S26.leading-boundary-identifier-adjacent-emitted|BEHAVIOR|real-path"
    "S26|system-lifecycle.S26.trailing-boundary-identifier-adjacent-exits-zero|BEHAVIOR|real-path"
    "S26|system-lifecycle.S26.trailing-boundary-identifier-adjacent-avoids-failed-verdict|BEHAVIOR|real-path"
    "S26|system-lifecycle.S26.trailing-boundary-identifier-adjacent-emitted|BEHAVIOR|real-path"
    "S26|system-lifecycle.S26.identifier-contained-fatal-exits-zero|BEHAVIOR|real-path"
    "S26|system-lifecycle.S26.identifier-contained-fatal-avoids-failed-verdict|BEHAVIOR|real-path"
    "S26|system-lifecycle.S26.identifier-contained-fatal-emitted|BEHAVIOR|real-path"
    "S26|system-lifecycle.S26.broken-softioc-fatal-pre-init-exit-1|BEHAVIOR|real-path"
    "S26|system-lifecycle.S26.broken-softioc-failed-to-initialize-verdict|BEHAVIOR|real-path"
    "S27|system-lifecycle.S27.softioc-available|PREREQUISITE|direct-inspection"
    "S27|system-lifecycle.S27.probe-user-name-available|PREREQUISITE|direct-inspection"
    "S27|system-lifecycle.S27.operator-is-an-ioc-group-member-sudoers-gate-reachable|BEHAVIOR|real-path"
    "S27|system-lifecycle.S27.operator-is-not-in-systemd-journal|BEHAVIOR|real-path"
    "S27|system-lifecycle.S27.journal-less-operator-crash-exit-1|BEHAVIOR|real-path"
    "S27|system-lifecycle.S27.journal-less-operator-failed-to-initialize-verdict-reads-log-file-not-journal|BEHAVIOR|real-path"
    "S28|system-lifecycle.S28.logrotate-policy-exists|REQUIRED|direct-inspection"
    "S28|system-lifecycle.S28.softioc-available|PREREQUISITE|direct-inspection"
    "S28|system-lifecycle.S28.logrotate-available|PREREQUISITE|direct-inspection"
    "S28|system-lifecycle.S28.pre-rotate-fatal-pattern-moved-into-rotated-log-boundary-created|BEHAVIOR|real-path"
    "S28|system-lifecycle.S28.active-log-cleared-of-the-pre-rotate-fatal-pattern-after-rotation|BEHAVIOR|real-path"
    "S28|system-lifecycle.S28.no-false-crash-verdict-from-rotated-historical-fatal-pattern|BEHAVIOR|real-path"
    "S28|system-lifecycle.S28.t2-sub-case-a-restart-activation-observed-before-log-mutation|BEHAVIOR|real-path"
    "S28|system-lifecycle.S28.t2-sub-case-a-log-mv-to-side-name-succeeded|BEHAVIOR|real-path"
    "S28|system-lifecycle.S28.t2-sub-case-a-replacement-log-install-succeeded|BEHAVIOR|real-path"
    "S28|system-lifecycle.S28.t2-sub-case-a-active-log-inode-actually-changed-after-replacement|BEHAVIOR|real-path"
    "S28|system-lifecycle.S28.t2-sub-case-a-in-window-new-inode-replacement-triggers-crash-verdict-exit-1|BEHAVIOR|real-path"
    "S28|system-lifecycle.S28.t2-sub-case-b-restart-activation-observed-before-log-mutation|BEHAVIOR|real-path"
    "S28|system-lifecycle.S28.t2-sub-case-b-in-window-same-inode-regrow-past-triggers-crash-verdict-via-tailhash-mismatch|BEHAVIOR|real-path"
    "S29|system-lifecycle.S29.sudoers-policy-exists|REQUIRED|direct-inspection"
    "S29|system-lifecycle.S29.softioc-available|PREREQUISITE|direct-inspection"
    "S29|system-lifecycle.S29.probe-user-name-available|PREREQUISITE|direct-inspection"
    "S29|system-lifecycle.S29.probe-user-not-ioc-member|REQUIRED|direct-inspection"
    "S29|system-lifecycle.S29.non-ioc-user-can-read-the-log-file-mode-0644|BEHAVIOR|real-path"
    "S29|system-lifecycle.S29.non-ioc-user-denied-systemctl-start-by-ioc-sudoers-gate|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.conforming-root-ioc-2775-dir-emits-no-warning|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.conforming-install-exits-0|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.group-mismatch-dir-not-ioc-warns|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.group-mismatch-install-with-f-exits-0|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.untraversable-0700-parent-warns|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.untraversable-parent-install-with-f-exits-0|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.relative-ioc-chdir-is-a-hard-validation-error-m6-109|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.relative-path-install-exits-1-despite-f|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.symlinked-ioc-chdir-warns-symlinked-leaf-rejected|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.symlinked-leaf-install-with-f-exits-0|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.missing-setgid-0775-dir-warns|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.missing-setgid-install-with-f-exits-0|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.prompt-eof-aborts-install-exit-1|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.prompt-explicit-n-declines-install-exit-1|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.prompt-explicit-y-proceeds-with-install-exit-0|BEHAVIOR|real-path"
    "S30|system-lifecycle.S30.prompt-y-path-deploys-the-conf-file|BEHAVIOR|real-path"
    "S31|system-lifecycle.S31.symlink-created-in-multi-user-wants-enable|BEHAVIOR|real-path"
    "S31|system-lifecycle.S31.symlink-strictly-removed-disable|BEHAVIOR|real-path"
    "S32|system-lifecycle.S32.configuration-file-safely-removed|BEHAVIOR|real-path"
    "S32|system-lifecycle.S32.service-completely-stopped-inactive|BEHAVIOR|real-path"
)
declare -g -A SYSTEM_STEP_CHECK_IDS=()
# shellcheck source=lib/test-reporting.bash
source "${SC_TOP}/lib/test-reporting.bash"

# Resolve the ioc-runner binary under test. IOC_RUNNER_TEST_MODE selects
# the binary origin; the unset default is the source tree, matching the
# developer inner loop. An NFS + root_squash host, where root maps to
# nobody and cannot execve a user-owned source binary, runs system tests
# with IOC_RUNNER_TEST_MODE=installed. Selection failures stop here,
# before STEP 1, never deferred into the lifecycle body. See issue #45.
declare -g RUNNER_SCRIPT
function resolve_runner_script {
    local mode="${IOC_RUNNER_TEST_MODE:-}"
    local source_bin="${SC_TOP}/../bin/ioc-runner"
    # Installed mode follows IOC_RUNNER_SCRIPT_DEST (setup's deploy target),
    # defaulting to the canonical path; source mode ignores the override. (#145)
    local installed_bin="${IOC_RUNNER_SCRIPT_DEST:-/usr/local/bin/ioc-runner}"
    case "${mode}" in
        ""|source)
            RUNNER_SCRIPT="${source_bin}"
            ;;
        installed)
            RUNNER_SCRIPT="${installed_bin}"
            SUITE_RUNNER="installed"
            ;;
        *)
            printf "Error: invalid IOC_RUNNER_TEST_MODE '%s' (expected: source, installed)\n" "${mode}" >&2
            exit 1
            ;;
    esac
}
resolve_runner_script
declare -g CONF_DIR="/etc/procServ.d"
declare -g SYSTEMD_DIR="/etc/systemd/system"
declare -g SYSTEMD_WANTS_DIR="${SYSTEMD_DIR}/multi-user.target.wants"
declare -g RUN_DIR="/run/procserv"
declare -g SYSTEM_LOG_DIR="${IOC_RUNNER_SYSTEM_LOG_DIR:-/var/log/procserv}"
declare -g SUDOERS_FILE_PATH="/etc/sudoers.d/10-epics-ioc"
declare -g T5_CREATED_USER=""
declare -g T1_CREATED_USER=""

declare -g IOC_REPO="https://github.com/jeonghanlee/ServiceTestIOC.git"
declare -g REPO_NAME="ServiceTestIOC"
# System test uses a specific suffix to avoid colliding with local tests
declare -g IOC_NAME="iocServiceTestIOC-SYS"

# Global settings for system identity and workspace permissions
declare -g SYSTEM_USER="ioc-srv"
declare -g SYSTEM_GROUP="ioc"

declare -g WORKSPACE=""
declare -g TOP_DIR=""
declare -g BOOT_DIR=""
declare -g CONF_FILE=""

declare -g UDS_PATH="${RUN_DIR}/${IOC_NAME}/control"

# Dedicated Channel Access server port for the test IOC. STEP 24 runs a
# unicast (EPICS_CA_ADDR_LIST=127.0.0.1) search; when co-located IOCs share
# the default UDP 5064 SO_REUSEPORT fanout group, the kernel delivers the
# search to only one socket in that group, so the test PV can be absorbed by
# another IOC. A dedicated port isolates the test IOC from the shared group,
# deterministic regardless of IOC owner UID or host kernel. (#76)
declare -g TEST_CA_PORT=""
declare -g PERM_WORKSPACE="2770"
declare -g OWNER_WORKSPACE="root:ioc"

declare -g -a SYSTEMCTL_CMD=(systemctl)

declare -g KEEP_WORKSPACE="${KEEP_WORKSPACE:-0}"

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
    local row=""
    local step_id=""
    local check_id=""
    local check_kind=""
    local test_method=""
    local description=""
    local os_name="unknown"
    local os_version="0"
    local os_id=""
    local run_id="${SUITE_ID}.$$.${BASHPID}"
    local -a step_ids=(P00)
    local index=0

    for ((index = 1; index <= 32; index += 1)); do
        printf -v step_id 'S%02d' "${index}"
        step_ids+=("${step_id}")
    done
    if [[ -r /etc/os-release ]]; then
        os_name=$(read_os_release_value ID || true)
        os_version=$(read_os_release_value VERSION_ID || true)
    fi
    os_name="${os_name:-unknown}"
    os_version="${os_version%%.*}"
    os_version="${os_version:-0}"
    os_id="${os_name}-${os_version}"
    REPORT_DIR=$(mktemp -d /tmp/ioc-runner-system-lifecycle-report.XXXXXX)
    report_init "${SUITE_ID}" "${run_id}" "${SUITE_SCOPE}" "${SUITE_RUNNER}" \
        "${os_id}" "${EPICS_HOST_ARCH}" "${REPORT_DIR}"
    REPORT_READY=1
    for step_id in "${step_ids[@]}"; do
        report_register_step "${step_id}" "System lifecycle ${step_id}"
    done
    for row in "${SYSTEM_CATALOG_ROWS[@]}"; do
        IFS='|' read -r step_id check_id check_kind test_method <<< "${row}"
        description="${check_id#${SUITE_ID}.${step_id}.}"
        report_register_check "${check_id}" "${step_id}" "${SUITE_CATEGORY}" \
            "${check_kind}" "${test_method}" "${description}"
        if [[ -n "${SYSTEM_STEP_CHECK_IDS[${step_id}]:-}" ]]; then
            SYSTEM_STEP_CHECK_IDS["${step_id}"]+=" ${check_id}"
        else
            SYSTEM_STEP_CHECK_IDS["${step_id}"]="${check_id}"
        fi
    done
    report_close_catalog
    report_verify_catalog_counts
}

function next_current_check_id {
    local result_name="$1"
    local check_list="${SYSTEM_STEP_CHECK_IDS[${CURRENT_STEP_ID}]:-}"
    local -a check_ids=()

    read -r -a check_ids <<< "${check_list}"
    if (( CURRENT_STEP_CHECK_INDEX >= ${#check_ids[@]} )); then
        printf 'REPORTING ERROR: extra assertion in %s\n' "${CURRENT_STEP_ID}" >&2
        return 1
    fi
    printf -v "${result_name}" '%s' "${check_ids[${CURRENT_STEP_CHECK_INDEX}]}"
    CURRENT_STEP_CHECK_INDEX=$((CURRENT_STEP_CHECK_INDEX + 1))
}

function record_current_state {
    local state="$1"
    local reason="${2:-}"
    local check_id=""

    next_current_check_id check_id
    if [[ "${state}" == "PASS" ]]; then
        report_record "${check_id}" PASS
    else
        report_record "${check_id}" "${state}" "${reason}"
    fi
}

function close_current_remaining {
    local state="$1"
    local reason="$2"
    local check_list="${SYSTEM_STEP_CHECK_IDS[${CURRENT_STEP_ID}]:-}"
    local check_id=""
    local -a check_ids=()

    read -r -a check_ids <<< "${check_list}"
    while (( CURRENT_STEP_CHECK_INDEX < ${#check_ids[@]} )); do
        check_id="${check_ids[${CURRENT_STEP_CHECK_INDEX}]}"
        CURRENT_STEP_CHECK_INDEX=$((CURRENT_STEP_CHECK_INDEX + 1))
        report_record "${check_id}" "${state}" "${reason}"
    done
}

function close_catalog_from_index {
    local start_index="$1"
    local state="$2"
    local reason="$3"
    local row=""
    local step_id=""
    local check_id=""
    local check_kind=""
    local test_method=""

    for row in "${SYSTEM_CATALOG_ROWS[@]:${start_index}}"; do
        IFS='|' read -r step_id check_id check_kind test_method <<< "${row}"
        report_record "${check_id}" "${state}" "${reason}"
    done
}

function run_preflight {
    local epics_base_set="false"
    local lsof_available="false"
    local root_invocation="false"
    local runner_executable="false"

    CURRENT_STEP_ID=P00
    CURRENT_STEP_CHECK_INDEX=0
    [[ -n "${EPICS_BASE:-}" ]] && epics_base_set="true"
    command -v lsof >/dev/null 2>&1 && lsof_available="true"
    [[ "${EUID}" -eq 0 ]] && root_invocation="true"
    [[ -x "${RUNNER_SCRIPT}" ]] && runner_executable="true"
    verify_state true "${epics_base_set}" "EPICS_BASE is set"
    verify_state true "${lsof_available}" "lsof is available"
    verify_state true "${root_invocation}" "Effective user is root"
    verify_state true "${runner_executable}" "Selected runner is executable"
    if [[ "${epics_base_set}" != "true" || "${lsof_available}" != "true" ||
          "${root_invocation}" != "true" || "${runner_executable}" != "true" ]]; then
        close_catalog_from_index 4 SKIP "requires system lifecycle P00"
        return 1
    fi
}

function probe_optional_dependencies {
    local journal_probe=""

    JOURNAL_AVAILABLE="true"
    journal_probe=$(journalctl --no-pager -n 1 2>&1 || true)
    if [[ "${journal_probe}" == *"No journal files were found"* ||
          "${journal_probe}" == *"insufficient permissions"* ]]; then
        JOURNAL_AVAILABLE="false"
    fi
}

function _handle_exit {
    local exit_code=$?
    local final_status="${exit_code}"

    trap - EXIT
    set +e

    if (( REPORT_CATALOG_ONLY_COMPLETED )); then
        exit "${REPORT_FINAL_STATUS}"
    fi

    # T5 may create a throwaway non-ioc account; remove only the one this run
    # created (a pre-existing account of the same name is left untouched).
    if [[ -n "${T5_CREATED_USER:-}" ]] && id "${T5_CREATED_USER}" &>/dev/null; then
        userdel "${T5_CREATED_USER}" 2>/dev/null || true
        T5_CREATED_USER=""
    fi
    if [[ -n "${T1_CREATED_USER:-}" ]] && id "${T1_CREATED_USER}" &>/dev/null; then
        userdel "${T1_CREATED_USER}" 2>/dev/null || true
        T1_CREATED_USER=""
    fi

    if [[ -n "${WORKSPACE}" && "${WORKSPACE}" == */epics-ioc-test.* && -d "${WORKSPACE}" ]]; then
        if [[ ${exit_code} -ne 0 || ${SUITE_ASSERTION_FAILED} -ne 0 || "${KEEP_WORKSPACE}" == "1" ]]; then
            print_divider
            _log "WARN" "DEBUG: Test workspace retained for inspection."
            _log "WARN" "Path: ${WORKSPACE}"
            print_divider
        elif "${REPORT_RM_BIN:-/bin/rm}" -rf -- "${WORKSPACE}"; then
            _log "INFO" "Test workspace removed."
        else
            final_status=1
            print_divider
            _log "ERROR" "Failed to remove test workspace."
            _log "ERROR" "Path: ${WORKSPACE}"
            print_divider
        fi
    fi

    if (( REPORT_READY )); then
        report_finalize "${final_status}" || final_status=1
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
    local step_name="$3"
    local check_id=""

    next_current_check_id check_id

    if [[ "${expected}" == "${actual}" ]]; then
        printf "${GREEN}[ PASS ]${NC} %s\n" "${check_id}"
        report_record "${check_id}" PASS
    else
        printf "${RED}[ FAIL ]${NC} %s\n" "${check_id}" >&2
        printf "  ${YELLOW}Expected : %s${NC}\n" "${expected}" >&2
        printf "  ${YELLOW}Actual   : %s${NC}\n" "${actual}" >&2
        SUITE_ASSERTION_FAILED=1
        report_record "${check_id}" FAIL \
            "${step_name}: expected ${expected}, actual ${actual}"
    fi
}

function wait_for_state {
    local expected_state="$1"
    local max_wait="${2:-10}"
    local attempt=0
    local current_state

    while [[ ${attempt} -lt ${max_wait} ]]; do
        current_state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${IOC_NAME}.service" 2>/dev/null || true)
        if [[ "${current_state}" == "${expected_state}" ]]; then
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done

    _log "WARN" "Timeout waiting for state: ${expected_state} (Current: ${current_state})"
    return 1
}

function verify_infrastructure {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Verify System Infrastructure"
    print_sub_divider

    local conf_dir_exist="false"
    local conf_dir_writable="false"
    local tmpl_exist="false"

    if [[ -d "${CONF_DIR}" ]]; then conf_dir_exist="true"; fi
    if [[ -w "${CONF_DIR}" ]]; then conf_dir_writable="true"; fi
    if [[ -f "${SYSTEMD_DIR}/epics-@.service" ]]; then tmpl_exist="true"; fi

    verify_state "true" "${conf_dir_exist}" "System configuration directory exists (${CONF_DIR})"
    verify_state "true" "${conf_dir_writable}" "System configuration directory is writable by current user"
    verify_state "true" "${tmpl_exist}" "System template unit exists (${SYSTEMD_DIR}/epics-@.service)"
    if [[ "${conf_dir_exist}" == "true" && "${conf_dir_writable}" == "true" &&
          "${tmpl_exist}" == "true" ]]; then
        SYSTEM_INFRA_READY=1
    else
        close_catalog_from_index 7 SKIP "requires system-lifecycle S01 infrastructure"
    fi
}

# Returns the first free UDP port at or above the candidate base, so the
# dedicated test CA port never collides with an IOC already bound on the host.
function pick_free_ca_port {
    local port="${1:-5095}"
    while ss -uHln "sport = :${port}" 2>/dev/null | grep -q .; do
        port=$((port + 1))
    done
    printf '%s' "${port}"
}

function _setup_workspace {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Setup Test Workspace"
    print_sub_divider

    local target_tmp="${TMPDIR:-/dev/shm}"
    if [[ ! -d "${target_tmp}" || ! -w "${target_tmp}" ]]; then
        target_tmp="/tmp"
    fi

    WORKSPACE=$(mktemp -d -p "${target_tmp}" epics-ioc-test.XXXXXX)

    # TOP_DIR uses the repository name. BOOT_DIR aligns with the system IOC_NAME.
    TOP_DIR="${WORKSPACE}/${REPO_NAME}"
    BOOT_DIR="${TOP_DIR}/iocBoot/${IOC_NAME}"
    CONF_FILE="${BOOT_DIR}/${IOC_NAME}.conf"

    chgrp "${OWNER_WORKSPACE#*:}" "${WORKSPACE}"
    chmod "${PERM_WORKSPACE}" "${WORKSPACE}"

    TEST_CA_PORT="$(pick_free_ca_port 5095)"

    _log "SUCCESS" "Test workspace created at ${WORKSPACE}"
}

function cleanup_previous_state {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Cleanup Previous State"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" remove "${IOC_NAME}" >/dev/null 2>&1 || true
    _log "SUCCESS" "Cleaned up residual processes and configurations."
}

function setup_environment {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Environment Setup & Compilation"
    print_sub_divider

    if [[ ! -d "${TOP_DIR}" ]]; then
        _log "INFO" "Cloning target IOC repository..."
        # Bypass the user's global git config for this clone so any
        # url.<...>.insteadOf rewrite (e.g. https -> ssh) does not apply.
        # The target repo is public, so anonymous HTTPS avoids SSH key and
        # known_hosts complications when the test runs under sudo (where
        # OpenSSH resolves ~ via getpwuid, not $HOME).
        GIT_CONFIG_GLOBAL=/dev/null git clone -q "${IOC_REPO}" "${TOP_DIR}" >/dev/null 2>&1
    fi

    cd "${TOP_DIR}" || exit 1
    if [[ ! -d "bin" ]]; then
        _log "INFO" "Configuring EPICS environment..."
        printf "EPICS_BASE=%s\n" "${EPICS_BASE}" > configure/RELEASE.local

        _log "INFO" "Compiling ServiceTestIOC..."
        make > build.log 2>&1 || { _log "ERROR" "Compilation failed. Check build.log"; exit 1; }
        _log "SUCCESS" "Compilation completed."
    else
        _log "INFO" "Binaries found. Skipping compilation."
    fi

    # Rename the standard boot directory to match our SYS test target name
    if [[ -d "iocBoot/iocServiceTestIOC" && "${IOC_NAME}" != "iocServiceTestIOC" ]]; then
        mv "iocBoot/iocServiceTestIOC" "${BOOT_DIR}"
    fi

    # System tests run as root, but the IOC runs as ioc-srv. Ensure permissions.
    chown -R "${OWNER_WORKSPACE}" "${TOP_DIR}"
    chmod -R g+rX "${TOP_DIR}"
    chmod 0750 "${BOOT_DIR}/st.cmd"

    _log "SUCCESS" "System environment structure prepared at ${BOOT_DIR}"
}

function test_generate_manual {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Generate (Manual)"
    print_sub_divider

    cd "${BOOT_DIR}" || exit 1
    cat <<EOF > "${CONF_FILE}"
IOC_NAME="${IOC_NAME}"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${BOOT_DIR}"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF
    chown "${OWNER_WORKSPACE}" "${CONF_FILE}"

    local conf_exist="false"
    if [[ -f "${CONF_FILE}" ]]; then conf_exist="true"; fi
    verify_state "true" "${conf_exist}" "Manual configuration artifact created"
}

function test_generate_auto {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Generate (Auto)"
    print_sub_divider

    cd "${BOOT_DIR}" || exit 1
    # System generation explicitly detects the target boot directory
    bash "${RUNNER_SCRIPT}" generate . >/dev/null
    # Pin the test IOC to its dedicated CA server port through the conf, which
    # the systemd template loads as an EnvironmentFile into the IOC environment.
    printf 'EPICS_CA_SERVER_PORT="%s"\n' "${TEST_CA_PORT}" >> "${CONF_FILE}"

    local conf_exist="false"
    if [[ -f "${CONF_FILE}" ]]; then conf_exist="true"; fi
    verify_state "true" "${conf_exist}" "Configuration artifact auto-generated natively"
}

function test_install_explicit {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Install (Explicit)"
    print_sub_divider

    cd "${BOOT_DIR}" || exit 1
    bash "${RUNNER_SCRIPT}" -f install "${CONF_FILE}" >/dev/null

    local conf_exist="false"
    if [[ -f "${CONF_DIR}/${IOC_NAME}.conf" ]]; then conf_exist="true"; fi
    verify_state "true" "${conf_exist}" "Explicit file installation succeeded"
}

function test_install_dir {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Install (Directory)"
    print_sub_divider

    cd "${BOOT_DIR}" || exit 1
    bash "${RUNNER_SCRIPT}" -f install . >/dev/null

    local conf_exist="false"
    if [[ -f "${CONF_DIR}/${IOC_NAME}.conf" ]]; then conf_exist="true"; fi
    verify_state "true" "${conf_exist}" "Directory-based installation succeeded"
}

function test_cleanup_install {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Cleanup Installation"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" remove "${IOC_NAME}" >/dev/null 2>&1 || true

    local conf_exist="true"
    if [[ ! -f "${CONF_DIR}/${IOC_NAME}.conf" ]]; then conf_exist="false"; fi
    verify_state "false" "${conf_exist}" "Deployed configuration safely removed"
}

function test_cleanup_conf {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Cleanup Artifact"
    print_sub_divider

    rm -f "${CONF_FILE}"

    local conf_exist="true"
    if [[ ! -f "${CONF_FILE}" ]]; then conf_exist="false"; fi
    verify_state "false" "${conf_exist}" "Workspace configuration artifact removed"
}

function test_start {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Start Command"
    print_sub_divider

    local start_time=${SECONDS}

    bash "${RUNNER_SCRIPT}" start "${IOC_NAME}"
    _log "INFO" "Waiting for IOC to initialize (smart polling)..."
    # A state timeout must not abort the suite under set -e; the
    # following verify_state is the counted, honest assertion.
    wait_for_state "active" || true

    local state
    state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${IOC_NAME}.service" || true)

    local elapsed=$((SECONDS - start_time))
    verify_state "active" "${state}" "Service state is 'active' (Startup time: ${elapsed}s)"
}

function test_status {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Status Command"
    print_sub_divider

    local output
    output=$(bash "${RUNNER_SCRIPT}" status "${IOC_NAME}" 2>&1 || true)

    local active_in_output="false"
    if printf "%s" "${output}" | grep -q "Active: active"; then active_in_output="true"; fi
    verify_state "true" "${active_in_output}" "Status output shows 'Active: active'"
}

function test_view {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test View Command"
    print_sub_divider

    local output
    output=$(bash "${RUNNER_SCRIPT}" view "${IOC_NAME}" 2>&1 || true)

    local conf_in_output="false"
    # The error path echoes the IOC name too; only a conf-content token
    # proves the configuration actually rendered (M8/#111).
    if printf "%s" "${output}" | grep -q "IOC_CMD="; then conf_in_output="true"; fi
    verify_state "true" "${conf_in_output}" "View output renders the configuration (IOC_CMD=)"
}

function test_restart {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Restart Command"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" restart "${IOC_NAME}"
    # A state timeout must not abort the suite under set -e; the
    # following verify_state is the counted, honest assertion.
    wait_for_state "active" || true

    local state
    state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${IOC_NAME}.service" || true)
    verify_state "active" "${state}" "Service remains active after restart"
}

function test_stop {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Stop Command"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" stop "${IOC_NAME}"

    local state
    state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${IOC_NAME}.service" || true)
    verify_state "inactive" "${state}" "Service is inactive after stop"

    _log "INFO" "Waiting for systemd to cleanup asynchronous resources..."
    sleep 2

    bash "${RUNNER_SCRIPT}" start "${IOC_NAME}"
    # A state timeout must not abort the suite under set -e; the
    # following verify_state is the counted, honest assertion.
    wait_for_state "active" || true

    state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${IOC_NAME}.service" || true)
    verify_state "active" "${state}" "Service is active after restart following stop"
}

function test_socket_list {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test List and Socket Creation"
    print_sub_divider

    local socket_exist="false"
    if [[ -S "${UDS_PATH}" ]]; then socket_exist="true"; fi
    verify_state "true" "${socket_exist}" "UNIX Domain Socket explicitly created"

    local output
    output=$(bash "${RUNNER_SCRIPT}" list)

    local ioc_in_output="false"
    local uds_in_output="false"

    if printf "%s" "${output}" | grep -q "${IOC_NAME}";  then ioc_in_output="true"; fi
    if printf "%s" "${output}" | grep -q "${UDS_PATH}";  then uds_in_output="true"; fi

    verify_state "true" "${ioc_in_output}"      "IOC name appears in list output"
    verify_state "true" "${uds_in_output}"      "UDS socket path appears in list output"

    local output_v
    output_v=$(bash "${RUNNER_SCRIPT}" -v list)

    local pid_in_output="false"
    local cpu_in_output="false"
    local mem_in_output="false"
    if printf "%s" "${output_v}" | grep -q "PID";   then pid_in_output="true"; fi
    if printf "%s" "${output_v}" | grep -q "CPU";   then cpu_in_output="true"; fi
    if printf "%s" "${output_v}" | grep -q "MEM";   then mem_in_output="true"; fi

    verify_state "true" "${pid_in_output}" "List -v output contains PID column"
    verify_state "true" "${cpu_in_output}" "List -v output contains CPU column"
    verify_state "true" "${mem_in_output}" "List -v output contains MEM column"

    local output_vv
    output_vv=$(bash "${RUNNER_SCRIPT}" -vv list)

    local recv_in_output="false"
    local sq_in_output="false"
    local perm_in_output="false"

    if printf "%s" "${output_vv}" | grep -q "RQ"; then recv_in_output="true"; fi
    if printf "%s" "${output_vv}" | grep -q "SQ"; then sq_in_output="true"; fi
    if printf "%s" "${output_vv}" | grep -q "PERM";   then perm_in_output="true"; fi

    verify_state "true" "${recv_in_output}" "List -vv output contains Recv-Q column"
    verify_state "true" "${sq_in_output}" "List -vv output contains Send-Q column"
    verify_state "true" "${perm_in_output}" "List -vv output contains PERM column"
}

function test_console_attach {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Automated Console Attach Verification"
    print_sub_divider

    local socket_perm
    socket_perm=$(stat -c "%A" "${UDS_PATH}")

    local perm_ok="false"
    if [[ "${socket_perm}" == "srw-rw----" ]]; then perm_ok="true"; fi
    verify_state "true" "${perm_ok}" "UDS socket has correct permissions (srw-rw----)"

    # Probe con exactly where bin/ioc-runner's resolve_con_tool searches in
    # system mode (/usr/local/bin, then /usr/bin); the runner never consults
    # PATH for con, so neither does the probe. The runner's socat fallback is
    # not mirrored: this check asserts the con utility itself.
    local con_ok="false" con_candidate
    for con_candidate in /usr/local/bin/con /usr/bin/con; do
        if [[ -x "${con_candidate}" ]]; then
            con_ok="true"
            break
        fi
    done
    verify_state "true" "${con_ok}" "con utility is available"

    local socket_listening="false"
    if ss -lx 2>/dev/null | grep -q "${UDS_PATH}"; then socket_listening="true"; fi
    verify_state "true" "${socket_listening}" "UDS socket is in listening state"
}

function test_channel_access {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test EPICS Channel Access (camonitor)"
    print_sub_divider

    local camonitor_cmd
    if command -v camonitor >/dev/null 2>&1; then
        camonitor_cmd="camonitor"
    else
        camonitor_cmd="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}/camonitor"
    fi

    if [[ ! -x "${camonitor_cmd}" ]] && ! command -v "${camonitor_cmd}" >/dev/null 2>&1; then
        _log "ERROR" "camonitor utility not found. Cannot verify PV."
        verify_state "found" "not_found" "camonitor executable availability"
        close_current_remaining SKIP "requires ${SUITE_ID}.S23.camonitor-available"
        return 0
    fi
    record_current_state PASS

    local test_pv="LBNL:TESTIOC:aiExample"
    _log "INFO" "Monitoring PV: ${test_pv} (${CAMONITOR_COUNT} updates)"

    export EPICS_CA_ADDR_LIST="127.0.0.1"
    export EPICS_CA_AUTO_ADDR_LIST="NO"
    # Reach the test IOC on its dedicated port; the server side is set in the conf.
    export EPICS_CA_SERVER_PORT="${TEST_CA_PORT}"

    local read_start_time=${SECONDS}
    local pv_ok="false"
    local success_count=0

    local line pv_val
    while IFS= read -r line; do
        [[ -z "${line}" ]] && continue
        pv_val=$(printf "%s" "${line}" | awk '{print $2}' | tr -d '\r')
        # Count numeric value samples only. Connection/status lines (e.g.
        # "***" during PV reconnect) carry no value and are skipped, not
        # counted, keeping the sample count stable across reconnect timing.
        [[ "${pv_val}" =~ ^[0-9]+(\.[0-9]+)?$ ]] || continue
        success_count=$((success_count + 1))
        _log "SUCCESS" "Update [${success_count}/${CAMONITOR_COUNT}] PV ${test_pv} = ${pv_val}"
        [[ ${success_count} -ge ${CAMONITOR_COUNT} ]] && break
    done < <(timeout "${CAMONITOR_TIMEOUT}" "${camonitor_cmd}" -w "${CAMONITOR_TIMEOUT}" -t n "${test_pv}" 2>/dev/null || true)

    local elapsed=$((SECONDS - read_start_time))

    if [[ ${success_count} -eq ${CAMONITOR_COUNT} ]]; then
        pv_ok="true"
    fi

    verify_state "true" "${pv_ok}" "Channel Access monitored ${CAMONITOR_COUNT} updates successfully (Time: ${elapsed}s)"
}

function test_list_options {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test List Option Parsing Flexibility"
    print_sub_divider

    local out_1
    local out_2
    out_1=$(bash "${RUNNER_SCRIPT}" list -v | grep "${IOC_NAME}" | awk '{print $1}' | tr -d ' ')
    out_2=$(bash "${RUNNER_SCRIPT}" -v list | grep "${IOC_NAME}" | awk '{print $1}' | tr -d ' ')

    verify_state "${IOC_NAME}" "${out_1}" "Parsed: list -v"
    verify_state "${IOC_NAME}" "${out_2}" "Parsed: -v list"
}

function test_inspect_and_multiple_connections {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Inspect Command Parsing"
    print_sub_divider

    # System Note: The explicit dummy connection and CON check were removed
    # as the Linux kernel obscures ESTABLISHED UDS paths in standard outputs.
    # We now solely verify the 'inspect' command executes successfully and
    # retrieves the server's Netlink context.

    local inspect_out
    inspect_out=$(bash "${RUNNER_SCRIPT}" inspect "${IOC_NAME}" 2>&1 || true)

    local server_pid_detected="false"
    if printf "%s" "${inspect_out}" | grep -q "Server Process Context"; then
        server_pid_detected="true"
    fi

    verify_state "true" "${server_pid_detected}" "Inspect command successfully retrieved server Netlink context"

    # Regression guard: lsof must scope to the target socket via -a (AND).
    # Without -a, lsof's default OR semantics would dump every UNIX socket
    # on the host (systemd PID 1, journal, D-Bus, etc.).
    local has_target_sock="false"
    local has_systemd_noise="false"

    if printf "%s" "${inspect_out}" | grep -qF "${UDS_PATH}"; then
        has_target_sock="true"
    fi
    if printf "%s" "${inspect_out}" | grep -qE "^systemd[[:space:]]+[0-9]+[[:space:]]+root[[:space:]]+.+/run/systemd/"; then
        has_systemd_noise="true"
    fi

    verify_state "true"  "${has_target_sock}"   "Inspect section 1 references the target socket path"
    verify_state "false" "${has_systemd_noise}" "Inspect section 1 excludes unrelated systemd UDS entries"
}

function test_monitor_isolation {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Monitor Input Isolation"
    print_sub_divider

    if [[ "${JOURNAL_AVAILABLE}" != "true" ]]; then
        _log "WARN" "System journal unavailable, skipping monitor isolation test."
        record_current_state SKIP "system journal is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S25.system-journal-available"
        return 0
    fi
    record_current_state PASS

    # Positive control (R8-F2): prove the unit's journal channel is
    # visible before asserting the marker's ABSENCE; the empty-window
    # "-- No entries --" banner lands on stdout and must be excluded.
    local probe_out
    probe_out=$(journalctl -u "epics-@${IOC_NAME}.service" -n 5 --no-pager 2>/dev/null || true)
    local journal_visible="false"
    if [[ -n "${probe_out}" && "${probe_out}" != *"-- No entries --"* ]]; then
        journal_visible="true"
    fi
    verify_state "true" "${journal_visible}" "Journal channel visible for unit (positive control)"

    printf "test_monitor_input_blocked\\n" | setsid bash "${RUNNER_SCRIPT}" monitor "${IOC_NAME}" >/dev/null 2>&1 &
    local monitor_pid=$!
    sleep 2

    local log_out
    log_out=$(journalctl -u "epics-@${IOC_NAME}.service" --since "5 seconds ago" || true)

    local input_blocked="true"
    if printf "%s" "${log_out}" | grep -q "test_monitor_input_blocked"; then
        input_blocked="false"
    fi

    verify_state "true" "${input_blocked}" "Input securely blocked in monitor mode"

    kill -- -"${monitor_pid}" 2>/dev/null || true
}


# Runs one benign FATAL token-boundary case through the installed system unit,
# then verifies the start result, operator verdict, and emitted fixture.
function _run_system_fatal_boundary_probe {
    local softioc_bin="$1"
    local ioc_name="$2"
    local ioc_dir="$3"
    local fixture="$4"
    local assertion_name="$5"
    local log_file="${SYSTEM_LOG_DIR}/${ioc_name}.log"
    local output=""
    local rc=0
    local rc_ok="false"
    local msg_ok="true"
    local emitted="false"

    mkdir -p "${ioc_dir}"
    chown "${OWNER_WORKSPACE}" "${ioc_dir}"
    chmod 2775 "${ioc_dir}"

    cat << EOF > "${ioc_dir}/st.cmd"
#!${softioc_bin}
system "echo '${fixture}'"
iocInit()
EOF
    chown "${OWNER_WORKSPACE}" "${ioc_dir}/st.cmd"
    chmod 0750 "${ioc_dir}/st.cmd"

    cat << EOF > "${WORKSPACE}/${ioc_name}.conf"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${ioc_dir}"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF

    bash "${RUNNER_SCRIPT}" -f install "${WORKSPACE}/${ioc_name}.conf" >/dev/null
    output=$(bash "${RUNNER_SCRIPT}" start "${ioc_name}" 2>&1) || rc=$?
    bash "${RUNNER_SCRIPT}" remove "${ioc_name}" >/dev/null 2>&1 || true

    if [[ "${rc}" == "0" ]]; then
        rc_ok="true"
    fi
    if printf "%s" "${output}" | grep -q "failed to initialize"; then
        msg_ok="false"
    fi
    if grep -qF -- "${fixture}" "${log_file}"; then
        emitted="true"
    fi
    verify_state "true" "${rc_ok}" "${assertion_name}: exit 0"
    verify_state "true" "${msg_ok}" "${assertion_name}: no failed verdict"
    verify_state "true" "${emitted}" "${assertion_name}: fixture emitted"
}

# Exercises each benign FATAL token boundary and a true pre-init fatal token.
# The runner reads procServ logs as the invoking engineer, independent of
# system-journal or adm group membership.
function test_crash_detection {
    local step="$1"
    local softioc_bin="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}/softIoc"
    local bad_ioc_name="CrashTestIOC-SYS"
    local bad_ioc_dir="${WORKSPACE}/bad_ioc"
    local output=""
    local rc=0
    local rc_ok="false"
    local msg_ok="false"

    print_divider
    _log "INFO" "STEP ${step}: Test Crash Detection with softIoc"
    print_sub_divider

    if [[ ! -x "${softioc_bin}" ]]; then
        _log "WARN" "softIoc not found at ${softioc_bin}, skipping crash detection test."
        record_current_state SKIP "softIoc is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S26.softioc-available"
        return 0
    fi
    record_current_state PASS

    _run_system_fatal_boundary_probe \
        "${softioc_bin}" \
        "CrashTestFatalLeadingBoundary-SYS" \
        "${WORKSPACE}/crash_fatal_leading_boundary_ioc" \
        "device_nonfatal=ready" \
        "Leading-boundary identifier adjacency"
    _run_system_fatal_boundary_probe \
        "${softioc_bin}" \
        "CrashTestFatalTrailingBoundary-SYS" \
        "${WORKSPACE}/crash_fatal_trailing_boundary_ioc" \
        "fatalFlag=ready" \
        "Trailing-boundary identifier adjacency"
    _run_system_fatal_boundary_probe \
        "${softioc_bin}" \
        "CrashTestFatalBoundary-SYS" \
        "${WORKSPACE}/crash_fatal_boundary_ioc" \
        "device_nonfatal_state=ready" \
        "Identifier-contained fatal text"

    mkdir -p "${bad_ioc_dir}"
    chown "${OWNER_WORKSPACE}" "${bad_ioc_dir}"
    chmod 2775 "${bad_ioc_dir}"

    cat << EOF > "${bad_ioc_dir}/st.cmd"
#!${softioc_bin}
system "sleep 0.5"
system "echo 'FATAL: Simulated softIoc crash'"
system "kill -9 \$PPID"
EOF
    chown "${OWNER_WORKSPACE}" "${bad_ioc_dir}/st.cmd"
    chmod 0750 "${bad_ioc_dir}/st.cmd"

    cat << EOF > "${WORKSPACE}/${bad_ioc_name}.conf"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${bad_ioc_dir}"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF

    bash "${RUNNER_SCRIPT}" -f install "${WORKSPACE}/${bad_ioc_name}.conf" >/dev/null

    output=$(bash "${RUNNER_SCRIPT}" start "${bad_ioc_name}" 2>&1) || rc=$?

    bash "${RUNNER_SCRIPT}" remove "${bad_ioc_name}" >/dev/null 2>&1 || true

    # M11/#67: a FATAL-subset token before iocInit is a hard failure (exit 1 with
    # the failed-to-initialize verdict), not the old active-IOC Warning.
    if [[ "${rc}" == "1" ]]; then rc_ok="true"; fi
    if printf "%s" "${output}" | grep -q "failed to initialize"; then msg_ok="true"; fi
    verify_state "true" "${rc_ok}" "Broken softIoc (FATAL pre-init) -> exit 1"
    verify_state "true" "${msg_ok}" "Broken softIoc -> failed-to-initialize verdict"
}

# T1 (Phase E): crash detection without journal access. An operator who is an
# ioc-group member (so the %ioc sudoers gate lets them start the service) but
# is NOT in systemd-journal must still get the crash warning -- 1.1.0 scans the
# dedicated log file, not the journal. On 1.0.8 the journal scan would hand this
# operator empty output and a false success, so T1 is a natural baseline-fail.
function test_detection_without_journal {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Crash Detection Without Journal Access (T1)"
    print_sub_divider

    local softioc_bin="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}/softIoc"
    if [[ ! -x "${softioc_bin}" ]]; then
        _log "WARN" "softIoc not found at ${softioc_bin}, skipping journal-less detection test."
        record_current_state SKIP "softIoc is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S27.softioc-available"
        return 0
    fi
    record_current_state PASS

    local operator="epics-t1-operator"
    # Never touch a pre-existing account of this name: it may not be ours.
    if id "${operator}" &>/dev/null; then
        _log "WARN" "User ${operator} already exists; skipping to avoid removing a non-test account."
        record_current_state SKIP "probe user name is already in use"
        close_current_remaining SKIP "requires ${SUITE_ID}.S27.probe-user-name-available"
        return 0
    fi
    record_current_state PASS
    useradd -M -N -G "${SYSTEM_GROUP}" "${operator}" >/dev/null 2>&1
    T1_CREATED_USER="${operator}"

    # The whole point: ioc member (sudoers gate reachable) but no systemd-journal.
    local op_groups in_ioc="false" in_journal="false"
    op_groups=$(id -nG "${operator}" 2>/dev/null)
    if printf "%s" "${op_groups}" | grep -qw "${SYSTEM_GROUP}"; then in_ioc="true"; fi
    if printf "%s" "${op_groups}" | grep -qw "systemd-journal"; then in_journal="true"; fi
    verify_state "true" "${in_ioc}" "Operator is an ioc-group member (sudoers gate reachable)"
    verify_state "false" "${in_journal}" "Operator is NOT in systemd-journal"

    local bad_ioc_name="JournalLessIOC-SYS"
    local bad_ioc_dir="${WORKSPACE}/journalless_ioc"
    mkdir -p "${bad_ioc_dir}"
    chown "${OWNER_WORKSPACE}" "${bad_ioc_dir}"
    chmod 2775 "${bad_ioc_dir}"

    # Malformed st.cmd: an unbalanced quote drives an iocsh parse error whose
    # crash pattern (Unbalanced quote) must land in the dedicated log file.
    cat << EOF > "${bad_ioc_dir}/st.cmd"
#!${softioc_bin}
epicsEnvSet("BROKEN", "unterminated
EOF
    chown "${OWNER_WORKSPACE}" "${bad_ioc_dir}/st.cmd"
    chmod 0750 "${bad_ioc_dir}/st.cmd"

    cat << EOF > "${WORKSPACE}/${bad_ioc_name}.conf"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${bad_ioc_dir}"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF

    bash "${RUNNER_SCRIPT}" -f install "${WORKSPACE}/${bad_ioc_name}.conf" >/dev/null

    # The operator (no systemd-journal) starts the IOC; crash detection must
    # still warn, proving it reads the log file rather than the journal.
    local output rc=0
    output=$(runuser -u "${operator}" -- bash "${RUNNER_SCRIPT}" start "${bad_ioc_name}" 2>&1) || rc=$?

    # M11/#67: the unbalanced-quote parse error (Unbalanced quote, a FATAL token)
    # before iocInit -> exit 1 failed-to-initialize, read from the dedicated log
    # file (not the journal), proving journal-less detection still works.
    local rc_ok="false" msg_ok="false"
    if [[ "${rc}" == "1" ]]; then rc_ok="true"; fi
    if printf "%s" "${output}" | grep -q "failed to initialize"; then msg_ok="true"; fi
    verify_state "true" "${rc_ok}" "Journal-less operator: crash -> exit 1"
    verify_state "true" "${msg_ok}" "Journal-less operator: failed-to-initialize verdict (reads log file, not journal)"

    bash "${RUNNER_SCRIPT}" remove "${bad_ioc_name}" >/dev/null 2>&1 || true
    userdel "${operator}" 2>/dev/null || true
    T1_CREATED_USER=""
}

# T2 (Phase E): crash detection across a logrotate boundary. A fatal pattern
# present in the log BEFORE rotation must move into the rotated/compressed file
# (copytruncate) and must NOT be re-scanned by the post-restart startup window,
# which begins at the post-rotation offset. Otherwise a single historical crash
# would raise a false crash warning on every subsequent restart.
function test_logrotate_boundary {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Crash Detection Across Logrotate Boundary (T2)"
    print_sub_divider

    local logrotate_conf="/etc/logrotate.d/procserv"
    local softioc_bin="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}/softIoc"
    if [[ ! -f "${logrotate_conf}" ]]; then
        _log "WARN" "${logrotate_conf} not found, skipping logrotate boundary test."
        verify_state "true" "false" "System logrotate policy exists"
        close_current_remaining SKIP "requires ${SUITE_ID}.S28.logrotate-policy-exists"
        return 0
    fi
    record_current_state PASS
    if [[ ! -x "${softioc_bin}" ]]; then
        _log "WARN" "softIoc not found at ${softioc_bin}, skipping logrotate boundary test."
        record_current_state SKIP "softIoc is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S28.softioc-available"
        return 0
    fi
    record_current_state PASS

    # Resolve logrotate the way bin/ioc-runner's resolve_logrotate_tool does
    # (a second copy of its LOGROTATE_SEARCH_PATHS, like the local suite's
    # probe): root's PATH normally carries sbin, but under set -e a bare name
    # that fails to resolve would abort the whole suite instead of skipping.
    local logrotate_bin="" logrotate_candidate
    for logrotate_candidate in /usr/sbin/logrotate /sbin/logrotate /usr/bin/logrotate; do
        if [[ -x "${logrotate_candidate}" ]]; then
            logrotate_bin="${logrotate_candidate}"
            break
        fi
    done
    if [[ -z "${logrotate_bin}" ]]; then
        logrotate_bin=$(command -v logrotate 2>/dev/null || true)
    fi
    if [[ -z "${logrotate_bin}" ]]; then
        _log "WARN" "logrotate not found, skipping logrotate boundary test."
        record_current_state SKIP "logrotate is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S28.logrotate-available"
        return 0
    fi
    record_current_state PASS

    # M11/#67: the T2 fixtures intentionally never call iocInit (they stay in the
    # pre-marker phase so an in-window FATAL is a deterministic exit-1), so the
    # marker-less clean cases would otherwise wait out the full readiness timeout.
    # Shrink the readiness timeout via the test seam (D025) to keep T2 fast.
    export IOC_RUNNER_TEST_MAX_INIT_TIMEOUT=8
    export IOC_RUNNER_TEST_CONFIRM_DWELL=1

    local rot_ioc_name="RotateTestIOC-SYS"
    local rot_ioc_dir="${WORKSPACE}/rotate_ioc"
    local log_file="${SYSTEM_LOG_DIR}/${rot_ioc_name}.log"
    mkdir -p "${rot_ioc_dir}"
    # ioc-srv must be able to write runtime artifacts under IOC_CHDIR; otherwise
    # the startup permission errors would themselves trip crash detection and
    # mask the historical-pattern boundary this test actually probes.
    chown "${OWNER_WORKSPACE}" "${rot_ioc_dir}"
    chmod 2775 "${rot_ioc_dir}"

    # Healthy IOC: stays up and emits no crash pattern of its own. The probe dir
    # is group-writable (2775 above), so the iocsh history-file write succeeds
    # and cannot leak a crash pattern into the startup scan window. No knob is
    # needed: IOCSH_HISTSIZE does not gate the file (it bounds the in-memory list
    # only; the file is gated by EPICS_IOCSH_HISTFILE), and an epicsEnvSet inside
    # st.cmd runs after history setup anyway.
    cat << EOF > "${rot_ioc_dir}/st.cmd"
#!${softioc_bin}
system "sleep 0.5"
EOF
    chown "${OWNER_WORKSPACE}" "${rot_ioc_dir}/st.cmd"
    chmod 0750 "${rot_ioc_dir}/st.cmd"

    cat << EOF > "${WORKSPACE}/${rot_ioc_name}.conf"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${rot_ioc_dir}"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF

    bash "${RUNNER_SCRIPT}" -f install "${WORKSPACE}/${rot_ioc_name}.conf" >/dev/null
    bash "${RUNNER_SCRIPT}" start "${rot_ioc_name}" >/dev/null 2>&1 || true

    # Inject a fatal pattern into the ACTIVE log, ahead of rotation.
    local crash_marker="FATAL: synthetic pre-rotate crash marker"
    printf "%s\n" "${crash_marker}" >> "${log_file}"

    # Force rotation: copytruncate moves history into <name>.log.1.gz and
    # truncates the active log in place.
    "${logrotate_bin}" -f "${logrotate_conf}" >/dev/null 2>&1

    # Evidence 1 (boundary created): the marker now lives in the rotated file
    # and no longer in the active log.
    local rotated_has_marker="false"
    if [[ -f "${log_file}.1.gz" ]] && zgrep -qF "${crash_marker}" "${log_file}.1.gz" 2>/dev/null; then
        rotated_has_marker="true"
    fi
    verify_state "true" "${rotated_has_marker}" "Pre-rotate FATAL pattern moved into rotated log (boundary created)"

    local active_clean="true"
    if grep -qF "${crash_marker}" "${log_file}" 2>/dev/null; then
        active_clean="false"
    fi
    verify_state "true" "${active_clean}" "Active log cleared of the pre-rotate FATAL pattern after rotation"

    # Evidence 2 (no false positive): restart after rotation must not re-flag
    # the historical pattern that now lives only in the rotated file.
    local output
    output=$(bash "${RUNNER_SCRIPT}" restart "${rot_ioc_name}" 2>&1 || true)

    # M11/#67: the historical FATAL now lives only in the rotated file, outside the
    # post-restart scan window, so no crash verdict (failed-to-initialize) is raised
    # -- the marker-less clean restart yields only the readiness-timeout Warning.
    local false_positive="false"
    if printf "%s" "${output}" | grep -q "failed to initialize"; then
        false_positive="true"
    fi
    verify_state "false" "${false_positive}" "No false crash verdict from rotated historical FATAL pattern"

    # --- T2 sub-case A: new-inode replacement during the sleep window (#58)
    # Background a restart and gate the log mutation on the unit's
    # ActiveEnterTimestampMonotonic actually changing -- this guarantees
    # the runner has completed its pre-restart capture and is now inside
    # its post-restart sleep window, which a fixed sleep cannot. Then swap
    # the active log file with a new-inode file. The replacement MUST grow
    # past the captured offset, otherwise the existing size-shrink guard
    # could rescue a missing inode check. mv, install, and the active-path
    # inode change are each verified so a degraded setup cannot be misread
    # as a successful inode-branch fire.
    print_sub_divider
    _log "INFO" "T2 sub-case A: New-inode replacement during sleep window"

    printf "T2 sub-case A priming line for inode/size context\n" >> "${log_file}"
    sleep 0.2
    local pre_a_size pre_a_inode pre_a_active_ts
    pre_a_size=$(stat -c '%s' "${log_file}" 2>/dev/null || printf "0")
    pre_a_inode=$(stat -c '%i' "${log_file}" 2>/dev/null || printf "")
    pre_a_active_ts=$(systemctl show "epics-@${rot_ioc_name}.service" --property=ActiveEnterTimestampMonotonic --value 2>/dev/null || printf "")

    local sub_a_marker="FATAL: synthetic in-window inode replacement"
    local sub_a_out="${WORKSPACE}/t2_sub_a.out"
    local sub_a_old="${log_file}.t2_sub_a.old"
    local sub_a_mv_ok="true" sub_a_install_ok="true"

    bash "${RUNNER_SCRIPT}" restart "${rot_ioc_name}" >"${sub_a_out}" 2>&1 &
    local sub_a_pid=$!

    local sub_a_activation="false"
    local sub_a_deadline=$((SECONDS + 20))
    local sub_a_cur_ts
    while [[ ${SECONDS} -lt ${sub_a_deadline} ]]; do
        sub_a_cur_ts=$(systemctl show "epics-@${rot_ioc_name}.service" --property=ActiveEnterTimestampMonotonic --value 2>/dev/null || printf "")
        if [[ -n "${sub_a_cur_ts}" && "${sub_a_cur_ts}" != "0" && "${sub_a_cur_ts}" != "${pre_a_active_ts}" ]]; then
            sub_a_activation="true"
            break
        fi
        sleep 0.1
    done
    verify_state "true" "${sub_a_activation}" "T2 sub-case A: restart activation observed before log mutation"

    mv "${log_file}" "${sub_a_old}" || sub_a_mv_ok="false"
    install -o "${SYSTEM_USER}" -g "${SYSTEM_GROUP}" -m 0644 /dev/null "${log_file}" || sub_a_install_ok="false"
    printf "%s\n" "${sub_a_marker}" >> "${log_file}"
    # Grow the replacement past the captured offset so the size guard
    # alone cannot detect the rotation; only the inode branch can.
    yes X 2>/dev/null | head -c "$((pre_a_size + 1024))" >> "${log_file}" || true

    wait "${sub_a_pid}" || true

    verify_state "true" "${sub_a_mv_ok}" "T2 sub-case A: log mv to side-name succeeded"
    verify_state "true" "${sub_a_install_ok}" "T2 sub-case A: replacement log install succeeded"

    local post_a_inode
    post_a_inode=$(stat -c '%i' "${log_file}" 2>/dev/null || printf "")
    local sub_a_inode_changed="false"
    if [[ -n "${pre_a_inode}" && -n "${post_a_inode}" && "${pre_a_inode}" != "${post_a_inode}" ]]; then
        sub_a_inode_changed="true"
    fi
    verify_state "true" "${sub_a_inode_changed}" "T2 sub-case A: active log inode actually changed after replacement"

    local sub_a_caught="false"
    if grep -q "failed to initialize" "${sub_a_out}" 2>/dev/null; then
        sub_a_caught="true"
    fi
    verify_state "true" "${sub_a_caught}" "T2 sub-case A: in-window new-inode replacement triggers crash verdict (exit 1)"

    rm -f "${sub_a_old}"

    # --- T2 sub-case B: same-inode truncate-and-regrow-past during the
    # sleep window (#58). Seed the active log so the captured tailhash
    # spans a non-trivial byte range, then gate the mutation on the unit's
    # ActiveEnterTimestampMonotonic actually changing so the truncate is
    # guaranteed to land between the runner's capture and its scan. inode
    # and size guards alone cannot tell this apart from healthy growth:
    # inode unchanged, current_size > captured offset. The tailhash guard
    # fires because the byte window ending at the captured offset is now
    # different content, so the scanner re-scans from offset 0.
    print_sub_divider
    _log "INFO" "T2 sub-case B: Same-inode truncate-and-regrow-past during sleep window"

    printf "T2 sub-case B priming line for tailhash range\n" >> "${log_file}"
    sleep 0.2
    local pre_cap_size pre_b_active_ts
    pre_cap_size=$(stat -c '%s' "${log_file}" 2>/dev/null || printf "0")
    pre_b_active_ts=$(systemctl show "epics-@${rot_ioc_name}.service" --property=ActiveEnterTimestampMonotonic --value 2>/dev/null || printf "")

    local sub_b_marker="FATAL: synthetic same-inode regrow past offset"
    local sub_b_out="${WORKSPACE}/t2_sub_b.out"

    bash "${RUNNER_SCRIPT}" restart "${rot_ioc_name}" >"${sub_b_out}" 2>&1 &
    local sub_b_pid=$!

    local sub_b_activation="false"
    local sub_b_deadline=$((SECONDS + 20))
    local sub_b_cur_ts
    while [[ ${SECONDS} -lt ${sub_b_deadline} ]]; do
        sub_b_cur_ts=$(systemctl show "epics-@${rot_ioc_name}.service" --property=ActiveEnterTimestampMonotonic --value 2>/dev/null || printf "")
        if [[ -n "${sub_b_cur_ts}" && "${sub_b_cur_ts}" != "0" && "${sub_b_cur_ts}" != "${pre_b_active_ts}" ]]; then
            sub_b_activation="true"
            break
        fi
        sleep 0.1
    done
    verify_state "true" "${sub_b_activation}" "T2 sub-case B: restart activation observed before log mutation"

    : > "${log_file}"
    printf "%s\n" "${sub_b_marker}" >> "${log_file}"
    yes X 2>/dev/null | head -c "$((pre_cap_size + 1024))" >> "${log_file}" || true

    wait "${sub_b_pid}" || true

    local sub_b_caught="false"
    if grep -q "failed to initialize" "${sub_b_out}" 2>/dev/null; then
        sub_b_caught="true"
    fi
    verify_state "true" "${sub_b_caught}" "T2 sub-case B: in-window same-inode regrow-past triggers crash verdict via tailhash mismatch"

    bash "${RUNNER_SCRIPT}" remove "${rot_ioc_name}" >/dev/null 2>&1 || true
    unset IOC_RUNNER_TEST_MAX_INIT_TIMEOUT IOC_RUNNER_TEST_CONFIRM_DWELL
}

# T5 (Phase E): permission enforcement. A user outside the ioc group must be
# able to READ a log file (mode 0644, o+r) yet must be DENIED a state-changing
# systemctl start -- the %ioc sudoers gate, not file mode, is the boundary for
# IOC state changes. The test account is created only if absent and removed only
# if this run created it (function tail plus the exit trap).
function test_permission_enforcement {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Permission Enforcement (T5)"
    print_sub_divider

    local softioc_bin="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}/softIoc"
    if [[ ! -f "${SUDOERS_FILE_PATH}" ]]; then
        _log "WARN" "${SUDOERS_FILE_PATH} not found, skipping permission enforcement test."
        verify_state "true" "false" "System sudoers policy exists"
        close_current_remaining SKIP "requires ${SUITE_ID}.S29.sudoers-policy-exists"
        return 0
    fi
    record_current_state PASS
    if [[ ! -x "${softioc_bin}" ]]; then
        _log "WARN" "softIoc not found at ${softioc_bin}, skipping permission enforcement test."
        record_current_state SKIP "softIoc is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S29.softioc-available"
        return 0
    fi
    record_current_state PASS

    local nonioc_user="epics-t5-noioc"
    # Never touch a pre-existing account of this name: it may not be ours.
    if id "${nonioc_user}" &>/dev/null; then
        _log "WARN" "User ${nonioc_user} already exists; skipping to avoid removing a non-test account."
        record_current_state SKIP "probe user name is already in use"
        close_current_remaining SKIP "requires ${SUITE_ID}.S29.probe-user-name-available"
        return 0
    fi
    record_current_state PASS
    useradd -M -N "${nonioc_user}" >/dev/null 2>&1
    T5_CREATED_USER="${nonioc_user}"

    # Guard: the test account must not be an ioc-group member, or the gate check
    # below would be meaningless.
    if id -nG "${nonioc_user}" 2>/dev/null | grep -qw "${SYSTEM_GROUP}"; then
        _log "WARN" "Test user unexpectedly in ${SYSTEM_GROUP}; skipping."
        verify_state "false" "true" "Probe user is not an ioc-group member"
        close_current_remaining SKIP "requires ${SUITE_ID}.S29.probe-user-not-ioc-member"
        userdel "${nonioc_user}" 2>/dev/null || true
        T5_CREATED_USER=""
        return 0
    fi
    record_current_state PASS

    local perm_ioc_name="PermTestIOC-SYS"
    local perm_ioc_dir="${WORKSPACE}/perm_ioc"
    local log_file="${SYSTEM_LOG_DIR}/${perm_ioc_name}.log"
    mkdir -p "${perm_ioc_dir}"
    chown "${OWNER_WORKSPACE}" "${perm_ioc_dir}"
    chmod 2775 "${perm_ioc_dir}"

    cat << EOF > "${perm_ioc_dir}/st.cmd"
#!${softioc_bin}
system "sleep 0.5"
EOF
    chown "${OWNER_WORKSPACE}" "${perm_ioc_dir}/st.cmd"
    chmod 0750 "${perm_ioc_dir}/st.cmd"

    cat << EOF > "${WORKSPACE}/${perm_ioc_name}.conf"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${perm_ioc_dir}"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF

    bash "${RUNNER_SCRIPT}" -f install "${WORKSPACE}/${perm_ioc_name}.conf" >/dev/null
    bash "${RUNNER_SCRIPT}" start "${perm_ioc_name}" >/dev/null 2>&1 || true

    # Evidence 1: a user outside ioc can READ the log (file mode 0644, o+r).
    local read_ok="false"
    if runuser -u "${nonioc_user}" -- cat "${log_file}" >/dev/null 2>&1; then
        read_ok="true"
    fi
    verify_state "true" "${read_ok}" "Non-ioc user can read the log file (mode 0644)"

    # Evidence 2: the same user is DENIED a state-changing start -- not in the
    # %ioc sudoers gate, so sudo -n exits non-zero.
    local start_denied="false"
    if ! runuser -u "${nonioc_user}" -- sudo -n /usr/bin/systemctl start "epics-@${perm_ioc_name}.service" >/dev/null 2>&1; then
        start_denied="true"
    fi
    verify_state "true" "${start_denied}" "Non-ioc user denied systemctl start by %ioc sudoers gate"

    bash "${RUNNER_SCRIPT}" remove "${perm_ioc_name}" >/dev/null 2>&1 || true
    userdel "${nonioc_user}" 2>/dev/null || true
    T5_CREATED_USER=""
}

# System-mode IOC_CHDIR precheck. do_install runs chdir_conforms_to_system_model
# before deploying a system IOC and warns ("Warning: IOC_CHDIR ...") when the
# directory does not conform to the permission model: an absolute, non-symlinked
# dir, group-owned by ioc with setgid + group write + group execute (2775), and
# every parent traversable by the service account. Conformance is decided by real
# filesystem state, so this test builds real root-created fixtures rather than
# stubbing sudo. Each case uses its own IOC name, conf dir, and systemd dir so the
# overwrite prompt never consumes the y/N stdin token meant for the precheck prompt.
function test_chdir_precheck {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: System-mode IOC_CHDIR Precheck (permission model)"
    print_sub_divider

    # Fixture root under WORKSPACE (root:ioc 2770). The service account
    # traverses it via ioc group-execute, so no permission relaxation is
    # needed, and _handle_exit's cleanup/retention covers it even on abort.
    local base="${WORKSPACE}/precheck"
    mkdir -p "${base}"
    chown "${OWNER_WORKSPACE}" "${base}"
    chmod 2770 "${base}"

    local stderr_cap="${base}/stderr"
    local ec

    # Writes a system-mode conf for the given name with IOC_CHDIR set to chdir.
    # Caller supplies a pre-built isolated sysd/conf dir pair; here we only emit
    # the conf artifact the runner consumes.
    local sysd conf name chdir conf_file

    # Case 1: conforming dir (root:ioc 2775) with traversable parents -> no warning.
    name="PrecheckOK-SYS"
    chdir="${base}/conform"; conf_file="${base}/${name}.conf"
    sysd="${base}/s1"; conf="${base}/c1"
    mkdir -p "${chdir}" "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    chgrp "${SYSTEM_GROUP}" "${chdir}"; chmod 2775 "${chdir}"
    touch "${chdir}/st.cmd"; chmod 0755 "${chdir}/st.cmd"
    cat <<EOF > "${conf_file}"
IOC_NAME="${name}"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${chdir}"
IOC_PORT="unix:ioc-srv:ioc:0660:/run/procserv/${name}/control"
IOC_CMD="./st.cmd"
EOF
    ec=0
    IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        bash "${RUNNER_SCRIPT}" -f install "${conf_file}" >/dev/null 2>"${stderr_cap}" || ec=$?
    local warned1="warned"
    grep -q "Warning: IOC_CHDIR" "${stderr_cap}" 2>/dev/null || warned1="clean"
    verify_state "clean" "${warned1}" "Conforming root:ioc 2775 dir emits no warning"
    verify_state "0" "${ec}" "Conforming install exits 0"

    # Case 2: 2775 but group mismatch (not ioc) -> warning.
    name="PrecheckGrp-SYS"
    chdir="${base}/grpmismatch"; conf_file="${base}/${name}.conf"
    sysd="${base}/s2"; conf="${base}/c2"
    mkdir -p "${chdir}" "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    chgrp root "${chdir}"; chmod 2775 "${chdir}"
    touch "${chdir}/st.cmd"; chmod 0755 "${chdir}/st.cmd"
    cat <<EOF > "${conf_file}"
IOC_NAME="${name}"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${chdir}"
IOC_PORT="unix:ioc-srv:ioc:0660:/run/procserv/${name}/control"
IOC_CMD="./st.cmd"
EOF
    ec=0
    IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        bash "${RUNNER_SCRIPT}" -f install "${conf_file}" >/dev/null 2>"${stderr_cap}" || ec=$?
    local warned2="clean"
    grep -q "Warning: IOC_CHDIR" "${stderr_cap}" 2>/dev/null && warned2="warned"
    verify_state "warned" "${warned2}" "Group-mismatch dir (not ioc) warns"
    verify_state "0" "${ec}" "Group-mismatch install with -f exits 0"

    # Case 3: conforming leaf but a parent dir is 0700 (not traversable) -> warning.
    name="PrecheckParent-SYS"
    local p3="${base}/parent700"; chdir="${p3}/leaf"; conf_file="${base}/${name}.conf"
    sysd="${base}/s3"; conf="${base}/c3"
    mkdir -p "${chdir}" "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    chgrp "${SYSTEM_GROUP}" "${chdir}"; chmod 2775 "${chdir}"
    touch "${chdir}/st.cmd"; chmod 0755 "${chdir}/st.cmd"
    chmod 0700 "${p3}"
    cat <<EOF > "${conf_file}"
IOC_NAME="${name}"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${chdir}"
IOC_PORT="unix:ioc-srv:ioc:0660:/run/procserv/${name}/control"
IOC_CMD="./st.cmd"
EOF
    ec=0
    IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        bash "${RUNNER_SCRIPT}" -f install "${conf_file}" >/dev/null 2>"${stderr_cap}" || ec=$?
    local warned3="clean"
    grep -q "Warning: IOC_CHDIR" "${stderr_cap}" 2>/dev/null && warned3="warned"
    verify_state "warned" "${warned3}" "Untraversable 0700 parent warns"
    verify_state "0" "${ec}" "Untraversable-parent install with -f exits 0"
    chmod 0755 "${p3}"  # restore so cleanup can recurse

    # Case 4: relative IOC_CHDIR. Since M6/#109 validate_conf rejects any
    # non-absolute IOC_CHDIR outright (hard error, no -f bypass); the cd into
    # case_root keeps the directory resolvable so the absolute-path check is
    # what fires, not the missing-directory check.
    name="PrecheckRel-SYS"
    local case_root="${base}/relcase"; chdir="reldir"; conf_file="${base}/${name}.conf"
    sysd="${base}/s4"; conf="${base}/c4"
    mkdir -p "${case_root}/${chdir}" "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    chgrp "${SYSTEM_GROUP}" "${case_root}/${chdir}"; chmod 2775 "${case_root}/${chdir}"
    touch "${case_root}/${chdir}/st.cmd"; chmod 0755 "${case_root}/${chdir}/st.cmd"
    cat <<EOF > "${conf_file}"
IOC_NAME="${name}"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${chdir}"
IOC_PORT="unix:ioc-srv:ioc:0660:/run/procserv/${name}/control"
IOC_CMD="./st.cmd"
EOF
    ec=0
    IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        bash -c "cd \"${case_root}\" && bash \"${RUNNER_SCRIPT}\" -f install \"${conf_file}\"" \
        >/dev/null 2>"${stderr_cap}" || ec=$?
    local rejected4="clean"
    grep -q "IOC_CHDIR must be an absolute path" "${stderr_cap}" 2>/dev/null && rejected4="rejected"
    verify_state "rejected" "${rejected4}" "Relative IOC_CHDIR is a hard validation error (M6/#109)"
    verify_state "1" "${ec}" "Relative-path install exits 1 despite -f"

    # Case 5: IOC_CHDIR is a symlink to a conforming target (symlinked leaf rejected).
    name="PrecheckLink-SYS"
    local link_target="${base}/linktarget"; chdir="${base}/linkdir"; conf_file="${base}/${name}.conf"
    sysd="${base}/s5"; conf="${base}/c5"
    mkdir -p "${link_target}" "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    chgrp "${SYSTEM_GROUP}" "${link_target}"; chmod 2775 "${link_target}"
    touch "${link_target}/st.cmd"; chmod 0755 "${link_target}/st.cmd"
    ln -s "${link_target}" "${chdir}"
    cat <<EOF > "${conf_file}"
IOC_NAME="${name}"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${chdir}"
IOC_PORT="unix:ioc-srv:ioc:0660:/run/procserv/${name}/control"
IOC_CMD="./st.cmd"
EOF
    ec=0
    IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        bash "${RUNNER_SCRIPT}" -f install "${conf_file}" >/dev/null 2>"${stderr_cap}" || ec=$?
    local warned5="clean"
    grep -q "Warning: IOC_CHDIR" "${stderr_cap}" 2>/dev/null && warned5="warned"
    verify_state "warned" "${warned5}" "Symlinked IOC_CHDIR warns (symlinked leaf rejected)"
    verify_state "0" "${ec}" "Symlinked-leaf install with -f exits 0"

    # Case 6: root:ioc 0775 (group rwx but no setgid) -> warning.
    name="PrecheckNoSgid-SYS"
    chdir="${base}/nosetgid"; conf_file="${base}/${name}.conf"
    sysd="${base}/s6"; conf="${base}/c6"
    mkdir -p "${chdir}" "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    chgrp "${SYSTEM_GROUP}" "${chdir}"; chmod 0775 "${chdir}"
    # chmod 0775 keeps the parent-inherited setgid bit; clear it explicitly so
    # this case truly exercises a non-setgid (mode 775) directory.
    chmod g-s "${chdir}"
    touch "${chdir}/st.cmd"; chmod 0755 "${chdir}/st.cmd"
    cat <<EOF > "${conf_file}"
IOC_NAME="${name}"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${chdir}"
IOC_PORT="unix:ioc-srv:ioc:0660:/run/procserv/${name}/control"
IOC_CMD="./st.cmd"
EOF
    ec=0
    IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        bash "${RUNNER_SCRIPT}" -f install "${conf_file}" >/dev/null 2>"${stderr_cap}" || ec=$?
    local warned6="clean"
    grep -q "Warning: IOC_CHDIR" "${stderr_cap}" 2>/dev/null && warned6="warned"
    verify_state "warned" "${warned6}" "Missing-setgid 0775 dir warns"
    verify_state "0" "${ec}" "Missing-setgid install with -f exits 0"

    # Case 7: y/N prompt flow (no -f), triggered by a group-mismatch dir.
    name="PrecheckPrompt-SYS"
    chdir="${base}/promptdir"; conf_file="${base}/${name}.conf"
    mkdir -p "${chdir}"
    chgrp root "${chdir}"; chmod 2775 "${chdir}"
    touch "${chdir}/st.cmd"; chmod 0755 "${chdir}/st.cmd"
    cat <<EOF > "${conf_file}"
IOC_NAME="${name}"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${chdir}"
IOC_PORT="unix:ioc-srv:ioc:0660:/run/procserv/${name}/control"
IOC_CMD="./st.cmd"
EOF

    # 7a: EOF on the prompt -> abort, exit 1.
    sysd="${base}/s7a"; conf="${base}/c7a"
    mkdir -p "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    ec=0
    IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        bash "${RUNNER_SCRIPT}" install "${conf_file}" </dev/null >/dev/null 2>&1 || ec=$?
    verify_state "1" "${ec}" "Prompt EOF aborts install (exit 1)"

    # 7b: explicit N -> declined, exit 1 (nonzero-abort convention, #93).
    sysd="${base}/s7b"; conf="${base}/c7b"
    mkdir -p "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    ec=0
    printf 'N\n' | IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        bash "${RUNNER_SCRIPT}" install "${conf_file}" >/dev/null 2>&1 || ec=$?
    verify_state "1" "${ec}" "Prompt explicit N declines install (exit 1)"

    # 7c: explicit Y -> proceeds, exit 0, conf deployed.
    sysd="${base}/s7c"; conf="${base}/c7c"
    mkdir -p "${sysd}" "${conf}"; touch "${sysd}/epics-@.service"
    ec=0
    printf 'Y\n' | IOC_RUNNER_SYSTEM_SYSTEMD_DIR="${sysd}" IOC_RUNNER_SYSTEM_CONF_DIR="${conf}" \
        bash "${RUNNER_SCRIPT}" install "${conf_file}" >/dev/null 2>&1 || ec=$?
    verify_state "0" "${ec}" "Prompt explicit Y proceeds with install (exit 0)"
    local installed7c="false"
    [[ -f "${conf}/${name}.conf" ]] && installed7c="true"
    verify_state "true" "${installed7c}" "Prompt Y path deploys the conf file"

    # Cleanup is left to _handle_exit: base lives under WORKSPACE, so the
    # standard cleanup/retention policy removes it on success and retains it
    # (with the precheck fixtures) for inspection on failure. Isolated
    # CONF_DIR/SYSTEMD_DIR overrides kept every artifact under base; real
    # /etc is never touched.
}

function test_persistence {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Enable and Disable (Persistence)"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" enable "${IOC_NAME}"

    local link_exist="false"
    if [[ -L "${SYSTEMD_WANTS_DIR}/epics-@${IOC_NAME}.service" ]]; then link_exist="true"; fi
    verify_state "true" "${link_exist}" "Symlink created in multi-user.wants (Enable)"

    bash "${RUNNER_SCRIPT}" disable "${IOC_NAME}"

    link_exist="false"
    if [[ -L "${SYSTEMD_WANTS_DIR}/epics-@${IOC_NAME}.service" ]]; then link_exist="true"; fi
    verify_state "false" "${link_exist}" "Symlink strictly removed (Disable)"
}

function test_remove {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Remove Command"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" remove "${IOC_NAME}"

    local conf_exist="false"
    local state

    if [[ -f "${CONF_DIR}/${IOC_NAME}.conf" ]]; then conf_exist="true"; fi
    state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${IOC_NAME}.service" || true)

    verify_state "false" "${conf_exist}" "Configuration file safely removed"
    verify_state "inactive" "${state}"   "Service completely stopped (inactive)"
}

function run_all_tests {
    local -a pipeline=(
        "verify_infrastructure"
        "_setup_workspace"
        "cleanup_previous_state"
        "setup_environment"
        "test_generate_manual"
        "test_install_explicit"
        "test_cleanup_install"
        "test_install_dir"
        "test_cleanup_install"
        "test_cleanup_conf"
        "test_generate_auto"
        "test_install_explicit"
        "test_cleanup_install"
        "test_install_dir"
        "test_start"
        "test_status"
        "test_view"
        "test_restart"
        "test_stop"
        "test_socket_list"
        "test_list_options"
        "test_console_attach"
        "test_channel_access"
        "test_inspect_and_multiple_connections"
        "test_monitor_isolation"
        "test_crash_detection"
        "test_detection_without_journal"
        "test_logrotate_boundary"
        "test_permission_enforcement"
        "test_chdir_precheck"
        "test_persistence"
        "test_remove"
    )

    local step=1
    local func=""

    initialize_reporting
    if (( REPORT_CATALOG_ONLY_COMPLETED )); then
        return "${REPORT_FINAL_STATUS}"
    fi
    if ! run_preflight; then
        return
    fi
    probe_optional_dependencies

    # Record which ioc-runner binary this run exercises, so captured
    # output shows whether the installed or source-tree binary ran. A
    # stale installed binary previously masked a passing fix as a failing
    # test until an external reviewer caught the path mismatch. (#71)
    print_divider
    _log "INFO" "Runner under test: ${RUNNER_SCRIPT}"
    bash "${RUNNER_SCRIPT}" -V || _log "WARN" "ioc-runner -V returned non-zero"
    print_divider

    for func in "${pipeline[@]}"; do
        printf -v CURRENT_STEP_ID 'S%02d' "${step}"
        CURRENT_STEP_CHECK_INDEX=0
        "${func}" "${step}"
        if [[ "${CURRENT_STEP_ID}" == "S01" && ${SYSTEM_INFRA_READY} -eq 0 ]]; then
            return
        fi
        step=$((step + 1))
    done
}

run_all_tests
