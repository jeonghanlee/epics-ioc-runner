# Joining Guide for Reviewer 1

Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Prepared At: 2026-05-14 10:09:30
Prepared By: claudecode_claude_opus_4_7 (Facilitator)

This guide brings Reviewer 1 to a working understanding of the session
without requiring chat replay. Read it before publishing any artifact.

## 1. Skill Activation

Before any write tool use, Reviewer 1 must:

1. Invoke `agent-review-convergence` in the current turn.
2. Read `README.md` from the resolved session root.
3. Locate own row in `## Participants (active)`. The Facilitator will
   add the row once the User confirms your `agent_id` label
   (`<transport>_<model>`).
4. State `Acting As: Reviewer 1 (per README.md row 2)` on the first
   line of your response.
5. Do not write under `convergence/`, `plan/`, or `handoff/`. Do not
   modify `README.md`. Comments use `comments/cmt*.md` per Hard Rule 6.

## 2. Session Scope

This session produces the Implementation Readiness Packet for the
GitHub release milestone `1.1.0` (Journal decoupling release, due
2026-05-29). The four target deliverables are documented in
`README.md` "Session Objective".

The convergence cycle is L-size: review_report → review_response (if
needed) → review_followup → convergence_report → development_plan →
execution_authorization → execution (per Phase A~G) → execution_handoff
→ closure_report.

Commit cadence is (a) per-milestone: Implementer commits after each
Phase handoff is cross-checked.

## 3. Required Reading Order

1. `README.md` — session state, participants, Cross-Check Policy,
   Open User Decisions.
2. `00_source_release-1.1.0.md` — frozen inventory of issues, phases,
   dependency graph, cross-cutting concerns, and explicit review
   focus questions.
3. `docs/ARCHITECTURE.md` and `docs/CLI_REFERENCE.md` — baseline
   architecture and CLI surface the 1.1.0 changes must respect.
4. GitHub issues (live links, but the session-authoritative snapshot
   is `00_source_release-1.1.0.md`):
   - Epic: #7
   - P0: #8, #9, #10, #11
   - P1: #12
   - P2: #15, #17, #24, #49
   - P3: #18, #19, #20, #21, #22

## 4. Initial Review_Report Expectations

Artifact path:
`reviews/rev<YYYYMMDD_HHMMSS>_<your_agent_id>_initial.md`

Follow the `review_report` template in
`references/artifact-templates.md`. Required body sections:

- `## Role Assertion`
- `## Executive Summary`
- `## Reviewed Scope`
- `## Findings` — use stable IDs (F-001, F-002, ...).
- `## Required Decisions`
- `## Recommended Implementation Order`
- `## Verification Notes`

Specific questions to address (from
`00_source_release-1.1.0.md` "Source Inputs For Reviewer 1"):

1. Phase A~G granularity correctness.
2. Cross-Check Policy SKIP-allowed cell for Phase F.
3. #49 phase placement (D+ vs fold-in vs defer).
4. Acceptance criteria sufficiency for #11 and #12.
5. Test coverage vs CC1 (two-mode), CC2 (Debian/Rocky parity), CC3
   (NFS root_squash).
6. Schedule risk for 2026-05-29 due date.

## 5. Cross-Check Obligations After Convergence

Once the development plan is authorized and execution begins, Reviewer
1 cross-checks each Phase handoff. Per Cross-Check Policy:

- Phases A, B, C, D, D+, E, G — cross-check YES.
- Phase F — SKIP-allowed; Reviewer 1 may decline to cross-check or
  may opt in; either is recorded.

Cross-check artifact: `reviews/fup<ts>_<your_agent_id>_on_<hand_id>.md`
(`review_followup`). Accept, accept-with-revisions, or reject. State
`Round 1`, `Round 2`, etc. in the body Context section when revisions
loop.

## 6. Disagreement Procedure

Per `technical-discussion` skill (always active during this session):

- Make claims with evidence (file paths, line numbers, commit hashes,
  test output).
- Hold correct positions under pushback; explain context before
  yielding.
- Do not flip-flop. One correction with evidence is sufficient.

Disagreement with Facilitator content: open `comments/cmt*.md`
targeting the specific artifact. Do not edit Facilitator artifacts in
place.

Disagreement with Implementer execution: open a `review_followup`
rejecting the handoff with evidence, or a `cmt*.md` for narrower
points.

## 7. Authority Boundaries

- README.md is write-locked to the Facilitator
  (claudecode_claude_opus_4_7). Reviewer 1 requests README updates via
  `comments/cmt*.md`.
- `convergence/` is write-locked to the Facilitator.
- `plan/` and `handoff/` are write-locked to the Implementer
  (claudecode_claude_opus_4_7 also holds this role for this session).
- Reviewer 1 writes only under `reviews/` and `comments/`.

## 8. Open User Decisions Affecting Reviewer 1

| ID | Decision | Effect on Reviewer 1 |
| --- | --- | --- |
| UD001 | Confirm Reviewer 1 agent_id label | Blocks Participants row entry |
| UD002 | #49 phase placement | Affects review of Phase D+ scope |
| UD003 | #26 (Backlog) in/out of 1.1.0 docs | Affects review of Phase F docs |

The User addresses these directly; Reviewer 1 may comment on them in
the initial review_report under `## Required Decisions`.

## 9. Closure Cross-Check

When the Facilitator drafts the `closure_report`, Reviewer 1 must
accept it (via `review_followup` or short `comment`) before the
session moves to CLOSED in README.md. Closure reports describe state
at time of writing; pending gates are listed as pending, not
pre-declared complete.
