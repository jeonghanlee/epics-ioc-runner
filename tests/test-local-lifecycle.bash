#!/usr/bin/env bash
#
# Automated lifecycle test for EPICS local IOC management.
# This script uses the actual ServiceTestIOC repository to verify
# the install, start, view, list, enable, disable, and remove workflows.
# It validates the systemd template unit (@.service) architecture dynamically.

set -e

# --- Global Output & Color Settings ---
declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g BLUE='\033[0;34m'
declare -g YELLOW='\033[0;33m'
declare -g NC='\033[0m'

# --- EPICS Test Configuration ---
declare -g CAMONITOR_COUNT=5
declare -g CAMONITOR_TIMEOUT=10

# STEP 29 reads journalctl --user output after its OS applicability boundary.
# Rocky ordinary operators intentionally lack broad journal access, so the
# complete step is non-applicable there. Other hosts probe the user journal
# and skip the dependent behavior checks when that optional facility is absent.
declare -g MONITOR_ISOLATION_APPLICABLE="true"
declare -g JOURNAL_AVAILABLE="false"

# U003/M19: the local log-rotation steps need logrotate. Resolve it the way
# bin/ioc-runner's resolve_logrotate_tool does - absolute paths first, PATH
# lookup as fallback - because Debian keeps sbin off a user PATH while the
# runner still installs rotation there; the probe must answer what the runner
# answers. The path list is a deliberate second copy of the runner's
# LOGROTATE_SEARCH_PATHS; IOC_RUNNER_LOGROTATE_TOOL is not consulted because
# the suite verifies the default deployment. Hosts without logrotate cannot
# verify rotation; mark it unavailable so those steps skip with a WARN rather
# than fail (deploy_local_logrotate itself warns and skips).
declare -g LOGROTATE_AVAILABLE="false"
declare -g LOGROTATE_BIN=""
declare -gr LOGROTATE_RUNTIME_STATE_NAME="ioc-runner-logrotate.state"
declare -gr LOGROTATE_PROBE_BYTES=52428801
declare -gra SYSTEM_LOGROTATE_STATE_PATHS=(
    "/var/lib/logrotate/status"
    "/var/lib/logrotate/logrotate.status"
    "/var/lib/logrotate.status"
)
declare -g LOGROTATE_RUNTIME_STATE_PATH=""
declare -g LOGROTATE_RUNTIME_STATE_BACKUP=""
declare -g LOGROTATE_RUNTIME_STATE_EXISTED=0
declare -g LOGROTATE_EXECSTART_OVERRIDE=""
declare -g LOGROTATE_EXECSTART_OVERRIDE_DIR_CREATED=0

if [[ -z "${EPICS_HOST_ARCH:-}" ]]; then
    export EPICS_HOST_ARCH="linux-x86_64"
fi

declare -g SC_RPATH
declare -g SC_TOP
SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"

declare -gr SUITE_ID="local-lifecycle"
declare -gr SUITE_SCOPE="local"
declare -gr SUITE_CATEGORY="lifecycle-behavior"
declare -g SUITE_RUNNER="source"
declare -g REPORT_DIR=""
declare -g REPORT_READY=0
declare -g CURRENT_STEP_ID=""
declare -g CURRENT_STEP_CHECK_INDEX=0
declare -g -a LOCAL_CATALOG_ROWS=(
    "P00|local-lifecycle.P00.epics-base-set|REQUIRED"
    "P00|local-lifecycle.P00.lsof-available|REQUIRED"
    "P00|local-lifecycle.P00.selected-runner-executable|REQUIRED"
    "S04|local-lifecycle.S04.manual-configuration-created|BEHAVIOR"
    "S05|local-lifecycle.S05.explicit-install-succeeded|BEHAVIOR"
    "S06|local-lifecycle.S06.installed-configuration-removed|BEHAVIOR"
    "S07|local-lifecycle.S07.directory-install-succeeded|BEHAVIOR"
    "S08|local-lifecycle.S08.installed-configuration-removed|BEHAVIOR"
    "S09|local-lifecycle.S09.workspace-configuration-removed|BEHAVIOR"
    "S10|local-lifecycle.S10.automatic-configuration-created|BEHAVIOR"
    "S11|local-lifecycle.S11.explicit-install-succeeded|BEHAVIOR"
    "S12|local-lifecycle.S12.installed-configuration-removed|BEHAVIOR"
    "S13|local-lifecycle.S13.directory-install-succeeded|BEHAVIOR"
    "S14|local-lifecycle.S14.logrotate-available|PREREQUISITE"
    "S14|local-lifecycle.S14.rotation-config-exists|REQUIRED"
    "S14|local-lifecycle.S14.rotation-service-exists|REQUIRED"
    "S14|local-lifecycle.S14.rotation-timer-exists|REQUIRED"
    "S14|local-lifecycle.S14.rotation-contract-pinned|BEHAVIOR"
    "S14|local-lifecycle.S14.su-directive-absent|BEHAVIOR"
    "S14|local-lifecycle.S14.rotation-config-valid|BEHAVIOR"
    "S14|local-lifecycle.S14.rotation-timer-enabled|BEHAVIOR"
    "S14|local-lifecycle.S14.repeat-install-succeeded|BEHAVIOR"
    "S14|local-lifecycle.S14.repeat-install-stable|BEHAVIOR"
    "S15|local-lifecycle.S15.logrotate-available|PREREQUISITE"
    "S15|local-lifecycle.S15.rotation-config-exists|REQUIRED"
    "S15|local-lifecycle.S15.oneshot-result-success|BEHAVIOR"
    "S15|local-lifecycle.S15.compressed-archive-created|BEHAVIOR"
    "S15|local-lifecycle.S15.live-log-truncated|BEHAVIOR"
    "S15|local-lifecycle.S15.runtime-state-created|BEHAVIOR"
    "S15|local-lifecycle.S15.system-default-state-unchanged|BEHAVIOR"
    "S16|local-lifecycle.S16.logrotate-available|PREREQUISITE"
    "S16|local-lifecycle.S16.rotation-config-exists|REQUIRED"
    "S16|local-lifecycle.S16.maxsize-rotates-before-weekly|BEHAVIOR"
    "S17|local-lifecycle.S17.service-active|BEHAVIOR"
    "S18|local-lifecycle.S18.status-shows-active|BEHAVIOR"
    "S19|local-lifecycle.S19.view-renders-configuration|BEHAVIOR"
    "S20|local-lifecycle.S20.inspect-exits-zero|BEHAVIOR"
    "S20|local-lifecycle.S20.inspect-shows-sockets|BEHAVIOR"
    "S20|local-lifecycle.S20.inspect-shows-server|BEHAVIOR"
    "S20|local-lifecycle.S20.inspect-shows-client|BEHAVIOR"
    "S21|local-lifecycle.S21.socat-available|PREREQUISITE"
    "S21|local-lifecycle.S21.unrelated-sockets-created|BEHAVIOR"
    "S21|local-lifecycle.S21.inspect-exits-zero|BEHAVIOR"
    "S21|local-lifecycle.S21.inspect-within-one-second|BEHAVIOR"
    "S22|local-lifecycle.S22.service-active-after-restart|BEHAVIOR"
    "S23|local-lifecycle.S23.service-inactive-after-stop|BEHAVIOR"
    "S23|local-lifecycle.S23.service-active-after-start|BEHAVIOR"
    "S24|local-lifecycle.S24.control-socket-created|BEHAVIOR"
    "S24|local-lifecycle.S24.list-shows-ioc-name|BEHAVIOR"
    "S24|local-lifecycle.S24.list-shows-socket-path|BEHAVIOR"
    "S24|local-lifecycle.S24.verbose-list-shows-pid|BEHAVIOR"
    "S24|local-lifecycle.S24.verbose-list-shows-cpu|BEHAVIOR"
    "S24|local-lifecycle.S24.verbose-list-shows-memory|BEHAVIOR"
    "S24|local-lifecycle.S24.double-verbose-list-shows-recvq|BEHAVIOR"
    "S24|local-lifecycle.S24.double-verbose-list-shows-sendq|BEHAVIOR"
    "S24|local-lifecycle.S24.double-verbose-list-shows-permission|BEHAVIOR"
    "S25|local-lifecycle.S25.local-list-v-parsed|BEHAVIOR"
    "S25|local-lifecycle.S25.list-v-local-parsed|BEHAVIOR"
    "S25|local-lifecycle.S25.list-local-v-parsed|BEHAVIOR"
    "S26|local-lifecycle.S26.user-list-shows-ioc|BEHAVIOR"
    "S26|local-lifecycle.S26.user-list-matches-local|BEHAVIOR"
    "S26|local-lifecycle.S26.user-status-shows-active|BEHAVIOR"
    "S27|local-lifecycle.S27.socket-permission-valid|BEHAVIOR"
    "S27|local-lifecycle.S27.con-available|REQUIRED"
    "S27|local-lifecycle.S27.socket-listening|BEHAVIOR"
    "S28|local-lifecycle.S28.camonitor-available|REQUIRED"
    "S28|local-lifecycle.S28.expected-updates-observed|BEHAVIOR"
    "S29|local-lifecycle.S29.monitor-isolation-applicable|APPLICABILITY"
    "S29|local-lifecycle.S29.user-journal-available|PREREQUISITE"
    "S29|local-lifecycle.S29.unit-journal-visible|BEHAVIOR"
    "S29|local-lifecycle.S29.monitor-input-blocked|BEHAVIOR"
    "S30|local-lifecycle.S30.softioc-available|PREREQUISITE"
    "S30|local-lifecycle.S30.leading-boundary-identifier-adjacent-exits-zero|BEHAVIOR"
    "S30|local-lifecycle.S30.leading-boundary-identifier-adjacent-success-verdict|BEHAVIOR"
    "S30|local-lifecycle.S30.leading-boundary-identifier-adjacent-emitted|BEHAVIOR"
    "S30|local-lifecycle.S30.trailing-boundary-identifier-adjacent-exits-zero|BEHAVIOR"
    "S30|local-lifecycle.S30.trailing-boundary-identifier-adjacent-success-verdict|BEHAVIOR"
    "S30|local-lifecycle.S30.trailing-boundary-identifier-adjacent-emitted|BEHAVIOR"
    "S30|local-lifecycle.S30.identifier-contained-fatal-exits-zero|BEHAVIOR"
    "S30|local-lifecycle.S30.identifier-contained-fatal-success-verdict|BEHAVIOR"
    "S30|local-lifecycle.S30.identifier-contained-fatal-emitted|BEHAVIOR"
    "S30|local-lifecycle.S30.fatal-probe-exits-one|BEHAVIOR"
    "S30|local-lifecycle.S30.fatal-probe-verdict|BEHAVIOR"
    "S30|local-lifecycle.S30.silent-loop-exits-one|BEHAVIOR"
    "S30|local-lifecycle.S30.silent-loop-verdict|BEHAVIOR"
    "S30|local-lifecycle.S30.parse-error-exits-one|BEHAVIOR"
    "S30|local-lifecycle.S30.parse-error-verdict|BEHAVIOR"
    "S30|local-lifecycle.S30.historical-fatal-exits-zero|BEHAVIOR"
    "S30|local-lifecycle.S30.historical-fatal-success-verdict|BEHAVIOR"
    "S30|local-lifecycle.S30.truncate-available|PREREQUISITE"
    "S30|local-lifecycle.S30.truncated-log-exits-one|BEHAVIOR"
    "S30|local-lifecycle.S30.truncated-log-verdict|BEHAVIOR"
    "S30|local-lifecycle.S30.nonroot-history-probes-applicable|APPLICABILITY"
    "S30|local-lifecycle.S30.history-noise-exits-zero|BEHAVIOR"
    "S30|local-lifecycle.S30.history-noise-success-verdict|BEHAVIOR"
    "S30|local-lifecycle.S30.history-noise-emitted|BEHAVIOR"
    "S30|local-lifecycle.S30.history-fatal-exits-one|BEHAVIOR"
    "S30|local-lifecycle.S30.history-fatal-verdict|BEHAVIOR"
    "S31|local-lifecycle.S31.softioc-available|PREREQUISITE"
    "S31|local-lifecycle.S31.wellformed-start-succeeds|BEHAVIOR"
    "S31|local-lifecycle.S31.wellformed-not-warned|BEHAVIOR"
    "S31|local-lifecycle.S31.dot-start-succeeds|BEHAVIOR"
    "S31|local-lifecycle.S31.dot-reason-reported|BEHAVIOR"
    "S31|local-lifecycle.S31.dot-does-not-corroborate|BEHAVIOR"
    "S31|local-lifecycle.S31.trailing-pipe-start-succeeds|BEHAVIOR"
    "S31|local-lifecycle.S31.trailing-pipe-reason-reported|BEHAVIOR"
    "S31|local-lifecycle.S31.trailing-pipe-does-not-corroborate|BEHAVIOR"
    "S31|local-lifecycle.S31.invalid-regex-start-succeeds|BEHAVIOR"
    "S31|local-lifecycle.S31.invalid-regex-reason-reported|BEHAVIOR"
    "S31|local-lifecycle.S31.invalid-regex-does-not-corroborate|BEHAVIOR"
    "S31|local-lifecycle.S31.positive-start-succeeds|BEHAVIOR"
    "S31|local-lifecycle.S31.positive-not-rejected|BEHAVIOR"
    "S31|local-lifecycle.S31.positive-corroborates|BEHAVIOR"
    "S31|local-lifecycle.S31.spaced-start-succeeds|BEHAVIOR"
    "S31|local-lifecycle.S31.spaced-reason-reported|BEHAVIOR"
    "S31|local-lifecycle.S31.spaced-does-not-corroborate|BEHAVIOR"
    "S31|local-lifecycle.S31.blank-start-succeeds|BEHAVIOR"
    "S31|local-lifecycle.S31.blank-not-warned|BEHAVIOR"
    "S32|local-lifecycle.S32.enable-creates-link|BEHAVIOR"
    "S32|local-lifecycle.S32.disable-removes-link|BEHAVIOR"
    "S33|local-lifecycle.S33.configuration-removed|BEHAVIOR"
    "S33|local-lifecycle.S33.service-inactive|BEHAVIOR"
    "S34|local-lifecycle.S34.logrotate-available|PREREQUISITE"
    "S34|local-lifecycle.S34.shared-timer-survives-ioc-remove|BEHAVIOR"
    "S34|local-lifecycle.S34.manual-teardown-removes-timer|BEHAVIOR"
    "S35|local-lifecycle.S35.namespaced-install-succeeds|BEHAVIOR"
    "S35|local-lifecycle.S35.namespaced-conf-path-used|BEHAVIOR"
    "S35|local-lifecycle.S35.namespaced-log-path-baked-into-unit|BEHAVIOR"
    "S35|local-lifecycle.S35.precedence-install-succeeds|BEHAVIOR"
    "S35|local-lifecycle.S35.unified-conf-path-used|BEHAVIOR"
    "S35|local-lifecycle.S35.namespaced-conf-path-unused|BEHAVIOR"
    "S35|local-lifecycle.S35.unified-run-path-baked-into-ioc-port|BEHAVIOR"
    "S35|local-lifecycle.S35.namespaced-run-path-unused|BEHAVIOR"
    "S35|local-lifecycle.S35.unified-systemd-path-used|BEHAVIOR"
    "S35|local-lifecycle.S35.namespaced-systemd-path-unused|BEHAVIOR"
    "S35|local-lifecycle.S35.unified-log-path-baked-into-unit|BEHAVIOR"
    "S35|local-lifecycle.S35.xdg-state-home-unset-log-path-baked-into-unit|BEHAVIOR"
    "S35|local-lifecycle.S35.xdg-state-home-log-path-baked-into-unit|BEHAVIOR"
    "S36|local-lifecycle.S36.absent-template-deployed|BEHAVIOR"
    "S36|local-lifecycle.S36.absent-deploy-message|BEHAVIOR"
    "S36|local-lifecycle.S36.identical-template-kept|BEHAVIOR"
    "S36|local-lifecycle.S36.identical-no-backup|BEHAVIOR"
    "S36|local-lifecycle.S36.identical-no-update-message|BEHAVIOR"
    "S36|local-lifecycle.S36.different-noninteractive-kept|BEHAVIOR"
    "S36|local-lifecycle.S36.different-keep-message|BEHAVIOR"
    "S36|local-lifecycle.S36.force-updated|BEHAVIOR"
    "S36|local-lifecycle.S36.force-backup-created|BEHAVIOR"
    "S36|local-lifecycle.S36.abort-nonzero|BEHAVIOR"
    "S36|local-lifecycle.S36.abort-template-unchanged|BEHAVIOR"
)
declare -g -A LOCAL_STEP_CHECK_IDS=()
# shellcheck source=lib/test-reporting.bash
source "${SC_TOP}/lib/test-reporting.bash"

