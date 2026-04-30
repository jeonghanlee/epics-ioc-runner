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

declare -g SYSTEM_USER="ioc-srv"
declare -g SYSTEM_GROUP="ioc"
declare -g CONF_DIR="/etc/procServ.d"
declare -g SUDOERS_FILE="/etc/sudoers.d/10-epics-ioc"
declare -g SYSTEMD_TEMPLATE="/etc/systemd/system/epics-@.service"
declare -g BACKUP_DIR="/var/backups/epics-ioc-runner"

declare -g SC_DIR
SC_DIR="$(dirname "${BASH_SOURCE[0]}")"

if [[ -n "${IOC_RUNNER_PROCSERV_PATH:-}" ]]; then
    declare -g -a PROCSERV_SEARCH_PATHS=("${IOC_RUNNER_PROCSERV_PATH}")
else
    declare -g -a PROCSERV_SEARCH_PATHS=(/usr/local/bin/procServ /usr/bin/procServ)
fi
declare -g RUNNER_SCRIPT_SRC="${IOC_RUNNER_SCRIPT_SRC:-${SC_DIR}/ioc-runner}"
declare -g RUNNER_SCRIPT_DEST="${IOC_RUNNER_SCRIPT_DEST:-/usr/local/bin/ioc-runner}"
declare -g BASH_COMP_SRC="${IOC_RUNNER_BASH_COMP_SRC:-${SC_DIR}/ioc-runner-completion.bash}"
declare -g BASH_COMP_DEST="${IOC_RUNNER_BASH_COMP_DEST:-/etc/bash_completion.d/ioc-runner}"
declare -g RUNNER_SCRIPT_SYMLINK="${IOC_RUNNER_SCRIPT_SYMLINK:-/usr/bin/ioc-runner}"
declare -g OS_RELEASE_FILE="/etc/os-release"


declare -g RESOLVED_PROCSERV_BIN=""

declare -g VERIFY_PASS=0
declare -g VERIFY_FAIL=0

declare -g PERM_CONF_DIR="2770"
declare -g PERM_SUDOERS="0440"
declare -g PERM_SYSTEMD_TEMPLATE="0644"
declare -g PERM_RUNNER_SCRIPT="0755"
declare -g PERM_BASH_COMP="0644"
declare -g PERM_BACKUP_DIR="0700"
declare -g OWNER_CONF_DIR="root:${SYSTEM_GROUP}"
declare -g OWNER_SYSTEM="root:root"

# --- Base Commands & Paths ---
declare -g SYSTEMCTL_BIN="/usr/bin/systemctl"

if [[ ! -x "${SYSTEMCTL_BIN}" ]]; then
    printf "Error: %s not found or not executable. This script requires systemd.\n" "${SYSTEMCTL_BIN}" >&2
    exit 1
fi

if [[ $EUID -ne 0 ]]; then
    printf "${RED}%s${NC}\n" "Error: This script must be run as root (or via sudo)." >&2
    printf "%s\n" "Usage: sudo bash $(basename "$0")" >&2
    exit 1
fi

# --- CLI Argument Parsing ---
declare -g FULL_SETUP_MODE=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --full)
            FULL_SETUP_MODE=1
            shift
            ;;
        -h|--help)
            printf "Usage: sudo bash %s [--full]\n" "$(basename "$0")"
            printf "  (Running without arguments safely updates the CLI wrapper only)\n"
            exit 0
            ;;
        *)
            printf "Error: Unknown option '%s'\n" "$1" >&2
            exit 1
            ;;
    esac
done

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

function is_rhel_family {
    [[ -f "${OS_RELEASE_FILE}" ]] || return 1

    # Execute in subshell so sourced variables do not leak to caller
    (
        . "${OS_RELEASE_FILE}"
        [[ "${ID:-}" == "rhel" ]] && exit 0
        case " ${ID_LIKE:-} " in
            *" rhel "*) exit 0 ;;
        esac
        exit 1
    )
}

function verify_path {
    local path="$1"
    local expected_owner="$2"
    local expected_perm="$3"
    local success_message="$4"

    local actual_owner
    local actual_perm

    actual_owner=$(stat -c "%U:%G" "${path}")
    actual_perm=$(stat -c "%a" "${path}")

    # Normalize to 4-digit octal for comparison
    expected_perm=$(printf "%04o" "0${expected_perm}")
    actual_perm=$(printf "%04o" "0${actual_perm}")

    if [[ "${actual_owner}" != "${expected_owner}" || "${actual_perm}" != "${expected_perm}" ]]; then
        _log "ERROR" "Verify FAILED : ${path} (owner: ${actual_owner}, perm: ${actual_perm})"
        (( VERIFY_FAIL++ )) || true
        return
    fi

    _log "SUCCESS" "Verify PASSED : ${path} (${actual_owner}, ${actual_perm})"
    (( VERIFY_PASS++ )) || true
    if [[ -n "${success_message}" ]]; then
        _log "SUCCESS" "${success_message}"
    fi
}

