# Work Register

Release line: 1.2.4
Milestone index: 1.2.4
Canonical path: `docs/milestone-1.2.4.md`
Canonical branch or ref: `release-1.2.4`
Git upstream: `origin/release-1.2.4` after first push
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `1.2.4`
(pending creation)
Activation state: staged target; authority remains with
`master`, `docs/milestone-a39623c.md` until its source transfer commit names
this target commit and removes the four source rows and details.

Next session entry point: commit this staged target, then return to `master`
and prepare the source transfer commit naming the exact target commit.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Detection | M3 | (#114) Boundary hygiene for the FATAL crash-token subset | Milestone | Not started | Yes | D1, D2 | Identifier-contained `fatal` stays benign while true fatal startup remains detected on both goldens; [detail](#m3---fatal-token-boundary-hygiene) |
| Setup | M7 | (#118) Type expectation for `verify_path` (false-green directory impostors) | Milestone | Not started | Yes | D1, D2 | Every file target rejects a directory impostor and the two directory targets still verify through the shipped setup path; [detail](#m7---verify_path-type-expectation) |
| Local install | M6 | (#117) Reorder local install so deployment follows the abort gates | Milestone | Open | No | D1, D2 | Owner settles whether accepted installs refresh shared assets, then abort and accepted paths meet their ordering contracts; [detail](#m6---local-install-ordering) |
| Local install | M13 | (#143) Make local logrotate validation independent of the system state file | Milestone | Not started | No | M6, D1, D2 | Local validation avoids the system state file and consecutive two-golden runs pass without changing its metadata; [detail](#m13---local-logrotate-state-isolation) |
| Tracker | G1 | GitHub milestone 1.2.4 exists | External gate | Open | No | | Repository owner creates the open GitHub milestone with the exact title `1.2.4`; [detail](#g1---github-milestone-1.2.4) |
| Release | M16 | Final release 1.2.4 | Milestone | Blocked | No | M3, M7, M6, M13, G1, D3 | Tag `1.2.4`, GitHub release, milestone closed, production install verified, and every Release Verification row Pass; [detail](#m16---final-release) |

### Decisions

| ID | Decision | Source |
| --- | --- | --- |
| D1 | Stage M3, M7, M6, and M13 on `release-1.2.4`; authority moves only after the master source transfer commit names this exact target commit and removes the four source rows and details. | Owner-approved cross-branch assignment, 2026-08-12 |
| D2 | Run the bugfix work in the order M3, M7, M6, and M13. M3 and M7 are independent; M6 precedes M13 because both change the local install path. | Owner-accepted 1.2.4 cycle plan, 2026-08-12 |
| D3 | Final release verification runs the complete gate on Debian 13 and Rocky 8, changes the version to 1.2.4, verifies the release objects, and verifies the documented production install path. | Owner-accepted 1.2.4 cycle plan, 2026-08-12 |

### Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| a39623c / M3 | `master`, `docs/milestone-a39623c.md` | `release-1.2.4`, `docs/milestone-1.2.4.md` | this synchronization commit | source transfer commit naming this target commit |
| a39623c / M6 | `master`, `docs/milestone-a39623c.md` | `release-1.2.4`, `docs/milestone-1.2.4.md` | this synchronization commit | source transfer commit naming this target commit |
| a39623c / M7 | `master`, `docs/milestone-a39623c.md` | `release-1.2.4`, `docs/milestone-1.2.4.md` | this synchronization commit | source transfer commit naming this target commit |
| a39623c / M13 | `master`, `docs/milestone-a39623c.md` | `release-1.2.4`, `docs/milestone-1.2.4.md` | this synchronization commit | source transfer commit naming this target commit |

### Milestone Details

#### M3 - FATAL token boundary hygiene

Origin: a39623c / M3
Identity History: transferred unchanged from `docs/milestone-a39623c.md`;
staged target activation requires the master source transfer commit.
GitHub Issue: 114, https://github.com/jeonghanlee/epics-ioc-runner/issues/114
Status: Not started

##### Summary

The case-insensitive FATAL substring match has no word boundaries, so a
pre-marker line carrying `fatal` inside an identifier trips the standalone
exit-1 path while the IOC starts fine.

##### Scope

Add a portable leading boundary to the case-insensitive FATAL subset and
re-run the shipped benign and fatal startup paths on both golden OS families.

##### Out of Scope

Adding crash tokens, changing the initialization marker, or changing the
measured startup window.

##### Completion Criteria

- The owner assigns the detection change to a release line.
- `fatal` inside an identifier does not produce the standalone fatal verdict.
- A true fatal startup still produces the expected failed-initialization
  verdict on both golden OS families.

##### Dependencies And Decisions

- Pairs with M4 (#115), the later 1.3.0 end-to-end supervision probe.
- D1 stages the cross-branch transfer.
- D2 places this work first in the 1.2.4 cycle.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner accepted the 1.2.4 cycle plan, 2026-08-12
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define a portable leading boundary for the FATAL subset.
2. Apply it to the shipped crash scan without weakening true-fatal detection.
3. Re-run benign and fatal startup cases on both golden OS families.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | False-positive boundary | Start a real IOC whose pre-marker output contains `fatal` only inside an identifier | Both golden OS families | Startup succeeds without the standalone fatal verdict |
| T2 | Detection sensitivity | Start the shipped fatal softIoc fixture through the real runner path | Both golden OS families | The true fatal token still produces the expected failed-initialization verdict |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Both golden OS families | Pending | none |
| T2 | Not run | Both golden OS families | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Add boundary hygiene to the FATAL crash-token subset
Labels: P2-medium, area/detection
GitHub Milestone: 1.2.4
Observed State: open
Observed Labels: P2-medium, area/detection
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:39Z

#### M7 - verify_path type expectation

Origin: a39623c / M7
Identity History: transferred unchanged from `docs/milestone-a39623c.md`;
staged target activation requires the master source transfer commit.
GitHub Issue: 118, https://github.com/jeonghanlee/epics-ioc-runner/issues/118
Status: Not started

##### Summary

`verify_path` asserts owner and mode but not file type, so a pre-existing
directory at a file target verifies green while the deployment is broken.

##### Scope

An expected-type parameter threaded through all seven call sites; two targets
are legitimately directories, so a blanket file test is wrong.

##### Out of Scope

Changing target ownership or mode contracts, or replacing the existing
deployment mechanisms.

##### Completion Criteria

- The owner assigns the helper-signature change to a release line.
- Every file target rejects a directory impostor through the real setup path.
- The two legitimate directory targets pass explicit directory checks.

##### Dependencies And Decisions

- The 1.2.3 runbook (#131) records this false-green class as a known limitation
  of a green `verify_path` result until the type expectation lands.
- The false green was reproduced through the real setup behavior at
  `BASH_COMP_DEST`: `backup_if_exists` ignores a directory because its guard
  uses `[[ -f ]]`, `cp` writes the payload inside that directory, `chmod`
  gives the directory the expected mode, and `verify_path` reports success
  from its owner and mode alone.
- Crafted directories at `SUDOERS_FILE` and `LOGROTATE_FILE` produce the same
  class through their `mv` deployment paths. The sudo includedir ignores the
  dot-named payload and logrotate ignores the subdirectory, so the required
  policy is absent even though setup reports success.
- No maintained provisioning path creates these impostors, but a root-created
  directory is reachable and persistent: later runs neither displace nor
  reject it. This is why the correction covers all seven call sites rather
  than only the first reproduced target.
- D1 stages the cross-branch transfer.
- D2 places this work second in the 1.2.4 cycle.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner accepted the 1.2.4 cycle plan, 2026-08-12
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define the expected type at every `verify_path` call site.
2. Extend the helper to reject a type mismatch before reporting success.
3. Exercise file-target impostors and legitimate directory targets through
   the shipped setup path.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Honest red | Place directories at file targets and run the shipped setup path | Isolated system setup environment | Each type mismatch returns nonzero and cannot produce the success banner |
| T2 | Legitimate directories | Run the same setup with the real configuration and log directories | Isolated system setup environment | Directory targets pass their explicit type checks and deployment completes |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Isolated system setup environment | Pending | none |
| T2 | Not run | Isolated system setup environment | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Add a type expectation to verify_path (false-green directory impostors)
Labels: P3-low, ops
GitHub Milestone: 1.2.4
Observed State: open
Observed Labels: P3-low, ops
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:43Z

#### M6 - Local install ordering

Origin: a39623c / M6
Identity History: transferred unchanged from `docs/milestone-a39623c.md`;
staged target activation requires the master source transfer commit.
GitHub Issue: 117, https://github.com/jeonghanlee/epics-ioc-runner/issues/117
Status: Open

##### Summary

Local-mode `do_install` replaces the shared user template and reloads systemd
before the running-service guard and the overwrite prompt, so an aborted
install still leaves durable changes affecting every local IOC.

##### Scope

Settle whether accepted local installs refresh shared assets, then place every
selected deployment and daemon reload after the running-service guard and
overwrite-abort gates.

##### Out of Scope

Changing system-mode ordering or the content, ownership, and mode contracts
of the deployed local artifacts.

##### Completion Criteria

- The owner assigns the ordering change and settles the refresh policy.
- EOF and explicit decline leave the shared template, rotation units, and
  manager state unchanged.
- An accepted install deploys the configuration and selected shared assets
  after all abort gates pass.

##### Dependencies And Decisions

- D1 stages the cross-branch transfer.
- D2 places this work before M13 because both change local install.
- The accepted-install shared-asset refresh policy remains an owner decision.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner accepted the 1.2.4 cycle plan, 2026-08-12
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Settle whether every accepted install refreshes the shared local assets.
2. Move shared deployment and daemon reload after the running-service and
   overwrite-abort gates.
3. Verify both abort paths and the accepted-install upgrade path.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Abort integrity | Drive EOF and explicit decline through the shipped local install path and compare shared assets before and after | Local lifecycle environment | Each abort returns nonzero and leaves the template, rotation units, and manager state unchanged |
| T2 | Accepted install | Accept the overwrite through the same shipped path | Local lifecycle environment | Configuration and shared assets deploy once after all abort gates pass |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Local lifecycle environment | Pending | none |
| T2 | Not run | Local lifecycle environment | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Reorder local install so deployment follows the abort gates
Labels: enhancement, P3-low
GitHub Milestone: 1.2.4
Observed State: open
Observed Labels: enhancement, P3-low
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:42Z

#### M13 - Local logrotate state isolation

Origin: a39623c / M13
Identity History: transferred unchanged from `docs/milestone-a39623c.md`;
staged target activation requires the master source transfer commit.
GitHub Issue: 143, https://github.com/jeonghanlee/epics-ioc-runner/issues/143
Status: Not started

##### Summary

Local configuration validation runs `logrotate -d` without selecting a state
file. Rocky logrotate treats an unreadable system default state file as an
error, so a root-owned state file left by an earlier system run prevents the
ordinary user's later local install from deploying rotation artifacts. The
deployed user service already uses `%t/ioc-runner-logrotate.state`; the defect
is limited to the install-time debug validation.

##### Scope

- Make local configuration debug validation independent of the system default
  state file.
- Add a real install-path regression check using only the external
  `IOC_RUNNER_LOGROTATE_TOOL` boundary.
- Update the maintained inventories and driver expectations for the 1.2.4
  implementation.

##### Out of Scope

Changing the system default state file, changing its ownership or mode,
changing the deployed user timer's runtime state path, changing system
logrotate policy, or changing the 1.2.3 M11 journal applicability decision.

##### Completion Criteria

- A shipped local install validates and deploys rotation artifacts without
  reading the system default state file.
- A regression check drives the real local install path and fails if validation
  returns to the system default state file.
- Consecutive two-golden suite-driver runs pass without changing system
  state-file ownership or mode.

##### Dependencies And Decisions

- M6 completes first because it changes the same local install path.
- D1 stages the cross-branch transfer.
- D2 places this work last in the bugfix sequence.
- The defect was observed during a repeated Rocky M11 gate after an earlier
  system run had created a `root:root 0600` default state file.
- The final 1.2.3 two-host gate passed without changing either default state
  file. That clean-path result does not mean the state-dependent defect is
  fixed.
- #116 covers runtime execution of the deployed oneshot; this row covers the
  earlier install-time validation.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner accepted the 1.2.4 cycle plan, 2026-08-12
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Select an explicit non-persistent state target for local debug validation.
2. Add a real install-path regression check at the external logrotate boundary.
3. Update maintained inventories, driver expectations, and runbook counts.
4. Run the shipped two-host suite driver consecutively and compare the complete
   state vectors and default state-file metadata.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Install contract | Drive a real local install through an external logrotate boundary that rejects use of the system default state | Source error-contract suite | The install returns zero, deploys all rotation artifacts, and the check passes |
| T2 | Repeated integration | Run the shipped suite driver consecutively without changing either system default state file | Debian and Rocky goldens for 1.2.4 | Both runs record complete PASS suite vectors |
| T3 | State preservation | Compare owner, group, and mode before and after T2 | Both goldens | The default state files remain `root:root 0600` |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Source tree | Pending | none |
| T2 | Not run | 1.2.4 goldens | Pending | none |
| T3 | Not run | 1.2.4 goldens | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Make local logrotate validation independent of the system state file
Labels: bug, ops, tests
GitHub Milestone: 1.2.4
Observed State: open
Observed Labels: bug, ops, tests
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:49Z

#### M16 - Final release

Origin: 1.2.4 / M16
Identity History: none
GitHub Issue: none
Status: Blocked

##### Summary

Release 1.2.4 after the four accepted bugfixes complete and the combined
candidate passes the standing release gate on Debian 13 and Rocky 8.

##### Scope

Integrated re-runs, complete two-golden gate execution, version change,
release objects, tracker closure, and production installation verification.

##### Out of Scope

Opening the 1.3.0 cycle or implementing any backlog item assigned to that
future line.

##### Completion Criteria

- M3, M7, M6, and M13 are Complete with reachable real-path evidence.
- Every Release Verification row records Pass with reachable evidence.
- Tag `1.2.4`, the GitHub release, and the closed remote milestone agree on
  the released commit.
- The documented production install path reports version 1.2.4.

##### Dependencies And Decisions

- M3, M7, M6, and M13.
- G1; resume as Not started after the remote milestone exists.
- D3 defines the complete two-golden gate and release boundary.
- The 1.3.0 target decisions remain on master and do not open that cycle.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner accepted the 1.2.4 cycle plan, 2026-08-12
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Confirm the four bugfix rows are Complete and review their recorded
   evidence against the combined candidate.
2. Bake or accept clean Debian 13 and Rocky 8 goldens according to
   `gate/RUNBOOK.md`, recording Release Verification 1.
3. Add and review the 1.2.4 changelog entry in a standalone commit.
4. Change only `RUNNER_VERSION` from 1.2.3 to 1.2.4 in a standalone commit.
5. Drive the complete gate and M13's consecutive-suite condition, then record
   Release Verification 2 through 6 in a readiness-evidence commit.
6. Execute the separately authorized merge, tag, pushes, GitHub release, and
   milestone closure.
7. Verify the actual release objects and the documented production install
   path, then record Release Verification 7 and 8 and close the cycle.

##### Integrated Verification

| Source Check | Re-run Trigger | Shared Surface | Release Verification Label | Expected Result | Result Evidence |
| --- | --- | --- | --- | --- | --- |
| M3 / T1, T2 | Later changes reach the shared runner and startup scan | Crash scan and startup path | Release Verification 2 | Benign identifier text remains accepted and true fatal startup remains detected in the final candidate | pending |
| M7 / T1, T2 | Later setup changes may alter type checks or deployment | System setup path | Release Verification 2 | File impostors fail and legitimate directories pass in the final candidate | pending |
| M6 / T1, T2 | M13 later changes the same local install path | Local install ordering | Release Verification 2 | Abort integrity and accepted deployment both hold after M13 | pending |
| M13 / T1, T2, T3 | Final candidate and repeated host execution may expose state coupling | Local logrotate validation and suite driver | Release Verification 2 | Both consecutive host runs pass and default state-file metadata is unchanged | pending |

##### Production Environment Tests

| Release Verification Label | Timing | System | Version | Architecture | Deployment Path | Method | Expected Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Release Verification 8 | post-release | `alsucl-psrv3` | Rocky 8, NFS home with root_squash | x86_64 | `/usr/local/bin/ioc-runner` | Follow the documented install path from the NFS-home checkout, then read `-V` | Install completes and `-V` reports 1.2.4 with the released short hash | pending |

##### Version Changes

| Field | File | Before | Planned After | Pre-check | Pre-check Label | Post-check | Post-check Label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `RUNNER_VERSION` | `bin/ioc-runner` | `1.2.3` | `1.2.4` | Read the declaration before mutation | Release Verification 5 | Read deployed `-V` after the final gate deploy | Release Verification 6 |

##### Release Execution

| Step | Action | Authorization | Expected Result | Evidence |
| --- | --- | --- | --- | --- |
| 1 | Add the accepted 1.2.4 section to `CHANGELOG.md` | commit delegation | One standalone changelog commit | pending |
| 2 | Bump `RUNNER_VERSION` to 1.2.4 | commit delegation | One standalone version commit changing only the declaration | pending |
| 3 | Record the complete gate and readiness evidence | commit delegation | One reviewed release-candidate commit | pending |
| 4 | Merge the named release candidate into `master` with `--no-ff` | release delegation | One merge commit on `master` | pending |
| 5 | Create annotated tag `1.2.4` on the merge commit | release delegation | One annotated tag with the accepted title | pending |
| 6 | Push `master`, tag `1.2.4`, and the final `release-1.2.4` ref | release delegation | All three refs identify the accepted objects | pending |
| 7 | Create the GitHub release from reviewed release notes | release delegation | One published 1.2.4 release object | pending |
| 8 | Close the remote GitHub milestone `1.2.4` | release delegation | Milestone state is closed | pending |
| 9 | Record Release Verification 7 and 8 and close M16 | commit delegation | One final closure commit | pending |
| 10 | Push the final closure commit | push delegation | Local and remote closure state agree | pending |

##### Release Verification Plan

| Label | Layer | Timing | Method | Environment | Expected Result | Evidence Target |
| --- | --- | --- | --- | --- | --- | --- |
| Release Verification 1 | Golden acceptance | pre-change | Run the acceptance sequence in `gate/RUNBOOK.md` before tree push or deploy | Debian 13 and Rocky 8 goldens | Both goldens have accepted provenance and the declared baseline | Acceptance log and manifest identities |
| Release Verification 2 | Automated and integrated checks | post-change | Run the complete shipped suite driver twice consecutively and compare state-file metadata around the runs | Both goldens at the final candidate | Every suite is complete and green on both runs; all imported work checks hold; system state-file owner, group, and mode are unchanged | Suite records, cross-host comparison, and metadata reads |
| Release Verification 3 | Standing scenarios | post-change | Run the shipped multi-user scenario driver through `gate/RUNBOOK.md` | Both goldens at the final candidate | Every declared scenario passes on each host | Per-scenario records and final verdicts |
| Release Verification 4 | root_squash procedure | post-change | Run the standing root_squash path through all documented deployment entries | Both goldens at the final candidate | Every entry stamps the real candidate hash without a layout warning | Procedure logs and `-V` output |
| Release Verification 5 | Version consistency | pre-change | Read `RUNNER_VERSION` before mutation | Release branch | Value is 1.2.3 | Commit and file read |
| Release Verification 6 | Version consistency | post-change | Read deployed `-V` after the final gate deploy | Both goldens | Version is 1.2.4 with the version commit's short hash | `-V` output |
| Release Verification 7 | Release objects and tracker | post-release | Read the merge commit, annotated tag, GitHub release target, and milestone state independently | Git and GitHub | All released objects agree and milestone 1.2.4 is closed | Object identifiers and GitHub observations |
| Release Verification 8 | Production deployment | post-release | Follow the documented install path and read deployed `-V` | `alsucl-psrv3` | Installation succeeds and reports released version 1.2.4 | Install log and `-V` output |

##### Release Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| Release Verification 1 | Not run | Debian 13 and Rocky 8 goldens | Pending | none |
| Release Verification 2 | Not run | Debian 13 and Rocky 8 goldens | Pending | none |
| Release Verification 3 | Not run | Debian 13 and Rocky 8 goldens | Pending | none |
| Release Verification 4 | Not run | Debian 13 and Rocky 8 goldens | Pending | none |
| Release Verification 5 | Not run | Release branch | Pending | none |
| Release Verification 6 | Not run | Debian 13 and Rocky 8 goldens | Pending | none |
| Release Verification 7 | Not run | Git and GitHub | Pending | none |
| Release Verification 8 | Not run | `alsucl-psrv3` | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: 1.2.4
Observed State: none
Last Compared: never

#### G1 - GitHub milestone 1.2.4

Origin: 1.2.4 / G1
GitHub Issue: none
Status: Open

##### Summary

The repository owner must create the open GitHub milestone `1.2.4` before the
four issue projections can move from Backlog and before final release closure.

##### Completion Criteria

- The GitHub repository has one open milestone titled exactly `1.2.4`.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| Not run | Pending | GitHub milestone query after owner execution |

##### Closure Evidence

- none

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

No backlog work is carried on the 1.2.4 release branch. The active master
register retains the conditional Backlog and the work targeted for 1.3.0.

### Backlog Details

No backlog details are carried on the 1.2.4 release branch.
