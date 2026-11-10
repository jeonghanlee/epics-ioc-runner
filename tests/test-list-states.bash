#!/bin/bash -p
# Native list-state checks on a prepared systemd host. The Python driver emits
# check events; the shared reporter owns all result counts and projections.
set -euo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
umask 077
unset BASH_ENV ENV CDPATH PYTHONPATH PYTHONHOME

if [[ $- != *p* ]]; then
    printf 'Error: invoke this test with bash -p.\n' >&2
    exit 1
fi

declare -g TEST_DIR="${BASH_SOURCE[0]%/*}"
declare -g TEST_SCOPE="system" TEST_USER="root"
declare -g TEST_RUNNER="${IOC_RUNNER_TEST_MODE:-source}"
declare -g REPORT_READY=0 WORKSPACE="" DRIVER_STATUS=0 DRIVER_PID=""
declare -g -a DRIVER_ARGS=()

while (( $# )); do
    case "$1" in
        --system) TEST_SCOPE=system; TEST_USER=root ;;
        --local-user)
            (( $# >= 2 )) || { printf 'Error: --local-user needs an account.\n' >&2; exit 1; }
            TEST_SCOPE=local; TEST_USER="$2"; shift ;;
        --help)
            printf 'Usage: bash -p tests/test-list-states.bash [--system | --local-user ACCOUNT]\n'
            printf 'Requires a prepared host, root, EPICS_BASE, Python 3, strace, socat and network namespaces.\n'
            exit 0 ;;
        *) printf 'Error: unknown argument: %s\n' "$1" >&2; exit 1 ;;
    esac
    shift
done
case "${TEST_RUNNER}" in
    source|installed) ;;
    *) printf 'Error: IOC_RUNNER_TEST_MODE must be source or installed.\n' >&2; exit 1 ;;
esac

# shellcheck source=lib/test-reporting.bash
source "${TEST_DIR}/lib/test-reporting.bash"
declare -ga LIST_CHECKS=(
    'P00|root|REQUIRED|direct-inspection'
    'P00|tools|REQUIRED|direct-inspection'
    'P00|prepared-host|REQUIRED|direct-inspection'
    'P00|network-namespace|REQUIRED|direct-inspection'
    'S01|native-ioc-started|BEHAVIOR|real-path'
    'S02|inactive-job-visible|BEHAVIOR|real-path'
    'S03|dbus-unavailable-values|BEHAVIOR|real-path'
    'S03|unavailable-values-render-na|BEHAVIOR|real-path'
    'S03|numeric-sentinel-input|PREREQUISITE|direct-inspection'
    'S03|numeric-sentinel-render-na|BEHAVIOR|real-path'
    'S04|bound-before-listen|BEHAVIOR|real-path'
    'S04|unconnected-rendered|BEHAVIOR|real-path'
    'S05|listener-priority|BEHAVIOR|real-path'
    'S05|connecting-rendered|BEHAVIOR|real-path'
    'S05|established-rendered|BEHAVIOR|real-path'
    'S05|first-nonlistener-selected|BEHAVIOR|real-path'
    'S05|native-processes-preserved|BEHAVIOR|real-path'
    'S06|established-held-thirty-seconds|BEHAVIOR|real-path'
    'S07|disconnecting-input-observed|PREREQUISITE|direct-inspection'
    'S07|disconnecting-rendered|BEHAVIOR|real-path'
    'S07|closed-connection-unknown|BEHAVIOR|real-path'
    'S08|owned-resources-cleaned|INTEGRITY|direct-inspection'
    'S08|shared-assets-preserved|INTEGRITY|direct-inspection'
)

function finish {
    local rc=$?
    trap - EXIT
    if (( REPORT_READY && ! REPORT_CATALOG_ONLY_COMPLETED )); then
        report_finalize "${rc}" || rc=1
    fi
    if [[ -n "${WORKSPACE}" ]]; then
        printf 'Evidence retained: %s\n' "${WORKSPACE}" >&2
    fi
    exit "${rc}"
}

