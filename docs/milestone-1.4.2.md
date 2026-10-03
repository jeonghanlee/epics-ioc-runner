# Work Register

Release line: 1.4.2
Milestone index: 1.4.2
Canonical path: `docs/milestone-1.4.2.md`
Canonical branch or ref: `release-1.4.2`
Git upstream: `origin/release-1.4.2` (observed 2026-09-24; recheck with `git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'`)
Remote tracker: `jeonghanlee/epics-ioc-runner`; GitHub milestone `1.4.2` (19); issues #157 through #162 are closed under it

Next session entry point: M1 through M7 and M9 are Complete, and #157 through #162 are closed. M8, the documentation revision under D12 and D13, lands in 1.4.2; its plan was accepted and implementation authorized on 2026-09-28, and the work is in progress. Its glossary, book groups, and heading changes are implemented. The incremental T4 updates account for all 352 entries as covered, with no partial or missing entry. Historical T1, T2, and T4 passes are recorded for 2026-09-29 after the diagnostic and lifecycle additions; same-run evidence linkage for the historical T1/T2 rows is unconfirmed. The available 2026-10-01 build/link evidence is preserved in its own run directory. The revised remaining-verification plan is accepted and separately authorized on 2026-10-01; execute its five steps before closing T3, T5, and T6; the Debian container lifecycle suite passed 64 assertions and thirteen targeted local CLI calls matched their documented errors, but these do not verify every book command. Dedicated Debian 13 and Rocky 8 VMs completed local and system IOC lifecycles, infrastructure removal, and subsequent full setup against `c558513`; this is partial T3 evidence. Subsequent checks covered real PTY consoles, manual infrastructure and CLI deployment, completion, NFS checkout staging, a temporary NFS IOC payload mount, and configuration/environment examples. Whole-book second-person reading and the accepted INSTALL corrections are recorded; subsequent INSTALL reviews found no additional actionable finding. The plan-by-plan whole-book review found two accepted corrections, committed as `ecde536`: sudo glob authorization warnings and consolidated permission references. The corrected five-file set passed a subsequent second-person review, build, and link scan. Subsequent whole-book reviews found an obsolete heading reference, four missing glossary terms, and an inaccurate FAQ statement about runtime-only changes. These findings were committed in `87aa67c`. The fifth whole-book review found a removal-verification conflict and an incorrect local primary-group assumption. Both corrections are applied, and the two-file set passed its first second-person review. Dedicated Debian 13 and Rocky 8 VMs then passed actual local primary-group checks and document-derived removal/preservation checks, followed by successful system setup restoration. The accepted CLI target-name clarification is also applied. Selected manual account/group creation and fstab mount-by-target verification are complete within their recorded boundaries. The latest 2026-10-01 source refresh matches all 2163 inline spans and 108 fenced blocks to native HTML; statement classification and evidence comparisons remain pending. The five-step plan in the M8 detail was accepted and separately authorized on 2026-10-01. The selected minimal CLI option-restriction correction is applied; eight real source CLI cases match it in `work/m8-verification-runs/20261001T213618Z-87aa67c-cli-order-corrected-source-check/`. Installed-runner and full-claim comparisons remain Pending. The three option-restriction bullets have six scoped semantic rows in `work/m8-verification-runs/20261001T215805Z-87aa67c-option-restriction-comparisons/claims.jsonl`: 524 installed-runner cases match on both dedicated hosts, while successful target paths and five container comparisons remain pending. The subsequent 48 successful-target status/view calls on both hosts and 133 root/live-s6 container restriction cases are recorded in `work/m8-verification-runs/20261001T233721Z-87aa67c-target-option-comparisons/`: four restriction rows are Verified and force/count behavior remains Partial for other successful targets. The original incorrect system fixture selection is retained with recovery evidence. The next 240 installed host command-option cases and 72 installed container cases passed, with a 64-assertion shipped container fixture suite, in `work/m8-verification-runs/20261001T235704Z-87aa67c-command-option-comparisons/`. All twelve other commands now have selected normal-path force/count comparisons across the five mode/OS environments; broad R05/R06 remain Partial for unselected failure and fallback paths. The stdout-wrapper failure and all original evidence are preserved, and readable container copies have matching hashes. The next host console batch passed 96 frozen calls through real socat and unavailable-client paths on Debian 13/Rocky 8 in local/system mode; its 16 scoped comparisons are recorded in `work/m8-verification-runs/20261002T001723Z-87aa67c-console-paths-comparisons/`. Actual client arguments/exits, terminal settings, native supervisor/child/socket continuity, fixture/client fingerprints, inactive states, and original log prefixes were checked. Container fallback and unselected failure cases remain pending; broad R05/R06 remain Partial. The subsequent container batch passed all 24 frozen socat/no-client calls without added capabilities, using Docker read-only client masks and the original shipped-suite fixture; its four scoped comparisons are in `work/m8-verification-runs/20261002T015411Z-87aa67c-container-console-comparisons/`. Combined with the preceding 96 host cases, both selected console paths are verified in all five mode/OS domains. Original failed preflight/state-read evidence is retained; container absence, original file bytes, native client exits, terminal restoration, and supervisor/child/socket continuity were checked. Other failure paths and whole-book comparisons remain incomplete; broad R05/R06 remain Partial. The next missing-configuration batch verified 35 calls for seven commands in the five mode/OS domains, with complete output/exit comparisons and unchanged native state, in work/m8-verification-runs/20261002T022108Z-87aa67c-missing-config-comparisons/. Source statement counts and broader command coverage remain unchanged. Current semantic progress is in work/m8-verification-runs/20261002T023624Z-87aa67c-cli-semantics-evidence/: CLI lines 1-77 cover 44 original candidates split into 171 predicates, with 62 Verified, 24 Partial, and 85 Pending rows after independently rereading 615 unique original native case entries. Outside that prefix, 1474 original Pending candidates still require semantic decomposition. The three actual list traces in work/m8-verification-runs/20261002T025035Z-87aa67c-list-trace-comparison/ establish a Mismatch in the unqualified zero-per-IOC-subprocess explanation. Option 1 was accepted on 2026-10-01 and applied. The restored candidate in work/m8-verification-runs/20261002T034039Z-87aa67c-source-refresh/ builds without warnings and matches 2165 inline spans and 108 fences; its refreshed baseline is 293 structural/1513 Pending candidates. Its sibling CLI-prefix evidence rebind retains 62 Verified, 24 Partial, and 85 Pending predicates after native evidence rechecks. The three fresh installed calls in work/m8-verification-runs/20261002T034053Z-87aa67c-list-correction-comparison/ verify the selected container state/PID correction; its sixteen scoped rows are two Verified, five Partial, and nine Pending. The generate section at CLI lines 79-118 is independently decomposed into 52 predicates, with current comparisons in work/m8-verification-runs/20261002T040530Z-87aa67c-generate-native-comparison/: six Verified (including four non-executable source comparisons), 25 Partial, 20 Pending, and one Mismatch. Thirteen selected container-root calls, five preparatory calls, and one additional non-setgid group case ran through the installed CLI with the original shipped fixture. The unqualified directory-group sentence fails: a root:ioc 0755 directory yields a root-group configuration when root generates it. Option 1 was accepted on 2026-10-01 and applied exactly, qualifying directory-group inheritance with setgid. The refreshed snapshot in work/m8-verification-runs/20261002T043018Z-87aa67c-source-refresh/ builds without warnings and matches 2165 inline spans and 108 fences. Its baseline has 293 structural and 1514 Pending candidates. CLI-prefix evidence remains 62 Verified, 24 Partial, and 85 Pending after original-native rechecks. Two fresh installed generate calls confirm group ioc in root:ioc 2775 and group root in root:ioc 0755; the latter is outside the conditional promise. The current source-bound generate comparison in work/m8-verification-runs/20261002T043228Z-87aa67c-generate-ownership-2775-comparison/ has six Verified, 26 Partial, 20 Pending, and zero Mismatch rows. The shifted list overlay is rebound to lines 409-427 after native evidence checks with no new list execution. The next install batch in work/m8-verification-runs/20261002T050445Z-87aa67c-install-native/ runs twenty selected root/container calls: five successes and fifteen expected aborts, with output, installed attributes, native inactive s6 services and restoration comparisons. The corrected install worksheet covers 53 source candidates and 74 predicates; its source-bound comparison has eight Verified (five non-executable), 35 Partial, and 31 Pending rows. Host/local-asset paths and unselected failures remain incomplete. The remove section at CLI lines 199-224 has 31 source-bound predicates: five Verified, twelve Partial and fourteen Pending. Six selected container calls match their expected exits; a separate active supplement verifies real softIOC child, procServ and supervisor removal after readiness. Current mode/OS cases are fourteen Verified, two Partial and 97 Pending. The initial Partial active execution and two aborted readiness runs remain immutable. The start/restart section at CLI lines 226-276 has 51 predicates: 29 Verified (three non-executable), three Partial and 19 Pending. Its 260 mode/OS/action cases are 106 Verified, two Partial and 152 Pending. The 60-call failure supplement and seven additional installed parse-error calls match their expected outputs and exits. The additional seven calls verify the fatal clause with native parser messages absent from the startup commands. The original seven echo-only observations retain Partial in their immutable comparison. Original incomplete runs and failed supplement preconditions remain preserved with their recorded restoration limits. The stop/enable/disable section at CLI lines 278-291 has 11 predicates: nine Verified (two non-executable) and two Partial. Its 90 mode/OS/action cases are 72 Verified and 18 Partial. Forty installed host calls and twelve fresh container calls match all expected outputs, exits and states. Actual reboot/startup and host stop/disable nonzero paths remain incomplete. The accepted status example correction is applied and verified by one fresh installed container query plus rechecks of the original 27 status calls. The status section at CLI lines 293-300 has 11 Verified predicates (one non-executable), and all 29 mode/OS comparisons are Verified within their selected-state limits. The original Mismatch remains historical. Both host system observers outside ioc query without sudo. The current source snapshot is work/m8-verification-runs/20261002T231334Z-87aa67c-source-refresh/, with unchanged 2165 inline spans and 108 fences matching native HTML. Current source bindings for prefix, generate, install, remove, start/restart, controls, list overlay and status are in work/m8-verification-runs/20261002T232051Z-87aa67c-status-example-comparison/; unchanged predicates retain their earlier verdicts and native provenance. The view section at CLI lines 302-311 has eleven Verified predicates (one non-executable) and 28 Verified mode/OS comparisons within the selected states. Its 20 fresh installed queries match complete configuration and native unit/run bytes, section order, exits and preserved state/PIDs; five missing-configuration exits of 1 are expected. Current view comparisons are in work/m8-verification-runs/20261002T235032Z-87aa67c-view-comparison/. Continue log at CLI line 313, list and option/environment cases, and unresolved generate/install/remove/start/restart/control cases. There are 1357 provisional Pending candidates outside the classified prefix, generate, install, remove, start/restart, control, status and view sections; preserve the separate list overlay and all original/superseded records. The original worksheet remains the immutable 293 structural/1511 Pending historical baseline. Reconcile the 2110 lexical source-surface candidates before step 2 evidence comparison and final candidate checks; T3, T5, and T6 remain Pending. Preserve the dedicated VMs and their evidence. M10, the help, completion, and message corrections that the M8 inventory found, lands in 1.4.2; issue #163 is recorded; its implementation plan remains a draft to be written and accepted. Then open the 1.4.2 release through release-cycle once G2, an iocrunner production bake carrying `opc` requested from cloud-provision, is Complete: run the release Gate on fresh consumers from that bake against one unchanged candidate, and carry the D8 upgrade actions into the 1.4.2 release notes and CHANGELOG. The two reused test consumers hold payload directories from the M9 runs, to be cleared before their next scenario-driver run, and cloud-provision is to be told when they are no longer needed. Preserve the committed version, console behavior, and production-validation documentation.

The initial detach implementation is commit `1bb270f45192763eb9db799bbf8a9b97901c803f`:
`con` and `socat` use Ctrl-A by default, `--detach-key` selects a key per
connection, and `nc` is excluded from `attach`. The same commit updates the
console documentation and resolves the runner and completion ShellCheck
diagnostics. Commit `b8d65c3` sets the development version to `1.4.2-dev`.
Commit `2fa6b55` removes nc from monitor, corrects con read-only option
detection, and documents socat's production validation limits. These changes
are committed on `release-1.4.2`; they are not remaining implementation work.

This register tracks the remaining durable verification and documentation
work. It does not treat the existing implementation as completed acceptance
evidence. The released 1.4.1 record remains in `docs/milestone-1.4.1.md`.

