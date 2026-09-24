# Work Register

Release line: 1.4.2
Milestone index: 1.4.2
Canonical path: `docs/milestone-1.4.2.md`
Canonical branch or ref: `release-1.4.2`
Git upstream: `origin/release-1.4.2` (observed 2026-09-24; recheck with `git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}'`)
Remote tracker: `jeonghanlee/epics-ioc-runner`; GitHub milestone `1.4.2` does not yet exist; issue #157 is assigned to `Backlog` (9)

Next session entry point: Continue T9 historical regression and T5 byte-flow tracing, then rerun T10. The Check-grade six-suite matrix with the three S42 client-rejection checks passes on both test consumers, and the driver identity is repinned. Old con without read-only support is withdrawn by D6, and nc-specific checks by D7. Additional tools require separate discussion. The S42 checks landed in `ba9ef10`; the nc-only removal and the identity repin are committed alongside this register update. Leftover payload directories on both consumers must be cleared before a scenario-driver run. Preserve the committed version, console behavior, and production-validation documentation.

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
| D5 | Exclude Python from the new test implementation and its dependencies. Use Bash and util-linux for the PTY procedure; discuss additional tools separately before adding them. | 2026-09-24 |
| D6 | Exclude old con without read-only support from the remaining verification. T6 covers only rejection without con or socat (D7), and T12 covers only the direct socat path; the old-con fallback cases in the T6 and T12 rows, the Scope clause on con without -r, and the Completion Criteria sentence on con lacking -r are withdrawn. The runner's fallback code is unchanged. | 2026-09-24 |
| D7 | Add no nc-specific checks. The runner has no nc path after D3, so the nc-only cases in T6, the Scope clause on nc-only rejection, and the Completion Criteria sentence on an nc-only environment are withdrawn. S42 verifies rejection without con or socat; other host tools, including any nc, stay visible to the runner. | 2026-09-24 |

### Milestone Details

#### M1 - Verify console detach keys and align documentation

Origin: 1.4.2 / M1
Identity History: none
GitHub Issue: #157, https://github.com/jeonghanlee/epics-ioc-runner/issues/157
Status: In progress

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
  procServ discarding Ctrl-C, Ctrl-D, and Ctrl-]. Include the default Ctrl-A
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

| Label | Observed At | Environment | Result | Evidence |
| --- | --- | --- | --- | --- |
| T1 | 2026-09-24T17:11:03Z | PTY matrix above | PASS | Con/default Ctrl-A passes all common detach observations |
| T2 | 2026-09-24T17:11:03Z | PTY matrix above; private namespace hides con | PASS | Socat/default Ctrl-A passes all common detach observations |
| T3 | 2026-09-24T17:11:03Z | PTY matrix above | PASS | Con/custom Ctrl-] and Ctrl-B pass all common detach observations |
| T4 | 2026-09-24T17:11:03Z | PTY matrix above; private namespace hides con | PASS | Socat/custom Ctrl-] and Ctrl-B pass all common detach observations |
| T5 | 2026-09-24T17:11:03Z | PTY matrix above; transport trace not run | Pending | IOC command input, Ctrl-A line editing under custom keys, and a subsequent default-key connection pass; byte-flow tracing remains pending |
| T6 | 2026-09-24T23:10:28Z | Development host error suite and both test consumers; private namespace hides con, mirrored PATH omits socat | PASS | S42 rejects attach and monitor without con or socat with exit 1 and the installation hint on all three hosts; nc-only cases withdrawn by D7 and old-con fallback cases by D6 |
| T7 | 2026-09-24T15:32:17Z | Debian 13 and Rocky 8.10 test consumers; source runner at `74c8b28` plus working-tree tests | PASS | All 47 shipped S41 checks passed within each 246-check error suite; both complete matrices and reporting validation passed after identity repin; Check-grade records and limits above |
| T8 | 2026-09-24T19:51:43Z | Development host; documented attach example forms executed through the real CLI | PASS | Help key list, attach banner text, four documented attach forms and the backslash quoting, and monitor option rejection agree with executed output; direct-con examples retain default Ctrl-A; monitor exit-key guidance added to both user guides and the ignored-keys note to the local guide; a standalone second-person pass on the changed guidance and register text converged on 2026-09-24 after one accepted count correction |
| T9 | Not run | Planned historical runner fixture | Pending | Await observed pre-fix failure |
| T10 | 2026-09-24T23:10:28Z | Local lint/catalog checks plus complete two-host matrix with the three S42 checks | PASS | Current shipped checks, deployment, identity repin, and reporting validation pass at Check grade; rerun after T9 and T5 cases are implemented |
| T11 | 2026-09-24T17:11:03Z | PTY matrix above | PASS | Con monitor receives IOC output, blocks input, exits on Ctrl-A, restores the terminal, preserves IOC/socket state, and reconnects |
| T12 | 2026-09-24T17:11:03Z | PTY matrix above; direct socat only | PASS | Direct socat monitor passes the common observations and exits on Ctrl-C with status 130; the old-con fallback path is withdrawn by D6 |

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
