# Local Lifecycle Reporting Inventory

Status: M8 step 1 inventory
Source: `tests/test-local-lifecycle.bash`
Expected Counts: [`reporting-counts.csv`](reporting-counts.csv)

## Runner Policy

The source and installed invocations use the same catalog. No current behavior
check is exclusive to one runner origin. `local-lifecycle.P00.selected-runner-executable`
resolves the expected path from the SUITE `runner` value. A missing selected
binary is `FAIL`; all dependent checks are `SKIP`. Any other runner origin is
rejected before reporter initialization and is not part of this catalog.

## Inventory Basis

The current maximum branch contains 121 assertions. The fixed catalog adds
three P00 checks and eleven prerequisite or applicability checks for logrotate,
socat, journal, softIoc, truncate, and the non-root history boundary. It also
declares three REQUIRED checks that the current script emits only on failure:
camonitor availability and the S15 and S16 configuration requirements. The
resulting expected check and STEP counts are owned by
[`reporting-counts.csv`](reporting-counts.csv).

## Test Method Assignment

P00 checks and checks with kind REQUIRED, PREREQUISITE, or APPLICABILITY use
direct-inspection to establish the execution boundary. BEHAVIOR checks use
real-path: they execute the selected shipped runner or the external facility
whose installed behavior is under test. No current local-lifecycle catalog row
uses hand-built-reproduction.

## Catalog

### P00 - Invocation Preflight (3)

- `local-lifecycle.P00.epics-base-set` | `REQUIRED` | `EPICS_BASE` is set.
- `local-lifecycle.P00.lsof-available` | `REQUIRED` | `lsof` is available.
- `local-lifecycle.P00.selected-runner-executable` | `REQUIRED` | The selected runner path is executable.

The `EPICS_BASE` check is the first environment boundary after catalog close
and expected-count comparison. If it fails, the remaining P00 checks and every
numbered STEP check are `SKIP`; `lsof` and runner executability are not
evaluated.

### S01 - Setup Test Workspace (0)

Setup-only STEP.

### S02 - Cleanup Previous State (0)

Setup-only STEP.

### S03 - Environment Setup and Compilation (0)

Setup-only STEP. An unexpected clone or build exit closes remaining checks as
`SCRIPT_ERROR`.

### S04 - Generate Manual (1)

- `local-lifecycle.S04.manual-configuration-created` | `BEHAVIOR` | Manual configuration artifact exists.

### S05 - Install Explicit (1)

- `local-lifecycle.S05.explicit-install-succeeded` | `BEHAVIOR` | Explicit file installation deploys the configuration.

### S06 - Cleanup Installed Configuration (1)

- `local-lifecycle.S06.installed-configuration-removed` | `BEHAVIOR` | Deployed configuration is removed.

### S07 - Install by Directory (1)

- `local-lifecycle.S07.directory-install-succeeded` | `BEHAVIOR` | Directory installation deploys the configuration.

### S08 - Cleanup Installed Configuration (1)

- `local-lifecycle.S08.installed-configuration-removed` | `BEHAVIOR` | Deployed configuration is removed after directory installation.

### S09 - Cleanup Workspace Configuration (1)

- `local-lifecycle.S09.workspace-configuration-removed` | `BEHAVIOR` | Workspace configuration is removed.

### S10 - Generate Automatically (1)

- `local-lifecycle.S10.automatic-configuration-created` | `BEHAVIOR` | Native discovery creates the configuration.

### S11 - Install Explicit after Automatic Generation (1)

- `local-lifecycle.S11.explicit-install-succeeded` | `BEHAVIOR` | Explicit installation deploys the generated configuration.

### S12 - Cleanup Installed Configuration (1)

- `local-lifecycle.S12.installed-configuration-removed` | `BEHAVIOR` | Deployed generated configuration is removed.

### S13 - Install Generated Configuration by Directory (1)

- `local-lifecycle.S13.directory-install-succeeded` | `BEHAVIOR` | Directory installation deploys the generated configuration.

### S14 - Local Log Rotation Deployment (10)

