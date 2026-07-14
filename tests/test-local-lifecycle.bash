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
declare -g MAGENTA='\033[0;35m'
declare -g BLUE='\033[0;34m'
declare -g YELLOW='\033[0;33m'
declare -g NC='\033[0m'

# --- Global Test Tracking ---
declare -g TEST_TOTAL=0
declare -g TEST_PASSED=0
declare -g TEST_FAILED=0
declare -g SCRIPT_ERROR=0
declare -g -a FAILED_DETAILS=()

# --- EPICS Test Configuration ---
declare -g CAMONITOR_COUNT=5
declare -g CAMONITOR_TIMEOUT=10

if [[ -z "${EPICS_BASE}" ]]; then
    printf "${RED}%s${NC}\n" "ERROR: The EPICS_BASE environment variable is not set." >&2
    printf "Please source your EPICS environment script before running this test.\n" >&2
    exit 1
fi

if ! command -v lsof >/dev/null 2>&1; then
    printf "${RED}%s${NC}\n" "ERROR: The 'lsof' utility is required for the inspect test (STEP 17) but was not found in PATH." >&2
    printf "Hint: install lsof via your package manager (apt install lsof / dnf install lsof).\n" >&2
    exit 1
fi

# STEP 24 (monitor isolation) reads journalctl --user output. Hosts
# without a working user-scope journal (no linger, missing
# /var/log/journal/<machine-id>, or user not in systemd-journal group)
# cannot verify that step. Detect both common failure messages and mark
# the journal unavailable so dependent steps skip with a WARN.
# See issue #50.
declare -g JOURNAL_AVAILABLE="true"
journal_probe=$(journalctl --user --no-pager -n 1 2>&1 || true)
if [[ "${journal_probe}" == *"No journal files were found"* || "${journal_probe}" == *"insufficient permissions"* ]]; then
    JOURNAL_AVAILABLE="false"
    printf "${YELLOW}%s${NC}\n" "WARN: User-scope journal unavailable on this host." >&2
    printf "The monitor-isolation step will be skipped.\n" >&2
    printf "Hint: enable linger and persistent journal to enable these steps:\n" >&2
    printf "  sudo loginctl enable-linger %s\n" "$(id -un)" >&2
    printf "  sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald\n" >&2
fi

# U003/M19: the local log-rotation steps need logrotate. Hosts without it
# cannot verify rotation; mark it unavailable so those steps skip with a WARN
# rather than fail (deploy_local_logrotate itself warns and skips).
declare -g LOGROTATE_AVAILABLE="true"
if ! command -v logrotate >/dev/null 2>&1; then
    LOGROTATE_AVAILABLE="false"
    printf "${YELLOW}%s${NC}\n" "WARN: logrotate not found; U003/M19 rotation steps will be skipped." >&2
fi

if [[ -z "${EPICS_HOST_ARCH}" ]]; then
    export EPICS_HOST_ARCH="linux-x86_64"
fi

declare -g SC_RPATH
declare -g SC_TOP
SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"

# --- Managed Architecture Paths ---
# Resolve the ioc-runner binary under test. IOC_RUNNER_TEST_MODE selects
# the binary origin; the unset default is the source tree, matching the
# developer inner loop. Selection failures stop here, before STEP 1,
# never deferred into the lifecycle body.
declare -g RUNNER_SCRIPT
function resolve_runner_script {
    local mode="${IOC_RUNNER_TEST_MODE:-}"
    local source_bin="${SC_TOP}/../bin/ioc-runner"
    local installed_bin="/usr/local/bin/ioc-runner"
    case "${mode}" in
        ""|source)
            RUNNER_SCRIPT="${source_bin}"
            ;;
        installed)
            if [[ ! -x "${installed_bin}" ]]; then
                printf "Error: installed ioc-runner not found\n" >&2
                exit 1
            fi
            RUNNER_SCRIPT="${installed_bin}"
            ;;
        *)
            printf "Error: invalid IOC_RUNNER_TEST_MODE '%s' (expected: source, installed)\n" "${mode}" >&2
            exit 1
            ;;
    esac
    if [[ "${RUNNER_SCRIPT}" == "${source_bin}" && ! -x "${RUNNER_SCRIPT}" ]]; then
        printf "Error: source ioc-runner not found\n" >&2
        exit 1
    fi
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

