# Changelog

## 1.2.1 - Stability Patch

Make what 1.2.0 already does honest and robust, with no redesign.
Every change was review-converged and suite-pinned; the consolidated
patch was verified on both golden images at the release gate.

### Fixes

- `setup` now exits 1 when post-setup verification fails, printing a
  failure banner; a missing or unreadable verify target is counted as
  a failure instead of aborting the run mid-verify. (#104)
- Lifecycle verbs tell the truth about unknown names: `stop`,
  `enable`, `disable`, and `remove` on a never-installed IOC hard-error
  instead of exiting 0 (a typo previously succeeded silently, and
  `remove` reported success); `remove` verifies its outcome and
  surfaces the captured systemctl stderr; `view` exits nonzero on a
  missing configuration. In local mode, a supplied `IOC_PORT` that does
  not match the standard per-IOC socket path is rewritten to it with a
  warning instead of silently. (#105)
- A non-compiling `CRASH_LOG_PATTERNS_EXTRA` can no longer silently
  disable the whole crash-pattern set at runtime: the value is
  re-validated at every start/restart (warn and ignore, base patterns
  stay active), install additionally rejects empty alternations and
  degenerate match-everything patterns, and a `restart` of a
  still-running IOC warns when the .conf was edited after the unit was
  activated, since that restart applies unvalidated edits. (#106)
- The `nc` / `con` console capability probes capture help output
  before testing it, so a usage exit or SIGPIPE under pipefail no
  longer discards a usable tool. (#110)
- `make uninstall` no longer dies with a bare `sudo: a password is required`;
  it prints the same cached-credentials guidance `make install` and
  `make setup` gained in #119. (#124)

### Changed

- Both systemd unit templates emit `RuntimeDirectoryPreserve=restart`,
  so an IOC's runtime socket directory survives automatic restarts and
  is removed only on stop. The start/restart confirmation dwell now
  carries rotation fingerprints and a final death-banner check, so a
  crash loop hidden behind a log rotation is no longer reported as a
  successful start. (#108)
- Every deployed artifact (the runner, the unit template, the bash
  completion, and generated `.conf` files) is staged inside its target
  directory and renamed into place atomically; `generate` no longer
  depends on `TMPDIR` and writes `0660` in system mode. (#107)
- Local `start` / `restart` warn when the resolved log directory
  diverges from the value baked into the installed unit, or when the
  installed `IOC_PORT` no longer matches the runtime directory.
  `CONF_DIR` must be absolute and whitespace-free, `IOC_CHDIR` must be
  absolute, and `IOC_CMD` must be a single word. (#109)
- `setup` resolves procServ before mutating anything, skips
  content-identical backups, reads the deployed default ACLs back to
  verify them, refuses to stamp a foreign repository's HEAD as the
  version, and prints the resolved service identity before first use.
  Local `list` warns when the log-rotation timer is installed but
  inactive. (#110)
- `sudo make setup` (and other nested-sudo invocations) once stamped
  the version as `unknown`; the git delegation now recovers the
  repository owner, and an unstampable build warns instead of failing
  silently. (#119)

### Tests

- The error suite grew from 148 to 188 assertions, pinning every new
  contract above plus a behavioral charset-parity guard between the
  IOC-name rule and the sudoers pattern. Lifecycle status and view
  assertions were retargeted from substrings that could never fail to
  exact tokens; state-wait timeouts now fall through to counted
  assertions; the monitor-isolation tests gained a journal positive
  control. (#111)

### Documentation

- Operator-facing docs were aligned with the code across eight files:
  the direction-reversed socat monitor fallback (the old documented
  command would have written into the console), the pass-through /
  revival / corroboration semantics in the FAQ, local rotation and
  drift-warning sections, socket permission truth (`0770` directory /
  `0660` socket), the setup exit contract, and uninstall reversal steps
  with a log-retention statement. Reviewed-and-kept divergences were
  recorded in an examined-keep ledger in the milestone register. Four
  warning strings introduced this cycle had their em-dash punctuation
  replaced with ASCII. (#112, #126)

### Operational Notes

These are cases where a verb that previously returned success (exit 0)
on a no-op or an error now exits 1; a site that wraps these verbs in
automation and relied on the old exit 0 should add explicit handling.

- `stop` / `enable` / `disable` / `remove` on a never-installed IOC
  name now exit 1 (previously 0; `remove` even reported success). (#105)
- `setup` exits 1 when post-setup verification fails (previously 0
  with a success banner). (#104)
- `view` exits 1 on a missing configuration (previously 0). (#105)
- Plain `list` no longer aborts when `ss` is absent; `list -vv` fails
  with a named error instead. (#105)

## 1.2.0 — Restart Supervision Release

### New Features

- Restart supervision (C1+H, ADR 0001): both unit copies carry
  `Restart=always` with `StartLimitIntervalSec=0` / `StartLimitBurst=5` /
  `StartLimitAction=none`, `RestartSec=2`, and `KillMode=mixed`. A
  crash-looping IOC stays `activating (auto-restart)` and never reaches
  systemd `failed`; procServ-death recovery is bounded at ~2.3 s
  (vs ~92 s under `control-group`). (#54)
- Startup readiness polling replaces the fixed `sleep 5`: `start` /
  `restart` poll the procServ log for the initialization marker, report
  a fatal token or a recurring death banner before the marker as a
  failed initialization (exit 1), watch a short post-marker dwell for
  crash loops, and downgrade marker-less-but-active starts to a
  warning. (#67)
- Silent crash-loop detection: a pre-iocInit loop that emits no fatal
  token is caught by the recurring death-banner count. (#52)
- Local-mode procServ log rotation: `--local install` deploys a
  per-user logrotate config plus `epics-logrotate.{service,timer}`
  (hourly timer, `maxsize 50M`, weekly, `rotate 8`, `copytruncate`)
  idempotently; the shared timer is never auto-removed by a per-IOC
  `remove`. (#103)
- System service account and group configurable from a single source
  (`IOC_RUNNER_SYSTEM_USER` / `IOC_RUNNER_SYSTEM_GROUP`); defaults
  unchanged. (#87)
- Observer `list` prints a permission hint when socket directories are
  not readable by the invoking user. (#94)

### Fixes

- Crash-warning false positive after a manual `st.cmd` run removed via
  a line-targeted `CRASH_LOG_EXCLUDE_PATTERNS` pre-filter; the FAQ
  history knob corrected. (#92)
- Interactive abort exit codes unified: declining any install or
  generate prompt (`n` or EOF) exits 1. (#93)
- Install precheck hint now names the effective
  `EPICS_IOCSH_HISTFILE` knob (#97), and the history-disable guidance
  uses the EPICS-documented empty-string form. (#101)

### Hardening

- A shared-contract guard pins the must-agree rows across the two
  procServ unit-template copies; a one-sided edit fails the error
  suite. `--autorestartcmd=''` lands in both copies, closing the `^T`
  autorestart-toggle foot-gun. (#81)
- The git-metadata injection contract is pinned by a guard test across
  the runner and both installers. (#84)
- Examined-Keep dispositions recorded: the unit dependency set is kept
  with the `network-online.target` exclusion documented (#53); the
  validating `systemctl` wrapper is reviewed and not adopted, keeping
  the documented sudoers residual accepted (#68); the socket-path
  alias is kept (#86); the examined-Keep to guard promotion test is
  the Ledger standing rule. (#100)

### Tests

- Subshell assertions reach the suite counters, with a permanent
  executed-vs-counted tripwire. (#98)
- Stale install-decline exit-code assertion corrected in the
  system-lifecycle suite (#99); the no-op `IOCSH_HISTSIZE` history
  knob removed from the lifecycle probes. (#96)
- Multi-user test plan gains the User Fixtures table, an Execution
  Harness (pty/EOF, payload locations, state paths), and the full-run
  rationale; executed on both golden images as the release gate.

### Migration

No breaking changes. Install the 1.2.0 runner, then re-run
`setup-system-infra.bash --full` plus `systemctl daemon-reload` so
deployed system units pick up the restart-supervision directives;
local IOCs pick them up (and the log rotation) on the next
`--local install` of the IOC.

## 1.1.1 — Install Tooling Release

### New Features

- Modular Makefile install front end (EPICS `configure/` pattern):
  `make install` / `make setup` for the system path, `make install.user`
  for a no-root `~/.local/bin` copy with version injection;
  `CONFIG_SITE.local` overrides the user-home path. (#72)
- `--user` accepted as an alias for `--local` runtime mode, aligning
  with `systemctl --user`. (#73)
- procServ resolution overridable via `IOC_RUNNER_PROCSERV_TOOL`
  (mirroring the existing `IOC_RUNNER_CON_TOOL`); `~/.local/bin`
  prepended to both tool search lists, gated on a trusted `HOME`. (#74)

### Fixes

- Generated units emit `StandardOutput=journal`, clearing the Debian 13
  systemd warning about the obsolete `syslog` output type; applies to
  both the local user unit and the system template. (#75)
- Lifecycle STEP 24 Channel Access test isolated from co-located IOCs
  via a dedicated `EPICS_CA_SERVER_PORT`. (#76)

### Hardening

- System-mode chdir precheck rejects any `..` component in `IOC_CHDIR`
  as a hard error — no confirmation prompt, no `--force` bypass. (#66)
- `IOC_RUNNER_*_TOOL` overrides require a regular executable file
  (`-f && -x`); an executable directory is rejected. (#78)

### Tests

- Lifecycle suites select the runner binary explicitly via
  `IOC_RUNNER_TEST_MODE` (source/installed) and log the resolved
  binary; the error suite runs standalone. (#69)
- Error suite host-independent of procServ via a `_setup` mock. (#77)
- Multi-user test plan added (`docs/testplan.md`) and executed on both
  golden images as the release gate. (#91)

### Documentation

- Docs aligned with current behavior: tool resolver order, the
  `IOC_RUNNER_PROCSERV_PATH` setup override, the rocky8 sudoers example
  path, mode-qualified help text, and testplan/FAQ wording.
  (#79, #80, #82, #88, #89, #90, #95)

### Migration

No breaking changes. Install the 1.1.1 runner (`make install` or the
setup script). Existing deployed units keep running; to pick up the
`journal` output type, re-run `setup-system-infra.bash --full` plus
`systemctl daemon-reload` (system) or reinstall the IOC (local).

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

Install the 1.1.0 runner, re-run `setup-system-infra.bash --full`, reload systemd
and restart IOCs, verify the log file mode, and remove the now-unnecessary
`systemd-journal` group from operator accounts. Step-by-step instructions
are in the "Upgrading from 1.0.x" section of [`docs/README.md`](docs/README.md);
the path, permission, and rotation reference is in
[`docs/LOG_LAYOUT.md`](docs/LOG_LAYOUT.md).
