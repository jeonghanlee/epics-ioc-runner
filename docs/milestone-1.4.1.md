# Work Register

Release line: 1.4.1
Milestone index: 1.4.1
Canonical path: `docs/milestone-1.4.1.md`
Canonical branch or ref: `release-1.4.1`
Git upstream: `origin/master`
Remote tracker: `jeonghanlee/epics-ioc-runner`, GitHub milestone `1.4.1`, number 18
Activation state: active on `release-1.4.1`, opened from the post-1.4.0 reset generation `8ee915a`

Next session entry point: M7 (mdBook docs site), then M5 (release 1.4.1). M1-M4 and M6 are Complete;
#152, #153 are closed and #154 closes on this landing; the gate is full-green
at the repinned identity (run 20260919T165029Z-494007). Open M5 through
release-cycle: version bump, integrated re-gate, master merge, tag 1.4.1,
GitHub release, milestone close.
GitHub milestone `1.4.1` (number 18) carries #153 (M1) and #152 (M3).

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Detection | M1 | Stop the post-init warning on self-diagnostic `error` text (#153) | Milestone | Complete | — | D4, D6 | A healthy IOC whose post-marker `error` occurrences are report lines starts without the warning; an uppercase `ERROR` severity line still warns with the heuristic wording, the matched line shown, and exit 0; [detail](#m1---stop-the-post-init-warning-on-self-diagnostic-error-text) |
| Environment | M2 | ADR 0003: site-wide environment layer under the per-IOC conf | Milestone | Complete | — | D1, D2, D3 | ADR accepted and indexed in `docs/adr/README.md`; [detail](#m2---adr-0003-site-wide-environment-layer-under-the-per-ioc-conf) |
| Environment | M3 | Optional site environment file in both systemd unit templates (#152) | Milestone | Complete | — | M2 | Both templates carry the optional site `EnvironmentFile=`, a site value reaches the IOC environment, the per-IOC conf overrides it, and an absent file changes nothing; [detail](#m3---optional-site-environment-file-in-both-systemd-unit-templates) |
| Environment | M4 | Network environment reference: CA and PVA variables, layering rule, multi-homed example | Milestone | Complete | — | M2, D3 | `docs/NETWORK_ENV.md` published with the variable tables and the RFC 5737 example, `USER_GUIDE.md` and `FAQ.md` cross-linked; [detail](#m4---network-environment-reference-ca-and-pva-variables-layering-rule-multi-homed-example) |
| Operations | M6 | `log` command: show the effective procServ log of an IOC (#154) | Milestone | Complete | — | D5 | `ioc-runner [--local] log <name> [-f] [-n <count>]` prints the tail of the IOC's effective procServ log file, follows it with `-f`, and sets the tail depth with `-n` (default 40); the post-init warning hint names the command; [detail](#m6---log-command-show-the-effective-procserv-log-of-an-ioc) |
| Documentation | M7 | mdBook documentation site over the existing docs, deployed to GitHub Pages (#155) | Milestone | In progress | — | — | `mdbook build` renders the existing `docs/` into a site with a curated `SUMMARY.md` (internal register docs excluded), and `.github/workflows/docs.yml` deploys it to GitHub Pages on push to master; [detail](#m7---mdbook-documentation-site) |
| Release | M5 | Release 1.4.1 | Milestone | Not started | No | M1, M2, M3, M4, M6, M7 | Version stamped `1.4.1`, `release-1.4.1` merged to master, tag `1.4.1` and GitHub release published, milestone `1.4.1` closed; [detail](#m5---release-141) |

Tally: 7 milestone rows (5 Complete, 1 In progress, 1 Not started). Backlog is reported separately below
and excluded from this tally.

### Decisions

| ID | Decision | Decision Date |
| --- | --- | --- |
| D1 | The next development cycle is the patch line 1.4.1, carrying #152 and #153. #153 is a bug fix; #152 adds one optional `EnvironmentFile=` line whose absence leaves every existing installation unchanged. | 2026-09-17 |
| D2 | ioc-runner ships the layering mechanism (site-wide file under the per-IOC conf) and the variable documentation only. Site-specific values, including the owner's production topology, stay outside the repository. | 2026-09-17 |
| D3 | Every documented example address uses the RFC 5737 documentation ranges (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`), one per example network, so a multi-homed scenario is shown without any site value. | 2026-09-17 |
| D4 | The post-initialization corroboration warning is a heuristic hint, not a verdict. Its text says so and directs the operator to the log, it prints the matched line(s), and the `ERROR` corroborating token matches the marker shape — `ERROR` followed by a colon, after ANSI SGR sequences are removed from the scan window — instead of the bare word. Count fields, column headers, and colon-less prose (including the transient `devSnmp ... read error` lines) no longer raise it. The fatal subset, the death-banner verdict, and `CRASH_LOG_PATTERNS_EXTRA` are unchanged. | 2026-09-18 |
| D5 | A `log` command (`ioc-runner [--local] log <name> [-f] [-n <count>]`) ships in 1.4.1 as its own work item, M6, separate from the #153 fix: the reworded warning directs the operator to the log, and the command is the one-step way there. `-f` follows and `-n` sets the tail depth (default 40); both reuse the global option parser, and `-f` carries no force meaning on this read-only verb. | 2026-09-18 |
| D6 | D4's corroborating-token mechanism is superseded: the built-in corroboration matches framework severity markers case-sensitively (the uppercase `ERROR` word, the PVXS ` ERR `/` CRIT ` level words, `sevr=major`/`sevr=fatal`) plus the existing case-insensitive message phrases, and never English error vocabulary — prose sensitivity is the per-IOC `CRASH_LOG_PATTERNS_EXTRA` opt-in. Grounds (the 33-module emission survey, the renderer evidence including colon-less `ERL_ERROR`, the healthy-log measurement) and the rejected alternatives are ADR 0004. D4's heuristic warning wording, matched-line display, and ANSI SGR normalization stand. | 2026-09-18 |

### Milestone Details

#### M1 - Stop the post-init warning on self-diagnostic `error` text

Origin: 8ee915a / M1
Identity History: none
GitHub Issue: #153 https://github.com/jeonghanlee/epics-ioc-runner/issues/153
Status: Complete

##### Summary

The ambiguous crash-detection subset matches `ERROR` as a bare, case-insensitive substring (`CRASH_LOG_PATTERNS_AMBIGUOUS`, `bin/ioc-runner:125`). During the post-marker confirmation dwell an IOC's own healthy diagnostic output — a `devSnmp` report's `Error count : 0` field and its `errors` column header — trips the corroborating-warning branch (`bin/ioc-runner:3379`). First observed on a PDU IOC on 2026-09-16; the IOC was healthy and stayed up (exit 0), so the defect is a false-positive warning, not a lifecycle failure.

##### Scope

Rework the post-marker corroboration warning per D4/D6: (1) reword it as a heuristic hint that directs the operator to the log; (2) print the matched line(s) under it; (3) replace the bare `ERROR` vocabulary token with the case-sensitive severity subset (`CRASH_LOG_PATTERNS_SEVERITY`: the uppercase `ERROR` word, PVXS ` ERR `/` CRIT `, `sevr=major|fatal`), with ANSI SGR sequences removed from the scan window before matching, so healthy report vocabulary (a count field, a column header, lowercase prose) never corroborates while framework severity markers on a still-alive IOC do (ADR 0004). Update `docs/FAQ.md` Q6 and Q7, the source-regression S20/S21 pattern contracts, and the local lifecycle fixtures that assert the warning text.

Out of scope: the fatal-subset pre-marker verdict, the crash-loop death-banner verdict, `CRASH_LOG_PATTERNS_EXTRA` validation, and the `log` command (M6). The transient first-poll `devSnmp ... read error` lines are lowercase prose outside the severity subset and therefore stop raising the warning; this is a consequence of D6, not a target of M1.

##### Completion Criteria

- A fixture log carrying `Error count      : 0` and an `errors  OID name` header after the readiness marker, and nothing else matching, starts without the warning.
- A fixture log carrying an uppercase `ERROR ...` severity line after the marker on a still-alive IOC prints the warning with the heuristic wording, shows the matched line, and exits 0.
- The same marker wrapped in ANSI SGR sequences (the EPICS `ERL_ERROR` rendering) still prints the warning.
- The existing fatal and crash-loop cases in the lifecycle suites are unchanged.

##### Dependencies And Decisions

- D4 (heuristic-warning principle, matched-line display, ANSI normalization), D6 (severity-marker mechanism; ADR 0004). The log hint line keeps its current `tail -f` form here; M6 changes it to name `ioc-runner log <name>`.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-18 (owner confirmed the three-part rework as D4; amended same day to the D6 severity-marker mechanism after the gate falsified the colon rule — ADR 0004)
Implementation Authorization: 2026-09-18
Superseded Plan Artifacts: the D4 colon-marker step, superseded by D6

1. In `read_startup_signals`, remove ANSI SGR sequences from the scan window before the exclusion filter and pattern matching (shared `crash_scan_filter`).
2. Move `ERROR` out of `CRASH_LOG_PATTERNS_AMBIGUOUS` into the new case-sensitive `CRASH_LOG_PATTERNS_SEVERITY` (uppercase `ERROR` word, PVXS ` ERR `/` CRIT `, `sevr=major|fatal`); the ambiguous phrases and `CRASH_LOG_PATTERNS_EXTRA` stay case-insensitive.
3. Reword the post-marker corroboration warning as a heuristic hint that directs the operator to the log, and print the matched line(s) (first few) beneath it before the existing log hint, unioning both match classes.
4. Add the fixture cases to `tests/test-local-lifecycle.bash` next to the existing post-init warning check, update any assertion on the old warning text, and repin the source-regression S20/S21 pattern contracts to the severity subset (membership, case-sensitivity, benign vocabulary, normalized S21 positive control).
5. Update `docs/FAQ.md` Q6 and Q7 to state the severity-marker rule, the ANSI normalization, the vocabulary opt-in via `CRASH_LOG_PATTERNS_EXTRA`, and that the warning is a heuristic to confirm in the log; record the grounds as ADR 0004.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local lifecycle | `tests/test-local-lifecycle.bash` with a post-marker fixture of report lines only | top (Debian 13) | `start` prints `successfully started`, no warning, exit 0 |
| T2 | Local lifecycle | Same suite with a genuine `ERROR:` marker line after the marker on a live IOC | top (Debian 13) | Heuristic warning printed with the matched line shown, exit 0 |
| T3 | Regression | Full local lifecycle and source-regression suites | top (Debian 13) and rocky8-iocrunner VM | All existing fatal and crash-loop cases unchanged |
| T4 | Local lifecycle | Same suite with the `ERROR:` marker wrapped in ANSI SGR sequences | top (Debian 13) | Heuristic warning still printed, exit 0 |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-18 | rocky8 + debian13 iocrunner goldens | Pass | local S39 report-lines pair (start exit 0, no warning) PASS on both goldens; gate run 20260919T060839Z-218241 |
| T2 | 2026-09-18 | rocky8 + debian13 iocrunner goldens | Pass | local S39 error-marker trio (exit 0, heuristic warning, matched line shown) PASS on both goldens; same run |
| T3 | 2026-09-18 | rocky8 + debian13 iocrunner goldens | Pass | full six-suite matrix, both hosts, 12/12 rc=0, no FAIL/SKIP/SCRIPT_ERROR; only the examined OS-applicability NAs (rocky S29 per CI-32, debian S23); same run |
| T4 | 2026-09-18 | rocky8 + debian13 iocrunner goldens | Pass | local S39 ANSI-marker pair (exit 0, warning) PASS on both goldens; same run |

##### Closure Evidence

- Implementation commits on `release-1.4.1`: cd77398 (D6 severity subset, S20/S21 contracts, ADR 0004, FAQ) and 4d709fb (warning-path errexit fix, S39 exit-0 pins). Verification: gate run 20260919T060839Z-218241, both goldens, 12/12 suites PASS; identity repinned to that run's reported value in the commit carrying this row. Grounds: ADR 0004; D4/D6. Confirming full-green gate: run 20260919T061758Z-227038 (identity pin matched). #153 closed 2026-09-18.

##### GitHub Projection

Title: False positive: post-init warning triggered by IOC self-diagnostic output containing "error" substring
Labels: bug, P2-medium, area/detection
GitHub Milestone: 1.4.1
Observed State: closed
Observed Labels: bug, P2-medium, area/detection
Observed Milestone: 1.4.1
Last Compared: 2026-09-18

#### M2 - ADR 0003: site-wide environment layer under the per-IOC conf

Origin: 8ee915a / M2
Identity History: none
GitHub Issue: none
Status: Complete

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

Plan Status: accepted
Plan Acceptance: 2026-09-18 (owner accepted ADR 0003)
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
| T1 | 2026-09-18 | top (Debian 13) | Pass | ADR committed clean (gitleaks and whitespace); index row present in `docs/adr/README.md` |

##### Closure Evidence

- ADR 0003 Accepted (2026-09-18), indexed in `docs/adr/README.md`; committed `7db8cbe` and corrected at `1307568` after a grammar-layer review finding; passed third-person and second-person review passes before each commit.

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
Status: Complete

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

Plan Status: accepted
Plan Acceptance: 2026-09-18 (owner accepted the M3 plan)
Implementation Authorization: 2026-09-18 (owner directed implementation)
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
| T1 | 2026-09-18 | rocky8 + debian13 iocrunner goldens | Pass | source-regression S16 `test_unit_template_contract` PASS on both goldens; deployed unit template carries the site line |
| T2 | 2026-09-18 | rocky8 + debian13 iocrunner goldens | Pass | local S38 / system S35 `site-env-value-reaches-ioc-environment` PASS on both goldens (read from the running procServ `/proc/<pid>/environ`) |
| T3 | 2026-09-18 | rocky8 + debian13 iocrunner goldens | Pass | local S38 / system S35 `per-ioc-conf-overrides-site-env` PASS on both goldens |
| T4 | 2026-09-18 | rocky8 + debian13 iocrunner goldens | Pass | all six suites PASS on both goldens with no site file present (the baseline gate run) |
| T5 | 2026-09-18 | rocky8 + debian13 iocrunner goldens | Pass | error-handling S08 `install-rejects-malformed-site-env` PASS on both goldens |

##### Closure Evidence

- Templates and install validation committed `b8b840e`; error-handling site.env grammar test in the same commit. Lifecycle (a)/(b) tests land in this commit with the `suites.bash` identity re-baseline. Verified on fresh rocky8 + debian13 iocrunner goldens (baked 2026-09-18 from cloud-provision/ansible-provision master) via the gate-suites run `20260918T153431Z`: all six suites PASS on both goldens; the two-copy template guard covers the new line with no guard change. Refs #152.

##### GitHub Projection

Title: Standard way of appending EPICS_CA_ADDR_LIST environment variable to system unit
Labels: enhancement, area/template
GitHub Milestone: 1.4.1
Observed State: closed
Observed Labels: enhancement, area/template
Observed Milestone: 1.4.1
Last Compared: 2026-09-18

#### M4 - Network environment reference: CA and PVA variables, layering rule, multi-homed example

Origin: 8ee915a / M4
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

Publish `docs/NETWORK_ENV.md`, the topic document for the CA and PVA network environment variables an IOC under ioc-runner reads: the CA client set (libca, `modules/ca/src/client/iocinf.cpp`), the CA server set (rsrv, `modules/database/src/ioc/rsrv/caservertask.c`), the PVA client and server sets (PVXS 1.5.1 `netconfig.rst`, `client.rst`, `server.rst`), each with its shipped default, the asymmetries that mislead (the `EPICS_PVA_ADDR_LIST` server beacon fallback that CA removed in R3.15.4; the dual role of `EPICS_CA_SERVER_PORT`; the beacon narrowing side effect of `EPICS_CAS_INTF_ADDR_LIST`; the shared-UDP-port difference on a multi-IOC host), the site-wide versus per-IOC layering rule from ADR 0003, and one multi-homed worked example on the RFC 5737 ranges.

##### Scope

The new topic document organized around the usage scenarios that lead an operator to the site layer (single shared discovery network, multi-homed IOC, per-IOC exception), carrying the four variable tables, the layering rule, and the CA/PVA asymmetries inside that framing; one new `docs/FAQ.md` entry for the shared-variable question; its entry in `docs/README.md`; cross-links from `docs/USER_GUIDE.md` and `docs/FAQ.md`; and a static guard that every address in the document lies in an RFC 5737 range.

Out of scope: any site value or site topology; the ADR (M2); the implementation (M3).

##### Completion Criteria

- Every variable statement in the document cites its source file and section and matches the cited source.
- The multi-homed example uses only `192.0.2.0/24`, `198.51.100.0/24`, and `203.0.113.0/24`.
- The PVA auto-beacon claim (all local broadcast addresses are supplemented when `EPICS_PVAS_INTF_ADDR_LIST` is set and auto-beacon is YES) is stated from an observed run, not from the document alone.

##### Dependencies And Decisions

- M2, D3.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-18 (owner direction to organize the document around usage scenarios and add a FAQ entry)
Implementation Authorization: 2026-09-18
Superseded Plan Artifacts: none

1. Frame the document around three usage scenarios (single shared discovery network, multi-homed IOC, per-IOC exception) so each scenario names the variables it needs and where they belong.
2. Write the four variable tables (CA client, CA server, PVA client, PVA server) with defaults from `configure/CONFIG_ENV` and the PVXS references, each row citing its source.
3. Write the confusion-point section (the CA/PVA beacon-fallback asymmetry, the `EPICS_CA_SERVER_PORT` dual role, the `EPICS_CAS_INTF_ADDR_LIST` beacon narrowing) and the site-wide versus per-IOC layering rule, referencing ADR 0003.
4. Write the multi-homed worked example on the RFC 5737 ranges: a site file with the client discovery lists and a per-IOC conf with the server interface binding.
5. Observe the PVA auto-beacon behavior on a test host and record the result in the document.
6. Add the new `docs/FAQ.md` entry, the `docs/README.md` index entry, the `docs/USER_GUIDE.md` cross-link, and the address-range guard.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Static | Address-range guard over `docs/NETWORK_ENV.md` | top (Debian 13) | Every dotted address is in an RFC 5737 range |
| T2 | Observation | A PVXS server with `EPICS_PVAS_INTF_ADDR_LIST` set and auto-beacon YES on a multi-interface host; capture beacon destinations | top (Debian 13) | Recorded destination set, used to word the document |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-18 | top (Debian 13) | Pass | `tests/check-doc-addresses.bash` over `docs/NETWORK_ENV.md`: 10 unique addresses, all within RFC 5737 ranges; a non-RFC-5737 address fails the guard (negative case) |
| T2 | 2026-09-18 | top (Debian 13) | Observed | PVXS 1.5.1 `softIocPVX` `pvxsr 1` on a four-interface host: a wildcard `EPICS_PVAS_INTF_ADDR_LIST` gives a beacon list of the loopback broadcast plus all four interface broadcasts, while a single named interface gives the loopback broadcast plus that interface's broadcast only. The observation corrected the draft: PVA narrows beacons to the named interface, as CA does, so the `server.rst` "all local broadcast addresses" wording holds only for the wildcard case (`config.cpp` `Config::expand`/`expandAddrList`) |

##### Closure Evidence

- `docs/NETWORK_ENV.md` (topic reference), `docs/FAQ.md` Q12, the `docs/README.md` index entry, and the `docs/USER_GUIDE.md` cross-link; the static guard `tests/check-doc-addresses.bash`. T1 Pass and the T2 observation (which corrected the PVA beacon-narrowing wording) are recorded above. Carried by the M4 documentation commit on `release-1.4.1`.

##### GitHub Projection

Title: none
Labels: none
GitHub Milestone: none
Observed State: none
Observed Labels: none
Observed Milestone: none
Last Compared: never

#### M6 - log command: show the effective procServ log of an IOC

Origin: 8ee915a / M6
Identity History: none
GitHub Issue: #154 https://github.com/jeonghanlee/epics-ioc-runner/issues/154
Status: Complete

##### Summary

Add a `log` subcommand that resolves an IOC's effective procServ log file — the same path `start` and `restart` verify before changing service state — and prints its tail, following it on request. The post-initialization warning directs the operator to the log; this command is the one-step way there, and the warning's log hint names it once the command exists.

##### Scope

`ioc-runner [--local] log <name> [-f] [-n <count>]`: resolve the effective log path for the IOC in the active mode, print the last 40 lines by default (or `-n <count>` lines), follow with `-f`; fail with a clear message when the IOC is unknown, the log file is absent, or `-n` is not a positive integer. Change the post-init warning's hint from the raw `tail -f <path>` form to `ioc-runner log <name>`. Document the command in `docs/CLI_REFERENCE.md`, the log section of `docs/USER_GUIDE.md`, and cross-link from `docs/FAQ.md` Q9 and `docs/LOG_LAYOUT.md`.

Out of scope: journal integration, log rotation or layout changes, remote-host access, and any change to the permission model (the system log stays `0644`).

##### Completion Criteria

- `log <name>` prints the tail of the effective log file in local and system mode, exit 0; `-n <count>` limits the output to that many lines and a non-positive-integer `-n` is rejected.
- `log -f <name>` follows the file until interrupted.
- An unknown IOC name or a missing log file exits non-zero with a message naming the cause.
- The post-init warning hint names `ioc-runner log <name>`.
- Existing lifecycle and source-regression suites are unchanged.

##### Dependencies And Decisions

- D5. Sequencing note, not a dependency: land after M1 to avoid concurrent edits in the same start/restart region; the hint change applies whatever the warning wording.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-18 (owner started M6 on the drafted plan; the follow flag reuses the existing global `-f`, which has no other meaning on a read-only verb)
Implementation Authorization: 2026-09-18
Superseded Plan Artifacts: none

1. Add the `log` subcommand and its usage entry in `bin/ioc-runner`, reusing the effective log path resolution; add the `-n <count>` global option (positive-integer validated, default tail 40) alongside the reused `-f`.
2. Implement the default tail and `-f` follow; define the error paths for an unknown IOC and a missing file.
3. Change `print_log_file_hint` to name `ioc-runner log <name>` (with `--local` in local mode).
4. Add local and system lifecycle checks for the command and its error paths.
5. Update `docs/CLI_REFERENCE.md`, `docs/USER_GUIDE.md`, `docs/FAQ.md` Q9, and `docs/LOG_LAYOUT.md`.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | Local lifecycle | `log <name>` on a running local IOC | top (Debian 13) | Tail of the effective log printed, exit 0 |
| T2 | System lifecycle | `log <name>` on a running system IOC | rocky8 + debian13 iocrunner goldens | Tail printed under the `0644` log permission, exit 0 |
| T3 | Local lifecycle | `log <unknown>` and `log <name>` with the log file removed | top (Debian 13) | Non-zero exit with a message naming the cause |
| T4 | Static | Warning hint text | top (Debian 13) | Post-init warning hint names `ioc-runner log <name>` |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-19 | rocky8 + debian13 iocrunner goldens | Pass | `log` tail shows the readiness marker (local S40, both goldens); gate run 20260919T165029Z-494007 |
| T2 | 2026-09-19 | rocky8 + debian13 iocrunner goldens | Pass | `log` on a running system IOC shows the marker under the 0644 log (system S15, both goldens); same run |
| T3 | 2026-09-19 | rocky8 + debian13 iocrunner goldens | Pass | unknown IOC, never-started IOC, and non-positive `-n` each exit non-zero with the cause (local S40); same run |
| T4 | 2026-09-19 | rocky8 + debian13 iocrunner goldens | Pass | the post-init hint names `ioc-runner log` and `-n <count>` limits the tail (local S40); same run |

##### Closure Evidence

- `log` verb in `bin/ioc-runner` (dispatch, usage, `-f`/`-n`, hint rewrite), local S40 (7 checks) and system S15 (1 check), docs (`CLI_REFERENCE`, `USER_GUIDE`, `FAQ` Q9, `LOG_LAYOUT`). Verified on both goldens, gate run 20260919T165029Z-494007, 12/12 suites PASS; identity repinned to that run's value in the commit carrying this row. Commits: dbcf2d9 (feature + tests), 7d5a2b9 (S40 fixture isolation). Refs #154; close #154 on this landing.

##### GitHub Projection

Title: Add a log command to show an IOC's procServ log
Labels: enhancement, area/inspect, P2-medium
GitHub Milestone: 1.4.1
Observed State: open
Observed Labels: enhancement, area/inspect, P2-medium
Observed Milestone: 1.4.1
Last Compared: 2026-09-18

#### M7 - mdBook documentation site

Origin: 28cba65 / M7
Identity History: none
GitHub Issue: #155
Status: In progress

##### Summary

Bundle the existing user-facing documentation into an mdBook site and deploy it
to GitHub Pages, following the epics-trainings pattern (in-place `src = "docs"`)
simplified to GitHub only (a single `book.toml`, no GitLab variant).

##### Scope

A repository-root `book.toml` (`src = "docs"`, `build-dir = "public"`, GitHub
`git-repository-url` and `edit-url-template`), a curated `docs/SUMMARY.md` over
the existing docs, a `.github/workflows/docs.yml` that builds with the
`jeonghanlee/mdbook` container and deploys to GitHub Pages on push to master,
and a `.gitignore` entry for the build output.

Out of scope: rewriting or relocating the existing documents; a Makefile build
target; publishing the internal register (`CLOSED_DOORS.md`, `milestone-*.md`,
`review_sessions/`) and the Architecture Decision Records (`docs/adr/`), which
stay out of `SUMMARY.md`. Enabling GitHub Pages with the GitHub Actions source
is a repository setting performed by the owner.

##### Completion Criteria

- `mdbook build` renders the curated `docs/` into `public/` with no unresolved
  SUMMARY reference.
- The internal register documents are not published.
- `.github/workflows/docs.yml` is valid and deploys to GitHub Pages on push to
  master.

##### Dependencies And Decisions

- No milestone dependencies; ships in 1.4.1, so M5 depends on M7.
- Decision (2026-09-19): GitHub-only, a single `book.toml`; in-place
  `src = "docs"` per the epics-trainings pattern rather than relocating the
  documents into `docs/src/`.
- Decision (2026-09-19): the ADRs are maintainer decision-history, not end-user
  documentation, so they are excluded from `SUMMARY.md` alongside the internal
  register. `docs/FAQ.md` had a `<name>` placeholder inside an italic quote that
  mdBook parsed as an unclosed HTML tag; it is backslash-escaped so it renders
  literally.

##### Implementation Plan

1. Add `book.toml` at the repository root.
2. Author `docs/SUMMARY.md` covering the user-facing chapters (overview,
   install and uninstall, user guides, CLI reference, architecture, permission
   model, network environment, log layout, exit and signal handling, and
   FAQ).
3. Add `.github/workflows/docs.yml` (build with the `jeonghanlee/mdbook`
   container, deploy to GitHub Pages).
4. Add `public/` to `.gitignore`.

Acceptance: local `mdbook build` clean; SUMMARY resolves; internal docs absent
from `public/`; workflow YAML valid.

##### Test Plan

- T1: `mdbook build` from a clean tree exits 0 with no missing-file error and no
  unresolved SUMMARY link.
- T2: the build output `public/` contains the curated chapters and none of the
  internal register documents.
- T3: `.github/workflows/docs.yml` parses as valid workflow YAML.

##### Verification Results

| Check | Result | Evidence |
| --- | --- | --- |
| T1 | Pass | `mdbook build` in the `jeonghanlee/mdbook` container: rc=0, no warning, HTML written to `public/` |
| T2 | Pass | `public/` has the curated chapters; no `adr/`, `CLOSED_DOORS`, or `milestone-*` published |
| T3 | Pass | `.github/workflows/docs.yml` parses as valid YAML |

The GitHub Pages deployment itself is verified post-merge, after `docs.yml` runs
on `master`.

##### Closure Evidence

- none

##### GitHub Projection

Title: Add an mdBook documentation site deployed to GitHub Pages
Labels: documentation
GitHub Milestone: 1.4.1
Observed State: open (#155)
Observed Labels: documentation
Observed Milestone: 1.4.1
Last Compared: 2026-09-19

#### M5 - Release 1.4.1

Origin: 8ee915a / M5
Identity History: none
GitHub Issue: none
Status: Not started

##### Summary

Close the 1.4.1 cycle: stamp the release version, merge `release-1.4.1` into
master, publish the annotated tag `1.4.1` and its GitHub release from the
CHANGELOG section, and close the `1.4.1` milestone. Carries the two shipped
changes #153 (M1) and #152 (M3) with their reference documents (M2, M4), and
the `log` command (M6).

##### Scope

Version bump to the release value, integrated re-run of the regression suites
on the merged candidate, the two-host gate and the production system suite,
and the release execution actions. Every git and GitHub action is separately
authorized under `git-workflow`.

Out of scope: any work item M1-M4 or M6 itself; new features beyond #152, #153, and the `log` command (D5).

##### Completion Criteria

- `RUNNER_VERSION` is `1.4.1` and the CHANGELOG carries a `1.4.1` section.
- The regression suites pass on the merged candidate on both goldens.
- Tag `1.4.1` and the GitHub release exist; the `1.4.1` milestone is closed.

##### Dependencies And Decisions

- M1, M2, M3, M4, M6 complete before release readiness (phase 9).
- Decision (2026-09-19): the multi-user 14-scenario contract gate is required
  for 1.4.1. #152 adds `EnvironmentFile=` to the shared system unit template
  (multi-user S2 shared-configuration surface) and #154's `log` command reads
  procServ log files (multi-user L3 and S5 log-isolation surface), so the
  release must re-verify multi-user permission isolation. Added as Release
  Verification 9.

##### Integrated Verification

| Source Check | Re-run Trigger | Shared Surface | Release Verification Label | Expected Result | Result Evidence |
| --- | --- | --- | --- | --- | --- |
| M1 / T3 | M3 template change merged onto the M1 detection change | `bin/ioc-runner`, local lifecycle suite | Release Verification 1 | Full local lifecycle and source-regression suites pass on the merged tree | Pass; gate-suites 20260919T184758Z on both goldens (811b546), GATE SUITES PASS |
| M3 / T4 | M1 detection change merged onto the M3 template change | systemd unit templates, system lifecycle suite | Release Verification 2 | System lifecycle suite passes with no site file (behavior unchanged) | Pass; same run 20260919T184758Z, system-lifecycle green both hosts |

##### Production Environment Tests

| Release Verification Label | Timing | System | Version | Architecture | Deployment Path | Method | Expected Result | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Release Verification 3 | post-change | rocky8-iocrunner VM | 1.4.1 | x86_64 | clone-and-test + install-and-test | VM gate per RUNBOOK | Both pass | Pass; gate-suites 20260919T202844Z (cf5cecc), GATE SUITES PASS hosts=2 |
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
| Release Verification 9 | Multi-user | post-change | Multi-user 14-scenario contract (`run-all` driver) | rocky8-iocrunner + debian13-iocrunner VMs | Pass | run-all.log |

##### Release Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| Release Verification 1 | 2026-09-19 | rocky8 + debian13 goldens (suite matrix; top has no EPICS runtime) | Pass | gate-suites 20260919T184758Z, 811b546, GATE SUITES PASS, local-lifecycle + source-regression green |
| Release Verification 2 | 2026-09-19 | rocky8 + debian13 goldens | Pass | same run 20260919T184758Z, system-lifecycle suite green both hosts |
| Release Verification 3 | 2026-09-19 | rocky8 + debian13 goldens | Pass | gate-suites 20260919T202844Z, cf5cecc, GATE SUITES PASS hosts=2, no FAIL/SKIP/SCRIPT_ERROR |
| Release Verification 4 | Not run | alsucl-psrv3 | Pending | none |
| Release Verification 5 | 2026-09-19 | working tree | Confirmed | RUNNER_VERSION 1.4.1-dev and no CHANGELOG 1.4.1 section before the bump |
| Release Verification 6 | 2026-09-19 | both goldens | Confirmed | `ioc-runner -V` reports 1.4.1 (cf5cecc) on both; CHANGELOG 1.4.1 section present |
| Release Verification 7 | Not run | GitHub | Pending | none |
| Release Verification 8 | Not run | GitHub | Pending | none |
| Release Verification 9 | 2026-09-19 | rocky8 + debian13 goldens | Pass | run-all VERDICT RUN PASS, 14/14 scenarios both hosts, all P-* PASS |

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
