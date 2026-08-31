# EPICS IOC Runner - System Uninstallation Guide

## Scope

This guide removes the system-wide `epics-ioc-runner` infrastructure deployed
by `bin/setup-system-infra.bash --full`. It preserves retained logs, backups,
and any account, group, or log directory that is not confirmed as dedicated to
this installation.

**Out of scope:** removing a single IOC while keeping the infrastructure. Use
`ioc-runner remove <ioc-name>` for that operation.

## Prerequisites

- Root access to the target server.
- No active `epics-@*.service` instances.
- No IOC configuration files remaining in `/etc/procServ.d`.
- The deployed `/etc/systemd/system/epics-@.service` is still present.
- Site records or operator knowledge that distinguish installation-dedicated
  resources from pre-existing or shared resources.

Use one privileged Bash session for the procedure. Before either identity is
deleted, a closed session can restart at section 1.3 so the identity and log
path are read again from the deployed source. After an identity deletion
starts, complete sections 2.2-2.4 without closing the session.

```bash
sudo -i
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
umask 077
```

## 1. Pre-Removal Safety Checks

### 1.1 Active services

```bash
systemctl list-units 'epics-@*.service' --state=active
```

If any service is listed, stop and remove each instance with
`ioc-runner remove <ioc-name>` before continuing.

### 1.2 Existing IOC configurations

```bash
find /etc/procServ.d -maxdepth 1 -type f -name '*.conf' -print
```

If any configuration is listed, stop and remove its IOC through `ioc-runner`.
Do not force-delete configuration files because the normal removal path also
disables the corresponding systemd instance.

### 1.3 Resolve the deployed identity and log path

The deployed unit is the source for the service account, group, and logfile
template. The resolver requires the root-owned `0644` regular file produced by
the installer, exactly one non-empty `User=` and `Group=`, and exactly one
`--logfile=` value. It resolves the logfile parent to a canonical directory and
rejects an empty path, `/`, a missing directory, or a template that does not end
in `/%i.log`.