# --- Managed Architecture Paths ---
# Resolve the ioc-runner binary under test. IOC_RUNNER_TEST_MODE selects
# the binary origin; the unset default is the source tree, matching the
# developer inner loop. Selection failures stop here, before STEP 1,
# never deferred into the lifecycle body.
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
declare -g CONF_DIR="${HOME}/.config/procServ.d"
declare -g SYSTEMD_USER_DIR="${HOME}/.config/systemd/user"
declare -g SYSTEMD_WANTS_DIR="${SYSTEMD_USER_DIR}/default.target.wants"
declare -g RUN_DIR
RUN_DIR="/run/user/$(id -u)/procserv"

# --- IOC Test Target Paths ---

declare -g IOC_REPO="https://github.com/jeonghanlee/ServiceTestIOC.git"
declare -g REPO_NAME="ServiceTestIOC"
declare -g IOC_NAME="iocServiceTestIOC"

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

declare -g -a SYSTEMCTL_CMD=(systemctl --user)

declare -g KEEP_WORKSPACE="${KEEP_WORKSPACE:-0}"
declare -g SUITE_ASSERTION_FAILED=0

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

    for ((index = 1; index <= 36; index += 1)); do
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
    REPORT_DIR=$(mktemp -d /tmp/ioc-runner-local-report.XXXXXX)
    report_init "${SUITE_ID}" "${run_id}" "${SUITE_SCOPE}" "${SUITE_RUNNER}" \
        "${os_id}" "${EPICS_HOST_ARCH}" "${REPORT_DIR}"
    REPORT_READY=1
    for step_id in "${step_ids[@]}"; do
        report_register_step "${step_id}" "Local lifecycle ${step_id}"
    done
    for row in "${LOCAL_CATALOG_ROWS[@]}"; do
        IFS='|' read -r step_id check_id check_kind <<< "${row}"
        if [[ "${check_kind}" == "BEHAVIOR" ]]; then
            test_method="real-path"
        else
            test_method="direct-inspection"
        fi
        description="${check_id#${SUITE_ID}.${step_id}.}"
        report_register_check "${check_id}" "${step_id}" "${SUITE_CATEGORY}" \
            "${check_kind}" "${test_method}" "${description}"
        if [[ -n "${LOCAL_STEP_CHECK_IDS[${step_id}]:-}" ]]; then
            LOCAL_STEP_CHECK_IDS["${step_id}"]+=" ${check_id}"
        else
            LOCAL_STEP_CHECK_IDS["${step_id}"]="${check_id}"
        fi
    done
    report_close_catalog
    report_verify_catalog_counts
}