## Milestone

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Console | M1 | Verify console detach keys and align documentation (#157) | Milestone | Complete | — | D1, D2, D3, D4, D5 | Real con/socat default and custom-key attach cases and monitor exit-key cases pass; nc exclusion, input handling, banners, and guides agree; socat production validation limits are explicit; [detail](#m1---verify-console-detach-keys-and-align-documentation) |
| Reporting | M2 | Keep multi-line check values out of FAIL reasons (#159) | Milestone | Complete | — | none | A multi-line mismatch is recorded as FAIL with a one-line escaped reason, the suite continues, and the human report keeps the full values; [detail](#m2---keep-multi-line-check-values-out-of-fail-reasons) |
| Reporting | M3 | Refresh the reporting self-test's stale expectations (#158) | Milestone | Complete | — | none | The reporting self-test passes, its two expectations derive from their sources, and the gate matrix runs all three self-tests; [detail](#m3---refresh-the-reporting-self-tests-stale-expectations) |
| Console | M4 | Reject ctrl-[ as a detach key (#160) | Milestone | Complete | — | D2 | `--detach-key ctrl-[` fails before connection, the documented key list omits it, and the S41 catalog proves the rejection; [detail](#m4---reject-ctrl--as-a-detach-key) |
| Console | M5 | State how each console client handles a pasted detach key | Milestone | Complete | — | none | The attach banner and the three console documents no longer claim the key never reaches the IOC, and state the con and socat difference for pasted text; [detail](#m5---state-how-each-console-client-handles-a-pasted-detach-key) |
| Generate | M6 | Rewrite an identical configuration regardless of its owner (#161) | Milestone | Complete | — | D10, D11 | Any group member regenerates an identical existing configuration without a `chmod` failure, a transfer from another owner asks first unless `-f` is given, the file carries the target mode afterwards, the S04 checks pin the rewrite, and a system-lifecycle check regenerates as a second operator; [detail](#m6---rewrite-an-identical-configuration-regardless-of-its-owner) |
| Console | M7 | Document iocsh history ownership across principals (#162) | Milestone | Complete | — | D9 | FAQ Q13 states the verified ownership behavior and the per-principal settings, Q5 points to it, and CLOSED_DOORS carries CI-44; [detail](#m7---document-iocsh-history-ownership-across-principals) |
| Documentation | M8 | Revise and supplement the published documentation against the current code | Milestone | In progress | No | M6, D12, D13, D14 | Every page of the mdBook site is revised and supplemented against the current runner, setup script, and templates for the operator who installs and runs IOCs, and every command and output it shows is checked against a real run; [detail](#m8---revise-and-supplement-the-published-documentation-against-the-current-code) |
| Gate | M9 | Extend the multi-user gate to the 1.4.1 and 1.4.2 changes | Milestone | Complete | — | G1 | Every user-visible 1.4.1 and 1.4.2 change that differs between principals has a multi-user scenario with a stated expected result, and the complete multi-user driver passes on both test consumers; [detail](#m9---extend-the-multi-user-gate-to-the-141-and-142-changes) |
| Command line | M10 | Correct the command-line help, completion, and mode-specific messages (#163) | Milestone | Not started | Yes | none | Completion offers `log`, `-n`, and `--lines`; the usage names `--lines`; container mode prints mode-correct identity and `inspect` messages; setup `--help` works for a non-root user; a failed logrotate validation states that setup stops; the `IOC_RUNNER_SCAN_DIR` forwarding question is settled; [detail](#m10---correct-the-command-line-help-completion-and-mode-specific-messages) |
| Gate | G1 | Test fixture account `opc` in `ioc` with linger | External gate | Complete | — | none | The `testusers` role of ansible-provision creates `opc` in the `ioc` group with systemd linger, and both test consumers carry it; [detail](#g1---test-fixture-account-opc-in-ioc-with-linger) |
| Gate | G2 | iocrunner bake carrying `opc` | External gate | Open | No | G1 | cloud-provision reports an iocrunner bake made at ansible-provision `32ea95f` or later, from which the 1.4.2 release Gate creates its fresh consumers; [detail](#g2---iocrunner-bake-carrying-opc) |

### Decisions

| ID | Decision | Decision Date |
| --- | --- | --- |
| D1 | Continue the implemented console changes on `release-1.4.2`, opened from the updated master, using development version `1.4.2-dev`. | 2026-09-22 |
| D2 | Keep Ctrl-A as the default for both con and socat, and retain the per-connection `--detach-key` option. Verify both clients with their default and custom keys. | 2026-09-22 |
| D3 | Exclude nc from both attach and monitor. Use con or socat only; fail with an installation hint when neither suitable client is available. Monitor requires con with -r or socat. | 2026-09-22 |
| D4 | Prefer con for production console access. Support socat for ordinary use while explicitly documenting that production workloads with sustained heavy or burst IOC output have not been validated. Production load testing is outside this change. | 2026-09-22 |
| D5 | Exclude Python from the new test implementation and its dependencies. Use Bash and util-linux for the PTY procedure; discuss additional tools separately before adding them. | 2026-09-24 |
| D6 | Exclude old con without read-only support from the remaining verification. T6 covers only rejection without con or socat (D7), and T12 covers only the direct socat path; the old-con fallback cases in the T6 and T12 rows, the Scope clause on con without -r, and the Completion Criteria sentence on con lacking -r are withdrawn. The runner's fallback code is unchanged. | 2026-09-24 |
| D7 | Add no nc-specific checks. The runner has no nc path after D3, so the nc-only cases in T6, the Scope clause on nc-only rejection, and the Completion Criteria sentence on an nc-only environment are withdrawn. S42 verifies rejection without con or socat; other host tools, including any nc, stay visible to the runner. | 2026-09-24 |
| D8 | Set the procServ ignore set to `^D^C` in the system unit, local unit, and container run script. procServ converts `^` only before `A` through `Z`, so `^]` dropped the printable `^` and `]` from console input and let `Ctrl-]` through. The supported clients use no telnet escape, so `Ctrl-]` is forwarded like any other byte. This product fix is within M1 because the console input documentation depends on it. `source-regression.S16.unit.ignore-set` pins the value in both unit templates. The 1.4.2 release notes must state the upgrade actions: rerun system setup, reinstall local IOCs with `--force` because a non-forced install keeps a differing user template, reinstall container IOCs to re-render the run script, and restart running IOCs so procServ receives the new argument. | 2026-09-24 |
| D9 | Leave the iocsh history file where iocsh puts it: the runner sets no `EPICS_IOCSH_HISTFILE` and does not manage the ownership of `.iocsh_history`. Each principal switch in a shared IOC directory costs one benign loading error and a history restart, because readline saves the file as a fresh 0600 owned by the running principal; the runner documents this in FAQ Q13 with the per-principal `EPICS_IOCSH_HISTFILE` settings a site can adopt, and records the examined Keep as CLOSED_DOORS CI-44. | 2026-09-25 |
| D10 | When `generate` finds an identical existing configuration, rewrite it through the staged temporary file and rename, as the differing-content path does, instead of skipping the write and reasserting the mode with `chmod`. A rename needs only directory write permission, so any `ioc` group member corrects the mode, and a file whose creator's account no longer exists is taken over instead of left unfixable by anyone but root. The identical case still asks no overwrite question. | 2026-09-26 |
| D11 | Supersede D10's last sentence. Rewriting identical content transfers the file to the invoking user, so `generate` asks before that transfer: identical content owned by the invoking user is rewritten without a question; identical content owned by another user is rewritten only after a y/N question that names the current owner, bypassed by `-f`, with a closed standard input or a refusal exiting 1 and leaving the file unchanged; differing content keeps its diff and y/N question. `docs/CLI_REFERENCE.md` gains a `generate` section stating these cases. | 2026-09-26 |
| D12 | Supersede the 2026-09-26 direction to rewrite the published documentation without regard to the previous pages. M8 revises and supplements the existing pages against the current code instead: the pages were first written between 2026-03 and 2026-09 and ten of the twelve last changed in 2026-09 alongside the code, so their faults are organization and coverage rather than drift. Revision may split, merge, or move sections between pages; every command, option, path, and output a page shows is still checked against the current code and a real run. | 2026-09-28 |
| D13 | M8 keeps the twelve published pages and their file names, and adds one glossary page. Sections that mix page types are split or moved between the existing pages, steps repeated between the system and local guides are kept in one place, and `CLI_REFERENCE.md` covers every command and option; in-repository links to a changed heading are updated. The book introduction drops the 1.0.x upgrade section, the release runbook entry, and the milestone register entries; the upgrade steps move into the 1.1.0 Migration section of `CHANGELOG.md`, which points to them. Design rationale that follows from the code stays in the concept pages. | 2026-09-28 |
| D14 | Narrow D13 on mixed sections: the Manual Setup Reference section of `INSTALL.md` and the Verification section of `PERMISSION_MODEL.md` stay on their pages as their own headed sections, because each checks the subject of its page directly (the setup script, the permission model). The troubleshooting table of `LOG_LAYOUT.md` is the section that moves. | 2026-09-28 |

### Assignment History

| Work Identity | From Canonical | To Canonical | Target Commit | Authority Moved At |
| --- | --- | --- | --- | --- |
| 1.4.2 / M3 | 1.4.2 Backlog, `docs/milestone-1.4.2.md`, `release-1.4.2` | 1.4.2 Milestone, `docs/milestone-1.4.2.md`, `release-1.4.2` | this synchronization commit | this synchronization commit |

### Milestone Details

#### M1 - Verify console detach keys and align documentation

Origin: 1.4.2 / M1
Identity History: none
GitHub Issue: #157, https://github.com/jeonghanlee/epics-ioc-runner/issues/157
Status: Complete

##### Summary

Establish repeatable acceptance evidence for the implemented detach behavior
and make every console instruction agree with the observed client behavior.
The `test_console_attach` functions in the local and system lifecycle suites
retain their socket checks and invoke the shared Bash PTY helper. Verification
results below distinguish executed cases from pending acceptance evidence.

##### Scope

- Exercise the shipped runner, real con or socat, real procServ, and a real IOC
  through a PTY in the local and system lifecycle suites. Respect the suite's
  selected source or installed runner.
- Cover four required combinations: con/default Ctrl-A, socat/default Ctrl-A,
  con/custom key, and socat/custom key. Use `ctrl-]` as the documented custom
  example and also `ctrl-b` to cover a key outside procServ's ignore list.
- Verify the selected client and key in the banner, client exit, terminal
  restoration, IOC continuity, socket continuity, and reconnectability.
- Verify that the detach key is consumed by the client; distinguish this from
  procServ discarding Ctrl-C and Ctrl-D (D8). Include the default Ctrl-A
  line-editing limitation in the documentation.
- Verify the committed nc exclusion from console selection and execution. Cover
  nc-only rejection for attach and monitor (withdrawn by D7), including con
  without -r when socat is unavailable (withdrawn by D6). Verify monitor's read-only behavior
  and actual key-driven exit through con with Ctrl-A and socat with Ctrl-C,
  including terminal restoration, IOC continuity, socket continuity, and
  reconnectability.
- Verify CLI option validation and completion.
- Document socat's unverified production behavior under sustained heavy and
  burst IOC output; ordinary-use support is not production load evidence.
- Review and update `README.md`, `docs/CLI_REFERENCE.md`,
  `docs/USER_GUIDE.md`, `docs/USER_GUIDE_LOCAL.md`, `docs/ARCHITECTURE.md`,
  CLI help, and attach banners where needed against the executed cases.
  Preserve already-correct text.
- Maintain the affected test catalogs, `tests/reporting-counts.csv`, and test
  documentation under `tests/REPORTING_CONTRACT.md`.

Out of scope: changing the default key, adding an nc path, changing monitor's
read-only behavior or exit keys, persistent per-user key configuration,
scrollback support, unrelated ShellCheck cleanup, production load testing,
release publication, and production deployment.

##### Completion Criteria

- All four required client/key combinations have separate, passing checks in
  shipped tests, with the actual runner and client identities recorded.
- Each successful detach ends only the client. The original procServ PID and
  IOC child PID remain alive, the unit remains active, the original socket
  remains available, and a fresh attachment can execute an IOC shell command.
- The terminal settings after detach match those captured before attachment.
- A custom-key connection does not change the default of the next connection.
  Under a custom key, Ctrl-A is available to the IOC line editor again.
- Ordinary IOC input reaches the IOC; the selected detach byte does not reach
  procServ. Ctrl-C and Ctrl-D remain ignored by procServ when neither is the
  selected detach key. Silence alone is not evidence of where a byte stopped.
- With no con or socat available, both attach and monitor reject the
  environment with the documented installation hint. The nc-only environment
  and its nc-selection sentence are withdrawn by D7.
  Monitor also fails when con lacks -r and socat is unavailable (withdrawn by D6).
- Separate shipped monitor checks receive actual IOC output and confirm that
  terminal input does not reach the IOC. Con exits on Ctrl-A and socat on
  Ctrl-C without external termination. Each exit restores terminal settings,
  preserves the original procServ/IOC PIDs, active unit, and socket, and allows
  a fresh attachment to execute an IOC shell command. Timeout or forced cleanup
  is a failure, not evidence that an exit key works.
- The guides list only con and socat as supported console clients, prefer con
  for production, and explicitly state that socat has not been validated for
  production workloads with sustained heavy or burst IOC output.
- Help, banners, examples, accepted key syntax, and input explanations agree
  with the real test results. Direct `con -c` examples retain default Ctrl-A.
- Required checks do not report success on missing prerequisites, timeouts,
  or forced cleanup. Catalog and result records account for every case.

##### Dependencies And Decisions

- D1-D4 define the release line, key behavior, supported console clients, and
  production validation limits.
- D5 excludes Python from the new tests. The CLI checks use Bash; the PTY
  helper uses Bash, util-linux, and existing system utilities. No additional
  package is authorized or installed for these checks. Byte-flow tracing still
  needs a method decision; bubblewrap and strace are not dependencies.
- Completed implementation: initial detach support in `1bb270f`, development
  version in `b8d65c3`, and nc exclusion, monitor detection, and related user
  documentation in `2fa6b55`. These are not requests to reimplement those changes.
- Documentation verification uses the executed banner and input results.
- The original #157 body excluded configurable keys and nc changes; D2-D3
  extended that scope. The body was later rewritten from this detail, the issue
  moved to GitHub milestone `1.4.2`, and it closed as recorded in Closure
  Evidence.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-24, including the monitor exit-key checks and separation of committed implementation from remaining verification.
Implementation Authorization: 2026-09-24 for the accepted durable-test and documentation plan, constrained by D5 to exclude Python. The proposed bubblewrap and strace test dependencies await a separate decision; existing Bash-only checks can proceed. Full candidate setup and Check-grade six-suite verification on both test consumers were authorized on 2026-09-24.
Superseded Plan Artifacts: none

1. Add a shared Bash-based PTY test helper under `tests/lib/`, without Python,
   and real attach detach-key
   and monitor exit-key checks to
   `tests/test-local-lifecycle.bash` and `tests/test-system-lifecycle.bash`.
   Wait for an observed ready IOC connection before sending each key; capture
   exit status, terminal attributes, procServ/IOC PIDs, unit state, socket
   identity, and a command result after reconnection.
2. Select the real client through an isolated outer filesystem/PATH boundary.
   The socat case must make the runner's fixed con search paths unavailable,
   not merely change PATH. Do not replace `do_attach`, `resolve_con_tool`,
   procServ, or the IOC with an internal mock or a reconstructed implementation.
3. Add CLI rejection and completion cases to `tests/test-error-handling.bash`.
   Cover missing and invalid values, reserved Ctrl-T, a non-attach command,
   case-insensitive names, and the documented backslash quoting.
4. Compare the committed console documentation with the new results: nc
   exclusion, socat's production validation limit, client-consumed versus
   procServ-ignored keys, and monitor exit keys. Preserve correct text and
   update the test guide with the shipped checks. The nc removal and monitor
   option detection fix are complete in `2fa6b55`; verify them rather than
   reimplementing them. Perform a second-person read of any changed guidance.
5. Register every added check before execution and reconcile the affected
   catalog counts. If the release suite matrix's identity hash changes,
   follow `gate/RUNBOOK.md`'s check-identity repin procedure; never invent the
   new hash or copy it from a failing run.
6. Run the checks below and record their actual environments and evidence.
   Resolve any confirmed defect within this scope before acceptance.

##### Test Plan

For T1-T4, invoke `ioc-runner attach` in a PTY against the suite's real
procServ/IOC fixture. Required observations are the named client and key,
successful client exit without external termination, restored terminal state,
unchanged live procServ/IOC PIDs, active unit, retained socket, and successful
IOC command execution after reconnecting. A timeout is a failure followed by
cleanup, not a successful detach.

For T11-T12, invoke `ioc-runner monitor` through a PTY against the same real
procServ/IOC fixtures and selected runner origins as T1-T4. Observe IOC output
before sending input and the exit key. Confirm read-only input handling and
record the actual client, exit key, and resulting exit status. Con exits with
Ctrl-A; socat exits with Ctrl-C. Require restored terminal settings, unchanged
live procServ/IOC PIDs, active unit, retained socket, and a successful IOC shell
command through a fresh attachment. A key-driven socat SIGINT exit is distinct
from timeout or cleanup termination; external termination never satisfies
these checks. The `--detach-key` option remains attach-only.

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | lifecycle-behavior | Attach through real con without `--detach-key`; send Ctrl-A | Local and system suites; selected source/installed runner | Common detach observations pass with default Ctrl-A |
| T2 | lifecycle-behavior | Make con unavailable, attach through real socat without `--detach-key`; send Ctrl-A | Same fixture and runner origins as T1 | Common detach observations pass with default Ctrl-A |
| T3 | lifecycle-behavior | Attach through con with `--detach-key ctrl-]` and separately `--detach-key ctrl-b`; send each selected key | Same fixture and runner origins as T1 | Both custom keys satisfy the common detach observations |
| T4 | lifecycle-behavior | Repeat T3 through socat selected by the real fallback path | Same fixture and runner origins as T2 | Both custom keys satisfy the common detach observations |
| T5 | lifecycle-behavior | Trace actual client-to-procServ and procServ-to-IOC bytes while sending ordinary input and control keys; verify Ctrl-A line editing under a custom key and reconnect without the option | Real PTY, client, procServ, and IOC; trace only the actual transport boundary | Selected detach byte stops at the client; ignored bytes stop at procServ; ordinary input and restored Ctrl-A editing work; next default is Ctrl-A |
| T6 | client selection and error-contract | Invoke shipped attach and monitor with only real nc visible and with no clients; also monitor with real con lacking -r, with and without socat, using executable paths both containing and excluding -r | Isolated executable search paths; real procServ/IOC for successful monitor connections | No nc selection; suitable installation hint when no supported client is available; old con selects socat regardless of executable path |
| T7 | error-contract | Execute shipped CLI with valid and invalid option forms; source the shipped completion handler | Error-handling suite | Accepted names and quoting work; invalid/reserved/missing/non-attach values fail before connection; completion offers the option and keys |
| T8 | documentation | Follow every changed attach example and compare help, banner, and guide claims with T1-T7; compare monitor instructions with T11-T12; inspect direct-con examples separately | Source docs and corresponding executed output | Default/custom keys, con/socat-only selection, monitor exit keys, ignored input, IOC continuity, and socat's unverified production load behavior are explained consistently |
| T9 | lifecycle-behavior | Run T2's real-path scenario against the pre-fix runner from commit `48b7ed9` with identical client and IOC fixtures | Isolated historical runner fixture; bounded wait and cleanup | Ctrl-A fails to detach the old socat path, while T2 passes on the candidate; proves the regression detects the original defect |
| T10 | regression and reporting | Run Bash syntax checks, ShellCheck, the full error suite, affected lifecycle suites, and reporting validation | Supported suite environments under `tests/README.md` | Required checks pass with complete catalogs and consistent counts; no internal mocks stand in for the detach path |
| T11 | lifecycle-behavior | Monitor through real con with -r in a PTY; observe IOC output, check input isolation, and send Ctrl-A | Local and system suites; selected source/installed runner; real procServ/IOC | Common monitor observations pass; Ctrl-A ends only the client |
| T12 | lifecycle-behavior | Make con unavailable, monitor through real socat in a PTY; observe IOC output, check input isolation, and send Ctrl-C; repeat through T6's old-con fallback | Same fixtures and runner origins as T11 | Common monitor observations pass on direct and old-con fallback paths; Ctrl-C ends only the client |

##### Verification Results

Targeted checks on 2026-09-22 against the working tree based on `1bb270f`:

- `bash tests/test-error-handling.bash`: 199 assertions passed, with no
  failures, skips, not-applicable results, or script errors.
- `bash -n bin/ioc-runner`, plain ShellCheck, and its warning gate passed.
- The shipped runner rejected both attach and monitor in isolated nc-only
  and no-client environments, returning exit 1 and the installation hint.
- Against real procServ and softIoc 7.0.10 in a temporary local user service,
  real con and socat monitor sessions received console output and exited with
  their documented keys. Terminal settings were restored, and the original
  procServ PID, IOC PID, active unit, and socket remained available.
- Real con from before read-only support (`8e2ec7f^` in the con repository)
  selected socat when available. Without socat, monitor returned exit 1 and an
  installation hint despite nc being available. The IOC remained running.

These targeted checks are not production load tests or release Gate evidence.
The retained local monitor procedure is
`/tmp/ioc-nc-removal-9to66vbb/verify_monitor.py`; its adjacent logs and
`/tmp/ioc-nc-removal-errors.log` are temporary execution evidence.

Targeted follow-up on 2026-09-23: monitor detects the read-only option only
on a help option-definition line. With the same real procServ/softIoc fixture,
six cases passed: current con, direct socat, and old con with and without
socat at each of two executable paths (one containing `-r`, one without it).
Successful sessions detached with the documented key and restored terminal
settings; all cases preserved the original procServ/IOC PIDs, active unit,
and socket. Before the fix, the old con path containing `-r` produced
`Invalid switch "r"` even with socat available; that case now selects socat.
Bash syntax, both ShellCheck commands, and the full error suite passed
(199 assertions, no failures or skips). The local reproduction procedure
and logs are under `/tmp/iocmonitorfixknrhhb0z`; the error-suite log is
`/tmp/ioc-monitor-option-fix-errors.log`. These are targeted checks, not
completed shipped regression coverage or production load evidence.

The rows below distinguish executed shipped checks from pending checks.
Existing code, earlier exploratory runs, and an open or closed issue do not
fill a pending row.

CLI verification observed at 2026-09-24T08:06:50Z on the development host
(Debian 13, x86_64), using the working tree based on `74c8b28`:

- `REPORT_MACHINE_OUTPUT=1 bash tests/test-error-handling.bash` exited 0:
  246 PASS, including all 47 S41 checks, with no FAIL, SKIP, NA, or
  SCRIPT_ERROR results. The suite reports its host label as `os=host`.
- The shipped `test_record_validate_file` accepted the captured records with
  producer exit status 0. Records: `/tmp/ioc-console-error-tests.records`;
  human report: `/tmp/ioc-console-error-tests.log`. These are temporary local
  evidence, not release Gate evidence. The records SHA-256 is
  `7b56e3b1dba5b94bbbdcb19712a747bdd5244b940226cb3c205486e310d64cfa`.
- Bash syntax checks passed for the error suite and its new
  `tests/lib/test-console-options.bash` helper. Plain ShellCheck passed for
  the helper; the error suite passed the warning gate. Its existing
  informational diagnostics remain.
- Valid detach names are verified through the real CLI up to an unavailable
  client path. These checks establish option parsing, not actual detach.
- The error catalog contains 246 checks and 42 steps. The complete matrix
  and identity repin results are recorded below.

Cross-platform source verification observed at 2026-09-24T09:01:23Z:

- The shipped transfer driver copied the same candidate to separate test
  paths on the reused Debian 13 and Rocky 8.10 consumers and confirmed that
  source and remote Git status matched. The existing checkouts were preserved.
- Each consumer ran the shipped source error suite: 246 PASS, including all
  47 S41 checks, exit 0, and no FAIL, SKIP, NA, or SCRIPT_ERROR results. The
  shipped machine-record validator accepted both captured reports.
- Local records are `work/console-matrix-debian-error.records` (SHA-256
  `52928be1ebc1cf9c0e4f314058aab4db166d5b27dbb7c131f0752aa68a453d26`)
  and `work/console-matrix-rocky-error.records` (SHA-256
  `0d3a9e5a5afbff655db1edd5c52e451f59d282ab3d454f8a88cf0dfc186d1153`).
  The adjacent `.log` files contain the human reports.
- This is Check-grade source-only evidence. The subsequent full deployment
  and matrix results are recorded below.

Complete suite matrix verification observed at 2026-09-24T15:32:17Z:

- Grade: Check. The Debian 13 and Rocky 8.10 consumers were reused, the
  candidate was the uncommitted tree based on `74c8b28`, and only the
  six-suite matrix ran. This is not release Gate or production load evidence.
- The shipped transfer driver confirmed matching source and remote status.
  Full setup passed 9/9 deployment checks on Debian and 12/12 on Rocky.
  Both installed runners reported `1.4.2-dev (74c8b28-dirty)`; the matrix
  verified that source and installed runner bodies matched.
- The initial complete run, retained under
  `work/gate-suites-20260924T151655Z-1386236`, had six successful suite
  producers per host and no FAIL, SKIP, or SCRIPT_ERROR. Its only failing
  verdict was the expected check-list identity mismatch. Both host verdicts
  reported `1a5094c6d166182cac702280379d24988044b90ffd8eb39507297c4b5b3808ff`.
  That observed value is now `EXPECTED_IDENTITY_SHA256` in
  `gate/drivers/control/suites.bash`.
- After redeployment, the unchanged candidate passed the complete shipped
  control driver again. Both host verdicts were exit 0 and `SUITES OK`
  with six blocks and 992 checks; the driver exited 0 with
  `GATE SUITES PASS`. That driver message does not change the Check grade.
  Evidence is under `work/gate-suites-20260924T152508Z-1413892`; the control
  transcript is `work/console-matrix-repin.log`.
- Each per-suite `.machine` and `.human` file passed the driver's transfer
  hash and ownership checks; every machine block passed the shipped record
  validator. The combined Debian machine-record SHA-256 is
  `25831a1be0b2d0caf8335c29dadc4aec8493f32c620b0c3ec9460a987f5f1cfb`;
  Rocky's is
  `fb46b56269d6595d4961a7898eb2dd5e4b3a6b9c4e6cdde482ea327d2f94c55e`.
- Every difference in `cross-host.diff` was examined. Debian excludes one
  RHEL-only symlink check and four inactive-SELinux checks. Rocky excludes
  four user-journal checks in each local lifecycle run and four regex-only
  sudoers checks because its deployed policy uses the supported glob form.
  These account for all 5 Debian and 12 Rocky NA results; no other result
  differs. The diff SHA-256 is
  `c760a01b5eabfd3398007e379034b0fb5f036d4dd4f336cf19ca34c54cd3b739`.
- Full setup logs are `work/console-matrix-debian-repin-setup.log` (SHA-256
  `26061a0bb346e0395032e868a17efb76f846b4b7412159da5c54fc7106f0117f`)
  and `work/console-matrix-rocky-repin-setup.log` (SHA-256
  `0a23fa988815ff4c0b123008ed5bbe5b9a334019bbcac567bc3626f239186d24`).
- Bash syntax and ShellCheck warning checks passed for the changed test
  files and matrix driver. Plain ShellCheck passed for the new sourced
  helper with the Bash dialect selected. No Python dependency was added.
  Existing suite results do not fill the pending PTY detach and monitor rows.

| Platform | Suite | Scope | Runner | PASS | FAIL | SKIP | NA | SCRIPT_ERROR | State | Elapsed |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Debian 13 | error-handling | none | source | 246 | 0 | 0 | 0 | 0 | PASS | 4s |
| Debian 13 | source-regression | system | source | 137 | 0 | 0 | 1 | 0 | PASS | 2s |
| Debian 13 | local-lifecycle | local | source | 205 | 0 | 0 | 0 | 0 | PASS | 135s |
| Debian 13 | local-lifecycle | local | installed | 205 | 0 | 0 | 0 | 0 | PASS | 135s |
| Debian 13 | system-infra | system | none | 36 | 0 | 0 | 4 | 0 | PASS | 1s |
| Debian 13 | system-lifecycle | system | installed | 158 | 0 | 0 | 0 | 0 | PASS | 135s |
| Rocky 8.10 | error-handling | none | source | 246 | 0 | 0 | 0 | 0 | PASS | 4s |
| Rocky 8.10 | source-regression | system | source | 138 | 0 | 0 | 0 | 0 | PASS | 3s |
| Rocky 8.10 | local-lifecycle | local | source | 201 | 0 | 0 | 4 | 0 | PASS | 130s |
| Rocky 8.10 | local-lifecycle | local | installed | 201 | 0 | 0 | 4 | 0 | PASS | 126s |
| Rocky 8.10 | system-infra | system | none | 36 | 0 | 0 | 4 | 0 | PASS | 0s |
| Rocky 8.10 | system-lifecycle | system | installed | 158 | 0 | 0 | 0 | 0 | PASS | 128s |

PTY verification observed at 2026-09-24T17:11:03Z on Debian 13 and Rocky 8.10,
using the working tree based on `0397963`:

- `tests/lib/test-console-pty.bash` and `console-pty-child.bash` exercise the
  real ServiceTestIOC through the selected runner, con/socat, and procServ.
  Each local S27 and system S22 now registers one required tools check and
  eight PTY behavior checks. Local catalogs contain 214 checks and 41 steps;
  system catalogs contain 167 checks and 36 steps. Existing IDs are unchanged.
- The full setup passed on both test consumers (Debian 9/9; Rocky 12/12).
  Source and installed runner bodies matched and reported `0397963-dirty`.
  Six test/catalog/driver file hashes matched between the control tree and
  both consumers. The manifest is `work/console-pty-candidate.sha256`, SHA-256
  `67a517c600c1c990dd32ab23ba7a9bf8eaf4de9ea0794c3cf3a7b72c4619ca4a`.
- Actual client executable hashes are retained in
  `work/console-pty-debian-clients.sha256` and
  `work/console-pty-rocky-clients.sha256`. Both consumers had con only at
  `/usr/local/bin/con` among the runner's fixed search locations; socat was
  `/usr/bin/socat`. Each PTY capture also records the observed client PID/name.
- The first complete matrix, under
  `work/gate-suites-20260924T165505Z-2709607`, had no FAIL, SKIP, or
  SCRIPT_ERROR. Its sole verdict failure was the expected identity mismatch.
  The observed pin was
  `954bedecd60b4fda6e4bb4addf50dbc95e79be96cf6981073c4e79805be4047b`.
- After repinning and enforcing capture-write failures, the complete driver
  passed again under `work/gate-suites-20260924T170311Z-2913449`;
  transcript: `work/console-pty-matrix-repin.log`. Both host verdicts were 0,
  with six validated suite blocks and 1019 checks each. All 48 PTY behavior
  results passed across local/source, local/installed, and system/installed
  on both consumers. This is Check evidence from reused consumers and an
  uncommitted candidate, not release Gate or production load evidence.
- Combined machine-record SHA-256: Debian
  `94f9dd2a6c4b871b67b67870c4bb82455a3cb9ee034b169a9733227d1ee9a750`;
  Rocky `065112678a46575ef195199666c84d9a70eed809cb51fdf58996aeecc8749b4c`.
  Every cross-host difference was examined: Debian's five NA results are one
  RHEL symlink check and four inactive-SELinux checks; Rocky's twelve are eight
  local journal checks and four regex-policy checks on its glob sudoers policy.
  `cross-host.diff` SHA-256:
  `8c66ab56cad507e058804a6a2a64c3a7a38457d9bfd6571061520c8ea3511332`.
- Bash syntax, ShellCheck warning checks, catalog-only validation, and
  `git diff --check` passed. Plain ShellCheck reports SC2030/SC2031 for the
  intentional subshell-local directory reset in the independent attachment;
  the parent must retain its monitor directory. These are informational
  diagnostics; the warning gate passes.
  No Python or additional package was added. Byte tracing, old-con fallback,
  client-absence regression, and the historical runner check remain pending.

| Platform | Suite Blocks | Checks | PASS | FAIL | SKIP | NA | SCRIPT_ERROR | Grade |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Debian 13 | 6 | 1019 | 1014 | 0 | 0 | 5 | 0 | Check |
| Rocky 8.10 | 6 | 1019 | 1007 | 0 | 0 | 12 | 0 | Check |

Client-selection verification observed at 2026-09-24T22:55:26Z on the
development host (Debian 13, x86_64), using the working tree based on `ba9ef10`:

- `REPORT_MACHINE_OUTPUT=1 bash tests/test-error-handling.bash` exited 0:
  249 PASS, including all three S42 checks, with no FAIL, SKIP, NA, or
  SCRIPT_ERROR results.
- The shipped `test_record_validate_file` accepted the captured records with
  producer exit status 0. Records: `/tmp/ioc-console-clients.records`; human
  report: `/tmp/ioc-console-clients.log`. These are temporary local evidence,
  not release Gate evidence. The records SHA-256 is
  `a8c0c84e7b64cc57f5ceee494032bccdec00b564dbaba4167c7abfd4ef491ad7`.
- The shipped `tests/lib/console-client-child.bash` runs the real runner inside
  a private mount namespace (created inside a user namespace when the suite
  does not run as root) that bind-mounts an empty file over every fixed con
  search path, with PATH set to a mirrored tool directory that omits socat.
  Attach and monitor each exit 1 with the documented error and installation
  hint before any connection. With socat left in the mirror, the same child
  reaches configuration resolution instead, so the rejection checks are not
  vacuous.
- The first consumer matrix with the earlier six-check S42 passed on Debian 13
  and closed the three nc checks as SKIP on Rocky 8.10, which has no nc. D7
  removed those checks instead of adding nc to the consumers.
- Bash syntax, `shellcheck -s bash -S warning`, catalog-only validation
  (249 checks, 43 steps), and `git diff --check` passed. Plain ShellCheck
  passed for both helpers.
- Old con without read-only support is not exercised (D6).

Consumer matrix with the three S42 checks observed at 2026-09-24T23:10:28Z,
Check grade on the reused Debian 13 and Rocky 8.10 test consumers, using the
working tree based on `ba9ef10` with the repinned driver identity:

- Before deployment, the shipped cleanup driver cleared the system and local
  IOC registrations on both consumers. The leftover payload directories named
  by `leftovers.bash` remain; they do not affect the six-suite matrix.
- The shipped push driver delivered the tree with matching source and remote
  status, and `run-setup-system-infra.bash --full` passed on both consumers.
  Both installed runners reported `1.4.2-dev (ba9ef10-dirty)` with matching
  source and installed runner bodies.
- The run before the repin reported only the expected identity mismatch, with
  no FAIL, SKIP, or SCRIPT_ERROR result. `EXPECTED_IDENTITY_SHA256` in
  `gate/drivers/control/suites.bash` is now
  `06ea31cc4c284b5c83ec3ec8525654d78d088f6e051f97c87ac12a6725dfe3ca`.
- The confirming run reported `GATE SUITES PASS hosts=2` with both host
  verdicts `SUITES OK`. The cross-host differences match the accepted
  2026-09-24T17:11:03Z run line for line. Evidence directory:
  `work/gate-suites-20260924T230336Z-2238510/`.

| Platform | Suite Blocks | Checks | PASS | FAIL | SKIP | NA | SCRIPT_ERROR | Grade |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Debian 13 | 6 | 1022 | 1017 | 0 | 0 | 5 | 0 | Check |
| Rocky 8.10 | 6 | 1022 | 1010 | 0 | 0 | 12 | 0 | Check |

Combined machine record SHA-256, Debian:
`4b553f6c4990e98aba074b703f551c42c8df54a7ddaf141aa018aa6798fc8a29`; Rocky:
`8723e06e771b112889c8b92c851cd2eec043f7915da8cbe6539d2c08891f396a`;
`cross-host.diff`:
`eb41a7de2f8264ff4a5c09aa0f4a5b3140c59dec00ca52c292d8f2fd394baa2e`.

Historical regression observed at 2026-09-24T23:26:00Z, Check grade on the
same Debian 13 and Rocky 8.10 test consumers with the candidate deployed:

- A local driver sourced the shipped `tests/lib/test-console-pty.bash` on each
  consumer and installed a temporary local IOC whose command execs the real
  softIoc shell under real procServ. It hid every fixed con search path with
  the helper's private mount namespace so both runners selected real socat.
- The pre-fix runner, extracted from `48b7ed9` (`1.4.1 (unknown)`), attached
  through socat with its `Use Ctrl-C to exit` banner and executed an IOC
  `echo`. Ctrl-A did not end the client: it was still running after the
  helper's 10-second deadline, left no exit record, and was then terminated
  by the helper's cleanup. The procServ/IOC PIDs and socket identity were
  unchanged.
- The installed candidate `1.4.2-dev (ba9ef10-dirty)` ran the same sequence
  against the same IOC; Ctrl-A ended socat with exit 0 and restored the
  terminal, with the IOC state unchanged.
- Both consumers produced the same result. The driver removed the temporary
  IOC afterwards. Driver and output SHA-256: `work/t9-historical.bash`
  `56497ec41b596503addad48a47d737f7fc314bf00b66b547f69dcf40fe98035a`, Debian `work/t9-debian.log`
  `8dd269e730bae6d3d8858f8a3076ec152f140303b5b385885287994a4bb44bec`, Rocky `work/t9-rocky.log`
  `b0a9f6b742d180f890db00eca921251466e585dc6f09226cfcbf836e137b351e`. PTY transcripts remain under the consumers'
  `/tmp/ioc-t9.*` directories while those hosts keep their temporary files.

Byte-flow tracing observed at 2026-09-24T23:52:00Z, Check grade on both test
consumers:

- A local driver placed a `socat -x` relay at the procServ socket path and
  moved the procServ socket beside it, so the unchanged runner attached through
  the relay. The IOC child was a raw-mode `dd` recorder, so every byte procServ
  forwarded was written to a file. The driver sourced the shipped PTY helper
  and used real con and socat.
- With the original `--ignore=^D^C^]`, both consumers showed the defect D8
  fixes: `Ctrl-]` reached the child, while typed `]` and `^` reached procServ
  but not the child.
- With `--ignore=^D^C` deployed, con and socat gave the same result on both
  consumers. The default Ctrl-A and custom Ctrl-B detach bytes never reached
  the relay. Ctrl-C and Ctrl-D reached procServ but not the child. Ordinary
  input, `Ctrl-]`, `[`, `]`, `^`, and Ctrl-A under a custom key reached the
  child.
- Driver and output SHA-256: `work/t5-byteflow.bash`
  `52ef888c1e0d9e4177ae468d997d37d4983778acb3cdce879b875149a3c5ed65`; before the
  fix, Debian `work/t5-debian.log`
  `34c06bd0210a9bdd36bce97e411a29f6277be08d3668e60b021ea8af27a072cc` and Rocky
  `work/t5-rocky.log`
  `50fc3a786ed39a900cee7bf04617172498dd389f8f583edaec920ef5f87f81ee`; after the
  fix, Debian `work/t5-debian-fixed.log`
  `1a7da7da0c9327828e685c7cd47944d1595ec283febb7f63ae386bf9612e2e92` and Rocky
  `work/t5-rocky-fixed.log`
  `1d83239f7a4f73aa0b64865fde4b527e65ab8c1f6ad68001495b660755ebada4`.

Consumer matrix with the D8 ignore set observed at 2026-09-25T00:24:08Z, Check
grade on both test consumers, using the working tree based on `f8e13d2`:

- The push driver delivered the tree with matching status, and full setup
  deployed `--ignore=^D^C` in the system unit on both consumers.
- `source-regression.S16.unit.ignore-set` pins the value in both unit
  templates. In a temporary copy on the Debian consumer with both templates
  reverted to `^D^C^]`, the shipped source-regression suite failed only that
  check (`missing:runner-unit`); every other S16 check passed. Reverting the
  runner template alone is caught earlier by `S16.templates.must-agree`.
- The run before the repin reported only the expected identity mismatch.
  `EXPECTED_IDENTITY_SHA256` is now
  `917adb4a6c5d9d3ddda77b6a07dfcfaec7e78f2c172979a68578942bc53974ae`.
- The confirming run reported `GATE SUITES PASS hosts=2`; the cross-host
  differences match the earlier accepted runs line for line. Evidence
  directory: `work/gate-suites-20260925T001706Z-2344504/`.

| Platform | Suite Blocks | Checks | PASS | FAIL | SKIP | NA | SCRIPT_ERROR | Grade |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Debian 13 | 6 | 1023 | 1018 | 0 | 0 | 5 | 0 | Check |
| Rocky 8.10 | 6 | 1023 | 1011 | 0 | 0 | 12 | 0 | Check |

Combined machine record SHA-256, Debian:
`1f67d06b81bb83f5bff6775fd1ce78eeb3978f81676c856232413e54a9339eb7`; Rocky:
`fddf567d2351999b83e74e53cf01b1c575ff7b8bc19c148b463ef7a2070796d7`.
The container path was then exercised on 2026-09-25T09:50:05Z: the shipped
`tests/run-container-tests.bash` ran the container lifecycle suite from the
tree at `2aee5c1` on its four default images, `jeonghanlee/debian13-epics`,
`ubuntu24-epics`, `rocky8-epics`, and `rocky10-epics` (`latest`). Each image
passed 64 of 64 checks with no FAIL, SKIP, NA, or `SCRIPT_ERROR`, so the s6 run
script carrying `--ignore=^D^C` and the escaped `verify_state` reason ran in
the container backend. The suite does not assert the ignore value itself;
byte-level evidence for it remains the systemd-path T5 trace.

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-24T17:11:03Z | PTY matrix above | PASS | Con/default Ctrl-A passes all common detach observations |
| T2 | 2026-09-24T17:11:03Z | PTY matrix above; private namespace hides con | PASS | Socat/default Ctrl-A passes all common detach observations |
| T3 | 2026-09-24T17:11:03Z | PTY matrix above | PASS | Con/custom Ctrl-] and Ctrl-B pass all common detach observations |
| T4 | 2026-09-24T17:11:03Z | PTY matrix above; private namespace hides con | PASS | Socat/custom Ctrl-] and Ctrl-B pass all common detach observations |
| T5 | 2026-09-24T23:52:00Z | Both test consumers; socat -x relay at the socket path and raw dd recorder as the IOC child; real con and socat | PASS | Detach bytes stop at the client; Ctrl-C and Ctrl-D stop at procServ; ordinary input, Ctrl-], `]`, `^`, and Ctrl-A under a custom key reach the child after the D8 ignore-set fix |
| T6 | 2026-09-24T23:10:28Z | Development host error suite and both test consumers; private namespace hides con, mirrored PATH omits socat | PASS | S42 rejects attach and monitor without con or socat with exit 1 and the installation hint on all three hosts; nc-only cases withdrawn by D7 and old-con fallback cases by D6 |
| T7 | 2026-09-24T15:32:17Z | Debian 13 and Rocky 8.10 test consumers; source runner at `74c8b28` plus working-tree tests | PASS | All 47 shipped S41 checks passed within each 246-check error suite; both complete matrices and reporting validation passed after identity repin; Check-grade records and limits above |
| T8 | 2026-09-24T19:51:43Z | Development host; documented attach example forms executed through the real CLI | PASS | Help key list, attach banner text, four documented attach forms and the backslash quoting, and monitor option rejection agree with executed output; direct-con examples retain default Ctrl-A; monitor exit-key guidance added to both user guides and the ignored-keys note to the local guide; a standalone second-person pass on the changed guidance and register text converged on 2026-09-24 after one accepted count correction |
| T9 | 2026-09-24T23:26:00Z | Both test consumers; shipped PTY helper, real socat, procServ, and softIoc; pre-fix runner from `48b7ed9` | PASS | Ctrl-A did not detach the pre-fix socat path within the bounded wait, while the candidate detached with exit 0 on the same IOC; IOC state unchanged in both cases |
| T10 | 2026-09-25T00:24:08Z | Local lint/catalog checks plus complete two-host matrix with the three S42 checks, the D8 ignore set, and the unit ignore-set check | PASS | Current shipped checks, deployment, identity repin, and reporting validation pass at Check grade |
| T11 | 2026-09-24T17:11:03Z | PTY matrix above | PASS | Con monitor receives IOC output, blocks input, exits on Ctrl-A, restores the terminal, preserves IOC/socket state, and reconnects |
| T12 | 2026-09-24T17:11:03Z | PTY matrix above; direct socat only | PASS | Direct socat monitor passes the common observations and exits on Ctrl-C with status 130; the old-con fallback path is withdrawn by D6 |

##### Closure Evidence

- Implementation on `release-1.4.2`: `1bb270f` (detach keys and
  `--detach-key`), `b8d65c3` (development version), `2fa6b55` (nc exclusion
  and monitor option detection), and `860fa66` (D8 ignore set and its unit
  check). Tests and documentation: `74c8b28`, `0397963`, `8c200dc`,
  `e71a2e6`, `ba9ef10`, `f8e13d2`, and `860fa66`.
- Verification: every Test Plan row passed at Check grade on the reused Debian
  13 and Rocky 8.10 test consumers; the final six-suite matrix is
  `work/gate-suites-20260925T001706Z-2344504/` with the identity pinned in
  `860fa66`. D6 and D7 withdraw the old-con and nc-only cases. Release Gate
  evidence on fresh consumers belongs to the release, not to this row.
- Landing: `git fetch` at 2026-09-25T00:52:57Z observed
  `origin/release-1.4.2` at `860fa661101ec5701e87e8853ca414707dbbd8a9`, the
  commit carrying the last implementation change.
- Linked issue: #157 retitled, moved to GitHub milestone `1.4.2`, its body
  synchronized with this detail, and closed as completed at
  2026-09-25T00:54:56Z.

##### GitHub Projection

Title: Verify console detach keys and document supported clients
Labels: bug, documentation, P2-medium, area/shell
GitHub Milestone: 1.4.2
Observed State: closed (completed)
Observed Labels: bug, documentation, P2-medium, area/shell
Observed Milestone: 1.4.2 (19)
Last Compared: after 2026-09-25T00:54:56Z with `gh issue view 157`; issue updated at 2026-09-25T00:54:56Z

#### M2 - Keep multi-line check values out of FAIL reasons

Origin: 1.4.2 / M2
Identity History: none
GitHub Issue: #159, https://github.com/jeonghanlee/epics-ioc-runner/issues/159
Status: Complete

##### Summary

The shared reporter requires a one-line reason for every FAIL. Each suite's
`verify_state` builds that reason from the expected and actual values, so a
check comparing multi-line values produces a multi-line reason on a
mismatch. The reporter then records the check as `SCRIPT_ERROR`, the suite
stops, and every later check closes as `SCRIPT_ERROR`. The real failure is
hidden and the rest of the suite does not run.

Observed on 2026-09-24 with the shipped suites against temporary copies:

- `source-regression.S16.templates.must-agree`, comparing both unit template
  bodies, with only the runner template changed on the Debian 13 test
  consumer: 90 checks, including it, closed as `SCRIPT_ERROR`.
- `error-handling.S41.completion-keys`, comparing a multi-line completion
  list, with one completion key changed on the development host: six checks,
  including it, closed as `SCRIPT_ERROR`.
- `error-handling.S38.local-mode-mismatch-diagnostic-exact`, comparing a
  five-line diagnostic, with one diagnostic label changed on the development
  host: 95 checks, including it, closed as `SCRIPT_ERROR`.

A search of the 578 `verify_state` call sites for actual values produced by
command substitution also finds multi-line comparisons in
`source-regression.S17.metadata.injectors-agree`,
`source-regression.S17.metadata.declaration-anchors-present`, and
`local-lifecycle.S15.system-default-state-unchanged`, plus the other two
S38 exact-diagnostic checks.

##### Scope

- Add one shared helper to `tests/lib/test-reporting.bash` that escapes a
  backslash as `\\` and then line feed, carriage return, and tab as `\n`,
  `\r`, and `\t` in a reason, so an escaped reason stays unambiguous.
- Document `report_escape_reason` in the interface list of
  `tests/REPORTING_CONTRACT.md`, so a new caller escapes multi-line values
  before `report_record` (added by the second-person review, 2026-09-24).
- Add shipped assertions to `tests/lib/test-reporting-self-test.bash` for
  that helper and for a multi-line reason passed directly to `report_record`,
  which must still become `SCRIPT_ERROR` with the one-line reason diagnostic.
  The existing reason scenario covers only an empty reason.
- Use it in the FAIL reason built by `verify_state` in each of the six suites
  that define one. The human report keeps its multi-line Expected and Actual
  output.
- Keep every check ID, kind, and method, so the catalog, counts, and matrix
  identity are unchanged.

Out of scope: relaxing the reporter's one-line reason validation, which still
rejects a multi-line reason from any other caller, and rewriting individual
checks.

##### Completion Criteria

- A check whose multi-line values differ records `FAIL` with a one-line
  escaped reason, the suite continues to the next check, and the human report
  shows the full values.
- With matching values, every check still records `PASS`.
- The reporter still rejects a multi-line reason passed directly to
  `report_record`.
- The catalog, counts, and matrix identity are unchanged.

##### Dependencies And Decisions

- Owner direction 2026-09-24: escape the reason in the shared `verify_state`
  path rather than rewrite each affected check, because the same pattern
  spans three suites and would recur in new checks.
- The reporter's one-line contract in `tests/REPORTING_CONTRACT.md` stays
  unchanged.
- The reporting self-test already fails two unrelated assertions on the
  committed tree: a hard-coded source-regression count of 132 against 139,
  stale since `045bcd5`, and a dimension-matrix count of 7 against 9. They are
  tracked as Backlog M3; T4 evaluates only the assertions this work adds or
  depends on.
- The FAIL path in the local-lifecycle, system-lifecycle, system-infra, and
  container-lifecycle suites is the same one-line helper call as in the two
  exercised suites; it is verified by inspection plus the helper's own
  self-test assertions, not by a failing check in each suite.
- The helper's self-test assertions run only when the reporting self-test is
  run by hand; the gate matrix does not include it. Whether it joins a
  routine check is decided under M3.
- An escaped reason keeps every value on one line, so a large comparison
  yields a long reason: about 1.3 KB for the S16 unit template comparison,
  whose compared block is 619 bytes on each side. The reporter and the record
  validator impose no length limit; the human report remains the readable
  view of the values.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-24, after third-person and second-person review of this plan; the revision adding the contract documentation accepted 2026-09-24
Implementation Authorization: 2026-09-24 for this accepted plan, including that revision
Superseded Plan Artifacts: none

1. Add the reason-escaping helper to `tests/lib/test-reporting.bash`. Add
   self-test assertions for the helper and a multi-line reason scenario to
   `tests/lib/test-reporting-self-test.bash`. Closed by T4. Document the
   helper in the interface list and reason paragraph of
   `tests/REPORTING_CONTRACT.md`; closed by a second-person review and by
   matching the listed name and argument to the function.
2. Call it where `verify_state` builds its FAIL reason in
   `tests/test-error-handling.bash`, `tests/test-source-regression.bash`,
   `tests/test-local-lifecycle.bash`, `tests/test-system-lifecycle.bash`,
   `tests/test-system-infra.bash`, and `tests/test-container-lifecycle.bash`.
   Closed by T1-T3 for the FAIL path, T4 for the catalogs, and T5 for the
   passing path. The container lifecycle suite needs container images, so
   its call site is covered by syntax, ShellCheck, and catalog-only checks.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | reporting | In a `cp -a` copy of the consumer checkout, change `--ignore=^D^C` to `--ignore=^D^C^]` in the local unit `ExecStart` of `bin/ioc-runner` only, then run `tests/run-all-tests.bash --source-regression` from the copy | Test consumer with sudo | `S16.templates.must-agree` records FAIL with a one-line escaped reason, the remaining checks run, and the human report shows the diff |
| T2 | reporting | In a `git archive` copy of the candidate, replace `ctrl-b` in the example key list of `bin/ioc-runner-completion.bash`, then run `tests/test-error-handling.bash` from the copy | Development host | `S41.completion-keys` records FAIL with a one-line escaped reason and the remaining checks run |
| T3 | reporting | In a `git archive` copy of the candidate, change the `Regenerate` label of the configuration mode-mismatch diagnostic in `bin/ioc-runner` to `Regenerat`, then run `tests/test-error-handling.bash` from the copy | Development host | The three S38 exact-diagnostic checks record FAIL with one-line escaped reasons and the remaining checks run |
| T4 | reporting | Run the unchanged error-handling suite, catalog-only validation for all six suites, and the shipped reporting self-test | Development host | All error-handling checks PASS; counts unchanged; the new helper assertions and the new multi-line reason rejection scenario PASS; the only self-test failures are the two M3 assertions |
| T5 | regression and reporting | Run the complete six-suite matrix | Both test consumers | `GATE SUITES PASS` with the pinned identity unchanged |

##### Verification Results

Observed on 2026-09-25 (UTC) against the working tree based on `2ddbf80`;
the times are the completion times of each run's report, read from the Debian
test consumer's clock for T1 and from the development host's clock otherwise:

- T1 on the Debian 13 test consumer: in a `cp -a` copy with only the runner
  unit reverted to `--ignore=^D^C^]`, the shipped source-regression suite ran
  all 139 checks with no `SCRIPT_ERROR`. `S16.templates.must-agree` recorded
  FAIL with a one-line escaped reason, the human report kept the `diff`, and
  `S16.unit.ignore-set` also failed as intended.
- T2 on the development host: with `ctrl-b` replaced in the completion key
  list, the error-handling suite ran all 249 checks with no `SCRIPT_ERROR`;
  `S41.completion-keys` and `S41.completion-prefix` recorded FAIL with
  one-line escaped reasons, and the human report kept the multi-line values.
- T3 on the development host: with the `Regenerate` label changed, the three
  S38 exact-diagnostic checks recorded FAIL with one-line escaped reasons, all
  249 checks ran with no `SCRIPT_ERROR`, and the shipped
  `test_record_validate_file` accepted the records.
- T4 on the development host: the unchanged error-handling suite passed
  249/249; catalog-only validation reported unchanged counts for all six
  suites; the reporting self-test passed the four new assertions and failed
  only the two M3 assertions (116 of 118 passed).
- T5 on both test consumers: the complete driver reported
  `GATE SUITES PASS hosts=2` with the pinned identity unchanged and the
  installed runners at `2ddbf80-dirty`; cross-host differences match the
  earlier accepted runs. Evidence directory:
  `work/gate-suites-20260925T031059Z-464174/`. Combined machine record
  SHA-256, Debian
  `cfaf067df28db66bb59167133679bdc882034e26165915143652151141a2dcec`, Rocky
  `0f690794bdfb64654e58be3059ddb84e35701320f8fb7333cfeab5017dc627f9`.
- `bash -n` and `git diff --check` passed for every changed file. The
  ShellCheck warning gate reports only the SC2034 warning in
  `tests/test-system-infra.bash` that the committed tree already carries.

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-25T03:10:41Z | Debian 13 test consumer, temporary copy | PASS | FAIL with one-line escaped reason; 139 checks ran; no `SCRIPT_ERROR` |
| T2 | 2026-09-25T03:09:31Z | Development host, temporary copy | PASS | Two S41 FAILs with one-line escaped reasons; 249 checks ran; no `SCRIPT_ERROR` |
| T3 | 2026-09-25T03:09:44Z | Development host, temporary copy | PASS | Three S38 FAILs with one-line escaped reasons; 249 checks ran; validator accepted |
| T4 | 2026-09-25T03:10:23Z | Development host | PASS | 249/249; counts unchanged; new self-test assertions PASS; only M3 failures remain |
| T5 | 2026-09-25T03:18:01Z | Both test consumers | PASS | `GATE SUITES PASS hosts=2`; identity unchanged |

##### Closure Evidence

- Implementation, tests, contract documentation, and this detail landed in
  `7032895` on `release-1.4.2`.
- Verification: T1-T5 passed as recorded above; the confirming six-suite
  matrix is `work/gate-suites-20260925T031059Z-464174/` with the pinned
  identity unchanged.
- Landing: `git fetch` at 2026-09-25T04:25:31Z observed
  `origin/release-1.4.2` at `7032895cc179d379916476e91f9d73c5e290404c`.
- Linked issue: #159 filed after the work landed, assigned to GitHub
  milestone `1.4.2`, and closed as completed at 2026-09-25T04:37:51Z.

##### GitHub Projection

Title: A multi-line check mismatch becomes SCRIPT_ERROR and stops the suite
Labels: bug, tests, P2-medium
GitHub Milestone: 1.4.2
Observed State: closed (completed)
Observed Labels: bug, tests, P2-medium
Observed Milestone: 1.4.2 (19)
Last Compared: after 2026-09-25T04:37:51Z with `gh issue view 159`; issue updated at 2026-09-25T04:37:51Z

#### M3 - Refresh the reporting self-test's stale expectations

Origin: 1.4.2 / M3
Identity History: none
GitHub Issue: #158, https://github.com/jeonghanlee/epics-ioc-runner/issues/158
Status: Complete

##### Summary

`tests/lib/test-reporting-self-test.bash` fails two assertions on the
committed tree. Both compare against a literal value copied when `8a56031`
(2026-09-03) added the container-lifecycle suite, and neither literal followed
later changes. Before this work, no gate step or dispatcher mode ran any of
the three shipped self-tests, so the drift went unnoticed. Observed on
2026-09-24 on the development host:

- `catalog precedence: exact standard-output contract` runs the real
  source-regression catalog-only path and compares its last line with the
  literal `checks=132 steps=20`. The catalog grew to 134 in `045bcd5`, 138 in
  `cd77398`, and 139 in `860fa66`; `tests/reporting-counts.csv` already holds
  the current value.
- `dimension-matrix: all accepted combinations finalize` finalizes one run for
  each of the nine suite-dimension combinations in its list and expects the
  literal 7 `SUITE` records. The reporter accepts exactly the same nine
  combinations; `8a56031` added two to both without updating the count.

The record-validator self-test (66 of 66) and the reporting-counts self-test
(8 of 8) pass.

Run as the gate runs source-regression, with `REPORT_MACHINE_OUTPUT=1`
inherited, the reporting self-test also fails the two escape assertions that
`7032895` added. `check_escape_reason` sources the reporter inside a command
substitution, and with that variable set the reporter routes standard output
to standard error as it loads, so the capture is empty. Observed on
2026-09-25 on the Debian 13 test consumer and reproduced on the development
host. The suites' own `verify_state` path is unaffected because it loads the
reporter before capturing.

##### Scope

- Derive the catalog-precedence expectation from the source-regression row of
  `tests/reporting-counts.csv`.
- Derive the dimension-matrix expectation from the length of its combination
  list.
- Make `check_escape_reason` independent of an inherited
  `REPORT_MACHINE_OUTPUT` by clearing it in the capturing subshell before the
  reporter loads.
- Add a source-regression STEP that runs the three shipped self-tests and
  requires each to exit 0, so the gate matrix exercises them on every run.
- Register the new checks, update the catalog count, the inventory, and the
  test documentation, and repin the gate identity from a clean run.

Out of scope: changing the reporter contract or any self-test assertion other
than the two stale expectations.

##### Completion Criteria

- The reporting self-test passes every assertion on the committed tree, both
  with `REPORT_MACHINE_OUTPUT` unset and with `REPORT_MACHINE_OUTPUT=1`
  inherited.
- Adding a source-regression check or a suite-dimension combination no longer
  requires editing either expectation by hand.
- The gate matrix runs all three self-tests on both test consumers and fails
  if any of them fails.
- The catalog, counts, inventory, and pinned identity agree with the new
  checks.

##### Dependencies And Decisions

- Owner decision 2026-09-24, delegated to the recommended option: run the
  self-tests routinely rather than by hand, because the two failures went
  unnoticed for three weeks while nothing ran them.
- They run in the source-regression suite because its category covers shipped
  test-script behavior and it already runs on both consumers in the gate. The
  reporting self-test calls the source-regression suite only in catalog-only
  mode, which exits before any STEP runs, so the new STEP does not recurse.
- The escape-assertion defect from `7032895` is fixed within this work rather
  than as separate work, because a self-test result must not depend on an
  inherited environment variable (owner decision 2026-09-25, delegated to the
  recommended option). S26 itself does not expose the defect: its
  `run_as_invoker` call uses `sudo`, whose `env_reset` on both test consumers
  drops `REPORT_MACHINE_OUTPUT`, observed on 2026-09-25.
- The suite-dimension part of the Completion Criteria is closed by inspection:
  the count is computed from the combination list, and a combination the
  reporter does not accept cannot be added to the list for an execution test.
- The self-tests need no root privilege, so S26 runs them through the suite's
  existing `run_as_invoker`. Each takes under one second on the test
  consumers.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-25, after third-person and second-person review of this plan
Implementation Authorization: 2026-09-25 for this accepted plan
Superseded Plan Artifacts: none

1. In `tests/lib/test-reporting-self-test.bash`, build the catalog-precedence
   expected line from the source-regression row of `tests/reporting-counts.csv`
   and the dimension-matrix count from its combination list, and clear
   `REPORT_MACHINE_OUTPUT` inside `check_escape_reason` before the reporter
   loads. Closed by T1.
2. Add STEP S26 to `tests/test-source-regression.bash` with three
   `BEHAVIOR`/`real-path` checks that run
   `tests/lib/test-reporting-self-test.bash`,
   `tests/lib/test-record-validator-self-test.bash`, and
   `tests/lib/reporting-counts-self-test.bash` through `run_as_invoker` and
   require exit 0. Capture each self-test's output in a file under the suite's
   workspace and print its path and failed assertions only on failure. Update
   `tests/reporting-counts.csv`, `tests/SOURCE_REGRESSION_INVENTORY.md`, and
   `tests/README.md`. Closed by T2 and T3.
3. Run the six-suite matrix, repin `EXPECTED_IDENTITY_SHA256` from a run whose
   only failure is the identity mismatch, and confirm with a second run.
   Closed by T4.
4. Project the current Scope and Completion Criteria into the #158 body under
   separate Issue authority, then read the issue back. Closed by the recorded
   GitHub Projection comparison.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | reporting | Run `tests/lib/test-reporting-self-test.bash` with `REPORT_MACHINE_OUTPUT` unset and again with `REPORT_MACHINE_OUTPUT=1` | Development host | Every assertion PASS in both runs |
| T2 | reporting | Run catalog-only validation on the development host, then `tests/run-all-tests.bash --source-regression` on a test consumer | Development host and Debian 13 test consumer | Counts agree; the three S26 checks PASS |
| T3 | reporting | (a) In a `git archive` copy, add one check ID to the S25 entries of the check list in `tests/test-source-regression.bash`, raise the source-regression row of `tests/reporting-counts.csv` to 140, and run the reporting self-test. (b) In a `cp -a` copy on the consumer, change the expected value of one assertion in `tests/lib/reporting-counts-self-test.bash` and run `tests/run-all-tests.bash --source-regression` | (a) development host; (b) Debian 13 test consumer | (a) The catalog-precedence assertion passes with no self-test edit; (b) the matching S26 check records FAIL with a one-line reason and the suite continues |
| T4 | regression and reporting | Run the complete six-suite matrix before and after the identity repin | Both test consumers | Only the expected identity mismatch before the repin; `GATE SUITES PASS` after it |

##### Verification Results

Observed on 2026-09-25 (UTC) against the working tree based on `1203427`; the
times are the completion times of each run's report, read from the Debian 13
test consumer's clock for T2, T3 (b), and T4 and from the development host's
clock otherwise:

- T1 on the development host: the reporting self-test passed 118 of 118
  assertions with `REPORT_MACHINE_OUTPUT` unset and again with
  `REPORT_MACHINE_OUTPUT=1`.
- T2: catalog-only validation reported `checks=142 steps=21 state=PASS` on the
  development host. On the Debian 13 test consumer,
  `tests/run-all-tests.bash --source-regression` passed with the three S26
  checks PASS, 141 PASS and 1 NA in total, and no `SCRIPT_ERROR`.
- T3 (a) on the development host: with one S25 check ID added in a
  `git archive` copy and the source-regression row raised to 143, catalog-only
  validation passed and the unedited reporting self-test passed every
  assertion, including the catalog-precedence expectation.
- T3 (b) on the Debian 13 test consumer: with one expected message changed in
  a `cp -a` copy of `tests/lib/reporting-counts-self-test.bash`,
  `S26.self-test.reporting-counts` recorded FAIL with the one-line reason
  `expected 0, actual 1`, the human report named the failed assertion and the
  retained workspace, and all 142 checks ran with no `SCRIPT_ERROR`.
- T4 on both test consumers: the first matrix failed only on the expected
  identity mismatch, with 1026 checks per host and no FAIL, SKIP, or
  `SCRIPT_ERROR`. `EXPECTED_IDENTITY_SHA256` is now
  `52c1fb53ab4ffc22189a747dee34d5808715e9f0d2157ab7ee0698b6def7d5ab`. The
  confirming run reported `GATE SUITES PASS hosts=2` with the installed
  runners at `1203427-dirty`; cross-host differences match the earlier
  accepted runs. Evidence directory:
  `work/gate-suites-20260925T054538Z-1684424/`. Combined machine record
  SHA-256, Debian
  `aea722c01ed36933f91b17ea2e2946f45768aeb5093791a33f7b243fc936f350`, Rocky
  `15f278962e649d60c1f526aac0ea8342e732d1abb4facb92b950b9e9d100ffff`.
- ShellCheck against the committed tree adds only one informational SC1091
  note for the new `source` line, matching the file's existing `source`
  notes; the self-test's SC2034 warning predates this work.

| Platform | Suite Blocks | Checks | PASS | FAIL | SKIP | NA | SCRIPT_ERROR | Grade |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Debian 13 | 6 | 1026 | 1021 | 0 | 0 | 5 | 0 | Check |
| Rocky 8.10 | 6 | 1026 | 1014 | 0 | 0 | 12 | 0 | Check |

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-25T05:36:01Z | Development host | PASS | 118/118 in both environments |
| T2 | 2026-09-25T05:37:28Z | Development host and Debian 13 test consumer | PASS | Catalog 142/21; S26 checks PASS on the consumer |
| T3 | 2026-09-25T05:37:56Z | Development host and Debian 13 test consumer, temporary copies | PASS | Derived count followed the added check; broken self-test made S26 FAIL with a one-line reason |
| T4 | 2026-09-25T05:52:41Z | Both test consumers | PASS | Identity mismatch only before the repin; `GATE SUITES PASS hosts=2` after it |

##### Closure Evidence

- Implementation, the S26 step, catalog, inventory, documentation, identity
  repin, and this detail landed in `b638ed9` on `release-1.4.2`.
- Verification: T1-T4 passed as recorded above; the confirming six-suite
  matrix is `work/gate-suites-20260925T054538Z-1684424/`.
- Landing: `git fetch` at 2026-09-25T09:32:11Z observed
  `origin/release-1.4.2` at `b638ed96d35ead79cb3612823975c69cd037c83f`.
- Linked issue: #158 body updated with the resolution and checked acceptance
  criteria, and closed as completed at 2026-09-25T09:36:17Z.

##### GitHub Projection

Title: Reporting self-test carries stale expectations and runs in no routine check
Labels: bug, tests, P3-low
GitHub Milestone: 1.4.2
Observed State: closed (completed)
Observed Labels: bug, tests, P3-low
Observed Milestone: 1.4.2 (19)
Last Compared: after 2026-09-25T09:36:17Z with `gh issue view 158`; issue updated at 2026-09-25T09:36:17Z; the body carries the resolution and checked acceptance criteria


#### M4 - Reject ctrl-[ as a detach key

Origin: 1.4.2 / M4
Identity History: none
GitHub Issue: #160, https://github.com/jeonghanlee/epics-ioc-runner/issues/160
Status: Complete

##### Summary

Before this work, `set_detach_key` accepted `ctrl-[`, which is byte 0x1b
(ESC). Arrow, Home, and function keys start with the same byte. Observed on 2026-09-25 on the
development host in a PTY: socat started with `escape=0x1b` ended on a single
up-arrow sequence while `escape=0x02` did not, so under socat the IOC shell's
history keys would detach the console. con 1.1.0 ended only on a lone ESC
because it honors the exit key only as a single-byte read. The key was added
in this release line (`1bb270f`) and has not shipped, so removing it breaks no
released usage.

##### Scope

- Reject `ctrl-[` in `set_detach_key` with the invalid-key error, and remove
  it from the error text, the help key list, and `docs/CLI_REFERENCE.md`.
- Replace the S41 acceptance check for `ctrl-[` with a rejection check, update
  the accepted-key count in `tests/README.md`, and repin the gate identity.

Out of scope: changing the default key, the other accepted keys, or con.

##### Completion Criteria

- `ioc-runner attach <name> --detach-key ctrl-[` exits 1 with the invalid-key
  error before any client resolution.
- Help, error text, and documentation list the 29 accepted keys without
  `ctrl-[`.
- The S41 catalog carries the rejection check, counts are unchanged, and the
  gate matrix passes with the repinned identity.

##### Dependencies And Decisions

- Owner direction 2026-09-25: remove `ctrl-[` from the accepted keys, after
  the conceptual-integrity sweep of this release line.
- D2 keeps Ctrl-A as the default and the per-connection option; this narrows
  only the accepted set.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-25, owner direction
Implementation Authorization: 2026-09-25, owner direction
Superseded Plan Artifacts: none

1. Change `set_detach_key`, its error text, and the help key list in
   `bin/ioc-runner`, and the key list in `docs/CLI_REFERENCE.md`. Closed by T1.
2. In `tests/lib/test-console-options.bash` and the S41 catalog of
   `tests/test-error-handling.bash`, replace the `ctrl-[` acceptance check with
   a rejection check, and change the count in `tests/README.md`. Closed by T1
   and T2.
3. Run the matrix, repin from a run whose only failure is the identity
   mismatch, and confirm. Closed by T3.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | error-contract | Run the shipped CLI with `--detach-key ctrl-[` and run the error-handling suite | Development host | Exit 1 with the invalid-key error; the S41 rejection check PASS; 249 checks PASS |
| T2 | reporting | Catalog-only validation and the reporting self-test | Development host | Counts unchanged; self-test PASS |
| T3 | regression and reporting | Complete six-suite matrix before and after the identity repin | Both test consumers | Only the identity mismatch before the repin; `GATE SUITES PASS` after it |

##### Verification Results

Observed on 2026-09-25 (UTC) against the working tree based on `2aee5c1`:

- T1 on the development host: `ioc-runner --local attach x --detach-key
  'ctrl-['` and the uppercase form exited 1 with the invalid-key error before
  client resolution. The error-handling suite passed 249 of 249, including
  `S41.reject-escape-byte`.
- T2 on the development host: catalog-only validation reported
  `checks=249 steps=43 state=PASS`; the reporting self-test passed; the
  ShellCheck warning gate and `git diff --check` passed.
- T3 on both test consumers: the first matrix failed only on the expected
  identity mismatch, with 1026 checks per host and no FAIL, SKIP, or
  `SCRIPT_ERROR`; `S41.reject-escape-byte` passed on both hosts.
  `EXPECTED_IDENTITY_SHA256` is now
  `37db797f5ab7a49786bc3a598702a22ed9c75dc9e5b159ae110ad08ea024fde1`. The
  confirming run reported `GATE SUITES PASS hosts=2` with the installed
  runners at `2aee5c1-dirty`; cross-host differences match the earlier
  accepted runs. Evidence directory:
  `work/gate-suites-20260925T095858Z-4071740/`. Combined machine record
  SHA-256, Debian
  `7a4a96026fa2293e1c5a398e83e5ca889dca2690a385849c3c74941288deed2b`, Rocky
  `f1186584a10c16a4a984c60a18ba36ee58c054d6654ececaaa569fc0713f0e71`.

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-25T09:51:22Z | Development host | PASS | `ctrl-[` rejected; 249/249 |
| T2 | 2026-09-25T09:51:22Z | Development host | PASS | Counts unchanged; self-test PASS |
| T3 | 2026-09-25T10:06:02Z | Both test consumers | PASS | Identity mismatch only before the repin; `GATE SUITES PASS hosts=2` after it |

##### Closure Evidence

- Rejection, help, error text, CLI reference, the S41 rejection check, test
  documentation, identity repin, and this detail landed in `ad5b1e7` on
  `release-1.4.2`.
- Verification: T1-T3 passed as recorded above. At 2026-09-25T16:13:13Z,
  re-allowing `ctrl-[` in a temporary copy of `ad5b1e7` made the
  error-handling suite fail only `S41.reject-escape-byte`.
- Landing: `git fetch` at 2026-09-25T16:19:35Z observed
  `origin/release-1.4.2` at `ad5b1e7736f1057447aea2a7624030c71ac2bff9`.
- Linked issue: #160 filed with the resolution and checked acceptance
  criteria, and closed as completed at 2026-09-25T16:18:22Z.

##### GitHub Projection

Title: Detach key ctrl-[ is the Escape byte and detaches socat on arrow keys
Labels: bug, P3-low, area/shell
GitHub Milestone: 1.4.2
Observed State: closed (completed)
Observed Labels: bug, P3-low, area/shell
Observed Milestone: 1.4.2 (19)
Last Compared: after 2026-09-25T16:18:22Z with `gh issue view 160`; issue updated at 2026-09-25T16:18:22Z; the body carries the resolution and checked acceptance criteria

#### M5 - State how each console client handles a pasted detach key

Origin: 1.4.2 / M5
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

The attach banner and the console documents said that both clients consume
the detach key, so it never reaches the IOC shell. That holds for a typed key
only. con honors its exit key only when the key arrives alone in one read, so
inside pasted text it forwards the key to the IOC shell; socat detaches at its
escape byte wherever it appears. The con behavior matches the lone-ESC
observation recorded in M4.

##### Scope

- Change the second attach banner line in `bin/ioc-runner` to state that a
  typed key detaches and is not sent to the IOC shell.
- Change the detach sentence in `docs/CLI_REFERENCE.md`, `docs/USER_GUIDE.md`,
  and `docs/USER_GUIDE_LOCAL.md` to state the typed-key behavior and the con
  and socat difference for pasted text.

Out of scope: changing either client's behavior, the accepted key set, the
monitor banner, and `CHANGELOG.md`, which the release cycle writes.

##### Completion Criteria

- The attach banner line in `bin/ioc-runner` reads `A typed <key> detaches and
  is not sent to the IOC shell.` for the selected key.
- No console document states that the detach key never reaches the IOC shell,
  and the three documents state the pasted-text difference.
- The runner passes `bash -n` and the ShellCheck warning gate.

##### Dependencies And Decisions

- Owner direction 2026-09-25: adopt the proposed banner and document wording,
  from the conceptual-integrity sweep of this release line, and leave the
  1.4.2 CHANGELOG entry to the release cycle.
- Owner direction 2026-09-25: verify by static checks and document search
  only; the planned PTY banner check was dropped as disproportionate to a
  wording change.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-25, owner direction
Implementation Authorization: 2026-09-25, owner direction
Superseded Plan Artifacts: none

1. Change the banner line in `bin/ioc-runner`. Closed by T1.
2. Change the detach sentence in the three console documents. Closed by T1.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | static | `bash -n`, the ShellCheck warning gate, `git diff --check`, and a search of the console documents for the old claim | Development host | All pass; the old claim is absent |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-25T19:09:31Z | Development host | PASS | `bash -n`, ShellCheck warning gate, and `git diff --check` passed; the old claim is absent and each console document states the pasted-text difference |

##### Closure Evidence

- The banner line, the three console documents, and this detail landed in
  `7c7444c` on `release-1.4.2`.
- Verification: T1 passed as recorded above.
- Landing: `git fetch` at 2026-09-25T19:52:39Z observed
  `origin/release-1.4.2` at `7c7444c54130cf5968167f2c04f10e5a0bb02886`.

#### M6 - Rewrite an identical configuration regardless of its owner

Origin: 1.4.2 / M6
Identity History: none
GitHub Issue: #161, https://github.com/jeonghanlee/epics-ioc-runner/issues/161
Status: Complete

##### Summary

When `generate` produces a configuration identical to the existing file, it
skips the overwrite but reasserts the file mode with `chmod` (0660 in system
and container mode, 0600 in local mode). Only the file owner may change a
mode, so a member of the `ioc` group who regenerates a shared IOC directory
whose configuration another member created fails with `chmod: ... Operation
not permitted` and exits nonzero, even when the mode is already correct; and
a file whose creator's account no longer exists cannot be corrected by anyone
but root. Observed on 2026-09-25 on a system-mode host with an existing 0660
configuration owned by another group member.

A sweep of the shipped code on 2026-09-25 found no other ownership-dependent
change that aborts: the remaining `chmod` calls act on temporary files the
runner just created, the `.iocsh_history` mode reassertion ignores failure
and is inert in any case (M7), `install -d -m` runs only on new directories,
in local mode under the user's own home, or as root, and
`bin/setup-system-infra.bash` runs as root.

##### Scope

- In the identical-configuration path of `do_generate` in `bin/ioc-runner`,
  replace the skip and `chmod` with the same staged rewrite the
  differing-content path performs: set the target mode on the temporary file
  and rename it over the existing one. When the existing file belongs to the
  invoking user, rewrite without a question; when it belongs to another
  user, name that owner and ask y/N first, unless `-f` is given (D11).
- On identical content, print the `already up-to-date (Identical)` line,
  drop the `Skipping overwrite.` line, and continue to the common success
  output.
- Identical content now also reaches the `.iocsh_history` block after the
  rename; its failure is ignored, so a non-owner run is unaffected.
- Change the three S04 checks in `tests/test-error-handling.bash` that pin
  the skip path so they pin the rewrite and its mode.
- Add one system-lifecycle check in which a second `ioc` group operator
  regenerates with `-f` an identical system-mode configuration created by
  another user, update the system-lifecycle count, inventory, and test
  documentation, and repin the gate identity.
- Add a `generate` section to `docs/CLI_REFERENCE.md` stating the four
  cases (no file, identical and own, identical and another owner, differing),
  the `-f` bypass, the exit status of a refusal or closed input, that a
  rewrite transfers the file to the invoking user, and that its group comes
  from the directory.

Out of scope: changes to the differing-content path, to the
`.iocsh_history` block itself (M7), and to `bin/setup-system-infra.bash`.

##### Completion Criteria

- A non-owner group member regenerating an identical configuration with
  `-f` exits 0, and the file carries the target mode and the new owner
  afterwards; without `-f` the owner is named and a y/N question is asked,
  and a closed standard input exits 1 with the file unchanged.
- The owner regenerating an identical configuration exits 0 without a
  question, including a loosened mode being corrected.
- `docs/CLI_REFERENCE.md` carries a `generate` section matching this
  behavior.
- The S04 checks pin the rewrite with the error-handling count unchanged,
  the new system-lifecycle check fails against the skip-and-`chmod` code and
  passes against the rewrite, the system-lifecycle count rises from 167 to
  168 with 36 steps, and the gate matrix passes with the repinned identity.

##### Dependencies And Decisions

- D10 sets the rewrite approach; D11 sets when it asks first.
- Owner direction 2026-09-25: include this fix in 1.4.2, and sweep the code
  for similar ownership-dependent permission changes.
- Owner direction 2026-09-26: rewrite regardless of owner rather than skip
  and `chmod`, because the file's creator may no longer exist.
- Owner direction 2026-09-26: pin the non-owner path with an automated
  check. The error-handling suite runs as an ordinary user and cannot switch
  users, so the check belongs to the system-lifecycle suite, which runs as
  root and already provisions a temporary `ioc` group operator (S27).

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-26, owner direction
Implementation Authorization: 2026-09-26, owner direction
Superseded Plan Artifacts: none

1. In `do_generate`, on identical content, print the `already up-to-date
   (Identical)` line and drop the `chmod`, the `Skipping overwrite.` line, and
   the early exit. Compare the existing file's numeric owner UID with `id -u`.
   When they match, bypass the `FORCE_OVERWRITE` diff-and-question block; when
   they differ and `-f` is absent, name the owner (the name that
   `getent passwd <uid>` resolves, or the numeric UID when it resolves none;
   `stat -c %U` prints `UNKNOWN` there and is not used) and ask y/N, exiting 1
   on a refusal or a closed standard input. Then reach the existing
   mode-setting and rename of the staged file and end in the common success
   output. Closed by T1.
2. Rename and re-expect the three S04 checks: exit 0, the `already
   up-to-date (Identical)` line, no prompt on a closed standard input, and
   the target mode after a loosened mode; update their rows in
   `tests/ERROR_HANDLING_INVENTORY.md`. The error-handling count stays 249.
   Closed by T1 and T2.
3. Inside the system-lifecycle S27 step, which already provisions the temporary
   `ioc` group operator, run the new check right after the operator is created.
   S27 gates on `softioc-available` and then on `probe-user-name-available`
   before creating the operator, so the check skips with the step when either
   gate fails, although it needs no softIoc; both gates pass on the gate
   consumers, and the step order is kept. Create a `root:ioc 2775` IOC
   directory, generate its configuration as root, and have the operator
   regenerate the identical configuration with `-f`; expect exit 0, mode 0660,
   and the operator as owner. The step count stays 36 and the check count rises
   from 167 to 168: update `tests/reporting-counts.csv`,
   `tests/SYSTEM_LIFECYCLE_INVENTORY.md`, and `tests/README.md`. Repin the gate
   identity once for both suites' check changes. Closed by T1, T2, and T3.
4. Append section 6, `generate`, to `docs/CLI_REFERENCE.md`, after the
   existing five so no section number moves, with the four cases, the `-f`
   bypass, the refusal exit status, the ownership transfer, and that the
   rewritten file takes its group from the directory, which the documented
   `root:ioc 2775` payload directory keeps as `ioc`. Closed by T4.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | behavior | Regenerate an identical configuration owned by another group member without `-f` on a closed standard input, then with `-f` after loosening its mode, and as the owner with a loosened mode | Test consumer | Without `-f`: the owner is named, exit 1, file unchanged; with `-f`: exit 0, target mode, new owner; as owner: exit 0, no question, target mode |
| T2 | regression | Run the new system-lifecycle check against the unchanged skip-and-`chmod` code, then against the rewrite | Test consumer | FAIL before the change with the `chmod` error; PASS after it |
| T3 | regression | Complete six-suite matrix before and after the identity repin | Both test consumers | Only the identity mismatch before the repin; `GATE SUITES PASS hosts=2` after it |
| T4 | documentation | Compare the `generate` section of `docs/CLI_REFERENCE.md` with the T1 observations | Development host | Every case, the `-f` bypass, and the exit statuses match |

##### Verification Results

Observed on 2026-09-26 (UTC) with the working tree based on `1c62846`. The
development host ran the error-handling suite: 249 of 249 passed, including
the three renamed S04 checks.

- T1 on both test consumers, with the working-tree runner copied to a
  temporary path and a `root:ioc 2775` directory under `/opt/epics-iocs`: a
  configuration generated by `opa` and regenerated identically by `opb`
  without `-f` on a closed standard input printed `It is owned by opa;
  rewriting it makes opb the owner.`, exited 1, and left `opa:ioc 660` with
  no temporary file; a refusal exited 1 and left the loosened `666` mode;
  `-f` exited 0 with `opb:ioc 660`; `opb` as owner, after loosening the mode,
  exited 0 without a question and restored `660`; `opa` answering `y` took
  it back; after a temporary `ioc` user took it over with `-f` and was
  deleted, `opa` was told `It is owned by UID 1006` and exited 1 on a closed
  standard input.
- T2 on the Debian 13 test consumer, system-lifecycle in source mode from
  two pushed copies of the working tree: with `bin/ioc-runner` from `1c62846`
  the suite reported 167 of 168 with only
  `S27.second-operator-takes-over-an-identical-conf-with-f-161` failing,
  `expected root 0 660 epics-t1-operator, actual root 1 660 root`; with the
  changed runner it reported 168 of 168 and `Suite State: PASS`. The check
  records the owner before the operator's run, so a root generate that left
  no file cannot pass through the no-file path; this run follows that
  change, after an earlier run of the check without it gave the same
  verdicts.
- T3 on both test consumers after `gate/drivers/push.bash` and
  `bin/run-setup-system-infra.bash --full`, with the installed runners at
  `1c62846-dirty`: the first matrix failed only on the expected identity
  mismatch, with 1027 checks per host and no FAIL, SKIP, or `SCRIPT_ERROR`.
  `EXPECTED_IDENTITY_SHA256` is now
  `34c01b1f4f4eebc8b69d29c81133a24cbb7bbef2a60e3636cd2725871c5e77d3`. The
  confirming run reported `GATE SUITES PASS hosts=2`. After the check
  gained its before-owner field, which keeps its identifier, the matrix was
  rerun on the final tree without another repin and again reported
  `GATE SUITES PASS hosts=2` with 1027 checks per host; NA counts (5 on
  Debian, 12 on Rocky) match the earlier accepted runs. Evidence directory:
  `work/gate-suites-20260926T204823Z-2765468/`. Combined machine record
  SHA-256, Debian
  `ab54f4e57cce9f636f3f0f92856b12bb5cfe05d3feb0b08645587e7d71c4c0a4`, Rocky
  `22ee8d8fabdf8e40a3d77cb3df5c7ae007ad0ccb4a740c286b83e5ccfabd1c41`.
- T4 on the development host: each row of the `generate` table in
  `docs/CLI_REFERENCE.md` section 6, the `-f` bypass, and the ownership and
  group statements match the T1 observations; the differing-content row
  matches the unchanged S04 prompt checks.

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-26T19:59:25Z | Both test consumers | PASS | Every case matched the Test Plan on Debian 13 and Rocky 8.10 |
| T2 | 2026-09-26T20:48:22Z | Debian 13 test consumer | PASS | FAIL on the old runner with the `chmod` exit, PASS on the change; 168 checks |
| T3 | 2026-09-26T20:55:25Z | Both test consumers | PASS | Identity mismatch only before the repin; `GATE SUITES PASS hosts=2` after it |
| T4 | 2026-09-26T20:19:59Z | Development host | PASS | Every documented case matches the observed behavior |

##### Closure Evidence

- The runner change, the CLI reference section, the renamed S04 checks, the
  S27 check, the catalog, inventories, test documentation, the identity
  repin, and this detail landed in `458403f` on `release-1.4.2`.
- Verification: T1-T4 passed as recorded above.
- Landing: `git fetch` at 2026-09-27T06:02:33Z observed
  `origin/release-1.4.2` at `065e438b5bc8d65718d66ba43066c37e22b417bf`,
  which contains `458403f`.
- Linked issue: #161 body updated with the resolution and checked acceptance
  criteria, and closed as completed at 2026-09-27T09:53:36Z.

##### GitHub Projection

Title: generate fails for a non-owner when the existing configuration is identical
Labels: bug, P2-medium, area/permissions
GitHub Milestone: 1.4.2
Observed State: closed (completed)
Observed Labels: bug, P2-medium, area/permissions
Observed Milestone: 1.4.2 (19)
Last Compared: after 2026-09-27T09:53:36Z with `gh issue view 161`; issue updated at 2026-09-27T09:53:36Z; the body carries the resolution and checked acceptance criteria

#### M7 - Document iocsh history ownership across principals

Origin: 1.4.2 / M7
Identity History: none
GitHub Issue: #162, https://github.com/jeonghanlee/epics-ioc-runner/issues/162
Status: Complete

##### Summary

The console documents said that iocsh saves `.iocsh_history` as 0600 owned
by the last principal, and `do_generate` pre-allocates the file as 0664 in
system mode so that `ioc-srv` can append to it. Reading EPICS Base R7.0.10
(`iocsh.cpp`, `ReadlineContext`) and GNU readline 7.0 and 8.2
(`histfile.c`, `history_do_write`) showed that readline saves the file as a
temporary file renamed over the original, always a fresh 0600 owned by the
running principal, with a chown back to the previous owner that succeeds only
for root; saving needs directory write permission, not permission on the
existing file. The pre-allocated file therefore contributes nothing. The
sequences an operator follows in practice (manual run, service run as
`ioc-srv`, a second operator's manual run, local mode by two users, a
sticky-bit directory) were run on both test consumers and behave as the
source predicts: one benign loading error per principal switch, a history
restart, exit status and IOC behavior unchanged.

##### Scope

- Add FAQ Q13 with the file location, the readline mechanism, the verified
  sequence table, the sticky-bit case, and the per-principal
  `EPICS_IOCSH_HISTFILE` settings for the service drop-in, the local drop-in,
  and a shell.
- Point the Q5 history-file note to Q13.
- Record the examined Keep as CLOSED_DOORS CI-44.

Out of scope: any change to the runner's launch environment (D9), and the
`do_generate` pre-allocation block, whose removal is an open decision below.

##### Completion Criteria

- FAQ Q13 is present with the verified table and the three settings, and Q5
  refers to it.
- CLOSED_DOORS carries CI-44 with its carrying commit.
- The documents pass `git diff --check`.

##### Dependencies And Decisions

- D9 fixes the runner boundary this work documents.
- Owner direction 2026-09-25: run the sticky-bit case as well, write the
  result into the FAQ, and record the Keep in CLOSED_DOORS.
- Open: whether to remove the `do_generate` history pre-allocation
  (`bin/ioc-runner`, the `.iocsh_history` block after the conf rename),
  which the verification showed to be inert, or to correct its comment only.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-25, owner direction
Implementation Authorization: 2026-09-25, owner direction
Superseded Plan Artifacts: none

1. Run the principal-switch, runner-path, and sticky-bit sequences on both
   test consumers. Closed by T1, T2, and T3.
2. Write FAQ Q13, the Q5 pointer, and CLOSED_DOORS CI-44. Closed by T4.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | behavior | In a `2775` `ioc`-group directory, run a `softIoc` `st.cmd` through `runuser` as `opa`, `opb`, `ioc-srv`, and `opa` again, first with `EPICS_IOCSH_HISTFILE` unset and then set per principal (`~/.iocsh_history` for the operators, a file in the service log directory for `ioc-srv`); record the error lines and the file owner and mode after each run | Both test consumers | Unset: one loading error per principal switch and a fresh 0600 file owned by the runner; per principal: no error, each file owned by its principal, the operator's history retained |
| T2 | behavior | As `opa`, `generate`, `install`, `start`, and `stop` a system IOC under a template drop-in setting `EPICS_IOCSH_HISTFILE=/var/log/procserv/%i.iocsh_history`, then a second start and stop; as `usera`, the same in local mode under a user drop-in with `%h/.iocsh_history-%i` | Both test consumers | The file appears at the configured path owned by the launching principal; the log carries no history error after the second cycle |
| T3 | behavior | T1's unset sequence in a `3775` directory | Both test consumers | The second and third principals print a loading error and a writing error; the first principal's file remains |
| T4 | static | `git diff --check` on the three documents | Development host | Pass |

##### Verification Results

Observed on 2026-09-26 (UTC) with the installed runner at `6209734` on both
test consumers; each run was cleaned up afterwards.

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | after 2026-09-26T05:51:58Z | Both test consumers | PASS | Unset: `opa:ioc 600` then `opb`, `ioc-srv`, `opa`, one `Permission denied (13) loading` line per switch; per principal: no error, `opa:opa 600`, `opb:opb 600`, `ioc-srv:ioc 600` in the log directory, three retained `dbl` lines for opa |
| T2 | after 2026-09-26T05:53:54Z | Both test consumers | PASS | `/var/log/procserv/histsys.iocsh_history` as `ioc-srv:ioc 600` after stop, zero history lines in `histsys.log` after the second cycle; `~usera/.iocsh_history-histloc` as `usera 600`; the pre-allocated `.iocsh_history` in each IOC directory untouched |
| T3 | after 2026-09-26T06:10:30Z | Both test consumers | PASS | `opb` and `ioc-srv` print the loading error and `Operation not permitted (1) writing` (readline 8.2) or `Unknown error -1 (-1) writing` (readline 7.0); the file stays `opa:ioc 600` |
| T4 | 2026-09-26T06:18:16Z | Development host | PASS | `git diff --check` clean |

##### Closure Evidence

- FAQ Q13, the Q5 pointer, and CLOSED_DOORS CI-44 landed in `d1ee7cb` on
  `release-1.4.2`; CI-44's carrying commit is `d1ee7cb`.
- Verification: T1-T4 passed as recorded above.
- Landing: `git fetch` at 2026-09-26T18:54:03Z observed
  `origin/release-1.4.2` at `d1ee7cb00b3a694824fda590dd07ddb6c6bdb0cb`.
- Linked issue: #162 body updated with the resolution and checked acceptance
  criteria, and closed as completed at 2026-09-26T18:58:04Z.

##### GitHub Projection

Title: Document iocsh history ownership across principals
Labels: docs, P3-low, area/permissions
GitHub Milestone: 1.4.2
Observed State: closed (completed)
Observed Labels: docs, P3-low, area/permissions
Observed Milestone: 1.4.2 (19)
Last Compared: after 2026-09-26T18:58:04Z with `gh issue view 162`; issue updated at 2026-09-26T18:58:04Z; the body carries the resolution and checked acceptance criteria

#### M8 - Revise and supplement the published documentation against the current code

Origin: 1.4.2 / M8
Identity History: none
GitHub Issue: none
Status: In progress

##### Summary

The mdBook site added in 1.4.1 (`book.toml` with `src = "docs"` and
`docs/SUMMARY.md`) publishes the existing `docs/` pages: twelve pages, about
3000 lines, first written between 2026-03 and 2026-09, ten of them last
changed in 2026-09 alongside the code. A survey on 2026-09-28 found their
faults in organization and coverage rather than accuracy: pages that mix
concept, procedure, and reference material; system and local guides that
repeat the same steps; a CLI reference that covers six of the fifteen
commands; release history in the book introduction; and no glossary. Under
D12 the pages are revised and supplemented against the current code rather
than written again.

##### Scope

- Every page listed in `docs/SUMMARY.md`: `README.md`, `INSTALL.md`,
  `UNINSTALL.md`, `USER_GUIDE.md`, `USER_GUIDE_LOCAL.md`, `CLI_REFERENCE.md`,
  `FAQ.md`, `ARCHITECTURE.md`, `PERMISSION_MODEL.md`, `NETWORK_ENV.md`,
  `LOG_LAYOUT.md`, and `EXIT_SIGNAL_HANDLING.md`, and `SUMMARY.md` itself.
- The 1.1.0 Migration section of `CHANGELOG.md`, which receives the 1.0.x
  upgrade steps from the book introduction.
- A new `docs/GLOSSARY.md`, listed in `docs/SUMMARY.md`.
- Check every statement against the current `bin/ioc-runner`,
  `bin/setup-system-infra.bash`, the unit and container templates, and
  observed runs, including the M6 `generate` behavior.

Out of scope: `docs/CLOSED_DOORS.md`, the milestone registers, `docs/adr/`,
`docs/review_sessions/`, the test documentation under `tests/`, the gate
runbook, and any change to runner behavior.

##### Completion Criteria

- The published pages are revised and supplemented for an operator who
  installs, runs, and troubleshoots IOCs: inaccurate text is corrected,
  missing material is added, and material repeated across pages is kept in
  one place.
- Every command, option, path, and output the pages show matches the
  current code and a real run.
- Links inside the book and from files outside it that point into `docs/`
  resolve, and the mdBook build passes.
- Every outcome D13 and D14 name is present in the pages: the glossary page,
  the `SUMMARY.md` groups, the upgrade steps in `CHANGELOG.md` without the
  pointer, the troubleshooting questions in `FAQ.md`, and no history words
  in page prose.

##### Dependencies And Decisions

- D12 supersedes the owner direction of 2026-09-26 to rewrite the whole
  published documentation set without regard to the previous pages.
- M6 changes `generate` and adds its CLI reference section; the revision
  starts from the landed M6 behavior.
- D13 settles the book structure, the file names, and the treatment of
  history in the book introduction; D14 keeps the manual setup and
  permission verification sections on their pages.
- Owner direction 2026-09-26: the revision lands in the 1.4.2 release, before
  the release cycle opens.
- Decision Date: 2026-10-01. Container console checks use Docker read-only
  client masks without added capabilities. The unavailable-client case also
  excludes socat names from the native-tool PATH mirror, as the shipped
  rejection fixture does.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-10-01; owner accepted the 2026-10-01 verification-plan revision after four third-person passes and one second-person pass
Implementation Authorization: 2026-10-01; owner authorized the accepted 2026-10-01 verification-plan revision
Superseded Plan Artifacts: the original accepted plan in `222ab3c`

The original plan was accepted and authorized on 2026-09-28. The
2026-10-01 direction accepted the plan review findings and evidence
reconciliation for incorporation. The owner accepted the resulting
verification-plan revision on 2026-10-01 after the four third-person passes
and the first second-person pass. The owner separately authorized
implementation of this accepted revision on 2026-10-01. Password,
multi-interface, and optional deletion cases retain the concrete-plan
approval conditions in execution step 3.

1. Inventory. List every command, global option, command option, path,
   mode, and printed message that `bin/ioc-runner`,
   `bin/setup-system-infra.bash`, and the unit and container templates
   expose, and map each to the page that states it or mark it missing.
   The inventory is a working file under `work/`; its gaps drive items 2
   through 8, and its counts go into Verification Results.
2. `docs/CLI_REFERENCE.md`: add a section for each command it lacks
   (`install`, `remove`, `start`, `stop`, `restart`, `status`, `enable`,
   `disable`, `view`) and one for the options (`--local`/`--user`,
   `--container`, `-f`/`--force`, `-n`/`--lines`, `-v`, `-vv`,
   `--detach-key`, `-V`/`--version`, `-h`/`--help`), each with its usage,
   the modes it applies to, and its exit behavior. `-f` is one flag with
   two meanings: overwrite without a question for `generate` and `install`,
   follow for `log`. The `start` and `restart` sections absorb the existing
   Lifecycle Preflight Diagnostics section; the other existing sections
   stay.
3. `docs/USER_GUIDE.md` and `docs/USER_GUIDE_LOCAL.md`: the console, list,
   direct-console, and version steps the two repeat are kept in
   `USER_GUIDE.md`, which states the system and local values side by side
   where they differ (socket path, log path, `--local`); `USER_GUIDE_LOCAL.md`
   keeps only the local-specific steps and links to those sections. Daily
   operations lead with the runner commands and name direct `systemctl` as
   the bypass.
4. `docs/INSTALL.md`, `docs/ARCHITECTURE.md`, `docs/LOG_LAYOUT.md`: prose
   that restates a mode, owner, or ACL value links to `PERMISSION_MODEL.md`,
   which states each value once; a command that sets a value stays where it
   is. Move the troubleshooting table of `LOG_LAYOUT.md` into `FAQ.md` as one
   question per symptom. Under D14 the Manual Setup Reference section of
   `INSTALL.md` and the Verification section of `PERMISSION_MODEL.md` stay
   as their own headed sections.
5. `docs/README.md` (book introduction): remove the 1.0.x upgrade section,
   the release runbook entry, and the milestone register entries; move the
   upgrade steps into the 1.1.0 Migration section of `CHANGELOG.md` in place
   of its pointer. Its Documentation Index follows the `SUMMARY.md` groups of
   item 7 and lists the glossary.
6. `docs/EXIT_SIGNAL_HANDLING.md`, `docs/NETWORK_ENV.md`, `docs/FAQ.md`,
   `docs/UNINSTALL.md`, `docs/PERMISSION_MODEL.md`: check every statement
   against the code and correct what differs.
7. `docs/GLOSSARY.md`: a new page defining each term the book uses once.
   `docs/SUMMARY.md` keeps the introduction first and groups the pages, with
   no file renamed: Guides (`INSTALL.md`, `UNINSTALL.md`, `USER_GUIDE.md`,
   `USER_GUIDE_LOCAL.md`, `FAQ.md`), Concepts (`ARCHITECTURE.md`,
   `PERMISSION_MODEL.md`, `EXIT_SIGNAL_HANDLING.md`), and Reference
   (`CLI_REFERENCE.md`, `NETWORK_ENV.md`, `LOG_LAYOUT.md`, `GLOSSARY.md`).
8. All pages: headings in sentence case without numbering; none of the
   history words `now`, `still`, `new`, `no longer`, or `previously` in
   page prose; ASCII punctuation. Every in-repository link to a changed
   heading is updated; on 2026-09-28 the anchor links into `docs/` sit only
   in `USER_GUIDE.md`, `USER_GUIDE_LOCAL.md`, `CLI_REFERENCE.md`, and
   `FAQ.md`, so no out-of-scope file changes.

###### Remaining verification execution plan

The following five steps refine implementation items 1 through 8. They
cover the thirteen published pages, `SUMMARY.md`, and the moved 1.1.0
Migration content in `CHANGELOG.md`. Runner behavior remains outside M8.

1. **Refresh the source snapshot and claim list.** Pin HEAD, working-tree
   source hashes, build configuration, and the actual mdBook image ID.
   Render the original pages and rebuild inline and fenced inventories
   against that output. Separate prose into independently verifiable
   statements and reconcile the code-to-document surface inventory with
   the document-to-code list. Record each statement's source range, text,
   source hash, configuration or implementation reference, applicable
   mode and OS, and expected output, exit, state, or metadata. A mentioned
   mode or OS is only a candidate until its applicability is resolved.
   Every statement receives a disposition; prose without an executable
   claim receives a reason and its source comparison. A source edit
   invalidates affected classifications and evidence links. Refresh them
   in a separate snapshot and retain the historical inputs unchanged.
   Completion: native rendering matches both inventories, every source
   surface and document statement is accounted for, and all input hashes
   match the selected snapshot.
2. **Compare existing evidence at claim level.** For each applicable
   statement/mode/OS case, record the actual runner path and hash, fixture,
   principal, environment, expected result, observed result, exact log
   lines, and verdict. Use `Verified`, `Partial`, `Pending`, or `Mismatch`
   for comparisons; retain the separately recorded failed-run status.
   Reuse evidence only after confirming the current statement, relevant
   implementation, fixture, and environmental preconditions agree with
   that executed case. Store each execution in a unique directory without
   overwriting an earlier run. Bind its logs and source manifest with
   SHA256 hashes, and record its observation time, HEAD, and input identity.
   Before reuse, verify those hashes and confirm that the cited logs,
   manifest, and recorded result belong to the same execution. A source
   manifest alone does not establish a log's execution identity. Mark an
   unresolved historical evidence link as unconfirmed; retain the reported
   observation without treating that link as sufficient evidence.
   Historical exit matches and overlapping source
   ranges do not establish whole-statement coverage. Completion: every
   applicable case has either sufficient native evidence or a specific
   remaining execution case; no mismatch or partial result is hidden.
3. **Execute the remaining cases in order.** Freeze the finite execution
   list from step 2 before each batch, with its document statements and
   expected results. First check installed help, version, argument errors,
   and read-only queries. Then check documented local paths, overrides,
   ownership, history settings, and manual-run workflows; follow with
   the outstanding documented system and container cases. Use the two
   dedicated Debian 13 and Rocky 8 consumers for applicable host cases
   and the selected default image for container cases. Record installed
   runner identity and installation provenance before executing a case;
   source-only probes remain identified as source probes. Run the shipped
   CLI, scripts, templates, and native components through the documented
   path without substituting an internal span. Finish the batch's
   restoration checks before recording its result.
   Password-authentication cases require a concrete plan naming the test
   identity, temporary policy, authentication path, and restoration.
   Multi-interface cases require selected interfaces, addresses, actual
   CA/PVA binding and traffic observations, and restoration checks.
   Optional deletion cases require explicitly selected disposable
   identities and resources with preflight and residual-state checks.
   Present these plans for owner approval before their state changes.
   Existing VM service identities, payloads, logs, and backups are retained.
   Completion: every selected case has observed output and state plus
   restoration evidence; unapproved and unexecuted cases remain pending.
4. **Apply accepted discrepancies and refresh affected checks.** Present
   each mismatch with its document clause, actual observation, and proposed
   correction. Apply only owner-accepted corrections in the M8 scope.
   Refresh the affected claim rows, source hashes, and evidence links, and
   rerun the affected documented paths when the claim or implementation
   changed. Preserve failed and superseded snapshots as historical records.
   Completion: each mismatch is corrected and verified, or has an explicit
   owner ruling; planned checks are never recorded as observed passes.
5. **Verify the final candidate and review the whole artifact.** After the
   public pages stop changing, rerun T1, T2, and T4 against one source-hash
   snapshot, and finish T3 comparisons against that candidate. Run T5 over
   all thirteen pages, `SUMMARY.md`, and the changed Migration content.
   Run T6 against implementation items 2 through 8, D13, and D14, including
   the glossary, page groups, upgrade steps, retained manual sections, and
   one authoritative location for consolidated material. Map every review
   finding to that scope and its evidence. A subsequent correction
   invalidates affected results and requires the relevant pass again.
   Completion: final T1 through T6 satisfy their own criteria with matching
   source hashes, and all findings are resolved or explicitly ruled on.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | build | From the repository top, `docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/book -w /book jeonghanlee/mdbook mdbook build`, the image the Pages workflow uses | Control host | Exit 0 with no warning |
| T2 | links | A Bash check under `work/` of every relative link and anchor in the published pages, the top-level `README.md`, `CHANGELOG.md`, `gate/RUNBOOK.md`, `tests/README.md`, `docs/adr/`, and `bin/setup-system-infra.bash` against the files and the heading ids of the T1 build | Control host | Every link resolves |
| T3 | commands | With the runner of the current tree installed, run every command a page shows, as shown with placeholders replaced, and compare its output with the page. The commands of `INSTALL.md` and `UNINSTALL.md` change accounts, sudoers, and units, so they run only on a consumer that is set up again afterwards, and only after owner approval | Test consumer in system and local mode; one default image of `tests/run-container-tests.bash` for container commands | Each command runs and prints what the page shows |
| T4 | static | `LC_ALL=C grep -nP "[^\x00-\x7F]"`, a word-bounded `grep -nwE` for `now`, `still`, `new`, `no longer`, and `previously`, and `tests/check-doc-addresses.bash` over every published page; the item 1 inventory has no missing entry | Control host | No non-ASCII hit other than the semantic glyphs that markdown-authoring section 7 allows, no history word in page prose: each hit is judged and recorded, a word that compares with an earlier state of the runner or the pages fails, and a word that describes current behavior (`a new IOC`, `the IOC is still running`) passes, no address failure, no missing entry |
| T5 | review | Second-person review pass over the changed pages before commit | Control host | Every finding resolved or ruled on by the owner |
| T6 | review | Third-person pass that walks plan items 2 through 8, D13, and D14 one by one against the changed pages, including that the material item 3 and item 4 consolidate appears in one place only | Control host | Every item carried out, or ruled on by the owner |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-29T15:48:21Z | Control host; Pages mdBook image | Historical PASS; evidence linkage unconfirmed | Reported mdBook build exited 0 without warnings after both review corrections; historical input hashes in `work/m8-review-fixes-sources.sha256`. The shared `work/m8-review-fixes-build.log` has no time or HEAD metadata and is also cited by the 2026-10-01 run; its linkage to this observation is unconfirmed. |
| T2 | 2026-09-29T15:48:21Z | Control host; T1 HTML and supplemental mdBook rendering | Historical PASS; evidence linkage unconfirmed | Reported `bash work/m8-check-links.bash` result: 22 Markdown source pages plus setup script, 147 local references, 0 failures; 8 external URLs excluded. The shared `work/m8-review-fixes-links.log` records 2026-10-01T05:06:26Z and 171 local references; it does not substantiate this historical row. |
| T3 | 2026-09-29 through 2026-09-30 UTC | Control host, Debian container, dedicated Debian 13 and Rocky 8 VMs | Pending | Actual container suite: 64 PASS; thirteen targeted local CLI errors agree. Both VMs passed selected local/system lifecycles, document-derived infrastructure removal, and full setup afterwards against `c558513`. Every book command has not been executed; details below. |
| T4 | 2026-09-29T15:35:16Z | Control host; incremental inventory update and 13 published pages | PASS | 352 covered, 0 partial, 0 missing after the final 66 updates; `work/m8-coverage-completion.md` and `work/m8-coverage-completion.sha256`. ASCII, history-word, address, and diff checks pass; `work/m8-coverage-static.log`. Coverage is static evidence. |
| T5 | 2026-09-30 | Control host; published book and subsequent corrections | Pending | Whole-book reading and accepted INSTALL corrections are recorded. The five-file correction set in `ecde536` passed its second second-person review after a contradictory INSTALL opening sentence was corrected. The subsequent three-file correction set and the latest two-file correction set each passed their first second-person review. Comparison with unexecuted commands remains open; details below. |
| T6 | 2026-09-30 | Control host; published book and dedicated Debian 13 and Rocky 8 VMs | Pending | The plan-by-plan whole-book pass found incorrect sudo glob authorization claims and repeated permission values. Both accepted findings were corrected in `ecde536`. Later whole-book passes found an obsolete heading reference, missing glossary terms, and an inaccurate runtime-only FAQ claim; all were corrected. The fifth whole-book pass found a removal-verification conflict and an incorrect local primary-group assumption; both were corrected and checked on the dedicated VMs. A final whole-book pass after those corrections remains open; details below. |

These rows retain their reported observations. The historical T1 and T2
same-run evidence links are unconfirmed; the source manifest does not bind
the current shared logs to the 2026-09-29 execution. Recover matching
original artifacts before reusing those observations as verified evidence.
The 2026-10-01 logs are preserved separately below. Final T1, T2, and T4
results against one finalized document candidate remain Pending, alongside
T3, T5, and T6. The remaining-verification plan above defines their refresh
and acceptance criteria; the historical PASS rows do not close that step.

The historical T1 and T2 rows report a working tree based on `c4304b0`, including the
six pages that cover the remaining diagnostics and infrastructure lifecycles,
plus the accepted local-cleanup ordering and diagnostic-scope corrections.
The build image ID was
`sha256:2b53e59ebf0edf2913e0636ff2e31351f0f0c4c7593fb51d1f22b4b629173015`.
T2 reads links from rendered article content and checks published target
anchors against T1 HTML. For pages outside the book, it renders repository
Markdown with the same image and checks the generated IDs. It also checks
repository-relative documentation paths in `bin/setup-system-infra.bash`.
Supplemental evidence is under `work/m8-links.kNcjdK/`. The pre-review build
and link evidence remains in `work/m8-coverage-build.log`,
`work/m8-coverage-links.log`, and `work/m8-coverage-sources.sha256`.
The original logs and hashes remain in `work/m8-t1-build.log`,
`work/m8-t2-links.log`, and `work/m8-t1-sources-062115.sha256`.
The subsequent reference-correction results remain in
`work/m8-followup-build.log`, `work/m8-followup-links.log`, and
`work/m8-followup-sources.sha256`. The current checker input manifest is
`work/m8-t1-sources.sha256`. These results do not complete T3, T5, or T6.

T3 preparation: `work/m8-current-command-candidates.md` records the snapshot
before the two review corrections: 100 fenced blocks and 180 inline command
candidates. Refresh it against the selected execution candidate before use.
Configuration, output, symbolic syntax, and command
fragments need classification before execution. The earlier
`work/m8-t3-code-blocks.md` remains historical evidence. Full execution and
comparison remain pending. The dedicated-VM results below cover selected
installation, operation, and removal commands; the candidate list still needs
a command-by-command comparison for the remaining book content.

Seven real runner calls confirmed system/local configuration-path rejection
and help/version/no-command bypass (`work/m8-followup-runner.log`).
At 2026-09-29T15:35:16Z, thirteen additional real local runner calls confirmed
missing-target errors for twelve commands and invalid-directory rejection
for `generate`; each exited 1 (`work/m8-coverage-runner.log`).

The shipped `tests/run-container-tests.bash` ran with
`jeonghanlee/debian13-epics:latest` against the source runner and actual s6
services: 64 PASS, 0 FAIL, 0 SKIP, 0 not applicable, and 0 script errors.
The log is `work/m8-coverage-container/jeonghanlee_debian13-epics_latest.log`.
Its image ID is
`sha256:8e55df14fec16dacfe70095540b2fd110172a62e9cdd1360aaa70e8996d03889`.
This is partial T3 evidence, not verification of every book command.

T3 selected lifecycle verification, observed 2026-09-29 through
2026-09-30 UTC, used dedicated Debian 13 and Rocky Linux 8.10 VMs and
candidate `c558513f0c8cc9f2c277801cd9d8d4455ecceaef`. EPICS Base R7.0.10
was built on each VM. The startup fixture uses the actual printf/chmod/chgrp
lines from `tests/test-container-lifecycle.bash`, with real native softIoc,
procServ, and systemd. Local installation, generate, install, start, status,
view, log, list, inspect, enable, disable, restart, stop, and remove passed on
both VMs. Configuration and socket paths were removed; the shared rotation
timer, payload, and log remained.

System verification on both VMs exercised the installed runner through
`vmadmin` in the `ioc` group. The documented shared-directory permissions
and default ACLs were configured, and home traversal allowed the service
account to reach the built Base. Generate, install, start, status, view,
log, inspect with sudo, enable, disable, restart, stop, and remove passed.
Debian additionally passed forced system log rotation with an active IOC and
retained a nonempty compressed log. The shipped launcher ran full setup;
Rocky's includedir was made the final active sudoers directive with existing
rules preserved and visudo validation. SELinux remained Enforcing.

The selected `UNINSTALL.md` blocks removed system infrastructure and the
dedicated service account on each VM. They retained the group, payloads,
backups, and logs, transferred retained log ownership to root, and checked
that system artifacts and the account were absent. Full setup afterwards
passed all checks: Debian 10/10 and Rocky 13/13. The installed version matched
`c558513`. A fresh IOC name passed another real lifecycle after setup on each
VM; Debian's second cycle used a root operator, while Rocky's used vmadmin.
No tested system IOC remained loaded after removal. Both VMs are retained;
the approved permission settings remain configured.

Evidence is under `work/m8-doccheck-vms/`: `result.txt`,
`sources.sha256`, and per-OS `local-continuation.log`,
`system-vmadmin-lifecycle.log`, `system-uninstall.log`, and
`setup-reinstall.log`. Debian's `system-lifecycle.log` and
`system-reinstall-lifecycle.log` record the root-operated cycles and rotation;
Rocky's `setup-approved.log` and `system-reinstall-vmadmin-lifecycle.log`
record the accepted setup and second operator cycle. The source hash manifest
pins the historical documents, runner, and setup scripts used for that run. These are selected command
results, not completion of every book command or the full Release Gate.
T3 stays Pending, T5 and T6 stay Pending, and M8 stays In progress.

Additional T3 observations on 2026-09-30 used the same dedicated VMs and
runner candidate `c558513`. Evidence is under `work/m8-doccheck-vms/`:

- Both VMs completed Makefile setup/install, CLI-only setup, the manual CLI
  deployment block, and installed Bash completion checks. Installed runner
  ownership/mode was `root:root 0755`; completion was `root:root 0644` and
  matched source. See per-OS `installation-probes.log` and
  `completion-probes.log`.
- The additional lifecycle probes completed on both VMs, including direct
  service commands, log permissions, group-created files, and local aliases.
  Follow commands intentionally ended with timeout status 124. See per-OS
  `remaining-probes.log` and `manual-lifecycle.log`.
- Actual PTY console checks completed eight local and twelve system/container
  connections: attach with default/custom detach keys, monitor, and direct
  con. Services, sockets, and procServ PIDs survived detach. Monitor produced
  no output from Enter; this is the observed input check, not exhaustive
  keyboard verification. See `console-terminal-results.json` and
  `system-container-console-results.json`. Container setup passed 6/6;
  its runner stamp was unknown, with source content compared excluding the
  three version assignments. This does not establish candidate provenance.
- Manual infrastructure deployment and subsequent real IOC probes completed
  on both VMs. Existing accounts/groups were retained, so their creation
  commands were not exercised. Debian omitted explicitly SELinux-conditional
  commands; Rocky used the documented old-sudo glob policy. See
  `debian13/manual-infrastructure.log`,
  `rocky8/manual-infrastructure-retry.log`, and per-OS `manual-lifecycle.log`.
- The existing ansible-provision `nfs_sim` role configured only the two
  dedicated VMs. Real NFS checkout access reproduced root_squash: owner
  access succeeded while root access failed. The full launcher, make setup,
  and make install then succeeded from that checkout. See
  `nfs-provision.log` and per-OS `nfs-install.log`.
- A separate temporary NFS payload mount at `/opt/epics-iocs` completed real
  IOC generate/install/start/status/view/log/restart/stop/remove on both VMs.
  A separate service-account write probe was `ioc-srv:ioc 0664`; it was not
  generated by the IOC. After unmount, original local directory names and
  parent metadata matched the pre-mount observations; old payload contents
  were not hash-compared. See per-OS `nfs-payload-mount.log`,
  `nfs-payload-lifecycle.log`, and `nfs-payload-unmount.log`.
- Hand-written system/local configuration examples produced the documented
  metadata, decoded crash pattern, shared site.env values, and per-IOC
  overrides in the real softIoc child environment. Sandbox generate/install
  and removal also completed; sandbox startup was not tested. Interrupted
  scripts remain recorded as failures, with subsequent successful checks
  recorded separately. See per-OS `config-examples*.log` and
  `sandbox-example.log`.

As reconciled on 2026-10-01, the selected manual account/group creation
and fstab-entry plus mount-by-target cases have executed with native
evidence below. Remaining T3 coverage includes the password-authentication
sudo alternative, multi-homed interface binding, selected optional resource
deletion, and the pending claim/mode/OS comparisons. Reboot recovery and
separate-host NFS behavior are outside the completed fstab case. Network
interface changes and optional deletion targets were not selected. No
remaining check is waived. Both VMs, retained payloads/logs/backups, and
NFS resources remain available; cleanup is separate.

The 2026-09-30 book build and link scan are recorded in
`work/m8-current-build.log` and `work/m8-current-links.log`: 22 pages,
147 local links, zero failures, and eight external links excluded.
`work/m8-current-sources.sha256` matched the published inputs when rechecked
on 2026-09-30. These supplement the historical T1/T2 rows above.

T5 whole-book reading on 2026-09-30 covered all thirteen published pages,
SUMMARY, and the CHANGELOG 1.1.0 Migration section. Three INSTALL findings
were accepted and corrected: NOPASSWD versus cached sudo access, explicit
root execution for manual setup, and the distinction between time-sync.target
ordering and actual clock synchronization. The subsequent INSTALL review
sequence was second-person, third-person, and second-person; no additional
actionable finding was reported. These chat reviews are recorded here;
there is no independent-reviewer artifact. T5 remains Pending because the
remaining actable claims have not all been compared with real command output.

The scoped third-person pass directly observed `sudo -n true` exit 0 on both
VMs, time-sync.target active with `NTPSynchronized=no`, and the installed unit
as `root:root 0644`. On Debian, actual root launcher and non-root direct setup
calls both rejected invocation with exit 1. A subsequent T6 pass walked
plan items 2 through 8, D13, and D14 across the book; its accepted
corrections and remaining final check are recorded below.

Correction evidence, observed on 2026-09-30, carried by
`ecde53646df112f88a9fe8b05ac196a9a1c1d0c2`:

- The whole-book third-person pass found a must-fix authorization claim:
  sudo argument globs can span additional unit arguments and authorize
  unrelated services. The actual Rocky 8 installed policy query,
  `sudo -n /usr/bin/sudo -l -U ioc-srv /usr/bin/systemctl start epics-@myioc.service sshd.service`,
  returned exit 0. This was a policy query; no service operation ran.
  The unrelated unit alone was denied, and the Debian anchored regex policy
  denied the combined arguments.
- The accepted minor finding consolidated repeated permission values into
  the reference tables, retaining setting commands and verification examples.
- The commit contains `bin/setup-system-infra.bash`, `ARCHITECTURE.md`,
  `FAQ.md`, `INSTALL.md`, and `PERMISSION_MODEL.md`. Its setup warning,
  source comments, generated policy comments, and document descriptions
  identify the broader glob authorization. The sudoers authorization lines
  were unchanged; the policy exposure was not mitigated.
- The corrected five-file set received two standalone second-person
  self-review passes. The first found an INSTALL opening sentence that
  contradicted the glob warning. The sentence was corrected; the second
  found no additional actionable finding. No independent reviewer participated.
- Actual mdBook build exited 0 without warnings. The actual rendered-link
  scan checked 22 pages and 168 local links with zero failures; eight
  external links were excluded. Evidence is in
  `work/m8-second-person-fixes-build.log`,
  `work/m8-second-person-fixes-links.log`, and
  `work/m8-second-person-fixes-sources.sha256`.
  Bash syntax, ShellCheck, and `git diff --check` passed.
- T3 and T5 remain Pending because every actable claim has not been compared
  with executed output. T6 remains Pending until the corrected whole book
  receives its final plan-by-plan third-person check. M8 remains In progress.

Additional documentation correction evidence, observed on 2026-09-30,
against `46fff66786de2ae40424f81cd89b92a01d5886e3` plus the current
working-tree changes:

- The third whole-book third-person review found an obsolete heading
  reference in `PERMISSION_MODEL.md` and missing NFS, SSSD, LDAP, and
  NOPASSWD glossary entries. The reference links to the current heading,
  and each term has one entry in `GLOSSARY.md`.
- The fourth whole-book third-person review found that the manual-testing
  FAQ called its effects runtime-only despite its `disable` and `enable`
  steps. `FAQ.md` states that runtime state and boot-time auto-start settings
  change. A focused comparison with the runner's command dispatch found no
  further issue in that correction; service commands were not rerun.
- Before the FAQ correction, the actual mdBook build exited 0 without
  warnings, and the rendered-link scan checked 22 pages and 171 local links
  with zero failures; eight external links were excluded. Evidence is in
  `work/m8-fourth-third-person-build.log` and
  `work/m8-fourth-third-person-links.log`; the corresponding public-document
  input hashes are in `work/m8-glossary-fixes-sources.sha256`. These hashes
  and build results precede the FAQ prose correction.
- The first standalone second-person self-review of the three-file correction
  set found no additional actionable finding. It covered the corrected FAQ
  explanation, all four glossary definitions, and the permission-model link.
  The three rendered heading targets exist, command blocks match HEAD, and
  `git diff --check` passed. No independent reviewer participated.
- T3 and T5 remain Pending because every actable claim has not been compared
  with executed output. T6 remains Pending until the final whole-book check
  includes the FAQ correction. M8 remains In progress.

Additional correction and runtime evidence, observed on 2026-10-01 UTC,
against `87aa67c6183a56018d367bc3bcfc99187aaa0c67` plus the two
working-tree document corrections:

- The fifth whole-book third-person review identified two plan-item-6
  findings: `UNINSTALL.md` required a preserved alternative installation
  to be absent, and `PERMISSION_MODEL.md` assumed identical user and
  primary-group names. Both accepted findings are corrected. The first
  second-person self-review of this two-file correction set found no
  additional actionable finding; no independent reviewer participated.
- The actual mdBook build passed without warnings. The rendered-link scan
  checked 22 pages and 171 local references with zero failures; eight external
  links were excluded. All 23 Bash blocks in `UNINSTALL.md` passed `bash -n`.
  The link log records 2026-10-01T05:06:26Z and source HEAD `87aa67c`.
  Preserved evidence is under
  `work/m8-verification-runs/20261001T050626Z-87aa67c-recheck/`:
  `work/m8-review-fixes-build.log`, `work/m8-review-fixes-links.log`, and
  `work/m8-doccheck-vms/recheck-evidence.sha256`, with its referenced inputs
  and runtime artifacts at their original relative paths. `capture.sha256`
  binds every copied artifact and `provenance.txt` states the observed
  identity and coverage limits. The original manifest identifies two public
  document inputs; it is not a full-book input manifest. This preserved run
  does not substantiate the 2026-09-29 T1/T2 rows or final candidate checks.
- On both dedicated doccheck VMs, the approved `m8operator` account used
  primary group `m8group`. The current runner generated and installed the
  configuration and started real native softIoc under procServ and user
  systemd. Observed owner/group and modes were `m8operator:m8group 750`
  for the log directory, `640` for the log, `770` for the console directory,
  and `660` for its socket. The IOC was stopped and removed afterwards.
  Evidence: each platform directory under `work/m8-doccheck-vms/` contains
  `primary-group-recheck.log`; the driver is `recheck-local.bash`.
- Selected whole Bash blocks extracted from the current `UNINSTALL.md`
  executed against the actual system paths. Debian preserved a regular
  `/usr/bin/ioc-runner` file; Rocky preserved a symlink to a separate runner
  copy. Removal verification exited 0 on both. File content and metadata
  checks confirmed preservation; retained service identities and the log
  tree fingerprint remained unchanged. Existing accounts, logs, payloads,
  and backups were retained. Evidence: each platform directory contains
  `uninstall-preservation-recheck.log`; `recheck-uninstall-ready.bash`
  contains the executed blocks and surrounding state checks.
- Full setup from the transferred working tree restored system infrastructure:
  Debian passed 9/9 checks and Rocky passed 12/12. Both installed runners
  reported `87aa67c-dirty`; full `visudo -c` passed. The cloud-owned
  `/etc/sudoers.d/91-cloud-provision-validation` hash was unchanged.
  Rocky setup also confirmed that includedir was the final active directive.
  The approved test account, group, local shared files, and evidence remain.
- These are selected T3 results, not execution of every published command
  or a Release Gate. T3 and T5 remain Pending. T6 remains Pending until a
  final whole-book review includes these corrections. M8 remains In progress.

T4 coverage is 352 covered, 0 partially covered, and 0 missing entries.
`work/m8-followup-coverage.md` records the first 30 updates;
`work/m8-coverage-completion.md` maps the final 66 entries to source and
current documentation. Unchanged classifications retain the original full
inventory assessment; this is not an independent full audit. Counts describe
inventory entries, not independent defects. All 11 original mismatch entries
have corrected text by static comparison; their runtime verification remains
part of T3. No entry was waived or removed. The fresh static scan has no
non-ASCII hit, and the address guard passes for twelve per-file distinct
addresses. Every history-word hit describes current behavior, procedure
state, or literal command/output; none compares documentation or runner
releases.

The earlier scoped second-person review covered three UNINSTALL references,
local configuration/log-path requirements, and local logrotate path and tool
selection. This turn's first-person reading covers the six pages' 66-entry
additions, including partial installation state and retained shared resources.
Neither scoped reading completes the whole-book T5 or plan-by-plan T6.
Full reviews must compare the text against the remaining actual command runs.

The scoped third-person review found two documentation defects: the local
cleanup sequence called the CLI after deleting it, and the missing-config
paragraph applied the stale-directory hint to commands that do not emit it.
Both corrections were accepted and applied on 2026-09-29. Local IOC removal
is a prerequisite to system uninstall, with a check before CLI deletion;
the diagnostic paragraph lists the applicable commands and modes. T1/T2
passes for that corrected snapshot were reported on 2026-09-29, but their
same-run evidence links remain unconfirmed as recorded above. Those
historical reports do not establish verification of the current candidate.
The review also recalculated 352 covered entries with 96 unique incremental
updates and reran the real Debian container suite: 64 PASS, no failures or
skips. These scoped checks do not close T3, T5, or T6.

Item 1 inventory, 2026-09-28, from the source at `222ab3c`: 352 surfaces
(36 command rows, 48 options, 53 paths, 215 printed messages), of which 148
are stated on no page, 101 of them `ioc-runner` messages. Eleven page
statements differ from the code: the manual unit in `INSTALL.md` lacks the
`site.env` line and leaves `${IOC_CHDIR}`, `${IOC_PORT}`, and `${IOC_CMD}`
unescaped; the sudoers example in `ARCHITECTURE.md` pads the verbs; the
local template mode in `PERMISSION_MODEL.md`, the local asset replacement
in `USER_GUIDE_LOCAL.md` and `PERMISSION_MODEL.md`, the system-mode
`IOC_RUNNER_LOG_DIR` behavior in `LOG_LAYOUT.md`, the FAQ Q11 message, the
scope of `IOC_RUNNER_PROCSERV_TOOL` and `IOC_RUNNER_SYSTEM_LOG_DIR`, and the
container `status` output differ. The working file is `work/m8-inventory.md`.

Current scoped verification reconciliation, observed 2026-10-01 UTC,
against `87aa67c6183a56018d367bc3bcfc99187aaa0c67` with the working-tree
document corrections:

- Manual account/group creation: the exact `INSTALL.md` Bash block ran
  on isolated Debian 13 and Rocky 8 containers where both identities were
  absent. Both blocks exited 0. Native account records confirmed the ioc
  primary group, executable nologin shell, locked password, and absent home.
  The disposable containers were removed; existing VM identities remained.
  This closes the selected creation comparison, not deletion or full
  container setup. Evidence: `work/m8-doccheck-containers/account-create-evidence.txt`,
  its SHA256 manifest, and the two `*-account-create.log` files.
- fstab mount: after approval of `work/m8-fstab-verification-plan.txt`,
  both dedicated VMs ran the documented mount command by target using an
  actual temporary fstab entry and the selected existing loopback export.
  Native `findmnt` observed the intended NFS mount. Both drivers recorded
  `FSTAB_BODY_EXIT 0 RESTORE_EXIT 0`; original fstab bytes and metadata,
  unmounted target state, ACLs, payloads, exports, and cloud policy hashes
  were restored. This closes that selected path, not reboot recovery or
  separate-host transport. Evidence: `work/m8-fstab-verification-evidence.txt`,
  its SHA256 manifest, and per-OS `fstab-mount-check.log` files.
- Current source CLI probes: each VM's initial driver recorded sixteen
  matching exits and then stopped at the `status bad/name` expectation
  mismatch (expected 1, observed 3). Each separate supplemental driver
  completed sixteen cases with exit 0. Invalid `bad!name` was rejected;
  twelve commands rejected missing targets. Three local status forms
  matched the real systemctl user backend's output bytes and exit. Initial
  runs remain failed/incomplete. Evidence: `work/m8-cli-readonly-results/case-ledger.json`
  and its four native logs. These source probes do not establish every
  installed-runner or mode-specific behavior.
- The accepted CLI clarification states basename and trailing `.conf`
  handling before IOC name validation. The exact selected replacement is
  applied to `CLI_REFERENCE.md`. A fresh native mdBook build exited 0
  without warnings, and the rendered paragraph contains the explanation.
  Evidence: `work/m8-cli-target-applied/evidence.txt`, `inputs.sha256`,
  `evidence.sha256`, and `render.log`. Production code is unchanged.
- The pre-clarification classification snapshot contains 2156 inline spans,
  108 fenced blocks, and 1158 context units, with 32 scoped native evidence
  groups. The current native rendered book contains 2159 inline spans.
  The CLI source hash differs from the earlier inventory snapshot, which
  remains historical. Fresh source-position indexes are recorded below;
  semantic classification and evidence comparison remain steps 1 and 2.
  References to 136 source rows are evidence links, not completed row verdicts.
  Evidence: `work/m8-claim-audit-accepted/` and the actual rendered pages in
  `work/m8-cli-target-applied/public/`.
- The first third-person review of the five-step remaining-verification
  plan required source refresh after edits, per-claim verdict criteria,
  concrete execution and approval boundaries, and final T1/T2/T4 plus
  whole-artifact T5/T6 checks. All four findings and the scoped evidence
  reconciliation were incorporated into the reviewed draft. At that review,
  plan acceptance, implementation authorization, and final candidate
  verification remained open.
- The second third-person plan review found that the historical T2 row
  cited a log from a different execution. The owner accepted the finding
  on 2026-10-01. Step 2 requires unique preserved run directories, log and
  source-manifest hashes, and same-execution identity checks before reuse.
  Historical T1/T2 observations remain recorded with unconfirmed evidence
  linkage; the available 2026-10-01 evidence is preserved separately above.
  That correction did not rerun a check or accept or authorize the draft.
- The third third-person plan review found a remaining statement that
  incorrectly treated the historical T1/T2 rows as verified current evidence.
  The owner accepted the finding on 2026-10-01. The statement records the
  historical PASS reports and their unconfirmed same-run evidence links;
  it does not claim verification of the current candidate. At that review,
  plan acceptance, implementation authorization, and final candidate
  verification remained open.
- Plan acceptance, 2026-10-01: the fourth third-person pass and the first
  second-person pass found no additional actionable finding. Both were
  standalone self-reviews of the plan, not whole-book T5/T6 completion.
  The owner accepted the revised verification plan afterwards. At acceptance,
  implementation authorization was ungranted and final candidate
  verification remained pending.
- Implementation authorization, 2026-10-01: the owner separately authorized
  the accepted verification-plan revision. Execution begins with a fresh
  source snapshot and claim list. Case-specific approvals and final
  candidate verification remain required; no pending check is waived.

- Source refresh, 2026-10-01T20:50:27Z: captured 138 working-tree inputs
  at HEAD `87aa67c6183a56018d367bc3bcfc99187aaa0c67` in
  `work/m8-verification-runs/20261001T205027Z-87aa67c-source-refresh/`.
  The native build used immutable image
  `sha256:2b53e59ebf0edf2913e0636ff2e31351f0f0c4c7593fb51d1f22b4b629173015`,
  a read-only source mount, a separate output mount, and no network.
  It exited 0 without warnings; source hashes matched before and after
  the build. Native comparisons matched 2159 inline spans (11 multiline)
  and 108 fenced blocks across all thirteen pages. Their 1158 context
  units are source-position indexes, not completed behavioral verdicts.
  The run binds its source manifest, HTML, tools, logs, and execution
  records through 206 hashes in `capture.sha256`; its SHA256 is
  `2910c46df5fdad0b5a9320f14fbcb0aef53bcad4a8caee0a3520c3471b0215fe`.
  Evidence: `capture.json`, `build-result.json`, `build.log`,
  `inventory-execution.json`, `inline/`, and `audit/` in that run.
  This is the source-refresh build; final-candidate T1/T2/T4 remain Pending.
- Source-derived classification, 2026-10-01T21:02:58Z: fresh parsing
  includes the thirteen pages, `SUMMARY.md`, and `CHANGELOG.md`
  lines 574 through 592 (1.1.0 Migration). The current list has 1803
  statement candidates: 293 structural rows are `Non-executable`;
  1510 remain `Pending`. All 205 book headings match native output after
  explicitly normalizing mdBook's smart-quote display transformation.
  The structural verdict covers headings and table formatting only.
  Compound statements, implementation references, applicable modes/OS,
  and expected outcomes require semantic review. The lexical code index
  has 2110 surface candidates and accounts for 4687 lines in the runner,
  setup script, and completion script; token occurrence is not
  documentation coverage. Evidence:
  `work/m8-verification-runs/20261001T205027Z-87aa67c-statement-candidates-v2/`
  and
  `work/m8-verification-runs/20261001T205027Z-87aa67c-structure-classification/`,
  each with `artifacts.sha256`. The first provisional candidate list is
  retained separately; the selected v2 list separates headings from an
  immediately following paragraph. Step 1 remains incomplete.
- CLI surface mapping, 2026-10-01T20:59:25Z: all 15 top-level dispatched
  commands and 14 accepted parser option spellings have exact source
  locations and matching current documentation entries. The command
  sections and option code spans were compared with native HTML.
  Evidence:
  `work/m8-verification-runs/20261001T205027Z-87aa67c-cli-surface-map/cli-surface-map.json`
  and its `artifacts.sha256`. This maps locations; command behavior,
  command-specific arguments, paths, output messages, and setup/template
  surfaces retain their separate pending comparisons.
- CLI argument-order observations, 2026-10-01T21:23:04Z: eight literal
  argv cases ran through the captured real `bin/ioc-runner` on the Debian
  13 control host as uid/gid 1000, with `LC_ALL=C`, `SYSTEMD_PAGER=cat`,
  and `SYSTEMD_COLORS=0`. No IOC fixture or service transition was used.
  The unconditional restrictions in `CLI_REFERENCE.md` lines 32 through
  36 differ from five observed cases: `status m8unused` with `-v`, `-vv`,
  or `--detach-key ctrl-b` followed by help exits 0, as does `-v` followed
  by version and help preceding conflicting mode flags. Mode conflicts
  before help/version and an invalid line count before help exit 1.
  Results retain five `Mismatch` and three scoped `Verified` comparisons.
  Collection exit 0 does not mean all claims match. The parser reads
  left to right and exits immediately on help/version; command-specific
  validation runs later. Implementation references: runner lines 371
  through 473 and 485 through 505. Evidence:
  `work/m8-verification-runs/20261001T212304Z-87aa67c-cli-order-source-probe/`
  contains literal argv, exact stdout/stderr, expected/observed exits,
  source clauses, principal, OS, timestamps, source hashes, and results.
  Its `artifacts.sha256` SHA256 is
  `f495dc9a6fc5951151096e55c081f1c199c60372e772d3e7793717d84a61c26f`;
  every listed artifact hash was rechecked. Runner SHA256
  `7a351ffca20dc387799029e1d726530ae811aad569fe06c61b4fa243aa0a4682`
  and CLI SHA256
  `a33d9a519c4e07bbee774cba6be7072a2a3ad712a587f4338cfbc902f3b3e27d`
  match the current inputs and the source-refresh capture. This is source
  parsing evidence; installed-runner and container-runtime comparisons
  remain Pending. `work/m8-cli-order-correction-proposal.md` presents two
  replacements for the introductory paragraph: a minimal early-exit
  exception or an explicit check-order explanation. At this observation,
  owner selection was pending under execution step 4 and neither correction
  had been applied. Subsequent acceptance and execution are recorded below.
  These scoped observations do not close any parent statement verdict:
  step 1 remains incomplete with 1510 candidates Pending, and final
  T1/T2/T4, T3, T5, and T6 remain Pending. Existing snapshots are retained.
- CLI correction acceptance (Decision Date: 2026-10-01): option 1 in
  `work/m8-cli-order-correction-proposal.md` is accepted and applied exactly
  to the introductory paragraph in `CLI_REFERENCE.md` lines 32 through 35.
  Help/version exit when read, later arguments are not checked, and an
  invalid earlier argument can exit 1. The restriction bullets are retained.
  The word `still` describes a possible current exit, not a prior release.
- Correction source refresh, 2026-10-01T21:33:49Z: a separate snapshot of
  138 inputs at HEAD `87aa67c6183a56018d367bc3bcfc99187aaa0c67` is in
  `work/m8-verification-runs/20261001T213349Z-87aa67c-source-refresh/`.
  The same immutable mdBook image ran with read-only source, separate
  output, and no network. Build exit was 0 without warnings; source hashes
  matched before and after. Native HTML contains the exact selected
  paragraph. All 2163 inline spans (11 multiline) and 108 fenced blocks
  match native HTML across thirteen pages. The 206-artifact capture manifest
  SHA256 is `3eccc44e4438639da61bda5679cd6ce43139bd3469b1ee1012abfb86519616dd`.
  Source-derived indexes under the matching `-statement-candidates`,
  `-structure-classification`, and `-cli-surface-map` directories contain
  1804 candidates: 293 structural rows are `Non-executable`, and 1511
  candidates remain `Pending`. The 15 commands and 14 parser option
  spellings retain current source/document/native-HTML location mappings.
- Corrected CLI execution, 2026-10-01T21:36:18Z: the same eight literal
  argv cases ran through the captured real runner on the Debian 13 control
  host as uid/gid 1000. Every selected output and exit matched the corrected
  paragraph: eight scoped `Verified`, zero `Mismatch`. The principal,
  OS, environment overrides, literal argv, stdout/stderr, expected/observed
  exits, implementation references, and source identity are recorded in
  `work/m8-verification-runs/20261001T213618Z-87aa67c-cli-order-corrected-source-check/`.
  Its 20-artifact manifest SHA256 is
  `72dcb9c018c6c1e323b4131d977f0cb9dace022bf7d299bb4d629a5d02c869e9`.
  `affected-claims.jsonl` separates the paragraph into five semantic rows
  and links them to refreshed candidates and same-run evidence. One row
  remains `Pending` and four remain `Partial`: selected long-option source
  cases do not verify every alias, invalid argument, installed runner,
  mode, or OS. CLI SHA256 is
  `d4a3942204269065c083d8fbc440cb7a3b06952412d3229fc962e9ec886e9399`;
  runner SHA256 remains
  `7a351ffca20dc387799029e1d726530ae811aad569fe06c61b4fa243aa0a4682`.
  All 20 current published and bin inputs match the captured candidate,
  and all new artifact hashes match. The original five
  mismatches remain preserved in their unchanged run. Step 1 remains
  incomplete; final T1/T2/T4, T3, T5, and T6 remain Pending. Production
  code and VM state are unchanged by this correction.
- Installed option-restriction batch, 2026-10-01T21:58:33Z through
  21:58:36Z: a list of 262 literal cases per host was frozen before execution
  in `work/m8-verification-runs/20261001T215805Z-87aa67c-option-restrictions-installed/`.
  The actual `/usr/local/bin/ioc-runner` ran on both dedicated consumers as
  `vmadmin`, in system/local modes. Each driver exited 0: 524 scoped
  `Verified` cases and zero mismatches. Cases cover both mode-flag orders
  and the `--user` alias, `-v`/`-vv` on every non-list command,
  `--detach-key` on every non-attach command, allowed flags on empty list
  or missing-target attach, and the twelve other commands with short/long
  force and line-count forms and their combined form. Invalid zero counts
  were rejected even outside `log`.
  No IOC target was supplied and no service transition ran. The actual
  list queries reported no active sockets. Force/line-count variants had
  the same output bytes and exit as their same-run native baselines; this
  covers those missing-target and empty-list paths only.
  Installed hashes are
  `2bd6755d19e81567a3d4643f0b794cb1146162651b5325d8818b7963c3813af3`
  on Debian and
  `14edc5e19f8c163af1b5a7aa45d6369b0b35bb8394f4ad1253134ac8b6a33e5a`
  on Rocky. Both report `87aa67c-dirty`; actual installation timestamps
  are retained in each native `version.txt`. Captured installed bytes match runner
  SHA256 `7a351ffca20dc387799029e1d726530ae811aad569fe06c61b4fa243aa0a4682`
  after excluding only the three deployment-stamp assignments. Full
  original installed files, original stat metadata, version output,
  OS, principal, declared environment, literal argv, raw stdout/stderr,
  case timestamps, and exact ledger lines are retained. Runner hashes
  and account/configuration/unit-file fingerprints match before and after.
  The input manifest SHA256 is
  `8fa7c8e049b0f61f2dde7e911b8f9f09d48ba0a763a423a97490b716bad4aa68`;
  the final 1840-artifact manifest SHA256 is
  `2e096cb54a26e65ba74d1925c8e0a3979acb1c0d8bc99b716e88d8978108bba8`.
  The earlier `20261001T215709Z` preparation remains unexecuted: its driver
  had a ShellCheck warning. The separate executed driver passed Bash syntax
  and full ShellCheck before the native batch; the initial inputs are retained.
- Option statement comparisons, 2026-10-01T22:04:15Z: the three restriction
  bullets at `CLI_REFERENCE.md` lines 37 through 40 are separated into six
  semantic rows with implementation references, source hashes, applicable
  modes/OS, expected results, and exact same-run evidence. The global mode
  conflict row is `Verified`; the other five rows are `Partial` overall.
  Their scoped comparisons are fourteen `Verified` host groups, eight
  `Partial` force/line-count groups, and five `Pending` container cases.
  Here a comparison groups multiple native invocations; these counts do
  not describe defects or independent executions. Successful installed-target
  paths for force/line-count behavior and root with a live s6 backend remain
  required. Populated list columns and attach key delivery are separate
  claims. Evidence:
  `work/m8-verification-runs/20261001T215805Z-87aa67c-option-restriction-comparisons/claims.jsonl`
  and `summary.json`, bound by manifest SHA256
  `92fe5b7facdcd6aea9611523fa6c1f4ea74cd610a33a18218d1bfd10ece3f2b5`.
  The source worksheet remains the immutable base; these scoped semantic
  rows do not automatically remove its parent candidates. Step 1 and final
  T1/T2/T4, T3, T5, and T6 remain incomplete. No public correction was required
  by the observed host cases; production code, policies, and retained VM
  resources were not changed by this batch.
- Installed IOC query batch, 2026-10-01T23:34:44Z through 23:34:53Z:
  `work/m8-verification-runs/20261001T233432Z-87aa67c-target-queries-installed/`
  froze 24 cases per host before execution. Both installed runners completed
  all 48 cases as `vmadmin`, using retained real softIoc payloads: `m8local`
  for local mode and `m8console`, configured as `ioc-srv:ioc`, for system mode.
  Actual install/start preceded `status` and `view` with the baseline,
  short/long force, short/long line count, and combined flags. Every query
  returned 0. Each `view` output matched its same-run baseline byte for byte.
  Each `status` retained the same Loaded/Active/Main PID/CGroup fields after
  excluding the elapsed-time suffix; actual backend state and PID matched
  before and after every call. Dynamic resource and journal values remain
  in the raw logs and are outside this equality verdict.
  Shipped stop/remove restored configuration/socket absence and inactive
  service state. Account, configuration, unit, runner, softIoc, and selected
  startup/configuration file fingerprints matched; original log prefixes
  were preserved. Existing payloads and logs remain. Installed identities
  are unchanged from the preceding host batch. Input manifest SHA256:
  `7cffbfaef564213ab52b96a3292d975751a7bd6f47f5f9ceb0acb071a2da7ab4`;
  final manifest SHA256:
  `a3fc61e7ade201f0af493c9eb2fffb2dce70140037f39efd570dbb2a5e3dd891`.
  The original attempt at 23:32:16Z through 23:32:25Z remains preserved in
  `work/m8-verification-runs/20261001T233201Z-87aa67c-target-queries-installed/`.
  Its two drivers exited 1 after twelve matching local queries each: the
  selected `m8sandbox.conf` had local identities and real system installation
  rejected it before deployment. This is a fixture-selection failure, not a
  documentation mismatch or a completed batch. Its manifest SHA256 is
  `d5b225e677412133eef060414d0571c7b6f28df97183100d1eaf9080b8986a9d`.
  `recovery.json` in the comparison directory links the original fingerprints
  to the corrected run's preflight and confirms restoration.
- Native container restriction batch, 2026-10-01T23:38:04Z through 23:38:08Z:
  `work/m8-verification-runs/20261001T233721Z-87aa67c-container-options/`
  froze 133 literal cases before execution. The selected Debian 13 image
  ran actual `setup-system-infra.bash --container`, then its installed runner
  as root with real live `s6-svscan`. All 133 cases matched: mode conflicts,
  verbose/detach command restrictions, accepted empty-list/missing-target
  flags, unchanged force/count baselines, and invalid zero counts.
  Account/configuration/runner fingerprints matched across the cases.
  The new isolated container was removed; its absence is recorded. Source
  was mounted read-only, networking was disabled, and VM resources were
  unchanged. Installation reports unknown Git metadata because the captured
  source has no Git checkout; actual installed bytes match the current
  runner after excluding only the three deployment-stamp assignments.
  Original bytes, installation stat/version, image identity, root principal,
  setup logs, scanner process, environment, literal argv, raw output,
  timestamps, and exact case ledger lines are retained. Input manifest SHA256:
  `0e95b67a6f3f28980aea2a517121d64d4e9dfc789674d4224d10b19796f876a3`;
  final manifest SHA256:
  `1cb44fad98fad26fea4bf1bc33846c5eee5338979257aa85058d27c14f9e88d8`.
- Updated option/query comparisons, 2026-10-01T23:40:52Z:
  `work/m8-verification-runs/20261001T233721Z-87aa67c-target-option-comparisons/`
  binds fourteen scoped comparison rows to the 48 completed host queries
  and 133 container cases. Combining the preceding host evidence with these
  container comparisons gives four `Verified` restriction rows (R01-R04)
  and two `Partial` rows (R05-R06). Successful force/count target behavior is
  verified only for host system/local `status` and `view`; the other commands
  and successful container IOC targets remain pending. Populated list columns
  and console detach delivery remain separate claims. Manifest SHA256:
  `1b2c93f7d4e99f5c6be3780d5052e5450eadc26d57364708a02e29cb34939dd7`.
  All manifests and same-run argv/exit/ledger references were checked, and
  the original failed attempt remains separate from the 181 completed cases.
  The immutable source worksheet and its counts are unchanged. Step 1 and
  final T1/T2/T4, T3, T5, and T6 remain incomplete. No public correction was
  required by these cases; production code and host policies are unchanged.
- Installed command-option batch, 2026-10-01T23:52:38Z through 23:56:11Z:
  `work/m8-verification-runs/20261001T235221Z-87aa67c-command-options/`
  froze 120 cases per host before execution. Both installed runners completed
  all 240 cases as `vmadmin`; system `inspect` used the existing sudo path.
  The retained real `m8local` and `m8console` fixtures exercised populated
  `list`, `inspect`, `attach`, `monitor`, and actual `start`, `stop`, `restart`,
  `enable`, `disable`, and `remove`, each with a baseline and five short/long
  force/count variants. All calls returned 0 and matched their frozen native
  postconditions. Start/restart produced a new active supervisor PID and socket;
  stop/remove left no active PID/socket; remove also removed the installed
  configuration. Enable/disable changed boot enablement without changing the
  active PID. Query calls preserved native state. Populated list output bytes
  matched; inspect socket/executable identity fields matched while raw process
  details remained available. Forty-eight real console clients exited 0,
  restored terminal settings, and preserved the IOC PID; attach also completed
  a real IOC echo round trip. Console banner fields matched their baselines.
  Account/unit/runner/selected fixture fingerprints, original inactive/disabled
  states, and original log prefixes were restored or preserved. No new VM
  account or privilege policy was created. Original installed hashes remain
  unchanged from the preceding host batches. Input manifest SHA256:
  `69224f8440488c320681146b30f019d2658ebbbd9ad306b37688097182c27890`;
  final manifest SHA256:
  `ab84cb8534eb4354dc20ca9c4f152dd489de0a50f678a9339eb64573188905e6`.
- Installed container command-option batch, 2026-10-01T23:57:32Z through
  23:57:56Z:
  `work/m8-verification-runs/20261001T235704Z-87aa67c-container-command-options/`.
  The unchanged shipped container lifecycle suite ran in installed mode,
  passed all 64 assertions, and retained its actual generated softIoc fixture.
  That original fixture was reinstalled for 72 frozen calls: all twelve other
  commands, each with a baseline and five force/count variants. Root and real
  live s6 were used; all cases matched native state/output expectations.
  Twelve real console clients exited 0 and restored their terminals. Start,
  restart, stop, boot enablement, and removal met the same scoped contracts as
  the host cases. Status excluded only elapsed seconds from equality; view
  compared complete output bytes. Account/configuration/runner fingerprints
  and fixture contents matched; installed configuration, service, and socket
  directories were removed. The new container's absence is recorded.
  Installed SHA256 is
  `8946469f36151e53fd849b3e872bc048e4476acd446b1f16823c7f75f3dfd6c4`;
  original bytes match the current runner after excluding only deployment
  stamps. The captured source is read-only and Git metadata is unknown.
  Input manifest SHA256:
  `cda0e8ef3b225adf0517ad8791d8f6c3f3d097d07f69b3ac7a2d06514dd45468`;
  final manifest SHA256:
  `bd9a398a753a5e5e57cfa46e621a650dc29f8e47284ef476fffe5dc6b1de9488`.
  Root-owned terminal records were copied through a read-only evidence mount
  without changing original bytes or permissions; all 966 regular-file hashes
  match the readable copy in
  `work/m8-verification-runs/20261001T235704Z-87aa67c-container-native-export/`.
  Its archive retains original modes and its manifest SHA256 is
  `ca7a3b4f6ad2d7f77f96ee72f6f8d90cbe78cc2f69c7de2fb52aabe0b0703c4e`.
  The earlier attempt at 23:54:26Z through 23:54:34Z remains preserved in
  `work/m8-verification-runs/20261001T235344Z-87aa67c-container-command-options/`.
  It ran the real suite with 63 passes and one failure: the outer wrapper
  redirected scanner stdout, violating the container-stdout FD assertion.
  Downstream option cases did not run. Its manifest SHA256 is
  `3239f7a62c3b043b1b4114af9c3fac56a715e197030783543f4f3b8dfb42c79d`.
  The corrected wrapper inherited container stdout as the shipped harness
  specifies. Neither the suite nor production code was changed.
- Command comparison audit, 2026-10-02T00:04:08Z:
  `work/m8-verification-runs/20261001T235704Z-87aa67c-command-option-comparisons/`
  contains 52 scoped `Verified` rows with document clauses, implementation
  references, runner/source hashes, principals/environments, expected results,
  literal argv, native exit, before/after states, raw output, and exact ledger
  lines. Native client exits and terminal restoration were checked directly
  from the original records, including the earlier host driver; container
  records also retain the outer terminal process exit. Raw console bytes are
  read as binary because telnet control bytes are not UTF-8 text.
  Combining these 312 calls with the preceding 48 host status/view queries
  accounts for all twelve other commands in the five selected mode/OS
  environments, with six calls per command. This completes the selected normal
  paths, not every failure or fallback path: broad R05/R06 statements remain
  `Partial` for unselected failure cases and fallback clients. Monitor input
  isolation, pasted/custom detach behavior, and startup/crash failure behavior
  remain separate claims. The source worksheet and its counts are unchanged;
  semantic segmentation/reconciliation and final T1/T2/T4, T3, T5, and T6
  remain incomplete. No public correction was required by these cases.
  Comparison manifest SHA256:
  `e9aaa37f0a477bea6bf262c371cb61c9d9c36285f75b278cd00798fe1099cba2`.
- Installed host console-path batch, 2026-10-02T00:17:42Z through
  00:17:57Z:
  `work/m8-verification-runs/20261002T001723Z-87aa67c-console-paths/`
  froze 48 cases per host before execution. Both installed runners completed
  all 96 calls on Debian 13 and Rocky 8 in local and system modes, using the
  retained real `m8local` and `m8console` fixtures. Each mode exercised
  `attach` and `monitor` through actual socat and unavailable-client paths,
  with a baseline and five short/long force/count variants. All cases matched
  the frozen output, exit, and native state expectations. Actual socat attach
  completed an IOC echo round trip and exited 0 on Ctrl-A; actual socat
  monitor exited 130 on Ctrl-C. All 48 clients restored terminal settings;
  captured process command lines match the runner's native socat arguments.
  All 48 unavailable-client cases exited 1, produced the same complete
  resolver error and installation hint as their baseline, and had empty
  stdout with no connection banner. Supervisor PID, actual IOC child PID,
  socket inode, and active state stayed unchanged for all 96 calls.
  The unchanged shipped console helpers isolated fixed con search paths in
  private user/mount namespaces; only socat links were excluded from the
  rejection PATH mirror. The outer principal was `vmadmin`, mapped to root
  only within its namespace. The existing local runtime directory was
  preserved explicitly, as in the shipped PTY producer. Host client binaries,
  runner, accounts, unit/configuration files, and fixture contents matched
  their original fingerprints; actual stop/remove restored inactive states
  and removed only this batch's installed targets. Existing log prefixes and
  payloads remain intact. Installed runner hashes are unchanged from the
  preceding host runs. No VM identity, package, sudo policy, or production
  source was changed. Frozen validation records contain passing Bash syntax,
  complete ShellCheck gate/inventory, and Ruby syntax results; environment
  hardening and failure/restoration checks were also examined separately.
  Input manifest SHA256:
  `d524aa3d61665fb631d2dce3baeeed166346717f7a95a9ee17eda256937dc25f`;
  final manifest SHA256:
  `1030b2682dce2b8dbf332c50c02963c2b39afff4de07545b9f4f6ae79f0d9f49`.
- Console-path comparison audit, 2026-10-02T00:20:09Z:
  `work/m8-verification-runs/20261002T001723Z-87aa67c-console-paths-comparisons/`
  contains 16 scoped `Verified` rows. Each row binds current CLI clauses and
  implementation ranges to source hashes, installed identity, fixture,
  principal/namespace, environment, native argv/output/exit/state files, and
  exact case-ledger lines. Original deployed code bytes match the current
  runner after removing only the three deployment stamp declarations. Raw
  client command lines, exits, terminal settings, before/after PID/socket
  states, baseline output comparisons, restoration fingerprints, and original
  log prefixes were checked directly. Selected monitor exit/output behavior
  does not establish input isolation. Container fallback, con without
  read-only support, paste/custom detach behavior, missing target/socket, and
  lifecycle failure paths remain separate cases. Broad R05/R06 remain
  `Partial`; the whole-book statement worksheet and its counts are unchanged.
  Final T1/T2/T4, statement segmentation/reconciliation, T3, T5, and T6 remain
  incomplete. No public correction was required by this batch.
  Comparison manifest SHA256:
  `5145e4b6c458abf2a6640f51c74009bbe7342ffe7175b91bea5854c1ebaacff1`.
- Installed container console-path batch, 2026-10-02T01:54:26Z through
  01:54:31Z:
  `work/m8-verification-runs/20261002T015411Z-87aa67c-container-console/`
  froze 24 cases before execution. Two new root containers used the pinned
  default Debian 13 image, no added capabilities, no network, and read-only
  source, IOC fixture, driver, and client masks. Both `attach` and `monitor`
  ran through socat and unavailable-client paths, each with a baseline and
  five force/count variants. All 24 cases matched their expected native
  outputs, exits, and states. Six real socat attachments completed an IOC echo
  round trip and exited 0 on Ctrl-A; six real socat monitors exited 130 on
  Ctrl-C. All twelve clients had the exact native socat argument list and
  restored terminal settings. All twelve unavailable-client calls exited 1
  with the complete resolver error and installation hint, empty stdout, and
  no connection banner; stderr bytes matched their respective baselines.
  The real supervisor PID, IOC child PID, active state, and control socket
  inode remained unchanged for every call. Readiness records retain the
  initial empty child lists and the subsequently observed positive child.
  Docker mount records show read-only client masks; the requested socat
  target resolves to `/usr/bin/socat1`, independently confirmed in the same
  pinned image. Recorded effective capabilities lack both SYS_ADMIN and
  SYS_PTRACE. The rejection PATH mirror omits socat names while retaining
  other native tools. The shipped PTY child is unchanged and runs without
  its private-namespace option. No CLI function or IOC startup content was
  substituted.
  The original fixture was generated by the previously verified unchanged
  shipped container lifecycle suite in
  `work/m8-verification-runs/20261001T235704Z-87aa67c-container-command-options/`.
  Its provenance, exported bytes, source identity, image, configuration, and
  startup hashes were checked before reuse. The suite's 64 assertions belong
  to that earlier run; they are not new assertions in this batch. The retained
  payload was mounted at its original absolute path and stayed read-only.
  Its non-writable-directory installation warning is retained in raw output;
  real IOC startup and attachment completed. Account/configuration/runner/
  fixture/client fingerprints matched, actual stop/remove restored the
  initial inactive state, and configuration/socket/s6 service directories
  were absent at the final live-scanner check. Both new containers were
  absent afterwards. Original root records retain their modes and bytes;
  read-only archive exports verified all 358 regular files against readable
  copies. Existing VMs, payloads, logs, and production code were preserved.
  Installed hashes are
  `bd0ca0b689d843027eab3601133fb4564e279ea99d63dde4db0cefa28c4d9f1d`
  for socat and
  `7b684e2264a413f03ed7b2a43297877955484eff317e6fe931fef548acc85849`
  for rejection. Both original deployed files match current runner bytes
  after excluding only the three deployment stamps. Input manifest SHA256:
  `e11b9753c29d4c6d5f60d9db84b121dc8269c141c514355a1d1205fb44cb4fee`;
  final manifest SHA256:
  `366f59e81c109ac6ff94b04a2acc00f7b70469bf5eea8f31fbf209dcb58c0f80`.
  The initial attempt at 01:49:52Z through 01:49:54Z remains preserved in
  `work/m8-verification-runs/20261002T014934Z-87aa67c-container-console/`.
  Both drivers aborted before a selected invocation. The rejection preflight
  found a non-executable socat through `command -v`; the socat context stopped
  on an empty IOC child list immediately after start. Actual cleanup and
  container absence are retained. The subsequent outer driver excludes
  socat names from PATH and polls the real child/socket before snapshots.
  The failed-run status remains ABORT with zero selected cases; its manifest
  SHA256 is
  `623911d32b1ab70259bf0e0ded75823c637b5e871852d166f3e2921945244391`.
- Container console comparison audit, 2026-10-02T02:02:52Z:
  `work/m8-verification-runs/20261002T015411Z-87aa67c-container-console-comparisons/`
  contains four scoped `Verified` rows with current CLI clauses, source and
  implementation hashes, actual installed identity, original fixture
  provenance, root principal, default capability records, mount/readiness
  observations, literal argv, raw outputs, exact case-ledger lines, native
  client exits, and terminal/state comparisons. All native original/export
  bytes, restoration evidence, failed-run records, and source bindings were
  checked. Combined with the preceding host batch, selected unavailable-con
  fallback and unavailable-client errors have 120 observed calls in the five
  mode/OS domains. This does not cover con without read-only support, monitor
  input isolation, pasted/custom detach behavior, or other failure paths.
  nc was absent in both selected containers, so the even-if-nc-available
  clause remains unverified here. Broad R05/R06 remain `Partial`; the source
  worksheet and its counts are unchanged. Statement segmentation and
  reconciliation, final T1/T2/T4, T3, T5, and T6 remain incomplete. No public
  correction was required by this batch. Comparison manifest SHA256:
  `6ca32dd24724a21f1a1aa66573b0e4c7f16a75febdf11d16010a25ca8fa22d9e`.
- Installed missing-configuration batch, host transport observations
  2026-10-02T02:21:26Z through 02:21:28Z:
  `work/m8-verification-runs/20261002T022108Z-87aa67c-missing-config/`
  froze 35 calls before execution. The actual installed host runners on
  Debian 13 and Rocky 8 ran `remove`, `stop`, `enable`, `disable`, `view`,
  `attach`, and `monitor` in system and local mode. One new container ran
  the same seven commands after shipped infrastructure setup, with real
  live s6 supervision, the pinned default image, no network, and no added
  capabilities. Every call used the same unique IOC name, whose
  configuration and runtime directory were verified absent beforehand.
  All 35 calls exited 1 with the complete expected stdout and stderr bytes.
  The target remained inactive with MainPID 0 on both hosts; its container
  service directory remained absent while the owned scanner stayed live.
  Every post-call target state matched its initial observation. Configuration,
  account, installed runner, native client, and existing log fingerprints
  matched before and after the batch. No target was installed or started,
  and no internal CLI or backend span was replaced. Existing VM resources
  were retained; the new container was absent after its owned scanner stopped.
  Original container records retain their bytes and metadata. Installed
  hashes are `2bd6755d19e81567a3d4643f0b794cb1146162651b5325d8818b7963c3813af3`
  on Debian, `14edc5e19f8c163af1b5a7aa45d6369b0b35bb8394f4ad1253134ac8b6a33e5a`
  on Rocky, and `c59dad8fa03654b4966851c520d71f48533389c5b3e5ee82fa6cc0cd44c73e51`
  in the container. All three deployed files match current runner bytes
  after excluding only the three deployment stamps. Input manifest SHA256:
  `d45ef2c9ee33a6690cf9e2c6fd54c1daf49ff72c19f095a05d68a424876751d0`;
  final manifest SHA256:
  `d9a8fabdadabc7163002ffcbf8b4624fe2c34aff03a8507c99fb26a85aecec67`.
- Missing-configuration comparison audit, 2026-10-02T02:25:19Z:
  `work/m8-verification-runs/20261002T022108Z-87aa67c-missing-config-comparisons/`
  contains 35 scoped `Verified` rows across five mode/OS domains, each with
  the current document clause, actual installed identity, principal,
  environment, implementation text, literal argv, full outputs, native
  case-ledger line, observation times, and state comparisons. All 20 public
  and bin inputs still match the immutable source capture. The frozen plan's
  stop/enable/disable implementation range omitted the configuration gate;
  the comparison retains that plan and cites the reread dispatch at lines
  3599 through 3604. Execution inputs and expectations are unchanged.
  Two earlier comparison attempts stopped before creating result artifacts:
  one on Ruby binary/UTF-8 string equality, the other on an unsupported
  assumption that host and consumer clocks agreed. Binary reads and
  normalized hashes match all three deployed files. Native and transport
  timestamps are preserved and checked in their own ordered sequences;
  Rocky records 02:21:23Z while the host transport records 02:21:26Z.
  Clock synchronization is not asserted. Frozen inputs, the unique target,
  literal argv, and hashed native records establish the execution identity.
  These rows verify only absent configurations with readable parents,
  available console clients, and no stale runtime directories. Other command
  failures, installed-but-stopped sockets, and enclosing command semantics
  remain separate. Broad R05/R06 and whole-book worksheet counts are
  unchanged; final T1/T2/T4, T3, T5, and T6 remain incomplete. No public
  correction was required. Comparison manifest SHA256:
  `da6cc3fb3108794b6d397b6626a2d78097075353869a1ee971ba66e805cdb124`.
- CLI semantic decomposition, 2026-10-02T02:36:24Z, and native evidence
  comparison, 02:41:16Z:
  `work/m8-verification-runs/20261002T023624Z-87aa67c-cli-semantics/`
  derives predicates from current CLI source lines 1 through 77 and the
  reread implementation. Its 44 original candidates contain seven previously
  structural rows and 37 previously Pending rows. They are represented by
  171 independently specified rows: 160 behavioral predicates and eleven
  non-executable descriptions or structure entries. Behavioral rows specify
  726 mode/OS cases, implementation source text and hashes, preconditions,
  and expected output, exit, state, or metadata. Source-range intersections
  preserve provenance; they do not establish runtime coverage. The original
  worksheets remain immutable. Outside this selected prefix, 1474 original
  Pending candidates still need semantic decomposition and applicability.
  The separate evidence overlay in
  `work/m8-verification-runs/20261002T023624Z-87aa67c-cli-semantics-evidence/`
  independently rechecks native argv, complete error bytes, exits, installed
  runner bytes, input manifests and fingerprints from the installed host
  restrictions, default container restrictions, and missing-configuration
  runs. No earlier filled verdict supplies a new expectation. The overlay
  has 62 Verified predicates, 24 Partial predicates, and 85 Pending rows;
  its mode/OS cases are 310 Verified, 120 Partial, and 296 Pending. The
  Pending row count includes the eleven non-executable rows whose separate
  source comparisons remain pending. Partial force/count predicates cover
  selected missing-target or empty-list baselines only. The 430 comparison
  rows refer to 615 unique original case-ledger entries, including their
  baselines; this is evidence reuse with zero new runtime calls. Whole-command
  success/error claims, other CLI sections/pages, and source-surface
  reconciliation remain incomplete. Semantic manifest SHA256:
  `b93f15d4d0ac7011b79509dab3e5480bb146989d8d6050908f9bef01aec10c5d`;
  overlay manifest SHA256:
  `571081ef5adeb180c78c14fd2c2558438753f7825d0caa338f82023f755b1d80`.
- Container list collection discrepancy, 2026-10-02T02:50:49Z through
  02:50:51Z:
  `work/m8-verification-runs/20261002T025035Z-87aa67c-list-trace/`
  froze three calls using the original shipped-suite IOC payload and the
  pinned default image without added capabilities. Shipped setup installed
  the current CLI; real s6, procServ, softIoc, positive supervisor/IOC PIDs,
  and a listening control socket were verified. Bash tracing observes the
  installed file without replacing a CLI function or native component.
  `list`, `list -v`, and `list -vv` each exited 0 and printed the active IOC.
  Their traces contain respectively one, two, and two external `s6-svstat`
  calls for that IOC's service directory. These observations contradict the
  unqualified zero-per-IOC-subprocess claim in CLI lines 410 through 423.
  Only s6-svstat calls are counted; total subprocess counts, durations,
  scaling, and host-mode performance are not claimed. Native PID/socket
  snapshots were unchanged, actual stop/remove restored the initial target
  absence, account/configuration/runner/fixture fingerprints matched, and
  the new container was absent afterwards. Original evidence is retained.
  Installed runner SHA256:
  `afec0bbfe9d0dd03ec6aad31f4ce9d0420504962daf09b4b20c52389ab896cae`;
  its bytes match current source after excluding the three deployment stamps.
  Run manifest SHA256:
  `2448c64aa874c6809cbc5f6866c13db025a963144b6375c0112d30afc063d956`.
  The independent comparison and two exact draft replacements are in
  `work/m8-verification-runs/20261002T025035Z-87aa67c-list-trace-comparison/`.
  Verdict: Mismatch. Owner decision: Pending. Option 1 retains the collection
  explanation with separate system/local and container behavior; option 2
  removes it while retaining the actionable ss dependency/error rules.
  Public documentation and runner behavior are unchanged. Apply only the
  selected owner-accepted correction under execution-plan step 4, then
  refresh affected source rows and comparisons. Final T1/T2/T4, T3, T5, and
  T6 remain incomplete. Comparison manifest SHA256:
  `1f31f6bb6943c9a2c85f9abd05f6be4ecabfbe701e18cc2a740ef7595a01b982`.
- Decision Date: 2026-10-01. Accept option 1 in
  `work/m8-verification-runs/20261002T025035Z-87aa67c-list-trace-comparison/option-1.md`.
  The exact selected replacement is applied to the list collection section
  of `docs/CLI_REFERENCE.md`: system/local sources use bulk queries, while
  container mode queries each IOC's s6 service and supervised PID.
  The preceding Mismatch and Pending decision describe the historical
  observation; this decision supersedes that pending owner selection.
  First application CLI source SHA256, superseded after scope correction:
  `b1560118f776fa635bb3a586681511fdee6e44d08c23b58c7e37e38c49ed2af6`.
  The historical excerpt included the following console heading; the first
  replacement accidentally removed it. The native CLI surface check stopped
  with `Ambiguous or absent command section: attach`. That heading is restored.
  The first refresh and three installed container calls remain preserved in
  `work/m8-verification-runs/20261002T033749Z-87aa67c-source-refresh/` and
  `work/m8-verification-runs/20261002T033900Z-87aa67c-list-correction/`;
  they do not establish acceptance of the restored document candidate.
  Corrected CLI source SHA256:
  `11a098f8dfafd7e38eaf533cb041e32319a78d91012ed426aed15e1211655741`.
  Fresh build, affected source rows, and installed container comparisons
  remain pending until their actual paths run. Runner behavior is unchanged.
- Accepted list correction refresh, 2026-10-02T03:40:39Z through 03:46:27Z:
  the restored candidate in
  `work/m8-verification-runs/20261002T034039Z-87aa67c-source-refresh/`
  contains the exact selected option 1 and preserves all surrounding CLI
  text, including the console heading. Its native mdBook build exited 0
  without warnings; all 2165 inline spans and 108 fenced blocks match the
  actual HTML of the thirteen pages. Its 206-artifact capture manifest is
  `63cf3723571857b3417330448ee2579dd946a3b88077b572bbf323ca471ef1e5`.
  The sibling `-candidates`, `-structure`, and `-cli-surface` runs refresh
  source ranges and hashes: 1806 provisional candidates, 293 structural
  Non-executable rows, 1513 Pending rows, and 2110 lexical implementation
  surfaces. The native command/option mapping covers 15 commands and 14
  options; it establishes locations, not behavioral completeness.
  The unchanged CLI prefix, lines 1 through 77, is connected to the new
  source in the sibling `-cli-prefix` and `-cli-prefix-evidence` runs.
  Exact predicate and implementation text are checked before reuse; the
  native evidence auditor independently rereads the original argv, output,
  exits, installed bytes, fingerprints, and execution-bound hashes.
  Its 171 rows retain 62 Verified, 24 Partial, and 85 Pending comparisons;
  this is unchanged-predicate reuse, not fresh independent classification
  or new runtime calls. Its comparison manifest is
  `c4df76270a91653f378458a57c86ad0bcc834a7a2b74dc238c7853b13d9ca74d`.
  The three newly executed installed container calls are in
  `work/m8-verification-runs/20261002T034053Z-87aa67c-list-correction/`,
  with comparisons in the sibling `-comparison` run. The original shipped
  IOC fixture, default image, real s6/procServ/softIoc, and no added
  capabilities are retained. Plain, -v, and -vv list each exit 0 and print
  the active IOC; their actual s6-svstat calls are one, two, and two.
  The verbose displayed PID matches the actual supervised PID. The native
  procServ/descendant collection path runs, plain/-v make no ss call, and
  -vv makes one ss -lx call. Native PID/socket continuity, account/config/
  runner/fixture fingerprints, actual stop/remove, target absence, and
  container absence are verified. Installed runner SHA256 is
  `0ef7de1fadc2b6b60916b3bc35d1b32fc69c670134e062e10b54a4c3a79989a1`;
  its bytes match source except the three deployment stamps. The run
  manifest is `e6deb996be678ac2297dd3ca654339170e389ac1fb8657056ed0bbeb68182021`.
  The correction has sixteen separate source-bound predicates: two
  Verified for selected container state/PID behavior, five Partial, and
  nine Pending. Host bulk collection, unexecuted ss failures, and independent
  numeric CPU/memory validation remain incomplete. This verifies the
  accepted mode-qualified correction within the selected native cases;
  it does not close every predicate in that paragraph or whole-book T3.
  Comparison manifest:
  `ba52f2725b5136cc9003da7e9014459ebd2c152dbdbe8f0284bcbfc852f7ed64`.
  All failed and superseded sources and native runs are preserved. Final
  T1/T2/T4, T3, T5, and T6 remain incomplete. Continue CLI line 79 and the
  other pages from the current snapshot; 1476 provisional Pending rows
  outside the classified prefix still require full semantic treatment,
  with the selected list comparisons retained as a separate scoped overlay.
- Generate semantic decomposition and native comparison,
  2026-10-02T04:00:08Z through 04:15:40Z:
  CLI lines 79 through 118 contain 21 source candidates. The current
  decomposition in
  `work/m8-verification-runs/20261002T041002Z-87aa67c-generate-semantics/`
  derives 52 predicates, 48 behavioral and four Non-executable, with 212
  mode/OS cases from the unchanged current source. The preceding
  `20261002T040008Z-87aa67c-generate-semantics` worksheet conditioned the
  group predicate on setgid although the source clause states no condition;
  it remains historical and is superseded before that claim's comparison.
  The native run in
  `work/m8-verification-runs/20261002T040530Z-87aa67c-generate-native/`
  freezes thirteen container-root calls and five preparatory CLI calls.
  It uses the original shipped-suite IOC fixture copied into fresh root:ioc
  2775 directories, the pinned default image, shipped setup, installed CLI,
  and a real s6 scanner without added capabilities. Filesystem variations
  preserve the original fixture bytes: copied history is retained as an
  input backup for the absent-history case; startup execution permission,
  a same-byte second startup file, and a comment on an actual generated
  configuration select the documented branches. No internal path is
  replaced. All thirteen calls match their frozen exits, with seven
  successful generations and six expected aborts. The five preparation
  calls exit 0. Native comparisons confirm generated fields and path,
  configuration mode 0660, absent/existing history mode 0664, same-owner
  identical rewrite with mode restoration and inode replacement, differing
  content preview and confirmation, yes/force overwrite, refusal/EOF
  preservation, missing target/directory, no executable startup, selection
  EOF, two invalid selections followed by a valid selection, and forced
  selection of the first filename. Abort comparisons preserve observed
  bytes, UID/GID, mode and inode; timestamp preservation is not measured.
  The actual non-setgid case is separately frozen and executed in
  `work/m8-verification-runs/20261002T041020Z-87aa67c-generate-group/`.
  Root with primary GID 0 generates in a root:ioc directory with mode 0755
  and GID 1000; the resulting configuration has GID 0, mode 0660, and exit 0.
  The preceding setgid case uses GID 1000 for both directory and file.
  These real observations contradict the unqualified source statement
  that the replacement file takes its group from the directory. The
  single-case driver's ShellCheck warning was corrected before freezing;
  both executed drivers pass syntax and full ShellCheck checks. Native
  readiness polling retains its initial unsuccessful scanner-control
  observation; the scanner is confirmed live before generation and after
  every selected call. No IOC is installed or started, account/config/
  installed-runner/original-fixture fingerprints match, both owned scanners
  are stopped, and both new containers are absent afterwards.
  The current source-bound comparison is in
  `work/m8-verification-runs/20261002T040530Z-87aa67c-generate-native-comparison/`.
  Its 52 rows are six Verified, 25 Partial, 20 Pending, and one Mismatch;
  four of the Verified rows are separate native heading/table/FAQ-link
  comparisons. Its 212 executable cases are 25 Verified, two Partial,
  184 Pending, and one Mismatch. Host domains, different-owner/deleted-user
  takeover, diff-unavailable, staging denial, and ignored history errors
  remain unexecuted here. Root-owned rewrites do not establish ownership
  transfer, and the invalid-directory probe covers a nonexistent target
  only. Public documentation and runner behavior are unchanged.
  Finding: CLI lines 113 through 118, unqualified directory-group rule.
  Owner decision: Pending. The comparison holds exact option 1 and option 2
  drafts: qualify group inheritance with setgid, or remove the general
  group sentence and retain the root:ioc 2775 shared-tree example.
  Apply only the selected owner-accepted text under execution step 4 and
  refresh affected source hashes and comparisons. Then continue from CLI
  line 120 with the unresolved generate cases retained. Of the current
  provisional Pending candidates, 1458 lie outside the classified prefix
  and generate sections; the separate list overlay does not imply complete
  semantic treatment of its enclosing candidates. Final T1/T2/T4, T3, T5,
  and T6 remain incomplete. Comparison manifest SHA256:
  `4fe0a98338fbaa4d6521b9db6ca2ee3bbe177375ae0aca44a1b2f4bce8dd64fe`.

- Generate directory-group correction, Decision Date: 2026-10-01.
  Option 1 is accepted and applied exactly from
  `work/m8-verification-runs/20261002T040530Z-87aa67c-generate-native-comparison/option-1.md`.
  The replacement file inherits the target directory group when setgid is set.
  The documented root:ioc 2775 shared-tree example is retained.
  CLI source SHA256: `8d92bb88d66b6c23f81aa7d73bbe60b6e8d5b431e5cdeae83f5c09eb4cb4db2d`.
  Observed refresh: 2026-10-02T04:30:18Z through 04:35:02Z.
  The new source/build snapshot is
  `work/m8-verification-runs/20261002T043018Z-87aa67c-source-refresh/`.
  The actual pinned mdBook build exits 0 without warnings; all thirteen
  pages match 2165 inline spans and 108 fenced blocks to native HTML.
  Its 138-input manifest is
  `5847a0364cd9eebe931ef5ba90f091757e10678596161eea8b56973760c950f3`;
  the 206-artifact capture manifest is
  `df03fab81dff2a7c6e53e58cb13cb4e14e8b76eb73d8824a3ac8230297bdc569`.
  The first socket-permission failure is preserved separately in
  `work/m8-verification-runs/20261002T042957Z-87aa67c-source-refresh/`;
  it is not a successful build. The successful refresh has 1807 provisional
  candidates: 293 structural and 1514 Pending. Native CLI heading/parser
  mapping remains fifteen commands and fourteen options. The 2110 lexical
  surfaces and 4687 implementation lines still require full reconciliation.
  The unchanged CLI prefix at lines 1 through 77 is explicitly rebound
  after exact source and implementation checks in the snapshot sibling
  `-cli-prefix` and `-cli-prefix-evidence` directories. Rechecking original
  raw native evidence retains 62 Verified, 24 Partial, and 85 Pending rows;
  there is no new prefix execution or independent reclassification claim.
  The updated generate expectations at lines 79 through 119 are in
  `work/m8-verification-runs/20261002T043216Z-87aa67c-generate-semantics/`.
  Its 22 current source candidates map to 52 predicates and 212 cases.
  The maintained classifier retains unchanged expectations and derives the
  corrected group condition from the accepted text; this is a source
  refresh, not an independent whole-section review.
  Two fresh installed CLI calls run through shipped setup, the original
  shipped-suite fixture, the default image, and a real s6 scanner without
  added capabilities:
  `work/m8-verification-runs/20261002T043228Z-87aa67c-generate-ownership-2775/`
  and its sibling `-0755/`. At 04:32:41Z through 04:32:46Z, root with primary
  GID 0 generates in root:ioc directories with GID 1000. The 2775 directory
  produces configuration GID 1000; the 0755 directory produces GID 0.
  Both configurations have mode 0660 and both calls exit 0. The 0755 case
  is a control outside the corrected conditional inheritance promise.
  Account/configuration/runner/original-fixture fingerprints match, both
  owned scanners stop, and both new containers are absent. No IOC is
  installed or started. The initial guarded scanner-readiness failure is
  retained in raw stderr; scanner liveness is confirmed before generation.
  The sibling `-2775-comparison/` checks both fresh cases and rechecks the
  thirteen original selected calls and five preparation calls from their
  sealed raw artifacts after current implementation, fixture, environment,
  and source-identity comparisons. The original unchanged cases are reused,
  not rerun. Current generate rows: six Verified, 26 Partial, 20 Pending,
  zero Mismatch. Four Verified rows concern non-executable source structure.
  Current executable cases: 26 Verified, two Partial, and 184 Pending.
  Comparison manifest:
  `bbf0727d8ae3c69b46e1c6c894d1e7ec7a7669cc08715ff3287b48e80c9b2326`.
  The selected container setgid correction is Verified; host group cases,
  other-owner/deleted-user takeover, unavailable diff, staging denial, and
  ignored history failures remain incomplete. Root-owned rewrites do not
  establish ownership transfer. The source-shifted list overlay at lines
  409 through 427 is rebound in the snapshot sibling `-list-evidence/`:
  sixteen rows remain two Verified, five Partial, and nine Pending after
  rechecking the three original native list calls, exact accepted text,
  installed implementation, fixture identity, traces, and restoration.
  There is no new list execution. Its comparison manifest is
  `0d44a97201c3e68a9af082eed250d56e5d5e6798feef3887235e22fa91780cb5`.
  The install heading remains present at CLI line 121. Continue that section
  and unresolved generate cases; 1458 provisional Pending candidates lie
  outside the classified prefix and generate section. The separate list
  overlay does not complete its enclosing candidate rows.
  Final artifact check at 2026-10-02T04:38:58Z is in
  `work/m8-verification-runs/20261002T043858Z-87aa67c-ownership-final-check/`.
  It verifies every cited artifact manifest, all twenty public source inputs,
  exact option-1 text, unchanged surrounding CLI text and runner bytes,
  the retained shared-tree HTML anchor, and all 47 unaffected generate
  predicates against their original source/expected-result/implementation
  records. The five Ownership predicates retain explicit refreshed ranges;
  their current host and takeover limits remain visible. Final-check manifest:
  `d7cfe9330185193214d1c4acbfe9910c18319b35aacfa47109f7bae81ed90e00`.
  The canonical evidence update is outside the twenty public inputs; the
  snapshot retains the capture-time canonical document unchanged.
  The original unqualified-source Mismatch and both drafts remain immutable.
  Runner behavior is unchanged; whole-book T1 through T6 remain incomplete.

- Install semantic classification and frozen native batch,
  observed 2026-10-02T05:00:19Z through 05:04:45Z:
  CLI lines 121 through 197 contain 53 current source candidates.
  `work/m8-verification-runs/20261002T050019Z-87aa67c-install-semantics/`
  defines 74 predicates, 69 behavioral and five Non-executable, with 246
  mode/OS cases. All comparisons are Pending before native evidence checks.
  The `error(s)` summary notation denotes native singular/plural variants;
  it is not treated as a promise to print literal parentheses.
  The finite execution plan in
  `work/m8-verification-runs/20261002T050445Z-87aa67c-install-native/`
  freezes twenty selected root/container installed CLI calls, nineteen
  preparatory native generate calls, and four preparatory native installs.
  It covers file/directory targets, missing targets/configurations, field
  error accumulation, whitespace command rejection, pair/individual identity
  failures, relative and dotdot paths, invalid port/site grammar, permission
  warning refusal/EOF/force, and overwrite refusal/EOF/yes/force.
  Source, original shipped fixture, default image, expected argv/input/exits,
  native configuration/service attributes and restoration are frozen before
  execution. Syntax, warning-level ShellCheck and full ShellCheck pass.
  Native execution and source-bound comparisons remain Pending here.
  No public text or runner behavior is changed. Host domains, active service
  states, local shared assets, nonroot filesystem denial, and failures after
  configuration installation remain unexecuted in this batch. Whole-book
  acceptance and the 2110-surface reconciliation remain incomplete.

- Install native output and state comparison, observed
  2026-10-02T05:05:32Z through 05:14:29Z:
  The twenty frozen selected calls in
  `work/m8-verification-runs/20261002T050445Z-87aa67c-install-native/`
  match their expected exits: five successful installs and fifteen expected
  aborts. Nineteen preparatory generate calls and four preparatory install
  calls also exit 0. The actual installed runner is
  `52375acbb6960a151288dd4a85bbac3f3caaa8c8b27ddb834f8cd24919656276`;
  its bytes match the frozen source except the three deployment stamps.
  The original shipped fixture, real setup/CLI/s6 and default image are
  retained with no additional capabilities or substituted internal path.
  The initial worksheet has some inaccurate implementation line ranges.
  It remains immutable with all comparisons Pending; the corrected worksheet
  in `work/m8-verification-runs/20261002T050907Z-87aa67c-install-semantics/`
  supersedes it before native comparison. Exact source text, expected
  results and applicability are unchanged from the frozen execution list;
  code locations are rechecked against the real source.
  The source-bound comparison is in
  `work/m8-verification-runs/20261002T050445Z-87aa67c-install-native-comparison/`.
  It records 74 predicates: eight Verified, 35 Partial, and 31 Pending;
  five Verified rows are separate non-executable heading/table/link checks.
  Its 246 mode/OS cases are 23 Verified, fifteen Partial, and 208 Pending.
  No Mismatch is observed among the selected cases. Native comparisons
  confirm file/directory target resolution, missing target/config errors,
  seven accumulated field errors and singular one-error summaries,
  single-word command rejection, aggregate mode mismatch fields and selected
  individual identity errors, relative and interior dotdot rejection,
  nonstandard port rejection, one malformed site.env rejection, warning
  refusal/EOF/force, and configuration overwrite refusal/EOF/yes/force.
  Native permission inputs are recorded separately: setup creates the
  root:ioc configuration directory at 2770; selected ordinary payload
  directories are 2775; the warning cases have mode 2755 with no group write
  bit. Successful configuration files are mode 0660, UID 0, and ioc GID 1000,
  and contain exactly the source assignments with one standard socket port.
  New native s6 services have an executable rendered run script, down and
  timeout-kill files, respond with up=false/PID=-1, and have no control socket.
  No IOC is started. Refusal and EOF preserve observed installed bytes,
  UID/GID, mode/inode, service-file bytes/metadata and inactive state.
  Accepted overwrite changes the actual installed inode and source content.
  The snapshots do not independently trace mktemp/mv or atomicity; staged
  write remains Partial. Timestamp preservation is not claimed. Root-owned
  replacement does not establish transfer from another owner.
  Seven actual shipped remove calls restore only new case names. Original
  account/configuration/runner/readonly-fixture fingerprints match; the
  scanner remains live through restoration and is then stopped; all new
  targets and the disposable container are absent. Original fixtures, VMs,
  payloads, logs and preceding evidence are retained. Native run manifest:
  `51fa9562fa885f41b29cd09304ffbed41fd9be4df7434400ec787b0b4f6e95f8`.
  Comparison manifest:
  `c677526f68d716b9d402fa8e9936a33df75604888fd746a5783f0b85867e29a5`.
  Host domains, active/activating/deactivating guards, local shared-asset
  paths, existing configuration-directory failures, an absent IOC_PORT
  assignment, nonroot rejection, post-configuration deployment failures,
  and unselected identity/path/grammar inputs remain incomplete. The native
  generated inputs have an empty IOC_PORT assignment; they do not verify an
  absent assignment. Existing source-candidate totals remain unchanged.
  There are 1409 provisional Pending candidates outside the classified CLI
  prefix, generate and install sections; range provenance does not complete
  any surrounding behavioral claim. The separate list overlay is retained.
  Continue the remove section at CLI line 199 and unresolved generate/install
  cases; final T1/T2/T4, T3, T5, T6 and surface reconciliation remain incomplete.

- Remove semantic and native comparisons, observed
  2026-10-02T06:52:41Z through 07:12:17Z:
  CLI lines 199 through 224 contain thirteen current source candidates.
  `work/m8-verification-runs/20261002T065241Z-87aa67c-remove-semantics/`
  derives 31 predicates, thirty behavioral and one non-executable heading,
  with 113 mode/OS cases. Twelve of the parent candidates were Pending;
  the remaining parent was already structural. Source clauses, expected
  outcomes, exact implementation text, hashes and applicability are frozen.
  Seven actual remove calls from the preceding install run are rechecked
  for original argv, exits, success output, times, installed bytes, fixture,
  source identity and same-execution manifests. They remain Partial reused
  evidence for down-service restoration; they are not new runtime calls.
  The frozen six-case native batch is in
  `work/m8-verification-runs/20261002T065324Z-87aa67c-remove-native/`.
  Its two fresh containers run actual shipped setup and installed CLI with
  the original shipped-suite fixture copies, real s6 and the default image.
  No internal CLI, backend, utility or fixture is substituted. Source and
  fixture mounts are readonly; networking is disabled; no capability is added.
  At 06:53:44Z through 06:53:49Z, three selected removals exit 0 and three
  expected aborts exit 1: inactive, active, missing configuration, missing
  configuration with a stale runtime directory, absent service directory,
  and retained configuration. Seven preparatory generate calls, seven
  installs, one start, and four preparatory/restoration removes exit 0.
  A native first-phase install produces the exact retained-file configuration
  used as a readonly file mount in the second container. The actual native
  rm fails with Device or resource busy. Configuration bytes, mode, UID/GID
  and inode remain; the service directory has already been deleted; the
  runtime directory remains; exit is 1 with The IOC is still installed and
  no success message. This is a filesystem mount failure, not a verified
  directory-permission denial or repair. The service for that case is
  prepared and restored through the real configuration-directory override.
  Missing configuration retains the observed stale directory. Successful
  removal deletes selected configuration/service/runtime paths while an
  unrelated native keeper IOC remains unchanged. Native procServ and
  supervisor PIDs disappear while the scanner remains live. Payload content,
  type, mode, UID/GID and link targets agree before and after each call;
  payload inode and timestamp preservation are not measured.
  The original active snapshot has no softIOC child PID. Its execution
  precondition remains Partial; its successful exit does not establish
  actual IOC-program removal. The initial source-bound comparison in
  `work/m8-verification-runs/20261002T065324Z-87aa67c-remove-native-comparison/`
  has five Verified, twelve Partial and fourteen Pending rows; one Verified
  row is the native heading check. Initial cases are thirteen Verified,
  three Partial and 97 Pending. Native run manifest:
  `42879af1da787340b89f3cd265f311040dea6b9fc2beb4c7bf56d25d379c1e98`.
  Comparison manifest:
  `f4d0c494e57c9e525b5e918d7c3971ae53761fd8cd682f20fd8da28dadb782e9`.
  Two subsequent active-readiness attempts remain aborted before any selected
  remove call, in the `20261002T070609Z` and `20261002T070933Z` remove-active
  directories. Both native driver exits are 1 and both containers are absent.
  Their process logs contain a real softIOC child, but root executable reads
  do not confirm its identity. The first lacks final restoration fingerprints
  and a copied-payload archive; its container-absence observation does not
  establish those checks. The second records two actual restoration removes
  with exit 0, matching original fingerprints and a retained payload archive.
  No failed-run status or expectation is overwritten.
  A separate one-case supplement is frozen and executed in
  `work/m8-verification-runs/20261002T071147Z-87aa67c-remove-active/`.
  At 07:11:59Z through 07:12:02Z, native readiness polling identifies the
  real softIOC child, its procServ parent and its executable through the
  existing ioc-srv owner; a separate root readlink observation is retained.
  Actual process and listening-socket snapshots precede remove. The selected
  call exits 0; child, procServ and supervisor PIDs, configuration, service
  and runtime directory are absent afterwards. Keeper service and observed
  payload attributes remain unchanged. Two native generate calls, two
  installs, one start and keeper restoration remove exit 0. Fingerprints
  match, the scanner stays live through restoration, payloads are archived,
  and the new container is absent. Installed runner SHA256:
  `ffb2eb9148864a6c61e2f054c79ceef261eee7670127c1d042d06091161c8c8b`;
  bytes match the frozen runner excluding only the three deployment stamps.
  Native manifest:
  `e6ac908431b5d00d97aa4f6673377acd86dd5c44da80ac9d1536276f6d43aae5`.
  The source-bound supplement in its sibling `-comparison/` directory
  explicitly verifies two container predicates and retains unchanged source
  and implementation bindings. Combined row counts remain five Verified,
  twelve Partial and fourteen Pending. Current cases are fourteen Verified,
  two Partial and 97 Pending; host applicability keeps the broad stop row
  Partial. This is an evidence overlay, not independent reclassification.
  Supplement comparison manifest:
  `4e00ef8962e6e007ae4fe2e01e0b97dfd8e94043ac70ce21b161be380c392b14`.
  Native stop refusal, host manager states, disabled/enabled warnings,
  dangling symlink survival, permission correction, payload inode/time
  attributes and native inspection after configuration-deletion failure
  remain incomplete. Existing VMs, fixture originals, payloads, logs and
  all earlier sealed records are retained. Public sources and production
  behavior are unchanged. There are 1397 provisional Pending candidates
  outside the classified CLI prefix, generate, install and remove sections.
  Preserve the separate list overlay and continue CLI line 226 plus the
  unresolved cases. Final T1/T2/T4, T3, T5, T6 and surface reconciliation
  remain incomplete; M8 stays In progress and Closure Evidence remains None.

- Start/restart semantic and native comparisons, observed
  2026-10-02T08:44:28Z through 08:55:02Z:
  CLI lines 226 through 276 contain 32 source candidates.
  `work/m8-verification-runs/20261002T084428Z-87aa67c-start-semantics/`
  derives 51 predicates, 48 behavioral and three non-executable, with 260
  mode/OS/action cases. Host outcomes retain their system/local scope;
  container outcomes use socket and native s6 state. Source ranges, hashes,
  implementation text, applicability and expectations are recorded separately.
  The frozen native batch is in
  `work/m8-verification-runs/20261002T084737Z-87aa67c-start-native/`.
  At 08:47:50Z through 08:49:35Z, eighteen selected installed CLI calls
  complete with five exits of 0 and thirteen expected exits of 1.
  Normal inactive start/restart, active start/restart, absent/nonexecutable
  run files, absent/relative IOC_PORT, missing configurations, failed s6
  transitions, active-without-configured-socket and down-during-wait cases
  have raw argv, output, exit, times and before/after native snapshots.
  The two missing-configuration calls are supplemental gate observations.
  Four additional Bash traces execute the whole unchanged installed runner.
  Native calls are -u -wu for inactive start/restart and -r -wr for active
  restart, with -T 30000. Active start makes no s6-svc transition call.
  The traces do not invoke the host log probe. Seventeen generate calls,
  seventeen installs, seventeen restoration removes, three preparatory
  starts, two preparatory stops, setup, version and one external native
  down call also exit 0. Including the four traces, these are 63 auxiliary
  native calls; the driver exit record is not an invocation.
  Original shipped-suite fixture bytes are copied into new owned payloads.
  The original producer's exported manifest, fixture hashes, actual suite
  exit 0 and 64-pass record are rechecked; that suite is not rerun here.
  Shipped setup installs the runner; the selected default image, real s6,
  procServ and softIOC run without additional capabilities or network.
  Native child executable reads run as the existing ioc-srv owner. Positive
  child and procServ PIDs and listening sockets appear in independent snapshots.
  Active start retains both PIDs; active restart replaces both and retires
  the old processes. Socket directories have mode 0770 and ioc-srv:ioc
  ownership. Rendered procServ uses --logfile=-; scanner and container FD 1
  match, and identified native child banners and IOC initialization output
  reach the transport stdout. No dedicated procServ log is observed.
  Actual control FIFOs are moved for the transition failures and restored
  with matching attributes. The runner reports the native s6-svc error and
  s6-svlisten1 timeout, exits 1, and preserves the active IOC for blocked
  restart. The socket-wait case retains the rendered original socket path
  while its installed IOC_PORT names a different absolute socket. Its
  original parent is prepared as ioc-srv:ioc 0770. The native IOC remains
  live; the default 30-second deadline yields a warning and exit 0 after
  approximately 29.761 seconds. A separate native s6-svc down action during
  the next wait yields inactive state, absent original PIDs and exit 1.
  Failure inputs are restored before actual removal. Keeper fingerprints
  agree for every selected call. Account/configuration/runner/original-fixture
  fingerprints match after restoration with the scanner live. Copied payloads
  and fault inputs are archived; the disposable container is absent.
  Installed runner SHA256:
  `228055376d1785493c33b6472b217a2b73bc54261398582835a1d201056cfb0f`;
  bytes match current source excluding only the three deployment stamps.
  Native manifest:
  `b7f151b18fc4baf7a3cfc93b9f9b46c90d39f85529953b9d462d9b1a4a0fa46f`.
  The first execution at 08:44:51Z through 08:46:17Z remains incomplete in
  `work/m8-verification-runs/20261002T084429Z-87aa67c-start-native/`.
  Sixteen ledger entries match their exits; the next no-socket call exits 1
  because its original socket parent was created as root and procServ could
  not create its socket. The final down-during-wait case does not execute.
  Driver exit 1, native errors and the failed precondition remain preserved.
  Actual cleanup removes the remaining no-socket IOC and keeper, both with
  exit 0; retries for already-removed names return 1. Final fingerprints
  match, failure payload/input archives remain, and the container is absent.
  The successful separate run prepares the original socket parent first;
  no failed record or production source is rewritten. Failed-run manifest:
  `b63af7240f8511902c5944718c7fd3d9961022ffae0d22f3a6bdbb2b3294335e`.
  The current source-bound comparison is in
  `work/m8-verification-runs/20261002T084737Z-87aa67c-start-native-comparison-v2/`.
  It has seventeen Verified, six Partial and 28 Pending predicates; three
  Verified rows are separate native HTML structure comparisons. Executable
  cases are 31 Verified, two Partial and 227 Pending. The preceding sealed
  comparison retains its incorrect auxiliary count, which included driver.exit;
  v2 excludes that record and rechecks the same native evidence. Row verdicts
  are unchanged. Transport times have one-second precision; native times are
  checked within those intervals without asserting synchronized clocks.
  Comparison manifest:
  `795eaf22853071ea7d181404be61f2d9bb596b00758961368252715c5e17390a`.
  Host probes/log offsets, warnings, fatal/crash outcomes and extra patterns
  remain Pending in this worksheet. Container restart without a socket,
  restart down-during-wait, other input variants and nonroot paths remain
  incomplete. No selected documentation mismatch requires a correction.
  Public sources, original fixtures, existing VMs and previous evidence remain
  unchanged. There are 1368 provisional Pending candidates outside the
  classified prefix, generate, install, remove and start/restart sections.
  Continue CLI line 278 and unresolved cases; retain the separate list overlay.
  Final T1/T2/T4, T3, T5, T6 and surface reconciliation remain incomplete.
  M8 stays In progress and Closure Evidence remains None.

- Start/restart failure comparisons, observed 2026-10-02T16:28:25Z
  through 17:00:49Z; evidence audit at 2026-10-02T17:11:08Z:
  Four container calls and 56 installed host calls match the frozen expected
  output and exit. Selected conditions are 53 Verified and seven Partial.
  The source-bound worksheet retains 51 predicates and 260 mode/OS/action
  cases. Its current totals are 28 Verified, four Partial, and 19 Pending
  predicates; cases are 99 Verified, nine Partial, and 152 Pending.
  Three Verified predicates are non-executable HTML structure comparisons.
  The comparison overlays three container predicates and nine host predicates.
  Source classifications, applicability, implementation ranges, and unrelated
  rows remain unchanged; this is not an independent reclassification.
  Container evidence is in
  `work/m8-verification-runs/20261002T162806Z-87aa67c-restart-failures/`.
  From 16:28:25Z through 16:29:33Z, active and inactive restart each exercise
  a missing configured socket and a real s6 down action during the wait.
  The missing-socket calls remain active, warn after the default 30-second
  deadline, and exit 0. Both down calls become inactive and exit 1.
  Positive native softIOC executable reads, independent process snapshots,
  listening original sockets, and new restart PIDs bind the observed states.
  Actual setup/generate/install uses copied original shipped-suite fixtures,
  the selected default image, and native s6/procServ/softIOC without added
  capabilities or network. Twenty-one auxiliary native calls exit 0.
  Fault inputs are restored before actual remove. Keeper and final original
  account/configuration/runner/fixture fingerprints agree; the scanner remains
  live, copied payload/input archives remain, and the container is absent.
  Installed runner SHA256: `eff0e783b188d0c674046e56d818f4976060c15be2f4ead409efd6c21bd4ceba`.
  Native manifest: `377f80b5eba0e08f52fc9600d17570e309f26403d9bd630bf4c89909fee43efc`.
  Comparison manifest: `8b4279792e666404dd86deb363c3fdfd87f17cff05ae7fbab54c793b340d8d37`.
  The first supplement execution at 16:25:30Z remains aborted before the
  native selected ledger in
  `work/m8-verification-runs/20261002T162505Z-87aa67c-restart-failures/`.
  Its driver exits 1 and container absence is observed. No final native
  fingerprint or payload archive exists; its precise abort cause is unconfirmed
  by that execution's recorded output. Frozen inputs and results remain intact.
  Failed manifest: `d92184d871c44bd75738973471a557f63846d6f1db380a44829d37a6e013eed3`.
  Host evidence is in
  `work/m8-verification-runs/20261002T165337Z-87aa67c-host-failures/`.
  Control transport intervals are 16:53:57Z through 17:00:49Z for Debian 13
  and 16:53:57Z through 17:00:43Z for Rocky 8. Each host executes 28 calls:
  system/local, inactive start/active restart, and seven selected conditions.
  These conditions are log-probe permission denial, pre-init fatal detection,
  pre-init repeated death, post-init child death, post-init error lines,
  initialization timeout, and service down during the wait. Sixteen calls
  exit 0 and forty expected failures exit 1. Each host's 115 auxiliary native
  calls also exit 0; both drivers and archive export/extraction exit 0.
  System calls run as existing vmadmin; native services run as ioc-srv:ioc.
  Local calls and services use existing m8operator:m8group. Effective native
  unit execution, owner-read child executables, UID/GID process snapshots,
  original copied startup hashes, exact argv, logs, and listening socket paths
  bind the evidence. No runner timing override is present.
  The probe directories retain setgid and have observed mode 2550 while
  mktemp reports Permission denied. Blocked restart preserves native PIDs
  and manager restart counters. Post-init death uses a successful actual
  SIGKILL after positive initialization. Debian's selected child is absent
  afterwards; Rocky's is defunct in the immediate snapshot. The current
  child marker precedes its death banner; older restart death banners are
  excluded from that ordering comparison. Actual removal finishes restoration.
  All eight fatal calls print the expected pre-init fatal error and exit 1.
  Only Rocky system restart contains the independently emitted plain fatal
  message. The other seven record FATAL solely in the IOC shell command echo;
  those semantic cases stay Partial instead of claiming independent emission.
  Post-init error calls contain the plain emitted ERROR line and matching-line
  warning. Timeout and service-down calls use the default 30-second deadline.
  All 28 owned restart log prefixes match. Original account/group, runner,
  template, startup file, retained configuration/service, and timer fingerprints
  agree after restoration. Owned configurations, dropins, sockets, and native
  processes are absent; copied payloads and logs remain with readable archives.
  This batch does not measure unrelated retained log prefixes or payload
  inode/timestamp preservation. Case times use each VM's native driver bounds;
  control transport times establish plan-before-dispatch ordering. No
  synchronized clock or cross-host nanosecond ordering is asserted.
  Debian installed runner SHA256: `2bd6755d19e81567a3d4643f0b794cb1146162651b5325d8818b7963c3813af3`.
  Rocky installed runner SHA256: `14edc5e19f8c163af1b5a7aa45d6369b0b35bb8394f4ad1253134ac8b6a33e5a`.
  Installed bytes match the captured source excluding three deployment stamps.
  Input manifest: `c1714b49d5e6fc96d33c2321ef7799901358b27413c01b300b58aa713335f5cc`.
  Debian native manifest: `b25f5b27998af458cda1daa66fab076f6bb044d41460bac908e8e713367675ad`.
  Rocky native manifest: `7a971f79532d055bbb7c23f77696cae8fc0b1c6f6d66b01ce7db405e30c89166`.
  Comparison manifest: `9c0630f2d15512aa54ea5b4cc038d3f0bc554696da15a2dd5135475d2886b782`.
  The frozen auditor is retained. The comparison auditor checks the observed
  setgid bit, native death banner/order, and defunct state, and records fatal
  emission limits. Native driver inputs, expectations, and outputs are unchanged.
  The preceding host execution in
  `work/m8-verification-runs/20261002T164749Z-87aa67c-host-failures/`
  ends after three selected calls per host. Its next healthy pre-start reports
  the fatal verdict and exits 1; the selected fatal restart does not execute.
  Original names contain a standalone fatal token; the separate completed
  execution uses neutral numbered names and preserves the failed precondition.
  Both failed drivers exit 1. Their original fingerprints agree after cleanup,
  and native failure payload archives and raw results remain intact.
  Failed Debian manifest: `dc19bb59019de6cac08a4ab386627801787d61c24e09920bc3741da51e47665c`.
  Failed Rocky manifest: `51f3404daf72ec0c4d59b8c80792aa7684c0a02d6e4402d3be7babc0d8b84933`.
  Public inputs and original startup fixtures remain unchanged. Log-probe
  write/sync/delete failure variants, extra patterns, other environment and
  input variants, and remaining generate/install/remove/start/restart cases
  remain incomplete. Continue CLI line 278 and retain the separate list overlay.
  There are 1368 provisional Pending candidates outside the classified sections.
  Final T1/T2/T4, T3, T5, T6, and source-surface reconciliation remain incomplete.
  M8 stays In progress and Closure Evidence remains None.

- Fatal-message distinction, control transport observed
  2026-10-02T19:07:11Z through 19:07:27Z; audit at 2026-10-02T19:08:30Z:
  Seven additional installed calls verify the fatal clause in the seven
  mode/OS/action domains that previously had echo-only Partial evidence.
  Debian 13 covers system/local start and restart. Rocky 8 covers system
  start and local start/restart; its preceding system restart evidence remains.
  Native evidence is in
  `work/m8-verification-runs/20261002T190621Z-87aa67c-fatal-distinction/`.
  Each call uses a fresh owned IOC and unchanged bytes from the actual retained
  shipped parse-error fixture, `m8parseclaim/st.cmd`. Its producer is the
  original local lifecycle fixture at lines 1723 through 1726. That producer
  is not rerun, and no startup content or internal runner function is substituted.
  Startup bytes contain no fatal-pattern text. The malformed dbLoadRecords
  command causes the native EPICS parser to emit
  `ERROR st.cmd line 2: Unbalanced quote.` in every selected current log window.
  That line does not occur in the startup file or its command echo.
  The captured native iocsh source contains the matching parser diagnostic.
  No initialization marker or FATAL token occurs in those current windows.
  All seven actual runner calls print the pre-init fatal error and exit 1.
  The independent parser message establishes this fatal input's precondition.
  Installed runner, procServ, softIOC, units, original fixture, principal,
  environment, exact argv, exit, and raw log snapshots are bound by SHA256.
  Positive owner-read executable identities, native UID/GID process snapshots,
  manager PIDs, and listening socket paths bind the running native children.
  The three active restarts replace their original PIDs and preserve their
  captured log prefixes. Starts begin inactive. Default runner timing applies.
  Twenty-six auxiliary native calls exit 0. Both drivers, native archive
  export, and extraction exit 0. Actual remove restores the owned targets;
  configurations, dropins, sockets, and native processes are absent afterwards.
  Original account/group, runner/template, startup-file attributes and bytes,
  retained configuration/service, and timer fingerprints agree. Copied payloads
  and logs remain with readable archives. Unrelated retained log prefixes and
  payload inode/timestamps are not measured in this batch.
  Per-case times use each VM's native driver bounds. Control-host intervals
  establish frozen-plan ordering without asserting synchronized VM clocks.
  Parse fixture SHA256:
  `7e4b668a02820086b93a766800a5d0cdf291b5c6fe869b0619df85bc9a4b83c4`.
  Input manifest: `04c82618a4f287c8e42b1f3a48bf14ce595404f30670511eebe70f65158c8253`.
  Debian native manifest: `4ea239f57bd746b11cd3849168d0b3a8d4744acdce405c62bb92f3d62e90121b`.
  Rocky native manifest: `56a56c521d8d944f7959906b4b4619a8c4ea15ec28694450fc2e87573a300ead`.
  Current comparison:
  `work/m8-verification-runs/20261002T190621Z-87aa67c-fatal-distinction-comparison-v2/`.
  Comparison manifest: `a57ce2e0b0145fefb95240cbcee839483f54a7a85399c4467037bcd420f83f4f`.
  Its 51 predicates are 29 Verified, three Partial, and 19 Pending;
  its 260 cases are 106 Verified, two Partial, and 152 Pending.
  Only the seven host-fatal evidence bindings and their row verdict change.
  The preceding sealed comparison retains a summary-key error; v2 corrects
  that aggregate while the cases and row verdicts remain byte-identical.
  The original seven echo-only executions remain Partial in their immutable
  preceding comparison. This supplement adds a distinct real fatal input;
  it does not prove independent FATAL emission in those original executions.
  Public sources, original fixtures, existing identities, and runner behavior
  remain unchanged. Other fatal patterns and environment/input variants remain
  separate. Final whole-book checks and surface reconciliation remain incomplete.
  M8 stays In progress and Closure Evidence remains None.

- Installed stop/enable/disable comparison, observed 2026-10-02T20:11:25Z
  through 20:16:52Z; audit at 2026-10-02T20:17:45Z:
  Eight source candidates at CLI lines 278 through 291 are independently
  classified into eleven predicates, including two native-rendered structural
  predicates. Nine are Verified and two Partial. Their ninety mode/OS/action
  cases are 72 Verified and 18 Partial. Five previously provisional Pending
  candidates are classified; 1363 remain outside the classified sections.
  Debian 13 and Rocky 8 each execute twenty installed system/local calls in
  `work/m8-verification-runs/20261002T201111Z-87aa67c-controls/`.
  Twelve fresh default-image container calls execute in
  `work/m8-verification-runs/20261002T201535Z-87aa67c-controls/`.
  The comparison binds the original forty host executions explicitly; they
  are not rerun or relabeled as fresh calls. Current comparison is
  `work/m8-verification-runs/20261002T201535Z-87aa67c-controls-comparison/`.
  All 52 selected calls agree with the frozen expected output, exit, and state.
  Thirty successful native controls exit 0. Fifteen missing-configuration
  calls exit 1. Four masked host enable calls and two container down-directory
  calls return the native failure exit 1. With its control FIFO absent, an
  active container stop and direct native s6-svc both return 99 after the
  default thirty-second wait, with identical native diagnostic output.
  The failed control preserves its running native PIDs. Successful enable
  and disable preserve both procServ and softIOC PIDs for active services,
  and leave inactive services inactive. Native unit links/UnitFileState and
  container down-file metadata verify the startup setting. Successful stop
  removes both observed native processes; a repeated inactive stop exits 0.
  Whole installed Bash traces confirm sudo systemctl, systemctl --user,
  s6-svc -d -wd -T 30000, and native down-file operations.
  Seventy auxiliary calls have their expected exits: 63 zero, six one,
  and one 99. Original shipped startup bytes are copied unchanged; runner
  bytes, templates, original fixtures, principals, exact argv, native UID/GID
  process identities, owner-read executable paths, and listening sockets are
  bound to the same native evidence. No internal span is substituted.
  Both VM drivers/export/extraction and the fresh container driver exit 0.
  Own masks and moved FIFO are restored before actual remove. Owned
  configurations, instance units/links, sockets, and observed native PIDs
  are absent after restoration; the disposable container is absent.
  Original account/group, fixture attributes/bytes, runner/templates,
  configurations, retained services, and timer fingerprints agree.
  Copied payload archives are readable and host logs remain on the VMs.
  Full host log contents and unrelated payload/log inode/timestamps are not
  measured in this batch. Actual reboot and subsequent IOC startup remain
  Partial for ten cases; host stop/disable nonzero propagation remains
  Partial for eight cases. Selected success/failure cases do not close them.
  Host input manifest: `51fcc2eb5f565d74f74deb7f028665c7677e03172781e6fdbab7d949981835ab`.
  Container input manifest: `283ca6d215ef63a4355e797c21649899f5ae16ad9444f14e25ae4b663880a76b`.
  Debian native manifest: `a0d3e2e713352cdd01f73d05f40b56b00c9c87497934d36dfd433f8f0bdea33a`.
  Rocky native manifest: `6e5b4a33c3c42d88be77a28d97789614c3388ed9382400253b31ee398375dbfc`.
  Container native manifest: `e743861d06ae52f6a3614b35102ebea103cc2ca8803e7aa535c5aaa06d23a811`.
  Comparison manifest: `7acea912b3acdff476326507e03649f68a49fc43c2c0c079dd3a5b17f6e9e567`.
  The earlier Debian preparation abort is preserved in
  `work/m8-verification-runs/20261002T201007Z-87aa67c-controls/`.
  Three selected missing-configuration calls ran before an auxiliary install
  rejected the copied 0755 directory and EOF. Its restoration fingerprint
  agrees; copied payloads remain, without a payload archive in that run.
  The earlier container execution remains preserved in the host root above.
  All twelve selected calls ran, but an already-inactive service made both
  no-control stop calls exit 0, invalidating the intended nonzero precondition.
  Its driver exits 1; failure remove calls and fingerprints agree, and the
  container is absent. It has no final payload archive or process snapshot.
  The fresh container uses an active service and an expected matching
  nonzero native exit. Public inputs remain unchanged. Earlier comparisons
  retain their identities and verdicts. Final T1/T2/T4, complete T3, T5/T6,
  and source-surface reconciliation remain incomplete.
  M8 stays In progress and Closure Evidence remains None.

- Installed status comparison, observed 2026-10-02T20:45:06Z through
  20:46:29Z; audit at 2026-10-02T20:48:49Z:
  Three original source candidates at CLI lines 293 through 300 are
  classified into eleven predicates. Ten are Verified, including one
  native-rendered heading, and one container example is Mismatch.
  Their 29 mode/OS cases are 28 Verified and one Mismatch. Two previously
  provisional Pending candidates are classified; 1361 remain outside
  the classified sections. The frozen ten-row classification is retained
  unchanged; the comparison separately classifies its output-example clause.
  Native evidence is in
  `work/m8-verification-runs/20261002T204442Z-87aa67c-status/`;
  the source-bound comparison is in
  `work/m8-verification-runs/20261002T204442Z-87aa67c-status-comparison/`.
  Debian 13 and Rocky 8 each execute eleven installed system/local queries.
  The default-image container executes five installed queries. All 27 match
  their frozen expected configuration presence, native state, exit category,
  exact argv, and native output comparison. Fourteen exit 0, twelve host
  inactive or missing-configuration queries exit 3, and one absent container
  service query exits 1. These nonzero values match the same principal's
  direct native query; they are expected observations. Sixty-six auxiliary
  calls have their expected exits: 53 zero, twelve three, and one one.
  Installed status queries run on missing names, configured inactive and
  active services, and both inactive and active services with only their own
  fresh configuration renamed within its directory. Status preserves native
  manager state and procServ/softIOC PIDs. Active observations verify native
  UID/GID, parent/child relationships, exact executable paths, and LISTEN
  sockets. Configured observations preserve configuration hash and metadata.
  Unconfigured observations confirm actual file absence before and after.
  Whole installed Bash traces confirm systemctl status without sudo,
  systemctl --user status, and the native s6-svstat route. The existing
  m8operator principal, outside ioc, also queries the active system service
  with its configuration absent on both VMs; both installed and direct
  native calls exit 0 without sudo. No account or sudo policy is changed.
  Container stdout has the name prefix followed by the actual s6 line.
  Both installed and native active output show
  `up (pid 446 pgid 446) 0 seconds, normally down`.
  The published example at CLI line 299 is
  `myioc: up (pid 123) 42 seconds`; after replacing name, PID and elapsed
  seconds, its format lacks PGID and the normally-down suffix observed in
  the selected image. This example discrepancy does not affect the verified
  native delegation, state or exit. It remains Mismatch pending owner
  direction; no public document is changed by this batch. Inactive s6 output
  includes exit code and ready duration. Native container lines are compared
  in full apart from elapsed-time values; host output uses stable unit,
  Active and Main PID fields because uptime and journal contents can change.
  The original frozen auditor's simplified active-line pattern is retained.
  The comparison auditor accepts actual native PGID and state suffixes,
  preserves them in the native comparison, and separately checks the example.
  Source and fixture bytes are unchanged, with their input identity and
  original producer evidence bound to the same runs. No internal span is
  substituted. All three drivers exit 0. Original account/group, fixture
  attributes/bytes, runner/templates, configurations, retained services and
  timer fingerprints agree. Each moved own configuration is restored before
  stop/remove; own configurations, unit files/links, sockets and observed
  native PIDs are absent after restoration. The container is absent.
  Copied payload archives are readable and VM payloads/logs remain retained.
  Full host log contents and unrelated payload/log inode/timestamps are not
  measured. Driver clocks are retained as observed; Rocky's guest clock is
  about four seconds behind the control host in this execution.
  Input manifest: `d340ee6d20dd287724fe6d8c3764e2a88c56f8d37b45aba4bac1fb5007c10cd6`.
  Debian native manifest: `40023f55ef778e72a6606ae6f74cddb0d97227328ca2a9a31f0089a9389e222a`.
  Rocky native manifest: `5fedd9d4bbac76b5eb5f130915e10feb4a105a1851d4c7d6c0f586660ce3e682`.
  Container native manifest: `738469fc444cb9418008289e7d41a1674ca99e8536e5047998cef375fbc7e41b`.
  Comparison manifest: `46f4483625c58f9b6557fbc2c326f2a6bbd318dee77531718f3de3225e16eae0`.
  Selected states and environments only; failed-service and other backend
  failure variants are not claimed. Public inputs and previous evidence
  identities/verdicts are retained. Final T1/T2/T4, complete T3, T5/T6 and
  source-surface reconciliation remain incomplete.
  M8 stays In progress and Closure Evidence remains None.

- Accepted status output-example correction, Decision Date: 2026-10-02;
  fresh installed query observed 2026-10-02T23:21:12.094746713Z through
  2026-10-02T23:21:12.130946899Z; comparison at 2026-10-02T23:21:48Z:
  Option 1 adds PGID and the normally-down suffix to the active container
  example at CLI line 299. The exact accepted change replaces
  `myioc: up (pid 123) 42 seconds` with
  `myioc: up (pid 123 pgid 123) 42 seconds, normally down`.
  The surrounding document, line positions and nineteen other public
  inputs are unchanged; runner behavior is unchanged.
  The new source snapshot is
  `work/m8-verification-runs/20261002T231334Z-87aa67c-source-refresh/`.
  Its actual mdBook build exits 0 without warnings, using the same immutable
  build image as the preceding source snapshot. All 2165 inline spans and
  108 fenced blocks across thirteen pages match native HTML. The provisional
  structural baseline remains 293 non-executable and 1514 Pending candidates;
  the 2110 lexical implementation candidates retain their reconciliation
  requirement. No whole-book behavioral completion follows from these counts.
  One fresh installed container status query runs with the original shipped
  fixture and default image in
  `work/m8-verification-runs/20261002T232051Z-87aa67c-status-example/`.
  Installed and direct native calls both exit 0 and show
  `m8status: up (pid 362 pgid 362) 0 seconds, normally down` after the installed
  name prefix is accounted for. The corrected example matches after replacing
  IOC name, PID/PGID and elapsed seconds; the displayed native state suffix
  is preserved. Before/after native state, configuration hash and metadata,
  procServ/softIOC PIDs, UID/GID, exact executable identity and LISTEN socket
  agree. Ten auxiliary calls all exit 0. Actual remove clears the owned
  configurations, service directories, sockets and observed processes.
  Original fingerprints agree, the payload archive is readable, the driver
  exits 0 and the disposable container is absent. The two VMs are unchanged.
  The current source-bound comparison is
  `work/m8-verification-runs/20261002T232051Z-87aa67c-status-example-comparison/`.
  It rechecks all 27 original status calls against raw installed argv/output,
  native output/exits, installed bytes and original restoration fingerprints.
  One additional fresh call verifies the changed example. It does not relabel
  those 27 original executions as fresh calls. The status section has eleven
  Verified predicates, including one native-rendered heading, and 29 Verified
  mode/OS comparisons, with selected-state limits retained. The original
  one-example Mismatch and all original input/output artifacts remain intact.
  The prefix, generate, install, remove, start/restart, controls and separate
  list overlay receive current source hashes after exact unchanged predicate
  text, implementation text/identity and sealed comparison checks. Their
  verdicts, original native references and limits are inherited; no fresh
  independent classification or additional native execution is claimed.
  The two accepted active-remove case overrides remain separately bound.
  The 1361 provisional Pending candidates outside the classified sections
  remain unchanged. Final T1/T2/T4, complete T3, T5/T6 and source-surface
  reconciliation remain incomplete. Continue view at CLI line 302.
  Source capture manifest: `0ac17f25ee8b55acb350ef25b8085174e90fc2580a5183af62300d9f5461ee08`.
  Source input manifest: `80429a699dd39f953fd61decfa86d8fd1c3ff5ff5464926bb76b817283a950d7`.
  Fresh execution input manifest: `b6fdad74944bc1b6ec8e0fd3304ea76c66d42622850f1562fcf8bec034791e87`.
  Fresh native manifest: `0433e107ae0974fd0afb55f690dee5935986aaf2c9150f7c18864e1875368078`.
  Current comparison manifest: `d1c47c91b721750163121b197b6beb80bd681418c10b6c1b6ecd12279f537651`.
  M8 stays In progress and Closure Evidence remains None.

- Installed view comparison, observed 2026-10-02T23:50:53.911326223Z through
  2026-10-02T23:51:44.004140888Z; audit at 2026-10-02T23:52:03Z:
  Five source candidates at CLI lines 302 through 311 are independently
  classified into eleven predicates. All eleven are Verified, including
  one native-rendered heading. All 28 applicable mode/OS comparisons are
  Verified within the selected states. Four previously provisional Pending
  candidates are classified; 1357 remain outside the classified sections.
  The separate list overlay and all earlier classifications retain their
  recorded verdicts, source bindings and limits.
  Native evidence is in
  `work/m8-verification-runs/20261002T235032Z-87aa67c-view/`;
  its source-bound comparison is in
  `work/m8-verification-runs/20261002T235032Z-87aa67c-view-comparison/`.
  Debian 13 and Rocky 8 each execute eight fresh installed system/local
  view queries. The default-image container executes four fresh queries.
  All twenty match the frozen expected argv, configuration presence,
  complete stdout/stderr bytes, section order, exit and native state.
  Fifteen exit 0; five missing-configuration queries exit 1 with the
  documented file-not-found diagnostic. These are expected failures of
  the selected precondition. All 59 auxiliary calls exit 0.
  Host cases cover missing configuration, installed inactive units,
  inactive units with a fresh own-instance description drop-in, and
  active units with that drop-in. Direct native systemctl cat runs as
  the same principal. Its complete template and resolved drop-in bytes
  appear after the complete installed configuration. Whole installed
  Bash traces confirm systemctl cat without sudo and systemctl --user cat.
  System queries run as vmadmin; local queries run as the existing
  m8operator principal with primary group m8group, outside ioc.
  Container cases cover missing configuration, inactive rendered service,
  inactive service with only its own run file renamed to a root-owned
  stash, and active service after restoring that exact run file. The
  absent-run case prints the complete configuration first, followed by
  `(not rendered; run 'ioc-runner --container install' first)`, and exits 0.
  Configured rendered cases print the complete native installed run bytes;
  the whole installed trace confirms the native cat route.
  Before/after manager state, configuration hash and metadata agree.
  Active comparisons preserve procServ and softIOC PIDs and verify their
  native UID/GID, parent/child relationship, exact executable identity
  and LISTEN socket. Container run bytes/metadata and the unrelated
  inactive keeper configuration, run, down file and state are preserved.
  The original native fixture directories are copied unchanged, with
  their startup hashes, installed runner identity and producer evidence
  bound to the same executions. No internal span is substituted.
  All three drivers exit 0. Original account/group, fixture attributes
  and bytes, runner/templates, configurations, retained service and timer
  fingerprints agree. Only fresh own drop-ins, configurations, units,
  service directories and sockets are removed. Observed native PIDs are
  absent after removal. Copied payload archives are readable; VM payloads
  and nonempty logs remain retained. The disposable container is absent.
  The final read-only VM resource and retained-log checks are in the final
  check directory's native-residual-checks.json. Guest timestamps are
  retained as observed, without assigning control-host times to them.
  The twenty public inputs match their preceding hashes and the selected
  source snapshot. No public page or runner behavior changes in this batch.
  Input manifest: `847402bd367f3d7a5c3dc94275dca4cddb89a1740ae5c14b503d8537846066e7`.
  Debian native manifest: `78a42a7a2e5deff7e0581bb79a38f38f8210e8082c06404201626a4be6c2da8f`.
  Rocky native manifest: `fd7a27d38a9604e0bfc66b8b702ece4f32862fa76c99eb461ecd0ee6d1e297b4`.
  Container native manifest: `94a9e929294a4b700cf0d3e4ba34e7a13904a22a4a017f32aac145059eb00268`.
  Comparison manifest: `d973aef031abe8d0dc20346e504893f5f0d0bf42e8c44ec19547c71bf4f9bcdf`.
  Other principals, unreadable configurations/run files, failed systemctl
  cat and other backend failures are not claimed. Full unrelated log
  contents and payload/log inode or timestamp equality are not measured.
  Continue log at CLI line 313. Final T1/T2/T4, complete T3, T5/T6 and
  source-surface reconciliation remain incomplete.
  M8 stays In progress and Closure Evidence remains None.

##### Closure Evidence

None.

#### M9 - Extend the multi-user gate to the 1.4.1 and 1.4.2 changes

Origin: 1.4.2 / M9
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

The multi-user contract in `gate/RUNBOOK.md` (L1-L3 in local mode, S1-S11 in
system mode) predates the 1.4.1 and 1.4.2 changes. A survey of its drivers
on 2026-09-27 found these changes exercised by the per-suite checks but not
by any multi-user scenario:

- `ioc-runner log` (1.4.1, #154): S5 reads the service log with `stat` and a
  direct read, never through the command.
- The site environment file `site.env` (1.4.1, #152): no scenario writes it
  as one operator and observes it in another operator's IOC.
- Console detach keys, the `^D^C` ignore set, and the rejected `ctrl-[`
  (1.4.2, #157, #160): S4 and S10 attach and monitor with the default key
  only; no scenario runs two operators' consoles on one IOC at once, a
  custom key, or `Ctrl-C` and `Ctrl-D` from a console against a shared IOC.
- `generate` by another operator (1.4.2, #161): S2 appends to the installed
  configuration only; no scenario regenerates a payload directory another
  operator created.
- The sequence an operator follows in practice: one operator tests an IOC in
  local mode, installs it as a system service, and a second operator stops
  it, edits `st.cmd`, regenerates, runs it by hand, and returns it to the
  service. S7 runs its manual run as the same operator, and no scenario
  moves a payload directory between local and system mode, where the
  configuration's mode check refuses the other mode's file.

##### Scope

- Add or extend multi-user scenarios for the items above, with their
  expected results in the Multi-User Contract of `gate/RUNBOOK.md`, their
  drivers under `gate/drivers/`, and any runner fix a scenario exposes as a
  separate owner decision.

Out of scope: the six-suite matrix itself, the per-suite checks, and runner
behavior changes not required by a failing scenario.

##### Completion Criteria

- Each accepted item has a scenario ID, a driver, and an expected result in
  the Multi-User Contract.
- The complete multi-user driver (`gate/drivers/control/run-all.bash`) passes
  on both test consumers.

##### Dependencies And Decisions

- Owner direction 2026-09-26: strengthen the gate for the 1.4.1 and 1.4.2
  changes, especially the multi-user scenarios, and record it in the
  milestone.
- The iocsh history behavior across principals is documented in FAQ Q13 (M7,
  D9); a scenario observes it as a benign startup message, not as a new
  runner behavior.
- Owner direction 2026-09-27: every one of the five items above becomes a
  multi-user scenario.
- Probe on both test consumers at 2026-09-27T22:39:27Z, with a temporary
  system IOC installed by `opa`: `opb`'s `ioc-runner log <ioc> -n 3` exited 0
  with the IOC's last lines; `obs`'s exited 1 with the ioc-membership message
  in plan item 2, and `obs` read the `ioc-srv:ioc 0644` log file directly.
  Owner direction 2026-09-27: take these observed results as S12's expected
  ones; the runner is unchanged.
- Owner direction 2026-09-27: give the new items new scenario IDs and keep
  S1-S11 and L1-L3 unchanged; run the practical operator sequence as one
  scenario, L4, because its point is the state carried between steps; and
  land M9 before the 1.4.2 release Gate, which runs the same driver.
- L4 needs one principal in both the `ioc` group and local mode. The fixture
  accounts give linger only to `usera` and `userb`, which are outside `ioc`.
  Owner direction 2026-09-27: add a fixture account for it rather than
  change linger on an existing one. The account is `opc`, a third operator
  in `ioc` with linger; `opa` and `opb` keep their roles. The accounts are
  created by the `testusers` role in ansible-provision, so the account is
  external gate G1, and M9 was Blocked on it from 2026-09-27; resume as Not
  started.
- Owner direction 2026-09-28: split G1. G1 keeps the role change and the two
  test consumers, both met, and is Complete, which lifts M9's block; the
  bake that carries `opc` becomes G2, a condition of the 1.4.2 release Gate
  and not of M9. Implementation is authorized the same day.

##### Implementation Plan

Plan Status: accepted
Plan Acceptance: 2026-09-27, owner direction
Implementation Authorization: 2026-09-28, owner direction
Superseded Plan Artifacts: none

1. Add `opc` and L4's IOC name, `mioc1`, to `gate/drivers/identities.bash`,
   with the principal assignments of every new scenario; teach
   `gate/drivers/control/cleanup.bash` and `leftovers.bash` the name and
   `opc`'s local state; and add `opc` to the fixture table, the fixture
   check, and its required results in `gate/RUNBOOK.md`. Closed by T3.
2. S12, `ioc-runner log` on the shared IOC: the second operator's
   `ioc-runner log <ioc> -n 3` exits 0 and prints the IOC's last lines; the
   observer's same command exits 1 with `Cannot read /etc/procServ.d to
   resolve IOC '<ioc>' (ioc group membership required).`, while the
   observer can still read the log file directly, because procServ creates
   it `ioc-srv:ioc 0644` as `docs/INSTALL.md` states. Closed by T1.
3. S13, `site.env`: the first operator writes a distinctive variable into
   `/etc/procServ.d/site.env`; the second operator restarts the shared IOC,
   attaches, and reads the value with `epicsEnvShow <VAR>`; the observer's
   write is refused. The scenario saves any `site.env` that existed before
   it and restores it, or removes the file when none existed, before the
   next scenario. Closed by T1.
4. S14, consoles on one IOC: the first operator attaches with
   `--detach-key ctrl-b` while the second operator monitors; the attach
   sends `Ctrl-C` and `Ctrl-D`, which the IOC ignores with its procServ and
   IOC process IDs unchanged and the unit active; a command the attach
   types, such as `dbl`, shows its output in the monitor's capture; after
   the attach detaches with its key, the monitor process is still running
   and still connected to the socket; and an attach with
   `--detach-key ctrl-[` is refused before connecting.
   Closed by T1.
5. S15, `generate` by another operator: the second operator regenerates the
   shared IOC's payload that the first operator generated, first without
   `-f` on a closed standard input, which names the first operator, exits 1,
   and leaves the file, then with `-f`, which exits 0 and leaves mode 0660,
   group `ioc`, and the second operator as owner. Closed by T1 and T2.
6. L4, the operator sequence on its own IOC under `/opt/epics-iocs`, with
   only one mode running the IOC at a time:
   - `opc` generates, installs, starts, and stops the IOC in local mode.
   - `opc` runs a system `install` of the local-mode configuration, which is
     refused with `Configuration mode mismatch`; `-f generate` in system
     mode rewrites it, and `install` and `start` succeed.
   - `opb` stops the service, appends a line to `st.cmd`, regenerates with
     `-f`, runs `st.cmd` by hand, and starts the service again.
   - `opc` stops the service; a local `install` of the system-mode
     configuration is refused with `Configuration mode mismatch`;
     `--local -f generate`, `--local install`, `start`, and `stop` succeed.
   - `opc` returns it to system mode the same way and starts it.

   Every step's exit code, both refusals, the active service at the end, and
   the absence of a crash warning are recorded; the iocsh history loading
   message is expected and benign (FAQ Q13). Closed by T1.
7. Run S12-S15 after S11 against the surviving shared IOC and before S9,
   and L4 after S7 on its own IOC; extend `tally` in
   `gate/drivers/control/lib.bash` to nineteen IDs; add the five rows to the
   Multi-User Contract and replace "fourteen" in its driver contract in
   `gate/RUNBOOK.md`. Closed by T1 and T3.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | multi-user | Complete `gate/drivers/control/run-all.bash` after cleanup and a `P-LEFTOVERS PASS` | Both test consumers | `VERDICT RUN PASS` with nineteen scenarios, each new scenario PASS with its recorded detail |
| T2 | regression | On one test consumer, install the runner from `1c62846` with `bin/run-setup-system-infra.bash --full` from that commit's tree, run the shared-IOC setup and the S15 driver alone, then reinstall the current runner the same way and run them again | Test consumer | S15 FAIL on the `chmod` exit with the old runner; PASS with the current one; the consumer ends on the current runner |
| T3 | static | `bash -n` and ShellCheck on every changed driver; compare the contract rows, `tally`, run order, and identities | Development host | All pass; nineteen IDs agree across the four places |

##### Verification Results

Observed on 2026-09-28 (UTC) with the drivers in the working tree based on
`7a33601` and the installed runners at `1c62846-dirty`, whose runner body is
the landed `458403f` change.

- T3 on the development host: `bash -n` and ShellCheck passed on every
  changed and new driver; the only ShellCheck notice left is the existing
  SC2016 information note in `gate/drivers/control/lib.bash`, present before
  the change. The nineteen IDs agree across the Multi-User Contract rows, the
  `tally` list, and the verdicts the drivers emit; every step in the
  `run-all.bash` order has its driver; no "fourteen", `S1[01]`, or `L[1-3]`
  remains under `gate/`, `tests/`, or `docs/` outside the registers.
- Before T1, the cleanup driver passed on both test consumers for `opa`,
  `usera`, `userb`, and `opc`, the named payload directories left by earlier
  runs were removed, and `leftovers.bash` reported `P-LEFTOVERS PASS` on
  both.
- T1 on both test consumers, the complete `run-all.bash` run in parallel:
  each host reported `VERDICT RUN PASS 19 scenarios: pass=19 fail=0
  missing=none` and every `P-*` verdict PASS. S14 kept the procServ and IOC
  process IDs across `Ctrl-C` and `Ctrl-D`, the monitor survived the detach
  and received the attach's output, and `ctrl-[` never connected. Every L4
  step passed: each move refused the other mode's configuration with
  `Configuration mode mismatch` until `-f generate`, `opb` owned the
  configuration after its takeover, the manual run printed one history
  message, and no start raised a crash warning. Evidence directories:
  `work/gate-multiuser-20260928T042630Z-150/` (Rocky 8.10) and
  `work/gate-multiuser-20260928T042630Z-350/` (Debian 13); `run-all.log`
  SHA-256, Rocky
  `d28a7515c1201ba2b4134f508f1820192a445df0bd159e77e59bf03ba688b380`, Debian
  `1be1158edd68f2b5b93e1703b6b27df18c74f14fa2665dae1c084c1074ce078f`.
- T1 again on two fresh consumers created by cloud-provision on 2026-09-28
  from the iocrunner bakes `iocrunner-rocky8-20260928T041905Z-37b54bf22f59`
  and `iocrunner-debian13-20260928T042250Z-ad86c76f6ed5` (ansible-provision
  `0b23811`, EPICS environment 1.3.0), after the runbook fixture check printed
  `FIXTURES OK` on both and `gate/drivers/push.bash` and
  `bin/run-setup-system-infra.bash --full` installed the runner at
  `7a33601-dirty`: each host reported `VERDICT RUN PASS 19 scenarios:
  pass=19 fail=0 missing=none`, with every `P-*` verdict PASS and every L4
  step PASS. Evidence directories:
  `work/gate-multiuser-20260928T043551Z-rocky8-opc/` and
  `work/gate-multiuser-20260928T043551Z-debian13-opc/`; `run-all.log`
  SHA-256, Rocky
  `8bfaab0714e8c7fec5e0a21244ba872f3b95fecfce534d082c608973faad91fb`, Debian
  `d1ac1372aa0908cdc3dbf0826ec4a06caceeb646e9f99e4650f5d7d83874a823`. This
  is Check evidence on fresh consumers, not the release Gate: the bakes come
  from work branches of both suppliers.
- After the implementation review, the S14 monitor check gained a
  connected-socket count: the descendants of the monitor's leader, read with
  `ss -xp` as their owner, must hold at least one connected unix socket.
  `script` runs its child in a session of its own, so the count follows
  parent links; a first version that walked the session counted 0 on both
  hosts while the monitor was connected. The shared-IOC setup and S14 were
  rerun on both test consumers at 2026-09-28T04:56:52Z: S14 PASS on both,
  with `connected unix sockets=1`, the procServ and IOC process IDs unchanged
  across `Ctrl-C` and `Ctrl-D`, and no `opb` console process left afterwards.
  Evidence directories: `work/gate-s14-20260928T045635Z-rocky8/` and
  `work/gate-s14-20260928T045635Z-debian13/`.
- After the second-person review of the implementation, `leftovers.bash`
  also reads `/etc/procServ.d/site.env` for a `GATE_S13_MARK` line, which a
  run cut off inside S13 would leave, and `gate/RUNBOOK.md` gained the
  removal command and the note that `opc` exists only in bakes at
  ansible-provision `32ea95f` or later. On the Rocky 8.10 test consumer at
  2026-09-28T06:09:00Z, with no `site.env` present, the read reported
  `site.env S13 marks=0`; with a temporary file holding one mark line it
  reported `marks=1`, which fails `P-LEFTOVERS`; the runbook's `sed` command
  removed the line, and the temporary file was then removed.
- T2 on the Debian 13 test consumer: with the runner from `1c62846`
  installed by full setup from that commit's tree, the shared-IOC setup
  passed and S15 failed, `without -f rc=1 owner named=1`, `with -f rc=1
  after=660 opa ioc`; after full setup from the current tree, the same run
  passed with `660 opb ioc`. The consumer ended on the current runner, and
  the temporary tree was removed. Evidence directories:
  `work/gate-m9t2-20260928T042952Z-old/` and
  `work/gate-m9t2-20260928T042952Z-new/`.
- The runs leave payload directories under `/opt/epics-iocs` and the local
  users' `~/iocBoot`, as the runbook states; they are to be cleared before
  the next run.

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-28T04:38:07Z | Both test consumers, and two fresh consumers from the 2026-09-28 bakes | PASS | `VERDICT RUN PASS`, nineteen scenarios on each of the four hosts |
| T2 | 2026-09-28T04:30:09Z | Debian 13 test consumer | PASS | S15 FAIL on the `1c62846` runner, PASS on the current one |
| T3 | 2026-09-28T04:24:51Z | Development host | PASS | Lint clean; nineteen IDs agree across the contract, `tally`, and the drivers |

##### Closure Evidence

- The five scenario drivers, the shared driver changes, the runbook's
  fixture, contract, cleanup, and count updates, and this detail landed in
  `b7427c8` on `release-1.4.2`.
- Verification: T1-T3 passed as recorded above, including the S14 and
  leftovers checks rerun after the implementation reviews.
- Landing: `git fetch` at 2026-09-28T07:25:53Z observed
  `origin/release-1.4.2` at `b7427c8abe663a227863ed28f3f0950a05bea355`.
- External gate: G1 is Complete. G2, the production bake carrying `opc`, is
  a condition of the 1.4.2 release Gate, not of this work.
- Linked issue: none.

#### M10 - Correct the command-line help, completion, and mode-specific messages

Origin: 1.4.2 / M10
Identity History: none
GitHub Issue: #163 (https://github.com/jeonghanlee/epics-ioc-runner/issues/163)
Status: Not started

##### Summary

The M8 inventory of the command surface, checked against the code on
2026-09-28 at `222ab3c`, found seven places where the runner's completion,
help, or messages disagree with its own behavior. None changes what a command
does; each misleads an operator who reads the prompt, the help, or the error.

##### Scope

- `bin/ioc-runner-completion.bash`: the command list omits `log`
  (line 14), and the option list omits `-n` and `--lines` (line 15).
- `bin/ioc-runner` usage: the `log` entry shows `-n <count>` without its long
  form `--lines` (line 267).
- `bin/ioc-runner` `validate_conf`: in container mode an identity mismatch
  prints `Local IOCs must run as` and `Local IOCs must run under group`,
  because the message branches only on `system` (lines 1763-1773).
- `bin/ioc-runner` `do_inspect`: in container mode the root check prints
  `requires root privileges in system mode` (line 3031).
- `bin/setup-system-infra.bash`: the root check runs before argument parsing,
  so `--help` as a non-root user prints the root error instead of the usage
  (lines 79-83).
- `bin/setup-system-infra.bash`: a failed logrotate validation prints
  `Skipping deployment.` and then exits 1 (lines 745-747).
- Decide whether `bin/run-setup-system-infra.bash` should forward
  `IOC_RUNNER_SCAN_DIR`, which the setup script reads (line 75) and the
  launcher does not forward (lines 57-65). The launcher serves `--full` and
  the CLI update; container setup runs the setup script directly.

Out of scope: changing any command's behavior, exit status, or accepted
input beyond these texts and lists, and the published pages, which M8 owns.

##### Completion Criteria

- Completion offers `log`, `-n`, and `--lines`.
- The usage names `--lines`.
- Container mode prints mode-correct identity and `inspect` root messages.
- `setup-system-infra.bash --help` prints the usage for a non-root user and
  exits 0.
- A failed logrotate validation states that setup stops.
- The `IOC_RUNNER_SCAN_DIR` forwarding question is settled as a change or a
  recorded Keep.
- The affected suites pass with their counts updated where checks change.

##### Dependencies And Decisions

- Owner direction 2026-09-28: record these code-side findings as separate
  work in 1.4.2, with a GitHub issue.

##### Implementation Plan

Plan Status: draft
Plan Acceptance: none
Implementation Authorization: none
Superseded Plan Artifacts: none

To be written.

##### Test Plan

| Label | Layer | Method | Environment | Expected Result |
| --- | --- | --- | --- | --- |
| T1 | behavior | To be defined with the plan | To be defined | To be defined |

##### Verification Results

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | — | Pending | none |

##### Closure Evidence

None.

#### G1 - Test fixture account `opc` in `ioc` with linger

Origin: 1.4.2 / G1
Identity History: none
GitHub Issue: none
Status: Complete

##### Summary

M9's L4 scenario needs one account that is both an `ioc` group member and a
local-mode user with systemd linger. The fixture accounts come from the
`testusers` role of ansible-provision (`roles/testusers/`), baked into the
iocrunner golden: `opa` and `opb` are operators without linger, and `usera`
and `userb` have linger but are outside `ioc`.

##### Completion Condition

- The `testusers` role creates `opc` in the `ioc` group with linger enabled.
- Both reused test consumers carry `opc`.

The bake that carries `opc` was a third condition until 2026-09-28, when the
owner moved it to G2.

##### Verification Results

Checked on both test consumers with `id -nG opc`, which must list `ioc`,
and the presence of `/var/lib/systemd/linger/opc`, the same form as the
fixture check in `gate/RUNBOOK.md`.

Observed on 2026-09-28 (UTC):

- The first condition is met by ansible-provision `32ea95f` on
  `origin/m14-middleware-reconcile` (jeonghanlee/ansible-provision#27),
  which adds `test_users_operators_linger: [opc]` and the task that creates
  each such account in `ioc` with linger; the other fixture accounts are
  unchanged.
- The second condition is met: `make op.testusers.<vacuum>` from that
  ansible-provision checkout, with host inventories generated by
  cloud-provision's `bin/generate_ansible_inventory.bash`, returned rc 0 and
  `failed=0` on both test consumers; on both, `id -nG opc` printed
  `opc ioc`, `/var/lib/systemd/linger/opc` existed, and `opa` and `opb`
  still had no linger file.
- The bake condition, then open, moved to G2 the same day.

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-28T04:02:13Z | Met | Both conditions met as recorded above |

##### Closure Evidence

- Condition 1: ansible-provision `32ea95f` (jeonghanlee/ansible-provision#27).
- Condition 2: the testusers pass and checks on both test consumers at
  2026-09-28T04:02:13Z, recorded above.
- Scope narrowed by owner direction on 2026-09-28; the bake condition moved
  to G2.

#### G2 - iocrunner bake carrying `opc`

Origin: 1.4.2 / G2
Identity History: split from G1 on 2026-09-28
GitHub Issue: none
Status: Open

##### Summary

The 1.4.2 release Gate creates fresh test consumers from an iocrunner golden
bake. The bakes kept on 2026-09-28 (2026-09-18 through 2026-09-21) predate
ansible-provision `32ea95f`, so their consumers would lack `opc`, which M9's
L4 scenario needs. cloud-provision owns the bakes and was asked on
2026-09-28 to make one at `32ea95f` or later and report it.

##### Completion Condition

- cloud-provision reports an iocrunner bake made at ansible-provision
  `32ea95f` or later, with its identifier and date.
- A consumer created from it carries `opc`, checked with `id -nG opc` and
  `/var/lib/systemd/linger/opc` as in G1.

##### Verification Results

Observed on 2026-09-28 (UTC):

- cloud-provision reported two iocrunner bakes made at ansible-provision
  `0b23811`, which contains `32ea95f`:
  `iocrunner-rocky8-20260928T041905Z-37b54bf22f59` (bake date
  2026-09-28T04:19:54Z) and `iocrunner-debian13-20260928T042250Z-ad86c76f6ed5`
  (bake date 2026-09-28T04:23:22Z), with cloud-provision `4c9e97d` and EPICS
  environment 1.3.0.
- Two fresh consumers created from them carry `opc`: the runbook fixture
  check printed `FIXTURES OK` on both, and `id -nG opc` printed `opc ioc`.
  The complete multi-user driver passed on both (M9 / T1).
- Both bakes come from work branches of cloud-provision
  (`m11-middleware-operators`) and ansible-provision
  (`m14-middleware-reconcile`), not from their masters, so they are not
  production goldens; cloud-provision plans to bake again for the release
  Gate. The condition therefore stays open for that bake, which the release
  Gate's own fixture check verifies.

| Observed At | Result | Evidence |
| --- | --- | --- |
| 2026-09-28T04:38:07Z | Partial | Work-branch bakes carry `opc`; the production bake for the release Gate is pending |

##### Closure Evidence

None.

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

No unassigned work is held in this register. GitHub Backlog was not imported
as unrelated release work.

### Backlog Details

None.
