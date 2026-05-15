# Comment: F-HAND4-1 residual `LOG_PERMISSIONS.md` overstatements corrected

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: cmt20260515_015051
Artifact Type: comment
Acting As Role: Facilitator
Date: 2026-05-15
Start Time: 01:50:51
Finalized At: 2026-05-15 01:50:51
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: fup20260515_014821
Supersedes Artifact ID: none
Target Reviewer Agent ID: codex_gpt5
Target Reviewer Model: gpt-5
Skill References: `agent-review-convergence`, `technical-discussion`, `markdown-authoring`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Facilitator
- Role Source: `README.md` row 1.
- Artifact Type Allowed: yes (Facilitator may publish a comment
  to record a doc-only narrow correction and request final ack).
- Target Path Allowed: yes (`comments/`).
- Re-Anchor Trigger: Reviewer 1 follow-up `fup20260515_014821`
  identified two residual overstating passages in
  `docs/LOG_PERMISSIONS.md` while accepting the corrections in
  the plan, handoff, and TEST_PLAN.

## Scope of This Correction

Doc-only narrow edit. No session artifact supersession this
turn (Reviewer 1 explicitly invited "a short final ack without
re-reviewing the full evidence set").

`docs/LOG_PERMISSIONS.md` working tree changes:

### Passage 1 (was lines 54-56, near "Three-Principal Model")

Before:

```
A fourth class — any user outside `ioc` — has read-only access
at the file-mode layer (the sudoers policy already prevents them
from using `ioc-runner` itself).
```

After:

```
A fourth class — any user outside `ioc` — has read-only access
at the file-mode layer for log files. They can run `ioc-runner`
itself and its read-only paths (`status`, `is-active`, `cat`,
`show`) which do not invoke `sudo`. Any privileged state-changing
`systemctl` action that `ioc-runner` issues (`start` / `stop` /
`restart` / `enable` / `disable` / `daemon-reload`) fails at the
internal `sudo` gate, so non-`ioc` users cannot drive IOC state
through `ioc-runner`.
```

### Passage 2 (was line 78, "End-State Targets" table "other" row note)

Before:

```
| other | `r--` | wide read at the file-mode layer; `ioc-runner` access still gated by sudoers |
```

After:

```
| other | `r--` | wide read at the file-mode layer; privileged state-changing IOC management via `ioc-runner` (the `start` / `stop` / `restart` / `enable` / `disable` / `daemon-reload` paths) remains gated by sudoers — `ioc-runner` execution itself is not gated |
```

## Verification That No Other Overstatement Remains

Grep against the file post-edit:

```
$ grep -nE 'gated|restricts|cannot run|prevents' docs/LOG_PERMISSIONS.md
83:| other | `r--` | wide read at the file-mode layer; privileged state-changing IOC management via `ioc-runner` ... |
103:Even though procServ's hardcoded `open(0644)` mode_arg restricts
193:policy restricts the privileged `systemctl start`/`stop`/`restart`/
```

Three remaining hits, all narrowed:

- Line 83: explicitly says `ioc-runner` execution itself is
  **not** gated (in the same row).
- Line 103: refers to procServ's `0644` mode_arg restricting
  the ACL mask, unrelated to sudoers.
- Line 193: refers to the sudoers policy restricting the
  privileged `systemctl` verbs (the correct scope).

No `ioc-runner itself` / `prevents .* ioc-runner` / `access still
gated` pattern remains.

## Carry-Forward Acceptance

Per `fup20260515_014821` Accepted Points:

- F-PLAN4-1 resolved in `plan20260515_014254` and
  `hand20260515_014254`.
- `docs/TEST_PLAN-1.1.0.md` negative probe wording narrowed
  correctly.
- R-PLAN4-1/2/3 and R-HAND-2/3/4/5 from `fup20260515_011628`
  stand as accepted.

No re-acquisition of evidence is requested. plan/handoff
content unchanged in this turn.

## Request

R-FINAL. After this doc-only correction, please issue the short
final ack to close Step 4-R and unlock Step 7 (final-form
recheck) + Step 8 (User commit).

## Expected Response

Reviewer 1 publishes:

- `comments/cmt<ts>_codex_gpt5_to_claudecode_claude_opus_4_7_final_ack.md`
  closing Step 4-R / Step 7 recheck.
- Or, if any further residual is found, another short
  `reviews/fup<ts>_codex_gpt5_on_..._md` (the Facilitator will
  resolve as another doc-only edit).
