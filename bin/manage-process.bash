#!/usr/bin/env bash
#
# A front-end CLI manager for EPICS IOCs.
# Creates configurations and relies on the Systemd Generator.

set -e

declare -g CONF_DIR="/etc/procServ.d"
declare -g RUN_BASE_DIR="/run/procserv"
declare -g CON_TOOL="/usr/local/bin/con"

declare -g DEFAULT_USER="ioc-srv"
declare -g DEFAULT_GROUP="ioc"

function print_usage {
    printf "Usage: %s {add|remove|start|stop|restart|status|attach} <ioc_name> [options]\n" "$0"
    printf "\n"
    printf "Commands:\n"
    printf "  add <ioc_name> -C <chdir> -c <command> [args...]\n"
    printf "  remove <ioc_name>\n"
    printf "  start|stop|restart|status <ioc_name>\n"
    printf "  attach <ioc_name>\n"
}

function do_add {
    local ioc_name="$1"
    shift

    local ioc_chdir=""
    local ioc_cmd=""
    local ioc_user="${DEFAULT_USER}"
    local ioc_group="${DEFAULT_GROUP}"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -C|--chdir) ioc_chdir="$2"; shift 2 ;;
            -c|--command) ioc_cmd="$2"; shift 2 ;;
            -U|--user) ioc_user="$2"; shift 2 ;;
            -G|--group) ioc_group="$2"; shift 2 ;;
            *) break ;;
        esac
    done

    local ioc_args="$*"
    if [[ -n "${ioc_args}" ]]; then
        ioc_cmd="${ioc_cmd} ${ioc_args}"
    fi

    if [[ -z "${ioc_chdir}" || -z "${ioc_cmd}" ]]; then
        printf "Error: --chdir and --command are required.\n" >&2
        exit 1
    fi

    local sock_path="${RUN_BASE_DIR}/${ioc_name}/control"
    local ioc_port="unix:${ioc_user}:${ioc_group}:0660:${sock_path}"
    local conf_file="${CONF_DIR}/${ioc_name}.conf"

    printf "%s\n" "--------------------------------------------------------"
    printf "Creating configuration for IOC: %s\n" "${ioc_name}"
    printf "%s\n" "--------------------------------------------------------"

    cat <<EOF > "${conf_file}"
IOC_NAME="${ioc_name}"
IOC_USER="${ioc_user}"
IOC_GROUP="${ioc_group}"
IOC_CHDIR="${ioc_chdir}"
IOC_PORT="${ioc_port}"
IOC_CMD="${ioc_cmd}"
EOF

    printf "Configuration saved at %s\n" "${conf_file}"

    sudo /bin/systemctl daemon-reload || exit
    sudo /bin/systemctl start "procserv-${ioc_name}.service" || exit

    printf "IOC %s has been successfully added and started.\n" "${ioc_name}"
}

function do_remove {
    local ioc_name="$1"
    local conf_file="${CONF_DIR}/${ioc_name}.conf"

    printf "%s\n" "--------------------------------------------------------"
    printf "Removing IOC: %s\n" "${ioc_name}"
    printf "%s\n" "--------------------------------------------------------"

    sudo /bin/systemctl stop "procserv-${ioc_name}.service" 2>/dev/null || true
    rm -f "${conf_file}" || exit

    sudo /bin/systemctl daemon-reload || exit
    printf "IOC %s has been successfully removed.\n" "${ioc_name}"
}

function do_attach {
    local ioc_name="$1"
    local conf_file="${CONF_DIR}/${ioc_name}.conf"

    if [[ ! -f "${conf_file}" ]]; then
        printf "Error: Configuration for %s not found.\n" "${ioc_name}" >&2
        exit 1
    fi

    source "${conf_file}"
    local sock_path="${IOC_PORT##*:}"

    printf "%s\n" "========================================================"
    printf "Attaching to %s via UNIX domain socket:\n" "${ioc_name}"
    printf "Path: %s\n" "${sock_path}"
    printf "Use Ctrl-A to exit the console.\n"
    printf "%s\n" "========================================================"

    exec "${CON_TOOL}" -c "${sock_path}" || exit
}

if [[ $# -lt 1 ]]; then
    print_usage
    exit 1
fi

declare -g COMMAND_ACTION="$1"
shift

case "${COMMAND_ACTION}" in
    add)
        do_add "$@"
        ;;
    remove)
        do_remove "$1"
        ;;
    attach)
        do_attach "$1"
        ;;
    start|stop|restart|status)
        sudo /bin/systemctl "${COMMAND_ACTION}" "procserv-$1.service" || exit
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
