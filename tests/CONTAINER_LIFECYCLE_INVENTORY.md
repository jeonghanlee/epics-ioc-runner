# Container Lifecycle Reporting Inventory

## Scope

This document is the reporting inventory for
`tests/test-container-lifecycle.bash`. It assigns a stable identity to every
assertion and every result-producing preflight, prerequisite, and early-return
branch. The suite identity is `container-lifecycle`, its scope is `container`,
and its category is `lifecycle-behavior`. Source and installed runner origins
use the same identity set.

## Inventory Basis

The suite drives the shipped `--container` backend against a real soft IOC
supervised by `s6-svscan` inside a systemd-less container image. Its expected
check and STEP counts are owned by [`reporting-counts.csv`](reporting-counts.csv).
`S02` is a setup-only STEP and owns no checks.

## Execution Boundary

The suite runs as root inside the container. The container image supplies s6
(2.13 or later), procServ, con or socat, and the EPICS base that provides
`softIoc`; the harness
[`run-container-tests.bash`](run-container-tests.bash) owns only the outermost
boundary: mounting the source tree, starting `s6-svscan` on the scan directory
so the container stdout carries the IOC output, and collecting each image's
report and exit status. `setup-system-infra.bash --container` prepares the
accounts, the configuration directory, and the scan directory before the run.

Deep `inspect` maps another account's file descriptors, so the container needs
the `CAP_SYS_PTRACE` capability; the harness adds it.

## Dependency Policy

- `P00.root-invocation` is the first boundary: container mode is root-only, so
  a non-root invocation closes every remaining check as `SKIP`.
- `P00.epics-base-set` follows, because `softIoc` is resolved from
  `EPICS_BASE`; its failure closes the remaining P00 checks and every numbered
  STEP as `SKIP`.
- The remaining P00 checks (softIoc, the six s6 binaries, a listening
  `s6-svscan`, `lsof`, `ps`, the selected runner) govern all numbered STEPs.
- `S01` infrastructure governs `S03` onward: a missing configuration
  directory, scan directory, or service account closes them as `SKIP`.
- `S10.console-tool-available` governs the monitor-isolation check.
- An unexpected abort preserves closed states and closes every remaining open
  identity as `SCRIPT_ERROR`.

## Test Method Assignment

Invocation, environment, installed-state, and ownership conditions use
`direct-inspection`. Lifecycle command behavior uses `real-path` against the
selected shipped runner. No row uses `hand-built-reproduction`.

## Stable Identity Mapping

