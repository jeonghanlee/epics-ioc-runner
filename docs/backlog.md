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
| M13 | (#140) Determine when the local monitor-isolation test can rely on a user journal | Milestone | Open | No | D4 | VM and production scenarios identify where S29 applies, how the prerequisite is provided, and how each scenario is verified; [detail](#m13---user-journal-applicability) |

## Decisions

| ID | Decision | Source |
| --- | --- | --- |
| D1 | #120 items 1 and 2 are examined-Keep and were retired; only item 3 (SELinux) remains, and it stays closed until the owner confirms a production SELinux-enforcing environment. | Owner decision, 2026-07-28; recorded in `CLOSED_DOORS.md` CI-29 |
| D2 | #129 stays out of the 1.2.2 and 1.2.3 lines: it changes runtime parsing for every key, and #122 already closed the specific gap at its single call site. | Owner decision, 2026-07-29 |
| D3 | The `docs/MILESTONE_PROCEDURE.md` draft stays in place and unchanged through 1.2.3; the release-cycle runbook references it rather than absorbing it, so the cycle stays a scenario re-set. | Owner decision, 2026-07-30 |
| D4 | The Rocky user-journal prerequisite observed during the 1.2.3 gate is not changed in 1.2.3. After 1.2.3, examine VM and production environments separately, define the possible supported scenarios, and only then decide whether provisioning, test applicability, or both should change. A missing journal cannot verify monitor isolation and must not be treated as a pass. | Owner decision, 2026-08-10 |

## Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| (#130) Golden `ioc-runner` baseline named at bake time | Backlog, `docs/milestone.md` 1.2.2 register, `master` | 1.2.3, `docs/milestone.md`, `release-1.2.3` | this synchronization commit | this synchronization commit |

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
  487-check identity set.

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

### M13 - User journal applicability

Origin: 1.2.3 M5 / T6 observation on the reused Rocky 8 golden, 2026-08-10
Identity History: none
GitHub Issue: 140, https://github.com/jeonghanlee/epics-ioc-runner/issues/140
Status: Open

#### Summary

The local lifecycle monitor-isolation test needs a readable user systemd
journal as its positive control. On the reused Rocky 8 golden,
`/var/log/journal` is absent, `vmadmin` has `Linger=no` and no
`systemd-journal` membership, and `journalctl --user` reports insufficient
permissions. S29 therefore cannot distinguish blocked monitor input from an
unreadable output channel and correctly records three SKIPs in each runner
mode.

The available evidence does not establish whether this is specific to the VM
golden, also occurs on production hosts, or represents one of several supported
operating scenarios. Resolve that question after 1.2.3 rather than changing the
test or host policy inside the release gate.

#### Scope

- Compare golden VM and representative production environments for journal
  storage, active login state, linger, user ACL or group access, and user-unit
  journal visibility.
- Enumerate the supported scenarios in which S29 can and cannot verify monitor
  isolation.
- Decide from measured environments whether a later release should change
  provisioning, test applicability, or both.

Out of scope: changing the 1.2.3 verdict, enabling journal access on the current
golden in place, changing product behavior, or treating an unavailable journal
as a successful monitor-isolation verification.

#### Completion Criteria

- A scenario matrix distinguishes VM and production environments and records
  the exact journal prerequisite present or absent in each.
- Every available scenario is measured through the shipped S29 real path; an
  unavailable production scenario remains explicitly unknown rather than
  inferred from a VM.
- The owner selects the supported scenarios and assigns any provisioning or
  test change to a post-1.2.3 release.
- No scenario reports monitor isolation as verified without a visible positive
  control from the IOC user unit.

#### Dependencies And Decisions

- D4
- Related release evidence: 1.2.3 `docs/milestone.md`, M5 / T6 and M6 / T1.
- `docs/FAQ.md` Q9 describes active-login, linger, persistent-journal, and
  journal-access conditions but does not decide which production scenarios are
  supported.

#### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Record the journal conditions on both golden VM families and on each
   available representative production host class.
2. Build the scenario matrix from active-login, linger, persistent-storage,
   ACL or group-access, and unavailable-journal combinations actually found.
3. Run the shipped local lifecycle S29 path in each available scenario and
   retain the positive-control and input-isolation result.
4. Present the measured matrix for an owner decision before proposing any
   provisioning or test change.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Golden VM scenarios | Run the shipped local lifecycle S29 path and inspect its journal prerequisites | Debian and Rocky golden VMs | Each VM state is measured and S29 either runs with a visible positive control or records the exact unavailable boundary |
| T2 | Production scenarios | Run the same read-only prerequisite checks and, where authorized, the shipped S29 path | Representative production host classes | Production applicability is observed directly and is not inferred from a VM result |
| T3 | Scenario decision | Re-run the selected supported scenarios after the chosen provisioning or test change | Environments selected by the owner | Every supported applicable scenario verifies monitor isolation; every inapplicable scenario has an explicit policy basis |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Golden VMs | Pending | The 1.2.3 Rocky observation is origin evidence, not this post-1.2.3 matrix run |
| T2 | Not run | Production | Pending | none |
| T3 | Not run | Owner-selected scenarios | Pending | none |

#### Closure Evidence

- none

#### GitHub Projection

Title: Determine user-journal applicability for local monitor isolation
Labels: tests, ops
GitHub Milestone: Backlog
Observed State: open
Observed Labels: ops, tests
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Observed Updated At: 2026-08-11T00:53:33Z
Last Compared: 2026-08-10T17:53:33-07:00
