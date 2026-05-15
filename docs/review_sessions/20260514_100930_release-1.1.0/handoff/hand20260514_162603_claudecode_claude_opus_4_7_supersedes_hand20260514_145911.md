# Execution Handoff: Phase A — LOG_DIR variables + permanent test coverage

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: hand20260514_162603
Artifact Type: execution_handoff
Acting As Role: Implementer
Date: 2026-05-14
Start Time: 16:26:03
Finalized At: 2026-05-14 16:26:03
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: plan20260514_114106
Supersedes Artifact ID: hand20260514_145911
Implementer Agent ID: claudecode_claude_opus_4_7
Implementer Model: claude-opus-4-7
Based On: `plan/plan20260514_114106_claudecode_claude_opus_4_7.md`
Authorized By: `plan/auth20260514_121723_claudecode_claude_opus_4_7_for_user.md` (P-A) plus User chat direction on 2026-05-14 to absorb #21-style LOG_DIR tests into Phase A scope.
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`, `doc-pipelines`, `git-workflow`, `bash-coding`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Implementer
- Role Source: `README.md` row 1 (Facilitator + Implementer dual role).
- Artifact Type Allowed: yes (only Implementer may publish
  execution_handoff).
- Target Path Allowed: yes (`handoff/`).
- Re-Anchor Trigger: User direction on 2026-05-14 to extend Phase A
  scope with permanent LOG_DIR tests; supersedes prior handoff
  hand20260514_145911.

## Supersession Reason

This handoff supersedes `hand20260514_145911` to record a Phase A
scope expansion authorized in chat: the LOG_DIR-related permanent
test coverage that the development plan originally allocated to
Phase E (#21) is folded into Phase A so that Phase A ships as a
self-contained unit with its tests on the same commit.

## Implemented Decisions

- D-001 (foundation portion) — generic `LOG_DIR` variable introduced
  following the existing `RUN_DIR`/`CONF_DIR`/`SYSTEMD_DIR` pattern.
- D-006 (V-A captured for #8) — phase acceptance verification recorded
  inline (matching env, differing env, defaults).
- D-007 — per-phase narrow verification commands consolidated into
  permanent test functions in `tests/test-error-handling.bash` instead
  of deferring all permanent test work to Phase E.

## Completed Plan Items

- P-A — `bin/ioc-runner` LOG_DIR configuration variables, `set_local_mode`
  rebind, and foot-gun guard (unchanged from prior handoff).
- Partial advance of P-E (#21) test consolidation: LOG_DIR coverage
  added to permanent suite now, ahead of the remaining T1-T5 work in
  Phase E.

## Plan Item Mapping

| Plan ID | Decision IDs | Files Changed | Verification | State |
| --- | --- | --- | --- | --- |
| P-A | D-001 (foundation), D-006, D-007 | `bin/ioc-runner`, `tests/test-error-handling.bash` | V-A + new STEPs 12 and 13 in error-handling | implemented |
| P-E (partial) | D-007 | `tests/test-error-handling.bash` | new STEPs 12 and 13 | partially implemented (LOG_DIR slice only; T1-T5 remain) |

## Changed Files

| File | Change | Location |
| --- | --- | --- |
| `bin/ioc-runner` | LOG_DIR declarations + set_local_mode rebind + foot-gun guard (unchanged from hand20260514_145911) | 18 insertions, 0 deletions |
| `tests/test-error-handling.bash` | `_probe_log_dir` helper, LOG_DIR case in `test_env_var_namespacing`, LOG_DIR precedence in `test_env_var_precedence`, new `test_log_dir_guard`, new `test_log_dir_xdg_fallback`, pipeline registration | 106 insertions, 1 deletion |

Diffstat overall: `bin/ioc-runner | 18 +++`, `tests/test-error-handling.bash | 106 ++++--`. Total 123 insertions, 1 deletion across 2 files.

New test surface, per-step:

- STEP 10 (`test_env_var_namespacing`) — added one assertion:
  `IOC_RUNNER_LOCAL_LOG_DIR resolves LOG_DIR in --local`.
- STEP 11 (`test_env_var_precedence`) — added two assertions:
  `LOG_DIR: unified var wins` and `LOG_DIR: namespaced var honored when no unified`.
- STEP 12 (new) `test_log_dir_guard` — three assertions:
  system+differing triggers warning, system+matching suppresses, --local suppresses.
- STEP 13 (new) `test_log_dir_xdg_fallback` — two assertions:
  XDG_STATE_HOME unset falls back to `$HOME/.local/state/procserv`, set uses `<XDG_STATE_HOME>/procserv`.

Existing STEP numbers downstream (Bash Completion, IOC Name Validation,
Configuration Validation, Attach, List, Inspect, Crash Patterns)
shifted by +2 because two new STEPs landed between STEP 11 and STEP 12.
This is mechanical numbering; assertion content unchanged.

## Deviations From Plan

The original P-A scope did not include `tests/` changes. The development
plan placed permanent LOG_DIR test coverage in Phase E (#21). This
handoff records User-authorized expansion of P-A scope to include the
LOG_DIR test slice now, leaving T1-T5 functional tests in Phase E.

One in-development defect was caught and fixed before this handoff was
finalized: the first run of the extended suite failed `XDG_STATE_HOME
set` because the `env(1)` call passed `-u` options after `VAR=value`,
which is not portable. Re-ordering options before `VAR=value` resolved
the failure and the suite ran clean on the second run.

## Commands Run

- `bash -n tests/test-error-handling.bash` — syntax OK.
- `EPICS_BASE=/opt/epics-iocs/epics/1.2.0/debian-13/7.0.10/base timeout 600 bash tests/run-all-tests.bash --local`
  — first run: 1 failure (env arg order). Second run after fix: PASS.
- `git diff --stat bin/ioc-runner tests/test-error-handling.bash`
  — 123 insertions, 1 deletion across 2 files.

## Verification Performed

Extended `run-all-tests.bash --local` regression — second run, post fix:

```
Error Handling phase:
  Total Assertions     : 98
  Passed               : 98
  Failed               : 0
