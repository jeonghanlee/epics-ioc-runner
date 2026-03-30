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

declare -g MAX_CAGET_READS=10
declare -g CAGET_INTERVAL=1

if [[ -z "${EPICS_BASE}" ]]; then
    printf "${RED}%s${NC}\n" "ERROR: The EPICS_BASE environment variable is not set." >&2
    printf "Please source your EPICS environment script and run as: bash %s\n" "$(basename "$0")" >&2
    exit 1
fi

if [[ -z "${EPICS_HOST_ARCH}" ]]; then
    export EPICS_HOST_ARCH="linux-x86_64"
fi

declare -g SC_RPATH
declare -g SC_TOP
SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"

declare -g RUNNER_SCRIPT="${SC_TOP}/../bin/ioc-runner"
declare -g CONF_DIR="/etc/procServ.d"
declare -g SYSTEMD_DIR="/etc/systemd/system"
declare -g SYSTEMD_WANTS_DIR="${SYSTEMD_DIR}/multi-user.target.wants"
declare -g RUN_DIR="/run/procserv"

declare -g IOC_REPO="https://github.com/jeonghanlee/ServiceTestIOC.git"
declare -g IOC_NAME="ServiceTestIOC-SYS"

# Global settings for system identity and workspace permissions
declare -g SYSTEM_USER="ioc-srv"
declare -g SYSTEM_GROUP="ioc"

declare -g WORKSPACE=""
declare -g IOC_DIR=""
declare -g CONF_FILE=""
declare -g UDS_PATH="${RUN_DIR}/${IOC_NAME}/control"
declare -g PERM_WORKSPACE="2770"
declare -g OWNER_WORKSPACE="root:ioc"

declare -g -a SYSTEMCTL_CMD=(systemctl)

declare -g KEEP_WORKSPACE="${KEEP_WORKSPACE:-0}"

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
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
        exit 1
    fi
}

function wait_for_state {
    local expected_state="$1"
    local max_wait="${2:-10}"
    local attempt=0
    
    while [[ ${attempt} -lt ${max_wait} ]]; do
        local current_state
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
    IOC_DIR="${WORKSPACE}/${IOC_NAME}"
    CONF_FILE="${WORKSPACE}/${IOC_NAME}.conf"

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

    if [[ ! -d "${IOC_DIR}" ]]; then
        _log "INFO" "Cloning target IOC repository..."
        git clone "${IOC_REPO}" "${IOC_DIR}"
    fi

    cd "${IOC_DIR}"
    if [[ ! -d "bin" ]]; then
        _log "INFO" "Configuring EPICS environment..."
        printf "EPICS_BASE=%s\n" "${EPICS_BASE}" > configure/RELEASE.local

        _log "INFO" "Compiling ServiceTestIOC..."
        make > build.log 2>&1 || { _log "ERROR" "Compilation failed. Check build.log"; exit 1; }
        _log "SUCCESS" "Compilation completed."
    else
        _log "INFO" "Binaries found. Skipping compilation."
    fi

    chmod +x cmd/st.cmd

    _log "INFO" "Generating Configuration File in workspace..."
    cat <<EOF > "${CONF_FILE}"
IOC_NAME="${IOC_NAME}"
IOC_USER="${SYSTEM_USER}"
IOC_GROUP="${SYSTEM_GROUP}"
IOC_CHDIR="${IOC_DIR}"
IOC_PORT=""
IOC_CMD="./cmd/st.cmd"
EOF
    _log "SUCCESS" "Configuration generated at ${CONF_FILE}"
}

function test_install {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Test Install Command"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" -f install "${CONF_FILE}" >/dev/null

    local conf_exist="false"
    if [[ -f "${CONF_DIR}/${IOC_NAME}.conf" ]]; then conf_exist="true"; fi

    verify_state "true" "${conf_exist}" "Configuration file deployed to system procServ.d"

    local injected_port=""
    if [[ "${conf_exist}" == "true" ]]; then
        injected_port=$(grep "^IOC_PORT=" "${CONF_DIR}/${IOC_NAME}.conf" | cut -d'"' -f2)
    fi
    local expected_port="unix:${SYSTEM_USER}:${SYSTEM_GROUP}:0660:${UDS_PATH}"
    verify_state "${expected_port}" "${injected_port}" "IOC_PORT auto-filled correctly for system mode"
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
    _log "INFO" "STEP ${step}: Test EPICS Channel Access (caget)"
    print_sub_divider

    local caget_cmd
    if command -v caget >/dev/null 2>&1; then
        caget_cmd="caget"
    else
        caget_cmd="${EPICS_BASE}/bin/${EPICS_HOST_ARCH}/caget"
    fi

    if [[ ! -x "${caget_cmd}" ]] && ! command -v "${caget_cmd}" >/dev/null 2>&1; then
        _log "ERROR" "caget utility not found. Cannot verify PV."
        verify_state "found" "not_found" "caget executable availability"
    fi

    local test_pv="LBNL:TESTIOC:aiExample"
    _log "INFO" "Attempting to read PV: ${test_pv} (${MAX_CAGET_READS} times)"

    local read_start_time=${SECONDS}
    local pv_val
    local pv_ok="false"
    local success_count=0
    local i

    for i in $(seq 1 "${MAX_CAGET_READS}"); do
        pv_val=$("${caget_cmd}" -w 5 -t "${test_pv}" 2>/dev/null || true)
        pv_val=$(printf "%s" "${pv_val}" | tr -d '\r')

        if [[ "${pv_val}" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            _log "SUCCESS" "Read [${i}/${MAX_CAGET_READS}] PV ${test_pv} = ${pv_val}"
            success_count=$((success_count + 1))
        elif [[ -n "${pv_val}" ]]; then
            _log "SUCCESS" "Read [${i}/${MAX_CAGET_READS}] PV ${test_pv} = ${pv_val} (Non-numeric fallback)"
            success_count=$((success_count + 1))
        else
            _log "WARN" "Read [${i}/${MAX_CAGET_READS}] Failed to read PV or empty value returned."
        fi

        if [[ ${i} -lt ${MAX_CAGET_READS} ]]; then
            sleep "${CAGET_INTERVAL}"
        fi
    done

    local elapsed=$((SECONDS - read_start_time))

    if [[ ${success_count} -eq ${MAX_CAGET_READS} ]]; then
        pv_ok="true"
    fi

    verify_state "true" "${pv_ok}" "Channel Access read ${MAX_CAGET_READS} times successfully (Read time: ${elapsed}s)"
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
    verify_infrastructure     1
    _setup_workspace          2
    cleanup_previous_state    3
    setup_environment         4
    test_install              5
    test_start                6
    test_status               7
    test_view                 8
    test_restart              9
    test_stop                 10
    test_socket_list          11
    test_console_attach       12
    test_channel_access       13
    test_persistence          14
    test_remove               15
}

run_all_tests