function next_current_check_id {
    local result_name="$1"
    local check_list="${LOCAL_STEP_CHECK_IDS[${CURRENT_STEP_ID}]:-}"
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
    local check_list="${LOCAL_STEP_CHECK_IDS[${CURRENT_STEP_ID}]:-}"
    local check_id=""
    local -a check_ids=()

    read -r -a check_ids <<< "${check_list}"
    while (( CURRENT_STEP_CHECK_INDEX < ${#check_ids[@]} )); do
        check_id="${check_ids[${CURRENT_STEP_CHECK_INDEX}]}"
        CURRENT_STEP_CHECK_INDEX=$((CURRENT_STEP_CHECK_INDEX + 1))
        report_record "${check_id}" "${state}" "${reason}"
    done
}

function close_local_catalog_from_index {
    local start_index="$1"
    local state="$2"
    local reason="$3"
    local row=""
    local step_id=""
    local check_id=""
    local check_kind=""

    for row in "${LOCAL_CATALOG_ROWS[@]:${start_index}}"; do
        IFS='|' read -r step_id check_id check_kind <<< "${row}"
        report_record "${check_id}" "${state}" "${reason}"
    done
}

function run_preflight {
    local epics_base_set="false"
    local lsof_available="false"
    local runner_executable="false"

    CURRENT_STEP_ID=P00
    CURRENT_STEP_CHECK_INDEX=0
    [[ -n "${EPICS_BASE:-}" ]] && epics_base_set="true"
    verify_state true "${epics_base_set}" "EPICS_BASE is set"
    if [[ "${epics_base_set}" != "true" ]]; then
        close_local_catalog_from_index 1 SKIP \
            "requires ${SUITE_ID}.P00.epics-base-set"
        return 1
    fi

    command -v lsof >/dev/null 2>&1 && lsof_available="true"
    [[ -x "${RUNNER_SCRIPT}" ]] && runner_executable="true"
    verify_state true "${lsof_available}" "lsof is available"
    verify_state true "${runner_executable}" "Selected runner is executable"
    if [[ "${lsof_available}" != "true" || "${runner_executable}" != "true" ]]; then
        close_local_catalog_from_index 3 SKIP "requires local lifecycle P00"
        return 1
    fi
}

function probe_optional_dependencies {
    local journal_probe=""
    local logrotate_candidate=""
    local os_name=""

    MONITOR_ISOLATION_APPLICABLE="true"
    JOURNAL_AVAILABLE="false"
    os_name=$(read_os_release_value ID || true)
    if [[ "${os_name}" == "rocky" ]]; then
        MONITOR_ISOLATION_APPLICABLE="false"
    else
        JOURNAL_AVAILABLE="true"
        journal_probe=$(journalctl --user --no-pager -n 1 2>&1 || true)
        if [[ "${journal_probe}" == *"No journal files were found"* ||
              "${journal_probe}" == *"insufficient permissions"* ]]; then
            JOURNAL_AVAILABLE="false"
        fi
    fi
    for logrotate_candidate in /usr/sbin/logrotate /sbin/logrotate /usr/bin/logrotate; do
        if [[ -x "${logrotate_candidate}" ]]; then
            LOGROTATE_BIN="${logrotate_candidate}"
            break
        fi
    done
    if [[ -z "${LOGROTATE_BIN}" ]]; then
        LOGROTATE_BIN=$(command -v logrotate 2>/dev/null || true)
    fi
    [[ -n "${LOGROTATE_BIN}" ]] && LOGROTATE_AVAILABLE="true"
}

function resolve_user_runtime_dir {
    local runtime_dir="${XDG_RUNTIME_DIR:-}"

    if [[ -z "${runtime_dir}" ]]; then
        runtime_dir=$(systemd-path user-runtime 2>/dev/null || true)
    fi
    if [[ -z "${runtime_dir}" ]]; then
        runtime_dir="/run/user/$(id -u)"
    fi
    printf '%s' "${runtime_dir}"
}

function snapshot_system_logrotate_states {
    local path=""
    local fingerprint=""

    for path in "${SYSTEM_LOGROTATE_STATE_PATHS[@]}"; do
        if fingerprint=$(stat -Lc '%d:%i:%s:%Y:%Z' -- "${path}" 2>/dev/null); then
            printf '%s=%s\n' "${path}" "${fingerprint}"
        elif [[ -e "${path}" ]]; then
            printf '%s=%s\n' "${path}" "unreadable"
        else
            printf '%s=%s\n' "${path}" "absent"
        fi
    done
}

function prepare_logrotate_runtime_state {
    local runtime_dir=""
    local state_path=""
    local backup_path="${WORKSPACE}/logrotate-runtime-state.backup"

    runtime_dir=$(resolve_user_runtime_dir)
    state_path="${runtime_dir}/${LOGROTATE_RUNTIME_STATE_NAME}"
    if [[ -L "${state_path}" || ( -e "${state_path}" && ! -f "${state_path}" ) ]]; then
        _log "ERROR" "Refusing to replace a non-regular logrotate runtime state path."
        return 1
    fi
    if [[ -e "${state_path}" ]]; then
        cp -p -- "${state_path}" "${backup_path}" || return 1
        LOGROTATE_RUNTIME_STATE_EXISTED=1
    else
        LOGROTATE_RUNTIME_STATE_EXISTED=0
    fi
    LOGROTATE_RUNTIME_STATE_PATH="${state_path}"
    LOGROTATE_RUNTIME_STATE_BACKUP="${backup_path}"
    rm -f -- "${state_path}"
}

function restore_logrotate_runtime_state {
    local restore_rc=0

    [[ -n "${LOGROTATE_RUNTIME_STATE_PATH}" ]] || return 0
    rm -f -- "${LOGROTATE_RUNTIME_STATE_PATH}" || restore_rc=1
    if (( LOGROTATE_RUNTIME_STATE_EXISTED )); then
        if [[ -f "${LOGROTATE_RUNTIME_STATE_BACKUP}" ]]; then
            cp -p -- "${LOGROTATE_RUNTIME_STATE_BACKUP}" \
                "${LOGROTATE_RUNTIME_STATE_PATH}" || restore_rc=1
        else
            restore_rc=1
        fi
    fi
    rm -f -- "${LOGROTATE_RUNTIME_STATE_BACKUP}" || restore_rc=1
    if (( restore_rc == 0 )); then
        LOGROTATE_RUNTIME_STATE_PATH=""
        LOGROTATE_RUNTIME_STATE_BACKUP=""
        LOGROTATE_RUNTIME_STATE_EXISTED=0
    fi
    return "${restore_rc}"
}

function install_logrotate_execstart_override {
    local override_dir="${SYSTEMD_USER_DIR}/epics-logrotate.service.d"
    local override_file="${override_dir}/90-ioc-runner-test.conf"

    if [[ -L "${override_dir}" || -L "${override_file}" || -e "${override_file}" ]]; then
        _log "ERROR" "Refusing to replace an existing logrotate service override."
        return 1
    fi
    if [[ ! -d "${override_dir}" ]]; then
        install -d -m 0700 "${override_dir}" || return 1
        LOGROTATE_EXECSTART_OVERRIDE_DIR_CREATED=1
    else
        LOGROTATE_EXECSTART_OVERRIDE_DIR_CREATED=0
    fi
    LOGROTATE_EXECSTART_OVERRIDE="${override_file}"
    install -m 0600 /dev/null "${override_file}" || return 1
    printf '%s\n' '[Service]' 'ExecStart=' 'ExecStart=/bin/false' > "${override_file}"
    systemctl --user daemon-reload
}

function restore_logrotate_execstart_override {
    local override_dir=""
    local restore_rc=0

    [[ -n "${LOGROTATE_EXECSTART_OVERRIDE}" ]] || return 0
    override_dir="${LOGROTATE_EXECSTART_OVERRIDE%/*}"
    rm -f -- "${LOGROTATE_EXECSTART_OVERRIDE}" || restore_rc=1
    if (( LOGROTATE_EXECSTART_OVERRIDE_DIR_CREATED )); then
        rmdir -- "${override_dir}" 2>/dev/null || true
    fi
    systemctl --user daemon-reload >/dev/null 2>&1 || restore_rc=1
    if (( restore_rc == 0 )); then
        LOGROTATE_EXECSTART_OVERRIDE=""
        LOGROTATE_EXECSTART_OVERRIDE_DIR_CREATED=0
    fi
    return "${restore_rc}"
}

function _handle_exit {
    local exit_code=$?
    local final_status="${exit_code}"

    trap - EXIT
    set +e

    if (( REPORT_CATALOG_ONLY_COMPLETED )); then
        exit "${REPORT_FINAL_STATUS}"
    fi

    if ! restore_logrotate_execstart_override; then
        final_status=1
        _log "ERROR" "Failed to restore the logrotate service override."
    fi
    if ! restore_logrotate_runtime_state; then
        final_status=1
        _log "ERROR" "Failed to restore the logrotate runtime state."
    fi

    # Workspace setup precedes every lifecycle action that can arm the user
    # log-rotation timer. Preflight exits leave WORKSPACE empty and finalize
    # reporting without touching user systemd state.
    if [[ -n "${WORKSPACE}" ]]; then
        systemctl --user disable --now epics-logrotate.timer >/dev/null 2>&1 || true
        if ! "${REPORT_RM_BIN:-/bin/rm}" -f -- \
            "${SYSTEMD_USER_DIR}/epics-logrotate.service" \
            "${SYSTEMD_USER_DIR}/epics-logrotate.timer"; then
            final_status=1
            _log "ERROR" "Failed to remove local log-rotation units."
        fi
        systemctl --user daemon-reload >/dev/null 2>&1 || true
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

function cleanup_previous_state {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Cleanup Previous State"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" --local remove "${IOC_NAME}" >/dev/null 2>&1 || true

    rm -f "${SYSTEMD_USER_DIR}/epics-@.service"

    # U003/M19: remove any residual user log-rotation units from a prior run.
    # A normal per-IOC remove leaves these in place (never-auto-remove), so the
    # suite tears them down explicitly to start from a clean state.
    systemctl --user disable --now epics-logrotate.timer >/dev/null 2>&1 || true
    rm -f "${SYSTEMD_USER_DIR}/epics-logrotate.service" "${SYSTEMD_USER_DIR}/epics-logrotate.timer"

    systemctl --user daemon-reload || true

    _log "SUCCESS" "Cleaned up residual processes, templates, and configurations."
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

    # Isolate local-mode CONF_DIR / LOG_DIR under WORKSPACE so a direct or
    # sudo-elevated run cannot corrupt the user's ~/.config/procServ.d or
    # ~/.local/state/procserv. RUN_DIR stays at the default
    # /run/user/<uid>/procserv because the deployed user unit relies on
    # systemd's RuntimeDirectory= directive, which only materialises a
    # subdirectory of XDG_RUNTIME_DIR. SYSTEMD_DIR also stays default so
    # systemctl --user can find the unit on its standard search path. (#70)
    export IOC_RUNNER_LOCAL_CONF_DIR="${WORKSPACE}/local-config/procServ.d"
    export IOC_RUNNER_LOCAL_LOG_DIR="${WORKSPACE}/local-state/procserv"

    # Keep test-side globals consistent with the exported env vars so the
    # conf-existence assertions look in the right place.
    CONF_DIR="${IOC_RUNNER_LOCAL_CONF_DIR}"

    # TOP_DIR uses the repository name. BOOT_DIR matches the standard IOC name.
    TOP_DIR="${WORKSPACE}/${REPO_NAME}"
    BOOT_DIR="${TOP_DIR}/iocBoot/${IOC_NAME}"

    # The configuration artifact is now strictly aligned with the implicit IOC_NAME.
    CONF_FILE="${BOOT_DIR}/${IOC_NAME}.conf"

    TEST_CA_PORT="$(pick_free_ca_port 5095)"

    _log "SUCCESS" "Test workspace defined with standard EPICS structure at ${WORKSPACE}"
}

function setup_environment {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Environment Setup & Compilation"
    print_sub_divider

    if [[ ! -d "${TOP_DIR}" ]]; then
        _log "INFO" "Cloning target IOC repository..."
        git clone -q "${IOC_REPO}" "${TOP_DIR}" >/dev/null 2>&1
    fi

    # Compile the application at the top-level directory.
    cd "${TOP_DIR}" || exit 1
    if [[ ! -d "bin" ]]; then
        _log "INFO" "Configuring and compiling EPICS application..."
        printf "EPICS_BASE=%s\n" "${EPICS_BASE}" > configure/RELEASE.local
        make > build.log 2>&1 || { _log "ERROR" "Compilation failed. Check build.log"; exit 1; }
        _log "SUCCESS" "Compilation completed."
    fi

    chmod +x "${BOOT_DIR}/st.cmd"

    _log "SUCCESS" "Standard environment structure prepared at ${BOOT_DIR}"
}

# Validates manual creation of the configuration artifact.
function test_generate_manual {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Generate (Manual)"
    print_sub_divider

    cd "${BOOT_DIR}" || exit 1
    cat <<EOF > "${CONF_FILE}"
IOC_NAME="${IOC_NAME}"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${BOOT_DIR}"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF

    local conf_exist="false"
    if [[ -f "${CONF_FILE}" ]]; then conf_exist="true"; fi
    verify_state "true" "${conf_exist}" "Manual configuration artifact created"
}

# Validates native auto-generation of the configuration artifact.
function test_generate_auto {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Generate (Auto)"
    print_sub_divider

    cd "${BOOT_DIR}" || exit 1
    bash "${RUNNER_SCRIPT}" --local generate . >/dev/null
    # Pin the test IOC to its dedicated CA server port through the conf, which
    # the systemd template loads as an EnvironmentFile into the IOC environment.
    printf 'EPICS_CA_SERVER_PORT="%s"\n' "${TEST_CA_PORT}" >> "${CONF_FILE}"

    local conf_exist="false"
    if [[ -f "${CONF_FILE}" ]]; then conf_exist="true"; fi
    verify_state "true" "${conf_exist}" "Configuration artifact auto-generated natively"
}

# Validates deployment using an explicit file path.
function test_install_explicit {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Install (Explicit)"
    print_sub_divider

    cd "${BOOT_DIR}" || exit 1
    bash "${RUNNER_SCRIPT}" --local -f install "${CONF_FILE}" >/dev/null

    local conf_exist="false"
    if [[ -f "${CONF_DIR}/${IOC_NAME}.conf" ]]; then conf_exist="true"; fi
    verify_state "true" "${conf_exist}" "Explicit file installation succeeded"
}

# Validates deployment using dynamic directory resolution.
function test_install_dir {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Install (Directory)"
    print_sub_divider

    cd "${BOOT_DIR}" || exit 1
    bash "${RUNNER_SCRIPT}" --local -f install . >/dev/null

    local conf_exist="false"
    if [[ -f "${CONF_DIR}/${IOC_NAME}.conf" ]]; then conf_exist="true"; fi
    verify_state "true" "${conf_exist}" "Directory-based installation succeeded"
}

# Reverts deployed system state for subsequent pipeline steps.
function test_cleanup_install {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Cleanup Installation"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" --local remove "${IOC_NAME}" >/dev/null 2>&1 || true

    local conf_exist="true"
    if [[ ! -f "${CONF_DIR}/${IOC_NAME}.conf" ]]; then conf_exist="false"; fi
    verify_state "false" "${conf_exist}" "Deployed configuration safely removed"
}

# Removes the workspace artifact to ensure isolated generation testing.
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

    bash "${RUNNER_SCRIPT}" --local start "${IOC_NAME}"
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
    output=$(bash "${RUNNER_SCRIPT}" --local status "${IOC_NAME}" 2>&1 || true)

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
    output=$(bash "${RUNNER_SCRIPT}" --local view "${IOC_NAME}" 2>&1 || true)

    local conf_in_output="false"
    # The error path echoes the IOC name too; only a conf-content token
    # proves the configuration actually rendered (M8/#111).
    if printf "%s" "${output}" | grep -q "IOC_CMD="; then conf_in_output="true"; fi
    verify_state "true" "${conf_in_output}" "View output renders the configuration (IOC_CMD=)"
}

function test_inspect {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Inspect (Local Mode)"
    print_sub_divider

    local exit_code=0
    local inspect_out=""

    # Validates that the Netlink socket diagnostic tool runs successfully
    # without root privileges when the target process is owned by the current user.
    inspect_out=$(bash "${RUNNER_SCRIPT}" --local inspect "${IOC_NAME}" 2>&1) || exit_code=$?

    verify_state "0" "${exit_code}" "Inspect executes successfully as standard user in local mode"

    # Validates that the three diagnostic sections actually render, catching
    # regressions where the command exits 0 but produces truncated output.
    local has_sockets="false" has_server="false" has_client="false"
    [[ "${inspect_out}" == *"UNIX Domain Socket FDs"* ]]      && has_sockets="true"
    [[ "${inspect_out}" == *"Server Process Context"* ]]      && has_server="true"
    [[ "${inspect_out}" == *"Client Process Context"* ]]      && has_client="true"
    verify_state "true" "${has_sockets}" "Inspect renders UDS section"
    verify_state "true" "${has_server}"  "Inspect renders server process section"
    verify_state "true" "${has_client}"  "Inspect renders client process section"
}

# T4 (Phase E): do_inspect bounded runtime. inspect must stay under 1s even
# when the host carries many unrelated UDS sockets. Separate from test_inspect
# so a functional regression and a performance regression report distinctly.
function test_inspect_bounded_runtime {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Inspect Bounded Runtime (T4)"
    print_sub_divider

    local socat_bin
    socat_bin=$(command -v socat 2>/dev/null || true)
    if [[ -z "${socat_bin}" ]]; then
        _log "WARN" "socat not found, skipping inspect bounded-runtime test (T4)."
        record_current_state SKIP "socat is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S21.socat-available"
        return 0
    fi
    record_current_state PASS

    # Spawn many unrelated UDS listeners. inspect must stay bounded and not be
    # dragged down by host-wide socket noise independent of the IOC's own UDS.
    local noise_dir="${WORKSPACE}/t4_noise"
    mkdir -p "${noise_dir}"
    local -a noise_pids=()
    local target=500 i
    for ((i = 1; i <= target; i = i + 1)); do
        "${socat_bin}" UNIX-LISTEN:"${noise_dir}/s${i}.sock" /dev/null >/dev/null 2>&1 &
        noise_pids+=("$!")
    done

    # Let the listeners bind, then count what exists (load evidence).
    sleep 1
    local created
    created=$(find "${noise_dir}" -type s 2>/dev/null | wc -l)
    _log "INFO" "T4 load: ${created} unrelated UDS listeners created via socat"

    # Measure wall-clock time of a single inspect under that load. Capture
    # the exit code too: a fast failure under load must not pass T4 merely
    # because elapsed stayed under the bound.
    local start_ns end_ns elapsed_ms inspect_exit=0
    start_ns=$(date +%s%N)
    bash "${RUNNER_SCRIPT}" --local inspect "${IOC_NAME}" >/dev/null 2>&1 || inspect_exit=$?
    end_ns=$(date +%s%N)
    elapsed_ms=$(( (end_ns - start_ns) / 1000000 ))
    _log "INFO" "T4 elapsed: ${elapsed_ms} ms (bound: 1000 ms), inspect exit ${inspect_exit}"

    # Tear down the noise listeners.
    local pid
    for pid in "${noise_pids[@]}"; do kill "${pid}" 2>/dev/null || true; done
    wait 2>/dev/null || true
    rm -rf "${noise_dir}"

    local load_ok="false" within_bound="false"
    if [[ "${created}" -ge 450 ]]; then load_ok="true"; fi
    if [[ "${elapsed_ms}" -lt 1000 ]]; then within_bound="true"; fi
    verify_state "true" "${load_ok}" "T4 load generated 450+ unrelated UDS sockets (got ${created})"
    verify_state "0" "${inspect_exit}" "Inspect succeeds under ${created} unrelated sockets"
    verify_state "true" "${within_bound}" "Inspect bounded under 1s with ${created} unrelated sockets (elapsed ${elapsed_ms} ms)"
}

function test_restart {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Restart Command"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" --local restart "${IOC_NAME}"
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

    bash "${RUNNER_SCRIPT}" --local stop "${IOC_NAME}"

    local state
    state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${IOC_NAME}.service" || true)
    verify_state "inactive" "${state}" "Service is inactive after stop"

    _log "INFO" "Waiting for systemd to cleanup asynchronous resources..."
    sleep 2

    bash "${RUNNER_SCRIPT}" --local start "${IOC_NAME}"
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
    output=$(bash "${RUNNER_SCRIPT}" --local list)

    local ioc_in_output="false"
    local uds_in_output="false"

    if printf "%s" "${output}" | grep -q "${IOC_NAME}";  then ioc_in_output="true"; fi
    if printf "%s" "${output}" | grep -q "${UDS_PATH}";  then uds_in_output="true"; fi

    verify_state "true" "${ioc_in_output}"      "IOC name appears in list output"
    verify_state "true" "${uds_in_output}"      "UDS socket path appears in list output"

    local output_v
    output_v=$(bash "${RUNNER_SCRIPT}" --local -v list)

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
    output_vv=$(bash "${RUNNER_SCRIPT}" --local -vv list)

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

function test_list_options {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test List Option Parsing Flexibility"
    print_sub_divider

    local out_1
    local out_2
    local out_3

    out_1=$(bash "${RUNNER_SCRIPT}" --local list -v | grep "${IOC_NAME}" | awk -F'|' '{print $1}' | tr -d ' ')
    out_2=$(bash "${RUNNER_SCRIPT}" list -v --local | grep "${IOC_NAME}" | awk -F'|' '{print $1}' | tr -d ' ')
    out_3=$(bash "${RUNNER_SCRIPT}" list --local -v | grep "${IOC_NAME}" | awk -F'|' '{print $1}' | tr -d ' ')

    verify_state "${IOC_NAME}" "${out_1}" "Parsed: --local list -v"
    verify_state "${IOC_NAME}" "${out_2}" "Parsed: list -v --local"
    verify_state "${IOC_NAME}" "${out_3}" "Parsed: list --local -v"
}

function test_user_alias {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test --user Alias Equivalence to --local"
    print_sub_divider

    # --user is a thin alias for --local. The IOC was installed and started
    # with --local; observing the same running IOC through --user proves both
    # flags route to the identical local-mode path, not merely that --user parses.
    local via_user via_local user_status active_via_user
    via_user=$(bash "${RUNNER_SCRIPT}" --user list -v | grep "${IOC_NAME}" | awk -F'|' '{print $1}' | tr -d ' ')
    via_local=$(bash "${RUNNER_SCRIPT}" --local list -v | grep "${IOC_NAME}" | awk -F'|' '{print $1}' | tr -d ' ')
    user_status=$(bash "${RUNNER_SCRIPT}" --user status "${IOC_NAME}" 2>&1 || true)

    # Match the exact systemd token, not a bare *active* substring, so that
    # an "Active: inactive" status cannot pass this "reports active" check.
    active_via_user="false"
    [[ "${user_status}" == *"Active: active"* ]] && active_via_user="true"

    verify_state "${IOC_NAME}" "${via_user}" "--user list shows the --local-installed IOC"
    verify_state "${via_local}" "${via_user}" "--user and --local list yield the same IOC"
    verify_state "true" "${active_via_user}" "--user status reports the IOC active"
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
    # user mode (home bin first, then /usr/local/bin, /usr/bin); the runner
    # never consults PATH for con, so neither does the probe. The runner's
    # socat fallback is not mirrored: this check asserts the con utility
    # itself.
    local con_ok="false" con_candidate
    for con_candidate in "${HOME}/.local/bin/con" /usr/local/bin/con /usr/bin/con; do
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
        close_current_remaining SKIP "requires ${SUITE_ID}.S28.camonitor-available"
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

function test_monitor_isolation {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Monitor Input Isolation"
    print_sub_divider

    if [[ "${MONITOR_ISOLATION_APPLICABLE}" != "true" ]]; then
        _log "INFO" "Monitor isolation is not applicable under the Rocky ordinary-user journal policy."
        record_current_state NA "Rocky ordinary-user policy excludes broad journal access"
        close_current_remaining NA "requires ${SUITE_ID}.S29.monitor-isolation-applicable"
        return 0
    fi
    record_current_state PASS

    if [[ "${JOURNAL_AVAILABLE}" != "true" ]]; then
        _log "WARN" "User-scope journal unavailable, skipping monitor isolation test."
        record_current_state SKIP "user journal is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S29.user-journal-available"
        return 0
    fi
    record_current_state PASS

    # Positive control (R8-F2): prove the unit's journal channel is
    # visible before asserting the marker's ABSENCE. The IOC has been
    # running since the earlier start/restart steps with
    # StandardOutput=journal, so at least one unit-attributed line
    # must exist. journalctl prints "-- No entries --" on STDOUT when
    # the window is empty, so that banner must be excluded explicitly
    # or this control is itself vacuous.
    local probe_out
    probe_out=$(journalctl --user -u "epics-@${IOC_NAME}.service" -n 5 --no-pager 2>/dev/null || true)
    local journal_visible="false"
    if [[ -n "${probe_out}" && "${probe_out}" != *"-- No entries --"* ]]; then
        journal_visible="true"
    fi
    verify_state "true" "${journal_visible}" "Journal channel visible for unit (positive control)"

    printf "test_monitor_input_blocked\\n" | setsid bash "${RUNNER_SCRIPT}" --local monitor "${IOC_NAME}" >/dev/null 2>&1 &

    local monitor_pid=$!
    sleep 2

    local log_out
    log_out=$(journalctl --user -u "epics-@${IOC_NAME}.service" --since "5 seconds ago" || true)

    local input_blocked="true"
    if printf "%s" "${log_out}" | grep -q "test_monitor_input_blocked"; then
        input_blocked="false"
    fi

    verify_state "true" "${input_blocked}" "Input securely blocked in monitor mode"

    kill -- -"${monitor_pid}" 2>/dev/null || true
}

function _install_crash_probe {
    local ioc_name="$1"
    local ioc_dir="$2"

    cat << EOF > "${WORKSPACE}/${ioc_name}.conf"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${ioc_dir}"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF

    bash "${RUNNER_SCRIPT}" --local -f install "${WORKSPACE}/${ioc_name}.conf" >/dev/null
}

function _remove_crash_probe {
    local ioc_name="$1"
    local dropin_dir="${SYSTEMD_USER_DIR}/epics-@${ioc_name}.service.d"

    bash "${RUNNER_SCRIPT}" --local remove "${ioc_name}" >/dev/null 2>&1 || true
    rm -f "${dropin_dir}/override.conf"
    rmdir "${dropin_dir}" 2>/dev/null || true
    "${SYSTEMCTL_CMD[@]}" daemon-reload >/dev/null 2>&1 || true
}

function _run_crash_probe {
    local ioc_name="$1"
    local expected_kind="$2"   # "fatal" -> exit 1 failed-to-init; "healthy" -> exit 0 success
    local assertion_name="$3"
    local output
    local exit_code=0
    local rc_ok="false"
    local msg_ok="false"

    # M11/#67: a pre-iocInit FATAL-subset token is now a hard failure (exit 1 with
    # the "failed to initialize" verdict), not the old active-IOC Warning. A healthy
    # IOC reaches the marker and reports success (exit 0); pre-offset / benign noise
    # is correctly ignored.
    output=$(bash "${RUNNER_SCRIPT}" --local start "${ioc_name}" 2>&1) || exit_code=$?
    _remove_crash_probe "${ioc_name}"

    if [[ "${expected_kind}" == "fatal" ]]; then
        if [[ "${exit_code}" == "1" ]]; then rc_ok="true"; fi
        verify_state "true" "${rc_ok}" "${assertion_name}: exit 1"
        if printf "%s" "${output}" | grep -q "failed to initialize"; then msg_ok="true"; fi
        verify_state "true" "${msg_ok}" "${assertion_name}: failed-to-initialize verdict"
    elif [[ "${expected_kind}" == "crashloop" ]]; then
        # M8/#52: a SILENT pre-iocInit crash loop (the child killed by signal,
        # recurring death banner, NO fatal token) is caught by the banner-count
        # path, not a fatal-subset token -> exit 1 with the crash-looping verdict.
        if [[ "${exit_code}" == "1" ]]; then rc_ok="true"; fi
        verify_state "true" "${rc_ok}" "${assertion_name}: exit 1"
        if printf "%s" "${output}" | grep -q "crash-looping"; then msg_ok="true"; fi
        verify_state "true" "${msg_ok}" "${assertion_name}: crash-looping verdict"
    else
        if [[ "${exit_code}" == "0" ]]; then rc_ok="true"; fi
        verify_state "true" "${rc_ok}" "${assertion_name}: exit 0 (healthy)"
        if printf "%s" "${output}" | grep -q "successfully started"; then msg_ok="true"; fi
        verify_state "true" "${msg_ok}" "${assertion_name}: success verdict"
    fi
}

# Runs one benign FATAL token-boundary case through the installed local unit,
# then verifies the start result, operator verdict, and emitted fixture.
function _run_local_fatal_boundary_probe {
    local softioc_bin="$1"
    local ioc_name="$2"
    local ioc_dir="$3"
    local log_file="$4"
    local fixture="$5"
    local assertion_name="$6"
    local emitted="false"

    mkdir -p "${ioc_dir}"
    cat << EOF > "${ioc_dir}/st.cmd"
#!${softioc_bin}
system "echo '${fixture}'"
iocInit()
EOF
    chmod +x "${ioc_dir}/st.cmd"

    _install_crash_probe "${ioc_name}" "${ioc_dir}"
    _run_crash_probe "${ioc_name}" "healthy" "${assertion_name}"
    if grep -qF -- "${fixture}" "${log_file}"; then
        emitted="true"
    fi
    verify_state "true" "${emitted}" "${assertion_name}: fixture emitted"
}

# Exercise the runtime CRASH_LOG_PATTERNS_EXTRA gate with an in-place edit of
# the DEPLOYED conf. Install validates the copy it makes, so appending the value
# afterwards reproduces an operator editing the installed file with an editor;
# the runtime re-read is the only gate left in front of it. The probe IOC
# optionally emits a token after iocInit so a well-formed pattern that matches
# real output can be shown to still corroborate.
#   disposition = rejected   -> exit 0, a warning naming the reason, and no
#                               post-initialization error warning
#   disposition = accepted   -> exit 0, no _EXTRA warning at all
#   disposition = corroborates -> exit 0, no _EXTRA warning, and the pattern
#                               fires the post-initialization error warning
function _probe_runtime_extra_gate {
    local ioc_name="$1"
    local extra_value="$2"
    local emit_token="$3"
    local disposition="$4"
    local expected_reason="$5"
    local assertion_name="$6"
    # Optional: a verbatim conf line, used when the exact whitespace/quoting of
    # the edit is the thing under test; otherwise the value is written quoted.
    local raw_line="${7:-}"

    local ioc_dir="${WORKSPACE}/${ioc_name}"
    mkdir -p "${ioc_dir}"
    {
        printf '#!%s\n' "${softioc_bin}"
        printf 'iocInit\n'
        if [[ -n "${emit_token}" ]]; then
            printf 'system "echo %s"\n' "${emit_token}"
        fi
    } > "${ioc_dir}/st.cmd"
    chmod +x "${ioc_dir}/st.cmd"

    _install_crash_probe "${ioc_name}" "${ioc_dir}"
    if [[ -n "${raw_line}" ]]; then
        printf '%s\n' "${raw_line}" >> "${CONF_DIR}/${ioc_name}.conf"
    else
        printf 'CRASH_LOG_PATTERNS_EXTRA="%s"\n' "${extra_value}" >> "${CONF_DIR}/${ioc_name}.conf"
    fi

    local output
    local exit_code=0
    output=$(bash "${RUNNER_SCRIPT}" --local start "${ioc_name}" 2>&1) || exit_code=$?
    _remove_crash_probe "${ioc_name}"

    local rc_ok="false"
    [[ "${exit_code}" == "0" ]] && rc_ok="true"
    verify_state "true" "${rc_ok}" "${assertion_name}: start succeeds (exit 0)"

    local extra_warned="false"
    local chronic="false"
    printf "%s" "${output}" | grep -q "CRASH_LOG_PATTERNS_EXTRA" && extra_warned="true"
    printf "%s" "${output}" | grep -q "reported errors after initialization" && chronic="true"

    case "${disposition}" in
        rejected)
            local reason_ok="false"
            printf "%s" "${output}" | grep -qF "${expected_reason}" && reason_ok="true"
            verify_state "true" "${reason_ok}" "${assertion_name}: warning names the reason"
            verify_state "false" "${chronic}" "${assertion_name}: no post-initialization error warning"
            ;;
        accepted)
            verify_state "false" "${extra_warned}" "${assertion_name}: no _EXTRA warning"
            ;;
        corroborates)
            verify_state "false" "${extra_warned}" "${assertion_name}: value not rejected"
            verify_state "true" "${chronic}" "${assertion_name}: pattern still corroborates"
            ;;
    esac
}

function test_runtime_extra_pattern_gates {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Runtime CRASH_LOG_PATTERNS_EXTRA Gates"
    print_sub_divider

    local softioc_bin="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}/softIoc"
    if [[ ! -x "${softioc_bin}" ]]; then
        _log "WARN" "softIoc not found at ${softioc_bin}, skipping runtime pattern gate test."
        record_current_state SKIP "softIoc is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S31.softioc-available"
        return 0
    fi
    record_current_state PASS

    local positive_token="M1PROBETOKEN"

    # A: a well-formed value is accepted silently.
    _probe_runtime_extra_gate "ExtraGateWellFormed" "Bergoz link lost|NPCT overrange" "" \
        "accepted" "" "Runtime _EXTRA gate: well-formed value"
    # B: a bare dot matches ordinary log text.
    _probe_runtime_extra_gate "ExtraGateDot" "." "" \
        "rejected" "matches ordinary log text" "Runtime _EXTRA gate: bare dot"
    # C: a trailing pipe is an empty alternation.
    _probe_runtime_extra_gate "ExtraGatePipe" "Bergoz link lost|" "" \
        "rejected" "has an empty alternation" "Runtime _EXTRA gate: trailing pipe"
    # D: an unclosed group is not a valid regular expression (regression).
    _probe_runtime_extra_gate "ExtraGateBadRe" "unclosed(group" "" \
        "rejected" "is not a valid regular expression" "Runtime _EXTRA gate: unclosed group"
    # E: a well-formed value the log actually emits still corroborates (positive control).
    _probe_runtime_extra_gate "ExtraGatePositive" "${positive_token}" "${positive_token}" \
        "corroborates" "" "Runtime _EXTRA gate: positive control"
    # F: a value written with spaces around '=' and no quotes must reach the same
    # verdict install reaches on the trimmed value; without the runtime trim the
    # leading space would defeat the canary and the value would slip through.
    _probe_runtime_extra_gate "ExtraGateSpaced" "" "" \
        "rejected" "matches ordinary log text" "Runtime _EXTRA gate: spaced assignment" \
        "CRASH_LOG_PATTERNS_EXTRA = ioc-runner"
    # G: a whitespace-only value collapses to empty and must be a silent no-op,
    # matching install, not a spurious "matches ordinary log text" warning on an
    # empty pattern.
    _probe_runtime_extra_gate "ExtraGateBlank" "" "" \
        "accepted" "" "Runtime _EXTRA gate: whitespace-only value" \
        "CRASH_LOG_PATTERNS_EXTRA =    "
}

function test_crash_detection {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Crash Detection with softIoc"
    print_sub_divider

    local softioc_bin="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}/softIoc"
    if [[ ! -x "${softioc_bin}" ]]; then
        _log "WARN" "softIoc not found at ${softioc_bin}, skipping crash detection test."
        record_current_state SKIP "softIoc is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S30.softioc-available"
        return 0
    fi
    record_current_state PASS

    local local_log_dir="${IOC_RUNNER_LOCAL_LOG_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/procserv}"
    local fatal_ioc_name="CrashTestFatal"
    local fatal_ioc_dir="${WORKSPACE}/crash_fatal_ioc"

    _run_local_fatal_boundary_probe \
        "${softioc_bin}" \
        "CrashTestFatalLeadingBoundary" \
        "${WORKSPACE}/crash_fatal_leading_boundary_ioc" \
        "${local_log_dir}/CrashTestFatalLeadingBoundary.log" \
        "device_nonfatal=ready" \
        "Crash detection: leading-boundary identifier adjacency remains benign"
    _run_local_fatal_boundary_probe \
        "${softioc_bin}" \
        "CrashTestFatalTrailingBoundary" \
        "${WORKSPACE}/crash_fatal_trailing_boundary_ioc" \
        "${local_log_dir}/CrashTestFatalTrailingBoundary.log" \
        "fatalFlag=ready" \
        "Crash detection: trailing-boundary identifier adjacency remains benign"
    _run_local_fatal_boundary_probe \
        "${softioc_bin}" \
        "CrashTestFatalBoundary" \
        "${WORKSPACE}/crash_fatal_boundary_ioc" \
        "${local_log_dir}/CrashTestFatalBoundary.log" \
        "device_nonfatal_state=ready" \
        "Crash detection: identifier-contained fatal text remains benign"

    mkdir -p "${fatal_ioc_dir}"

    cat << EOF > "${fatal_ioc_dir}/st.cmd"
#!${softioc_bin}
system "sleep 0.5"
system "echo 'FATAL: Simulated softIoc crash'"
system "kill -9 \$PPID"
EOF
    chmod +x "${fatal_ioc_dir}/st.cmd"
    _install_crash_probe "${fatal_ioc_name}" "${fatal_ioc_dir}"
    _run_crash_probe "${fatal_ioc_name}" "fatal" "Crash detection: FATAL softIoc child kill -> exit 1"

    # M8/#52: a SILENT pre-iocInit crash loop — the child is killed by signal
    # repeatedly with NO fatal token in its own output. procServ records the death
    # banner and "The process was killed by signal N"; detection must fire on the
    # recurring-banner count, not a fatal-subset token. (golden-confirmed both VMs)
    local silent_ioc_name="CrashTestSilentLoop"
    local silent_ioc_dir="${WORKSPACE}/crash_silent_ioc"
    mkdir -p "${silent_ioc_dir}"

    cat << EOF > "${silent_ioc_dir}/st.cmd"
#!${softioc_bin}
epicsThreadSleep 0.3
system "kill -9 \$PPID"
EOF
    chmod +x "${silent_ioc_dir}/st.cmd"
    _install_crash_probe "${silent_ioc_name}" "${silent_ioc_dir}"
    _run_crash_probe "${silent_ioc_name}" "crashloop" "Crash detection: silent child-kill loop (no fatal token) -> exit 1 crash-looping"

    local parse_ioc_name="CrashTestParse"
    local parse_ioc_dir="${WORKSPACE}/crash_parse_ioc"
    mkdir -p "${parse_ioc_dir}"

    cat << EOF > "${parse_ioc_dir}/st.cmd"
#!${softioc_bin}
dbLoadRecords("missing.db
EOF
    chmod +x "${parse_ioc_dir}/st.cmd"
    _install_crash_probe "${parse_ioc_name}" "${parse_ioc_dir}"
    _run_crash_probe "${parse_ioc_name}" "fatal" "Crash detection: iocsh parse error -> exit 1"

    local history_ioc_name="CrashTestHistory"
    local history_ioc_dir="${WORKSPACE}/crash_history_ioc"
    mkdir -p "${history_ioc_dir}" "${local_log_dir}"

    cat << EOF > "${history_ioc_dir}/st.cmd"
#!${softioc_bin}
iocInit()
EOF
    chmod +x "${history_ioc_dir}/st.cmd"
    _install_crash_probe "${history_ioc_name}" "${history_ioc_dir}"
    printf "%s\n" "FATAL: historical startup failure before current start" > "${local_log_dir}/${history_ioc_name}.log"
    _run_crash_probe "${history_ioc_name}" "healthy" "Crash detection: historical fatal log ignored for healthy start"

    local truncate_bin
    truncate_bin=$(command -v truncate || true)
    if [[ -n "${truncate_bin}" ]]; then
        record_current_state PASS
        local truncate_ioc_name="CrashTestTruncate"
        local truncate_ioc_dir="${WORKSPACE}/crash_truncate_ioc"
        local truncate_log="${local_log_dir}/${truncate_ioc_name}.log"
        local i
        mkdir -p "${truncate_ioc_dir}" "${local_log_dir}"

        : > "${truncate_log}"
        for i in {1..40}; do
            printf "%s %02d\n" "FATAL: stale failure before truncation" "${i}" >> "${truncate_log}"
        done

        cat << EOF > "${truncate_ioc_dir}/st.cmd"
#!${softioc_bin}
system "${truncate_bin} -s 0 ${truncate_log}"
system "sleep 0.5"
system "echo 'FATAL: new failure after truncation'"
system "kill -9 \$PPID"
EOF
        chmod +x "${truncate_ioc_dir}/st.cmd"
        _install_crash_probe "${truncate_ioc_name}" "${truncate_ioc_dir}"
        _run_crash_probe "${truncate_ioc_name}" "fatal" "Crash detection: truncated log scans new fatal content -> exit 1"
    else
        _log "WARN" "truncate not found, skipping truncated log crash detection test."
        record_current_state SKIP "truncate is unavailable"
        record_current_state SKIP "requires ${SUITE_ID}.S30.truncate-available"
        record_current_state SKIP "requires ${SUITE_ID}.S30.truncate-available"
    fi

    # Issue #92: a pre-existing unreadable .iocsh_history makes iocsh emit the
    # benign "ERROR Permission denied (N) loading '...'" line inside the startup
    # scan window; CRASH_LOG_EXCLUDE_PATTERNS must clear it without weakening the
    # scan. Root bypasses the chmod-0 read denial (CAP_DAC_OVERRIDE), so the line
    # would never be emitted and the probes are skipped as root. Distinct from
    # CrashTestHistory above, which covers historical-log-offset behavior.
    if [[ ${EUID} -eq 0 ]]; then
        _log "WARN" "Running as root: chmod 0 cannot deny reads, skipping history-noise crash scan probes."
        record_current_state NA "read-denial probes do not apply to root"
        close_current_remaining NA "requires ${SUITE_ID}.S30.nonroot-history-probes-applicable"
    else
        record_current_state PASS
        local histnoise_ioc_name="CrashTestHistNoise"
        local histnoise_ioc_dir="${WORKSPACE}/crash_histnoise_ioc"
        local histnoise_log="${local_log_dir}/${histnoise_ioc_name}.log"
        local histnoise_emitted="false"
        mkdir -p "${histnoise_ioc_dir}" "${local_log_dir}"

        cat << EOF > "${histnoise_ioc_dir}/st.cmd"
#!${softioc_bin}
iocInit()
EOF
        chmod +x "${histnoise_ioc_dir}/st.cmd"
        : > "${histnoise_ioc_dir}/.iocsh_history"
        chmod 0 "${histnoise_ioc_dir}/.iocsh_history"
        _install_crash_probe "${histnoise_ioc_name}" "${histnoise_ioc_dir}"
        _run_crash_probe "${histnoise_ioc_name}" "healthy" "Crash detection: benign history-load ERROR excluded from scan"

        # Self-validation: assert the benign line was actually emitted, so this
        # case fails loudly instead of passing vacuously if the environment stops
        # producing it (grep -a: the line carries raw ANSI escape bytes).
        if grep -aq "loading '.*iocsh_history'" "${histnoise_log}" 2>/dev/null; then
            histnoise_emitted="true"
        fi
        verify_state "true" "${histnoise_emitted}" "Crash detection: history-load ERROR present in probe log (self-validation)"

        local histfatal_ioc_name="CrashTestHistFatal"
        local histfatal_ioc_dir="${WORKSPACE}/crash_histfatal_ioc"
        mkdir -p "${histfatal_ioc_dir}"

        cat << EOF > "${histfatal_ioc_dir}/st.cmd"
#!${softioc_bin}
system "sleep 0.5"
system "echo 'FATAL: real failure beside benign history noise'"
system "kill -9 \$PPID"
EOF
        chmod +x "${histfatal_ioc_dir}/st.cmd"
        : > "${histfatal_ioc_dir}/.iocsh_history"
        chmod 0 "${histfatal_ioc_dir}/.iocsh_history"
        _install_crash_probe "${histfatal_ioc_name}" "${histfatal_ioc_dir}"
        _run_crash_probe "${histfatal_ioc_name}" "fatal" "Crash detection: real FATAL beside benign history noise -> exit 1"
    fi
}

function test_persistence {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Enable and Disable (Persistence)"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" --local enable "${IOC_NAME}"

    local link_exist="false"
    if [[ -L "${SYSTEMD_WANTS_DIR}/epics-@${IOC_NAME}.service" ]]; then link_exist="true"; fi
    verify_state "true" "${link_exist}" "Symlink created in default.target.wants (Enable)"

    bash "${RUNNER_SCRIPT}" --local disable "${IOC_NAME}"

    link_exist="false"
    if [[ -L "${SYSTEMD_WANTS_DIR}/epics-@${IOC_NAME}.service" ]]; then link_exist="true"; fi
    verify_state "false" "${link_exist}" "Symlink strictly removed (Disable)"
}

function test_remove {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Remove Command"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" --local remove "${IOC_NAME}"

    local conf_exist="false"
    local state

    if [[ -f "${CONF_DIR}/${IOC_NAME}.conf" ]]; then conf_exist="true"; fi
    state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${IOC_NAME}.service" || true)

    verify_state "false" "${conf_exist}" "Configuration file safely removed"
    verify_state "inactive" "${state}"   "Service completely stopped (inactive)"
}

# U003/M19.T1: --local install deploys the per-user logrotate config + the
# oneshot service + the hourly timer, idempotently. Runs while the IOC is
# installed-but-inactive so the idempotency re-install is not blocked.
function test_local_logrotate {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Local Log Rotation Deploy (U003/M19.T1)"
    print_sub_divider

    if [[ "${LOGROTATE_AVAILABLE}" != "true" ]]; then
        _log "WARN" "logrotate unavailable; skipping M19.T1."
        record_current_state SKIP "logrotate is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S14.logrotate-available"
        return 0
    fi
    record_current_state PASS

    local cfg="${CONF_DIR%/*}/ioc-runner/logrotate.conf"
    local svc="${SYSTEMD_USER_DIR}/epics-logrotate.service"
    local tmr="${SYSTEMD_USER_DIR}/epics-logrotate.timer"
    # The test shell has no LOG_DIR; resolve it like the runner (mirror the
    # crash-probe step) so the glob-pin checks the real deployed path.
    local log_dir="${IOC_RUNNER_LOCAL_LOG_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/procserv}"

    local cfg_exist="false"; [[ -f "${cfg}" ]] && cfg_exist="true"
    verify_state "true" "${cfg_exist}" "M19.T1: logrotate config deployed"
    local svc_exist="false"; [[ -f "${svc}" ]] && svc_exist="true"
    verify_state "true" "${svc_exist}" "M19.T1: epics-logrotate.service deployed"
    local tmr_exist="false"; [[ -f "${tmr}" ]] && tmr_exist="true"
    verify_state "true" "${tmr_exist}" "M19.T1: epics-logrotate.timer deployed"

    if [[ "${cfg_exist}" == "true" ]]; then
        local d_ok="true" directive
        for directive in "weekly" "maxsize 50M" "rotate 8" "copytruncate" "compress" "missingok" "notifempty" "nodateext"; do
            grep -qF "${directive}" "${cfg}" || d_ok="false"
        done
        grep -qF "${log_dir}/*.log {" "${cfg}" || d_ok="false"
        verify_state "true" "${d_ok}" "M19.T1: config pins the rotation contract + LOG_DIR glob"

        local su_absent="true"; grep -qE '^[[:space:]]*su ' "${cfg}" && su_absent="false"
        verify_state "true" "${su_absent}" "M19.T1: no 'su' directive (single-user dir)"

        # M13/#143: pass a throwaway --state so this debug validation does not
        # read the root-owned system default state file (mirrors the runner fix).
        local vstate; vstate=$(mktemp /tmp/ioc-runner-lrvalidate.XXXXXX)
        local validate_ok="true"
        "${LOGROTATE_BIN}" -d --state "${vstate}" "${cfg}" >/dev/null 2>&1 || validate_ok="false"
        rm -f "${vstate}"
        verify_state "true" "${validate_ok}" "M19.T1: logrotate -d validates the config"
    else
        record_current_state SKIP "requires ${SUITE_ID}.S14.rotation-config-exists"
        record_current_state SKIP "requires ${SUITE_ID}.S14.rotation-config-exists"
        record_current_state SKIP "requires ${SUITE_ID}.S14.rotation-config-exists"
    fi

    # Timer armed (the user bus is up in this suite, as the IOC lifecycle steps need it).
    local enabled; enabled=$(systemctl --user is-enabled epics-logrotate.timer 2>/dev/null || true)
    if [[ "${tmr_exist}" == "true" ]]; then
        verify_state "enabled" "${enabled}" "M19.T1: timer enabled"
    else
        record_current_state SKIP "requires ${SUITE_ID}.S14.rotation-timer-exists"
    fi

    # Idempotency: a repeat install must run deploy_local_logrotate (assert it
    # exits 0) and rewrite nothing. The units (not the config) are what
    # units_changed gates, so stat both unit mtimes too, not just the config.
    if [[ "${cfg_exist}" == "true" ]]; then
        local cfg_b svc_b tmr_b rc=0
        cfg_b=$(stat -c %Y "${cfg}" 2>/dev/null || echo 0)
        svc_b=$(stat -c %Y "${svc}" 2>/dev/null || echo 0)
        tmr_b=$(stat -c %Y "${tmr}" 2>/dev/null || echo 0)
        sleep 1
        bash "${RUNNER_SCRIPT}" --local -f install "${CONF_FILE}" >/dev/null 2>&1 || rc=$?
        verify_state "0" "${rc}" "M19.T1: repeat install succeeds (re-runs deploy)"
        local cfg_a svc_a tmr_a
        cfg_a=$(stat -c %Y "${cfg}" 2>/dev/null || echo 0)
        svc_a=$(stat -c %Y "${svc}" 2>/dev/null || echo 0)
        tmr_a=$(stat -c %Y "${tmr}" 2>/dev/null || echo 0)
        verify_state "${cfg_b}-${svc_b}-${tmr_b}" "${cfg_a}-${svc_a}-${tmr_a}" "M19.T1: repeat install rewrites nothing (config + units stable)"
    else
        record_current_state SKIP "requires ${SUITE_ID}.S14.rotation-config-exists"
        record_current_state SKIP "requires ${SUITE_ID}.S14.rotation-config-exists"
    fi
}

# The deployed user service rotates an oversized local log through its real
# systemd ExecStart, preserves the system default state, and supports an
# isolated broken-ExecStart run that proves the same check reports failure.
function test_logrotate_rotation {
    local step="$1"
    local cfg="${CONF_DIR%/*}/ioc-runner/logrotate.conf"
    local log_dir="${IOC_RUNNER_LOCAL_LOG_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/procserv}"
    local probe="${log_dir}/rotateprobe.log"
    local break_execstart="${IOC_RUNNER_TEST_BREAK_LOGROTATE_EXECSTART:-0}"
    local default_state_before=""
    local default_state_after=""
    local service_result=""
    local service_actual=""
    local service_ok="false"
    local archived="false"
    local truncated="false"
    local runtime_state_created="false"
    local start_rc=0
    local cleanup_rc=0

    print_divider
    _log "INFO" "STEP ${step}: Local Log Rotation Through User Service"
    print_sub_divider

    if [[ "${LOGROTATE_AVAILABLE}" != "true" ]]; then
        _log "WARN" "logrotate unavailable; skipping the user-service rotation check."
        record_current_state SKIP "logrotate is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S15.logrotate-available"
        return 0
    fi
    record_current_state PASS
    if [[ ! -f "${cfg}" ]]; then
        verify_state "true" "false" "logrotate config present for user-service test"
        close_current_remaining SKIP "requires ${SUITE_ID}.S15.rotation-config-exists"
        return 0
    fi
    verify_state "true" "true" "logrotate config present for user-service test"

    install -d -m 0750 "${log_dir}"
    head -c "${LOGROTATE_PROBE_BYTES}" /dev/zero > "${probe}"
    systemctl --user stop epics-logrotate.timer epics-logrotate.service >/dev/null 2>&1 || true
    prepare_logrotate_runtime_state
    default_state_before=$(snapshot_system_logrotate_states)

    case "${break_execstart}" in
        0) ;;
        1) install_logrotate_execstart_override ;;
        *)
            _log "ERROR" "IOC_RUNNER_TEST_BREAK_LOGROTATE_EXECSTART must be 0 or 1."
            return 1
            ;;
    esac

    systemctl --user reset-failed epics-logrotate.service >/dev/null 2>&1 || true
    systemctl --user start epics-logrotate.service >/dev/null 2>&1 || start_rc=$?
    service_result=$(systemctl --user show epics-logrotate.service \
        --property=Result --value 2>/dev/null || true)
    service_actual="${start_rc}-${service_result}"
    [[ "${service_actual}" == "0-success" ]] && service_ok="true"

    restore_logrotate_execstart_override || cleanup_rc=1
    default_state_after=$(snapshot_system_logrotate_states)

    verify_state "0-success" "${service_actual}" \
        "deployed logrotate oneshot succeeds through the user manager"

    if [[ "${service_ok}" == "true" ]]; then
        [[ -f "${probe}.1.gz" ]] && archived="true"
        verify_state "true" "${archived}" \
            "user service produced rotateprobe.log.1.gz"
        [[ -f "${probe}" && ! -s "${probe}" ]] && truncated="true"
        verify_state "true" "${truncated}" \
            "user service truncated the live log in place"
        [[ -f "${LOGROTATE_RUNTIME_STATE_PATH}" ]] && runtime_state_created="true"
        verify_state "true" "${runtime_state_created}" \
            "user service created its runtime state file"
    else
        record_current_state SKIP "requires ${SUITE_ID}.S15.oneshot-result-success"
        record_current_state SKIP "requires ${SUITE_ID}.S15.oneshot-result-success"
        record_current_state SKIP "requires ${SUITE_ID}.S15.oneshot-result-success"
    fi
    verify_state "${default_state_before}" "${default_state_after}" \
        "user service leaves the system default logrotate state unchanged"

    rm -f "${probe}" "${probe}".*.gz
    restore_logrotate_runtime_state || cleanup_rc=1
    if (( cleanup_rc != 0 )); then
        _log "ERROR" "Failed to restore logrotate test state."
        return 1
    fi
}

