#!/usr/bin/env bash
#
# Stages system setup sources on a root-readable local filesystem, then runs
# the privileged setup while retaining Git metadata from the invoking checkout.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
umask 077
unset BASH_ENV ENV CDPATH

declare -gr SUDO_BIN="/usr/bin/sudo"
declare -gr TAR_BIN="/usr/bin/tar"
declare -gr ROOT_BASH_BIN="/bin/bash"
declare -g SC_PATH="${BASH_SOURCE[0]}"
declare -g SC_DIR=""
declare -g env_name=""
declare -ga setup_env=()

if [[ "${SC_PATH}" != /* ]]; then
    SC_PATH="${PWD}/${SC_PATH}"
fi
SC_DIR="${SC_PATH%/*}"

for required_file in \
    "${SC_DIR}/setup-system-infra.bash" \
    "${SC_DIR}/ioc-runner" \
    "${SC_DIR}/ioc-runner-completion.bash"; do
    if [[ ! -f "${required_file}" || -L "${required_file}" ]]; then
        printf "Error: required setup source is not a regular file: %s\n" \
            "${required_file}" >&2
        exit 1
    fi
done

for required_command in "${SUDO_BIN}" "${TAR_BIN}" "${ROOT_BASH_BIN}"; do
    if [[ ! -x "${required_command}" ]]; then
        printf "Error: required command is not executable: %s\n" \
            "${required_command}" >&2
        exit 1
    fi
done

if [[ ${EUID} -eq 0 ]]; then
    printf "%s\n" \
        "Error: run this launcher as the checkout owner without sudo." >&2
    exit 1
fi

if ! "${SUDO_BIN}" -n true 2>/dev/null; then
    printf "%s\n" \
        "Error: sudo credentials are not cached; run sudo -v and retry." >&2
    exit 1
fi

# Explicitly forward only setup configuration supported by the privileged
# script. Source and metadata paths are fixed by the staging boundary below.
for env_name in \
    IOC_RUNNER_SYSTEM_USER \
    IOC_RUNNER_SYSTEM_GROUP \
    IOC_RUNNER_BACKUP_DIR \
    IOC_RUNNER_SYSTEM_LOG_DIR \
    IOC_RUNNER_PROCSERV_PATH \
    IOC_RUNNER_SCRIPT_DEST \
    IOC_RUNNER_BASH_COMP_DEST \
    IOC_RUNNER_SCRIPT_SYMLINK; do
    if [[ -v "${env_name}" ]]; then
        setup_env+=("${env_name}=${!env_name}")
    fi
done

# The root side owns the temporary directory and removes it on every exit.
# Only the three fixed setup sources are accepted from the archive stream.
# shellcheck disable=SC2016
declare -gr ROOT_STAGE_PROGRAM='set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
umask 077
unset BASH_ENV ENV CDPATH

stage_dir=""
function cleanup {
    local rc=$?
    trap - EXIT HUP INT TERM
    case "${stage_dir}" in
        /tmp/ioc-runner-system-setup.*)
            /usr/bin/rm -rf -- "${stage_dir}"
            ;;
        "")
            ;;
        *)
            printf "Error: refusing to remove unexpected staging path: %s\n" \
                "${stage_dir}" >&2
            rc=1
            ;;
    esac
    exit "${rc}"
}
function stop {
    exit 1
}
trap cleanup EXIT
trap stop HUP INT TERM

stage_dir=$(/usr/bin/mktemp -d /tmp/ioc-runner-system-setup.XXXXXX)
/usr/bin/tar --no-same-owner -C "${stage_dir}" -xf -
for source_name in setup-system-infra.bash ioc-runner ioc-runner-completion.bash; do
    source_path="${stage_dir}/${source_name}"
    if [[ ! -f "${source_path}" || -L "${source_path}" ]]; then
        printf "Error: staged setup source is not a regular file: %s\n" \
            "${source_path}" >&2
        exit 1
    fi
done

export IOC_RUNNER_SCRIPT_SRC="${stage_dir}/ioc-runner"
export IOC_RUNNER_BASH_COMP_SRC="${stage_dir}/ioc-runner-completion.bash"
/bin/bash -p "${stage_dir}/setup-system-infra.bash" "$@"
'

"${TAR_BIN}" -C "${SC_DIR}" -cf - \
    setup-system-infra.bash ioc-runner ioc-runner-completion.bash \
    | "${SUDO_BIN}" -n /usr/bin/env "${setup_env[@]}" \
        "IOC_RUNNER_METADATA_DIR=${SC_DIR}" \
        "${ROOT_BASH_BIN}" -p -c "${ROOT_STAGE_PROGRAM}" \
        ioc-runner-system-setup "$@"
