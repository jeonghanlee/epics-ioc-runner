#!/usr/bin/env bash
#
# Automated lifecycle test for EPICS system-wide IOC management.
# This script uses the actual ServiceTestIOC repository to verify
# the install, start, view, list, enable, disable, and remove workflows.
# It validates the systemd template unit (@.service) architecture at the system level.

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

declare -g CAMONITOR_COUNT=5
declare -g CAMONITOR_TIMEOUT=10

if [[ -z "${EPICS_BASE}" ]]; then
    printf "${RED}%s${NC}\n" "ERROR: The EPICS_BASE environment variable is not set." >&2
    printf "Please source your EPICS environment script and run as: bash %s\n" "$(basename "$0")" >&2
    exit 1
fi

if [[ -z "${EPICS_HOST_ARCH}" ]]; then
    export EPICS_HOST_ARCH="linux-x86_64"
fi

# System Requirement: System-wide operations and Netlink socket diagnostics require root privileges.
if [[ "${EUID}" -ne 0 ]]; then
    printf "${RED}%s${NC}\n" "ERROR: System lifecycle tests require root privileges." >&2
    printf "Please run this script with sudo: sudo bash %s\n" "$(basename "$0")" >&2
    exit 1
fi

declare -g SC_TOP
# Capture an absolute SC_TOP without readlink/realpath/cd-pwd; later
# steps cd into a workspace, so a relative path would fail to resolve
# back to the source tree. ${PWD} reflects the invoker's CWD at script
# start, set by the kernel and not subject to NFS root_squash.
SC_TOP="$(dirname "${BASH_SOURCE[0]}")"
[[ "${SC_TOP}" != /* ]] && SC_TOP="${PWD}/${SC_TOP}"

declare -g RUNNER_SCRIPT="${SC_TOP}/../bin/ioc-runner"
declare -g CONF_DIR="/etc/procServ.d"
declare -g SYSTEMD_DIR="/etc/systemd/system"
declare -g SYSTEMD_WANTS_DIR="${SYSTEMD_DIR}/multi-user.target.wants"
declare -g RUN_DIR="/run/procserv"

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
declare -g PERM_WORKSPACE="2770"
declare -g OWNER_WORKSPACE="root:ioc"

declare -g -a SYSTEMCTL_CMD=(systemctl)

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
    printf "${BLUE}%s${NC}\n" "                                    SYSTEM LIFECYCLE TEST SUMMARY                                   "
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
    chmod +x "${BOOT_DIR}/st.cmd"

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
    output=$(bash "${RUNNER_SCRIPT}" status "${IOC_NAME}" 2>&1 || true)

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
    output=$(bash "${RUNNER_SCRIPT}" view "${IOC_NAME}" 2>&1 || true)

    local conf_in_output="false"
    if printf "%s" "${output}" | grep -q "${IOC_NAME}"; then conf_in_output="true"; fi
    verify_state "true" "${conf_in_output}" "View output contains IOC name"
}

function test_restart {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Restart Command"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" restart "${IOC_NAME}"
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

    bash "${RUNNER_SCRIPT}" stop "${IOC_NAME}"

    local state
    state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${IOC_NAME}.service" || true)
    verify_state "inactive" "${state}" "Service is inactive after stop"

    _log "INFO" "Waiting for systemd to cleanup asynchronous resources..."
    sleep 2

    bash "${RUNNER_SCRIPT}" start "${IOC_NAME}"
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

    local line pv_val i=0
    while IFS= read -r line; do
        [[ -z "${line}" ]] && continue
        i=$((i + 1))
        pv_val=$(printf "%s" "${line}" | awk '{print $NF}' | tr -d '\r')
        if [[ "${pv_val}" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            _log "SUCCESS" "Update [${i}/${CAMONITOR_COUNT}] PV ${test_pv} = ${pv_val}"
            success_count=$((success_count + 1))
        elif [[ -n "${pv_val}" ]]; then
            _log "SUCCESS" "Update [${i}/${CAMONITOR_COUNT}] PV ${test_pv} = ${pv_val} (Non-numeric)"
            success_count=$((success_count + 1))
        else
            _log "WARN" "Update [${i}/${CAMONITOR_COUNT}] Failed to read PV or empty value."
        fi
        [[ ${i} -ge ${CAMONITOR_COUNT} ]] && break
    done < <("${camonitor_cmd}" -w "${CAMONITOR_TIMEOUT}" "${test_pv}" 2>/dev/null || true)

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

    printf "test_monitor_input_blocked\\n" | setsid bash "${RUNNER_SCRIPT}" monitor "${IOC_NAME}" >/dev/null 2>&1 &
    local monitor_pid=$!
    sleep 2

    local log_out
    log_out=$(journalctl -u "epics-@${IOC_NAME}.service" --since "5 seconds ago")

    local input_blocked="true"
    if printf "%s" "${log_out}" | grep -q "test_monitor_input_blocked"; then
        input_blocked="false"
    fi

    verify_state "true" "${input_blocked}" "Input securely blocked in monitor mode"

    kill -- -"${monitor_pid}" 2>/dev/null || true
}


# test_crash_detection — disabled; blocked by #7 (v1.1.0 log file redirect).
# Requires 'adm' or 'systemd-journal' group to read the system journal under ioc-srv.
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

    local bad_ioc_name="CrashTestIOC-SYS"
    local bad_ioc_dir="${WORKSPACE}/bad_ioc"
    mkdir -p "${bad_ioc_dir}"

    cat << EOF > "${bad_ioc_dir}/st.cmd"
#!${softioc_bin}
system "sleep 0.5"
system "echo 'FATAL: Simulated softIoc crash'"
system "kill -9 \$PPID"
EOF
    chmod +x "${bad_ioc_dir}/st.cmd"

    cat << EOF > "${WORKSPACE}/${bad_ioc_name}.conf"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${bad_ioc_dir}"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF

    bash "${RUNNER_SCRIPT}" -f install "${WORKSPACE}/${bad_ioc_name}.conf" >/dev/null

    local output
    output=$(bash "${RUNNER_SCRIPT}" start "${bad_ioc_name}" 2>&1 || true)

    local warning_detected="false"
    if printf "%s" "${output}" | grep -q "Warning"; then
        warning_detected="true"
    fi

    bash "${RUNNER_SCRIPT}" remove "${bad_ioc_name}" >/dev/null 2>&1 || true

    verify_state "true" "${warning_detected}" "Crash-loop warning detected for broken softIoc"
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
#        "test_crash_detection"  # blocked by #7 (v1.1.0 log file redirect); system journal requires adm or systemd-journal group
        "test_persistence"
        "test_remove"
    )

    local step=1
    local func
    for func in "${pipeline[@]}"; do
        "${func}" "${step}"
        step=$((step + 1))
    done
}

run_all_tests