```bash
declare IOC_UNIT_FILE="/etc/systemd/system/epics-@.service"
declare IOC_SYSTEM_USER=""
declare IOC_SYSTEM_GROUP=""
declare IOC_SYSTEM_UID=""
declare IOC_SYSTEM_GID=""
declare IOC_USER_RECORD=""
declare IOC_GROUP_RECORD=""
declare IOC_LOGFILE_TEMPLATE=""
declare IOC_SYSTEM_LOG_DIR=""

function resolve_ioc_runner_uninstall_state {
    local unit_stat=""
    local user_record=""
    local group_record=""
    local group_fields=""
    local raw_log_dir=""
    local canonical_log_dir=""
    local -a unit_users=()
    local -a unit_groups=()
    local -a logfile_args=()

    if [[ ! -f "${IOC_UNIT_FILE}" || -L "${IOC_UNIT_FILE}" ]]; then
        printf "ERROR: deployed unit is missing, not regular, or a symlink: %s\n" "${IOC_UNIT_FILE}" >&2
        return 1
    fi
    unit_stat=$(stat -c '%u:%g:%a' -- "${IOC_UNIT_FILE}")
    if [[ "${unit_stat}" != "0:0:644" ]]; then
        printf "ERROR: deployed unit must be root:root 0644, found %s\n" "${unit_stat}" >&2
        return 1
    fi

    mapfile -t unit_users < <(sed -n 's/^User=//p' -- "${IOC_UNIT_FILE}")
    mapfile -t unit_groups < <(sed -n 's/^Group=//p' -- "${IOC_UNIT_FILE}")
    mapfile -t logfile_args < <(grep -oE -- '--logfile=[^[:space:]]+' "${IOC_UNIT_FILE}")

    if [[ ${#unit_users[@]} -ne 1 || -z "${unit_users[0]}" ]]; then
        printf "ERROR: expected exactly one non-empty User= in %s\n" "${IOC_UNIT_FILE}" >&2
        return 1
    fi
    if [[ ${#unit_groups[@]} -ne 1 || -z "${unit_groups[0]}" ]]; then
        printf "ERROR: expected exactly one non-empty Group= in %s\n" "${IOC_UNIT_FILE}" >&2
        return 1
    fi
    if [[ ${#logfile_args[@]} -ne 1 ]]; then
        printf "ERROR: expected exactly one --logfile= value in %s\n" "${IOC_UNIT_FILE}" >&2
        return 1
    fi

    IOC_SYSTEM_USER="${unit_users[0]}"
    IOC_SYSTEM_GROUP="${unit_groups[0]}"
    IOC_LOGFILE_TEMPLATE="${logfile_args[0]#--logfile=}"

    if [[ "${IOC_LOGFILE_TEMPLATE}" != /* || "${IOC_LOGFILE_TEMPLATE}" != */%i.log ]]; then
        printf "ERROR: logfile template must be an absolute path ending in /%%i.log: %s\n" "${IOC_LOGFILE_TEMPLATE}" >&2
        return 1
    fi
    raw_log_dir="${IOC_LOGFILE_TEMPLATE%/%i.log}"
    if ! canonical_log_dir=$(readlink -f -- "${raw_log_dir}"); then
        printf "ERROR: cannot resolve logfile directory: %s\n" "${raw_log_dir}" >&2
        return 1
    fi
    if [[ -z "${canonical_log_dir}" || "${canonical_log_dir}" == "/" || ! -d "${canonical_log_dir}" ]]; then
        printf "ERROR: unsafe or missing logfile directory: %s\n" "${canonical_log_dir}" >&2
        return 1
    fi
    IOC_SYSTEM_LOG_DIR="${canonical_log_dir}"

    if ! user_record=$(getent passwd -- "${IOC_SYSTEM_USER}"); then
        printf "ERROR: deployed service account does not exist: %s\n" "${IOC_SYSTEM_USER}" >&2
        return 1
    fi
    if ! group_record=$(getent group -- "${IOC_SYSTEM_GROUP}"); then
        printf "ERROR: deployed service group does not exist: %s\n" "${IOC_SYSTEM_GROUP}" >&2
        return 1
    fi
    if [[ "${user_record}" == *$'\n'* || "${group_record}" == *$'\n'* ]]; then
        printf "%s\n" "ERROR: identity lookup returned multiple records" >&2
        return 1
    fi

    IOC_USER_RECORD="${user_record}"
    IOC_GROUP_RECORD="${group_record}"
    IOC_SYSTEM_UID=$(id -u -- "${IOC_SYSTEM_USER}")
    group_fields="${group_record#*:}"
    group_fields="${group_fields#*:}"
    IOC_SYSTEM_GID="${group_fields%%:*}"
    if [[ ! "${IOC_SYSTEM_UID}" =~ ^[0-9]+$ || ! "${IOC_SYSTEM_GID}" =~ ^[0-9]+$ ]]; then
        printf "%s\n" "ERROR: identity lookup returned a non-numeric UID or GID" >&2
        return 1
    fi

    printf "Service account : %s (UID %s)\n" "${IOC_SYSTEM_USER}" "${IOC_SYSTEM_UID}"
    printf "Service group   : %s (GID %s)\n" "${IOC_SYSTEM_GROUP}" "${IOC_SYSTEM_GID}"
    printf "Logfile template: %s\n" "${IOC_LOGFILE_TEMPLATE}"
    printf "Log directory   : %s\n" "${IOC_SYSTEM_LOG_DIR}"
}

if ! resolve_ioc_runner_uninstall_state; then
    exit 1
fi
```

Compare all displayed values with the installation and site records. Stop if
any value is unexpected. Do not edit the resolved variables to bypass a failed
check.

### 1.4 Classify resources before changing metadata

The installer creates a missing account, group, or log directory, but reuses
an existing one. It does not record which case occurred. Treat each decision
independently and use the conservative result when the origin is unknown.

