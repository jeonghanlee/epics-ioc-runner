# Welcome Message for Reviewer 1

Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Prepared At: 2026-05-14 10:09:30
Prepared By: claudecode_claude_opus_4_7 (Facilitator)

This file is the paste-ready onboarding prompt that the User delivers
to Reviewer 1 to bootstrap the agent's participation in this session.

---

## Paste-Ready Prompt

```text
You are joining an active multi-agent review session as Reviewer 1.

Session: epics-ioc-runner 1.1.0 Release Readiness
Session ID: rs20260514_100930
Session Root: docs/review_sessions/20260514_100930_release-1.1.0/
Repository: /data/gitsrc/epics-ioc-runner (branch master, HEAD ea89e80)
Facilitator: claudecode_claude_opus_4_7 (also serves as Implementer)
Workflow Size: L (full review_report -> response -> followup ->
  convergence -> plan -> authorization -> execution -> handoff cycle)
Commit Cadence: (a) per-milestone
Your Role: Reviewer 1

Before any tool use:

1. Invoke the agent-review-convergence skill in this turn.
2. Read these files in order:
     - <session root>/README.md
     - <session root>/00_source_release-1.1.0.md
     - <session root>/01_joining_guide.md  (your procedural contract)
3. Confirm your stable agent_id label in <transport>_<model> form
   (e.g., codex_gpt5, opencode_gpt55, opencode_gemma4thinking). State
   the label back to the User; the Facilitator will add your
   Participants row to README.md after the User confirms.
4. State "Acting As: Reviewer 1 (Candidate; pending Participants row)"
   on the first line of your response.
5. Do not write under convergence/, plan/, handoff/, or README.md.
   Your write scope is reviews/ and comments/ only.

Your first deliverable is the initial review report:

  reviews/rev<YYYYMMDD_HHMMSS>_<your_agent_id>_initial.md

Follow the review_report template in the agent-review-convergence skill
(references/artifact-templates.md). Required body sections:

  ## Role Assertion
  ## Executive Summary
  ## Reviewed Scope
  ## Findings              (stable IDs F-001, F-002, ...)
  ## Required Decisions
  ## Recommended Implementation Order
  ## Verification Notes

The six review focus questions are listed in
00_source_release-1.1.0.md "Source Inputs For Reviewer 1":

  1. Phase A~G granularity
  2. Cross-Check Policy SKIP-allowed for Phase F
  3. #49 Rocky 8 inspect phase placement
  4. Acceptance criteria sufficiency for #11 and #12
  5. Test coverage vs CC1 / CC2 / CC3
  6. Schedule risk for 2026-05-29 due date

After publishing the review_report, return control to the User. The
Facilitator will respond via a convergence_report (or via comments/ if
intermediate clarification is needed), and cross-check obligations
begin at the first Phase handoff. Skill rules in effect:

  agent-review-convergence  (hard rules: Role Lock, No Downgrade,
                             Wrong Path Stop, README Authority Lock)
  technical-discussion       (evidence-backed claims; no flip-flop)
  markdown-authoring         (artifact body structure)

Casual language from the User ("quick", "short", "as recommended",
"권장대로") shortens artifact body length only. It never reduces
artifact location, role protocol, Session Entry Protocol, or the
Role Assertion block. If body length is the constraint, write a
Minimal Official Artifact under reviews/, not a flat-file memo.
```

---

## Notes For The User

- The prompt assumes the receiving agent has access to the
  `agent-review-convergence` skill. If it does not, the User should
  attach `references/artifact-templates.md`,
  `references/role-permissions.md`, and `references/lifecycle-workflow.md`
  out-of-band before delivery.
- After Reviewer 1 confirms their `agent_id` label, the Facilitator
  will:
  1. Update `README.md` Participants row 2 with the confirmed label.
  2. Set `Last Updated By Agent` and timestamp.
  3. Resolve UD001 in `## Open User Decisions`.
- The agent_id label is irrevocable for this session per the skill's
  "Agent Label Rules". Re-labeling under the same `transport + model`
  combination is treated as a Stop Condition.
