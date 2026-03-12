#!/usr/bin/env bash
#
# A front-end CLI manager for EPICS IOCs.
# Utilizes systemd template units (@.service) for zero-dependency management.
# Supports both system-wide deployment and local user-level testing.

set -e

# --- Configuration Directories ---
declare -g SYSTEM_CONF_DIR="/etc/procServ.d"
declare -g LOCAL_CONF_DIR="${HOME}/.config/procServ.d"

declare -g SYSTEM_SYSTEMD_DIR="/etc/systemd/system"
declare -g LOCAL_SYSTEMD_DIR="${HOME}/.config/systemd/user"

declare -g SYSTEM_RUN_DIR="/run/procserv"
declare -g LOCAL_RUN_DIR="/run/user/$(id -u)/procserv"

# --- Base Commands ---
declare -g SYSTEMCTL_BIN="/bin/systemctl"

# --- Active State Variables ---
declare -g EXEC_MODE="system"
declare -g CONF_DIR="${SYSTEM_CONF_DIR}"
declare -g SYSTEMD_DIR="${SYSTEM_SYSTEMD_DIR}"
declare -g RUN_DIR="${SYSTEM_RUN_DIR}"
declare -g CON_TOOL=""

function set_local_mode {
    EXEC_MODE="local"
    CONF_DIR="${LOCAL_CONF_DIR}"
    SYSTEMD_DIR="${LOCAL_SYSTEMD_DIR}"
    RUN_DIR="${LOCAL_RUN_DIR}"
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

function run_systemctl {
    local action="$1"
    shift

    if [[ "${EXEC_MODE}" == "local" ]]; then
        "${SYSTEMCTL_BIN}" --user "${action}" "$@"
    else
        case "${action}" in
            is-active|status|cat|show)
                "${SYSTEMCTL_BIN}" "${action}" "$@"
                ;;
            *)
                if [[ $EUID -eq 0 ]]; then
                    "${SYSTEMCTL_BIN}" "${action}" "$@"
                else
                    sudo "${SYSTEMCTL_BIN}" "${action}" "$@"
                fi
                ;;
        esac
    fi
}

function do_install {
    local source_conf="${TARGET_ARG}"
    if [[ ! -f "${source_conf}" ]]; then
        printf "Error: Configuration file %s not found.\n" "${source_conf}" >&2
        exit 1
    fi

    local template_path="${SYSTEMD_DIR}/epics-@.service"
    if [[ ! -f "${template_path}" ]]; then
        printf "Error: Systemd template %s not found.\n" "${template_path}" >&2
        printf "Please ensure the template is deployed before installing IOCs.\n" >&2
        exit 1
    fi

    local state
    state=$(run_systemctl is-active "epics-@${IOC_NAME}.service" 2>/dev/null || true)

    if [[ "${state}" == "active" ]]; then
        printf "%s\n" "================================================================================" >&2
        printf "WARNING: Installation aborted.\n" >&2
        printf "IOC '%s' is currently running.\n" "${IOC_NAME}" >&2
        printf "Please stop the service explicitly before reinstalling to prevent data loss.\n" >&2
        printf "%s\n" "================================================================================" >&2
        exit 1
    fi

    if [[ ! -d "${CONF_DIR}" ]]; then
        if [[ "${EXEC_MODE}" == "system" && $EUID -ne 0 ]]; then
            sudo mkdir -p "${CONF_DIR}"
        else
            mkdir -p "${CONF_DIR}"
        fi
    fi

    if [[ "${EXEC_MODE}" == "system" && ! -w "${CONF_DIR}" ]]; then
        sudo cp "${source_conf}" "${CONF_DIR}/"
    else
        cp "${source_conf}" "${CONF_DIR}/"
    fi

    run_systemctl daemon-reload || exit

    printf "IOC %s installed in %s mode. Use 'start' command to run it.\n" "${IOC_NAME}" "${EXEC_MODE}"
}

function do_remove {
    local target_conf="${CONF_DIR}/${IOC_NAME}.conf"

    run_systemctl stop "epics-@${IOC_NAME}.service" 2>/dev/null || true
    run_systemctl disable "epics-@${IOC_NAME}.service" 2>/dev/null || true

    if [[ "${EXEC_MODE}" == "system" && ! -w "${CONF_DIR}" ]]; then
        sudo rm -f "${target_conf}" || true
    else
        rm -f "${target_conf}" || true
    fi

    run_systemctl daemon-reload || exit
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
    if [[ ! -d "${RUN_DIR}" ]]; then
        printf "No active IOC sockets found in %s\n" "${RUN_DIR}"
        return 0
    fi

    local sockets=()
    while IFS= read -r -d '' sock; do
        sockets+=("$sock")
    done < <(find "${RUN_DIR}" -type s -print0 2>/dev/null)

    if [[ ${#sockets[@]} -eq 0 ]]; then
        printf "No active IOC sockets found in %s\n" "${RUN_DIR}"
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
        run_systemctl cat "epics-@${IOC_NAME}.service" || exit
        ;;
    start|stop|restart|status|enable|disable)
        run_systemctl "${COMMAND_ACTION}" "epics-@${IOC_NAME}.service" || exit
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