| Resource | Dedicated result | Conservative result |
| --- | --- | --- |
| Log directory | Confirmed created exclusively for this installation and has no other use | Existing, shared, or origin unknown: preserve its current metadata and retain both related identities |
| Service account | Confirmed created exclusively for this installation and has no other use | Existing, shared, or origin unknown: retain it |
| Service group | Confirmed created exclusively for this installation and has no other use | Existing, shared, or origin unknown: retain it |

For an existing, shared, or origin-unknown log directory, record its metadata
and numeric ACL state before continuing. Keep this value in the same privileged
Bash session through section 3.

```bash
declare IOC_PRESERVED_LOG_STATE=""

function fingerprint_ioc_runner_log_tree {
    local log_dir="$1"

    {
        find -P "${log_dir}" -xdev -printf '%P\0%U\0%G\0%m\0%s\0%T@\0%y\0' | sort -z
        find -P "${log_dir}" -xdev ! -type l -exec getfacl -n -p -- {} +
    } | sha256sum | awk '{print $1}'
}

IOC_PRESERVED_LOG_STATE=$(fingerprint_ioc_runner_log_tree "${IOC_SYSTEM_LOG_DIR}")
printf "Preserved log state: %s\n" "${IOC_PRESERVED_LOG_STATE}"
```

## 2. Ordered Removal Steps

### 2.1 Installation-dedicated log directory only

Skip this section when the log directory is existing, shared, or of unknown
origin. In that conservative case, do not change its ownership or ACLs and do
not delete the resolved account or group.

For a confirmed installation-dedicated directory, resolve the deployed values
again immediately before changing metadata. The physical, one-filesystem walk
does not follow symbolic links or cross nested mount points.

```bash
if ! resolve_ioc_runner_uninstall_state; then
    exit 1
fi
find -P "${IOC_SYSTEM_LOG_DIR}" -xdev -exec chown -h root:root -- {} +
find -P "${IOC_SYSTEM_LOG_DIR}" -xdev ! -type l -exec setfacl -x "u:${IOC_SYSTEM_USER}" -- {} +
find -P "${IOC_SYSTEM_LOG_DIR}" -xdev ! -type l -exec setfacl -x "g:${IOC_SYSTEM_GROUP}" -- {} +
find -P "${IOC_SYSTEM_LOG_DIR}" -xdev -type d -exec setfacl -d -x "u:${IOC_SYSTEM_USER}" -- {} +
find -P "${IOC_SYSTEM_LOG_DIR}" -xdev -type d -exec setfacl -d -x "g:${IOC_SYSTEM_GROUP}" -- {} +
```

Verify that the dedicated log tree no longer refers to the selected numeric
identity before deleting either identity.

```bash
IOC_OWNER_RESIDUE=$(find -P "${IOC_SYSTEM_LOG_DIR}" -xdev \( -uid "${IOC_SYSTEM_UID}" -o -gid "${IOC_SYSTEM_GID}" \) -print -quit)
if [[ -n "${IOC_OWNER_RESIDUE}" ]]; then
    printf "ERROR: selected UID or GID remains under %s: %s\n" "${IOC_SYSTEM_LOG_DIR}" "${IOC_OWNER_RESIDUE}" >&2
    exit 1
fi
if find -P "${IOC_SYSTEM_LOG_DIR}" -xdev ! -type l -exec getfacl -n -p -- {} + 2>/dev/null | grep -Eq "^(default:)?(user:${IOC_SYSTEM_UID}|group:${IOC_SYSTEM_GID}):"; then
    printf "ERROR: selected UID or GID remains in an ACL under %s\n" "${IOC_SYSTEM_LOG_DIR}" >&2
    exit 1
fi
```

### 2.2 Service account decision

Run the deletion block only when the service account is confirmed as
installation-dedicated and no retained log directory requires it. The process
check prevents deletion while the account still owns a running process.

