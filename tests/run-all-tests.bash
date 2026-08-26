#!/usr/bin/env bash
#
# Master script to execute all EPICS IOC runner tests.
# Supports lifecycle-axis selection and exclusive source-regression execution.

set -e
set -o pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
umask 077
unset BASH_ENV ENV CDPATH GIT_DIR GIT_WORK_TREE

declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g BLUE='\033[0;34m'
declare -g NC='\033[0m'

declare -g SC_RPATH
declare -g SC_TOP
SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"

# shellcheck source=lib/test-record-validator.bash
source "${SC_TOP}/lib/test-record-validator.bash"

declare -g RUN_LOCAL=1
declare -g RUN_SYSTEM=1
declare -g RUN_SOURCE_REGRESSION=0
declare -g SEEN_PERMISSION_SELECTOR=0
declare -g SEEN_RUNNER_SELECTOR=0
declare -g TEST_MODE="source"
declare -g COLLECTOR_DIR=""
declare -g COLLECTOR_READY=0
declare -g DISPATCHER_MACHINE_OUTPUT_ACTIVE=0
declare -g DISPATCHER_MACHINE_OUTPUT_FD=""
declare -g -a SELECTED_SUITE_IDS=()
declare -g -A SELECTED_SUITE_SCOPE=()
declare -g -A SELECTED_SUITE_RUNNER=()
declare -g -A COLLECTED_SUITE_RECORDS=()
declare -g -A COLLECTED_RUN_IDS=()
declare -g -A COLLECTED_MACHINE_FILES=()

function initialize_output_boundary {
    local mode="${REPORT_MACHINE_OUTPUT:-0}"

    case "${mode}" in
        ""|0) return 0 ;;
        1) ;;
        *)
            collector_error "REPORT_MACHINE_OUTPUT must be 0, 1, or unset: ${mode}"
            return 1
            ;;
    esac
    if ! exec {DISPATCHER_MACHINE_OUTPUT_FD}>&1; then
        collector_error "Cannot reserve standard output for machine records."
        return 1
    fi
    if ! exec 1>&2; then
        exec {DISPATCHER_MACHINE_OUTPUT_FD}>&- || true
        DISPATCHER_MACHINE_OUTPUT_FD=""
        collector_error "Cannot route dispatcher output to standard error."
        return 1
    fi
    DISPATCHER_MACHINE_OUTPUT_ACTIVE=1
}

function print_divider {
    printf "${BLUE}%s${NC}\n" "===================================================================================================="
}

function collector_error {
    local message="$1"

    printf "%b[COLLECTOR ERROR]%b %s\n" "${RED}" "${NC}" "${message}" >&2
}

function cleanup_collector {
    if (( ! COLLECTOR_READY )); then
        return 0
    fi
    if [[ "${COLLECTOR_DIR}" != /tmp/ioc-runner-suite-collector.* ||
          ! -d "${COLLECTOR_DIR}" || -L "${COLLECTOR_DIR}" ]]; then
        return 1
    fi
    /bin/rm -rf -- "${COLLECTOR_DIR}"
    COLLECTOR_DIR=""
    COLLECTOR_READY=0
}

function handle_exit {
    local exit_status=$?

    trap - EXIT
    set +e
    if ! cleanup_collector; then
        collector_error "Failed to remove the suite collector workspace."
        exit_status=1
    fi
    exit "${exit_status}"
}

function initialize_collector {
    COLLECTOR_DIR=$(mktemp -d /tmp/ioc-runner-suite-collector.XXXXXX)
    COLLECTOR_READY=1
}

function add_selected_suite {
    local suite_id="$1"
    local suite_scope="$2"
    local suite_runner="$3"

    if [[ -n "${SELECTED_SUITE_SCOPE[${suite_id}]:-}" ]]; then
        collector_error "Duplicate selected suite: ${suite_id}"
        return 1
    fi
    SELECTED_SUITE_IDS+=("${suite_id}")
    SELECTED_SUITE_SCOPE["${suite_id}"]="${suite_scope}"
    SELECTED_SUITE_RUNNER["${suite_id}"]="${suite_runner}"
}

function configure_selected_suites {
    if (( RUN_SOURCE_REGRESSION )); then
        add_selected_suite source-regression system source
        return 0
    fi
    if (( RUN_LOCAL )); then
        add_selected_suite local-lifecycle local "${TEST_MODE}"
    fi
    if (( RUN_SYSTEM )); then
        add_selected_suite system-infra system none
        add_selected_suite system-lifecycle system "${TEST_MODE}"
    fi
}

function collect_validated_suite_output {
    local expected_suite="$1"
    local expected_scope="$2"
    local expected_runner="$3"
    local machine_file="$4"
    local producer_status="$5"
    local validated_run=""
    local validated_suite=""

    if [[ -n "${COLLECTED_SUITE_RECORDS[${expected_suite}]:-}" ]]; then
        collector_error "Duplicate collected suite: ${expected_suite}"
        return 1
    fi
    if ! test_record_validate_file "${machine_file}" "${expected_suite}" \
        "${expected_scope}" "${expected_runner}" "${producer_status}" \
        validated_run validated_suite; then
        collector_error "Machine records failed validation for ${expected_suite}."
        return 1
    fi
    if [[ -n "${COLLECTED_RUN_IDS[${validated_run}]:-}" ]]; then
        collector_error "Duplicate collected run ID: ${validated_run}"
        return 1
    fi

    COLLECTED_SUITE_RECORDS["${expected_suite}"]="${validated_suite}"
    COLLECTED_RUN_IDS["${validated_run}"]="${expected_suite}"
    COLLECTED_MACHINE_FILES["${expected_suite}"]="${machine_file}"
}

