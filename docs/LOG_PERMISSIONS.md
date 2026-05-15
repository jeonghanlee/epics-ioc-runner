# Log File Permission Model

This document captures the permission model for procServ-managed
IOC log files under `epics-ioc-runner` 1.1.0. It is intentionally
scoped to log files and the directories that contain them. Broader
log architecture (rotation, retention, layout) belongs in
`LOG_LAYOUT.md` (Phase F #18); this document may later be merged
into that file or into `FAQ.md`.

## Access Boundary: sudoers Policy + File Mode

The sudoers policy at `/etc/sudoers.d/10-epics-ioc` gates the
privileged state-changing systemctl verbs that `ioc-runner`
issues in system mode:

```
%ioc ALL=(root) NOPASSWD: /usr/bin/systemctl start|stop|restart|
                          status|enable|disable|daemon-reload
                          epics-@*.service
```

Effective scope:

- Only members of the `ioc` group can have `ioc-runner` succeed
  in `start` / `stop` / `restart` / `enable` / `disable` / `daemon-reload`
  operations on `epics-@*.service` instances. For non-`ioc`
  users, the `sudo systemctl ...` call inside `ioc-runner` fails
  at the sudo gate.
- `ioc-runner` execution itself is not restricted — any user can
  invoke the script. The gate is the privileged systemctl
  invocation it makes internally.
- Read-only paths (`ioc-runner status`, `is-active`, `cat`, `show`)
  do not go through `sudo`. They rely on systemd's own permission
  for those queries (typically permissive) and on file system
  permissions for any log file reads.

File-mode permissions and default ACLs reinforce the boundary at
the file system layer: who can read log files, who can write,
and who can create files in the log directory.

## Three-Principal Model (system mode)

The system-wide mode has three distinct principals against the
log directory and log files. The permission model satisfies each
principal's operational role without granting more access than
required.

| Principal | Role | Required access |
| --- | --- | --- |
| `root` | install | create the log directory; verify ownership and mode at install time |
| `ioc-srv` | operate | write log records during procServ execution |
| engineer ∈ `ioc` group | manage | read logs (`ioc-runner status`, crash detection); engineer-created files in the dir get group `ioc` write |

A fourth class — any user outside `ioc` — has read-only access
at the file-mode layer for log files. They can run `ioc-runner`
itself and its read-only paths (`status`, `is-active`, `cat`,
`show`) which do not invoke `sudo`. Any privileged state-changing
`systemctl` action that `ioc-runner` issues (`start` / `stop` /
`restart` / `enable` / `disable` / `daemon-reload`) fails at the
internal `sudo` gate, so non-`ioc` users cannot drive IOC state
through `ioc-runner`.

The `--local` mode is single-principal by construction (one
engineer is install, operate, and manage at the same time). It
does not use the three-principal model.

## End-State Targets

### System mode

| Object | Owner:Group | Mode | Default ACL | Creator |
| --- | --- | --- | --- | --- |
| `${SYSTEM_LOG_DIR}/` (default `/var/log/procserv/`) | `root:ioc` | `2770` (setgid) | `g:ioc:rw`, `o::r--`, `m::rw` | `setup-system-infra.bash` at install time |
| `${SYSTEM_LOG_DIR}/<ioc>.log` (procServ-created) | `ioc-srv:ioc` | `0644` | (inherited from parent default ACL) | procServ at IOC start (procServ uses `open(O_CREAT, 0644)` internally) |
| `${SYSTEM_LOG_DIR}/<adhoc>` (engineer-created) | `<engineer>:ioc` | `0664` | (inherited; default ACL `g:ioc:rw` raises mask above `0644`) | engineer's shell `touch` under default `umask 0022` |

Result by principal on a procServ-created `<ioc>.log` (mode `0644`):

| Principal | Bit | Effect |
| --- | --- | --- |
| `ioc-srv` (owner) | `rw-` | append log entries during procServ runtime |
| `ioc` group (engineer) | `r--` | read via `cat`, `tail`, `grep`, crash detection scan |
| other | `r--` | wide read at the file-mode layer; privileged state-changing IOC management via `ioc-runner` (the `start` / `stop` / `restart` / `enable` / `disable` / `daemon-reload` paths) remains gated by sudoers — `ioc-runner` execution itself is not gated |

procServ uses `open(O_CREAT, 0644)` internally. No upstream change
is made; the systemd unit no longer carries `UMask=` so the
natural `0644` survives.

### Local mode

| Object | Owner:Group | Mode | Creator |
| --- | --- | --- | --- |
| `${LOCAL_LOG_DIR}/` (default `~/.local/state/procserv/`) | `<user>:<user>` | `0750` | `bin/ioc-runner` `do_install` local branch |
| `${LOCAL_LOG_DIR}/<ioc>.log` | `<user>:<user>` | `0640` | procServ at IOC start, with user-mode unit `UMask=0027` |

Local mode keeps `UMask=0027` in the user-mode unit. The engineer
is the only principal; `0640` ensures their primary group has
read but other users on the same host cannot read the user's
logs.

## Why Default ACLs Are Still Set

Even though procServ's hardcoded `open(0644)` mode_arg restricts
the access ACL mask to `r--` (no group write) for procServ-created
files, default ACLs still serve two purposes:

1. **Engineer-created files in the log directory** (e.g., manual
   probe files, rotated archive copies created by an engineer)
   inherit group `ioc` with `rw` access. Without the default ACL,
   an engineer-created file under default `umask 0022` would land
   at `<engineer>:<engineer-primary-group> 0644` and the
   `ioc-srv` service account could not read or write it under
   group bit. With the default ACL, such files become
   `<engineer>:ioc 0664`, preserving the ioc-srv-can-write
   invariant for the rare case.
2. **Cross-creator consistency** of group membership. setgid on
   the directory enforces the `ioc` group on every newly created
   entry regardless of creator's primary group; default ACL
   reinforces the same with explicit mask handling.

## How the Model Is Set Up

System mode setup is performed once at install time by
`setup-system-infra.bash`, running as `root` via `sudo`:

```bash
install -d -o root -g ioc -m 2770 "${SYSTEM_LOG_DIR}"
setfacl -d -m g:ioc:rw "${SYSTEM_LOG_DIR}"
setfacl -d -m o::r-- "${SYSTEM_LOG_DIR}"
setfacl -d -m m::rw "${SYSTEM_LOG_DIR}"
```

The system unit (`/etc/systemd/system/epics-@.service`) does NOT
set `UMask=`. systemd's default for system units is `0022`, which
preserves procServ's `0644` mode_arg through to the resulting
file. `LogsDirectory=procserv` is intentionally not used in the
unit — the directive would chown the log directory to the unit's
`User=`/`Group=` (`ioc-srv:ioc`) on every activation, overriding
the `root:ioc` owner that this model requires.

Local mode setup is performed by `ioc-runner --local install`
under the invoking user:

```bash
install -d -m 0750 "${LOCAL_LOG_DIR}"
```

The local user systemd template carries `UMask=0027` so that
procServ-created log files start at mode `0640`.

## Verification

System mode (after `setup-system-infra.bash` + IOC start):

```bash
stat -c '%U:%G %a' /var/log/procserv
# expected: root:ioc 2770

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

Engineer-created file in the dir (default ACL effect):

```bash
(umask 0022; touch /var/log/procserv/probe.log)
stat -c '%U:%G %a' /var/log/procserv/probe.log
# expected: <engineer>:ioc 664
```

A user outside `ioc`:

```bash
sudo -u nobody cat /var/log/procserv/<ioc>.log
# succeeds: other has r-- bit
```

Note that wide read is at the file-mode layer only. The sudoers
policy restricts the privileged `systemctl start`/`stop`/`restart`/
`enable`/`disable`/`daemon-reload` calls that `ioc-runner` makes
internally in system mode to `%ioc` group members. Non-`ioc`
users can run the `ioc-runner` binary itself and can `cat` the
log directly under `o::r--` of the default ACL, but any IOC
state change attempted through `ioc-runner` fails at the sudo
gate inside the script.

Local mode (after `ioc-runner --local install <conf>` + IOC start):

```bash
stat -c '%U:%G %a' ~/.local/state/procserv
# expected: <user>:<user> 750

stat -c '%U:%G %a' ~/.local/state/procserv/<ioc>.log
# expected: <user>:<user> 640
```

## Why This Matters (Crash Detection Context)

The 1.0.x release chain detected IOC startup crashes by scanning
`journalctl -u epics-@<name>.service` after `sudo systemctl
start`. That required engineers to be in the `systemd-journal`
group, which was fragile across Debian 13 and Rocky 8 due to
distribution-specific journal layouts and group memberships.

1.1.0 decouples crash detection from journal access by writing
procServ output to a dedicated log file under `${SYSTEM_LOG_DIR}`
and scanning that file inline in `do_start_restart`. The scan
runs in the same `ioc-runner` process that the engineer invoked
— it executes under the engineer's UID, not via `sudo`. The
permission model above is the precondition: engineers in the
`ioc` group can `stat`, `tail`, `grep` the log file directly,
without `sudo` and without `systemd-journal` group membership.

## Future Consolidation

This document captures the permission model decisions reached
during the 1.1.0 readiness session. Possible future moves:

- Merge into `LOG_LAYOUT.md` (Phase F #18) once that document
  exists, as the "Permission Model" section.
- Promote operator-facing verification commands into
  `FAQ.md` Q8/Q9 alongside existing `/opt/epics-iocs` permission
  guidance.

Either move is a docs-only revision and does not alter the
underlying model.
