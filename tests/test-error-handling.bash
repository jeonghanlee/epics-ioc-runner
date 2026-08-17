#!/usr/bin/env bash
#
# Error path and negative-case tests for ioc-runner.
# Requires only mock con and procServ binaries, both exported by _setup via
# IOC_RUNNER_CON_TOOL / IOC_RUNNER_PROCSERV_TOOL. Does not require EPICS, a host
# procServ, or a running systemd service.

set -e
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
umask 077
unset BASH_ENV ENV CDPATH GIT_DIR GIT_WORK_TREE

declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g BLUE='\033[0;34m'
declare -g YELLOW='\033[0;33m'
declare -g NC='\033[0m'

declare -g SC_RPATH="${BASH_SOURCE[0]}"
declare -g SC_TOP=""
if [[ "${SC_RPATH}" != /* ]]; then
    SC_RPATH="${PWD}/${SC_RPATH}"
fi
SC_TOP="${SC_RPATH%/*}"

declare -g RUNNER_SCRIPT="${SC_TOP}/../bin/ioc-runner"
declare -gr SUITE_ID="error-handling"
declare -gr SUITE_SCOPE="none"
declare -gr SUITE_RUNNER="source"
declare -gr SUITE_CATEGORY="error-contract"
declare -g REPORT_DIR=""
declare -g REPORT_READY=0
declare -g CURRENT_STEP_ID=""
declare -g CURRENT_STEP_CHECK_INDEX=0
declare -g MOCK_CON_BIN=""
declare -g TEST_TMPDIR=""
declare -g -a ERROR_CATALOG_ROWS=(
    "P00|error-handling.P00.runner-source-readable|REQUIRED|direct-inspection"
    "S02|error-handling.S02.help-exits-0|BEHAVIOR|real-path"
    "S02|error-handling.S02.h-exits-0|BEHAVIOR|real-path"
    "S02|error-handling.S02.no-arguments-exits-0|BEHAVIOR|real-path"
    "S02|error-handling.S02.unknown-command-exits-1|BEHAVIOR|real-path"
    "S02|error-handling.S02.v-exits-0-from-unrelated-cwd|BEHAVIOR|real-path"
    "S02|error-handling.S02.v-produces-valid-version-output-from-unrelated-cwd|BEHAVIOR|real-path"
    "S02|error-handling.S02.v-start-exits-1-verbose-restricted-to-list|BEHAVIOR|real-path"
    "S02|error-handling.S02.vv-status-exits-1-verbose-restricted-to-list|BEHAVIOR|real-path"
    "S02|error-handling.S02.local-v-list-exits-0-verbose-valid-for-list|BEHAVIOR|real-path"
    "S03|error-handling.S03.start-without-target-exits-1|BEHAVIOR|real-path"
    "S03|error-handling.S03.stop-without-target-exits-1|BEHAVIOR|real-path"
    "S03|error-handling.S03.restart-without-target-exits-1|BEHAVIOR|real-path"
    "S03|error-handling.S03.status-without-target-exits-1|BEHAVIOR|real-path"
    "S03|error-handling.S03.enable-without-target-exits-1|BEHAVIOR|real-path"
    "S03|error-handling.S03.disable-without-target-exits-1|BEHAVIOR|real-path"
    "S03|error-handling.S03.remove-without-target-exits-1|BEHAVIOR|real-path"
    "S03|error-handling.S03.attach-without-target-exits-1|BEHAVIOR|real-path"
    "S03|error-handling.S03.view-without-target-exits-1|BEHAVIOR|real-path"
    "S04|error-handling.S04.generate-native-dot-path-resolves-successfully|BEHAVIOR|real-path"
    "S04|error-handling.S04.configuration-artifact-created-dynamically|BEHAVIOR|real-path"
    "S04|error-handling.S04.identical-artifact-natively-bypasses-overwrite-and-exits-0|BEHAVIOR|real-path"
    "S04|error-handling.S04.identical-re-generate-takes-the-skip-path|BEHAVIOR|real-path"
    "S04|error-handling.S04.identical-skip-reasserts-conf-mode-0600-123|BEHAVIOR|real-path"
    "S04|error-handling.S04.differential-artifact-prompt-exits-1-on-eof|BEHAVIOR|real-path"
    "S04|error-handling.S04.differential-artifact-prompt-exits-1-on-user-decline|BEHAVIOR|real-path"
    "S04|error-handling.S04.forced-overwrite-ignores-diff-constraint-and-exits-0|BEHAVIOR|real-path"
    "S05|error-handling.S05.directory-based-installation-resolves-artifact-correctly|BEHAVIOR|real-path"
    "S05|error-handling.S05.artifact-successfully-routed-to-configuration-directory|BEHAVIOR|real-path"
    "S05|error-handling.S05.install-overwrite-prompt-exits-1-on-eof|BEHAVIOR|real-path"
    "S05|error-handling.S05.install-eof-abort-preserves-existing-conf-marker-retained|BEHAVIOR|real-path"
    "S05|error-handling.S05.install-overwrite-prompt-exits-1-on-user-decline|BEHAVIOR|real-path"
    "S05|error-handling.S05.install-decline-abort-preserves-existing-conf-marker-retained|BEHAVIOR|real-path"
    "S06|error-handling.S06.atomic-install-no-partial-conf-across-120-interrupted-installs|BEHAVIOR|real-path"
    "S06|error-handling.S06.atomic-install-install-exits-only-0-or-124-under-interruption|BEHAVIOR|real-path"
    "S07|error-handling.S07.generate-with-invalid-directory-name-exits-1|BEHAVIOR|real-path"
    "S07|error-handling.S07.generate-with-no-executable-scripts-exits-1|BEHAVIOR|real-path"
    "S07|error-handling.S07.generate-with-multiple-candidates-aborts-interactively|BEHAVIOR|real-path"
    "S07|error-handling.S07.generate-with-force-flag-resolves-multiple-candidates-and-exits-0|BEHAVIOR|real-path"
    "S07|error-handling.S07.multiple-cmd-candidates-without-input-exits-1-no-default|BEHAVIOR|real-path"
    "S07|error-handling.S07.generate-overwrite-prompt-exits-1-on-eof|BEHAVIOR|real-path"
    "S07|error-handling.S07.generate-eof-abort-preserves-existing-conf-unchanged|BEHAVIOR|real-path"
    "S07|error-handling.S07.generate-abort-leaves-no-staged-tmp-in-the-target-dir-107|BEHAVIOR|real-path"
    "S07|error-handling.S07.generate-succeeds-with-a-poisoned-tmpdir-107-same-dir-staging|BEHAVIOR|real-path"
    "S07|error-handling.S07.local-generate-writes-the-conf-0600-107|BEHAVIOR|real-path"
    "S07|error-handling.S07.system-mode-generate-succeeds-with-a-poisoned-tmpdir-107|BEHAVIOR|real-path"
    "S07|error-handling.S07.system-mode-generate-writes-the-conf-0660-107|BEHAVIOR|real-path"
    "S08|error-handling.S08.install-with-missing-conf-file-exits-1|BEHAVIOR|real-path"
    "S08|error-handling.S08.install-with-missing-system-template-exits-1|BEHAVIOR|real-path"
    "S08|error-handling.S08.install-directory-with-mismatched-conf-name-exits-1|BEHAVIOR|real-path"
    "S08|error-handling.S08.install-file-direct-with-invalid-ioc-name-exits-1|BEHAVIOR|real-path"
    "S09|error-handling.S09.plain-list-succeeds-with-broken-ss-no-vv-dependency|BEHAVIOR|real-path"
    "S09|error-handling.S09.list-vv-with-broken-ss-exits-1|BEHAVIOR|real-path"
    "S09|error-handling.S09.list-vv-failure-names-ss-in-the-error|BEHAVIOR|real-path"
    "S10|error-handling.S10.stop-on-a-never-installed-name-exits-1|BEHAVIOR|real-path"
    "S10|error-handling.S10.enable-on-a-never-installed-name-exits-1|BEHAVIOR|real-path"
    "S10|error-handling.S10.disable-on-a-never-installed-name-exits-1|BEHAVIOR|real-path"
    "S10|error-handling.S10.remove-on-a-never-installed-name-exits-1|BEHAVIOR|real-path"
    "S10|error-handling.S10.view-on-a-never-installed-name-exits-1|BEHAVIOR|real-path"
    "S10|error-handling.S10.gate-message-names-the-missing-configuration|BEHAVIOR|real-path"
    "S11|error-handling.S11.exactly-one-ioc-port-replacement-warning|BEHAVIOR|real-path"
    "S17|error-handling.S17.system-differing-ioc-runner-log-dir-triggers-warning|BEHAVIOR|real-path"
    "S17|error-handling.S17.system-matching-ioc-runner-log-dir-suppresses-warning|BEHAVIOR|real-path"
    "S17|error-handling.S17.local-mode-suppresses-log-dir-guard|BEHAVIOR|real-path"
    "S19|error-handling.S19.relative-ioc-runner-conf-dir-exits-1-on-list|BEHAVIOR|real-path"
    "S19|error-handling.S19.relative-conf-dir-error-names-the-resolved-directory|BEHAVIOR|real-path"
    "S19|error-handling.S19.whitespace-conf-dir-exits-1-on-status|BEHAVIOR|real-path"
    "S19|error-handling.S19.whitespace-conf-dir-error-names-the-resolved-directory|BEHAVIOR|real-path"
    "S19|error-handling.S19.absolute-conf-dir-passes-the-guard|BEHAVIOR|real-path"
    "S21|error-handling.S21.install-proceeds-when-the-rotation-cfg-dir-is-uncreatable-110|BEHAVIOR|real-path"
    "S21|error-handling.S21.uncreatable-cfg-dir-warns-and-skips-rotation-110|BEHAVIOR|real-path"
    "S23|error-handling.S23.completion-script-available|REQUIRED|direct-inspection"
    "S23|error-handling.S23.bare-invocation-offers-generate-install-list|BEHAVIOR|real-path"
    "S23|error-handling.S23.dash-prefix-offers-global-options|BEHAVIOR|real-path"
    "S23|error-handling.S23.system-mode-reads-ioc-runner-system-conf-dir|BEHAVIOR|real-path"
    "S23|error-handling.S23.local-mode-reads-ioc-runner-local-conf-dir|BEHAVIOR|real-path"
    "S23|error-handling.S23.ioc-runner-conf-dir-overrides-local-var-in-completion|BEHAVIOR|real-path"
    "S23|error-handling.S23.list-command-suggests-v-and-vv|BEHAVIOR|real-path"
    "S23|error-handling.S23.st-prefix-narrows-to-start-stop-status|BEHAVIOR|real-path"
    "S23|error-handling.S23.missing-conf-dir-yields-empty-compreply|BEHAVIOR|real-path"
    "S24|error-handling.S24.view-bad-name-whitespace-exits-1-via-name-validation|BEHAVIOR|real-path"
    "S24|error-handling.S24.view-bad-name-special-char-exits-1-via-name-validation|BEHAVIOR|real-path"
    "S24|error-handling.S24.view-bad-name-period-exits-1-via-name-validation|BEHAVIOR|real-path"
    "S24|error-handling.S24.view-bad-name-produces-invalid-ioc-name-error-message|BEHAVIOR|real-path"
    "S25|error-handling.S25.install-with-illegal-characters-in-cmd-exits-1|BEHAVIOR|real-path"
    "S25|error-handling.S25.install-with-wrong-local-user-exits-1|BEHAVIOR|real-path"
    "S25|error-handling.S25.install-without-directory-execute-permission-exits-1|BEHAVIOR|real-path"
    "S25|error-handling.S25.install-with-missing-required-key-ioc-cmd-exits-1|BEHAVIOR|real-path"
    "S25|error-handling.S25.install-with-in-system-ioc-chdir-exits-1|BEHAVIOR|real-path"
    "S25|error-handling.S25.rejection-error-references-the-component|BEHAVIOR|real-path"
    "S25|error-handling.S25.install-with-bare-ioc-chdir-exits-1|BEHAVIOR|real-path"
    "S25|error-handling.S25.bare-rejected-by-the-absolute-path-requirement-m6-109|BEHAVIOR|real-path"
    "S25|error-handling.S25.install-with-relative-ioc-chdir-exits-1|BEHAVIOR|real-path"
    "S25|error-handling.S25.relative-ioc-chdir-error-names-the-absolute-path-requirement|BEHAVIOR|real-path"
    "S25|error-handling.S25.install-with-multi-word-ioc-cmd-exits-1|BEHAVIOR|real-path"
    "S25|error-handling.S25.multi-word-ioc-cmd-error-names-the-single-word-contract|BEHAVIOR|real-path"
    "S26|error-handling.S26.attach-with-missing-conf-exits-1|BEHAVIOR|real-path"
    "S26|error-handling.S26.attach-with-missing-ioc-port-key-exits-1|BEHAVIOR|real-path"
    "S26|error-handling.S26.attach-error-references-missing-ioc-port-key|BEHAVIOR|real-path"
    "S27|error-handling.S27.nonroot-permission-probes-applicable|APPLICABILITY|direct-inspection"
    "S27|error-handling.S27.list-with-no-active-sockets-exits-0|BEHAVIOR|real-path"
    "S27|error-handling.S27.genuinely-empty-list-carries-no-permission-hint|BEHAVIOR|real-path"
    "S27|error-handling.S27.list-with-a-non-traversable-socket-dir-exits-0|BEHAVIOR|real-path"
    "S27|error-handling.S27.non-traversable-socket-dir-appends-the-permission-hint|BEHAVIOR|real-path"
    "S28|error-handling.S28.inspect-without-root-privileges-exits-1|BEHAVIOR|real-path"
    "S29|error-handling.S29.nonroot-permission-probes-applicable|APPLICABILITY|direct-inspection"
    "S29|error-handling.S29.generate-into-a-non-writable-directory-exits-1|BEHAVIOR|real-path"
    "S29|error-handling.S29.generate-staging-failure-names-directory-writability|BEHAVIOR|real-path"
    "S29|error-handling.S29.generate-staging-failure-hides-the-raw-mktemp-error|BEHAVIOR|real-path"
    "S30|error-handling.S30.nonroot-permission-probes-applicable|APPLICABILITY|direct-inspection"
    "S30|error-handling.S30.view-of-an-absent-conf-exits-1|BEHAVIOR|real-path"
    "S30|error-handling.S30.view-missing-conf-error-rides-stderr|BEHAVIOR|real-path"
    "S30|error-handling.S30.view-missing-conf-closing-divider-joins-the-error-on-stderr|BEHAVIOR|real-path"
    "S30|error-handling.S30.view-missing-conf-stdout-keeps-only-the-header-divider|BEHAVIOR|real-path"
    "S30|error-handling.S30.view-of-an-unreadable-conf-dir-exits-1|BEHAVIOR|real-path"
    "S30|error-handling.S30.view-names-the-access-barrier-for-an-unreadable-conf-dir|BEHAVIOR|real-path"
    "S30|error-handling.S30.view-does-not-misreport-an-unreadable-conf-dir-as-not-found|BEHAVIOR|real-path"
    "S31|error-handling.S31.nonroot-permission-probes-applicable|APPLICABILITY|direct-inspection"
    "S31|error-handling.S31.attach-to-an-unreadable-conf-dir-exits-1|BEHAVIOR|real-path"
    "S31|error-handling.S31.attach-names-the-access-barrier-for-an-unreadable-conf-dir|BEHAVIOR|real-path"
    "S31|error-handling.S31.attach-does-not-misreport-an-unreadable-conf-dir-as-not-found|BEHAVIOR|real-path"
    "S32|error-handling.S32.nonroot-permission-probes-applicable|APPLICABILITY|direct-inspection"
    "S32|error-handling.S32.local-install-into-a-non-writable-conf-dir-exits-1|BEHAVIOR|real-path"
    "S32|error-handling.S32.local-install-names-the-non-writable-conf-dir-branch-reached|BEHAVIOR|real-path"
    "S32|error-handling.S32.local-install-drops-the-ioc-group-question|BEHAVIOR|real-path"
    "S35|error-handling.S35.valid-crash-log-patterns-extra-accepted-at-install|BEHAVIOR|real-path"
    "S35|error-handling.S35.illegal-characters-in-crash-log-patterns-extra-rejected-at-install|BEHAVIOR|real-path"
    "S35|error-handling.S35.invalid-regex-in-crash-log-patterns-extra-rejected-at-install|BEHAVIOR|real-path"
    "S35|error-handling.S35.extra.dot-rejected|BEHAVIOR|real-path"
    "S35|error-handling.S35.extra.internal-empty-alternation-rejected|BEHAVIOR|real-path"
    "S35|error-handling.S35.extra.leading-empty-alternation-rejected|BEHAVIOR|real-path"
    "S35|error-handling.S35.extra.trailing-empty-alternation-rejected|BEHAVIOR|real-path"
    "S35|error-handling.S35.extra.grouped-leading-empty-alternation-rejected|BEHAVIOR|real-path"
    "S35|error-handling.S35.extra.grouped-trailing-empty-alternation-rejected|BEHAVIOR|real-path"
    "S35|error-handling.S35.extra.ordinary-lowercase-rejected|BEHAVIOR|real-path"
    "S35|error-handling.S35.extra.ordinary-uppercase-rejected|BEHAVIOR|real-path"
    "S35|error-handling.S35.legitimate-multi-alternation-extra-accepted-at-install-106|BEHAVIOR|real-path"
    "S36|error-handling.S36.non-executable-ioc-runner-procserv-tool-exits-1|BEHAVIOR|real-path"
    "S36|error-handling.S36.non-executable-override-error-names-the-variable|BEHAVIOR|real-path"
    "S36|error-handling.S36.executable-directory-ioc-runner-procserv-tool-exits-1|BEHAVIOR|real-path"
    "S36|error-handling.S36.executable-directory-override-error-names-the-variable|BEHAVIOR|real-path"
    "S36|error-handling.S36.executable-ioc-runner-procserv-tool-accepted|BEHAVIOR|real-path"
    "S36|error-handling.S36.template-execstart-references-the-override-binary|BEHAVIOR|real-path"
    "S36|error-handling.S36.home-bin-procserv-resolves-without-an-override|BEHAVIOR|real-path"
    "S36|error-handling.S36.template-execstart-references-the-home-bin-binary|BEHAVIOR|real-path"
    "S36|error-handling.S36.con-search-path-prepends-home-bin-when-home-is-trusted|BEHAVIOR|real-path"
    "S37|error-handling.S37.install-proceeds-with-logrotate-boundary|BEHAVIOR|real-path"
    "S37|error-handling.S37.rotation-cfg-deployed|BEHAVIOR|real-path"
    "S37|error-handling.S37.debug-validation-passes-explicit-state|BEHAVIOR|real-path"
    "S37|error-handling.S37.state-off-system-default|BEHAVIOR|real-path"
)
declare -g -A ERROR_STEP_CHECK_IDS=()

# shellcheck source=lib/test-reporting.bash
source "${SC_TOP}/lib/test-reporting.bash"

# --- Interrupt & Exit Handling ---
function _handle_exit {
    local exit_code=$?
    local final_status="${exit_code}"

    trap - EXIT
    set +e
    if ! _cleanup; then
        final_status=1
        _log "ERROR" "Failed to remove the error-handling workspace."
    fi
    if (( REPORT_READY )); then
        report_finalize "${final_status}" || final_status=1
    fi
    exit "${final_status}"
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

    printf "%b[%-7s] %s%b\n" "${color}" "${level}" "${message}" "${NC}"
}

function print_divider {
    printf "%b%s%b\n" "${BLUE}" "====================================================================================================" "${NC}"
}

function print_sub_divider {
    printf "%b%s%b\n" "${BLUE}" "----------------------------------------------------------------------------------------------------" "${NC}"
}

function initialize_reporting {
    local row=""
    local step_id=""
    local check_id=""
    local check_kind=""
    local test_method=""
    local description=""
    local arch_id=""
    local run_id="${SUITE_ID}.$$.${BASHPID}"
    local index=0
    local -a step_ids=(P00)

    for ((index = 1; index <= 37; index += 1)); do
        printf -v step_id 'S%02d' "${index}"
        step_ids+=("${step_id}")
    done
    arch_id=$(uname -m)
    REPORT_DIR=$(mktemp -d /tmp/ioc-runner-error-report.XXXXXX)
    report_init "${SUITE_ID}" "${run_id}" "${SUITE_SCOPE}" "${SUITE_RUNNER}" \
        host "${arch_id}" "${REPORT_DIR}"
    REPORT_READY=1
    for step_id in "${step_ids[@]}"; do
        report_register_step "${step_id}" "Error handling ${step_id}"
    done
    for row in "${ERROR_CATALOG_ROWS[@]}"; do
        IFS='|' read -r step_id check_id check_kind test_method <<< "${row}"
        description="${check_id#${SUITE_ID}.${step_id}.}"
        report_register_check "${check_id}" "${step_id}" "${SUITE_CATEGORY}" \
            "${check_kind}" "${test_method}" "${description}"
        if [[ -n "${ERROR_STEP_CHECK_IDS[${step_id}]:-}" ]]; then
            ERROR_STEP_CHECK_IDS["${step_id}"]+=" ${check_id}"
        else
            ERROR_STEP_CHECK_IDS["${step_id}"]="${check_id}"
        fi
    done
    report_close_catalog
}

function next_current_check_id {
    local result_name="$1"
    local check_list="${ERROR_STEP_CHECK_IDS[${CURRENT_STEP_ID}]:-}"
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
    local check_list="${ERROR_STEP_CHECK_IDS[${CURRENT_STEP_ID}]:-}"
    local check_id=""
    local -a check_ids=()

    read -r -a check_ids <<< "${check_list}"
    while (( CURRENT_STEP_CHECK_INDEX < ${#check_ids[@]} )); do
        check_id="${check_ids[${CURRENT_STEP_CHECK_INDEX}]}"
        CURRENT_STEP_CHECK_INDEX=$((CURRENT_STEP_CHECK_INDEX + 1))
        report_record "${check_id}" "${state}" "${reason}"
    done
}

function close_error_catalog_after_preflight {
    local row=""
    local step_id=""
    local check_id=""
    local check_kind=""
    local test_method=""

    for row in "${ERROR_CATALOG_ROWS[@]:1}"; do
        IFS='|' read -r step_id check_id check_kind test_method <<< "${row}"
        report_record "${check_id}" SKIP "requires ${SUITE_ID}.P00.runner-source-readable"
    done
}

function run_preflight {
    local runner_source_readable="false"

    CURRENT_STEP_ID=P00
    CURRENT_STEP_CHECK_INDEX=0
    [[ -r "${RUNNER_SCRIPT}" ]] && runner_source_readable="true"
    verify_state true "${runner_source_readable}" "Runner source is readable"
    if [[ "${runner_source_readable}" != "true" ]]; then
        close_error_catalog_after_preflight
        return 1
    fi
}

function verify_state {
    local expected="$1"
    local actual="$2"
    local step_name="$3"
    local reason=""

    if [[ "${expected}" == "${actual}" ]]; then
        printf "%b[ PASS ]%b %s\n" "${GREEN}" "${NC}" "${step_name}"
        record_current_state PASS
    else
        printf "%b[ FAIL ]%b %s\n" "${RED}" "${NC}" "${step_name}" >&2
        printf "  %bExpected : %s%b\n" "${YELLOW}" "${expected}" "${NC}" >&2
        printf "  %bActual   : %s%b\n" "${YELLOW}" "${actual}" "${NC}" >&2
        reason="${step_name}: expected ${expected}, actual ${actual}"
        record_current_state FAIL "${reason}"
    fi
}

function verify_exit_code {
    local expected_exit="$1"
    local actual_exit="$2"
    local step_name="$3"
    local reason=""

    if [[ "${expected_exit}" == "${actual_exit}" ]]; then
        printf "%b[ PASS ]%b %s\n" "${GREEN}" "${NC}" "${step_name}"
        record_current_state PASS
    else
        printf "%b[ FAIL ]%b %s\n" "${RED}" "${NC}" "${step_name}" >&2
        printf "  %bExpected exit : %s%b\n" "${YELLOW}" "${expected_exit}" "${NC}" >&2
        printf "  %bActual exit   : %s%b\n" "${YELLOW}" "${actual_exit}" "${NC}" >&2
        reason="${step_name}: expected exit ${expected_exit}, actual exit ${actual_exit}"
        record_current_state FAIL "${reason}"
    fi
}

function _run {
    local cmd=("$@")
    local exit_code=0

    "${cmd[@]}" >/dev/null 2>&1 || exit_code=$?
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

    TEST_TMPDIR=$(mktemp -d /tmp/ioc-runner-error-handling.XXXXXX)

    # Isolate local-mode CONF / SYSTEMD / RUN / LOG directories under
    # TEST_TMPDIR so a direct or sudo-elevated run cannot corrupt the
    # user's ~/.config or ~/.local/state. Per-case unified env vars
    # (IOC_RUNNER_{CONF,SYSTEMD,RUN,LOG}_DIR) take precedence over these
    # namespaced defaults per ioc-runner's resolution order. (#70)
    export IOC_RUNNER_LOCAL_CONF_DIR="${TEST_TMPDIR}/local-config/procServ.d"
    export IOC_RUNNER_LOCAL_SYSTEMD_DIR="${TEST_TMPDIR}/local-config/systemd/user"
    export IOC_RUNNER_LOCAL_RUN_DIR="${TEST_TMPDIR}/local-run/procserv"
    export IOC_RUNNER_LOCAL_LOG_DIR="${TEST_TMPDIR}/local-state/procserv"

    # Create a mock con binary that exits successfully without doing anything.
    MOCK_CON_BIN="${TEST_TMPDIR}/con"
    printf "#!/usr/bin/env bash\nexit 0\n" > "${MOCK_CON_BIN}"
    chmod +x "${MOCK_CON_BIN}"

    export IOC_RUNNER_CON_TOOL="${MOCK_CON_BIN}"

    # Create a mock procServ binary so the install path (deploy_local_template ->
    # resolve_procserv_tool) resolves it instead of searching the host. The
    # install cases only bake this path into the unit template; they never exec
    # it, so a plain exit-0 stub is sufficient. This makes the suite truly
    # host-independent (#77). test_tool_resolution's home-bin search case unsets
    # this override (env -u) to exercise the real search path.
    MOCK_PROCSERV_BIN="${TEST_TMPDIR}/procServ"
    printf "#!/usr/bin/env bash\nexit 0\n" > "${MOCK_PROCSERV_BIN}"
    chmod +x "${MOCK_PROCSERV_BIN}"

    export IOC_RUNNER_PROCSERV_TOOL="${MOCK_PROCSERV_BIN}"

    _log "SUCCESS" "Mock environment ready at ${TEST_TMPDIR}"
}

function _cleanup {
    if [[ -z "${TEST_TMPDIR}" ]]; then
        return 0
    fi
    if [[ "${TEST_TMPDIR}" != /tmp/ioc-runner-error-handling.* ||
          ! -d "${TEST_TMPDIR}" || -L "${TEST_TMPDIR}" ]]; then
        return 1
    fi
    "${REPORT_RM_BIN:-/bin/rm}" -rf -- "${TEST_TMPDIR}"
    TEST_TMPDIR=""
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
    # Issue #98: the cd stays scoped inside the command substitution (its own
    # subshell); the assertion runs in the parent shell so the counters hold.
    exit_code=$(cd "${test_dir}" && _run bash "${RUNNER_SCRIPT}" --local generate .)
    verify_exit_code "0" "${exit_code}" "Generate native dot path resolves successfully"

    local conf_exists="false"
    if [[ -f "${conf_file}" ]]; then conf_exists="true"; fi
    verify_state "true" "${conf_exists}" "Configuration artifact created dynamically"

    # Evaluates the internal cmp -s integration bypassing identical configuration files.
    exit_code=$(cd "${test_dir}" && _run bash "${RUNNER_SCRIPT}" --local generate .)
    verify_exit_code "0" "${exit_code}" "Identical artifact natively bypasses overwrite and exits 0"

    # Issue #123: the identical-skip must still reassert the conf mode, or a
    # hand-loosened permission survives the re-generate. Loosen to a different
    # mode, re-generate identical content, and confirm both that the skip path
    # actually ran (the "Identical" marker guards against a vacuous green from
    # the write path) and that the mode is restored to the local-mode 0600.
    chmod 0666 "${conf_file}"
    local identical_out skip_ran="false"
    identical_out=$(cd "${test_dir}" && bash "${RUNNER_SCRIPT}" --local generate . 2>&1)
    if printf "%s" "${identical_out}" | grep -q "already up-to-date (Identical)"; then skip_ran="true"; fi
    verify_state "true" "${skip_ran}" "Identical re-generate takes the skip path"
    verify_state "600" "$(stat -c %a "${conf_file}")" "Identical-skip reasserts conf mode 0600 (#123)"

    # Evaluates the ANSI diff engine and interactive prompt behavior using a mocked non-interactive shell.
    printf "\n# Modified\n" >> "${conf_file}"
    exit_code=$(cd "${test_dir}" && _run bash -c "bash \"${RUNNER_SCRIPT}\" --local generate . < /dev/null")
    verify_exit_code "1" "${exit_code}" "Differential artifact prompt exits 1 on EOF"

    # Issue #93: a user decline (n) is an abort like EOF; both exit nonzero
    # so a scripted caller cannot mistake a declined overwrite for success.
    exit_code=$(cd "${test_dir}" && _run bash -c "printf 'n\n' | bash \"${RUNNER_SCRIPT}\" --local generate .")
    verify_exit_code "1" "${exit_code}" "Differential artifact prompt exits 1 on user decline"

    # Evaluates the forced overwrite bypass mechanism for automation pipelines.
    exit_code=$(cd "${test_dir}" && _run bash "${RUNNER_SCRIPT}" --local -f generate .)
    verify_exit_code "0" "${exit_code}" "Forced overwrite ignores diff constraint and exits 0"
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

    # #107: the abort path must leave no staged .name.conf.XXXXXX file
    # behind in the target directory (EXIT-trap regression tripwire).
    local leftover="false"
    compgen -G "${overwrite_dir}/.*.conf.*" >/dev/null 2>&1 && leftover="true"
    verify_state "false" "${leftover}" "Generate abort leaves no staged tmp in the target dir (#107)"

    # #107: generate stages in the TARGET directory — a poisoned TMPDIR
    # must not matter (the old /tmp staging failed here at mktemp).
    local tp_dir="${TEST_TMPDIR}/tmpdir_poison_ioc"
    mkdir -p "${tp_dir}"; touch "${tp_dir}/st.cmd"; chmod +x "${tp_dir}/st.cmd"
    exit_code=$(TMPDIR=/nonexistent-m4 _run bash -c "cd \"${tp_dir}\" && bash \"${RUNNER_SCRIPT}\" --local -f generate .")
    verify_exit_code "0" "${exit_code}" "Generate succeeds with a poisoned TMPDIR (#107 same-dir staging)"

    # #107: explicit perms on the generated conf.
    local gen_mode
    gen_mode=$(stat -c %a "${tp_dir}/tmpdir_poison_ioc.conf" 2>/dev/null || printf "missing")
    verify_state "600" "${gen_mode}" "Local generate writes the conf 0600 (#107)"
    rm -f "${tp_dir}/tmpdir_poison_ioc.conf"
    exit_code=$(TMPDIR=/nonexistent-m4 _run bash -c "cd \"${tp_dir}\" && bash \"${RUNNER_SCRIPT}\" -f generate .")
    verify_exit_code "0" "${exit_code}" "System-mode generate succeeds with a poisoned TMPDIR (#107)"
    gen_mode=$(stat -c %a "${tp_dir}/tmpdir_poison_ioc.conf" 2>/dev/null || printf "missing")
    verify_state "660" "${gen_mode}" "System-mode generate writes the conf 0660 (#107)"
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
    exit_code=$(cd "${test_dir}" && IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" _run bash "${RUNNER_SCRIPT}" --local -f install .)
    verify_exit_code "0" "${exit_code}" "Directory-based installation resolves artifact correctly"

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

    exit_code=$(cd "${test_dir}" && IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
        _run bash -c "bash \"${RUNNER_SCRIPT}\" --local install . < /dev/null")
    verify_exit_code "1" "${exit_code}" "Install overwrite prompt exits 1 on EOF"

    local preserved="false"
    if [[ -f "${installed_conf}" ]] && grep -qF "${eof_marker}" "${installed_conf}" 2>/dev/null; then
        preserved="true"
    fi
    verify_state "true" "${preserved}" "Install EOF abort preserves existing conf (marker retained)"

    # Issue #93: user decline (n) on the install overwrite prompt exits 1
    # and preserves the existing conf, matching the EOF abort convention.
    exit_code=$(cd "${test_dir}" && IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
        _run bash -c "printf 'n\n' | bash \"${RUNNER_SCRIPT}\" --local install .")
    verify_exit_code "1" "${exit_code}" "Install overwrite prompt exits 1 on user decline"

    local declined_preserved="false"
    if [[ -f "${installed_conf}" ]] && grep -qF "${eof_marker}" "${installed_conf}" 2>/dev/null; then
        declined_preserved="true"
    fi
    verify_state "true" "${declined_preserved}" "Install decline abort preserves existing conf (marker retained)"
}

# T3 (Phase E): IOC_PORT atomic install. The write path in do_install
# (mktemp + mv -f) must leave the target conf valid-or-untouched under any
# interruption -- a partially written conf must never be observable.
function test_ioc_port_atomic_install {
    local step="$1"
    local test_dir="${TEST_TMPDIR}/atomic_ioc"
    local mock_conf_dir="${TEST_TMPDIR}/atomic_etc"
    local mock_sysd_dir="${TEST_TMPDIR}/atomic_sysd"
    local target_conf="${mock_conf_dir}/atomic_ioc.conf"

    print_divider
    _log "INFO" "STEP ${step}: IOC_PORT Atomic Install (T3)"
    print_sub_divider

    mkdir -p "${test_dir}" "${mock_conf_dir}" "${mock_sysd_dir}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    # Pre-generate the source conf the install loop consumes.
    ( cd "${test_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1 )

    # Hammer install under a tight timeout that interrupts at varied points.
    local iterations=120
    local i rc port_count partial_writes=0 unexpected_exit=0
    for ((i = 1; i <= iterations; i = i + 1)); do
        if (
            cd "${test_dir}" || exit 1
            IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
            timeout 0.01 bash "${RUNNER_SCRIPT}" --local -f install . >/dev/null 2>&1
        ); then
            rc=0
        else
            rc=$?
        fi
        # timeout completion (0) and timeout kill (124) are both expected.
        if [[ "${rc}" -ne 0 && "${rc}" -ne 124 ]]; then
            unexpected_exit=$((unexpected_exit + 1))
        fi
        # When present, the target must hold exactly one valid IOC_PORT= line.
        if [[ -f "${target_conf}" ]]; then
            port_count=$(grep -c '^IOC_PORT=' "${target_conf}" 2>/dev/null) || true
            if [[ "${port_count:-0}" -ne 1 ]] \
               || ! grep -qE '^IOC_PORT="unix:[^:]+:[^:]+:0660:.*/atomic_ioc/control"$' "${target_conf}" 2>/dev/null; then
                partial_writes=$((partial_writes + 1))
            fi
        fi
    done

    verify_state "0" "${partial_writes}" "Atomic install: no partial conf across ${iterations} interrupted installs"
    verify_state "0" "${unexpected_exit}" "Atomic install: install exits only 0 or 124 under interruption"
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

    # Regression guard: IOC name validation must also apply when a .conf
    # file is supplied directly (not via its parent directory). Without
    # the convergence-point check, names like 'myioc@' would propagate
    # into systemd unit names where '@' is reserved.
    local invalid_named_conf="${TEST_TMPDIR}/myioc@.conf"
    touch "${invalid_named_conf}"
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local install "${invalid_named_conf}")
    verify_exit_code "1" "${exit_code}" "Install file-direct with invalid IOC name exits 1"
}


