# Work Register

Release line: master
Milestone index: 46790f9
Canonical path: `docs/milestone-46790f9.md`
Canonical branch or ref: `master`
Git upstream: `origin/master`
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `Backlog`
Activation state: active on `master` as the post-1.2.4 reset generation

Next session entry point: no work is Ready. M2 (#127) remains the only
unassigned Backlog item and stays Deferred until the owner assigns it to a
later release cycle.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

No work is currently assigned to master.

### Decisions

| ID | Decision | Source |
| --- | --- | --- |
| D1 | #120 items 1 and 2 are examined-Keep and were retired; only item 3 (SELinux) remains, and it stays closed until the owner confirms a production SELinux-enforcing environment. | Owner decision, 2026-07-28; recorded in `CLOSED_DOORS.md` CI-29 |
| D2 | Open 1.3.0 as a reliability-and-configuration-contract line. Transfer M4-M13 (#102, #115, #113, #129, #142, #139, #116, #144, #148, #132) to `docs/milestone-1.3.0.md` on `release-1.3.0`. #127 (M2) stays deferred as a standalone feature for a later cycle. This supersedes the prior generation's 1.3.0 targeting decision, retained at the History commit. | Owner decision, 2026-08-17 |
| D3 | The obsolete `cloud-provision` 2026-06-03 Rocky golden target was retired without claiming its downstream check passed. Validation of the current image-workflow Rocky golden is carried as independent Backlog work in this repository; it does not block any release. | Owner selection of the Backlog carry-forward and repository boundary, 2026-08-16 |
| D4 | Assign M3 (#146) and M1 (#120 item 3) to the 1.3.0 release after its current M11, in that order. M3 becomes Not started when authority moves. M1 remains Conditional until a production SELinux-enforcing IOC host is confirmed. The final release milestone follows both items. This supersedes D3's independent Backlog placement and retains D1's activation condition. | Decision Date: 2026-08-30 |

### Assignment History

| Identity | From | To | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| 46790f9 / M4 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `d8493660ef2d92b34d05949a59dba5ca156e96c6` | this synchronization commit |
| 46790f9 / M5 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `d8493660ef2d92b34d05949a59dba5ca156e96c6` | this synchronization commit |
| 46790f9 / M6 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `d8493660ef2d92b34d05949a59dba5ca156e96c6` | this synchronization commit |
| 46790f9 / M7 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `d8493660ef2d92b34d05949a59dba5ca156e96c6` | this synchronization commit |
| 46790f9 / M8 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `d8493660ef2d92b34d05949a59dba5ca156e96c6` | this synchronization commit |
| 46790f9 / M9 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `d8493660ef2d92b34d05949a59dba5ca156e96c6` | this synchronization commit |
| 46790f9 / M10 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `d8493660ef2d92b34d05949a59dba5ca156e96c6` | this synchronization commit |
| 46790f9 / M11 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `d8493660ef2d92b34d05949a59dba5ca156e96c6` | this synchronization commit |
| 46790f9 / M12 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `d8493660ef2d92b34d05949a59dba5ca156e96c6` | this synchronization commit |
| 46790f9 / M13 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `d8493660ef2d92b34d05949a59dba5ca156e96c6` | this synchronization commit |
| 46790f9 / M3 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `36396b371464575ad325d3ed0bd18b02281495d8` | this synchronization commit |
| 46790f9 / M1 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `36396b371464575ad325d3ed0bd18b02281495d8` | this synchronization commit |

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| | M2 | (#127) Container execution mode without systemd | Milestone | Deferred | No | D2 | D2 defers it to a later cycle as a standalone feature; [detail](#m2---container-execution-mode) |

### Backlog Details

#### M2 - Container execution mode

Origin: 46790f9 / M2
Identity History: none
GitHub Issue: 127, https://github.com/jeonghanlee/epics-ioc-runner/issues/127
Status: Deferred

##### Summary

A container execution mode that does not require systemd.

##### Scope

Add a third lifecycle backend that manages procServ without systemd, plus a
matching setup mode that installs accounts, configuration, the CLI, and
completion while skipping systemd-only assets.

##### Out of Scope

Behavior changes to system and `--local` modes, and container image
definitions in another repository.

##### Completion Criteria

- The owner assigns the new execution mode to a release line.
- Setup completes without `systemctl` in a systemd-less container.
- Generate, install, start, stop, list, attach, and monitor operate against a
  real soft IOC through the new backend.
- Existing system and local lifecycle suites remain green.

##### Dependencies And Decisions

- D2 defers this work to a later cycle: it adds a complete new lifecycle
  backend and does not fit the 1.3.0 reliability-and-configuration theme.

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
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:45Z

## History

| Reset Date | Prior State Commit |
| --- | --- |
| 2026-08-17 | `46790f9ed9b725e700cc3607e195ea706ca383d8` |
