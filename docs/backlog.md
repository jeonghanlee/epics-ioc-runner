# Work Register

Release line: unassigned
Canonical path: `docs/backlog.md`
Canonical branch or ref: `master`
Git upstream: `origin/master`
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `Backlog`

Next session entry point: review and commit this synchronized pre-reset state,
then perform the owner-directed milestone reset.

## Work

| ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | (#102) Fleet-layer reliability: restart-storm boundary and running-IOC hang detection | Milestone | Open | No | | Owner assigns it to a release line and its scope is settled; [detail](#m1---fleet-layer-reliability) |
| M2 | (#113) Unify the three conf parsers behind one shared parse core | Milestone | Open | No | | Owner assigns it to a release line and its scope is settled; [detail](#m2---conf-parser-unification) |
| M3 | (#114) Boundary hygiene for the FATAL crash-token subset | Milestone | Open | No | | Owner assigns it to a release line; [detail](#m3---fatal-token-boundary-hygiene) |
| M4 | (#115) Exercise restart supervision end-to-end on the goldens | Milestone | Open | No | | Owner assigns it to a release line; [detail](#m4---restart-supervision-probe) |
| M5 | (#116) Exercise the deployed local logrotate oneshot through systemd | Milestone | Open | No | | Owner assigns the remaining real systemd path to a release line; [detail](#m5---suite-integrity) |
| M6 | (#117) Reorder local install so deployment follows the abort gates | Milestone | Open | No | | Owner assigns it to a release line; [detail](#m6---local-install-ordering) |
| M7 | (#118) Type expectation for `verify_path` (false-green directory impostors) | Milestone | Open | No | | Owner assigns it to a release line; [detail](#m7---verify_path-type-expectation) |
| M8 | (#120 item 3) SELinux context on the setup deploys, RHEL-only | Milestone | Conditional | No | D1 | The owner confirms production hosts run SELinux enforcing; [detail](#m8---selinux-context) |
| M9 | (#127) Container execution mode without systemd | Milestone | Open | No | | Owner assigns it to a release line; [detail](#m9---container-execution-mode) |
| M10 | (#129) Unify conf-value normalization between `read_conf_var` and `read_conf_all` | Milestone | Open | No | | Owner assigns it to a release line; [detail](#m10---conf-value-normalization) |
| M11 | (#132) Settle the fate of the `docs/MILESTONE_PROCEDURE.md` working draft: fold into a skill, keep as a repository document, or absorb | Milestone | Open | No | D3 | Owner assigns it to a release line and the boundary with the release-cycle runbook is settled; [detail](#m11---milestone-procedure-draft-fate) |
| M12 | (#144) Separate human-readable test output from machine-readable records | Milestone | Open | No | | Owner assigns it to a release line and the output contract is settled; [detail](#m12---human-and-machine-output-separation) |
| M13 | (#143) Make local logrotate validation independent of the system state file | Milestone | Deferred | No | D4 | Transfer the complete row and detail when the 1.2.4 release line opens; [detail](#m13---local-logrotate-state-isolation) |
| M14 | (#139) Stop EPICS-dependent test scripts before setup when `EPICS_BASE` is unset | Milestone | Open | No | | Owner assigns the test-entry boundary to a release line; [detail](#m14---epics-base-entry-boundary) |
| M15 | (#142) Diagnose a conf/mode mismatch in one message | Milestone | Open | No | | Owner assigns the operator-message change to a release line; [detail](#m15---conf-mode-mismatch-diagnosis) |

## Decisions

| ID | Decision | Source |
| --- | --- | --- |
| D1 | #120 items 1 and 2 are examined-Keep and were retired; only item 3 (SELinux) remains, and it stays closed until the owner confirms a production SELinux-enforcing environment. | Owner decision, 2026-07-28; recorded in `CLOSED_DOORS.md` CI-29 |
| D2 | #129 stays out of the 1.2.2 and 1.2.3 lines: it changes runtime parsing for every key, and #122 already closed the specific gap at its single call site. | Owner decision, 2026-07-29 |
| D3 | The `docs/MILESTONE_PROCEDURE.md` draft stays in place and unchanged through 1.2.3; the release-cycle runbook references it rather than absorbing it, so the cycle stays a scenario re-set. | Owner decision, 2026-07-30 |
| D4 | The local logrotate state-file defect is separate product work for 1.2.4. Keep it out of 1.2.3 M11 and leave the root-owned system state file unchanged. | Owner decision, 2026-08-11 |

## Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| (#130) Golden `ioc-runner` baseline named at bake time | Backlog, `docs/milestone.md` 1.2.2 register, `master` | 1.2.3, `docs/milestone.md`, `release-1.2.3` | this synchronization commit | this synchronization commit |
| Local logrotate state isolation | 1.2.3 draft M12, `docs/milestone.md`, `release-1.2.3` | Backlog M13, target release 1.2.4 | this synchronization commit | this synchronization commit |

## Milestone Details

### M1 - Fleet-layer reliability

Origin: #102, filed for the 1.3.0 detection-layer theme
GitHub Issue: 102, https://github.com/jeonghanlee/epics-ioc-runner/issues/102
Status: Open

#### Summary

Restart-storm boundary and running-IOC hang detection: the fleet-level
reliability work that the 1.3.0 theme is built around.

#### Scope

As filed in the issue. Out of scope: any release line until the owner assigns
it.

#### Completion Criteria

- The owner assigns the work to a release line and its scope is settled there.

#### Dependencies And Decisions

- none

#### GitHub Projection

Title: Fleet-layer reliability: restart-storm boundary and running-IOC hang detection
Labels: enhancement, P3-low, ops, area/architecture
GitHub Milestone: Backlog
Observed State: open
Last Compared: 2026-07-30

### M2 - Conf parser unification

Origin: 1.2.0 full-code review, filed as #113
GitHub Issue: 113, https://github.com/jeonghanlee/epics-ioc-runner/issues/113
Status: Open

#### Summary

Three conf parsers disagree on trimming, duplicate keys, and CRLF. One shared
parse core plus divergence fixtures pinning install-time acceptance to runtime
interpretation.

#### Scope

As filed. Behavior-visible, so it needs its own review before scheduling.

#### Completion Criteria

- The owner assigns the work to a release line and its scope is settled there.

#### Dependencies And Decisions

- Related: M10 (#129) is the narrow two-reader case inside this general work.

#### GitHub Projection

Title: Unify the three conf parsers behind one shared parse core
Labels: P2-medium, refactor, area/architecture
GitHub Milestone: Backlog
Observed State: open
Last Compared: 2026-07-30

### M3 - FATAL token boundary hygiene

Origin: 1.2.0 full-code review R2-F5, filed as #114
GitHub Issue: 114, https://github.com/jeonghanlee/epics-ioc-runner/issues/114
Status: Open

#### Summary

The case-insensitive FATAL substring match has no word boundaries, so a
pre-marker line carrying `fatal` inside an identifier trips the standalone
exit-1 path while the IOC starts fine.

#### Scope

As filed, including the golden re-run that re-validates detection sensitivity.

#### Completion Criteria

- The owner assigns the work to a release line and its scope is settled there.

#### Dependencies And Decisions

- Pairs with M4 (#115), the end-to-end supervision probe.

#### GitHub Projection

Title: Add boundary hygiene to the FATAL crash-token subset
Labels: P2-medium, area/detection
GitHub Milestone: Backlog
Observed State: open
Last Compared: 2026-07-30

### M4 - Restart supervision probe

Origin: 1.2.0 full-code review R8 G1, filed as #115
GitHub Issue: 115, https://github.com/jeonghanlee/epics-ioc-runner/issues/115
Status: Open

#### Summary

No automated test kills a running IOC and asserts recovery; the ADR 0001
promise is pinned only by static directive-row guards.

#### Scope

A kill-based probe on the golden VMs, as filed.

#### Completion Criteria

- The owner assigns the work to a release line and its scope is settled there.

#### Dependencies And Decisions

- Named as a still-open coverage gap by the 1.2.3 runbook work (#131), so a
  gate record cannot read as if restart supervision had been exercised.

#### GitHub Projection

Title: Exercise restart supervision end-to-end on the goldens
Labels: P2-medium, tests
GitHub Milestone: Backlog
Observed State: open
Last Compared: 2026-07-30

### M5 - Suite integrity

Origin: 1.2.0 full-code review R8-F5 and coverage gap G3, filed as #116
GitHub Issue: 116, https://github.com/jeonghanlee/epics-ioc-runner/issues/116
Status: Open

#### Summary

The original issue contained two test-integrity gaps. The shared reporter now
closes the executed-versus-counted gap: every suite declares a complete
catalog, records one terminal state per identity, and resolves missing or
duplicate results as `SCRIPT_ERROR`. The remaining gap is that the local
lifecycle suite invokes logrotate directly and never starts the deployed
`epics-logrotate.service` through the user systemd manager.

#### Scope

Run the real deployed oneshot through `systemctl --user` and verify its result,
rotation effect, and `%t/ioc-runner-logrotate.state` path. The check must use
the shipped unit and real logrotate binary rather than reproducing the
`ExecStart` command.

Out of scope: changing the shared reporter, adding a second counter, changing
product logrotate policy, or implementing #143's install-time validation fix.

#### Completion Criteria

- The owner assigns the remaining systemd path to a release line.
- The deployed oneshot completes successfully through the real user manager
  on both applicable golden environments and produces the expected rotation.
- A broken deployed `ExecStart` makes the check fail.

#### Dependencies And Decisions

- The catalog-ledger half completed in commits `f5871c7`, `1893c6e`, and
  `a60802b`; it is checked in the GitHub issue and is not remaining work.
- #143 covers install-time `logrotate -d` state isolation. This row covers the
  deployed runtime systemd path.

#### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Prepare a safe local log fixture under the deployed user configuration.
2. Start the shipped `epics-logrotate.service` through `systemctl --user`.
3. Verify the oneshot result, rotation effect, and per-user runtime state path.
4. Prove that a broken deployed `ExecStart` turns the real-path check red.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime unit | Start the deployed oneshot through the real user systemd manager | Debian and Rocky goldens where the user manager is available | The unit completes and produces the expected rotation effect |
| T2 | Honest red | Install an isolated broken unit and start it through the same public systemd path | Golden VM test workspace | The check fails on the broken `ExecStart` |
| T3 | State isolation | Inspect the resolved runtime state and the system default state before and after T1 | Both applicable goldens | The service uses `%t/ioc-runner-logrotate.state` and does not modify the system default state |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Both applicable goldens | Pending | none |
| T2 | Not run | Golden VM test workspace | Pending | none |
| T3 | Not run | Both applicable goldens | Pending | none |

#### Closure Evidence

- The catalog-ledger half is complete; the remaining runtime unit path has no
  closure evidence.

#### GitHub Projection

Title: Extend suite integrity: tripwire port and the M19 oneshot under systemd
Labels: P3-low, tests
GitHub Milestone: Backlog
Observed State: open
Observed Labels: P3-low, tests
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12T06:29:59Z

### M6 - Local install ordering

Origin: 1.2.0 full-code review R1-F3, filed as #117
GitHub Issue: 117, https://github.com/jeonghanlee/epics-ioc-runner/issues/117
Status: Open

#### Summary

Local-mode `do_install` replaces the shared user template and reloads systemd
before the running-service guard and the overwrite prompt, so an aborted
install still leaves durable changes affecting every local IOC.

#### Scope

As filed, including the decision on whether refresh-on-every-install remains
the intended upgrade vehicle.

#### Completion Criteria

- The owner assigns the work to a release line and its scope is settled there.

#### Dependencies And Decisions

- none

#### GitHub Projection

Title: Reorder local install so deployment follows the abort gates
Labels: enhancement, P3-low
GitHub Milestone: Backlog
Observed State: open
Last Compared: 2026-07-30

### M7 - verify_path type expectation

Origin: 1.2.1 M1 review, 2026-07-06, filed as #118
GitHub Issue: 118, https://github.com/jeonghanlee/epics-ioc-runner/issues/118
Status: Open

#### Summary

`verify_path` asserts owner and mode but not file type, so a pre-existing
directory at a file target verifies green while the deployment is broken.

#### Scope

An expected-type parameter threaded through all seven call sites; two targets
are legitimately directories, so a blanket file test is wrong.

#### Completion Criteria

- The owner assigns the work to a release line and its scope is settled there.

#### Dependencies And Decisions

- The 1.2.3 runbook (#131) records this false-green class as a known limitation
  of a green `verify_path` result until the type expectation lands.

#### GitHub Projection

Title: Add a type expectation to verify_path (false-green directory impostors)
Labels: P3-low, ops
GitHub Milestone: Backlog
Observed State: open
Last Compared: 2026-07-30

### M8 - SELinux context

Origin: #120 item 3, the remaining part after items 1 and 2 were retired
GitHub Issue: 120, https://github.com/jeonghanlee/epics-ioc-runner/issues/120
Status: Conditional

#### Summary

Items 1 and 2 are examined-Keep decisions, not pending implementation. Only
the SELinux context of setup deployments into `/etc` remains, conditional on
the owner confirming a production SELinux-enforcing IOC host.

#### Scope

On an enforcing production host, record the expected contexts for the sudoers
and logrotate targets, run the shipped setup path, and compare the resulting
contexts and policy acceptance. If a mismatch is observed, implement the
smallest cross-distribution correction and a real-path final-context check.

Out of scope: reopening items 1 or 2 without new reachability evidence, or
treating a non-enforcing golden as proof of production SELinux behavior.

#### Completion Criteria

- The named condition is observed: the owner confirms a production
  SELinux-enforcing environment. The row then moves to Not started.
- The real setup deployment records expected and observed contexts for both
  `/etc` targets before any correction is selected.

#### Dependencies And Decisions

- D1

#### Implementation Plan

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

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Activation condition | Read the production host SELinux mode with owner authorization | Production IOC host | `Enforcing` is observed before investigation begins |
| T2 | Deployment context | Run the shipped setup path and compare `matchpathcon` with resulting target contexts | Same enforcing host | Both deployed policies carry their expected contexts and are accepted by their consumers |
| T3 | Regression | If T2 finds a mismatch, rerun the real setup path with the correction present | Supported enforcing targets | A wrong final context fails the check and the corrected context passes |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Production IOC host | Pending | none |
| T2 | Not run | Production IOC host | Pending | none |
| T3 | Not run | Supported enforcing targets | Pending | none |

#### Closure Evidence

- Items 1 and 2 are retired as examined Keep in `docs/CLOSED_DOORS.md` CI-29;
  the conditional SELinux item remains open.

#### GitHub Projection

Title: Extend atomic same-dir staging to the remaining deploy sites
Labels: P3-low, ops
GitHub Milestone: Backlog
Observed State: open
Observed Labels: P3-low, ops
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12T06:30:06Z

### M9 - Container execution mode

Origin: #127
GitHub Issue: 127, https://github.com/jeonghanlee/epics-ioc-runner/issues/127
Status: Open

#### Summary

A container execution mode that does not require systemd.

#### Scope

As filed. Feature work, unscheduled.

#### Completion Criteria

- The owner assigns the work to a release line and its scope is settled there.

#### Dependencies And Decisions

- none

#### GitHub Projection

Title: Add container execution mode without systemd
Labels: P3-low, feature, area/architecture
GitHub Milestone: Backlog
Observed State: open
Last Compared: 2026-07-30

### M10 - Conf value normalization

Origin: spun off from #122 during the 1.2.2 cycle, filed as #129
GitHub Issue: 129, https://github.com/jeonghanlee/epics-ioc-runner/issues/129
Status: Open

#### Summary

`read_conf_var` and `read_conf_all` normalize a value differently: the runtime
reader neither trims nor applies the trim-before-unquote ordering that install
uses, so one conf line can reach two verdicts.

#### Scope

As filed. Changes runtime parsing for every key, so it needs its own review.

Out of scope: the `CRASH_LOG_PATTERNS_EXTRA` call-site trim, which #122 landed.

#### Completion Criteria

- The owner assigns the work to a release line and its scope is settled there.

#### Dependencies And Decisions

- D2
- Related: M2 (#113) subsumes this once the shared parse core exists.

#### GitHub Projection

Title: Unify conf-value normalization between read_conf_var and read_conf_all
Labels: bug, P3-low, area/architecture
GitHub Milestone: Backlog
Observed State: open
Last Compared: 2026-07-30

### M11 - Milestone procedure draft fate

Origin: written during the 1.2.2 cycle in commit `f5994e8` and untouched since
GitHub Issue: 132, https://github.com/jeonghanlee/epics-ioc-runner/issues/132
Status: Open

#### Summary

`docs/MILESTONE_PROCEDURE.md` carries the per-milestone procedure - plan review
before code, the owner gate, de-knotting, implementation, verification on the
real path, and the reconcile-and-land step - with the 1.2.2 M2, M3 and M4 runs
as worked examples. Its own first line names the fate it expects: fold it into
a skill. That fate has never been decided.

#### Scope

Decide between the three fates and carry it out: fold the draft into a skill,
keep it as a repository document with the draft marker removed, or absorb it
into another document. The decision settles its boundary with
`gate/RUNBOOK.md`, which covers the release gate rather than the
work inside a cycle.

Out of scope: the 1.2.3 line, which references the draft and leaves it
unchanged (D3).

#### Completion Criteria

- The owner assigns the work to a release line and chooses one of the three
  fates.

#### Dependencies And Decisions

- D3
- The runbook written under 1.2.3 M1 (#131) references this draft, so whichever
  fate is chosen must keep that reference resolvable.

#### GitHub Projection

Title: Settle the fate of the milestone procedure working draft
Labels: docs, P3-low
GitHub Milestone: Backlog
Observed State: open
Last Compared: 2026-07-30

### M12 - Human and machine output separation

Origin: Backlog / M12
Identity History: none
GitHub Issue: 144, https://github.com/jeonghanlee/epics-ioc-runner/issues/144
Status: Open

#### Summary

The test suites currently print the human summary and the machine-readable
`TEST`, `STEP`, and `SUITE` records in one terminal output. The complete
machine record sequence obscures the result intended for an operator.

#### Scope

Define and implement separate output surfaces for the human report and the
machine-readable record sequence. Both outputs continue to derive from the
same validated ledger, and the collector consumes only the machine-readable
surface.

Out of scope: changing the fixed check identities, terminal states, suite-state
semantics, or the accepted M8 count vectors. This work is not part of the
1.2.3 M8 remediation.

#### Completion Criteria

- A normal operator invocation displays the human report without the full
  `TEST`, `STEP`, and `SUITE` sequence.
- A documented machine-readable surface preserves the complete accepted record
  grammar and final suite state.
- The collector reads only the machine-readable surface and rejects missing,
  malformed, duplicate, or inconsistent records.
- Real producer and dispatcher runs prove that both outputs describe the same
  ledger and process result.

#### Dependencies And Decisions

- Owner direction, 2026-08-10: record human and machine output separation as
  later milestone work rather than extending the active M8 remediation.
- The implementation must preserve the M8 reporting contract and the fixed
  488-check identity set.

#### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Choose the output boundary and document direct-suite and dispatcher
   behavior.
2. Route the human report and machine records through their selected surfaces
   without introducing a second calculation path.
3. Update the collector to consume only the machine-readable surface.
4. Verify all producer and dispatcher paths and update maintained test
   documentation.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Reporter contract | Run the shipped reporter self-test through its public API | Working tree | Human and machine outputs reconcile to one ledger while using separate surfaces |
| T2 | Collector integration | Run the shipped collector probe and a real source-regression dispatcher path | Debian 13 | The operator output stays concise and the collector validates the complete machine record sequence |
| T3 | Producer integration | Run all five shipped producer paths | Both golden OS families | Every fixed identity closes once and both output surfaces carry the same suite result |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Working tree | Pending | none |
| T2 | Not run | Debian 13 | Pending | none |
| T3 | Not run | Both golden OS families | Pending | none |

#### Closure Evidence

- none

#### GitHub Projection

Title: Separate human-readable test output from machine-readable records
Labels: tests
GitHub Milestone: Backlog
Observed State: open
Observed Labels: tests
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12T06:30:50Z

### M13 - Local logrotate state isolation

Origin: 1.2.3 / M12
Identity History: 1.2.3 draft M12 -> Backlog M13, owner decision 2026-08-11
GitHub Issue: 143, https://github.com/jeonghanlee/epics-ioc-runner/issues/143
Status: Deferred

#### Summary

Local configuration validation runs `logrotate -d` without selecting a state
file. Rocky logrotate treats an unreadable system default state file as an
error, so a root-owned state file left by an earlier system run prevents the
ordinary user's later local install from deploying rotation artifacts. The
deployed user service already uses `%t/ioc-runner-logrotate.state`; the defect
is limited to the install-time debug validation.

#### Scope

- Make local configuration debug validation independent of the system default
  state file.
- Add a real install-path regression check using only the external
  `IOC_RUNNER_LOGROTATE_TOOL` boundary.
- Update the maintained inventories and driver expectations when the 1.2.4
  release line accepts the implementation plan.

Out of scope: changing the system default state file, changing its ownership or
mode, changing the deployed user timer's runtime state path, changing system
logrotate policy, or changing the 1.2.3 M11 journal applicability decision.

#### Completion Criteria

- A shipped local install validates and deploys rotation artifacts without
  reading the system default state file.
- A regression check drives the real local install path and fails if validation
  returns to the system default state file.
- Consecutive two-golden suite-driver runs pass without changing system
  state-file ownership or mode.

#### Dependencies And Decisions

- D4 assigns the work to 1.2.4 and excludes it from 1.2.3 implementation.
- Transfer the complete row and detail when the 1.2.4 release line opens.
- The defect was observed during a repeated Rocky M11 gate after an earlier
  system run had created a `root:root 0600` default state file.
- The final 1.2.3 two-host gate passed without changing either default state
  file. That clean-path result does not mean the state-dependent defect is
  fixed.
- #116 covers runtime execution of the deployed oneshot; this row covers the
  earlier install-time validation.

#### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Select an explicit non-persistent state target for local debug validation.
2. Add a real install-path regression check at the external logrotate boundary.
3. Update maintained inventories, driver expectations, and runbook counts.
4. Run the shipped two-host suite driver consecutively and compare the complete
   state vectors and default state-file metadata.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Install contract | Drive a real local install through an external logrotate boundary that rejects use of the system default state | Source error-contract suite | The install returns zero, deploys all rotation artifacts, and the check passes |
| T2 | Repeated integration | Run the shipped suite driver consecutively without changing either system default state file | Debian and Rocky goldens for 1.2.4 | Both runs record complete PASS suite vectors |
| T3 | State preservation | Compare owner, group, and mode before and after T2 | Both goldens | The default state files remain `root:root 0600` |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Source tree | Pending | none |
| T2 | Not run | 1.2.4 goldens | Pending | none |
| T3 | Not run | 1.2.4 goldens | Pending | none |

#### Closure Evidence

- none

#### GitHub Projection

Title: Make local logrotate validation independent of the system state file
Labels: bug, tests, ops
GitHub Milestone: Backlog
Observed State: open
Observed Labels: bug, tests, ops
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12T06:30:19Z

### M14 - EPICS_BASE entry boundary

Origin: Backlog / M14, synchronized from #139 on 2026-08-12
Identity History: none
GitHub Issue: 139, https://github.com/jeonghanlee/epics-ioc-runner/issues/139
Status: Open

#### Summary

The dispatcher checks `EPICS_BASE` before launching an EPICS-dependent suite.
The direct local and system lifecycle suites instead initialize the reporter,
evaluate all P00 prerequisites, record the missing environment as FAIL, and
close the remaining catalog as SKIP. They do not enter workspace setup or
lifecycle execution, so this is an inconsistent entry boundary rather than a
false green.

#### Scope

Inventory every shipped test entry point that consumes `EPICS_BASE`, make the
missing variable its first environment boundary, and preserve the complete
catalog reporter contract without later dependency, privilege, workspace,
compilation, systemd, or IOC work.

Out of scope: sourcing an EPICS environment automatically, making source
regression depend on EPICS Base, changing IOC behavior, or weakening the
reporter's complete-state contract.

#### Completion Criteria

- The owner assigns the test-entry boundary to a release line.
- Every affected entry point stops nonzero at its first environment boundary
  and performs no later setup or lifecycle work.
- Direct suites close every catalog identity once with no `SCRIPT_ERROR`.
- The source-regression-only selection still runs without `EPICS_BASE`.
- The real lifecycle paths remain unchanged when `EPICS_BASE` is present.

#### Dependencies And Decisions

- The 1.2.3 gate ran with the declared EPICS environment on both goldens, so
  this inconsistency does not invalidate its evidence.

#### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Inventory the EPICS-dependent entry points and pin that set.
2. Define the first-boundary reporter result for each direct suite.
3. Move the environment stop ahead of every unrelated probe and side effect.
4. Re-run the missing-environment and real lifecycle paths.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Entry contract | Run every EPICS-dependent entry point with `EPICS_BASE` unset | Debian 13 | Nonzero at the first boundary, no later work, complete catalog, no `SCRIPT_ERROR` |
| T2 | Independent path | Run `tests/run-all-tests.bash --source-regression` without `EPICS_BASE` | Debian 13 | Source regression executes normally |
| T3 | Positive path | Run both real lifecycle suites with the declared EPICS environment | Both golden OS families | Existing shipped paths and fixtures complete normally |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Debian 13 | Pending | none |
| T2 | Not run | Debian 13 | Pending | none |
| T3 | Not run | Both golden OS families | Pending | none |

#### Closure Evidence

- none

#### GitHub Projection

Title: Stop EPICS-dependent test scripts before setup when EPICS_BASE is unset
Labels: P3-low, tests
GitHub Milestone: Backlog
Observed State: open
Observed Labels: P3-low, tests
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12T06:30:10Z

### M15 - Conf mode mismatch diagnosis

Origin: Backlog / M15, synchronized from #142 on 2026-08-12
Identity History: none
GitHub Issue: 142, https://github.com/jeonghanlee/epics-ioc-runner/issues/142
Status: Open

#### Summary

Identity validation safely rejects a configuration whose `IOC_USER` and
`IOC_GROUP` do not match the selected execution mode, but it reports two
field-level errors and leaves the operator to infer one mode mismatch. It does
not show the values found, name the file, or provide the correct regeneration
command.

#### Scope

When both identity fields support the diagnosis, emit one found-versus-needed
mode-mismatch message with the configuration path and correct `generate`
command. A third-account configuration receives the comparison and remedy
without an unsupported mode claim. System mode remains the unflagged default;
there is no `--system` option.

Out of scope: rewriting the configuration during install, switching modes,
adding a `--system` option, or changing the identity validation rules.

#### Completion Criteria

- The owner assigns the operator-message change to a release line.
- Both supported mismatch directions produce one complete diagnosis and the
  correct regeneration command.
- A third-account case does not claim either supported source mode.
- Invalid identity values still abort without rewriting the configuration.
- Tests update the error-count and message contract deliberately.

#### Dependencies And Decisions

- This is an operator-message improvement, not a validation bypass. The hard
  failure behaved correctly during the 1.2.3 verification.

#### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Classify the two supported opposite-mode pairs and the third-account case.
2. Render one diagnosis from the selected and found identities.
3. Update the validation count and message tests.
4. Run the real install validation paths in both modes.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local mismatch | Install a system-mode conf with `--local` through the shipped install path | Debian 13 | One complete diagnosis and `generate --local` remedy; install aborts |
| T2 | System mismatch | Install a local-mode conf in default system mode through the shipped path | Debian 13 | Mirror diagnosis and unflagged `generate` remedy; install aborts |
| T3 | Unknown account | Install a conf naming neither supported identity | Debian 13 | Found-versus-needed output without a source-mode claim; install aborts |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Debian 13 | Pending | none |
| T2 | Not run | Debian 13 | Pending | none |
| T3 | Not run | Debian 13 | Pending | none |

#### Closure Evidence

- none

#### GitHub Projection

Title: Diagnose conf/mode mismatch in one message
Labels: enhancement, P2-medium, area/install
GitHub Milestone: Backlog
Observed State: open
Observed Labels: enhancement, P2-medium, area/install
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12T06:30:15Z
