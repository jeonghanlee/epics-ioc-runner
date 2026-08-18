# Work Register

Release line: 1.3.0
Milestone index: 1.3.0
Canonical path: `docs/milestone-1.3.0.md`
Canonical branch or ref: `release-1.3.0`
Git upstream: `origin/release-1.3.0`
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `1.3.0`,
number 16
Activation state: active on `release-1.3.0`; source authority moved in master
commit `05c49629e2cbc2a61414303a1c26fbd3b9acc601`.

Next session entry point: The 1.3.0 cycle is open at version 1.3.0-dev, G1 is
Complete (milestone 16), all ten issues carry the `1.3.0` milestone, and the
execution order is settled as the local ID order (D3). Next: finish the M1
(#148, count-coherence guard) review and prepare its commit, then open the M10
(#102) health-signal design conversation — M10 is the largest item and its
boundary must be designed before any code.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Tests | M1 | (#148) Centralize expected reporting counts and guard runtime catalog coherence | Milestone | In progress | No | D1, D3, D4 | One CSV owns expected check and STEP counts, every suite compares its real catalog before preflight, and the gate derives totals while keeping its six-run set independent; [detail](#m1---suite-count-coherence-guard) |
| Environment | M2 | (#139) Stop EPICS-dependent test scripts before setup when `EPICS_BASE` is unset | Milestone | Not started | Yes | D1, D3 | Every affected entry point stops nonzero at its first environment boundary with the catalog contract preserved; [detail](#m2---epics_base-entry-boundary) |
| Diagnosis | M3 | (#142) Diagnose a conf/mode mismatch in one message | Milestone | Not started | Yes | D1, D3 | Both supported mismatch directions produce one complete diagnosis with the correct regeneration command; [detail](#m3---conf-mode-mismatch-diagnosis) |
| Reliability | M4 | (#115) Exercise restart supervision end-to-end on the goldens | Milestone | Not started | Yes | D1, D3 | Killing the real softIoc child increases the child-death count and the unit recovers on both golden OS families; [detail](#m4---restart-supervision-probe) |
| Configuration | M5 | (#113) Unify the three conf parsers behind one shared parse core | Milestone | Not started | Yes | D1, D2, D3 | Every divergence fixture resolves identically through install-time, runtime, and systemd consumers; [detail](#m5---conf-parser-unification) |
| Configuration | M6 | (#129) Unify conf-value normalization between `read_conf_var` and `read_conf_all` | Milestone | Not started | No | M5, D1, D2, D3 | Both readers return the identical string for every whitespace- and quote-bearing fixture; [detail](#m6---conf-value-normalization) |
| Tests | M7 | (#116) Exercise the deployed local logrotate oneshot through systemd | Milestone | Not started | Yes | D1, D3 | The deployed oneshot completes through the real user manager on both applicable goldens and a broken `ExecStart` fails; [detail](#m7---suite-integrity) |
| Tests | M8 | (#144) Separate human-readable test output from machine-readable records | Milestone | Not started | Yes | D1, D3 | Operator output and the machine record surface separate while describing one ledger; [detail](#m8---human-and-machine-output-separation) |
| Docs | M9 | (#132) Settle the fate of the `docs/MILESTONE_PROCEDURE.md` working draft | Milestone | Not started | Yes | D1, D3 | One fate is chosen and applied with every live reference resolvable; [detail](#m9---milestone-procedure-draft-fate) |
| Reliability | M10 | (#102) Fleet-layer reliability: restart-storm boundary and running-IOC hang detection | Milestone | Not started | Yes | D1, D3 | A live-but-unresponsive IOC is detected without process exit and fleet recovery is observable; [detail](#m10---fleet-layer-reliability) |
| Release | M11 | Final release 1.3.0 | Milestone | Not started | No | M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, G1 | The release-cycle final phase completes with all Release Verification checks Pass; [detail](#m11---final-release) |
| Tracker | G1 | GitHub milestone 1.3.0 exists | External gate | Complete | No | | Repository owner created open GitHub milestone 1.3.0, number 16, on 2026-08-18; [detail](#g1---github-milestone-1.3.0) |

### Decisions

| ID | Decision | Source |
| --- | --- | --- |
| D1 | Open 1.3.0 as a reliability-and-configuration-contract line carrying #102, #115, #113, #129, #142, #139, #116, #144, #148, and #132. #127 (container execution mode) is excluded to a later cycle as a standalone feature. | Owner decision, 2026-08-17; recorded as D2 in `docs/milestone-46790f9.md` |
| D2 | Run M5 and M6 as one configuration-contract lane: M6 is the narrow two-reader case that M5's shared parse core subsumes, so M6 follows M5 and closes on the shared core's evidence plus its own reader-equivalence fixtures. | Owner-accepted lane pairing, 2026-08-17 |
| D3 | Execute the cycle in local ID order M1 (#148), M2 (#139), M3 (#142), M4 (#115), M5+M6 (#113/#129 lane), M7 (#116), M8 (#144), M9 (#132); M10 (#102) runs its design conversation from cycle start with implementation placed after the mid-cycle. Local IDs were renumbered to match this order; each detail's Identity History records its prior ID. | Owner decision, 2026-08-18 |
| D4 | M1 centralizes expected check and STEP counts in `tests/reporting-counts.csv`. Runtime catalogs remain the independent actual values, and the CSV is initially populated only from pre-change observations of the five real shipped suite paths. The reporter's existing five-suite set becomes a public supported-suite contract that independently validates CSV membership. Normal suite runs compare immediately after catalog close; `REPORT_CATALOG_ONLY=1` performs the same comparison and then exits through a reporter-owned cleanup state before environment preflight, emitting exactly one `CATALOG suite=<suite> checks=<checks> steps=<steps> state=PASS` line on success. The gate's six-run execution set remains independent and joins to the CSV for per-suite expectations and derived totals. Live expectation documents reference the CSV; historical observed counts remain unchanged. | Owner design direction, 2026-08-18; third-person and second-person review findings accepted 2026-08-18 |

### Assignment History

| Identity | From | To | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| 46790f9 / M4 -> 1.3.0 / M1 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | this synchronization commit | source transfer commit naming this target commit |
| 46790f9 / M5 -> 1.3.0 / M2 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | this synchronization commit | source transfer commit naming this target commit |
| 46790f9 / M6 -> 1.3.0 / M3 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | this synchronization commit | source transfer commit naming this target commit |
| 46790f9 / M7 -> 1.3.0 / M4 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | this synchronization commit | source transfer commit naming this target commit |
| 46790f9 / M8 -> 1.3.0 / M5 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | this synchronization commit | source transfer commit naming this target commit |
| 46790f9 / M9 -> 1.3.0 / M6 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | this synchronization commit | source transfer commit naming this target commit |
| 46790f9 / M10 -> 1.3.0 / M7 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | this synchronization commit | source transfer commit naming this target commit |
| 46790f9 / M11 -> 1.3.0 / M8 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | this synchronization commit | source transfer commit naming this target commit |
| 46790f9 / M12 -> 1.3.0 / M9 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | this synchronization commit | source transfer commit naming this target commit |
| 46790f9 / M13 -> 1.3.0 / M10 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | this synchronization commit | source transfer commit naming this target commit |

### Milestone Details

#### M1 - Suite count coherence guard

Origin: 1.3.0 / M9
Identity History: staged from `docs/milestone-46790f9.md` M12; 1.3.0 / M9 -> 1.3.0 / M1 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 148, https://github.com/jeonghanlee/epics-ioc-runner/issues/148
Status: In progress

##### Summary

One concept — a suite's expected check and STEP counts — is encoded in the
reporting inventories, the gate driver's `want[]` and `want_step[]`, and
`gate/RUNBOOK.md`. Runtime catalog emission is the independent actual value.
The gate compares its expected copy to real runs, but the live document copies
have no equivalent enforcement. They drifted silently for the whole 1.2.4
cycle: the driver expected 614 checks while the suites emitted 688, and the
copies were re-synchronized by hand during the 1.2.4 logrotate state-isolation
work.

##### Scope

Extract the reporter's existing five suite IDs into the public contract
`tests/lib/reporting-suites.bash`. The reporter and CSV parser consume that
contract so the accepted suite set remains independent of the CSV being
validated.

Create `tests/reporting-counts.csv` with the exact header
`suite,checks,steps` and one unique row for every suite in the public contract.
Populate its initial rows only from a pre-change run of the five real shipped
suite paths. It is the sole manually maintained source for current expected
check and STEP counts; it contains no aggregate or gate-run rows.

Each suite keeps its runtime catalog independent and compares the registered
check and STEP counts with its CSV row immediately after `report_close_catalog`
and before environment preflight. An absent or zero `REPORT_CATALOG_ONLY`
continues through the normal suite path after a successful comparison. A value
of `1` performs the same real catalog registration, close, and comparison,
then emits exactly one
`CATALOG suite=<suite> checks=<checks> steps=<steps> state=PASS` line and exits
through a shared reporter lifecycle that cleans its workspace without
projecting unexecuted checks as `SCRIPT_ERROR`. Any other value is rejected.

The gate retains its existing independent six-run execution and run-status
sets. Its count verdict joins each run's suite to the CSV and derives block,
check, and STEP totals instead of carrying `want[]`, `want_step[]`, `6`, `688`,
or `170` count literals. Live reporting inventories and `gate/RUNBOOK.md`
reference the CSV rather than repeating current expected totals.

##### Out of Scope

- Auto-generating per-check identity listings or their descriptions.
- Deriving or changing the gate's independent six-run execution set.
- Replacing `EXPECTED_IDENTITY_SHA256`, which guards identity membership rather
  than counts.
- Rewriting historical observed counts in release notes, changelogs, milestone
  history, or verification evidence.
- Changing product behavior or the meaning of any existing test identity.

##### Completion Criteria

- `tests/reporting-counts.csv` is the only live expected check and STEP count
  source, has the exact accepted schema, and has one valid row for every
  suite in the independent public supported-suite contract.
- The public supported-suite contract is extracted from the reporter's
  existing five-suite set, and the reporter and CSV parser both consume it;
  the CSV cannot authorize its own membership.
- Every normal suite run compares its real registered catalog with the CSV
  before environment preflight and stops nonzero without a valid `SUITE`
  projection on mismatch.
- `REPORT_CATALOG_ONLY=1` runs the same catalog registration, close, and
  comparison, then cleans reporter state and exits zero without entering
  EPICS, privilege, workspace, systemd, or IOC setup. Success emits exactly
  one `CATALOG suite=<suite> checks=<checks> steps=<steps> state=PASS` line;
  a mismatch remains nonzero.
- The gate keeps its six-run membership independent, consumes CSV counts, and
  derives the expected block, check, and STEP totals without duplicated count
  literals.
- Live inventory and runbook text references the CSV without repeating current
  expected totals; historical observed counts remain unchanged.
- The shipped tree passes the real catalog, parser, documentation, and full
  two-golden gate checks, while an isolated one-row drift fails through the
  shipped suite path.
- The repository's four-gate promotion test (`docs/CLOSED_DOORS.md`) records
  elimination of duplicated live expectations before the remaining
  independent actual-versus-expected guard.

##### Dependencies And Decisions

- The counts are correct now (re-synced during the 1.2.4 cycle), so no release
  evidence is invalidated; the guard prevents the next silent drift.
- Contrast recorded as CI-33 (the logrotate directive seam is self-enforcing
  and needs no guard); this count seam is the un-enforced case that does.
- Promotion-test result: Gate A passes because actual catalog counts and
  accepted expected counts must agree. Gate B passes because silent drift
  changes release acceptance evidence. Gate C passes because the existing
  two-golden gate catches drift only at the release boundary and does not
  protect the live inventory copies or ordinary suite runs. Gate D places the
  actual-versus-expected comparison at the reporting boundary and keeps the
  gate-run membership check independent.
- Elimination result: duplicated current expected values move to one CSV;
  runtime catalogs do not consume that CSV because they must remain the
  independent actual side of the comparison.
- D1, D4

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner confirmed the reviewed M1 plan on 2026-08-18 ("맞아").
Implementation Authorization: Owner explicitly authorized implementation on 2026-08-18 ("맞아").
Superseded Plan Artifacts: none

1. Before adding the comparison, run the five current shipped suite entry
   points through their real normal paths: `tests/test-error-handling.bash`,
   `tests/test-source-regression.bash`, `tests/test-local-lifecycle.bash` in
   `IOC_RUNNER_TEST_MODE=source`, `tests/test-system-infra.bash`, and
   `tests/test-system-lifecycle.bash` in
   `IOC_RUNNER_TEST_MODE=installed`. Capture each command's combined output
   separately. Read the check count from the `total=` field on the final real
   `SUITE` record and the STEP count from the number of emitted `STEP` records,
   even when a later environment preflight makes the suite exit nonzero; do
   not reconstruct a catalog or copy totals from an inventory.
2. Extract the reporter's existing five suite IDs into
   `tests/lib/reporting-suites.bash`. Provide one public ordered suite-list
   function and one membership predicate, then make
   `tests/lib/test-reporting.bash` use that contract before applying its
   existing category and scope/runner validation.
3. Add `tests/reporting-counts.csv`, seeded only from the observations in step
   1, with one `suite,checks,steps` row per public supported suite and no
   persisted aggregate values.
4. Add `tests/lib/reporting-counts.bash` as the shared CSV parser. It sources
   the public supported-suite contract, strips
   carriage returns, requires the exact header, rejects malformed or duplicate
   rows, rejects missing or unknown suites against that independent contract,
   and provides strict suite lookups to every consumer.
5. Add the suite-owned comparison to `tests/lib/test-reporting.bash` and call
   it after `report_close_catalog` in all five result-producing suite scripts.
   Keep it outside the generic close operation so
   `tests/lib/test-reporting-self-test.bash` can continue exercising
   deliberately small catalogs.
6. Add the shared reporter catalog-only completion state to
   `tests/lib/test-reporting.bash`. On success it prints exactly one
   `CATALOG suite=<suite> checks=<checks> steps=<steps> state=PASS` line,
   cleans the reporter workspace, suppresses normal finalization, and is
   honored by all five suite exit handlers.
7. Make every normal suite path compare before environment preflight and make
   `REPORT_CATALOG_ONLY=1` stop only after that same comparison.
8. In `gate/drivers/control/suites.bash`, replace count literals with a join
   from the independent six-run list to the CSV. Derive aggregate block, check,
   and STEP totals while leaving the execution list, run-status set, and
   identity digest independent.
9. Remove current expected count literals from `tests/REPORTING_INVENTORY.md`,
   the five `tests/*_INVENTORY.md` files, and `gate/RUNBOOK.md`; replace them
   with CSV references. Preserve historical observed counts in changelogs,
   milestone history, and verification evidence unchanged.
10. Run the source checks, isolated honest-red mutation, documentation authority
   check, and full two-golden gate through their shipped paths.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Real catalog comparison | Run all five shipped suites with `REPORT_CATALOG_ONLY=1` | Source test environment without EPICS, root, systemd, or IOC setup | Every suite registers and closes its real catalog, matches its CSV row, emits exactly one `CATALOG suite=<suite> checks=<checks> steps=<steps> state=PASS` line, cleans reporter state, and exits zero without `TEST`, `STEP`, `SUITE`, or `SCRIPT_ERROR` projection |
| T2 | Normal-path honest red | Change one suite's CSV count in an isolated repository copy and run that shipped suite without catalog-only mode | Source test environment | The suite stops nonzero after real catalog close and before environment preflight, reports the expected-versus-actual mismatch, and emits no valid `SUITE` record |
| T3 | CSV boundary | Run the shipped parser against the committed CSV and isolated CRLF, duplicate-row, missing-suite, unknown-suite, and nonnumeric-count variants; obtain the accepted suite set only from `tests/lib/reporting-suites.bash` | Source test environment | The committed and CRLF inputs normalize and match the complete public supported-suite set; every malformed, duplicate, incomplete, unknown, or nonnumeric variant fails explicitly |
| T4 | Gate integration | Run `gate/drivers/control/suites.bash` through its real six-run path | Both golden OS families | Each independent run key appears exactly once, real counts match the CSV, derived totals reconcile, identity digest validation passes, and both host verdicts pass |
| T5 | Documentation authority | Search all tracked live documentation for current expected count declarations and inspect historical count occurrences | Working tree | Live inventories and RUNBOOK reference the CSV without current expected literals; changelog, release history, and observed drift evidence remain unchanged |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-18 | Source test environment | Pass: all five shipped suite entry points ran their real catalog registration and emitted only the expected `CATALOG` record with the CSV check and STEP counts | Terminal observation |
| T2 | 2026-08-18 | Isolated source-tree copy | Pass: changing the error-handling CSV row to 149 checks made the real normal suite path exit 1 after catalog close, report expected 149 versus actual 150, and emit no `SUITE` record | Terminal observation |
| T3 | 2026-08-18 | Source test environment | Pass: the parser self-test passed 8 of 8 assertions, including the committed CSV, CRLF equality, duplicate, missing, unknown, nonnumeric, and malformed-header cases; the existing reporter self-test passed 88 of 88 assertions | Terminal observation |
| T4 | 2026-08-18 | Debian 13 and Rocky 8 goldens | Pass: the current M1 working tree was copied to both hosts and fully deployed; both hosts completed all six real runs, each CSV-derived verdict reported 6 blocks and 688 checks, both host verdicts passed, and the final gate passed | `work/gate-suites-20260818T215458Z-847854` |
| T5 | 2026-08-18 | Working tree | Pass: every live inventory and the gate runbook references `reporting-counts.csv`, no current expected count literal remains, and the checked historical documents are unchanged | Terminal observation |

##### Closure Evidence

- none

##### GitHub Projection

Title: Guard suite check-count coherence: fail on inventory vs actual drift
Labels: P3-low, tests
GitHub Milestone: 1.3.0
Observed State: open
Observed Labels: P3-low, tests
Observed Milestone: 1.3.0
Observed Assignee: none
Last Compared: 2026-08-18; remote updated 2026-08-18T07:39:22Z

#### M2 - EPICS_BASE entry boundary

Origin: 1.3.0 / M6
Identity History: staged from `docs/milestone-46790f9.md` M9; 1.3.0 / M6 -> 1.3.0 / M2 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 139, https://github.com/jeonghanlee/epics-ioc-runner/issues/139
Status: Not started

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

- Every affected entry point stops nonzero at its first environment boundary
  and performs no later setup or lifecycle work.
- Direct suites close every catalog identity once with no `SCRIPT_ERROR`.
- The source-regression-only selection still runs without `EPICS_BASE`.
- The real lifecycle paths remain unchanged when `EPICS_BASE` is present.

##### Dependencies And Decisions

- The 1.2.3 gate ran with the declared EPICS environment on both goldens, so
  this inconsistency does not invalidate its evidence.
- D1

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
GitHub Milestone: 1.3.0
Observed State: open
Observed Labels: P3-low, tests
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-18; remote updated 2026-08-18T07:39:22Z

#### M3 - Conf mode mismatch diagnosis

Origin: 1.3.0 / M5
Identity History: staged from `docs/milestone-46790f9.md` M8; 1.3.0 / M5 -> 1.3.0 / M3 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 142, https://github.com/jeonghanlee/epics-ioc-runner/issues/142
Status: Not started

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

- Both supported mismatch directions produce one complete diagnosis and the
  correct regeneration command.
- A third-account case does not claim either supported source mode.
- Invalid identity values still abort without rewriting the configuration.
- Tests update the error-count and message contract deliberately.

##### Dependencies And Decisions

- This is an operator-message improvement, not a validation bypass. The hard
  failure behaved correctly during the 1.2.3 verification.
- D1

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
GitHub Milestone: 1.3.0
Observed State: open
Observed Labels: enhancement, P2-medium, area/install
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-18; remote updated 2026-08-18T07:39:23Z

#### M4 - Restart supervision probe

Origin: 1.3.0 / M2
Identity History: staged from `docs/milestone-46790f9.md` M5; 1.3.0 / M2 -> 1.3.0 / M4 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 115, https://github.com/jeonghanlee/epics-ioc-runner/issues/115
Status: Not started

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

- Killing the child increases the child-death banner count and the unit
  returns to active with a new child on both golden OS families.

##### Dependencies And Decisions

- Named as a still-open coverage gap by the 1.2.3 runbook work (#131), so a
  gate record cannot read as if restart supervision had been exercised.
- D1

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
GitHub Milestone: 1.3.0
Observed State: open
Observed Labels: P2-medium, tests
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-18; remote updated 2026-08-18T07:39:23Z

#### M5 - Conf parser unification

Origin: 1.3.0 / M3
Identity History: staged from `docs/milestone-46790f9.md` M6; 1.3.0 / M3 -> 1.3.0 / M5 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 113, https://github.com/jeonghanlee/epics-ioc-runner/issues/113
Status: Not started

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

- Every divergence fixture resolves identically through install-time, runtime,
  and systemd consumers, or is rejected before deployment.
- Real install and start paths agree on the accepted artifact.

##### Dependencies And Decisions

- D1, D2
- Related: M6 (#129) is the narrow two-reader case inside this general work
  and runs in the same lane.

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
| T2 | Lifecycle integration | Install and start an IOC from the accepted divergence fixtures through the shipped commands | Both golden OS families | Install-time acceptance and runtime interpretation agree |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Source test environment | Pending | none |
| T2 | Not run | Both golden OS families | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Unify the three conf parsers behind one shared parse core
Labels: P2-medium, refactor, area/architecture
GitHub Milestone: 1.3.0
Observed State: open
Observed Labels: P2-medium, refactor, area/architecture
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-18; remote updated 2026-08-18T07:39:22Z

#### M6 - Conf value normalization

Origin: 1.3.0 / M4
Identity History: staged from `docs/milestone-46790f9.md` M7; 1.3.0 / M4 -> 1.3.0 / M6 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 129, https://github.com/jeonghanlee/epics-ioc-runner/issues/129
Status: Not started

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

- Both readers return the identical string for every whitespace- and
  quote-bearing fixture.
- Maintained lifecycle and error-handling paths remain green.

##### Dependencies And Decisions

- M5, D1, D2: the shared parse core subsumes this narrow case; this row
  follows M3 in the same lane and closes on the shared core's evidence plus
  its own reader-equivalence fixtures.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Define one trim-before-unquote value-normalization function (or adopt the
   M3 parse core directly).
2. Route `read_conf_var` and `read_conf_all` through it and remove the local
   #122 workaround when it becomes redundant.
3. Pin both readers to identical results on whitespace- and quote-bearing
   fixtures.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Reader equivalence | Pass spaces around `=`, quoted values, and quoted whitespace through both shipped readers | Source test environment | Both readers return the identical normalized string for every fixture |
| T2 | Lifecycle regression | Run the maintained error-handling and lifecycle paths with representative configuration keys | Both golden OS families | No supported key relies on preserving the divergent whitespace behavior |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Source test environment | Pending | none |
| T2 | Not run | Both golden OS families | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Unify conf-value normalization between read_conf_var and read_conf_all
Labels: bug, P3-low, area/architecture
GitHub Milestone: 1.3.0
Observed State: open
Observed Labels: bug, P3-low, area/architecture
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-18; remote updated 2026-08-18T07:39:22Z

#### M7 - Suite integrity

Origin: 1.3.0 / M7
Identity History: staged from `docs/milestone-46790f9.md` M10
GitHub Issue: 116, https://github.com/jeonghanlee/epics-ioc-runner/issues/116
Status: Not started

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
logrotate policy, or the install-time `logrotate -d` state isolation, which
1.2.4 landed (#143).

##### Completion Criteria

- The deployed oneshot completes successfully through the real user manager
  on both applicable golden environments and produces the expected rotation.
- A broken deployed `ExecStart` makes the check fail.

##### Dependencies And Decisions

- The catalog-ledger half completed in commits `f5871c7`, `1893c6e`, and
  `a60802b`; it is checked in the GitHub issue and is not remaining work.
- #143 covered install-time `logrotate -d` state isolation and shipped in
  1.2.4. This row covers the deployed runtime systemd path.
- D1

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
GitHub Milestone: 1.3.0
Observed State: open
Observed Labels: P3-low, tests
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-18; remote updated 2026-08-18T07:39:23Z

#### M8 - Human and machine output separation

Origin: 1.3.0 / M8
Identity History: staged from `docs/milestone-46790f9.md` M11
GitHub Issue: 144, https://github.com/jeonghanlee/epics-ioc-runner/issues/144
Status: Not started

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
or the accepted reporting count vectors.

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
  later milestone work rather than extending the then-active reporting
  remediation.
- The implementation must preserve the shipped reporting contract and the
  fixed check identity set.
- D1

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
GitHub Milestone: 1.3.0
Observed State: open
Observed Labels: tests
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-18; remote updated 2026-08-18T07:39:23Z

#### M9 - Milestone procedure draft fate

Origin: 1.3.0 / M10
Identity History: staged from `docs/milestone-46790f9.md` M13; 1.3.0 / M10 -> 1.3.0 / M9 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 132, https://github.com/jeonghanlee/epics-ioc-runner/issues/132
Status: Not started

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

Retroactive changes to closed release lines that reference the draft.

##### Completion Criteria

- The owner chooses one of the three fates and it is applied.
- No live document calls the surviving procedure a working draft.
- The release-cycle runbook reference remains resolvable and the two
  procedures state non-overlapping boundaries.

##### Dependencies And Decisions

- The runbook written under 1.2.3 (#131) references this draft, so whichever
  fate is chosen must keep that reference resolvable.
- D1

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
GitHub Milestone: 1.3.0
Observed State: open
Observed Labels: P3-low, docs
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-18; remote updated 2026-08-18T07:39:22Z

#### M10 - Fleet-layer reliability

Origin: 1.3.0 / M1
Identity History: staged from `docs/milestone-46790f9.md` M4; 1.3.0 / M1 -> 1.3.0 / M10 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 102, https://github.com/jeonghanlee/epics-ioc-runner/issues/102
Status: Not started

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

- The owner accepts the selected health signal before implementation.
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
- D1
- D3 places implementation after the mid-cycle while the design conversation runs from cycle start.

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
| T1 | Runtime health | Make a real IOC process remain alive while its selected health signal stops progressing | Both golden OS families | Monitoring detects the hang without waiting for process exit or a crash token |
| T2 | Fleet recovery | Interrupt a shared dependency for multiple running IOCs and restore it | Assigned fleet test environment | Monitoring exposes the synchronized failures and the documented recovery path controls restart load |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Both golden OS families | Pending | none |
| T2 | Not run | Assigned fleet test environment | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Fleet-layer reliability: restart-storm boundary and running-IOC hang detection
Labels: enhancement, P3-low, ops, area/architecture
GitHub Milestone: 1.3.0
Observed State: open
Observed Labels: enhancement, P3-low, ops, area/architecture
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-18; remote updated 2026-08-18T07:39:22Z

#### M11 - Final release

Origin: 1.3.0 / M11
Identity History: none
GitHub Issue: none
Status: Not started

##### Summary

Complete the 1.3.0 release: integrated verification of the full milestone set
on both golden OS families, the version change to 1.3.0, release execution,
and final Release Verification.

##### Scope

Release-wide ordering, the integrated gate re-run, production environment
tests, version changes, the master merge and tag, the GitHub release, and the
milestone close, following the release-cycle procedure.

##### Out of Scope

Individual milestone implementation and verification, which the M1-M10 rows
own.

##### Completion Criteria

- Every dependency row is Complete and G1 is Complete.
- The release-cycle final phase populates and passes the Integrated
  Verification, Production Environment Tests, Version Changes, Release
  Execution, and Release Verification sections below.

##### Dependencies And Decisions

- M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, G1
- D1

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Populate the release-wide ordering and integrated verification plan when
   the release-cycle final phase opens.
2. Execute version changes, release execution, and Release Verification per
   the release-cycle procedure.

##### Test Plan

Defined by the Release Verification Plan when the release-cycle final phase
opens; this milestone uses `Release Verification <k>` labels and no local T
labels.

##### Integrated Verification

To be populated by the release-cycle final phase.

##### Production Environment Tests

To be populated by the release-cycle final phase.

##### Version Changes

- Development version on this branch: 1.3.0-dev (set at cycle open).
- Release version: 1.3.0, set during the final phase.

##### Release Execution

To be populated by the release-cycle final phase.

##### Release Verification Plan

To be populated by the release-cycle final phase.

##### Release Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |

Not yet run.

##### Closure Evidence

- none

#### G1 - GitHub milestone 1.3.0

Origin: 1.3.0 / G1
Identity History: none
Status: Complete

##### Condition

The repository owner creates an open GitHub milestone named `1.3.0` on
`jeonghanlee/epics-ioc-runner`.

##### Responsible Party

Repository owner.

##### Affected Work

M11 (final release) and the GitHub projection of M1-M10, whose issues move
from the `Backlog` milestone to `1.3.0` once it exists.

##### Completion Criterion

`gh api repos/jeonghanlee/epics-ioc-runner/milestones` lists an open
milestone titled `1.3.0`.

##### Observed Result

Observed 2026-08-18: `gh api -X POST repos/jeonghanlee/epics-ioc-runner/milestones`
returned milestone number 16, title `1.3.0`, state `open`, created
2026-08-18T07:38:43Z. Recheck with
`gh api repos/jeonghanlee/epics-ioc-runner/milestones --jq '.[] | "\(.number)\t\(.state)\t\(.title)"'`.

##### Closure Evidence

- Open GitHub milestone `1.3.0`, number 16, created by the repository owner
  on 2026-08-18 (creation response recorded above).

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

No unassigned work is held on this release line; the master register
`docs/milestone-46790f9.md` owns the Backlog.

### Backlog Details

None.