function verify_symlink {
    local link_path="$1"
    local expected_target="$2"
    local success_message="$3"

    if [[ ! -L "${link_path}" ]]; then
        _log "ERROR" "Verify FAILED : ${link_path} is not a symbolic link"
        (( VERIFY_FAIL++ )) || true
        return
    fi

    local actual_target
    actual_target=$(readlink "${link_path}")

    if [[ "${actual_target}" != "${expected_target}" ]]; then
        _log "ERROR" "Verify FAILED : ${link_path} -> ${actual_target} (expected ${expected_target})"
        (( VERIFY_FAIL++ )) || true
        return
    fi

    _log "SUCCESS" "Verify PASSED : ${link_path} -> ${actual_target}"
    (( VERIFY_PASS++ )) || true
    if [[ -n "${success_message}" ]]; then
        _log "SUCCESS" "${success_message}"
    fi
}

function verify_sudoers_includedir_order {
    local sudoers_file="$1"
    local idr_line
    local trailing

    if [[ ! -f "${sudoers_file}" ]]; then
        _log "ERROR" "Verify FAILED : ${sudoers_file} not found"
        (( VERIFY_FAIL++ )) || true
        return
    fi

    idr_line=$(grep -nE '^[[:space:]]*[#@]includedir[[:space:]]+/etc/sudoers\.d' "${sudoers_file}" | tail -1 | cut -d: -f1)

    if [[ -z "${idr_line}" ]]; then
        _log "ERROR" "Verify FAILED : no includedir /etc/sudoers.d directive in ${sudoers_file}"
        (( VERIFY_FAIL++ )) || true
        return
    fi

    trailing=$(tail -n +$((idr_line + 1)) "${sudoers_file}" | grep -E '^[[:space:]]*([^#[:space:]]|[#@]include)' || true)

    if [[ -n "${trailing}" ]]; then
        _log "ERROR" "Verify FAILED : active rules follow includedir in ${sudoers_file}"
        _log "ERROR" "The NOPASSWD policy in ${SUDOERS_FILE} will be overridden by trailing rules."
        _log "ERROR" "Fix with visudo: move the includedir directive to the END of ${sudoers_file}"
        printf "%s\n" "${trailing}" | while IFS= read -r line; do
            _log "ERROR" "  offending: ${line}"
        done
        (( VERIFY_FAIL++ )) || true
        return
    fi

    _log "SUCCESS" "Verify PASSED : includedir is the final active directive in ${sudoers_file}"
    (( VERIFY_PASS++ )) || true
}

function verify_account {
    local type="$1"
    local name="$2"

    case "${type}" in
        group)
            if getent group "${name}" >/dev/null; then
                _log "SUCCESS" "Verify PASSED : group '${name}' exists"
                (( VERIFY_PASS++ )) || true
            else
                _log "ERROR" "Verify FAILED : group '${name}' not found"
                (( VERIFY_FAIL++ )) || true
            fi
            ;;
        user)
            if id -u "${name}" >/dev/null 2>&1; then
                _log "SUCCESS" "Verify PASSED : user '${name}' exists"
                (( VERIFY_PASS++ )) || true
            else
                _log "ERROR" "Verify FAILED : user '${name}' not found"
                (( VERIFY_FAIL++ )) || true
            fi
            ;;
    esac
}

