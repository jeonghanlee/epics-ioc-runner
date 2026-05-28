#!/usr/bin/env bash
#
# Master script to execute all EPICS IOC runner tests.
# Supports selective execution via arguments (--local or --system).

set -e

declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g BLUE='\033[0;34m'
declare -g NC='\033[0m'

declare -g SC_RPATH
declare -g SC_TOP
SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"

declare -g RUN_LOCAL=1
declare -g RUN_SYSTEM=1

function print_divider {
    printf "${BLUE}%s${NC}\n" "===================================================================================================="
}

function _run_test {
    local test_name="$1"
    local test_cmd=("${@:2}")

    print_divider
    printf "${BLUE}[ RUN      ] %s${NC}\n" "${test_name}"
    print_divider

    "${test_cmd[@]}"

    printf "\n${GREEN}[ PASSED   ] %s${NC}\n\n" "${test_name}"
}

# --- CLI Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --local|local)
            RUN_LOCAL=1
            RUN_SYSTEM=0
            shift
            ;;
        --system|system)
            RUN_LOCAL=0
            RUN_SYSTEM=1
            shift
            ;;
        -h|--help)
            printf "Usage: bash %s [--local | --system]\n" "$(basename "$0")"
            printf "  (Running without arguments executes all test phases)\n"
            exit 0
            ;;
        *)
            printf "${RED}Error: Unknown option '%s'${NC}\n" "$1" >&2
            exit 1
            ;;
    esac
done

# Pre-flight environment check
if [[ -z "${EPICS_BASE}" ]]; then
    printf "${RED}%s${NC}\n" "ERROR: EPICS_BASE environment variable is not set." >&2
    exit 1
fi

if [[ ${RUN_SYSTEM} -eq 1 ]]; then
    # Cache sudo credentials upfront for uninterrupted system-wide execution
    printf "%s\n" "Caching sudo credentials for system infrastructure tests..."
    sudo -v
fi

# Execute tests based on selected mode.
# Phase 1 / Phase 2 exercise local mode, which routes through
# `systemctl --user` against the caller's user-mode systemd. When the
# whole suite is invoked via `sudo -E`, root's user bus is typically
# unreachable, so drop privilege back to ${SUDO_USER} for these two
# phases. The system phases below stay root because they need it.
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
        )
        _run_test "Phase 1: Error Handling" sudo -u "${SUDO_USER}" env -i "${LOCAL_PHASE_ENV[@]}" bash "${SC_TOP}/test-error-handling.bash"
        _run_test "Phase 2: Local Lifecycle" sudo -u "${SUDO_USER}" env -i "${LOCAL_PHASE_ENV[@]}" bash "${SC_TOP}/test-local-lifecycle.bash"
    else
        _run_test "Phase 1: Error Handling" bash "${SC_TOP}/test-error-handling.bash"
        _run_test "Phase 2: Local Lifecycle" bash "${SC_TOP}/test-local-lifecycle.bash"
    fi
fi

if [[ ${RUN_SYSTEM} -eq 1 ]]; then
    _run_test "Phase 3: System Infrastructure" sudo bash "${SC_TOP}/test-system-infra.bash"
    _run_test "Phase 4: System Lifecycle" sudo -E bash "${SC_TOP}/test-system-lifecycle.bash"
fi

print_divider
printf "${GREEN}%s${NC}\n" "ALL SELECTED TEST SUITES COMPLETED SUCCESSFULLY."
print_divider
