# Work Register

Release line: unassigned
Canonical path: `docs/backlog.md`
Canonical branch or ref: `master`
Git upstream: `origin/master`
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `Backlog`

Next session entry point: no backlog action is scheduled; work leaves this
document only when the owner assigns it to a release line.

## Work

| ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | (#102) Fleet-layer reliability: restart-storm boundary and running-IOC hang detection | Milestone | Open | No | | Owner assigns it to a release line and its scope is settled; [detail](#m1---fleet-layer-reliability) |
| M2 | (#113) Unify the three conf parsers behind one shared parse core | Milestone | Open | No | | Owner assigns it to a release line and its scope is settled; [detail](#m2---conf-parser-unification) |
| M3 | (#114) Boundary hygiene for the FATAL crash-token subset | Milestone | Open | No | | Owner assigns it to a release line; [detail](#m3---fatal-token-boundary-hygiene) |
| M4 | (#115) Exercise restart supervision end-to-end on the goldens | Milestone | Open | No | | Owner assigns it to a release line; [detail](#m4---restart-supervision-probe) |
| M5 | (#116) Extend suite integrity: tripwire port and the logrotate oneshot under systemd | Milestone | Open | No | | Owner assigns it to a release line; [detail](#m5---suite-integrity) |
| M6 | (#117) Reorder local install so deployment follows the abort gates | Milestone | Open | No | | Owner assigns it to a release line; [detail](#m6---local-install-ordering) |
| M7 | (#118) Type expectation for `verify_path` (false-green directory impostors) | Milestone | Open | No | | Owner assigns it to a release line; [detail](#m7---verify_path-type-expectation) |
| M8 | (#120 item 3) SELinux context on the setup deploys, RHEL-only | Milestone | Conditional | No | D1 | The owner confirms production hosts run SELinux enforcing; [detail](#m8---selinux-context) |
| M9 | (#127) Container execution mode without systemd | Milestone | Open | No | | Owner assigns it to a release line; [detail](#m9---container-execution-mode) |
| M10 | (#129) Unify conf-value normalization between `read_conf_var` and `read_conf_all` | Milestone | Open | No | | Owner assigns it to a release line; [detail](#m10---conf-value-normalization) |
| M11 | (#132) Settle the fate of the `docs/MILESTONE_PROCEDURE.md` working draft: fold into a skill, keep as a repository document, or absorb | Milestone | Open | No | D3 | Owner assigns it to a release line and the boundary with the release-cycle runbook is settled; [detail](#m11---milestone-procedure-draft-fate) |
| M12 | Separate human-readable test output from machine-readable records | Milestone | Open | No | | Owner assigns it to a release line and the output contract is settled; [detail](#m12---human-and-machine-output-separation) |
| M13 | (#143) Make local logrotate validation independent of the system state file | Milestone | Deferred | No | D4 | Transfer the complete row and detail when the 1.2.4 release line opens; [detail](#m13---local-logrotate-state-isolation) |

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

Port the executed-vs-counted tripwire to the three lifecycle suites, and run
the logrotate unit once through systemd so a broken ExecStart cannot pass every
test while production rotation is dead.

#### Scope

As filed; both parts are harness code changes.

Out of scope: the scenario-precision half, which the 1.2.3 scenario re-set
(#131) carries.

#### Completion Criteria

- The owner assigns the work to a release line and its scope is settled there.

#### Dependencies And Decisions

- Cross-referenced from #131.

#### GitHub Projection

Title: Extend suite integrity: tripwire port and the M19 oneshot under systemd
Labels: P3-low, tests
GitHub Milestone: Backlog
Observed State: open
Last Compared: 2026-07-30

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

SELinux context on the setup script's `/tmp` to `/etc` deploys. RHEL-only, and
closed until the owner confirms that production hosts run SELinux enforcing.

#### Scope

Item 3 only. Items 1 and 2 are examined-Keep (`CLOSED_DOORS.md` CI-29).

#### Completion Criteria

- The named condition is observed: the owner confirms a production
  SELinux-enforcing environment. The row then moves to Not started.

#### Dependencies And Decisions

- D1

#### GitHub Projection

Title: Extend atomic same-dir staging to the remaining deploy sites
Labels: P3-low, ops
GitHub Milestone: Backlog
Observed State: open
Last Compared: 2026-07-30

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
GitHub Issue: none
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
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

### M13 - Local logrotate state isolation

Origin: 1.2.3 / M12
Identity History: 1.2.3 draft M12 -> Backlog M13, owner decision 2026-08-11
GitHub Issue: 143, https://github.com/jeonghanlee/epics-ioc-runner/issues/143
Status: Deferred

#### Summary

Local configuration validation runs `logrotate -d` without selecting a state
file. Rocky logrotate treats an unreadable system default state file as an
error, so a root-owned state file left by an earlier system run prevents the
ordinary user's later local install from deploying rotation artifacts.

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
Observed State: Open
Observed Labels: bug, tests, ops
Observed Milestone: Backlog
Last Compared: 2026-08-11
