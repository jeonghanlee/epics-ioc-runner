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

Next session entry point: commit the review-accepted M8 (#144) output-boundary
implementation.
M1 through M7 are Complete and their linked issues are closed. Continue the
M10 (#102) health-signal design conversation in parallel - M10 is the largest
item and its boundary must be designed before any code.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Tests | M1 | (#148) Centralize expected reporting counts and guard runtime catalog coherence | Milestone | Complete | No | D1, D3, D4 | Complete in `f7ba3c9`; T1-T5 Pass, including the current-tree two-golden gate; [detail](#m1---suite-count-coherence-guard) |
| Environment | M2 | (#139) Stop EPICS-dependent test scripts before setup when `EPICS_BASE` is unset | Milestone | Complete | No | D1, D3 | Complete in `df30423`; T1-T5 Pass, including the canonical two-golden gate; [detail](#m2---epics_base-entry-boundary) |
| Diagnosis | M3 | (#142) Diagnose a conf/mode mismatch in one message | Milestone | Complete | No | D1, D3 | Complete in `b6547bd`; T1-T6 Pass, including the canonical two-golden gate; [detail](#m3---conf-mode-mismatch-diagnosis) |
| Reliability | M4 | (#115) Exercise restart supervision end-to-end on the goldens | Milestone | Complete | No | D1, D3 | T1-T2 Pass: the verified child recovers under the same procServ on both golden OS families, and the Debian `--oneshot` honest-red discriminates systemd replacement; [detail](#m4---restart-supervision-probe) |
| Configuration | M5 | (#113) Unify runner conf parsing and enforce systemd agreement | Milestone | Complete | No | D1, D2, D3 | Complete in `c10659d`; T1-T4 Pass. Both internal readers share one parser, and accepted deployed fixtures agree with systemd; [detail](#m5---conf-parser-unification) |
| Configuration | M6 | (#129) Unify conf-value normalization between `read_conf_var` and `read_conf_all` | Milestone | Complete | No | M5, D1, D2, D3 | Complete in `9061d2e` and `14b362f`; T1-T3 Pass and issue #129 is closed; [detail](#m6---conf-value-normalization) |
| Tests | M7 | (#116) Exercise the deployed local logrotate oneshot through systemd | Milestone | Complete | No | D1, D3 | Complete in `836311a`; T1-T3 Pass on both goldens, the canonical gate passed 758 checks per host, and issue #116 is closed; [detail](#m7---suite-integrity) |
| Tests | M8 | (#144) Separate human-readable test output from machine-readable records | Milestone | In progress | No | D1, D3 | Implementation, real-path verification, and review are complete in the working tree; commit remains; [detail](#m8---human-and-machine-output-separation) |
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
Status: Complete

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

- Implementation commit `f7ba3c97602a561a9238b4c7ec6d7f6df7bf4ef0` is
  pushed to `origin/release-1.3.0`.
- M1 / T1-T5 are Pass. The current working tree was copied and fully deployed
  to both golden hosts before the final gate evidence at
  `work/gate-suites-20260818T215458Z-847854` was recorded.
- The third-person review finding about the stale remote tree was fixed by the
  current-tree rerun; the corrected implementation passed third-person and
  second-person review with no remaining finding.
- Linked issue #148 was manually closed after its canonical body was projected
  to GitHub, observed at 2026-08-19T08:05:10Z. The implementation commit keeps
  its exact `Closes #148` footer; it becomes a no-op when the release branch
  reaches the default branch.

##### GitHub Projection

Title: Guard suite check-count coherence: fail on inventory vs actual drift
Labels: P3-low, tests
GitHub Milestone: 1.3.0
Observed State: closed
Observed Labels: P3-low, tests
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-19; remote updated 2026-08-19T08:05:10Z

#### M2 - EPICS_BASE entry boundary

Origin: 1.3.0 / M6
Identity History: staged from `docs/milestone-46790f9.md` M9; 1.3.0 / M6 -> 1.3.0 / M2 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 139, https://github.com/jeonghanlee/epics-ioc-runner/issues/139
Status: Complete

##### Summary

The dispatcher checks `EPICS_BASE` before launching an EPICS-dependent suite.
The direct local and system lifecycle suites initialize and close the real
reporter catalog, compare its expected counts, honor catalog-only mode, and
then evaluate `EPICS_BASE` as the first P00 environment boundary. A missing
value records only `epics-base-set` as FAIL, closes every later identity as
SKIP, and exits without later P00 probes, workspace or lifecycle work, or local
systemd cleanup.

##### Scope

Inventory every shipped test entry point that consumes `EPICS_BASE` and
classify its input contract. For the lifecycle dispatcher and direct lifecycle
suites, make the missing variable the first environment boundary after the
required reporter catalog work, without later lifecycle prerequisite,
privilege, workspace, compilation, systemd, or IOC work. Gate drivers that
source an operator-supplied environment file are inventory-only because their
entry contract supplies the environment before launching a suite.

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
- The owner selected the existing nonempty `WORKSPACE` state as the local
  lifecycle cleanup threshold instead of adding another lifecycle-state
  variable (conversation, 2026-08-18).
- D1

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner approved the reviewed M2 plan on 2026-08-18 ("승인").
Implementation Authorization: Owner explicitly authorized implementation of the accepted M2 plan on 2026-08-18 ("승인").
Superseded Plan Artifacts: none

1. Pin the affected entry points as the lifecycle selections of
   `tests/run-all-tests.bash` and direct execution of
   `tests/test-local-lifecycle.bash` and
   `tests/test-system-lifecycle.bash`. Record source regression and system
   infrastructure as EPICS-independent. Record the host gate drivers as
   inspected but unaffected because they source their required environment
   path before launching a suite.
2. Preserve each direct suite's real reporting sequence through
   `initialize_reporting`, `report_close_catalog`, expected-count comparison,
   and the `REPORT_CATALOG_ONLY=1` return before evaluating `EPICS_BASE`.
3. Split direct-suite P00 evaluation at the first check. When `EPICS_BASE` is
   absent, record `epics-base-set` as FAIL, close every later identity as SKIP
   with that check as the reason, and return without evaluating `lsof`, root
   invocation, or runner executability. The local P00 vector is
   `FAIL, SKIP, SKIP`; the system P00 vector is
   `FAIL, SKIP, SKIP, SKIP`.
4. Keep the dispatcher's existing environment stop before exports, `sudo`,
   collector initialization, and suite launch.
5. In the local exit handler, perform systemd timer and unit cleanup only when
   `WORKSPACE` is nonempty. Always finalize an initialized reporter. Preserve
   the existing cleanup after workspace setup begins.
6. Preserve the current remaining P00 evaluation and lifecycle execution when
   `EPICS_BASE` is present, and update the local and system lifecycle
   inventories with the boundary dependency.
7. Run the missing-environment, catalog-only, and independent
   source-regression paths, then run the canonical six-suite gate driver with
   the declared EPICS environment on both golden OS families.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Dispatcher boundary | Run the default, local, and system lifecycle selections of `tests/run-all-tests.bash` with `EPICS_BASE` unset and `bash -x`; inspect each shell trace | Debian 13 | Each exits nonzero, and its trace contains no `initialize_collector`, `sudo`, or `_run_test` execution |
| T2 | Direct-suite boundary | Run both lifecycle suites without privilege elevation, with `EPICS_BASE` unset and `bash -x`; inspect their real reporter output and shell trace | Debian 13 | Exact P00 vectors are emitted, every later identity is SKIP exactly once, and no `SCRIPT_ERROR` occurs; the trace shows reporter setup but no `lsof`, root-condition, runner-executable, optional-dependency, workspace, systemd, or IOC evaluation |
| T3 | Catalog-only precedence | Run both direct lifecycle suites with `REPORT_CATALOG_ONLY=1` and `EPICS_BASE` unset | Debian 13 | Each real catalog registers, closes, matches `reporting-counts.csv`, and exits successfully before the environment boundary |
| T4 | Independent path | Run `tests/run-all-tests.bash --source-regression` without `EPICS_BASE` | Debian 13 | Source regression executes normally |
| T5 | Positive path | Run `gate/drivers/control/suites.bash` with each golden host and its resolved absolute EPICS environment path | Both golden OS families | The real six-suite matrix and shipped fixtures finish with `GATE SUITES PASS hosts=2` |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-18 19:04 PDT | Debian 13 control host | Pass | All three dispatcher selections exited 1; each trace recorded zero `initialize_collector`, `sudo`, and `_run_test` calls; `work/m2-entry-20260819T020417Z-rerun/` |
| T2 | 2026-08-18 19:05 PDT | Debian 13 control host | Pass | The real local and system reporters emitted the planned P00 vectors, closed 146 and 102 unique checks once, and traced no prohibited later work or `SCRIPT_ERROR`; `work/m2-entry-20260819T020417Z-rerun/` |
| T3 | 2026-08-18 19:05 PDT | Debian 13 control host | Pass | The real suites emitted `CATALOG` PASS with local 146/37 and system 102/33; `work/m2-entry-20260819T020417Z-rerun/` |
| T4 | 2026-08-18 19:06 PDT | Debian 13 golden | Pass | The real dispatcher completed source regression without `EPICS_BASE`: 108 total, 107 PASS, 1 NA, 0 errors; `work/m2-entry-20260819T020417Z-rerun/t4-source-regression-debian13-golden.log` |
| T5 | 2026-08-18 20:47 PDT | Debian 13 and Rocky 8 goldens | Pass | The first canonical run failed only Rocky `system-lifecycle.S22.uds-socket-is-in-listening-state`; its bounded real-suite retry passed 102/102, and the canonical rerun finished `GATE SUITES PASS hosts=2` with six runs and 688 checks per host; `work/gate-suites-20260819T020635Z-1067055/`, `work/m2-entry-20260819T020417Z-rerun/t5-rocky-system-lifecycle-retry.log`, and `work/gate-suites-20260819T034301Z-1099453/` |

Follow-up Result: Rocky
`system-lifecycle.S22.uds-socket-is-in-listening-state` repeated once during
the M3 post-style-cleanup gate. All later Rocky lifecycle checks passed, and
the unchanged-tree canonical rerun passed. Neither failed run retained its raw
`ss -lx` snapshot.

##### Closure Evidence

- Implementation commit `df30423331639080b3ff290bbb00fc0d5ff011b8` is
  pushed to `origin/release-1.3.0`.
- M2 / T1-T5 are Pass. The final canonical two-host gate ran the real six-suite
  matrix and finished with 688 checks per host at
  `work/gate-suites-20260819T034301Z-1099453/`.
- Linked issue #139 was manually closed after this canonical result was
  projected to GitHub, observed at 2026-08-19T08:05:20Z. The implementation
  commit keeps its exact `Closes #139` footer; it becomes a no-op when the
  release branch reaches the default branch.

##### GitHub Projection

Title: Stop EPICS-dependent test scripts before setup when EPICS_BASE is unset
Labels: P3-low, tests
GitHub Milestone: 1.3.0
Observed State: closed
Observed Labels: P3-low, tests
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-19; remote updated 2026-08-19T08:05:20Z

#### M3 - Conf mode mismatch diagnosis

Origin: 1.3.0 / M5
Identity History: staged from `docs/milestone-46790f9.md` M8; 1.3.0 / M5 -> 1.3.0 / M3 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 142, https://github.com/jeonghanlee/epics-ioc-runner/issues/142
Status: Complete

##### Summary

Identity validation safely rejects a configuration whose `IOC_USER` and
`IOC_GROUP` do not match the selected execution mode, but it reports two
field-level errors and leaves the operator to infer one mode mismatch. It does
not show the values found, name the file, or provide the correct regeneration
command.

##### Scope

When `IOC_USER` and `IOC_GROUP` are both nonempty, both pass the existing
critical-variable whitelist, both differ from the selected mode, and
`IOC_CHDIR` is an absolute, existing, executable, and writable `generate`
target, count one found-versus-required mode-mismatch error. Derive the system
pair from `TARGET_SYSTEM_USER` and `TARGET_SYSTEM_GROUP`, including their
supported environment overrides. Derive the local pair once from the invoking
user's `id -un` and `id -gn` values even when system mode is selected.

An exact opposite supported pair names its source mode. Any other complete
pair receives the same comparison and remedy without a source-mode claim. A
one-field mismatch, an identity value that fails the whitelist, or an unusable
`IOC_CHDIR` retains the existing field-level identity errors instead of
presenting an incomplete mode diagnosis. Writability affects only whether the
combined remedy is available; M3 does not add a general `IOC_CHDIR`
writability error to `validate_conf`.

Emit one aligned diagnostic block with fixed label width:

```text
Error: Configuration mode mismatch
       Config     : /path/ioc.conf
       Found      : IOC_USER=ioc-srv, IOC_GROUP=ioc (system mode)
       Required   : IOC_USER=alice, IOC_GROUP=alice (local mode)
       Regenerate : ioc-runner --local generate /path/iocBoot/ioc
```

Use the operator-facing `display_name` for `Config`. Render every dynamic value
in the block with Bash `printf %q`: `display_name`, the found and required
user/group values, and the `IOC_CHDIR` command argument. Local mode uses
`--local`; system mode remains the unflagged default and has no `--system`
option. The final validation summary uses `error` for a count of one and
`errors` for every other nonzero count.

##### Out of Scope

Rewriting the configuration during install, switching modes, adding a
`--system` option, or changing the identity validation rules.

##### Completion Criteria

- Both supported mismatch directions produce one aligned diagnosis, count one
  error, and provide the correct mode-specific regeneration command.
- A third-account case produces the same aligned comparison without claiming
  either supported source mode.
- A one-field mismatch remains a field-level error. A pair mismatch with an
  invalid `IOC_CHDIR` retains the field-level and existing path errors and
  provides no invalid regeneration command. A non-writable `IOC_CHDIR` retains
  the field-level errors without adding a new path-validation error.
- An identity value that fails the whitelist cannot select the combined
  diagnosis, and its raw value does not appear in the new diagnostic block.
- Every dynamic value in a combined block is shell-safe. Ordinary values keep
  the documented readable form, while whitespace and other shell-sensitive
  characters are escaped.
- Each complete-pair diagnosis case aborts without changing its source
  configuration or creating an installed configuration. The existing
  one-field exit identity continues to pin the non-aggregated abort path.
- Singular and plural validation summaries are both pinned through real
  install paths.
- The reporting catalog, inventory, CSV count, and gate identity digest agree
  on the new fixed identity set.

##### Dependencies And Decisions

- This is an operator-message improvement, not a validation bypass. The hard
  failure behaved correctly during the 1.2.3 verification.
- The owner selected pair-level aggregation only when both identity fields
  differ; one-field mismatches retain the existing field error (2026-08-19).
- The owner selected one aligned multi-line diagnostic, inline implementation
  inside `validate_conf`, singular/plural summary grammar, and a dedicated
  S38 test step with independent semantic identities (2026-08-19).
- The owner selected existing field and path errors when `IOC_CHDIR` cannot
  supply a correct `generate` target (2026-08-19).
- The owner selected whitelist eligibility plus `%q` rendering for every
  dynamic diagnostic value, and required a writable `IOC_CHDIR` before showing
  a regeneration command (2026-08-19).
- The strengthened plan incorporates the third-person findings to classify
  `IOC_CHDIR` once, pin supported-pair sources, enumerate the count change,
  deploy the current tree to both goldens, verify shell escaping, and reconcile
  the gate identity digest across both hosts (2026-08-19).
- The owner accepted the implementation after third-person and second-person
  review on 2026-08-19. T6 completed before M3 closure.
- The owner selected permanent gate enforcement for deployed-runner
  provenance on 2026-08-19. The comparison excludes only the three metadata
  declarations that setup intentionally stamps and verifies their installed
  identity separately through `-V`.
- Existing gate history confirms that `CROSS_HOST rc=1` preserves visible,
  nonfatal OS applicability differences when both host verdicts pass. M3 T6
  accepts only the reviewed S23, S29, and S06 difference classes rather than
  requiring identical normalized records.
- D1

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner approved the reviewed M3 plan on 2026-08-19
("계획승인").
Implementation Authorization: Owner explicitly authorized M3 implementation
on 2026-08-19 ("구현승인").
Superseded Plan Artifacts: none

1. In `validate_conf`, resolve `IOC_USER`, `IOC_GROUP`, `IOC_CHDIR`, the
   invoking local user/group pair, and the configured system user/group pair
   once. Record whether each identity value passes the existing whitelist.
   Classify `IOC_CHDIR` once as relative, missing, non-executable,
   non-writable, or ready. Reuse that state in the existing path-error branch,
   but treat non-writable only as a combined-diagnosis guard so M3 does not
   introduce a new general path-validation rule.
2. Select the required pair from `EXEC_MODE` and the supported opposite pair
   from the other mode. Aggregate only a complete, whitelist-valid two-field
   mismatch with a ready `IOC_CHDIR`. Name the source mode only when the found
   pair exactly matches the supported opposite pair; otherwise omit the
   source-mode suffix.
3. Print the fixed-width `Config`, `Found`, `Required`, and `Regenerate` rows
   inside `validate_conf`. Use `printf -v ... '%q'` to prepare every dynamic
   value before rendering, `--local` only for a local remedy, and one increment
   of `error_count` for the complete pair diagnosis. Preserve the current
   per-field increments for every non-aggregated case.
4. Select `error` when `error_count` is one and `errors` otherwise, preserving
   the numeric count and abort result.
5. Add 26 fixed check identities: five each for the local mismatch, system
   mismatch, and third-account cases; two for the one-field regression; three
   for the relative-`IOC_CHDIR` boundary; three for the non-writable-
   `IOC_CHDIR` boundary; and three for the invalid-identity boundary. Each main
   case separately checks nonzero exit, the exact diagnostic block, the
   singular count, source preservation, and absence of an installed
   configuration. The boundary identities separately pin non-aggregation,
   retained errors and summary count, or absence of the raw invalid value. Pin
   the one-field case to `1 error`, the relative-path pair to `3 errors`, the
   non-writable pair to `2 errors`, and the single-whitelist-error pair to
   `3 errors`.
6. Keep the existing one-field exit identity in S25, isolate its fixture from
   unrelated command errors, and add its field-message and singular-summary
   identities there. Add S38 for the remaining 24 identities. Exercise a
   whitelist-valid system pair containing whitespace as `Found` in T1 and as
   `Required` in T2. Exercise a configuration path and `IOC_CHDIR` containing
   whitespace in T3. These three exact diagnostic cases make every dynamic
   field's `printf %q` behavior observable.
7. Extend reporter STEP registration through S38 and update
   `tests/ERROR_HANDLING_INVENTORY.md` with the same ordered identities. Change
   the sole current expected-count row to `error-handling,176,39` in
   `tests/reporting-counts.csv`; do not add count literals to live inventory or
   runbook text.
8. Run `bash -n` and repository-standard `shellcheck -S warning` checks for
   every changed Bash file. Then run the real catalog-only and error-handling
   paths, followed by `tests/lib/reporting-counts-self-test.bash` and
   `tests/lib/test-reporting-self-test.bash`.
9. Before either canonical gate, use `gate/drivers/push.bash` to synchronize the
   current tree to both goldens and run `setup-system-infra.bash --full` on each
   host. Require matching source commits and identical control/remote
   `git status` output. In the permanent gate driver, compare each pushed
   source runner with its installed runner after excluding exactly the
   `RUNNER_GIT_HASH`, `RUNNER_COMMIT_DATE`, and `RUNNER_INSTALL_DATE`
   declarations that setup stamps. Require the remaining content SHA-256 and
   the installed `-V` identity to match the remote HEAD and dirty state.
10. Leave `EXPECTED_IDENTITY_SHA256` unchanged for the initial canonical
   two-host gate and require it to fail only on the identity digest. Require
   both host verdicts to print the same candidate derived by the shipped gate
   from their real TEST records. Reconcile that common candidate with the
   accepted catalog and inventory, update the digest, and rerun `bash -n` and
   repository-standard `shellcheck -S warning` on
   `gate/drivers/control/suites.bash`. Then rerun the full canonical gate to
   PASS. Expected CSV-derived totals are six blocks, 714 checks, and 171 steps;
   the driver must derive them rather than store new aggregate literals.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local mismatch | Install an exact configured-system identity pair containing whitelist-valid whitespace with `--local` through the shipped file-direct install path | Debian 13 | Exit 1; one exact aligned block names system mode, renders the whitespace-bearing pair safely as `Found`, names the local required pair, and provides `ioc-runner --local generate <IOC_CHDIR>`; summary is `1 error`; source is unchanged and no target conf exists |
| T2 | System mismatch | Install the invoking local identity pair in default system mode with the same whitespace-bearing configured-system pair as `Required`, using the shipped file-direct install path with only the outer conf directory redirected | Debian 13 | Exit 1 after reaching `validate_conf`; one exact aligned block names local mode, renders the required pair safely, and provides an unflagged `ioc-runner generate <IOC_CHDIR>` remedy; summary is `1 error`; source is unchanged and no target conf exists |
| T3 | Unknown account and escaping | Install a complete third-account pair from a configuration path and valid `IOC_CHDIR` containing whitespace through the shipped local install path | Debian 13 | Exit 1; the exact aligned block has no source-mode suffix, every dynamic value is shell-safe, summary is `1 error`, source is unchanged, and no target conf exists |
| T4 | Non-aggregation boundaries | Run one-field, relative-`IOC_CHDIR`, non-writable-`IOC_CHDIR`, and single-whitelist-error identity cases through the shipped local install path | Debian 13 | No boundary case emits a combined block or regeneration command; the one-field case reports `1 error`, the relative-path pair reports `3 errors`, the non-writable pair reports `2 errors`, and the whitelist-invalid pair reports `3 errors` without exposing its raw invalid value |
| T5 | Source verification | Run `bash -n` and repository-standard `shellcheck -S warning` checks on changed Bash files, then catalog-only, the full error-handling suite, `tests/lib/reporting-counts-self-test.bash`, and `tests/lib/test-reporting-self-test.bash` | Source environment | Static checks pass; catalog reports 176 checks and 39 steps; the suite passes all 176 fixed identities; both named self-tests pass |
| T6 | Golden deployment and gate | Synchronize the current tree with `gate/drivers/push.bash`, run full system setup, verify source and installed runner provenance, then run the canonical two-host gate before and after the accepted identity-digest update | Debian 13 and Rocky 8 goldens | Both remote trees match the control-tree status; each installed runner matches its pushed source after excluding only the three stamped metadata declarations, and its `-V` identity matches the remote HEAD and dirty state; the first gate fails only on one common real identity digest; the updated gate driver passes `bash -n` and `shellcheck -S warning`; both hosts then pass six runs, 714 checks, and 171 steps; `cross-host.diff` contains only the accepted S23, S29, and S06 OS applicability differences, with nonfatal `CROSS_HOST rc=1` |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-19 16:31 PDT | Debian 13 source environment | Pass | The shipped file-direct local install path exited 1, emitted the exact escaped system-to-local diagnostic and singular summary, preserved the source, and created no target configuration; all five S38 identities passed in the full suite |
| T2 | 2026-08-19 16:31 PDT | Debian 13 source environment | Pass | The shipped file-direct system install path reached `validate_conf`, exited 1, emitted the exact escaped local-to-system diagnostic and singular summary, preserved the source, and created no target configuration; all five S38 identities passed in the full suite |
| T3 | 2026-08-19 16:31 PDT | Debian 13 source environment | Pass | The shipped file-direct local install path escaped the whitespace-bearing source and `IOC_CHDIR`, omitted a source-mode claim for the third-account pair, exited 1, preserved the source, and created no target configuration; all five S38 identities passed in the full suite |
| T4 | 2026-08-19 16:31 PDT | Debian 13 source environment | Pass | The real install paths retained the one-field, relative-path, non-writable-path, and whitelist errors without a combined diagnostic; the planned 1, 3, 2, and 3 error summaries and all 12 boundary identities passed |
| T5 | 2026-08-19 16:32 PDT | Source environment | Pass | `bash -n` and `shellcheck -S warning` passed; catalog-only reported 176 checks and 39 steps; the full suite passed 176 of 176 identities; reporting-counts and reporter self-tests passed 8 of 8 and 88 of 88 assertions |
| T6 | 2026-08-19 19:58 PDT | Debian 13 and Rocky 8 goldens | Pass | Both remote status listings matched the control tree; full setup passed 9 of 9 checks on Debian and 10 of 10 on Rocky; source and installed runner bodies matched on both hosts and both installed identities matched `2640dfb-dirty`; the initial gate failed only on the common real identity digest `2d73f006c5ffc7c37bea4bc21c438d6f3473f63d2ca55930641ccdcef1a87e5e`; after accepting that digest, both hosts passed six runs, 714 TEST records, and 171 STEP records; the post-style-cleanup gate repeated the existing Rocky `system-lifecycle.S22.uds-socket-is-in-listening-state` timing failure while all later checks passed, and the unchanged-tree rerun passed; Debian reported one NA and Rocky reported 12 NA; `CROSS_HOST rc=1` enumerated 77 lines containing only source-regression S23, local-lifecycle S29, and system-infra S06 applicability differences; the final gate passed | Initial digest evidence: `work/gate-suites-20260820T003541Z-33257`; accepted gate evidence: `work/gate-suites-20260820T011725Z-42855`; post-style-cleanup timing evidence: `work/gate-suites-20260820T024956Z-48794`; final accepted gate evidence: `work/gate-suites-20260820T025805Z-49933` |

##### Closure Evidence

- Implementation commit `b6547bd5aa962a665f62990cdb4b41e1cc2bf4cf` is
  pushed to `origin/release-1.3.0`.
- M3 / T1-T6 are Pass. The final canonical two-host gate ran the real six-suite
  matrix with 714 TEST records and 171 STEP records per host and finished at
  `work/gate-suites-20260820T025805Z-49933/`.
- Linked issue #142 was manually closed after its canonical body was projected
  to GitHub, observed at 2026-08-20T03:44:27Z. The close comment cites
  `b6547bd`; the implementation commit retains its exact `Closes #142` footer
  for the later default-branch merge.

##### GitHub Projection

Title: Diagnose conf/mode mismatch in one message
Labels: enhancement, P2-medium, area/install
GitHub Milestone: 1.3.0
Observed State: closed
Observed Labels: enhancement, P2-medium, area/install
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-19; remote updated 2026-08-20T03:44:27Z

#### M4 - Restart supervision probe

Origin: 1.3.0 / M2
Identity History: staged from `docs/milestone-46790f9.md` M5; 1.3.0 / M2 -> 1.3.0 / M4 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 115, https://github.com/jeonghanlee/epics-ioc-runner/issues/115
Status: Complete

##### Summary

No automated test kills a running IOC and asserts recovery; the ADR 0001
promise is pinned only by static directive-row guards.

##### Scope

An automated golden-VM probe in system-lifecycle S26 that starts a dedicated
healthy managed softIoc through the installed runner, kills only its child
with `SIGKILL`, and observes procServ recovery while systemd keeps supervising
the same procServ process.

##### Out of Scope

Changing the restart policy or replacing the existing static directive
guards.

##### Completion Criteria

- Killing the verified softIoc child increases the child-death banner count
  after the recorded log boundary and produces a new ready softIoc child on
  both golden OS families.
- The unit remains active, the procServ `MainPID` and systemd `NRestarts`
  remain unchanged, and the replacement child remains stable for the
  observation interval.

##### Dependencies And Decisions

- Named as a still-open coverage gap by the 1.2.3 runbook work (#131), so a
  gate record cannot read as if restart supervision had been exercised.
- D1

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: owner accepted option 2 and the detailed plan in chat,
2026-08-19
Implementation Authorization: owner authorized implementation in chat,
2026-08-19
Superseded Plan Artifacts: none

1. Extend system-lifecycle S26 with a dedicated healthy softIoc fixture that
   the installed runner installs and starts through the shipped systemd path.
   Remove the fixture during normal and failure cleanup.
2. Before signalling, require an active unit, identify the procServ
   `MainPID` and its direct softIoc child, and record systemd `NRestarts`, the
   child identity, and a rotation-safe procServ log boundary.
3. Send `SIGKILL` only to the verified softIoc child. Poll for at most 30
   seconds for a new child-death banner after the boundary, a replacement
   child with a different identity, and a new readiness marker after the
   death banner.
4. Require the unit to remain active, the procServ `MainPID` and systemd
   `NRestarts` to remain unchanged, and the replacement child to remain
   stable for three seconds.
5. Keep the S26 STEP identity stable. Add distinct check identities and update
   the system-lifecycle inventory, reporting count, behavior documentation,
   and gate identity digest together.
6. Run an honest-red check with the shipped unit path changed to procServ
   `--oneshot`; the unchanged-`MainPID` assertion must fail. Restore the
   shipped configuration before running the final real two-golden gate.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Restart supervision | Kill the verified child of a dedicated healthy softIoc installed through the shipped system path | Both golden OS families | A new ready child appears after a new death banner while the unit remains active and procServ `MainPID` and `NRestarts` remain unchanged |
| T2 | Honest-red discrimination | Deploy the same shipped path with procServ `--oneshot` and run the unchanged restart-supervision check | One disposable golden VM, followed by restoration | The check fails because systemd replaces procServ and changes its `MainPID` |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-23 02:18 PDT | Fresh Debian 13 and Rocky 8 consumers from the 2026-08-22 proxy-clean ioc-runner images; installed candidate `0c7b7a8-dirty` | Pass | `work/gate-suites-20260823T091343Z-845266`: both hosts completed all six runs with `rc=0`; each verdict accepted 722 checks with no FAIL, SKIP, or SCRIPT_ERROR state; the final driver reported `GATE SUITES PASS hosts=2` |
| T2 | 2026-08-23 02:03 PDT | Disposable fresh Debian 13 consumer; installed candidate `0c7b7a8-dirty`; deployed unit changed only by adding procServ `--oneshot`, then restored | Pass | `work/m4-t2-debian-20260823T090200Z.log` (`sha256:86e133e0175f0d240a42006876011ca1e13b7c17e52ff7d51d8ae017cef582e8`): the unchanged suite exited 1 with 106 PASS and the four expected S26 supervision FAIL records, including changed procServ `MainPID`; shipped full setup then restored the original unit hash with no `--oneshot` and no residual probe configuration or active unit |

##### Closure Evidence

- Implementation commit `98fafea39a74a03a663ff18f6e6d1b63aa34c29c` is
  pushed to `origin/release-1.3.0`.
- The first two-host run completed all real suite processes successfully and
  both hosts reported the same new catalog identity digest,
  `7ab4641bdac721cfaa55f6cfc1d491a3a3ff62e7c69d2bcf9634cbd26bdf5e7b`;
  only the prior expected digest was rejected.
- After updating the fixed expected digest to that observed common value, the
  complete two-host run passed. Its recorded OS differences are only the
  established `PASS`/`NA` applicability boundaries for journal access,
  sudoers regex support, and the RHEL-family setup path.
- Both image manifests are `clean-untagged`, so this result is M4 real-path
  Check evidence and is not a release Gate claim.
- Linked issue #115 was manually closed after its canonical body was projected
  to GitHub, observed at 2026-08-23T21:59:39Z. The close comment cites
  `98fafea`; the implementation commit retains its exact `Closes #115` footer
  for the later default-branch merge.

##### GitHub Projection

Title: Exercise restart supervision end-to-end on the goldens
Labels: P2-medium, tests
GitHub Milestone: 1.3.0
Observed State: closed
Observed Labels: P2-medium, tests
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-23; remote updated 2026-08-23T21:59:39Z

#### M5 - Conf parser unification

Origin: 1.3.0 / M3
Identity History: staged from `docs/milestone-46790f9.md` M6; 1.3.0 / M3 -> 1.3.0 / M5 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 113, https://github.com/jeonghanlee/epics-ioc-runner/issues/113
Status: Complete

##### Summary

`read_conf_var` and `read_conf_all` disagree on trimming, quote order,
duplicate keys, and CRLF. systemd is a separate `EnvironmentFile` parser, so
the runner needs one internal parse core plus a bounded accepted syntax whose
deployed values are proven to agree with systemd.

##### Scope

Define one pure-Bash, non-executing full-file parser for the supported
single-line assignment form. It owns key and value trimming, matching outer
quotes, empty values, values containing `=`, CRLF, and last-wins duplicate
handling. `read_conf_var`, `read_conf_all`, and install-time syntax acceptance
delegate to that parser. systemd remains external; accepted deployed files
must produce the same values through `EnvironmentFile`.

##### Out of Scope

Implementing full systemd `EnvironmentFile` multiline, continuation, quoting,
or escape grammar; changing the supported configuration keys; adding a second
configuration format; sourcing, evaluating, or executing conf content; and
changing the #122 runtime validation policy beyond removing its redundant
call-site trim after parser unification.

##### Completion Criteria

- The runner contains one assignment-parse loop, and both internal reader APIs
  delegate to it without `source`, `eval`, or command execution.
- Accepted fixtures trim surrounding space, tab, and line-ending CR before
  removing one matching outer quote pair, preserve interior whitespace, and
  resolve duplicate keys by the later assignment.
- Unsupported fixtures fail the shipped install path before an existing target
  configuration is replaced.
- The shipped install and start paths produce the same observed value through
  install validation, runtime lookup, and the real systemd manager on Debian 13
  and Rocky 8.
- An honest-red mutation of the real runner makes the unchanged divergence
  assertion fail before the candidate tree is restored.

##### Dependencies And Decisions

- D1, D2, D3
- Related: M6 (#129) is the narrow two-reader case inside this general work
  and follows M5 in the same lane.
- #62 established acceptance of surrounding assignment whitespace. #122's
  runtime call-site trim is removed only after the shared parser makes it
  redundant.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner accepted `plan20260823_192325` on 2026-08-23.
Implementation Authorization: Owner authorized P001-P006 on 2026-08-23.
Superseded Plan Artifacts: none

1. Add one pure-Bash `parse_conf_file` function that clears and fills a
   caller-owned associative map, splits at the first `=`, accepts the bounded
   single-line grammar, trims keys and values in the required order, rejects
   unsupported syntax, and applies last-wins duplicates.
2. Route `read_conf_all` and `read_conf_var` through the full-file parser while
   preserving the missing-versus-empty lookup contract. Make the shared parser
   the install-time syntax authority and propagate rejection before target
   replacement.
3. Remove the #122 `CRASH_LOG_PATTERNS_EXTRA` call-site trim only after its
   caller receives the shared normalized value.
4. Add real file-direct install fixtures covering spaces, tabs, matching
   quotes, CRLF, empty values, embedded `=`, duplicate keys, supported regex
   backslashes, unmatched quotes, continuations, and multiline input.
5. Add a probe IOC that installs the fixture through the shipped runner,
   starts it through the real systemd manager, and exposes the resulting
   environment while a runtime lookup observes a discriminator in the same
   deployed file. Run it on Debian 13 and Rocky 8, then run an honest-red
   mutation against the unchanged assertion.
6. Update affected inventories, observed reporting counts, gate identity, and
   operator configuration documentation from real results only. Allow the
   canonical gate to select one shared absolute remote repository path so an
   isolated candidate checkout can be verified without replacing the default
   checkout.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Install contract | Run accepted and rejected fixtures through the shipped file-direct install path with only outer boundaries redirected | Source test environment | Accepted fixtures reach target staging with the expected value; rejected fixtures exit nonzero before replacing an existing target |
| T2 | External consumer agreement | Install and start a probe IOC through the shipped runner and real systemd manager, then observe its environment and the runtime discriminator | Debian 13 and Rocky 8 goldens | Install validation, runtime lookup, and systemd report the same last-wins normalized value for every accepted fixture |
| T3 | Honest red | Restore the old first-wins or trim-order defect in the real runner and run the unchanged T2 assertion before restoring the candidate | Debian 13 and Rocky 8 goldens | The exact divergence assertion fails under the mutation and passes again after restoration |
| T4 | Regression and identity | Run static checks, catalog-only modes, maintained reporting self-tests, full affected suites, inventory agreement, and the canonical two-host gate | Source environment plus Debian 13 and Rocky 8 goldens | All maintained checks pass; counts and gate identity come only from observed real catalogs |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-24 09:45 PDT | Source runner on Debian 13 and Rocky 8 goldens | Pass: the shipped file-direct install matrix completed 189/189 checks on each host; S39 passed all 13 accepted, rejected, preservation, duplicate, empty, embedded-`=`, CRLF, and regex-backslash assertions | `work/gate-suites-20260824T164017Z-3835511/vmadmin_192.168.122.50.log`; `work/gate-suites-20260824T164017Z-3835511/vmadmin_192.168.122.150.log` |
| T2 | 2026-08-24 09:45 PDT | Debian 13 and Rocky 8 goldens | Pass: each real installed system-lifecycle run completed 118/118 checks; S33 passed all 8 install, deployed-file, runtime-lookup, systemd-value, working-directory, and cleanup assertions | `work/gate-suites-20260824T164017Z-3835511/vmadmin_192.168.122.50.log`; `work/gate-suites-20260824T164017Z-3835511/vmadmin_192.168.122.150.log` |
| T3 | 2026-08-24 09:40 PDT | Debian 13 and Rocky 8 goldens | Pass: applying the first-wins defect to the real installed runner made the unchanged suite exit 1 with exactly the 8 S33 checks failing and the other 110 checks passing on each host; both installed runners were restored to SHA-256 `2f929c611d2746fc6a02c1a7be96d90038c242fec6521a87cab1309e6d5bdbb3` before T4 | `work/m5-honest-red-debian-20260824.log` (`sha256:7156851975ed2cc98ee160bc583caba78186fa6c238fe542d873dbd6ecf69560`); `work/m5-honest-red-rocky-20260824.log` (`sha256:2f88a6ebb71e5b79b224b8808ba02ef971d4522d657c48770401928d386435b7`) |
| T4 | 2026-08-24 09:47 PDT | Source environment plus Debian 13 and Rocky 8 goldens | Pass: `bash -n`, warning-level `shellcheck`, and `git diff --check` passed; all five catalogs passed at 189/40, 108/18, 146/37, 36/7, and 118/34; reporting self-tests passed 8/8 and 88/88; the alternate-path canonical gate verified matching source and installed runner bodies, six successful runs and 743 checks per host, then reported `GATE SUITES PASS hosts=2` | `work/gate-suites-20260824T164017Z-3835511`; terminal observation for local static, catalog, and self-tests |

##### Closure Evidence

- Implementation commit `c10659d8852f73f508d434ffa18bd410b8f12399` is
  pushed to `origin/release-1.3.0`.
- Implementation and reader-seat review are complete. Post-implementation
  review: `docs/review_sessions/20260823_192315_m5-conf-parser-contract/reviews/rev20260824_094708_codex_gpt5_post_implementation.md`.
- The final restored-candidate gate is
  `work/gate-suites-20260824T164017Z-3835511/`.
- Linked issue #113 was manually closed after its canonical body was projected
  to GitHub, observed at 2026-08-24T17:16:05Z. The close comment cites
  `c10659d`; the implementation commit retains its exact `Closes #113` footer
  for the later default-branch merge.

##### GitHub Projection

Title: Unify runner conf parsing and enforce systemd agreement
Labels: P2-medium, refactor, area/architecture
GitHub Milestone: 1.3.0
Observed State: closed
Observed Labels: P2-medium, refactor, area/architecture
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-24; remote updated 2026-08-24T17:16:05Z

#### M6 - Conf value normalization

Origin: 1.3.0 / M4
Identity History: staged from `docs/milestone-46790f9.md` M7; 1.3.0 / M4 -> 1.3.0 / M6 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 129, https://github.com/jeonghanlee/epics-ioc-runner/issues/129
Status: Complete

##### Summary

M5 routes `read_conf_var` and `read_conf_all` through one shared parser, but no
direct fixture invokes both reader APIs and compares their resulting values.
M6 closes that evidence gap without changing the production parser.

##### Scope

A logic-level direct test reads the shipped `parse_conf_file`,
`read_conf_var`, and `read_conf_all` function definitions from
`bin/ioc-runner`. It compares each present value against an independent
expected value through both reader APIs and preserves their documented empty
and missing-key states.

##### Out of Scope

Changes to `bin/ioc-runner`, the bounded parser grammar, systemd
`EnvironmentFile` behavior, or the `CRASH_LOG_PATTERNS_EXTRA` runtime policy.

##### Completion Criteria

- Both reader APIs expose the same expected value for every present
  whitespace- and quote-bearing fixture.
- A quoted empty value remains present and empty through both APIs. A missing
  key remains absent from the full map while `read_conf_var` returns 1.
- An isolated runner carrying the exact pre-M5 `read_conf_var` makes the named
  unchanged equivalence checks fail.
- Maintained error-handling and system-lifecycle paths remain green on Debian
  13 and Rocky 8.

##### Dependencies And Decisions

- M5, D1, D2: the shared parse core subsumes this narrow case; this row
  follows M5 in the same lane and closes on the shared core's evidence plus
  its own reader-equivalence fixtures.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner selected the direct-function option and directed all
third-person review findings to be applied on 2026-08-24.
Implementation Authorization: Owner selected implementation option 1 on
2026-08-24 ("1"): implement M6, then run the new and maintained suites in an
isolated Rocky 8 workspace.
Superseded Plan Artifacts: none

1. Before test-code edits, record owner acceptance of this direct-verification
   plan and explicit implementation authorization.
2. Add a fail-closed test helper that reads anchored function ranges from the
   selected `bin/ioc-runner`, requires exactly one source and generated
   definition for each of `parse_conf_file`, `read_conf_var`, and
   `read_conf_all`, requires nonempty output, and passes `bash -n` before the
   generated source is loaded.
3. Add stable reader-equivalence check identities for surrounding spaces,
   surrounding tabs, matching single and double quotes, preserved interior
   whitespace, quoted whitespace-only values, quoted empty values, and the
   intentional missing-key API states according to the Direct Fixture Matrix
   below. Compare each present reader result independently with its expected
   value rather than comparing only the two readers with each other.
4. After the Rocky 8 golden is free of other work, copy the full candidate
   tree to an isolated workspace there and replace only `read_conf_var` with
   its exact definition from
   `a3801003f25dbadebde8da7a3e3d649fc4af4712`. Run the unchanged new test and
   require every check marked `FAIL` in the Direct Fixture Matrix to report
   FAIL, then discard the copy and confirm the candidate tree remains
   unchanged.
5. Run static checks, catalogs, reporting self-tests, both maintained affected
   suites, and the canonical two-host gate. Update inventories, observed
   reporting counts, gate identity, test documentation, and verification
   records only from real results. Use `tests/README.md`, section "Test
   Execution", for suite commands and `gate/RUNBOOK.md`, section "Gate steps",
   for the canonical driver procedure.

##### Direct Fixture Matrix

| Check Identity | Input | Expected Current State | Pre-M5 `read_conf_var` Outcome |
| --- | --- | --- | --- |
| `error-handling.S40.reader-equivalence.exact-function-extraction` | The three anchored function ranges from the selected runner | Exactly one definition each; generated source is nonempty and passes `bash -n` | `PASS` |
| `error-handling.S40.reader-equivalence.surrounding-spaces` | `M6_VALUE = alpha` | Full map contains `alpha`; single-key reader returns 0 and `alpha` | `FAIL` |
| `error-handling.S40.reader-equivalence.surrounding-tabs` | `M6_VALUE\t=\tbravo` | Full map contains `bravo`; single-key reader returns 0 and `bravo` | `FAIL` |
| `error-handling.S40.reader-equivalence.single-quoted-interior-whitespace` | `M6_VALUE = ' charlie '` | Both values are ` charlie ` with length 9 | `FAIL` |
| `error-handling.S40.reader-equivalence.double-quoted-interior-whitespace` | `M6_VALUE = " delta "` | Both values are ` delta ` with length 7 | `FAIL` |
| `error-handling.S40.reader-equivalence.single-quoted-whitespace-only` | `M6_VALUE = '   '` | The key is present through both APIs with three space bytes | `FAIL` |
| `error-handling.S40.reader-equivalence.double-quoted-whitespace-only` | `M6_VALUE = "   "` | The key is present through both APIs with three space bytes | `FAIL` |
| `error-handling.S40.reader-equivalence.quoted-empty-present` | `M6_VALUE = ""` | The key is present through both APIs with an empty value; single-key reader returns 0 | `FAIL` |
| `error-handling.S40.reader-equivalence.missing-key-api-states` | `M6_OTHER=present` | Full-file parsing returns 0 with `M6_VALUE` absent; single-key reader returns 1 | `PASS` |

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Reader equivalence | Load the three exact function definitions from the selected runner and pass the accepted whitespace, quote, empty, and missing-key fixtures through both APIs | Debian 13 and Rocky 8 source-tree runs | Every present fixture equals its independent expected value through both APIs; empty and missing keys retain their documented states |
| T2 | Honest red | Replace only `read_conf_var` in an isolated full-tree copy with its exact definition from `a3801003f25dbadebde8da7a3e3d649fc4af4712` and run the unchanged new test after the host is free | Rocky 8 golden, isolated source-tree copy | Every Direct Fixture Matrix row marked `FAIL` reports FAIL; the two rows marked `PASS` remain passing; the candidate tree remains unchanged |
| T3 | Regression and identity | Run static checks, catalogs, reporting self-tests, maintained error-handling and system-lifecycle suites, inventory agreement, and the canonical gate | Source environment plus Debian 13 and Rocky 8 goldens | All maintained checks pass and counts and gate identity come only from observed real catalogs |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-24 12:22 PDT | Debian 13 control host and Rocky 8 golden, source-tree runs | Pass: each real error-handling suite completed 198/198; S40 extracted the exact three shipped definitions and passed all nine whitespace, quote, empty, and missing-key checks | `work/m6-rocky8-s40/m6-debian13-current.log`; `work/m6-rocky8-s40/m6-rocky-current.log` |
| T2 | 2026-08-24 12:22 PDT | Rocky 8 golden, isolated source-tree copy | Pass: replacing only `read_conf_var` with the exact `a3801003` definition made the seven matrix rows marked `FAIL` fail while extraction and missing-key states passed; the current runner was restored byte-for-byte before the isolated copy was removed | `work/m6-rocky8-s40/m6-rocky-pre-m5.log`; terminal observation |
| T3 | 2026-08-24 17:36 PDT | Fresh Debian 13 and Rocky 8 golden consumers from matched supplier commits | Pass: static checks, all five real catalogs, reporting self-tests, the 198-entry inventory comparison, maintained error-handling and system-lifecycle paths, and the canonical two-host gate passed. Each host completed six suite blocks and 752 checks; the final gate accepted the expected OS-specific NA differences and reported PASS | `work/m6-rocky8-s40/m6-extraction-fail-closed.log`; `work/m6-debian13-golden/system-lifecycle.log`; `work/gate-suites-20260825T003641Z-1024751` |

##### Closure Evidence

- Direct reader-equivalence coverage commit
  `9061d2e0012b1ab4fd091669f1f9489c40f018bf` is pushed to
  `origin/release-1.3.0`.
- Observed gate identity and matched two-host verification commit
  `14b362fbb7a0252f430f3da53cd1b23e4ba94ef2` is pushed to
  `origin/release-1.3.0`.
- The final matched-consumer gate is
  `work/gate-suites-20260825T003641Z-1024751/`.
- Linked issue #129 was manually closed after its canonical body was projected
  to GitHub, observed at 2026-08-25T01:17:08Z. The close comment cites
  `9061d2e` and `14b362f`; the gate commit retains its exact `Closes #129`
  footer for the later default-branch merge.

##### GitHub Projection

Title: Unify conf-value normalization between read_conf_var and read_conf_all
Labels: bug, P3-low, area/architecture
GitHub Milestone: 1.3.0
Observed State: closed
Observed Labels: bug, P3-low, area/architecture
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-24; remote updated 2026-08-25T01:17:08Z

#### M7 - Suite integrity

Origin: 1.3.0 / M7
Identity History: staged from `docs/milestone-46790f9.md` M10
GitHub Issue: 116, https://github.com/jeonghanlee/epics-ioc-runner/issues/116
Status: Complete

##### Summary

The original issue contained two test-integrity gaps. The shared reporter now
closes the executed-versus-counted gap: every suite declares a complete
catalog, records one terminal state per identity, and resolves missing or
duplicate results as `SCRIPT_ERROR`. The current M7 implementation addresses
the remaining gap: the local lifecycle suite starts the deployed
`epics-logrotate.service` through the user systemd manager and verifies its
result, rotation effects, and isolated runtime state.

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

Plan Status: accepted
Plan Acceptance: owner accepted, 2026-08-25
Implementation Authorization: owner authorized, 2026-08-25
Superseded Plan Artifacts: none

1. Extend the existing S15 copytruncate check rather than adding or renumbering
   lifecycle steps. Create a log larger than the deployed `maxsize 50M` limit
   under the suite's isolated `IOC_RUNNER_LOCAL_LOG_DIR`.
2. Start the deployed `epics-logrotate.service` with `systemctl --user` and
   verify the manager reports a successful oneshot result.
3. Verify that the deployed path creates the compressed archive, truncates the
   live log, creates `%t/ioc-runner-logrotate.state`, and leaves the system
   default logrotate state unchanged.
4. Provide an isolated test mutation that replaces the deployed unit's
   `ExecStart` with a failing command, reloads the user manager, and runs the
   same S15 check through `systemctl --user`. The mutation run must fail, and
   cleanup must restore the original unit and user-manager state on every exit.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Runtime unit | Run the extended S15 check through the deployed user service | Debian and Rocky goldens where the user manager is available | The manager reports success, `.1.gz` is created, and the live log is empty |
| T2 | Honest red | Run the same S15 check with only the deployed `ExecStart` changed to a failing command | Golden VM test workspace | The shipped suite exits nonzero and reports the service-path check as failed |
| T3 | State isolation | Compare the runtime state path and system default state before and after T1 | Both applicable goldens | `%t/ioc-runner-logrotate.state` is created and the system default state is unchanged |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-25 02:06 PDT | Debian 13 and Rocky 8 goldens, source and installed runners | Pass: S15 completed 7/7 checks through the deployed user service in all four runs; each host completed six suite blocks and 758 checks | `work/m7-local-lifecycle-debian13.log`; `work/m7-local-lifecycle-rocky8.log`; `work/gate-suites-20260825T090106Z-1465094` |
| T2 | 2026-08-25 10:00 PDT | Debian 13 and Rocky 8 golden workspaces, source runner | Pass: the temporary `ExecStart=/bin/false` drop-in made `local-lifecycle.S15.oneshot-result-success` fail and both suites exit 1; cleanup preserved a pre-existing empty override directory, and the guard refused and preserved a dangling override-file symlink | `work/m7-review-empty-dir-debian13.log`; `work/m7-review-empty-dir-rocky8.log`; `work/m7-review-dangling-symlink-debian13.log`; `work/m7-review-dangling-symlink-rocky8.log` |
| T3 | 2026-08-25 02:06 PDT | Debian 13 and Rocky 8 goldens, source and installed runners | Pass: every S15 run created `%t/ioc-runner-logrotate.state` while the readable system default state fingerprint remained unchanged | `work/gate-suites-20260825T090106Z-1465094`; post-run state-path observations |

##### Closure Evidence

- The catalog-ledger half remains complete in `f5871c7`, `1893c6e`, and
  `a60802b`.
- The runtime unit path and broken-`ExecStart` discrimination passed T1-T3 on
  2026-08-25. Static checks, all five catalogs, both reporting self-tests, and
  the canonical two-host gate also passed; the gate recorded six blocks and
  758 checks per host in `work/gate-suites-20260825T090106Z-1465094`.
- On both goldens, the T2 revision ran the real source suite after preparing
  either an empty override directory or a dangling override-file symlink. The
  suite preserved the empty directory, refused and preserved the symlink, and
  left no override residue after the review-owned artifacts were removed.
- Implementation commit `836311ae305370fe37d9a6980ca124ff996f0324` is
  pushed to `origin/release-1.3.0`.
- Implementation review found no blocking defect.
- Linked issue #116 was manually closed after its canonical body was projected
  to GitHub, observed at 2026-08-25T17:58:39Z. The close comment cites
  `836311a`; the implementation commit retains its exact `Closes #116` footer
  for the later default-branch merge.

##### GitHub Projection

Title: Extend suite integrity: tripwire port and the M19 oneshot under systemd
Labels: P3-low, tests
GitHub Milestone: 1.3.0
Observed State: closed
Observed Labels: P3-low, tests
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-25; remote updated 2026-08-25T17:58:39Z

#### M8 - Human and machine output separation

Origin: 1.3.0 / M8
Identity History: staged from `docs/milestone-46790f9.md` M11
GitHub Issue: 144, https://github.com/jeonghanlee/epics-ioc-runner/issues/144
Status: In progress

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
- D1: default invocations emit human output only;
  `REPORT_MACHINE_OUTPUT=1` reserves standard output for complete machine
  records and routes human output to standard error.
- D2: `REPORT_CATALOG_ONLY=1` takes precedence and preserves its single
  standard-output `CATALOG` record.
- D3: one shared per-file validator is used by the dispatcher and gate; the
  gate's existing digest remains the exact six-run identity authority.
- D4: remote login shells own per-run machine and human evidence files outside
  producer sudo boundaries.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: accepted 2026-08-25
Implementation Authorization: all plan items P001-P006 authorized 2026-08-25
Superseded Plan Artifacts: none

1. Add the reporter output boundary and same-process projection checks.
2. Add one structural validator for a complete suite machine-record file.
3. Make the dispatcher capture, validate, and conditionally emit child machine
   blocks while retaining the human report separately.
4. Make the gate verify and retain per-run machine and human evidence before
   aggregate identity and matrix checks.
5. Verify the real producer, dispatcher, privilege, remote-shell, and gate
   paths, then update maintained documentation and ADR 0002.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Reporter contract | Run the shipped reporter self-test through its public API | Working tree | Human and machine outputs reconcile to one ledger while using separate surfaces |
| T2 | Collector integration | Run the shipped collector probe and a real source-regression dispatcher path | Debian 13 | The operator output stays concise and the collector validates the complete machine record sequence |
| T3 | Producer integration | Run all five shipped producer paths | Both golden OS families | Every fixed identity closes once and both output surfaces carry the same suite result |
| T4 | Static and catalog boundary | Run Bash parse, warning-level shellcheck, whitespace checks, and all five real catalog-only entry points with both output modes selected | Working tree | Static checks pass and every catalog emits only its one accepted `CATALOG` record |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-25 20:12 PDT | Working tree, Debian 13, Rocky Linux 8 | Pass: reporter 113/113 locally; validator 66/66 and count parser 8/8 locally and on both goldens | Terminal observation |
| T2 | 2026-08-25 20:12 PDT | Debian 13 and Rocky Linux 8 | Pass: source-regression dispatcher runs produced one validated 108-check, 18-STEP block on both goldens; Debian direct-user local, root-to-user local, and passwordless sudo system routes returned 187, 187, and 197 machine records with no mixed output; default dispatcher mode emitted no execution records | `work/gate-suites-20260826T030650Z-2686588`; terminal observation |
| T3 | 2026-08-25 20:12 PDT | Debian 13 and Rocky Linux 8 | Pass: both hosts completed six validated blocks and 758 checks; all twelve per-run machine files passed the shared validator; final gate result was PASS | `work/gate-suites-20260826T030650Z-2686588` |
| T4 | 2026-08-25 18:40 PDT | Working tree | Pass: parse, warning-level shellcheck, and whitespace checks passed; the five real catalogs emitted only accepted records at 198/41, 108/18, 149/37, 36/7, and 118/34 | Terminal observation |

##### Closure Evidence

- Implementation and real-path verification are complete in the working tree.
- Commit, GitHub projection, and milestone closure remain pending.

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

- Issues #148 and #139 were manually closed after verification on 2026-08-19.
  Their implementation commits retain exact `Closes` footers, which become
  no-ops when the release branch reaches the default branch.
- Remaining release actions will be populated by the release-cycle final
  phase.

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