function interrupt_driver {
    DRIVER_STATUS="$1"
    trap '' INT TERM
    if [[ -n "${DRIVER_PID}" ]]; then
        kill -TERM "${DRIVER_PID}" 2>/dev/null || true
        wait "${DRIVER_PID}" || true
    else
        exit "${DRIVER_STATUS}"
    fi
}
trap finish EXIT
trap 'interrupt_driver 130' INT
trap 'interrupt_driver 143' TERM

declare -g OS_ID="unknown" OS_VERSION="0" KEY="" VALUE=""
while IFS='=' read -r KEY VALUE; do
    VALUE="${VALUE#\"}"; VALUE="${VALUE%\"}"
    case "${KEY}" in ID) OS_ID="${VALUE}" ;; VERSION_ID) OS_VERSION="${VALUE%%.*}" ;; esac
done < /etc/os-release
declare -g LEDGER_DIR
LEDGER_DIR=$(mktemp -d /tmp/ioc-list-report.XXXXXXXX)
report_init list-states "list-states.$$.${BASHPID}" "${TEST_SCOPE}" "${TEST_RUNNER}" \
    "${OS_ID}-${OS_VERSION}" "${EPICS_HOST_ARCH:-linux-x86_64}" "${LEDGER_DIR}"
REPORT_READY=1
for KEY in P00 S01 S02 S03 S04 S05 S06 S07 S08; do
    report_register_step "${KEY}" "Native list states ${KEY}"
done
declare -g ROW="" STEP="" CHECK="" KIND="" METHOD="" STATE="" REASON=""
for ROW in "${LIST_CHECKS[@]}"; do
    IFS='|' read -r STEP CHECK KIND METHOD <<< "${ROW}"
    report_register_check "list-states.${STEP}.${CHECK}" "${STEP}" lifecycle-behavior \
        "${KIND}" "${METHOD}" "${CHECK}"
done
report_close_catalog
report_verify_catalog_counts
if (( REPORT_CATALOG_ONLY_COMPLETED )); then
    exit 0
fi

if [[ ! -x /usr/bin/python3 ]]; then
    if (( EUID == 0 )); then
        report_record list-states.P00.root PASS
    else
        report_record list-states.P00.root FAIL 'root is required for network namespace isolation'
    fi
    report_record list-states.P00.tools FAIL '/usr/bin/python3 is required'
    for ROW in "${LIST_CHECKS[@]:2}"; do
        IFS='|' read -r STEP CHECK KIND METHOD <<< "${ROW}"
        report_record "list-states.${STEP}.${CHECK}" SKIP 'requires list-states.P00.tools'
    done
    exit 1
fi

WORKSPACE=$(mktemp -d /tmp/ioc-list-states.XXXXXXXX)
DRIVER_ARGS=("${TEST_DIR}/lib/list-states-native.py" "${TEST_SCOPE}" "${TEST_USER}"
    "${TEST_RUNNER}" "${TEST_DIR}/.." "${WORKSPACE}" "${EPICS_BASE:-}" "${EPICS_HOST_ARCH:-linux-x86_64}")
/usr/bin/python3 -I -B "${DRIVER_ARGS[@]}" "${LIST_CHECKS[@]}" > "${WORKSPACE}/events.tsv" \
    2> "${WORKSPACE}/driver.stderr" &
DRIVER_PID=$!
wait "${DRIVER_PID}" || DRIVER_STATUS=$?
DRIVER_PID=""
cat "${WORKSPACE}/driver.stderr" >&2
while IFS=$'\t' read -r CHECK STATE REASON; do
    if [[ "${STATE}" == PASS ]]; then
        report_record "${CHECK}" PASS
    else
        report_record "${CHECK}" "${STATE}" "${REASON}"
    fi
done < "${WORKSPACE}/events.tsv"
exit "${DRIVER_STATUS}"
