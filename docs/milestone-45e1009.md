# Work Register

Release line: master
Milestone index: 45e1009
Canonical path: `docs/milestone-45e1009.md`
Canonical branch or ref: `master`
Git upstream: `origin/master`
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `Backlog`
Activation state: active on `master` as the post-1.3.0 reset generation

Next session entry point: the M1 (#127) plan is accepted and implementation
is authorized (2026-09-03) on branch `feature/container-execution`; start
item 1 of the Implementation Plan and project the accepted plan to issue
#127. M1 is In progress.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Runtime | M1 | (#127) Container execution mode without systemd | Milestone | In progress | No | D2, D3, D4, D5 | The runner manages a real soft IOC without systemd, existing modes remain green, and the interface satisfies the downstream Dockerfiles consumer contract; [detail](#m1---container-execution-mode) |

Tally: 1 milestone row - Complete 0, In progress 1, Not started 0, Ready 0.
Backlog is reported separately below and excluded from this tally.

### Decisions

| ID | Decision | Decision Date |
| --- | --- | --- |
| D1 | Keep #127 Deferred in Backlog until the owner assigns it to a later release cycle. | 2026-08-31 |
| D2 | Assign #127 to master work on branch `feature/container-execution`. Keep Dockerfile and runtime image changes in the Dockerfiles M1 (jeonghanlee/Dockerfiles#28), whose G1 waits for this runner capability. This supersedes D1's deferral. | 2026-09-03 |
| D3 | Adopt s6 as the container-mode supervisor; Python-based supervisors are excluded. The runner contracts only on s6 2.13 or later binaries in `PATH` (`s6-svscan`, `s6-supervise`, `s6-svc`, `s6-svstat`, `s6-svscanctl`, `s6-setuidgid`), never on s6-overlay `/init` or s6-rc; how s6 enters each image is a Dockerfiles M1 decision. Mode flag `--container` sets `EXEC_MODE=container`; the scan directory is `/run/s6-procserv`; IOC logs go to stdout; the permission model is root-only: root runs `s6-svscan` and the runner, procServ runs as `ioc-srv`, and a non-root EUID is rejected. | 2026-09-03 |
| D4 | T1 runs on the three images already shipping s6; putting s6 into them is Dockerfiles work tracked in that repository and is not a gate row here. | 2026-09-03 |
| D5 | Drive the container lifecycle suite with `tests/run-container-tests.bash` (one `docker run` per image) instead of a `--container` selector in `tests/run-all-tests.bash`: the suite runs as root inside an image, while every dispatcher child runs on the host. Report the suite under a new `container` scope and `container-lifecycle` suite identity rather than under `system`. Verify debian13 first; rocky8 and rocky10 follow once those images ship s6. | 2026-09-03 |

### Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| 45e1009 / M1 | `master`, `docs/milestone-45e1009.md`, Backlog | `master`, `docs/milestone-45e1009.md`, Milestone | this synchronization commit | this synchronization commit |

### Milestone Details

#### M1 - Container execution mode

Origin: 45e1009 / M1
Identity History: none
GitHub Issue: 127, https://github.com/jeonghanlee/epics-ioc-runner/issues/127
Status: In progress

##### Summary

A container execution mode that does not require systemd: a third lifecycle
backend that drives procServ through s6 supervision (D3). This repository owns
the runner capability; the Dockerfiles M1 (jeonghanlee/Dockerfiles#28) consumes
it through G1.

##### Scope

Add a third lifecycle backend, selected by `--container`, that manages procServ
through s6 (`s6-svscan` supervising one service directory per IOC under
`/run/s6-procserv`), plus a matching setup mode that installs accounts,
configuration, the CLI, and completion while skipping systemd-only assets
(sudoers policy, unit template, logrotate timer).

Out of scope: behavior changes to system and `--local` modes, and Dockerfile or
runtime image changes owned by the Dockerfiles M1
(jeonghanlee/Dockerfiles#28).

##### Completion Criteria

- Setup completes without `systemctl` in a systemd-less container.
- Generate, install, start, stop, restart, status, list, view, inspect, remove,
  attach, and monitor operate against a real soft IOC through the new backend.
- Existing system and local lifecycle suites remain green.
- The delivered CLI and setup contract is sufficient for
  the Dockerfiles M1 (jeonghanlee/Dockerfiles#28) to consume after
  a release.

##### Dependencies And Decisions

- D2 assigns this work to the current master generation and supersedes D1.
- D3 fixes the supervisor (s6), the mode flag, the scan directory, the log
  destination, and the permission model; the plan below implements D3.
- Behavioral constraint: system and `--local` modes keep their current
  `systemctl` call route unchanged; the container backend is a parallel
  dispatcher.
- Observed 2026-09-03: `debian:trixie-slim` provides s6 2.13.1.0 and execline
  2.9.6.1 through apt (`apt-cache policy s6 execline`), and that build exposes
  `s6-svc -D/-U/-w*/-T`, `s6-svstat -o`, `s6-svscanctl -a/-h`, and
  `s6-svlink/s6-svunlink`. Rocky 8.10 and 10.2 BaseOS, AppStream, and EPEL carry
  no s6, skalibs, or execline (`dnf install epel-release; dnf search s6
  execline skalibs`; EPEL 8/9/10 package indexes). s6-overlay 3.2.3.2
  (2026-07-16) ships static s6 2.15.1.0 and execline 2.9.9.2 (`gh release view
  -R just-containers/s6-overlay`). The s6 delivery route per image belongs to
  Dockerfiles M1.
- D4 places s6 delivery into the images with the Dockerfiles repository; T1
  runs on images that already ship s6, with no gate row here.
- Downstream Dockerfiles M1 (jeonghanlee/Dockerfiles#28)
  remains Blocked on its G1 until #127 is resolved and the container mode is
  released. This consumer condition does not block M1 implementation or
  closure.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-03, after four third-person and seven second-person
review passes on the register plan
Implementation Authorization: 2026-09-03
Superseded Plan Artifacts: none

1. `bin/ioc-runner` mode seam: add `--container` (sets `EXEC_MODE=container`,
   `SCAN_DIR=/run/s6-procserv`, `CONF_DIR=/etc/procServ.d`,
   `RUN_DIR=/run/procserv`) and make the presence check mode-specific: after
   option parsing, system and local modes require `/usr/bin/systemctl` as
   today, and container mode requires EUID 0, the six s6 binaries, and a live
   `s6-svscan` on `SCAN_DIR` (probe with `s6-svscanctl -z SCAN_DIR`, a
   side-effect-free reaper trigger that exits 0 when svscan is listening and
   100 otherwise; the `.s6-svscan/control` fifo outlives svscan, so its
   presence proves nothing), failing with a clear error otherwise. `LOG_DIR`
   has no value in container mode because logs go to stdout. Add an s6
   dispatcher beside `run_systemctl`; system and local callers keep their
   current route. Walk all 21 `EXEC_MODE` comparisons in `bin/ioc-runner` (16
   `== "system"`, 1 `!= "system"`, 4 `== "local"`) and give each three explicit
   arms: container joins the system arm where behavior is identical (conf
   0660 `root:ioc`, `/etc/procServ.d`, `/run/procserv`, the root-only
   `inspect` gate) and gets its own arm where the system arm is
   systemd-specific (sudo, unit template, `daemon-reload`, logrotate); no
   two-way else may remain that would route container into local behavior.
   Closed by T2 and T3.
2. `bin/ioc-runner` execution verbs in container mode: `install` renders
   `${SCAN_DIR}/<ioc>/run` (`s6-setuidgid ioc-srv procServ --foreground
   --logfile=- ...` with the conf values filled in), `down`, and `timeout-kill`
   (90000 ms, systemd's `TimeoutStopSec` default, since the unit template sets
   none; s6-supervise's fixed 1 s restart delay replaces `RestartSec=2`), then
   rescans with `s6-svscanctl -a`; `start` creates `RUN_DIR/<ioc>` (0770,
   `ioc-srv:ioc`), takes the launch command from the rendered `run` instead of
   `resolve_effective_launch_command` (systemd `ExecStart`), runs
   `s6-svc -u -wu -T` with `MAX_INIT_TIMEOUT` (30 s, `bin/ioc-runner:138`) as
   the timeout, and reports readiness from that wait plus the control
   socket appearing under `RUN_DIR/<ioc>`, replacing the log-file
   size/inode/tailhash startup-signal scan; `stop` `-d -wd`; `restart`
   `-r -wr`; `enable`/`disable` only remove/create the `down` file (never
   `s6-svc -U`/`-D`, which would also start/stop the IOC, unlike `systemctl
   enable`/`disable`); `status` reads `s6-svstat`;
   `remove` runs `s6-svc -d -wd`, deletes the service directory, prunes with
   `s6-svscanctl -h` (a live `s6-svscan` respawns any `s6-supervise` that exits,
   so `-x` does not apply and `-a` leaves an orphan supervisor), and removes the
   conf; `view` prints the conf and the rendered `run`. Closed by T1.
3. `bin/ioc-runner` observation verbs in container mode: `list` and `inspect`
   read `s6-svstat -o up,pid,exitcode,updownfor` for state and `/proc` for CPU
   and memory, summing procServ and its descendants found through
   `/proc/*/status` `PPid` (the IOC child runs in its own process group, so a
   pgid sum would miss it; systemd's cgroup figures covered both); every
   `LOG_DIR` path (`probe_effective_log_path`, log-file hints, log directory
   creation, logrotate notices) is skipped because logs go to stdout;
   `attach` and `monitor` are unchanged. Closed by T1.
4. `bin/setup-system-infra.bash` `--container` mode, a third invocation form
   beside the default CLI-wrapper run and `--full` (`--container` carries its
   own step set and rejects `--full`): accounts, conf directory, CLI, and
   completion as today; skip sudoers, unit template, log directory, and
   logrotate; create the `/run/s6-procserv` skeleton at build time as a
   convenience only, since the ENTRYPOINT owns its creation at container start
   (a build-time directory under `/run` survives under Docker, where `/run` is
   a plain layer directory, but not under a runtime that mounts `/run` as
   tmpfs); the preflight, moved after option parsing like the runner's,
   requires the six s6 binaries instead of `systemctl` and drops the
   `setfacl`/`getfacl`/`logrotate`/`sudo` requirement that belongs to the
   skipped steps (observed 2026-09-03:
   `jeonghanlee/debian13-epics` has no `setfacl` or `logrotate`;
   `command -v setfacl logrotate`). Closed by T1.
5. `tests/test-container-lifecycle.bash` (category `lifecycle-behavior`, method
   `real-path`), `tests/run-container-tests.bash` as its harness (D5), a
   `CONTAINER_LIFECYCLE_INVENTORY.md`, and reporting updates for the new
   `container` scope and `container-lifecycle` suite identity (contract,
   reporter matrix, validator, counts, self-tests). The harness runs the suite
   inside the three Dockerfiles images (`jeonghanlee/debian13-epics`,
   `jeonghanlee/rocky8-epics`, `jeonghanlee/rocky10-epics`) through
   `docker run`, taking s6 from the image itself; starting `s6-svscan` and
   adding `CAP_SYS_PTRACE` are the outermost boundaries the harness owns.
   Closed by T1 running green.
6. Static guards in `tests/test-source-regression.bash`:
   `test_unit_template_contract` (S16, the CI-25 guard) compares two unit
   blocks and cannot absorb a shell render, so add a new check that extracts
   the procServ argument list from the system template, the local template,
   and the container `run` render and requires the three to agree; cover
   `--container` in `bin/ioc-runner-completion.bash`. Closed by T3.
7. Documentation: `docs/ARCHITECTURE.md` (third backend),
   `docs/CLI_REFERENCE.md`, `docs/INSTALL.md`, `docs/PERMISSION_MODEL.md`
   (root-only container model: the runner rejects a non-root EUID, so the
   `ioc` group holds no operator role and remains only the owning group of
   `/run/procserv/<ioc>`), `docs/USER_GUIDE.md`, and `CHANGELOG.md`;
   state the consumer contract for Dockerfiles M1 (s6 2.13 or later in `PATH`;
   the ENTRYPOINT creates `/run/s6-procserv` and runs `s6-svscan` on it as
   PID 1; `setup-system-infra.bash --container` runs at image build). Closed
   by review.

Progress (2026-09-03, working tree, uncommitted): all seven items are
implemented under D5. The `CHANGELOG.md` entry follows the repository
convention of landing with the release changelog. T1 is green on debian13 and
waits on the rocky images shipping s6; T2 and T3 need the golden testbeds.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Container lifecycle | Run `setup-system-infra.bash --container`, then generate, install, start, stop, restart, status, list, view, inspect, remove, attach, and monitor through the shipped `--container` mode under a live `s6-svscan` | debian13, rocky8, and rocky10 Dockerfiles images, which ship s6 | Every supported verb operates against the real soft IOC without `systemctl`; procServ runs as `ioc-srv`; IOC output reaches container stdout |
| T2 | Existing modes | Run the maintained local and system lifecycle suites | Both golden OS families | Existing systemd-backed behavior remains green |
| T3 | Source regression | Run `tests/test-source-regression.bash` | Source tree | The three-way procServ-argument check passes across the system template, the local template, and the container `run` render, and completion covers `--container` |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-03, debian13 only | `jeonghanlee/debian13-epics` with s6 2.13.1.0 added by hand (the images do not ship s6 yet, D4), `docker run --cap-add SYS_PTRACE` | Partial PASS | `tests/test-container-lifecycle.bash` 64/64 PASS: every verb operated on a real softIoc as `ioc-srv`, procServ stdout resolved to the container stdout, no log file, and removal left no orphan supervisor. rocky8 and rocky10 remain unrun until those images ship s6 |
| T2 | Not run | Both golden OS families | Pending | container images cannot host T2 (it drives systemd system and user managers), so it runs on the golden VM testbeds; this host cannot build the ServiceTestIOC fixture |
| T3 | 2026-09-03 | `jeonghanlee/debian13-epics` as root with `SUDO_USER` set (docker) | Pending | S16 8/8 PASS including the four new container checks; error-handling 198/198 PASS on this host; S22 isolation and S24 launcher checks fail inside docker (no private mount namespace or sudo launcher context), so the full green run needs a golden host |

##### Closure Evidence

- none

##### GitHub Projection

Title: Add container execution mode without systemd
Labels: P3-low, feature, area/architecture
GitHub Milestone: Backlog
Observed State: open
Observed Labels: P3-low, feature, area/architecture
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-09-03; remote updated 2026-08-14T17:06:01Z
Body: the issue still carries the pre-D3 three-item plan; project D3, D4, and
the seven-item plan after Plan Acceptance.

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

No unassigned work is currently held in Backlog.

### Backlog Details

None.

## History

| Reset Date | Prior State Commit |
| --- | --- |
| 2026-09-03 | [45e10098cba886433c831e4e54c1f903b0ee8cf2](https://github.com/jeonghanlee/epics-ioc-runner/commit/45e10098cba886433c831e4e54c1f903b0ee8cf2) |
