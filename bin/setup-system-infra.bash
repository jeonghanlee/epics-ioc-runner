#!/usr/bin/env bash
#
# Automated system infrastructure setup for EPICS IOC Runner.
# Deploys service accounts, shared directories, sudoers policies, systemd templates,
# and the CLI wrapper script.
# Includes security hardening: sudoers validation, strict ACLs, and isolated accounts.
# Must be executed with root privileges.

set -e

declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g BLUE='\033[0;34m'
declare -g NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    printf "${RED}%s${NC}\n" "Error: This script must be run as root (or via sudo)." >&2
    exit 1
fi

declare -g SYSTEM_USER="ioc-srv"
declare -g SYSTEM_GROUP="ioc"
declare -g CONF_DIR="/etc/procServ.d"
declare -g SUDOERS_FILE="/etc/sudoers.d/10-epics-ioc"
declare -g SYSTEMD_TEMPLATE="/etc/systemd/system/epics-@.service"
declare -g BACKUP_DIR="/var/backups/epics-ioc-runner"

declare -g -a PROCSERV_SEARCH_PATHS=("/usr/local/bin/procServ" "/usr/bin/procServ")
declare -g RESOLVED_PROCSERV_BIN=""

declare -g SC_RPATH="$(realpath "$0")"
declare -g SC_DIR="${SC_RPATH%/*}"
declare -g RUNNER_SCRIPT_SRC="${SC_DIR}/ioc-runner"
declare -g RUNNER_SCRIPT_DEST="/usr/local/bin/ioc-runner"

function _log {
    local level="$1"
    local message="$2"
    local color="$NC"

    case "$level" in
        "INFO")    color="$BLUE" ;;
        "SUCCESS") color="$GREEN" ;;
        "ERROR")   color="$RED" ;;
    esac

    printf "${color}[%-7s] %s${NC}\n" "$level" "$message"
}

function print_divider {
    printf "${BLUE}%s${NC}\n" "===================================================================================================="
}

function print_sub_divider {
    printf "${BLUE}%s${NC}\n" "----------------------------------------------------------------------------------------------------"
}