Local Lifecycle phase:
  Total Assertions     : 42
  Passed               : 42
  Failed               : 0
ALL SELECTED TEST SUITES COMPLETED SUCCESSFULLY.
exit=0
```

Host: `top` (Debian 13, dev baseline). Mode: `--local`. EPICS_BASE:
`/opt/epics-iocs/epics/1.2.0/debian-13/7.0.10/base` (7.0.10). Watchdog:
600s hard cap; suite completed well within cap.

The new STEPs 12 and 13 are part of the 98 Error Handling assertions
above. STEP 17 (Test Inspect Local Mode), STEP 23 (camonitor), and
STEP 25 (crash detection) all pass in Local Lifecycle.

## Verification Not Performed

- System-mode lifecycle (`tests/test-system-lifecycle.bash`) — requires
  sudo and a system-mode environment.
- Rocky 8 hosts (`testbed-rocky8-iocrunner-server`, `alsucl-psrv3`) —
  external hosts.
- T1-T5 (#21) — remaining Phase E scope (T1 detection without journal,
  T2 logrotate boundary, T3 IOC_PORT atomic install, T4 inspect bounded
  runtime, T5 permission enforcement).

## Current Git State

- Branch: `release-1.1.0` (switched from `master` at User direction on
  2026-05-14).
- Working tree:
  - Modified: `bin/ioc-runner` (18 insertions, 0 deletions).
  - Modified: `tests/test-error-handling.bash` (106 insertions, 1
    deletion).
  - Untracked: `docs/review_sessions/` (session artifacts).
- No staged changes. No commit. No push.

## Next Required Action

1. Reviewer 1 re-cross-check on this superseding handoff and on the
   extended diff:
   - `comments/cmt<ts>_codex_gpt5_to_claudecode_claude_opus_4_7_phase_a_ack.md`
     for accept, or
   - `reviews/fup<ts>_codex_gpt5_on_hand20260514_162603.md` for revisions.
2. After Reviewer 1 ack: User commits per cadence (a) per-milestone on
   the `release-1.1.0` branch. Updated commit message file:
   `work/commit-msg-8-log-dir-variables.txt` (will be refreshed by the
   Implementer in the same turn that publishes this handoff).
3. After commit: User issues `execution_authorization` for the next
   plan item (recommended order: P-Readiness, then P-B-1).