The availability check governs the remaining S14 checks. When it passes, the
configuration, service, and timer are required installation artifacts. When it
skips, every dependent S14 check also skips.

- `local-lifecycle.S14.logrotate-available` | `PREREQUISITE` | `logrotate` is available.
- `local-lifecycle.S14.rotation-config-exists` | `REQUIRED` | User logrotate configuration exists.
- `local-lifecycle.S14.rotation-service-exists` | `REQUIRED` | User rotation service exists.
- `local-lifecycle.S14.rotation-timer-exists` | `REQUIRED` | User rotation timer exists.
- `local-lifecycle.S14.rotation-contract-pinned` | `BEHAVIOR` | Configuration pins directives and the local log glob.
- `local-lifecycle.S14.su-directive-absent` | `BEHAVIOR` | User configuration contains no `su` directive.
- `local-lifecycle.S14.rotation-config-valid` | `BEHAVIOR` | Configuration passes logrotate debug validation.
- `local-lifecycle.S14.rotation-timer-enabled` | `BEHAVIOR` | User rotation timer is enabled.
- `local-lifecycle.S14.repeat-install-succeeded` | `BEHAVIOR` | Repeated installation exits successfully.
- `local-lifecycle.S14.repeat-install-stable` | `BEHAVIOR` | Repeated installation rewrites no rotation artifact.

### S15 - User-Service Copytruncate Rotation (7)

The normal path starts the deployed `epics-logrotate.service`. Setting
`IOC_RUNNER_TEST_BREAK_LOGROTATE_EXECSTART=1` installs a temporary systemd
drop-in with `ExecStart=/bin/false`; the same oneshot-result check must fail,
and the suite restores the effective unit and runtime state during cleanup.
The mutation refuses a pre-existing override file or symlink and preserves a
pre-existing override directory.

- `local-lifecycle.S15.logrotate-available` | `PREREQUISITE` | `logrotate` is available.
- `local-lifecycle.S15.rotation-config-exists` | `REQUIRED` | User logrotate configuration exists for the probe.
- `local-lifecycle.S15.oneshot-result-success` | `BEHAVIOR` | The deployed oneshot succeeds through the user manager.
- `local-lifecycle.S15.compressed-archive-created` | `BEHAVIOR` | The deployed service creates `.1.gz`.
- `local-lifecycle.S15.live-log-truncated` | `BEHAVIOR` | The deployed service leaves the live log empty in place.
- `local-lifecycle.S15.runtime-state-created` | `BEHAVIOR` | The deployed service creates `%t/ioc-runner-logrotate.state`.
- `local-lifecycle.S15.system-default-state-unchanged` | `BEHAVIOR` | The deployed service leaves system logrotate state unchanged.

### S16 - Maxsize Rotation (3)

- `local-lifecycle.S16.logrotate-available` | `PREREQUISITE` | `logrotate` is available.
- `local-lifecycle.S16.rotation-config-exists` | `REQUIRED` | User logrotate configuration exists for the probe.
- `local-lifecycle.S16.maxsize-rotates-before-weekly` | `BEHAVIOR` | `maxsize` triggers rotation before the weekly interval.

### S17 - Start (1)

- `local-lifecycle.S17.service-active` | `BEHAVIOR` | Service reaches the active state.

### S18 - Status (1)

- `local-lifecycle.S18.status-shows-active` | `BEHAVIOR` | Status output reports active state.

### S19 - View (1)

- `local-lifecycle.S19.view-renders-configuration` | `BEHAVIOR` | View output includes the IOC command.

### S20 - Inspect (4)

- `local-lifecycle.S20.inspect-exits-zero` | `BEHAVIOR` | Local inspect exits successfully.
- `local-lifecycle.S20.inspect-shows-sockets` | `BEHAVIOR` | Inspect renders the UDS section.
- `local-lifecycle.S20.inspect-shows-server` | `BEHAVIOR` | Inspect renders the server process section.
- `local-lifecycle.S20.inspect-shows-client` | `BEHAVIOR` | Inspect renders the client process section.