function backup_if_exists {
    local target_file="$1"

    if [[ -f "${target_file}" ]]; then
        if [[ ! -d "${BACKUP_DIR}" ]]; then
            mkdir -p "${BACKUP_DIR}"
            chmod "${PERM_BACKUP_DIR}" "${BACKUP_DIR}"
        fi

        local base_name
        base_name=$(basename "${target_file}")

        local timestamp
        timestamp=$(date +%Y%m%d_%H%M%S)

        local backup_file="${BACKUP_DIR}/${base_name}.${timestamp}.bak"

        cp -a "${target_file}" "${backup_file}"
        _log "INFO" "Created backup of ${base_name} in ${BACKUP_DIR}"

        local backups
        mapfile -t backups < <(find "${BACKUP_DIR}" -maxdepth 1 -name "${base_name}.*.bak" -printf "%T@ %p\n" 2>/dev/null | sort -rn | awk '{print $2}')

        if [[ ${#backups[@]} -gt 3 ]]; then
            local i
            for ((i=3; i<${#backups[@]}; i++)); do
                rm -f "${backups[i]}"
            done
        fi
    fi
}

if [[ ${FULL_SETUP_MODE} -eq 1 ]]; then

    print_divider
    _log "INFO" "STEP 1: Account and Group Setup (Hardened)"
    print_sub_divider

    if ! getent group "${SYSTEM_GROUP}" >/dev/null; then
        groupadd "${SYSTEM_GROUP}"
        verify_account "group" "${SYSTEM_GROUP}"
    else
        _log "INFO" "Group ${SYSTEM_GROUP} already exists."
    fi

    if ! id -u "${SYSTEM_USER}" >/dev/null 2>&1; then
        useradd -r -M -d /nonexistent -g "${SYSTEM_GROUP}" -s /sbin/nologin -c "EPICS procServ Daemon Account" "${SYSTEM_USER}"
        verify_account "user" "${SYSTEM_USER}"
    else
        _log "INFO" "System user ${SYSTEM_USER} already exists."
    fi

    print_divider
    _log "INFO" "STEP 2: Shared Configuration Directory Setup (Strict ACL)"
    print_sub_divider

    mkdir -p "${CONF_DIR}"
    chown "${OWNER_CONF_DIR}" "${CONF_DIR}"
    chmod "${PERM_CONF_DIR}" "${CONF_DIR}"
    verify_path "${CONF_DIR}" "${OWNER_CONF_DIR}" "${PERM_CONF_DIR}" "Configured directory: ${CONF_DIR} (${OWNER_CONF_DIR}, ${PERM_CONF_DIR})"

    print_divider
    _log "INFO" "STEP 3: Sudoers Configuration (Validated & Restricted)"
    print_sub_divider

    tmp_sudoers=$(mktemp)

    cat <<EOF > "${tmp_sudoers}"
# /etc/sudoers.d/10-epics-ioc
%${SYSTEM_GROUP} ALL=(root) NOPASSWD: ${SYSTEMCTL_BIN} start epics-@*.service, \\
                                      ${SYSTEMCTL_BIN} stop epics-@*.service, \\
                                      ${SYSTEMCTL_BIN} restart epics-@*.service, \\
                                      ${SYSTEMCTL_BIN} status epics-@*.service, \\
                                      ${SYSTEMCTL_BIN} enable epics-@*.service, \\
                                      ${SYSTEMCTL_BIN} disable epics-@*.service, \\
                                      ${SYSTEMCTL_BIN} daemon-reload
EOF

    if visudo -cf "${tmp_sudoers}" >/dev/null 2>&1; then
        chmod "${PERM_SUDOERS}" "${tmp_sudoers}"
        backup_if_exists "${SUDOERS_FILE}"
        mv "${tmp_sudoers}" "${SUDOERS_FILE}"
        verify_path "${SUDOERS_FILE}" "${OWNER_SYSTEM}" "${PERM_SUDOERS}" "Validated and deployed sudoers policy to ${SUDOERS_FILE}"
        verify_sudoers_includedir_order "/etc/sudoers"
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
Wants=time-sync.target
After=network.target remote-fs.target time-sync.target
AssertFileNotEmpty=${CONF_DIR}/%i.conf

[Service]
Type=simple
User=${SYSTEM_USER}
Group=${SYSTEM_GROUP}
EnvironmentFile=${CONF_DIR}/%i.conf
RuntimeDirectory=procserv/%i
RuntimeDirectoryMode=0770
ExecStart=${RESOLVED_PROCSERV_BIN} --foreground --logfile=- --name=%i --ignore=^D^C^] --chdir=\${IOC_CHDIR} --port=\${IOC_PORT} \${IOC_CMD}
SuccessExitStatus=0 1 2 15 143 SIGTERM SIGKILL
StandardOutput=syslog
StandardError=inherit
SyslogIdentifier=epics-%i

[Install]
WantedBy=multi-user.target
EOF

    chmod "${PERM_SYSTEMD_TEMPLATE}" "${SYSTEMD_TEMPLATE}"
    verify_path "${SYSTEMD_TEMPLATE}" "${OWNER_SYSTEM}" "${PERM_SYSTEMD_TEMPLATE}" "Deployed systemd template to ${SYSTEMD_TEMPLATE} using ${RESOLVED_PROCSERV_BIN}"

    systemctl daemon-reload
    _log "SUCCESS" "Reloaded systemd daemon."

fi

print_divider
_log "INFO" "STEP 5: CLI Wrapper Deployment"
print_sub_divider

if [[ -f "${RUNNER_SCRIPT_SRC}" ]]; then
    backup_if_exists "${RUNNER_SCRIPT_DEST}"
    cp "${RUNNER_SCRIPT_SRC}" "${RUNNER_SCRIPT_DEST}"

    # Inject version and build information into the deployed script.
    # Use -C "${SC_DIR}" so the metadata reflects the epics-ioc-runner repo
    # regardless of the caller's working directory.
    # safe.directory keeps git working when sudo runs against a repo
    # owned by the invoking user (git 2.35.2+ dubious-ownership guard).
    current_git_hash=$(git -c safe.directory="${SC_DIR}" -C "${SC_DIR}" rev-parse --short HEAD 2>/dev/null || printf "unknown")

    # Append "-dirty" only when we have a real hash; otherwise a failed
    # diff-index (git missing, repo absent) would yield "unknown-dirty".
    if [[ "${current_git_hash}" != "unknown" ]] && command -v git >/dev/null 2>&1 && ! git -c safe.directory="${SC_DIR}" -C "${SC_DIR}" diff-index --quiet HEAD -- 2>/dev/null; then
        current_git_hash="${current_git_hash}-dirty"
    fi

    current_build_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    sed -i "s/^declare -g RUNNER_GIT_HASH=.*/declare -g RUNNER_GIT_HASH=\"${current_git_hash}\"/" "${RUNNER_SCRIPT_DEST}"
    sed -i "s/^declare -g RUNNER_BUILD_DATE=.*/declare -g RUNNER_BUILD_DATE=\"${current_build_date}\"/" "${RUNNER_SCRIPT_DEST}"

    chmod "${PERM_RUNNER_SCRIPT}" "${RUNNER_SCRIPT_DEST}"
    verify_path "${RUNNER_SCRIPT_DEST}" "${OWNER_SYSTEM}" "${PERM_RUNNER_SCRIPT}" "Deployed ioc-runner to ${RUNNER_SCRIPT_DEST} (${PERM_RUNNER_SCRIPT})"

    # On RHEL-family systems, sudo's secure_path excludes /usr/local/bin,
    # so 'sudo ioc-runner inspect' fails to resolve the CLI. Add a symlink
    # under /usr/bin (always in secure_path) to restore the invocation path.
    if is_rhel_family; then
        ln -sfn "${RUNNER_SCRIPT_DEST}" "${RUNNER_SCRIPT_SYMLINK}"
        verify_symlink "${RUNNER_SCRIPT_SYMLINK}" "${RUNNER_SCRIPT_DEST}" \
            "Created ${RUNNER_SCRIPT_SYMLINK} -> ${RUNNER_SCRIPT_DEST} for sudo secure_path"
    fi

else
    _log "ERROR" "Could not find ${RUNNER_SCRIPT_SRC}."
    _log "ERROR" "Please ensure you are running this script from the repository's bin/ directory."
    exit 1
fi

# Deploys the Bash completion script to the system directory for enhanced CLI usability and validates deployment state.
if [[ -f "${BASH_COMP_SRC}" ]]; then
    backup_if_exists "${BASH_COMP_DEST}"
    cp "${BASH_COMP_SRC}" "${BASH_COMP_DEST}"
    chmod "${PERM_BASH_COMP}" "${BASH_COMP_DEST}"
    verify_path "${BASH_COMP_DEST}" "${OWNER_SYSTEM}" "${PERM_BASH_COMP}" "Deployed Bash completion to ${BASH_COMP_DEST} (${PERM_BASH_COMP})"
else
    _log "INFO" "Bash completion source not found at ${BASH_COMP_SRC}. Skipping deployment."
fi

print_divider
_log "INFO" "Verification Summary"
print_sub_divider
total=$(( VERIFY_PASS + VERIFY_FAIL ))
_log "SUCCESS" "Passed : ${VERIFY_PASS}/${total}"
if [[ ${VERIFY_FAIL} -gt 0 ]]; then
    _log "ERROR" "Failed : ${VERIFY_FAIL}/${total}"
else
    _log "INFO" "Failed : ${VERIFY_FAIL}/${total}"
fi
print_divider

print_divider
if [[ ${FULL_SETUP_MODE} -eq 1 ]]; then
    _log "SUCCESS" "Secure system infrastructure setup completed."
    _log "INFO" "Add authorized engineers to the '${SYSTEM_GROUP}' group:"
    _log "INFO" "  sudo usermod -aG ${SYSTEM_GROUP} <username>"
    _log "INFO" "After adding the user, apply the new group membership immediately:"
    _log "INFO" "  newgrp ${SYSTEM_GROUP}"
else
    _log "SUCCESS" "CLI wrapper updated successfully."
fi
print_divider