# U003/M19.T3: maxsize triggers a rotation before the weekly mark. Scaled to a
# tiny cap so it does not require a 50M file; a fresh state means a rotation here
# is attributable to size, not the (unseen) weekly interval.
function test_logrotate_maxsize {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Local Log Rotation maxsize path (U003/M19.T3)"
    print_sub_divider

    if [[ "${LOGROTATE_AVAILABLE}" != "true" ]]; then
        _log "WARN" "logrotate unavailable; skipping M19.T3."
        record_current_state SKIP "logrotate is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S16.logrotate-available"
        return 0
    fi
    record_current_state PASS
    local cfg="${CONF_DIR%/*}/ioc-runner/logrotate.conf"
    if [[ ! -f "${cfg}" ]]; then
        verify_state "true" "false" "M19.T3: config present for maxsize test"
        close_current_remaining SKIP "requires ${SUITE_ID}.S16.rotation-config-exists"
        return 0
    fi
    verify_state "true" "true" "M19.T3: config present for maxsize test"

    local tcfg; tcfg=$(mktemp)
    sed 's/maxsize 50M/maxsize 1k/' "${cfg}" > "${tcfg}"
    local log_dir="${IOC_RUNNER_LOCAL_LOG_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/procserv}"
    install -d -m 0750 "${log_dir}"
    local probe="${log_dir}/maxprobe.log"
    head -c 4096 /dev/zero | tr '\0' 'x' > "${probe}"
    local state; state=$(mktemp)
    "${LOGROTATE_BIN}" --state "${state}" "${tcfg}" >/dev/null 2>&1 || true

    local rotated="false"; [[ -f "${probe}.1.gz" ]] && rotated="true"
    verify_state "true" "${rotated}" "M19.T3: maxsize rotates the log before the weekly mark"

    rm -f "${probe}" "${probe}".*.gz "${state}" "${tcfg}"
}