### S21 - Inspect Bounded Runtime (4)

- `local-lifecycle.S21.socat-available` | `PREREQUISITE` | `socat` is available.
- `local-lifecycle.S21.unrelated-sockets-created` | `BEHAVIOR` | Load fixture creates at least 450 unrelated sockets.
- `local-lifecycle.S21.inspect-exits-zero` | `BEHAVIOR` | Inspect succeeds under unrelated-socket load.
- `local-lifecycle.S21.inspect-within-one-second` | `BEHAVIOR` | Inspect completes within one second.

### S22 - Restart (1)

- `local-lifecycle.S22.service-active-after-restart` | `BEHAVIOR` | Service remains active after restart.

### S23 - Stop and Restart (2)

- `local-lifecycle.S23.service-inactive-after-stop` | `BEHAVIOR` | Service becomes inactive after stop.
- `local-lifecycle.S23.service-active-after-start` | `BEHAVIOR` | Service becomes active after the following start.

### S24 - Socket and List Output (9)

- `local-lifecycle.S24.control-socket-created` | `BEHAVIOR` | Control UDS exists.
- `local-lifecycle.S24.list-shows-ioc-name` | `BEHAVIOR` | Plain list contains the IOC name.
- `local-lifecycle.S24.list-shows-socket-path` | `BEHAVIOR` | Plain list contains the UDS path.
- `local-lifecycle.S24.verbose-list-shows-pid` | `BEHAVIOR` | Verbose list contains the PID column.
- `local-lifecycle.S24.verbose-list-shows-cpu` | `BEHAVIOR` | Verbose list contains the CPU column.
- `local-lifecycle.S24.verbose-list-shows-memory` | `BEHAVIOR` | Verbose list contains the memory column.
- `local-lifecycle.S24.double-verbose-list-shows-recvq` | `BEHAVIOR` | Double-verbose list contains the receive queue column.
- `local-lifecycle.S24.double-verbose-list-shows-sendq` | `BEHAVIOR` | Double-verbose list contains the send queue column.
- `local-lifecycle.S24.double-verbose-list-shows-permission` | `BEHAVIOR` | Double-verbose list contains the permission column.

### S25 - List Option Ordering (3)

- `local-lifecycle.S25.local-list-v-parsed` | `BEHAVIOR` | `--local list -v` selects the IOC.
- `local-lifecycle.S25.list-v-local-parsed` | `BEHAVIOR` | `list -v --local` selects the IOC.
- `local-lifecycle.S25.list-local-v-parsed` | `BEHAVIOR` | `list --local -v` selects the IOC.

### S26 - User Alias (3)

- `local-lifecycle.S26.user-list-shows-ioc` | `BEHAVIOR` | `--user list` shows the local IOC.
- `local-lifecycle.S26.user-list-matches-local` | `BEHAVIOR` | `--user` and `--local` list results match.
- `local-lifecycle.S26.user-status-shows-active` | `BEHAVIOR` | `--user status` reports active state.

### S27 - Console Attach Prerequisites (3)

- `local-lifecycle.S27.socket-permission-valid` | `BEHAVIOR` | Control socket permission is `srw-rw----`.
- `local-lifecycle.S27.con-available` | `REQUIRED` | A runner-supported `con` executable is available.
- `local-lifecycle.S27.socket-listening` | `BEHAVIOR` | Control socket is listening.

### S28 - Channel Access (2)

- `local-lifecycle.S28.camonitor-available` | `REQUIRED` | `camonitor` is executable.
- `local-lifecycle.S28.expected-updates-observed` | `BEHAVIOR` | Channel Access reports the required update count.

### S29 - Monitor Input Isolation (4)

- `local-lifecycle.S29.monitor-isolation-applicable` | `APPLICABILITY` | Monitor isolation applies outside the Rocky ordinary-user journal policy.
- `local-lifecycle.S29.user-journal-available` | `PREREQUISITE` | User journal output is available.
- `local-lifecycle.S29.unit-journal-visible` | `BEHAVIOR` | Unit-attributed journal output is visible.
- `local-lifecycle.S29.monitor-input-blocked` | `BEHAVIOR` | Monitor input does not reach the IOC.