```bash
if pgrep -u "${IOC_SYSTEM_UID}" >/dev/null; then
    printf "ERROR: service account still owns a running process: %s\n" "${IOC_SYSTEM_USER}" >&2
    exit 1
fi
userdel -- "${IOC_SYSTEM_USER}"
```

Otherwise, retain the account and do not run this block.

### 2.3 Service group decision

Run the deletion block only when the service group is confirmed as
installation-dedicated, has no other use, and no retained log directory
requires it. Delete the dedicated service account first when it uses this group.

```bash
IOC_PRIMARY_GROUP_USERS=$(getent passwd | awk -F: -v gid="${IOC_SYSTEM_GID}" '$4 == gid {print $1}')
IOC_CURRENT_GROUP_RECORD=$(getent group -- "${IOC_SYSTEM_GROUP}")
IOC_SUPPLEMENTARY_GROUP_USERS="${IOC_CURRENT_GROUP_RECORD##*:}"
if [[ -n "${IOC_PRIMARY_GROUP_USERS}" || -n "${IOC_SUPPLEMENTARY_GROUP_USERS}" ]]; then
    printf "ERROR: service group still has primary or supplementary members: %s\n" "${IOC_SYSTEM_GROUP}" >&2
    exit 1
fi
groupdel -- "${IOC_SYSTEM_GROUP}"
```

Otherwise, retain the group and do not run this block.

### 2.4 Systemd template

Remove the deployed identity source only after sections 2.1-2.3 are complete.

```bash
rm -f /etc/systemd/system/epics-@.service
systemctl daemon-reload
```

### 2.5 Bash completion and CLI wrapper

The `/usr/bin` path applies to Rocky/RHEL. `rm -f` is a no-op when a path is
absent.

```bash
rm -f /etc/bash_completion.d/ioc-runner
rm -f /usr/local/bin/ioc-runner
rm -f /usr/bin/ioc-runner
```

### 2.6 Sudoers and log rotation policies

```bash
rm -f /etc/sudoers.d/10-epics-ioc
rm -f /etc/logrotate.d/procserv
```

### 2.7 Shared configuration directory

The directory removal refuses to continue when IOC configuration remains.

```bash
rmdir /etc/procServ.d
```

## 3. Verification

The deployed infrastructure must be absent.

```bash
test ! -e /etc/systemd/system/epics-@.service
test ! -e /etc/bash_completion.d/ioc-runner
test ! -e /usr/local/bin/ioc-runner
test ! -e /usr/bin/ioc-runner
test ! -e /etc/sudoers.d/10-epics-ioc
test ! -e /etc/logrotate.d/procserv
test ! -e /etc/procServ.d
if command -v ioc-runner >/dev/null; then
    printf "%s\n" "ERROR: ioc-runner remains on PATH" >&2
    exit 1
fi
```

For every account or group selected for deletion, run the applicable check. A
successful lookup is an error.

```bash
if getent passwd -- "${IOC_SYSTEM_USER}" >/dev/null; then
    printf "ERROR: deleted service account still exists: %s\n" "${IOC_SYSTEM_USER}" >&2
    exit 1
fi
if getent group -- "${IOC_SYSTEM_GROUP}" >/dev/null; then
    printf "ERROR: deleted service group still exists: %s\n" "${IOC_SYSTEM_GROUP}" >&2
    exit 1
fi
```

Run only the applicable line when one identity was retained. A retained record
must match the record captured in section 1.3.

```bash
test "$(getent passwd -- "${IOC_SYSTEM_USER}")" = "${IOC_USER_RECORD}"
test "$(getent group -- "${IOC_SYSTEM_GROUP}")" = "${IOC_GROUP_RECORD}"
```

For a confirmed installation-dedicated log directory, every retained entry
must now be owned by `root:root`, and no ACL may name the removed numeric
identity.

