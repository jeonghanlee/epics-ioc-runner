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
    printf "Please source your EPICS environment script before running this test.\n" >&2
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

declare -g WORKSPACE="${HOME}/ioc-test-workspace"
declare -g IOC_REPO="https://github.com/jeonghanlee/ServiceTestIOC.git"
declare -g IOC_NAME="ServiceTestIOC-SYS"
declare -g IOC_DIR="${WORKSPACE}/${IOC_NAME}"
declare -g CONF_FILE="${WORKSPACE}/${IOC_NAME}.conf"
declare -g UDS_PATH="${RUN_DIR}/${IOC_NAME}/control"

declare -g -a SYSTEMCTL_CMD=(sudo systemctl)

function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        SCRIPT_ERROR=1
        printf "\n${RED}%s${NC}\n" "[ABORT] Script terminated unexpectedly. (Exit code: ${exit_code})"
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
    printf "${BLUE}%s${NC}\n" "===================================================================================================="
    printf "${BLUE}%s${NC}\n" "                                    SYSTEM LIFECYCLE TEST SUMMARY                                   "
    printf "${BLUE}%s${NC}\n" "===================================================================================================="

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

function verify_infrastructure {
    print_divider
    _log "INFO" "STEP 0: Verify System Infrastructure"
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

function cleanup_previous_state {
    print_divider
    _log "INFO" "STEP 1: Cleanup Previous State"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" remove "${IOC_NAME}" >/dev/null 2>&1 || true
    _log "SUCCESS" "Cleaned up residual processes and configurations."
}

function setup_environment {
    print_divider
    _log "INFO" "STEP 2: Environment Setup & Compilation"
    print_sub_divider

    mkdir -p "${WORKSPACE}"

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
IOC_USER="ioc-srv"
IOC_GROUP="ioc"
IOC_CHDIR="${IOC_DIR}"
IOC_PORT="unix:ioc-srv:ioc:0660:${UDS_PATH}"
IOC_CMD="./cmd/st.cmd"
EOF
    _log "SUCCESS" "Configuration generated at ${CONF_FILE}"
}

function test_install {
    print_divider
    _log "INFO" "STEP 3: Test Install Command"
    print_sub_divider

    bash "${RUNNER_SCRIPT}" install "${CONF_FILE}"

    local conf_exist="false"
    if [[ -f "${CONF_DIR}/${IOC_NAME}.conf" ]]; then conf_exist="true"; fi

    verify_state "true" "${conf_exist}" "Configuration file deployed to system procServ.d"
}

function test_start {
    print_divider
    _log "INFO" "STEP 4: Test Start Command"
    print_sub_divider

    local start_time=${SECONDS}

    bash "${RUNNER_SCRIPT}" start "${IOC_NAME}"
    _log "INFO" "Waiting for IOC to initialize (2 seconds)..."
    sleep 2

    local state
    state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-@${IOC_NAME}.service" || true)

    local elapsed=$((SECONDS - start_time))
    verify_state "active" "${state}" "Service state is 'active' (Startup time: ${elapsed}s)"
}

function test_socket_list {
    print_divider
    _log "INFO" "STEP 5: Test List and Socket Creation"
    print_sub_divider

    local socket_exist="false"

    if [[ -S "${UDS_PATH}" ]]; then socket_exist="true"; fi
    verify_state "true" "${socket_exist}" "UNIX Domain Socket explicitly created in system directory"

    _log "INFO" "Executing list command:"
    bash "${RUNNER_SCRIPT}" list
}

function test_console_attach {
    print_divider
    _log "INFO" "STEP 5.5: Interactive Console Attach"
    print_sub_divider

    printf "${YELLOW}%s${NC}\n" ">>> The script will now attach to the system IOC console for debugging."
    printf "${YELLOW}%s${NC}\n" ">>> 1. Check if there are any iocInit errors."
    printf "${YELLOW}%s${NC}\n" ">>> 2. Press [Enter] to display the 'epics>' prompt."
    printf "${YELLOW}%s${NC}\n" ">>> 3. Press [Ctrl-A] when you are ready to resume the test."
    printf "\n"
    read -r -p "Press [Enter] to attach now..."

    bash "${RUNNER_SCRIPT}" attach "${IOC_NAME}" || true

    printf "\n"
    _log "SUCCESS" "Detached from console. Resuming tests..."
}

function test_channel_access {
    print_divider
    _log "INFO" "STEP 6: Test EPICS Channel Access (caget)"
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
    print_divider
    _log "INFO" "STEP 7: Test Enable and Disable (Persistence)"
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
    print_divider
    _log "INFO" "STEP 8: Test Remove Command"
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
    verify_infrastructure
    cleanup_previous_state
    setup_environment
    test_install
    test_start
    test_socket_list
    test_console_attach
    test_channel_access
    test_persistence
    test_remove
}

run_all_tests
