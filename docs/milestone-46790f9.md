# Work Register

Release line: master
Milestone index: 46790f9
Canonical path: `docs/milestone-46790f9.md`
Canonical branch or ref: `master`
Git upstream: `origin/master`
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `Backlog`
Activation state: active on `master` as the post-1.2.4 reset generation

Next session entry point: The 1.3.0 line is open. Authority for the ten
selected items moved to `docs/milestone-1.3.0.md` on `release-1.3.0` at
target commit `d849366`. This register holds only the M1-M3 Backlog; current
work continues on `release-1.3.0` (version 1.3.0-dev).

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

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| | M1 | (#120 item 3) SELinux context on the setup deploys, RHEL-only | Milestone | Conditional | No | D1 | The owner confirms production hosts run SELinux enforcing; [detail](#m1---selinux-context) |
| | M2 | (#127) Container execution mode without systemd | Milestone | Deferred | No | D2 | D2 defers it to a later cycle as a standalone feature; [detail](#m2---container-execution-mode) |
| | M3 | (#146) Validate the current Rocky 8 golden through downstream runner suites | Carry-forward | Deferred | No | D3 | A fresh consumer from the current image workflow passes the shipped system-infrastructure and system-lifecycle suites with exact image and runner identities recorded; [detail](#m3---current-rocky-golden-downstream-validation) |

### Backlog Details

#### M1 - SELinux context

Origin: 46790f9 / M1
Identity History: none
GitHub Issue: 120, https://github.com/jeonghanlee/epics-ioc-runner/issues/120
Status: Conditional

##### Summary

Items 1 and 2 are examined-Keep decisions, not pending implementation. Only
the SELinux context of setup deployments into `/etc` remains, conditional on
the owner confirming a production SELinux-enforcing IOC host.

##### Scope

On an enforcing production host, record the expected contexts for the sudoers
and logrotate targets, run the shipped setup path, and compare the resulting
contexts and policy acceptance. If a mismatch is observed, implement the
smallest cross-distribution correction and a real-path final-context check.

##### Out of Scope

Reopening items 1 or 2 without new reachability evidence, or treating a
non-enforcing golden as proof of production SELinux behavior.

##### Completion Criteria

- The named condition is observed: the owner confirms a production
  SELinux-enforcing environment. The row then moves to Not started.
- The real setup deployment records expected and observed contexts for both
  `/etc` targets before any correction is selected.

##### Dependencies And Decisions

- D1

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Confirm an owner-authorized production IOC host is SELinux enforcing.
2. Record `getenforce`, filesystem boundaries, `matchpathcon` expectations,
   and existing target contexts.
3. Run the shipped setup deployment and compare resulting contexts and policy
   acceptance.
4. Only after an observed mismatch, select and verify a correction supported
   by the target distributions.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Activation condition | Read the production host SELinux mode with owner authorization | Production IOC host | `Enforcing` is observed before investigation begins |
| T2 | Deployment context | Run the shipped setup path and compare `matchpathcon` with resulting target contexts | Same enforcing host | Both deployed policies carry their expected contexts and are accepted by their consumers |
| T3 | Regression | If T2 finds a mismatch, rerun the real setup path with the correction present | Supported enforcing targets | A wrong final context fails the check and the corrected context passes |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Production IOC host | Pending | none |
| T2 | Not run | Production IOC host | Pending | none |
| T3 | Not run | Supported enforcing targets | Pending | none |

##### Closure Evidence

- Items 1 and 2 are retired as examined Keep in `docs/CLOSED_DOORS.md` CI-29;
  the conditional SELinux item remains open.

##### GitHub Projection

Title: Extend atomic same-dir staging to the remaining deploy sites
Labels: P3-low, ops
GitHub Milestone: Backlog
Observed State: open
Observed Labels: P3-low, ops
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:44Z

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

#### M3 - Current Rocky golden downstream validation

Origin: 46790f9 / M3
Identity History: none
GitHub Issue: 146, https://github.com/jeonghanlee/epics-ioc-runner/issues/146
Status: Deferred

##### Summary

The 2026-06-03 Rocky golden named by jeonghanlee/cloud-provision#4 is obsolete
after the copy-based image workflow shipped in jeonghanlee/cloud-provision#30.
The current workflow has real bake, provenance, publication, and
fresh-consumer acceptance, but the downstream system-infrastructure and
system-lifecycle suites have not run against that current Rocky image. This
row carries only that remaining verification.

##### Scope

- Boot a fresh Rocky 8 consumer from a current run-specific image and matching
  creation record produced by the shipped `cloud-provision` image workflow.
- Record the exact `cloud-provision`, `ansible-provision`, and installed
  `epics-ioc-runner` identities before the test.
- Run the shipped system-infrastructure and system-lifecycle suites through
  the real installed-runner path without replacing the setup, sudo, systemd,
  or IOC paths.
- Record the complete suite results and the current sudoers-policy
  observations.

##### Out of Scope

- Re-running the retired 2026-06-03 Rocky golden.
- Treating the 2026-08-12 pre-#30 Rocky gate as verification of the current
  image-workflow artifact.
- Rebuilding the current golden unless provenance is invalid or the downstream
  run exposes a defect.
- Blocking any release on this independent Backlog check.

##### Completion Criteria

- A fresh consumer selects one exact current Rocky image and matching creation
  record and reaches `READY`.
- The image manifest records the exact clean supplier identities and the
  installed runner reports the expected identity.
- `tests/test-system-infra.bash` and `tests/test-system-lifecycle.bash` run
  through the shipped installed path and both finish with final PASS suite
  records.
- Evidence records the image name, creation record, supplier commits, runner
  identity, commands, suite counts, final states, and log hashes.

##### Dependencies And Decisions

- D3
- jeonghanlee/cloud-provision#30 supplies the current copy-based image
  workflow and its accepted Rocky image format.
- jeonghanlee/cloud-provision#4 closed by owner-approved retirement of its
  exact historical target; this row does not retroactively satisfy that
  issue's original first check.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Select or bake a current Rocky golden through the shipped `cloud-provision`
   image workflow and boot a fresh consumer.
2. Capture the selected image, creation record, manifest, supplier commits,
   and installed runner identity.
3. Run the shipped system-infrastructure and system-lifecycle suites through
   the installed-runner path.
4. Record complete results and reconcile this detail and its GitHub issue.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime acceptance | Run the shipped system-only installed suite selection on a fresh current Rocky consumer after recording its image and software identities | Rocky 8 consumer from the current copy-based image workflow | The real system-infrastructure and system-lifecycle suites both emit complete final PASS records |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Fresh current-image Rocky 8 consumer | Pending | The 2026-08-12 Rocky gate predates jeonghanlee/cloud-provision#30 and is supporting history, not M3 verification |

##### Closure Evidence

- none

##### GitHub Projection

Title: Validate the current Rocky 8 golden through downstream runner suites
Labels: tests
GitHub Milestone: Backlog
Observed State: open
Observed Labels: tests
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-16; remote updated 2026-08-16T08:24:10Z

## History

| Reset Date | Prior State Commit |
| --- | --- |
| 2026-08-17 | `46790f9ed9b725e700cc3607e195ea706ca383d8` |
