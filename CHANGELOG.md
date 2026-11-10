# Changelog

## 1.4.2 - Console and Startup Reliability Release

Make console access predictable on both supported clients, report IOC startup
outcomes from what the IOC and procServ actually did, and correct the help,
completion, container autostart, and local-mode lifetime guidance that
disagreed with the runner's behavior.

### Added

- `ioc-runner attach <name> --detach-key <key>` selects the control key that
  ends one console connection; the default stays `Ctrl-A`. Accepted names are
  `ctrl-a` through `ctrl-z` except `ctrl-t`, plus `ctrl-\`, `ctrl-]`,
  `ctrl-^`, and `ctrl-_`, in either case. `ctrl-[` is rejected before any
  connection because it is the Escape byte that arrow and function keys begin
  with. Completion offers the option and example keys. (#157, #160)

### Fixes

- Both supported console clients, `con` and `socat`, now detach on `Ctrl-A`
  and consume the key, so it no longer reaches the IOC shell. The socat
  fallback previously had no escape and could only be ended from outside.
  (#157)
- `attach` and `monitor` use only `con` or `socat`; `nc` is no longer
  selected, and with neither client available both commands exit 1 with an
  installation hint. `monitor` takes read-only support from the `con` help and
  falls back to `socat` when `con` lacks it. (#157)
- procServ now ignores only `^D^C` in the system unit, the local unit, and the
  container `run` script. The former `^]` entry dropped the printable `^` and
  `]` from console input and let `Ctrl-]` through. (#157)
- `generate` no longer fails with `chmod: Operation not permitted` when the
  generated configuration is identical to the existing one and the caller is
  not its owner. It rewrites the file through the staged temporary file and a
  rename, so any `ioc` group member corrects the mode. Because that transfers
  ownership, it asks first when another user owns the file; `-f` skips the
  question, and a closed standard input refuses with exit 1. (#161)
- `start` and `restart` report the IOC child's observed nonzero exit code and
  return 1 while procServ stays active, and a genuine continued iocsh quote
  error no longer fails startup by itself. (#166)
- `start` and `restart` no longer report an initialization failure only
  because an IOC logged `sevr=fatal` and then initialized. They return 0 with a
  warning that initialization completed with error-log lines and keep the
  first three distinct severity lines; a child exit still takes priority.
  (#165)
- Local `enable` prints the linger advice that `install` already printed when
  lingering is off. (#167)
- Completion offers `log`, `-n`, and `--lines` and completes IOC names after
  `log`. The help names both line-count forms, and Container user or group
  mismatch messages name Container. (#163)
- `setup-system-infra.bash --help` and argument errors work for an ordinary
  user, because parsing runs before the root check. An invalid logrotate policy
  now reports `Setup aborted; logrotate policy not deployed.` and exits 1
  before the CLI is deployed. (#163)
- A container that boots with an enabled IOC starts it without an earlier CLI
  `start`: the generated s6 `run` script creates the socket parent directory
  (mode `0770`, service user and group) before dropping privileges, and exits
  1 before procServ if that fails. (#164)
- Local `install` no longer aborts when its log-rotation files cannot be
  written or replaced: it warns, keeps the IOC installation usable, and still
  requests the reload for changed units.
- `install` validates `site.env` only in System and Local modes; Container
  mode does not load it and installs with a malformed file.

### Documentation

- The console guides, CLI reference, FAQ, install guide, and help name each
  client's key and state that a typed detach key is consumed by the client. For
  pasted text `con` forwards the key to the IOC shell, while `socat` detaches
  at its escape byte wherever it appears. They give the `monitor` exit keys
  (`Ctrl-A` with `con`, `Ctrl-C` with `socat`), prefer `con` for production,
  and state that `socat` has not been validated for sustained heavy or burst
  IOC output. (#157)
- The FAQ entry "Why does IOC shell history report permission denied?"
  documents `.iocsh_history` ownership across principals and the
  per-principal `EPICS_IOCSH_HISTFILE` settings. (#162)
- The local guide explains that a Local IOC ends when its user manager stops
  under the host's logout policy, and that lingering keeps the manager after
  logout and at boot. (#167)
- The install guide gives the stop-and-reinstall procedure that re-renders an
  existing container service's `run` script. (#164)
- The twelve published pages were revised and supplemented against the
  current code: `CLI_REFERENCE.md` covers every command and option, and a
  glossary page was added.
- The Rocky 8 sudoers example and `docs/PERMISSION_MODEL.md` state that the
  wildcard policy used with sudo older than 1.9.10 can manage unrelated
  services.

### Tests

- The local and system lifecycle suites attach and monitor through real `con`
  and `socat` clients in a PTY with default and custom keys, and the
  error-handling suite covers the option forms and the missing-client failure.
  (#157, #160)
- A failing check that compares multi-line values records `FAIL` with a
  one-line reason and the suite continues; before, such a mismatch stopped the
  suite as `SCRIPT_ERROR`. (#159)
- The reporting self-test derives its expectations from
  `tests/reporting-counts.csv`, and source regression runs the three
  test-library self-tests. (#158)
- The lifecycle suites run original generated IOC startup fixtures for
  continued and terminating iocsh errors and for severity logs before and
  after readiness. (#165, #166)
- `tests/test-container-boot.bash` restarts a real container with s6 as PID 1
  and checks autostart, and `tests/test-install-boundaries.bash` runs the
  install under write, replacement, directory, and `site.env` faults in each
  mode. (#164)
- The multi-user Gate gains scenarios for the `log` command, the `site.env`
  layer, two operators' consoles on one IOC with a custom detach key,
  regeneration by a second operator, and an operator moving one IOC between
  modes.
- The release Gate stages the original startup generator and its module
  assignments on each consumer and passes them to the suites it runs.

### Migration

No breaking changes apart from the `nc` change in step 4. After installing the
1.4.2 runner (`make install` or the setup script):

1. System mode: re-run `bin/run-setup-system-infra.bash --full` (or
   `make setup`) so the system unit template carries the new procServ ignore
   set `^D^C`; the setup reloads systemd itself. Then restart each running IOC
   so procServ receives it.
2. Local mode: reinstall each local IOC with
   `ioc-runner --local --force install <ioc directory or conf>`, because a
   non-forced install keeps a differing user template, then restart the IOC.
3. Container mode: as root inside the container, stop each IOC and reinstall
   it with `ioc-runner --container --force install /etc/procServ.d/<name>.conf`
   to render the new `run` script, then start it.
4. Hosts that relied on `nc` for `attach` or `monitor` need `con` (preferred)
   or `socat`; without them both commands now exit 1 with an installation hint.

## 1.4.1 - Site Environment and Diagnostics Release

Layer an optional site-wide environment file under the per-IOC configuration,
add a read-only `log` command for an IOC's procServ output, and narrow the
post-initialization warning to framework severity markers so a healthy IOC's
own diagnostic text no longer triggers it.

### Added

- An optional site environment file in both systemd unit templates
  (`EnvironmentFile=-${CONF_DIR}/site.env`). A site value reaches the IOC
  environment, the per-IOC configuration still overrides it, and an absent
  file changes nothing. (#152)
- A `log` command, `ioc-runner [--local] log <name> [-f] [-n <count>]`, that
  prints the tail of the IOC's effective procServ log file, follows it with
  `-f`, and sets the tail depth with `-n` (default 40). The post-initialization
  warning now names this command in its hint. (#154)

### Fixes

- The post-initialization warning no longer fires on ordinary "error" text in a
  healthy IOC's diagnostic output. Built-in corroboration now matches
  case-sensitive framework severity markers (the uppercase `ERROR` word, the
  PVXS `ERR` and `CRIT` levels, and `sevr=major` / `sevr=fatal`) alongside the
  existing message phrases; free-form prose sensitivity moves to the per-IOC
  `CRASH_LOG_PATTERNS_EXTRA` opt-in. (#153)

### Documentation

- ADR 0003 records the site-wide environment layer under the per-IOC
  configuration, and ADR 0004 records the severity-marker corroboration
  decision with its rejected alternatives. (#152, #153)
- `docs/NETWORK_ENV.md` documents the Channel Access and PVAccess network
  environment variables, the per-IOC-over-site layering rule, and a multi-homed
  example, cross-linked from the user guide and FAQ. (#152)
- The documentation is published as an mdBook site deployed to GitHub Pages: a
  root `book.toml` over the existing `docs/`, a curated `docs/SUMMARY.md`, and a
  `.github/workflows/docs.yml` build-and-deploy workflow. (#155)

### Tests

- The local and system lifecycle suites exercise the `log` command and the
  severity-marker post-initialization path against a real IOC. (#153, #154)
- A source-regression guard pins the severity-marker and prose-token
  corroboration classes so the two match paths cannot silently converge. (#153)

## 1.4.0 - Container Execution Mode Release

Add a systemd-less container execution mode: a third lifecycle backend that
drives procServ through s6 supervision, with a matching setup mode, so the
runner manages soft IOCs inside container images without systemd.

### Added

- A `--container` lifecycle backend that manages procServ through s6
  (`s6-svscan` supervising one service directory per IOC under
  `/run/s6-procserv`), sends IOC logs to container stdout, and rejects a
  non-root EUID. Every lifecycle verb operates through this backend. (#127)
- `setup-system-infra.bash --container`: a setup mode that installs the
  accounts, configuration directory, CLI, and completion for a systemd-less
  image while skipping the systemd-only sudoers, unit template, and logrotate
  assets. (#127)

### Tests

- A container lifecycle suite (`tests/test-container-lifecycle.bash`, driven
  by `tests/run-container-tests.bash`) exercises the `--container` backend
  against a real soft IOC inside each shipped EPICS image. (#127)
- A source-regression guard requires the procServ argument list to agree
  across the system template, the local template, and the container `run`
  render, and requires completion to cover `--container`. (#127)
- Lifecycle test libraries read process state through race-tolerant `/proc`
  helpers, so a process that exits during a read no longer aborts the
  suite. (#151)

### Documentation

- Architecture, CLI, install, permission-model, and user-guide docs describe
  the container mode and its consumer contract: s6 2.13 or later on `PATH`, an
  ENTRYPOINT that runs `s6-svscan` on `/run/s6-procserv` as PID 1, and
  `setup-system-infra.bash --container` at image build. (#127)

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
- `inspect` treats a process that disappears during restart as an empty
  volatile sample while retaining hard process-inspection failures, so
  concurrent process churn no longer terminates the report. (#150)

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

Site administrators upgrading from 1.0.x:

1. Install the 1.1.0 `ioc-runner` binary.
2. Re-run `sudo ./bin/setup-system-infra.bash --full` to deploy the updated
   system systemd template and the logrotate config.
3. Run `sudo systemctl daemon-reload`, then restart each IOC; `procServ` begins
   writing to `/var/log/procserv/<name>.log`.
4. Verify the log file: `stat -c '%U:%G %a' /var/log/procserv/<name>.log`
   returns `ioc-srv:ioc 644`.
5. Remove the now-unnecessary `systemd-journal` group from IOC operator
   accounts: `sudo gpasswd -d <operator> systemd-journal`, then confirm with
   `id <operator>`.

Verify the deployment: `systemctl cat epics-@<name>.service` shows
`--logfile=`, and `logrotate -d /etc/logrotate.d/procserv` reports no errors.
The path, permission, and rotation reference is in
[`docs/LOG_LAYOUT.md`](docs/LOG_LAYOUT.md).
