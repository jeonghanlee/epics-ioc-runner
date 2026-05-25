# Changelog

## 1.1.0 — Journal Decoupling Release

### Breaking Changes

- Crash detection source changed from the systemd journal to the procServ
  log file. The runner performs a byte-offset scan of the log file and no
  longer reads the journal. (#11)
- IOC console output moved to dedicated procServ log files — under
  `/var/log/procserv/` (system) or `$XDG_STATE_HOME/procserv` (local) —
  instead of the journal. (#9, #10)

### New Features

- `LOG_DIR` configuration variables: `IOC_RUNNER_SYSTEM_LOG_DIR`,
  `IOC_RUNNER_LOCAL_LOG_DIR`, `IOC_RUNNER_LOG_DIR`. (#8)
- systemd templates emit a per-IOC log file via procServ `--logfile`. (#9, #10)
- logrotate policy at `/etc/logrotate.d/procserv`: weekly, 8-week
  retention, `copytruncate` (no IOC restart, UDS socket preserved). (#15)
- Byte-offset crash detection that scans only new log content on each
  start/restart. (#11)

### Fixes

- `ioc-runner inspect` Netlink/UDS rendering on Rocky 8. (#49)
- Local-lifecycle crash detection on Rocky 8 with an inactive user
  journal. (#50)

### Hardening

- Operator accounts no longer require `systemd-journal` membership; crash
  detection runs at the engineer UID against the log file. (#17)
- Log file permission model: system `0644` (`ioc-srv:ioc`, readable at the
  file-mode layer), local `0640`; directory `2775`/`0750`. State-changing
  operations remain gated by the `%ioc` sudoers policy. (#12)
- Journal fallback in crash detection dropped as won't-fix; an unreadable
  log yields a could-not-scan warning rather than a journal scan. (#24)

### Migration

Install the 1.1.0 runner, re-run `setup-system-infra.bash`, reload systemd
and restart IOCs, verify the log file mode, and remove the now-unnecessary
`systemd-journal` group from operator accounts. Step-by-step instructions
are in the "Upgrading from 1.0.x" section of [`docs/README.md`](docs/README.md);
the path, permission, and rotation reference is in
[`docs/LOG_LAYOUT.md`](docs/LOG_LAYOUT.md).
