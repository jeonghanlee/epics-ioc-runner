# Development Plan: epics-ioc-runner 1.1.0 Release

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: plan20260514_114106
Artifact Type: development_plan
Acting As Role: Implementer
Date: 2026-05-14
Start Time: 11:41:06
Finalized At: 2026-05-14 11:41:06
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: conv20260514_112923
Supersedes Artifact ID: none
Implementer Agent ID: claudecode_claude_opus_4_7
Implementer Model: claude-opus-4-7
Based On Artifact ID: conv20260514_112923
Based On: `convergence/conv20260514_112923_claudecode_claude_opus_4_7.md`
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`, `doc-pipelines`, `git-workflow`, `bash-coding`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Implementer
- Role Source: `README.md` row 1 (User direction at session start
  assigning Facilitator + Implementer dual role)
- Artifact Type Allowed: yes (only Implementer may publish
  development_plan).
- Target Path Allowed: yes (`plan/`).
- Re-Anchor Trigger: ack artifact cmt20260514_113543 by codex_gpt5;
  convergence_report conv20260514_112923 final on disk.

## Objective

Implement the GitHub release milestone `1.1.0` (Journal decoupling
release, due 2026-05-29) per the Implementation Boundary defined in
`conv20260514_112923`. The release decouples crash detection from
the systemd journal, establishes a dedicated log file model with
explicit permissions, removes the operational requirement for
operators to hold `systemd-journal` group membership, and adds a
Rocky 8 inspect compatibility gate.

## In Scope

Per Implementation Boundary in `conv20260514_112923`:

- `bin/ioc-runner` — LOG_DIR variables, `set_local_mode` rebind,
  `do_install` local-mode mkdir, `do_inspect` (optional rework),
  `do_start_restart` rewrite (byte-offset log scan), journal fallback
  branch, RUNNER_VERSION bump.
- `setup-system-infra.bash` — system systemd template, logrotate
  config deployment, directory ownership and mode.
- `tests/test-local-lifecycle.bash`, `tests/test-system-lifecycle.bash`,
  `tests/test-system-infra.bash`, `tests/test-error-handling.bash`,
  `tests/run-all-tests.bash` — T1-T5 from #21 plus per-phase
  verification commands plus Rocky 8 regression coverage.
- `docs/LOG_LAYOUT.md` (new) — operator-facing log layout reference.
- `docs/CHANGELOG.md` — new section for 1.1.0.
- `docs/README.md` — migration section.
- `docs/ROADMAP-1.1.0.md` (new) — Development Milestones doc for the
  Implementation Readiness Packet.
- `docs/TEST_PLAN-1.1.0.md` (new) — Test Plan doc for the
  Implementation Readiness Packet.
- Operational removal of `systemd-journal` group membership from
  operator accounts (deployment runbook step, not code).

## Out Of Scope

- `bin/ioc-runner` changes outside the scoped functions.
- `docs/ARCHITECTURE.md` rewrite (deltas only).
- `docs/CLI_REFERENCE.md` rewrite (deltas only for `do_inspect` if
  D-002 rework lands).
- Issues #6 (closed 1.0.4), #13 (closed 1.0.5), #25 (closed 1.0.8).
- Issue #26 (Backlog, upstream procServ).
- Any code or doc change not enumerated under In Scope.

## Plan Item Matrix

| Plan ID | Source Decisions | Issues | Files | Verification | State |
| --- | --- | --- | --- | --- | --- |
| P-A | D-001..D-008 (foundation) | #8 | `bin/ioc-runner` (lines ~28-33 SYSTEM_/LOCAL_, ~52-54 generic, line 77 `set_local_mode`) | V-A | planned |
| P-B-1 | D-001..D-008 | #9 | `setup-system-infra.bash` (system systemd template emission) | V-B-1 | planned |
| P-B-2 | D-001..D-008 | #10 | `bin/ioc-runner` (line 277 `deploy_local_template`, line 773 `do_install` local branch) | V-B-2 | planned |
| P-B-3 | D-001..D-008 | #15 | `setup-system-infra.bash` (`/etc/logrotate.d/procserv` deployment) | V-B-3 | planned |
| P-C1 | D-001, D-006, D-007 | #11 | `bin/ioc-runner` (line 1398 `do_start_restart`) | V-C1 | planned |
| P-C2 | D-001, D-006, D-007 | #12 | `setup-system-infra.bash` (LogsDirectory, ownership), `bin/ioc-runner` `do_install` local mkdir mode | V-C2 | planned |
| P-D-1 | D-007 | #17 | (no code; deployment runbook) | V-D-1 | planned |
| P-D-2 | D-007 | #24 | `bin/ioc-runner` `do_start_restart` fallback branch | V-D-2 | planned |
| P-D+ | D-002, D-006, D-007 | #49 | `bin/ioc-runner` (line 1249 `do_inspect`) | V-Dplus | planned |
| P-E | D-007 | #21 | `tests/test-local-lifecycle.bash`, `tests/test-system-lifecycle.bash`, helpers | V-E | planned |
| P-F-1 | D-005, D-009 | #18 | `docs/LOG_LAYOUT.md` (new) | V-F-1 | planned |
| P-F-2 | D-003, D-005, D-009 | #19 | `docs/CHANGELOG.md` | V-F-2 | planned |
| P-F-3 | D-005 | #20 | `docs/README.md` | V-F-3 | planned |
| P-G | (release gate) | #22 | `bin/ioc-runner` (line 14 RUNNER_VERSION) | V-G | planned |
| P-Readiness | (Implementation Readiness Packet) | (session deliverable) | `docs/ROADMAP-1.1.0.md` (new), `docs/TEST_PLAN-1.1.0.md` (new) | V-Readiness | planned |

P-Readiness is produced once, after P-A but before P-B, to anchor the
remaining phases against an explicit checked-in roadmap and test plan.
P-D-1 carries no code change; the verification is operational and
runs alongside P-D-2.

## File-Level Change Plan

### P-A. `bin/ioc-runner` — LOG_DIR variables

Purpose:

Introduce `SYSTEM_LOG_DIR`, `LOCAL_LOG_DIR`, and generic `LOG_DIR`
following the existing SYSTEM_*/LOCAL_*/generic pattern. Rebind
`LOG_DIR` to `LOCAL_LOG_DIR` inside `set_local_mode`. Add a foot-gun
guard analogous to the existing `IOC_RUNNER_RUN_DIR` guard.

Changes:

- Append three `declare -g` lines after the existing block at lines
  28-33 (SYSTEM_/LOCAL_) and lines 52-54 (generic).
  - `SYSTEM_LOG_DIR=${IOC_RUNNER_SYSTEM_LOG_DIR:-/var/log/procserv}`.
  - `LOCAL_LOG_DIR=${IOC_RUNNER_LOCAL_LOG_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/procserv}`.
  - `LOG_DIR=${IOC_RUNNER_LOG_DIR:-${SYSTEM_LOG_DIR}}`.
- Extend `set_local_mode` at line 77 to assign
  `LOG_DIR=${LOCAL_LOG_DIR}` alongside the existing rebinds.
- Argument parsing: warn if `IOC_RUNNER_LOG_DIR` is set in system mode
  but differs from `SYSTEM_LOG_DIR`.

Verification:

- V-A: `ioc-runner --local -h | grep -i 'log dir'` and
  `IOC_RUNNER_LOCAL_LOG_DIR=/tmp/x ioc-runner --local install ...`
  with subsequent `cat ${LOCAL_CONF_DIR}/<ioc>.conf` for environment
  reflection. Specific verification commands recorded in
  `docs/TEST_PLAN-1.1.0.md`.

### P-Readiness. `docs/ROADMAP-1.1.0.md` and `docs/TEST_PLAN-1.1.0.md`

Purpose:

Establish the Implementation Readiness Packet for the remaining
phases. The roadmap doc carries the public Phase A..G + D+ ordering,
acceptance, and verification commands. The test plan doc carries the
Phase Acceptance Matrix (D-006) and per-phase verification commands
(D-007), plus the #21 T1-T5 expansion plan and the Rocky 8
regression matrix.

Changes:

- Create `docs/ROADMAP-1.1.0.md` mirroring this plan's Plan Item
  Matrix and the convergence Implementation Boundary, with
  user-facing language and no session-internal artifact IDs.
- Create `docs/TEST_PLAN-1.1.0.md` containing the Phase Acceptance
  Matrix (next section), the per-phase verification commands, and
  the T1-T5 specifications.

Verification:

- V-Readiness: both files render correctly. `docs/README.md` links
  to both.

### P-B-1. `setup-system-infra.bash` — system systemd template

Purpose:

Update the system systemd template emitted to
`/etc/systemd/system/epics-@.service` to direct procServ output to a
dedicated log file with `LogsDirectory=` for directory creation.

Changes:

- Modify the heredoc producing the system template:
  - Add `LogsDirectory=procserv` and `LogsDirectoryMode=0750`.
  - Replace existing `ExecStart=` to append
    `--logfile=/var/log/procserv/%i.log` before `--name=%i`.
  - Keep `StandardError=inherit`; set `StandardOutput=journal` if it
    is not already (modern default).

Verification:

- V-B-1: `systemctl cat epics-@<name>.service` shows the new
  `--logfile=` and `LogsDirectory=` directives. Recorded in TEST_PLAN.

### P-B-2. `bin/ioc-runner` — `deploy_local_template` and `do_install`

Purpose:

Update the user systemd template emitted to
`${HOME}/.config/systemd/user/epics-@.service` to direct procServ
output to a per-user log path. Add `mkdir -p ${LOCAL_LOG_DIR}` to
`do_install` local branch.

Changes:

- `bin/ioc-runner` line 277 `deploy_local_template`: modify heredoc
  to include `--logfile=${LOCAL_LOG_DIR}/%i.log` in `ExecStart=`.
  Keep `\${IOC_CHDIR}`, `\${IOC_PORT}`, `\${IOC_CMD}` escaped for
  systemd resolution.
- `bin/ioc-runner` line 773 `do_install` local-mode branch: add
  `install -d -m 0750 "${LOCAL_LOG_DIR}"` before conf file write.

Verification:

- V-B-2: `ioc-runner --local install <conf>` creates
  `${LOCAL_LOG_DIR}` with `0750`; rendered user unit contains the
  correct `--logfile=`. Recorded in TEST_PLAN.

### P-B-3. `setup-system-infra.bash` — logrotate config

Purpose:

Deploy `/etc/logrotate.d/procserv` with weekly rotation, 8-week
retention, `copytruncate` (procServ cannot reopen on SIGHUP).

Changes:

- Append a heredoc emission block to `setup-system-infra.bash` that
  writes `/etc/logrotate.d/procserv` with the spec from issue #15.

Verification:

- V-B-3: `logrotate -d /etc/logrotate.d/procserv` syntax check and
  `logrotate -f` forced rotation producing `<ioc>.log.1.gz`. Recorded
  in TEST_PLAN.

### P-C1. `bin/ioc-runner` — byte-offset crash detection

Purpose:

Replace journalctl-based crash scan in `do_start_restart` (line 1398)
with a byte-offset read against `${LOG_DIR}/${IOC_NAME}.log`.

Changes:

- `bin/ioc-runner` `do_start_restart`:
  - Compute `log_file="${LOG_DIR}/${IOC_NAME}.log"`.
  - Capture `size_before=$(stat -c '%s' "${log_file}" 2>/dev/null || printf '%s' 0)`.
  - After `run_systemctl start` and active-state check (sleep 5),
    read `size_now`.
  - If `size_now > size_before`:
    `tail -c +$((size_before + 1)) "${log_file}"`.
  - If `size_now <= size_before` (rotated or truncated mid-run):
    `tail -n 500 "${log_file}"`.
  - Pipe to `grep -qiE "${CRASH_LOG_PATTERNS}"`.
  - Remove `--since "@${start_ts}"` and `log_cmd` journalctl array.
  - Keep journalctl references only in user-facing diagnostic hint
    strings.

Verification:

- V-C1: crash detection succeeds with operator removed from
  `systemd-journal` group; iocsh parse error detected within 1
  second of startup; rotation between two restarts does not produce
  false warnings. Recorded in TEST_PLAN.

### P-C2. `setup-system-infra.bash` and `bin/ioc-runner` — permission model

Purpose:

Enforce the log file permission model:

- `/var/log/procserv/` = `root:ioc-srv` `0750`.
- `/var/log/procserv/<ioc>.log` = `ioc-srv:ioc` `0640`.
- `${LOCAL_LOG_DIR}/` = user `0750`.
- `${LOCAL_LOG_DIR}/<ioc>.log` = user `0640`.

Changes:

- `setup-system-infra.bash`: after `LogsDirectory=procserv` takes
  effect on first activation, verify and if needed `chgrp ioc-srv`
  and `chmod 0750 /var/log/procserv` to override systemd's default
  `0755` if necessary. Document in deployment notes.
- `bin/ioc-runner` `do_install` local branch:
  `install -d -m 0750 "${LOCAL_LOG_DIR}"` already covers local-mode
  directory mode.

Verification:

- V-C2: `stat` shows `0750` for directory and `0640` for log file;
  `cat <log>` succeeds for user in `ioc`, fails for user outside;
  no `systemd-journal` membership required. Recorded in TEST_PLAN.

### P-D-1. Operational journal grant removal (#17)

Purpose:

Remove `systemd-journal` supplementary group from IOC operator
accounts. Operational change, not code.

Changes:

- None in repository.
- Deployment runbook addition documenting `getent group
  systemd-journal`, cross-reference to operator roster, and
  `gpasswd -d <user> systemd-journal`. Captured in
  `docs/LOG_LAYOUT.md` "Group membership requirements" and runbook.

Verification:

- V-D-1: `id <operator-user>` does not list `systemd-journal`;
  `ioc-runner restart` on a faulty IOC under that user still warns.

### P-D-2. `bin/ioc-runner` — dual-path fallback (#24)

Purpose:

Add a journal-based fallback path to `do_start_restart` for the rare
case where the log file is unreachable.

Changes:

- `bin/ioc-runner` `do_start_restart` after P-C1 primary path:
  - If `[[ ! -s "${log_file}" || ! -r "${log_file}" ]]`:
    - If `journalctl -u "epics-@${IOC_NAME}.service" --since "@${start_ts}" -n 1 --no-pager >/dev/null 2>&1`
      (probe), then run journal scan with `grep -qiE`.
    - Else informational message: "neither log file nor journal
      available; scan skipped".

Verification:

- V-D-2: with `chmod 000 ${log_file}` and operator in
  `systemd-journal`: journal scan hits. With both unavailable: clear
  informational message, no false "successfully started" claim.

### P-D+. `bin/ioc-runner` — Rocky 8 `do_inspect` compatibility

Purpose:

Achieve Rocky 8 STEP 17 (local) and STEP 24 (system) pass without
regressing Debian 13. The path may be either (a) keep `do_inspect`
on `lsof`/`ss` and address the Rocky 8 environment dependency, or
(b) rework `do_inspect` to read from the log file path when feasible
and fall back to socket diagnostics.

Investigation step before code change:

- On `testbed-rocky8-iocrunner-server`, run `do_inspect` with shell
  tracing to isolate which `lsof`/`ss` invocation diverges from the
  Debian baseline. Capture the actual output and exit code for the
  failed cases. Decide path (a) vs (b) based on the trace.

Changes (path TBD after investigation):

- Path (a): adjust `bin/ioc-runner` `do_inspect` (line 1249) command
  arguments or output parsing to handle Rocky 8 iproute2/util-linux
  version skew. Document in CLI_REFERENCE delta if user-visible.
- Path (b): rework `do_inspect` to derive server context from the
  log file path and only consult `lsof`/`ss` for the client
  enumeration. May require CLI_REFERENCE delta.

Verification:

- V-Dplus: STEP 17 and STEP 24 pass on
  `testbed-rocky8-iocrunner-server`; STEP 17/24 baseline preserved
  on `top` (Debian 13) and `testbed-debian13-iocrunner-server`.
  Recorded in TEST_PLAN.

### P-E. `tests/` — integration test expansion (#21)

Purpose:

Add the five test cases T1-T5 from #21 and consolidate the
per-phase verification commands from P-A through P-D+ into the
permanent suite.

Changes:

- Append T1 (detection without journal) to
  `tests/test-local-lifecycle.bash` and/or a new dedicated step.
- Append T2 (logrotate boundary), T3 (IOC_PORT atomic install),
  T4 (`do_inspect` bounded runtime), T5 (permission enforcement)
  similarly. Each test maps to a Phase as captured in TEST_PLAN.
- Promote per-phase verification commands to test assertions where
  appropriate.

Verification:

- V-E: tests fail on the 1.0.x baseline (proves they exercise new
  behavior) and pass on the 1.1.0 HEAD across Debian 13 and Rocky 8.
  Recorded in TEST_PLAN.

### P-F-1. `docs/LOG_LAYOUT.md` (new)

Purpose:

Operator-facing reference for the new log layout.

Changes:

- Create the file with sections: Overview (data flow), System-mode
  layout, Local-mode layout, Group membership requirements (#17),
  Log rotation behavior (`copytruncate` rationale), Troubleshooting
  (log file missing, permission denied).
- No reference to issue #26 per D-009.

Verification:

- V-F-1: file renders; `docs/README.md` links to it.

### P-F-2. `docs/CHANGELOG.md`

Purpose:

Document the 1.1.0 release per the spec in #19. No `#26` reference
per D-009.

