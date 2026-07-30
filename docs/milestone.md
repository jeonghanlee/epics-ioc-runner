# Work Register

Release line: 1.2.3
Canonical path: `docs/milestone.md`
Canonical branch or ref: `release-1.2.3`
Git upstream: none
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `1.2.3`

Next session entry point: write `docs/RELEASE_CYCLE_RUNBOOK.md` under M1, then
obtain plan acceptance for M1 and M2 before any implementation.

## Work

| ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | (#131) Re-set the verification scenarios and write the standing release-cycle runbook | Milestone | Not started | Yes | | `docs/RELEASE_CYCLE_RUNBOOK.md` exists and is standing, the scenario documents state expected results a driver can assert, and the retired cycle-plan file is gone; [detail](#m1---release-cycle-runbook-and-scenario-re-set) |
| M2 | (#130) Declare the `ioc-runner` baseline the goldens carry, in the gate procedure and in the gate record | Milestone | Not started | No | M1 | The runbook names how the baseline is chosen and a gate record carries it beside the suite counts; [detail](#m2---golden-baseline-declaration) |
| M3 | Final release 1.2.3 | Milestone | Not started | No | M1, M2 | Tag `1.2.3`, GitHub release, milestone closed, and every Release Verification row Pass; [detail](#m3---final-release) |

## Decisions

| ID | Decision | Source |
| --- | --- | --- |
| D1 | 1.2.3 is a verification cycle: documents and test scenarios only, no product code change. | Owner decision, 2026-07-30 |
| D2 | The register adopts the current `milestone-tracking` schema at this cycle open, and unassigned work moves to `docs/backlog.md`. | Owner decision, 2026-07-30 |
| D3 | `docs/testplan.md` is retired as an active file; the per-cycle plan lives in the final release detail of this register, and released cycles keep their plan through their tag. | Owner decision, 2026-07-30, following the current `release-cycle` contract |

## ID Migration

| Old ID | Current ID | Reason | Updated References |
| --- | --- | --- | --- |
| 1.2.2 register M1-M6 | none | The 1.2.2 line closed with its release; its rows are preserved in tag `1.2.2` and are not carried forward. | `git show 1.2.2:docs/milestone.md` |

## Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| (#130) Golden `ioc-runner` baseline named at bake time | Backlog, `docs/backlog.md`, `master` | 1.2.3, `docs/milestone.md`, `release-1.2.3` | this synchronization commit | this synchronization commit |

## Milestone Details

### M1 - Release-cycle runbook and scenario re-set

Origin: #131, filed 2026-07-30 from the 1.2.2 gate experience
Identity History: none
GitHub Issue: 131, https://github.com/jeonghanlee/epics-ioc-runner/issues/131
Status: Not started

#### Summary

The gate procedure lives inside a file that every cycle open overwrites, so the
standing part is re-derived each time. The 1.2.2 cycle showed the cost: the
gate ran on reused test beds rather than freshly baked goldens, the system
suites ran in a mode `tests/README.md` rules out for such hosts, and the
multi-user step was closed by citing an earlier run. Write the standing
procedure once, and re-set the scenario documents so a driver can assert them
without re-interpretation.

#### Scope

- `docs/RELEASE_CYCLE_RUNBOOK.md`, standing and not cleared at a cycle open,
  modelled on `cloud-provision/docs/RUNBOOK_BAKE.md`: preconditions including
  freshly baked goldens and the golden acceptance of that bake runbook; the
  gate steps in order, each naming its execution mode; the evidence format;
  the rule that the root_squash path and the multi-user plan run in the gate
  itself; red triage; upstream links in both directions; a reference to the
  release sequence rather than a copy of it.
- `docs/testplan_multiuser.md` reviewed so each scenario's expected result is
  stated precisely enough to drive it, with fixture dependencies named as a
  link to `ansible-provision/docs/test_users_handoff.md`.
- `docs/testplan.md` retired as an active file (D3).
- The pointer returned from the fixture handoff to this runbook, which lands in
  `ansible-provision`.

Out of scope: product code; making the runbook executable as a gate script,
which is a code change with its own verification.

#### Completion Criteria

- `docs/RELEASE_CYCLE_RUNBOOK.md` exists, is standing, and covers the six
  points above with upstream links in both directions.
- `docs/testplan_multiuser.md` states each scenario's expected result precisely
  enough to drive it without re-interpretation.
- `docs/testplan.md` is absent from the working tree and its role is carried by
  M3's final release detail.

#### Dependencies And Decisions

- D1, D3
- Cross-referenced, staying in `docs/backlog.md`: M5 there (#116) keeps the
  harness code changes; M7 (#118) is the false-green class this runbook records
  as a known limitation; M4 (#115) is the coverage gap the runbook names as
  still open.

#### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Draft `docs/RELEASE_CYCLE_RUNBOOK.md` from the bake runbook's form, using
   the 1.2.2 post-release verification as its first worked example.
2. Re-set `docs/testplan_multiuser.md` against what a driver actually needs.
3. Remove `docs/testplan.md` in the same commit that lands the runbook.
4. Prepare the fixture-handoff pointer edit for `ansible-provision`.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Document review | Read the runbook against `RUNBOOK_BAKE.md` and `tests/README.md`; every gate step names its execution mode and every precondition is checkable | Working tree | No step lacks a mode; no precondition is prose-only |
| T2 | Scenario drive | Drive two multi-user scenarios straight from `testplan_multiuser.md` without consulting any other document | Both goldens | Each expected result is assertable as written; no re-interpretation needed |
| T3 | Retirement check | Confirm `docs/testplan.md` is absent and that the register's final release detail carries the cycle plan | Working tree | The file is gone and no document references it as active |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Working tree | Pending | none |
| T2 | Not run | Both goldens | Pending | none |
| T3 | Not run | Working tree | Pending | none |

#### Closure Evidence

- none

#### GitHub Projection

Title: Re-set the verification scenarios and write the release-cycle runbook
Labels: docs, tests, P2-medium
GitHub Milestone: 1.2.3
Observed State: open
Observed Labels: P2-medium, docs, tests
Observed Milestone: 1.2.3
Last Compared: 2026-07-30

### M2 - Golden baseline declaration

Origin: #130, filed 2026-07-29 during the 1.2.2 gate
Identity History: Backlog row (`docs/backlog.md`) moved to this register at the 1.2.3 open
GitHub Issue: 130, https://github.com/jeonghanlee/epics-ioc-runner/issues/130
Status: Not started

#### Summary

The goldens ship a pre-installed `ioc-runner` whose version is whatever the
default branch pointed at when the image was baked, not a value anyone chose.
It is harmless while a gate deploys the tree under test over that copy, and it
stops being harmless the moment a result depends on the starting state.

#### Scope

The consuming half: which baseline each gate declares, and citing it in the
gate record beside the suite counts.

Out of scope: the provisioning implementation, which belongs to the
`ansible-provision` `app_ioc_runner` role.

#### Completion Criteria

- The runbook states which baseline the goldens carry and how it is chosen.
- A gate record carries the baseline version with its results, readable without
  inspecting the image.

#### Dependencies And Decisions

- M1 owns the runbook this declaration lands in.

#### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Add the baseline declaration to the runbook's preconditions and evidence
   format under M1.
2. Record the baseline in the 1.2.3 gate evidence rows.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Gate record | Read the 1.2.3 gate evidence rows | This register | Each golden's `ioc-runner` baseline version appears beside its counts |
| T2 | Image observation | Read the baked manifest and the deployed `-V` on each golden | Both goldens | The observed baseline matches the declared one |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | This register | Pending | none |
| T2 | Not run | Both goldens | Pending | none |

#### Closure Evidence

- none

#### GitHub Projection

Title: Name the golden's ioc-runner baseline at bake time instead of inheriting the default branch
Labels: P3-low, tests
GitHub Milestone: 1.2.3
Observed State: open
Observed Labels: P3-low, tests
Observed Milestone: 1.2.3
Last Compared: 2026-07-30

### M3 - Final release

Origin: this cycle open, 2026-07-30
Identity History: none
GitHub Issue: none
Status: Not started

#### Summary

Release 1.2.3 once the runbook and the baseline declaration land, and run the
gate by following that runbook so its first execution is also its first test.

#### Scope

Version change, release execution, and the final verification for the 1.2.3
line.

Out of scope: product behavior changes (D1).

#### Completion Criteria

- Every Release Verification row records Pass with reachable evidence.
- Tag `1.2.3`, the GitHub release, and the closed remote milestone exist.

#### Dependencies And Decisions

- M1, M2
- D1: no product code change, so the suites verify unchanged behavior.

#### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Bake both goldens fresh and record the golden acceptance.
2. Run the gate by following `docs/RELEASE_CYCLE_RUNBOOK.md`.
3. Execute the release sequence under `git-workflow` authority.

#### Integrated Verification

| Source Check | Re-run Trigger | Shared Surface | Release Verification Label | Expected Result | Result Evidence |
| --- | --- | --- | --- | --- | --- |
| M1 / T2 | The scenario documents change after the drive test | `docs/testplan_multiuser.md` | Release Verification 3 | The multi-user plan drives green from the final text | pending |
| M2 / T1 | The runbook's evidence format changes after the gate record is written | `docs/RELEASE_CYCLE_RUNBOOK.md` | Release Verification 4 | The gate record still carries the declared baseline | pending |

#### Production Environment Tests

| Release Verification Label | Timing | System | Version | Architecture | Deployment Path | Method | Expected Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Release Verification 8 | post-release | `alsucl-psrv3` | Rocky 8, NFS home with root_squash | x86_64 | `/usr/local/bin/ioc-runner` | Follow the documented install path from a checkout on the NFS home, then read `-V` | Install completes and `-V` reports `1.2.3` with a real short hash | pending |

#### Version Changes

| Field | File | Before | Planned After | Pre-check | Pre-check Label | Post-check | Post-check Label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `RUNNER_VERSION` | `bin/ioc-runner` | `1.2.2` | `1.2.3` | Read the declaration on the release branch | Release Verification 5 | Read the deployed `-V` after the tagged tree is installed | Release Verification 6 |

#### Release Execution

| Step | Action | Authorization | Expected Result | Evidence |
| --- | --- | --- | --- | --- |
| 1 | Bump `RUNNER_VERSION` to `1.2.3` on `release-1.2.3` | commit delegation | One standalone commit | pending |
| 2 | Merge `release-1.2.3` into `master` with `--no-ff` | release delegation | A merge commit on `master` | pending |
| 3 | Create the annotated tag `1.2.3` on that merge | release delegation | Tag object with the release title | pending |
| 4 | Push `master` and the tag | release delegation | Both refs on `origin` | pending |
| 5 | Create the GitHub release from the changelog section | release delegation | Release object with a curated body | pending |
| 6 | Close the remote milestone `1.2.3` | release delegation | Milestone state closed | pending |

#### Release Verification Plan

| Label | Layer | Timing | Method | Environment | Expected Result | Evidence Target |
| --- | --- | --- | --- | --- | --- | --- |
| Release Verification 1 | Golden acceptance | pre-change | The bake runbook's acceptance sequence: manifest ownership and hash, the provenance validator, the sidecar comparison, the deployed `-V` | Both goldens | All four checks pass and the baseline is recorded | Command output in the result row |
| Release Verification 2 | Automated suites | pre-change | All four suites in both permission modes, following the runbook's mode table | Both goldens | Green with counts recorded per host and mode | Suite summaries |
| Release Verification 3 | Standing scenarios | pre-change | The multi-user plan, driven from its own text | Both goldens | Every scenario meets its stated expected result | Per-scenario results |
| Release Verification 4 | Standing procedure | pre-change | The root_squash path through the three documented entry points from the `nfs_sim` mount | Both goldens | Each entry point stamps a real short hash with no layout warning | Stamp output and `-V` |
| Release Verification 5 | Version consistency | pre-change | Read `RUNNER_VERSION` on the release branch | Working tree | The value is the planned release version before the mutation is verified | Commit and file read |
| Release Verification 6 | Version consistency | post-change | Read the deployed `-V` from the tagged tree | Both goldens | `1.2.3` with a real short hash | `-V` output |
| Release Verification 7 | Release objects | post-release | Read the tag object, the release object, and the remote milestone state | GitHub | Tag, release, and closed milestone exist and match the merge commit | Object identifiers |
| Release Verification 8 | Production deployment | post-release | The documented install path on the production host | `alsucl-psrv3` | Install completes and the runner reports the released version | `-V` output |

#### Release Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| Release Verification 1 | Not run | Both goldens | Pending | none |
| Release Verification 2 | Not run | Both goldens | Pending | none |
| Release Verification 3 | Not run | Both goldens | Pending | none |
| Release Verification 4 | Not run | Both goldens | Pending | none |
| Release Verification 5 | Not run | Working tree | Pending | none |
| Release Verification 6 | Not run | Both goldens | Pending | none |
| Release Verification 7 | Not run | GitHub | Pending | none |
| Release Verification 8 | Not run | `alsucl-psrv3` | Pending | none |

#### Closure Evidence

- none

#### GitHub Projection

Title: none
Labels: none
GitHub Milestone: 1.2.3
Observed State: none
Last Compared: 2026-07-30
