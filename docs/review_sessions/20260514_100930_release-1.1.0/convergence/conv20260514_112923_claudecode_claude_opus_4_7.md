# Convergence Report: epics-ioc-runner 1.1.0 Release Readiness

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: conv20260514_112923
Artifact Type: convergence_report
Acting As Role: Facilitator
Date: 2026-05-14
Start Time: 11:29:23
Finalized At: 2026-05-14 11:29:23
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: none
Supersedes Artifact ID: none
Facilitator Agent ID: claudecode_claude_opus_4_7
Facilitator Model: claude-opus-4-7
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`, `doc-pipelines`
Inputs:

- `reviews/rev20260514_102952_codex_gpt5_initial.md` (Reviewer 1 initial review)
- `reviews/fup20260514_112053_codex_gpt5_on_rev20260514_102952.md` (Q3 follow-up)
- `comments/cmt20260514_111434_claudecode_claude_opus_4_7_to_codex_gpt5_policy_v2_check.md`
- `comments/cmt20260514_112325_claudecode_claude_opus_4_7_to_codex_gpt5_q3_fix_applied.md`
- `comments/cmt20260514_112602_codex_gpt5_to_claudecode_claude_opus_4_7_q3_ack.md`
- `README.md` (v2 with Cross-Check Policy Revisions and Procedural Document Revisions)
- `00_source_release-1.1.0.md`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Facilitator
- Role Source: `README.md` row 1 (User direction at session start)
- Artifact Type Allowed: yes (only Facilitator may publish convergence_report).
- Target Path Allowed: yes (`convergence/`).
- Re-Anchor Trigger: ack artifact cmt20260514_112602 by codex_gpt5;
  User UD003 decision on 2026-05-14.

## Decisions

### D-001. Phase C is split into C1 (detection) and C2 (permissions)

State: accepted
Source Findings: F-002
Decision: Phase C is operationally split into two cross-check gates.
C1 covers #11 (byte-offset crash detection rewrite). C2 covers #12
(log file permission model). Each phase has its own handoff and
Reviewer 1 cross-check.
Promotion Required: no

Rationale:

The two work items have orthogonal failure modes (detection
correctness and rotation behavior vs access-control surface) and a
combined cross-check would hide a permission regression behind a
detection refactor.

Applies To:

- `bin/ioc-runner` (`do_start_restart`, log scan path).
- `setup-system-infra.bash` (directory ownership and mode).
- README Cross-Check Policy (already applied).

Next Action: propagate to development_plan as separate plan items.

### D-002. #49 stays as standalone Phase D+ compatibility gate

State: accepted
Source Findings: F-003
Decision: #49 (Rocky 8 inspect Netlink/UDS rendering) is a standalone
Phase D+ gate with mandatory cross-check. It is not folded into Phase
B (templates) and is not deferred to a later milestone. It will not
be claimed auto-resolved by the #11 crash-detection rewrite without
Rocky 8 STEP 17 and STEP 24 pass logs.
Promotion Required: no

Rationale:

`docs/CLI_REFERENCE.md` and `bin/ioc-runner` `do_inspect` use
`lsof -a -U` and `ss -x -a -p`. These are a separate behavioral
surface from `do_start_restart` crash-detection. The Rocky 8 failure
is environment-dependent and not resolved by file-log scanning.

Applies To:

- `bin/ioc-runner` `do_inspect`.
- `tests/test-local-lifecycle.bash` STEP 17.
- `tests/test-system-lifecycle.bash` STEP 24.

Next Action: develop Phase D+ work item in development_plan, including
optional rewrite path for `do_inspect` if log-file basis turns out to
satisfy the contract.

### D-003. #25 is documented as already delivered

State: accepted
Source Findings: F-001
Decision: #25 (Per-IOC `CRASH_LOG_PATTERNS` override) is closed in
milestone 1.0.8 via commit `f0e4ebf` on 2026-05-13. It is removed
from Phase D scope of 1.1.0 and documented as a pre-1.1.0
prerequisite in CHANGELOG.md and the development plan.
Promotion Required: no

Rationale:

Source-snapshot drift carried a stale Phase D scope item. `gh issue
view 25` verified state=CLOSED, milestone=1.0.8.

Applies To:

- README Cross-Check Policy Phase D (already applied).
- CHANGELOG.md 1.1.0 section (Phase F) — note as pre-existing
  capability when documenting log decoupling.

Next Action: no plan item; convergence record only.

### D-004. #6 and #13 are satisfied prerequisites

State: accepted
Source Findings: F-001
Decision: #6 (Align crash scan window with service start timestamp,
closed 2026-04-19 in 1.0.4) and #13 (Enable `set -o pipefail`, closed
2026-04-22 in 1.0.5) are pre-1.1.0 prerequisites already merged. No
1.1.0 action required.
Promotion Required: no

Rationale:

`gh issue view` confirmed both closed in earlier 1.0.x releases.
Dependency references in #11, #12, #21 issue bodies remain valid as
historical record.

Applies To:

- 00_source_release-1.1.0.md dependency graph note (kept as
  historical record; not a blocking gap).

Next Action: no plan item; convergence record only.

### D-005. Phase F cross-check is restricted

State: accepted
Source Findings: F-006
Decision: Phase F SKIP-allowed applies to #19 (CHANGELOG) and #20
(README migration) only. Phase F #18 (`docs/LOG_LAYOUT.md`) requires
Reviewer 1 cross-check because it records operator-facing paths,
permissions, retention behavior, and the systemd >= 235 floor (CC4).
Promotion Required: no

Rationale:

Mechanical doc updates (release notes, migration steps) are
defensibly SKIP-allowed. Operator-facing reference docs that codify
the permission model are not.

Applies To:

- README Cross-Check Policy Phase F (already applied).

Next Action: propagate to development_plan; #18 handoff carries
Reviewer 1 cross-check, #19 and #20 may proceed without.

### D-006. Phase acceptance matrix is required for #11 and #12

State: accepted
Source Findings: F-004
Decision: The development_plan must include a phase acceptance matrix
for #11 and #12 with columns: local mode, system mode, Debian 13,
Rocky 8, NFS root_squash, negative permission check.
Promotion Required: no

Rationale:

Issue acceptance prose is sufficient for engineering intent but
needs release-gate operationalization for cross-platform and
multi-mode coverage (CC1, CC2, CC3).

Applies To:

- `plan/plan<ts>_claudecode_claude_opus_4_7.md` Plan Item Matrix and
  Verification subsections for P-C1 and P-C2.

Next Action: include matrix in development_plan.

### D-007. Per-phase verification commands are required at handoff

State: accepted
Source Findings: F-005
Decision: Each phase handoff carries at least one narrow verification
command exercising the new behavior introduced in that phase. Phase E
(#21 integration test expansion) then consolidates those commands into
permanent test scripts.
Promotion Required: no

Rationale:

Deferring all verification to Phase E creates late cross-platform
discovery risk after templates and permission model have already
landed. The CC1/CC2/CC3 surface is too wide to validate only once.

Applies To:

- Each `handoff/hand<ts>_*.md` in the execution path.
- `plan/plan<ts>_claudecode_claude_opus_4_7.md` File-Level Change Plan
  Verification subsections.

Next Action: include per-phase verification command in development_plan
and execute at each handoff.

### D-008. Schedule risk recorded as moderate

State: accepted
Source Findings: F-007
Decision: 2026-05-29 release date is achievable but moderate-risk.
Critical path is Phase A → C1 → C2 → D+ . Phase F/G stay small. Phase
E may not become the first complete verification point (consistent with
D-007).
Promotion Required: no

Rationale:

15 open issues plus #49, two distributions, two execution modes, NFS
root_squash, and a security-sensitive permission change concentrate
risk on the critical path. Recovery boundary is per-phase
file-/worktree-level correction without git history mutation.

Applies To:

- `plan/plan<ts>_claudecode_claude_opus_4_7.md` Recovery Boundary.

Next Action: record recovery boundary in development_plan and gate
phase entry on prior phase handoff acceptance.

### D-009. Backlog #26 excluded from 1.1.0 documentation

State: accepted
Source Findings: UD003 (User direction)
Decision: Issue #26 (upstream procServ SIGUSR1 log reopen) is excluded
from all 1.1.0 documents. No forward-looking note in
`docs/LOG_LAYOUT.md`, no reference in `CHANGELOG.md`. #26 remains in
the `Backlog` milestone as upstream work.
Promotion Required: no

Rationale:

User direction on 2026-05-14: "백로그는 1.1.0 에서 제외시켜".
Documentation scope is kept tight on shipped behavior; upstream
dependencies are tracked separately in the Backlog milestone.

Applies To:

- `docs/LOG_LAYOUT.md` (no #26 reference).
- `docs/CHANGELOG.md` 1.1.0 section (no #26 reference).

Next Action: Implementer respects this exclusion in Phase F docs.

## Finding State Matrix

| Finding ID | Source | State | Decision ID | Blocks Execution | Next Action |
| --- | --- | --- | --- | --- | --- |
| F001 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted | D-003, D-004 | no | convergence record |
| F002 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted | D-001 | no | propagate to plan |
| F003 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted | D-002 | no | propagate to plan |
| F004 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted | D-006 | yes | plan acceptance matrix |
| F005 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted | D-007 | yes | plan per-phase verification |
| F006 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted | D-005 | no | propagate to plan |
| F007 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted | D-008 | no | record in plan Recovery Boundary |

## ID Crosswalk

| Normalized ID | Source IDs | Source Artifacts | State |
| --- | --- | --- | --- |
| F001 | F-001 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted |
| F002 | F-002 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted |
| F003 | F-003 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted |
| F004 | F-004 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted |
| F005 | F-005 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted |
| F006 | F-006 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted |
| F007 | F-007 | `reviews/rev20260514_102952_codex_gpt5_initial.md` | accepted |

Reviewer 1 was the sole reviewer for this round; the crosswalk has no
multi-source merges.

## Accepted Findings

All seven findings F-001 through F-007 are accepted. See Finding State
Matrix above for each finding's mapped decision and next action.

## Deferred Findings

None.

## Rejected Findings

None.

## Implementation Boundary

The Implementer's development plan is authorized to make changes
within the following boundary, and only within this boundary, without
returning to convergence:

In scope:

- `bin/ioc-runner` for #8 (LOG_DIR variables), #11 (crash detection
  rewrite), #12 (permission model enforcement helpers), #24 (journal
  fallback path), #49 (inspect Rocky 8 compatibility, optionally
  log-file basis).
- `setup-system-infra.bash` for #9 (system template), #15 (logrotate
  deployment), #12 (directory ownership and mode).
- `deploy_local_template` (function in `bin/ioc-runner`) for #10
  (user systemd unit log path and local log directory creation).
- `tests/test-local-lifecycle.bash`, `tests/test-system-lifecycle.bash`,
  `tests/test-system-infra.bash`, `tests/test-error-handling.bash`,
  `tests/run-all-tests.bash` for #21 (T1-T5 additions and Rocky 8
  regression coverage), per-phase verification commands per D-007.
- `docs/LOG_LAYOUT.md` (new) for #18.
- `docs/CHANGELOG.md` (new section for 1.1.0) for #19.
- `docs/README.md` migration section for #20.
- `docs/ROADMAP-1.1.0.md` (new) for the Development Milestones
  artifact of the Implementation Readiness Packet.
- `docs/TEST_PLAN-1.1.0.md` (new) for the Test Plan artifact of the
  Implementation Readiness Packet.
- Operational removal of `systemd-journal` group from operator
  accounts for #17 (deployment runbook step, not code).

Out of scope:

- #25 (already delivered in 1.0.8).
- #6, #13 (already delivered in 1.0.4, 1.0.5).
- #26 (Backlog, upstream procServ work).
- `docs/ARCHITECTURE.md` rewrite — deltas only, no rewrite.
- `docs/CLI_REFERENCE.md` rewrite — deltas only for `do_inspect` if
  D-002 rework lands; otherwise no change.
- Any change to `bin/ioc-runner` outside the scoped functions or to
  files not listed above.

Phase mapping (informational; authoritative is README Cross-Check
Policy):

```
A   #8                        LOG_DIR variables
B   #9, #10, #15              templates and logrotate
C1  #11                       detection rewrite
C2  #12                       permission model
D   #17, #24                  ops: grant removal, fallback
D+  #49                       Rocky 8 inspect gate
E   #21                       integration test expansion
F   #18, #19, #20             docs (LOG_LAYOUT cross-check; CHANGELOG/README SKIP-allowed)
G   #22                       RUNNER_VERSION bump and release
```

Per-milestone commit cadence applies (README v2). The Implementer
commits after each phase handoff is cross-checked.

## Promotion Requirements

| Decision ID | ADR Path | State |
| --- | --- | --- |
| (none) | (none) | (n/a) |

No decision in this convergence requires ADR promotion. All decisions
are operational and within the session's review scope. The
Cross-Check Policy revisions are recorded in README.md as the
session-authoritative location.

## Open Questions Requiring User Decision

None. UD001 through UD005 are closed in `README.md`
`## Open User Decisions`. RD-001 through RD-005 (from Reviewer 1) are
resolved by User direction on 2026-05-14.

The Implementer (claudecode_claude_opus_4_7, dual role) may proceed
to author `plan/plan<YYYYMMDD_HHMMSS>_claudecode_claude_opus_4_7.md`
based on this convergence report, subject to subsequent
`execution_authorization` from the User before any source file in
`bin/ioc-runner` or related repository content is modified.