Changes:

- Add a 1.1.0 section with Breaking Changes, New Features, Fixes,
  Hardening, Migration subsections.
- Date-stamp at tag time.

Verification:

- V-F-2: section follows existing format conventions; all merged
  1.1.0 issues represented; no narrative or effort descriptions.

### P-F-3. `docs/README.md` — migration section

Purpose:

Add "Upgrading from 1.0.x" section per #20.

Changes:

- New section linked from TOC; ordered upgrade steps; compatibility
  matrix; troubleshooting quickref pointing to LOG_LAYOUT.md.

Verification:

- V-F-3: section accessible from TOC; steps copy-pastable as shell
  commands.

### P-G. `bin/ioc-runner` — RUNNER_VERSION

Purpose:

Release gate (#22).

Changes:

- `bin/ioc-runner` line 14: `RUNNER_VERSION="1.1.0"`.

Verification:

- V-G: `ioc-runner -V` outputs `1.1.0` plus git hash. Tag `1.1.0`
  created by User per memory rule (no `v` prefix).

## Test Plan

### D-006 Phase Acceptance Matrix

Both P-C1 (#11) and P-C2 (#12) carry release-gate columns covering
local mode, system mode, both supported distributions, NFS
root_squash compatibility, and a negative permission probe. Rows are
the aspect under test; cells reference the test ID in TEST_PLAN.

P-C1 (`#11` crash detection rewrite):

| Aspect | Local | System | Debian 13 | Rocky 8 | NFS root_squash | Negative perm |
| --- | --- | --- | --- | --- | --- | --- |
| Byte-offset scan correctness on healthy IOC | T-C1a-L | T-C1a-S | required | required | required | n/a |
| iocsh parse error detected within 1s of startup | T-C1b-L | T-C1b-S | required | required | required | n/a |
| Rotation or truncation mid-run does not false-positive | T-C1c-L | T-C1c-S | required | required | required | n/a |
| Primary path requires no journalctl access | T-C1d-L | T-C1d-S | required | required | n/a | n/a |

P-C2 (`#12` permission model):

| Aspect | Local | System | Debian 13 | Rocky 8 | NFS root_squash | Negative perm |
| --- | --- | --- | --- | --- | --- | --- |
| Directory mode 0750 verified at install | T-C2a-L | T-C2a-S | required | required | NFS-aware | n/a |
| Log file mode 0640 verified after start | T-C2b-L | T-C2b-S | required | required | NFS-aware | n/a |
| `ioc` group member reads log | n/a (single user) | T-C2c-S | required | required | NFS-aware | n/a |
| Non-`ioc` user cannot read log | n/a | T-C2d-S | required | required | n/a | required |
| No `systemd-journal` membership required | T-C2e-L | T-C2e-S | required | required | n/a | n/a |

### D-007 Per-Phase Verification Commands

Each phase handoff carries at least the listed verification command.
TEST_PLAN.md captures the full per-command expected output.

| Phase | Verification ID | Command (representative) |
| --- | --- | --- |
| P-A | V-A | `ioc-runner --local -h` + env override probe |
| P-B-1 | V-B-1 | `systemctl cat epics-@<name>.service \| grep -E '(--logfile=\|LogsDirectory=)'` |
| P-B-2 | V-B-2 | `ioc-runner --local install <conf>; stat ${LOCAL_LOG_DIR}` |
| P-B-3 | V-B-3 | `logrotate -d /etc/logrotate.d/procserv; logrotate -f /etc/logrotate.d/procserv` |
| P-C1 | V-C1 | `ioc-runner --local start <bad-ioc>` under operator without `systemd-journal`; expect crash warning |
| P-C2 | V-C2 | `stat ${log}; sudo -u <non-ioc-user> cat ${log}` (expect denied) |
| P-D-1 | V-D-1 | `id <operator>` confirms `systemd-journal` absent; restart still warns |
| P-D-2 | V-D-2 | `chmod 000 ${log}; ioc-runner restart <ioc>` (expect informational; or journal fallback hits if available) |
| P-D+ | V-Dplus | `bash tests/run-all-tests.bash --local` STEP 17 + `sudo -E bash tests/test-system-lifecycle.bash` STEP 24 on Rocky 8 |
| P-E | V-E | `bash tests/run-all-tests.bash` clean pass on 1.1.0 HEAD; T1-T5 fail on 1.0.x baseline |
| P-F-1 | V-F-1 | Renders cleanly; linked from README |
| P-F-2 | V-F-2 | All 1.1.0 in-scope issues represented; format-clean |
| P-F-3 | V-F-3 | TOC link present; commands copy-pastable |
| P-G | V-G | `ioc-runner -V` shows `1.1.0` plus git hash |

### T1-T5 Specifications (#21)

| Test | Phase Validating | Setup | Action | Expected |
| --- | --- | --- | --- | --- |
| T1 | P-C1, P-D-2 | bad IOC with malformed `st.cmd` | start as operator without `systemd-journal` | warning, message references crash pattern match |
| T2 | P-B-3, P-C1 | running IOC with active log | `logrotate -f`, then `ioc-runner restart` | new log created; detection reads new content; no false positives |
| T3 | P-A | prepared conf | `timeout 0.01 ioc-runner install` x100 | every surviving conf has valid `IOC_PORT`, or no file |
| T4 | P-D+ | host with 500+ UDS sockets (socat) | `time ioc-runner inspect <healthy-ioc>` | wall-clock < 1s |
| T5 | P-C2 | post-install state | `sudo -u <user-not-in-ioc> cat <log>` | permission denied |

### Host Coverage

| Host | Role | Required for |
| --- | --- | --- |
| `top` (Debian 13) | dev baseline | every phase verification, T1-T5, 1.0.x baseline fail-then-pass for T1-T5 |
| `testbed-debian13-iocrunner-server` | clone-and-test, install-and-test | system mode P-B-1, P-C2, P-D-2, P-F-1 reference |
| `testbed-rocky8-iocrunner-server` | Rocky 8 gate | P-D+ V-Dplus, P-C1 V-C1, P-C2 V-C2, T1 T2 T4 |
| `alsucl-psrv3` | Rocky NFS production-like | install-and-test, NFS root_squash regression for P-B, P-C |

## ADR Promotion Plan

| Decision ID | ADR Path | State |
| --- | --- | --- |
| (none) | (none) | (n/a) |

No decision in this plan requires ADR promotion. Convergence record
in `convergence/conv20260514_112923_claudecode_claude_opus_4_7.md`
is the durable record.

## Recovery Boundary

Recovery is per-phase, file- or worktree-level, with no git history
mutation:

- Each phase commits only after its handoff passes Reviewer 1
  cross-check (commit cadence (a) per-milestone, recorded in
  `README.md`).
- If a phase handoff fails cross-check, recovery is in-place repair
  on the working tree followed by a superseding handoff, never a
  retro-amend of a prior committed phase.
- If a phase exposes a defect in a prior phase that already
  committed, the next phase opens a new corrective sub-phase with
  its own handoff and commit, rather than amending the prior commit.
- The Implementer maintains a per-phase change list in each handoff
  artifact so recovery scope is bounded to that list.

## User Decisions Needed Before Execution

| ID | Decision | Blocking |
| --- | --- | --- |
| EA-001 | `execution_authorization` granting Implementer authority to begin Phase A and proceed phase-by-phase per this plan | All P-* execution |

The Implementer will not modify any file under `bin/`,
`setup-system-infra.bash`, `tests/`, or `docs/` (other than the
already-published session artifacts under `docs/review_sessions/`)
until the User publishes `plan/auth<YYYYMMDD_HHMMSS>_<user_label_or_facilitator_proxy>.md`
referencing this plan's Artifact ID `plan20260514_114106`, or the
User issues equivalent explicit chat authorization that the
Facilitator records into an authorization artifact on the User's
behalf.
