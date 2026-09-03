#!/usr/bin/env bash
# Prepare the privileged filesystem boundary for the unprivileged local suite.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
unset BASH_ENV ENV CDPATH
umask 077

if [[ $# -ne 1 || ( "$1" != "source" && "$1" != "installed" ) ]]; then
    printf 'Usage: %s <source|installed>\n' "$0" >&2
    exit 1
fi

readonly RUNNER_MODE="$1"
MOUNT_DIR=""

for required_command in sudo mount umount install mktemp id rmdir; do
    command -v "${required_command}" >/dev/null 2>&1 || {
        printf 'Missing required command: %s\n' "${required_command}" >&2
        exit 1
    }
done

function cleanup_fixture {
    local cleanup_rc=0

    if [[ -n "${MOUNT_DIR}" ]]; then
        sudo -n umount -- "${MOUNT_DIR}" >/dev/null 2>&1 || cleanup_rc=1
        rmdir -- "${MOUNT_DIR}" >/dev/null 2>&1 || cleanup_rc=1
    fi
    return "${cleanup_rc}"
}

trap cleanup_fixture EXIT
trap 'exit 1' HUP INT TERM

MOUNT_DIR=$(mktemp -d /tmp/ioc-runner-m10-local.XXXXXX)
sudo -n mount -t tmpfs -o nodev,nosuid,noexec,size=4m tmpfs "${MOUNT_DIR}"
sudo -n install -d -o "$(id -u)" -g "$(id -g)" -m 0700 "${MOUNT_DIR}/data"

IOC_RUNNER_M10_LOG_FIXTURE="${MOUNT_DIR}/data" \
IOC_RUNNER_TEST_MODE="${RUNNER_MODE}" \
REPORT_MACHINE_OUTPUT=1 \
bash tests/test-local-lifecycle.bash
