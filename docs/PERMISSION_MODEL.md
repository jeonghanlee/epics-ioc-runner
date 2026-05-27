# Filesystem Permission Model

This document captures the filesystem permission model for the
`epics-ioc-runner` 1.1.0 release. It covers every directory and
file the runner installs, references, or creates at IOC start time,
plus the principals authorized to create, manage, and read each
object.

Scope:

- System-mode paths managed by `setup-system-infra.bash`
- Site-provisioned paths the runner only reads (procServ binary,
  EPICS base, `/opt/epics-iocs/`)
- Local-mode paths created by `ioc-runner --local install`
- Three-principal model and end-state targets for the log directory
- Permission lifecycle (Create / Manage / Track) per principal

## Filesystem Layout

### Setup-managed paths

Paths created or installed by `setup-system-infra.bash`. Owner and
mode are enforced at install time and re-verified by the script.

| Path | Owner:Group | Mode | Variable | Notes |
| --- | --- | --- | --- | --- |
| `/etc/procServ.d/` | `root:ioc` | `2770` (setgid) | `CONF_DIR` / `PERM_CONF_DIR` | per-IOC `.conf` files; group rw for engineers |
| `/etc/sudoers.d/10-epics-ioc` | `root:root` | `0440` | `SUDOERS_FILE` / `PERM_SUDOERS` | sudo policy granting `%ioc` the privileged systemctl verbs |
| `/etc/systemd/system/epics-@.service` | `root:root` | `0644` | `SYSTEMD_TEMPLATE` | system-mode unit template |
| `/var/log/procserv/` | `root:ioc` | `2775` (setgid) | `SYSTEM_LOG_DIR` / `PERM_LOG_DIR` | procServ log directory; default ACL `g:ioc:rw, o::r--, m::rw` |
| `/var/backups/epics-ioc-runner/` | `root:root` | `0700` | `BACKUP_DIR` / `PERM_BACKUP_DIR` | atomic backups before template rewrites |
| `/usr/local/bin/ioc-runner` | `root:root` | `0755` | `RUNNER_SCRIPT_DEST` | runner script |
| `/usr/bin/ioc-runner` | symlink → `/usr/local/bin/ioc-runner` | — | `RUNNER_SCRIPT_SYMLINK` | RHEL-family `secure_path` workaround |
| `/etc/bash_completion.d/ioc-runner` | `root:root` | `0644` | `BASH_COMP_DEST` | tab completion |

### Site-provisioned paths

Paths the runner references but does not manage. The site is
responsible for owner and mode at provisioning time (typically via
`cloud-provision` / `ansible-provision`).

| Path | Typical Owner:Group | Typical Mode | Source | Runner's role |
| --- | --- | --- | --- | --- |
| `/opt/epics-iocs/` | `root:ioc` | `2775` | site provisioning | `bin/ioc-runner` runs a metadata-based model-conformance check on `IOC_CHDIR` |
| `/opt/epics-iocs/epics/<base-suite>/<distro>/<base-ver>/base` | site | site-defined | site provisioning | unused by the runner — IOC `.conf` references it via environment |
| `/usr/local/bin/procServ` or `/usr/bin/procServ` | site | site-defined | package or site build | discovered via `PROCSERV_SEARCH_PATHS` |

The runner's `IOC_CHDIR` writability check is satisfied by directory
group ownership and mode, not by an ACL. The `ioc-srv` account is in
the `ioc` group, so a `root:ioc` tree with setgid plus group
write+execute permissions (typically mode `2775`) lets it create
runtime artifacts such as `.iocsh_history`, autosave files, and
save/restore state directly. This is the directory group-write bit
acting on the directory itself. It is distinct from the default ACL on
the log directory (see "Why Default ACLs Are Still Set"), which governs
the ACL permissions and mask inherited by newly created entries, not
write access to the parent directory. `IOC_CHDIR` needs the group-write
model, not a default ACL.

### Local-mode paths

Paths created by `ioc-runner --local install` under the invoking
user's account.

| Path | Owner:Group | Mode | Variable | Notes |
| --- | --- | --- | --- | --- |
| `${LOCAL_LOG_DIR}/` (default `~/.local/state/procserv/`) | `<user>:<user>` | `0750` | `LOCAL_LOG_DIR` | created by `do_install` local branch |
| `${LOCAL_LOG_DIR}/<ioc>.log` | `<user>:<user>` | `0640` | — | procServ-created with user unit `UMask=0027` |
| `~/.config/systemd/user/epics-@.service` | `<user>:<user>` | umask-dependent (`0644` at the conventional `umask 022`) | — | written by `deploy_local_template` via `cat`; no explicit `chmod`, so the final mode follows the invoking user's umask |