# U003/M19: a per-IOC remove must leave the shared timer (never-auto-remove);
# then perform the documented manual teardown and confirm it removes the timer.
function test_logrotate_teardown {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Local Log Rotation Teardown (U003/M19, never-auto-remove)"
    print_sub_divider

    if [[ "${LOGROTATE_AVAILABLE}" != "true" ]]; then
        _log "WARN" "logrotate unavailable; skipping M19 teardown checks."
        record_current_state SKIP "logrotate is unavailable"
        close_current_remaining SKIP "requires ${SUITE_ID}.S34.logrotate-available"
        return 0
    fi
    record_current_state PASS
    local tmr="${SYSTEMD_USER_DIR}/epics-logrotate.timer"

    local survived="false"; [[ -f "${tmr}" ]] && survived="true"
    verify_state "true" "${survived}" "M19: per-IOC remove leaves the shared timer (never-auto-remove)"

    # Documented manual teardown (operator action) + host hygiene.
    systemctl --user disable --now epics-logrotate.timer >/dev/null 2>&1 || true
    rm -f "${SYSTEMD_USER_DIR}/epics-logrotate.service" "${tmr}"
    rm -f "${CONF_DIR%/*}/ioc-runner/logrotate.conf"
    systemctl --user daemon-reload || true

    local gone="true"; [[ -f "${tmr}" ]] && gone="false"
    verify_state "true" "${gone}" "M19: manual teardown removes the timer"
}

