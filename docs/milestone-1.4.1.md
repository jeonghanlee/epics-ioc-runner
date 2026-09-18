# Work Register

Release line: 1.4.1
Milestone index: 1.4.1
Canonical path: `docs/milestone-1.4.1.md`
Canonical branch or ref: `release-1.4.1`
Git upstream: `origin/master`
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `1.4.1`, number 18
Activation state: active on `release-1.4.1`, opened from the post-1.4.0 reset generation `8ee915a`

Next session entry point: the 1.4.1 cycle is open on `release-1.4.1`
(`RUNNER_VERSION` is `1.4.1-dev`). M1 and M2 are Ready. Start with M2: draft
`docs/adr/0003-site-environment-layer.md` per its Implementation Plan and
bring the plan to acceptance; M3 and M4 depend on it. GitHub milestone `1.4.1`
(number 18) exists and carries #153 (M1) and #152 (M3); the eventual master
merge and tag are owner-run steps.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Detection | M1 | Stop the post-init warning on self-diagnostic `error` text (#153) | Milestone | Not started | Yes | | A healthy IOC whose post-marker `error` occurrences are report lines starts without the warning while a genuine device error still warns; [detail](#m1---stop-the-post-init-warning-on-self-diagnostic-error-text) |
| Environment | M2 | ADR 0003: site-wide environment layer under the per-IOC conf | Milestone | Not started | Yes | D1, D2, D3 | ADR accepted and indexed in `docs/adr/README.md`; [detail](#m2---adr-0003-site-wide-environment-layer-under-the-per-ioc-conf) |
| Environment | M3 | Optional site environment file in both systemd unit templates (#152) | Milestone | Not started | No | M2 | Both templates carry the optional site `EnvironmentFile=`, a site value reaches the IOC environment, the per-IOC conf overrides it, and an absent file changes nothing; [detail](#m3---optional-site-environment-file-in-both-systemd-unit-templates) |
| Environment | M4 | Network environment reference: CA and PVA variables, layering rule, multi-homed example | Milestone | Not started | No | M2, D3 | `docs/NETWORK_ENV.md` published with the variable tables and the RFC 5737 example, `USER_GUIDE.md` and `FAQ.md` cross-linked; [detail](#m4---network-environment-reference-ca-and-pva-variables-layering-rule-multi-homed-example) |
| Release | M5 | Release 1.4.1 | Milestone | Not started | No | M1, M2, M3, M4 | Version stamped `1.4.1`, `release-1.4.1` merged to master, tag `1.4.1` and GitHub release published, milestone `1.4.1` closed; [detail](#m5---release-141) |

Tally: 5 milestone rows (5 Not started). Backlog is reported separately below
and excluded from this tally.

### Decisions

| ID | Decision | Decision Date |
| --- | --- | --- |
| D1 | The next development cycle is the patch line 1.4.1, carrying #152 and #153. #153 is a bug fix; #152 adds one optional `EnvironmentFile=` line whose absence leaves every existing installation unchanged. | 2026-09-17 |
| D2 | ioc-runner ships the layering mechanism (site-wide file under the per-IOC conf) and the variable documentation only. Site-specific values, including the owner's production topology, stay outside the repository. | 2026-09-17 |
| D3 | Every documented example address uses the RFC 5737 documentation ranges (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`), one per example network, so a multi-homed scenario is shown without any site value. | 2026-09-17 |

### Milestone Details

#### M1 - Stop the post-init warning on self-diagnostic `error` text

Origin: 8ee915a / M1
Identity History: none
GitHub Issue: #153 https://github.com/jeonghanlee/epics-ioc-runner/issues/153
Status: Not started

##### Summary

The ambiguous crash-detection subset matches `ERROR` as a bare, case-insensitive substring (`CRASH_LOG_PATTERNS_AMBIGUOUS`, `bin/ioc-runner:125`). During the post-marker confirmation dwell an IOC's own healthy diagnostic output — a `devSnmp` report's `Error count : 0` field and its `errors` column header — trips the corroborating-warning branch (`bin/ioc-runner:3379`). First observed on a PDU IOC on 2026-09-16; the IOC was healthy and stayed up (exit 0), so the defect is a false-positive warning, not a lifecycle failure.

##### Scope

Change the post-marker corroboration match so that report lines whose only `error` content is a count field or a column header no longer raise the warning, while a genuine post-initialization device error on a still-alive IOC continues to raise it. Update `docs/FAQ.md` Q6 and Q7 wherever the described matching rule changes.

Out of scope: the fatal-subset pre-marker verdict, the crash-loop death-banner verdict, `CRASH_LOG_PATTERNS_EXTRA` validation, and the transient first-poll `devSnmp ... read error` lines (a device-driver timing artifact).

##### Completion Criteria

- A fixture log carrying `Error count      : 0` and an `errors  OID name` header after the readiness marker, and nothing else matching, starts without the warning.
- A fixture log carrying a genuine post-marker error line on a still-alive IOC still prints the warning and exits 0.
- The existing fatal and crash-loop cases in the lifecycle suites are unchanged.

##### Dependencies And Decisions

- None. The matching rule itself is an open owner decision: tighten the `ERROR` token (boundary or context rule) versus exclude the report-line shapes through `CRASH_LOG_EXCLUDE_PATTERNS`. Record the choice as a D row when made.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Resolve the matching rule with the owner and record it as a decision.
2. Apply the rule in `bin/ioc-runner` at the ambiguous subset or the exclusion set, keeping the two subsets the single source of the base pattern.
3. Add the two fixture cases to `tests/test-local-lifecycle.bash` next to the existing post-init warning check (`tests/test-local-lifecycle.bash:1553`).
4. Update `docs/FAQ.md` Q6 and Q7 to state the rule.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local lifecycle | `tests/test-local-lifecycle.bash` with a post-marker fixture of report lines only | top (Debian 13) | `start` prints `successfully started`, no warning, exit 0 |
| T2 | Local lifecycle | Same suite with a genuine post-marker error line on a live IOC | top (Debian 13) | Warning printed, exit 0 |
| T3 | Regression | Full local lifecycle and source-regression suites | top (Debian 13) and rocky8-iocrunner VM | All existing fatal and crash-loop cases unchanged |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | top (Debian 13) | Pending | none |
| T2 | Not run | top (Debian 13) | Pending | none |
| T3 | Not run | top and rocky8-iocrunner VM | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: False positive: post-init warning triggered by IOC self-diagnostic output containing "error" substring
Labels: bug, P2-medium, area/detection
GitHub Milestone: 1.4.1
Observed State: open
Observed Labels: bug, P2-medium, area/detection
Observed Milestone: 1.4.1
Last Compared: 2026-09-18

#### M2 - ADR 0003: site-wide environment layer under the per-IOC conf

Origin: 8ee915a / M2
Identity History: none
GitHub Issue: none
Status: Not started

##### Summary

The per-IOC conf is loaded by systemd as the unit's `EnvironmentFile=` (`bin/ioc-runner:832`, `bin/setup-system-infra.bash:677`), so any `KEY=VALUE` in it reaches the IOC process (`docs/FAQ.md` Q:29). Values common to every IOC on a host or site — the CA and PVA client discovery lists in particular — must today be repeated in each conf. #152 asks for a standard way. The decision to record: an optional site-wide environment file read before the per-IOC conf, so the per-IOC conf overrides it, with the site values themselves kept outside ioc-runner (D2).

##### Scope

Write `docs/adr/0003-site-environment-layer.md` in the ADR conventions: context, the decision, the alternatives weighed (per-IOC conf only; a systemd drop-in per host; a second `EnvironmentFile=` line in the templates), evidence from the EPICS base 7.0.10 and PVXS 1.5.1 sources on which variables are host-common versus per-IOC (client discovery lists versus server interface binding, including the `EPICS_PVA_ADDR_LIST` beacon fallback that CA no longer has), and the consequences for install validation and documentation. Add the ADR row to `docs/adr/README.md`.

Out of scope: the implementation (M3), the reference document (M4), the container backend (which passes only `IOC_USER`, `IOC_CHDIR`, `IOC_PORT`, `IOC_CMD` to procServ and exports no conf environment, `bin/ioc-runner:553-575` — a pre-existing gap recorded here for a separate decision), and any site value.

##### Completion Criteria

- The ADR states the decision, the alternatives, the evidence, and the consequences inline and names the site file's location, precedence, and optional status.
- `docs/adr/README.md` lists ADR 0003 as Accepted with its date.
- The owner accepted the plan and the ADR text.

##### Dependencies And Decisions

- D1, D2, D3.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Draft the ADR with the alternatives table and the variable-class evidence.
2. Fix the site file's name, directory (`CONF_DIR`), precedence, and the `-` optional prefix in the decision.
3. Add the index row to `docs/adr/README.md`.
4. Owner review and acceptance.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Static | `git diff --check` and the ADR index row rendering | top (Debian 13) | No whitespace errors; index links resolve |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | top (Debian 13) | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M3 - Optional site environment file in both systemd unit templates

Origin: 8ee915a / M3
Identity History: none
GitHub Issue: #152 https://github.com/jeonghanlee/epics-ioc-runner/issues/152
Status: Not started

##### Summary

Implement the ADR 0003 decision: each systemd unit template gains one optional `EnvironmentFile=-<site file>` line before the per-IOC `EnvironmentFile=`, so a site-wide value is inherited by every IOC and the per-IOC conf overrides it; an absent site file leaves the unit's behavior exactly as today. Both template copies (`bin/ioc-runner`, `bin/setup-system-infra.bash`) change together under the two-copy contract guard (CI-25, `test_unit_template_contract`).

##### Scope

The two template renderers, the `test_unit_template_contract` guard, `install`-time validation of the site file with the same `parse_conf_file` grammar when the file exists, lifecycle-suite coverage for the three behaviors (site value reaches the IOC environment, per-IOC overrides it, absent file unchanged), and the #152 issue body rewrite to the new scope plus the reply to the reporter.

Out of scope: the container backend (see M2), the reference document (M4), any site value, and a merged-value view in `inspect` unless the owner adds it to the accepted plan.

##### Completion Criteria

- Both rendered templates contain the optional site `EnvironmentFile=` line ahead of the per-IOC line, and `test_unit_template_contract` passes.
- With a site file present, a key set only there is visible in the IOC process environment; a key set in both takes the per-IOC value.
- With no site file, the local and system lifecycle suites pass unchanged.
- `install` rejects a site file that fails the conf grammar with the same error shape as a conf failure.

##### Dependencies And Decisions

- M2 (the accepted ADR fixes name, location, and precedence).

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Add the optional site `EnvironmentFile=` line to both templates and extend `test_unit_template_contract` to pin it.
2. Validate the site file in `install` through `parse_conf_file` when it exists.
3. Extend `tests/test-local-lifecycle.bash` (next to `:933`) and `tests/test-system-lifecycle.bash` (next to `:805`) with the three behaviors.
4. Rewrite the #152 body to the new scope, reply to the reporter that the per-IOC conf is the documented path (`docs/FAQ.md` Q:29) and ask why broadcast auto-discovery did not reach the target IOC; both are owner-run or Issue-scope delegated.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Static | `tests/test-source-regression.bash` S16 `test_unit_template_contract` | top (Debian 13) | Both templates agree and carry the site line |
| T2 | Local lifecycle | Site file with a probe key; read the IOC process environment | top (Debian 13) | Probe key present with the site value |
| T3 | Local lifecycle | Same key in site file and per-IOC conf | top (Debian 13) | Per-IOC value observed |
| T4 | Local and system lifecycle | No site file; full suites | top (Debian 13) and rocky8-iocrunner VM | Unchanged results |
| T5 | Local lifecycle | Site file with an invalid line; `install` | top (Debian 13) | Same error shape as a conf grammar failure, non-zero exit |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | top (Debian 13) | Pending | none |
| T2 | Not run | top (Debian 13) | Pending | none |
| T3 | Not run | top (Debian 13) | Pending | none |
| T4 | Not run | top and rocky8-iocrunner VM | Pending | none |
| T5 | Not run | top (Debian 13) | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: Standard way of appending EPICS_CA_ADDR_LIST environment variable to system unit
Labels: enhancement, area/template
GitHub Milestone: 1.4.1
Observed State: open
Observed Labels: enhancement, area/template
Observed Milestone: 1.4.1
Last Compared: 2026-09-18

#### M4 - Network environment reference: CA and PVA variables, layering rule, multi-homed example

Origin: 8ee915a / M4
Identity History: none
GitHub Issue: none
Status: Not started

##### Summary

Publish `docs/NETWORK_ENV.md`, the topic document for the CA and PVA network environment variables an IOC under ioc-runner reads: the CA client set (libca, `modules/ca/src/client/iocinf.cpp`), the CA server set (rsrv, `modules/database/src/ioc/rsrv/caservertask.c`), the PVA client and server sets (PVXS 1.5.1 `netconfig.rst`, `client.rst`, `server.rst`), each with its shipped default, the asymmetries that mislead (the `EPICS_PVA_ADDR_LIST` server beacon fallback that CA removed in R3.15.4; the dual role of `EPICS_CA_SERVER_PORT`; the beacon narrowing side effect of `EPICS_CAS_INTF_ADDR_LIST`; the shared-UDP-port difference on a multi-IOC host), the site-wide versus per-IOC layering rule from ADR 0003, and one multi-homed worked example on the RFC 5737 ranges.

##### Scope

The new topic document, its entry in `docs/README.md`, cross-links from `docs/USER_GUIDE.md` and `docs/FAQ.md`, and a static guard that every address in the document lies in an RFC 5737 range.

Out of scope: any site value or site topology; the ADR (M2); the implementation (M3).

##### Completion Criteria

- Every variable statement in the document cites its source file and section and matches the cited source.
- The multi-homed example uses only `192.0.2.0/24`, `198.51.100.0/24`, and `203.0.113.0/24`.
- The PVA auto-beacon claim (all local broadcast addresses are supplemented when `EPICS_PVAS_INTF_ADDR_LIST` is set and auto-beacon is YES) is stated from an observed run, not from the document alone.

##### Dependencies And Decisions

- M2, D3.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

1. Write the four variable tables with defaults from `configure/CONFIG_ENV` and the PVXS references, each row citing its source.
2. Write the confusion-point section and the layering rule, referencing ADR 0003.
3. Write the multi-homed example on the RFC 5737 ranges: a site file with the client discovery lists and a per-IOC conf with the server interface binding.
4. Observe the PVA auto-beacon behavior on a test host and record the result in the document.
5. Add the `docs/README.md` entry, the cross-links, and the address-range guard.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Static | Address-range guard over `docs/NETWORK_ENV.md` | top (Debian 13) | Every dotted address is in an RFC 5737 range |
| T2 | Observation | A PVXS server with `EPICS_PVAS_INTF_ADDR_LIST` set and auto-beacon YES on a multi-interface host; capture beacon destinations | top (Debian 13) | Recorded destination set, used to word the document |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | top (Debian 13) | Pending | none |
| T2 | Not run | top (Debian 13) | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M5 - Release 1.4.1

Origin: 8ee915a / M5
Identity History: none
GitHub Issue: none
Status: Not started

##### Summary

Close the 1.4.1 cycle: stamp the release version, merge `release-1.4.1` into
master, publish the annotated tag `1.4.1` and its GitHub release from the
CHANGELOG section, and close the `1.4.1` milestone. Carries the two shipped
changes #153 (M1) and #152 (M3) with their reference documents (M2, M4).

##### Scope

Version bump to the release value, integrated re-run of the regression suites
on the merged candidate, the two-host gate and the production system suite,
and the release execution actions. Every git and GitHub action is separately
authorized under `git-workflow`.

Out of scope: any work item M1-M4 itself; new features beyond #152 and #153.

##### Completion Criteria

- `RUNNER_VERSION` is `1.4.1` and the CHANGELOG carries a `1.4.1` section.
- The regression suites pass on the merged candidate on both goldens.
- Tag `1.4.1` and the GitHub release exist; the `1.4.1` milestone is closed.

##### Dependencies And Decisions

- M1, M2, M3, M4 complete before release readiness (phase 9).

##### Integrated Verification

| Source Check | Re-run Trigger | Shared Surface | Release Verification Label | Expected Result | Result Evidence |
| --- | --- | --- | --- | --- | --- |
| M1 / T3 | M3 template change merged onto the M1 detection change | `bin/ioc-runner`, local lifecycle suite | Release Verification 1 | Full local lifecycle and source-regression suites pass on the merged tree | pending |
| M3 / T4 | M1 detection change merged onto the M3 template change | systemd unit templates, system lifecycle suite | Release Verification 2 | System lifecycle suite passes with no site file (behavior unchanged) | pending |

##### Production Environment Tests

| Release Verification Label | Timing | System | Version | Architecture | Deployment Path | Method | Expected Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Release Verification 3 | post-change | rocky8-iocrunner VM | 1.4.1 | x86_64 | clone-and-test + install-and-test | VM gate per RUNBOOK | Both pass | pending |
| Release Verification 4 | post-release | alsucl-psrv3 (Rocky NFS) | 1.4.1 | x86_64 | installed-mode `--system` suite in place | production system suite | Suite passes on root_squash workspace | pending |

##### Version Changes

| Field | File | Before | Planned After | Pre-check | Pre-check Label | Post-check | Post-check Label |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `RUNNER_VERSION` | `bin/ioc-runner` | 1.4.1-dev | 1.4.1 | `grep RUNNER_VERSION= bin/ioc-runner` | Release Verification 5 | `ioc-runner --version` | Release Verification 6 |
| CHANGELOG section | `CHANGELOG.md` | (none) | `## 1.4.1` | section absent | Release Verification 5 | section present | Release Verification 6 |

##### Release Execution

| Step | Action | Authorization | Expected Result | Evidence |
| --- | --- | --- | --- | --- |
| 1 | Merge `release-1.4.1` into master (no fast-forward) | `override release` | Merge commit on master | pending |
| 2 | Annotated tag `1.4.1` on the merge commit | `override release` | Tag object `1.4.1` | pending |
| 3 | Push master and the tag | `override release` | `origin/master` and `refs/tags/1.4.1` updated | pending |
| 4 | `gh release create 1.4.1 --notes-file` from the CHANGELOG section | `override release` | Release published | pending |
| 5 | Close GitHub milestone `1.4.1` | `override release` | Milestone closed | pending |
| 6 | Delete the release branch two releases back (local + origin) per the branch workflow | owner-run | Stale release branch removed | pending |

##### Release Verification Plan

| Label | Layer | Timing | Method | Environment | Expected Result | Evidence Target |
| --- | --- | --- | --- | --- | --- | --- |
| Release Verification 1 | Regression | pre-change | Local lifecycle + source-regression suites on the merged candidate | top (Debian 13) | Pass | run log |
| Release Verification 2 | Regression | pre-change | System lifecycle suite on the merged candidate | rocky8-iocrunner VM | Pass | run log |
| Release Verification 3 | System | post-change | VM gate (clone-and-test + install-and-test) | rocky8-iocrunner VM | Pass | run log |
| Release Verification 4 | Production | post-release | Installed-mode `--system` suite in place | alsucl-psrv3 | Pass | run log |
| Release Verification 5 | Version | pre-change | Version fields at their before state | working tree | Confirmed | command output |
| Release Verification 6 | Version | post-change | Version fields at their after state | working tree | Confirmed | command output |
| Release Verification 7 | Release object | post-release | Tag and release identity on `origin` | GitHub | `1.4.1` present | tag and release URL |
| Release Verification 8 | Tracker | post-release | Milestone `1.4.1` state and issue closure | GitHub | Closed | milestone URL |

##### Release Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| Release Verification 1 | Not run | top (Debian 13) | Pending | none |
| Release Verification 2 | Not run | rocky8-iocrunner VM | Pending | none |
| Release Verification 3 | Not run | rocky8-iocrunner VM | Pending | none |
| Release Verification 4 | Not run | alsucl-psrv3 | Pending | none |
| Release Verification 5 | Not run | working tree | Pending | none |
| Release Verification 6 | Not run | working tree | Pending | none |
| Release Verification 7 | Not run | GitHub | Pending | none |
| Release Verification 8 | Not run | GitHub | Pending | none |

##### Closure Evidence

- none

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: 1.4.1
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

No unassigned work is currently held in Backlog.

### Backlog Details

None.

## History

| Reset Date | Prior State Commit |
| --- | --- |
| 2026-09-07 | [8ee915aecb3a25888b7553c2309f627deeac37b3](https://github.com/jeonghanlee/epics-ioc-runner/commit/8ee915aecb3a25888b7553c2309f627deeac37b3) |
