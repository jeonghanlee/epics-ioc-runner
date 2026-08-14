#!/bin/bash -p
# Runs the shipped full setup against isolated filesystem targets.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
umask 077
unset BASH_ENV ENV CDPATH GIT_DIR GIT_WORK_TREE

function die {
    printf "ERROR: %s\n" "$1" >&2
    exit 2
}

if [[ $# -ne 4 ]]; then
    die "usage: setup-type-isolation.bash REPO_TOP WORK_DIR MODE INVOKING_USER"
fi

readonly REPO_TOP="$1"
readonly WORK_DIR="$2"
readonly FIXTURE_MODE="$3"
readonly INVOKING_USER="$4"
readonly SETUP_SCRIPT="${REPO_TOP}/bin/setup-system-infra.bash"

if [[ ${EUID} -ne 0 ]]; then
    die "root execution is required"
fi
if [[ "${REPO_TOP}" != /* || ! -f "${SETUP_SCRIPT}" || ! -r "${SETUP_SCRIPT}" || -L "${SETUP_SCRIPT}" ]]; then
    die "the repository setup script is not a readable regular path"
fi
case "${WORK_DIR}" in
    /tmp/ioc-runner-setup-type.*/*) ;;
    *) die "the work directory is outside the source-regression workspace" ;;
esac
if [[ ! -d "${WORK_DIR%/*}" || -L "${WORK_DIR%/*}" || -e "${WORK_DIR}" ]]; then
    die "the work directory parent is invalid or the target already exists"
fi
if [[ "$(stat -c '%U:%G:%a' "${WORK_DIR%/*}")" != "root:root:700" ]]; then
    die "the work directory parent must be root-owned with mode 0700"
fi
if ! id -u "${INVOKING_USER}" >/dev/null 2>&1; then
    die "the invoking user is not resolvable"
fi
case "${FIXTURE_MODE}" in
    impostor|valid) ;;
    *) die "fixture mode must be impostor or valid" ;;
esac
if [[ /proc/self/ns/mnt -ef /proc/1/ns/mnt ]]; then
    die "a separate mount namespace is required"
fi
if [[ "$(findmnt -n -o PROPAGATION /)" != "private" ]]; then
    die "private mount propagation is required"
fi

readonly CONF_MOUNT="${WORK_DIR}/mounts/procServ.d"
readonly SUDOERS_MOUNT="${WORK_DIR}/mounts/sudoers.d"
readonly SYSTEMD_MOUNT="${WORK_DIR}/mounts/systemd"
readonly LOGROTATE_MOUNT="${WORK_DIR}/mounts/logrotate.d"
readonly TARGET_DIR="${WORK_DIR}/targets"
readonly FAKE_DIR="${WORK_DIR}/outer-boundaries"
readonly RUNNER_DEST="${TARGET_DIR}/ioc-runner"
readonly COMPLETION_DEST="${TARGET_DIR}/ioc-runner-completion"
readonly LOG_DIR="${TARGET_DIR}/procserv-log"
readonly BACKUP_DIR="${TARGET_DIR}/backups"
readonly RUNNER_SYMLINK="${TARGET_DIR}/ioc-runner-symlink"
readonly FAKE_PROCSERV="${FAKE_DIR}/procServ"
readonly FAKE_SYSTEMCTL="${FAKE_DIR}/systemctl"

for target in /etc/procServ.d /etc/sudoers.d /etc/systemd/system /etc/logrotate.d; do
    if [[ ! -d "${target}" || -L "${target}" ]]; then
        die "required mount target is not a real directory: ${target}"
    fi
done

systemctl_target=$(readlink -f /usr/bin/systemctl)
readonly systemctl_target
if [[ -z "${systemctl_target}" || ! -f "${systemctl_target}" || ! -x "${systemctl_target}" ]]; then
    die "the systemctl mount target is unavailable"
fi

mkdir -p "${CONF_MOUNT}" "${SUDOERS_MOUNT}" "${SYSTEMD_MOUNT}" \
    "${LOGROTATE_MOUNT}" "${TARGET_DIR}" "${FAKE_DIR}"
printf '#!/bin/sh\nexit 0\n' > "${FAKE_PROCSERV}"
printf '#!/bin/sh\nexit 0\n' > "${FAKE_SYSTEMCTL}"
chmod 0755 "${FAKE_PROCSERV}" "${FAKE_SYSTEMCTL}"

if [[ "${FIXTURE_MODE}" == "impostor" ]]; then
    mkdir "${SUDOERS_MOUNT}/10-epics-ioc"
    mkdir "${SYSTEMD_MOUNT}/epics-@.service"
    mkdir "${LOGROTATE_MOUNT}/procserv"
    mkdir "${RUNNER_DEST}"
    mkdir "${COMPLETION_DEST}"
fi

mount --bind "${CONF_MOUNT}" /etc/procServ.d
mount --bind "${SUDOERS_MOUNT}" /etc/sudoers.d
mount --bind "${SYSTEMD_MOUNT}" /etc/systemd/system
mount --bind "${LOGROTATE_MOUNT}" /etc/logrotate.d
mount --bind "${FAKE_SYSTEMCTL}" "${systemctl_target}"

env -i \
    PATH="${PATH}" \
    SUDO_USER="${INVOKING_USER}" \
    IOC_RUNNER_PROCSERV_PATH="${FAKE_PROCSERV}" \
    IOC_RUNNER_SCRIPT_DEST="${RUNNER_DEST}" \
    IOC_RUNNER_SCRIPT_SYMLINK="${RUNNER_SYMLINK}" \
    IOC_RUNNER_BASH_COMP_DEST="${COMPLETION_DEST}" \
    IOC_RUNNER_BACKUP_DIR="${BACKUP_DIR}" \
    IOC_RUNNER_SYSTEM_LOG_DIR="${LOG_DIR}" \
    /bin/bash -p "${SETUP_SCRIPT}" --full