## Access Boundary: sudoers Policy + File Mode

The sudoers policy at `/etc/sudoers.d/10-epics-ioc` gates the
privileged state-changing systemctl verbs that `ioc-runner` issues
in system mode:

```
%ioc ALL=(root) NOPASSWD: /usr/bin/systemctl start|stop|restart|
                          status|enable|disable|daemon-reload
                          epics-@*.service
```

Effective scope:

- Only members of the `ioc` group can have `ioc-runner` succeed in
  `start` / `stop` / `restart` / `enable` / `disable` /
  `daemon-reload` operations on `epics-@*.service` instances. For
  non-`ioc` users, the `sudo systemctl ...` call inside
  `ioc-runner` fails at the sudo gate.
- `ioc-runner` execution itself is not restricted — any user can
  invoke the script. The gate is the privileged systemctl
  invocation it makes internally.
- Read-only paths (`ioc-runner status`, `is-active`, `cat`, `show`)
  do not go through `sudo`. They rely on systemd's own permission
  for those queries (typically permissive) and on file system
  permissions for any log file reads.

File-mode permissions and default ACLs reinforce the boundary at
the file system layer: who can read log files, who can write, and
who can create files in the log directory.

## Three-Principal Model (system mode)

The system-wide mode has three distinct principals against the log
directory and log files. A fourth class — any user outside `ioc` —
has read-only access via the directory's `o+rx` bits and the file's
`o+r` bit.

| Principal | Role | Required access |
| --- | --- | --- |
| `root` | install | create directories; verify ownership and mode at install time |
| `ioc-srv` | operate | write log records during procServ execution |
| engineer ∈ `ioc` group | manage | read logs (status, crash detection); engineer-created files in the dir get group `ioc` write |
| any user (other) | observe | read logs and list the directory at the file-mode layer |

The `--local` mode is single-principal by construction (one
engineer is install, operate, manage, and observe at the same
time). It does not use the three-principal model.

## End-State Targets

### System mode log directory and files

| Object | Owner:Group | Mode | Default ACL | Creator |
| --- | --- | --- | --- | --- |
| `${SYSTEM_LOG_DIR}/` | `root:ioc` | `2775` (setgid) | `g:ioc:rw`, `o::r--`, `m::rw` | `setup-system-infra.bash` at install time |
| `${SYSTEM_LOG_DIR}/<ioc>.log` (procServ-created) | `ioc-srv:ioc` | `0644` | (inherited from parent default ACL) | procServ at IOC start: `open(O_CREAT, 0644)` |
| `${SYSTEM_LOG_DIR}/<adhoc>` (engineer-created) | `<engineer>:ioc` | `0664` | (default ACL `g:ioc:rw` raises mask above `0644`) | engineer's shell `touch` under default `umask 0022` |

Result by principal on a procServ-created `<ioc>.log` (mode `0644`):

| Principal | Bit | Effect |
| --- | --- | --- |
| `ioc-srv` (owner) | `rw-` | append log entries during procServ runtime |
| `ioc` group (engineer) | `r--` | read via `cat`, `tail`, `grep`, crash detection scan |
| other | `r--` | read at the file-mode layer; state-changing IOC management through `ioc-runner` remains sudoers-gated |

procServ uses `open(O_CREAT, 0644)` internally (`procServ.cc:924`,
`S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH`). No upstream change is made;
the system unit carries no `UMask=` directive so the default system
umask `0022` preserves the `0644` mode through.

### Local mode log directory and files

| Object | Owner:Group | Mode | Creator |
| --- | --- | --- | --- |
| `${LOCAL_LOG_DIR}/` (default `~/.local/state/procserv/`) | `<user>:<user>` | `0750` | `bin/ioc-runner` `do_install` local branch |
| `${LOCAL_LOG_DIR}/<ioc>.log` | `<user>:<user>` | `0640` | procServ at IOC start, with user-mode unit `UMask=0027` |

Local mode keeps `UMask=0027` in the user-mode unit. The engineer
is the only principal; `0640` ensures their primary group has read
but other users on the same host cannot read the user's logs.

## Permission Lifecycle

The lifecycle of every log object covers three operational phases:
Create, Manage, and Track (read).

### System mode

