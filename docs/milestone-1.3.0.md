# Work Register

Release line: 1.3.0
Milestone index: 1.3.0
Canonical path: `docs/milestone-1.3.0.md`
Canonical branch or ref: `release-1.3.0`
Git upstream: `origin/release-1.3.0`
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `1.3.0`,
number 16
Activation state: active on `release-1.3.0`; initial source authority moved in
master commit `05c49629e2cbc2a61414303a1c26fbd3b9acc601`. Authority for M12 and
M13 moved in master commit `757dcd2464d34d616a32fe7175ba9371ddc8e92c`
to target commit `36396b371464575ad325d3ed0bd18b02281495d8`.

Next session entry point: reconcile and close issue #150 under Issue authority,
record the closed read-back, mark M14 Complete, and land its closure evidence.
M15 Release Verification 2 is Fail at candidate `9890227`; Release
Verification 3 and 4 remain Pending.

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
| Tests | M8 | (#144) Separate human-readable test output from machine-readable records | Milestone | Complete | No | D1, D3 | Complete in `ee40e5a`; T1-T4 Pass, including the two-golden gate, and issue #144 is closed; [detail](#m8---human-and-machine-output-separation) |
| Docs | M9 | (#132) Settle the fate of the `docs/MILESTONE_PROCEDURE.md` working draft | Milestone | Complete | No | D1, D3 | Complete in this repository `a8bfdcd` with the shared skill source applied upstream; T1-T6 and both upstream readbacks Pass; issue #132 is closed; [detail](#m9---milestone-procedure-draft-fate) |
| Reliability | M10 | (#102) Runner-owned reliability checks: configuration, log path, and procServ executable | Milestone | Complete | No | D1, D3, D5, D6, D7, D8, D9, D11 | Complete in `4f2caab`; T1-T3 Pass on both goldens, M10-2 is an examined no-action result, and issue #102 is closed; [detail](#m10---fleet-layer-reliability) |
| Install | M11 | (#149) Align custom service identity teardown with installation | Milestone | Complete | No | M10, D1, D10, D13 | Complete in `7894b1d`; T1-T5 Pass on Debian 13 and Rocky 8, and issue #149 is closed; [detail](#m11---custom-identity-teardown-agreement) |
| Tests | M12 | (#146) Validate the current Rocky 8 golden through downstream runner suites | Carry-forward | Complete | No | M11, D12, D14 | Complete in `86094f0`; T1-T2 Pass on a fresh Rocky 8 consumer from the current image workflow, and issue #146 is closed; [detail](#m12---current-rocky-golden-downstream-validation) |
| Install | M13 | (#120 item 3) Validate SELinux contexts on system policy deployments | Milestone | Complete | No | M12, D12, D15, D16 | Complete in `1647f8a` and `7c9f590`; T1-T6 Pass, including production acceptance on an owner-authorized SELinux-enforcing IOC host, and issue #120 is closed; [detail](#m13---selinux-context) |
| Reliability | M14 | (#150) Keep inspect alive when process context changes during restart | Milestone | In progress | No | M10, D20 | T1-T3 Pass on clean pushed commit `63c7f82`; issue #150 closure and closure-evidence landing remain; [detail](#m14---inspect-process-context-churn) |
| Release | M15 | Final release 1.3.0 | Milestone | In progress | No | M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13, M14, G1, D17, D18, D19, D20 | Release Verification 1 and 5 are Pass; Release Verification 2 is Fail at `9890227`, and M14 blocks further release verification; [detail](#m15---final-release) |
| Tracker | G1 | GitHub milestone 1.3.0 exists | External gate | Complete | No | | Repository owner created open GitHub milestone 1.3.0, number 16, on 2026-08-18; [detail](#g1---github-milestone-1.3.0) |

### Decisions

| ID | Decision | Source |
| --- | --- | --- |
| D1 | Open 1.3.0 as a reliability-and-configuration-contract line carrying #102, #115, #113, #129, #142, #139, #116, #144, #148, and #132. #127 (container execution mode) is excluded to a later cycle as a standalone feature. | Owner decision, 2026-08-17; recorded as D2 in `docs/milestone-46790f9.md` |
| D2 | Run M5 and M6 as one configuration-contract lane: M6 is the narrow two-reader case that M5's shared parse core subsumes, so M6 follows M5 and closes on the shared core's evidence plus its own reader-equivalence fixtures. | Owner-accepted lane pairing, 2026-08-17 |
| D3 | Execute the cycle in local ID order M1 (#148), M2 (#139), M3 (#142), M4 (#115), M5+M6 (#113/#129 lane), M7 (#116), M8 (#144), M9 (#132); M10 (#102) runs its design conversation from cycle start with implementation placed after the mid-cycle. Local IDs were renumbered to match this order; each detail's Identity History records its prior ID. | Owner decision, 2026-08-18 |
| D4 | M1 centralizes expected check and STEP counts in `tests/reporting-counts.csv`. Runtime catalogs remain the independent actual values, and the CSV is initially populated only from pre-change observations of the five real shipped suite paths. The reporter's existing five-suite set becomes a public supported-suite contract that independently validates CSV membership. Normal suite runs compare immediately after catalog close; `REPORT_CATALOG_ONLY=1` performs the same comparison and then exits through a reporter-owned cleanup state before environment preflight, emitting exactly one `CATALOG suite=<suite> checks=<checks> steps=<steps> state=PASS` line on success. The gate's six-run execution set remains independent and joins to the CSV for per-suite expectations and derived totals. Live expectation documents reference the CSV; historical observed counts remain unchanged. | Owner design direction, 2026-08-18; third-person and second-person review findings accepted 2026-08-18 |
| D5 | Keep M10 as one milestone and implement M10-2, M10-3, M10-4, and M10-5 in that order. M10-1 and M10-6 remain outside this repository's implementation boundary. Scope-fit scores of 1-2 exclude an item, 3 require boundary revision, and 4-5 retain it. | Decision Date: 2026-08-28 |
| D6 | Exclude M10-4 from implementation. Linux `hard` NFS mounts retry requests indefinitely, while `soft` and `softerr` can risk silent data corruption; `ioc-runner` therefore cannot guarantee a bounded command return without imposing a host mount policy. NFS availability and mount policy remain host responsibilities. This supersedes the M10-4 portion of D5. | Decision Date: 2026-08-28 |
| D7 | Implement the retained M10 checks with an install-owned configuration hash and a dedicated launch helper for M10-2, a create-write-delete log-path probe for M10-3, and an on-demand systemd PID, UDS, and executable-identity comparison for M10-5. Hash mismatch blocks activation without a restart loop; log-path failure blocks `start` and `restart` but only warns during `inspect`; executable drift only warns and never changes process state. | Decision Date: 2026-08-28 |
| D8 | Replace the M10-2 hash portion of D7 with activation-time validation of the deployed configuration. Preserve the established group-writable configuration and shared-operator contracts; valid direct edits remain eligible for activation, while validation failure exits 78 and prevents a restart loop. Add no hash state, migration baseline, sudo command, or account-model change. | Decision Date: 2026-08-29 |
| D9 | Do not implement M10-2. On the minimum supported systemd 239, a main-process restart exception cannot distinguish a launch validator from procServ after `exec`; the pinned procServ `073f290` can return a child exit code or an errno, so no numeric status is reserved for validation. A parent wrapper would replace procServ as `MainPID`, while self-stop would expand the sudo contract. Preserve the direct procServ `MainPID`, indefinite `Restart=always` policy, shared configuration, and current sudo model. This supersedes D8 and the M10-2 portion of D5. | Decision Date: 2026-08-29 |
| D10 | Keep the custom service identity teardown seam in the 1.3.0 release as M11, after M10 and before the final release phase. Renumber the prior final release row from M11 to M12. | Decision Date: 2026-08-30 |
| D11 | Use `/usr/sbin/runuser` for the already-root system `inspect` log probe to assume the effective unit `User=` and `Group=`. Do not add a nested sudoers rule; require the `util-linux` runtime dependency. | Decision Date: 2026-08-30 |
| D12 | Assign #146 and #120 item 3 to the 1.3.0 release after M11, in that order. #146 becomes M12 and moves to Not started when source authority transfers. #120 item 3 becomes M13 and remains Conditional until a production SELinux-enforcing IOC host is confirmed. Renumber the final release row from M12 to M14 and require both new rows to complete before release execution. | Decision Date: 2026-08-30 |
| D13 | Resolve the uninstall identity and system log path from the deployed `epics-@.service` `User=`, `Group=`, and `ExecStart=...--logfile=` values. Accept only one absolute logfile template ending in `/%i.log`, derive a non-root existing parent directory, and stop before any metadata change when a value is missing, ambiguous, or unsafe. Require the operator to confirm the resolved values and whether the log directory was created exclusively for this installation. Transfer retained logs to `root:root` and remove identity ACL entries only for a confirmed dedicated log directory; otherwise preserve its observed pre-teardown metadata and retain the related account and group. Delete any remaining account or group only when the operator separately confirms it was created exclusively for this installation and has no other use. Keep the deployed unit available as the identity source until all identity-dependent log and account work completes, then remove it. | Decision Date: 2026-08-31 |
| D14 | Produce a new Rocky 8 golden for M12 and pin its `epics-ioc-runner` input to `release-1.3.0`. Do not use an earlier golden as M12 evidence. | Decision Date: 2026-08-31 |
| D15 | Correct the M13 policy-file context only when SELinux is active: run `restorecon` after deploying `/etc/sudoers.d/10-epics-ioc` and `/etc/logrotate.d/procserv`, then require `matchpathcon -V` to accept each final path. Keep the Debian path unchanged and do not require SELinux tools when SELinux is unavailable. | Decision Date: 2026-08-31 |
| D16 | Treat the enforcing Rocky 8 testbed observation as the M13 implementation activation condition and move M13 to Not started. Keep an enforcing production IOC host as a completion condition, not an implementation prerequisite. This supersedes only the M13 activation portion of D12. | Decision Date: 2026-08-31 |
| D17 | Build new Debian 13 and Rocky 8 release-gate images from baseline tag `1.2.4`, then create fresh consumers from that pair for M15. Do not reuse an earlier consumer or accept an unpinned image pair as final release evidence. | Decision Date: 2026-08-31 |
| D18 | Retain every existing `release-1.2.x` branch during the 1.3.0 release. Do not delete a historical release branch as part of M15. | Owner decision, 2026-08-31 |
| D19 | Do not open a new release line at 1.3.0 closure. Keep #127 Deferred in the master Backlog, and make that surviving Backlog entry the next canonical entry point. | Owner decision, 2026-08-31 |
| D20 | Insert issue #150 as M14 before the final release milestone, renumber the final release milestone from M14 to M15, and require M14 to complete before M15 resumes Release Verification 2. | Decision Date: 2026-09-02 |

### ID Migration

| Old ID | Current ID | Reason | Updated References |
| --- | --- | --- | --- |
| M11 | M15 | Insert M11 for custom identity teardown, then M12 and M13 for the two Backlog transfers and M14 for issue #150 before the final release phase (D10, D12, D20). | Work table, final release detail, dependencies, and G1 affected work |
| M14 | M15 | Insert M14 for issue #150 before the final release milestone (D20). | Work table, final release detail, dependencies, and G1 affected work |

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
| 46790f9 / M3 -> 1.3.0 / M12 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `36396b371464575ad325d3ed0bd18b02281495d8` | `757dcd2464d34d616a32fe7175ba9371ddc8e92c` |
| 46790f9 / M1 -> 1.3.0 / M13 | `master`, `docs/milestone-46790f9.md` | `release-1.3.0`, `docs/milestone-1.3.0.md` | `36396b371464575ad325d3ed0bd18b02281495d8` | `757dcd2464d34d616a32fe7175ba9371ddc8e92c` |

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
Status: Complete

##### Summary

The shipped test paths separate the human report from the machine-readable
`TEST`, `STEP`, and `SUITE` record sequence. Both surfaces derive from the
same validated ledger, and collectors consume only complete machine-record
blocks.

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
- The implementation preserves the shipped reporting contract and the fixed
  check identity set.
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
   paths.
6. Update the maintained reporting documentation, test README, gate runbook,
   ADR 0002, ADR index, and milestone evidence.

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
| T1 | 2026-08-25 20:12 PDT | Working tree, Debian 13, Rocky Linux 8 | Pass: reporter 113/113 locally; validator 66/66 and count parser 8/8 locally and on both goldens | Direct execution of the shipped self-tests |
| T2 | 2026-08-25 20:12 PDT | Debian 13 and Rocky Linux 8 | Pass: source-regression dispatcher runs produced one validated 108-check, 18-STEP block on both goldens; Debian direct-user local, root-to-user local, and passwordless sudo system routes returned 187, 187, and 197 machine records with no mixed output; default dispatcher mode emitted no execution records | Direct execution through the shipped dispatcher and privilege routes |
| T3 | 2026-08-25 20:12 PDT | Debian 13 and Rocky Linux 8 | Pass: both hosts completed six validated blocks and 758 checks; all twelve per-run machine files passed the shared validator; final gate result was PASS | Direct execution of the shipped two-host gate |
| T4 | 2026-08-25 18:40 PDT | Working tree | Pass: parse, warning-level shellcheck, and whitespace checks passed; the five real catalogs emitted only accepted records at 198/41, 108/18, 149/37, 36/7, and 118/34 | Direct execution of the shipped catalog entry points |

##### Closure Evidence

- Implementation and documentation review completed with no blocking findings.
- Commit `ee40e5a` contains the implementation, tests, ADR, runbook, reporting
  contract, and milestone evidence.
- The real Debian 13 and Rocky Linux 8 gate paths each passed six suite blocks
  and 758 checks.
- Issue #144 is closed as completed; observed 2026-08-26.

##### GitHub Projection

Title: Separate human-readable test output from machine-readable records
Labels: tests
GitHub Milestone: 1.3.0
Observed State: closed
Observed Labels: tests
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-26; remote updated 2026-08-26T16:09:47Z

#### M9 - Milestone procedure draft fate

Origin: 1.3.0 / M10
Identity History: staged from `docs/milestone-46790f9.md` M13; 1.3.0 / M10 -> 1.3.0 / M9 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 132, https://github.com/jeonghanlee/epics-ioc-runner/issues/132
Status: Complete

##### Summary

`docs/MILESTONE_PROCEDURE.md` was a repository working draft for plan review,
the owner gate, implementation, real-path verification, and landing. Review of
the 1.2.3 M1 record, issue #131, driver issue #134, verdict issue #135,
tool-probe issue #136, machine-record issue #137, and the current runbook
confirmed the durable boundary: `milestone-tracking` owns work planning,
acceptance, local verification, and closure; `gate/RUNBOOK.md` owns executable
release-gate operation. The owner selected that split on 2026-08-26. All 21
candidate rules now have one inspected owner or explicit rejection, their
reusable parts are in the shared skills, and T1 passed before the working draft
was removed. T1-T6 and both configured-upstream readbacks now pass. This final
projection records the state used for issue closure.

##### Scope

- Add a plan-review operation to the `milestone-tracking` source package. It
  covers premise recovery, evidence classification, owner decisions, removal
  of invented dependencies, conditional use of `conceptual-integrity`, plan
  acceptance, separate implementation authorization, real-path verification,
  and `Keep (examined, no action)` records.
- Route the operation from the skill entry point and the milestone procedure,
  including the requirement that a behavior regression detect the old defect
  when that claim is part of acceptance.
- Add the source rule for matching the surrounding code idiom to
  `code-conventions`; do not duplicate general code-style ownership in the
  milestone procedure.
- Add only the ownership boundary to `gate/RUNBOOK.md`; retain its current
  operational commands, evidence rules, and driver contracts.
- Remove `docs/MILESTONE_PROCEDURE.md` after parity and reference checks, then
  reconcile the canonical milestone and its GitHub projection.
- Use the fixed DR1-DR21 inventory below as the complete migration ledger for
  the draft's candidate rules.
- Reconcile the milestone authority text in `docs/README.md` and use that index
  as the starting point for the fresh-context route check.

##### Out of Scope

- Rewriting historical tags, issues, or worked examples.
- Making `conceptual-integrity`, multiple reviewers, both golden images, or one
  coupled commit mandatory for every milestone regardless of risk.
- Changing Gate commands, tracked drivers, evidence schemas, or the release
  sequence.
- Moving general code-style ownership out of `code-conventions`.

##### Completion Criteria

- All 21 candidate rules in the DR1-DR21 inventory have exactly one recorded
  destination or explicit rejection, with zero missing or multiply owned IDs;
  repository-specific history is not copied into the shared skill.
- `milestone-tracking` routes plan review to one maintained procedure that
  preserves the owner gate and the distinction between plan acceptance and
  implementation authorization.
- `conceptual-integrity` is selected only when accumulated code or shared
  agreement-points make a whole-codebase coherence review relevant.
- `code-conventions` explicitly preserves the surrounding-code idiom rule and
  remains the only owner of general code style.
- `gate/RUNBOOK.md` states the ownership boundary without taking ownership of
  per-milestone planning or release execution.
- The working draft is removed, every live reference resolves, and the shared
  skill and repository documentation checks pass.
- After T6, the verified implementation state in both source repositories is
  committed and pushed under separately granted per-repository Commit and Push
  authorities. Each configured upstream is read back, and its changed-path set
  matches the verified local state before issue closure, including required
  absence for a removed path. The commit IDs and upstream readbacks are
  recorded in Closure Evidence.
- The final GitHub issue body is generated only after both upstream readbacks
  succeed and T1-T6 results and Closure Evidence are final. Under separate
  Issue authority, the final body is applied, the linked issue is closed, and
  its body, state, and metadata are read back.
  After readback, projected sections remain unchanged; only GitHub Projection
  observation fields, the M9 row and detail status, the release tally, and the
  `Next session entry point:` may change. The observed closed state is evidence
  for, but does not by itself imply, canonical completion.
- Under separately granted Commit and Push authorities, the post-readback
  canonical reconciliation is committed and pushed without changing projected
  sections.
  An upstream readback contains the final M9 status and next-session entry
  point, matches the local canonical file, and requires no later record edit.
- A reader starting at `docs/README.md` can locate the active 1.3.0 register,
  enter M9, follow the installed skill to the plan-review procedure, keep
  `conceptual-integrity` conditional, and distinguish plan acceptance from
  implementation authorization.

##### Dependencies And Decisions

- Owner direction, 2026-08-26: fold the reusable rules into
  `milestone-tracking`, retain operational Gate rules in `gate/RUNBOOK.md`, and
  retire the repository draft after parity checks.
- The 1.2.3 M1 record and issue #131 established the standing runbook. Issue
  #134 shipped the executable drivers, #137 produced the machine-readable
  records, #135 consumed those records for the verdict, and #136 independently
  aligned suite tool probes with runner resolution.
- Contrary to the prior M9 dependency text, neither the initial nor the current
  runbook links to `docs/MILESTONE_PROCEDURE.md`; only milestone records made
  that assertion. M9 corrects the premise instead of preserving a link that
  never existed.
- Existing unrelated working-tree changes are outside M9 and must remain
  untouched when the shared skill source is updated.
- Owner direction, 2026-08-26: preserve the ordered plan-to-landed-commit
  lifecycle as a separate DR20 entry rather than combine it with DR1.
- Owner direction, 2026-08-26: keep DR1 limited to canonical identity and local
  T labels; record the draft's mandatory tracker-issue rule as rejected DR21;
  inspect every declared destination in T1; add end-to-end issue-projection
  verification; and correct the historical issue roles.
- Owner direction, 2026-08-26: supersede the preceding end-to-end T6 sequence;
  make DR13 a new `code-conventions` rule; use T6 for the pre-mutation
  projection comparison; and perform one final stable issue synchronization
  only after every projected result and Closure Evidence are final.
- Owner direction, 2026-08-26: the stable synchronization applies the final
  body and closes issue #132 under separate Issue authority, reads back the
  live body, state, and metadata, then permits only unprojected observations
  and canonical status, tally, and next-entry fields to change.
- Owner direction, 2026-08-26: after that canonical update, use a separate
  reconciliation commit and push, then verify the configured upstream without
  adding a projected result that would reopen the final issue body.
- Owner direction, 2026-08-26: after T6 and before final issue synchronization,
  commit, push, and read back the verified implementation in both source
  repositories; record that landing in Closure Evidence, then retain the later
  `epics-ioc-runner` canonical reconciliation as the terminal step.
- Owner direction, 2026-08-26: replace the tracked essay-site memory's deleted
  draft reference with the maintained `milestone-tracking` plan route and
  include that path in M9 rather than leave T4 failing.
- D1

##### Source Rule Inventory

This fixed inventory is the complete migration ledger for candidate rules in
`docs/MILESTONE_PROCEDURE.md`. The five principles repeat DR2, DR5, DR14, DR9,
and DR7. The worked examples are repository evidence rather than shared rules.

| ID | Candidate Rule | Disposition |
| --- | --- | --- |
| DR1 | Identify a milestone by its canonical register entry and local T labels. | Existing owner: `milestone-tracking` work-register contract. |
| DR2 | Recover the premise before choosing a fate. | New owner: `milestone-tracking/references/plan.md`. |
| DR3 | Require independent reviewers to read every essay for every milestone. | Explicit rejection: reviewer count and `conceptual-integrity` use remain risk-based. |
| DR4 | Rank findings by observed impact rather than presentation preference. | Existing owner: `conceptual-integrity`, when the plan-review route selects it. |
| DR5 | Examine real seams and dependencies asserted without evidence. | New owner: `milestone-tracking/references/plan.md`. |
| DR6 | Classify candidates as confirmed findings, hypotheses, or owner decisions, with evidence locations. | New owner: `milestone-tracking/references/plan.md`. |
| DR7 | Obtain the owner's choice when more than one defensible fate exists before recording a decision. | New owner: `milestone-tracking/references/plan.md`. |
| DR8 | Remove confirmed invented dependencies and narrow the milestone to its real target. | New owner: `milestone-tracking/references/plan.md`. |
| DR9 | Record examined-no-action decisions in `docs/CLOSED_DOORS.md`. | Existing owner: `milestone-tracking` work-register contract. |
| DR10 | Reflect corrected scope, dependency meaning, and local T labels in the canonical register. | New owner: `milestone-tracking/references/plan.md`. |
| DR11 | Project the accepted canonical plan and later evidence to the tracker issue. | Existing owner: `milestone-tracking/references/reconcile.md`. |
| DR12 | Update release-wide ordering only when an active release cycle is affected. | Existing owner: `release-cycle`. |
| DR13 | Match implementation to the surrounding code idiom. | New owner: `code-conventions`. |
| DR14 | Verify the real shipped path without replacing internal spans with substitutes. | Existing owner: `milestone-tracking/references/procedure.md`. |
| DR15 | Require a behavior regression to detect the old defect when that claim is part of acceptance. | New owner: `milestone-tracking/references/plan.md`. |
| DR16 | Run every affected suite on both golden images for every milestone. | Explicit rejection: the milestone Test Plan is risk-based; `gate/RUNBOOK.md` owns the release Gate matrix. |
| DR17 | Record observed evidence and the next session entry point before closure. | Existing owner: `milestone-tracking/references/procedure.md`. |
| DR18 | Require one coupled code, test, and documentation commit for every milestone. | Explicit rejection: `git-workflow` retains commit-granularity authority. |
| DR19 | Keep git and GitHub mutations owner-run unless the matching authority is delegated in the same request. | Existing owner: `git-workflow`. |
| DR20 | Follow the ordered per-milestone lifecycle from plan review through landed commit. | New owner: `milestone-tracking` plan-to-close operation route. |
| DR21 | Require every milestone to have exactly one tracker issue. | Explicit rejection: `milestone-tracking` permits no issue link and reconciles GitHub only when one is linked. |

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: accepted 2026-08-26 by the repository owner
Implementation Authorization: Owner authorized P001-P011 on 2026-08-26.
Superseded Plan Artifacts: none

1. Add `references/plan.md` to the `milestone-tracking` source package with the
   reusable planning gate, using the fixed DR1-DR21 inventory as the migration
   ledger rather than deriving a new source list during implementation.
2. Add the plan-review operation to `SKILL.md` routing and connect it from
   `references/procedure.md`; add the behavior-regression detection condition
   without making one test shape universal.
3. Add the surrounding-code idiom rule to `code-conventions` without moving
   general code-style ownership into the milestone procedure.
4. Update `gate/RUNBOOK.md` only at its ownership boundary so the runbook keeps
   operational Gate execution while `milestone-tracking`, `release-cycle`, and
   `git-workflow` retain their existing responsibilities.
5. Run T1 against the still-present draft and every declared destination,
   including unchanged owner text and explicit rejection rationale. Stop unless
   all 21 IDs are present and each has exactly one owner or explicit rejection.
6. After T1 passes, remove `docs/MILESTONE_PROCEDURE.md`, update all live
   repository references, reconcile `docs/README.md` with the active register,
   update canonical milestone evidence, and prepare the issue projection for
   application only under separate `git-workflow` Issue authority.
7. Run T2 through T5 against the resulting cross-repository change, including
   the fresh-context route check and complete review, and reconcile only
   evidence produced by those real validation paths.
8. Run T6 as a pre-mutation comparison between the canonical detail and its
   generated issue content, then record the observed T6 result in the canonical
   detail without changing GitHub.
9. Under separately granted `git-workflow` Commit and Push authorities for each
   repository, commit the verified implementation state in both source
   repositories, push each configured branch, fetch its upstream, and read back
   each scoped changed path. Treat an intentionally removed path as a required
   absence. Stop unless both upstream trees match their verified local commits
   over the exact changed-path sets. Record the commit IDs and upstream
   readbacks in Closure Evidence before generating the final issue body.
10. After both upstream readbacks succeed and all T1-T6 results and Closure
    Evidence are final, regenerate the issue body. Only under separate Issue
    authority, apply that final body, close issue #132, and re-read the live
    body, state, and metadata. After observing the closed state, update the
    unprojected GitHub Projection observations, the M9 row and detail status,
    the release tally, and the `Next session entry point:`. Do not change a
    projected section after readback.
11. Under separately granted `git-workflow` Commit and Push authorities, commit
    only the final canonical reconciliation, push the configured
    `epics-ioc-runner` branch, fetch its upstream, and read the upstream register
    back. Require the upstream M9 row, detail status, GitHub observations,
    release tally, and next-session entry point to match the local canonical
    file, with no remaining M9 reconciliation diff. This is the terminal check;
    do not create a new projected result afterward.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Rule disposition | For each fixed DR1-DR21 row, compare the candidate with the draft and inspect its named existing owner, proposed new owner, or explicit rejection rationale | Both source repositories | Exactly 21 unique IDs are present; zero source rules or destination checks are missing; every ID has exactly one owner or explicit rejection; no repository history is copied into the skill |
| T2 | Skill packages | Run the package validator for `shared/skills/milestone-tracking` and `shared/skills/code-conventions`, run `make render.check`, then confirm each installed skill entry resolves to its matching source package | Shared skill source working tree | Both source packages are valid, repository instruction projections are in sync, and installed skill entries resolve to their source packages |
| T3 | Procedure route | Give a fresh-context reviewer the installed skill and only `docs/README.md` as the repository starting point | Current checkout | The reviewer locates the active 1.3.0 register and M9 through its Next session entry point, follows the skill to `references/plan.md`, keeps `conceptual-integrity` conditional, and preserves plan acceptance and implementation authorization as separate gates |
| T4 | Reference integrity | Search tracked live documentation after removing the draft and compare the register descriptions in `docs/README.md` with the canonical register headers | Both source repositories | No live text depends on the removed path or calls a surviving procedure a working draft; the documentation index names the active authority without contradicting either register header |
| T5 | Ownership boundary | Review the shared procedure against `gate/RUNBOOK.md`, `release-cycle`, and `git-workflow` | Working trees | Per-milestone planning, Gate operation, release execution, and GitHub or git mutation each retain one non-overlapping owner |
| T6 | Issue projection content | Generate issue content from the current canonical detail and compare every required projected section without mutating GitHub | Canonical checkout | The generated body matches the current canonical projected sections; no GitHub mutation occurs; the observed result can be recorded before generating the final body for authorized application |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-27 00:56 PDT | Both source repository working trees | Pass: all 21 fixed ledger IDs had one inspected owner or explicit rejection; DR20 preserved distinct Commit and Push authorities plus configured-upstream readback, no candidate or destination was missing, all four rejections had a rationale, and no repository history entered the shared skill | Direct inspection of the byte-identical restored draft, fixed Source Rule Inventory, and every declared destination |
| T2 | 2026-08-27 00:57 PDT | Shared skill source tree and installed skill entries | Pass: both skill validators exited 0, `make render.check` reported projections in sync, and all four source-to-installed identity checks exited 0 | Direct execution of both package validators, `make render.check`, and the four source-to-installed identity checks |
| T3 | 2026-08-27 00:58 PDT | Fresh read-only context starting from the installed `milestone-tracking` skill and `docs/README.md` | Pass: the reader found the active 1.3.0 register and M9, reached `references/plan.md` and `references/procedure.md`, kept `conceptual-integrity` conditional, distinguished plan acceptance, implementation authorization, Commit, Push, and Issue authorities, and required upstream readback before Complete | Independent route inspection through the installed skill and tracked repository documentation from a fresh context |
| T4 | 2026-08-27 00:58 PDT | Tracked Markdown in both source repositories | Pass: the shared skill source repository had zero removed-path hits; release-branch hits were the current M9 removal record or the non-authoritative master snapshot, and `docs/README.md` agreed with both register headers about authority | Direct tracked-file searches, including a no-match `git grep`, plus inspection of `docs/README.md`, `docs/milestone-1.3.0.md`, and `docs/milestone-46790f9.md` headers |
| T5 | 2026-08-27 00:58 PDT | Both source repository working trees | Pass: `milestone-tracking` owned per-milestone planning and closure with distinct Commit, Push, and Issue authorities and required landing evidence; `gate/RUNBOOK.md` owned Gate operation, `release-cycle` owned release-wide execution, and `git-workflow` owned git and GitHub mutations | Direct cross-file inspection of all four ownership surfaces |
| T6 | 2026-08-27 01:00 PDT | Canonical checkout | Pass: the canonical M9 detail and generated local issue body each contained the nine required projected sections, their complete projected content matched, excluded GitHub metadata was absent from the body, and no GitHub mutation was issued | Direct section counts and byte comparison of the nine canonical projected sections against the generated body before GitHub mutation |

##### Closure Evidence

- At 2026-08-27 08:55 PDT, the shared skill source implementation was present
  in its configured upstream. Direct `git diff --exit-code` readback found zero
  differences across all five planned M9 paths.
- At 2026-08-27 08:55 PDT, `epics-ioc-runner` implementation commit
  `a8bfdcd2579aa85c2af6334dbedaddcb5dc3cb9c` was the current
  `origin/release-1.3.0` tip. Direct `git diff --exit-code` readback found zero
  differences across all four planned M9 paths, and a `git cat-file -e`
  absence check confirmed that `docs/MILESTONE_PROCEDURE.md` is not in the
  upstream tree.
- P009 / V008 passed. Both implementation commits are durable upstream. This
  evidence is the fixed input for final issue synchronization; terminal
  canonical reconciliation is a separate post-readback step and is not part of
  this projected body.

##### GitHub Projection

Title: Settle the fate of the milestone procedure working draft
Labels: P3-low, docs
GitHub Milestone: 1.3.0
Observed State: closed
Observed Labels: P3-low, docs
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-27; remote updated 2026-08-27T16:05:43Z

#### M10 - Fleet-layer reliability

Origin: 1.3.0 / M1
Identity History: staged from `docs/milestone-46790f9.md` M4; 1.3.0 / M1 -> 1.3.0 / M10 (execution-order renumbering, D3, 2026-08-18)
GitHub Issue: 102, https://github.com/jeonghanlee/epics-ioc-runner/issues/102
Status: Complete

##### Summary

The child-exit, crash-loop, and procServ-death layers are already complete.
M10 retains two runner-owned reliability checks after evaluating the original
six candidates against the repository boundary and the supported systemd and
procServ contracts. Application-level IOC health and fleet recovery remain
external responsibilities.

##### Scope

| ID | Remaining Item | Completion Boundary |
| --- | --- | --- |
| M10-3 | Log-path availability | During system `start` and `restart`, report shared-filesystem write failure visible to the ordinary authorized operator. During system `inspect`, probe the effective log directory as the unit's service identity. Local commands probe as the local owner. |
| M10-5 | procServ executable drift | When `inspect` is invoked, confirm that systemd `MainPID` owns the target UDS, then compare the active executable with the procServ executable configured in the effective systemd launch command. Warn if the executable is missing, deleted, or has a different device and inode. |

##### Out of Scope

- Reimplementing recurring child-death detection delivered in `44b9191`, its
  silent child-kill regression delivered in `b49d074`, or the later real child
  recovery proof delivered in `98fafea`.
- Reimplementing procServ-death recovery delivered in `d0338f1`.
- Unit-layer restart jitter, `ExecStartPre` random delay, or changing the
  per-IOC indefinite-restart policy.
- M10-1 application-level IOC hang detection. A heartbeat PV or equivalent
  health signal belongs to external IOC monitoring rather than this
  lifecycle CLI.
- M10-6 common-cause correlation, restart-load orchestration, and other fleet
  recovery controls.
- Continuous disk-capacity and NFS-availability monitoring. M10-3 covers only
  runner command behavior when the configured log path is unavailable.
- M10-4 bounded local-mode NFS failure. Linux `hard` NFS mounts retry requests
  indefinitely, while `soft` and `softerr` can risk silent data corruption.
  NFS availability and mount policy remain host responsibilities.
- A runner executable, shell, or current working directory that is itself
  blocked on unavailable NFS; the runner cannot bound execution before its
  own code is locally available.
- Configuration immutability, per-IOC hash state, migration baselines, and
  changes to the established `ioc` group or sudo policy.
- M10-2 activation-time configuration validation. systemd 239 cannot make a
  restart decision based on whether the main process exited before or after
  `exec`, and the pinned procServ returns child exit codes and errno values.
  The feasible alternatives would replace procServ as `MainPID`, add another
  supervisor, or expand the sudo contract. The explicit-restart warning from
  #106 remains; automatic-restart validation is an accepted limitation.
- Continuous procServ executable or package monitoring, package management,
  and automatic stop or restart in response to M10-5.

##### Completion Criteria

- M10-3 creates a temporary file in the effective procServ log directory,
  writes one byte, forces the write to the filesystem, verifies every result,
  and removes the file on both success and failure. The existing startup
  readiness scan reads the IOC log from that same effective directory. Failure
  blocks `start` and `restart` before systemd is called; `inspect` warns and
  continues.
- System `start` and `restart` perform the probe as the invoking authorized
  operator and cover shared-filesystem capacity under the established
  group-writable log-directory model. They do not claim service-UID quota or
  owner-only permission equivalence. System `inspect` runs the probe with the
  effective unit's `User=` and `Group=`; local commands run it as the local
  owner.
- M10-5 verifies that systemd `MainPID` is a target-UDS server PID and compares
  device and inode identities. A missing, deleted, unreadable, or mismatched
  executable produces a warning; `inspect` returns success and changes no
  process state. If `MainPID:starttime` changes during the inspection,
  `inspect` reports an unstable snapshot instead of executable drift.
- Each detection reports its named condition without depending on the signal
  that condition disables.
- M10-3 affects only the requested runner command and introduces no
  continuous monitoring process.
- M10-5 reports executable drift only during an explicit `inspect` and does
  not change process state.

##### Dependencies And Decisions

- #52 and #67 are completed foundations, not open M10 work. Commit `44b9191`
  added readiness polling and recurring child-death-banner detection;
  `b49d074` added the silent child-kill crash-loop regression; and `98fafea`
  later verified real child recovery under the same procServ on both golden OS
  families.
- #54 is a completed foundation, not open M10 work. Commit `d0338f1` added
  `Restart=always`, `RestartSec=2`, `KillMode=mixed`, and disabled the systemd
  start-rate limit in both procServ unit templates so procServ death recovers
  without operator intervention.
- systemd service units have no restart jitter. `RandomizedDelaySec` applies
  to timer units, not service restarts.
- `RestartSteps` and `RestartMaxDelaySec` require systemd v254 or later,
  remain phase-synchronized across identical units, and are unavailable on
  Rocky 8 systemd 239.
- An `ExecStartPre` random delay would affect every start and restart and
  conflict with the measured per-IOC stabilization window established by
  #67. Restart-storm control therefore remains a fleet and operations-layer
  responsibility rather than a per-IOC unit change.
- The 1.2.0 full-code review recorded configuration drift, log-path
  disk-full, NFS outage, and procServ executable replacement as additional
  detection-layer gaps. They are M10-2 through M10-5 rather than separate
  untracked work.
- M10-5 is an on-demand `inspect` diagnostic. It reuses the active procServ
  server PID already identified through the target UDS and adds no background
  daemon or package-monitoring responsibility.
- Commit `f5789a8` and #106 already warn when an explicit restart would apply a
  configuration changed after activation. That warning remains the runner's
  configuration-change boundary.
- The established configuration contract remains unchanged: system `.conf`
  files are group-writable, any authorized `ioc` engineer may manage an IOC,
  and the multi-user gate requires a second operator to edit the deployed
  configuration successfully.
- systemd 239 applies `RestartPreventExitStatus` to the main process without
  retaining whether that status came from a pre-`exec` validator or procServ.
  The pinned procServ source at `073f290` returns the managed child's last exit
  code and returns errno values on listener setup failures, so no numeric exit
  status is a validation-only channel.
- A parent wrapper would add a second supervisor and replace procServ as the
  systemd `MainPID`. A validation-time self-stop would require a new nonblocking
  systemctl permission outside the current sudo policy. Both contradict
  established contracts, so M10-2 is recorded as examined and not implemented.
- M10-3 resolves the effective procServ log directory from the installed unit
  launch command rather than the caller's current environment, then uses a
  same-directory temporary file for a create-write-sync probe and cleanup. The
  existing startup readiness scan uses the same resolved directory instead of
  independently following the caller's `LOG_DIR`.
- M10-3 detects command-time write failure at the configured log filesystem;
  it does not add a general permission audit or continuous capacity monitor.
  In system mode, `start` and `restart` retain the ordinary `ioc` operator path
  and its existing restricted `sudo systemctl` transition. Their probe covers
  shared-filesystem capacity under the established group-writable directory
  model; per-service-UID quota and owner-only permission differences are
  outside this check. Because `inspect` already requires root, it resolves the
  effective unit's `User=` and `Group=` and runs the probe with both identities
  through `/usr/sbin/runuser`. This matches a custom unit even when
  the service user's passwd primary group differs from `Group=`, and prevents
  root-only reserved capacity from producing a false success. This adds no
  nested sudoers entry or password prompt. In local mode, the current local user remains both runner and
  procServ writer for all three commands. The canonical gate may prepare and
  remove an isolated size-limited filesystem outside the local suite, but the
  local lifecycle suite itself remains an ordinary-user path with no `sudo`.
- M10-5 reads the direct procServ `ExecStart` from the effective systemd launch
  command and extracts the configured executable before comparing identities.
- The evaluation used five 1-5 scores: `ioc-runner` scope fit, impact,
  likelihood, current detection gap, and real-path verification feasibility.
  The displayed 10-point result is their sum divided by 2.5. Scope fit is a
  gate applied before the total: 1-2 excludes, 3 requires boundary revision,
  and 4-5 retains an item.

| ID | Scope Fit | Score / 10 | Disposition | Basis |
| --- | ---: | ---: | --- | --- |
| M10-1 | 2 | 6.4 | External | The runner observes systemd, procServ, UDS, and startup logs; application health requires a PV or equivalent external signal. |
| M10-2 | 5 | 8.0 | No action after feasibility review | The runner owns activation, but systemd 239 exposes no validation-only restart result; every feasible implementation changes the procServ `MainPID`, indefinite restart, or sudo contract. |
| M10-3 | 5 | 8.0 | Retain after narrowing | Runner commands depend directly on the configured log path; continuous capacity monitoring remains external. |
| M10-4 | 2 | 6.8 | External after feasibility correction | A runner cannot guarantee a bounded return from indefinitely retried `hard` NFS access without imposing a host mount policy. |
| M10-5 | 4 | 6.0 | Retain as on-demand diagnostic | `inspect` already identifies the active procServ server PID and can report executable identity without changing process state. |
| M10-6 | 1 | 6.8 | External | Cross-host correlation and restart orchestration require inventory and a continuous fleet control surface that the runner does not own. |

- D1 assigns #102 to the 1.3.0 reliability and configuration contract release
  line.
- D3 places implementation after the mid-cycle while the design conversation
  runs from cycle start.
- D5 keeps one M10 and orders implementation as M10-2, M10-3, M10-4, then
  M10-5; M10-1 and M10-6 remain outside this repository's implementation
  boundary.
- D6 supersedes the M10-4 portion of D5 after the NFS client recovery contract
  showed that the proposed bounded-return guarantee is not runner-owned.
- D7 originally specified a create-write-delete log-path probe for M10-3 and
  the on-demand systemd PID, UDS, and executable-identity comparison for
  M10-5. The current draft strengthens the retained M10-3 probe by requiring
  successful sync and result checks. D8 supersedes only D7's M10-2 hash design
  with activation-time validation.
- D9 supersedes D8 and the M10-2 portion of D5 after the pinned procServ source
  confirmed that no numeric exit status is reserved for validation. M10-2 is
  not implemented; the direct procServ `MainPID`, indefinite restart, shared
  configuration, account, and sudo contracts remain unchanged.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner re-approved the revised M10 plan on 2026-08-30 ("재승인") and accepted the `runuser` correction on 2026-08-30 ("승인할께").
Implementation Authorization: Owner authorized implementation of the accepted M10 plan on 2026-08-30 ("구현 승인할께 진행해줘") and authorized the accepted `runuser` correction on 2026-08-30 ("승인할께").

1. In `bin/ioc-runner`, add one shared effective-launch-command reader. Use it
   to resolve the real procServ log directory for a create-write-sync-delete
   probe in `start`, `restart`, and `inspect`, and use that same resolved path
   for the existing startup readiness scan. Require successful creation,
   one-byte write, filesystem sync, close, and cleanup; preserve the original
   failure if cleanup also fails. Mutation commands fail before systemd, while
   `inspect` reports a warning and continues. Preserve the ordinary `ioc`
   operator and restricted `sudo systemctl` path for system `start` and
   `restart`; classify those probes as shared-filesystem capacity checks under
   the established group-writable model, not service-UID quota or owner-only
   permission checks. Make the already-root system `inspect` resolve the
   effective unit's `User=` and `Group=` and run the probe with both identities
   through `/usr/sbin/runuser`. Keep local probes under the current
   local user.
2. In `bin/ioc-runner`, extend `inspect` to read systemd `MainPID`, require it
   to match a server PID found through the target UDS, extract the configured
   procServ executable from the direct launch command, and compare device and
   inode identities without changing service state or supervision. Capture
   `MainPID:starttime` before the UDS and executable checks and revalidate it
   afterward; if it changed, report an unstable inspection snapshot rather
   than executable drift.
3. Add real-path coverage to `tests/test-system-lifecycle.bash` and
   `tests/test-local-lifecycle.bash`. In `gate/drivers/control/suites.bash`,
   prepare and remove the isolated local size-limited filesystem outside the
   local suite, transfer its writable directory to the local test owner, and
   pass only the prepared path into the suite. Keep filesystem exhaustion,
   restoration, and every shipped `ioc-runner --local` invocation inside the
   suite under the ordinary local owner with no `sudo`. Update the matching
   `SYSTEM_LIFECYCLE_INVENTORY.md` and `LOCAL_LIFECYCLE_INVENTORY.md` rows,
   then update `tests/reporting-counts.csv` only from the observed closed
   catalogs. Run the canonical gate with its prior expected identity digest,
   require the only identity failure to report one common digest from both
   hosts, update that digest in `gate/drivers/control/suites.bash`, and rerun
   the gate.
4. Update `docs/CLI_REFERENCE.md`, `docs/USER_GUIDE.md`,
   `docs/USER_GUIDE_LOCAL.md`, and `docs/PERMISSION_MODEL.md` for the two
   diagnostics and their execution identities. State that direct `systemctl`
   lifecycle commands remain supported but bypass `ioc-runner` preflight
   diagnostics and readiness reporting. Do not change the account, sudoers,
   configuration-write, or direct procServ `MainPID` contracts.
5. Run T1 through T3 through the real shipped system and local paths on both
   golden OS families and record observed results.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | M10-3 log-path availability | Point a real installed unit at a size-limited filesystem and exhaust it. Exercise `start` from inactive and `restart` plus `inspect` from active. In system mode, invoke the shipped `start` and `restart` as an ordinary `ioc` operator through the existing sudoers path; these calls test shared-filesystem capacity under the established group-writable model and make no service-UID quota or owner-only permission claim. Invoke `inspect` as root while its probe runs with the effective unit's `User=` and `Group=`. Include a temporary custom-identity fixture whose passwd primary group differs from the unit `Group=` and remove it during cleanup. For local mode, have the canonical gate create and mount the isolated size-limited filesystem before the local suite, transfer its writable directory to the ordinary local owner, and pass the prepared path into the suite. Have the local suite exhaust and restore that filesystem and invoke all three shipped `ioc-runner --local` commands as the local owner without calling `sudo`. After the suite exits, have the gate unmount and remove the fixture through its always-run cleanup. Record unit state and `MainPID` before and after each command, restore capacity, and repeat. | System and local modes on both golden OS families | At full capacity, inactive `start` remains inactive, active `restart` and `inspect` retain their original active state and `MainPID`, `inspect` warns and returns success, and no probe file remains. The custom-identity fixture proves that the inspect probe uses both effective unit identities. After capacity is restored, inactive `start` becomes active with a valid `MainPID`, active `restart` succeeds with a new `MainPID`, and `inspect` succeeds without a log-path warning or process-state change. The local lifecycle suite remains sudo-free; only the gate's outer fixture setup and cleanup use privilege. No product account, sudoers, unit, or permission change is required, and the temporary filesystem and identity fixtures leave no residue. |
| T2 | M10-5 executable drift | In the stable phases, install and start a real service against an isolated procServ copy, record unit state and `MainPID`, invoke the shipped `inspect`, atomically replace the copy while it remains active, and invoke the same path again with state observations around each call. In the separate race phase, start the real `inspect` with streamed captured output, record its PID in the suite's always-run cleanup state, and wait for its existing `Target Socket:` line emitted after the initial `MainPID:starttime` snapshot. Immediately send `SIGSTOP` to the inspect process, have the harness request exactly one real systemd restart, wait within a fixed timeout for the unit to become active with a different `MainPID:starttime`, then send `SIGCONT` and wait for inspect completion. In a separate cleanup failure phase, start the same real inspect path, wait for the same line, send `SIGSTOP`, deliberately omit the restart, and require a short fixed test timeout to invoke the same always-run cleanup. On every exit, cleanup sends `SIGCONT` to a surviving stopped inspect process, terminates it with a bounded wait and `SIGKILL` fallback, reaps it, restores the pre-test unit state and isolated procServ copy, and verifies that no process or fixture residue remains. Fail on any stop, restart, state, resume, cleanup, or timeout-contract error. Use root for system `inspect` and the local owner for local `inspect`. | System and local modes on both golden OS families | In the stable phases, baseline identity reports no warning, replacement reports the deleted or device-and-inode mismatch, and each `inspect` returns success without changing unit state or `MainPID`. In the race phase, the changed snapshot is reported as unstable rather than executable drift. The harness records exactly one restart after the synchronization line and while inspect is stopped; the inspected process resumes only after the replacement `MainPID:starttime` is observed. In the cleanup failure phase, the planned timeout occurs without a restart and the cleanup leaves no inspect process, changed unit state, modified procServ copy, or fixture residue. |
| T3 | Reporting and gate identity | Close the updated real lifecycle catalogs, compare their inventories and observed CSV counts, run the canonical two-host gate with the prior digest, update only the common observed identity digest, and rerun the same gate. | Source environment plus both golden OS families | Catalogs, inventories, and CSV counts agree; the first gate fails only on one common new identity digest; the updated gate passes on both hosts. |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-30 21:59 PDT | Debian 13 and Rocky 8 goldens, installed and source lifecycle paths | Pass: exhausted filesystems blocked `start` and `restart`, `inspect` warned without changing service state, restored filesystems recovered, the custom system identity used its effective `User=` and `Group=` through `runuser`, and every fixture reported clean removal | Final canonical evidence in `work/gate-suites-20260831T045417Z-1188529`; both installed system-lifecycle runs passed 144 checks, and both source and installed local-lifecycle runs passed their closed catalogs |
| T2 | 2026-08-30 21:59 PDT | Debian 13 and Rocky 8 goldens, system and local modes | Pass: baseline executable identity matched, atomic replacement warned without changing service state, the forced restart race reported an unstable snapshot rather than drift, timeout cleanup reaped the stopped inspection, and all fixture cleanup checks passed | Final canonical evidence in `work/gate-suites-20260831T045417Z-1188529`; focused Rocky race observation in `work/gate-suites-20260831T032518Z-1149985/rocky-m10-race-observer.log` |
| T3 | 2026-08-30 21:59 PDT | Source environment plus Debian 13 and Rocky 8 goldens | Pass: static checks and closed catalogs agreed; the unchanged-digest gate produced the same `d2c25a1cfdd26f70bc4e7646bde85fc4443299d7ce95ecd4d39577641feaf1bd` candidate on both hosts; after accepting it, the final gate passed six blocks and 830 checks per host with only the documented OS applicability differences. Investigation of the pre-final S22 failure found a `pipefail` false negative in `ss -lx | grep -q`; materializing the real `ss` output before fixed-string matching removed it, and the focused Debian run passed 144/144 before the final gate | Digest-only evidence in `work/gate-suites-20260831T043115Z-1169420`; S22 diagnostic trace in `work/gate-suites-20260831T043740Z-1174983/debian-s22-trace.log`; final PASS in `work/gate-suites-20260831T045417Z-1188529` |

##### Closure Evidence

- Commit `4f2caabbfd956f4cb73609ffbab2c35331a362cf` implements the
  accepted M10 scope on `release-1.3.0` and is present on
  `origin/release-1.3.0`.
- The final canonical Debian 13 and Rocky 8 gate passed all six suite blocks
  and 830 checks per host.
- GitHub issue #102 carries the completed criteria and verification results
  and was closed on 2026-08-30.

##### GitHub Projection

Title: Runner-owned reliability checks: configuration, log path, and procServ executable
Labels: enhancement, P3-low, ops, area/architecture
GitHub Milestone: 1.3.0
Observed State: closed
Observed Labels: enhancement, P3-low, ops, area/architecture
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-30; remote updated 2026-08-31T05:17:08Z

#### M11 - Custom identity teardown agreement

Origin: 1.3.0 / M11
Identity History: none
GitHub Issue: 149, https://github.com/jeonghanlee/epics-ioc-runner/issues/149
Status: Complete

##### Summary

The full installation path supports a custom system service account and group
through `IOC_RUNNER_SYSTEM_USER` and `IOC_RUNNER_SYSTEM_GROUP`. The full
uninstallation guide still removes and verifies only the shipped `ioc-srv` and
`ioc` defaults. A custom installation can therefore leave its actual identity
behind or direct an operator to remove unrelated default-named accounts.

##### Scope

Make the full uninstallation procedure read the service account and group from
the deployed `epics-@.service` before removing the unit. Read the actual system
log path from the same deployed unit. Require the operator to confirm those
values before any account or group removal, use the confirmed identity and log
path in removal and verification steps, transfer retained system logs away from
that identity only when the log directory is confirmed as dedicated, and
delete only accounts and groups confirmed as dedicated and unused. Preserve an
existing or origin-unknown log directory and its related identity. Keep the
default `ioc-srv` and `ioc` behavior unchanged when no override was used,
subject to the same dedicated-use checks.

##### Out of Scope

- Adding an automated full-teardown command.
- Changing the installed service-account, sudoers, runtime
  directory-ownership, or runner execution model. The teardown-only ownership
  transfer for retained system logs is in scope.

##### Completion Criteria

- `docs/UNINSTALL.md` reads the service account, group, and system log path
  chosen during installation from the deployed unit before showing destructive
  commands.
- The deployed unit remains available until system-log ownership, ACL cleanup,
  and account and group retain-or-delete decisions complete; unit removal
  follows those identity-dependent steps.
- The procedure stops account removal when any deployed value is missing or
  ambiguous and requires the operator to confirm all three values.
- The logfile template must be an absolute path ending in `/%i.log`; its
  derived parent must exist and must not be `/`. Any failure stops before an
  ownership or ACL change.
- Account and group removal, verification, and recovery guidance consistently
  use the selected identity rather than unconditional default names.
- Account and group deletion are separate operator decisions. A selected
  identity is deleted only when it was created exclusively for this
  installation and has no other use; an unknown or pre-existing identity is
  retained.
- Log-directory handling is a separate operator decision. A confirmed
  installation-dedicated directory is transferred to `root:root` with no ACL
  entry naming a removed identity. An existing or origin-unknown directory
  keeps its observed pre-teardown metadata, and its related account and group
  are retained.
- The default installation still resolves to `ioc-srv` and `ioc` without an
  additional site setting.
- A real custom-identity setup and documented teardown on both golden OS
  families removes the deployed infrastructure, removes only resources
  confirmed as dedicated and unused, and preserves the documented logs,
  backups, pre-existing resources, and conservative identity dependencies.

##### Dependencies And Decisions

- M10
- D1, D10, D13
- The custom identity contract is established by `docs/INSTALL.md`,
  `docs/PERMISSION_MODEL.md`, and `bin/setup-system-infra.bash`.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner accepted 2026-08-31
Implementation Authorization: Owner authorized 2026-08-31
Superseded Plan Artifacts: none

1. Update `docs/UNINSTALL.md` so it reads exactly one non-empty `User=` and
   `Group=` value and exactly one `--logfile=` path from the deployed
   `epics-@.service`. Require an absolute logfile template ending in `/%i.log`,
   derive its parent directory, reject an empty, root, or missing directory,
   and show all three resolved values for operator confirmation. Stop before
   any metadata change on every failure.
2. Require confirmation that the resolved log directory was created
   exclusively for this installation and has no other use. Only for that case,
   recursively transfer retained log ownership to `root:root` and remove access
   and default ACL entries that name the confirmed identity. Otherwise preserve
   the directory's observed pre-teardown metadata and retain the related
   account and group.
3. For identities not retained by step 2, require separate confirmation that
   the selected account and group were
   created exclusively for this installation and have no other use. Show each
   deletion command only for a confirmed dedicated identity; otherwise retain
   it and verify that the infrastructure no longer depends on it.
4. Keep `epics-@.service` in place through steps 1-3. Before either identity is
   deleted, an interrupted procedure can restart identity resolution from the
   deployed source. Once identity deletion begins, require the operator to
   complete the identity-dependent steps in the same privileged session or
   stop and inspect the remaining state. Remove the unit only after all
   identity-dependent work completes.
5. Carry the confirmed values and retain-or-delete decisions through removal,
   verification, and recovery guidance while retaining the shipped defaults as
   the ordinary case.
6. Verify the updated procedure through the real full setup and teardown path
   with a custom identity on both golden OS families.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Documentation agreement | Compare the deployed unit rendering, account and group creation-or-reuse behavior, identity and log-path defaults, and system-log ownership contract in `bin/setup-system-infra.bash`, `docs/INSTALL.md`, and `docs/PERMISSION_MODEL.md` with every identity and log-path reference in `docs/UNINSTALL.md` | Tracked source | Teardown reads exactly one non-empty deployed account, group, and `--logfile=` path; validates and derives a safe log directory before metadata changes; changes log metadata only after a dedicated-directory confirmation; retains identities related to an existing or origin-unknown directory; permits any remaining deletion only after a separate dedicated-use confirmation; and removes the unit only after all identity-dependent work completes |
| T2 | Real custom teardown | On a disposable golden host, preserve a pre-existing default-named sentinel identity, run the shipped full setup with a distinct custom account, group, and system log path, create retained log content, then follow the documented teardown and verification procedure | Debian 13 and Rocky 8 golden OS families | The custom account, group, and installed infrastructure are absent; retained content at the resolved custom log path is `root:root` with no ACL reference to the removed identity; the sentinel default identity is unchanged; setup and teardown leave no test residue outside the retained logs and backups documented by the procedure |
| T3 | Unsafe deployed-value refusal | On a disposable golden host, run the shipped full setup, then mutate one deployed-unit field at a time to produce missing and multiple `User=` values, missing and multiple `Group=` values, and a missing `--logfile=`, multiple logfile values, a relative logfile, a logfile without the `/%i.log` suffix, a root parent, and a missing parent directory; execute the documented resolution step after each mutation | Debian 13 and Rocky 8 golden OS families | Every unsafe case stops with no state change beyond the intentional unit mutation; restoring the original shipped unit permits normal teardown |
| T4 | Identity creation-or-reuse matrix | On a disposable golden host, exercise the three custom-identity cases in which setup creates the account but reuses a sentinel group, reuses a sentinel account but creates the group, or reuses both; run the shipped full setup with a custom system log path, then follow the documented teardown with a separate origin decision for each identity | Debian 13 and Rocky 8 golden OS families | Installed infrastructure is absent; retained logs are `root:root` with no ACL reference to the selected identity; each setup-created identity is deleted; each pre-existing identity and its sentinel properties are unchanged |
| T5 | Existing log-directory preservation | On a disposable golden host, create a custom log directory with sentinel content, run the shipped full setup with otherwise new custom identities, capture the post-setup directory ownership, modes, ACLs, and content, then follow the documented teardown without confirming the directory as installation-owned | Debian 13 and Rocky 8 golden OS families | Deployed infrastructure is absent; the log tree matches its post-setup metadata and content snapshot; the related account and group are retained; no unrelated path changes |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-31 02:13 PDT | Tracked source at `c31a379b1703` with the M11 documentation changes | Pass: the deployed unit rendering, identity defaults and overrides, log-directory creation-or-reuse behavior, ownership and ACL contract, teardown resolver, retain-or-delete decisions, preservation-state comparison, and unit-removal order agree across the setup code and maintained documents | Direct comparison of `bin/setup-system-infra.bash`, `docs/INSTALL.md`, `docs/PERMISSION_MODEL.md`, and `docs/UNINSTALL.md`; every Bash block in the uninstall guide passed `bash -n` and ShellCheck after the final review changes |
| T2 | 2026-08-31 01:00 PDT | Reused Debian 13 and Rocky 8 golden testbeds, current tree copied to `/home/vmadmin/gitsrc-m11/epics-ioc-runner` | Pass: the shipped full setup created a distinct custom account, group, and log path; the documented blocks removed only the custom infrastructure and identities, transferred retained content to `root:root`, removed its identity ACLs, and left the default sentinel identity records unchanged | Direct execution of the shipped setup and Bash blocks extracted from `docs/UNINSTALL.md`; both hosts restored the default installation after verification |
| T3 | 2026-08-31 01:00 PDT | Reused Debian 13 and Rocky 8 golden testbeds | Pass: all ten missing, duplicate, relative, wrong-suffix, root-parent, and missing-parent unit mutations returned nonzero without changing the selected account, group, or log tree; restoring the shipped unit permitted normal teardown | Direct execution of the documented resolver against each mutated deployed unit on both hosts, with identity and log-tree digests compared before and after every refusal |
| T4 | 2026-08-31 01:00 PDT | Reused Debian 13 and Rocky 8 golden testbeds | Pass: the create-account/reuse-group, reuse-account/create-group, and reuse-both cases independently deleted every setup-created identity and preserved every pre-existing identity record; each dedicated log tree passed ownership and ACL cleanup | Direct execution of the shipped setup and documented teardown blocks for all three creation-or-reuse cases on both hosts |
| T5 | 2026-08-31 02:13 PDT | Reused Debian 13 and Rocky 8 golden testbeds | Pass: a pre-existing custom log tree retained its complete post-setup content, ownership, modes, and numeric ACL digest while the infrastructure was removed and both related identities remained; the final documented state-capture and comparison blocks returned the same value on each host | Direct execution of the conservative documented path on both hosts after the second-person finding was applied; test-only identities, source copies, and paths were removed after observation, and the default installation was restored |

##### Closure Evidence

- Implementation and T1-T5 verification are complete in the current working
  tree. The third-person and repeated second-person reviews have no remaining
  finding.
- Implementation commit `7894b1d13c4212789a34e78c4542c2f2a776f8a1` is
  pushed to `origin/release-1.3.0`; a 2026-08-31 fetch observed local HEAD and
  upstream at the same commit with no changed path.
- Linked issue #149 was observed closed as completed after its canonical body
  and checked acceptance criteria were projected on 2026-08-31.

##### GitHub Projection

Title: Align custom service identity teardown with installation
Labels: bug, P2-medium, docs, area/install
GitHub Milestone: 1.3.0
Observed State: closed
Observed Labels: bug, P2-medium, docs, area/install
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-31; remote updated 2026-08-31T10:01:57Z

#### M12 - Current Rocky golden downstream validation

Origin: 46790f9 / M3
Identity History: 46790f9 / M3 -> 1.3.0 / M12 (staged target, D12, 2026-08-30)
GitHub Issue: 146, https://github.com/jeonghanlee/epics-ioc-runner/issues/146
Status: Complete

##### Summary

The 2026-06-03 Rocky golden named by jeonghanlee/cloud-provision#4 is
obsolete after the copy-based image workflow shipped in
jeonghanlee/cloud-provision#30. A new Rocky image pinned to the current
`release-1.3.0` runner line now passes fresh-consumer provenance acceptance
and the downstream system-infrastructure and system-lifecycle suites. This row
records the completed verification.

##### Scope

- Produce a new Rocky 8 golden with the shipped `cloud-provision` image
  workflow and `epics-ioc-runner` ref `release-1.3.0`.
- Boot a fresh consumer from that exact image and its matching creation
  record.
- Before deploying the candidate tree, verify the untouched consumer against
  the image manifest and record the exact `cloud-provision`,
  `ansible-provision`, retained checkout, and installed runner identities.
- Deploy the current candidate through the shipped full setup path, then run
  the shipped system-infrastructure and system-lifecycle suites through the
  real installed-runner path without replacing the setup, sudo, systemd, or
  IOC paths.
- Record the complete suite results, current sudoers-policy observations, and
  evidence hashes.

##### Out of Scope

- Re-running the retired 2026-06-03 Rocky golden.
- Treating the 2026-08-12 Rocky gate, which predates jeonghanlee/cloud-provision#30, as verification of the current image-workflow artifact.
- Reusing any earlier Rocky golden as M12 verification.
- Treating this downstream runner check as image-workflow acceptance.

##### Completion Criteria

- A new Rocky 8 bake publishes one exact image, creation record, and manifest,
  with `app_ioc_runner requested=release-1.3.0` and clean supplier identities.
- The manifest's supplier commits match the fetched `origin/master` tips of
  `cloud-provision` and `ansible-provision`, and its `app_ioc_runner commit`
  matches the fetched `origin/release-1.3.0` commit recorded before the bake.
- The candidate checkout is a clean `release-1.3.0` branch exactly equal to
  that fetched `origin/release-1.3.0` commit before the bake and again before
  it is pushed to the consumer.
- A fresh consumer selects that exact image, reaches `READY`, and passes the
  untouched golden acceptance checks before any candidate deployment.
- Before deployment, both the retained checkout and installed runner agree
  with the manifest's `app_ioc_runner commit`.
- After the shipped full setup, the installed runner agrees with the current
  M12 candidate commit.
- `tests/test-system-infra.bash` and `tests/test-system-lifecycle.bash` run
  through the shipped installed path and both finish with final PASS suite
  records.
- Evidence records the image name, creation record, manifest, supplier
  commits, baseline and candidate runner identities, commands, suite counts,
  final states, and log hashes.

##### Dependencies And Decisions

- M11
- D12
- D14
- jeonghanlee/cloud-provision#30 supplies the current copy-based image workflow and its accepted Rocky image format.
- jeonghanlee/cloud-provision#4 closed by owner-approved retirement of its exact historical target; this row does not retroactively satisfy that issue's original first check.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner approved the reviewed M12 plan on 2026-08-31
("승인해").
Implementation Authorization: Owner authorized M12 implementation on
2026-08-31 ("구현 승인").
Superseded Plan Artifacts: none

1. Fetch `cloud-provision`, `ansible-provision`, and `epics-ioc-runner`.
   Require the first two checkouts to be clean `master` branches exactly equal
   to their `origin/master` tips. Require the runner checkout to be a clean
   `release-1.3.0` branch exactly equal to its fetched
   `origin/release-1.3.0` tip, and record that candidate commit. Then run
   `bin/bake_iocrunner_image.bash -o rocky8 -r release-1.3.0` from the
   `cloud-provision` checkout.
2. Record the published image, matching creation record and manifest,
   supplier commits, requested runner ref, and artifact hashes.
3. In the current `cloud-provision` checkout, confirm the effective
   `VM_PREFIX=lab` and `NODE_IDS=main`. Run
   `make rocky8-iocrunner.main.clean`, then
   `make rocky8-iocrunner.main`. Require `READY`, and record the resulting
   domain, VM disk creation record, and address instead of using an address
   copied from an older runbook example.
4. Before pushing or deploying the candidate tree, follow
   `cloud-provision/docs/RUNBOOK_BAKE.md`, section "Fresh consumer SSH host
   keys", and `gate/RUNBOOK.md`, section "Golden acceptance", using the
   address recorded in step 3. The bake runbook owns host-key handling and the
   SSH transport: use `ControlMaster=no` and `ControlPath=none`. The gate
   runbook owns acceptance order and criteria: use `sudo -n` for every remote
   privileged command. Run the shipped validator and verify the remote
   manifest, retained checkout, installed runner, fixture accounts, and
   source-image identity against the control-host artifacts. Keep the
   acceptance commands unredirected as required by the bake runbook. After
   each command returns, record its exact command and exit status, and record
   the remote and control-host manifest hashes in
   `work/m12-<run-id>/golden-acceptance.status`.
5. Follow `gate/RUNBOOK.md`, section "The tree on each host", using the
   address recorded in step 3. Reconfirm that the runner checkout is clean,
   remains on `release-1.3.0`, and still equals the candidate commit recorded
   in step 1. Push that candidate with `gate/drivers/push.bash`, deploy it with
   `bin/setup-system-infra.bash --full`, and verify the installed runner
   identity against the candidate commit.
6. Follow `gate/RUNBOOK.md`, section "The EPICS environment", to resolve and
   source the consumer's absolute EPICS environment path, then run
   `REPORT_MACHINE_OUTPUT=1 bash tests/run-all-tests.bash --system --installed`
   from the pushed candidate through SSH. Apply the standard-output and
   standard-error redirections to the control-host SSH invocation, not inside
   the remote command. Store standard output as
   `work/m12-<run-id>/system-installed.machine` and standard error as
   `work/m12-<run-id>/system-installed.human` on the control host.
7. Store the upstream-input record, image creation record, manifest, golden
   acceptance status record, suite outputs, and one `SHA256SUMS` file under
   the same `work/m12-<run-id>/` directory. Do not create a redirected copy of
   the acceptance output. Record the complete results and reconcile this
   detail and its GitHub issue.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Bake provenance | Fetch and record the three upstream inputs, require a clean runner `release-1.3.0` checkout equal to its fetched upstream, produce a new Rocky 8 golden with that ref, boot a fresh consumer, and run the shipped untouched-golden acceptance checks before candidate deployment | Rocky 8 consumer from the new copy-based image workflow artifact | The image pair is valid, the consumer reaches `READY`, the manifest matches both recorded supplier `origin/master` commits and the recorded runner `origin/release-1.3.0` commit, has clean supplier identities and `requested=release-1.3.0`, both baseline runner identities agree with its `app_ioc_runner commit`, and the unredirected acceptance commands have a complete status and manifest-hash record |
| T2 | Runtime acceptance | Reconfirm and push the same clean `release-1.3.0` candidate commit, fully deploy it, verify the installed runner identity, then run `REPORT_MACHINE_OUTPUT=1 bash tests/run-all-tests.bash --system --installed` while preserving both output streams under one `work/m12-<run-id>/` directory | Same fresh Rocky 8 consumer after candidate deployment | The installed runner agrees with the recorded candidate commit, and the real system-infrastructure and system-lifecycle suites emit complete final PASS records with the expected counts and evidence hashes |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-31 15:24 PDT | Fresh consumer `lab-rocky8-iocrunner-main` from `iocrunner-rocky8-20260831T220442Z-85267a69c44f.qcow2` | Pass | The bake published a valid image pair from `cloud-provision` `a5557d8`, `ansible-provision` `05b1ad8`, and runner `0ee75ab`; the manifest hash was `cb08d878c926c4f915673f74d942638ab29d6855f286cee95c289310c6e120d5` on both the control host and consumer; the consumer reached `READY`; the shipped validator, baseline checkout and runner identity checks, clean-manifest check, and fixture checks passed; `net-snmp-devel-5.8-33.el8_10.x86_64` supplied `/usr/lib64/libnetsnmp.so` |
| T2 | 2026-08-31 15:24 PDT | Same fresh Rocky 8 consumer after deployment of clean `release-1.3.0` commit `0ee75abc43883bb4c9191111485b35b9c3b1c2ed` | Pass | The shipped full setup passed 10/10; the installed runner reported `0ee75ab`; the real installed system-infrastructure suite passed with 36 total, 32 Pass, 4 NA, and no failures or script errors; the real installed system-lifecycle suite passed 144/144 with no NA, failures, or script errors; machine-output SHA-256 was `7c2e0bcf93fb8ba48edef69428b504e1fb94a2f8dbe039a19d5b7bf5e79f0913` and human-output SHA-256 was `755a4e686f9cc9515cc08642c01a75eb3840225be89e8287d5b2a211d661cc39` |

##### Closure Evidence

- T1 and T2 satisfy the implementation and verification criteria on
  2026-08-31. The canonical result landed on `origin/release-1.3.0` in
  `86094f0b1a0f961e1ebac92c2d7ada92dbe01906` and the remote branch was
  observed at that commit.
- Linked issue #146 was observed closed on 2026-08-31 with every Completion
  Criteria checkbox checked and the `tests` label, `1.3.0` milestone, and
  `jeonghanlee` assignee intact.

##### GitHub Projection

Title: Validate the current Rocky 8 golden through downstream runner suites
Labels: tests
GitHub Milestone: 1.3.0
Observed State: closed
Observed Labels: tests
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-31; remote updated 2026-08-31T22:39:10Z

#### M13 - SELinux context

Origin: 46790f9 / M1
Identity History: 46790f9 / M1 -> 1.3.0 / M13 (staged target, D12, 2026-08-30)
GitHub Issue: 120, https://github.com/jeonghanlee/epics-ioc-runner/issues/120
Status: Complete

##### Summary

Items 1 and 2 are examined-Keep decisions, not pending implementation. An enforcing Rocky 8 testbed reproduced the remaining setup defect: both policy files retained `user_tmp_t` after deployment while policy expected `etc_t`. The implementation corrected the deployment path, and an owner-authorized production SELinux-enforcing IOC host passed final acceptance.

##### Scope

On a SELinux-active host, normalize the sudoers and logrotate targets with `restorecon` after deployment and require `matchpathcon -V` to accept both final paths. Keep systems without active SELinux unchanged. Use the enforcing Rocky 8 testbed for implementation regression and an enforcing production IOC host for final acceptance.

##### Out of Scope

Reopening items 1 or 2 without new reachability evidence, or treating a non-enforcing golden as proof of production SELinux behavior.

##### Completion Criteria

- The setup preflight detects active SELinux and stops before any mutation if `restorecon` or `matchpathcon` is unavailable.
- The real setup deployment restores and verifies the policy context of both `/etc` targets when SELinux is active.
- The real setup path exits nonzero when final-context verification fails.
- The Debian setup path gains no SELinux package requirement and preserves its current behavior.
- The enforcing testbed proves both the corrected final state and detection of a deliberately wrong final type.
- Installation and test documentation describe the SELinux-active dependency and each new test identity, and the observed catalogs agree with `tests/reporting-counts.csv`.
- The canonical two-host gate accepts the updated common identity and completes with both host verdicts passing.
- An owner-authorized production IOC host is confirmed as SELinux `Enforcing` and accepts both deployed policy contexts.

##### Dependencies And Decisions

- M12
- D12
- D15
- D16
- Items 1 and 2 are retired as examined Keep in `docs/CLOSED_DOORS.md` CI-29.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner approved the reviewed M13 plan on 2026-08-31 ("승인함").
Implementation Authorization: Owner authorized M13 implementation on
2026-08-31 ("구현승인").
Superseded Plan Artifacts: none

1. Before the first setup mutation, detect active SELinux through `/sys/fs/selinux/enforce`; only in that state require executable `restorecon` and `matchpathcon`, and fail the preflight if either tool is unavailable.
2. Add a setup helper that runs `restorecon` on a deployed path and records a setup verification failure unless `matchpathcon -V` accepts the final context.
3. Apply the helper immediately after deploying `/etc/sudoers.d/10-epics-ioc` and `/etc/logrotate.d/procserv` without changing the inactive-SELinux path.
4. Extend the shipped system-infrastructure suite to verify both final contexts on an active SELinux host and report the check as not applicable otherwise.
5. Extend the existing private-mount-namespace setup regression with an active-SELinux fixture and outer-boundary tool controls. Require the real setup script to stop before target mutation when a required tool is unavailable and to exit nonzero when `matchpathcon -V` rejects a final path.
6. Update `docs/INSTALL.md` and `tests/README.md` with the SELinux-active dependency and checks, add the new identities to `tests/SYSTEM_INFRA_INVENTORY.md` and `tests/SOURCE_REGRESSION_INVENTORY.md`, and derive `tests/reporting-counts.csv` values only from closed real catalogs.
7. On the enforcing Rocky 8 testbed, run the corrected shipped full setup and system-infrastructure suite, then change one target to a wrong type, prove that the real suite fails, and restore the host through the shipped setup path.
8. Run the full setup and system-infrastructure path on Debian 13 and confirm that the SELinux checks are not applicable without adding a package requirement.
9. Run static checks, all affected catalog-only paths, reporting self-tests, full affected suites, inventory agreement, and the canonical two-host gate. Update the common gate identity only after the unchanged identity fails solely on the observed new records, then rerun the same gate to Pass.
10. Confirm an owner-authorized production IOC host is SELinux enforcing and repeat the final-context and policy-acceptance checks there before closure.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Diagnostic | Run the current shipped full setup on an enforcing Rocky 8 testbed and compare `matchpathcon` expectations with final contexts | Rocky 8 testbed | The pre-change path reproduces `user_tmp_t` where policy expects `etc_t` |
| T2 | Correction and regression | Run the corrected shipped full setup and system-infrastructure suite, change one final target to a wrong type, run the real suite, and restore through shipped setup | Same enforcing Rocky 8 testbed | Correct contexts pass, the wrong type fails, and the restored state passes |
| T3 | Setup failure paths | Run the shipped setup in its existing private mount namespace with an active-SELinux fixture and only outer-boundary tool controls | Source regression environment | A missing required tool stops before target mutation, and a rejected final context makes the real setup exit nonzero |
| T4 | Cross-distribution | Run the shipped full setup and system-infrastructure suite | Debian 13 testbed without active SELinux | Existing setup behavior passes, SELinux checks are not applicable, and no SELinux package is required |
| T5 | Contract integration | Run static checks, affected catalogs and suites, reporting self-tests, inventory comparison, and the canonical two-host gate before and after accepting the observed common identity | Source environment plus Debian 13 and Rocky 8 testbeds | Documentation and inventories name every new identity, catalog counts agree with the CSV, the first gate differs only by the expected identity, and the accepted rerun passes both hosts |
| T6 | Production acceptance | Read SELinux mode, run shipped setup, and compare expected and final policy contexts | Owner-authorized production IOC host | `Enforcing` is observed and both deployed policies carry expected contexts accepted by their consumers |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-31 16:22 PDT | Rocky 8.10 testbed, `testbed-rocky8-iocrunner-server` | Pass | `getenforce` reported `Enforcing`; current shipped full setup passed its 10 checks, but `matchpathcon -V` rejected both targets because policy expected `etc_t` and each deployed file retained `user_tmp_t`; `visudo` and `logrotate -d` accepted their contents |
| T2 | 2026-08-31 17:54 PDT | Rocky 8.10 testbed, `testbed-rocky8-iocrunner-server` | Pass: the corrected full setup restored and accepted both contexts; the real system-infrastructure suite passed both S07 policy checks; changing the sudoers target to `user_tmp_t` made that real check fail, and the shipped setup restored the accepted state | Direct testbed observation; restored final state in `work/gate-suites-20260901T004837Z-3311446` |
| T3 | 2026-08-31 17:54 PDT | Shipped source regression path on Debian 13 and Rocky 8 testbeds | Pass: S22 exercised the real setup in its private mount namespace; missing `restorecon` and `matchpathcon` stopped before target mutation, a rejected context exited nonzero, and the `Permissive` active-SELinux fixture processed both policy paths | Both source-regression runs in `work/gate-suites-20260901T004837Z-3311446`; the catalog closed at 119 checks and 18 steps |
| T4 | 2026-08-31 17:54 PDT | Debian 13 testbed without active SELinux | Pass: full setup completed without SELinux tools; system-infrastructure S07 reported all four identities as not applicable and the suite passed | Direct setup observation; Debian system-infrastructure evidence in `work/gate-suites-20260901T004837Z-3311446` |
| T5 | 2026-08-31 17:54 PDT | Source environment plus Debian 13 and Rocky 8 testbeds | Pass: Bash parse, whitespace, both affected catalogs, and reporting self-tests passed; warning-level shellcheck added no warning relative to `HEAD` and retained the existing SC1090 and SC2034 findings; the unchanged identity failed only against the same new digest on both hosts, and the accepted rerun passed six blocks and 845 checks per host with only documented OS applicability differences | Digest-only evidence in `work/gate-suites-20260901T002208Z-2788177`; final PASS in `work/gate-suites-20260901T004837Z-3311446` |
| T6 | 2026-08-31 22:24 PDT | Owner-authorized production SELinux-enforcing IOC host | Pass: `getenforce` reported `Enforcing`; both required tools were executable; the shipped `make setup` path passed 13/13; both deployed contexts passed `/usr/sbin/matchpathcon -V`; `visudo -cf` and `logrotate -d` accepted the deployed policies; and the real shipped system-infrastructure suite passed with 40 total, 36 Pass, 0 Fail, and 4 documented S06 applicability NAs | Owner-provided terminal transcript; installed candidate reported `1.3.0-dev (1647f8a)` with install date `2026-09-01T05:23:58Z` |

##### Closure Evidence

- Items 1 and 2 are retired as examined Keep in `docs/CLOSED_DOORS.md` CI-29.
- The enforcing Rocky 8 testbed established the defect, D15 selected the
  correction, and D16 activated implementation. An owner-authorized production
  SELinux-enforcing IOC host passed final acceptance.
- The implementation, testbed verification, and production acceptance T1-T6
  pass.
- Implementation commit `1647f8a3ded85f114714a129b8bfdf9c849868da`
  and production evidence commit
  `7c9f59013ac672a598678d7d40cbdf6ea7d49075` are pushed to
  `origin/release-1.3.0`; the latter was read back at the same upstream commit
  on 2026-08-31 22:32 PDT.
- Linked issue #120 is closed with every acceptance criterion checked;
  observed remote update `2026-09-01T05:32:30Z`.

##### GitHub Projection

Title: Validate SELinux contexts on system policy deployments
Labels: P3-low, ops
GitHub Milestone: 1.3.0
Observed State: closed
Observed Labels: P3-low, ops
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-08-31; remote updated 2026-09-01T05:32:30Z

#### M14 - Inspect process-context churn

Origin: 1.3.0 / M14
Identity History: none
GitHub Issue: #150, https://github.com/jeonghanlee/epics-ioc-runner/issues/150
Status: In progress

##### Summary

Keep `inspect` running when a server restart or client disconnect removes a
process after socket discovery but before process-context rendering.

##### Scope

- The server and client process-context paths in `do_inspect`.
- Required-tool validation and exit-status handling for the external `ps`
  boundary.
- Real local and system M10 lifecycle coverage for server replacement and
  client disconnect races.
- Separate race and cleanup evidence files, separate assertions, affected
  inventories, reporting counts, and gate identity.

##### Out of Scope

- IOC restart policy, procServ supervision, socket ownership, or executable
  identity rules.
- Background monitoring, automatic recovery, or a product-only test hook.
- Release Verification 3 and 4 execution before M15 Release Verification 2
  passes on the corrected candidate.

##### Completion Criteria

- A server process that disappears after socket discovery does not terminate
  `inspect`; a changed `MainPID:starttime` reports an unstable snapshot without
  an executable-drift warning.
- A real client that disconnects after its PID is discovered does not terminate
  `inspect`.
- `ps` is resolved with `command -v`, and the resolved path is required to be
  executable. Exit status 1 from the fixed PID-selection command is treated as
  process churn; missing execution or any other nonzero status remains a hard
  error.
- Local and system race checks report restart observation and `inspect`
  completion separately and retain race output independently from cleanup
  output.
- T1-T3 Pass through the shipped source and installed paths, and linked issue
  #150 agrees with the accepted implementation and observed results.

##### Dependencies And Decisions

- M10 is the completed behavioral foundation for log-path and procServ
  executable-identity inspection.
- D20 places this correction before the final release milestone.
- M15 Release Verification 2 failed at clean candidate
  `98902279e9b3111fa50b3e9dfb339b3fb44de6c7`. The real local source lifecycle
  failed on Debian 13 and Rocky 8, and the real installed system lifecycle
  failed on Rocky 8 because `ps` returned nonzero after a collected server
  process disappeared.
- The codebase review found the same unguarded volatile lookup only in the
  server and client process-context `ps` calls. The surrounding `lsof`, `ss`,
  snapshot, and setup-time systemd paths retain their existing failure policy.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner approved the M14 plan on 2026-09-02.
Implementation Authorization: Owner authorized the accepted M14 plan on
2026-09-02.
Superseded Plan Artifacts: none

1. Add one process-context renderer in `bin/ioc-runner` and route both server
   and client PID sets through it. Resolve `ps` with `command -v`, require the
   resolved path to be executable, run the fixed PID-selection command, accept
   only status 1 as a no-surviving-process observation, and propagate every
   other nonzero status.
2. Preserve the existing socket discovery, required `ss` failure, initial and
   final `MainPID:starttime` snapshots, UDS ownership, and executable-identity
   decisions. Add no retry, service mutation, or test-only runtime branch.
3. In `tests/lib/test-m10-local.bash` and
   `tests/lib/test-m10-system.bash`, give the server race, client race, and
   cleanup probe separate output files. Split restart observation from
   `inspect` completion so either failure names its own invariant.
4. Exercise the real server race after the server PID set is collected. For
   the client path, attach a real `socat` client and first prove that a baseline
   `inspect` reports its PID. Use a temporary outer-boundary `ps` wrapper to
   pause the shipped inspection after its fixed PID selection is received,
   perform exactly one server restart or client disconnect, then resume the
   same request through the real `ps`. Require the completed output to exclude
   the retired PID; add no product test hook or scheduling retry.
5. Update only the affected lifecycle catalogs, inventories,
   `tests/reporting-counts.csv`, and gate identity from the resulting real
   checks. Run focused source and installed lifecycle tests before the full
   replacement-candidate gate.

##### Test Plan

| ID | Check | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Process-context exit contract and source consistency | Run Bash syntax and ShellCheck gates; exercise the shipped `inspect` path with the external `ps` boundary returning the allowed no-selection status and disallowed execution statuses; verify both server and client paths call the common renderer and no other inspection failure policy changes | Canonical checkout | Syntax and lint pass; `command -v` and executable-path validation both accept the required tool; status 1 continues to the final snapshot; missing or other failing `ps` execution remains nonzero; catalogs, inventories, counts, and gate identity agree |
| T2 | Real server and client churn | Run the shipped local and system M10 lifecycle paths with a real service restart and a real `socat` client disconnect after confirmed discovery; run source and installed combinations used by the gate | Debian 13 and Rocky 8 release consumers | Every accepted overlap executes the real `inspect`, `ps`, systemd, procServ, and UDS paths; `inspect` returns success for disappearing processes; server churn reports unstable rather than drift; separate evidence files remain available |
| T3 | Replacement-candidate release gate | Push one clean candidate, deploy it through full setup on both fresh consumers, and run `gate/drivers/control/suites.bash` through all six declared suite blocks per host | Debian 13 and Rocky 8 release consumers | Both host verdicts and the final gate verdict pass; derived counts agree with `tests/reporting-counts.csv`; cross-host differences contain only reviewed applicability states |

##### Verification Results

| ID | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-02 11:26 PDT | Canonical checkout and both release consumers | Pass | Bash syntax, ShellCheck, diff whitespace, and real catalog closure passed; local and system catalogs closed at 188 checks/38 steps and 155 checks/35 steps; both source local-lifecycle runs exercised status 1, 2, 127, and non-path `ps` boundary checks. The prior-digest gate observed one common identity `41df722b77a2ba3040e8541e00cfeb0ad5701b5b75e09e6542609e810701704e`; after changing only the fixed digest, `work/gate-suites-20260902T182103Z-587998` passed 6 blocks and 897 checks on each OS family |
| T2 | 2026-09-02 11:12 PDT | Debian 13 and Rocky 8 release consumers, current candidate based on `f754a95` | Pass | Real local-lifecycle source and installed runs passed on both OS families: Debian 188/188 in each mode, Rocky 184/188 with the four established journal-policy NA results in each mode. Real installed system-lifecycle passed 155/155 on both. Every M14 server-restart, client-disconnect, inspect-completion, PID-exclusion, unstable-snapshot, and cleanup assertion passed through the shipped systemd, procServ, UDS, `socat`, and `ps` paths |
| T3 | 2026-09-02 11:53 PDT | Debian 13 and Rocky 8 release consumers at clean commit `63c7f828f1145bda4036d9f4641ac6f02d647cd6` | Pass | Both remote checkouts were clean at the pushed candidate; shipped full setup passed 9/9 on Debian and 12/12 on Rocky; source and installed runner identities matched `63c7f82`; `work/gate-suites-20260902T184643Z-592313` passed all six blocks and 897 checks per host with no FAIL, SKIP, or SCRIPT_ERROR. Debian reported 5 and Rocky 12 reviewed NA results; the 88-line cross-host diff contained only the established S23, S29, S06, and S07 OS applicability differences; both test workspaces cleaned completely |

##### Closure Evidence

- Implementation commit `63c7f828f1145bda4036d9f4641ac6f02d647cd6`
  is present on fetched `origin/release-1.3.0`; local and upstream IDs matched at
  2026-09-02T11:38:15-0700.
- Full-setup evidence hashes are
  `26061a0bb346e0395032e868a17efb76f846b4b7412159da5c54fc7106f0117f`
  for Debian and
  `0a23fa988815ff4c0b123008ed5bbe5b9a334019bbcac567bc3626f239186d24`
  for Rocky.
- The clean-candidate gate evidence is
  `work/gate-suites-20260902T184643Z-592313`; its reviewed cross-host diff has
  SHA-256
  `49a38f96afbe69b3fdf9362e03b10d18571124887caf883fc03ce893ffe4fb38`.
- GitHub issue #150 remained open with the projected labels, milestone, and
  assignee when observed at 2026-09-02 11:53 PDT.

##### GitHub Projection

Title: Keep inspect alive when process context changes during restart
Labels: bug, P2-medium, area/inspect, tests
GitHub Milestone: 1.3.0
Observed State: open
Observed Labels: bug, P2-medium, area/inspect, tests
Observed Milestone: 1.3.0
Observed Assignee: jeonghanlee
Last Compared: 2026-09-02; remote updated 2026-09-02T17:00:29Z

#### M15 - Final release

Origin: 1.3.0 / M11
Identity History: 1.3.0 / M11 -> 1.3.0 / M12 (new M11 inserted, D10, 2026-08-30); 1.3.0 / M12 -> 1.3.0 / M14 (M12 and M13 inserted, D12, 2026-08-30); 1.3.0 / M14 -> 1.3.0 / M15 (new M14 inserted, D20, 2026-09-02)
GitHub Issue: none
Status: In progress

##### Summary

Complete the 1.3.0 release: integrated verification of the full milestone set
on both golden OS families, the version change to 1.3.0, release execution,
and final Release Verification.

##### Scope

Release-wide ordering, the integrated gate re-run, production environment
tests, version changes, the master merge and tag, the GitHub release, and the
milestone close, following the release-cycle procedure.

##### Out of Scope

Individual milestone implementation and verification, which the M1-M14 rows
own.

##### Completion Criteria

- Every dependency row is Complete and G1 is Complete.
- A fetched `master` is integrated into `release-1.3.0` before the release
  candidate is established, and the final candidate is clean and pushed.
- New Debian 13 and Rocky 8 release-gate images are baked from baseline tag
  `1.2.4`; fresh consumers from that pair pass the complete standing gate.
- After publication, a separate clean Rocky 8 production-equivalent consumer
  with no existing `epics-ioc-runner` installation passes the documented
  initial installation path from tag `1.3.0`.
- `CHANGELOG.md` contains the accepted 1.3.0 release entry and
  `RUNNER_VERSION` changes from `1.3.0-dev` to `1.3.0` in its own commit.
- The curated GitHub release notes are reviewed against the accepted changelog
  entry and the `1.2.4...1.3.0` comparison before publication.
- Every Release Verification row records Pass with reachable real-path
  evidence.
- The merge commit, annotated tag `1.3.0`, GitHub release, closed remote
  milestone, and production deployment agree on the released object.
- The master canonical register records #127 as the surviving Backlog entry
  after 1.3.0; no new release line is opened and all existing
  `release-1.2.x` branches remain unchanged.

##### Dependencies And Decisions

- M1, M2, M3, M4, M5, M6, M7, M8, M9, M10, M11, M12, M13, M14, G1
- D1
- D17
- D18
- D19
- D20
- Observed 2026-09-01: merge commit
  `d926ee9b4dc3a306729d3ba94d07afdc25c0aa79` integrates fetched
  `origin/master` commit `757dcd2464d34d616a32fe7175ba9371ddc8e92c`;
  local `release-1.3.0` and its upstream agree at the merge commit.
- Observed 2026-09-01: GitHub milestone 1.3.0, number 16, remains open with
  13 closed issues and no open issues.
- Observed 2026-09-02: Release Verification 2 failed at clean candidate
  `98902279e9b3111fa50b3e9dfb339b3fb44de6c7`. The real local source lifecycle
  failed on Debian 13 and Rocky 8, and the real installed system lifecycle
  failed on Rocky 8 when `inspect` overlapped a service restart. The restart
  produced a new `MainPID:starttime`, but a collected process disappeared
  before `ps` read it and `set -e` terminated `inspect` before the final
  snapshot comparison. Issue #150 owns the correction and the related test
  evidence improvements; Release Verification 3 and 4 remain Pending.
- Observed 2026-09-02: GitHub milestone 1.3.0, number 16, remains open with
  issue #150 as its only open issue.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner approved the reviewed M15 plan, then identified as M14,
on 2026-08-31 and
accepted its correction to the current cloud image-pair and manifest-sidecar
contract on
2026-09-01.
Implementation Authorization: Owner authorized M15 implementation, then
identified as M14, on
2026-08-31 and the cloud-contract documentation correction on 2026-09-01.
Superseded Plan Artifacts: none

1. Fetch both branches, require clean named worktrees and current upstreams,
   review the three `master`-only commits, then merge fetched `master` into
   `release-1.3.0` under separate release authority and push the integration
   result under separate Push authority.
2. Record Release Verification 5 against the integrated clean release branch:
   `RUNNER_VERSION` is `1.3.0-dev` and no 1.3.0 changelog section exists.
3. Bake new Debian 13 and Rocky 8 images through the real cloud-provision image
   workflow with baseline tag `1.2.4`, validate each published versioned image
   pair and manifest sidecar in `IMAGE_DIR`, create fresh consumers, and record
   Release Verification 1 before candidate deployment.
4. Record Release Verification 1 and 5, pass repository checks, and create and
   push a separately authorized pre-change evidence commit before any version
   mutation.
5. Add the accepted `1.3.0 - Reliability and Configuration Contract Release`
   entry to `CHANGELOG.md` in a standalone commit.
6. Prepare and review `work/release-notes-1.3.0.md` from that changelog entry,
   with the accepted release title and the `1.2.4...1.3.0` comparison link.
7. Change only `RUNNER_VERSION` in `bin/ioc-runner` from `1.3.0-dev` to
   `1.3.0` in a standalone version commit.
8. Push that exact version commit to both fresh consumers through
   `gate/drivers/push.bash`, run the shipped full setup, and require source and
   installed runner provenance to match the tested version commit.
9. After M14 T3 passes its complete two-host suite gate and M14 is Complete,
   push the exact corrected product commit to both fresh consumers, deploy it
   through full setup, and execute Release Verification 2 as a separate
   complete two-host suite-gate run. Only after that separate run passes,
   execute Release Verification 3 and 4 through the remaining real standing
   paths in `gate/RUNBOOK.md`: both multi-user scenario runs and the
   root_squash deployment path. Record Release Verification 6 from the same
   corrected product commit.
10. Review the complete readiness evidence, leave post-release checks Pending,
    and create and push one readiness-evidence commit. Require every commit
    after the tested corrected product commit to contain only canonical
    evidence updates; the readiness-evidence commit ID is the immutable release
    candidate selected for every release action.
11. Execute only the separately previewed and authorized merge, branch Push,
    annotated tag, tag Push, GitHub release, and remote milestone-close
    actions. After each remotely irreversible result, run repository checks
    and create the separately authorized canonical checkpoint commit before
    the next dependent action. Every later action names the recorded release
    merge commit or tag explicitly rather than selecting the new `HEAD`.
12. Run the released-object storage preflight and independently verify the
    actual released objects and tracker as Release Verification 7. Recreate a
    plain `rocky8.main` consumer through the real cloud-provision target,
    provision only the documented prerequisites, prove that no default
    runner-owned installation target exists, and execute the documented
    initial installation from tag `1.3.0`. Separately update only the CLI from
    the same tag with `make install` on the owner-authorized SELinux-enforcing
    IOC host, then verify its retained infrastructure. Both observations
    constitute Release Verification 8.
13. Record the post-release results, #127 next-entry state, branch-retention
    result, and issue intent while M15 remains In progress; pass repository
    checks and create a separately authorized source-first preparation commit.
    Re-read every linked issue, then mark M15 Complete, record Release
    Verification 9, and create and push the separately authorized closure
    commit without opening a release line or deleting a release branch.

##### Test Plan

The Release Verification Plan below owns the final checks. Every method runs
through the shipped repository, gate, installation, Git, or GitHub path and
uses consecutive `Release Verification <k>` labels; M15 defines no local T
labels.

##### Integrated Verification

| Source Check | Re-run Trigger | Shared Surface | Release Verification Label | Expected Result | Result Evidence |
| --- | --- | --- | --- | --- | --- |
| M1 / T1-T5; M7 / T1-T3; M8 / T1-T4 | Later runner, reporter, and gate changes plus the final version mutation | Reporter ledger, catalogs, machine output, installed logrotate service, and gate aggregation | Release Verification 2 | Every real catalog agrees with `tests/reporting-counts.csv`; all six suite blocks close through the shared ledger and the deployed logrotate path remains green | The checks passed within the failed `9890227` gate; the complete replacement-candidate rerun remains pending under #150 |
| M2 / T1-T5; M3 / T1-T6; M5 / T1-T4; M6 / T1-T3; M10 / T1-T3 | Later changes to the shared runner, setup, systemd, and installed executable | EPICS entry boundary, conf parser, diagnosis, log path, and procServ identity | Release Verification 2 | The final combined candidate preserves every accepted configuration and reliability behavior on both supported OS families | Fail at `9890227`: the M10 restart race terminated `inspect` before its final snapshot comparison; #150 owns the correction |
| M4 / T1-T2 | Later runner, conf, and test changes reach procServ supervision | Real systemd to procServ to child restart path | Release Verification 2 | The shipped lifecycle path still observes child recovery under the same procServ on both consumers | The M4 checks passed within the failed `9890227` gate; the complete replacement-candidate rerun remains pending under #150 |
| M9 / T1-T6 | Later canonical and documentation edits could reintroduce a removed live reference | Tracked documentation authority and reference integrity | Release Verification 5; Release Verification 6 | The removed draft stays absent, every live reference resolves, and the canonical path remains unique before and after the M14 correction | Release Verification 5 Pass before M14 was inserted; Release Verification 6 recheck pending |
| M12 / T1-T2 | M15 selects a newly baked two-image pair and fresh consumers | Image provenance and downstream runner suites | Release Verification 1; Release Verification 2 | Both new images validate against baseline `1.2.4`, and both fresh consumers pass the final combined candidate | Release Verification 1 Pass; Release Verification 2 Fail at `9890227`, with the replacement-candidate rerun pending under #150 |
| M13 / T1-T5 | The final versioned candidate is redeployed after the M13 implementation commit | SELinux-active policy deployment and installed context checks | Release Verification 2 | Rocky accepts both deployed contexts; Debian retains the inactive-SELinux path; the final two-host gate passes | The M13 checks passed within the failed `9890227` gate; the complete replacement-candidate rerun remains pending under #150 |
| M13 / T6 | The tagged release replaces the pre-release production candidate | Documented production setup and SELinux-enforcing consumer acceptance | Release Verification 8 | The actual released tag installs with accepted contexts and passes the shipped installed-state suite | pending |
| M14 / T1-T3 | The final release reruns the complete gate after the focused correction gate | Process-context rendering, lifecycle evidence separation, and full suite aggregation | Release Verification 2 | M14 first closes on its own T1-T3 evidence; a distinct complete two-host suite-gate run then passes as Release Verification 2 | pending |

##### Production Environment Tests

| Release Verification Label | Timing | System | Version | Architecture | Deployment Path | Method | Expected Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Release Verification 8 | post-release | Fresh plain Rocky 8 production-equivalent consumer created by the cloud-provision `rocky8.main` target | Record `ID` and `VERSION_ID` from `/etc/os-release` before installation | Record `uname -m` before installation | Clean checkout of tag `1.3.0` through the initial `docs/INSTALL.md` full-setup path | Provision only the documented prerequisites; require `ioc-srv`, group `ioc`, `/usr/local/bin/ioc-runner`, `/usr/bin/ioc-runner`, `/etc/procServ.d`, `/etc/sudoers.d/10-epics-ioc`, `/etc/systemd/system/epics-@.service`, `/etc/logrotate.d/procserv`, `/etc/bash_completion.d/ioc-runner`, and `/var/log/procserv` to be absent; follow the documented initial installation; run `matchpathcon -V` for both policy files, `visudo -cf`, `logrotate -d`, and the shipped `tests/test-system-infra.bash` from a root-readable local tree | The clean installation succeeds; `-V` reports `1.3.0` and the released short hash; both context checks, both policy consumers, and the suite pass with no Fail or Script Error | pending |
| Release Verification 8 | post-release | Owner-authorized SELinux-enforcing production IOC host | Record `ID` and `VERSION_ID` from `/etc/os-release` before deployment | Record `uname -m` before deployment | Clean checkout of tag `1.3.0` through the documented `make install` CLI-update path | After the released-object storage preflight, run `make install`, read `ioc-runner -V`, run `matchpathcon -V` for both retained policy files, `visudo -cf`, `logrotate -d`, and the shipped `tests/test-system-infra.bash` from a root-readable local tree | The CLI update succeeds; `-V` reports `1.3.0` and the released short hash; both retained context checks, both policy consumers, and the suite pass with no Fail or Script Error | pending |

##### Version Changes

| Field | File | Before | Planned After | Pre-check | Pre-check Label | Post-check | Post-check Label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Release heading | `CHANGELOG.md` | No 1.3.0 section | `1.3.0 - Reliability and Configuration Contract Release` | Require exactly zero 1.3.0 headings before mutation | Release Verification 5 | Require exactly one accepted 1.3.0 heading and review its issue references against the closed 1.3.0 issue set | Release Verification 6 |
| `RUNNER_VERSION` | `bin/ioc-runner` | `1.3.0-dev` | `1.3.0` | Read the single declaration before mutation | Release Verification 5 | Read the source declaration and deployed `ioc-runner -V` on both fresh consumers | Release Verification 6 |

##### Release Execution

- Issues #148 and #139 were manually closed after verification on 2026-08-19.
  Their implementation commits retain exact `Closes` footers, which become
  no-ops when the release branch reaches the default branch.
| Step | Action | Authorization | Expected Result | Evidence |
| --- | --- | --- | --- | --- |
| 1 | Merge fetched `master` into `release-1.3.0` before pre-change verification | Release delegation after exact command preview | The release branch contains current master and preserves both canonical paths | Pass 2026-09-01: `d926ee9b4dc3a306729d3ba94d07afdc25c0aa79` has parents `8d87048714a260f46fd8d85243d10eaa9672d865` and `757dcd2464d34d616a32fe7175ba9371ddc8e92c`; the merge completed without conflict |
| 2 | Push the integration merge to `origin/release-1.3.0` | Push delegation | Local and upstream release refs agree | Pass 2026-09-01: fetched `origin/release-1.3.0` and local `HEAD` both resolve to `d926ee9b4dc3a306729d3ba94d07afdc25c0aa79` |
| 3 | Commit Release Verification 1 and 5 pre-change evidence | Commit delegation | One checked pre-change evidence commit precedes every version mutation | pending |
| 4 | Push the pre-change evidence commit to `origin/release-1.3.0` | Push delegation | The fetched upstream contains the durable pre-change state | pending |
| 5 | Commit the accepted 1.3.0 changelog section | Commit delegation | One standalone changelog commit | pending |
| 6 | Commit the `RUNNER_VERSION` change to 1.3.0 | Commit delegation | One standalone version commit changing only `bin/ioc-runner` | pending |
| 7 | Commit Release Verification 2-4 and 6 readiness evidence | Commit delegation | The reviewed readiness commit descends from the tested corrected product commit through canonical-evidence-only commits and names the immutable release candidate | pending |
| 8 | Push the readiness candidate to `origin/release-1.3.0` | Push delegation | The fetched upstream identifies the accepted candidate | pending |
| 9 | Merge the named release candidate into `master` with `--no-ff` | Release delegation after exact command preview | One release merge commit on `master` | pending |
| 10 | Push the release merge commit to `origin/master` | Push delegation | Local and upstream master identify the release merge | pending |
| 11 | Commit the release-merge checkpoint | Commit delegation | The canonical record names the candidate, merge commit, and observed upstream master | pending |
| 12 | Create annotated tag `1.3.0` on the recorded release merge commit | Release delegation after exact command preview | One annotated tag with the accepted release title targets the recorded merge, not the checkpoint `HEAD` | pending |
| 13 | Push exactly `refs/tags/1.3.0` to `origin` | Tag Push delegation | The remote tag object ID matches the inspected local tag object | pending |
| 14 | Commit the tag checkpoint | Commit delegation | The canonical record names the tag object and peeled release merge commit | pending |
| 15 | Create the GitHub 1.3.0 release from reviewed `work/release-notes-1.3.0.md` | Release delegation after exact command preview | One published release object targets tag `1.3.0` and carries the accepted notes | pending |
| 16 | Commit the GitHub-release checkpoint | Commit delegation | The canonical record names the published release URL and target tag | pending |
| 17 | Close remote GitHub milestone 1.3.0, number 16 | Release delegation after exact command preview | The milestone is closed with no open linked issue | pending |
| 18 | Commit the remote-milestone checkpoint | Commit delegation | The canonical record contains the observed closed milestone state | pending |
| 19 | Commit the post-release preparation record with Release Verification 7-8, #127 next-entry state, branch retention, and issue intent while M15 remains In progress | Commit delegation | One checked source-first preparation commit precedes final issue read-back and M15 closure | pending |
| 20 | Commit M15 completion and Release Verification 9 after final issue and canonical read-back | Commit delegation | One checked cycle-closure commit on `master` points to deferred Backlog issue #127 without branch creation or deletion | pending |
| 21 | Push the closure commit and accumulated canonical checkpoints to `origin/master` | Push delegation | Local and upstream closure state agree | pending |

##### Release Verification Plan

| Label | Layer | Timing | Method | Environment | Expected Result | Evidence Target |
| --- | --- | --- | --- | --- | --- | --- |
| Release Verification 1 | Image and golden acceptance | pre-change | Bake both images with baseline tag `1.2.4`, validate each versioned qcow2 image with its matching creation record and manifest sidecar in `IMAGE_DIR`, create fresh consumers, and run the acceptance sequence in `gate/RUNBOOK.md` before candidate deployment | New Debian 13 and Rocky 8 release-gate images and fresh consumers | Both manifests record baseline `1.2.4`, both image pairs pass validation, and both consumers have accepted provenance and clean retained checkouts | Image-pair names and hashes, manifest-sidecar hashes, and consumer acceptance records |
| Release Verification 2 | Automated and integrated checks | post-change | Push the exact corrected product commit, run shipped full setup, then run `gate/drivers/control/suites.bash` through the complete six-suite matrix | Both fresh consumers at the tested corrected product commit | Both host verdicts and the final gate verdict pass; derived counts agree with `tests/reporting-counts.csv`; cross-host differences contain only reviewed applicability states | Complete gate evidence directory, setup logs, runner provenance, and cross-host comparison |
| Release Verification 3 | Standing multi-user scenarios | post-change | Run `gate/drivers/control/run-all.bash` on each fresh consumer | Both fresh consumers at the tested corrected product commit | Every declared scenario has one Pass verdict and no missing or failed scenario | Per-scenario records and each host's final verdict |
| Release Verification 4 | root_squash deployment | post-change | Run the standing denial precheck and all root_squash deployment entries from `gate/RUNBOOK.md` using the exact corrected product commit | Both fresh consumers at the tested corrected product commit | The denial boundary is reproduced, each documented deployment entry stamps the tested corrected product commit hash, and no unrelated configuration changes | Procedure logs, configuration fingerprints, and deployed `-V` output |
| Release Verification 5 | Pre-change consistency | pre-change | On the clean integrated release branch, inspect `RUNNER_VERSION`, the absence of a 1.3.0 changelog heading, canonical references, branch ancestry, and tracker state | Release branch, Git, tracked documentation, and GitHub | Version is `1.3.0-dev`; the 1.3.0 changelog section is absent; live references resolve; the release branch contains master; the original 13 linked issues are closed and milestone 16 remains open | File reads, tracked-reference checks, commit IDs, ancestry result, and tracker observation |
| Release Verification 6 | Post-change version, notes, and current release state | post-change | Inspect the version, corrected product, and changelog commits; review the release-notes file; deploy the corrected product through full setup on both consumers; read source and installed version identity; and recheck canonical references and tracker state after M14 | Release branch, both fresh consumers, tracked documentation, and GitHub | Changelog has one accepted 1.3.0 section; release notes agree with it and name the `1.2.4...1.3.0` comparison; source and deployed runners report `1.3.0` and the tested corrected product commit hash; the version commit changes only `bin/ioc-runner`; live references resolve; all 14 linked issues are closed; every later commit through the readiness candidate changes only canonical evidence | Commit path lists and ancestry, changelog and release-notes comparison, source reads, setup logs, `ioc-runner -V` output, tracked-reference checks, and tracker observation |
| Release Verification 7 | Released objects and tracker | post-release | After the released-object storage preflight, independently read the master merge commit, annotated tag, GitHub release target, milestone, and linked issue states | Canonical Git remote and GitHub | Merge, tag, and release object identify the accepted candidate ancestry; milestone 16 is closed; all 14 linked issues remain closed | Object and peeled commit IDs plus GitHub read-back |
| Release Verification 8 | Clean installation and production deployment | post-release | Execute both Production Environment Test rows above from the actual released tag | Fresh plain Rocky 8 production-equivalent consumer and owner-authorized SELinux-enforcing production IOC host | The clean initial installation and production CLI update both install the released identity; policy contexts and consumers pass; both real installed-state suites have no failure | Clean-install and production-update version, context, consumer, and suite records without production host identity |
| Release Verification 9 | Cycle closure | post-release | Compare the checked canonical closure file with its committed copy, read M15 and the release tally, and inspect the master canonical next entry | `master`, canonical documents, and fetched upstream | M15 is Complete; every Release Verification row is Pass; the 1.3.0 record is durable; master points to its surviving Backlog work; local and upstream closure state agree | Closure commit ID, byte comparison, register rows, and upstream read-back |

##### Release Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| Release Verification 1 | 2026-09-01 18:49 PDT | New Debian 13 and Rocky 8 release-gate images and fresh consumers | Pass | Both published image pairs passed the shipped pair validator, no-backing check, and `qemu-img check`; both fresh consumers matched their new source images; both remote manifests matched their sidecars; the canonical validator accepted both retained checkouts and installed runners; see the Release Verification 1 Evidence table |
| Release Verification 2 | 2026-09-02 01:14 PDT | Both fresh Debian 13 and Rocky 8 consumers at candidate `98902279e9b3111fa50b3e9dfb339b3fb44de6c7` | Fail | The complete two-host gate ran the six declared suite blocks per host. Debian local source failed two M10 race checks; Rocky local source and installed system paths failed the same two checks. Direct tracing of the real Rocky local source path confirmed that restart changed `MainPID:starttime`, then `ps` returned nonzero for a process collected before restart and `set -e` ended `inspect` before the final snapshot comparison. The codebase review found the same volatile lookup only in the server and client process-context `ps` calls; it also found that the M10 race tests combine restart observation with inspect completion and overwrite race output during cleanup. Issue #150 tracks the correction. Evidence: `work/gate-suites-20260902T081436Z-236978` |
| Release Verification 3 | Not run | Both fresh consumers at the tested corrected product commit | Pending | none |
| Release Verification 4 | Not run | Both fresh consumers at the tested corrected product commit | Pending | none |
| Release Verification 5 | 2026-09-01 08:54 PDT | Integrated `release-1.3.0`, Git, tracked documentation, and GitHub | Pass | `RUNNER_VERSION` is `1.3.0-dev`; `CHANGELOG.md` has zero 1.3.0 headings; `origin/master` commit `757dcd2464d34d616a32fe7175ba9371ddc8e92c` is an ancestor of merge commit `d926ee9b4dc3a306729d3ba94d07afdc25c0aa79`; local and upstream release refs agree; both canonical paths and their documented authority resolve; GitHub milestone 16 is open with 0 open and 13 closed issues |
| Release Verification 6 | Not run | Release branch and both fresh consumers | Pending | none |
| Release Verification 7 | Not run | Canonical Git remote and GitHub | Pending | none |
| Release Verification 8 | Not run | Fresh plain Rocky 8 production-equivalent consumer and owner-authorized SELinux-enforcing production IOC host | Pending | none |
| Release Verification 9 | Not run | `master`, canonical documents, and fetched upstream | Pending | none |

##### Release Verification 1 Evidence

| Platform | Published Image and SHA-256 | Creation Record SHA-256 | Manifest SHA-256 | Fresh Consumer Record | Installed Runner | Golden Acceptance Record |
| --- | --- | --- | --- | --- | --- | --- |
| Rocky 8 | `iocrunner-rocky8-20260902T013005Z-88835f3f1262.qcow2`; `13320629abb8f3721d7080a0bb3ab6cea86446bf93ea16c827d6b45ed0764048` | `96ba2f063e82824321337c13347daf445c84ada079001b5a632d77b8652d6fcf` | `9f3124e08eff4cd15d0277706274b800e167dbf62c9393127bf6c3ea47e0648e` | `20260902T014421Z-c8e18ed3ac9f`; source image matched | `1.2.4 (1961fbf)` | `work/m14-20260902T014900Z/rocky-golden-acceptance.log`; `e0a79f62467c5d11b23258b7ea5bcd732a4b6efc65beb00a55f400ca3ad7453a` |
| Debian 13 | `iocrunner-debian13-20260902T013303Z-c23caacf9795.qcow2`; `de05c6f036e57c27bcb81608400eb944b2c399269ae0f1a0af686e12482138aa` | `fc61e7a75fd99b6a8f12e25b1ed1da590495373f55bf235909fdb129fed185ef` | `ea7374a91d60605b59292e0d9a5a7debcf8d8625e05d7b7a1a2b1c398421b78a` | `20260902T014450Z-73c3f395c53e`; source image matched | `1.2.4 (1961fbf)` | `work/m14-20260902T014900Z/debian-golden-acceptance.log`; `e8e612bb14253ae759646a652a28d58a47da46e1ce59f4b13227481568abb7df` |

Both manifests record `requested=1.2.4`, clean tagged runner commit
`1961fbffbb1c650999b62d562f05363152c6a9cd`, cloud-provision commit
`35c859b17830e976cc09ad95f29051cfd469e61d`, and ansible-provision commit
`67bc25c1d9672948cb48827b0afede263fec3296`. The supplier commits remained
unchanged across the image pair, and neither manifest contains a dirty source
record. Both images report a 20 GiB virtual size, no backing file, no qcow2
errors, and no corrupt or dirty flag.

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

M15 (final release) and the GitHub projection of M1-M14. Every linked issue is
assigned to the open `1.3.0` milestone.

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
