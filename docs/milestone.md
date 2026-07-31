# Work Register

Release line: 1.2.3
Canonical path: `docs/milestone.md`
Canonical branch or ref: `release-1.2.3`
Git upstream: none
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `1.2.3`

Next session entry point: finish M1 — run T1, the document review of the
runbook against `RUNBOOK_BAKE.md` and `tests/README.md`, and prepare the
fixture-handoff pointer edit that lands in `ansible-provision`. Then obtain
plan acceptance for M2.

## Work

| ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | (#131) Re-set the verification scenarios and write the standing release-cycle runbook | Milestone | In progress | Yes | | `docs/RELEASE_CYCLE_RUNBOOK.md` exists and is standing, its multi-user scenarios state expected results a driver can assert and carry the drive commands, and both retired plan files are gone; [detail](#m1---release-cycle-runbook-and-scenario-re-set) |
| M2 | (#130) Declare the `ioc-runner` baseline the goldens carry, in the gate procedure and in the gate record | Milestone | Not started | No | M1 | The runbook names how the baseline is chosen and a gate record carries it beside the suite counts; [detail](#m2---golden-baseline-declaration) |
| M3 | Final release 1.2.3 | Milestone | Not started | No | M1, M2 | Tag `1.2.3`, GitHub release, milestone closed, and every Release Verification row Pass; [detail](#m3---final-release) |

## Decisions

| ID | Decision | Source |
| --- | --- | --- |
| D1 | 1.2.3 is a verification cycle: documents and test scenarios only, no product code change. | Owner decision, 2026-07-30 |
| D2 | The register adopts the current `milestone-tracking` schema at this cycle open, and unassigned work moves to `docs/backlog.md`. | Owner decision, 2026-07-30 |
| D3 | `docs/testplan.md` is retired as an active file; the per-cycle plan lives in the final release detail of this register, and released cycles keep their plan through their tag. | Owner decision, 2026-07-30, following the current `release-cycle` contract |
| D4 | `docs/MILESTONE_PROCEDURE.md` stays in place and unchanged through this cycle; the runbook references it rather than absorbing it, and its fate is recorded as backlog M11. | Owner decision, 2026-07-30 |

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
- `docs/testplan_multiuser.md` absorbed into the runbook and retired as a
  separate file: its scenarios are a gate step, so a second procedure document
  for one operation is what let that step be closed by citation. The absorbed
  text carries each scenario's expected result and the commands that drive it,
  with the fixture accounts verified rather than created.
- `docs/testplan.md` retired as an active file (D3).
- The pointer returned from the fixture handoff to this runbook, which lands in
  `ansible-provision`.

Out of scope: product code; making the runbook executable as a gate script,
which is a code change with its own verification.

#### Completion Criteria

- `docs/RELEASE_CYCLE_RUNBOOK.md` exists, is standing, and covers the six
  points above with upstream links in both directions.
- The runbook states each multi-user scenario's expected result precisely
  enough to drive it without re-interpretation, and carries the drive commands.
- `docs/testplan.md` and `docs/testplan_multiuser.md` are absent from the
  working tree; the cycle plan's role is carried by M3's final release detail
  and the standing procedure's role by the runbook.

#### Dependencies And Decisions

- D1, D3, D4
- Cross-referenced, staying in `docs/backlog.md`: M11 there carries the fate of
  the `MILESTONE_PROCEDURE.md` draft, which this runbook references and leaves
  unchanged.
- Cross-referenced, staying in `docs/backlog.md`: M5 there (#116) keeps the
  harness code changes; M7 (#118) is the false-green class this runbook records
  as a known limitation; M4 (#115) is the coverage gap the runbook names as
  still open.

#### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner, 2026-07-30, on the section outline presented in the
design conversation
Implementation Authorization: owner, 2026-07-30, same exchange
Superseded Plan Artifacts: none

1. Draft `docs/RELEASE_CYCLE_RUNBOOK.md` from the bake runbook's form, carrying
   no version, date, issue number, or measured count in the body.
2. Absorb the multi-user scenarios into it and retire the separate file.
3. Drive every scenario on both goldens, and correct the document wherever the
   observed behavior differs from what it claims.
4. Remove `docs/testplan.md` in the same commit that lands the runbook, and
   repoint every live reference.
5. Prepare the fixture-handoff pointer edit for `ansible-provision`.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Document review | Read the runbook against `RUNBOOK_BAKE.md` and `tests/README.md`; every gate step names its execution mode and every precondition is checkable | Working tree | No step lacks a mode; no precondition is prose-only |
| T4 | Command execution | Execute the runbook's own commands on the goldens — fixture check, golden acceptance, the four suites in both modes — and correct any that do not behave as the document claims | Both goldens | Every command runs as written, or the document is corrected to what was observed |
| T5 | Document-only execution | Rebake, rebuild the consumers, and run the whole procedure driven by the runbook text alone, substituting only the placeholders it defines; record every place the document had to be supplemented | Both goldens | The procedure completes from the document alone, or each insufficiency is corrected and the corrected form re-executed |
| T2 | Scenario drive | Drive every multi-user scenario straight from the runbook, on both goldens, without consulting any other document | Both goldens | Each expected result is assertable as written, or the document is corrected to what was observed |
| T3 | Retirement check | Confirm both retired plan files are absent and that no live document references them | Working tree | The files are gone and every remaining reference points at the runbook or the register |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-07-30 | Working tree | Pass, after correction | Two independent read-only reviews followed the author's own pass, one asking whether a first-time operator could execute the document alone and one comparing it against every document it depends on. Between them they returned thirty-two findings; each was checked against the code or the live goldens before acting, and the confirmed ones are listed under T5. Three were factual errors the author had carried in: there is no crash-scan verb, so the scenario that named one could not be executed as written; `/opt/epics-iocs` is created by the bake, not by the setup script the document implied; and the provenance validator accepts a dirty application record although the bake runbook forbids one at final acceptance, so the acceptance step needed its own check. One finding did not reproduce here and was recorded rather than applied: the stale-host-key case, where this control host's client accepts a new key without prompting. Author's own pass, run first: read against `RUNBOOK_BAKE.md` and `tests/README.md`, six defects found and fixed. Ordering: the consumer VMs must be destroyed before the bake, not after it — the bake refuses to publish while a disk backs onto the target image, which is what a running consumer does; the document had the destroy step in the wrong section, and the run hit exactly that. Execution mode: the multi-user step named none, and it is always the deployed binary. Precision: the system infrastructure suite has no binary axis, so claiming the mode matters there was wrong. Checkability: `IMAGE_DIR` was used with nothing saying where it comes from; the acceptance block used a plain `sudo` that stalls when driven without a terminal; and the baked runner's own `-V`, the baseline, was only read after the deploy that replaces it. |
| T2 | 2026-07-30 | Both goldens | Pass, after correction | All fourteen scenarios (L1-L3, S1-S11) driven on each golden from the runbook text. Five statements were wrong and were corrected against what was observed: local payloads need `--local generate` (plain `generate` writes the system identity and local install refuses it); the shared IOC directory is `2775`, not `2770`; L2 refuses both verbs at configuration resolution, not `attach` at socket resolution; L3's peer cannot `stat` the log at all, the `0700` home blocking it first; `inspect` puts its root gate ahead of the configuration gate. Four items the document lacked were added: a negative needs a target the actor does not own, `generate` prompts on an existing configuration, the terminal wrapper leaves stray NUL bytes on one golden, and a remotely held console must be detached or the driving connection never returns. The corrected text has not been re-driven; that is Release Verification 3. |
| T4 | 2026-07-30 | Both goldens | Pass, after correction | Executed on both goldens against the working tree at 6c64624 with seven uncommitted paths, deployed identity `1.2.2 (6c64624-dirty)`. Fixture check, manifest permissions and hash, and the test-mode environment carry all behaved as written. Four suites in both modes: all green on each golden, no failure. Tree push with `.git` and `setup --full`: succeeded on both. root_squash: the denial precheck held on each (root denied, owner allowed, the `0750` ancestor the barrier) and all three documented entry points stamped `6c64624-dirty` with no layout warning. Corrections the run forced into the runbook: the golden acceptance is only meaningful before the gate deploys, since the validator compares the installed hash against the manifest commit and reported `installed ioc-runner identity mismatch` on both hosts purely because an earlier deploy had replaced the baked runner; a suite's whole summary block must be kept, because a fixed tail drops the counts the evidence table asks for; a background launch is confirmed by its output, not by a process search that matches the searching shell itself. The whole runbook was then executed again at Gate grade: both goldens rebaked from scratch, the previous consumers destroyed first because the bake refuses to publish while a disk backs onto the target image, fresh consumers created, and the acceptance run before any deploy — where the same validator that had failed on the drifted VMs reported the provenance valid on both, with each remote manifest hash equal to its sidecar. Baked baseline `1.2.2 (85b6d90)` on each, manifest still `clean-untagged tag=-`. Suites on the fresh pair, all executed, zero failures and zero script errors: rocky8 206/206, 94/94 source, 94/94 installed, 45/45, 77/77; debian13 206/206, 82/82 source, 82/82 installed, 46/46, 77/77. root_squash: denial precheck held on both and all three entry points stamped `6c64624-dirty` with no layout warning. Multi-user: all fourteen scenarios on each golden, including both S11 branches — the older sudo let the malformed name through to systemd, the newer one denied it at the gate. |
| T5 | 2026-07-30 | Both goldens | Pass, after correction | Goldens rebaked a third time, consumers rebuilt, and the procedure driven from the document text alone. Four insufficiencies stopped or misled the run and were corrected, each confirmed by executing the document's own form: the suite commands never sourced the EPICS environment, so on the golden whose profile does not set it a lifecycle suite exits before its first step with `ERROR: The EPICS_BASE environment variable is not set.` — reproduced, then fixed by giving a command that derives the per-OS path from the host and by sourcing it in every suite invocation; `IMAGE_DIR` was read as a make variable and used as a shell one, so the sidecar comparison expanded to a bare filename and failed — reproduced, then fixed by setting it; the root_squash step named neither the mount, nor how the tree reaches it, nor how to resolve its absolute root, all of which the author had been supplying from memory; and the guard shown in prose used `$EPICS_BASE` where the document's own trap list forbids it, which dies under `set -u` before sourcing anything. A fifth was learned from a red: the acceptance failed on one consumer with `retained repository mismatch` because the tree under test had already been pushed over the checkout the bake retained, and a remote address in `git@` form where the manifest holds `https://` is enough on its own — the acceptance must precede the push, not only the deploy, and a pushed consumer can only be rebuilt. It was rebuilt, and the acceptance then passed on both. One defect was the author's own new verdict command: an empty log scored as a pass, since zero failures in no input is still zero. It now refuses to score a log with no summary block. After the corrections the run completed from the document alone through the suites and the root_squash path: acceptance valid on both with a dirty count of 0 and matching sidecar hashes, `FIXTURES OK` on both, suites `SUITES OK (5 blocks)` on both — rocky8 206/206, 94/94 source, 94/94 installed, 45/45, 77/77; debian13 206/206, 82/82, 82/82, 46/46, 77/77 — and `SQUASH REPRODUCED` with all three entry points stamping `6c64624-dirty` at zero warnings. The corrected document was then executed once more end to end, bake through multi-user, at the tree carrying the landed runbook (deployed `1.2.2 (4189fd4-dirty)`): the bake itself failed three ways first — a slow mirror exhausted the cloud-init budget while the VM was healthy, a backgrounded launch was refused by the configuration step's blocking-IO check, and the publish `mv` sat 43 minutes on an overwrite prompt because the previous goldens' ownership had been taken by the hypervisor when consumers were created from them and never returned on their forced removal, which is documented libvirt behavior — all three filed upstream (cloud-provision #24 with the verified pseudo-terminal form and the ownership evidence, a measurement comment on #19), the owner restored ownership, and the rebake published cleanly. On the fresh pair: acceptance before anything touched the goldens, `FIXTURES OK`, `SUITES OK (5 blocks)` both — same counts as above — `SQUASH REPRODUCED` with three entry points at zero warnings, and all fourteen multi-user scenarios in the document's prescribed order on each golden, including the S11 branch determination reading glob on one and anchored on the other with the two opposite denials observed as written. |
| T3 | 2026-07-30 | Working tree | Pass | `docs/testplan.md` and `docs/testplan_multiuser.md` removed. Live references repointed: `docs/FAQ.md` to the runbook's S6 and S10, `docs/README.md` index extended with the runbook. The `CHANGELOG.md` mentions are historical and stay. |

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
- Observed during the M1 command run, 2026-07-30: both goldens record
  `app_ioc_runner ... state=clean-untagged tag=-` in
  `/etc/iocrunner-bake.manifest`, so the baked baseline is the default branch
  tip at bake time and nothing in the record names a chosen version. This is
  the condition #130 describes, read directly rather than inferred.
- Same run: the bake's provenance validator compares the installed runner's
  short hash against that manifest commit, so it can only be trusted before the
  gate deploys anything. The ordering rule lands in the runbook under M1; the
  baseline declaration this milestone owns is what makes the record readable
  afterwards.
- Owner decision, 2026-07-31, on the supplying half (ansible-provision M.13,
  its #9): the hybrid form — the `group_vars` default stays `""`, and the bake
  gains a `-r <ref>` flag that overrides only the `site.yml` run via
  `-e ioc_runner_version=<ref>`, the value validated against
  `^[A-Za-z0-9._/-]+$`. First use of extra-vars in cloud-provision, confined to
  that single call. In progress on the ansible side. Consequence for this
  milestone once it lands: a gate can request a released tag, the manifest
  records requested beside resolved, and the acceptance step can then require
  `state=clean-tagged` for a pinned bake instead of recording
  `clean-untagged tag=-` as a fact about the golden.

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
| M1 / T2 | The runbook's multi-user text changed after the drive that corrected it | `docs/RELEASE_CYCLE_RUNBOOK.md` | M1 / T4 | Every scenario drives green from the corrected text, on freshly baked goldens | done, 2026-07-30 |
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