# #105 U-5: ss feeds only the -vv columns. Plain list must succeed
# without a working ss; list -vv must fail loudly with a named error.
# find is replaced by a PATH stub that emits one fake socket entry so
# the collection path is actually reached; ss is stubbed to exit 1.
function test_list_ss_vv_contract {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: list ss Contract (-vv only, #105)"
    print_sub_divider

    local mock_bin="${TEST_TMPDIR}/ss_fail_bin"
    local mock_run="${TEST_TMPDIR}/ss_fail_run"
    local fake_sock="${mock_run}/test_ioc/control"

    mkdir -p "${mock_bin}" "${mock_run}/test_ioc"

    cat > "${mock_bin}/find" <<STUB
#!/usr/bin/env bash
printf '%s\0%s\0%s\0' "${fake_sock}" "2024-01-01 12:00" "srwxrwxr-x"
STUB
    chmod +x "${mock_bin}/find"

    printf '#!/usr/bin/env bash\nexit 1\n' > "${mock_bin}/ss"
    chmod +x "${mock_bin}/ss"

    local exit_code
    exit_code=$(PATH="${mock_bin}:${PATH}" \
        IOC_RUNNER_LOCAL_RUN_DIR="${mock_run}" \
        _run bash "${RUNNER_SCRIPT}" --local list)
    verify_exit_code "0" "${exit_code}" "plain list succeeds with broken ss (no -vv dependency)"

    exit_code=$(PATH="${mock_bin}:${PATH}" \
        IOC_RUNNER_LOCAL_RUN_DIR="${mock_run}" \
        _run bash "${RUNNER_SCRIPT}" --local -vv list)
    verify_exit_code "1" "${exit_code}" "list -vv with broken ss exits 1"

    local out match_rc=1
    out=$(PATH="${mock_bin}:${PATH}" IOC_RUNNER_LOCAL_RUN_DIR="${mock_run}" \
        bash "${RUNNER_SCRIPT}" --local -vv list 2>&1 || true)
    if [[ "${out}" == *"ss -lx"* ]]; then match_rc=0; fi
    verify_exit_code "0" "${match_rc}" "list -vv failure names ss in the error"
}

# #105 U-4: mutation verbs on a never-installed name are a hard error
# with the gate message, not systemd template-instantiation exit 0;
# view exits nonzero on a missing conf (U-5).
function test_unknown_name_verb_gate {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Unknown-Name Verb Gate (#105)"
    print_sub_divider

    local verb exit_code
    for verb in stop enable disable remove view; do
        exit_code=$(_run bash "${RUNNER_SCRIPT}" --local "${verb}" no_such_ioc_105)
        verify_exit_code "1" "${exit_code}" "${verb} on a never-installed name exits 1"
    done

    local out match_rc=1
    out=$(bash "${RUNNER_SCRIPT}" --local stop no_such_ioc_105 2>&1 || true)
    if [[ "${out}" == *"No configuration found"* ]]; then match_rc=0; fi
    verify_exit_code "0" "${match_rc}" "gate message names the missing configuration"
}

# #105: local mode replaces a mismatching conf IOC_PORT with the
# standard socket path — now with exactly one Warning.
function test_local_ioc_port_replacement_warns {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Local IOC_PORT Replacement Warning (#105)"
    print_sub_divider

    local wdir="${TEST_TMPDIR}/warn105"
    mkdir -p "${wdir}"
    cat > "${wdir}/warnioc.conf" <<CONF
IOC_NAME="warnioc"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CMD="/bin/echo"
IOC_CHDIR="${wdir}"
IOC_PORT="unix:someone:somegroup:0660:/definitely/not/standard"
CONF

    local out count
    out=$(IOC_RUNNER_PROCSERV_TOOL=/bin/true \
        bash "${RUNNER_SCRIPT}" --local install "${wdir}/warnioc.conf" -f 2>&1 >/dev/null || true)
    count=$(grep -c "Warning: IOC_PORT" <<< "${out}" || true)
    verify_exit_code "1" "${count}" "exactly one IOC_PORT replacement warning"
}

# Preserves the stable error-contract STEP sequence when this position owns no
# rejection or safe-failure check.
function no_error_contract_checks {
    :
}

# Validates the system-mode foot-gun warning for IOC_RUNNER_LOG_DIR:
# warning fires when IOC_RUNNER_LOG_DIR diverges from SYSTEM_LOG_DIR in
# system mode; suppressed when they match; suppressed in --local mode.
function test_log_dir_guard {
    local step="$1"
    local stderr_cap
    stderr_cap=$(mktemp)
    local has_warn

    print_divider
    _log "INFO" "STEP ${step}: LOG_DIR Foot-Gun Guard"
    print_sub_divider

    # Case 1: system mode + IOC_RUNNER_LOG_DIR differs from default SYSTEM_LOG_DIR.
    IOC_RUNNER_LOG_DIR=/tmp/log_dir_guard_test_diff \
        bash "${RUNNER_SCRIPT}" status fake-ioc >/dev/null 2>"${stderr_cap}" || true
    has_warn="false"
    grep -q 'IOC_RUNNER_LOG_DIR.*differs from SYSTEM_LOG_DIR' "${stderr_cap}" && has_warn="true"
    verify_state "true" "${has_warn}" "system + differing IOC_RUNNER_LOG_DIR triggers warning"

    # Case 2: system mode + IOC_RUNNER_LOG_DIR matches overridden SYSTEM_LOG_DIR.
    IOC_RUNNER_SYSTEM_LOG_DIR=/tmp/log_dir_guard_test_match \
    IOC_RUNNER_LOG_DIR=/tmp/log_dir_guard_test_match \
        bash "${RUNNER_SCRIPT}" status fake-ioc >/dev/null 2>"${stderr_cap}" || true
    has_warn="false"
    grep -q 'IOC_RUNNER_LOG_DIR.*differs from SYSTEM_LOG_DIR' "${stderr_cap}" && has_warn="true"
    verify_state "false" "${has_warn}" "system + matching IOC_RUNNER_LOG_DIR suppresses warning"

    # Case 3: --local mode + IOC_RUNNER_LOG_DIR set to non-default.
    IOC_RUNNER_LOG_DIR=/tmp/log_dir_guard_test_local \
        bash "${RUNNER_SCRIPT}" --local status fake-ioc >/dev/null 2>"${stderr_cap}" || true
    has_warn="false"
    grep -q 'IOC_RUNNER_LOG_DIR.*differs from SYSTEM_LOG_DIR' "${stderr_cap}" && has_warn="true"
    verify_state "false" "${has_warn}" "--local mode suppresses LOG_DIR guard"

    rm -f "${stderr_cap}"
}

# Validates the bash completion script by sourcing it in isolated subshells
# and invoking _ioc_runner_completions with synthesized COMP_WORDS/COMP_CWORD.
# Targets the env-var refactor to ensure completion picks up namespaced vars.
function test_completion {
    local step="$1"
    local comp_script="${SC_TOP}/../bin/ioc-runner-completion.bash"
    local completion_available="false"

    print_divider
    _log "INFO" "STEP ${step}: Bash Completion Smoke Tests"
    print_sub_divider

    [[ -f "${comp_script}" ]] && completion_available="true"
    verify_state "true" "${completion_available}" "Completion script is available"
    if [[ "${completion_available}" != "true" ]]; then
        _log "ERROR" "Completion script not found at ${comp_script}"
        close_current_remaining SKIP \
            "requires ${SUITE_ID}.S23.completion-script-available"
        return 0
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


function test_ioc_name_validation {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: IOC Name Validation Helper"
    print_sub_divider

    # Site 1 (early validation): non-generate/non-install commands route
    # the regex via 'view'. Names with characters outside [a-zA-Z0-9_-]
    # must be rejected before the dispatcher reaches do_view.
    local exit_code
    exit_code=$(_run bash "${RUNNER_SCRIPT}" view 'bad name')
    verify_exit_code "1" "${exit_code}" "view 'bad name' (whitespace) exits 1 via name validation"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" view 'bad@name')
    verify_exit_code "1" "${exit_code}" "view 'bad@name' (special char) exits 1 via name validation"

    # Path-separator inputs cannot reach the regex: 'basename' strips the
    # path before the regex check. Use period instead, which survives
    # basename and is rejected by [a-zA-Z0-9_-].
    exit_code=$(_run bash "${RUNNER_SCRIPT}" view 'bad.name')
    verify_exit_code "1" "${exit_code}" "view 'bad.name' (period) exits 1 via name validation"

    # Verify the error message format remains 'Invalid IOC name ...' so
    # log scrapers and regression observers can rely on the contract.
    local err_out
    # Suffix '|| true' so that the validation rejection (exit 1) does not
    # propagate through command substitution and trip 'set -e' in this
    # test driver.
    err_out=$(bash "${RUNNER_SCRIPT}" view 'bad@name' 2>&1 >/dev/null || true)
    local has_phrase="false"
    if [[ "${err_out}" == *"Invalid IOC name"* ]]; then has_phrase="true"; fi
    verify_state "true" "${has_phrase}" "view 'bad@name' produces 'Invalid IOC name' error message"
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

    # 5. Reject a '..' path component in IOC_CHDIR (system-mode precheck, #66).
    #    Driven in system mode (no --local) so the chdir precheck fires. The
    #    check is pure string work that exits before any privileged copy, so it
    #    needs neither the ioc-srv account nor sudo: validate_conf compares the
    #    IOC_USER/IOC_GROUP strings only, and the '..' path resolves to an
    #    existing directory so validate_conf's earlier -d test passes. The -f
    #    flag also confirms force does not bypass the rejection.
    cat <<EOF > "${bad_conf}"
IOC_NAME="test"
IOC_USER="ioc-srv"
IOC_GROUP="ioc"
IOC_CHDIR="${dummy_dir}/../dummy_ioc"
IOC_CMD="true"
EOF
    local dotdot_stderr="${TEST_TMPDIR}/dotdot_stderr"
    local dotdot_ec=0
    bash "${RUNNER_SCRIPT}" -f install "${bad_conf}" >/dev/null 2>"${dotdot_stderr}" || dotdot_ec=$?
    verify_exit_code "1" "${dotdot_ec}" "Install with '..' in system IOC_CHDIR exits 1"

    local has_dotdot_msg="false"
    grep -q "contains a '..' component" "${dotdot_stderr}" 2>/dev/null && has_dotdot_msg="true"
    verify_state "true" "${has_dotdot_msg}" "'..' rejection error references the '..' component"

    # 5b. Boundary form: IOC_CHDIR exactly '..'. Since M6/#109 the absolute-path
    #     check in validate_conf rejects it FIRST (a bare '..' is relative); the
    #     whole-string/leading '..' globs at the system precheck remain as
    #     defense-in-depth behind this shield.
    cat <<EOF > "${bad_conf}"
IOC_NAME="test"
IOC_USER="ioc-srv"
IOC_GROUP="ioc"
IOC_CHDIR=".."
IOC_CMD="true"
EOF
    local bare_stderr="${TEST_TMPDIR}/bare_dotdot_stderr"
    local bare_ec=0
    bash "${RUNNER_SCRIPT}" -f install "${bad_conf}" >/dev/null 2>"${bare_stderr}" || bare_ec=$?
    verify_exit_code "1" "${bare_ec}" "Install with bare '..' IOC_CHDIR exits 1"

    local has_bare_msg="false"
    grep -q "IOC_CHDIR must be an absolute path" "${bare_stderr}" 2>/dev/null && has_bare_msg="true"
    verify_state "true" "${has_bare_msg}" "bare '..' rejected by the absolute-path requirement (M6/#109)"

    # 6. Relative IOC_CHDIR is a validation error in any mode (M6/#109).
    cat <<EOF > "${bad_conf}"
IOC_NAME="test"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="relative/boot/dir"
IOC_CMD="true"
EOF
    local relchdir_stderr="${TEST_TMPDIR}/relchdir_stderr"
    local relchdir_ec=0
    bash "${RUNNER_SCRIPT}" --local -f install "${bad_conf}" >/dev/null 2>"${relchdir_stderr}" || relchdir_ec=$?
    verify_exit_code "1" "${relchdir_ec}" "Install with relative IOC_CHDIR exits 1"

    local has_relchdir_msg="false"
    grep -q "IOC_CHDIR must be an absolute path" "${relchdir_stderr}" 2>/dev/null && has_relchdir_msg="true"
    verify_state "true" "${has_relchdir_msg}" "relative IOC_CHDIR error names the absolute-path requirement"

    # 7. Multi-word IOC_CMD violates the U-3 single-word contract (M6/#109).
    #    Chosen value has no illegal characters so it pins the H3 check alone.
    cat <<EOF > "${bad_conf}"
IOC_NAME="test"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${dummy_dir}"
IOC_CMD="softIoc -d test.db"
EOF
    local mwcmd_stderr="${TEST_TMPDIR}/mwcmd_stderr"
    local mwcmd_ec=0
    bash "${RUNNER_SCRIPT}" --local -f install "${bad_conf}" >/dev/null 2>"${mwcmd_stderr}" || mwcmd_ec=$?
    verify_exit_code "1" "${mwcmd_ec}" "Install with multi-word IOC_CMD exits 1"

    local has_mwcmd_msg="false"
    grep -q "IOC_CMD must be a single word" "${mwcmd_stderr}" 2>/dev/null && has_mwcmd_msg="true"
    verify_state "true" "${has_mwcmd_msg}" "multi-word IOC_CMD error names the single-word contract"
}

function test_attach_errors {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Attach Error Paths"
    print_sub_divider

    local exit_code

    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local attach "nonexistent_ioc")
    verify_exit_code "1" "${exit_code}" "'attach' with missing conf exits 1"

    # Regression guard: a conf file with no IOC_PORT key should yield a
    # distinct 'not configured' error rather than the generic socket-file
    # error, exercising read_conf_var's missing-vs-empty signal.
    local missing_port_dir="${TEST_TMPDIR}/missing_port_conf"
    mkdir -p "${missing_port_dir}"
    printf "IOC_NAME=missing_port\nIOC_USER=%s\n" "$(id -un)" > "${missing_port_dir}/missing_port.conf"

    local stderr_cap="${TEST_TMPDIR}/missing_port_stderr"
    local ec=0
    IOC_RUNNER_LOCAL_CONF_DIR="${missing_port_dir}" \
        bash "${RUNNER_SCRIPT}" --local attach "missing_port" >/dev/null 2>"${stderr_cap}" \
        || ec=$?
    verify_exit_code "1" "${ec}" "'attach' with missing IOC_PORT key exits 1"

    local has_port_msg="false"
    grep -q "IOC_PORT not configured" "${stderr_cap}" 2>/dev/null && has_port_msg="true"
    verify_state "true" "${has_port_msg}" "'attach' error references missing IOC_PORT key"
}

function test_list_empty {
    local step="$1"
    local applicability_reason="requires a non-root effective user"
    print_divider
    _log "INFO" "STEP ${step}: List with No Active Sockets"
    print_sub_divider

    local exit_code

    if [[ ${EUID} -eq 0 ]]; then
        record_current_state NA "${applicability_reason}"
    else
        record_current_state PASS
    fi

    exit_code=$(IOC_RUNNER_RUN_DIR="${TEST_TMPDIR}/empty_run" _run bash "${RUNNER_SCRIPT}" --local list)
    verify_exit_code "0" "${exit_code}" "'list' with no active sockets exits 0"

    # Issue #94: an empty result caused by non-traversable (0770-style)
    # socket directories carries a permission hint; a genuinely empty run
    # dir does not. chmod 0 cannot deny root, so the hint case is skipped
    # under EUID 0.
    local output
    local genuine_run="${TEST_TMPDIR}/genuine_empty_run"
    mkdir -p "${genuine_run}"
    output=$(IOC_RUNNER_RUN_DIR="${genuine_run}" bash "${RUNNER_SCRIPT}" --local list 2>&1)
    local hint_absent="true"
    if printf "%s" "${output}" | grep -q "not readable by this user"; then
        hint_absent="false"
    fi
    verify_state "true" "${hint_absent}" "Genuinely empty list carries no permission hint"

    if [[ ${EUID} -eq 0 ]]; then
        _log "WARN" "Running as root: skipping the non-traversable hint case (chmod 0 cannot deny root)."
        close_current_remaining NA "${applicability_reason}"
    else
        local denied_run="${TEST_TMPDIR}/denied_run"
        local denied_exit=0
        local hint_present="false"
        mkdir -p "${denied_run}/secret_ioc"
        chmod 0 "${denied_run}/secret_ioc"
        output=$(IOC_RUNNER_RUN_DIR="${denied_run}" bash "${RUNNER_SCRIPT}" --local list 2>&1) || denied_exit=$?
        if printf "%s" "${output}" | grep -q "not readable by this user"; then
            hint_present="true"
        fi
        verify_exit_code "0" "${denied_exit}" "'list' with a non-traversable socket dir exits 0"
        verify_state "true" "${hint_present}" "Non-traversable socket dir appends the permission hint"
        chmod 700 "${denied_run}/secret_ioc"
    fi
}


function test_inspect_errors {
    local step="$1"
    local applicability_reason="requires a non-root effective user"
    print_divider
    _log "INFO" "STEP ${step}: Inspect Error Paths"
    print_sub_divider

    if [[ ${EUID} -eq 0 ]]; then
        _log "WARN" "Running as root: skipping the non-root inspect privilege case."
        close_current_remaining NA "${applicability_reason}"
        return 0
    fi

    local exit_code

    exit_code=$(_run bash "${RUNNER_SCRIPT}" inspect "dummy_ioc")
    verify_exit_code "1" "${exit_code}" "'inspect' without root privileges exits 1"
}


# Validates the install-time CRASH_LOG_PATTERNS_EXTRA contract from #25:
# valid extras are accepted, illegal characters and invalid regex syntax
# are rejected before the conf reaches the runtime grep call.
function test_crash_pattern_extra {
    local step="$1"
    local exit_code
    local test_dir="${TEST_TMPDIR}/extra_pattern_ioc"
    local mock_conf_dir="${TEST_TMPDIR}/extra_pattern_etc"
    local mock_sysd_dir="${TEST_TMPDIR}/extra_pattern_sysd"
    local conf_file="${test_dir}/extra_pattern_ioc.conf"

    print_divider
    _log "INFO" "STEP ${step}: CRASH_LOG_PATTERNS_EXTRA Validation"
    print_sub_divider

    mkdir -p "${test_dir}" "${mock_conf_dir}" "${mock_sysd_dir}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    local base_conf
    base_conf=$(printf "IOC_USER=%s\nIOC_GROUP=%s\nIOC_CHDIR=%s\nIOC_CMD=./st.cmd\n" \
        "$(id -un)" "$(id -gn)" "${test_dir}")

    printf "%s\nCRASH_LOG_PATTERNS_EXTRA=\"Bergoz link lost|NPCT overrange\"\n" "${base_conf}" > "${conf_file}"
    exit_code=$(IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
        _run bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}")
    verify_exit_code "0" "${exit_code}" "Valid CRASH_LOG_PATTERNS_EXTRA accepted at install"

    printf "%s\nCRASH_LOG_PATTERNS_EXTRA=\"foo;rm -rf /\"\n" "${base_conf}" > "${conf_file}"
    exit_code=$(IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
        _run bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}")
    verify_exit_code "1" "${exit_code}" "Illegal characters in CRASH_LOG_PATTERNS_EXTRA rejected at install"

    printf "%s\nCRASH_LOG_PATTERNS_EXTRA=\"unclosed(group\"\n" "${base_conf}" > "${conf_file}"
    exit_code=$(IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
        _run bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}")
    verify_exit_code "1" "${exit_code}" "Invalid regex in CRASH_LOG_PATTERNS_EXTRA rejected at install"

    # #106: degenerate and empty-alternation patterns are rejected even
    # though they compile; a legitimate multi-alternation still passes.
    local bad_pat
    for bad_pat in '.' 'a||b' '|a' 'a|' '(|a)' '(a|)' 'healthy log line' 'ORDINARY HEALTHY'; do
        printf "%s\nCRASH_LOG_PATTERNS_EXTRA=\"%s\"\n" "${base_conf}" "${bad_pat}" > "${conf_file}"
        exit_code=$(IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
        _run bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}")
        verify_exit_code "1" "${exit_code}" "Degenerate/empty-alternation _EXTRA '${bad_pat}' rejected at install (#106)"
    done

    printf "%s\nCRASH_LOG_PATTERNS_EXTRA=\"Broken pipe|net_ex\"\n" "${base_conf}" > "${conf_file}"
    exit_code=$(IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
        _run bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}")
    verify_exit_code "0" "${exit_code}" "Legitimate multi-alternation _EXTRA accepted at install (#106)"
}


# Validates the global CONF_DIR absolute/whitespace guard (M6/#109):
# relative or whitespace values exit 1 with the named error on any verb;
# an absolute override stays accepted.
function test_conf_dir_guard {
    local step="$1"
    local stderr_cap="${TEST_TMPDIR}/conf_dir_guard_stderr"
    local ec has_msg

    print_divider
    _log "INFO" "STEP ${step}: CONF_DIR Absolute/Whitespace Guard (#109)"
    print_sub_divider

    # Case 1: relative unified override -> exit 1, named error, read-only verb.
    ec=0
    IOC_RUNNER_CONF_DIR="relative/conf" \
        bash "${RUNNER_SCRIPT}" --local list >/dev/null 2>"${stderr_cap}" || ec=$?
    verify_exit_code "1" "${ec}" "relative IOC_RUNNER_CONF_DIR exits 1 on list"
    has_msg="false"
    grep -q "resolved configuration directory" "${stderr_cap}" 2>/dev/null && has_msg="true"
    verify_state "true" "${has_msg}" "relative CONF_DIR error names the resolved directory"

    # Case 2: whitespace in the namespaced override -> exit 1, named error.
    #    Message-asserted because a status verb can exit 1 for other reasons
    #    (unknown-name gate); the named error pins the guard itself.
    ec=0
    IOC_RUNNER_LOCAL_CONF_DIR="${TEST_TMPDIR}/conf dir" \
        bash "${RUNNER_SCRIPT}" --local status fake-ioc >/dev/null 2>"${stderr_cap}" || ec=$?
    verify_exit_code "1" "${ec}" "whitespace CONF_DIR exits 1 on status"
    has_msg="false"
    grep -q "resolved configuration directory" "${stderr_cap}" 2>/dev/null && has_msg="true"
    verify_state "true" "${has_msg}" "whitespace CONF_DIR error names the resolved directory"

    # Case 3: absolute override passes the guard (no over-firing).
    ec=0
    IOC_RUNNER_CONF_DIR="${TEST_TMPDIR}/local-config/procServ.d" \
        bash "${RUNNER_SCRIPT}" --local list >/dev/null 2>"${stderr_cap}" || ec=$?
    verify_exit_code "0" "${ec}" "absolute CONF_DIR passes the guard"
}

# M7/#110 (1a): an uncreatable local logrotate cfg_dir must skip rotation
# with a warning, never abort the IOC install (never-abort contract).
function test_logrotate_skip_guard {
    local step="$1"
    local applicability_reason="requires a non-root effective user"
    print_divider
    _log "INFO" "STEP ${step}: Logrotate Never-Abort Guard (#110)"
    print_sub_divider

    if [[ ${EUID} -eq 0 ]]; then
        _log "WARN" "Running as root: skipping the uncreatable-directory case (chmod 0555 cannot deny root)."
        close_current_remaining NA "${applicability_reason}"
        return 0
    fi

    local w="${TEST_TMPDIR}/lr_guard"
    mkdir -p "${w}/boot" "${w}/sysd" "${w}/run" "${w}/log" "${w}/roparent/procServ.d"
    touch "${w}/boot/st.cmd"; chmod +x "${w}/boot/st.cmd"
    cat <<EOF > "${w}/boot/lrg.conf"
IOC_NAME="lrg"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${w}/boot"
IOC_CMD="st.cmd"
EOF
    chmod 0555 "${w}/roparent"

    local ec=0 lr_stderr="${TEST_TMPDIR}/lr_guard_stderr"
    IOC_RUNNER_LOCAL_CONF_DIR="${w}/roparent/procServ.d" IOC_RUNNER_LOCAL_SYSTEMD_DIR="${w}/sysd" \
    IOC_RUNNER_LOCAL_RUN_DIR="${w}/run" IOC_RUNNER_LOCAL_LOG_DIR="${w}/log" \
        bash "${RUNNER_SCRIPT}" --local -f install "${w}/boot/lrg.conf" >/dev/null 2>"${lr_stderr}" || ec=$?
    chmod 0755 "${w}/roparent"
    verify_exit_code "0" "${ec}" "install proceeds when the rotation cfg_dir is uncreatable (#110)"

    local skipped="false"
    grep -q "rotation not installed" "${lr_stderr}" 2>/dev/null && skipped="true"
    verify_state "true" "${skipped}" "uncreatable cfg_dir warns and skips rotation (#110)"
}

# Validates #74/#78 tool resolution: IOC_RUNNER_PROCSERV_TOOL override semantics
# and the home-bin search-path default. Each case is self-contained -- it
# supplies its own stub via the override or a HOME-redirected ~/.local/bin.
# _setup now exports a suite-wide mock IOC_RUNNER_PROCSERV_TOOL (#77), so the
# home-bin search case below unsets it (env -u) to exercise the real search.
function test_tool_resolution {
    local step="$1"
    local test_dir="${TEST_TMPDIR}/toolres_ioc"
    local conf_dir="${TEST_TMPDIR}/toolres_conf"
    local sysd_dir="${TEST_TMPDIR}/toolres_sysd"
    local template="${sysd_dir}/epics-@.service"
    local conf_file="${test_dir}/toolres_ioc.conf"

    print_divider
    _log "INFO" "STEP ${step}: Tool Resolution (IOC_RUNNER_PROCSERV_TOOL + home-bin)"
    print_sub_divider

    mkdir -p "${test_dir}" "${conf_dir}" "${sysd_dir}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    # Pre-generate a valid conf the install path consumes. IOC_CHDIR resolves to
    # an absolute path, so later installs need no cwd change and can verify in
    # the function body (subshell verify calls would not update the counters).
    ( cd "${test_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1 )

    # --- Case 1: a non-executable IOC_RUNNER_PROCSERV_TOOL is rejected. ---
    local nonexec="${TEST_TMPDIR}/nonexec_procserv"
    printf "#!/usr/bin/env bash\nexit 0\n" > "${nonexec}"   # intentionally not +x
    local c1_stderr="${TEST_TMPDIR}/toolres_c1_stderr"
    local c1_ec=0
    IOC_RUNNER_PROCSERV_TOOL="${nonexec}" \
        IOC_RUNNER_CONF_DIR="${conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${sysd_dir}" \
        bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}" >/dev/null 2>"${c1_stderr}" || c1_ec=$?
    verify_exit_code "1" "${c1_ec}" "Non-executable IOC_RUNNER_PROCSERV_TOOL exits 1"

    local c1_msg="false"
    if grep -q "IOC_RUNNER_PROCSERV_TOOL" "${c1_stderr}" 2>/dev/null \
       && grep -q "not an executable" "${c1_stderr}" 2>/dev/null; then
        c1_msg="true"
    fi
    verify_state "true" "${c1_msg}" "Non-executable override error names the variable"

    # --- Case 1b: an executable directory as the override is rejected (#78). ---
    # A directory carries the execute bit, so a bare -x check would accept it;
    # the override must be a regular executable file (-f && -x).
    local execdir="${TEST_TMPDIR}/execdir_procserv"
    mkdir -p "${execdir}"
    chmod +x "${execdir}"   # guarantee the fixture is an executable directory
    local c1b_stderr="${TEST_TMPDIR}/toolres_c1b_stderr"
    local c1b_ec=0
    IOC_RUNNER_PROCSERV_TOOL="${execdir}" \
        IOC_RUNNER_CONF_DIR="${conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${sysd_dir}" \
        bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}" >/dev/null 2>"${c1b_stderr}" || c1b_ec=$?
    verify_exit_code "1" "${c1b_ec}" "Executable-directory IOC_RUNNER_PROCSERV_TOOL exits 1"

    local c1b_msg="false"
    if grep -q "IOC_RUNNER_PROCSERV_TOOL" "${c1b_stderr}" 2>/dev/null \
       && grep -q "not an executable" "${c1b_stderr}" 2>/dev/null; then
        c1b_msg="true"
    fi
    verify_state "true" "${c1b_msg}" "Executable-directory override error names the variable"

    # --- Case 2: an executable IOC_RUNNER_PROCSERV_TOOL is honored. ---
    local stub="${TEST_TMPDIR}/stub_procserv"
    printf "#!/usr/bin/env bash\nexit 0\n" > "${stub}"
    chmod +x "${stub}"
    rm -f "${template}"
    local c2_ec=0
    IOC_RUNNER_PROCSERV_TOOL="${stub}" \
        IOC_RUNNER_CONF_DIR="${conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${sysd_dir}" \
        bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}" >/dev/null 2>&1 || c2_ec=$?
    verify_exit_code "0" "${c2_ec}" "Executable IOC_RUNNER_PROCSERV_TOOL accepted"

    local c2_ref="false"
    grep -q -F "${stub}" "${template}" 2>/dev/null && c2_ref="true"
    verify_state "true" "${c2_ref}" "Template ExecStart references the override binary"

    # --- Case 3: procServ resolves from ${HOME}/.local/bin via the search path. ---
    local fake_home="${TEST_TMPDIR}/toolres_home"
    local home_stub="${fake_home}/.local/bin/procServ"
    mkdir -p "${fake_home}/.local/bin"
    printf "#!/usr/bin/env bash\nexit 0\n" > "${home_stub}"
    chmod +x "${home_stub}"
    rm -f "${template}"
    local c3_ec=0
    env -u IOC_RUNNER_PROCSERV_TOOL HOME="${fake_home}" \
        IOC_RUNNER_CONF_DIR="${conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${sysd_dir}" \
        bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}" >/dev/null 2>&1 || c3_ec=$?
    verify_exit_code "0" "${c3_ec}" "Home-bin procServ resolves without an override"

    local c3_ref="false"
    grep -q -F "${home_stub}" "${template}" 2>/dev/null && c3_ref="true"
    verify_state "true" "${c3_ref}" "Template ExecStart references the home-bin binary"

    # --- Case 4: con search path prepends home-bin under a trusted HOME. ---
    # Static: con resolution is observable only through the final exec, which
    # do_attach guards behind a live socket (resolve_sock_path), absent in this
    # suite. Source the trust-flag and array-construction fragments with HOME
    # set (trusted), then assert the home-bin entry is first.
    local fake_home_con="${TEST_TMPDIR}/toolres_home_con"
    local c4_got
    c4_got=$(env HOME="${fake_home_con}" bash -c '
        source <(sed -n "/^declare -g HOME_TRUSTED=/,/^fi$/p" "'"${RUNNER_SCRIPT}"'")
        source <(sed -n "/^declare -g -a CON_SEARCH_PATHS=/,/^fi$/p" "'"${RUNNER_SCRIPT}"'")
        printf "%s" "${CON_SEARCH_PATHS[0]}"
    ' 2>/dev/null)
    verify_state "${fake_home_con}/.local/bin/con" "${c4_got}" \
        "con search path prepends home-bin when HOME is trusted"
}



# Issue #121 item 1: a mktemp failure while staging the generated conf inside a
# non-writable target directory must surface a named directory-writability error,
# not the raw 'mktemp:' line. chmod 0500 cannot deny root, so the barrier never
# fires under EUID 0 and the case is skipped there.
function test_generate_staging_perm {
    local step="$1"
    local applicability_reason="requires a non-root effective user"
    print_divider
    _log "INFO" "STEP ${step}: Generate Staging Permission Barrier (#121)"
    print_sub_divider

    if [[ ${EUID} -eq 0 ]]; then
        _log "WARN" "Running as root: skipping the staging-permission case (chmod 0500 cannot deny root)."
        record_current_state NA "${applicability_reason}"
        close_current_remaining NA "${applicability_reason}"
        return 0
    fi
    record_current_state PASS

    local ro_dir="${TEST_TMPDIR}/ro_generate"
    mkdir -p "${ro_dir}"
    touch "${ro_dir}/st.cmd"
    chmod +x "${ro_dir}/st.cmd"
    chmod 0500 "${ro_dir}"

    local err_f="${TEST_TMPDIR}/gen_perm_err" ec=0
    bash "${RUNNER_SCRIPT}" --local generate "${ro_dir}" >/dev/null 2>"${err_f}" || ec=$?
    chmod 0700 "${ro_dir}"

    verify_exit_code "1" "${ec}" "Generate into a non-writable directory exits 1"

    local names_dir="false"
    if grep -q "No write permission to .* to stage the generated configuration" "${err_f}"; then names_dir="true"; fi
    verify_state "true" "${names_dir}" "Generate staging failure names directory writability"

    local raw_mktemp="false"
    if grep -q "mktemp:" "${err_f}"; then raw_mktemp="true"; fi
    verify_state "false" "${raw_mktemp}" "Generate staging failure hides the raw mktemp error"
}

# Issue #121 items 2 and 4 (view): the do_view missing-conf error block keeps its
# closing divider on stderr with the error rather than splitting it to stdout, and
# an unreadable CONF_DIR is reported as an access barrier instead of a misleading
# "not found". chmod 0 cannot deny root, so the access-barrier case is skipped
# under EUID 0.
function test_view_message_streams {
    local step="$1"
    local applicability_reason="requires a non-root effective user"
    print_divider
    _log "INFO" "STEP ${step}: View Message Streams and Access Barrier (#121)"
    print_sub_divider

    if [[ ${EUID} -eq 0 ]]; then
        record_current_state NA "${applicability_reason}"
    else
        record_current_state PASS
    fi

    local conf_dir="${IOC_RUNNER_LOCAL_CONF_DIR}"
    mkdir -p "${conf_dir}"

    # Item 2: a genuinely absent conf. The error and its closing divider both
    # ride stderr; stdout carries only the one header divider.
    local out_f="${TEST_TMPDIR}/view_out" err_f="${TEST_TMPDIR}/view_err" ec=0
    bash "${RUNNER_SCRIPT}" --local view absent_view_ioc >"${out_f}" 2>"${err_f}" || ec=$?
    verify_exit_code "1" "${ec}" "View of an absent conf exits 1"

    local err_has_notfound="false"
    if grep -q "Configuration file not found" "${err_f}"; then err_has_notfound="true"; fi
    verify_state "true" "${err_has_notfound}" "View missing-conf error rides stderr"

    local err_divider_count out_divider_count
    err_divider_count=$(grep -cE '^=+$' "${err_f}" || true)
    out_divider_count=$(grep -cE '^=+$' "${out_f}" || true)
    verify_state "1" "${err_divider_count}" "View missing-conf closing divider joins the error on stderr"
    verify_state "1" "${out_divider_count}" "View missing-conf stdout keeps only the header divider"

    # Item 4 (view): an unreadable CONF_DIR holding a real conf must name the
    # access barrier, not report the installed IOC as "not found".
    if [[ ${EUID} -eq 0 ]]; then
        _log "WARN" "Running as root: skipping the view access-barrier case (chmod 0 cannot deny root)."
        close_current_remaining NA "${applicability_reason}"
        return 0
    fi

    printf 'IOC_NAME="barred_view"\nIOC_USER="%s"\nIOC_CMD="st.cmd"\n' "$(id -un)" > "${conf_dir}/barred_view.conf"
    chmod 0 "${conf_dir}"
    local berr_f="${TEST_TMPDIR}/view_barred_err" bec=0
    bash "${RUNNER_SCRIPT}" --local view barred_view >/dev/null 2>"${berr_f}" || bec=$?
    chmod 0755 "${conf_dir}"

    verify_exit_code "1" "${bec}" "View of an unreadable CONF_DIR exits 1"

    local names_barrier="false"
    if grep -q "Cannot read .* to resolve IOC 'barred_view'" "${berr_f}"; then names_barrier="true"; fi
    verify_state "true" "${names_barrier}" "View names the access barrier for an unreadable CONF_DIR"

    local says_notfound="false"
    if grep -q "not found" "${berr_f}"; then says_notfound="true"; fi
    verify_state "false" "${says_notfound}" "View does not misreport an unreadable CONF_DIR as not found"
}

# Issue #121 item 4 (attach/monitor): resolve_sock_path shares the readability
# guard, so attach on an unreadable CONF_DIR names the access barrier instead of
# "not found". resolve_con_tool runs first and resolves the mocked console tool,
# so execution reaches resolve_sock_path. chmod 0 cannot deny root; skipped there.
function test_attach_access_barrier {
    local step="$1"
    local applicability_reason="requires a non-root effective user"
    print_divider
    _log "INFO" "STEP ${step}: Attach Access Barrier (#121)"
    print_sub_divider

    if [[ ${EUID} -eq 0 ]]; then
        _log "WARN" "Running as root: skipping the attach access-barrier case (chmod 0 cannot deny root)."
        record_current_state NA "${applicability_reason}"
        close_current_remaining NA "${applicability_reason}"
        return 0
    fi
    record_current_state PASS

    local conf_dir="${IOC_RUNNER_LOCAL_CONF_DIR}"
    mkdir -p "${conf_dir}"
    printf 'IOC_NAME="barred_attach"\nIOC_USER="%s"\nIOC_CMD="st.cmd"\n' "$(id -un)" > "${conf_dir}/barred_attach.conf"
    chmod 0 "${conf_dir}"
    local err_f="${TEST_TMPDIR}/attach_barred_err" ec=0
    bash "${RUNNER_SCRIPT}" --local attach barred_attach >/dev/null 2>"${err_f}" || ec=$?
    chmod 0755 "${conf_dir}"

    verify_exit_code "1" "${ec}" "Attach to an unreadable CONF_DIR exits 1"

    local names_barrier="false"
    if grep -q "Cannot read .* to resolve IOC 'barred_attach'" "${err_f}"; then names_barrier="true"; fi
    verify_state "true" "${names_barrier}" "Attach names the access barrier for an unreadable CONF_DIR"

    local says_notfound="false"
    if grep -q "Configuration for barred_attach not found" "${err_f}"; then says_notfound="true"; fi
    verify_state "false" "${says_notfound}" "Attach does not misreport an unreadable CONF_DIR as not found"
}

# Issue #121 item 5: in local mode the do_install permission hint must not suggest
# 'ioc' group membership -- local mode is not group-gated. Build a valid conf,
# point CONF_DIR at a 0500 directory so the write-permission branch fires, and
# confirm the message names the directory without the system-group question. The
# named-directory assertion doubles as the anti-vacuous marker: a green from an
# earlier failure would never reach the branch. chmod 0500 cannot deny root;
# skipped under EUID 0.
function test_install_local_perm_hint {
    local step="$1"
    local applicability_reason="requires a non-root effective user"
    print_divider
    _log "INFO" "STEP ${step}: Install Local Permission Hint (#121)"
    print_sub_divider

    if [[ ${EUID} -eq 0 ]]; then
        _log "WARN" "Running as root: skipping the local install hint case (chmod 0500 cannot deny root)."
        record_current_state NA "${applicability_reason}"
        close_current_remaining NA "${applicability_reason}"
        return 0
    fi
    record_current_state PASS

    local src_dir="${TEST_TMPDIR}/install_hint_ioc"
    local blocked_conf_dir="${TEST_TMPDIR}/blocked_conf"
    mkdir -p "${src_dir}" "${blocked_conf_dir}"
    touch "${src_dir}/st.cmd"
    chmod +x "${src_dir}/st.cmd"
    ( cd "${src_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1 )

    chmod 0500 "${blocked_conf_dir}"
    local err_f="${TEST_TMPDIR}/install_hint_err" ec=0
    ( cd "${src_dir}" && IOC_RUNNER_CONF_DIR="${blocked_conf_dir}" \
        bash "${RUNNER_SCRIPT}" --local install . </dev/null ) >/dev/null 2>"${err_f}" || ec=$?
    chmod 0700 "${blocked_conf_dir}"

    verify_exit_code "1" "${ec}" "Local install into a non-writable CONF_DIR exits 1"

    local names_dir="false"
    if grep -q "No write permission to ${blocked_conf_dir}" "${err_f}"; then names_dir="true"; fi
    verify_state "true" "${names_dir}" "Local install names the non-writable CONF_DIR (branch reached)"

    local asks_group="false"
    if grep -q "group?" "${err_f}"; then asks_group="true"; fi
    verify_state "false" "${asks_group}" "Local install drops the ioc group question"
}

# M13/#143: the local logrotate debug validation must isolate itself from the
# system default state file. This pins the runner's behavior at the outermost
# tool boundary -- a recording mock via IOC_RUNNER_LOGROTATE_TOOL -- so a
# regression to the default /var/lib/logrotate/logrotate.status goes red. Only
# the external logrotate binary is mocked; the whole local install path runs.
# verify_state pulls the S37 catalog rows in this emission order.
function test_logrotate_debug_state_isolation {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Logrotate Debug State Isolation (M13/#143)"
    print_sub_divider

    local w="${TEST_TMPDIR}/lr_state"
    mkdir -p "${w}/boot" "${w}/conf" "${w}/sysd" "${w}/run" "${w}/log"
    touch "${w}/boot/st.cmd"
    chmod +x "${w}/boot/st.cmd"
    cat <<EOF > "${w}/boot/lrs.conf"
IOC_NAME="lrs"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${w}/boot"
IOC_CMD="st.cmd"
EOF

    # Recording mock at the outermost tool boundary: append argv, accept.
    local mock="${w}/mock-logrotate"
    local argv="${w}/argv"
    cat <<'MOCK' > "${mock}"
#!/bin/bash
printf '%s\n' "$*" >> "${IOC_RUNNER_MOCK_LOGROTATE_ARGV}"
exit 0
MOCK
    chmod +x "${mock}"

    local ec=0
    IOC_RUNNER_MOCK_LOGROTATE_ARGV="${argv}" \
    IOC_RUNNER_LOGROTATE_TOOL="${mock}" \
    IOC_RUNNER_LOCAL_CONF_DIR="${w}/conf" IOC_RUNNER_LOCAL_SYSTEMD_DIR="${w}/sysd" \
    IOC_RUNNER_LOCAL_RUN_DIR="${w}/run" IOC_RUNNER_LOCAL_LOG_DIR="${w}/log" \
        bash "${RUNNER_SCRIPT}" --local -f install "${w}/boot/lrs.conf" >/dev/null 2>&1 || ec=$?
    verify_exit_code "0" "${ec}" "install proceeds with the mock logrotate boundary"

    # cfg_dir resolves to "${CONF_DIR%/*}/ioc-runner"; CONF_DIR is the override.
    local cfg_deployed="false"
    [[ -f "${w}/ioc-runner/logrotate.conf" ]] && cfg_deployed="true"
    verify_state "true" "${cfg_deployed}" "rotation config is deployed after validation"

    # The -d validation must carry an explicit --state (the only invocation with
    # one), and that state must not be the system default.
    local has_state="false"
    grep -q -- "--state" "${argv}" 2>/dev/null && has_state="true"
    verify_state "true" "${has_state}" "debug validation passes an explicit --state"

    local off_default="true"
    grep -q "/var/lib/logrotate/logrotate.status" "${argv}" 2>/dev/null && off_default="false"
    verify_state "true" "${off_default}" "validation state is off the system default"
}

function run_all_tests {
    local -a pipeline=(
        "_setup"
        "test_usage"
        "test_missing_target"
        "test_generate_logic"
        "test_install_logic"
        "test_ioc_port_atomic_install"
        "test_generate_errors"
        "test_install_errors"
        "test_list_ss_vv_contract"
        "test_unknown_name_verb_gate"
        "test_local_ioc_port_replacement_warns"
        "no_error_contract_checks"
        "no_error_contract_checks"
        "no_error_contract_checks"
        "no_error_contract_checks"
        "no_error_contract_checks"
        "test_log_dir_guard"
        "no_error_contract_checks"
        "test_conf_dir_guard"
        "no_error_contract_checks"
        "test_logrotate_skip_guard"
        "no_error_contract_checks"
        "test_completion"
        "test_ioc_name_validation"
        "test_validation_errors"
        "test_attach_errors"
        "test_list_empty"
        "test_inspect_errors"
        "test_generate_staging_perm"
        "test_view_message_streams"
        "test_attach_access_barrier"
        "test_install_local_perm_hint"
        "no_error_contract_checks"
        "no_error_contract_checks"
        "test_crash_pattern_extra"
        "test_tool_resolution"
        "test_logrotate_debug_state_isolation"
    )
    local step=1
    local func
    for func in "${pipeline[@]}"; do
        printf -v CURRENT_STEP_ID 'S%02d' "${step}"
        CURRENT_STEP_CHECK_INDEX=0
        "${func}" "${step}"
        step=$((step + 1))
    done
}

initialize_reporting
if ! run_preflight; then
    exit 1
fi
run_all_tests
