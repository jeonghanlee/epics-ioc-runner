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
    printf "STEP 24 (monitor isolation) will be skipped.\n" >&2
    printf "Hint: enable linger and persistent journal to enable these steps:\n" >&2
    printf "  sudo loginctl enable-linger %s\n" "$(id -un)" >&2
    printf "  sudo mkdir -p /var/log/journal && sudo systemctl restart systemd-journald\n" >&2
fi

if [[ -z "${EPICS_HOST_ARCH}" ]]; then
    export EPICS_HOST_ARCH="linux-x86_64"
fi

declare -g SC_RPATH
declare -g SC_TOP
SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"

# --- Managed Architecture Paths ---
declare -g RUNNER_SCRIPT="${SC_TOP}/../bin/ioc-runner"
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

declare -g -a SYSTEMCTL_CMD=(systemctl --user)

declare -g KEEP_WORKSPACE="${KEEP_WORKSPACE:-0}"

function _handle_exit {
    local exit_code=$?

    # System Requirement: Suppress unexpected abort message if failure is due to controlled test assertions
    if [[ ${exit_code} -ne 0 && ${TEST_FAILED} -eq 0 && ${SCRIPT_ERROR} -eq 0 ]]; then
        SCRIPT_ERROR=1
        printf "\n${RED}%s${NC}\n" "[ABORT] Script terminated unexpectedly. (Exit code: ${exit_code})"
    fi

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
    systemctl --user daemon-reload || true

    _log "SUCCESS" "Cleaned up residual processes, templates, and configurations."
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
    wait_for_state "active"

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
    if printf "%s" "${output}" | grep -q "active"; then active_in_output="true"; fi
    verify_state "true" "${active_in_output}" "Status output contains 'active'"
}

function test_view {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test View Command"
    print_sub_divider

    local output
    output=$(bash "${RUNNER_SCRIPT}" --local view "${IOC_NAME}" 2>&1 || true)

    local conf_in_output="false"
    if printf "%s" "${output}" | grep -q "${IOC_NAME}"; then conf_in_output="true"; fi
    verify_state "true" "${conf_in_output}" "View output contains IOC name"
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
    wait_for_state "active"

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
    wait_for_state "active"

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

    printf "test_monitor_input_blocked\\n" | setsid bash "${RUNNER_SCRIPT}" --local monitor "${IOC_NAME}" >/dev/null 2>&1 &

    local monitor_pid=$!
    sleep 2

    local log_out
    log_out=$(journalctl --user -u "epics-@${IOC_NAME}.service" --since "5 seconds ago")

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
    local expected_warning="$2"
    local assertion_name="$3"
    local output
    local exit_code=0
    local start_ok="true"
    local warning_detected="false"

    output=$(bash "${RUNNER_SCRIPT}" --local start "${ioc_name}" 2>&1) || exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        start_ok="false"
    fi
    if printf "%s" "${output}" | grep -q "procServ may be crash-looping"; then
        warning_detected="true"
    fi

    _remove_crash_probe "${ioc_name}"
    if [[ "${expected_warning}" == "false" ]]; then
        verify_state "true" "${start_ok}" "${assertion_name}: start completed"
    fi
    verify_state "${expected_warning}" "${warning_detected}" "${assertion_name}"
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
    _run_crash_probe "${fatal_ioc_name}" "true" "Crash detection: FATAL softIoc child kill warning"

    local parse_ioc_name="CrashTestParse"
    local parse_ioc_dir="${WORKSPACE}/crash_parse_ioc"
    mkdir -p "${parse_ioc_dir}"

    cat << EOF > "${parse_ioc_dir}/st.cmd"
#!${softioc_bin}
dbLoadRecords("missing.db
EOF
    chmod +x "${parse_ioc_dir}/st.cmd"
    _install_crash_probe "${parse_ioc_name}" "${parse_ioc_dir}"
    _run_crash_probe "${parse_ioc_name}" "true" "Crash detection: iocsh parse error warning"

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
    _run_crash_probe "${history_ioc_name}" "false" "Crash detection: historical fatal log ignored for healthy start"

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
        _run_crash_probe "${truncate_ioc_name}" "true" "Crash detection: truncated log scans new fatal content"
    else
        _log "WARN" "truncate not found, skipping truncated log crash detection test."
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
        "test_start"
        "test_status"
        "test_view"
        "test_inspect"
        "test_inspect_bounded_runtime"
        "test_restart"
        "test_stop"
        "test_socket_list"
        "test_list_options"
        "test_console_attach"
        "test_channel_access"
        "test_monitor_isolation"
        "test_crash_detection"
        "test_persistence"
        "test_remove"
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
