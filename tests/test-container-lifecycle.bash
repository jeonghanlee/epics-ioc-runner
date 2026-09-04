#!/usr/bin/env bash
#
# Automated lifecycle test for the systemd-less container execution mode.
# It drives the shipped runner's --container backend against a real soft IOC
# supervised by s6, verifying the deployment, control, observation, console,
# and teardown workflows without systemd.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
umask 022
unset BASH_ENV ENV CDPATH GIT_DIR GIT_WORK_TREE

declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g BLUE='\033[0;34m'
declare -g YELLOW='\033[0;33m'
declare -g NC='\033[0m'

if [[ -z "${EPICS_HOST_ARCH:-}" ]]; then
    export EPICS_HOST_ARCH="linux-x86_64"
fi

declare -g SC_TOP
SC_TOP="$(dirname "${BASH_SOURCE[0]}")"
[[ "${SC_TOP}" != /* ]] && SC_TOP="${PWD}/${SC_TOP}"

declare -gr SUITE_ID="container-lifecycle"
declare -gr SUITE_SCOPE="container"
declare -gr SUITE_CATEGORY="lifecycle-behavior"
declare -g SUITE_RUNNER="source"
declare -g REPORT_DIR=""
declare -g REPORT_READY=0
declare -g CURRENT_STEP_ID=""
declare -g CURRENT_STEP_CHECK_INDEX=0
declare -g SUITE_ASSERTION_FAILED=0
declare -g CONTAINER_INFRA_READY=0
declare -g -a CONTAINER_CATALOG_ROWS=(
    "P00|container-lifecycle.P00.root-invocation|REQUIRED|direct-inspection"
    "P00|container-lifecycle.P00.epics-base-set|REQUIRED|direct-inspection"
    "P00|container-lifecycle.P00.softioc-available|REQUIRED|direct-inspection"
    "P00|container-lifecycle.P00.s6-binaries-available|REQUIRED|direct-inspection"
    "P00|container-lifecycle.P00.s6-svscan-listening|REQUIRED|direct-inspection"
    "P00|container-lifecycle.P00.lsof-available|REQUIRED|direct-inspection"
    "P00|container-lifecycle.P00.ps-available|REQUIRED|direct-inspection"
    "P00|container-lifecycle.P00.selected-runner-executable|REQUIRED|direct-inspection"
    "S01|container-lifecycle.S01.conf-dir-exists|REQUIRED|direct-inspection"
    "S01|container-lifecycle.S01.conf-dir-writable|REQUIRED|direct-inspection"
    "S01|container-lifecycle.S01.scan-dir-exists|REQUIRED|direct-inspection"
    "S01|container-lifecycle.S01.service-account-exists|REQUIRED|direct-inspection"
    "S03|container-lifecycle.S03.generate-exits-zero|BEHAVIOR|real-path"
    "S03|container-lifecycle.S03.generated-conf-created|BEHAVIOR|real-path"
    "S03|container-lifecycle.S03.generated-conf-uses-service-identity|BEHAVIOR|real-path"
    "S04|container-lifecycle.S04.install-exits-zero|BEHAVIOR|real-path"
    "S04|container-lifecycle.S04.installed-conf-deployed|BEHAVIOR|real-path"
    "S04|container-lifecycle.S04.service-run-script-rendered|BEHAVIOR|real-path"
    "S04|container-lifecycle.S04.run-script-logs-to-stdout|BEHAVIOR|direct-inspection"
    "S04|container-lifecycle.S04.new-service-starts-down|BEHAVIOR|real-path"
    "S04|container-lifecycle.S04.timeout-kill-written|BEHAVIOR|real-path"
    "S04|container-lifecycle.S04.supervisor-adopted-service|BEHAVIOR|real-path"
    "S05|container-lifecycle.S05.start-exits-zero|BEHAVIOR|real-path"
    "S05|container-lifecycle.S05.service-reports-up|BEHAVIOR|real-path"
    "S05|container-lifecycle.S05.control-socket-created|BEHAVIOR|real-path"
    "S05|container-lifecycle.S05.socket-directory-owned-by-service-account|BEHAVIOR|direct-inspection"
    "S05|container-lifecycle.S05.procserv-runs-as-service-account|BEHAVIOR|direct-inspection"
    "S05|container-lifecycle.S05.procserv-stdout-reaches-container-stdout|BEHAVIOR|direct-inspection"
    "S05|container-lifecycle.S05.no-log-file-created|BEHAVIOR|direct-inspection"
    "S05|container-lifecycle.S05.repeated-start-reports-already-running|BEHAVIOR|real-path"
    "S06|container-lifecycle.S06.status-exits-zero|BEHAVIOR|real-path"
    "S06|container-lifecycle.S06.status-reports-up|BEHAVIOR|real-path"
    "S07|container-lifecycle.S07.list-exits-zero|BEHAVIOR|real-path"
    "S07|container-lifecycle.S07.list-shows-ioc-name|BEHAVIOR|real-path"
    "S07|container-lifecycle.S07.list-shows-active-status|BEHAVIOR|real-path"
    "S07|container-lifecycle.S07.list-shows-socket-path|BEHAVIOR|real-path"
    "S07|container-lifecycle.S07.list-verbose-shows-supervised-pid|BEHAVIOR|real-path"
    "S07|container-lifecycle.S07.list-verbose-reports-process-tree-memory|BEHAVIOR|real-path"
    "S08|container-lifecycle.S08.view-exits-zero|BEHAVIOR|real-path"
    "S08|container-lifecycle.S08.view-renders-configuration|BEHAVIOR|real-path"
    "S08|container-lifecycle.S08.view-renders-run-script|BEHAVIOR|real-path"
    "S09|container-lifecycle.S09.inspect-exits-zero|BEHAVIOR|real-path"
    "S09|container-lifecycle.S09.inspect-references-target-socket|BEHAVIOR|real-path"
    "S09|container-lifecycle.S09.inspect-attributes-executable-identity|BEHAVIOR|real-path"
    "S10|container-lifecycle.S10.console-tool-available|PREREQUISITE|direct-inspection"
    "S10|container-lifecycle.S10.monitor-input-securely-blocked|BEHAVIOR|real-path"
    "S11|container-lifecycle.S11.restart-exits-zero|BEHAVIOR|real-path"
    "S11|container-lifecycle.S11.restart-replaces-supervised-process|BEHAVIOR|real-path"
    "S11|container-lifecycle.S11.service-remains-up-after-restart|BEHAVIOR|real-path"
    "S12|container-lifecycle.S12.stop-exits-zero|BEHAVIOR|real-path"
    "S12|container-lifecycle.S12.service-reports-down-after-stop|BEHAVIOR|real-path"
    "S12|container-lifecycle.S12.supervisor-does-not-restart-stopped-service|BEHAVIOR|real-path"
    "S13|container-lifecycle.S13.disable-exits-zero|BEHAVIOR|real-path"
    "S13|container-lifecycle.S13.disable-creates-down-file|BEHAVIOR|real-path"
    "S13|container-lifecycle.S13.enable-exits-zero|BEHAVIOR|real-path"
    "S13|container-lifecycle.S13.enable-removes-down-file|BEHAVIOR|real-path"
    "S13|container-lifecycle.S13.enable-leaves-running-ioc-untouched|BEHAVIOR|real-path"
    "S14|container-lifecycle.S14.non-root-invocation-rejected|BEHAVIOR|real-path"
    "S14|container-lifecycle.S14.absent-scan-directory-rejected|BEHAVIOR|real-path"
    "S15|container-lifecycle.S15.remove-exits-zero|BEHAVIOR|real-path"
    "S15|container-lifecycle.S15.installed-conf-removed|BEHAVIOR|real-path"
    "S15|container-lifecycle.S15.service-directory-removed|BEHAVIOR|real-path"
    "S15|container-lifecycle.S15.socket-directory-removed|BEHAVIOR|real-path"
    "S15|container-lifecycle.S15.no-orphan-supervisor-remains|BEHAVIOR|real-path"
)
declare -g -A CONTAINER_STEP_CHECK_IDS=()
# shellcheck source=lib/test-reporting.bash
source "${SC_TOP}/lib/test-reporting.bash"

# Resolve the ioc-runner binary under test; IOC_RUNNER_TEST_MODE selects the
# origin exactly as the systemd-backed lifecycle suites do.
declare -g RUNNER_SCRIPT
function resolve_runner_script {
    local mode="${IOC_RUNNER_TEST_MODE:-}"
    local source_bin="${SC_TOP}/../bin/ioc-runner"
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
declare -g RUN_DIR="/run/procserv"
declare -g SCAN_DIR="${IOC_RUNNER_SCAN_DIR:-/run/s6-procserv}"
declare -g SYSTEM_USER="ioc-srv"
declare -g SYSTEM_GROUP="ioc"
declare -g IOC_NAME="iocContainerTestIOC"
declare -g SERVICE_DIR="${SCAN_DIR}/${IOC_NAME}"
declare -g UDS_PATH="${RUN_DIR}/${IOC_NAME}/control"
declare -g WORKSPACE=""
declare -g BOOT_DIR=""
declare -g CONF_FILE=""
declare -g SOFTIOC_BIN=""
declare -g CON_AVAILABLE="false"
declare -g NON_ROOT_USER="ioc-container-probe"
declare -g NON_ROOT_USER_CREATED=0
declare -g KEEP_WORKSPACE="${KEEP_WORKSPACE:-0}"
declare -g -a S6_REQUIRED_BINS=(s6-svscan s6-supervise s6-svc s6-svstat s6-svscanctl s6-setuidgid)

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

    for ((index = 1; index <= 15; index += 1)); do
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
    REPORT_DIR=$(mktemp -d /tmp/ioc-runner-container-lifecycle-report.XXXXXX)
    report_init "${SUITE_ID}" "${run_id}" "${SUITE_SCOPE}" "${SUITE_RUNNER}" \
        "${os_id}" "${EPICS_HOST_ARCH}" "${REPORT_DIR}"
    REPORT_READY=1
    for step_id in "${step_ids[@]}"; do
        report_register_step "${step_id}" "Container lifecycle ${step_id}"
    done
    for row in "${CONTAINER_CATALOG_ROWS[@]}"; do
        IFS='|' read -r step_id check_id check_kind test_method <<< "${row}"
        description="${check_id#${SUITE_ID}.${step_id}.}"
        report_register_check "${check_id}" "${step_id}" "${SUITE_CATEGORY}" \
            "${check_kind}" "${test_method}" "${description}"
        if [[ -n "${CONTAINER_STEP_CHECK_IDS[${step_id}]:-}" ]]; then
            CONTAINER_STEP_CHECK_IDS["${step_id}"]+=" ${check_id}"
        else
            CONTAINER_STEP_CHECK_IDS["${step_id}"]="${check_id}"
        fi
    done
    report_close_catalog
    report_verify_catalog_counts
}

function next_current_check_id {
    local result_name="$1"
    local check_list="${CONTAINER_STEP_CHECK_IDS[${CURRENT_STEP_ID}]:-}"
    local -a check_ids=()

    read -r -a check_ids <<< "${check_list}"
    if (( CURRENT_STEP_CHECK_INDEX >= ${#check_ids[@]} )); then
        printf 'REPORTING ERROR: extra assertion in %s\n' "${CURRENT_STEP_ID}" >&2
        return 1
    fi
    printf -v "${result_name}" '%s' "${check_ids[${CURRENT_STEP_CHECK_INDEX}]}"
    CURRENT_STEP_CHECK_INDEX=$((CURRENT_STEP_CHECK_INDEX + 1))
}

function close_current_remaining {
    local state="$1"
    local reason="$2"
    local check_list="${CONTAINER_STEP_CHECK_IDS[${CURRENT_STEP_ID}]:-}"
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

    for row in "${CONTAINER_CATALOG_ROWS[@]:${start_index}}"; do
        IFS='|' read -r step_id check_id check_kind test_method <<< "${row}"
        report_record "${check_id}" "${state}" "${reason}"
    done
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

function run_runner {
    bash "${RUNNER_SCRIPT}" --container "$@"
}

function service_up_state {
    s6-svstat -o up "${SERVICE_DIR}" 2>/dev/null || printf "unknown"
}

function service_pid {
    local pid=""

    pid=$(s6-svstat -o pid "${SERVICE_DIR}" 2>/dev/null || printf "")
    if [[ "${pid}" =~ ^[1-9][0-9]*$ ]]; then
        printf '%s' "${pid}"
    fi
}

function wait_for_up_state {
    local expected="$1"
    local max_wait="${2:-15}"
    local attempt=0

    while (( attempt < max_wait )); do
        if [[ "$(service_up_state)" == "${expected}" ]]; then
            return 0
        fi
        sleep 1
        attempt=$((attempt + 1))
    done
    return 1
}

function _handle_exit {
    local exit_code=$?
    local final_status="${exit_code}"

    trap - EXIT
    set +e

    if (( REPORT_CATALOG_ONLY_COMPLETED )); then
        exit "${REPORT_FINAL_STATUS}"
    fi

    if [[ -d "${SERVICE_DIR}" || -f "${CONF_DIR}/${IOC_NAME}.conf" ]]; then
        run_runner remove "${IOC_NAME}" >/dev/null 2>&1
    fi
    if (( NON_ROOT_USER_CREATED )) && id "${NON_ROOT_USER}" >/dev/null 2>&1; then
        userdel "${NON_ROOT_USER}" 2>/dev/null
        NON_ROOT_USER_CREATED=0
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
            _log "ERROR" "Failed to remove test workspace: ${WORKSPACE}"
        fi
    fi

    if (( REPORT_READY )); then
        report_finalize "${final_status}" || final_status=1
    fi
    exit "${final_status}"
}

trap _handle_exit EXIT
trap 'exit 1' SIGINT

function run_preflight {
    local root_invocation="false"
    local epics_base_set="false"
    local softioc_available="false"
    local s6_available="true"
    local svscan_listening="false"
    local lsof_available="false"
    local ps_available="false"
    local runner_executable="false"
    local s6_bin=""

    CURRENT_STEP_ID=P00
    CURRENT_STEP_CHECK_INDEX=0
    [[ "${EUID}" -eq 0 ]] && root_invocation="true"
    verify_state true "${root_invocation}" "Effective user is root"
    if [[ "${root_invocation}" != "true" ]]; then
        close_catalog_from_index 1 SKIP "requires ${SUITE_ID}.P00.root-invocation"
        return 1
    fi

    # The suite fixes its own PATH, so softIoc is resolved from EPICS_BASE the
    # way the systemd-backed lifecycle suites resolve it.
    [[ -n "${EPICS_BASE:-}" ]] && epics_base_set="true"
    verify_state true "${epics_base_set}" "EPICS_BASE is set"
    if [[ "${epics_base_set}" != "true" ]]; then
        close_catalog_from_index 2 SKIP "requires ${SUITE_ID}.P00.epics-base-set"
        return 1
    fi
    SOFTIOC_BIN="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}/softIoc"
    [[ -x "${SOFTIOC_BIN}" ]] && softioc_available="true"
    for s6_bin in "${S6_REQUIRED_BINS[@]}"; do
        if ! command -v "${s6_bin}" >/dev/null 2>&1; then
            s6_available="false"
            break
        fi
    done
    if [[ "${s6_available}" == "true" ]] && s6-svscanctl -z "${SCAN_DIR}" >/dev/null 2>&1; then
        svscan_listening="true"
    fi
    command -v lsof >/dev/null 2>&1 && lsof_available="true"
    [[ -x "$(command -v ps 2>/dev/null)" ]] && ps_available="true"
    [[ -x "${RUNNER_SCRIPT}" || -r "${RUNNER_SCRIPT}" ]] && runner_executable="true"

    verify_state true "${softioc_available}" "softIoc is available"
    verify_state true "${s6_available}" "s6 binaries are available"
    verify_state true "${svscan_listening}" "s6-svscan is listening on ${SCAN_DIR}"
    verify_state true "${lsof_available}" "lsof is available"
    verify_state true "${ps_available}" "ps is available and executable"
    verify_state true "${runner_executable}" "Selected runner is readable"
    if [[ "${softioc_available}" != "true" || "${s6_available}" != "true" ||
          "${svscan_listening}" != "true" || "${lsof_available}" != "true" ||
          "${ps_available}" != "true" || "${runner_executable}" != "true" ]]; then
        close_catalog_from_index 8 SKIP "requires container lifecycle P00"
        return 1
    fi
}

function verify_infrastructure {
    local step="$1"
    local conf_dir_exists="false"
    local conf_dir_writable="false"
    local scan_dir_exists="false"
    local account_exists="false"

    print_divider
    _log "INFO" "STEP ${step}: Verify Container Infrastructure"
    print_sub_divider

    [[ -d "${CONF_DIR}" ]] && conf_dir_exists="true"
    [[ -w "${CONF_DIR}" ]] && conf_dir_writable="true"
    [[ -d "${SCAN_DIR}" ]] && scan_dir_exists="true"
    id -u "${SYSTEM_USER}" >/dev/null 2>&1 && account_exists="true"

    verify_state "true" "${conf_dir_exists}" "Configuration directory exists (${CONF_DIR})"
    verify_state "true" "${conf_dir_writable}" "Configuration directory is writable"
    verify_state "true" "${scan_dir_exists}" "Scan directory exists (${SCAN_DIR})"
    verify_state "true" "${account_exists}" "Service account exists (${SYSTEM_USER})"
    if [[ "${conf_dir_exists}" == "true" && "${conf_dir_writable}" == "true" &&
          "${scan_dir_exists}" == "true" && "${account_exists}" == "true" ]]; then
        CONTAINER_INFRA_READY=1
    else
        close_catalog_from_index 12 SKIP "requires container-lifecycle S01 infrastructure"
    fi
}

function setup_workspace {
    local step="$1"
    # Container runtimes mount /dev/shm noexec, which would make the IOC
    # startup script non-executable to the runner's own validation, so the
    # workspace defaults to /tmp rather than shared memory.
    local target_tmp="${TMPDIR:-/tmp}"

    print_divider
    _log "INFO" "STEP ${step}: Setup Test Workspace and Soft IOC"
    print_sub_divider

    if [[ ! -d "${target_tmp}" || ! -w "${target_tmp}" ]]; then
        target_tmp="/tmp"
    fi
    WORKSPACE=$(mktemp -d -p "${target_tmp}" epics-ioc-test.XXXXXX)
    BOOT_DIR="${WORKSPACE}/${IOC_NAME}"
    CONF_FILE="${BOOT_DIR}/${IOC_NAME}.conf"

    # The IOC runs as the service account, so its working directory follows the
    # system-mode permission model: setgid, group-owned by the service group.
    install -d -m 2775 -o root -g "${SYSTEM_GROUP}" "${WORKSPACE}"
    install -d -m 2775 -o root -g "${SYSTEM_GROUP}" "${BOOT_DIR}"
    printf '#!%s\niocInit()\n' "${SOFTIOC_BIN}" > "${BOOT_DIR}/st.cmd"
    chmod 0775 "${BOOT_DIR}/st.cmd"
    chgrp "${SYSTEM_GROUP}" "${BOOT_DIR}/st.cmd"
    _log "SUCCESS" "Soft IOC fixture created at ${BOOT_DIR}"
}

function test_generate {
    local step="$1"
    local exit_code=0
    local conf_created="false"
    local identity_ok="false"

    print_divider
    _log "INFO" "STEP ${step}: Test Generate Command"
    print_sub_divider

    run_runner generate "${BOOT_DIR}" >/dev/null 2>&1 || exit_code=$?
    verify_state "0" "${exit_code}" "generate exits zero"
    [[ -f "${CONF_FILE}" ]] && conf_created="true"
    verify_state "true" "${conf_created}" "Generated configuration created"
    if [[ "${conf_created}" == "true" ]] &&
       grep -q "IOC_USER=\"${SYSTEM_USER}\"" "${CONF_FILE}" &&
       grep -q "IOC_GROUP=\"${SYSTEM_GROUP}\"" "${CONF_FILE}"; then
        identity_ok="true"
    fi
    verify_state "true" "${identity_ok}" "Generated configuration uses the service identity"
}

function test_install {
    local step="$1"
    local exit_code=0
    local conf_deployed="false"
    local run_rendered="false"
    local logs_to_stdout="false"
    local starts_down="false"
    local timeout_kill="false"
    local supervised="false"

    print_divider
    _log "INFO" "STEP ${step}: Test Install Command"
    print_sub_divider

    run_runner install "${CONF_FILE}" >/dev/null 2>&1 || exit_code=$?
    verify_state "0" "${exit_code}" "install exits zero"
    [[ -f "${CONF_DIR}/${IOC_NAME}.conf" ]] && conf_deployed="true"
    verify_state "true" "${conf_deployed}" "Installed configuration deployed"
    [[ -x "${SERVICE_DIR}/run" ]] && run_rendered="true"
    verify_state "true" "${run_rendered}" "s6 run script rendered and executable"
    if [[ "${run_rendered}" == "true" ]] && grep -qF -- "--logfile=-" "${SERVICE_DIR}/run"; then
        logs_to_stdout="true"
    fi
    verify_state "true" "${logs_to_stdout}" "Run script sends the IOC log to stdout"
    [[ -f "${SERVICE_DIR}/down" ]] && starts_down="true"
    verify_state "true" "${starts_down}" "New service starts disabled"
    [[ -s "${SERVICE_DIR}/timeout-kill" ]] && timeout_kill="true"
    verify_state "true" "${timeout_kill}" "Stop grace period written"
    if s6-svok "${SERVICE_DIR}" >/dev/null 2>&1 ||
       s6-svstat "${SERVICE_DIR}" >/dev/null 2>&1; then
        supervised="true"
    fi
    verify_state "true" "${supervised}" "Supervisor adopted the new service"
}

function test_start {
    local step="$1"
    local exit_code=0
    local reports_up="false"
    local socket_created="false"
    local socket_dir_owner=""
    local socket_dir_ok="false"
    local procserv_user=""
    local runs_as_service="false"
    local stdout_shared="false"
    local no_log_file="true"
    local repeat_output=""
    local already_running="false"
    local pid=""

    print_divider
    _log "INFO" "STEP ${step}: Test Start Command"
    print_sub_divider

    run_runner start "${IOC_NAME}" >/dev/null 2>&1 || exit_code=$?
    verify_state "0" "${exit_code}" "start exits zero"
    wait_for_up_state "true" 15 || true
    [[ "$(service_up_state)" == "true" ]] && reports_up="true"
    verify_state "true" "${reports_up}" "Service reports up"
    [[ -S "${UDS_PATH}" ]] && socket_created="true"
    verify_state "true" "${socket_created}" "Control socket created"

    socket_dir_owner=$(stat -c '%U:%G' "${RUN_DIR}/${IOC_NAME}" 2>/dev/null || printf "")
    [[ "${socket_dir_owner}" == "${SYSTEM_USER}:${SYSTEM_GROUP}" ]] && socket_dir_ok="true"
    verify_state "true" "${socket_dir_ok}" "Socket directory owned by the service account"

    pid=$(service_pid)
    if [[ -n "${pid}" ]]; then
        procserv_user=$(ps -o user= -p "${pid}" 2>/dev/null | tr -d ' ')
        [[ "${procserv_user}" == "${SYSTEM_USER}" ]] && runs_as_service="true"
        # procServ inherits its stdout from s6-supervise, which inherits it
        # from s6-svscan (PID 1 in the container), so the IOC output reaches
        # the container stdout.
        if [[ "$(readlink "/proc/${pid}/fd/1" 2>/dev/null)" == \
              "$(readlink /proc/1/fd/1 2>/dev/null)" ]]; then
            stdout_shared="true"
        fi
    fi
    verify_state "true" "${runs_as_service}" "procServ runs as the service account"
    verify_state "true" "${stdout_shared}" "procServ stdout reaches the container stdout"

    if compgen -G "/var/log/procserv/*.log" >/dev/null 2>&1; then
        no_log_file="false"
    fi
    verify_state "true" "${no_log_file}" "No IOC log file is created"

    repeat_output=$(run_runner start "${IOC_NAME}" 2>&1 || true)
    if [[ "${repeat_output}" == *"already running"* ]]; then
        already_running="true"
    fi
    verify_state "true" "${already_running}" "Repeated start reports the IOC as already running"
}

function test_status {
    local step="$1"
    local exit_code=0
    local output=""
    local reports_up="false"

    print_divider
    _log "INFO" "STEP ${step}: Test Status Command"
    print_sub_divider

    output=$(run_runner status "${IOC_NAME}" 2>&1) || exit_code=$?
    verify_state "0" "${exit_code}" "status exits zero"
    if [[ "${output}" == *"up"* && "${output}" == *"${IOC_NAME}"* ]]; then
        reports_up="true"
    fi
    verify_state "true" "${reports_up}" "status reports the IOC up"
}

function test_list {
    local step="$1"
    local exit_code=0
    local output=""
    local verbose_output=""
    local shows_name="false"
    local shows_status="false"
    local shows_socket="false"
    local shows_pid="false"
    local shows_memory="false"
    local pid=""

    print_divider
    _log "INFO" "STEP ${step}: Test List Command"
    print_sub_divider

    output=$(run_runner list 2>&1) || exit_code=$?
    verify_state "0" "${exit_code}" "list exits zero"
    [[ "${output}" == *"${IOC_NAME}"* ]] && shows_name="true"
    [[ "${output}" == *"active"* ]] && shows_status="true"
    [[ "${output}" == *"${UDS_PATH}"* ]] && shows_socket="true"
    verify_state "true" "${shows_name}" "list shows the IOC name"
    verify_state "true" "${shows_status}" "list shows the active status"
    verify_state "true" "${shows_socket}" "list shows the socket path"

    pid=$(service_pid)
    verbose_output=$(run_runner list -v 2>&1 || true)
    [[ -n "${pid}" && "${verbose_output}" == *"${pid}"* ]] && shows_pid="true"
    # The MEM column is summed over procServ and its IOC child from /proc, so a
    # live IOC always reports a nonzero megabyte figure.
    if [[ "${verbose_output}" =~ \|[[:space:]]*[0-9]+\.[0-9]+M[[:space:]]*\| ]]; then
        shows_memory="true"
    fi
    verify_state "true" "${shows_pid}" "list -v shows the supervised PID"
    verify_state "true" "${shows_memory}" "list -v reports process-tree memory"
}

function test_view {
    local step="$1"
    local exit_code=0
    local output=""
    local renders_conf="false"
    local renders_run="false"

    print_divider
    _log "INFO" "STEP ${step}: Test View Command"
    print_sub_divider

    output=$(run_runner view "${IOC_NAME}" 2>&1) || exit_code=$?
    verify_state "0" "${exit_code}" "view exits zero"
    [[ "${output}" == *"IOC_CMD="* ]] && renders_conf="true"
    [[ "${output}" == *"s6-setuidgid"* ]] && renders_run="true"
    verify_state "true" "${renders_conf}" "view renders the configuration"
    verify_state "true" "${renders_run}" "view renders the s6 run script"
}

function test_inspect {
    local step="$1"
    local exit_code=0
    local output=""
    local references_socket="false"
    local attributes_identity="false"

    print_divider
    _log "INFO" "STEP ${step}: Test Inspect Command"
    print_sub_divider

    output=$(run_runner inspect "${IOC_NAME}" 2>&1) || exit_code=$?
    verify_state "0" "${exit_code}" "inspect exits zero"
    [[ "${output}" == *"${UDS_PATH}"* ]] && references_socket="true"
    [[ "${output}" == *"Executable identity matches"* ]] && attributes_identity="true"
    verify_state "true" "${references_socket}" "inspect references the target socket"
    verify_state "true" "${attributes_identity}" "inspect attributes the procServ executable identity"
}

function test_monitor_isolation {
    local step="$1"
    local marker=""
    local monitor_log=""
    local blocked="false"

    print_divider
    _log "INFO" "STEP ${step}: Test Monitor Input Isolation"
    print_sub_divider

    CON_AVAILABLE="false"
    if command -v socat >/dev/null 2>&1; then
        CON_AVAILABLE="true"
    fi
    verify_state "true" "${CON_AVAILABLE}" "A console tool is available for read-only monitoring"
    if [[ "${CON_AVAILABLE}" != "true" ]]; then
        close_current_remaining SKIP "requires ${SUITE_ID}.S10.console-tool-available"
        return 0
    fi

    # A read-only monitor session must not reach the IOC shell: the injected
    # command would otherwise appear in the IOC output the socket echoes back.
    marker="container-monitor-probe-$$"
    monitor_log="${WORKSPACE}/monitor.out"
    printf '%s\n' "dbl \"${marker}\"" | timeout 5 env IOC_RUNNER_CON_TOOL= \
        bash "${RUNNER_SCRIPT}" --container monitor "${IOC_NAME}" \
        > "${monitor_log}" 2>&1 || true
    if ! grep -qF -- "${marker}" "${monitor_log}"; then
        blocked="true"
    fi
    verify_state "true" "${blocked}" "Input is securely blocked in monitor mode"
}

function test_restart {
    local step="$1"
    local exit_code=0
    local before_pid=""
    local after_pid=""
    local replaced="false"
    local remains_up="false"

    print_divider
    _log "INFO" "STEP ${step}: Test Restart Command"
    print_sub_divider

    before_pid=$(service_pid)
    run_runner restart "${IOC_NAME}" >/dev/null 2>&1 || exit_code=$?
    verify_state "0" "${exit_code}" "restart exits zero"
    wait_for_up_state "true" 15 || true
    after_pid=$(service_pid)
    if [[ -n "${before_pid}" && -n "${after_pid}" && "${before_pid}" != "${after_pid}" ]]; then
        replaced="true"
    fi
    verify_state "true" "${replaced}" "restart replaces the supervised process"
    [[ "$(service_up_state)" == "true" ]] && remains_up="true"
    verify_state "true" "${remains_up}" "Service remains up after restart"
}

function test_stop {
    local step="$1"
    local exit_code=0
    local reports_down="false"
    local stays_down="false"

    print_divider
    _log "INFO" "STEP ${step}: Test Stop Command"
    print_sub_divider

    run_runner stop "${IOC_NAME}" >/dev/null 2>&1 || exit_code=$?
    verify_state "0" "${exit_code}" "stop exits zero"
    wait_for_up_state "false" 15 || true
    [[ "$(service_up_state)" == "false" ]] && reports_down="true"
    verify_state "true" "${reports_down}" "Service reports down after stop"
    # s6-supervise restarts a dead process after one second; a commanded stop
    # must stay down instead.
    sleep 3
    [[ "$(service_up_state)" == "false" ]] && stays_down="true"
    verify_state "true" "${stays_down}" "Supervisor does not restart a stopped service"
}

function test_persistence {
    local step="$1"
    local disable_code=0
    local enable_code=0
    local down_created="false"
    local down_removed="false"
    local still_running="false"

    print_divider
    _log "INFO" "STEP ${step}: Test Enable and Disable (Persistence)"
    print_sub_divider

    run_runner disable "${IOC_NAME}" >/dev/null 2>&1 || disable_code=$?
    verify_state "0" "${disable_code}" "disable exits zero"
    [[ -f "${SERVICE_DIR}/down" ]] && down_created="true"
    verify_state "true" "${down_created}" "disable creates the boot-time down file"

    run_runner start "${IOC_NAME}" >/dev/null 2>&1 || true
    wait_for_up_state "true" 15 || true
    run_runner enable "${IOC_NAME}" >/dev/null 2>&1 || enable_code=$?
    verify_state "0" "${enable_code}" "enable exits zero"
    [[ ! -f "${SERVICE_DIR}/down" ]] && down_removed="true"
    verify_state "true" "${down_removed}" "enable removes the boot-time down file"
    [[ "$(service_up_state)" == "true" ]] && still_running="true"
    verify_state "true" "${still_running}" "enable leaves the running IOC untouched"
}

function test_error_contract {
    local step="$1"
    local non_root_output=""
    local non_root_rejected="false"
    local absent_output=""
    local absent_rejected="false"

    print_divider
    _log "INFO" "STEP ${step}: Container Mode Error Contract"
    print_sub_divider

    if ! id -u "${NON_ROOT_USER}" >/dev/null 2>&1; then
        useradd -r -M -d /nonexistent -s /sbin/nologin "${NON_ROOT_USER}" 2>/dev/null || true
        id -u "${NON_ROOT_USER}" >/dev/null 2>&1 && NON_ROOT_USER_CREATED=1
    fi
    non_root_output=$(setpriv --reuid "$(id -u "${NON_ROOT_USER}")" --regid "$(id -g "${NON_ROOT_USER}")" \
        --clear-groups bash "${RUNNER_SCRIPT}" --container list 2>&1 || true)
    if [[ "${non_root_output}" == *"requires root"* ]]; then
        non_root_rejected="true"
    fi
    verify_state "true" "${non_root_rejected}" "Container mode rejects a non-root invocation"

    absent_output=$(IOC_RUNNER_SCAN_DIR="${WORKSPACE}/absent-scan" \
        bash "${RUNNER_SCRIPT}" --container list 2>&1 || true)
    if [[ "${absent_output}" == *"s6-svscan is not running"* ]]; then
        absent_rejected="true"
    fi
    verify_state "true" "${absent_rejected}" "Container mode rejects a scan directory without a supervisor"
}

function test_remove {
    local step="$1"
    local exit_code=0
    local conf_removed="false"
    local service_removed="false"
    local socket_dir_removed="false"
    local no_orphan="false"

    print_divider
    _log "INFO" "STEP ${step}: Test Remove Command"
    print_sub_divider

    run_runner remove "${IOC_NAME}" >/dev/null 2>&1 || exit_code=$?
    verify_state "0" "${exit_code}" "remove exits zero"
    [[ ! -e "${CONF_DIR}/${IOC_NAME}.conf" ]] && conf_removed="true"
    verify_state "true" "${conf_removed}" "Installed configuration removed"
    [[ ! -d "${SERVICE_DIR}" ]] && service_removed="true"
    verify_state "true" "${service_removed}" "s6 service directory removed"
    [[ ! -d "${RUN_DIR}/${IOC_NAME}" ]] && socket_dir_removed="true"
    verify_state "true" "${socket_dir_removed}" "Socket directory removed"
    sleep 2
    if ! ps -eo args= | grep -q "[s]6-supervise ${IOC_NAME}"; then
        no_orphan="true"
    fi
    verify_state "true" "${no_orphan}" "No orphan supervisor remains"
}

function run_all_tests {
    local -a pipeline=(
        "verify_infrastructure"
        "setup_workspace"
        "test_generate"
        "test_install"
        "test_start"
        "test_status"
        "test_list"
        "test_view"
        "test_inspect"
        "test_monitor_isolation"
        "test_restart"
        "test_stop"
        "test_persistence"
        "test_error_contract"
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

    print_divider
    _log "INFO" "Runner under test: ${RUNNER_SCRIPT}"
    bash "${RUNNER_SCRIPT}" -V || _log "WARN" "ioc-runner -V returned non-zero"
    print_divider

    for func in "${pipeline[@]}"; do
        printf -v CURRENT_STEP_ID 'S%02d' "${step}"
        CURRENT_STEP_CHECK_INDEX=0
        "${func}" "${step}"
        if [[ "${CURRENT_STEP_ID}" == "S01" && ${CONTAINER_INFRA_READY} -eq 0 ]]; then
            return
        fi
        step=$((step + 1))
    done
}

run_all_tests
