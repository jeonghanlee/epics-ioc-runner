# Work Register

Release line: 1.2.3
Canonical path: `docs/milestone.md`
Canonical branch or ref: `release-1.2.3`
Git upstream: none
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `1.2.3`

Next session entry point: M6 first, then one golden-VM run closes both M6
and M7 — the owner approved this order 2026-08-03. Work M6's four steps and
its cheap T1 and T2, which need only recorded logs and the working tree, no
VM. Then a single golden-VM run drives M7's T1 (debian13, both modes) and T2
(rocky8) under the new skip-aware verdict, doubling as that verdict's live
confirmation, and the two milestones close together. M7 stays In progress
meanwhile: its step 2 is fully committed (`9f8d01c`, `9f6a3e9`) and the dev
host top passed 96 of 96 with all fourteen M19 assertions running (evidence
in the M7 detail). Both milestones are reviewed with the owner directly, no
agent panel; re-verify each detail's findings against the code before acting
on them. M8 (suite skip-reporting policy) opened 2026-08-03 behind M6 and
gates the release — it is in M3's dependency row. M5
steps 1 through 7 are done — the
drivers are landed under `gate/`, they reached fourteen of fourteen on debian13
and then on rocky8 at its first run with no edit, D8 is final, and the twelve
text findings are applied. What remains of M5 is expensive rather than uncertain:
step 8 restores the goldens' ownership, rebakes both, and creates fresh
consumers, and step 9 is the only run whose scenario verdicts carry Gate grade. M6 and M7 opened 2026-08-02
from a conceptual-integrity sweep and both gate the release: M6 makes a skip
visible to the verdict, M7 removes the one skip that should not be happening.
Until M6 lands, what the suites did and did not verify cannot be enumerated, so
they come before M5's step 9 rather than after it.

The recovered set that step 1
started from is kept at `work/gate-drivers-debian13-20260801/` as the record of
what was driven before the rewrite; it is ignored and untracked, and is no
longer load-bearing now that the drivers are tracked under `gate/drivers/`.

