# Work Register

Release line: master
Milestone index: a39623c
Canonical path: `docs/milestone-a39623c.md`
Canonical branch or ref: `master`
Git upstream: `origin/master`
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `Backlog`
Activation state: active on `master` as the post-1.2.3 reset generation

Next session entry point: 1.2.4 RELEASED 2026-08-17 (tag `1.2.4`, merge
`1961fbf`, GitHub release published, milestone 15 closed; the closed release
register is `docs/milestone-1.2.4.md`). Next: reset this master register from
its surviving work — the M1-M15 deferred set below plus 1.2.4's carry-forward
Backlog (M18, and M20/#148, the suite count-coherence guard) — then open
`release-1.3.0` (branch from master, register restart, bump to 1.3.0-dev).

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

No work is currently assigned to master.

### Decisions

| ID | Decision | Source |
| --- | --- | --- |
| D1 | #120 items 1 and 2 are examined-Keep and were retired; only item 3 (SELinux) remains, and it stays closed until the owner confirms a production SELinux-enforcing environment. | Owner decision, 2026-07-28; recorded in `CLOSED_DOORS.md` CI-29 |
| D2 | #129 stays out of the 1.2.2 and 1.2.3 lines: it changes runtime parsing for every key, and #122 already closed the specific gap at its single call site. | Owner decision, 2026-07-29 |
| D3 | The `docs/MILESTONE_PROCEDURE.md` draft stays in place and unchanged through 1.2.3; the release-cycle runbook references it rather than absorbing it, so the cycle stays a scenario re-set. | Owner decision, 2026-07-30 |
| D4 | The local logrotate state-file defect is separate product work for 1.2.4. Keep it out of 1.2.3 M11 and leave the root-owned system state file unchanged. | Owner decision, 2026-08-11 |
| D5 | Open 1.2.4 as a bugfix line with M3, M7, M6, and M13 in that order, followed by the final release work. Target M1, M2, M4, M5, M9, M10, M11, M12, M14, and M15 for 1.3.0 when that cycle opens. Keep M8 conditional in Backlog. | Owner decision, 2026-08-12 |

### Assignment History

| Identity | From | To | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| a39623c / M3 | `master`, `docs/milestone-a39623c.md` | `release-1.2.4`, `docs/milestone-1.2.4.md` | `4bcd63847fef73833946a49a1af05d29fc65bd8d` | this synchronization commit |
| a39623c / M6 | `master`, `docs/milestone-a39623c.md` | `release-1.2.4`, `docs/milestone-1.2.4.md` | `4bcd63847fef73833946a49a1af05d29fc65bd8d` | this synchronization commit |
| a39623c / M7 | `master`, `docs/milestone-a39623c.md` | `release-1.2.4`, `docs/milestone-1.2.4.md` | `4bcd63847fef73833946a49a1af05d29fc65bd8d` | this synchronization commit |
| a39623c / M13 | `master`, `docs/milestone-a39623c.md` | `release-1.2.4`, `docs/milestone-1.2.4.md` | `4bcd63847fef73833946a49a1af05d29fc65bd8d` | this synchronization commit |

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| | M1 | (#102) Fleet-layer reliability: restart-storm boundary and running-IOC hang detection | Milestone | Deferred | No | D5 | Transfer it when the 1.3.0 release line opens and its scope is settled; [detail](#m1---fleet-layer-reliability) |
| | M2 | (#113) Unify the three conf parsers behind one shared parse core | Milestone | Deferred | No | D5 | Transfer it when the 1.3.0 release line opens and its scope is settled; [detail](#m2---conf-parser-unification) |
| | M4 | (#115) Exercise restart supervision end-to-end on the goldens | Milestone | Deferred | No | D5 | Transfer it when the 1.3.0 release line opens; [detail](#m4---restart-supervision-probe) |
| | M5 | (#116) Exercise the deployed local logrotate oneshot through systemd | Milestone | Deferred | No | D5 | Transfer the remaining real systemd path when the 1.3.0 release line opens; [detail](#m5---suite-integrity) |
| | M8 | (#120 item 3) SELinux context on the setup deploys, RHEL-only | Milestone | Conditional | No | D1 | The owner confirms production hosts run SELinux enforcing; [detail](#m8---selinux-context) |
| | M9 | (#127) Container execution mode without systemd | Milestone | Deferred | No | D5 | Transfer it when the 1.3.0 release line opens; [detail](#m9---container-execution-mode) |
| | M10 | (#129) Unify conf-value normalization between `read_conf_var` and `read_conf_all` | Milestone | Deferred | No | D5 | Transfer it when the 1.3.0 release line opens; [detail](#m10---conf-value-normalization) |
| | M11 | (#132) Settle the fate of the `docs/MILESTONE_PROCEDURE.md` working draft: fold into a skill, keep as a repository document, or absorb | Milestone | Deferred | No | D3, D5 | Transfer it when the 1.3.0 release line opens and the boundary with the release-cycle runbook is settled; [detail](#m11---milestone-procedure-draft-fate) |
| | M12 | (#144) Separate human-readable test output from machine-readable records | Milestone | Deferred | No | D5 | Transfer it when the 1.3.0 release line opens and the output contract is settled; [detail](#m12---human-and-machine-output-separation) |
| | M14 | (#139) Stop EPICS-dependent test scripts before setup when `EPICS_BASE` is unset | Milestone | Deferred | No | D5 | Transfer it when the 1.3.0 release line opens; [detail](#m14---epics-base-entry-boundary) |
| | M15 | (#142) Diagnose a conf/mode mismatch in one message | Milestone | Deferred | No | D5 | Transfer it when the 1.3.0 release line opens; [detail](#m15---conf-mode-mismatch-diagnosis) |

### Backlog Details

#### M1 - Fleet-layer reliability

Origin: a39623c / M1
Identity History: none
GitHub Issue: 102, https://github.com/jeonghanlee/epics-ioc-runner/issues/102
Status: Deferred

##### Summary

Restart-storm boundary and running-IOC hang detection: the fleet-level
reliability work that the 1.3.0 theme is built around.

##### Scope

Running-time hang detection through an active health signal, plus fleet-level
restart-storm observability and orchestrated recovery.

##### Out of Scope

Unit-layer restart jitter, `ExecStartPre` random delay, or changing the
per-IOC indefinite-restart policy.

##### Completion Criteria

- The owner assigns the work to a release line and accepts its health signal.
- A live-but-unresponsive IOC is detected without requiring process exit.
- Fleet monitoring exposes synchronized failures and a documented recovery
  path controls restart load after a shared dependency returns.

##### Dependencies And Decisions

- systemd service units have no restart jitter. `RandomizedDelaySec` applies
  to timer units, not service restarts.
- `RestartSteps` and `RestartMaxDelaySec` require systemd v254 or later,
  remain phase-synchronized across identical units, and are unavailable on
  Rocky 8 systemd 239.
- An `ExecStartPre` random delay would affect every start and restart and
  conflict with the measured per-IOC stabilization window established by
  #67. Restart-storm control therefore remains a fleet and operations-layer
  responsibility rather than a per-IOC unit change.
- Related history: #52, #54, and #67.
- D5 targets this work for 1.3.0 when that release cycle opens.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Select the running-IOC health signal and fleet monitoring boundary.
2. Implement active hang detection and fleet recovery observability outside
   the per-IOC systemd unit.
3. Verify a live-but-unresponsive IOC and a common-cause fleet outage.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime health | Make a real IOC process remain alive while its selected health signal stops progressing | Assigned release goldens | Monitoring detects the hang without waiting for process exit or a crash token |
| T2 | Fleet recovery | Interrupt a shared dependency for multiple running IOCs and restore it | Assigned fleet test environment | Monitoring exposes the synchronized failures and the documented recovery path controls restart load |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Assigned release goldens | Pending | none |
| T2 | Not run | Assigned fleet test environment | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Fleet-layer reliability: restart-storm boundary and running-IOC hang detection
Labels: enhancement, P3-low, ops, area/architecture
GitHub Milestone: Backlog
Observed State: open
Observed Labels: enhancement, P3-low, ops, area/architecture
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:37Z

#### M2 - Conf parser unification

Origin: a39623c / M2
Identity History: none
GitHub Issue: 113, https://github.com/jeonghanlee/epics-ioc-runner/issues/113
Status: Deferred

##### Summary

Three conf parsers disagree on trimming, duplicate keys, and CRLF. One shared
parse core plus divergence fixtures pinning install-time acceptance to runtime
interpretation.

##### Scope

One configuration contract for trimming, quotes, duplicate keys, and CRLF,
shared by the runner's install-time and runtime readers and constrained so the
systemd `EnvironmentFile` interpretation agrees.

##### Out of Scope

Changing the supported configuration keys or adding a second configuration
format.

##### Completion Criteria

- The owner assigns the behavior-visible parser change to a release line.
- Every divergence fixture resolves identically through install-time, runtime,
  and systemd consumers, or is rejected before deployment.
- Real install and start paths agree on the accepted artifact.

##### Dependencies And Decisions

- Related: M10 (#129) is the narrow two-reader case inside this general work.
- D5 targets this work for 1.3.0 when that release cycle opens.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define one trim, quote, duplicate-key, and CRLF contract.
2. Route the shipped configuration consumers through one parse core.
3. Pin the contract with divergence fixtures and real install/runtime checks.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Parser contract | Feed whitespace, quote, duplicate-key, and CRLF fixtures through every shipped configuration reader | Source test environment | Every reader resolves each fixture to the same value or the same rejection |
| T2 | Lifecycle integration | Install and start an IOC from the accepted divergence fixtures through the shipped commands | Assigned release goldens | Install-time acceptance and runtime interpretation agree |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Source test environment | Pending | none |
| T2 | Not run | Assigned release goldens | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Unify the three conf parsers behind one shared parse core
Labels: P2-medium, refactor, area/architecture
GitHub Milestone: Backlog
Observed State: open
Observed Labels: P2-medium, refactor, area/architecture
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:37Z

#### M4 - Restart supervision probe

Origin: a39623c / M4
Identity History: none
GitHub Issue: 115, https://github.com/jeonghanlee/epics-ioc-runner/issues/115
Status: Deferred

##### Summary

No automated test kills a running IOC and asserts recovery; the ADR 0001
promise is pinned only by static directive-row guards.

##### Scope

An automated golden-VM probe that starts a healthy managed softIoc, kills the
child with `SIGKILL`, and observes systemd and procServ recovery.

##### Out of Scope

Changing the restart policy or replacing the existing static directive
guards.

##### Completion Criteria

- The owner assigns the probe to a release line.
- Killing the child increases the child-death banner count and the unit
  returns to active with a new child on both golden OS families.

##### Dependencies And Decisions

- Named as a still-open coverage gap by the 1.2.3 runbook work (#131), so a
  gate record cannot read as if restart supervision had been exercised.
- D5 targets this work for 1.3.0 when that release cycle opens.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Start the healthy softIoc fixture through the shipped systemd path.
2. Kill the softIoc child with `SIGKILL` while leaving supervision active.
3. Poll for recovery and compare the procServ child-death banner count.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Restart supervision | Kill the real softIoc child of a healthy managed IOC and observe the unit and log | Both golden OS families | The child-death count increases and the unit returns to active with a new child |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Both golden OS families | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Exercise restart supervision end-to-end on the goldens
Labels: P2-medium, tests
GitHub Milestone: Backlog
Observed State: open
Observed Labels: P2-medium, tests
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:40Z

#### M5 - Suite integrity

Origin: a39623c / M5
Identity History: none
GitHub Issue: 116, https://github.com/jeonghanlee/epics-ioc-runner/issues/116
Status: Deferred

##### Summary

The original issue contained two test-integrity gaps. The shared reporter now
closes the executed-versus-counted gap: every suite declares a complete
catalog, records one terminal state per identity, and resolves missing or
duplicate results as `SCRIPT_ERROR`. The remaining gap is that the local
lifecycle suite invokes logrotate directly and never starts the deployed
`epics-logrotate.service` through the user systemd manager.

##### Scope

Run the real deployed oneshot through `systemctl --user` and verify its result,
rotation effect, and `%t/ioc-runner-logrotate.state` path. The check must use
the shipped unit and real logrotate binary rather than reproducing the
`ExecStart` command.

##### Out of Scope

Changing the shared reporter, adding a second counter, changing product
logrotate policy, or implementing #143's install-time validation fix.

##### Completion Criteria

- The owner assigns the remaining systemd path to a release line.
- The deployed oneshot completes successfully through the real user manager
  on both applicable golden environments and produces the expected rotation.
- A broken deployed `ExecStart` makes the check fail.

##### Dependencies And Decisions

- The catalog-ledger half completed in commits `f5871c7`, `1893c6e`, and
  `a60802b`; it is checked in the GitHub issue and is not remaining work.
- #143 covers install-time `logrotate -d` state isolation. This row covers the
  deployed runtime systemd path.
- D5 targets this remaining work for 1.3.0 when that release cycle opens.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Prepare a safe local log fixture under the deployed user configuration.
2. Start the shipped `epics-logrotate.service` through `systemctl --user`.
3. Verify the oneshot result, rotation effect, and per-user runtime state path.
4. Prove that a broken deployed `ExecStart` turns the real-path check red.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime unit | Start the deployed oneshot through the real user systemd manager | Debian and Rocky goldens where the user manager is available | The unit completes and produces the expected rotation effect |
| T2 | Honest red | Install an isolated broken unit and start it through the same public systemd path | Golden VM test workspace | The check fails on the broken `ExecStart` |
| T3 | State isolation | Inspect the resolved runtime state and the system default state before and after T1 | Both applicable goldens | The service uses `%t/ioc-runner-logrotate.state` and does not modify the system default state |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Both applicable goldens | Pending | none |
| T2 | Not run | Golden VM test workspace | Pending | none |
| T3 | Not run | Both applicable goldens | Pending | none |

##### Closure Evidence

- The catalog-ledger half is complete; the remaining runtime unit path has no
  closure evidence.

##### GitHub Projection

Title: Extend suite integrity: tripwire port and the M19 oneshot under systemd
Labels: P3-low, tests
GitHub Milestone: Backlog
Observed State: open
Observed Labels: P3-low, tests
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:41Z

#### M8 - SELinux context

Origin: a39623c / M8
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

#### M9 - Container execution mode

Origin: a39623c / M9
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

- D5 targets this work for 1.3.0 when that release cycle opens.

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

#### M10 - Conf value normalization

Origin: a39623c / M10
Identity History: none
GitHub Issue: 129, https://github.com/jeonghanlee/epics-ioc-runner/issues/129
Status: Deferred

##### Summary

`read_conf_var` and `read_conf_all` normalize a value differently: the runtime
reader neither trims nor applies the trim-before-unquote ordering that install
uses, so one conf line can reach two verdicts.

##### Scope

One trim-before-unquote normalization step shared by `read_conf_var` and
`read_conf_all`, covering whitespace around `=`, quoted values, and quoted
whitespace-only values.

##### Out of Scope

The `CRASH_LOG_PATTERNS_EXTRA` call-site trim, which #122 landed.

##### Completion Criteria

- The owner assigns the runtime-visible parser change to a release line.
- Both readers return the identical string for every whitespace- and
  quote-bearing fixture.
- Maintained lifecycle and error-handling paths remain green.

##### Dependencies And Decisions

- D2
- Related: M2 (#113) subsumes this once the shared parse core exists.
- D5 targets this work for 1.3.0 when that release cycle opens.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define one trim-before-unquote value-normalization function.
2. Route `read_conf_var` and `read_conf_all` through it and remove the local
   #122 workaround when it becomes redundant.
3. Pin both readers to identical results on whitespace- and quote-bearing
   fixtures.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Reader equivalence | Pass spaces around `=`, quoted values, and quoted whitespace through both shipped readers | Source test environment | Both readers return the identical normalized string for every fixture |
| T2 | Lifecycle regression | Run the maintained error-handling and lifecycle paths with representative configuration keys | Assigned release environments | No supported key relies on preserving the divergent whitespace behavior |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Source test environment | Pending | none |
| T2 | Not run | Assigned release environments | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Unify conf-value normalization between read_conf_var and read_conf_all
Labels: bug, P3-low, area/architecture
GitHub Milestone: Backlog
Observed State: open
Observed Labels: bug, P3-low, area/architecture
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:46Z

#### M11 - Milestone procedure draft fate

Origin: a39623c / M11
Identity History: none
GitHub Issue: 132, https://github.com/jeonghanlee/epics-ioc-runner/issues/132
Status: Deferred

##### Summary

`docs/MILESTONE_PROCEDURE.md` carries the per-milestone procedure - plan review
before code, the owner gate, de-knotting, implementation, verification on the
real path, and the reconcile-and-land step - with the 1.2.2 M2, M3 and M4 runs
as worked examples. Its own first line names the fate it expects: fold it into
a skill. That fate has never been decided.

##### Scope

Decide between the three fates and carry it out: fold the draft into a skill,
keep it as a repository document with the draft marker removed, or absorb it
into another document. The decision settles its boundary with
`gate/RUNBOOK.md`, which covers the release gate rather than the
work inside a cycle.

##### Out of Scope

The 1.2.3 line, which references the draft and leaves it unchanged (D3).

##### Completion Criteria

- The owner assigns the work to a release line and chooses one of the three
  fates.
- No live document calls the surviving procedure a working draft.
- The release-cycle runbook reference remains resolvable and the two
  procedures state non-overlapping boundaries.

##### Dependencies And Decisions

- D3
- The runbook written under 1.2.3 M1 (#131) references this draft, so whichever
  fate is chosen must keep that reference resolvable.
- D5 targets this work for 1.3.0 when that release cycle opens.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Select fold-into-skill, keep-as-repository-document, or absorb.
2. Apply the selected fate and update every live reference.
3. Verify that the release-cycle runbook still reaches the surviving
   milestone procedure.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Reference integrity | Search tracked documentation after applying the selected fate | Working tree | No document calls the survivor a working draft and every live link resolves |
| T2 | Procedure boundary | Review the surviving procedure against `gate/RUNBOOK.md` | Working tree | Per-milestone work and release-gate work have one explicit, non-overlapping authority each |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Working tree | Pending | none |
| T2 | Not run | Working tree | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Settle the fate of the milestone procedure working draft
Labels: P3-low, docs
GitHub Milestone: Backlog
Observed State: open
Observed Labels: P3-low, docs
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:47Z

#### M12 - Human and machine output separation

Origin: a39623c / M12
Identity History: none
GitHub Issue: 144, https://github.com/jeonghanlee/epics-ioc-runner/issues/144
Status: Deferred

##### Summary

The test suites currently print the human summary and the machine-readable
`TEST`, `STEP`, and `SUITE` records in one terminal output. The complete
machine record sequence obscures the result intended for an operator.

##### Scope

Define and implement separate output surfaces for the human report and the
machine-readable record sequence. Both outputs continue to derive from the
same validated ledger, and the collector consumes only the machine-readable
surface.

##### Out of Scope

Changing the fixed check identities, terminal states, suite-state semantics,
or the accepted M8 count vectors. This work is not part of the 1.2.3 M8
remediation.

##### Completion Criteria

- A normal operator invocation displays the human report without the full
  `TEST`, `STEP`, and `SUITE` sequence.
- A documented machine-readable surface preserves the complete accepted record
  grammar and final suite state.
- The collector reads only the machine-readable surface and rejects missing,
  malformed, duplicate, or inconsistent records.
- Real producer and dispatcher runs prove that both outputs describe the same
  ledger and process result.

##### Dependencies And Decisions

- Owner direction, 2026-08-10: record human and machine output separation as
  later milestone work rather than extending the active M8 remediation.
- The implementation must preserve the M8 reporting contract and the fixed
  488-check identity set.
- D5 targets this work for 1.3.0 when that release cycle opens.

##### Implementation Plan

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

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Reporter contract | Run the shipped reporter self-test through its public API | Working tree | Human and machine outputs reconcile to one ledger while using separate surfaces |
| T2 | Collector integration | Run the shipped collector probe and a real source-regression dispatcher path | Debian 13 | The operator output stays concise and the collector validates the complete machine record sequence |
| T3 | Producer integration | Run all five shipped producer paths | Both golden OS families | Every fixed identity closes once and both output surfaces carry the same suite result |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Working tree | Pending | none |
| T2 | Not run | Debian 13 | Pending | none |
| T3 | Not run | Both golden OS families | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Separate human-readable test output from machine-readable records
Labels: tests
GitHub Milestone: Backlog
Observed State: open
Observed Labels: tests
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:48Z

#### M14 - EPICS_BASE entry boundary

Origin: a39623c / M14
Identity History: none
GitHub Issue: 139, https://github.com/jeonghanlee/epics-ioc-runner/issues/139
Status: Deferred

##### Summary

The dispatcher checks `EPICS_BASE` before launching an EPICS-dependent suite.
The direct local and system lifecycle suites instead initialize the reporter,
evaluate all P00 prerequisites, record the missing environment as FAIL, and
close the remaining catalog as SKIP. They do not enter workspace setup or
lifecycle execution, so this is an inconsistent entry boundary rather than a
false green.

##### Scope

Inventory every shipped test entry point that consumes `EPICS_BASE`, make the
missing variable its first environment boundary, and preserve the complete
catalog reporter contract without later dependency, privilege, workspace,
compilation, systemd, or IOC work.

##### Out of Scope

Sourcing an EPICS environment automatically, making source regression depend
on EPICS Base, changing IOC behavior, or weakening the reporter's
complete-state contract.

##### Completion Criteria

- The owner assigns the test-entry boundary to a release line.
- Every affected entry point stops nonzero at its first environment boundary
  and performs no later setup or lifecycle work.
- Direct suites close every catalog identity once with no `SCRIPT_ERROR`.
- The source-regression-only selection still runs without `EPICS_BASE`.
- The real lifecycle paths remain unchanged when `EPICS_BASE` is present.

##### Dependencies And Decisions

- The 1.2.3 gate ran with the declared EPICS environment on both goldens, so
  this inconsistency does not invalidate its evidence.
- D5 targets this work for 1.3.0 when that release cycle opens.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Inventory the EPICS-dependent entry points and pin that set.
2. Define the first-boundary reporter result for each direct suite.
3. Move the environment stop ahead of every unrelated probe and side effect.
4. Re-run the missing-environment and real lifecycle paths.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Entry contract | Run every EPICS-dependent entry point with `EPICS_BASE` unset | Debian 13 | Nonzero at the first boundary, no later work, complete catalog, no `SCRIPT_ERROR` |
| T2 | Independent path | Run `tests/run-all-tests.bash --source-regression` without `EPICS_BASE` | Debian 13 | Source regression executes normally |
| T3 | Positive path | Run both real lifecycle suites with the declared EPICS environment | Both golden OS families | Existing shipped paths and fixtures complete normally |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Debian 13 | Pending | none |
| T2 | Not run | Debian 13 | Pending | none |
| T3 | Not run | Both golden OS families | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Stop EPICS-dependent test scripts before setup when EPICS_BASE is unset
Labels: P3-low, tests
GitHub Milestone: Backlog
Observed State: open
Observed Labels: P3-low, tests
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:50Z

#### M15 - Conf mode mismatch diagnosis

Origin: a39623c / M15
Identity History: none
GitHub Issue: 142, https://github.com/jeonghanlee/epics-ioc-runner/issues/142
Status: Deferred

##### Summary

Identity validation safely rejects a configuration whose `IOC_USER` and
`IOC_GROUP` do not match the selected execution mode, but it reports two
field-level errors and leaves the operator to infer one mode mismatch. It does
not show the values found, name the file, or provide the correct regeneration
command.

##### Scope

When both identity fields support the diagnosis, emit one found-versus-needed
mode-mismatch message with the configuration path and correct `generate`
command. A third-account configuration receives the comparison and remedy
without an unsupported mode claim. System mode remains the unflagged default;
there is no `--system` option.

##### Out of Scope

Rewriting the configuration during install, switching modes, adding a
`--system` option, or changing the identity validation rules.

##### Completion Criteria

- The owner assigns the operator-message change to a release line.
- Both supported mismatch directions produce one complete diagnosis and the
  correct regeneration command.
- A third-account case does not claim either supported source mode.
- Invalid identity values still abort without rewriting the configuration.
- Tests update the error-count and message contract deliberately.

##### Dependencies And Decisions

- This is an operator-message improvement, not a validation bypass. The hard
  failure behaved correctly during the 1.2.3 verification.
- D5 targets this work for 1.3.0 when that release cycle opens.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Classify the two supported opposite-mode pairs and the third-account case.
2. Render one diagnosis from the selected and found identities.
3. Update the validation count and message tests.
4. Run the real install validation paths in both modes.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local mismatch | Install a system-mode conf with `--local` through the shipped install path | Debian 13 | One complete diagnosis and `generate --local` remedy; install aborts |
| T2 | System mismatch | Install a local-mode conf in default system mode through the shipped path | Debian 13 | Mirror diagnosis and unflagged `generate` remedy; install aborts |
| T3 | Unknown account | Install a conf naming neither supported identity | Debian 13 | Found-versus-needed output without a source-mode claim; install aborts |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Debian 13 | Pending | none |
| T2 | Not run | Debian 13 | Pending | none |
| T3 | Not run | Debian 13 | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Diagnose conf/mode mismatch in one message
Labels: enhancement, P2-medium, area/install
GitHub Milestone: Backlog
Observed State: open
Observed Labels: enhancement, P2-medium, area/install
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-12; remote updated 2026-08-13T05:52:51Z

## History

| Reset Date | Prior State Commit |
| --- | --- |
| 2026-08-12 | `a39623cc46ffec3c870474da65af52126d6d4b96` |