function validate_selected_suite_set {
    local suite_id=""

    for suite_id in "${SELECTED_SUITE_IDS[@]}"; do
        if [[ -z "${COLLECTED_SUITE_RECORDS[${suite_id}]:-}" ]]; then
            collector_error "Selected suite was not collected: ${suite_id}"
            return 1
        fi
        if [[ -z "${COLLECTED_MACHINE_FILES[${suite_id}]:-}" ]]; then
            collector_error "Selected suite has no validated machine file: ${suite_id}"
            return 1
        fi
    done
    if (( ${#COLLECTED_SUITE_RECORDS[@]} != ${#SELECTED_SUITE_IDS[@]} )); then
        collector_error "Collected suite set does not match the selected suite set."
        return 1
    fi
}

function emit_selected_machine_records {
    local suite_id=""

    if (( ! DISPATCHER_MACHINE_OUTPUT_ACTIVE )); then
        return 0
    fi
    for suite_id in "${SELECTED_SUITE_IDS[@]}"; do
        if ! /bin/cat -- "${COLLECTED_MACHINE_FILES[${suite_id}]}" \
            >&"${DISPATCHER_MACHINE_OUTPUT_FD}"; then
            collector_error "Failed to emit machine records for ${suite_id}."
            return 1
        fi
    done
}

function _run_test {
    local test_name="$1"
    local expected_suite="$2"
    local expected_scope="${SELECTED_SUITE_SCOPE[${expected_suite}]:-}"
    local expected_runner="${SELECTED_SUITE_RUNNER[${expected_suite}]:-}"
    local test_cmd=("${@:3}")
    local machine_file="${COLLECTOR_DIR}/${expected_suite}.machine"
    local human_file="${COLLECTOR_DIR}/${expected_suite}.human"
    local producer_status=0
    local validation_status=0

    print_divider
    printf "%b[ RUN      ] %s%b\n" "${BLUE}" "${test_name}" "${NC}"
    print_divider

    set +e
    "${test_cmd[@]}" > "${machine_file}" 2> "${human_file}"
    producer_status=$?
    set -e

    if ! /bin/cat -- "${human_file}"; then
        collector_error "Failed to display human output for ${expected_suite}."
        return 1
    fi
    collect_validated_suite_output "${expected_suite}" "${expected_scope}" \
        "${expected_runner}" "${machine_file}" "${producer_status}" || validation_status=$?
    if (( validation_status != 0 )); then
        return 1
    fi
    if (( producer_status != 0 )); then
        printf "\n%b[ FAILED   ] %s (exit %d)%b\n\n" \
            "${RED}" "${test_name}" "${producer_status}" "${NC}" >&2
        return "${producer_status}"
    fi

    printf "\n%b[ PASSED   ] %s%b\n\n" "${GREEN}" "${test_name}" "${NC}"
}

trap handle_exit EXIT
trap 'exit 1' SIGINT

initialize_output_boundary

# --- CLI Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --local|local)
            SEEN_PERMISSION_SELECTOR=1
            RUN_LOCAL=1
            RUN_SYSTEM=0
            shift
            ;;
        --system|system)
            SEEN_PERMISSION_SELECTOR=1
            RUN_LOCAL=0
            RUN_SYSTEM=1
            shift
            ;;
        --source)
            SEEN_RUNNER_SELECTOR=1
            TEST_MODE="source"
            shift
            ;;
        --installed)
            SEEN_RUNNER_SELECTOR=1
            TEST_MODE="installed"
            shift
            ;;
        --source-regression)
            RUN_SOURCE_REGRESSION=1
            RUN_LOCAL=0
            RUN_SYSTEM=0
            shift
            ;;
        -h|--help)
            printf "Usage: bash %s [--local | --system] [--source | --installed]\n" "$(basename "$0")"
            printf "       bash %s --source-regression\n" "$(basename "$0")"
            printf "  --local / --system   select permission mode (default: both)\n"
            printf "  --source / --installed   select runner binary origin (default: source)\n"
            printf "  --source-regression   run only source-tree regression checks\n"
            printf "  The error-handling suite is static and runs on its own:\n"
            printf "    bash %s/test-error-handling.bash\n" "$(dirname "$0")"
            exit 0
            ;;
        *)
            printf "${RED}Error: Unknown option '%s'${NC}\n" "$1" >&2
            exit 1
            ;;
    esac
done

if [[ ${RUN_SOURCE_REGRESSION} -eq 1 ]] &&
   [[ ${SEEN_PERMISSION_SELECTOR} -eq 1 || ${SEEN_RUNNER_SELECTOR} -eq 1 ]]; then
    printf "${RED}%s${NC}\n" \
        "Error: --source-regression cannot be combined with lifecycle selectors." >&2
    exit 1
