# Log Layout

Starting with 1.1.0, `procServ` writes each IOC's child output to a
dedicated log file instead of the systemd journal. Crash detection reads
that file directly. This document describes the log paths, ownership and
permissions, rotation policy, and access model for both system-wide and
`--local` modes. An operator can follow it without reading the source.

## 1. Data Flow

```text
IOC process (st.cmd)
   │  stdout + stderr
   ▼
procServ --foreground --logfile=<LOG_DIR>/<name>.log --name=<name> ...
   │  writes child output to the log file
   ▼
<LOG_DIR>/<name>.log
   ▲
   │  byte-offset scan (no journal, no sudo)
ioc-runner crash detection on start/restart
```

`procServ` runs in the foreground under systemd and is told where to write
with `--logfile`. The systemd journal still receives `procServ`'s own
stdout and stderr for service-manager diagnostics, but the IOC console
output and the crash-detection critical path live entirely in the log file.

## 2. System-mode Layout

The system log path is `/var/log/procserv` — set from `SYSTEM_LOG_DIR`
(overridable with `IOC_RUNNER_SYSTEM_LOG_DIR`) and baked into the systemd
template's `--logfile=` when the unit is deployed. `IOC_RUNNER_LOG_DIR`
does NOT change this path in system mode; it only moves where the runner
*scans* for crash patterns. If it differs from `SYSTEM_LOG_DIR` the runner
prints a foot-gun warning, because `procServ` still writes to
`SYSTEM_LOG_DIR` per the template.

| Path | Owner:Group | Mode | Created by |
| --- | --- | --- | --- |
| `/var/log/procserv/` | `root:ioc` | `2775` setgid + default ACL (`g:ioc:rw`, `o::r--`, `m::rw`) | `setup-system-infra.bash` |
| `/var/log/procserv/<name>.log` | `ioc-srv:ioc` | `0644` | `procServ` at IOC start |
| `/var/log/procserv/<name>.log.N.gz` | `ioc-srv:ioc` | `0644` | `logrotate` |

The file mode is `0644` because `procServ` creates it with a hardcoded
`open(O_CREAT, 0644)` and the system unit sets no `UMask=`, so the default
`0022` is preserved. The unit intentionally does NOT use
`LogsDirectory=`, which would chown the directory to `ioc-srv` on every
activation and break the `root:ioc` ownership the three-principal model
requires.

## 3. Local-mode Layout

The local log path is the resolved local `LOG_DIR`. By default it is
`$XDG_STATE_HOME/procserv`, falling back to
`$HOME/.local/state/procserv`; `IOC_RUNNER_LOCAL_LOG_DIR` changes that
local default, and `IOC_RUNNER_LOG_DIR` overrides the final value. The
resolved path is created by `ioc-runner --local install` and written
into the generated user unit's `--logfile=`.

| Path | Owner:Group | Mode | Created by |
| --- | --- | --- | --- |
| `<LOG_DIR>/` | `<user>:<user>` | `0750` | `ioc-runner --local install` |
| `<LOG_DIR>/<name>.log` | `<user>:<user>` | `0640` | `procServ` at IOC start |

The user-mode unit sets `UMask=0027`, which tightens `procServ`'s `0644`
mode_arg to `0640`. The single user is the only principal, so group/other
read is not required.

## 4. Access and Group Membership

| Principal | Log read | IOC management |
| --- | --- | --- |
| `ioc-srv` (daemon) | owner — writes the log | runs `procServ` |
| engineer in `ioc` | yes (group `r--`) | yes — `systemctl` via `%ioc` sudoers gate |
| user outside `ioc` (system mode) | yes — file mode `0644` grants `o+r` | no — sudoers gate denies state-changing `systemctl` |
| local-mode user | yes — owner of a `0640` file | yes — `systemctl --user` |

Reading a log never requires `systemd-journal` membership. In system mode,
wide read sits at the file-mode layer only; the access boundary for
state-changing operations is the `%ioc` sudoers gate, not the file mode.

## 5. Log Rotation

`setup-system-infra.bash` deploys `/etc/logrotate.d/procserv`:

- **Schedule:** weekly
- **Retention:** 8 rotations (8 weeks)
- **Method:** `copytruncate` — the file is copied then truncated in place,
  so `procServ` keeps writing to the same path and the UDS socket is never
  invalidated. No IOC restart is needed.
- **Archives:** `<name>.log.1.gz`, `<name>.log.2.gz`, ... (compressed)

Validate the policy with `logrotate -d /etc/logrotate.d/procserv` (dry
run) and force a rotation with `logrotate -f /etc/logrotate.d/procserv`.

## 6. Troubleshooting

| Symptom | Cause | Action |
| --- | --- | --- |
| `startup logs could not be scanned` warning | log file missing or unreadable at start | `stat <LOG_DIR>/<name>.log`; check the directory exists with the modes in section 2/3 |
| `journalctl -u epics-@<name>.service` returns empty | IOC output goes to the log file, not the journal | read `<LOG_DIR>/<name>.log` with `tail`/`grep` instead |
| log looks truncated right after rotation | `copytruncate` truncated the live file | inspect `<name>.log.1.gz` for the rotated content |
| local-mode log not found | wrong `XDG_STATE_HOME`, or linger not enabled | `ls "${XDG_STATE_HOME:-$HOME/.local/state}/procserv"` |
| engineer-created file in the dir lands at `0664` | shell `umask 0022` + directory default ACL `g:ioc:rw` | expected; `procServ`-created files stay `0644` |

## Cross-References

- Permission model: [`PERMISSION_MODEL.md`](PERMISSION_MODEL.md)
- Architecture: [`ARCHITECTURE.md`](ARCHITECTURE.md)
- System setup: [`INSTALL.md`](INSTALL.md)
