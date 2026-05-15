# Execution Authorization: UD006 — combined P-B-1 + P-B-2 + P-C2 start

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: auth20260514_235635
Artifact Type: execution_authorization
Acting As Role: Facilitator (scribe recording User direction)
Date: 2026-05-14
Start Time: 23:56:35
Finalized At: 2026-05-14 23:56:35
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: plan20260514_233353
Supersedes Artifact ID: none
Authorized By: User (jeongLee@lbl.gov), chat direction 2026-05-14 23:56 after Step 1 snapshot commit `9f569ea` landed and Step 0-R Reviewer 1 ack `cmt20260514_234412` was on disk.
Authorized Plan: `plan/plan20260514_233353_claudecode_claude_opus_4_7_supersedes_plan20260514_231659.md`
Authorized Scope: combined P-B-1 + P-B-2 + P-C2 against `plan20260514_233353`.
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`, `bash-coding`, `git-workflow`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Facilitator (scribe recording User direction)
- Role Source: `README.md` row 1 (Facilitator + Implementer dual role).
- Artifact Type Allowed: yes (Facilitator recording User direction
  may publish execution_authorization per
  `references/execution-gates.md`).
- Target Path Allowed: yes (`plan/`).
- Re-Anchor Trigger: User direction on 2026-05-14 23:56 after Step 1
  snapshot commit `9f569ea` landed on `release-1.1.0`.

## Authorization Statement

The User has authorized the Implementer to begin combined
P-B-1 + P-B-2 + P-C2 execution against development plan
`plan20260514_233353`.

User direction, verbatim:

> 다음 갑시다.

Translation: "Let's go to the next [step]." In the gate-model
context, "next" after Step 1 snapshot commit is Step 2 (User
direction authorizing the milestone scope). The Facilitator
interprets the direction as a green light for the recommended
plan item — combined P-B-1 + P-B-2 + P-C2 per `plan20260514_233353`.

Per `agent-review-convergence` Hard Rule 2, the casual phrasing
reduces artifact body length only; the underlying procedural
requirements (Session Entry, Role Assertion, authorization
recording, handoff cross-check, User commit at Step 8) remain in
force.

## Authorized Plan Items

- **P-B-1** (`#9`) — `bin/setup-system-infra.bash` and the system
  systemd template. Includes:
  - New `SYSTEM_LOG_DIR` variable (parity with `bin/ioc-runner`).
  - New install STEP that runs `install -d -o root -g ioc -m 2770
    "${SYSTEM_LOG_DIR}"` plus three `setfacl -d -m` lines
    (`g:ioc:rw`, `o::---`, `m::rw`) and a `verify_path` check.
  - System unit heredoc edits: add `UMask=0007`; modify `ExecStart=`
    to use `--logfile=${SYSTEM_LOG_DIR}/%i.log`; keep
    `User=${SYSTEM_USER}`, `Group=${SYSTEM_GROUP}`,
    `StandardOutput=syslog`, `StandardError=inherit`,
    `SyslogIdentifier=epics-%i` unchanged; no `LogsDirectory=*`.
- **P-B-2** (`#10`) — `bin/ioc-runner` local user template.
  Includes:
  - `deploy_local_template` becomes always-overwrite; existing
    template is preserved via `mktemp "${template_path}.bak.XXXXXXXX"`
    plus immediate `mv -f`.
  - Heredoc body adds `UMask=0027` and `--logfile=${LOCAL_LOG_DIR}/%i.log`.
  - `do_install` local branch gains `install -d -m 0750 "${LOCAL_LOG_DIR}"`
    before `deploy_local_template` runs.
- **P-C2** (`#12`) — Permission model verification (no new code beyond
  P-B-1 / P-B-2). `docs/TEST_PLAN-1.1.0.md` V-C2 wording updated to
  match Case 1 (procServ-created) and Case 2 (engineer-created file
  with default ACL).

## Authorized Deliverables (this milestone commit)

- `bin/setup-system-infra.bash` (edits per P-B-1).
- `bin/ioc-runner` (edits per P-B-2).
- `docs/TEST_PLAN-1.1.0.md` (V-B-1, V-B-2, V-C2 wording updates).
- `docs/LOG_PERMISSIONS.md` (currently untracked; lands with this
  commit per plan20260514_233353).

## Implementation-Time Refinements Carried From Step 0-R

Reviewer 1's Step 0-R ack flagged two non-blocking refinements for
the Implementer to apply during P-B-1 coding:

- R-PLAN3-2 — clearer diagnostic on `mktemp` failure (e.g.,
  read-only home directory).
- R-PLAN3-5 — `command -v setfacl` preflight check in
  `setup-system-infra.bash` with a clear error message if absent.

The handoff body at Step 4 must explicitly cite both as resolved,
so the 4-R cross-check can audit them.

## Exclusions

- P-B-3 (`#15`, logrotate). Reserved for a later separate milestone
  per the established Phase B split.
- All other plan items: P-C1, P-D-1, P-D-2, P-D+, P-E, P-F-1,
  P-F-2, P-F-3, P-G.
- Any git commit, push, branch creation, or remote-state change.
  The Implementer prepares file changes and the handoff artifact
  only; the User runs the phase commit at Step 8.

## Next Gate

Step 3-R — Reviewer 1 review of this execution_authorization.
Reviewer 1 publishes one of:

- `comments/cmt<ts>_codex_gpt5_to_claudecode_claude_opus_4_7_auth20260514_235635_ack.md`
  if the authorization scope and the Implementation-Time
  Refinements section match Reviewer 1's reading.
- `reviews/fup<ts>_codex_gpt5_on_auth20260514_235635.md` if any
  authorization-level finding requires revision.

The Implementer does not begin code edits until Step 3-R is on
disk.