| Phase | Action | Principal | Object | Mechanism | Resulting state / Gate |
| --- | --- | --- | --- | --- | --- |
| Create | install log directory | `root` (via sudo) | `${SYSTEM_LOG_DIR}/` | `setup-system-infra.bash`: `install -d -o root -g ioc -m 2775` + `setfacl -d` | `root:ioc 2775` + default ACL `g:ioc:rw, o::r--, m::rw` |
| Create | open log file | `ioc-srv` | `${SYSTEM_LOG_DIR}/<ioc>.log` | procServ `open(O_CREAT, 0644)` at IOC start; system unit umask `0022` | `ioc-srv:ioc 0644` |
| Create | adhoc file (probe, manual archive) | engineer ∈ `ioc` | `${SYSTEM_LOG_DIR}/<adhoc>` | shell `touch` (setgid + default ACL applied) | `<engineer>:ioc 0664` |
| Manage | append log records | `ioc-srv` | `<ioc>.log` | procServ `write(logFileFD, ...)` during IOC runtime | owner `w` bit |
| Manage | start / stop / restart IOC | engineer ∈ `ioc` (sudo) | `epics-@<ioc>.service` | `ioc-runner` → `sudo /usr/bin/systemctl ...` | sudoers gate `%ioc ALL=(root) NOPASSWD: ... epics-@*.service` |
| Manage | rotate (Phase B-3 #15, pending) | `root` (cron) | `<ioc>.log` | `logrotate -f /etc/logrotate.d/procserv` with `copytruncate` | mode and owner preserved; archives `<ioc>.log.N.gz` |
| Track | crash detection scan | engineer ∈ `ioc` | `<ioc>.log` | `ioc-runner` byte-offset scan (no sudo, engineer's UID) | group `r--` grants read |
| Track | manual read | engineer ∈ `ioc` | `<ioc>.log` | `cat` / `tail` / `grep` | group `r--` grants read |
| Track | read-only inspection | engineer ∉ `ioc` | `<ioc>.log` | direct shell read | dir `o+rx` traversal + file `o+r` |
| Track | directory listing | any user | `${SYSTEM_LOG_DIR}/` | `ls` | dir `o+rx` |
| Track | `ioc-runner status` / `is-active` | any user | service state | systemd query (no sudo) | systemd query ACL (permissive) |

### Local mode

| Phase | Action | Principal | Object | Mechanism | Resulting state |
| --- | --- | --- | --- | --- | --- |
| Create | install log directory | `<user>` | `${LOCAL_LOG_DIR}/` | `ioc-runner --local install`: `install -d -m 0750` | `<user>:<user> 0750` |
| Create | open log file | `<user>` (via `systemd --user`) | `${LOCAL_LOG_DIR}/<ioc>.log` | procServ `open(O_CREAT, 0644)` + user unit `UMask=0027` | `<user>:<user> 0640` |
| Manage | append / IOC lifecycle | `<user>` | log file, user unit | `systemctl --user ...` (no sudo) | self-managed |
| Track | crash scan / shell read | `<user>` | `<ioc>.log` | `ioc-runner --local`, `cat`, `tail` | owner `r` |

## Why Default ACLs Are Still Set

Even though procServ's hardcoded `open(0644)` mode_arg restricts the
access ACL mask to `r--` (no group write) for procServ-created files,
default ACLs still serve two purposes:

1. **Engineer-created files in the log directory** (manual probe
   files, rotated archive copies created by an engineer) inherit
   group `ioc` with `rw` access. Without the default ACL, an
   engineer-created file under default `umask 0022` would land at
   `<engineer>:<engineer-primary-group> 0644` and the `ioc-srv`
   service account could not read or write it under the group bit.
   With the default ACL, such files become `<engineer>:ioc 0664`,
   preserving the ioc-srv-can-write invariant for the rare case.
2. **Cross-creator consistency** of group membership. setgid on the
   directory enforces the `ioc` group on every newly created entry
   regardless of the creator's primary group; the default ACL
   reinforces the same with explicit mask handling.

## How the Model Is Set Up

System mode setup is performed once at install time by
`setup-system-infra.bash`, running as `root` via `sudo`:

```bash
install -d -o root -g ioc -m 2775 "${SYSTEM_LOG_DIR}"
setfacl -d -m g:ioc:rw "${SYSTEM_LOG_DIR}"
setfacl -d -m o::r-- "${SYSTEM_LOG_DIR}"
setfacl -d -m m::rw "${SYSTEM_LOG_DIR}"
```

The system unit (`/etc/systemd/system/epics-@.service`) does NOT
set `UMask=`. systemd's default for system units is `0022`, which
preserves procServ's `0644` mode_arg through to the resulting file.
`LogsDirectory=procserv` is intentionally NOT used in the unit —
the directive would chown the log directory to the unit's `User=`
/ `Group=` (`ioc-srv:ioc`) on every activation, overriding the
`root:ioc` ownership this model requires.

Local mode setup is performed by `ioc-runner --local install` under
the invoking user:

```bash
install -d -m 0750 "${LOCAL_LOG_DIR}"
```

The local user systemd template carries `UMask=0027` so that
procServ-created log files start at mode `0640`.

## Verification

System mode (after `setup-system-infra.bash` + IOC start):

```bash
stat -c '%U:%G %a' /var/log/procserv
# expected: root:ioc 2775

getfacl -p /var/log/procserv | grep -E 'default:'
# expected (order may vary):
#   default:user::rwx
#   default:group::rwx
#   default:group:ioc:rw-
#   default:mask::rw-
#   default:other::r--

stat -c '%U:%G %a' /var/log/procserv/<ioc>.log
# expected: ioc-srv:ioc 644
```

Engineer-side access probes (run as a user in the `ioc` group):

```bash
cat /var/log/procserv/<ioc>.log              # succeeds (group r--)
```

Engineer-created file in the directory (default ACL effect):

```bash
(umask 0022; touch /var/log/procserv/probe.log)
stat -c '%U:%G %a' /var/log/procserv/probe.log
# expected: <engineer>:ioc 664
```

A user outside the `ioc` group:

```bash
sudo -u nobody cat /var/log/procserv/<ioc>.log
# succeeds: dir 2775 grants o+rx traversal; file 0644 grants o+r
```

Note that wide read sits at the file-mode layer only. The sudoers
policy restricts the privileged `systemctl start`/`stop`/`restart`/
`enable`/`disable`/`daemon-reload` calls that `ioc-runner` makes
internally in system mode to `%ioc` group members. Non-`ioc` users
can run the `ioc-runner` binary itself and can `cat` the log
directly, but any IOC state change attempted through `ioc-runner`
fails at the sudo gate inside the script.

Local mode (after `ioc-runner --local install <conf>` + IOC start):

```bash
stat -c '%U:%G %a' ~/.local/state/procserv
# expected: <user>:<user> 750

stat -c '%U:%G %a' ~/.local/state/procserv/<ioc>.log
# expected: <user>:<user> 640
```

## Why This Matters (Crash Detection Context)

The 1.0.x release chain detected IOC startup crashes by scanning
`journalctl -u epics-@<name>.service` after `sudo systemctl start`.
That required engineers to be in the `systemd-journal` group, which
was fragile across Debian 13 and Rocky 8 due to distribution-specific
journal layouts and group memberships.

1.1.0 decouples crash detection from journal access by writing
procServ output to a dedicated log file under `${SYSTEM_LOG_DIR}`
and scanning that file inline in `do_start_restart`. The scan runs
in the same `ioc-runner` process that the engineer invoked — it
executes under the engineer's UID, not via `sudo`. The permission
model above is the precondition: engineers in the `ioc` group can
`stat`, `tail`, `grep` the log file directly, without `sudo` and
without `systemd-journal` group membership.

### No journal-group re-grant

The `systemd-journal` group reads the entire host journal — sshd
authentication, kernel events, sudo usage, and every unrelated service —
not only IOC logs. Granting it to IOC operators over-exposes them far
beyond their role; in a multi-tenant lab this is the least-privilege
violation that 1.1.0 removes by taking operators out of the group.

Removal is therefore not paired with a rollback or re-grant procedure:
re-adding the group would reopen the same broad exposure. Crash
detection reads the dedicated log file as the single source of truth,
with no journal dependency to restore, so the supported recovery is to
fix the log-file path — not to widen operator privilege.

## Cross-References

- Architecture: [`ARCHITECTURE.md`](ARCHITECTURE.md)
- CLI surface: [`CLI_REFERENCE.md`](CLI_REFERENCE.md)
- Release roadmap: [`ROADMAP-1.1.0.md`](ROADMAP-1.1.0.md)
- Test plan: [`TEST_PLAN-1.1.0.md`](TEST_PLAN-1.1.0.md)
- Tracking epic: [#7](https://github.com/jeonghanlee/epics-ioc-runner/issues/7)
- Milestone: [1.1.0](https://github.com/jeonghanlee/epics-ioc-runner/milestone/3)
