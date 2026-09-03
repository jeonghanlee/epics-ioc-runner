# Work Register

Release line: master
Milestone index: 45e1009
Canonical path: `docs/milestone-45e1009.md`
Canonical branch or ref: `master`
Git upstream: `origin/master`
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `Backlog`
Activation state: active on `master` as the post-1.3.0 reset generation

Next session entry point: no work is Ready. M1 (#127) remains the only
unassigned Backlog item and stays Deferred until the owner assigns it to a
later release cycle.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

No work is currently assigned to master.

### Decisions

| ID | Decision | Decision Date |
| --- | --- | --- |
| D1 | Keep #127 Deferred in Backlog until the owner assigns it to a later release cycle. | 2026-08-31 |

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| | M1 | (#127) Container execution mode without systemd | Milestone | Deferred | No | D1 | D1 defers it to a later release cycle as a standalone feature; [detail](#m1---container-execution-mode) |

### Backlog Details

#### M1 - Container execution mode

Origin: 45e1009 / M1
Identity History: none
GitHub Issue: 127, https://github.com/jeonghanlee/epics-ioc-runner/issues/127
Status: Deferred

##### Summary

A container execution mode that does not require systemd.

##### Scope

Add a third lifecycle backend that manages procServ without systemd, plus a
matching setup mode that installs accounts, configuration, the CLI, and
completion while skipping systemd-only assets.

Out of scope: behavior changes to system and `--local` modes, and container
image definitions in another repository.

##### Completion Criteria

- The owner assigns the new execution mode to a release line.
- Setup completes without `systemctl` in a systemd-less container.
- Generate, install, start, stop, list, attach, and monitor operate against a
  real soft IOC through the new backend.
- Existing system and local lifecycle suites remain green.

##### Dependencies And Decisions

- D1 defers this work to a later release cycle as a standalone feature.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define a systemd-free procServ lifecycle backend and its state ownership.
2. Add matching setup behavior that installs non-systemd assets only.
3. Exercise the supported verbs against a soft IOC in a systemd-less image.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Container lifecycle | Run setup, generate, install, start, stop, list, attach, and monitor through the shipped container mode | Debian and Rocky systemd-less containers | Every supported verb operates against the real soft IOC without `systemctl` |
| T2 | Existing modes | Run the maintained local and system lifecycle suites | Both golden OS families | Existing systemd-backed behavior remains green |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Systemd-less containers | Pending | none |
| T2 | Not run | Both golden OS families | Pending | none |

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

## History

| Reset Date | Prior State Commit |
| --- | --- |
| 2026-09-03 | [45e10098cba886433c831e4e54c1f903b0ee8cf2](https://github.com/jeonghanlee/epics-ioc-runner/commit/45e10098cba886433c831e4e54c1f903b0ee8cf2) |