| STEP | Check ID | Kind | Test Method | Condition or Assertion |
| --- | --- | --- | --- | --- |
| P00 | `container-lifecycle.P00.root-invocation` | `REQUIRED` | `direct-inspection` | The effective user is root. |
| P00 | `container-lifecycle.P00.epics-base-set` | `REQUIRED` | `direct-inspection` | `EPICS_BASE` is set. |
| P00 | `container-lifecycle.P00.softioc-available` | `REQUIRED` | `direct-inspection` | `softIoc` is executable under `EPICS_BASE`. |
| P00 | `container-lifecycle.P00.s6-binaries-available` | `REQUIRED` | `direct-inspection` | All six s6 binaries the runner contracts on are in `PATH`. |
| P00 | `container-lifecycle.P00.s6-svscan-listening` | `REQUIRED` | `direct-inspection` | `s6-svscanctl -z` reaches a live supervisor on the scan directory. |
| P00 | `container-lifecycle.P00.lsof-available` | `REQUIRED` | `direct-inspection` | `lsof` is available for `inspect`. |
| P00 | `container-lifecycle.P00.ps-available` | `REQUIRED` | `direct-inspection` | `ps` is available and executable. |
| P00 | `container-lifecycle.P00.selected-runner-executable` | `REQUIRED` | `direct-inspection` | The selected runner binary is readable. |
| S01 | `container-lifecycle.S01.conf-dir-exists` | `REQUIRED` | `direct-inspection` | The configuration directory exists. |
| S01 | `container-lifecycle.S01.conf-dir-writable` | `REQUIRED` | `direct-inspection` | The configuration directory is writable. |
| S01 | `container-lifecycle.S01.scan-dir-exists` | `REQUIRED` | `direct-inspection` | The scan directory exists. |
| S01 | `container-lifecycle.S01.service-account-exists` | `REQUIRED` | `direct-inspection` | The service account exists. |
| S03 | `container-lifecycle.S03.generate-exits-zero` | `BEHAVIOR` | `real-path` | `generate` exits zero against the IOC directory. |
| S03 | `container-lifecycle.S03.generated-conf-created` | `BEHAVIOR` | `real-path` | The configuration artifact is created. |
| S03 | `container-lifecycle.S03.generated-conf-uses-service-identity` | `BEHAVIOR` | `real-path` | The generated configuration carries the service user and group. |
| S04 | `container-lifecycle.S04.install-exits-zero` | `BEHAVIOR` | `real-path` | `install` exits zero. |
| S04 | `container-lifecycle.S04.installed-conf-deployed` | `BEHAVIOR` | `real-path` | The configuration is deployed to the configuration directory. |
| S04 | `container-lifecycle.S04.service-run-script-rendered` | `BEHAVIOR` | `real-path` | The s6 `run` script is rendered and executable. |
| S04 | `container-lifecycle.S04.run-script-logs-to-stdout` | `BEHAVIOR` | `direct-inspection` | The rendered `run` script passes `--logfile=-`. |
| S04 | `container-lifecycle.S04.new-service-starts-down` | `BEHAVIOR` | `real-path` | A newly installed service carries the `down` file. |
| S04 | `container-lifecycle.S04.timeout-kill-written` | `BEHAVIOR` | `real-path` | The stop grace period is written. |
| S04 | `container-lifecycle.S04.supervisor-adopted-service` | `BEHAVIOR` | `real-path` | The supervisor adopts the new service directory after the rescan. |
| S05 | `container-lifecycle.S05.start-exits-zero` | `BEHAVIOR` | `real-path` | `start` exits zero. |
| S05 | `container-lifecycle.S05.service-reports-up` | `BEHAVIOR` | `real-path` | `s6-svstat` reports the service up. |
| S05 | `container-lifecycle.S05.control-socket-created` | `BEHAVIOR` | `real-path` | The control socket is created. |
| S05 | `container-lifecycle.S05.socket-directory-owned-by-service-account` | `BEHAVIOR` | `direct-inspection` | The socket directory is owned by the service account and group. |
| S05 | `container-lifecycle.S05.procserv-runs-as-service-account` | `BEHAVIOR` | `direct-inspection` | The supervised procServ runs as the service account. |
| S05 | `container-lifecycle.S05.procserv-stdout-reaches-container-stdout` | `BEHAVIOR` | `direct-inspection` | procServ's standard output is the container's standard output. |
| S05 | `container-lifecycle.S05.no-log-file-created` | `BEHAVIOR` | `direct-inspection` | No IOC log file is created. |
| S05 | `container-lifecycle.S05.repeated-start-reports-already-running` | `BEHAVIOR` | `real-path` | A repeated `start` reports the IOC as already running. |
| S06 | `container-lifecycle.S06.status-exits-zero` | `BEHAVIOR` | `real-path` | `status` exits zero. |
| S06 | `container-lifecycle.S06.status-reports-up` | `BEHAVIOR` | `real-path` | `status` names the IOC and reports it up. |
| S07 | `container-lifecycle.S07.list-exits-zero` | `BEHAVIOR` | `real-path` | `list` exits zero. |
| S07 | `container-lifecycle.S07.list-shows-ioc-name` | `BEHAVIOR` | `real-path` | `list` shows the IOC name. |
| S07 | `container-lifecycle.S07.list-shows-active-status` | `BEHAVIOR` | `real-path` | `list` shows the active status. |
| S07 | `container-lifecycle.S07.list-shows-socket-path` | `BEHAVIOR` | `real-path` | `list` shows the socket path. |
| S07 | `container-lifecycle.S07.list-verbose-shows-supervised-pid` | `BEHAVIOR` | `real-path` | `list -v` shows the supervised PID. |
| S07 | `container-lifecycle.S07.list-verbose-reports-process-tree-memory` | `BEHAVIOR` | `real-path` | `list -v` reports a memory figure summed over the process tree. |
| S08 | `container-lifecycle.S08.view-exits-zero` | `BEHAVIOR` | `real-path` | `view` exits zero. |
| S08 | `container-lifecycle.S08.view-renders-configuration` | `BEHAVIOR` | `real-path` | `view` renders the configuration. |
| S08 | `container-lifecycle.S08.view-renders-run-script` | `BEHAVIOR` | `real-path` | `view` renders the s6 run script. |
| S09 | `container-lifecycle.S09.inspect-exits-zero` | `BEHAVIOR` | `real-path` | `inspect` exits zero. |
| S09 | `container-lifecycle.S09.inspect-references-target-socket` | `BEHAVIOR` | `real-path` | `inspect` references the target socket path. |
| S09 | `container-lifecycle.S09.inspect-attributes-executable-identity` | `BEHAVIOR` | `real-path` | `inspect` attributes the procServ executable identity. |
| S10 | `container-lifecycle.S10.console-tool-available` | `PREREQUISITE` | `direct-inspection` | A console tool is available for read-only monitoring. |
| S10 | `container-lifecycle.S10.monitor-input-securely-blocked` | `BEHAVIOR` | `real-path` | Injected input never reaches the IOC shell in monitor mode. |
| S11 | `container-lifecycle.S11.restart-exits-zero` | `BEHAVIOR` | `real-path` | `restart` exits zero. |
| S11 | `container-lifecycle.S11.restart-replaces-supervised-process` | `BEHAVIOR` | `real-path` | `restart` replaces the supervised process. |
| S11 | `container-lifecycle.S11.service-remains-up-after-restart` | `BEHAVIOR` | `real-path` | The service remains up after the restart. |
| S12 | `container-lifecycle.S12.stop-exits-zero` | `BEHAVIOR` | `real-path` | `stop` exits zero. |
| S12 | `container-lifecycle.S12.service-reports-down-after-stop` | `BEHAVIOR` | `real-path` | The service reports down after the stop. |
| S12 | `container-lifecycle.S12.supervisor-does-not-restart-stopped-service` | `BEHAVIOR` | `real-path` | The supervisor leaves a commanded stop down. |
| S13 | `container-lifecycle.S13.disable-exits-zero` | `BEHAVIOR` | `real-path` | `disable` exits zero. |
| S13 | `container-lifecycle.S13.disable-creates-down-file` | `BEHAVIOR` | `real-path` | `disable` creates the boot-time down file. |
| S13 | `container-lifecycle.S13.enable-exits-zero` | `BEHAVIOR` | `real-path` | `enable` exits zero. |
| S13 | `container-lifecycle.S13.enable-removes-down-file` | `BEHAVIOR` | `real-path` | `enable` removes the boot-time down file. |
| S13 | `container-lifecycle.S13.enable-leaves-running-ioc-untouched` | `BEHAVIOR` | `real-path` | `enable` does not disturb the running IOC. |
| S14 | `container-lifecycle.S14.non-root-invocation-rejected` | `BEHAVIOR` | `real-path` | A non-root invocation is rejected with the root requirement. |
| S14 | `container-lifecycle.S14.absent-scan-directory-rejected` | `BEHAVIOR` | `real-path` | A scan directory without a live supervisor is rejected. |
| S15 | `container-lifecycle.S15.remove-exits-zero` | `BEHAVIOR` | `real-path` | `remove` exits zero. |
| S15 | `container-lifecycle.S15.installed-conf-removed` | `BEHAVIOR` | `real-path` | The installed configuration is removed. |
| S15 | `container-lifecycle.S15.service-directory-removed` | `BEHAVIOR` | `real-path` | The s6 service directory is removed. |
| S15 | `container-lifecycle.S15.socket-directory-removed` | `BEHAVIOR` | `real-path` | The socket directory is removed. |
| S15 | `container-lifecycle.S15.no-orphan-supervisor-remains` | `BEHAVIOR` | `real-path` | No orphan supervisor survives the removal. |
