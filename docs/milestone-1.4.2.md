# Work Register

Release line: 1.4.2
Milestone index: 1.4.2
Canonical path: `docs/milestone-1.4.2.md`
Canonical branch or ref: `release-1.4.2`
Git upstream: `origin/release-1.4.2` (observed 2026-09-24; recheck with `git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'`)
Remote tracker: `jeonghanlee/epics-ioc-runner`; GitHub milestone `1.4.2` does not yet exist; issue #157 is assigned to `Backlog` (9)

Next session entry point: Commit the reviewed CLI checks and verified suite identity repin together; the Check-grade six-suite matrix passes on both test consumers. Continue the accepted attach and monitor regression plan without Python: determine a Bash-based PTY procedure using existing terminal tools; bubblewrap and strace remain proposed test-only dependencies, pending a decision. Actual PTY detach, monitor, and transport-tracing checks remain to be implemented. Preserve the committed version, console behavior, and production-validation documentation.

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
| Console | M1 | Verify console detach keys and align documentation (#157) | Milestone | In progress | No | D1, D2, D3, D4, D5 | Real con/socat default and custom-key attach cases and monitor exit-key cases pass; nc exclusion, input handling, banners, and guides agree; socat production validation limits are explicit; [detail](#m1---verify-console-detach-keys-and-align-documentation) |

### Decisions

| ID | Decision | Decision Date |
| --- | --- | --- |
| D1 | Continue the implemented console changes on `release-1.4.2`, opened from the updated master, using development version `1.4.2-dev`. | 2026-09-22 |
| D2 | Keep Ctrl-A as the default for both con and socat, and retain the per-connection `--detach-key` option. Verify both clients with their default and custom keys. | 2026-09-22 |
| D3 | Exclude nc from both attach and monitor. Use con or socat only; fail with an installation hint when neither suitable client is available. Monitor requires con with -r or socat. | 2026-09-22 |
| D4 | Prefer con for production console access. Support socat for ordinary use while explicitly documenting that production workloads with sustained heavy or burst IOC output have not been validated. Production load testing is outside this change. | 2026-09-22 |
| D5 | Exclude Python from the new test implementation and its dependencies. Use Bash with terminal tools for the PTY procedure. | 2026-09-24 |

### Milestone Details

#### M1 - Verify console detach keys and align documentation

Origin: 1.4.2 / M1
Identity History: none
GitHub Issue: #157, https://github.com/jeonghanlee/epics-ioc-runner/issues/157
Status: In progress

##### Summary

Establish repeatable acceptance evidence for the implemented detach behavior
and make every console instruction agree with the observed client behavior.
The current `test_console_attach` functions in the local and system lifecycle
suites inspect socket permissions, con availability, and socket listening
state; they do not send a detach key through `ioc-runner attach`.

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
  procServ discarding Ctrl-C, Ctrl-D, and Ctrl-]. Include the default Ctrl-A
  line-editing limitation in the documentation.
- Verify the committed nc exclusion from console selection and execution. Cover
  nc-only rejection for attach and monitor, including con without -r when
  socat is unavailable. Verify monitor's read-only behavior and actual key-driven
  exit through con with Ctrl-A and socat with Ctrl-C, including terminal
  restoration, IOC continuity, socket continuity, and reconnectability.
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
- With no con or socat available, both attach and monitor reject an nc-only
  environment with the documented installation hint. Neither selects nc.
  Monitor also fails when con lacks -r and socat is unavailable.
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
- D5 excludes Python from the new tests. No Python helper has been added to
  the shipped suite; the completed CLI checks use Bash. Approval of the
  proposed bubblewrap and strace dependencies remains pending.
- Completed implementation: initial detach support in `1bb270f`, development
  version in `b8d65c3`, and nc exclusion, monitor detection, and related user
  documentation in `2fa6b55`. These are not requests to reimplement those changes.
- Documentation verification uses the executed banner and input results.
- The live #157 body still excludes configurable keys and nc changes. D2-D3
  extend that older scope; the canonical plan is the source for a later issue
  update and reassignment to 1.4.2. No GitHub mutation is authorized by this plan.

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

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | Not run | Planned local/system lifecycle fixtures | Pending | Await shipped con/default check |
| T2 | Not run | Planned local/system lifecycle fixtures | Pending | Await shipped socat/default check |
| T3 | Not run | Planned local/system lifecycle fixtures | Pending | Await shipped con/custom checks |
| T4 | Not run | Planned local/system lifecycle fixtures | Pending | Await shipped socat/custom checks |
| T5 | Not run | Planned real input transport trace | Pending | Await byte-flow, line-editing, and reconnect evidence |
| T6 | Not run | Planned console-client search environments | Pending | Await shipped fallback rejection check |
| T7 | 2026-09-24T15:32:17Z | Debian 13 and Rocky 8.10 test consumers; source runner at `74c8b28` plus working-tree tests | PASS | All 47 shipped S41 checks passed within each 246-check error suite; both complete matrices and reporting validation passed after identity repin; Check-grade records and limits above |
| T8 | Not run | Planned document-to-output comparison | Pending | Await executed examples and second-person review |
| T9 | Not run | Planned historical runner fixture | Pending | Await observed pre-fix failure |
| T10 | 2026-09-24T15:32:17Z | Local lint checks plus Debian 13 and Rocky 8.10 complete six-suite matrices | Pending | Existing suite matrix, candidate deployment, identity pin, reporting validation, Bash syntax, and ShellCheck warning checks pass; regression verification must be repeated after the pending PTY lifecycle checks are implemented |
| T11 | Not run | Planned local/system con monitor fixtures | Pending | Await shipped con/Ctrl-A monitor check |
| T12 | Not run | Planned local/system socat monitor fixtures | Pending | Await shipped socat/Ctrl-C monitor checks on direct and old-con fallback paths |

##### Closure Evidence

None. Committed implementation: `1bb270f`, `b8d65c3`, and `2fa6b55`.
M1 remains open until its verification and documentation criteria are met and
linked-issue closure is handled under the milestone closure procedure.

##### GitHub Projection

Title: Verify console detach keys and document supported clients
Labels: bug, documentation, P2-medium, area/shell
GitHub Milestone: 1.4.2 (planned; not created)
Observed State: open
Observed Labels: bug, documentation, P2-medium, area/shell
Observed Milestone: Backlog (9)
Last Compared: 2026-09-22T17:52:32Z; issue updated at 2026-09-21T22:01:27Z

## Backlog

### Work

| Group | ID | Work unit | Type | Status | Ready | Deps | Done when / Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |

No unassigned work is held in this register. GitHub Backlog was not imported
as unrelated release work.

### Backlog Details

None.