fi

configure_selected_suites

if [[ ${RUN_SOURCE_REGRESSION} -eq 1 ]]; then
    initialize_collector
    _run_test "Source Regression" source-regression \
        sudo env REPORT_MACHINE_OUTPUT=1 bash "${SC_TOP}/test-source-regression.bash"
    validate_selected_suite_set
    print_divider
    printf "${GREEN}%s${NC}\n" "ALL SELECTED TEST SUITES COMPLETED SUCCESSFULLY."
    print_divider
    emit_selected_machine_records
    exit 0
fi

# Pre-flight environment check
if [[ -z "${EPICS_BASE:-}" ]]; then
    printf "${RED}%s${NC}\n" "ERROR: EPICS_BASE environment variable is not set." >&2
    exit 1
fi

# Propagate the runner binary origin to the lifecycle scripts. Exported so
# the non-root local path and the `sudo -E` system path both inherit it; the
# privilege-drop path below re-adds it explicitly because `env -i` clears it.
export IOC_RUNNER_TEST_MODE="${TEST_MODE}"

# Installed-mode tests resolve the runner from this override (the resolver
# applies the canonical default); export so the non-root local and `sudo -E`
# system routes inherit it, and the `env -i` privilege-drop path below re-adds
# it explicitly. An empty value when unset keeps the resolver's default. (#145)
export IOC_RUNNER_SCRIPT_DEST="${IOC_RUNNER_SCRIPT_DEST:-}"

if [[ ${RUN_SYSTEM} -eq 1 ]]; then
    # Avoid an authentication prompt when the test account already has a
    # non-interactive sudo route. Password-based accounts still authenticate
    # before suite output is captured.
    if ! sudo -n true 2>/dev/null; then
        printf "%s\n" "Caching sudo credentials for system infrastructure tests..."
        sudo -v
    fi
fi

initialize_collector

# Execute tests based on selected mode.
# The local lifecycle routes through `systemctl --user` against the caller's
# user-mode systemd. When the suite is invoked via `sudo -E`, root's user bus
# is typically unreachable, so drop privilege back to ${SUDO_USER} for it. The
# system phases below stay root because they need it.
#
# `sudo -u <user> -E` would carry the outer root process's HOME /
# XDG_RUNTIME_DIR into the dropped shell whenever sudoers env_keep
# preserves them, which then drives the wrong ~/.config/systemd/user
# discovery in test-local-lifecycle.bash (it captures HOME at script
# load). To remove that ambiguity we build an explicit environment
# (HOME, XDG_RUNTIME_DIR derived from SUDO_USER's passwd entry, plus
# the EPICS variables) and start the dropped shell from `env -i`. (#70)
if [[ ${RUN_LOCAL} -eq 1 ]]; then
    if [[ $(id -u) -eq 0 && -n "${SUDO_USER:-}" ]]; then
        SUDO_USER_UID=$(id -u "${SUDO_USER}")
        SUDO_USER_HOME=$(getent passwd "${SUDO_USER}" | cut -d: -f6)
        declare -a LOCAL_PHASE_ENV=(
            "HOME=${SUDO_USER_HOME}"
            "USER=${SUDO_USER}"
            "LOGNAME=${SUDO_USER}"
            "XDG_RUNTIME_DIR=/run/user/${SUDO_USER_UID}"
            "PATH=${PATH}"
            "LANG=${LANG:-C.UTF-8}"
            "EPICS_BASE=${EPICS_BASE:-}"
            "EPICS_HOST_ARCH=${EPICS_HOST_ARCH:-}"
            "EPICS_MODULES=${EPICS_MODULES:-}"
            "LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-}"
            "IOC_RUNNER_TEST_MODE=${TEST_MODE}"
            "IOC_RUNNER_SCRIPT_DEST=${IOC_RUNNER_SCRIPT_DEST:-}"
            "REPORT_MACHINE_OUTPUT=1"
        )
        _run_test "Local Lifecycle" local-lifecycle \
            sudo -u "${SUDO_USER}" env -i "${LOCAL_PHASE_ENV[@]}" \
            bash "${SC_TOP}/test-local-lifecycle.bash"
    else
        _run_test "Local Lifecycle" local-lifecycle \
            env REPORT_MACHINE_OUTPUT=1 bash "${SC_TOP}/test-local-lifecycle.bash"
    fi
fi

if [[ ${RUN_SYSTEM} -eq 1 ]]; then
    _run_test "System Infrastructure" system-infra \
        sudo env REPORT_MACHINE_OUTPUT=1 bash "${SC_TOP}/test-system-infra.bash"
    _run_test "System Lifecycle" system-lifecycle \
        sudo -E env REPORT_MACHINE_OUTPUT=1 bash "${SC_TOP}/test-system-lifecycle.bash"
fi

validate_selected_suite_set
print_divider
printf "${GREEN}%s${NC}\n" "ALL SELECTED TEST SUITES COMPLETED SUCCESSFULLY."
print_divider
emit_selected_machine_records