```bash
IOC_NON_ROOT_ENTRY=$(find -P "${IOC_SYSTEM_LOG_DIR}" -xdev \( ! -user root -o ! -group root \) -print -quit)
test -z "${IOC_NON_ROOT_ENTRY}"
if find -P "${IOC_SYSTEM_LOG_DIR}" -xdev ! -type l -exec getfacl -n -p -- {} + 2>/dev/null | grep -Eq "^(default:)?(user:${IOC_SYSTEM_UID}|group:${IOC_SYSTEM_GID}):"; then
    printf "ERROR: removed identity remains in an ACL under %s\n" "${IOC_SYSTEM_LOG_DIR}" >&2
    exit 1
fi
```

For an existing, shared, or origin-unknown log directory, do not run the
dedicated-directory verification. Confirm instead that its metadata and ACL
state match the value captured in section 1.4. Both related identities must
also pass the retained-record checks above.

```bash
IOC_CURRENT_LOG_STATE=$(fingerprint_ioc_runner_log_tree "${IOC_SYSTEM_LOG_DIR}")
if [[ -z "${IOC_PRESERVED_LOG_STATE}" || "${IOC_CURRENT_LOG_STATE}" != "${IOC_PRESERVED_LOG_STATE}" ]]; then
    printf "ERROR: preserved log metadata or ACL state changed under %s\n" "${IOC_SYSTEM_LOG_DIR}" >&2
    exit 1
fi
```

## 4. Backup and Log Retention

The installer writes timestamped backups under
`/var/backups/epics-ioc-runner`. Uninstall leaves this directory in place so a
previous configuration can be recovered.

Run the following command only when the backups are no longer required.

```bash
rm -rf /var/backups/epics-ioc-runner
```

The resolved system log directory and every user's local-mode log directory
are also retained by default. Remove the system log directory only when it was
confirmed as installation-dedicated and its operational history is no longer
required. The guard prevents an empty or root path from reaching `rm -rf`.

```bash
if [[ -z "${IOC_SYSTEM_LOG_DIR:-}" || "${IOC_SYSTEM_LOG_DIR}" == "/" ]]; then
    printf "%s\n" "ERROR: refusing to remove an empty or root log path" >&2
    exit 1
fi
rm -rf -- "${IOC_SYSTEM_LOG_DIR}"
```

Do not remove an existing, shared, or origin-unknown log directory through this
guide.

## 5. Optional Per-User Local-Mode Cleanup

System uninstall does not remove per-user local-mode rotation units. Complete
sections 3 and 4 first, then leave the privileged shell. Each local-mode user
runs the remaining commands from their own login session.

```bash
exit
```

```bash
systemctl --user disable --now epics-logrotate.timer
rm -f ~/.config/systemd/user/epics-logrotate.service
rm -f ~/.config/systemd/user/epics-logrotate.timer
rm -f ~/.config/ioc-runner/logrotate.conf
systemctl --user daemon-reload
```

## 6. Recovery and Failure Conditions

### Interrupted during identity removal

Keep the unit in place until all identity-dependent work is complete. If the
root shell closes before either identity is deleted, open a new root shell and
restart at section 1.3. If the shell closes after an account or group deletion,
stop and inspect the deployed unit, the remaining identity records, and the log
tree before continuing. The resolver requires both identities to exist and is
not a recovery mechanism after deletion begins. Do not reconstruct identity
values from memory.

### Service account owns a process

Inspect the remaining processes and stop only the known IOC-related process
before repeating the account decision.

```bash
ps -u "${IOC_SYSTEM_USER}" -o pid=,ppid=,cmd=
```

### Service group still has members

Inspect both primary and supplementary memberships. Retain the group unless
every remaining relationship is understood and removed through its owning
site procedure.

```bash
getent passwd | awk -F: -v gid="${IOC_SYSTEM_GID}" '$4 == gid {print $1}'
getent group -- "${IOC_SYSTEM_GROUP}"
```

### NFS `root_squash`

The infrastructure removal steps operate on root-owned local system paths. If
the resolved log directory is on NFS, follow the storage owner's procedure;
do not assume root can change its ownership or ACLs.