function _handle_exit {
    local exit_code=$?

    # System Requirement: Suppress unexpected abort message if failure is due to controlled test assertions
    if [[ ${exit_code} -ne 0 && ${TEST_FAILED} -eq 0 && ${SCRIPT_ERROR} -eq 0 ]]; then
        SCRIPT_ERROR=1
        printf "\n${RED}%s${NC}\n" "[ABORT] Script terminated unexpectedly. (Exit code: ${exit_code})"
    fi

    # U003/M19: unconditionally disarm the user log-rotation timer on every exit
    # path (success, assertion-fail, set -e abort, SIGINT). The pipeline arms a
    # real ~/.config/systemd/user timer at the first --local install; an aborted
    # run must not leave it enabled, or it would later fail hourly against the
    # removed workspace config. Runs even under KEEP_WORKSPACE=1 (re-arm by
    # re-running install). SYSTEMD_USER_DIR is declared unconditionally above.
    systemctl --user disable --now epics-logrotate.timer >/dev/null 2>&1 || true
    rm -f "${SYSTEMD_USER_DIR}/epics-logrotate.service" "${SYSTEMD_USER_DIR}/epics-logrotate.timer"
    systemctl --user daemon-reload >/dev/null 2>&1 || true

    if [[ -n "${WORKSPACE}" && "${WORKSPACE}" == */epics-ioc-test.* && -d "${WORKSPACE}" ]]; then
        if [[ ${TEST_FAILED} -gt 0 || ${SCRIPT_ERROR} -gt 0 || "${KEEP_WORKSPACE}" == "1" ]]; then
            print_divider
            _log "WARN" "DEBUG: Test workspace retained for inspection."
            _log "WARN" "Path: ${WORKSPACE}"
            print_divider
        else
            rm -rf "${WORKSPACE}"
            _log "INFO" "Test workspace removed."
        fi
    fi

    print_summary

    # System Requirement: Propagate aggregate failure state to CI/CD pipeline
    if [[ ${TEST_FAILED} -gt 0 || ${SCRIPT_ERROR} -gt 0 ]]; then
        exit 1
    fi
    exit 0
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
    printf "${BLUE}%s${NC}\n" "                                     LOCAL LIFECYCLE TEST SUMMARY                                   "
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
        printf "\n${GREEN}%s${NC}\n" "[SUCCESS] All lifecycle tests completed perfectly!"
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
        return 0
    fi

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

    local con_cmd
    if command -v con >/dev/null 2>&1; then
        con_cmd="con"
    else
        con_cmd="/usr/local/bin/con"
    fi

    local con_ok="false"
    if command -v "${con_cmd}" >/dev/null 2>&1; then con_ok="true"; fi
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
    fi

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

    if [[ "${JOURNAL_AVAILABLE}" != "true" ]]; then
        _log "WARN" "User-scope journal unavailable, skipping monitor isolation test."
        return 0
    fi

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

function test_crash_detection {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Crash Detection with softIoc"
    print_sub_divider

    local softioc_bin="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}/softIoc"
    if [[ ! -x "${softioc_bin}" ]]; then
        _log "WARN" "softIoc not found at ${softioc_bin}, skipping crash detection test."
        return 0
    fi

    local local_log_dir="${IOC_RUNNER_LOCAL_LOG_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/procserv}"
    local fatal_ioc_name="CrashTestFatal"
    local fatal_ioc_dir="${WORKSPACE}/crash_fatal_ioc"
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
    fi

    # Issue #92: a pre-existing unreadable .iocsh_history makes iocsh emit the
    # benign "ERROR Permission denied (N) loading '...'" line inside the startup
    # scan window; CRASH_LOG_EXCLUDE_PATTERNS must clear it without weakening the
    # scan. Root bypasses the chmod-0 read denial (CAP_DAC_OVERRIDE), so the line
    # would never be emitted and the probes are skipped as root. Distinct from
    # CrashTestHistory above, which covers historical-log-offset behavior.
    if [[ ${EUID} -eq 0 ]]; then
        _log "WARN" "Running as root: chmod 0 cannot deny reads, skipping history-noise crash scan probes."
    else
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
        return 0
    fi

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

        local validate_ok="true"; logrotate -d "${cfg}" >/dev/null 2>&1 || validate_ok="false"
        verify_state "true" "${validate_ok}" "M19.T1: logrotate -d validates the config"
    fi

    # Timer armed (the user bus is up in this suite, as the IOC lifecycle steps need it).
    local enabled; enabled=$(systemctl --user is-enabled epics-logrotate.timer 2>/dev/null || true)
    verify_state "enabled" "${enabled}" "M19.T1: timer enabled"

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
    fi
}

# U003/M19.T2: forced rotation via copytruncate produces a compressed archive and
# truncates the live file in place (no IOC restart, no fd reopen).
function test_logrotate_rotation {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Local Log Rotation copytruncate (U003/M19.T2)"
    print_sub_divider

    if [[ "${LOGROTATE_AVAILABLE}" != "true" ]]; then
        _log "WARN" "logrotate unavailable; skipping M19.T2."
        return 0
    fi
    local cfg="${CONF_DIR%/*}/ioc-runner/logrotate.conf"
    if [[ ! -f "${cfg}" ]]; then
        verify_state "true" "false" "M19.T2: config present for rotation test"
        return 0
    fi

    local log_dir="${IOC_RUNNER_LOCAL_LOG_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/procserv}"
    install -d -m 0750 "${log_dir}"
    local probe="${log_dir}/rotateprobe.log"
    printf 'seed line for copytruncate\n' > "${probe}"
    local state; state=$(mktemp)
    logrotate -f --state "${state}" "${cfg}" >/dev/null 2>&1 || true

    local archived="false"; [[ -f "${probe}.1.gz" ]] && archived="true"
    verify_state "true" "${archived}" "M19.T2: copytruncate produced rotateprobe.log.1.gz"
    local truncated="false"; [[ -f "${probe}" && ! -s "${probe}" ]] && truncated="true"
    verify_state "true" "${truncated}" "M19.T2: live log truncated in place (copytruncate)"

    rm -f "${probe}" "${probe}".*.gz "${state}"
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
        return 0
    fi
    local cfg="${CONF_DIR%/*}/ioc-runner/logrotate.conf"
    if [[ ! -f "${cfg}" ]]; then
        verify_state "true" "false" "M19.T3: config present for maxsize test"
        return 0
    fi

    local tcfg; tcfg=$(mktemp)
    sed 's/maxsize 50M/maxsize 1k/' "${cfg}" > "${tcfg}"
    local log_dir="${IOC_RUNNER_LOCAL_LOG_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/procserv}"
    install -d -m 0750 "${log_dir}"
    local probe="${log_dir}/maxprobe.log"
    head -c 4096 /dev/zero | tr '\0' 'x' > "${probe}"
    local state; state=$(mktemp)
    logrotate --state "${state}" "${tcfg}" >/dev/null 2>&1 || true

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
        return 0
    fi
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
        "test_persistence"
        "test_remove"
        "test_logrotate_teardown"
    )

    # Record which ioc-runner binary this run exercises, so captured
    # output shows whether the installed or source-tree binary ran. A
    # stale installed binary previously masked a passing fix as a failing
    # test until an external reviewer caught the path mismatch. (#71)
    print_divider
    _log "INFO" "Runner under test: ${RUNNER_SCRIPT}"
    bash "${RUNNER_SCRIPT}" -V || _log "WARN" "ioc-runner -V returned non-zero"
    print_divider

    local step=1
    local func
    for func in "${pipeline[@]}"; do
        "${func}" "${step}"
        step=$((step + 1))
    done
}

run_all_tests
