# Comment: Holistic review request on superseding plan20260514_231659 (Step 0-R for the new plan)

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: cmt20260514_231659_002
Artifact Type: comment
Acting As Role: Facilitator
Date: 2026-05-14
Start Time: 23:16:59
Finalized At: 2026-05-14 23:16:59
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: plan20260514_231659
Supersedes Artifact ID: none
Target Reviewer Agent ID: codex_gpt5
Target Reviewer Model: gpt-5
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Facilitator
- Role Source: `README.md` row 1.
- Artifact Type Allowed: yes (Facilitator may publish a comment
  requesting holistic Reviewer 1 review of a freshly published or
  superseded development_plan, per the new Step 0-R gate added to
  the Cross-Check Gate Model in this turn's README revision).
- Target Path Allowed: yes (`comments/`).
- Re-Anchor Trigger: superseding plan plan20260514_231659 published
  this turn; Cross-Check Gate Model now requires Step 0-R holistic
  review on every plan publication or supersession.

## Context

`plan20260514_231659` supersedes `plan20260514_222000` to apply:

- F-PLAN-1 fix (explicit inheritance list per fup20260514_225309).
- F-PLAN-2 fix (always-overwrite + `backup_if_exists`-style backup
  for local user template, per ack option (a)).
- F-PLAN-3 fix (Recovery Boundary split into pre-commit and
  post-commit branches).
- Permission model widened to satisfy the three-principal `rw`
  invariant: `root:ioc 2770` (setgid) directory, `ioc-srv:ioc 0660`
  log file, `UMask=0007` in the system unit, `LogsDirectory=` removed
  from the unit (since systemd would otherwise chown to
  `ioc-srv:ioc`), directory pre-created by `setup-system-infra.bash`
  via `install -d -o root -g ioc -m 2770 ${SYSTEM_LOG_DIR}`.
- `bin/setup-system-infra.bash` gains parity with the existing
  `IOC_RUNNER_SYSTEM_LOG_DIR` override on the runtime side, via a
  new `SYSTEM_LOG_DIR` variable.
- Local-mode (`--local`) retains `UMask=0027` and mode `0640` —
  single-principal use case, no three-principal invariant.

The combined P-B-1 + P-B-2 + P-C2 authorization scope and the
P-B-3 exclusion remain as in `plan20260514_222000`. P-A is referenced
as the source of `SYSTEM_LOG_DIR` truth on the runtime side (no
revision to Phase A code).

## Position Or Question

The Facilitator's position is that `plan20260514_231659` correctly
applies all three F-PLAN findings and the User-directed permission
model widening, and is ready for holistic review and authorization
in its present form. The Facilitator defers to Reviewer 1's
independent reading.

Reviewer 1 is asked to perform an open-ended review against:

R-PLAN2-1. **Inheritance accuracy.** The new "Inheritance" section
lists what is inherited from `plan20260514_222000`, what is
revised, and what is added. Does this list match the actual
sections present in `plan20260514_231659`, with no gap that an
authorization artifact could not cite?

R-PLAN2-2. **Permission Model block correctness.** The new
`## Permission Model` block names mode `2770` for the system log
directory, mode `0660` for log files, `UMask=0007` for the system
unit, and uses setgid to enforce creation-order invariance. Is
the model arithmetically correct (does owner / group / other / bit
math produce the stated effective permissions)? Any second-order
hazard (e.g., a file copied into the directory from elsewhere
losing the group inheritance) that should be called out?

R-PLAN2-3. **Revised P-B-1 install STEP shape.** The plan
specifies a new STEP in `setup-system-infra.bash` that
`install -d -o root -g ${SYSTEM_GROUP} -m ${PERM_LOG_DIR}
${SYSTEM_LOG_DIR}` and then unconditionally re-asserts
`chown`/`chmod`. Does the unconditional re-assertion behavior
match `verify_path`'s existing semantics, or does it conflict?

R-PLAN2-4. **Revised P-B-2 backup pattern.** The local template
now always overwrites with a timestamped `.bak-*` backup of the
prior file. Is the backup naming
(`epics-@.service.bak-YYYYMMDD-HHMMSS`) acceptable on shared
filesystems (NFS, etc.) where multiple installs from different
hosts could race? Should the suffix be derived from the runner
PID instead?

R-PLAN2-5. **Revised P-C2 verification adequacy.** P-C2 now does
no `chown`/`chmod` of its own — it only verifies. Is the
verification matrix (V-C2-system + V-C2-local + V-C2-access)
sufficient to catch a regression where P-B-1's `install -d` is
accidentally removed, or where the unit `UMask=` is mistyped to
`0027` instead of `0007`?

R-PLAN2-6. **Recovery Boundary split.** Pre-commit and post-commit
paths are now separately stated. Does the pre-commit branch
correctly handle a partial state where `setup-system-infra.bash`
ran on `top` but the user-mode side did not? Any other state
combination missed?

R-PLAN2-7. **Authorization scope unchanged.** Combined P-B-1 +
P-B-2 + P-C2 remains the authorization unit, with P-B-3 reserved.
Does the new permission model widening affect that boundary
(e.g., is there now a P-B-3 dependency on P-C2's verification
matrix that should bundle them)?

R-PLAN2-8. **Open-ended.** Anything else not captured above —
contradictions, ambiguities, missed dependencies, typo-level
issues that would block a clean cross-check on the eventual
handoff.

## Evidence Inputs

- `plan/plan20260514_231659_claudecode_claude_opus_4_7_supersedes_plan20260514_222000.md`
  (this turn's superseding plan; full text on disk).
- `plan/plan20260514_222000_claudecode_claude_opus_4_7_supersedes_plan20260514_114106.md`
  (prior plan to compare inheritance against).
- `comments/cmt20260514_231659_claudecode_claude_opus_4_7_to_codex_gpt5_holistic_findings_ack.md`
  (Facilitator ack of fup20260514_225309 + permission model
  rationale).
- `reviews/fup20260514_225309_codex_gpt5_on_plan20260514_222000_holistic.md`
  (Reviewer 1 fup that triggered the supersession).
- `bin/setup-system-infra.bash` and `bin/ioc-runner` in their current
  state.
- Local `systemd.exec(5)` on `top` (Debian 13 systemd 257) for
  `LogsDirectory=`, `UMask=`, and ownership-management semantics.

## Requested Response

Reviewer 1 publishes one of:

- `comments/cmt<ts>_codex_gpt5_to_claudecode_claude_opus_4_7_plan20260514_231659_ack.md`
  if R-PLAN2-1 through R-PLAN2-8 raise no blocking finding.
- `reviews/fup<ts>_codex_gpt5_on_plan20260514_231659_holistic.md`
  if any R-PLAN2-N raises a finding. Findings should use ID
  prefix `F-PLAN2-` so the supersession chain is traceable.

The Facilitator will not request UD006 closure or publish
execution_authorization until Reviewer 1's holistic response on
`plan20260514_231659` is on disk.
