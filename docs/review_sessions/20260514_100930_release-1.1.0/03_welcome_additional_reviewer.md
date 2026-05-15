# Welcome Message for Additional Reviewer (Reviewer N)

Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Prepared At: 2026-05-14 10:45:00
Prepared By: claudecode_claude_opus_4_7 (Facilitator)

This file is the paste-ready onboarding prompt for any Reviewer joining
after Reviewer 1 (codex_gpt5) has already published the initial review
report. The User customizes `N` and delivers the prompt to the new
agent.

## What's Different From Reviewer 1's Welcome

Reviewer 1 produced the initial `review_report`
(`rev20260514_102952`). New reviewers must NOT write a fresh
`review_report` — that role is closed for this session. Instead, the
new reviewer writes a `review_response` that targets Reviewer 1's
report, agreeing, disagreeing with evidence, or adding new findings.

This preserves the lifecycle order:

```
review_report (Reviewer 1, done)
  → review_response (Reviewer 2, 3, ...)   <-- new reviewer publishes here
  → review_followup (later passes if any)
  → convergence_report (Facilitator)
```

---

## Paste-Ready Prompt

```text
You are joining an active multi-agent review session as Reviewer <N>.

Session: epics-ioc-runner 1.1.0 Release Readiness
Session ID: rs20260514_100930
Session Root: docs/review_sessions/20260514_100930_release-1.1.0/
Repository: /data/gitsrc/epics-ioc-runner (branch master, HEAD ea89e80)
Facilitator: claudecode_claude_opus_4_7 (also serves as Implementer)
Workflow Size: L
Commit Cadence: (a) per-milestone
Existing Reviewer: Reviewer 1 = codex_gpt5 (published rev20260514_102952)
Your Role: Reviewer <N>

Before any tool use:

1. Invoke the agent-review-convergence skill in this turn.
2. Read these files in order:
     - <session root>/README.md
     - <session root>/00_source_release-1.1.0.md
     - <session root>/01_joining_guide.md       (procedural contract;
                                                  applies to you too,
                                                  Reviewer-N substitutes
                                                  Reviewer-1 wherever
                                                  named)
     - <session root>/reviews/rev20260514_102952_codex_gpt5_initial.md
                                                  (Reviewer 1's report;
                                                  this is your direct
                                                  target)
3. Confirm your stable agent_id label in <transport>_<model> form
   (e.g., opencode_gpt55, opencode_gemma4thinking, opencode_claude_opus_4_7,
   claudecode_sonnet_4_6). The full <transport>_<model> composite must
   not match any registered participant — currently
   claudecode_claude_opus_4_7 (Facilitator) and codex_gpt5 (Reviewer 1).
   Reusing one component is permitted as long as the composite differs
   (e.g., opencode_gpt5 is allowed alongside codex_gpt5; codex_some_other_model
   would also be allowed). State the label back to the User; the
   Facilitator will add your Participants row to README.md after the
   User confirms.
4. State "Acting As: Reviewer <N> (Candidate; pending Participants row)"
   on the first line of your response.
5. Do not write under convergence/, plan/, handoff/, or README.md.
   Your write scope is reviews/ and comments/ only.
6. Do NOT write a fresh review_report. Reviewer 1's report is the
   anchor for this round.

Your first deliverable is a review_response targeting Reviewer 1's
report:

  reviews/rsp<YYYYMMDD_HHMMSS>_<your_agent_id>_on_rev20260514_102952.md

Follow the review_response template in agent-review-convergence
(references/artifact-templates.md). Required body sections:

  ## Role Assertion
  ## Agreement                   (which of Reviewer 1's findings
                                  F-001..F-007 you confirm, and why)
  ## Disagreement With Evidence  (which findings you contest, cite
                                  files/lines/commits/test output)
  ## Additional Findings         (use IDs F-101, F-102, ... so they do
                                  not collide with Reviewer 1's F-0xx)
  ## Questions For Convergence

Header field requirements (per artifact-templates.md):

  Target Artifact ID: rev20260514_102952
  Responding To: `reviews/rev20260514_102952_codex_gpt5_initial.md`
  Acting As Role: Reviewer

Focus areas where independent perspective is most valuable (chosen
because Reviewer 1 already covered them but a second opinion changes
the convergence weight):

  A. Phase C1/C2 split correctness — is detection / permissions the
     right axis, or is the real coupling along a different one?
  B. #49 Phase D+ standalone vs deferral — does the Rocky 8 gate
     actually belong in 1.1.0 if it doesn't auto-resolve?
  C. Cross-cutting concerns CC1-CC4 coverage gaps — does the proposed
     phase acceptance matrix actually cover them, or are there blind
     spots?
  D. Schedule risk (F-007) — 2026-05-29 due date realism with the
     revised Phase A..G + D+ scope.
  E. Anything Reviewer 1 missed — security, ops, NFS, EPICS-side
     concerns Reviewer 1 may have under-weighted.

After publishing the review_response, return control to the User. The
Facilitator will run the convergence cycle once all reviewers have
published (or once the User signals that the review window is closed).
Skill rules in effect:

  agent-review-convergence  (hard rules: Role Lock, No Downgrade,
                             Wrong Path Stop, README Authority Lock)
  technical-discussion       (evidence-backed claims; no flip-flop)
  markdown-authoring         (artifact body structure)

Casual language from the User ("quick", "short", "as recommended",
"권장대로") shortens artifact body length only. It never reduces
artifact location, role protocol, Session Entry Protocol, or the
Role Assertion block.
```

---

## Notes For The User

- Substitute `<N>` with the slot number (`2`, `3`, ...) before pasting.
- If the receiving agent does not have the
  `agent-review-convergence` skill installed, attach
  `references/artifact-templates.md`,
  `references/role-permissions.md`, and
  `references/lifecycle-workflow.md` out-of-band.
- The Facilitator will register the new reviewer in README.md
  `## Participants (active)` only after the User confirms the
  agent_id label. The Participants table currently has rows 1 and 2;
  Reviewer 2 will be row 3, Reviewer 3 will be row 4, etc.
- Label collision is a Stop Condition. The full `<transport>_<model>`
  composite must not match any registered participant
  (`claudecode_claude_opus_4_7` or `codex_gpt5`). Reusing one component
  is permitted as long as the composite differs. Bare model-only or
  transport-only labels (e.g., `claude_opus_4_7`, `gpt5`, `opencode`)
  are not permitted in this environment.
- Multiple `review_response` artifacts may coexist in `reviews/`. The
  Facilitator merges them at convergence time. No reviewer needs to
  wait for the others.
- Convergence will not be authored until either (a) the User signals
  that the review window is closed, or (b) all expected reviewers have
  published their response.

## Revision History

| At | Change | Source |
| --- | --- | --- |
| 2026-05-14 11:25:00 | Replaced ambiguous "in either transport or model" wording in two locations with a single consistent rule: the full `<transport>_<model>` composite must not match any registered participant; component-level reuse is permitted as long as the composite differs. | `reviews/fup20260514_112053_codex_gpt5_on_rev20260514_102952.md` (Reviewer 1 Q3 correction) |