### S30 - Crash Detection (27)

- `local-lifecycle.S30.softioc-available` | `PREREQUISITE` | `softIoc` is executable.
- `local-lifecycle.S30.leading-boundary-identifier-adjacent-exits-zero` | `BEHAVIOR` | `fatal` preceded by an identifier character and followed by a boundary does not fail startup.
- `local-lifecycle.S30.leading-boundary-identifier-adjacent-success-verdict` | `BEHAVIOR` | The isolated leading-boundary case reports successful startup.
- `local-lifecycle.S30.leading-boundary-identifier-adjacent-emitted` | `BEHAVIOR` | The isolated leading-boundary fixture is present in the procServ log.
- `local-lifecycle.S30.trailing-boundary-identifier-adjacent-exits-zero` | `BEHAVIOR` | `fatal` preceded by a boundary and followed by an identifier character does not fail startup.
- `local-lifecycle.S30.trailing-boundary-identifier-adjacent-success-verdict` | `BEHAVIOR` | The isolated trailing-boundary case reports successful startup.
- `local-lifecycle.S30.trailing-boundary-identifier-adjacent-emitted` | `BEHAVIOR` | The isolated trailing-boundary fixture is present in the procServ log.
- `local-lifecycle.S30.identifier-contained-fatal-exits-zero` | `BEHAVIOR` | `fatal` adjacent to identifier characters on both sides does not fail startup.
- `local-lifecycle.S30.identifier-contained-fatal-success-verdict` | `BEHAVIOR` | The both-sides identifier case reports successful startup.
- `local-lifecycle.S30.identifier-contained-fatal-emitted` | `BEHAVIOR` | The both-sides identifier fixture is present in the procServ log.
- `local-lifecycle.S30.fatal-probe-exits-one` | `BEHAVIOR` | Pre-init FATAL probe exits one.
- `local-lifecycle.S30.fatal-probe-verdict` | `BEHAVIOR` | Pre-init FATAL probe reports failed initialization.
- `local-lifecycle.S30.silent-loop-exits-one` | `BEHAVIOR` | Silent crash-loop probe exits one.
- `local-lifecycle.S30.silent-loop-verdict` | `BEHAVIOR` | Silent crash-loop probe reports crash looping.
- `local-lifecycle.S30.parse-error-exits-one` | `BEHAVIOR` | IOC shell parse-error probe exits one.
- `local-lifecycle.S30.parse-error-verdict` | `BEHAVIOR` | IOC shell parse-error probe reports failed initialization.
- `local-lifecycle.S30.historical-fatal-exits-zero` | `BEHAVIOR` | Historical fatal content does not fail a healthy start.
- `local-lifecycle.S30.historical-fatal-success-verdict` | `BEHAVIOR` | Historical fatal probe reports successful start.
- `local-lifecycle.S30.truncate-available` | `PREREQUISITE` | `truncate` is available.
- `local-lifecycle.S30.truncated-log-exits-one` | `BEHAVIOR` | New fatal content after truncation exits one.
- `local-lifecycle.S30.truncated-log-verdict` | `BEHAVIOR` | New fatal content after truncation reports failed initialization.
- `local-lifecycle.S30.nonroot-history-probes-applicable` | `APPLICABILITY` | Read-denial history probes apply to the current user.
- `local-lifecycle.S30.history-noise-exits-zero` | `BEHAVIOR` | Benign history-load error does not fail startup.
- `local-lifecycle.S30.history-noise-success-verdict` | `BEHAVIOR` | Benign history-load probe reports successful start.
- `local-lifecycle.S30.history-noise-emitted` | `BEHAVIOR` | Fixture emitted the benign history-load error.
- `local-lifecycle.S30.history-fatal-exits-one` | `BEHAVIOR` | Real FATAL beside history noise exits one.
- `local-lifecycle.S30.history-fatal-verdict` | `BEHAVIOR` | Real FATAL beside history noise reports failed initialization.

