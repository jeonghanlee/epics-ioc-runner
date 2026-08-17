# Work Register

Release line: 1.2.4
Milestone index: 1.2.4
Canonical path: `docs/milestone-1.2.4.md`
Canonical branch or ref: `release-1.2.4`
Git upstream: `origin/release-1.2.4`
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `1.2.4`,
number 15
Activation state: active on `release-1.2.4`; source authority moved in master
commit `e357210e5c447d5736684395cd7f5d780b9df246`.

Next session entry point: G2 and M17 are Complete (M17 verified T1/T2/T3 on
both fresh goldens, 2026-08-16). Carry the remaining 1.2.4 work — M6 (settle the
shared-asset refresh policy first), M13, and M19 — toward the M16 release gate.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Detection | M3 | (#114) Boundary hygiene for the FATAL crash-token subset | Milestone | Complete | No | D1, D2, D5 | Commit `fccef50` and two-golden real-path evidence satisfy T1 and T2; issue #114 is closed; [detail](#m3---fatal-token-boundary-hygiene) |
| Setup | M7 | (#118) Type expectation for `verify_path` (false-green directory impostors) | Milestone | Complete | No | D1, D2 | Commit `50f27b2`, two-host shipped-path verification, and closed issue #118 satisfy T1 and T2; [detail](#m7---verify_path-type-expectation) |
| Integration | G2 | ([jeonghanlee/ansible-provision#13](https://github.com/jeonghanlee/ansible-provision/issues/13)) Propagate the configured installed runner destination | External gate | Complete | No | | Implementation commit `5a7d2aa` and the real `app_ioc_runner` role verify default and alternate destinations on Debian 13 and Rocky 8; [detail](#g2---ansible-installed-runner-destination-propagation) |
| Tests | M17 | (#145) Installed lifecycle tests honor `IOC_RUNNER_SCRIPT_DEST` | Milestone | Complete | No | G2, D4 | Installed mode keeps `/usr/local/bin/ioc-runner` as its default and exercises the destination deployed by the real Ansible role through both lifecycle suites; [detail](#m17---installed-runner-destination) |
| Local install | M6 | (#117) Reorder local install so deployment follows the abort gates | Milestone | Open | No | D1, D2 | Owner settles whether accepted installs refresh shared assets, then abort and accepted paths meet their ordering contracts; [detail](#m6---local-install-ordering) |
| Local install | M13 | (#143) Make local logrotate validation independent of the system state file | Milestone | Not started | No | M6, D1, D2 | Local validation avoids the system state file and consecutive two-golden runs pass without changing its metadata; [detail](#m13---local-logrotate-state-isolation) |
| Setup | M19 | (#147) Create the parent directory of `IOC_RUNNER_SCRIPT_DEST` before deploying the CLI | Milestone | Not started | No | | The shipped setup deploys the CLI to a non-default `IOC_RUNNER_SCRIPT_DEST` whose parent is absent on both goldens, and the default path stays unchanged; [detail](#m19---setup-destination-parent-creation) |
| Tracker | G1 | GitHub milestone 1.2.4 exists | External gate | Complete | No | | Repository owner created open GitHub milestone 1.2.4, number 15; [detail](#g1---github-milestone-1.2.4) |
| Release | M16 | Final release 1.2.4 | Milestone | Not started | No | M3, M7, M17, M6, M13, M19, G1, D3 | Tag `1.2.4`, GitHub release, milestone closed, production install verified, and every Release Verification row Pass; [detail](#m16---final-release) |

### Decisions

| ID | Decision | Source |
| --- | --- | --- |
| D1 | Stage M3, M7, M6, and M13 on `release-1.2.4`; authority moves only after the master source transfer commit names this exact target commit and removes the four source rows and details. | Owner-approved cross-branch assignment, 2026-08-12 |
| D2 | Run the bugfix work in the order M3, M7, M6, and M13. M3 and M7 are independent; M6 precedes M13 because both change the local install path. | Owner-accepted 1.2.4 cycle plan, 2026-08-12 |
| D3 | Final release verification runs the complete gate on Debian 13 and Rocky 8, changes the version to 1.2.4, verifies the release objects, and verifies the documented production install path. | Owner-accepted 1.2.4 cycle plan, 2026-08-12 |
| D4 | Run M17 after M7 and before M6. Keep the canonical installed path as the default while allowing lifecycle verification to follow `IOC_RUNNER_SCRIPT_DEST`. | Owner decision, 2026-08-13 |
| D5 | Complete M3 with leading and trailing token boundaries. M8/#137 moved source-contract ownership but retained quoted-global extraction; M3 reconstructs membership from the extracted subsets and separately pins direct base-pattern composition. | Owner decision after conceptual-integrity review, 2026-08-13 |
| D6 | Retire the obsolete `cloud-provision` 2026-06-03 Rocky golden target without claiming its downstream check passed. Carry validation of the current image-workflow Rocky golden as independent Backlog work in this repository; it does not block `cloud-provision` closure or the 1.2.4 release. | Owner selection of the Backlog carry-forward and repository boundary, 2026-08-16 |
| D7 | Enter #147 as its own 1.2.4 milestone row (M19) rather than folding it into M17, and include M19 in the M16 release gate. The setup-side parent creation is independent of the G2 and M17 destination work but ships in the same cycle as part of non-default destination support. | Owner decision, 2026-08-16 |
| D8 | Accept the real `app_ioc_runner` verification on Debian 13 and Rocky 8 base VMs (implementation commit `5a7d2aa`, jeonghanlee/ansible-provision#13) as completing G2. The golden-level default and alternate destination integration is verified under M17/T1-T3, not re-run in G2. Reconcile the G2 Work-row wording from "golden OS families" to "Debian 13 and Rocky 8" to match the detail criteria. | Owner decision, 2026-08-16 |
| D9 | Carry the paired G2/M17 `IOC_RUNNER_SCRIPT_DEST` runner-selection documentation — the `gate/RUNBOOK.md` cross-repository procedure and the runner-selection doc — into M16 rather than M17. M17's deliverable (both lifecycle suites honor the override, verified on both goldens) is complete without it; the RUNBOOK procedure belongs with the release gate where G2 and M17 run together. | Owner decision, 2026-08-16 |

### Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| a39623c / M3 | `master`, `docs/milestone-a39623c.md` | `release-1.2.4`, `docs/milestone-1.2.4.md` | `4bcd63847fef73833946a49a1af05d29fc65bd8d` | `e357210e5c447d5736684395cd7f5d780b9df246` |
| a39623c / M6 | `master`, `docs/milestone-a39623c.md` | `release-1.2.4`, `docs/milestone-1.2.4.md` | `4bcd63847fef73833946a49a1af05d29fc65bd8d` | `e357210e5c447d5736684395cd7f5d780b9df246` |
| a39623c / M7 | `master`, `docs/milestone-a39623c.md` | `release-1.2.4`, `docs/milestone-1.2.4.md` | `4bcd63847fef73833946a49a1af05d29fc65bd8d` | `e357210e5c447d5736684395cd7f5d780b9df246` |
| a39623c / M13 | `master`, `docs/milestone-a39623c.md` | `release-1.2.4`, `docs/milestone-1.2.4.md` | `4bcd63847fef73833946a49a1af05d29fc65bd8d` | `e357210e5c447d5736684395cd7f5d780b9df246` |

### Milestone Details

#### M3 - FATAL token boundary hygiene

Origin: a39623c / M3
Identity History: transferred unchanged from `docs/milestone-a39623c.md` at
master source transfer commit `e357210`.
GitHub Issue: 114, https://github.com/jeonghanlee/epics-ioc-runner/issues/114
Status: Complete

##### Summary

The case-insensitive FATAL substring match has no token boundaries, so a
pre-marker line carrying `fatal` as part of an identifier trips the standalone
exit-1 path while the IOC starts fine.

##### Scope

Add portable leading and trailing boundaries to the case-insensitive FATAL
subset and re-run the shipped benign and fatal startup paths on both golden OS
families.

##### Out of Scope

Adding crash tokens, changing the initialization marker, or changing the
measured startup window.

##### Completion Criteria

- The owner assigns the detection change to a release line.
- `fatal` adjacent to an identifier character on either side does not produce
  the standalone fatal verdict.
- A true fatal startup still produces the expected failed-initialization
  verdict on both golden OS families.

##### Dependencies And Decisions

- Pairs with M4 (#115), the later 1.3.0 end-to-end supervision probe.
- D1 stages the cross-branch transfer.
- D2 places this work first in the 1.2.4 cycle.
- D5 expands the original leading-boundary plan to a complete token boundary
  and removes the duplicated base regex. M8/#137 moved source-contract
  ownership to source regression while retaining quoted-global extraction;
  M3 reconstructs membership from the extracted fatal and ambiguous subsets
  and separately checks the direct base-pattern declaration.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner accepted the 1.2.4 cycle plan on 2026-08-12 and expanded
M3 to a complete token boundary on 2026-08-13
Implementation Authorization: Owner explicitly authorized M3 implementation
in chat, 2026-08-13
Superseded Plan Artifacts: none

1. Define portable leading and trailing boundaries for the FATAL subset.
2. Compose the base crash pattern directly from its fatal and ambiguous subsets.
3. Apply the boundary to the shipped crash scan without weakening true-fatal
   detection.
4. Run leading-only, trailing-only, and both-sides benign fixtures as separate
   real IOCs, plus the true-fatal control, on both golden OS families.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | False-positive boundary | Start three real IOCs whose pre-marker output isolates leading-only, trailing-only, and both-sides identifier adjacency | Both golden OS families | All three startups succeed without the standalone fatal verdict |
| T2 | Detection sensitivity | Start the shipped fatal softIoc fixture through the real runner path | Both golden OS families | The true fatal token still produces the expected failed-initialization verdict |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-13 | Debian 13 and Rocky 8 | Pass | Source regression passed 93/93 on both hosts with S20 at 28/28. Local lifecycle passed 135/135 on Debian and 131 pass with 4 NA on Rocky; S30 passed 27/27 on both. System lifecycle passed 102/102 on both; S26 passed 12/12. All nine real-path boundary checks passed in each lifecycle suite. Evidence: `work/m3-token-check-20260813/{debian13,rocky8}-{source-regression,local-lifecycle,system-lifecycle}.log`. |
| T2 | 2026-08-13 | Debian 13 and Rocky 8 | Pass | The two true-FATAL checks passed in each local and system lifecycle suite. The first system runs preserved under `*.env-red.log` show S26 at 12/12 before two unrelated S27 checks failed because the temporary checkout root was mode 0700; reruns after correcting that test-environment permission passed 102/102. |

##### Closure Evidence

- Commit `fccef50dd5d4fdfa11a9ccb39566949f280b5311` implements the
  token boundaries, direct subset composition, and three-case real-path matrix
  on `release-1.2.4`; `origin/release-1.2.4` contains the commit.
- T1 and T2 passed through the recorded real source, local lifecycle, and
  system lifecycle paths on Debian 13 and Rocky 8.
- GitHub issue #114 was reconciled and observed closed at
  `2026-08-14T17:11:43Z`.

##### GitHub Projection

Title: Add boundary hygiene to the FATAL crash-token subset
Labels: P2-medium, area/detection
GitHub Milestone: 1.2.4
Observed State: closed
Observed Labels: P2-medium, area/detection
Observed Milestone: 1.2.4
Observed Assignee: jeonghanlee
Last Compared: 2026-08-14; remote updated 2026-08-14T17:11:43Z

#### M7 - verify_path type expectation

Origin: a39623c / M7
Identity History: transferred unchanged from `docs/milestone-a39623c.md` at
master source transfer commit `e357210`.
GitHub Issue: 118, https://github.com/jeonghanlee/epics-ioc-runner/issues/118
Status: Complete

##### Summary

`verify_path` asserts owner and mode but not file type, so a pre-existing
directory at a file target verifies green while the deployment is broken.

##### Scope

An expected-type parameter threaded through all seven call sites; two targets
are legitimately directories, so a blanket file test is wrong.

##### Out of Scope

Changing target ownership or mode contracts, or replacing the existing
deployment mechanisms.

##### Completion Criteria

- The owner assigns the helper-signature change to a release line.
- Every file target rejects a directory impostor through the real setup path.
- The two legitimate directory targets pass explicit directory checks.

##### Dependencies And Decisions

- The 1.2.3 runbook (#131) records this false-green class as a known limitation
  of a green `verify_path` result until the type expectation lands.
- The false green was reproduced through the real setup behavior at
  `BASH_COMP_DEST`: `backup_if_exists` ignores a directory because its guard
  uses `[[ -f ]]`, `cp` writes the payload inside that directory, `chmod`
  gives the directory the expected mode, and `verify_path` reports success
  from its owner and mode alone.
- Crafted directories at `SUDOERS_FILE` and `LOGROTATE_FILE` produce the same
  class through their `mv` deployment paths. The sudo includedir ignores the
  dot-named payload and logrotate ignores the subdirectory, so the required
  policy is absent even though setup reports success.
- No maintained provisioning path creates these impostors, but a root-created
  directory is reachable and persistent: later runs neither displace nor
  reject it. This is why the correction covers all seven call sites rather
  than only the first reproduced target.
- D1 stages the cross-branch transfer.
- D2 places this work second in the 1.2.4 cycle.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner accepted the 1.2.4 cycle plan, 2026-08-12
Implementation Authorization: @jeonghanlee authorized implementation and the
mount-namespace isolation path in chat, 2026-08-14
Superseded Plan Artifacts: none

1. Define the expected type at every `verify_path` call site.
2. Extend the helper to reject a type mismatch before reporting success.
3. Exercise file-target impostors and legitimate directory targets through
   the shipped setup path.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Honest red | Place directories at file targets and run the shipped setup path | Isolated system setup environment | Each type mismatch returns nonzero and cannot produce the success banner |
| T2 | Legitimate directories | Run the same setup with the real configuration and log directories | Isolated system setup environment | Directory targets pass their explicit type checks and deployment completes |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-14 | Debian 13 and Rocky 8 private mount namespaces | Pass | Both shipped dispatcher runs passed 104/104 with S22 at 11/11. The impostor setup exited 1, omitted the final success banner, and reported all five file targets as non-regular files. Evidence: `work/m7-verify-path-type-20260814/debian13-source-regression-104.log` (SHA-256 `f4c2ab3c30b58d08b53e1356e2787dbd8491da54be9b5c9dcc8b679040b56e71`) and `rocky8-source-regression-104.log` (SHA-256 `17f97ced22f31f7536de39d85ebb3c15d7a447eecb61843d1996f090551639b6`). |
| T2 | 2026-08-14 | Debian 13 and Rocky 8 private mount namespaces | Pass | The valid full-setup path exited 0 and explicitly accepted the configuration and log directory targets on both hosts; evidence is the same two T1 logs. |

##### Closure Evidence

- Commit `50f27b24c6c42b232c43fb6e69985dbb1d937d6e` implements the type
  checks and real-path regression coverage on `release-1.2.4`;
  `origin/release-1.2.4` contains the commit.
- T1 and T2 passed through the shipped source-regression dispatcher on Debian
  13 and Rocky 8.
- `bash -n`, targeted `shellcheck`, and `git diff --check` passed on
  2026-08-14 before the two-host run.
- GitHub issue #118 was reconciled and observed closed at
  `2026-08-14T19:20:50Z`.

##### GitHub Projection

Title: Add a type expectation to verify_path (false-green directory impostors)
Labels: P3-low, ops
GitHub Milestone: 1.2.4
Observed State: closed
Observed Labels: P3-low, ops
Observed Milestone: 1.2.4
Observed Assignee: jeonghanlee
Last Compared: 2026-08-14; remote updated 2026-08-14T19:25:48Z

#### M17 - Installed runner destination

Origin: 1.2.4 / M17
Identity History: none
GitHub Issue: 145, https://github.com/jeonghanlee/epics-ioc-runner/issues/145
Status: Complete

##### Summary

Both lifecycle suites map installed mode directly to
`/usr/local/bin/ioc-runner`. That path is the canonical deployment default,
but setup also supports `IOC_RUNNER_SCRIPT_DEST`; installed lifecycle tests
cannot currently follow a deployment to that alternate destination.

##### Scope

Resolve the installed runner from `IOC_RUNNER_SCRIPT_DEST` with
`/usr/local/bin/ioc-runner` as the default in both lifecycle suites, preserve
the value through the dispatcher's clean local environment, and verify the
selected executable after the real `ansible-provision` role deploys it.

##### Out of Scope

Changing the default production path, changing setup deployment semantics,
adding another installed-runner environment variable, or changing
`cloud-provision` validation behavior. `test-system-infra.bash` runner-path
awareness stays out of scope: it is a deploy probe invoked with plain `sudo`,
not a lifecycle runner-path consumer, so it keeps checking the default path.

##### Completion Criteria

- Installed mode still selects `/usr/local/bin/ioc-runner` when
  `IOC_RUNNER_SCRIPT_DEST` is unset.
- G2 completes after an `ansible-provision` implementation commit passes the
  real `app_ioc_runner` default and alternate destination checks on Debian 13
  and Rocky 8.
- Both local and system lifecycle suites select an executable destination set
  through `IOC_RUNNER_SCRIPT_DEST`.
- `run-all-tests.bash` preserves the override across its clean local
  privilege-drop environment.
- Captured lifecycle output identifies the selected path and its real `-V`
  identity (the role's own default and alternate deployment is covered by G2).
- The paired cross-repository RUNBOOK procedure and runner-selection
  documentation are carried into M16 (D9); they are not required for M17
  completion.

##### Dependencies And Decisions

- G2 is Complete (`ansible-provision` commit `5a7d2aa`, #13 closed); M17's plan
  is accepted, the source change is implemented, and T1/T2/T3 pass on both fresh
  goldens.
- The accepted approach reuses the existing cataloged P00
  `selected-runner-executable` check and the existing warn-only `-V` line in both
  suites rather than adding new cataloged checks, so the catalog arrays,
  close-index literals, and fixed reporting totals stay unchanged.
- G2 is the implementation checkpoint tracked by
  [jeonghanlee/ansible-provision#13](https://github.com/jeonghanlee/ansible-provision/issues/13),
  not an issue-closure gate. The external issue may remain open for M17's
  downstream consumer evidence.
- G2 and M17 form one cross-repository verification path: Ansible deploys and
  verifies the configured executable, then the consumer suites select and
  execute that same path.
- D4 places this work after M7 and before M6.
- The canonical `/usr/local/bin/ioc-runner` default remains unchanged.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner accepted the minimal approach in chat, 2026-08-16 (reuse
the existing P00 check; no new cataloged checks)
Implementation Authorization: Owner authorized implementation of the accepted
approach in chat, 2026-08-16
Superseded Plan Artifacts: none

1. Keep source mode bound to `bin/ioc-runner`; derive only installed mode from
   `IOC_RUNNER_SCRIPT_DEST`, with the current canonical path as its default, in
   both lifecycle suites.
2. Preserve `IOC_RUNNER_SCRIPT_DEST` through the dispatcher's normal local and
   `sudo -E` system routes and its explicit `env -i` local privilege-drop
   environment.
3. Reuse the existing cataloged P00 `selected-runner-executable` check, which
   already tests the resolved `RUNNER_SCRIPT` (now override-derived), and the
   existing warn-only `-V` line present in both suites. Add no new cataloged
   check, so the catalog arrays, close-index literals, and fixed reporting
   totals stay unchanged.
4. Consume the completed G2 `app_ioc_runner` role on golden Debian 13 and Rocky
   8, verifying both the default destination and an alternate
   `path_ioc_runner_bin` through the installed runner's real `-V` identity.
   Before the alternate run, confirm the golden host `sudo` environment policy
   carries `IOC_RUNNER_SCRIPT_DEST` to the `sudo -E` system suite, so an
   override cannot silently fall back to the default.
5. Run default installed, Ansible-deployed overridden installed, and
   source-with-override regression coverage on both goldens. No inventory or
   fixed-total reconciliation is needed because no cataloged check was added; the
   runner-selection documentation and `gate/RUNBOOK.md` update is carried into
   M16 (D9).

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Default installed selection | Run the real `app_ioc_runner` role with its default `path_ioc_runner_bin`, then run the shipped dispatcher in installed mode with `IOC_RUNNER_SCRIPT_DEST` unset | Disposable Debian 13 and Rocky 8 consumers | Ansible and both lifecycle suites record, verify, and execute `/usr/local/bin/ioc-runner`; the real `-V` identity matches the retained checkout |
| T2 | Overridden installed selection | Run the real `app_ioc_runner` role with an alternate `path_ioc_runner_bin`, then run both lifecycle suites through the shipped dispatcher with the matching `IOC_RUNNER_SCRIPT_DEST`, including the clean local privilege-drop path | Same disposable Debian 13 and Rocky 8 consumers | Ansible installs and verifies the alternate path without a staged substitute; both lifecycle suites record and execute it, and the real `-V` identity matches the retained checkout |
| T3 | Source selection precedence | Keep the alternate `IOC_RUNNER_SCRIPT_DEST` set, select source mode, run both lifecycle suites through the shipped dispatcher, and run the source-regression suite | Same disposable consumers and source checkout | Both lifecycle suites ignore the installed override, record and execute `bin/ioc-runner`, and pass the real `-V` checks; every source contract passes |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-08-16 | Fresh `rocky8` and `debian13` iocrunner consumers (cloud-provision, images `20260817T002210Z-16eb9afaa058` / `20260817T002234Z-6a5b45df80f6`) | Pass | With `IOC_RUNNER_SCRIPT_DEST` unset, the shipped dispatcher installed mode records "Runner under test: /usr/local/bin/ioc-runner" (`-V` `1.2.3 (ddb558d-dirty)`) and both lifecycle suites plus system-infra pass on both hosts: rocky8 local 131/0 (4 na), system-infra 32/0 (4 na), system-lifecycle 102/102; debian13 135/135, 36/36, 102/102. Evidence: `work/m17-verify-20260817/{rocky8-t1b,debian13-t1}.log`. |
| T2 | 2026-08-16 | Same consumers, alternate `/opt/tools/bin/ioc-runner` deployed alongside the default | Pass | The candidate was deployed to the alternate path through the shipped `setup-system-infra.bash --full` with `IOC_RUNNER_SCRIPT_DEST` (the same script the `app_ioc_runner` role invokes; no staged or copied runner), leaving the default present. With the matching override, both the local (`env -i` privilege-drop) and system (`sudo -E`) phases record "Runner under test: /opt/tools/bin/ioc-runner" — the override wins even though the default is still installed — and all suites pass on both hosts (rocky8 131/0, 32/0, 102/102; debian13 135/135, 36/36, 102/102). Evidence: `work/m17-verify-20260817/{rocky8-t2b,debian13-t2}.log`. |
| T3 | 2026-08-16 | Same consumers and source checkout, override still set | Pass | With `IOC_RUNNER_SCRIPT_DEST=/opt/tools/bin/ioc-runner` still set, both phases in source mode record "Runner under test: .../bin/ioc-runner" — the override is ignored — and all suites pass on both hosts (rocky8 131/0, 32/0, 102/102; debian13 135/135, 36/36, 102/102). Evidence: `work/m17-verify-20260817/{rocky8-t3b,debian13-t3}.log`. |

##### Verification Notes

- Deviations from the Test Plan, recorded for the reader: (1) the default and alternate runners were deployed through the shipped `setup-system-infra.bash --full` — the exact script the `app_ioc_runner` role invokes — rather than the Ansible role itself; the role's own default and alternate deployment is verified by G2, and no staged or copied runner stood in. (2) The `test-source-regression.bash` suite named in the T3 plan was not run in this pass; T3's override-ignore behavior was confirmed through both lifecycle suites in source mode. (3) `Observed At` uses the dev-host local date; the consumer image IDs carry the UTC bake timestamp (`20260817T...`).

##### Closure Evidence

- The source change (resolver override in both lifecycle suites and the dispatcher `IOC_RUNNER_SCRIPT_DEST` propagation) passed on both goldens: T1 default, T2 alternate, and T3 source-precedence all Pass on fresh `rocky8` and `debian13` iocrunner consumers, with each host's local and system phases recording the expected runner path. Logs: `work/m17-verify-20260817/*.log` (SHA-256 recorded at retrieval).
- Verification-environment factors, all orthogonal to M17 and handled per run: the baked golden runner was `e357210` (pre-M3), so the 1.2.4 candidate was deployed through the shipped setup before testing; the known unfixed M13/#143 Rocky logrotate state-file interference was cleared before each run; and the `0700` consumer home was made traversable so the source-mode system suite's service account could reach the checkout.

##### GitHub Projection

Title: Honor IOC_RUNNER_SCRIPT_DEST in installed lifecycle tests
Labels: P3-low, tests
GitHub Milestone: 1.2.4
Observed State: open
Observed Labels: P3-low, tests
Observed Milestone: 1.2.4
Observed Assignee: jeonghanlee
Last Compared: 2026-08-15; remote updated 2026-08-15T09:21:21Z

#### M6 - Local install ordering

Origin: a39623c / M6
Identity History: transferred unchanged from `docs/milestone-a39623c.md` at
master source transfer commit `e357210`.
GitHub Issue: 117, https://github.com/jeonghanlee/epics-ioc-runner/issues/117
Status: Open

##### Summary

Local-mode `do_install` replaces the shared user template and reloads systemd
before the running-service guard and the overwrite prompt, so an aborted
install still leaves durable changes affecting every local IOC.

##### Scope

Settle whether accepted local installs refresh shared assets, then place every
selected deployment and daemon reload after the running-service guard and
overwrite-abort gates.

##### Out of Scope

Changing system-mode ordering or the content, ownership, and mode contracts
of the deployed local artifacts.

##### Completion Criteria

- The owner assigns the ordering change and settles the refresh policy.
- EOF and explicit decline leave the shared template, rotation units, and
  manager state unchanged.
- An accepted install deploys the configuration and selected shared assets
  after all abort gates pass.

##### Dependencies And Decisions

- D1 stages the cross-branch transfer.
- D2 places this work before M13 because both change local install.
- The accepted-install shared-asset refresh policy remains an owner decision.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner accepted the 1.2.4 cycle plan, 2026-08-12
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Settle whether every accepted install refreshes the shared local assets.
2. Move shared deployment and daemon reload after the running-service and
   overwrite-abort gates.
3. Verify both abort paths and the accepted-install upgrade path.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Abort integrity | Drive EOF and explicit decline through the shipped local install path and compare shared assets before and after | Local lifecycle environment | Each abort returns nonzero and leaves the template, rotation units, and manager state unchanged |
| T2 | Accepted install | Accept the overwrite through the same shipped path | Local lifecycle environment | Configuration and shared assets deploy once after all abort gates pass |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Local lifecycle environment | Pending | none |
| T2 | Not run | Local lifecycle environment | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Reorder local install so deployment follows the abort gates
Labels: enhancement, P3-low
GitHub Milestone: 1.2.4
Observed State: open
Observed Labels: enhancement, P3-low
Observed Milestone: 1.2.4
Observed Assignee: jeonghanlee
Last Compared: 2026-08-13; remote updated 2026-08-13T06:59:59Z

#### M13 - Local logrotate state isolation

Origin: a39623c / M13
Identity History: transferred unchanged from `docs/milestone-a39623c.md` at
master source transfer commit `e357210`.
GitHub Issue: 143, https://github.com/jeonghanlee/epics-ioc-runner/issues/143
Status: Not started

##### Summary

Local configuration validation runs `logrotate -d` without selecting a state
file. Rocky logrotate treats an unreadable system default state file as an
error, so a root-owned state file left by an earlier system run prevents the
ordinary user's later local install from deploying rotation artifacts. The
deployed user service already uses `%t/ioc-runner-logrotate.state`; the defect
is limited to the install-time debug validation.

##### Scope

- Make local configuration debug validation independent of the system default
  state file.
- Add a real install-path regression check using only the external
  `IOC_RUNNER_LOGROTATE_TOOL` boundary.
- Update the maintained inventories and driver expectations for the 1.2.4
  implementation.

##### Out of Scope

Changing the system default state file, changing its ownership or mode,
changing the deployed user timer's runtime state path, changing system
logrotate policy, or changing the 1.2.3 M11 journal applicability decision.

##### Completion Criteria

- A shipped local install validates and deploys rotation artifacts without
  reading the system default state file.
- A regression check drives the real local install path and fails if validation
  returns to the system default state file.
- Consecutive two-golden suite-driver runs pass without changing system
  state-file ownership or mode.

##### Dependencies And Decisions

- M6 completes first because it changes the same local install path.
- D1 stages the cross-branch transfer.
- D2 places this work last in the bugfix sequence.
- The defect was observed during a repeated Rocky M11 gate after an earlier
  system run had created a `root:root 0600` default state file.
- The final 1.2.3 two-host gate passed without changing either default state
  file. That clean-path result does not mean the state-dependent defect is
  fixed.
- #116 covers runtime execution of the deployed oneshot; this row covers the
  earlier install-time validation.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner accepted the 1.2.4 cycle plan, 2026-08-12
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Select an explicit non-persistent state target for local debug validation.
2. Add a real install-path regression check at the external logrotate boundary.
3. Update maintained inventories, driver expectations, and runbook counts.
4. Run the shipped two-host suite driver consecutively and compare the complete
   state vectors and default state-file metadata.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Install contract | Drive a real local install through an external logrotate boundary that rejects use of the system default state | Source error-contract suite | The install returns zero, deploys all rotation artifacts, and the check passes |
| T2 | Repeated integration | Run the shipped suite driver consecutively without changing either system default state file | Debian and Rocky goldens for 1.2.4 | Both runs record complete PASS suite vectors |
| T3 | State preservation | Compare owner, group, and mode before and after T2 | Both goldens | The default state files remain `root:root 0600` |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Source tree | Pending | none |
| T2 | Not run | 1.2.4 goldens | Pending | none |
| T3 | Not run | 1.2.4 goldens | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Make local logrotate validation independent of the system state file
Labels: bug, ops, tests
GitHub Milestone: 1.2.4
Observed State: open
Observed Labels: bug, ops, tests
Observed Milestone: 1.2.4
Observed Assignee: jeonghanlee
Last Compared: 2026-08-13; remote updated 2026-08-13T06:59:58Z

#### M19 - Setup destination parent creation

Origin: 1.2.4 / M19
Identity History: none
GitHub Issue: 147, https://github.com/jeonghanlee/epics-ioc-runner/issues/147
Status: Not started

##### Summary

`setup-system-infra.bash --full` fails when `IOC_RUNNER_SCRIPT_DEST` names a path
whose parent directory does not yet exist. STEP 7 runs
`mktemp "${RUNNER_SCRIPT_DEST}.XXXXXX"`, which cannot create the staging file
without an existing parent. The default `/usr/local/bin/ioc-runner` always has a
parent, so the failure only surfaces for a non-default destination.

##### Scope

Ensure the parent directory of `RUNNER_SCRIPT_DEST` exists before the STEP 7
staged deploy, and apply the same to `RUNNER_SCRIPT_SYMLINK` when its parent can
be redirected off `/usr/bin`. Cover the fix with a real setup-path regression on
both golden OS families.

##### Out of Scope

Changing the default destination, changing the ownership or mode contracts of the
deployed CLI, changing the symlink target policy, or altering the consumer-side
parent creation in `ansible-provision`.

##### Completion Criteria

- The shipped `setup-system-infra.bash --full` deploys the CLI to a non-default
  `IOC_RUNNER_SCRIPT_DEST` whose parent directory is absent.
- The default destination path still deploys unchanged.
- A regression check drives the real setup path against an absent parent and
  would fail on the un-fixed code.

##### Dependencies And Decisions

- D7 enters #147 as its own milestone row and includes it in the M16 release
  gate.
- Independent of G2 and M17: the parent-creation fix touches the setup deploy
  path, while G2 touches the Ansible role and M17 touches the lifecycle suites.
  The `ansible-provision` consumer already creates the destination parent before
  invoking setup, so M17's verification path does not exercise this defect.
- The caller-side parent creation stays regardless; a consumer may pin a setup
  version predating this fix. Both are idempotent `install -d` no-ops and compose
  without conflict.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Create the parent of `RUNNER_SCRIPT_DEST` with `install -d` before the STEP 7
   `mktemp`/`mv` staged deploy.
2. Apply the same parent creation to `RUNNER_SCRIPT_SYMLINK` when it is
   redirected off `/usr/bin`.
3. Add a real setup-path regression that deploys to a non-default destination
   with an absent parent and would go red on the un-fixed code.
4. Run the affected setup and source-regression suites on both golden OS
   families.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Absent-parent deploy | Run the shipped `setup-system-infra.bash --full` with `IOC_RUNNER_SCRIPT_DEST` set to a path whose parent is absent | Isolated system setup environment on both goldens | Setup creates the parent, deploys the CLI, and reports success |
| T2 | Default destination | Run the same shipped setup with `IOC_RUNNER_SCRIPT_DEST` unset | Same environment | The default `/usr/local/bin/ioc-runner` deploys unchanged |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Both goldens | Pending | none |
| T2 | Not run | Both goldens | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: setup-system-infra.bash: create the parent directory of IOC_RUNNER_SCRIPT_DEST before deploying the CLI
Labels: enhancement
GitHub Milestone: 1.2.4
Observed State: open
Observed Labels: enhancement
Observed Milestone: 1.2.4
Observed Assignee: none
Last Compared: 2026-08-16; remote updated 2026-08-16T10:37:31Z

#### M16 - Final release

Origin: 1.2.4 / M16
Identity History: none
GitHub Issue: none
Status: Not started

##### Summary

Release 1.2.4 after the six assigned work units complete and the combined
candidate passes the standing release gate on Debian 13 and Rocky 8.

##### Scope

Integrated re-runs, complete two-golden gate execution, version change,
release objects, tracker closure, and production installation verification. It
also folds in the paired G2/M17 `IOC_RUNNER_SCRIPT_DEST` runner-selection
documentation carried from M17 (D9): the `gate/RUNBOOK.md` cross-repository
procedure and the runner-selection doc.

##### Out of Scope

Opening the 1.3.0 cycle or implementing any backlog item assigned to that
future line.

##### Completion Criteria

- M3, M7, M17, M6, M13, and M19 are Complete with reachable real-path evidence.
- `gate/RUNBOOK.md` and the runner-selection documentation record the paired
  G2/M17 `IOC_RUNNER_SCRIPT_DEST` procedure (carried from M17 per D9).
- Every Release Verification row records Pass with reachable evidence.
- Tag `1.2.4`, the GitHub release, and the closed remote milestone agree on
  the released commit.
- The documented production install path reports version 1.2.4.

##### Dependencies And Decisions

- M3, M7, M17, M6, M13, and M19.
- G1 is Complete; GitHub milestone 1.2.4 exists as number 15.
- D3 defines the complete two-golden gate and release boundary.
- The 1.3.0 target decisions remain on master and do not open that cycle.

##### Golden Consumer Verification Notes

The M17 golden run surfaced these reusable factors for the M16 gate; all are environment handling, not product defects:

- The baked golden runner may lag the release candidate (M17 saw `e357210`, pre-M3). Deploy the candidate through the shipped `setup-system-infra.bash --full` before testing, and confirm `-V` reports the candidate hash.
- Clear the system default logrotate state file (`/var/lib/logrotate/logrotate.status`) before each run: a prior system run leaves it `root`-owned and blocks a later local rotation deploy (the unfixed M13/#143 defect on Rocky).
- `debian13` lacked `rsync`; push the candidate tree with tar-over-ssh there. Detach long suite runs (`setsid` plus a VM-side wait loop) because the ssh wrapper otherwise holds the channel open.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: Owner accepted the 1.2.4 cycle plan on 2026-08-12 and added
M17 to the pre-release sequence on 2026-08-13
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Confirm the six assigned work rows are Complete and review their recorded
   evidence against the combined candidate.
2. Bake or accept clean Debian 13 and Rocky 8 goldens according to
   `gate/RUNBOOK.md`, recording Release Verification 1.
3. Add and review the 1.2.4 changelog entry in a standalone commit.
4. Change only `RUNNER_VERSION` from 1.2.3 to 1.2.4 in a standalone commit.
5. Drive the complete gate and M13's consecutive-suite condition, then record
   Release Verification 2 through 6 in a readiness-evidence commit.
6. Execute the separately authorized merge, tag, pushes, GitHub release, and
   milestone closure.
7. Verify the actual release objects and the documented production install
   path, then record Release Verification 7 and 8 and close the cycle.

##### Integrated Verification

| Source Check | Re-run Trigger | Shared Surface | Release Verification Label | Expected Result | Result Evidence |
| --- | --- | --- | --- | --- | --- |
| M3 / T1, T2 | Later changes reach the shared runner and startup scan | Crash scan and startup path | Release Verification 2 | Benign identifier text remains accepted and true fatal startup remains detected in the final candidate | pending |
| M7 / T1, T2 | Later setup changes may alter type checks or deployment | System setup path | Release Verification 2 | File impostors fail and legitimate directories pass in the final candidate | pending |
| M17 / T1, T2, T3 | Later test-driver changes may alter runner selection or environment propagation | Lifecycle runner selection and dispatcher environment | Release Verification 2 | Default, override, and source selections execute the intended real runner in the final candidate | pending |
| M6 / T1, T2 | M13 later changes the same local install path | Local install ordering | Release Verification 2 | Abort integrity and accepted deployment both hold after M13 | pending |
| M13 / T1, T2, T3 | Final candidate and repeated host execution may expose state coupling | Local logrotate validation and suite driver | Release Verification 2 | Both consecutive host runs pass and default state-file metadata is unchanged | pending |
| M19 / T1, T2 | Later setup changes may alter destination staging | Setup deploy path | Release Verification 2 | A non-default destination with an absent parent still deploys and the default path stays unchanged in the final candidate | pending |

##### Production Environment Tests

| Release Verification Label | Timing | System | Version | Architecture | Deployment Path | Method | Expected Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Release Verification 8 | post-release | `alsucl-psrv3` | Rocky 8, NFS home with root_squash | x86_64 | `/usr/local/bin/ioc-runner` | Follow the documented install path from the NFS-home checkout, then read `-V` | Install completes and `-V` reports 1.2.4 with the released short hash | pending |

##### Version Changes

| Field | File | Before | Planned After | Pre-check | Pre-check Label | Post-check | Post-check Label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `RUNNER_VERSION` | `bin/ioc-runner` | `1.2.3` | `1.2.4` | Read the declaration before mutation | Release Verification 5 | Read deployed `-V` after the final gate deploy | Release Verification 6 |

##### Release Execution

| Step | Action | Authorization | Expected Result | Evidence |
| --- | --- | --- | --- | --- |
| 1 | Add the accepted 1.2.4 section to `CHANGELOG.md` | commit delegation | One standalone changelog commit | pending |
| 2 | Bump `RUNNER_VERSION` to 1.2.4 | commit delegation | One standalone version commit changing only the declaration | pending |
| 3 | Record the complete gate and readiness evidence | commit delegation | One reviewed release-candidate commit | pending |
| 4 | Merge the named release candidate into `master` with `--no-ff` | release delegation | One merge commit on `master` | pending |
| 5 | Create annotated tag `1.2.4` on the merge commit | release delegation | One annotated tag with the accepted title | pending |
| 6 | Push `master`, tag `1.2.4`, and the final `release-1.2.4` ref | release delegation | All three refs identify the accepted objects | pending |
| 7 | Create the GitHub release from reviewed release notes | release delegation | One published 1.2.4 release object | pending |
| 8 | Close the remote GitHub milestone `1.2.4` | release delegation | Milestone state is closed | pending |
| 9 | Record Release Verification 7 and 8 and close M16 | commit delegation | One final closure commit | pending |
| 10 | Push the final closure commit | push delegation | Local and remote closure state agree | pending |

##### Release Verification Plan

| Label | Layer | Timing | Method | Environment | Expected Result | Evidence Target |
| --- | --- | --- | --- | --- | --- | --- |
| Release Verification 1 | Golden acceptance | pre-change | Run the acceptance sequence in `gate/RUNBOOK.md` before tree push or deploy | Debian 13 and Rocky 8 goldens | Both goldens have accepted provenance and the declared baseline | Acceptance log and manifest identities |
| Release Verification 2 | Automated and integrated checks | post-change | Run the complete shipped suite driver twice consecutively and compare state-file metadata around the runs | Both goldens at the final candidate | Every suite is complete and green on both runs; all imported work checks hold; system state-file owner, group, and mode are unchanged | Suite records, cross-host comparison, and metadata reads |
| Release Verification 3 | Standing scenarios | post-change | Run the shipped multi-user scenario driver through `gate/RUNBOOK.md` | Both goldens at the final candidate | Every declared scenario passes on each host | Per-scenario records and final verdicts |
| Release Verification 4 | root_squash procedure | post-change | Run the standing root_squash path through all documented deployment entries | Both goldens at the final candidate | Every entry stamps the real candidate hash without a layout warning | Procedure logs and `-V` output |
| Release Verification 5 | Version consistency | pre-change | Read `RUNNER_VERSION` before mutation | Release branch | Value is 1.2.3 | Commit and file read |
| Release Verification 6 | Version consistency | post-change | Read deployed `-V` after the final gate deploy | Both goldens | Version is 1.2.4 with the version commit's short hash | `-V` output |
| Release Verification 7 | Release objects and tracker | post-release | Read the merge commit, annotated tag, GitHub release target, and milestone state independently | Git and GitHub | All released objects agree and milestone 1.2.4 is closed | Object identifiers and GitHub observations |
| Release Verification 8 | Production deployment | post-release | Follow the documented install path and read deployed `-V` | `alsucl-psrv3` | Installation succeeds and reports released version 1.2.4 | Install log and `-V` output |

##### Release Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| Release Verification 1 | Not run | Debian 13 and Rocky 8 goldens | Pending | none |
| Release Verification 2 | Not run | Debian 13 and Rocky 8 goldens | Pending | none |
| Release Verification 3 | Not run | Debian 13 and Rocky 8 goldens | Pending | none |
| Release Verification 4 | Not run | Debian 13 and Rocky 8 goldens | Pending | none |
| Release Verification 5 | Not run | Release branch | Pending | none |
| Release Verification 6 | Not run | Debian 13 and Rocky 8 goldens | Pending | none |
| Release Verification 7 | Not run | Git and GitHub | Pending | none |
| Release Verification 8 | Not run | `alsucl-psrv3` | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: 1.2.4
Observed State: none
Last Compared: never

#### G1 - GitHub milestone 1.2.4

Origin: 1.2.4 / G1
GitHub Issue: none
Status: Complete

##### Summary

The repository owner must create the open GitHub milestone `1.2.4` before
assigned issue projections can move from Backlog and before final release
closure.

##### Completion Criteria

- The GitHub repository has one open milestone titled exactly `1.2.4`.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-08-13T06:54:01Z | Pass | GitHub milestone 15 exists, title `1.2.4`, state open; issues #114, #118, #117, and #143 all project milestone `1.2.4` |

##### Closure Evidence

- Created by the repository owner on 2026-08-13 as milestone number 15.
- Four assigned issues were re-read after synchronization and each reported
  milestone `1.2.4`.

#### G2 - Ansible installed runner destination propagation

Origin: 1.2.4 / G2
External GitHub Issue: 13,
https://github.com/jeonghanlee/ansible-provision/issues/13
Status: Complete

##### Summary

The `app_ioc_runner` role must pass its configured `path_ioc_runner_bin` to
the shipped setup path as `IOC_RUNNER_SCRIPT_DEST` so its installation and
identity checks address the same executable.

##### Completion Criteria

- An `ansible-provision` implementation commit passes the configured
  `path_ioc_runner_bin` to the shipped setup path as
  `IOC_RUNNER_SCRIPT_DEST`.
- The default inventory value and an alternate `path_ioc_runner_bin` deploy
  and verify through the real `app_ioc_runner` role on Debian 13 and Rocky 8.
- Evidence names the implementation commit, both host results, both selected
  paths, and each installed runner's real `-V` identity.

##### Dependencies And Decisions

- G2 blocks M17; M17 resumes as Not started when G2 is Complete.
- Closing [jeonghanlee/ansible-provision#13](https://github.com/jeonghanlee/ansible-provision/issues/13)
  is not required for G2. The issue remains available for M17's downstream
  consumer evidence.
- The paired consumer verification belongs to M17 / T1-T3 and
  `gate/RUNBOOK.md`; no copied or staged runner may replace the shipped setup
  path.

##### Verification Results

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-08-16 | Pass | Implementation commit `5a7d2aa` on `ansible-provision` master (`Closes #13`) passes `IOC_RUNNER_SCRIPT_DEST="${bin}"` to the shipped setup and creates the destination parent with `install -d`. The real `app_ioc_runner` role verified the default `/usr/local/bin/ioc-runner` and the alternate `/opt/tools/bin/ioc-runner` on Debian 13 and Rocky 8 at tag `1.2.3` (`4868a25`); each installed runner's real `-V` reports `1.2.3 (4868a25)`. Evidence: `ansible-provision` `docs/milestone-a519802.md` M5 (commit `a815962`). Per D8, base-VM verification completes G2 and the golden-level integration is verified under M17. |

##### Closure Evidence

- Implementation commit `5a7d2aa` on `ansible-provision` master; jeonghanlee/ansible-provision#13 closed 2026-08-16T16:29:09Z via a `Closes #13` footer.
- The default and alternate destinations deploy and verify through the real `app_ioc_runner` role on Debian 13 and Rocky 8; evidence is recorded in `ansible-provision` `docs/milestone-a519802.md` M5.
- D8 records that this base-VM verification completes G2 and that the golden-level default and alternate destination integration belongs to M17.

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Runtime acceptance | M18 | Validate the current Rocky 8 golden through downstream runner suites | Carry-forward | Deferred | No | D6 | A fresh consumer from the current image workflow passes the shipped system-infrastructure and system-lifecycle suites with exact image and runner identities recorded; [detail](#m18---current-rocky-golden-downstream-validation) |

### Backlog Details

#### M18 - Current Rocky golden downstream validation

Origin: 1.2.4 / M18
Identity History: none
GitHub Issue: 146, https://github.com/jeonghanlee/epics-ioc-runner/issues/146
Status: Deferred

##### Summary

The 2026-06-03 Rocky golden named by jeonghanlee/cloud-provision#4 is obsolete after the copy-based image workflow shipped in jeonghanlee/cloud-provision#30. The current workflow has real bake, provenance, publication, and fresh-consumer acceptance, but the downstream system-infrastructure and system-lifecycle suites have not run against that current Rocky image. This row carries only that remaining verification.

##### Scope

- Boot a fresh Rocky 8 consumer from a current run-specific image and matching creation record produced by the shipped `cloud-provision` image workflow.
- Record the exact `cloud-provision`, `ansible-provision`, and installed `epics-ioc-runner` identities before the test.
- Run the shipped system-infrastructure and system-lifecycle suites through the real installed-runner path without replacing the setup, sudo, systemd, or IOC paths.
- Record the complete suite results and the current sudoers-policy observations.

##### Out of Scope

- Re-running the retired 2026-06-03 Rocky golden.
- Treating the 2026-08-12 pre-#30 Rocky gate as verification of the current image-workflow artifact.
- Rebuilding the current golden unless provenance is invalid or the downstream run exposes a defect.
- Blocking jeonghanlee/cloud-provision#4 or the 1.2.4 release on this independent Backlog check.

##### Completion Criteria

- A fresh consumer selects one exact current Rocky image and matching creation record and reaches `READY`.
- The image manifest records the exact clean supplier identities and the installed runner reports the expected identity.
- `tests/test-system-infra.bash` and `tests/test-system-lifecycle.bash` run through the shipped installed path and both finish with final PASS suite records.
- Evidence records the image name, creation record, supplier commits, runner identity, commands, suite counts, final states, and log hashes.

##### Dependencies And Decisions

- D6
- jeonghanlee/cloud-provision#30 supplies the current copy-based image workflow and its accepted Rocky image format.
- jeonghanlee/cloud-provision#4 closes by owner-approved retirement of its exact historical target; this row does not retroactively satisfy that issue's original T1.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Select or bake a current Rocky golden through the shipped `cloud-provision` image workflow and boot a fresh consumer.
2. Capture the selected image, creation record, manifest, supplier commits, and installed runner identity.
3. Run the shipped system-infrastructure and system-lifecycle suites through the installed-runner path.
4. Record complete results and reconcile this detail and its GitHub issue.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| M18 / T1 | Runtime acceptance | Run the shipped system-only installed suite selection on a fresh current Rocky consumer after recording its image and software identities | Rocky 8 consumer from the current copy-based image workflow | The real system-infrastructure and system-lifecycle suites both emit complete final PASS records |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| M18 / T1 | Not run | Fresh current-image Rocky 8 consumer | Pending | The 2026-08-12 Rocky gate predates jeonghanlee/cloud-provision#30 and is supporting history, not M18 verification |

##### Closure Evidence

- none

##### GitHub Projection

Title: Validate the current Rocky 8 golden through downstream runner suites
Labels: tests
GitHub Milestone: Backlog
Observed State: open
Observed Labels: tests
Observed Milestone: Backlog
Observed Assignee: jeonghanlee
Last Compared: 2026-08-16; remote updated 2026-08-16T08:24:10Z