M2 (#130) is the other work item before the release: it declares which
`ioc-runner` baseline a golden carries. Its supplying half is done and spans
both suppliers — `cloud-provision` `8ad180a` gives the bake its `-r <ref>` flag
and `ansible-provision` writes the `requested=` field — so nothing blocks M2;
what it declares is settled after step 8 uses the flag for the first time. M4 is complete at `cc9b02e`
with T1 through T6 recorded; its issue #133 stays open until the release, per
the manual-close practice on a long-lived release branch. The guard question is
settled as Keep (D6, `CLOSED_DOORS.md` CI-31). M1 is complete and #131 is
closed.

## Work

| ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | (#131) Re-set the verification scenarios and write the standing release-cycle runbook | Milestone | Complete | — | | Runbook standing with drive commands and verdicts, both plan files retired, references repointed in both repositories, and a fresh operator completed the full procedure from the document alone (T6); [detail](#m1---release-cycle-runbook-and-scenario-re-set) |
| M2 | (#130) Declare the `ioc-runner` baseline the goldens carry, in the gate procedure and in the gate record | Milestone | Not started | Yes | M1 | The runbook names how the baseline is chosen and a gate record carries it beside the suite counts; [detail](#m2---golden-baseline-declaration) |
| M4 | (#133) Version stamp reports `-dirty` for a relocated clean checkout whose index is stale; not reachable on the production deployment path | Milestone | Complete | Yes | D5 | All three stamp sites — the system setup script, the live `-V` fallback, and the `install.user` injector — report a bare hash for a relocated clean checkout, a genuinely modified one still carries the suffix, and a regression test pins both from a fixture no git command has touched; [detail](#m4---stale-index-dirty-stamp) |
| M5 | (#134) Ship the gate's scenario drivers as repository assets, and reduce the runbook's scenario section to invocations and verdicts | Milestone | In progress | No | M1, D7, D8 | The drivers live in the repository and fix the scenario identities, the runbook cites them rather than describing them, and an independent operator drives all fourteen scenarios on both goldens from the runbook and the shipped drivers alone; [detail](#m5---shipped-scenario-drivers) |
| M6 | (#135) The suite verdict cannot see a skip, so a run that dropped checks scores as a full green | Milestone | In progress | No | M1 | The verdict refuses a plain `SUITES OK` when the log carries a skip, and a run with a known skip is distinguishable from one without; [detail](#m6---the-suite-verdict-cannot-see-a-skip) |
| M7 | (#136) The suites probe for a tool by PATH where the runner resolves it absolutely, so checks skip for a tool the product can use | Milestone | In progress | No | M1 | The probe answers what the runner answers, and the four M19 steps run on the golden where they are skipped today; [detail](#m7---the-suite-tool-probe-disagrees-with-the-runner) |
| M8 | (#137) Re-examine the suites' skip-reporting policy so a skip is countable from the summary, not the body | Milestone | Not started | No | M6 | Every suite's summary block carries a skip count, every skip emission follows one written policy form per class, and the verdict reads the count instead of grepping prose; [detail](#m8---suite-skip-reporting-policy) |
| M3 | Final release 1.2.3 | Milestone | Not started | No | M1, M2, M4, M5, M6, M7, M8 | Tag `1.2.3`, GitHub release, milestone closed, and every Release Verification row Pass; [detail](#m3---final-release) |

## Decisions

| ID | Decision | Source |
| --- | --- | --- |
| D1 | 1.2.3 is a verification cycle: documents and test scenarios are its ordinary work, and code is not changed in passing. **Amended 2026-08-02:** the line takes a code change where one is genuinely needed to complete the cycle. The authority is the owner's, and the route is formal — the work gets its own row in this register and its own issue before it is written, never an inline repair made while something else was being fixed. What the amendment removes is the standing bar, not the discipline: the bar was there so scope could not widen quietly, and a row plus an issue is what keeps that true while letting the cycle finish. D5 and D7 remain as the record of the two exceptions named under the earlier form; work from here takes the formal route instead of a new named exception. | Owner decision, 2026-07-30, amended by owner decision 2026-08-02 |
| D2 | The register adopts the current `milestone-tracking` schema at this cycle open, and unassigned work moves to `docs/backlog.md`. | Owner decision, 2026-07-30 |
| D3 | `docs/testplan.md` is retired as an active file; the per-cycle plan lives in the final release detail of this register, and released cycles keep their plan through their tag. | Owner decision, 2026-07-30, following the current `release-cycle` contract |
| D4 | `docs/MILESTONE_PROCEDURE.md` stays in place and unchanged through this cycle; the runbook references it rather than absorbing it, and its fate is recorded as backlog M11. | Owner decision, 2026-07-30 |
| D5 | M4 (#133) is a named exception to D1, which otherwise stands: this cycle takes one product code change. The first rationale — that the stamp falsifies a gate record — was withdrawn the same day, once the reachability check showed the production deployment path cannot reach the condition (M4, Dependencies And Decisions), and the issue was regraded to `enhancement` / `P3-low`. The exception is kept on the narrower ground that survives: the work is done, the change is three lines with its regression coverage, and the condition it removes is one this project's own gate creates every run by pushing the tree under test with `tar`. The exception covers that change and its test; it does not reopen the line to other code work. | Owner decision, 2026-07-31, rationale narrowed the same day after the reachability finding |
| D7 | M5 is a named exception to D1 on the same footing as D5: the scenario drivers ship as repository assets under a top-level `gate/` directory, which also takes the runbook, and D1 otherwise stands. The ground is that D1 admits test scenarios, and the drivers are the executable half of the scenarios this cycle was opened to re-set — M1 carried the describing half and named the executable half out of scope, so the cycle's own purpose is unmet while it stays out. The exception covers the drivers, the runbook edits they force, and their verification; it does not reopen the line to work under `bin/`. Its cost is stated rather than discovered: the drivers are only accepted by a two-host gate run, which is the same run the release needs, so the release moves out by that run. | Owner decision, 2026-08-01 |
| D8 | The gate drivers take the shape the 2026-08-01 debian13 set already holds, read off all seventeen files rather than designed fresh, because that set is the only one that drove all fourteen scenarios to their stated results. Adopted as they stand: positional arguments, with `$1` always the EPICS environment path and `$2` always the IOC name and later positions carrying only that scenario's own values; the one sourcing line `set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u`, identical in every file; a header comment naming the scenarios covered and, past two arguments, the argument list; no `set -e`, because almost every command's nonzero exit is the observation itself; a console-opening command wrapped as `timeout -k 2 <N> script -qec "<cmd>" /dev/null </dev/null`, and a held console fed by a fifo from a detached `setsid`; absolute paths throughout. Seven places where the seventeen disagree are settled toward the majority, which is also the cheaper move: one verdict form rather than three; `cleanup.bash` and the S3 block brought inside the convention, the second becoming a file for the first time; the execution side (control host against VM) marked by the layout, since `sys-`/`local-` marks the mode and not the side; per-run scratch paths, since `/tmp/s4.out` is a fixed name two runs collide on; the scenario identities collected into one file rather than supplied by the caller, that being the exact place the per-run reinvention enters; the principal switch made by the caller and never inside a driver, as only `sys-s11.bash` does today; and `ssh -n` with batch options as a rule on every call rather than in the S3 block alone. This shape is provisional through step 6 and not before. It is read off one successful set on one host, so two runs are expected to move it: step 2 drives the recovered set unchanged and shows what the shape cannot carry, and step 6 is the only place the two hosts' divergences appear at all — at least the S11 sudo branch and the wrapper's closing message. Each revision amends this row with its date and what moved it; the shape is final when step 6 passes, and step 9 verifies rather than settles it. **Final as of 2026-08-02, when step 6 drove rocky8.** The set reached fourteen of fourteen there on its first run with no driver edited, so the shape carried a host it had never seen. Four of the five divergences the amendment predicted moved as predicted and needed no repair: `control/s11.bash` read `sudo 1.9.5p2` with six glob lines, took the glob branch, and asserted the result opposite to debian13's — the escaping complaint and the failed job assertion in the command's own output, with its own detail stating that the exit code is not the evidence; the environment path resolved to the rocky OS tree from `/etc/os-release`; this golden's wrapper closes with a trailing newline so nothing glues, which cost nothing because every verdict read is unanchored by construction rather than by branch; and the killed console recorded 124 here against 137 on the other, both ignored in favour of the connection banner. The fifth is recorded as **confirmed absent, not confirmed carried**: no login shell spoke ahead of any capture on rocky8, so the `tail -1` and match-not-equality defences ran without ever being loaded, and the claim that the set handles a speaking login shell still rests on the debian13 run alone. One repair the run forced, and the only place in the seventeen files where a host-specific value appeared at all: `host/sys-s4-server.bash` described a timed-out client in prose as recording one exit code and one closing message, both of them this host's; it now names both hosts' forms and asserts neither. **Amended 2026-08-01 by the step 2 and step 3 runs**, which moved six of the settlements above. One of them was measured false: `ssh -n` is not a rule for every call, because `-n` redirects stdin from `/dev/null` and the call that reads the archive off the pipe then feeds an empty stream to `tar`, which reports `This does not look like a tar archive` — so the rule splits, `-n` on a call that only issues a command and never on one that reads a stream. "One verdict form rather than three" understated the problem and is replaced: step 2 showed no driver prints a scenario verdict at all, only per-command exit lines, so every one of the fourteen verdicts was a human reading a transcript — three of them load-bearing, since L1's verdict is a comparison across two invocations no driver makes, S3's needs a printed word read against an inverted exit code, and S10's needs a nonzero code ignored and a banner found. Each driver therefore computes and prints its own scenario verdict. The principal becomes an argument the driver checks before acting rather than a value it reports afterwards, because three drivers run under more than one principal and a wrong one yields a plausible transcript. The parts of the run that have no driver at all get one: S9's root half, from which two of that scenario's four verdicts come, the local-user runtime directory forcing, and the survival check between S6 and S10. The capture form and the run order move into the set, both being outside it today. `set -e` stays off for scenario drivers and is on for the push driver, where a failed push is a failure rather than an observation. | Owner decision, 2026-08-01, on the shape read off the recovered set; amended the same day by the step 2 and step 3 runs; final 2026-08-02 on the step 6 rocky8 run |
| D6 | The three sites M4 aligns do NOT gain a contract guard: examined through the Ledger promotion test (#100 / M17, `git show 3e47ee6:docs/milestone.md`) and left at Keep, recorded as `CLOSED_DOORS.md` CI-31. Elimination stays blocked (three self-contained scripts, the CI-4/CI-15 premise) and gates A and B pass, but Gate C fails on a netting the first pass of this decision missed: M4's own regression asset drives all three entry points from a relocated clean fixture and a modified one on both goldens, so a one-sided return to a stat-trusting comparison turns it red with no guard in place. The residual — a one-sided move to a comparison those fixtures cannot tell apart, such as one that counts untracked files — is priced too narrow to fund a fifth guard against a base rate of four promotions in eighteen examined findings. The full gate walk, the measured drift history, and the declined fold live in CI-31. | Owner decision, 2026-07-31, superseding the same-day promotion decision after the Gate C netting |

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
Status: Complete

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
| T6 | Fresh-operator execution | Hand the runbook, and nothing else, to an independent agent with no access to this conversation's answers; it executes the full procedure and reports every place the document did not carry it | Both goldens | The independent operator completes the full procedure at Gate grade from the document alone, and each reported gap is corrected |
| T2 | Scenario drive | Drive every multi-user scenario straight from the runbook, on both goldens, without consulting any other document | Both goldens | Each expected result is assertable as written, or the document is corrected to what was observed |
| T3 | Retirement check | Confirm both retired plan files are absent and that no live document references them | Working tree | The files are gone and every remaining reference points at the runbook or the register |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-07-30 | Working tree | Pass, after correction | Two independent read-only reviews followed the author's own pass, one asking whether a first-time operator could execute the document alone and one comparing it against every document it depends on. Between them they returned thirty-two findings; each was checked against the code or the live goldens before acting, and the confirmed ones are listed under T5. Three were factual errors the author had carried in: there is no crash-scan verb, so the scenario that named one could not be executed as written; `/opt/epics-iocs` is created by the bake, not by the setup script the document implied; and the provenance validator accepts a dirty application record although the bake runbook forbids one at final acceptance, so the acceptance step needed its own check. One finding did not reproduce here and was recorded rather than applied: the stale-host-key case, where this control host's client accepts a new key without prompting. Author's own pass, run first: read against `RUNBOOK_BAKE.md` and `tests/README.md`, six defects found and fixed. Ordering: the consumer VMs must be destroyed before the bake, not after it — the bake refuses to publish while a disk backs onto the target image, which is what a running consumer does; the document had the destroy step in the wrong section, and the run hit exactly that. Execution mode: the multi-user step named none, and it is always the deployed binary. Precision: the system infrastructure suite has no binary axis, so claiming the mode matters there was wrong. Checkability: `IMAGE_DIR` was used with nothing saying where it comes from; the acceptance block used a plain `sudo` that stalls when driven without a terminal; and the baked runner's own `-V`, the baseline, was only read after the deploy that replaces it. |
| T2 | 2026-07-30 | Both goldens | Pass, after correction | All fourteen scenarios (L1-L3, S1-S11) driven on each golden from the runbook text. Five statements were wrong and were corrected against what was observed: local payloads need `--local generate` (plain `generate` writes the system identity and local install refuses it); the shared IOC directory is `2775`, not `2770`; L2 refuses both verbs at configuration resolution, not `attach` at socket resolution; L3's peer cannot `stat` the log at all, the `0700` home blocking it first; `inspect` puts its root gate ahead of the configuration gate. Four items the document lacked were added: a negative needs a target the actor does not own, `generate` prompts on an existing configuration, the terminal wrapper leaves stray NUL bytes on one golden, and a remotely held console must be detached or the driving connection never returns. The corrected text has not been re-driven; that is Release Verification 3. |
| T4 | 2026-07-30 | Both goldens | Pass, after correction | Executed on both goldens against the working tree at 6c64624 with seven uncommitted paths, deployed identity `1.2.2 (6c64624-dirty)`. Fixture check, manifest permissions and hash, and the test-mode environment carry all behaved as written. Four suites in both modes: all green on each golden, no failure. Tree push with `.git` and `setup --full`: succeeded on both. root_squash: the denial precheck held on each (root denied, owner allowed, the `0750` ancestor the barrier) and all three documented entry points stamped `6c64624-dirty` with no layout warning. Corrections the run forced into the runbook: the golden acceptance is only meaningful before the gate deploys, since the validator compares the installed hash against the manifest commit and reported `installed ioc-runner identity mismatch` on both hosts purely because an earlier deploy had replaced the baked runner; a suite's whole summary block must be kept, because a fixed tail drops the counts the evidence table asks for; a background launch is confirmed by its output, not by a process search that matches the searching shell itself. The whole runbook was then executed again at Gate grade: both goldens rebaked from scratch, the previous consumers destroyed first because the bake refuses to publish while a disk backs onto the target image, fresh consumers created, and the acceptance run before any deploy — where the same validator that had failed on the drifted VMs reported the provenance valid on both, with each remote manifest hash equal to its sidecar. Baked baseline `1.2.2 (85b6d90)` on each, manifest still `clean-untagged tag=-`. Suites on the fresh pair, all executed, zero failures and zero script errors: rocky8 206/206, 94/94 source, 94/94 installed, 45/45, 77/77; debian13 206/206, 82/82 source, 82/82 installed, 46/46, 77/77. root_squash: denial precheck held on both and all three entry points stamped `6c64624-dirty` with no layout warning. Multi-user: all fourteen scenarios on each golden, including both S11 branches — the older sudo let the malformed name through to systemd, the newer one denied it at the gate. |
| T5 | 2026-07-30 | Both goldens | Pass, after correction | Goldens rebaked a third time, consumers rebuilt, and the procedure driven from the document text alone. Four insufficiencies stopped or misled the run and were corrected, each confirmed by executing the document's own form: the suite commands never sourced the EPICS environment, so on the golden whose profile does not set it a lifecycle suite exits before its first step with `ERROR: The EPICS_BASE environment variable is not set.` — reproduced, then fixed by giving a command that derives the per-OS path from the host and by sourcing it in every suite invocation; `IMAGE_DIR` was read as a make variable and used as a shell one, so the sidecar comparison expanded to a bare filename and failed — reproduced, then fixed by setting it; the root_squash step named neither the mount, nor how the tree reaches it, nor how to resolve its absolute root, all of which the author had been supplying from memory; and the guard shown in prose used `$EPICS_BASE` where the document's own trap list forbids it, which dies under `set -u` before sourcing anything. A fifth was learned from a red: the acceptance failed on one consumer with `retained repository mismatch` because the tree under test had already been pushed over the checkout the bake retained, and a remote address in `git@` form where the manifest holds `https://` is enough on its own — the acceptance must precede the push, not only the deploy, and a pushed consumer can only be rebuilt. It was rebuilt, and the acceptance then passed on both. One defect was the author's own new verdict command: an empty log scored as a pass, since zero failures in no input is still zero. It now refuses to score a log with no summary block. After the corrections the run completed from the document alone through the suites and the root_squash path: acceptance valid on both with a dirty count of 0 and matching sidecar hashes, `FIXTURES OK` on both, suites `SUITES OK (5 blocks)` on both — rocky8 206/206, 94/94 source, 94/94 installed, 45/45, 77/77; debian13 206/206, 82/82, 82/82, 46/46, 77/77 — and `SQUASH REPRODUCED` with all three entry points stamping `6c64624-dirty` at zero warnings. The corrected document was then executed once more end to end, bake through multi-user, at the tree carrying the landed runbook (deployed `1.2.2 (4189fd4-dirty)`): the bake itself failed three ways first — a slow mirror exhausted the cloud-init budget while the VM was healthy, a backgrounded launch was refused by the configuration step's blocking-IO check, and the publish `mv` sat 43 minutes on an overwrite prompt because the previous goldens' ownership had been taken by the hypervisor when consumers were created from them and never returned on their forced removal, which is documented libvirt behavior — all three filed upstream (cloud-provision #24 with the verified pseudo-terminal form and the ownership evidence, a measurement comment on #19), the owner restored ownership, and the rebake published cleanly. On the fresh pair: acceptance before anything touched the goldens, `FIXTURES OK`, `SUITES OK (5 blocks)` both — same counts as above — `SQUASH REPRODUCED` with three entry points at zero warnings, and all fourteen multi-user scenarios in the document's prescribed order on each golden, including the S11 branch determination reading glob on one and anchored on the other with the two opposite denials observed as written. |
| T6 | 2026-07-31 | Both goldens | Pass, after correction | An independent agent, given only the runbook and barred from this session's answers and from `sudo` on the control host, executed the full procedure at Gate grade: consumers destroyed, ownership precheck passed (the owner had restored it; the bake's publish had also just gained a forced overwrite upstream), bake 12 minutes to both `Bake complete` lines with the in-bake validator valid twice, fresh consumers `READY`, acceptance before anything touched the goldens (`root:root 644`, remote hashes equal to sidecars, validator valid, dirty count 0, baseline `85b6d90` `clean-untagged tag=-`), `FIXTURES OK` twice, deploy to `1.2.2 (2de7275-dirty)`, `SUITES OK (5 blocks)` twice — rocky8 206/206, 94/94, 94/94, 45/45, 77/77; debian13 206/206, 82/82, 82/82, 46/46, 77/77, with the mode read back from the suites' own resolved-binary line — `SQUASH REPRODUCED` twice, three entry points with zero layout warnings, and all fourteen multi-user scenarios PASS on each golden, the S11 branches opposite as written. Zero product defects; every red resolved at step one of the document's own triage as a harness defect. The agent reported eight gaps, all corrected in the runbook: the sibling-checkout locations were nowhere resolved; S4's feeder subshell held the driving connection open and a stale result file could satisfy the attachment check for a client that never launched (feeder now detached, the check now matches the IOC-named banner); S9's root half could not reproduce both shapes from the single command given (the conforming shape is now restored first); S7's intermediate observation belonged to the second operator but the block ran one principal; S8's block inherited its directory from an earlier scenario; `grep -c` exits nonzero on the wanted zero; skips never appear in the summary block and need their own read; and the consumer targets' `READY` marker plus S10's wrapper-owned exit codes were unstated. |
| T3 | 2026-07-30 | Working tree | Pass | `docs/testplan.md` and `docs/testplan_multiuser.md` removed. Live references repointed: `docs/FAQ.md` to the runbook's S6 and S10, `docs/README.md` index extended with the runbook. The `CHANGELOG.md` mentions are historical and stay. |

#### Closure Evidence

- Deliverables: `docs/RELEASE_CYCLE_RUNBOOK.md` landed in `4189fd4`, driver
  forms and the run record in `2de7275`, the fixture-handoff repoint in
  `ansible-provision` `a1f413a`, the draft-fate backlog item in `ac7cd11`;
  the T6 gap corrections follow in the closing commit.
- Verification: T1 through T6 all Pass, each after correction where the run
  found the document wrong — recorded per row above.
- Independent acceptance: T6, 2026-07-31 — a fresh operator completed the
  procedure at Gate grade from the document alone, zero product defects.
- **Corrected 2026-08-02. What M1 delivered is the first draft of the standing
  procedure, not the settled one, and T6's verdict did not survive the next
  day.** Two further blind executions on 2026-08-01, each given the runbook
  alone, both answered that a first-time operator could not run it without
  supplying what the document did not carry, and returned nineteen findings
  against it. The document has since lost its scenario fragments to
  `gate/drivers/`, gained twelve text corrections, and moved from 1357 lines to
  1146. The deliverable itself stands and is in use — the completion criteria
  are met and the row remains Complete — but the claim that an independent
  operator could execute it unaided was overstated by one run. M5 replaces the
  half that could not be executed from prose, and M6 and M7 repair what the
  gate's own verdict could not see. Recorded here rather than by reopening
  #131, because the work M1 owned was done; the verdict on it was not final.

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
  that single call. **Landed, verified 2026-08-02.** It is not on the ansible
  side alone: `cloud-provision` `8ad180a` carries the operator-facing `-r <ref>`
  and passes it on as `ioc_runner_version`, doing nothing else with it, and its
  validator only shape-checks the field; `ansible-provision` writes
  `requested=<ref>` onto the record, in
  `roles/bake_provenance/files/record-iocrunner-source.bash`. No golden carries
  the field yet — the flag landed after the current pair was baked, and their
  records are the six-field form. Consequence for this
  milestone now that it has landed: a gate can request a released tag, the
  manifest records requested beside resolved, and the acceptance step can then require
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

### M4 - Stale index dirty stamp

Origin: found 2026-07-31 by the fifth document-only execution of the release
cycle runbook, at `release-1.2.3` `7511ed7`; filed as #133
Identity History: none
GitHub Issue: 133, https://github.com/jeonghanlee/epics-ioc-runner/issues/133
Status: Complete

#### Summary

Three sites decide the `-dirty` suffix with `git diff-index --quiet HEAD --`
and none of them refreshes the index first. That comparison trusts the index's
cached stat data, and the cached data records the device and inode a file had
where the index was written, not only its timestamps. Any relocation of the
tree changes those — `tar` extraction, `cp -a`, `rsync -a`, a restored snapshot
— so every entry reads stat-dirty and the comparison reports a difference the
content does not have.

New timestamps are not the trigger, and stating it that way sends a reader who
checks timestamps away with a false diagnosis: `tar` and `cp -a` both restore
mtime. Measured 2026-07-31, `bin/ioc-runner` in the source tree against the
same file in a tar-extracted copy — mtime `1785439776` in both, inode
`162192879` against `742574`. The same pair on the rocky8 golden: mtime
`1785439776` in both, inode `25241295` against `18677075`.

A clean tree therefore stamps `-dirty`. The suffix is the signal that says the
deployed binary came from a modified tree; where this fires, it reports the
opposite of the truth.

It does not fire on the production path, which is why this is a robustness fix
and not a defect report — see the reachability finding under Dependencies And
Decisions. It fired here because this project's own release gate pushes the
tree under test with `tar`, so that uncommitted code can be exercised on a
golden. That is a verification convenience, not a deployment method, and the
condition it creates is the one the fix removes.

#### Scope

All three sites that make the decision, because the completion criterion is a
property of the stamp and not of one entry point:

- `bin/setup-system-infra.bash:681`, the system install path — `make install`,
  `make setup`, and the direct script run;
- `bin/ioc-runner:280`, the live `-V` fallback taken when a source checkout is
  run before anything has stamped it;
- `configure/inject-runner-version.bash:17`, the `make install.user` injector
  (`configure/RULES_INSTALL:38`).

And a regression test that drives the real path at each of the three on a
relocated clean checkout.

Out of scope: the `unknown` stamp and its manual-repair guidance (#119, #128),
which are unaffected; every other product change on this line, which D5 does
not open.

#### Completion Criteria

- At each of the three entry points, a clean checkout relocated by extraction
  or copy, with no git invocation touching it first, reports a bare short hash
  with no suffix.
- At each of the three, a checkout carrying a real uncommitted change still
  reports `-dirty`.
- A clean relocated checkout whose index cannot be written reports bare, not
  `-dirty`.
- The system-install case holds on a local-disk checkout and on the
  `root_squash` mount.
- The regression test goes red on the unfixed scripts, from a fixture built
  under the T4 constraint.

#### Dependencies And Decisions

- D5 names this milestone as the exception that lets it exist on this line.
- Observed while executing the runbook, and reproduced independently before
  filing: on the same checkout, `git status --porcelain` reported nothing
  uncommitted while `git diff-index --quiet HEAD --` exited nonzero and the
  deploy stamped the suffix; after a single `git status`, the same comparison
  exited zero and the same deploy stamped bare. Reproduced on both goldens, on
  a local-disk checkout and on the squashed mount.
- The gate's ordinary path masks the defect: it verifies the pushed tree with
  `git status --porcelain` before deploying, and that read refreshes the index.
  The `root_squash` step has no such read, which is where it surfaced.
- All three sites, not only the filed one. #133 names the setup script because
  that is where the runbook run hit it, but the same expression appears
  verbatim at the other two, and each was reproduced directly on a pristine
  tar-extracted copy of this repository at `7c73c60` on 2026-07-31:
  `bash <copy>/bin/ioc-runner -V` reported `1.2.2 (7c73c60-dirty (live))`, and
  `configure/inject-runner-version.bash` stamped
  `RUNNER_GIT_HASH="7c73c60-dirty"`. Fixing one leaves `make install.user` and
  source-mode `-V` failing the criterion above. The repository already carries
  a guard whose whole purpose is to stop these injectors from drifting apart —
  `test_metadata_contract_guard` in `tests/test-error-handling.bash:1504`,
  landed under #84 as CI-9 and cited from `docs/CLOSED_DOORS.md` CI-29 — so
  leaving two of the three on the defective form is a drift this line has
  already decided it does not want. Nothing is deliberately left.
- Chosen form: replace the comparison itself with the porcelain diff,
  `git diff --quiet HEAD --`. It performs the content comparison in core rather
  than trusting the cached stat data, so it needs no index write, it is one
  call rather than two, and it needs no tolerant `|| true`. Verified on
  pristine extracted checkouts with no prior git read, 2026-07-31, on this
  control host and through the delegated principal on the rocky8 golden:
  `diff-index --quiet HEAD --` exits 1 where `diff --quiet HEAD --` exits 0;
  with one tracked file genuinely modified both exit 1; with a change staged
  but the worktree matching the index both exit 1; with a tracked file deleted
  the porcelain diff exits 1. An untracked file present does not make it exit
  nonzero.
- Rejected, the refresh form the first plan proposed
  (`update-index -q --refresh` before the comparison). It must write the index
  to have any effect, and where it cannot it fails silently: measured on a
  clean extracted checkout whose `.git` and `.git/index` were made unwritable,
  `update-index -q --refresh` exited 128 with zero bytes on stderr and the
  following `diff-index` still exited 1. The tolerant `|| true` the form needs
  then swallows the one case that should be visible, and the wrong suffix is
  stamped with no warning. On the same tree `git diff --quiet HEAD --` exited
  0, which is the correct answer.
- Rejected, `git status --porcelain` emptiness — but not for the reason the
  first plan gave. Cost is not the objection: the refresh form adds a whole
  extra invocation, and in the setup script that invocation is delegated, which
  is the expensive part. Measured on the rocky8 golden, 2026-07-31: a
  `sudo -n -u <invoker>` spawn costs 8-10 ms, while `status --porcelain` on a
  warm tree costs 2-4 ms; on this control host over five fresh extractions each,
  refresh-plus-`diff-index` averaged 4 ms, `diff --quiet` 6 ms, and
  `status --porcelain` 3 ms. The real objection is semantic: `status
  --porcelain` reports untracked files, so a clean checkout carrying one stray
  file would stamp `-dirty`. Measured on an extracted clean tree with a single
  untracked file added, `status --porcelain` printed one `??` line while
  `git diff --quiet HEAD --` exited 0.
- `set -e` is on in all three scripts (`bin/setup-system-infra.bash:9`,
  `bin/ioc-runner:11` with `-euo pipefail`, `configure/inject-runner-version.bash:11`),
  so the replacement keeps each site's existing `if ! <git> ... ; then` negation
  rather than introducing a bare call.
- T5 stays a runbook step rather than an automated check, and the split is
  forced by the environment, not chosen. The suites build scratch with
  `mktemp -d` (`tests/test-system-infra.bash:474`,
  `tests/test-system-lifecycle.bash:315`), which resolves to `/dev/shm` or
  `/tmp` — local disk on the goldens, never the exported mount. And a root-run
  invocation naming an absolute path under that mount is denied before it
  starts: measured on the rocky8 golden, the `gitsrc` ancestor of
  `/home/nfs/simulation/vmadmin/gitsrc/epics-ioc-runner` is `drwxr-x---` owned
  by the invoker on a `root_squash` export, and `sudo -n test -r` on a file
  beneath it returns 1 while `sudo -n ls` on the directory reports permission
  denied. The squashed half is therefore driven from the runbook's
  `root_squash` deployment section, by an operator standing in the mount.
- The squashed mount bears on the setup site only. The runbook's three
  documented entry points there — the direct script run, `make install`, and
  `make setup` — all route through `bin/setup-system-infra.bash`, which is the
  one site that runs as root and delegates. The `install.user` injector and the
  live `-V` fallback run as the invoking user, who owns the tree and traverses
  the ancestor, so no squash-specific behavior applies to them and T1 through
  T3 on local disk carry them in full.
- Reachability, confirmed 2026-07-31 against `ansible-provision` and
  `cloud-provision`: the production deployment path cannot reach this, on two
  independent counts. The tree arrives by `git clone`, or by `git fetch` plus
  `git checkout --force --detach` when it already exists
  (`roles/app_ioc_runner/tasks/main.yml`) — both write the index, and no copy,
  `rsync`, or archive extraction appears in that role or in the bake chain.
  And the same role runs `git status --porcelain=v1` to compute the expected
  identity before it invokes `setup-system-infra.bash`, which refreshes the
  index regardless. What remains reachable is a hand-managed deployment from a
  copied checkout that keeps its `.git` and is stamped with no intervening git
  read. A `.git`-less copy stamps `unknown` and belongs to #119 and #128.
  This finding is why the issue was regraded from `bug` / `P2-medium` to
  `enhancement` / `P3-low` on the same day.
- Accepted divergence, observed 2026-07-31: with a modification staged in the
  index and the working tree then reverted to the HEAD content (`git status`
  shows `MM`), the old comparison answers dirty and the replacement answers
  clean. The replacement's answer is adopted deliberately: the stamp describes
  what ships, what ships is the working tree, and a working tree whose content
  equals the commit is what a bare hash claims. Recorded so the next sweep
  reads the verdict instead of re-deriving the corner.

#### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner, 2026-07-31, on the plan as it stands after the review
that widened it from one site to three, replaced the index refresh with the
porcelain comparison, and added the issue sync, the comment updates, and the
recorded staged-revert divergence
Implementation Authorization: owner, 2026-07-31, covering the five steps below
and the documentation they carry
Superseded Plan Artifacts: the single-site scope and the
`update-index -q --refresh` form, both rejected by measurement and kept in the
Dependencies And Decisions above rather than deleted

1. Before touching code, sync the #133 body from the prepared correction at
   `work/issue-133-body.md` — the remote issue is the authoritative record and
   still carries the superseded diagnosis and the rejected fix.
2. Replace `diff-index --quiet HEAD --` with `diff --quiet HEAD --` at all
   three sites, keeping each site's existing negation idiom and its
   `2>/dev/null`, and adding no `|| true`. In the same commit, update the two
   comments that name the old command —
   `bin/setup-system-infra.bash:680` and the #42 guard comment at
   `tests/test-system-infra.bash:602` — so no comment points at a command the
   tree no longer contains.
3. Add the regression test, building its fixture under the T4 constraint and
   asserting the stamp at all three entry points, plus the unwritable-index
   case of T3.
4. Confirm it goes red against the unfixed scripts before the change lands, and
   green after.
5. Re-run the affected suites on both goldens, then drive the squashed-mount
   half from the runbook.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Change-specific, automated | Relocate a clean checkout into the scratch tree with `cp -a` or a `tar` extraction and, with no git invocation touching the copy first, drive all three entry points from it — the setup script with its destinations redirected as `test_setup_version_stamp` already does, `configure/inject-runner-version.bash` against an installed copy, and `bash <copy>/bin/ioc-runner -V` — then read the stamped hash from each | Both goldens, local disk | A bare short hash at all three, no suffix |
| T2 | Negative control, automated | The same fixture with one tracked file genuinely modified; drive the same three | Both goldens, local disk | The suffix is present at all three; the fix did not silence a real modification |
| T3 | Unwritable-index control, automated | The same clean fixture with `.git` and `.git/index` made unwritable to the stamping principal; drive the same three | One golden | A bare short hash at all three. This is the case that separates the two candidate fixes: the refresh form leaves the wrong suffix here and reports nothing |
| T4 | Regression-asset non-vacuity | Run the new test against the unfixed scripts, then against the fixed ones. Binding fixture constraint: the tree under test is produced only by copying or extracting an existing checkout, and no git command may touch it before the drive. `git init` + `git add -A` + `git commit` and `git clone` — the two fixture idioms this repository's own suites already use, at `tests/test-system-infra.bash:495` and `tests/test-local-lifecycle.bash:354` — each leave a freshly written index, and the unfixed comparison then returns 0, so the assertion passes on the unfixed script and proves nothing | Working tree | Red before, green after |
| T5 | Standing procedure, runbook step | The runbook's `root_squash` deployment section, driven on a clean tree placed on the `nfs_sim` mount by the `tar` pipeline that section already prescribes and untouched by git afterwards: its three documented entry points — the direct `bin/setup-system-infra.bash` run, `make install`, `make setup` — all route through the setup site, so this check covers that site only. Not automatable in the suites — see Dependencies And Decisions | Both goldens, squashed mount | Each entry point reports a bare short hash with no layout warning |
| T6 | Suites | Re-run the suites the three stamp paths touch | Both goldens | No failures, counts unchanged from the last recorded run |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-07-31 | Both goldens | Pass | `test_stamp_relocated_clean_checkout` drives all three entry points from a clone-then-`cp -a` fixture untouched by git. Bare `cc9b02e` at the setup deploy, the live `-V`, and the injector, on rocky8 and debian13. |
| T2 | 2026-07-31 | Both goldens | Pass | Same fixture with one tracked file appended: `cc9b02e-dirty` at all three, both goldens. The replacement did not silence a real modification. |
| T3 | 2026-07-31 | Both goldens | Pass | Same fixture with `.git` and `.git/index` made unwritable: bare `cc9b02e` at all three, both goldens. This is the state the rejected refresh form could not satisfy. |
| T4 | 2026-07-31 | Both goldens | Pass | Honest red then green on the same test. Against the pre-fix tree (`b4ef8b7`), six of the nine stamp assertions failed — the three clean-fixture reads and the three unwritable-index reads, all reporting `b4ef8b7-dirty` — while the three real-modification reads passed, so the test discriminates rather than failing wholesale. Against the fixed tree, system-infra 55/55 on rocky8 and 56/56 on debian13, 0 failures, 0 script errors. |
| T5 | 2026-07-31 | Both goldens, squashed mount | Pass | Denial precheck `SQUASH REPRODUCED` on both. All three documented entry points — the direct script run, `make install`, `make setup` — stamp bare `cc9b02e` with zero layout warnings, six invocations across the two goldens. Unplanned control from the first attempt: the same six on a tree carrying one real uncommitted file stamped `cc9b02e-dirty`, so the mount path discriminates too. |
| T6 | 2026-07-31 | Both goldens | Pass | error-handling 206/206 executed==counted; local-lifecycle 94/94 source and 94/94 installed on rocky8, 82/82 and 82/82 on debian13; system-lifecycle 77/77 both. 0 failures, 0 script errors throughout. |

#### Closure Evidence

- Fix and regression test: commit `cc9b02e`, four files — the three stamp
  sites, and `tests/test-system-infra.bash` carrying
  `test_stamp_relocated_clean_checkout` plus the two comment corrections.
- Verification: T1 through T6 all Pass, 2026-07-31, recorded above. The
  honest-red evidence is T4: six failures on the pre-fix tree against nine
  stamp assertions, the three real-modification reads passing throughout.
- Regrade: `bug` / `P2-medium` to `enhancement` / `P3-low` the same day, on the
  reachability finding recorded under Dependencies And Decisions; #133's body
  carries the same finding as its own Reachability section.
- Issue #133 stays open until the release, per the manual-close practice for a
  long-lived release branch.

#### GitHub Projection

Title: Version stamp reports -dirty for a clean checkout whose index is stale
Labels: enhancement, P3-low, area/install
GitHub Milestone: 1.2.3
Observed State: open
Observed Labels: enhancement, P3-low, area/install
Observed Milestone: 1.2.3
Last Compared: 2026-07-31, after the regrade and the body sync

### M5 - Shipped scenario drivers

Origin: the two blind runbook executions of 2026-08-01 against `7d82f4f`, one
per golden, each given the runbook alone
Identity History: none
GitHub Issue: 134, https://github.com/jeonghanlee/epics-ioc-runner/issues/134
Status: Not started

#### Summary

The gate's scenario drivers have always been scratch. Every run writes them,
uses them, and deletes them; the repository has never held one. The describing
half of the scenarios became standing in M1 and the executing half did not,
because M1 named it out of scope.

The cost is not that the work is repeated. It is that the instrument is rebuilt
before each measurement. The scenario names stay L1-L3 and S1-S11, but the IOC
identities, the waits, the capture forms, and the verdict arithmetic are chosen
afresh by whoever runs it, so one run's green is not the same green as the
next's and the two do not compare. Worse, a red cannot be attributed: the
2026-08-01 debian13 run had a `cd` bound to only the first of two background
jobs, which dropped a file into the working tree — a defect in that day's
driver, not in the product.

Both blind runs stopped in the same place for the same reason, and the reports
are the evidence for the whole scope below.

#### Scope

- A top-level `gate/` directory holds what an operator executes, as against
  `docs/`, which holds what a reader reads. The runbook moves there as
  `gate/RUNBOOK.md` and the drivers land beside it. M1's records keep the old
  `docs/RELEASE_CYCLE_RUNBOOK.md` path because they describe what landed at
  `4189fd4`, where that path is the one that resolves.
- The scenario drivers become repository assets under `gate/`, one per
  principal role and one per scenario, with the IOC identities and the role
  mapping fixed in one place rather than chosen per run.
- The tree push becomes a driver too, and is the only precondition that does.
  It excludes exactly what git ignores at the source
  (`git ls-files --others --ignored --exclude-standard --directory` fed to
  `tar --exclude-from=-`), rather than a hand-kept list that treats today's
  symptom and misses tomorrow's. The push earns a driver where the other
  preconditions do not because it is the one that fails silently and surfaces
  as a disagreement further down; golden acceptance, the fixture check, and the
  environment path are read-and-judge steps and stay prose.
- The runbook's scenario section reduces to the invocations, the verdicts, and
  the traps. The fragments it currently carries are removed as the drivers
  absorb them.
- The nineteen findings the two blind runs returned are all resolved here.
  Seven are resolved by the drivers existing at all; twelve are text corrections
  that stand on their own. The split was first written as six and thirteen, from
  before finding 1 moved to the push driver; the table below is what governs.

| # | Finding | Resolution |
| --- | --- | --- |
| 1 | The pushed tree's cleanliness reads differently on the two sides: `.claude/settings.local.json` is hidden on the control host by a global excludes file that `tar` does not carry, so `git status --porcelain` prints nothing there and `?? .claude/` on the VM. The operator cannot tell from the runbook's own check whether the tree under test is the tree they pushed. The deployed stamp is NOT affected — measured 2026-08-01 on `07bcb24` with the excludes file disabled: `git diff --quiet HEAD --` exits 0 and `-V` reports the bare hash, because M4 moved all three sites off the index comparison and an untracked file does not reach a content diff | Driver: the push driver excludes exactly what git ignores at the source, so both sides agree |
| 2 | The one-line fixture assertion cannot detect `obs` absent; its only `obs` clause is a negative test, so a missing account still prints `FIXTURES OK` | Text: add a presence clause |
| 3 | A failed "Required to continue" whose remedy is out of scope has no branch; both operators invented one | Text: connect the failed precondition to the Check grade |
| 4 | The scenario fragments are written in two calling conventions — positional arguments run as the principal, and control-host `ssh` lines — and neither is marked | Driver: the file's location states its side |
| 5 | No scenario IOC identities are given, though the ordering section depends on at least six | Driver: fixed in one place |
| 6 | No test states whether a consumer VM is fresh; the runbook prints two values and never says what they must equal | Text: compare against the manifest's `app_ioc_runner commit=` |
| 7 | The suite invocation and the capture form are never shown fused, and the fusion is not mechanical: the redirection must sit inside the `ssh` quotes and outside the `sudo` word, and only the first of five uses `>` | Driver: one invocation |
| 8 | The `.prevowner` guidance is attached to a listing that carries no trailing wildcard; only the post-repair listing has one | Text: move the guidance to the listing that can show them |
| 9 | `<log>` is a remote path in gate step 2 and a control-host path in step 3, and nothing says so | Text: state the side per step |
| 10 | S9's root half shows its two `sed` lines with no `ssh` and no principal switch; that they run as the operator is stated much later | Driver: already wrapped |
| 11 | The between-runs cleanup does not reach the payloads: `remove` clears `/etc/procServ.d` but leaves `/opt/epics-iocs/<name>` and `~/iocBoot/<name>` | Text: name both paths |
| 12 | No libvirt domain naming rule and no `virsh` command; the documented target `rocky8-iocrunner.server` is the domain `testbed-rocky8-iocrunner-server` | Text: give the command and the rule |
| 13 | `cat -v` shows `^@` throughout the verb captures. Those are a literal `0x5E 0x40` emitted by the runner, not a rendered NUL, so a reader following the document's own instruction concludes the trap entry is wrong | Text: distinguish the literal pair from a rendered control byte |
| 14 | The anchored-`grep` evidence holds only for the line that lost its start; where the closing message begins the line, anchoring loses nothing | Text: name which line the measurement is taken on |
| 15 | The named skip example did not occur; the actual skip is `logrotate not found`, next to a deploy line announcing that the logrotate policy was installed — both true, and unexplained | Text: correct the example and note that the golden ships the policy without the binary |
| 16 | Step 3's one expected warning is host-conditional but reads as universal, and which host it means is only learned by running S11, which comes later | Text: move the branch determination ahead of the step that depends on it |
| 17 | No expected runtime for the suites, so nothing distinguishes slow from hung | Text: give durations and a bounded wait |
| 18 | Scenario output paths are not stated to be absolute; a relative one drops files into the working tree | Driver: absolute paths |
| 19 | `ssh` hardening (`-n`, `BatchMode`) appears once, for one case only | Driver: carried by every call the drivers make |

Out of scope: product code under `bin/` and `configure/`; the runbook sections
the nineteen findings do not touch; the gate itself becoming a single script,
which would make the runbook's preconditions unreadable as steps;
`docs/MILESTONE_PROCEDURE.md`, which D4 holds in place unchanged through this
cycle and which therefore does not move into `gate/`.

#### Completion Criteria

- The drivers exist as tracked files, fix the scenario identities in one place,
  and print each scenario's verdict rather than deciding it silently.
- The runbook's scenario section cites the drivers and no longer carries
  fragments the reader must classify.
- The push driver makes `git status --porcelain` on the pushed tree agree with
  the same command on the control host, with nothing removed by hand.
- All nineteen findings above are resolved, each traceable to the driver or the
  text edit that resolves it.
- An independent operator, given the runbook and the shipped drivers and
  nothing else, drives all fourteen scenarios on both goldens.

#### Dependencies And Decisions

- D1, D7, D8, M1.
- The drivers are reconstructed from two sources, neither authoritative alone:
  the 2026-08-01 debian13 run, which drove all fourteen scenarios and is the
  only recorded set with a settled verdict per scenario; and the earlier rocky8
  material, which is the only evidence for the branches that host takes. The
  debian13 set is one-host-proven and must not be shipped as if it were both.
- The two hosts branch at, at least: the S11 sudo form (glob against anchored),
  the EPICS environment path, the `script` closing message and whether it ends
  with a newline, the timeout exit code, and whether the login shell prints a
  banner and locale warnings.

#### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner, 2026-08-01, on this plan as revised through the
third-person review and its four repairs
Implementation Authorization: owner, 2026-08-01, same exchange
Superseded Plan Artifacts: none

1. Recover the 2026-08-01 debian13 drivers verbatim. Done: seventeen drivers,
   the S3 block that was never a file, and a notes file, each byte count
   matching the listing taken on the VM after the copy. No rocky8 counterpart
   exists — that run stopped before the scenarios — and the earlier scratch
   material is two overlapping sets with no record of which was current and no
   settled verdict per scenario, so it is not mined. rocky8 coverage comes from
   step 6 instead, which is cheaper and is evidence rather than archaeology.
2. Clear the debian13 consumer of the prior runs' leftovers by name — `s3b`,
   `s8ioc` and `sshared` under `/opt/epics-iocs/`, and `lowna` and `lshared`
   under the local users' `~/iocBoot` — and confirm the removal by listing both
   locations. This step asks only that the consumer already carry a deployed
   runner; the recovered drivers are copied over on their own, so nothing here
   needs the tree pushed and nothing here depends on the push driver, which
   step 3 builds and step 6 is the first to need. Then drive the whole scenario
   step from the recovered set exactly as it stands, altering nothing in it, to
   confirm the set still runs and to
   produce the evidence the shape decision rests on. The findings are not
   folded in here: findings 4, 5, 18 and 19 each need the shape settled first,
   and the shape is settled from this run. The clearing comes first because
   `remove` never reaches the payload directories (finding 11), and a scenario
   that passes because a prior run's IOC happens to exist is exactly the false
   green this milestone exists to end. The run is Check grade in one narrow
   sense only — that the drivers execute, capture, and print — and in no other:
   its scenario verdicts are not evidence about the product, because the
   consumer is not freshly built and S3 and S4 turn on timing. Gate-grade
   verdicts come only from step 9.
   Done, 2026-08-01. The clearing measured finding 11 rather than inferring it:
   all three runner listings had nothing to remove and all three install records
   were empty, while the five payload directories were still there. All fourteen
   scenarios drove and all fourteen matched their stated expected results. Five
   observations read as red on sight and every one resolved at the first rule of
   the runbook's order or at the fixtures; none reached "Rebake and reproduce",
   so no red is carried forward unattributed. What the set could not carry is
   below, and it is the input to step 4's revision of D8:
   1. No driver prints a scenario verdict at all. Every verdict was a human
      reading of a transcript. L1's verdict is a comparison across two separate
      invocations that no driver makes; S3's needs the printed word read against
      an inverted exit code; S10's needs `rc=137` ignored and the banner found.
      D8's "one verdict form rather than three" understates this: there is no
      scenario verdict to unify.
   2. The principal is not an argument and cannot be checked. `sys-s10.bash`
      runs as two principals, `sys-s9-restore.bash` twice with different values,
      `cleanup.bash` three times; each only reports `id -un` after the fact, so
      a wrong principal yields a plausible transcript.
   3. Three parts of the run have no driver: the local-user runtime directory
      forcing, the survival check between S6 and S10, and S9's whole root half —
      two of S9's four verdicts come from a hand-typed command.
   4. Every identity lives outside the set: the environment path, six IOC names,
      five uids, the S8 token, the role mapping. Without the notes file not one
      driver runs.
   5. The execution side is in no file; `sys-`/`local-` marks the mode.
   6. The order is in no file.
   7. `sys-s11.bash` cannot tell which answer is correct; the branch
      determination is a separate lookup.
   8. `cleanup.bash` is outside the convention and its only input is an
      undocumented environment variable.
   9. `sys-payload.bash` serves two roles separated only by the name argument.
   10. The capture form is in no driver; every read was piped by hand.
   11. `/tmp/s4.out` is a fixed name two runs collide on.
   12. The notes file's S9 root half prints one exit code and it is false: `$?`
       captures the `sed` at the end of the read pipeline, so an install that
       aborts reports `rc=0`, under a label naming the wrong shape. The
       parent-reference invocation prints none. Confirmed by reading the file.
3. Write the push driver and check it on its own, before anything is built on
   it: push the tree with it, compare `git status --porcelain` on the pushed
   tree against the same command on the control host, and confirm the excluded
   set is exactly what
   `git ls-files --others --ignored --exclude-standard --directory` prints at
   the source (T5). That agreement is finding 1's whole claim and costs one
   push to check; leaving it to first run inside step 9 spends a two-host gate
   run to learn it.
4. Take the shape to the owner and stop there. Done, provisionally, as D8. The
   proposal carried the argument convention, how a verdict is printed, where
   the scenario identities are fixed, the absolute output paths, and the `ssh`
   hardening every call carries — findings 4, 5, 18 and 19. Its evidence is not
   what this step first planned: rather than waiting for the step 2 and step 3
   runs, it was read off all seventeen recovered files, on the ground that the
   2026-08-01 debian13 run is itself a successful run and the seventeen already
   agree on most of the shape, leaving only seven divergences to settle. That
   is why D8 is provisional through step 6 rather than final. These are durable
   design decisions on a standing asset that later cycles execute unchanged, so
   each revision is a dated owner decision amending D8, never a change the
   implementer makes mid-run.
5. Fold those four findings into the recovered set in the accepted shape, land
   the drivers and the push driver under `gate/`, and reduce the runbook's
   scenario section to invocations, verdicts, and traps.
6. Drive the landed drivers on rocky8 and repair what that host's own branches
   break. This consumer stands where step 2's does, and is treated the same
   way: no recorded run names its leftovers, so the step first reads them —
   `ioc-runner list` in both modes, plus the payload directories under
   `/opt/epics-iocs/` and the local users' `~/iocBoot` — clears what it finds,
   and then drives under step 2's narrowed Check grade, for step 2's reason.
   Until this step passes the set is one-host-proven.
   Done, 2026-08-02. Fourteen of fourteen on the first run with no driver
   edited, and no red to take through the runbook's order. The consumer carried
   six payload directories from the pre-M5 scratch identities, which
   `leftovers.bash` named and which were removed by name; its verdict inside the
   driven run then read clear. D8 is amended and final on this run. Two things
   the run settled rather than left: the one place a host-specific exit code and
   closing message were written as universal is repaired, and the login-shell
   trap is recorded as confirmed absent here rather than confirmed carried, so
   that defence remains one-host evidence.
7. Apply the twelve text findings — the Scope table's Text rows, which are
   findings 2, 3, 6, 8, 9, 11, 12, 13, 14, 15, 16 and 17. Done, 2026-08-02.
   Finding 15's recorded cause was wrong and was corrected against measurement:
   logrotate is present on both goldens and the user PATH differs, which is the
   root M7 now owns. The three places the document read "one golden" anonymously
   are named from the same measurements.
8. Restore the goldens' ownership, bake both, create fresh consumers, and
   record the golden acceptance before anything touches them. Both blind runs
   of 2026-08-01 failed the acceptance on a consumer a prior run had already
   deployed to, and the goldens are `libvirt-qemu`-owned, which stops a bake at
   its publish step without saying so.
9. Verify: the honest-red check (T2), the walk of all nineteen findings (T3),
   and blind execution on both goldens at Gate grade (T1, T4, T5). This is the
   only step whose scenario verdicts carry Gate grade, because it is the only
   one whose consumers are fresh.

Where a red sends the run. Every red is taken through the runbook's own
"When a red appears" order before anything is changed. In steps 2 and 6 the
order reaches its "Rebake and reproduce" rule and cannot pass it, because a red
seen only on a reused consumer is not attributable. That rule's own remedy is
deferred here rather than dropped — step 9 is where the fresh-consumer
reproduction happens — so until then such a red is pursued only as far as the
driver and the fixtures. One that
resolves there is repaired and its step re-driven whole rather than resumed at
the failing scenario; one that does not is recorded as unattributed and carried
to step 9 for reproduction on a fresh consumer, and the step does not continue
on the assumption that it is harmless. In step 9 a driver red returns the work
to the step that owns the driver, after which step 9 is driven again from fresh
consumers rather than patched in place, per the runbook's rule that a change to
the tree invalidates the steps already run. A product red stops the milestone
and goes to the owner with its evidence: D1 and D7 authorize no work under
`bin/`, so this milestone does not absorb it. A red that survives the whole
order unattributed also stops the milestone and is recorded as such; it is not
re-driven until its attribution is settled, because a red that disappears on a
re-drive is the condition this milestone exists to end.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Driver execution | Drive all fourteen scenarios from the shipped drivers on each golden, including both S11 branches | Both goldens | Every scenario reaches its stated expected result, and each verdict is printed by the driver |
| T2 | Honest-red check | Break one scenario's precondition deliberately and confirm the driver reports it rather than exiting green | One golden | The driver returns the red and names the scenario |
| T3 | Finding traceability | Walk the nineteen findings against the landed drivers and text | Working tree | Each finding names the driver line or the text edit that resolves it; none is closed by assertion |
| T4 | Blind execution | Hand an independent agent the runbook and the shipped drivers, with no access to this conversation, and have it run the scenario step on both goldens | Both goldens | The operator completes all fourteen scenarios on each golden without writing a driver of its own |
| T5 | Push-driver agreement | Push the tree with the push driver, then run `git status --porcelain` on the pushed tree and on the control host and compare, and compare the driver's exclusion set against `git ls-files --others --ignored --exclude-standard --directory` at the source | One golden, then both at the step 9 gate | The two `git status --porcelain` outputs are identical, the exclusion sets match, and finding 1's one-sided `?? .claude/` does not reappear |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | — | — | pending | |
| T2 | — | — | pending | |
| T3 | — | — | pending | |
| T4 | — | — | pending | |
| T5 | — | — | pending | |

#### Closure Evidence

Pending.

#### GitHub Projection

Title: Ship the gate's scenario drivers as repository assets
Labels: tests, docs, P2-medium
GitHub Milestone: 1.2.3
Observed State: open
Observed Labels: P2-medium, docs, tests
Observed Milestone: 1.2.3
Last Compared: 2026-08-01

### M6 - The suite verdict cannot see a skip

Origin: the conceptual-integrity sweep of 2026-08-02, run against the gate after
M5's step 6
Identity History: none
GitHub Issue: 135, https://github.com/jeonghanlee/epics-ioc-runner/issues/135
Status: In progress

#### Summary

`gate/RUNBOOK.md` says `A skip is not a pass.` in those words. Six lines above
that sentence, the command that decides a suite run counts `Failed` and
`Script Errors` and nothing else, so a skipped step is invisible to it. A run
that dropped four checks scores identically to one that ran them.

This is not a new class. The same document already records the same defect on a
different axis: a truncated log once printed `SUITES OK (1 blocks)`, which it
calls "a green for four suites that were thrown away", and the repair was to
count the blocks. The skip axis got prose instead of a count, and the prose can
be walked past.

Measured: debian13's local lifecycle reports 82/82 with M19.T1, M19.T2, M19.T3
and the M19 teardown absent, in both source and installed mode. rocky8 reports
94/94 with them present. The verdict says `SUITES OK` for both.

#### Scope

- The suite verdict command in `gate/RUNBOOK.md`, in both the gate step and the
  driver-forms copy, so the two do not drift.
- Whatever the verdict needs to read a skip. The suites report skips as prose in
  the body rather than in the summary block, so the count comes from the body.
- The evidence format, so a recorded run carries what was skipped beside the
  counts rather than only the counts.

Out of scope: making the skipped checks run, which is M7; the suites' own
reporting format, which this milestone reads rather than changes.

#### Completion Criteria

- The verdict does not print a plain `SUITES OK` for a log carrying a skip.
- A run with a known skip and a run without are distinguishable from the verdict
  line alone.
- The driver-forms copy of the command and the gate step's copy are the same
  command.
- The twelve differing checks between the two goldens' local lifecycle totals
  are enumerated, not just counted.

#### Dependencies And Decisions

- D1 as amended 2026-08-02: this is documentation work and needs no exception,
  but it takes the formal route regardless.
- M7 is the other half. M6 makes a skip visible; M7 removes the one skip that
  should not be happening. Neither substitutes for the other.
- Ordering, owner-approved 2026-08-03: M6 runs before M7's golden-VM
  verification, so the one VM run drives M7's T1 and T2 under the new verdict
  and confirms it live. M6's step 1 does not need M7's skip to still exist:
  the pre-fix logs of 2026-08-02 carry the real skip form.

#### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner decision in session, 2026-08-03
Implementation Authorization: owner decision in session, 2026-08-03; reviewed
with the owner directly, no agent review panel, as for M7. Step 2's verdict
behavior on a nonzero skip count is decided with the owner before it is
written, per the step's own wording.
Superseded Plan Artifacts: none

1. Read a real suite log from each golden and record how a skip is actually
   printed, per suite. The form is not assumed. Done 2026-08-03 — the log
   inventory and the step 1 findings below.
2. Extend the verdict to count skips from the body, and decide with the owner
   what a nonzero count does to the verdict line.
3. Apply it to both copies of the command.
4. Enumerate the twelve-check difference between the goldens.

Log inventory, observed 2026-08-03 from top over ssh (recheck with the
commands in `gate/RUNBOOK.md`'s verdict step):

- Both iocrunner testbeds are running: `testbed-debian13-iocrunner-server`
  (192.168.122.50) and `testbed-rocky8-iocrunner-server` (192.168.122.150),
  both up since 2026-08-01.
- rocky8 holds a real gate log: `/tmp/gate.log`, 121,654 bytes, 1,524
  lines, mtime Aug 1 00:13 — the no-skip side of T1.
- debian13 holds no log anywhere (`/tmp`, `/dev/shm`, home): the
  skip-carrying side of T1 did not survive. Its tree is at `1ee17fa` with
  step 2/3 driving edits in `gate/` — before the M7 fixes — so the testbed
  as it stands can regenerate a real skip-carrying log by running its own
  local lifecycle suite unmodified. rocky8's tree is at `57c2c3d`, also
  pre-fix, which keeps its existing log representative.
- Consequence for M7's T2: rocky8's pre-fix log doubles as the "totals
  unchanged from before" baseline (local lifecycle 94 of 94).

Step 1 findings, observed 2026-08-03, from both testbeds' `/tmp/gate.log`
(debian13's regenerated that day on its pre-fix tree at `1ee17fa`: local
lifecycle, 82 of 82, suite exit 0, the finding's condition reproduced):

- The debian13 log carries exactly five skip lines, all M19: the probe's
  `WARN: logrotate not found; U003/M19 rotation steps will be skipped.` and
  four step-level `[WARN   ] logrotate unavailable; skipping M19.T1.` (T2,
  T3, `M19 teardown checks.`) lines.
- The word `skip` alone cannot be the anchor. rocky8's log has nine
  case-insensitive matches, of which three are `[ PASS ]` lines whose check
  NAMES contain the word (`takes the skip path`, `Identical-skip reasserts
  conf mode 0600`, `warns and skips rotation`). A verdict grepping the bare
  word counts passes as skips.
- The "rocky8 is the no-skip side" assumption from the log inventory above
  was measured false. rocky8's log carries a real skip, twice (once per
  lifecycle run): `The monitor-isolation step will be skipped.` followed by
  `[WARN   ] User-scope journal unavailable, skipping monitor isolation
  test.` Its 94 of 94 green also meant "of what ran". The new verdict will
  flag rocky8's current log, correctly.
- A third form exists: `[INFO   ] SKIP: deployed sudoers uses glob
  fallback; regex-deny probe does not apply.` followed by a `[ PASS ]`
  line asserting the skip. This is a deliberate does-not-apply recorded as
  a pass, not a dropped check; whether the verdict counts it is a step 2
  decision for the owner.
- Real skip forms observed so far: step-level `[WARN   ] ... skipping ...`
  (the load-bearing one), probe-level prose `... will be skipped.`, and
  the `[INFO   ] SKIP:` does-not-apply form.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Verdict execution | Run the verdict over a real log known to carry the M19 skips, and over one known not to | Both goldens' logs | The two produce different verdict lines |
| T2 | Drift check | Compare the gate step's copy of the command against the driver-forms copy | Working tree | They are the same command |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | — | — | pending | |
| T2 | — | — | pending | |

#### Closure Evidence

Pending.

#### GitHub Projection

Title: The suite verdict cannot see a skip
Labels: docs, tests, P2-medium
GitHub Milestone: 1.2.3
Observed State: open
Observed Labels: P2-medium, docs, tests
Observed Milestone: 1.2.3
Last Compared: 2026-08-02

### M7 - The suite tool probe disagrees with the runner

Origin: the same sweep of 2026-08-02, measured on both goldens
Identity History: none
GitHub Issue: 136, https://github.com/jeonghanlee/epics-ioc-runner/issues/136
Status: In progress

#### Summary

`bin/ioc-runner` resolves `logrotate`, `con` and `procServ` by searching
absolute paths first and falling back to a PATH lookup. The reason is written at
`bin/ioc-runner:1100`: the systemd user manager runs services with a minimal
PATH, so the install must bake an absolute path. `tests/test-local-lifecycle.bash`
probes the same tools with `command -v` alone.

Measured 2026-08-02 in one shell on debian13: `command -v logrotate` fails while
`/usr/sbin/logrotate` is present and executable, version 3.22.0. rocky8 carries
`/usr/local/sbin:/usr/sbin` on the user PATH and rocky8 does not fail. Debian
keeps `sbin` off a user's PATH by convention; nothing is missing on either host.

The consequence is not a wrong pass. It is four checks — M19.T1, M19.T2,
M19.T3 and the M19 teardown — that do not run on debian13, in both modes, for a
feature the runner installs there correctly. `con` and `procServ` have the same
shape and are latent: both are on the user PATH on both goldens today.

#### Scope

- The tool probes in `tests/test-local-lifecycle.bash`, brought to the same
  answer the runner gives. The owner's direction is to augment the PATH the
  probe searches.
- The other suites' probes only where the same shape is present.

Out of scope: `bin/ioc-runner`'s resolution, which is correct and is the
reference this milestone aligns the probe to; the `lsof` probe at line 35, which
aborts rather than skips and is a different decision.

#### Completion Criteria

- The probe answers what the runner answers, on both goldens.
- M19.T1, M19.T2, M19.T3 and the M19 teardown execute on debian13 in both modes.
- No probe that guards a skip disagrees with a runner resolver for the same tool.
- The duplicated path knowledge is either avoided or recorded as a known second
  copy with the reason.

#### Dependencies And Decisions

- D1 as amended 2026-08-02: this is a code change under `tests/`, taken on the
  owner's authority by the formal route rather than a new named exception.
- M6 is the other half and does not substitute for this one: making the skip
  visible does not make the check run.
- Ordering, owner-approved 2026-08-03: T1 and T2 wait for M6's skip-aware
  verdict, so the one golden-VM run verifies both milestones. This milestone
  stays In progress, not blocked — everything except T1 and T2 is done.

#### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner decision in session, 2026-08-03
Implementation Authorization: owner decision in session, 2026-08-03; the review
runs with the owner directly, no agent review panel this milestone (token
budget). The owner's stated inclination is to bring the runner's verified
resolution over rather than design a fresh one.
Superseded Plan Artifacts: none

1. Enumerate every probe in the suites that guards a skip, and every runner
   resolver, and pair them. Done 2026-08-03; findings below.
2. Augment the probe's search per the owner's direction, and record what the
   second copy of the path knowledge costs. Done for logrotate 2026-08-03,
   committed as `9f8d01c`. Decisions 2 and 3 were both decided as fix by the
   owner later the same day and are committed as `9f6a3e9`; the decision
   paragraphs below record their shape.
3. Drive the local lifecycle on debian13 in both modes and confirm the four
   steps run.
4. Drive it on rocky8 and confirm nothing changed there.

Step 2 result, 2026-08-03, committed as `9f8d01c`:
`tests/test-local-lifecycle.bash` resolves one `LOGROTATE_BIN` at
the top in the runner's order — `/usr/sbin/logrotate`, `/sbin/logrotate`,
`/usr/bin/logrotate`, then `command -v` as fallback — and the probe plus the
three M19 invocations (the T1 `-d` validation and the T2 and T3 forced
rotations) all route through it. The comment above the block records the
second copy of the path knowledge, names `LOGROTATE_SEARCH_PATHS` in
`bin/ioc-runner` as the reference, and states why `IOC_RUNNER_LOGROTATE_TOOL`
is not consulted (the suite verifies the default deployment). Static
verification observed 2026-08-03: `bash -n` clean and `shellcheck -S warning`
clean on the edited file. The dev host top is itself the defect condition —
`command -v logrotate` fails while `/usr/sbin/logrotate` is executable — and
the new resolution order picks the first candidate there, so the probe no
longer skips on the shape that produced the finding. T1 and T2 remain the
real verification and need the golden VMs.

Before acting on this plan, re-verify it against the code. The session that
wrote it ran under a tight token budget, so this document can lag the working
tree: the line numbers and shapes below are observations at `6223a04`, not
guarantees. Re-run the pairing grep before step 2 and trust the tree over
this text where they disagree.

Step 1 findings, 2026-08-03, working tree at `6223a04`:

- The runner resolves three tools, each by env override first and then an
  absolute search list, in `bin/ioc-runner`: logrotate
  (`IOC_RUNNER_LOGROTATE_TOOL`; `/usr/sbin`, `/sbin`, `/usr/bin`; then a
  `command -v` fallback; returns nonzero when absent because rotation is
  best-effort), con and procServ (`IOC_RUNNER_CON_TOOL` /
  `IOC_RUNNER_PROCSERV_TOOL`; `/usr/local/bin`, `/usr/bin`, with
  `~/.local/bin` prepended in user mode; exit on failure).
- logrotate is the defect proper, and the probe is not the whole fix:
  `tests/test-local-lifecycle.bash:62` probes with `command -v` alone and
  gates the four M19 steps, but the M19 bodies also invoke `logrotate` by
  bare name at lines 1262, 1312 and 1348. A repaired probe alone would stop
  the skip on debian13 and then turn M19.T1 red (exit 127 on the `-d`
  validation) while T2 and T3 swallow the bare-name failure with `|| true`
  and fail later on the archive checks. The fix must resolve one absolute
  path and route the probe and all three invocations through it.
- con is latent in two places: `tests/test-local-lifecycle.bash:751` and
  `tests/test-system-lifecycle.bash:636` probe PATH and then only
  `/usr/local/bin/con`, missing the runner's `/usr/bin/con` and user-mode
  `~/.local/bin/con`. No symptom on either golden today (con is on PATH),
  and these are assertions rather than skip guards, so a disagreement would
  show as a false red, not a silent skip.
- procServ has no suite probe at all, so no pair can disagree; nothing to do.
- Tools with no runner resolver (lsof, socat, truncate, camonitor, sudo) have
  no pairing by construction; lsof aborts rather than skips and stays out of
  scope per this milestone's Scope.
- Boundary finding held for the owner: `tests/test-system-lifecycle.bash:993`
  runs bare `logrotate -f` with stderr swallowed, guarded by the existence of
  `/etc/logrotate.d/procserv` rather than a tool probe. That suite runs as
  root, whose PATH carries sbin, so there is no symptom today.

Decisions taken during step 2 — all three are settled:

1. Fix shape — decided (a) by the owner, 2026-08-03: copy the runner's search
   order into the suite, resolving one `LOGROTATE_BIN` at the top and routing
   the probe and the three invocations through it, with the second copy of
   the path knowledge recorded in a comment naming `bin/ioc-runner`'s
   `LOGROTATE_SEARCH_PATHS` as the reference. The alternative (b), prepending
   `/usr/sbin:/sbin` to PATH at the suite top, was declined for changing PATH
   for the whole suite.
2. Whether the two latent con probes are brought to the runner's list in this
   milestone — decided fix by the owner, 2026-08-03, committed as
   `9f6a3e9`. The probes in both suites now walk `resolve_con_tool`'s
   absolute list (user mode adds `${HOME}/.local/bin/con` first; system mode
   is `/usr/local/bin/con`, `/usr/bin/con`) with no PATH fallback, because
   the runner never consults PATH for con; the runner's socat fallback is
   deliberately not mirrored since the check asserts the con utility itself.
3. Whether the bare `logrotate -f` in `test_logrotate_boundary`
   (`tests/test-system-lifecycle.bash`) is taken here — decided fix by the
   owner, 2026-08-03, committed as `9f6a3e9`. The boundary test resolves
   `logrotate_bin` in the runner's order with a `command -v` fallback and,
   when unresolved, now WARN-skips like that function's other two guards
   instead of aborting the whole suite under `set -e`. The new skip path is
   one more instance for M6 to make visible.

Static verification of the decision 2 and 3 edits, observed 2026-08-03:
`bash -n` clean and `shellcheck -S warning` clean on both edited suites.

Dev-host run observed 2026-08-03 on top — debian with sbin off the user
PATH, the defect condition itself — in source mode with the 1.2.1
debian-13/7.0.10 environment: `bash tests/test-local-lifecycle.bash` passed
96 of 96 with zero failures and zero script errors, the log carries no skip
line, the fourteen M19 assertions all ran and passed (T1 nine, T2 two, T3
one, teardown two), and the con check passed through the new absolute-list
probe. Before the fix this host skipped every M19 step. This is the dev-host
tier, not T1: T1 (debian13 golden, both modes) and T2 (rocky8 golden) remain,
and the system suite has not yet run with the decision 3 edit — it runs on
the golden VMs as part of those.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Suite execution | Run the local lifecycle in both modes on debian13 | debian13 | The M19 skip is absent and the four steps execute |
| T2 | No-regression | Run the same on rocky8 | rocky8 | The totals are unchanged from before |
| T3 | Pairing walk | Walk every skip-guarding probe against the runner resolver for the same tool | Working tree | No pair disagrees |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | — | — | pending | |
| T2 | — | — | pending | |
| T3 | — | — | pending | |

#### Closure Evidence

Pending.

#### GitHub Projection

Title: The suite tool probe disagrees with the runner's resolution
Labels: bug, tests, P2-medium
GitHub Milestone: 1.2.3
Observed State: open
Observed Labels: P2-medium, bug, tests
Observed Milestone: 1.2.3
Last Compared: 2026-08-02

### M8 - Suite skip-reporting policy

Origin: M6's step 1 findings of 2026-08-03 in this register, opened at the
owner's direction the same day
Identity History: none
GitHub Issue: 137, https://github.com/jeonghanlee/epics-ioc-runner/issues/137
Status: Not started

#### Summary

The suites report a skip three different ways — step-level `[WARN   ] ...
skipping ...`, probe-level prose `... will be skipped.`, and `[INFO   ]
SKIP:` for a deliberate does-not-apply — and none of them reaches the
summary block, which counts only `Passed`, `Failed` and `Script Errors`.
Meanwhile three `[ PASS ]` check names contain the word `skip`, so no bare
word can anchor a count. M6 makes the verdict read these forms from the log
body; that is a reading of what exists, not a policy. Counting skips
exactly requires the tests' own verification policy to say what a skip is,
which class each emission belongs to, and where the count lives.

#### Scope

- Every skip, WARN, and does-not-apply emission across the four suites,
  enumerated and classified: a dropped check, a deliberate does-not-apply,
  or a benign warning.
- One written policy form per class, applied to every emission.
- The summary block of each suite extended to carry the skip count beside
  `Passed`, `Failed` and `Script Errors`, so a verdict reads a count
  rather than grepping prose.
- The reporting model below, refined and settled with the owner in step 2,
  applied across the four suites.
- The SKIP-versus-NA boundary for per-OS differences, defined explicitly:
  test counts and methods legitimately differ per OS, and the policy must
  say who declares "this check was never meant to run here" — the check
  code deciding at run time, or a per-OS expected list the run is compared
  against. Undefined today; owner decision in step 2. (Owner direction,
  2026-08-03.)
- rocky8's monitor-isolation skip (`User-scope journal unavailable`),
  examined under that boundary: whether it is a legitimate NA or a
  removable skip (enabling the user-scope journal), and resolved
  accordingly. (Owner direction, 2026-08-03 — pulled into M8 rather than
  opened separately.)
- A full re-verification once the policy lands: the owner's direction of
  2026-08-03 is that the whole suite set is re-verified on both goldens
  under the new reporting, so every state the old format could not record
  is observed once with the new one before the release gate reads it.

Out of scope: the verdict command, which is M6 and reads whatever the
suites print; making any other individual skipped check run (the M7
class); the drivers under `gate/`, whose verdict convention D8 fixed.

#### Reporting model (draft, 2026-08-03 — owner direction; settled in step 2)

The owner's requirement: the output and the summary must record the state
of the test procedure exactly, the per-step records must be fine-grained,
and at release-gate time those records alone must say what state the
product is in. Four layers follow from that:

1. **A closed state set per check.** Every check terminates in exactly one
   of: `PASS`, `FAIL`, `SKIP` (was meant to run and did not, with the
   reason), `NA` (examined and found not applicable, with the reason), or
   `SCRIPT ERROR`. A check that ends in none of these is itself a suite
   defect — silence is not a state. This gives every suite a denominator:
   the count of checks it owns, independent of what a particular run
   executed.
2. **A step outcome line per STEP.** Each numbered STEP closes with one
   line carrying the step's identity and its assert tally (pass, fail,
   skip, na). This is the granularity the goldens differ at — the
   twelve-check difference between debian13's 82 and rocky8's 94 becomes
   an enumerable list of steps, not a subtraction — and it feeds M6's
   fourth completion criterion directly.
3. **A summary block that carries the full vector.** `Total`, `Passed`,
   `Failed`, `Skipped`, `Not applicable`, `Script Errors` — zero printed,
   never omitted — followed by one line per SKIP and NA repeating the
   check identity and reason, so a reader gets the exceptions without
   scanning the body.
4. **One machine-readable trailer per suite run.** A single fixed-form
   final line (shape settled in step 2, e.g.
   `SUITE <name> total=<n> pass=<n> fail=<n> skip=<n> na=<n> err=<n>`)
   that the gate verdict parses. Five runs per host means five trailers in
   one log; the verdict counts blocks and reads trailers, and a green
   requires every trailer present, `fail=0`, `err=0`, `skip=0` — with a
   nonzero `na` allowed only because each NA line above names its reason.

At the release gate this makes the recorded state exact: the gate record
stores each host's five trailers plus the enumerated SKIP and NA lines, so
"passed" is always "passed out of the declared total, with these named
exceptions", never "of what ran".

#### Completion Criteria

- Every check in the four suites terminates in exactly one state from the
  closed set, and a check with no state is treated as a suite defect.
- Every suite's summary block reports the full vector — skip and
  not-applicable counts included, zero printed — and enumerates each SKIP
  and NA with its reason.
- Each numbered STEP closes with its own outcome line, and the difference
  between the two goldens' totals is enumerable from those lines alone.
- Every suite run ends in one fixed-form machine-readable trailer, and
  M6's verdict (or its successor) reads the trailers instead of the body
  forms.
- Every skip emission in the four suites matches its class's policy form,
  verified by a sweep, and no `[ PASS ]` name can be confused with one.
- The policy and the reporting model are written down beside the suites.

#### Dependencies And Decisions

- M6: its step 1 enumeration is this milestone's input, and its verdict is
  the consumer of the count. M8 lands after M6 so the interim body-reading
  verdict is not rewritten mid-flight; the owner approved the M6-first
  order 2026-08-03.
- M8 gates the 1.2.3 release — owner decision 2026-08-03, accepting that
  the release moves by the cost of a tests-wide reporting change plus a
  two-golden re-run. M3's dependency row carries M8.

#### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Sweep the four suites for every skip, WARN, and does-not-apply emission;
   classify each against the three classes and list the misfits.
2. Settle the policy and the reporting model with the owner: the form per
   class, the closed state set, the step outcome line, the summary vector,
   and the trailer's exact shape.
3. Apply both to every emission, every STEP, and the four summary blocks.
4. Point the verdict at the trailers and retire its body-form anchors.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Suite execution | Run a suite on a host with a known skip | A golden carrying one | The summary block counts it and the verdict refuses a plain green |
| T2 | Suite execution | Run the same suite where nothing skips | The other golden | The summary reports zero skips and the verdict passes |
| T3 | Policy sweep | Grep every emission against the policy forms | Working tree | No emission outside its class's form, and no `[ PASS ]` name collides |
| T4 | Gate readback | Reconstruct each host's state from the five trailers, the step outcome lines, and the enumerated exceptions alone, without the log body | Both goldens' logs | The reconstruction matches the body, and the goldens' total difference is enumerated step by step |
| T5 | Full re-verification | Run the whole suite set on both goldens under the new reporting | Both goldens | Every trailer present; every SKIP and NA enumerated with its reason; the monitor-isolation case carries the state the step 2 boundary decision assigned it |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | — | — | pending | |
| T2 | — | — | pending | |
| T3 | — | — | pending | |
| T4 | — | — | pending | |
| T5 | — | — | pending | |

#### Closure Evidence

Pending.

#### GitHub Projection

Title: Suite skip-reporting policy: make a skip countable from the summary
Labels: tests, P2-medium
GitHub Milestone: 1.2.3
Observed State: open
Observed Labels: P2-medium, tests
Observed Milestone: 1.2.3
Last Compared: 2026-08-03

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

- M1, M2, M4
- D1 and D5: the line is documents and scenarios apart from one named
  exception, so the suites verify unchanged behavior everywhere except the
  version stamp, where M4 changes the comparison and carries its own
  regression coverage. The integrated re-run below therefore inherits the
  same expectation as an unchanged-behavior cycle.
- D6: the contract guard over the three stamp sites was examined and declined
  (`CLOSED_DOORS.md` CI-31), so no guard work gates this release.

#### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Bake both goldens fresh and record the golden acceptance.
2. Run the gate by following `gate/RUNBOOK.md`.
3. Execute the release sequence under `git-workflow` authority.

#### Integrated Verification

| Source Check | Re-run Trigger | Shared Surface | Release Verification Label | Expected Result | Result Evidence |
| --- | --- | --- | --- | --- | --- |
| M1 / T2 | The runbook's multi-user text changed after the drive that corrected it | `docs/RELEASE_CYCLE_RUNBOOK.md` | M1 / T4 | Every scenario drives green from the corrected text, on freshly baked goldens | done, 2026-07-30 |
| M2 / T1 | The runbook's evidence format changes after the gate record is written | `gate/RUNBOOK.md` | Release Verification 4 | The gate record still carries the declared baseline | pending |

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
