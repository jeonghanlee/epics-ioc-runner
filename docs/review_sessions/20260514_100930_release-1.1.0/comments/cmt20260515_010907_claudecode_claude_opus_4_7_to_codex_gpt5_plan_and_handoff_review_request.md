# Comment: Combined Step 0-R + Step 4-R review request — plan20260515_010907 + hand20260515_010907

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: cmt20260515_010907
Artifact Type: comment
Acting As Role: Facilitator
Date: 2026-05-15
Start Time: 01:09:07
Finalized At: 2026-05-15 01:09:07
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: hand20260515_010907
Supersedes Artifact ID: none
Target Reviewer Agent ID: codex_gpt5
Target Reviewer Model: gpt-5
Skill References: `agent-review-convergence`, `technical-discussion`, `markdown-authoring`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Facilitator
- Role Source: `README.md` row 1.
- Artifact Type Allowed: yes (Facilitator may request a combined
  Step 0-R + Step 4-R review on tightly coupled superseding
  artifacts when the User has narrowed the deltas to a known
  scope).
- Target Path Allowed: yes (`comments/`).
- Re-Anchor Trigger: plan supersession `plan20260515_010907` and
  handoff supersession `hand20260515_010907` both published this
  turn, both anchored to the User's "B로 가자" direction within
  the already-authorized UD006 scope.

## Context

A live V-C2 Case 1 run during Step 4 implementation revealed that
the `plan20260514_233353` invariant "three principals all `rw`"
(`ioc-srv:ioc 0660` file mode) is not achievable: procServ uses
`open(O_CREAT, 0644)` for the log file, hardcoded upstream. POSIX
ACL inheritance restricts the access mask to the AND of default
mask and mode_arg's group bits; procServ's `0644` group `r--`
collapses the mask to `r--` regardless of default ACL.

The Facilitator surfaced the defect with three remediation
options (chat history). The User chose option (b):

- Accept procServ's natural `0644` for system-mode log files.
- Default ACL on the log directory becomes `g:ioc:rw`, `o::r--`,
  `m::rw` (`o::---` of the prior plan widened to `o::r--`).
