#!/usr/bin/env bash
#
# Master script to execute all EPICS IOC runner tests in the recommended sequence.

set -e

declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g BLUE='\033[0;34m'
declare -g NC='\033[0m'

declare -g SC_RPATH
declare -g SC_TOP
SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"

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

# Pre-flight environment check
if [[ -z "${EPICS_BASE}" ]]; then
    printf "${RED}%s${NC}\n" "ERROR: EPICS_BASE environment variable is not set." >&2
    exit 1
fi

# Cache sudo credentials upfront for uninterrupted execution
printf "%s\n" "Caching sudo credentials for system infrastructure tests..."
sudo -v

# Execute tests in SOP order
_run_test "Phase 1: Error Handling" bash "${SC_TOP}/test-error-handling.bash"
_run_test "Phase 2: Local Lifecycle" bash "${SC_TOP}/test-local-lifecycle.bash"
_run_test "Phase 3: System Infrastructure" sudo bash "${SC_TOP}/test-system-infra.bash"
_run_test "Phase 4: System Lifecycle" bash "${SC_TOP}/test-system-lifecycle.bash"

print_divider
printf "${GREEN}%s${NC}\n" "ALL TEST SUITES COMPLETED SUCCESSFULLY."
print_divider
