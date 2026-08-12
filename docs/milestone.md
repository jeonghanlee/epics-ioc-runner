# Work Register

Release line: 1.2.3
Canonical path: `docs/milestone.md`
Canonical branch or ref: `release-1.2.3`
Git upstream: none
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `1.2.3`

Next session entry point: review and commit the completed M11 implementation
and fresh-golden T1-T3 evidence, then close #141 under separate issue authority.
M3 remains unauthorized while its plan is draft.

The recovered set that step 1
started from is kept at `work/gate-drivers-debian13-20260801/` as the record of
what was driven before the rewrite; it is ignored and untracked, and is no
longer load-bearing now that the drivers are tracked under `gate/drivers/`.

M2 (#130) is complete. Both suppliers provide the declaration path —
`cloud-provision` `8ad180a` gives the bake its `-r <ref>` flag and
`ansible-provision` writes the `requested=` field — and the 1.2.3 Gate record
now carries the chosen `1.2.2` baseline beside each golden's suite counts and
canonical result. M4 is complete at `cc9b02e` with T1 through T6 recorded. The
owner replaced its older deferred-close record on 2026-08-06: #133 closes as a
completed standalone milestone after separate issue authority. The guard
question is settled as Keep (D6, `CLOSED_DOORS.md` CI-31). M1 is complete and
#131 is closed.

## Work

| ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- |
| M1 | (#131) Re-set the verification scenarios and write the standing release-cycle runbook | Milestone | Complete | No | | Runbook standing with drive commands and verdicts, both plan files retired, references repointed in both repositories, and a fresh operator completed the full procedure from the document alone (T6); [detail](#m1---release-cycle-runbook-and-scenario-re-set) |
| M2 | (#130) Declare the `ioc-runner` baseline the goldens carry, in the gate procedure and in the gate record | Milestone | Complete | No | M1 | Both accepted golden manifests and the Gate evidence rows name baseline `1.2.2` beside the observed suite counts and canonical host result; [detail](#m2---golden-baseline-declaration) |
| M4 | (#133) Version stamp reports `-dirty` for a relocated clean checkout whose index is stale; not reachable on the production deployment path | Milestone | Complete | No | D5 | All three stamp sites — the system setup script, the live `-V` fallback, and the `install.user` injector — report a bare hash for a relocated clean checkout, a genuinely modified one still carries the suffix, and a regression test pins both from a fixture no git command has touched; [detail](#m4---stale-index-dirty-stamp) |
| M5 | (#134) Ship the gate's scenario drivers as repository assets, and reduce the runbook's scenario section to invocations and verdicts | Milestone | Complete | No | M1, D7, D8 | The shipped scenario and suite drivers passed their execution, honest-red, traceability, blind-operation, and push-agreement checks on both fresh goldens; the release gate remains red on Rocky's recorded state vector and is not waived by this milestone; [detail](#m5---shipped-scenario-drivers) |
| M6 | (#135) The suite verdict cannot see a skip, so a run that dropped checks scores as a full green | Milestone | Complete | No | M1, M8 | The verdict consumes M8's machine-readable records, refuses a plain `SUITES OK` when any declared check is skipped or missing, and does not scan human-readable prose; [detail](#m6---the-suite-verdict-cannot-see-a-skip) |
| M7 | (#136) The suites probe for a tool by PATH where the runner resolves it absolutely, so checks skip for a tool the product can use | Milestone | Complete | No | M1 | The probe answers what the runner answers, and the four M19 steps run on the golden where they are skipped today; [detail](#m7---the-suite-tool-probe-disagrees-with-the-runner) |
| M9 | (#138) Separate source regression from post-install infrastructure verification | Milestone | Complete | No | D9, D10, D11, D12, D13, D14 | Source-tree behavior has one `source-regression` suite and separate `--source-regression` selection, while system infrastructure contains only installed-conformance checks; [detail](#m9---source-regression-suite-separation) |
| M8 | (#137) Re-examine the suites' skip-reporting policy so a skip is countable from the summary, not the body | Milestone | Complete | No | M9, D14, D15 | Every suite defines one Git-style terminal state for every check, records it once, and derives both the human summary and machine-readable records from the same ledger; [detail](#m8---suite-skip-reporting-policy) |
| M10 | Reconcile the 1.2.3 canonical register with its GitHub issues | Milestone | Complete | No | | #130 and #134 carry the completed M2 and M5 projections, are closed, and passed the post-update body and metadata comparison; [detail](#m10---release-record-reconciliation) |
| M11 | (#141) Classify Rocky local monitor-isolation checks as not applicable | Milestone | In progress | No | D16 | Both local lifecycle modes use one explicit applicability check, report the S29 group as NA on Rocky and PASS on Debian, and preserve journal least privilege; [detail](#m11---rocky-s29-applicability) |
| M3 | Final release 1.2.3 | Milestone | Not started | No | M1, M2, M4, M5, M6, M7, M8, M9, M10, M11 | Tag `1.2.3`, GitHub release, milestone closed, and every Release Verification row Pass; [detail](#m3---final-release) |

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
| D9 | Source regression and post-install infrastructure conformance are separate test categories and belong in separate suites. The former runs real shipped source paths with only their outer filesystem targets redirected to isolated temporary paths and is selected separately through `run-all-tests.bash --source-regression`; it is not part of the post-install `--system` selection. The latter reads the actual configured host state. M9 completes this separation before M8 changes reporting across the suite set. **Amended by D10:** the initially proposed `system-installer` identity was too narrow for the existing S07 through S14 inventory. | Owner decision, 2026-08-04; amended the same day after conceptual-integrity review |
| D10 | Use one `tests/test-source-regression.bash` suite with suite ID `source-regression` for the complete existing S07 through S14 inventory. Do not create a separate `test-harness-integrity` suite: setup, live runner, injection, Git fixture, and test path-safety checks already share one source-tree validity boundary, and splitting one path-safety assertion into another suite would invent a dependency and widen M9 without changing what must be verified. The suite reports `scope=system` and `runner=source`. `run-all-tests.bash --source-regression` is an exclusive selection and rejects combinations with `--local`, `--system`, `--source`, or `--installed`. The suite starts through `sudo bash`, retains the invoking identity in `SUDO_USER`, and drops to that identity only for the existing source and Git operations. | Owner decision, 2026-08-04, after conceptual-integrity review |
| D11 | Suspend the unfinished M8 reporter prototype before M9 as a local Git stash, not a `work/` copy or repository commit. Snapshot commit `f330b4e9962031de37c904ece23c653c800620c8` contains the four lifecycle and infrastructure suite edits plus `tests/lib/test-reporting.bash`; the active code paths were verified equal to local `HEAD` after capture. The stash is local-only, is not verification evidence, and is reconsidered against the M9 suite layout when M8 resumes. | Owner decision and local snapshot, 2026-08-04 |
| D12 | Every check is classified on three independent axes: test category, check kind, and test method. `tests/REPORTING_CONTRACT.md` is authoritative for category and check kind; `tests/README.md` "Test Classification" is authoritative for test method. Only real-path execution can support a behavior-verification claim. Direct state inspection can support only the state or contract directly observed, and a hand-built reproduction is invalid as verification evidence. Test method alone does not create a suite or selector. | Owner decision, 2026-08-05 |
| D13 | M9 does not preserve the current assertion count as an end in itself. Its migration inventory accounts for every current assertion and prerequisite and assigns exactly one reviewed disposition: `retain` keeps the valid check, `replace` preserves a needed verification target through valid evidence, and `remove` retires a redundant or invalid target with an owner-approved reason. No row disappears silently, and M9 step 1 remains open until every row has an accepted disposition. | Owner decision, 2026-08-05, after the second conceptual-integrity review |
| D14 | One canonical check catalog carries category, check kind, and test method. A single recording path combines that metadata with each observed terminal state in one ledger; the human summary and machine-readable records are two projections of that ledger and never separate calculations. M9 defines destination metadata and valid evidence without implementing reporting. M8 implements the record path, ledger, and both projections across the resulting suite set. M6 consumes only M8's machine-readable records and does not infer states from human-readable prose. The execution order is M9, then M8 producer, then M6 consumer. | Owner decision, 2026-08-05 |
| D15 | M8 preserves the fixed 487-check identity set and adds `state=<PASS\|FAIL>` to the final `SUITE` machine record. Cleanup and finalization failures are suite execution results, not additional checks. `PASS` requires zero final suite status with no failed checks, script errors, reporter integrity failure, or cleanup failure; every other final result is `FAIL`. M6 consumes this field later without scanning human-readable prose. **Amended 2026-08-11:** M11 adds one governing S29 applicability identity, advancing the maintained current set to 488 without rewriting historical 487-check evidence. | Owner decision, 2026-08-10; amended by owner approval of M11, 2026-08-11 |
| D16 | Under this project's Rocky ordinary-user policy, local lifecycle S29 cannot obtain its user-journal positive control and is not applicable. Do not grant `systemd-journal` membership or change host journal policy for the test. Add one governing applicability check, close it and the three existing S29 checks as NA on Rocky, and retain the applicable real path on Debian. The examined access question is closed as `CLOSED_DOORS.md` CI-32. | Owner decision, 2026-08-11, after re-reading #17, #50, #140, the reporting contract, and the 1.2.3 gate evidence |
| D17 | The repeated M11 gate exposed a separate product defect: local logrotate debug validation depends on the root-owned system default state file. Do not repair it inside M11 or change host permissions; assign it to the 1.2.4 line through `docs/backlog.md` M13. | Owner decision, 2026-08-11 |

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
Observed State: closed
Observed Labels: P2-medium, docs, tests
Observed Milestone: 1.2.3
Observed Assignee: jeonghanlee
Last Compared: 2026-08-06

### M2 - Golden baseline declaration

Origin: #130, filed 2026-07-29 during the 1.2.2 gate
Identity History: Backlog row (`docs/backlog.md`) moved to this register at the 1.2.3 open
GitHub Issue: 130, https://github.com/jeonghanlee/epics-ioc-runner/issues/130
Status: Complete

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
  `roles/bake_provenance/files/record-iocrunner-source.bash`. The pair that
  existed when the flag landed still had the six-field form. The fresh pair
  accepted on 2026-08-10 used the new path and records the requested ref beside
  the resolved identity, allowing the acceptance step to require
  `state=clean-tagged` for a pinned bake instead of recording
  `clean-untagged tag=-` as a fact about the golden.
- Owner decision, 2026-08-10: a release gate pins the last released tag that
  precedes the candidate. The 1.2.3 gate therefore uses `1.2.2` on both
  goldens and requires `requested=1.2.2 state=clean-tagged tag=1.2.2` in each
  accepted manifest record.

#### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner, 2026-08-10, selecting the current archive/working-copy
layout and the `1.2.2` baseline
Implementation Authorization: owner, 2026-08-10, same exchange
Superseded Plan Artifacts: none

1. Add the baseline selection rule to the runbook's preconditions and add the
   requested ref plus resolved identity to its evidence format. Done in
   `2eede46`; the accepted fresh-golden observation is recorded in `e659097`.
2. Record the baseline in the 1.2.3 gate evidence rows. Done, 2026-08-10, in
   the host rows below.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Gate record | Read the 1.2.3 gate evidence rows | This register | Each golden's `ioc-runner` baseline version appears beside its counts |
| T2 | Image observation | Read the baked manifest and the deployed `-V` on each golden | Both goldens | The observed baseline matches the declared one |

#### Gate Evidence

| Golden | Baked Baseline | Manifest Identity | Suite Records | Canonical Host Result | Evidence |
| --- | --- | --- | --- | --- | --- |
| Debian 13 | `1.2.2` | `requested=1.2.2 commit=fd14875df5fdbfcb362d194e81bf74c1de960daa state=clean-tagged tag=1.2.2` | 612 TEST, 165 STEP, six final PASS SUITE records | `SUITES OK (6 blocks, 612 checks, na=0)` | `work/gate-suites-20260811T020336Z-261435/vmadmin_192.168.122.50.log`, SHA-256 `74062b2a97d6f5b280a5001d93a7a6e17dd1918105457aa0cf9133a09146c219` |
| Rocky 8 | `1.2.2` | `requested=1.2.2 commit=fd14875df5fdbfcb362d194e81bf74c1de960daa state=clean-tagged tag=1.2.2` | 612 TEST, 165 STEP, six final PASS SUITE records | `SUITES FAIL blocks=6 checks=612 steps=165 skip=6 fail=0 na=4 err=0 invalid=0` | `work/gate-suites-20260811T020336Z-261435/vmadmin_192.168.122.150.log`, SHA-256 `8e9c5e2b1a869f75f2610def2eaf7588402cab94716740f8847a6c9f93a6bc4d` |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-10T20:58:08-07:00 | This register, using the clean-control Gate run at `e659097` | Pass | Both Gate Evidence rows name baked baseline `1.2.2`, the complete 612 TEST / 165 STEP / six SUITE record counts, and the actual canonical host result. The Rocky aggregate remains FAIL and is not changed by this record check. |
| T2 | 2026-08-10T18:49:18-07:00 | Fresh Rocky 8 and Debian 13 consumers | Pass | Both manifests recorded `requested=1.2.2`, `commit=fd14875df5fdbfcb362d194e81bf74c1de960daa`, `state=clean-tagged`, and `tag=1.2.2`; each retained checkout reported `fd14875`, each installed runner reported `epics-ioc-runner version 1.2.2 (fd14875)`, and each manifest dirty count was `0`. |

#### Closure Evidence

- Baseline selection and evidence format: `gate/RUNBOOK.md` lines 181-195 and
  303-330, carried by commits `2eede46` and `e659097`.
- Verification: T1 and T2 Pass. T1 reads both host rows from the actual clean
  control Gate run; T2 reads the fresh baked manifests and installed runners
  before deploy.
- GitHub issue #130 received the completed projection and closed on 2026-08-10.
  Its live body SHA-256 matched the reviewed draft at
  `3ca402b4ac7f8eba47d5d196bf63ec5c76cbe6afdf6ad4e6a10682f6c71390b3`;
  labels, milestone, and assignee matched the projection.

#### GitHub Projection

Title: Name the golden's ioc-runner baseline at bake time instead of inheriting the default branch
Labels: P3-low, tests
GitHub Milestone: 1.2.3
Observed State: closed
Observed Labels: P3-low, tests
Observed Milestone: 1.2.3
Observed Assignee: jeonghanlee
Observed Body SHA-256: 3ca402b4ac7f8eba47d5d196bf63ec5c76cbe6afdf6ad4e6a10682f6c71390b3
Last Compared: 2026-08-10T21:54:27-07:00

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
- Owner decision, 2026-08-06: close #133 as a completed standalone milestone
  after separate issue authority. This replaces the older deferred-close
  record and does not change M4's technical scope or verification evidence.

#### GitHub Projection

Title: Version stamp reports -dirty for a clean checkout whose index is stale
Labels: enhancement, P3-low, area/install
GitHub Milestone: 1.2.3
Observed State: closed
Observed Labels: enhancement, P3-low, area/install
Observed Milestone: 1.2.3
Observed Assignee: jeonghanlee
Last Compared: 2026-08-06, after the reconciled body sync and manual close

### M5 - Shipped scenario drivers

Origin: the two blind runbook executions of 2026-08-01 against `7d82f4f`, one
per golden, each given the runbook alone
Identity History: none
GitHub Issue: 134, https://github.com/jeonghanlee/epics-ioc-runner/issues/134
Status: Complete

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
- Finding 7's suite path becomes one shipped control-side driver. It owns the
  exact six invocations, remote log truncation and append order, per-run elapsed
  records, machine-record verdict, and normalized two-host comparison. The
  runbook keeps only its inputs, invocation, expected output, and evidence
  schema.
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
- The suite driver emits exactly six run-status records per host, preserves all
  six machine-record blocks in one host log, applies the canonical verdict, and
  enumerates the normalized cross-host state differences.
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
- Owner decision, 2026-08-10: resolve finding 7 with the shipped suite-driver
  form selected after the standalone second-person runbook review. This is the
  existing finding's missing implementation step, not a new gate surface.

#### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner, 2026-08-01, on this plan as revised through the
third-person review and its four repairs; amended by owner, 2026-08-10, for
the current archive/working-copy layout and the `1.2.2` baseline
Implementation Authorization: owner, 2026-08-01, same exchange; amendment
authorized by owner, 2026-08-10
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
7a. Implement finding 7 as one shipped control-side suite driver. The driver
   takes both host and resolved EPICS environment pairs as inputs; runs error
   handling, source regression, local lifecycle source, local lifecycle
   installed, system infrastructure, and system lifecycle installed in that
   order on each host; writes one remote log per host by truncating once and
   appending five times; records six elapsed results per host; applies the
   canonical machine-record verdict to each host; and emits the normalized
   two-host comparison. Reduce the runbook's suite section to the driver's
   inputs, invocation, expected output, and evidence schema. Implemented,
   real-path verified, and third-person follow-up reviewed 2026-08-10; pending
   commit. A
   third-person review found that the first evidence predated the current
   untracked driver and carried no driver hash. The owner accepted the finding.
   The driver now stores `control.meta`, the complete control porcelain status,
   and an exact driver snapshot, verifies the live and snapshot SHA-256 values
   again at finalization, and fails if either changes. The corrected two-host
   run at remote `61eea127` produced six process-success records, 612 TEST, 165
   STEP, and six final PASS SUITE records per host. Debian's canonical verdict
   passed; Rocky's canonical verdict correctly failed on six S29 SKIP and four
   S06 NA records; and the normalized comparison enumerated all differences in
   56 lines.
8. Destroy both consumers, bake Rocky 8 and Debian 13 with `-r 1.2.2`, create
   fresh consumers from the refreshed working copies, and record golden
   acceptance before anything touches them. The supplying repository now
   publishes immutable archive entries and refreshes separate working copies,
   so hypervisor ownership of a running consumer's working copy is expected
   and is not repaired. Required before the bake: no consumer domain is
   defined and the archive entries remain owned by the baking account. Both
   blind runs of 2026-08-01 failed acceptance on a consumer a prior run had
   already deployed to; the fresh-consumer boundary remains mandatory.
   Done, 2026-08-10. Before the bake, neither consumer domain nor either
   consumer overlay existed, and the archive entries were owned by the baking
   account. The supplier checkouts were clean at cloud-provision
   `579a8f322c6ee3997c6e6ae2581b9a0477666ef0` and ansible-provision
   `5c52419bf3be795780abdc64cec7732d424fede4`; `make check-bake` passed all
   7 fresh-input and 77 provenance checks. The real shipped bake path completed
   10/10 for each OS with `-r 1.2.2`, publishing archive entries
   `iocrunner-rocky8-20260811T013023Z.qcow2` and
   `iocrunner-debian13-20260811T013614Z.qcow2`. Fresh consumers reached `READY`
   at `192.168.122.150` and `192.168.122.50`. Before any deploy or tree push,
   both manifests were `root:root 644`; Rocky hash
   `fe5ca375b6801479ff8386b9a79a9b9501cd3b07a06c01978ba41ea1009940d8` and
   Debian hash
   `647067c54fa273242b3ad20d54b8cd9fc3ad621c6a32794308779c2a1debaa5f`
   each matched its working-copy sidecar; the shipped validator reported the
   provenance valid on both; retained checkout and installed runner identities
   both matched manifest commit `fd14875df5fdbfcb362d194e81bf74c1de960daa`;
   dirty counts were `0`; each `app_ioc_runner` record carried
   `requested=1.2.2 state=clean-tagged tag=1.2.2`; and the runbook fixture
   assertion printed `FIXTURES OK` on both. Local supporting bake captures are
   `work/bake-rocky8-20260811T012834Z.log` with SHA-256
   `026e9a3801da9c83a780bbaac061169038a766e1d551f77a096ecca17cbdd83b` and
   `work/bake-debian13-20260811T013351Z.log` with SHA-256
   `f1a7b252b6cb34f0691fe6fc2b031adb4827cc11ae17ccc237b63ea28551b017`;
   the milestone record above is the durable cross-machine evidence and does
   not depend on those ignored local captures.
9. Verify: the honest-red check (T2), the walk of all nineteen findings (T3),
   and blind execution on both goldens at Gate grade (T1, T4, T5). This is the
   only step whose scenario verdicts carry Gate grade, because it is the only
   one whose consumers are fresh.
   Done, 2026-08-10. The wrong-principal T2 probe ran the shipped S11 host
   driver as `opa` while requiring `opb`; the driver returned 2 and printed
   `VERDICT S11 FAIL wrong principal`, while the wrapper confirmed that the
   expected red was observed. T3 traced all nineteen findings to the landed
   driver or runbook resolution listed below. The independent T4 operator used
   only the runbook and shipped drivers, created no replacement driver, and
   completed all fourteen scenarios on each fresh golden: Debian exercised the
   anchored S11 branch and Rocky exercised the glob branch, with both final
   records reading `VERDICT RUN PASS 14 scenarios: pass=14 fail=0
   missing=none`. Each retained blind-run directory contains 112 files under
   `work/`. T5 then reported matching clean source and remote status on both
   hosts and an exact five-entry exclusion-set match. T6 drove all twelve real
   suite invocations from the clean control commit `e659097`; every invocation
   returned 0 and emitted its complete records, while the canonical aggregate
   remained red on Rocky's six S29 SKIP and four S06 NA records. That aggregate
   red remains a release-gate result; completing M5 records that the shipped
   drivers measured and reported it correctly, not that the release gate is
   green.

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
| T6 | Suite-driver execution | Run the shipped suite driver on both goldens and compare its host logs, run-status records, verdicts, and normalized cross-host output with the six direct shipped-suite paths | Both goldens | Each host records six successful suite invocations, 612 TEST and 165 STEP records, six final PASS SUITE records, the canonical verdict for its state vector, and the complete normalized cross-host difference set |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-10 | Fresh Debian 13 and Rocky 8 goldens, shipped host drivers at `e659097` | Pass | All L1-L3 and S1-S11 verdicts passed on both hosts. Debian used the anchored S11 branch; Rocky used the glob branch. Both final records report 14 passed, zero failed, and none missing. Retained evidence: `work/gate-run-20260811T021737Z/` and `work/gate-run-20260811T021547Z/`. |
| T2 | 2026-08-10 | Debian 13 golden, shipped S11 host driver at `e659097` | Pass | The deliberate wrong-principal invocation returned 2 and printed the required S11 FAIL verdict; the assertion wrapper returned 0 only after observing both. Evidence: `work/m5-t2-20260811T015959Z/`. |
| T3 | 2026-08-10 | Clean working tree at `e659097` | Pass, 19 of 19 traced | The trace below maps every finding to current shipped code, current runbook text, or the named text-resolution commit; no finding is closed by an unverified assertion. |
| T4 | 2026-08-10 | Independent operator, fresh Debian 13 and Rocky 8 goldens | Pass | The operator received the runbook and shipped drivers without the prior answers, created or edited no driver or product file, and completed both fourteen-scenario runs. The retained `run-all.log` SHA-256 values are `aa6d639cb4581f301aef54fbba803e76fae1c4fb2a69e7d4b11ee72cdbb77dac` for Debian and `e1cc3e6a18aa08409830b7310ed84251a0925e51aa3059143d7e744cf6d482d3` for Rocky. |
| T5 | 2026-08-10 | Clean control tree and both fresh goldens at `e659097` | Pass | On each host, source status, remote status, and their diff were empty. The shipped-driver and source exclusion lists each contained the same five entries and their diff was empty; no one-sided `?? .claude/` appeared. Evidence: `work/m5-t5-debian-20260811T020233Z/` and `work/m5-t5-rocky-20260811T020251Z/`. |
| T6 | 2026-08-10 | Debian 13 and Rocky 8 goldens at remote and deployed `e659097`; clean control `e659097` | Pass for driver provenance and execution; release gate remains red on Rocky state | The executed driver and evidence snapshot both have SHA-256 `86205ec1e80ddfcc3709856c15fa1dd41a650991a3f06b922a9c3b3639a6596d`; `control.status` is empty. All twelve real suite invocations returned 0. Each host log contains 612 TEST, 165 STEP, and six final PASS SUITE records. Debian returned `SUITES OK (6 blocks, 612 checks, na=0)`; log SHA-256 `74062b2a97d6f5b280a5001d93a7a6e17dd1918105457aa0cf9133a09146c219`. Rocky returned the canonical state-vector failure with six S29 SKIP and four S06 NA records, zero FAIL and zero SCRIPT_ERROR; log SHA-256 `8e9c5e2b1a869f75f2610def2eaf7588402cab94716740f8847a6c9f93a6bc4d`. `cross-host.diff` contains 56 lines and SHA-256 `6e35974e9c7c8670d3dba3bc4819505f12540dcddc0ce8553134f71dd4343652`. Evidence: `work/gate-suites-20260811T020336Z-261435/`. |

#### Finding Traceability

| # | Current Resolution |
| --- | --- |
| 1 | `gate/drivers/push.bash` lines 22-44 derives the exclusion set from the source and emits source and remote status. T5 compared both outputs and passed on both goldens. |
| 2 | `gate/RUNBOOK.md` lines 350 and 353-359 require the `obs` account and group presence. |
| 3 | `gate/RUNBOOK.md` lines 101-112 sends a failed required precondition to the Check grade when its remedy is outside the current scope. |
| 4 | Driver location fixes the calling side; `gate/RUNBOOK.md` lines 986-995 and `gate/drivers/control/lib.bash` lines 2-8 state the convention. |
| 5 | `gate/drivers/identities.bash` lines 25-57 fixes the scenario identities and roles. |
| 6 | `gate/RUNBOOK.md` lines 281-325 compares retained and installed identities with the manifest commit. |
| 7 | `gate/drivers/control/suites.bash` lines 187-212 owns the fused six-run capture path; `gate/RUNBOOK.md` lines 484-530 specifies its invocation and evidence. T6 exercised the real path. |
| 8 | `gate/RUNBOOK.md` lines 170 and 173-179 places `.prevowner` guidance on the listing that can display it. |
| 9 | `gate/RUNBOOK.md` lines 520-522 names the remote log, and lines 631-639 name the control-host evidence path. |
| 10 | `gate/drivers/control/s9.bash` lines 22-67 wraps the S9 root half with its host and principal changes. |
| 11 | `gate/RUNBOOK.md` lines 1144-1176 names both payload locations; the shipped cleanup and leftovers drivers enforce the check. |
| 12 | `gate/RUNBOOK.md` lines 128-155 gives the libvirt domain rule and commands. |
| 13 | `gate/RUNBOOK.md` lines 909-920 distinguishes the literal `^@` pair from a rendered control byte. |
| 14 | `gate/RUNBOOK.md` lines 922-935 limits the anchored measurement to the affected closing-message line. |
| 15 | Commit `94223e2` corrected the observed skip and its cause; the later canonical form in `gate/RUNBOOK.md` lines 538-541 rejects any SKIP rather than preserving that example. |
| 16 | `gate/RUNBOOK.md` lines 667-680 determines the S11 host branch before the deploy read that depends on it. |
| 17 | `gate/RUNBOOK.md` lines 507-512 state the measured runtime and 10-minute operator bound; `gate/drivers/control/suites.bash` lines 195 and 207 record and validate each elapsed result. |
| 18 | `gate/drivers/control/lib.bash` lines 88-112 and `gate/drivers/host/gate-lib.bash` lines 48-52 require absolute capture paths. |
| 19 | `gate/drivers/push.bash` lines 19-20, `gate/drivers/control/lib.bash` lines 24-30, and `gate/drivers/control/suites.bash` line 30 apply the SSH hardening. |

#### Closure Evidence

- Driver and runbook implementation: commits `1ee17fa`, `368964f`, `bdebdca`,
  `94223e2`, `61eea12`, `2d0288c`, and `ed94cc3`.
- Fresh-golden baseline and acceptance: commits `2eede46` and `e659097`.
- Verification: T1 through T5 passed on both fresh goldens where specified. T6
  passed its driver provenance and execution contract while preserving the
  Rocky canonical aggregate failure. The release gate therefore remains red;
  M5 does not waive or reclassify it.
- Local evidence needed for replay is retained under the `work/` paths named in
  the verification table. The durable verdicts, hashes, and traceability map
  are recorded here so they remain available across machines.
- GitHub issue #134 received the completed projection and closed on 2026-08-10.
  Its live body SHA-256 matched the reviewed draft at
  `cd82e7fdeac4bfdbc8ec352aff5d854e730d7d78d5e63ea79763f29c7392bc66`;
  labels, milestone, and assignee matched the projection.

#### GitHub Projection

Title: Ship the gate's scenario drivers as repository assets
Labels: tests, docs, P2-medium
GitHub Milestone: 1.2.3
Observed State: closed
Observed Labels: P2-medium, docs, tests
Observed Milestone: 1.2.3
Observed Assignee: jeonghanlee
Observed Body SHA-256: cd82e7fdeac4bfdbc8ec352aff5d854e730d7d78d5e63ea79763f29c7392bc66
Last Compared: 2026-08-10T21:54:23-07:00

### M6 - The suite verdict cannot see a skip

Origin: the conceptual-integrity sweep of 2026-08-02, run against the gate after
M5's step 6
Identity History: none
GitHub Issue: 135, https://github.com/jeonghanlee/epics-ioc-runner/issues/135
Status: Complete

#### Summary

Before M6, `gate/RUNBOOK.md` said `A skip is not a pass.` while its suite
verdict counted `Failed` and `Script Errors` and nothing else. A skipped step
was invisible, so a run that dropped four checks scored identically to one
that ran them.

This is not a new class. The same document already records the same defect on a
different axis: a truncated log once printed `SUITES OK (1 blocks)`, and the
repair was to count the blocks. The skip axis received prose instead of a
count, and that prose could be missed.

Measured: debian13's local lifecycle reports 82/82 with M19.T1, M19.T2, M19.T3
and the M19 teardown absent, in both source and installed mode. rocky8 reported
94/94 with them present. The former verdict said `SUITES OK` for both.

#### Scope

- The suite verdict command in `gate/RUNBOOK.md`, in both the gate step and the
  driver-forms copy, so the two do not drift.
- The machine-readable records produced by M8 from the same ledger as the
  human summary. The verdict reads declared identities and terminal states
  from those records; it does not scan body prose.
- The evidence format, so a recorded run carries what was skipped beside the
  counts rather than only the counts.

Out of scope: making the skipped checks run, which is M7; the suites' own
reporting format and ledger, which M8 produces before this consumer runs.

#### Completion Criteria

- The verdict does not print a plain `SUITES OK` for a log carrying a skip.
- A run with a known skip and a run without are distinguishable from the M8
  machine-readable records and the verdict line derived from them.
- The driver-forms copy of the command and the gate step's copy are the same
  command.
- Every cross-host terminal-state difference is enumerated from declared check
  and STEP records, not inferred from prose or summary-total subtraction.

#### Dependencies And Decisions

- D1 as amended 2026-08-02: this is documentation work and needs no exception,
  but it takes the formal route regardless.
- D14 and M8 define the producer-consumer boundary. M6 retains its observed
  skip inventory as producer input, but its implementation follows M8 and
  consumes only M8's machine-readable records. M8 completed and issue #137
  closed on 2026-08-10, so M6 implementation step 2 is executable.
- M7 is the other half. M6 makes a skip visible; M7 removes the one skip that
  should not be happening. Neither substitutes for the other.
- Ordering, owner-approved 2026-08-03: M6 runs before M7's golden-VM
  verification, so the one VM run drives M7's T1 and T2 under the new verdict
  and confirms it live. M6's step 1 does not need M7's skip to still exist:
  the pre-fix logs of 2026-08-02 carry the real skip form.

#### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner decision in session, 2026-08-03; amended by owner
decision 2026-08-05 to consume M8 records rather than scan log prose
Implementation Authorization: owner decision in session, 2026-08-03; amended
by owner decision 2026-08-05. Canonical commit `15d528ad` records the settled
step 2 behavior: reject any nonzero `SKIP`, `FAIL`, or `SCRIPT_ERROR` state,
while `NA` remains nonfatal, and do not scan human-readable body prose.
Superseded Plan Artifacts: none

1. Read a real suite log from each golden and record how a skip is actually
   printed, per suite. The form is not assumed. Done 2026-08-03 — the log
   inventory and the step 1 findings below.
2. After M8 emits the accepted machine-readable records, extend the verdict to
   validate the declared suite and check identities and reject any nonzero
   `SKIP`, `FAIL`, or `SCRIPT_ERROR` state without scanning body prose.
   Implemented 2026-08-10 in `gate/RUNBOOK.md`. The canonical M8
   execution-identity SHA-256 now rejects a missing or substituted identity
   before the vector verdict can print `SUITES OK`; T1 executed on both
   goldens on 2026-08-10.
3. Apply one command to both `gate/RUNBOOK.md` locations: the suite gate under
   `Required to continue` and the copy under `Driver forms`.
   Implemented 2026-08-10; T2 confirms that both compound-command copies are
   exact.
4. Enumerate every cross-host identity and terminal-state difference. Done
   2026-08-10: the corrected normalized TEST/STEP comparison enumerated the
   two local-lifecycle S29 STEP vectors and six TEST states, plus the
   system-infra S06 STEP vector and four TEST states.

Development evidence re-observed 2026-08-10T14:24:19-07:00 through SSH with
`stat`, `sha256sum`, and machine-record counts:

- debian13 log: SHA-256
  `9f1db70b9034f43e4b4346cb37b2b7b7a8ccbaa947acf6cbe0e26fc471bcd8ee`;
  612 TEST, 165 STEP, six SUITE records; all 612 TEST states are `PASS`.
  The corresponding status has SHA-256
  `2c7199ce7ed8f91005630df7502c6292da5a62e0b24c4a9f56ca48163ca1c738`.
- rocky8 log: SHA-256
  `944374e563128a16fedac4721c70a746a118273a0bf957c2c4b8728161c682df`;
  612 TEST, 165 STEP, six SUITE records; 602 `PASS`, six `SKIP`, and four
  `NA`. The corresponding status has SHA-256
  `93f68f6800f77f0610b2e20d96dd2f5bc9965f1278ab984a08dd63eeafde6b0b`.
- These hashes identify Check-grade historical evidence only. They are not T1
  inputs and do not replace the fresh logs produced through the shipped suite
  commands during T1.
- F1 repair evidence, re-observed 2026-08-10T15:22:29-07:00: the current
  compound command read the retained real M8 logs without modifying either
  host. Debian matched the canonical execution-identity SHA-256 and returned
  `SUITES OK (6 blocks, 612 checks, na=0)` with exit 0. Rocky matched the same
  identity SHA-256, printed its six `SKIP` and four `NA` TEST records, and
  returned `SUITES FAIL blocks=6 checks=612 steps=165 skip=6 fail=0 na=4 err=0
  invalid=0` with exit 1. Changing one TEST identity only at the verdict's
  external input boundary produced a different SHA-256, printed
  `SUITES FAIL identity_sha256=... expected=...`, returned 1, and printed no
  `SUITES OK`. The third-person follow-up found F1 resolved with no new blocking
  finding, and the second-person reader pass found the replacement values,
  command sequence, failure output, and next action unambiguous. This is
  Check-grade repair evidence and does not replace T1.

Step 1 execution context, observed 2026-08-03 from top over SSH:

- Both iocrunner testbeds are running: `testbed-debian13-iocrunner-server`
  (192.168.122.50) and `testbed-rocky8-iocrunner-server` (192.168.122.150),
  both up since 2026-08-01.
- The prior logs were transient development evidence. No current or future M6
  step depends on their paths or availability; T1 captures fresh logs from the
  shipped suite commands.
- The trees were at `1ee17fa` on debian13 and `57c2c3d` on rocky8 before the
  M7 fixes, which made their observed skip forms representative of step 1.
- Consequence for M7's T2: the recorded rocky8 local-lifecycle total of 94 of
  94 is the pre-fix comparison baseline.

Step 1 findings, observed 2026-08-03 from real suite logs on both testbeds
(debian13 regenerated its log that day on the pre-fix tree at `1ee17fa`:
local lifecycle, 82 of 82, suite exit 0, the finding's condition reproduced):

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
  test.` Its 94 of 94 green also meant "of what ran". A verdict applied to
  that recorded terminal-state vector must reject it.
- A third form exists: `[INFO   ] SKIP: deployed sudoers uses glob
  fallback; regex-deny probe does not apply.` followed by a `[ PASS ]`
  line asserting the skip. Under the settled step 2 rule, the body text is not
  scanned; only the corresponding machine-readable terminal state governs the
  verdict, and `NA` remains visible and nonfatal.
- Real skip forms observed so far: step-level `[WARN   ] ... skipping ...`
  (the load-bearing one), probe-level prose `... will be skipped.`, and
  the `[INFO   ] SKIP:` does-not-apply form.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Verdict execution | Run the real suite commands named by `gate/RUNBOOK.md` on both goldens, capture fresh machine-readable logs, then apply the verdict to both logs | debian13 and rocky8 | An all-`PASS` vector can produce plain `SUITES OK`; a vector carrying `SKIP` cannot; `NA` remains nonfatal and visible |
| T2 | Drift check | Compare the gate step's copy of the command against the driver-forms copy | Working tree | They are the same command |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-10T15:51:51-07:00 | debian13 and rocky8 goldens, source and installed runner identity `61eea12` | Pass, after correction | The shipped runbook commands produced fresh six-suite logs under run `m6-t1-20260810T223432Z`; all twelve suite invocations exited 0 and each host emitted 612 TEST, 165 STEP, and six final PASS SUITE records. Debian emitted 612 PASS, returned `SUITES OK (6 blocks, 612 checks, na=0)` with exit 0, and its log/status SHA-256 values are `11a38a5e9c8a0e0f2f4f5850763415cfc95b2f47528d3cb6472c7711514521b2` and `9b0c96233c4d8bf3d90825522a8e51fd1358b221b18fb7199fa4d684295488e8`. Rocky emitted 602 PASS, six SKIP, and four NA, printed all ten non-PASS TEST records, and returned `SUITES FAIL blocks=6 checks=612 steps=165 skip=6 fail=0 na=4 err=0 invalid=0` with exit 1; its log/status SHA-256 values are `dc2b55cfaa28c3aed1b701e13492d6f7aecddc710c08a7687bd2ffd78d7192fb` and `69c3a7d6fb97a08774cc1af432c0964f7c3e2623e66303c2af8a1a2cb1029428`. The first normalized comparison exposed an AWK lexical ambiguity: `SUBSEP ++n[r]` incremented `SUBSEP`, both producers emitted zero rows, and `diff` returned 0. Splitting it into `n[r]++; rec[r SUBSEP n[r]]=...` in all four producer branches passed extracted `bash -n`; the shipped command then returned 1 with a 56-line enumeration of the two S29 STEP and six TEST PASS-to-SKIP differences and the S06 STEP and four TEST PASS-to-NA differences. Local raw evidence is retained under `work/m6-t1-20260810T223432Z/`; the normalized diff SHA-256 is `330cbd50f120623429135829007003c9ed32e20c3518dbd4388e1d4e95f3bf16`. |
| T2 | 2026-08-10T15:22:29-07:00 | Working tree | Pass | The suite-gate and Driver forms compound-command blocks are byte-identical. The canonical identity precheck uses the M8 normalization and SHA-256; the extracted command passes `bash -n`; the vector AWK rejects empty input with exit 1 and `SUITES FAIL blocks=0 checks=0 steps=0 skip=0 fail=0 na=0 err=0 invalid=6`; the normalized cross-host comparison passes `bash -n`; stale body-prose verdict forms are absent; `git diff --check` passes. The retained real-log and external-input mutation observations are recorded above as Check-grade repair evidence and do not replace T1. |

#### Closure Evidence

Implementation in commit `61eea12` and T1/T2 verification are complete. GitHub
issue #135 was observed closed with all four completion criteria checked at
2026-08-10T22:58:28Z. No external condition remains; M6 is Complete.

#### GitHub Projection

Title: The suite verdict cannot see a skip
Labels: docs, tests, P2-medium
GitHub Milestone: 1.2.3
Observed State: closed
Observed Labels: P2-medium, docs, tests
Observed Milestone: 1.2.3
Observed Assignee: jeonghanlee
Observed Updated At: 2026-08-10T22:58:28Z
Observed Body: current; all four completion criteria are checked, #137 is recorded closed, T1/T2 results match the canonical detail, and closure cites commit `61eea12`
Last Compared: 2026-08-10T15:58:28-07:00

### M7 - The suite tool probe disagrees with the runner

Origin: the same sweep of 2026-08-02, measured on both goldens
Identity History: none
GitHub Issue: 136, https://github.com/jeonghanlee/epics-ioc-runner/issues/136
Status: Complete

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
  verdict, so the one golden-VM run verifies both milestones. T1 through T3
  passed by 2026-08-10, and #136 closed after its body was synchronized with
  those results.

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
   steps run. Done 2026-08-10 through the shipped suite driver; S14, S15, S16,
   and S34 recorded 10, 4, 3, and 3 PASS checks in each mode.
4. Drive it on rocky8 and confirm nothing changed there. Done 2026-08-10
   through the same driver; the four steps recorded the same PASS counts in
   each mode. The three S29 user-journal skips per mode are unrelated to this
   milestone and remain visible in the host verdict.

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
longer skips on the shape that produced the finding. T1 and T2 later ran on
the golden VMs and are recorded below.

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
probe. Before the fix this host skipped every M19 step. This was the dev-host
tier, not T1. The later golden runs are recorded in T1 and T2 below and include
the system suite carrying the decision 3 edit.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Suite execution | Run the local lifecycle in both modes on debian13 | debian13 | The M19 skip is absent and the four steps execute |
| T2 | No-regression | Run the same on rocky8 | rocky8 | The totals are unchanged from before |
| T3 | Pairing walk | Walk every skip-guarding probe against the runner resolver for the same tool | Working tree | No pair disagrees |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-10T17:01:44-07:00 | Debian 13 golden at `61eea127`, local lifecycle source and installed | Pass | Both real local lifecycle runs reported 125 PASS of 125 with zero SKIP, FAIL, NA, or SCRIPT_ERROR. S14, S15, S16, and S34 executed in both modes with 10, 4, 3, and 3 PASS records per mode. Evidence: `work/gate-suites-20260811T000144Z-85203/vmadmin_192.168.122.50.log`. |
| T2 | 2026-08-10T17:01:44-07:00 | Rocky 8 golden at `61eea127`, local lifecycle source and installed | Pass for M7; unrelated S29 skips remain | Both real local lifecycle runs executed all M19 replacement steps: S14, S15, S16, and S34 recorded 10, 4, 3, and 3 PASS records per mode. Each suite total was 125 with 122 PASS and three S29 user-journal SKIP records; none concerns tool resolution. Evidence: `work/gate-suites-20260811T000144Z-85203/vmadmin_192.168.122.150.log`. |
| T3 | 2026-08-10T18:01:44-07:00 | Working tree at `0d9f78e` | Pass | Direct current-tree pairing walk found exactly three runner tool resolvers: `resolve_logrotate_tool`, `resolve_con_tool`, and `resolve_procserv_tool`. Both lifecycle logrotate probes use the runner's `/usr/sbin`, `/sbin`, `/usr/bin`, then PATH order and route every guarded invocation through the resolved path. The local and system `con` checks use the runner's applicable absolute lists and deliberately exclude its `socat` and `nc` fallbacks because they assert `con` itself. No suite has a procServ skip probe. All other tool-driven skips concern tools with no runner resolver. No relevant resolver or probe logic changed after `9f6a3e9`. |

#### Closure Evidence

- Implementation commits `9f8d01c` and `9f6a3e9` are landed, and T1 through
  T3 pass. GitHub issue #136 was synchronized and observed closed at
  2026-08-10T18:05:17-07:00.

#### GitHub Projection

Title: The suite tool probe disagrees with the runner's resolution
Labels: bug, tests, P2-medium
GitHub Milestone: 1.2.3
Observed State: closed
Observed Labels: P2-medium, bug, tests
Observed Milestone: 1.2.3
Observed Assignee: jeonghanlee
Observed Body: current; all four completion criteria are checked, T1 through T3 match the canonical detail, and closure cites `9f8d01c` and `9f6a3e9`
Observed Updated At: 2026-08-11T01:05:17Z
Last Compared: 2026-08-10T18:05:42-07:00

### M9 - Source regression suite separation

Origin: M8 architecture review on 2026-08-04 found that
`test-system-infra.bash` combines source-regression checks with
installed-conformance checks
Identity History: none
GitHub Issue: 138, https://github.com/jeonghanlee/epics-ioc-runner/issues/138
Status: Complete

#### Summary

`test-system-infra.bash` previously combined two verification targets. S01
through S06 now inspect the configured host after installation, while S07
through S14 exercise setup, live runner, version injection, Git fixture, and
test path-safety behavior from the dedicated source-regression suite. A result
from one category does not establish the other, so each suite now has one
execution context.

#### Scope

- Keep S01 through S06 in system infrastructure as
  `installed-conformance`: actual accounts, paths, ownership, permissions,
  sudoers policy, systemd units, logrotate configuration, and policy behavior
  on the configured host.
- Move S07 through S14 into `tests/test-source-regression.bash`, suite ID
  `source-regression`, without replacing shipped setup, live runner, injection,
  Git, or test-script paths. Filesystem writes may be redirected only at their
  outer boundary to isolated temporary targets.
- Account for every existing assertion and prerequisite in the migration
  inventory, then assign exactly one D13 disposition: `retain`, `replace`, or
  `remove`. A replacement names its valid evidence path; a removal names the
  redundancy or invalid target and requires owner approval.
- Add the exclusive `run-all-tests.bash --source-regression` selection. Reject
  combinations with `--local`, `--system`, `--source`, or `--installed`, and do
  not include this suite in the post-install `--system` selection.
- Run the suite through `sudo bash`, retain the invoking identity in
  `SUDO_USER`, and drop to that identity only for the existing source and Git
  operations.
- Do not create a separate `test-harness-integrity` suite. The S08 test-script
  path guard stays in the single source-regression suite under the same
  source-tree validity boundary as S07 through S14.
- Classify every moved check on all three axes in D12. Use
  `tests/REPORTING_CONTRACT.md` for category and check kind, and
  `tests/README.md` "Test Classification" for test method. Do not treat direct
  state inspection or hand-built reproduction as real-path behavior evidence.

Out of scope: changing installer behavior; changing installed system policy;
the M8 terminal-state reporter; the M6 gate consumer; making an existing
skipped lifecycle check run.

#### Completion Criteria

- System infrastructure contains only post-install
  `installed-conformance` checks. It does not inspect product source files or
  require Git metadata; its test code and shared test library remain normal
  invocation dependencies.
- The dedicated `source-regression` suite owns all former S07 through S14
  checks and executes the real shipped script paths against isolated outer
  filesystem targets.
- The migration inventory accounts for every current assertion and prerequisite
  with one accepted D13 disposition and no silent omission. Every retained or
  replacement destination records its identity, category, check kind, test
  method, and decision reason against the D12 references.
- Direct invocation and `run-all-tests.bash --source-regression` are documented
  and implemented; post-install `--system` does not invoke source regression.
- The source-regression result uses `suite=source-regression`, `scope=system`,
  and `runner=source`; unsupported selector combinations fail before suite
  execution.
- No `test-harness-integrity` suite or additional result is created.
- Every behavior-verification result executes the real shipped path. No direct
  state inspection or hand-built reproduction is accepted as behavior evidence.
- Both suites pass their accepted real-path verification on Debian 13 and
  Rocky 8 before M8 begins.

#### Dependencies And Decisions

- D9 defines the category boundary, D10 fixes the single-suite shape, D12 fixes
  the three classification axes, D13 fixes the migration dispositions, and D14
  fixes the reporting boundary and M9-to-M8 handoff. They require this
  milestone to complete before M8.
- D11 removes the unfinished M8 reporter prototype from the active test paths
  while M9 runs. M9 starts from local `HEAD`; the local-only snapshot is not an
  implementation input for this milestone.
- GitHub issue #138 under milestone `1.2.3` satisfies D1. Its open state,
  labels, milestone, and assignee were observed on 2026-08-05 after creation.
- Owner decision, 2026-08-04: use one `tests/test-source-regression.bash` suite,
  suite ID `source-regression`, and an exclusive
  `run-all-tests.bash --source-regression` selection outside the post-install
  `--system` group. Do not add a test-harness suite.
- Owner decision, 2026-08-05: classify every M9 check using D12. Test method
  remains a check-level property and does not split the accepted suite.
- Owner decision, 2026-08-05: M9 step 1 reviews every current assertion and
  prerequisite through D13 rather than preserving the current count. M9
  records destination metadata but leaves ledger and output implementation to
  M8 under D14.
- Owner decision, 2026-08-06: combine the former suite-scaffold step and check
  move into one atomic step 2. A P00-only suite can print source-regression
  success while the accepted S07 through S14 inventory still runs elsewhere,
  so that intermediate state is not a completed implementation. New step 3
  re-reviews the complete suite and its output before step 4 begins.
- Owner decision, 2026-08-06: S07 isolates Git context resolution by comparing
  the deployed stamp's hash after removing an optional `-dirty` suffix with the
  checkout's short `HEAD`. S10 remains the independent owner of clean and dirty
  suffix behavior.
- M9 step 1 completed 2026-08-05: the accepted inventory maps all 36 current
  assertions and all eight validity prerequisites to 29 `retain`, seven
  `replace`, and eight `remove` dispositions with no duplicate source or
  destination identity.
- M8 depends on M9 and must re-inventory the resulting suite set rather than
  preserving the current four-suite assumption.

#### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner, 2026-08-04, amended after conceptual-integrity review
to one source-regression suite and no test-harness suite; amended 2026-08-06 to
make suite creation and check movement one atomic step 2 and add the step 3
review gate
Implementation Authorization: owner, 2026-08-05, step 1 and the former suite
scaffold; expanded by the owner's 2026-08-06 instructions through the complete
amended steps 2 through 5, including the two-OS real-path verification and
result synchronization.
Superseded Plan Artifacts: none

1. Inventory every assertion and prerequisite in S07 through S14. Record its
   current identity, verification target, check kind, test method, and evidence
   validity; then review it as `retain`, `replace`, or `remove`. For `retain`
   and `replace`, record the destination STEP, check identity, category, check
   kind, test method, and reason. For `remove`, record the owner-approved reason.
   Do not close this step until every row has one accepted disposition.
   Completed 2026-08-05 in `tests/SOURCE_REGRESSION_INVENTORY.md`.
2. In one atomic implementation, add `tests/test-source-regression.bash` with
   suite ID `source-regression`, the exclusive
   `run-all-tests.bash --source-regression` selection, and the accepted
   root-to-`SUDO_USER` execution boundary; move every accepted
   source-regression check without rewriting its product path; and retain S01
   through S06 as the system-infrastructure suite. Do not record, commit, or
   present the P00-only intermediate state as a completed suite.
   Completed 2026-08-06. The implementation has 36 unique accepted destination
   IDs, no removed destination, and passed the complete dev-host source run at
   36 of 36 with zero failures and zero script errors. Syntax, ShellCheck, diff
   format, non-root rejection, and all four forbidden selector combinations
   also passed their checks.
3. Re-review the complete source-regression suite against the accepted
   inventory and observed output. Confirm that every retained or replacement
   destination is present once, every removal is absent, system infrastructure
   contains only S01 through S06, and no success result can omit the accepted
   source-regression checks. Step 4 does not begin until this review is accepted.
   Completed 2026-08-06. The review reconciled all 36 destination IDs, confirmed
   all eight removals absent, and confirmed that system infrastructure contains
   only S01 through S06. It found and corrected three result-sensitivity defects:
   real-command exit status was discarded in several checks, the S11 no-change
   path counted the installed basename instead of its isolated target basename,
   and the S09 fixture inherited the invoking user's Git hook template. Syntax,
   ShellCheck, diff format, and non-root rejection passed after correction. The
   complete orchestrated real-path run then passed 36 of 36 with zero failures
   and zero script errors and emitted the final selected-suite success result.
4. Update suite documentation, catalog ownership, and orchestrator collection
   for the accepted invocation.
   Completed 2026-08-06. `tests/README.md` now declares the source-regression
   selector and direct invocation, maps all five suites to their canonical
   categories, assigns moved behavior to source regression and installed state
   to system infrastructure, and separates lifecycle NFS behavior from the
   root-to-`SUDO_USER` source boundary. The existing `REPORTING_CONTRACT.md`
   suite matrix already matched that ownership. `gate/RUNBOOK.md` collects the
   new suite through its exclusive dispatcher selection and requires six suite
   blocks per host. Dispatcher help, document links, code fences, ASCII
   additions, and diff format passed their checks.
5. Verify both resulting suites through the real shipped paths on Debian 13
   and Rocky 8, then review the assertion inventory for omissions.
   Completed 2026-08-06 on fresh consumers created from the 2026-08-03
   ioc-runner goldens. The first Rocky 8 run exposed two test-harness
   assumptions: the direct suite retained a relative self-path across a working
   directory change, and S10 selected the first version line through an
   early-closing `head` pipeline under `pipefail`. Commit `75f5073` retains a
   lexical absolute suite path without canonicalization and consumes the full
   real `-V` response before selecting its first line. On the committed clean
   tree, dispatcher and direct source-regression runs each passed 36 of 36 on
   both OS families; system infrastructure passed 25 of 25 on Rocky 8 and 26
   of 26 on Debian 13; and all four unsupported selector combinations exited 1
   before suite execution on both hosts.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Assertion inventory | Map every current S07 through S14 assertion and prerequisite to one D13 disposition and classify every retained or replacement destination on all three D12 axes | Working tree | Every current row is accounted for; each retained or replacement check names one valid destination and reason, and each removal carries an owner-approved reason |
| T2 | Source regression | Run the dedicated suite through shipped setup, live runner, injection, Git, and test-script paths with only outer filesystem writes redirected | Debian 13 and Rocky 8 source trees | Every applicable source regression executes and reaches its expected result without claiming installed-host conformance |
| T3 | Installed conformance | Run system infrastructure on a configured host without inspecting product source files or Git metadata | Debian 13 and Rocky 8 installed hosts | Every S01 through S06 requirement is evaluated against actual installed state and no source-regression check runs |
| T4 | Boundary check | Inspect both suite catalogs and execution logs against `tests/REPORTING_CONTRACT.md` and `tests/README.md` "Test Classification" | Both goldens | Each suite owns one primary category, every check records one valid method, and only real-path execution supports behavior verification |
| T5 | Orchestrator collection | Invoke `run-all-tests.bash --source-regression`, compare it with direct invocation, and try every rejected selector combination | Both goldens | The source-regression result is collected once with the accepted dimensions, and every unsupported combination fails before suite execution |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-05 | Working tree | Pass | `tests/test-system-infra.bash` contains 36 S07 through S14 `verify_state` calls; the inventory maps those assertions and eight validity prerequisites to 44 unique source rows and 36 unique retained or replacement destination identities: 29 `retain`, seven `replace`, and eight owner-approved `remove`; every accepted destination carries STEP, check ID, category, check kind, test method, and reason; `git diff --check` and `git diff --no-index --check -- /dev/null tests/SOURCE_REGRESSION_INVENTORY.md` passed |
| T2 | 2026-08-06 | Debian 13 and Rocky 8 source trees at `75f5073` | Pass | The exclusive dispatcher and documented relative-path direct invocation each executed the real setup, live runner, injection, Git, and test-script paths and reported 36/36, zero failures, and zero script errors on both OS families |
| T3 | 2026-08-06 | Fresh Debian 13 and Rocky 8 installed hosts | Pass | Full setup reported 9/9 on Debian 13 and 10/10 on Rocky 8; system infrastructure then reported 26/26 and 25/25 respectively, with zero failures and zero script errors; Rocky 8 took the documented sudo glob fallback branch and no source-regression check ran in either infrastructure invocation |
| T4 | 2026-08-06 | Both ioc-runner goldens | Pass | Source-regression output carried `suite=source-regression`, `scope=system`, and `runner=source`; system infrastructure executed only the S01 through S06 installed-state catalog; all behavior claims came from the shipped paths on the two fresh consumers |
| T5 | 2026-08-06 | Both ioc-runner goldens | Pass | Dispatcher and direct results matched at 36/36; combinations with `--local`, `--system`, `--source`, and `--installed` each exited 1 with the selector-boundary error before suite execution on both hosts |

#### Closure Evidence

- `c5b5058` separates the suites and updates their documentation and gate
  collection.
- `75f5073` removes nondeterministic version-output collection and preserves
  the documented direct invocation without introducing path canonicalization.
- Fresh consumers used working golden manifests baked on 2026-08-03; each
  in-image manifest hash matched its control-host sidecar before the current
  tree was installed.

#### GitHub Projection

Title: Separate source regression from post-install infrastructure verification
Labels: P2-medium, refactor, tests, area/architecture
GitHub Milestone: 1.2.3
Observed State: closed
Observed Labels: P2-medium, refactor, tests, area/architecture
Observed Milestone: 1.2.3
Observed Assignee: jeonghanlee
Last Compared: 2026-08-06

### M8 - Suite skip-reporting policy

Origin: M6's step 1 findings of 2026-08-03 in this register, opened at the
owner's direction the same day
Identity History: none
GitHub Issue: 137, https://github.com/jeonghanlee/epics-ioc-runner/issues/137
Status: Complete

#### Summary

Before M8, the suites derived their apparent result from assertion counters
and human-readable body text. Conditional branches, warnings, skips, and early
returns could therefore remove checks from the denominator without producing
a terminal state. M8 requires the test code to define the state of every check
before the shared reporter aggregates it; all five producer suites now use
that path. The fixed catalog remains 487 checks; P005 now also requires one
suite execution state that accounts for cleanup and finalization after the
check vector closes.

#### Scope

- A Git-style closed result state is defined in the test code: `PASS`,
  `FAIL`, `SKIP`, `NA`, and `SCRIPT_ERROR`.
- Every test-related script under `tests/` uses the same report envelope;
  `run-all-tests.bash` collects suite records without inventing states.
- Every check in the resulting suite set has one canonical catalog entry with
  a stable identity, STEP owner, category, check kind, and test method.
- One shared recording path combines catalog metadata with the test-owned
  terminal state in one ledger. The human summary and machine-readable records
  are generated from that ledger, never counted independently.
- The final human summary and `SUITE` machine record carry the same suite
  execution state after all failure-producing cleanup has completed.
- Every existing `SKIP`, `WARN`, does-not-apply branch, prerequisite branch,
  and early return is classified and closed explicitly.
- The reporter validates and aggregates test-owned states; it never converts
  an unvisited check into `NA`.
- The whole suite set is re-verified on both goldens after the state-first
  implementation, with OS differences recorded as explicit test-owned states.

Out of scope: the verdict command, which is M6 and consumes only M8's
accepted machine-readable records; making any other individual skipped check
run (the M7 class); the drivers under `gate/`, whose verdict convention D8
fixed.

#### Reporting model (draft, 2026-08-03 — revised by owner direction)

The owner's requirement: the output and the summary must record the state
of the test procedure exactly, the per-step records must be fine-grained,
and at release-gate time those records alone must say what state the
product is in. The catalog supplies identity, category, check kind, and test
method; the recording path adds the observed state and detail once. Four
output layers follow from that one ledger:

1. **A closed state set per check.** Every check terminates in exactly one
   of: `PASS`, `FAIL`, `SKIP` (was meant to run and did not, with the
   reason), `NA` (examined and found not applicable, with the reason), or
   `SCRIPT ERROR`. A check that ends in none of these is itself a suite
   defect — silence is not a state. This gives every suite a denominator:
   the count of checks it owns, independent of what a particular run
   executed.
2. **A step outcome line per STEP.** Each numbered STEP closes with one
   line carrying the step's identity and its complete assert tally (pass,
   fail, skip, na, script error). The difference between goldens becomes an
   enumerable list of test-owned states, not a subtraction from a total.
3. **A human summary that carries the full vector.** Generated from the ledger,
   it reports `Total`, `Passed`,
   `Failed`, `Skipped`, `Not applicable`, `Script Errors` — zero printed,
   never omitted — followed by one line per non-PASS check repeating the
   check identity, check kind, test method, state, and reason, so a reader gets
   the exceptions without scanning the body.
4. **Machine-readable records from the same ledger.** Fixed-form check and STEP
   records carry the catalog metadata, observed states, and complete vector.
   The final suite record also carries `state=<PASS|FAIL>` after cleanup and
   finalization. These records are the sole input for the separate M6 consumer;
   M8 does not implement that consumer.

This makes the producer state exact: the suite record describes the declared
inventory and every terminal state, so a total never means merely "of what
ran".

#### Producer implementation boundary

The previous implementation used a compatibility adapter that supplied fixed
numbers and synthesized states for unvisited checks. Reviewers rejected that
boundary because it does not make the test code the source of truth. The
revised implementation starts with the canonical catalog and test-owned state
definitions. The shared recording path writes one ledger, and the shared
library validates it before generating the human summary and machine-readable
check, STEP, and suite records.

The producer implementation does not modify `gate/` or the M6/#135 verdict
parser. Gate consumption of the `SUITE` records remains a separate milestone
item.

The unfinished pre-M9 reporter prototype is suspended in local Git stash
commit `f330b4e9962031de37c904ece23c653c800620c8` under D11. It is not accepted
implementation or verification evidence. After M9 completes, M8 re-inventories
the resulting suite set and compares the snapshot against that structure
before deciding which parts remain applicable.

#### Producer acceptance requirements

These are the acceptance conditions for the M8 producer. M6 owns the gate
consumer requirements.

1. Every test-related script uses the same report grammar.
2. Each suite declares one canonical catalog containing identity, STEP,
   category, check kind, and test method.
3. Every real check closes exactly once through the shared recording path.
4. The human summary and machine-readable records project the same ledger and
   reconcile without a second count.
5. Missing, duplicate, unknown, or unclosed identities produce
   `SCRIPT_ERROR`; the reporter never fabricates `NA`.
6. `Total = PASS + FAIL + SKIP + NA + SCRIPT_ERROR` and the identity set is
   invariant across supported OS and execution modes.
7. The final `SUITE state` equals the process result after cleanup and
   finalization without creating another check identity.

#### Completion Criteria

- Every test-related script uses the uniform report envelope.
- Every check has one catalog entry carrying category, check kind, and test
  method, and every observed state enters through one shared recording path.
- Every check in the resulting suite set terminates in exactly one state from the
  closed set, and a check with no state is a suite defect.
- Every existing skip, warning, does-not-apply branch, prerequisite branch,
  and early return has a named policy and explicit terminal state.
- Every suite run generates its human summary and machine-readable records from
  the same validated ledger after state completeness is verified.
- Every suite run reports one final suite execution state after cleanup and
  returns the same result as its final `SUITE` record.
- The identity set and total remain invariant across supported OS and modes.
- The state policy, report grammar, and implementation order are documented
  beside the suites.

#### Dependencies And Decisions

- M6: its step 1 enumeration is this milestone's input. Under D14, M8 produces
  the records first and M6 subsequently changes its verdict to consume them;
  M8 does not implement that consumer.
- M9: installer source regression must be separated from installed
  infrastructure conformance before M8 inventories and migrates the suite set.
- M8 gates the 1.2.3 release — owner decision 2026-08-03, accepting that
  the release moves by the cost of a tests-wide reporting change plus a
  two-golden re-run. M3's dependency row carries M8.
- Owner decision, 2026-08-06: move the three former error-handling S12 checks
  to local-lifecycle S35. Retain the real install and configuration-artifact
  checks, and replace the internal LOG_DIR reconstruction with inspection of
  the unit emitted by the real local install path.
- Step 1 completion establishes the static identity and branch mapping only.
  The owner accepted the S13 disposition on 2026-08-06: move seven real-path
  checks and one replacement real-path LOG_DIR check to local-lifecycle S35,
  and remove the namespaced LOG_DIR check duplicated by the existing S35
  artifact check.
- Owner decision, 2026-08-06: move all twelve S14 declaration and default
  checks to source-regression S15 as REQUIRED direct inspections. The suite
  reads both source files as the invoking user, and S15 performs no privileged
  product write.
- Owner decision, 2026-08-07: move all four S15 unit-template source-contract
  checks to source-regression S16 as REQUIRED direct inspections. The suite
  reads both templates through the invoking-user boundary, compares the
  normalized must-agree rows, and performs no privileged product write.
- Owner decision, 2026-08-07: move all three S16 metadata-injection source
  contracts to source-regression S17 as REQUIRED direct inspections. The suite
  reads the runner and both injectors through the invoking-user boundary and
  performs no privileged product write.
- Owner decision, 2026-08-07: replace both S18 hand-built LOG_DIR
  reproductions with real local installs in local-lifecycle S35. One install
  unsets all log overrides and `XDG_STATE_HOME`; the other sets
  `XDG_STATE_HOME`. Both inspect the emitted unit's `--logfile` path.
- Owner decision, 2026-08-07: move the S20 pipefail help-probe source rule to
  source-regression S18 as a REQUIRED direct inspection. The suite reads the
  runner through the invoking-user boundary; the check does not claim helper
  capability behavior.
- Owner decision, 2026-08-07: move three S22 IOC-name source contracts to
  source-regression S19 as REQUIRED direct inspections. Replace the finite
  21-candidate parity reproduction with normalized exact comparison of the
  extracted runner and regex-form sudoers source contracts. Normalization
  permits only equivalent ASCII letter-range order. Before step 2 begins, S33
  and S34 must receive accepted method, category, and evidence-path
  dispositions for their 29 rows.
- Owner decision, 2026-08-07: move all twenty-two S33 crash-pattern source
  contracts to source-regression S20 as REQUIRED direct inspections. The
  sixteen base-pattern fixtures evaluate the extracted regex without copying
  the exclusion pipeline; S34 owns exclusion, and local lifecycle S30 retains
  real softIoc crash behavior. Before step 2 begins, S34 must receive accepted
  method, category, and evidence-path dispositions for its seven rows.
- Owner decision, 2026-08-07: move five S34 exclusion source contracts to
  source-regression S21 as REQUIRED direct inspections. Remove two hand-built
  behavior checks already covered by real softIoc paths in local lifecycle S30.
  The pre-step-2 disposition review is complete.
- Owner decision, 2026-08-07: use both command-path protections. Step 2 makes
  the reporter resolve its own helper commands through a fixed system search
  path without changing the caller's `PATH`. Step 3 makes every root-run
  producer suite establish a fixed `PATH` for all suite commands.
- Owner decision, 2026-08-10 (D15): preserve all 487 check identities and add
  final `SUITE state=<PASS|FAIL>`. Cleanup failure is a suite execution result,
  and M6 consumes the field in its separate implementation.

#### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner, 2026-08-10, for `plan20260810_125403`
Implementation Authorization: owner, 2026-08-10, for P007 through P010 and the P006/V006 authority repair; recorded by `auth20260810_094716_codex_gpt5.md` and `auth20260810_125505_codex_gpt5.md`
Authoritative Plan Artifact: `plan20260810_125403_codex_gpt5_supersedes_plan20260810_021936.md`
Superseded Plan Artifacts: `plan20260810_021936_codex_gpt5_supersedes_plan20260807_163739.md`; `plan20260807_163739_codex_gpt5_supersedes_plan20260803_133000.md`; `plan20260803_133000_codex_gpt5.md`; proposed `plan20260803_235000_codex_gpt5.md` was never authoritative

1. Inventory all scripts under `tests/`, map every assertion and every
   conditional result branch, and assign stable test and STEP identities.
2. Define the Git-style closed state set, canonical catalog fields, shared
   recording path, ledger, and uniform report grammar. Refactor the shared
   reporter to validate test-owned states and generate both output projections;
   it must not synthesize `NA` for an unvisited check.
3. Update every producer suite script so its test code owns inventory and emits
   one explicit state for every check, including skip, NA, warning,
   prerequisite, and early-return paths.
4. Update `run-all-tests.bash` to collect uniform suite records and reject
   missing, duplicate, malformed, or unexpected records without inventing
   test states.
5. Ask all three reviewers to review the state-first implementation and
   require no blocking findings before statistics are accepted.
6. Run the current reporting method on both golden OS families and compare
   identity sets, totals, and state vectors across supported modes.
7. Reconcile the maintained check-kind and test-method definitions without
   changing catalog identities.
8. Finalize suite execution state after cleanup in the reporter and all five
   producer exit handlers.
9. Require and validate final suite state in `run-all-tests.bash`.
10. Verify both real lifecycle cleanup-failure paths, then repeat Reviewer 1
    before starting Reviewer 2 and Reviewer 3.

#### Implementation Progress

| Step | Status | Evidence |
| --- | --- | --- |
| 1 | Complete | `tests/REPORTING_INVENTORY.md` indexes 146 error-handling, 125 local-lifecycle, 87 source-regression, 36 system-infra, and 93 system-lifecycle identities. Local-lifecycle S35 owns the accepted S12, S13, and S18 real-path checks; source-regression S15 through S21 own the accepted S14 through S16, S20, S22, S33, and S34 source contracts. |
| 2 | Complete | `tests/lib/test-reporting.bash` implements the catalog, single recording path, private file-backed ledger, and ledger-derived human and machine projections. Its real shipped-library self-test passed 78/78 on Debian 13, including the accepted suite-dimension matrix and rejected check-ID-to-STEP mutations; syntax, warning-level ShellCheck, and `git diff --check` also passed. |
| 3 | Complete | All five producer suites use fixed catalogs and the shared reporter. Debian 13 runs closed all 487 identities: error handling closed 146 in non-root and root runs, local lifecycle passed 125/125, source regression passed 87/87, system infrastructure passed 36/36, and system lifecycle passed 93/93. The error-handling preflight probe closed one failure and 145 skips without entering setup. Real cleanup failures induced through isolated mount namespaces preserved the final `SUITE` record, emitted the cleanup error, and returned status 1 in both lifecycle suites. Formal findings F-codex_gpt5-001 and F-codex_gpt5-002 are resolved and accepted; `hand20260808_141524_codex_gpt5_supersedes_hand20260807_170938.md` records the final P003 handoff. |
| 4 | Complete | `tests/run-all-tests.bash` validates one final `SUITE` record per selected producer, checks suite identity, scope, runner, run-ID uniqueness, vector reconciliation, suite state against producer status, and selected-set completeness. The updated collector mutation probe passed 10/10, and the real source-regression dispatcher path passed 87/87 with `state=PASS` and the collector success banner. |
| 5 | Complete | Reviewer 0 follow-up `fup20260808_233240` accepts F-codex_gpt5-003 through F-codex_gpt5-005. Reviewer 1 follow-up `fup20260810_115015` accepts F009 and F010 after remediation. Reviewer 2 report `rev20260810_120802` and Reviewer 3 report `rev20260810_120522` each report no blocking or nonblocking finding. All three independent review lanes are closed. |
| 6 | Complete | `plan20260810_125403` places P006/V006 in scope and defines the two-host twelve-command matrix, four evidence paths, exact pass criteria, and Check-grade boundary. `auth20260810_125505` adopts the existing evidence without rerun. Each host emitted 612 TEST records, 165 STEP records, and six final `SUITE state=PASS` records; the normalized execution identities matched and the fixed catalog remained 487. Reviewer 1 `fup20260810_125825` resolved `F-reviewer1_state_coherence-003` with no blocking finding. |
| 7 | Complete | `tests/README.md` and `tests/REPORTING_CONTRACT.md` define check kind and test method as independent axes while limiting direct inspection to the observed state or contract. The catalog remains 487 identities and retains 24 `BEHAVIOR/direct-inspection` rows. |
| 8 | Complete | The shared reporter resolves suite state after requested status, check vector, integrity, workspace cleanup, and reporter-workspace cleanup. Its self-test passed 88/88, including clean `PASS`, requested-exit `FAIL`, and real reporter-workspace cleanup-failure paths. All five producers leave final status resolution to `report_finalize`. |
| 9 | Complete | The collector requires `state=PASS|FAIL`, reconciles it with producer status and the failure vector, and rejects missing, malformed, or inconsistent state. The preflighted outer-producer probe passed all 10 vectors and the real source-regression dispatcher passed 87/87. |
| 10 | Complete | Normal Debian 13 source paths emitted `state=PASS` for source regression 87/87, local lifecycle 125/125, system infrastructure 36/36, and system lifecycle 93/93. The error-handling producer closed all 146 identities with its known behavior failures and `state=FAIL`. Isolated local and system cleanup failures returned 1 and emitted final `state=FAIL` with 125/125 and 93/93 checks still PASS. `hand20260810_114052` records the complete execution evidence and returns the remediation to Reviewer 1. |

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Static inventory | Map every assertion, branch, skip, warning, and early return to one test ID and STEP | Working tree | No result-producing path is unmapped or multiply mapped |
| T2 | Reporter contract | Run the real reporter self-tests, including missing state, abort, and projection-agreement cases | Working tree | Missing state is `SCRIPT_ERROR`, no synthetic `NA` is emitted, and both outputs reconcile to the same ledger |
| T3 | Uniform format | Run all suite scripts and the orchestrator through the shared grammar | Working tree | Every suite has valid check, STEP, and suite records with catalog metadata; the human summary agrees and the orchestrator invents no state |
| T4 | State-first suite execution | Run a suite with a known environment exception and one without it | Both goldens | The test code emits explicit states, fixed identity sets remain equal, and totals reconcile |
| T5 | Reviewer gate | Three reviewers inspect the implementation and the state mapping | Review session | No blocking finding remains on inventory, terminal states, or statistics |
| T6 | Full re-verification | Run the whole suite set on both goldens under the new reporting | Both goldens | Every check has one state, every trailer is valid, and statistics derive from test-owned states |
| T7 | P003 producer integration | Run all five shipped producer suites, the error-handling preflight probe, and both lifecycle cleanup-failure probes through the real paths | Debian 13, source and installed-conformance paths, root and non-root where applicable | All 487 producer identities close exactly once, both projections reconcile, and cleanup failure preserves reporter finalization while returning failure |
| T8 | P005 suite execution state remediation | Run the shipped reporter, collector, and both real lifecycle cleanup-failure paths | Debian 13, source paths, root and non-root where applicable | Normal runs emit final `SUITE state=PASS`; cleanup failures return nonzero and emit final `SUITE state=FAIL` without changing the 487-check identity set |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-07T12:01:42-07:00 | Working tree, Debian 13 | Pass | Five suite inventories contain 487 unique IDs: error-handling 146, local-lifecycle 125, source-regression 87, system-infra 36, and system-lifecycle 93. The real error suite executed all 139 current assertions with 129 PASS, the same 10 FAIL outside moved S34, and zero script errors. The real source-regression suite passed 87 of 87, including all five S21 crash-exclusion source contracts. The prior real source local-lifecycle suite passed 109 of 109, including both S35 XDG fallback installs and the S30 real softIoc history-noise paths. The existing installed runner 1.2.1 passed both new S35 checks and finished 103 of 109; its six `_EXTRA` gate differences are outside S18 and are compatibility evidence, not current release installation verification. Syntax, source-regression ShellCheck, accepted-catalog counts and uniqueness, and `git diff --check` passed. Error-handling ShellCheck retained its pre-existing SC1090, SC2016, SC2030, SC2031, and SC2059 findings and was not a clean gate. |
| T2 | 2026-08-10T11:34:55-07:00 | Working tree, Debian 13 x86_64 | Pass | `bash tests/lib/test-reporting-self-test.bash` executed the shipped shared library and passed 88/88. It covered all accepted suite dimensions; kind/method independence; clean, check-failure, requested-exit, integrity, and reporter-workspace cleanup-failure states; final record ordering; ledger cleanup; and fixed command resolution. `bash -n`, warning-level ShellCheck, and `git diff --check` passed for the maintained implementation. |
| T3 | 2026-08-10T11:34:55-07:00 | Working tree and Debian 13 x86_64 | Pass | `sudo /bin/bash -p work/run-all-collector-probe.bash` drove the shipped collector through 10 preflighted outer-producer vectors; valid state passed and missing, invalid, duplicate, malformed, nonfinal, unexpected, and status-mismatch records failed as specified. `bash tests/run-all-tests.bash --source-regression` then ran the real producer through the collector, passed 87/87 with `state=PASS`, and printed `ALL SELECTED TEST SUITES COMPLETED SUCCESSFULLY.` |
| T4 | 2026-08-10T12:24:48-07:00 | Reused Debian 13 and Rocky 8 consumers, Check grade | Pass | Both hosts emitted the same 612 normalized execution identities across the six runbook blocks, representing the unchanged 487-check catalog with local lifecycle exercised in source and installed modes. Debian recorded all checks PASS. Rocky explicitly recorded three user-journal checks as SKIP in each local mode and four regex-policy checks as NA under its sudo glob policy; these ten state differences were the only cross-host differences. Every block vector reconciled. |
| T5 | 2026-08-10T12:09:55-07:00 | Review session `rs20260803_130456` | Pass | Reviewer 1 `fup20260810_115015` accepts F009 and F010 with no blocking finding. Reviewer 2 `rev20260810_120802` accepts P007-P010 with no blocking or nonblocking finding after real reporter and local collector execution. Reviewer 3 `rev20260810_120522` accepts the M9/M8/M6 boundary and evidence scope with no blocking or nonblocking finding. |
| T6 | 2026-08-10T12:24:48-07:00 | Reused Debian 13 and Rocky 8 consumers, Check grade | Pass | The shipped tree was copied with `gate/drivers/push.bash`; source and pushed `git status --porcelain` matched on both hosts. Full installation passed 9/9 on Debian and 10/10 on Rocky. All twelve real suite invocations returned 0. Each host emitted 612 TEST, 165 STEP, and six SUITE records; grammar, per-run uniqueness, terminal states, vectors, STEP ownership, final-record order, and `state=PASS` were validated with zero errors. Human summaries matched the machine vectors. Source and installed runner lines resolved to the intended binaries at commit `1893c6e-dirty`. Reused consumers make this P006 Check evidence only, not release Gate evidence. |
| T7 | 2026-08-08 | Debian 13 x86_64, source and installed-conformance paths | Pass | All five shipped producers ran through their real paths. Error handling closed 146 identities in both runs: non-root recorded 136 PASS and 10 known behavior FAIL; root recorded 117 PASS, 7 known behavior FAIL, and 22 NA. Its unreadable-source preflight recorded 1 FAIL and 145 SKIP without entering setup. Local lifecycle passed 125/125, source regression passed 87/87, system infrastructure passed 36/36, and system lifecycle passed 93/93. Both isolated mount-namespace cleanup-failure probes emitted the cleanup error, retained the final `SUITE` record, and returned status 1. Formal follow-ups accepted both P003 findings after their real-path verification. |
| T8 | 2026-08-10T11:34:55-07:00 | Debian 13 x86_64, source paths | Pass | The shipped reporter self-test passed 88/88 and the collector probe passed 10/10. Real normal paths emitted final `state=PASS`: source regression run `source-regression.3551812.3551812` passed 87/87; local lifecycle run `local-lifecycle.3621332.3621332` passed 125/125; system infrastructure run `system-infra.3633677.3633677` passed 36/36; system lifecycle run `system-lifecycle.3633798.3633798` passed 93/93. The error-handling producer closed its fixed 146 identities and emitted `state=FAIL` for known behavior failures. Mount-isolated cleanup failures returned 1 while preserving all-PASS check vectors: local run `local-lifecycle.3669370.3669370` emitted 125/125 with `state=FAIL`, and system run `system-lifecycle.3687355.3687355` emitted 93/93 with `state=FAIL`. The five catalog totals remain 146 + 125 + 87 + 36 + 93 = 487. |

#### 2026-08-10 Durable Activity Record

This tracked section preserves the M8 work performed on 2026-08-10 because
`docs/review_sessions/` is excluded from Git by `.gitignore`. The referenced
session artifact IDs provide local provenance; the facts required to resume
the work are recorded here independently of those ignored files.

| Area | Durable record |
| --- | --- |
| Owner decision | Preserve the fixed 487-check catalog and add final `SUITE state=<PASS\|FAIL>`. Cleanup and finalization failures are suite execution results rather than additional checks. The User later selected adoption of the existing P006 Check-grade evidence without rerunning the suites and explicitly authorized the authority repair. |
| Implementation | P007-P010 completed kind/method reconciliation, post-cleanup suite-state finalization, collector state validation, and both real lifecycle cleanup-failure paths. The reporter result, human summary, final SUITE state, and process status now derive from the same finalized execution state. |
| Debian verification | The shipped reporter self-test passed 88/88; the shipped collector probe passed 10/10; source regression passed 87/87; local lifecycle passed 125/125; system infrastructure passed 36/36; and system lifecycle passed 93/93. Mount-isolated cleanup failures returned 1 while preserving all-PASS check vectors and emitting final `SUITE state=FAIL` for local 125/125 and system 93/93. |
| P006 matrix | Reused Debian 13 (`192.168.122.50`) and Rocky 8 (`192.168.122.150`) consumers each ran error handling, source regression, local lifecycle in source and installed modes, system infrastructure installed, and system lifecycle installed. All twelve process statuses were zero. Each host emitted 612 TEST, 165 STEP, and six final `SUITE state=PASS` records. The normalized execution identities matched exactly and represented the unchanged 487-check catalog. |
| Cross-host states | Debian recorded all 612 execution identities as PASS. Rocky recorded 602 PASS, six SKIP from the three local S29 user-journal checks in both runner modes, and four NA from the system-infra S06 sudoers-policy branch. Those ten records were the only cross-host state differences. |
| Evidence identity | The normalized execution-identity SHA-256 was `0737c14595c574808f9b77fdcb8dd2b4cc81b3f3901824675e72db8c7f795cf3` on both hosts. Debian captured-log and status SHA-256 values were `9f1db70b9034f43e4b4346cb37b2b7b7a8ccbaa947acf6cbe0e26fc471bcd8ee` and `2c7199ce7ed8f91005630df7502c6292da5a62e0b24c4a9f56ca48163ca1c738`; Rocky values were `944374e563128a16fedac4721c70a746a118273a0bf957c2c4b8728161c682df` and `93f68f6800f77f0610b2e20d96dd2f5bc9965f1278ab984a08dd63eeafde6b0b`. The files were transient Check-grade evidence and are not required for later verification. |
| Authority conflict | `plan20260810_021936` listed P006 as out of scope and prohibited beginning it while `auth20260810_121447` and `hand20260810_122448` claimed P006 authorization and completion. Reviewer 1 accepted the real evidence but opened blocking finding `F-reviewer1_state_coherence-003` against that inconsistent authority chain. |
| Authority repair | `plan20260810_125403` superseded the conflicting plan and placed P006/V006 in scope with both hosts, the twelve-command matrix, four evidence paths, exact pass criteria, and the reused-consumer Check-grade boundary. `auth20260810_125505` recorded User approval; `hand20260810_125527` adopted the unchanged evidence without rerun; Reviewer 1 `fup20260810_125825` resolved F-003 with no blocking finding. Reviewer 2 `rev20260810_123926` and Reviewer 3 `rev20260810_123537` also accepted the execution and boundary evidence with no finding. |
| Final boundary | P006 is Complete and T4/T6 are Pass at Check grade only. No fresh bake or release Gate claim was made, no suite was rerun for the authority repair, and no file under `gate/` changed. M8 completed after its canonical record and GitHub issue body were reconciled and issue #137 was observed closed. |

#### Closure Evidence

Complete on 2026-08-10. Commit `a60802b` implements final suite-state
reporting and carries the durable M8 activity record. The shipped reporter
self-test passed 88/88, the collector probe passed 10/10, the fixed catalog
remained 487 identities, the two-golden Check-grade matrix reconciled, both
real cleanup-failure paths emitted final `state=FAIL`, and all three review
lanes reported no blocking finding. GitHub issue #137 was reconciled with this
record, all completion checkboxes were checked, and its `CLOSED` state was
observed after the authorized close. M6 is unblocked as the consumer of these
machine-readable records.

#### GitHub Projection

Title: Suite skip-reporting policy: make a skip countable from the summary
Labels: tests, P2-medium
GitHub Milestone: 1.2.3
Observed State: closed
Observed Labels: P2-medium, tests
Observed Milestone: 1.2.3
Observed Assignee: jeonghanlee
Observed Updated At: 2026-08-10T20:50:28Z
Observed Body: matches the canonical M8 closure record through T8
Last Compared: 2026-08-10T20:50:28Z

### M10 - Release record reconciliation

Origin: 1.2.3 / M10
Identity History: none
GitHub Issue: none
Status: Complete

#### Summary

The canonical register and the linked GitHub issues contain status, workflow,
and projected-content differences accumulated during the 1.2.3 cycle. Restore
one current account before release work relies on those records.

#### Scope

- Reconcile internal status fields, derived Ready values, the release
  dependency list, and the next-session entry point in this register.
- Compare every linked 1.2.3 issue (#130, #131, and #133 through #138) with its
  canonical detail and classify every difference as canonical projection, live
  metadata, or an owner decision.
- Project accepted canonical content to GitHub after separate issue authority.
- Re-read every changed issue and record its observed state, labels, milestone,
  assignee, and comparison date in the matching detail.

Out of scope: implementing or verifying M2, M5, M6, M7, or M8; changing their
accepted technical decisions; executing the final release.

#### Completion Criteria

- The work table, matching details, and next-session entry point contain no
  contradictory status or dependency information.
- Every linked issue matches its canonical projection or the matching detail
  records an explicit owner-approved exception.
- Every linked issue detail carries current observed GitHub metadata.
- No reconciliation difference remains unclassified or unresolved.

#### Dependencies And Decisions

- M10 does not block M8 implementation, but M3 depends on M10 completion.
- GitHub mutations require separate issue authority under `git-workflow`.
- Owner decision, 2026-08-06: apply the current standalone milestone-close
  workflow to completed M4 and close #133 after separate issue authority. This
  replaces the older deferred-close record.
- Owner decision, 2026-08-10: reopen M10 after M2 and M5 reached Complete while
  GitHub issues #130 and #134 remained open with their earlier projections.
  M3 resumes as Not started and is not Ready until both projections are
  published and re-read under M10.

#### Reconciliation Inventory

Observed 2026-08-06T19:03:22-07:00 from the live GitHub issues; all eight
linked issues were re-observed after the completed #130 and #134 projections
on 2026-08-10.

| Issue | Canonical Work | Difference Class | Result |
| --- | --- | --- | --- |
| #130 | M2 | Canonical projection and live metadata | Completed projection published; live body hash matched; issue closed; labels, milestone, and assignee matched |
| #131 | M1 | Live metadata | Current closed state, labels, milestone, assignee, and comparison date recorded |
| #133 | M4 | Canonical projection and live metadata | Reconciled body published and issue closed; owner decision 2026-08-06 replaces the older deferred-close record |
| #134 | M5 | Canonical projection and live metadata | Completed projection published; live body hash matched; issue closed; labels, milestone, and assignee matched |
| #135 | M6 | Canonical projection and live metadata | Completed M6 projection published; all completion criteria checked; issue closed; labels, milestone, and assignee matched |
| #136 | M7 | Canonical projection and live metadata | Completed M7 projection published; all completion criteria checked; issue closed; labels, milestone, and assignee matched |
| #137 | M8 | Canonical projection and live metadata | Completed M8 projection through T8 published; completion criteria and plan steps checked; issue closed; labels, milestone, and assignee matched |
| #138 | M9 | Live metadata | Current closed state and metadata recorded; projected implementation and verification content confirmed current |

#### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner, 2026-08-06, after reviewing the five-step reconciliation plan
Implementation Authorization: owner, 2026-08-06, same exchange
Superseded Plan Artifacts: none

1. Audit the canonical work table, details, derived Ready values, dependency
   lists, and next-session entry point; correct internal contradictions.
2. Compare #130, #131, and #133 through #138 with their matching canonical
   details and record each difference by authority class.
3. Present genuine conflicts for owner decision and update the canonical
   details with those decisions.
4. Prepare the complete GitHub projection changes and obtain separate issue
   authority before applying them.
5. Re-read the live issues, update observed metadata in the canonical details,
   and verify that no difference remains.
6. Reconcile the completed M2 and M5 projections with #130 and #134, then
   re-run the live comparison before restoring M10 Complete.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Register consistency | Compare every work row with its detail, dependencies, Ready value, and next-session entry point | Working tree | No internal status, dependency, or entry-point contradiction remains |
| T2 | GitHub reconciliation | Compare every linked issue field and projected body section with its canonical detail | GitHub and working tree | Every difference is classified and no genuine conflict remains unresolved |
| T3 | Post-update verification | Re-read every changed issue and compare live metadata and projected content with the updated canonical detail | GitHub and working tree | Every issue matches its projection or carries an owner-approved exception, and observed metadata is current |
| T4 | Post-closure reconciliation | Compare completed M2 and M5 with #130 and #134, publish the accepted projections, and re-read both issues | GitHub and working tree | Both issues match the completed canonical details and carry current observed metadata |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-06T19:01:46-07:00 | Working tree | Pass | Work-row/detail status comparison, dependency and Ready audit, and `git diff --check` |
| T2 | 2026-08-06T20:16:03-07:00 | GitHub and working tree | Pass | All eight linked issues classified; #133 owner conflict resolved; #133 through #137 canonical projection changes published |
| T3 | 2026-08-06T20:16:03-07:00 | GitHub and working tree | Pass | #133 through #137 remote body hashes matched the reviewed local drafts; states, labels, milestone, and assignees matched; #133 observed closed |
| T4 | 2026-08-10T21:57:26-07:00 | GitHub and working tree | Pass | The earlier 21:03 failure triggered reconciliation. The completed #130 and #134 projections were then published and both issues closed. Their live JSON body bytes matched the reviewed drafts at SHA-256 `3ca402b4ac7f8eba47d5d196bf63ec5c76cbe6afdf6ad4e6a10682f6c71390b3` and `cd82e7fdeac4bfdbc8ec352aff5d854e730d7d78d5e63ea79763f29c7392bc66`; a fresh sweep of all eight linked issues found states, labels, milestone, and assignees matching their canonical details. |

#### Closure Evidence

- Internal work-row/detail status and Ready values reconciled in this document.
- GitHub issues #133 through #137 reconciled on 2026-08-06; #133 closed and
  #137 assigned to `jeonghanlee`.
- Post-update body hashes matched the reviewed local drafts for all five
  changed issues, and live metadata matched their canonical projections.
- Reopened 2026-08-10: T4 first found #130 and #134 behind their completed
  canonical details. After owner acceptance and separate issue authority, both
  completed projections were published and both issues closed. The live body
  and metadata re-read passed, so M10 is Complete again.

#### GitHub Projection

Title: none
Labels: none
GitHub Milestone: 1.2.3
Observed State: none
Last Compared: 2026-08-10T21:57:26-07:00

### M11 - Rocky S29 applicability

Origin: 1.2.3 / M11, owner decision 2026-08-11
Identity History: none
GitHub Issue: #141
Status: In progress

#### Summary

Local lifecycle S29 uses the caller's user-unit journal as the positive control
for monitor input isolation. Under this project's Rocky ordinary-user policy,
that journal channel is deliberately unavailable and S29 cannot verify its
behavior. Classify the three checks as not applicable on Rocky instead of
reporting a missing prerequisite as SKIP.

#### Scope

- Add one stable S29 `APPLICABILITY/direct-inspection` check to the catalog.
- Close the applicability check and the three existing S29 checks as NA on
  Rocky before the user-journal probe.
- Preserve the current journal probe and real monitor-isolation path on Debian
  and other applicable environments.
- Keep the human summary, TEST records, STEP records, SUITE vector, and suite
  process status derived from the existing reporting ledger.

Out of scope: granting `systemd-journal` membership, changing journald storage
or ACL policy, changing `ioc-runner` monitor behavior, or reopening the
VM-versus-production journal matrix closed by CI-32.

#### Completion Criteria

- Rocky source and installed local lifecycle runs each record the governing
  applicability check and the three existing S29 checks as NA, record no S29
  SKIP, and finish with `state=PASS`.
- Debian source and installed local lifecycle runs record the applicability
  check as PASS, execute all three existing S29 checks through the real path,
  and record PASS.
- The shipped two-host suite driver accepts both complete state vectors without
  hiding or converting an unexpected SKIP.
- No user gains journal access and no host journal configuration changes.

#### Dependencies And Decisions

- D1: this test-code change needs its own issue before implementation.
- D16 and `CLOSED_DOORS.md` CI-32: Rocky S29 is not applicable under the
  ordinary-user policy; widening journal access is closed.
- M3 depends on M11 because the current six Rocky SKIPs keep Release
  Verification 2 red.

#### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner approval, 2026-08-11
Implementation Authorization: owner approval, 2026-08-11
Superseded Plan Artifacts: none

1. Add `local-lifecycle.S29.monitor-isolation-applicable` as an
   `APPLICABILITY/direct-inspection` catalog row governed by the suite's
   existing `/etc/os-release` reader.
2. Close that row and its three dependent S29 checks as NA with the CI-32
   policy reason on Rocky; record the applicability row as PASS and keep the
   existing prerequisite probe and real behavior checks elsewhere.
3. Advance the maintained current catalog count from 487 to 488 and the local
   lifecycle count from 125 to 126 without rewriting historical 487-check or
   125-check result rows.
4. Update the maintained local lifecycle inventory and test instructions to
   state the Rocky applicability boundary.
5. Run both local lifecycle modes and the shipped suite driver on both goldens.

#### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Rocky applicability | Run the shipped local lifecycle suite in source and installed modes as the ordinary golden user | Fresh Rocky 8 consumer | Four S29 NA per mode, zero S29 SKIP, both 126-check suites `state=PASS` |
| T2 | Debian positive path | Run the same two shipped modes without replacing the journal boundary | Fresh Debian 13 consumer | The applicability check and all three existing S29 checks PASS in each 126-check suite |
| T3 | Gate integration | Run `gate/drivers/control/suites.bash` against both consumers | Both goldens | Complete vectors are retained; both host verdicts PASS; no unexpected SKIP is accepted |

#### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-11T21:37:51-07:00 | Fresh Rocky 8 consumer from the 2026-08-12T04:08:22Z golden; source and installed modes at control HEAD `e0bc7f0` plus the one-line driver identity update | Pass | Each local lifecycle mode emitted 126 TEST records and one final PASS SUITE record with `pass=122 skip=0 na=4 err=0`. The two modes emitted exactly eight S29 NA records and zero S29 SKIP records. Evidence: `work/gate-suites-20260812T043206Z-790798/vmadmin_192.168.122.150.log`, SHA-256 `e776da3b1019496d728069f867fc2e3d007696479e254a0472a3d660b30e58a7`. |
| T2 | 2026-08-11T21:37:51-07:00 | Fresh Debian 13 consumer from the 2026-08-12T04:13:35Z golden; source and installed modes at control HEAD `e0bc7f0` plus the one-line driver identity update | Pass | Each local lifecycle mode emitted 126 TEST records and one final PASS SUITE record with `pass=126 skip=0 na=0 err=0`. The two modes emitted exactly eight S29 PASS records through the real user-journal path. Evidence: `work/gate-suites-20260812T043206Z-790798/vmadmin_192.168.122.50.log`, SHA-256 `7462aa464f1ec64eb8ff353fb969694d171641289f923e8338fef5b34249569d`. |
| T3 | 2026-08-11T21:37:51-07:00 | Both fresh consumers; shipped driver snapshot SHA-256 `145d1b43fc99ff2f2ead8806728c2033566fe1f2c30d9030ad4e3db02898d2db` | Pass | All twelve real suite invocations returned 0. Each host retained 614 TEST, 165 STEP, and six final PASS SUITE records with execution-identity SHA-256 `fcfdabf99fb5cfdc897b318afb4df79d611119eca719e96eca803d74422351a7`. Debian returned `SUITES OK (6 blocks, 614 checks, na=0)`; Rocky returned `SUITES OK (6 blocks, 614 checks, na=12)`; the final line was `GATE SUITES PASS hosts=2`. The 60-line normalized diff records only the declared S29 and S06 applicability differences. Evidence directory: `work/gate-suites-20260812T043206Z-790798/`; diff SHA-256 `e47465e819a329b2ba806c7d968b06a9d02a1f8c3e64f2f2b2bcb6dfaf2cf7b4`. |

#### Closure Evidence

- The accepted implementation and T1-T3 verification are complete in the
  working tree. Before and after the two-host run, neither ordinary user was a
  `systemd-journal` group member; Rocky had no `/var/log/journal`; Debian kept
  `/var/log/journal` as `root:systemd-journal 2755`; and the respective
  `/etc/systemd/journald.conf` SHA-256 values remained
  `5665c17814395153b05370a06c1c6cd5b24060ab58b76883535296bac922f7e1` and
  `b7ab521d85bbd289adc37788c469c6ac6a2021dd056a1eada02107bbe891c650`.
- M11 remains In progress until the driver identity update and this evidence
  are committed and linked issue #141 is observed closed under separate issue
  authority.

#### GitHub Projection

Title: Classify Rocky local monitor-isolation checks as not applicable
Labels: tests, ops
GitHub Milestone: 1.2.3
Observed State: Open, assigned to `jeonghanlee`
Last Compared: 2026-08-11T21:37:51-07:00

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

- M1, M2, M4, M5, M6, M7, M8, M9, M10, M11
- D1 and D5: the line is documents and scenarios apart from one named
  exception, so the suites verify unchanged behavior everywhere except the
  version stamp, where M4 changes the comparison and carries its own
  regression coverage. The integrated re-run below therefore inherits the
  same expectation as an unchanged-behavior cycle.
- D6: the contract guard over the three stamp sites was examined and declined
  (`CLOSED_DOORS.md` CI-31), so no guard work gates this release.
- D16: Rocky S29 is not applicable under the ordinary-user policy. M11 must
  replace the six current SKIPs with explicit NA records without widening
  journal access before Release Verification 2 can pass.

#### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Complete M11 and its two-golden verification.
2. Bake both goldens fresh and record the golden acceptance.
3. Run the gate by following `gate/RUNBOOK.md`.
4. Execute the release sequence under `git-workflow` authority.

#### Integrated Verification

| Source Check | Re-run Trigger | Shared Surface | Release Verification Label | Expected Result | Result Evidence |
| --- | --- | --- | --- | --- | --- |
| M1 / T2 | The runbook's multi-user text changed after the drive that corrected it | `docs/RELEASE_CYCLE_RUNBOOK.md` | M1 / T4 | Every scenario drives green from the corrected text, on freshly baked goldens | done, 2026-07-30 |
| M2 / T1 | The runbook's evidence format changes after the gate record is written | `gate/RUNBOOK.md` | Release Verification 4 | The gate record still carries the declared baseline | pending |
| M8 / T4 | M11 adds one S29 applicability identity and changes the Rocky S29 group from SKIP to NA | Test reporting ledger and suite collector | Release Verification 2 | Both hosts retain 614 complete execution identities; Rocky records eight S29 NA and zero SKIP; Debian records all four S29 checks PASS per mode; both host suite verdicts are green | pending |

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
| Release Verification 2 | Automated suites | pre-change | Run the complete suite set in each applicable permission mode, following the runbook's mode table | Both goldens | Green with counts recorded per host, suite, and applicable mode | Suite summaries |
| Release Verification 3 | Standing scenarios | pre-change | The multi-user plan, driven from its own text | Both goldens | Every scenario meets its stated expected result | Per-scenario results |
| Release Verification 4 | Standing procedure | pre-change | The root_squash path through the three documented entry points from the `nfs_sim` mount | Both goldens | Each entry point stamps a real short hash with no layout warning | Stamp output and `-V` |
| Release Verification 5 | Version consistency | pre-change | Read `RUNNER_VERSION` on the release branch | Working tree | The value is the planned release version before the mutation is verified | Commit and file read |
| Release Verification 6 | Version consistency | post-change | Read the deployed `-V` from the tagged tree | Both goldens | `1.2.3` with a real short hash | `-V` output |
| Release Verification 7 | Release objects | post-release | Read the tag object, the release object, and the remote milestone state | GitHub | Tag, release, and closed milestone exist and match the merge commit | Object identifiers |
| Release Verification 8 | Production deployment | post-release | The documented install path on the production host | `alsucl-psrv3` | Install completes and the runner reports the released version | `-V` output |

#### Release Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| Release Verification 1 | 2026-08-10T18:49:18-07:00 | Fresh Rocky 8 and Debian 13 consumers | Pass | Before any deploy or tree push, both manifests were `root:root 644`; remote hashes matched the working-copy sidecars; the shipped provenance validator passed; retained checkout and installed `-V` identities matched `fd14875`; both baseline records were `requested=1.2.2 state=clean-tagged tag=1.2.2` with dirty count `0`. Full bake and acceptance evidence is recorded under M5 step 8 and M2/T2. |
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
