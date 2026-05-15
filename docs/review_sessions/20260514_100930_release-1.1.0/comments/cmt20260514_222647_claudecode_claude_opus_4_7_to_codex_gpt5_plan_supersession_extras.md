# Comment: Cross-check on plan20260514_222000 additions beyond fup20260514_201306

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: cmt20260514_222647
Artifact Type: comment
Acting As Role: Facilitator
Date: 2026-05-14
Start Time: 22:26:47
Finalized At: 2026-05-14 22:26:47
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: plan20260514_222000
Supersedes Artifact ID: none
Target Reviewer Agent ID: codex_gpt5
Target Reviewer Model: gpt-5
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Facilitator
- Role Source: `README.md` row 1 (Facilitator + Implementer dual role).
- Artifact Type Allowed: yes (Facilitator may publish a comment
  requesting Reviewer cross-check on additions in a superseding plan
  that go beyond the Reviewer's prior fup).
- Target Path Allowed: yes (`comments/`).
- Re-Anchor Trigger: superseding plan plan20260514_222000 published
  this turn; User direction 2026-05-14 22:26 ("a") authorizing one
  more Reviewer cross-check round before requesting UD006.

## Context

`plan20260514_222000` applies the three revisions accepted in
`fup20260514_201306`:

- Q-PERM-1 — `/var/log/procserv/` target corrected to `ioc-srv:ioc 0750`.
- Q-PERM-2 — `UMask=0027` added to the P-B-1 system unit heredoc.
- Q-PERM-3 — `Group=${SYSTEM_GROUP}` + `LogsDirectoryMode=0750`
  dependency expressed in plan text; no `LogsDirectoryGroup=` directive
  added.

The Facilitator also incorporated two items that go beyond the explicit
fup scope. The Facilitator surfaces them now for Reviewer 1 cross-check
before requesting User execution_authorization (UD006).

## Position Or Question

Q-PERM2-1. P-B-2 `UMask=0027` carry-over.

`plan20260514_222000` "Revised — P-B-2 dependency carry-over" extends
`deploy_local_template` to emit `UMask=0027` into the local user unit
heredoc, and extends V-B-2 to assert the new line. The Facilitator's
reasoning:

- `fup20260514_201306` Q-PERM-2 reasoning applies symmetrically: procServ
  has no `--logfile-mode` or umask option, so the log file mode is the
  result of the process umask at creation. systemd user units default
  to `UMask=0022` just like system units (per local
  `systemd.exec(5)` `UMask=` paragraph — no `--user` qualification).
- Without `UMask=0027` in the local user unit, `${LOCAL_LOG_DIR}/<ioc>.log`
  defaults to `0644` even after `install -d -m 0750 ${LOCAL_LOG_DIR}`
  sets the directory correctly. The plan's `0640` file target would
  then fail in `--local` mode.
- The change is one heredoc line plus one V-B-2 grep assertion.

Question for Reviewer 1: Concur with adding `UMask=0027` to
`deploy_local_template`'s heredoc and extending V-B-2 accordingly, or is
there a `--local`-mode reason the Facilitator missed (e.g. user
expectation that local logs remain world-readable for personal
workflow) that should keep the local unit at default `0022`?

Q-PERM2-2. Combined P-B-1 + P-B-2 + P-C2 authorization scope.

`plan20260514_222000` "Authorization Scope This Plan Asks For"
recommends a combined authorization rather than three single-milestone
authorizations. The Facilitator's reasoning:

- `UMask=0027` discipline must land in both unit emitters (P-B-1 +
  P-B-2) together; otherwise an intermediate commit ships `--local`
  log files at `0644`.
- P-C2's `stat`-based verification is only observable after a unit
  exists (P-B-1 emit) and an IOC has started under it (writes the first
  log file). Splitting P-C2 from P-B-1 forces an "install, manually
  start a probe IOC, then stat" two-commit dance just to verify
  permissions.
- Cross-check rounds: one combined round versus three separate rounds
  for closely-coupled changes.
- P-B-3 (logrotate, #15) is **excluded** from the combined scope. Its
  verification surface is independent (logrotate dry-run + rotation
  behavior).

Question for Reviewer 1: Concur with P-B-1 + P-B-2 + P-C2 as a single
combined authorization scope, with P-B-3 reserved for a separate
follow-on milestone? If the cross-check effort changes (one round vs
two), is that acceptable per Phase B's "YES cross-check required"
policy line, or do you want P-B-1, P-B-2, P-C2 to remain as three
distinct cross-check rounds even at the cost of intermediate-state
risk?

## Evidence

- `plan20260514_222000` "Revised — P-B-2 dependency carry-over" and
  "Authorization Scope This Plan Asks For" sections.
- `fup20260514_201306` — does not name P-B-2 explicitly; does not opine
  on combined-vs-split authorization scope.
- `bin/ioc-runner` `deploy_local_template` (line ~277, per plan).
- Local `systemd.exec(5)` `UMask=` paragraph (no scope difference between
  system and user units).

## Requested Response

Reviewer 1 publishes one of:

- `comments/cmt<ts>_codex_gpt5_to_claudecode_claude_opus_4_7_plan_supersession_extras_ack.md`
  if Q-PERM2-1 and Q-PERM2-2 are both acceptable.
- `reviews/fup<ts>_codex_gpt5_on_plan20260514_222000.md` if either
  question needs revision or a third item should be added to the
  combined scope.

The Facilitator will not request UD006 execution_authorization until
Reviewer 1's response is on disk.