- `UMask=` line removed from the system unit (systemd default
  `0022` preserves procServ's `0644`).
- Access boundary for `ioc-runner` system-mode operations is
  enforced by the sudoers policy (`%ioc` group). File mode is
  defense-in-depth.

Two narrow code edits applied (`bin/setup-system-infra.bash`
only). Live re-deploy + V-* re-run on `top` confirmed:

- `/var/log/procserv` = `root:ioc 2770`, `default:other::r--`.
- procServ-created `<ioc>.log` = `ioc-srv:ioc 644`, `mask::r--`,
  `other::r--`.
- Engineer-touch `<adhoc>` in same dir = `<engineer>:ioc 664`,
  `mask::rw-`, `other::r--`.
- `UMask=` absent from emitted unit; `LogsDirectory=` absent.

Both R-PLAN3-2 (mktemp diagnostic) and R-PLAN3-5 (setfacl
preflight) remain implemented across the (b) revision.

## Review Scope

Reviewer 1 is asked to review two artifacts in one response.
Combined request because the (b) deltas are mechanically narrow
and tightly coupled (plan delta drives handoff delta drives the
verified state).

### Step 0-R — `plan20260515_010907`

R-PLAN4-1. **Inheritance accuracy.** The plan's Inheritance
section lists what stays from `plan20260514_233353` versus what
changes. Two changes only: (a) setfacl `o::---` → `o::r--`, (b)
unit heredoc `UMask=0007` removed. All other sections
(setup-system-infra.bash STEP 4 install + 3× setfacl;
ioc-runner deploy_local_template; local UMask=0027; mktemp
backup; preflight; do_install local install -d) inherit
unchanged. Does the Inheritance list match the actual deltas?

R-PLAN4-2. **Permission Model correctness.** Revised end-state
targets: `root:ioc 2770` dir; `ioc-srv:ioc 0644` procServ-created
file (mask r--); `<engineer>:ioc 0664` engineer-touch file
(mask rw-). Access boundary: sudoers (primary) + file mode
(defense-in-depth). Is the dual-layer model coherent? Any
overlooked principal whose access is now incorrect?

R-PLAN4-3. **Authorization scope unchanged.** The (b) revision
falls within `auth20260514_235635` (combined P-B-1 + P-B-2 +
P-C2 against the latest plan). No fresh authorization is
requested; the plan asserts the original auth still covers the
implementation. Acceptable, or does the model change warrant a
fresh User decision?

### Step 4-R — `hand20260515_010907`

R-HAND-1. **Plan-handoff alignment.** Implemented Decisions cite
D-001..D-008, R-PLAN3-2, R-PLAN3-5, and the (b) revision. Plan
Item Mapping covers P-B-1 / P-B-2 / P-C2. Does the implementation
match `plan20260515_010907`'s scope without scope creep?

R-HAND-2. **V-* evidence integrity.** Verification Performed
section embeds live command outputs (deploy summary 7/7 PASS,
unit grep, stat, getfacl, IOC start, post-start stat, engineer
touch). Are the captured outputs internally consistent with the
plan's expected values?

R-HAND-3. **R-PLAN3-2 + R-PLAN3-5 verbatim resolution.** Both
implementation-time refinements were carried as Step 3-R
conditions per `cmt20260514_235907`. Implementation-Time
Refinements section quotes the actual diagnostic strings.
Sufficient evidence?

R-HAND-4. **V-C2 Case 1 false-inference correction.** The prior
handoff (hand20260515_003138) claimed Case 1 PASS by inference
from POSIX semantics; live run produced 0640. The superseding
handoff captures the live re-run (0644 under the (b) plan) and
acknowledges the prior false inference in Supersession Reason.
Is the correction documented adequately, or should a self-
finding comment be added separately?

R-HAND-5. **V-B-2 carry-over.** V-B-2 (local mode) was verified
live in `hand20260515_003138` and is unchanged by the (b)
revision; this handoff re-cites the earlier evidence rather than
re-running. Acceptable carry-over, or does V-B-2 need a fresh
re-run as evidence?

R-HAND-6. **sudoers gate verification.** The sudoers gate is the
primary access boundary in the (b) model. The handoff records
the policy text emitted by STEP 3 (visudo validation in STEP 3
succeeded) and asserts a `sudo systemctl start` invocation as a
non-`ioc` user would be rejected. The negative probe was not
run live (would require creating a test user outside `ioc`). Is
the policy-text record sufficient evidence, or should a live
non-`ioc` user probe be added?

R-HAND-7. **Open-ended.** Anything else not captured above.

## Expected Response

Reviewer 1 publishes one of:

- `comments/cmt<ts>_codex_gpt5_to_claudecode_claude_opus_4_7_plan_and_handoff_ack.md`
  combining Step 0-R + Step 4-R accept in a single comment.
- `reviews/fup<ts>_codex_gpt5_on_plan20260515_010907.md` for
  plan-level findings (F-PLAN4-N).
- `reviews/fup<ts>_codex_gpt5_on_hand20260515_010907.md` for
  handoff-level findings (F-HAND-N).
- Two separate ack comments if Reviewer 1 prefers to keep Step
  0-R and Step 4-R distinct.

Any of the above forms is acceptable. The Facilitator will
proceed to Step 8 (User commit) only after Reviewer 1's
explicit accept on the final-form handoff (Step 7 recheck).

## Evidence Inputs

- `plan/plan20260515_010907_claudecode_claude_opus_4_7_supersedes_plan20260514_233353.md`
- `handoff/hand20260515_010907_claudecode_claude_opus_4_7_supersedes_hand20260515_003138.md`
- `plan/plan20260514_233353_claudecode_claude_opus_4_7_supersedes_plan20260514_231659.md`
  (superseded plan for delta comparison)
- `handoff/hand20260515_003138_claudecode_claude_opus_4_7.md`
  (superseded handoff for delta comparison and false-inference
  acknowledgement context)
- `bin/setup-system-infra.bash` and `bin/ioc-runner` in current
  working tree state.
- `docs/LOG_PERMISSIONS.md` (rewritten, current state).
- `docs/TEST_PLAN-1.1.0.md` (V-* wording updated).
- `cmt20260514_234412` (prior Step 0-R ack, covers shared inheritance).
- `cmt20260514_235907` (Step 3-R ack with R-PLAN3-2/3-5 conditions).
