# Changelog

## 1.3.0 - Reliability and Configuration Contract Release

Align configuration interpretation across validation, deployment, and
runtime; add bounded reliability diagnostics; and strengthen the release gate
and installed policy handling on Debian 13 and Rocky 8.

### Fixes

- Configuration validation and runtime lookups now share one bounded,
  non-executing parser. Both reader APIs normalize accepted values alike, and
  mode diagnostics report all safe user and group mismatches together.
  (#113, #129, #142)
- EPICS-dependent lifecycle suites require `EPICS_BASE` before workspace or
  systemd setup, while preserving catalog registration and terminal records
  for checks that cannot run. (#139)
- System setup restores and verifies the expected SELinux contexts for the
  sudoers and logrotate policies when SELinux is active, without adding tool
  requirements on inactive systems. (#120)

### Changed

- Lifecycle transitions resolve the effective systemd launch path, probe log
  storage availability, and report an active procServ executable mismatch
  without changing service state. (#102)
- Human-readable test reports and opt-in machine records use separate output
  paths, while suite and gate aggregation reject incomplete or inconsistent
  terminal records. (#144)

### Tests

- Expected check and STEP totals have one maintained CSV authority. Every real
  suite catalog and the six-run gate verify their independently collected
  identities and counts against it. (#148)
- Installed-system coverage exercises child recovery under the same procServ
  and the deployed local logrotate oneshot through their real systemd paths.
  (#115, #116)
- The current Rocky 8 golden image workflow is verified through provenance
  acceptance and both downstream installed-system suites. (#146)

### Documentation

- Custom service identity teardown now resolves the deployed identity and log
  path before removal and preserves resources that are not confirmed as
  dedicated. (#149)
- Release planning uses the maintained milestone-tracking skill and standing
  Gate runbook; the obsolete repository working draft is removed. (#132)

## 1.2.4 - Local Install and Setup Robustness Release

Harden the local-mode install path and the setup deploy against real operator
conditions, and tighten crash-token detection. No change to the system-mode
runtime contract. The release gate driver and its reporting inventories are
recalibrated to the cycle's check counts.

### Fixes

- Crash-token detection reconstructs the FATAL verdict from leading- and
  trailing-boundary identifier subsets, so an identifier merely adjacent to a
  fatal token no longer forces a false failed-initialization verdict while a
  true fatal token still does. (#114)
- Setup path validation expects a regular file where it deploys one: a
  directory left at a file target now fails its explicit type check instead of
  emitting a false-green success banner. (#118)
- Installed lifecycle tests honor `IOC_RUNNER_SCRIPT_DEST`, keeping
  `/usr/local/bin/ioc-runner` as the default while exercising an alternate
  destination deployed by the real Ansible role. (#145)
- `setup-system-infra.bash` creates the parent directory of a non-default
  `IOC_RUNNER_SCRIPT_DEST`, and the redirected RHEL symlink parent, before the
  staged deploy, instead of failing when the parent is absent. (#147)
- Local `--local install` defers every shared-asset deployment and daemon
  reload until after the running-service guard and the overwrite-abort prompt,
  so a declined install no longer changes the systemd template every local IOC
  shares. The template refresh is diff-aware: an identical template is kept
  untouched, and a differing one defaults to keep unless `-f/--force` updates
  it, reporting the running IOCs the change would affect. (#117)
- Local logrotate validation passes an explicit throwaway `--state` to
  `logrotate -d`, so a root-owned system default state file left by an earlier
  system run no longer blocks an unprivileged user's rotation deploy. (#143)

### Changed

- The two-host gate suite driver and the reporting inventories are recalibrated
  to the cycle's check counts (688 checks, 170 steps); the driver's expected
  vector self-enforces on every gate run and the per-suite identity totals are
  kept current.

## 1.2.3 - Verification Integrity Release

Make the release gate complete, repeatable, and machine-checkable. This cycle
has one product robustness fix: clean checkouts relocated by `tar`, `cp -a`,
or snapshot restore no longer report a false `-dirty` version stamp. The
remaining changes strengthen the standing two-OS release procedure and its
test evidence without changing IOC runtime behavior.

### Fixes

- Version stamping now compares tracked content instead of trusting cached
  index stat data. The setup installer, live `-V` fallback, and user-install
  injector all preserve a bare hash for a relocated clean checkout, retain
  `-dirty` for a real modification, and work when the index cannot be updated.
  (#133)
- Test tool checks resolve `logrotate` and `con` through the same absolute
  search paths as the runner. A usable tool is no longer skipped merely
  because a non-login user's `PATH` omits its directory. (#136)

### Changed

- The release gate now has one standing procedure under `gate/`, with shipped
  control-side and host-side drivers for the six suite runs, the
  `root_squash` deployment path, and all fourteen multi-user scenarios. Each
  run pins the prior release baseline in the golden manifest and validates
  the retained checkout and installed runner before deployment. (#130, #131,
  #134)
- Every declared test check now reaches exactly one terminal state: `PASS`,
  `FAIL`, `SKIP`, `NA`, or `ERROR`. Suite summaries and machine-readable
  records come from the same ledger, include cleanup failure in the final
  suite state, and let the collector reject missing, duplicate, malformed, or
  non-final records. (#135, #137)
- Source-tree setup, Git, metadata, and path contracts now live in a dedicated
  source-regression suite. System-infrastructure checks cover only installed
  host conformance, so each suite runs in the privilege context its assertions
  require. (#138)
- Rocky 8 records local monitor-isolation checks as not applicable when the
  ordinary user has no useful user-journal path; Debian 13 continues to run
  the real checks. The release does not broaden journal access. (#141)

### Tests

- The gate collector validates the fixed two-host execution matrix and refuses
  an overall pass when any required suite, mode, check identity, or final
  reporter record is absent.
- The shipped scenario driver reports one verdict for each of the three local
  and eleven system multi-user scenarios, preserving per-scenario evidence and
  refusing an empty or incomplete run.
- Relocated-checkout regression coverage exercises all three version-stamp
  sites with clean, modified, and locked-index fixtures through the shipped
  source path. (#133)

### Documentation

- The former per-cycle test plans are replaced by `gate/RUNBOOK.md`, which
  defines golden acceptance, fresh-consumer requirements, suite modes,
  `root_squash` verification, multi-user scenarios, evidence retention, and
  failure boundaries in one standing procedure. (#131, #134)
- `tests/REPORTING_CONTRACT.md` and the suite inventories define the stable
  check identities, applicability rules, terminal states, and aggregation
  invariants used by the release gate. (#137, #138)

## 1.2.2 - Deployment Path Patch

Five deployment-path and validation-path defects, no redesign. The
cycle exists because the version-stamp layout guard added in 1.2.1
re-broke, through a different cause, the root_squash stamping symptom
1.2.1 had closed. Every change was review-converged and suite-pinned,
and the consolidated patch was verified on freshly baked golden images
at the release gate.

### Fixes

- Version stamping works again on an NFS `root_squash` home: the
  layout guard now runs its three checks as the same delegated
  principal as the git queries it guards, and its tracked-file check
  uses repository-top-anchored pathspecs, which a plain relative
  pathspec could not satisfy from inside `bin`. All three documented
  entry points — `sudo bash bin/setup-system-infra.bash`, and
  `make install` / `make setup` run as your own user — stamp a real
  short hash and commit date again. When the metadata genuinely cannot
  be read, the warning now carries the manual repair that restores
  `-V`. (#128)
- A `CRASH_LOG_PATTERNS_EXTRA` value is judged the same way at runtime
  as at install: both call sites share one classifier, so a value that
  install rejects no longer slips through at start, and a value written
  with spaces around `=` reaches the same verdict either way. A
  whitespace-only value is a silent no-op instead of a spurious
  warning. Each runtime warning names the reason in plain terms and
  tells the operator to fix the value and re-run `install`; the base
  pattern set stays active throughout. (#122)
- `view` on a missing configuration sends its closing divider to
  stderr with the error, so stdout no longer carries a stray divider;
  `generate` names the directory it could not write to instead of
  leaking the raw `mktemp` line; and the local-mode `install`
  permission hint no longer suggests `ioc` group membership that local
  mode does not use. (#121)
- `view`, `attach`, and `monitor` name the real barrier when the
  configuration directory exists but is unreadable to the caller,
  rather than reporting the IOC as not found — the honest-report work
  of 1.2.1 reached the mutation verbs but not the observers. (#121)

### Changed

- A byte-identical `generate` re-run reasserts the configuration file
  mode instead of leaving a hand-loosened one as found; the
  "already up-to-date" skip no longer bypasses the permission the
  installed file is supposed to carry. (#123)
- `setup` stops rotating the runner's three-slot backup history on a
  no-change redeploy: the three `RUNNER_*` stamp lines, which differ on
  every run by construction, are excluded from the comparison that
  decides whether a backup is warranted. A real source change still
  produces exactly one. (#123)

### Tests

- The error suite grew from 188 to 206 assertions, pinning the shared
  pattern classifier and all four message-and-stream fixes with real
  filesystem permissions rather than stubs; each case asserts that the
  barrier branch actually ran, so a green cannot come from a skipped
  path. The local lifecycle suite gained seven runtime re-validation
  cases that the install-only fixtures cannot reach. (#121, #122)
- The system-infra suite gained two permanent every-run assets: a real
  run of the stamping step observing what a genuine checkout produces
  versus what `bin/` copied into an unrelated repository produces, and
  a backup-suppression check driven through an isolated backup
  directory. Both replace reproduction-style probes with observations
  of the shipped path. (#123, #128)

### Documentation

- The `INSTALL.md` NFS `root_squash` section is reconciled with the
  restored behavior: it names the three entry points that work in
  place, states that `make setup` runs as your own user rather than
  under `sudo`, re-anchors its verification note to the current golden
  images, and documents the manual stamp repair that matches the
  warning text. The FAQ's runtime sentence on
  `CRASH_LOG_PATTERNS_EXTRA` matches the shared verdict. (#122, #128)

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
