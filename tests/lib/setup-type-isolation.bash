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
    impostor|valid|selinux-valid|selinux-missing-restorecon|selinux-missing-matchpathcon|selinux-reject-context) ;;
    *) die "unsupported fixture mode" ;;
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
readonly FAKE_RESTORECON="${FAKE_DIR}/restorecon"
readonly FAKE_MATCHPATHCON="${FAKE_DIR}/matchpathcon"
readonly SELINUX_TOOL_LOG="${WORK_DIR}/selinux-tools.log"
readonly ORIGINAL_USR_SBIN="${WORK_DIR}/original-usr-sbin"
readonly USR_SBIN_MOUNT="${WORK_DIR}/usr-sbin"

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

case "${FIXTURE_MODE}" in
    selinux-*)
        mount -t tmpfs -o mode=0755 tmpfs /sys/fs
        mkdir -p /sys/fs/selinux
        if [[ "${FIXTURE_MODE}" == "selinux-valid" ]]; then
            printf '0\n' > /sys/fs/selinux/enforce
        else
            printf '1\n' > /sys/fs/selinux/enforce
        fi
        cat > "${FAKE_RESTORECON}" <<'EOF'
#!/bin/sh
printf 'restorecon %s\n' "$*" >> "${IOC_RUNNER_SELINUX_TOOL_LOG}"
exit 0
EOF
        cat > "${FAKE_MATCHPATHCON}" <<'EOF'
#!/bin/sh
printf 'matchpathcon %s\n' "$*" >> "${IOC_RUNNER_SELINUX_TOOL_LOG}"
exit "${IOC_RUNNER_MATCHPATHCON_RESULT:-0}"
EOF
        chmod 0755 "${FAKE_RESTORECON}" "${FAKE_MATCHPATHCON}"
        mkdir "${ORIGINAL_USR_SBIN}" "${USR_SBIN_MOUNT}"
        mount --bind /usr/sbin "${ORIGINAL_USR_SBIN}"
        cp -as "${ORIGINAL_USR_SBIN}/." "${USR_SBIN_MOUNT}"
        rm -f "${USR_SBIN_MOUNT}/restorecon" \
            "${USR_SBIN_MOUNT}/matchpathcon"
        ln -s "${FAKE_RESTORECON}" "${USR_SBIN_MOUNT}/restorecon"
        ln -s "${FAKE_MATCHPATHCON}" "${USR_SBIN_MOUNT}/matchpathcon"
        mount --bind "${USR_SBIN_MOUNT}" /usr/sbin
        ;;
esac

if [[ "${FIXTURE_MODE}" == "impostor" ]]; then
    mkdir "${SUDOERS_MOUNT}/10-epics-ioc"
    mkdir "${SYSTEMD_MOUNT}/epics-@.service"
    mkdir "${LOGROTATE_MOUNT}/procserv"
    mkdir "${RUNNER_DEST}"
    mkdir "${COMPLETION_DEST}"
fi
case "${FIXTURE_MODE}" in
    selinux-missing-restorecon|selinux-missing-matchpathcon)
        printf 'sudoers-sentinel\n' > "${SUDOERS_MOUNT}/10-epics-ioc"
        printf 'logrotate-sentinel\n' > "${LOGROTATE_MOUNT}/procserv"
        ;;
esac

mount --bind "${CONF_MOUNT}" /etc/procServ.d
mount --bind "${SUDOERS_MOUNT}" /etc/sudoers.d
mount --bind "${SYSTEMD_MOUNT}" /etc/systemd/system
mount --bind "${LOGROTATE_MOUNT}" /etc/logrotate.d
mount --bind "${FAKE_SYSTEMCTL}" "${systemctl_target}"

setup_path="${FAKE_DIR}:${PATH}"
matchpathcon_result=0
case "${FIXTURE_MODE}" in
    selinux-missing-restorecon|selinux-missing-matchpathcon)
        for required_tool in dirname rm setfacl getfacl logrotate sudo; do
            required_path=$(command -v "${required_tool}" 2>/dev/null || true)
            if [[ -z "${required_path}" || ! -x "${required_path}" ]]; then
                die "required preflight tool is unavailable: ${required_tool}"
            fi
            ln -s "${required_path}" "${FAKE_DIR}/${required_tool}"
        done
        setup_path="${FAKE_DIR}"
        ;;
esac
if [[ "${FIXTURE_MODE}" == "selinux-missing-restorecon" ]]; then
    rm -f "${FAKE_RESTORECON}"
fi
if [[ "${FIXTURE_MODE}" == "selinux-missing-matchpathcon" ]]; then
    rm -f "${FAKE_MATCHPATHCON}"
fi
if [[ "${FIXTURE_MODE}" == "selinux-reject-context" ]]; then
    matchpathcon_result=1
fi

env -i \
    PATH="${setup_path}" \
    SUDO_USER="${INVOKING_USER}" \
    IOC_RUNNER_SELINUX_TOOL_LOG="${SELINUX_TOOL_LOG}" \
    IOC_RUNNER_MATCHPATHCON_RESULT="${matchpathcon_result}" \
    IOC_RUNNER_PROCSERV_PATH="${FAKE_PROCSERV}" \
    IOC_RUNNER_SCRIPT_DEST="${RUNNER_DEST}" \
    IOC_RUNNER_SCRIPT_SYMLINK="${RUNNER_SYMLINK}" \
    IOC_RUNNER_BASH_COMP_DEST="${COMPLETION_DEST}" \
    IOC_RUNNER_BACKUP_DIR="${BACKUP_DIR}" \
    IOC_RUNNER_SYSTEM_LOG_DIR="${LOG_DIR}" \
    /bin/bash -p "${SETUP_SCRIPT}" --full
