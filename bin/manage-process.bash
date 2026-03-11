#!/usr/bin/env bash
#
# A front-end CLI manager for EPICS IOCs.
# Supports both system-wide deployment and local user-level testing.

set -e

declare -g EXEC_MODE="system"
declare -g CONF_DIR="/etc/procServ.d"
declare -g SYSTEM_SYSTEMD_DIR="/etc/systemd/system"
declare -g LOCAL_SYSTEMD_DIR="${HOME}/.config/systemd/user"
declare -g GENERATOR_EXEC="/usr/lib/systemd/system-generators/epics-ioc-generator"
declare -g CON_TOOL=""
declare -g -a SYSTEMCTL_CMD=(sudo /bin/systemctl)

function set_local_mode {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    EXEC_MODE="local"
    CONF_DIR="${HOME}/.config/procServ.d"
    SYSTEMCTL_CMD=(/bin/systemctl --user)
    GENERATOR_EXEC="${script_dir}/epics-ioc-generator.bash"
}

function print_usage {
    printf "%s\n" "Usage: $0 [--local] {install|remove|start|stop|restart|status|attach|list|view|enable|disable} [ioc_conf_or_name]"
}

if [[ -x "/usr/local/bin/con" ]]; then
    CON_TOOL="/usr/local/bin/con"
elif [[ -x "/usr/bin/con" ]]; then
    CON_TOOL="/usr/bin/con"
else
    printf "%s\n" "Error: con utility not found in /usr/local/bin or /usr/bin." >&2
    printf "%s\n" "Please install con before managing EPICS IOCs." >&2
    exit 1
fi

if [[ "$1" == "--local" ]]; then
    set_local_mode
    shift
fi

if [[ $# -lt 1 ]]; then
    print_usage
    exit 1
fi

declare -g COMMAND_ACTION="$1"
shift

declare -g TARGET_ARG="$1"
declare -g IOC_NAME=""

if [[ -n "${TARGET_ARG}" ]]; then
    IOC_NAME=$(basename "${TARGET_ARG}" .conf)
fi

function do_install {
    local source_conf="${TARGET_ARG}"
    if [[ ! -f "${source_conf}" ]]; then
        printf "Error: Configuration file %s not found.\n" "${source_conf}" >&2
        exit 1
    fi

    local state
    state=$("${SYSTEMCTL_CMD[@]}" is-active "epics-${IOC_NAME}.service" 2>/dev/null || true)

    if [[ "${state}" == "active" ]]; then
        printf "%s\n" "================================================================================" >&2
        printf "WARNING: Installation aborted.\n" >&2
        printf "IOC '%s' is currently running.\n" "${IOC_NAME}" >&2
        printf "Please stop the service explicitly before reinstalling to prevent data loss.\n" >&2
        printf "%s\n" "================================================================================" >&2
        exit 1
    fi

    mkdir -p "${CONF_DIR}"
    
    export CONF_DIR="${CONF_DIR}"
    export EXEC_MODE="${EXEC_MODE}"

    if [[ "${EXEC_MODE}" == "system" ]]; then
        sudo cp "${source_conf}" "${CONF_DIR}/"
        sudo -E bash "${GENERATOR_EXEC}" "${SYSTEM_SYSTEMD_DIR}"
    else
        cp "${source_conf}" "${CONF_DIR}/"
        mkdir -p "${LOCAL_SYSTEMD_DIR}"
        bash "${GENERATOR_EXEC}" "${LOCAL_SYSTEMD_DIR}"
    fi      

    "${SYSTEMCTL_CMD[@]}" daemon-reload || exit

    printf "IOC %s installed in %s mode. Use 'start' command to run it.\n" "${IOC_NAME}" "${EXEC_MODE}"
}

function do_remove {
    local target_conf="${CONF_DIR}/${IOC_NAME}.conf"

    "${SYSTEMCTL_CMD[@]}" stop "epics-${IOC_NAME}.service" 2>/dev/null || true
    "${SYSTEMCTL_CMD[@]}" disable "epics-${IOC_NAME}.service" 2>/dev/null || true

    if [[ "${EXEC_MODE}" == "system" ]]; then
        sudo rm -f "${target_conf}" || true
        sudo rm -f "${SYSTEM_SYSTEMD_DIR}/epics-${IOC_NAME}.service" || true
    else
        rm -f "${target_conf}" || true
        rm -f "${LOCAL_SYSTEMD_DIR}/epics-${IOC_NAME}.service" || true
    fi

    "${SYSTEMCTL_CMD[@]}" daemon-reload || exit
    printf "IOC %s removed.\n" "${IOC_NAME}"
}

function do_attach {
    local target_conf="${CONF_DIR}/${IOC_NAME}.conf"

    if [[ ! -f "${target_conf}" ]]; then
        printf "Error: Configuration for %s not found.\n" "${IOC_NAME}" >&2
        exit 1
    fi

    source "${target_conf}"
    local sock_path="${IOC_PORT##*:}"

    printf "%s\n" "========================================================"
    printf "Attaching to %s via UNIX domain socket:\n" "${IOC_NAME}"
    printf "Path: %s\n" "${sock_path}"
    printf "Use Ctrl-A to exit the console.\n"
    printf "%s\n" "========================================================"

    exec "${CON_TOOL}" -c "${sock_path}" || exit
}

function do_list {
    local run_dir
    if [[ "${EXEC_MODE}" == "local" ]]; then
        run_dir="/run/user/$(id -u)/procserv"
    else
        run_dir="/run/procserv"
    fi

    if [[ ! -d "${run_dir}" ]]; then
        printf "No active IOC sockets found in %s\n" "${run_dir}"
        return 0
    fi

    local sockets=()
    while IFS= read -r -d '' sock; do
        sockets+=("$sock")
    done < <(find "${run_dir}" -type s -print0 2>/dev/null)

    if [[ ${#sockets[@]} -eq 0 ]]; then
        printf "No active IOC sockets found in %s\n" "${run_dir}"
        return 0
    fi

    printf "%s\n" "================================================================================"
    printf "%-30s | %s\n" "IOC NAME" "UDS PATH"
    printf "%s\n" "--------------------------------------------------------------------------------"

    local sock ioc_name
    for sock in "${sockets[@]}"; do
        ioc_name=$(basename "$(dirname "${sock}")")
        printf "%-30s | %s\n" "${ioc_name}" "${sock}"
    done
    printf "%s\n" "================================================================================"
}

case "${COMMAND_ACTION}" in
    install)
        do_install
        ;;
    remove)
        do_remove
        ;;
    attach)
        do_attach
        ;;
    list)
        do_list
        ;;
    view)
        "${SYSTEMCTL_CMD[@]}" cat "epics-${IOC_NAME}.service" || exit
        ;;
    start|stop|restart|status|enable|disable)
        "${SYSTEMCTL_CMD[@]}" "${COMMAND_ACTION}" "epics-${IOC_NAME}.service" || exit
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