### S31 - Runtime Extra Pattern Gates (20)

- `local-lifecycle.S31.softioc-available` | `PREREQUISITE` | `softIoc` is executable.
- `local-lifecycle.S31.wellformed-start-succeeds` | `BEHAVIOR` | Well-formed extra pattern starts successfully.
- `local-lifecycle.S31.wellformed-not-warned` | `BEHAVIOR` | Well-formed extra pattern is accepted silently.
- `local-lifecycle.S31.dot-start-succeeds` | `BEHAVIOR` | Bare-dot rejection keeps startup successful.
- `local-lifecycle.S31.dot-reason-reported` | `BEHAVIOR` | Bare-dot warning names the ordinary-text reason.
- `local-lifecycle.S31.dot-does-not-corroborate` | `BEHAVIOR` | Bare dot produces no post-init error warning.
- `local-lifecycle.S31.trailing-pipe-start-succeeds` | `BEHAVIOR` | Trailing-pipe rejection keeps startup successful.
- `local-lifecycle.S31.trailing-pipe-reason-reported` | `BEHAVIOR` | Trailing-pipe warning names empty alternation.
- `local-lifecycle.S31.trailing-pipe-does-not-corroborate` | `BEHAVIOR` | Trailing pipe produces no post-init error warning.
- `local-lifecycle.S31.invalid-regex-start-succeeds` | `BEHAVIOR` | Invalid-regex rejection keeps startup successful.
- `local-lifecycle.S31.invalid-regex-reason-reported` | `BEHAVIOR` | Invalid-regex warning names the syntax reason.
- `local-lifecycle.S31.invalid-regex-does-not-corroborate` | `BEHAVIOR` | Invalid regex produces no post-init error warning.
- `local-lifecycle.S31.positive-start-succeeds` | `BEHAVIOR` | Positive-control pattern starts successfully.
- `local-lifecycle.S31.positive-not-rejected` | `BEHAVIOR` | Positive-control pattern is not rejected.
- `local-lifecycle.S31.positive-corroborates` | `BEHAVIOR` | Positive-control pattern corroborates the post-init warning.
- `local-lifecycle.S31.spaced-start-succeeds` | `BEHAVIOR` | Spaced-assignment rejection keeps startup successful.
- `local-lifecycle.S31.spaced-reason-reported` | `BEHAVIOR` | Spaced-assignment warning names the ordinary-text reason.
- `local-lifecycle.S31.spaced-does-not-corroborate` | `BEHAVIOR` | Spaced assignment produces no post-init error warning.
- `local-lifecycle.S31.blank-start-succeeds` | `BEHAVIOR` | Whitespace-only value starts successfully.
- `local-lifecycle.S31.blank-not-warned` | `BEHAVIOR` | Whitespace-only value is a silent no-op.

### S32 - Persistence (2)

- `local-lifecycle.S32.enable-creates-link` | `BEHAVIOR` | Enable creates the default-target link.
- `local-lifecycle.S32.disable-removes-link` | `BEHAVIOR` | Disable removes the default-target link.

### S33 - Remove (2)

- `local-lifecycle.S33.configuration-removed` | `BEHAVIOR` | Remove deletes the configuration.
- `local-lifecycle.S33.service-inactive` | `BEHAVIOR` | Remove leaves the service inactive.

### S34 - Log Rotation Teardown (3)

- `local-lifecycle.S34.logrotate-available` | `PREREQUISITE` | `logrotate` is available.
- `local-lifecycle.S34.shared-timer-survives-ioc-remove` | `BEHAVIOR` | Per-IOC remove preserves the shared timer.
- `local-lifecycle.S34.manual-teardown-removes-timer` | `BEHAVIOR` | Manual teardown removes the shared timer.

### S35 - Local Install Path Resolution (13)

