# Comment: Re-review request — F-PLAN4-1 sudoers wording narrowed in plan20260515_014254 + hand20260515_014254

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: cmt20260515_014254
Artifact Type: comment
Acting As Role: Facilitator
Date: 2026-05-15
Start Time: 01:42:54
Finalized At: 2026-05-15 01:42:54
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: hand20260515_014254
Supersedes Artifact ID: none
Target Reviewer Agent ID: codex_gpt5
Target Reviewer Model: gpt-5
Skill References: `agent-review-convergence`, `technical-discussion`, `markdown-authoring`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Facilitator
- Role Source: `README.md` row 1.
- Artifact Type Allowed: yes (Facilitator may request re-review
  after publishing supersession that resolves a blocking
  finding).
- Target Path Allowed: yes (`comments/`).
- Re-Anchor Trigger: F-PLAN4-1 resolved via formal supersession
  (per User direction "a"). plan20260515_014254 and
  hand20260515_014254 published this turn.

## Context

`fup20260515_011628` raised F-PLAN4-1 as a blocking finding on
the prior plan + handoff:

> sudoers is overstated as an `ioc-runner` execution gate.

The Facilitator concurs with the finding. The User chose option
(a) formal supersession over (b) targeted-correction comment.

Two artifacts published this turn:

- `plan/plan20260515_014254_claudecode_claude_opus_4_7_supersedes_plan20260515_010907.md`
- `handoff/hand20260515_014254_claudecode_claude_opus_4_7_supersedes_hand20260515_010907.md`

Wording-only change. No code, no V-* evidence, no runtime state
modified. The deltas are confined to the four passages
Reviewer 1 identified, plus the equivalent narrative in the
plan's `## Permission Model` and the handoff's `## Verification
Performed → sudoers boundary verification` section.

Working-tree edits applied in the same turn:

- `docs/LOG_PERMISSIONS.md` — "Access Boundary" section
  rewritten with explicit scope (what sudoers does / does not
  restrict). Later passage on "wide read at file-mode layer
  only" similarly narrowed.
- `docs/TEST_PLAN-1.1.0.md` — Phase C2 matrix row narrowed from
  "ioc-runner execution restricted ..." to "Privileged
  systemctl verbs ... gated by sudoers ...". V-C2 wording's
  negative probe target narrowed to a privileged systemctl
  call.

## Verification Of The Correction (text-level)

The four passages the Facilitator could find that previously
overstated the sudoers boundary, and their replacements:

- `plan20260515_014254` Permission Model section: replaces
  prior "Non-`ioc` users cannot run `ioc-runner` (sudoers
  layer)" with explicit "Layer 1 (sudoers): ... Layer 2 (file
  mode + default ACL): ..." breakdown plus a "What the sudoers
  layer does NOT restrict" subsection that names process
  execution and read-only paths.
- `hand20260515_014254` Verification Performed: replaces prior
  "sudoers gate restricts `ioc-runner` system-mode operations
  to `%ioc`" with the actual scope (seven privileged verbs;
  process execution and read-only paths not gated; negative
  probe narrowed to `sudo /usr/bin/systemctl start
  epics-@<name>.service`).
- `docs/TEST_PLAN-1.1.0.md` Phase C2 matrix: replaces prior
  "ioc-runner execution restricted ..." row with "Privileged
  systemctl verbs ... gated by sudoers to `%ioc`". V-C2 row
  narrowed similarly.
- `docs/LOG_PERMISSIONS.md` "Access Boundary" section:
  rewritten with explicit Effective scope, "Read-only paths
  (`ioc-runner status`, `is-active`, `cat`, `show`) do not go
  through `sudo`", and the later passage stating non-`ioc`
  users can `cat` and run the binary, just not state-change.

The Facilitator could not find additional overstating passages.
If Reviewer 1 identifies a fifth or sixth instance during
re-review, the Facilitator will fold it into a fresh
correction.

## Verification Of Carry-Over Evidence

All V-* live evidence carried forward from `hand20260515_010907`
to `hand20260515_014254` without modification:

- V-B-1: system unit text + dir `root:ioc 2770` + default ACL
  `g:ioc:rw`, `o::r--`, `m::rw`.
- V-C2 Case 1: `ioc-srv:ioc 644`, mask `r--`, other `r--`.
- V-C2 Case 2: `<engineer>:ioc 664`, mask `rw-`, other `r--`.
- V-B-2: local mode unchanged; backup distinctness verified.
- R-PLAN3-2 and R-PLAN3-5 diagnostic strings intact.

No re-deploy or re-run of any IOC was performed for this
wording-only supersession.

## Request

R-PLAN4-1 (re-review). Confirm the narrowed sudoers wording in
`plan20260515_014254`, `hand20260515_014254`,
`docs/TEST_PLAN-1.1.0.md`, and `docs/LOG_PERMISSIONS.md` matches
the actual code-enforced scope. Specifically: sudoers gates the
privileged state-changing `systemctl` verbs that `ioc-runner`
issues, not `ioc-runner` execution itself, and not read-only
paths.

R-PLAN4-2..3 + R-HAND-1..7 from `cmt20260515_010907` and your
accepted points in `fup20260515_011628` carry forward unchanged.
No need to re-evaluate.

## Expected Response

Reviewer 1 publishes one of:

- `comments/cmt<ts>_codex_gpt5_to_claudecode_claude_opus_4_7_plan_and_handoff_v2_ack.md`
  combining Step 0-R + Step 4-R accept on the corrected
  artifacts (final acceptance — Step 7 final-form recheck for
  the milestone).
- `reviews/fup<ts>_codex_gpt5_on_hand20260515_014254.md` if any
  residual blocking issue remains.

Upon Reviewer 1 ack, the Facilitator will prepare the Step 8
commit message + staging script for User commit.
