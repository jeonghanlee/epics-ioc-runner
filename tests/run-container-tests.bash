#!/usr/bin/env bash
#
# Container lifecycle harness: runs tests/test-container-lifecycle.bash inside
# each systemd-less runtime image through docker. The images ship s6; this
# harness owns only the outermost boundary of the test path: mounting the
# source tree, starting s6-svscan on the scan directory as the container's
# supervisor, and collecting each run's human report and exit status.
# Deep inspect needs CAP_SYS_PTRACE inside the container, so the run adds it.

set -euo pipefail

declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g BLUE='\033[0;34m'
declare -g NC='\033[0m'

declare -g SC_TOP
SC_TOP="$(dirname "${BASH_SOURCE[0]}")"
[[ "${SC_TOP}" != /* ]] && SC_TOP="${PWD}/${SC_TOP}"
declare -g REPO_TOP="${SC_TOP%/tests}"

declare -g -a DEFAULT_IMAGES=(
    jeonghanlee/debian13-epics:latest
    jeonghanlee/rocky8-epics:latest
    jeonghanlee/rocky10-epics:latest
)
declare -g -a IMAGES=()
declare -g SCAN_DIR="${IOC_RUNNER_SCAN_DIR:-/run/s6-procserv}"
declare -g REPORT_ROOT="${IOC_RUNNER_CONTAINER_REPORT_DIR:-/tmp/ioc-runner-container-tests}"
declare -g DOCKER_BIN="${IOC_RUNNER_DOCKER_BIN:-docker}"
declare -g FAILED=0

function print_usage {
    printf "Usage: bash %s [--image <name:tag>]...\n" "$(basename "$0")"
    printf "  --image   run only this image (repeatable); default: the three EPICS images\n"
    printf "  Reports: %s/<image>.log\n" "${REPORT_ROOT}"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --image)
            [[ $# -ge 2 ]] || { print_usage >&2; exit 1; }
            IMAGES+=("$2")
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            printf "%bError: Unknown option '%s'%b\n" "${RED}" "$1" "${NC}" >&2
            exit 1
            ;;
    esac
done
if [[ ${#IMAGES[@]} -eq 0 ]]; then
    IMAGES=("${DEFAULT_IMAGES[@]}")
fi

if ! command -v "${DOCKER_BIN}" >/dev/null 2>&1; then
    printf "%bError: %s not found in PATH.%b\n" "${RED}" "${DOCKER_BIN}" "${NC}" >&2
    exit 1
fi
mkdir -p "${REPORT_ROOT}"

# The container command: start s6-svscan on the scan directory with its
# stdout on the container stdout (the IOC log destination), then run the
# suite from the mounted source tree. The suite's own exit status is the
# container's exit status.
declare -g CONTAINER_SCRIPT
printf -v CONTAINER_SCRIPT '%s' \
    "mkdir -p '${SCAN_DIR}' && s6-svscan '${SCAN_DIR}' & sleep 1; " \
    "cd /repo && env EPICS_HOST_ARCH=\"\${EPICS_HOST_ARCH:-linux-x86_64}\" bash tests/test-container-lifecycle.bash"

for image in "${IMAGES[@]}"; do
    log_file="${REPORT_ROOT}/${image//[\/:]/_}.log"
    printf "%b%s%b\n" "${BLUE}" "====================================================================================================" "${NC}"
    printf "%b[INFO   ] Container lifecycle: %s%b\n" "${BLUE}" "${image}" "${NC}"
    printf "%b[INFO   ] Report: %s%b\n" "${BLUE}" "${log_file}" "${NC}"
    status=0
    "${DOCKER_BIN}" run --rm --cap-add SYS_PTRACE \
        -v "${REPO_TOP}:/repo:ro" \
        -e IOC_RUNNER_TEST_MODE=source \
        "${image}" bash -c "${CONTAINER_SCRIPT}" > "${log_file}" 2>&1 || status=$?
    if (( status == 0 )); then
        printf "%b[SUCCESS] %s: suite PASS%b\n" "${GREEN}" "${image}" "${NC}"
    else
        FAILED=1
        printf "%b[ERROR  ] %s: suite exit %s (see %s)%b\n" "${RED}" "${image}" "${status}" "${log_file}" "${NC}"
    fi
done

if (( FAILED )); then
    exit 1
fi
printf "%b%s%b\n" "${GREEN}" "ALL CONTAINER LIFECYCLE RUNS PASSED." "${NC}"