# Verifies namespaced local path settings and unified-variable precedence
# through artifacts emitted by the real install command. The procServ
# executable is an outer boundary: install records it but does not execute it.
function test_local_install_path_resolution {
    local step="$1"
    local namespaced_dir="${WORKSPACE}/namespaced_ioc"
    local namespaced_conf="${WORKSPACE}/namespaced-conf"
    local namespaced_systemd="${WORKSPACE}/namespaced-systemd"
    local namespaced_log="${WORKSPACE}/namespaced-log"
    local namespaced_installed_conf="${namespaced_conf}/namespaced_ioc.conf"
    local namespaced_installed_unit="${namespaced_systemd}/epics-@.service"
    local namespaced_install_rc=0
    local namespaced_conf_exists="false"
    local namespaced_baked_log=""
    local precedence_dir="${WORKSPACE}/precedence_ioc"
    local unified_conf="${WORKSPACE}/precedence-unified-conf"
    local unified_systemd="${WORKSPACE}/precedence-unified-systemd"
    local unified_run="${WORKSPACE}/precedence-unified-run"
    local unified_log="${WORKSPACE}/precedence-unified-log"
    local namespaced_fallback_conf="${WORKSPACE}/precedence-namespaced-conf"
    local namespaced_fallback_systemd="${WORKSPACE}/precedence-namespaced-systemd"
    local namespaced_fallback_run="${WORKSPACE}/precedence-namespaced-run"
    local namespaced_fallback_log="${WORKSPACE}/precedence-namespaced-log"
    local precedence_installed_conf="${unified_conf}/precedence_ioc.conf"
    local precedence_installed_unit="${unified_systemd}/epics-@.service"
    local precedence_install_rc=0
    local conf_in_unified="false"
    local conf_in_namespaced="false"
    local port_line=""
    local port_in_unified="false"
    local port_in_namespaced="false"
    local unit_in_unified="false"
    local unit_in_namespaced="false"
    local precedence_baked_log=""
    local fallback_unset_root="${WORKSPACE}/fallback-unset"
    local fallback_unset_dir="${fallback_unset_root}/fallbackUnset"
    local fallback_unset_conf="${fallback_unset_root}/config/procServ.d"
    local fallback_unset_systemd="${fallback_unset_root}/systemd"
    local fallback_unset_home="${fallback_unset_root}/home"
    local fallback_unset_log="${fallback_unset_home}/.local/state/procserv"
    local fallback_unset_unit="${fallback_unset_systemd}/epics-@.service"
    local fallback_unset_rc=0
    local fallback_unset_baked_log=""
    local fallback_xdg_root="${WORKSPACE}/fallback-xdg"
    local fallback_xdg_dir="${fallback_xdg_root}/fallbackXdg"
    local fallback_xdg_conf="${fallback_xdg_root}/config/procServ.d"
    local fallback_xdg_systemd="${fallback_xdg_root}/systemd"
    local fallback_xdg_home="${fallback_xdg_root}/home"
    local fallback_xdg_state="${fallback_xdg_root}/state"
    local fallback_xdg_log="${fallback_xdg_state}/procserv"
    local fallback_xdg_unit="${fallback_xdg_systemd}/epics-@.service"
    local fallback_xdg_rc=0
    local fallback_xdg_baked_log=""

    print_divider
    _log "INFO" "STEP ${step}: Local Install Path Resolution"
    print_sub_divider

    mkdir -p "${namespaced_dir}" "${namespaced_conf}" \
        "${namespaced_systemd}" "${namespaced_log}"
    touch "${namespaced_dir}/st.cmd"
    chmod +x "${namespaced_dir}/st.cmd"

    (cd "${namespaced_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1)

    (
        cd "${namespaced_dir}"
        IOC_RUNNER_LOCAL_CONF_DIR="${namespaced_conf}" \
        IOC_RUNNER_LOCAL_SYSTEMD_DIR="${namespaced_systemd}" \
        IOC_RUNNER_LOCAL_LOG_DIR="${namespaced_log}" \
        IOC_RUNNER_PROCSERV_TOOL=/bin/true \
            bash "${RUNNER_SCRIPT}" --local -f install . >/dev/null 2>&1
    ) || namespaced_install_rc=$?
    verify_state "0" "${namespaced_install_rc}" \
        "Namespaced CONF_DIR, SYSTEMD_DIR, and LOG_DIR route --local install"

    if [[ -f "${namespaced_installed_conf}" ]]; then
        namespaced_conf_exists="true"
    fi
    verify_state "true" "${namespaced_conf_exists}" \
        "IOC_RUNNER_LOCAL_CONF_DIR resolves to namespaced path"

    if [[ -f "${namespaced_installed_unit}" ]]; then
        namespaced_baked_log=$(sed -n \
            's|^ExecStart=.*--logfile=\(.*\)/%i\.log .*|\1|p' \
            "${namespaced_installed_unit}" | head -n1)
    fi
    verify_state "${namespaced_log}" "${namespaced_baked_log}" \
        "IOC_RUNNER_LOCAL_LOG_DIR reaches the installed unit logfile path"

    mkdir -p "${precedence_dir}" "${unified_conf}" "${unified_systemd}" \
        "${unified_run}" "${unified_log}" "${namespaced_fallback_conf}" \
        "${namespaced_fallback_systemd}" "${namespaced_fallback_run}" \
        "${namespaced_fallback_log}"
    touch "${precedence_dir}/st.cmd"
    chmod +x "${precedence_dir}/st.cmd"

    (cd "${precedence_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1)

    (
        cd "${precedence_dir}"
        IOC_RUNNER_CONF_DIR="${unified_conf}" \
        IOC_RUNNER_SYSTEMD_DIR="${unified_systemd}" \
        IOC_RUNNER_RUN_DIR="${unified_run}" \
        IOC_RUNNER_LOG_DIR="${unified_log}" \
        IOC_RUNNER_LOCAL_CONF_DIR="${namespaced_fallback_conf}" \
        IOC_RUNNER_LOCAL_SYSTEMD_DIR="${namespaced_fallback_systemd}" \
        IOC_RUNNER_LOCAL_RUN_DIR="${namespaced_fallback_run}" \
        IOC_RUNNER_LOCAL_LOG_DIR="${namespaced_fallback_log}" \
        IOC_RUNNER_PROCSERV_TOOL=/bin/true \
            bash "${RUNNER_SCRIPT}" --local -f install . >/dev/null 2>&1
    ) || precedence_install_rc=$?
    verify_state "0" "${precedence_install_rc}" \
        "Unified path variables take precedence during --local install"

    if [[ -f "${precedence_installed_conf}" ]]; then
        conf_in_unified="true"
        port_line=$(grep '^IOC_PORT=' "${precedence_installed_conf}" 2>/dev/null || true)
    fi
    if [[ -f "${namespaced_fallback_conf}/precedence_ioc.conf" ]]; then
        conf_in_namespaced="true"
    fi
    verify_state "true" "${conf_in_unified}" \
        "IOC_RUNNER_CONF_DIR overrides IOC_RUNNER_LOCAL_CONF_DIR"
    verify_state "false" "${conf_in_namespaced}" \
        "IOC_RUNNER_LOCAL_CONF_DIR is unused when IOC_RUNNER_CONF_DIR is set"

    if [[ "${port_line}" == *"${unified_run}/precedence_ioc/control"* ]]; then
        port_in_unified="true"
    fi
    if [[ "${port_line}" == *"${namespaced_fallback_run}/precedence_ioc/control"* ]]; then
        port_in_namespaced="true"
    fi
    verify_state "true" "${port_in_unified}" \
        "IOC_RUNNER_RUN_DIR reaches the installed IOC_PORT"
    verify_state "false" "${port_in_namespaced}" \
        "IOC_RUNNER_LOCAL_RUN_DIR is unused when IOC_RUNNER_RUN_DIR is set"

    if [[ -f "${precedence_installed_unit}" ]]; then
        unit_in_unified="true"
        precedence_baked_log=$(sed -n \
            's|^ExecStart=.*--logfile=\(.*\)/%i\.log .*|\1|p' \
            "${precedence_installed_unit}" | head -n1)
    fi
    if [[ -f "${namespaced_fallback_systemd}/epics-@.service" ]]; then
        unit_in_namespaced="true"
    fi
    verify_state "true" "${unit_in_unified}" \
        "IOC_RUNNER_SYSTEMD_DIR receives the installed unit"
    verify_state "false" "${unit_in_namespaced}" \
        "IOC_RUNNER_LOCAL_SYSTEMD_DIR is unused when IOC_RUNNER_SYSTEMD_DIR is set"
    verify_state "${unified_log}" "${precedence_baked_log}" \
        "IOC_RUNNER_LOG_DIR reaches the installed unit logfile path"

    mkdir -p "${fallback_unset_dir}" "${fallback_unset_conf}" \
        "${fallback_unset_systemd}" "${fallback_unset_home}"
    touch "${fallback_unset_dir}/st.cmd"
    chmod +x "${fallback_unset_dir}/st.cmd"
    (cd "${fallback_unset_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1)

    (
        cd "${fallback_unset_dir}"
        env -u XDG_STATE_HOME -u IOC_RUNNER_LOG_DIR -u IOC_RUNNER_LOCAL_LOG_DIR \
            HOME="${fallback_unset_home}" \
            IOC_RUNNER_LOCAL_CONF_DIR="${fallback_unset_conf}" \
            IOC_RUNNER_LOCAL_SYSTEMD_DIR="${fallback_unset_systemd}" \
            IOC_RUNNER_PROCSERV_TOOL=/bin/true \
            bash "${RUNNER_SCRIPT}" --local -f install . >/dev/null 2>&1
    ) || fallback_unset_rc=$?
    if [[ ${fallback_unset_rc} -eq 0 && -f "${fallback_unset_unit}" ]]; then
        fallback_unset_baked_log=$(sed -n \
            's|^ExecStart=.*--logfile=\(.*\)/%i\.log .*|\1|p' \
            "${fallback_unset_unit}" | head -n1)
    fi
    verify_state "${fallback_unset_log}" "${fallback_unset_baked_log}" \
        "XDG_STATE_HOME unset reaches the installed unit logfile fallback"

    mkdir -p "${fallback_xdg_dir}" "${fallback_xdg_conf}" \
        "${fallback_xdg_systemd}" "${fallback_xdg_home}" \
        "${fallback_xdg_state}"
    touch "${fallback_xdg_dir}/st.cmd"
    chmod +x "${fallback_xdg_dir}/st.cmd"
    (cd "${fallback_xdg_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1)

    (
        cd "${fallback_xdg_dir}"
        env -u IOC_RUNNER_LOG_DIR -u IOC_RUNNER_LOCAL_LOG_DIR \
            HOME="${fallback_xdg_home}" \
            XDG_STATE_HOME="${fallback_xdg_state}" \
            IOC_RUNNER_LOCAL_CONF_DIR="${fallback_xdg_conf}" \
            IOC_RUNNER_LOCAL_SYSTEMD_DIR="${fallback_xdg_systemd}" \
            IOC_RUNNER_PROCSERV_TOOL=/bin/true \
            bash "${RUNNER_SCRIPT}" --local -f install . >/dev/null 2>&1
    ) || fallback_xdg_rc=$?
    if [[ ${fallback_xdg_rc} -eq 0 && -f "${fallback_xdg_unit}" ]]; then
        fallback_xdg_baked_log=$(sed -n \
            's|^ExecStart=.*--logfile=\(.*\)/%i\.log .*|\1|p' \
            "${fallback_xdg_unit}" | head -n1)
    fi
    verify_state "${fallback_xdg_log}" "${fallback_xdg_baked_log}" \
        "XDG_STATE_HOME reaches the installed unit logfile path"
}

# M6 (#117): the local shared-asset (systemd template) refresh contract.
# Reorder puts deployment after the abort gates; the diff-aware policy keeps an
# identical asset untouched and, on a difference, defaults to keep unless the
# invoker forces the update. Template-only so the check is independent of the
# M13 logrotate-validation state-file issue. verify_state pulls the S36 catalog
# rows in this emission order.
function test_m6_shared_asset_refresh {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: M6 Shared-Asset Refresh (reorder + diff-aware keep/update/--force)"
    print_sub_divider

    local tpl="${SYSTEMD_USER_DIR}/epics-@.service"
    local root_dir probe_dir conf out a h1 h2 ht rc
    root_dir=$(mktemp -d /tmp/ioc-runner-m6probe.XXXXXX)
    probe_dir="${root_dir}/m6probe"
    mkdir -p "${probe_dir}"
    printf '#!/bin/bash\necho hi\n' > "${probe_dir}/st.cmd"
    chmod +x "${probe_dir}/st.cmd"
    conf="${probe_dir}/m6probe.conf"
    cat > "${conf}" <<EOF
IOC_NAME="m6probe"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${probe_dir}"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF

    bash "${RUNNER_SCRIPT}" --local remove m6probe >/dev/null 2>&1 || true
    rm -f "${tpl}" "${tpl}".bak.* 2>/dev/null

    # T2: absent -> deploy.
    out=$(bash "${RUNNER_SCRIPT}" --local install "${conf}" 2>&1)
    a="false"; [[ -f "${tpl}" ]] && a="true"
    verify_state "true" "${a}" "T2: absent template deployed"
    a="false"; printf '%s\n' "${out}" | grep -q "Deployed user-level systemd template" && a="true"
    verify_state "true" "${a}" "T2: deploy message emitted"

    # T3: identical -> keep untouched, no backup, no update message. The 'y'
    # accepts the per-IOC .conf overwrite prompt (out of M6 scope); a non-TTY
    # stdin then keeps the identical shared asset without prompting.
    h1=$(sha256sum "${tpl}" | cut -d' ' -f1)
    out=$(printf 'y\n' | bash "${RUNNER_SCRIPT}" --local install "${conf}" 2>&1)
    h2=$(sha256sum "${tpl}" | cut -d' ' -f1)
    verify_state "${h1}" "${h2}" "T3: identical template kept unchanged"
    a="true"; ls "${tpl}".bak.* >/dev/null 2>&1 && a="false"
    verify_state "true" "${a}" "T3: identical install made no backup"
    a="true"; printf '%s\n' "${out}" | grep -qE "Updated user-level|Backed up" && a="false"
    verify_state "true" "${a}" "T3: identical install emitted no update message"

    # T4: different + non-interactive + no --force -> keep, report, no overwrite.
    printf '\n# m6 tamper\n' >> "${tpl}"
    ht=$(sha256sum "${tpl}" | cut -d' ' -f1)
    out=$(printf 'y\n' | bash "${RUNNER_SCRIPT}" --local install "${conf}" 2>&1)
    h2=$(sha256sum "${tpl}" | cut -d' ' -f1)
    verify_state "${ht}" "${h2}" "T4: differing template kept non-interactively"
    a="false"; printf '%s\n' "${out}" | grep -qi "keeping the existing" && a="true"
    verify_state "true" "${a}" "T4: keep message emitted"

    # T5: different + --force -> update + backup.
    out=$(printf 'y\n' | bash "${RUNNER_SCRIPT}" --local -f install "${conf}" 2>&1)
    h2=$(sha256sum "${tpl}" | cut -d' ' -f1)
    a="false"; [[ "${h2}" != "${ht}" ]] && a="true"
    verify_state "true" "${a}" "T5: force updated the differing template"
    a="false"; ls "${tpl}".bak.* >/dev/null 2>&1 && a="true"
    verify_state "true" "${a}" "T5: force update created a backup"

    # T1: abort integrity -- a declined reinstall returns nonzero and leaves the
    # shared template unchanged (deployment now follows the abort gates).
    h1=$(sha256sum "${tpl}" | cut -d' ' -f1)
    rc=0
    printf 'n\n' | bash "${RUNNER_SCRIPT}" --local install "${conf}" >/dev/null 2>&1 || rc=$?
    a="false"; [[ "${rc}" -ne 0 ]] && a="true"
    verify_state "true" "${a}" "T1: declined reinstall returns nonzero"
    h2=$(sha256sum "${tpl}" | cut -d' ' -f1)
    verify_state "${h1}" "${h2}" "T1: template unchanged on abort"

    bash "${RUNNER_SCRIPT}" --local remove m6probe >/dev/null 2>&1 || true
    rm -rf "${root_dir}"
}

function run_all_tests {
    local -a pipeline=(
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
        "test_local_logrotate"
        "test_logrotate_rotation"
        "test_logrotate_maxsize"
        "test_start"
        "test_status"
        "test_view"
        "test_inspect"
        "test_inspect_bounded_runtime"
        "test_restart"
        "test_stop"
        "test_socket_list"
        "test_list_options"
        "test_user_alias"
        "test_console_attach"
        "test_channel_access"
        "test_monitor_isolation"
        "test_crash_detection"
        "test_runtime_extra_pattern_gates"
        "test_persistence"
        "test_remove"
        "test_logrotate_teardown"
        "test_local_install_path_resolution"
        "test_m6_shared_asset_refresh"
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
        step=$((step + 1))
    done
}

run_all_tests