- `local-lifecycle.S35.namespaced-install-succeeds` | `BEHAVIOR` | Namespaced CONF_DIR, SYSTEMD_DIR, and LOG_DIR permit installation through the selected runner.
- `local-lifecycle.S35.namespaced-conf-path-used` | `BEHAVIOR` | The installed configuration is emitted under `IOC_RUNNER_LOCAL_CONF_DIR`.
- `local-lifecycle.S35.namespaced-log-path-baked-into-unit` | `BEHAVIOR` | The installed unit's `--logfile` uses `IOC_RUNNER_LOCAL_LOG_DIR`.
- `local-lifecycle.S35.precedence-install-succeeds` | `BEHAVIOR` | Unified path variables take precedence during local installation.
- `local-lifecycle.S35.unified-conf-path-used` | `BEHAVIOR` | The installed configuration is emitted under `IOC_RUNNER_CONF_DIR`.
- `local-lifecycle.S35.namespaced-conf-path-unused` | `BEHAVIOR` | No configuration is emitted under `IOC_RUNNER_LOCAL_CONF_DIR` when the unified variable is set.
- `local-lifecycle.S35.unified-run-path-baked-into-ioc-port` | `BEHAVIOR` | The installed `IOC_PORT` uses `IOC_RUNNER_RUN_DIR`.
- `local-lifecycle.S35.namespaced-run-path-unused` | `BEHAVIOR` | The installed `IOC_PORT` does not use `IOC_RUNNER_LOCAL_RUN_DIR` when the unified variable is set.
- `local-lifecycle.S35.unified-systemd-path-used` | `BEHAVIOR` | The unit is emitted under `IOC_RUNNER_SYSTEMD_DIR`.
- `local-lifecycle.S35.namespaced-systemd-path-unused` | `BEHAVIOR` | No unit is emitted under `IOC_RUNNER_LOCAL_SYSTEMD_DIR` when the unified variable is set.
- `local-lifecycle.S35.unified-log-path-baked-into-unit` | `BEHAVIOR` | The installed unit's `--logfile` uses `IOC_RUNNER_LOG_DIR`.
- `local-lifecycle.S35.xdg-state-home-unset-log-path-baked-into-unit` | `BEHAVIOR` | With log overrides and `XDG_STATE_HOME` unset, the real install emits a unit using `HOME/.local/state/procserv`.
- `local-lifecycle.S35.xdg-state-home-log-path-baked-into-unit` | `BEHAVIOR` | With log overrides unset, the real install emits a unit using `XDG_STATE_HOME/procserv`.

### S36 - M6 Shared-Asset Refresh (11)

- `local-lifecycle.S36.absent-template-deployed` | `BEHAVIOR` | An absent shared template is deployed after the abort gates.
- `local-lifecycle.S36.absent-deploy-message` | `BEHAVIOR` | The absent-template deploy emits its message.
- `local-lifecycle.S36.identical-template-kept` | `BEHAVIOR` | A reinstall with an identical template leaves it byte-identical.
- `local-lifecycle.S36.identical-no-backup` | `BEHAVIOR` | An identical reinstall creates no template backup.
- `local-lifecycle.S36.identical-no-update-message` | `BEHAVIOR` | An identical reinstall emits no update message.
- `local-lifecycle.S36.different-noninteractive-kept` | `BEHAVIOR` | A differing template run non-interactively without --force is kept.
- `local-lifecycle.S36.different-keep-message` | `BEHAVIOR` | The non-interactive keep is reported.
- `local-lifecycle.S36.force-updated` | `BEHAVIOR` | --force updates a differing template after the abort gates.
- `local-lifecycle.S36.force-backup-created` | `BEHAVIOR` | A --force update backs up the prior template.
- `local-lifecycle.S36.abort-nonzero` | `BEHAVIOR` | A declined reinstall returns nonzero.
- `local-lifecycle.S36.abort-template-unchanged` | `BEHAVIOR` | The shared template is unchanged on abort.

## Fixed Vector Rule

Every source and installed invocation declares the same identities in this
order and compares the closed catalog with `reporting-counts.csv`. Runner
origin changes the selected binary and the SUITE `runner` field, not the
identity set. Missing prerequisites and non-applicable permission branches
close their declared dependent checks without changing `Total`.