function backup_if_exists {
    local target_file="$1"

    if [[ -f "${target_file}" ]]; then
        if [[ ! -d "${BACKUP_DIR}" ]]; then
            mkdir -p "${BACKUP_DIR}"
            chmod 0700 "${BACKUP_DIR}"
        fi

        local base_name
        base_name=$(basename "${target_file}")

        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)

        local backup_file="${BACKUP_DIR}/${base_name}.${timestamp}.bak"

        cp -a "${target_file}" "${backup_file}"
        _log "INFO" "Created backup of ${base_name} in ${BACKUP_DIR}"

        local backups
        mapfile -t backups < <(ls -t "${BACKUP_DIR}/${base_name}".*.bak 2>/dev/null || true)

        if [[ ${#backups[@]} -gt 3 ]]; then
            local i
            for ((i=3; i<${#backups[@]}; i++)); do
                rm -f "${backups[i]}"
            done
        fi
    fi
}

print_divider
_log "INFO" "STEP 1: Account and Group Setup (Hardened)"
print_sub_divider

if ! getent group "${SYSTEM_GROUP}" >/dev/null; then
    groupadd "${SYSTEM_GROUP}"
    _log "SUCCESS" "Created group: ${SYSTEM_GROUP}"
else
    _log "INFO" "Group ${SYSTEM_GROUP} already exists."
fi

if ! id -u "${SYSTEM_USER}" >/dev/null 2>&1; then
    useradd -r -M -d /nonexistent -g "${SYSTEM_GROUP}" -s /sbin/nologin -c "EPICS procServ Daemon Account" "${SYSTEM_USER}"
    _log "SUCCESS" "Created isolated system user: ${SYSTEM_USER}"
else
    _log "INFO" "System user ${SYSTEM_USER} already exists."
fi

print_divider
_log "INFO" "STEP 2: Shared Configuration Directory Setup (Strict ACL)"
print_sub_divider

mkdir -p "${CONF_DIR}"
chown root:"${SYSTEM_GROUP}" "${CONF_DIR}"
chmod 2770 "${CONF_DIR}"
_log "SUCCESS" "Configured directory: ${CONF_DIR} (root:${SYSTEM_GROUP}, 2770)"

print_divider
_log "INFO" "STEP 3: Sudoers Configuration (Validated & Restricted)"
print_sub_divider

declare tmp_sudoers
tmp_sudoers=$(mktemp)

cat <<EOF > "${tmp_sudoers}"
# /etc/sudoers.d/10-epics-ioc

# Allow trained engineers to manage ONLY EPICS template services
%${SYSTEM_GROUP} ALL=(root) NOPASSWD: /bin/systemctl start epics-@*.service, \\
                          /bin/systemctl stop epics-@*.service, \\
                          /bin/systemctl restart epics-@*.service, \\
                          /bin/systemctl status epics-@*.service, \\
                          /bin/systemctl enable epics-@*.service, \\
                          /bin/systemctl disable epics-@*.service, \\
                          /bin/systemctl daemon-reload
EOF

if visudo -cf "${tmp_sudoers}" >/dev/null 2>&1; then
    chmod 0440 "${tmp_sudoers}"
    backup_if_exists "${SUDOERS_FILE}"
    mv "${tmp_sudoers}" "${SUDOERS_FILE}"
    _log "SUCCESS" "Validated and deployed sudoers policy to ${SUDOERS_FILE}"
else
    _log "ERROR" "Sudoers syntax validation failed. Aborting to prevent system lockout."
    rm -f "${tmp_sudoers}"
    exit 1
fi

print_divider
_log "INFO" "STEP 4: Systemd Template Unit Deployment"
print_sub_divider

declare p_path
for p_path in "${PROCSERV_SEARCH_PATHS[@]}"; do
    if [[ -x "${p_path}" ]]; then
        RESOLVED_PROCSERV_BIN="${p_path}"
        break
    fi
done

if [[ -z "${RESOLVED_PROCSERV_BIN}" ]]; then
    _log "ERROR" "procServ executable not found in standard paths."
    exit 1
fi

backup_if_exists "${SYSTEMD_TEMPLATE}"

cat <<EOF > "${SYSTEMD_TEMPLATE}"
[Unit]
Description=procServ for %i
After=network.target remote-fs.target
AssertFileNotEmpty=${CONF_DIR}/%i.conf

[Service]
Type=simple
User=${SYSTEM_USER}
Group=${SYSTEM_GROUP}
EnvironmentFile=${CONF_DIR}/%i.conf
RuntimeDirectory=procserv/%i
ExecStart=${RESOLVED_PROCSERV_BIN} --foreground --logfile=- --name=%i --ignore=^D^C^] --chdir=\${IOC_CHDIR} --port=\${IOC_PORT} \${IOC_CMD}
StandardOutput=syslog
StandardError=inherit
SyslogIdentifier=epics-%i

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 "${SYSTEMD_TEMPLATE}"
_log "SUCCESS" "Deployed systemd template to ${SYSTEMD_TEMPLATE} using ${RESOLVED_PROCSERV_BIN}"

systemctl daemon-reload
_log "SUCCESS" "Reloaded systemd daemon."

print_divider
_log "INFO" "STEP 5: CLI Wrapper Deployment"
print_sub_divider

if [[ -f "${RUNNER_SCRIPT_SRC}" ]]; then
    backup_if_exists "${RUNNER_SCRIPT_DEST}"
    cp "${RUNNER_SCRIPT_SRC}" "${RUNNER_SCRIPT_DEST}"
    chmod 0755 "${RUNNER_SCRIPT_DEST}"
    _log "SUCCESS" "Deployed ioc-runner to ${RUNNER_SCRIPT_DEST} (0755)"
else
    _log "ERROR" "Could not find ${RUNNER_SCRIPT_SRC}."
    _log "ERROR" "Please ensure you are running this script from the repository's bin/ directory."
    exit 1
fi

print_divider
printf "${GREEN}%s${NC}\n" "[SUCCESS] Secure system infrastructure setup completed perfectly!"
printf "%s\n" "Please remember to add authorized engineers to the '${SYSTEM_GROUP}' group:"
printf "%s\n" "  sudo usermod -aG ${SYSTEM_GROUP} <username>"
print_divider
