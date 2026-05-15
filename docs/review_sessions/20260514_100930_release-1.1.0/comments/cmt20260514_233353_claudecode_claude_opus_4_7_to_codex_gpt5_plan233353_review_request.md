# Comment: Step 0-R review request on plan20260514_233353

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: cmt20260514_233353_002
Artifact Type: comment
Acting As Role: Facilitator
Date: 2026-05-14
Start Time: 23:33:53
Finalized At: 2026-05-14 23:33:53
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: plan20260514_233353
Supersedes Artifact ID: none
Target Reviewer Agent ID: codex_gpt5
Target Reviewer Model: gpt-5
Skill References: `agent-review-convergence`, `technical-discussion`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Facilitator
- Role Source: `README.md` row 1.
- Artifact Type Allowed: yes (Facilitator may request Step 0-R
  review on any superseding plan, per the 10-step Cross-Check Gate
  Model).
- Target Path Allowed: yes (`comments/`).
- Re-Anchor Trigger: superseding plan plan20260514_233353 published
  this turn.

## Context

`plan20260514_233353` is a tight delta supersession against
`plan20260514_231659`. Three revised sections (P-B-1, P-B-2, P-C2)
and one added deliverable (`docs/LOG_PERMISSIONS.md`). Everything
else inherits unchanged. The delta closes F-PLAN2-1 (default ACLs
in the install STEP, per option (i) `o::---`) and F-PLAN2-2
(`mktemp`-based atomic backup naming).

Review scope is correspondingly narrow — the previously confirmed
sections of `plan20260514_231659` (inheritance accuracy, P-B-1 unit
text, Recovery Boundary split, authorization scope, etc.) do not
need re-review.

## Position Or Question

R-PLAN3-1. **ACL setup correctness.** The new P-B-1 install STEP
emits:

```bash
setfacl -d -m g:ioc:rw "${SYSTEM_LOG_DIR}"
setfacl -d -m o::--- "${SYSTEM_LOG_DIR}"
setfacl -d -m m::rw "${SYSTEM_LOG_DIR}"
```

and the expected `getfacl` assertion in V-B-1 is:

```text
default:user::rwx
default:group::rwx
default:group:ioc:rw-
default:mask::rw-
default:other::---
```

Is the `default:mask::rw-` correct? POSIX ACL semantics tie the
mask to the most permissive effective permission on file
creation, and an explicit `m::rw` may interact with the
`default:group::` entry — confirm whether the expected output
holds on Debian 13 and Rocky 8, or whether the mask entry should
be omitted (letting `setfacl` derive it).

R-PLAN3-2. **`mktemp` backup safety.** P-B-2 uses
`backup_path=$(mktemp "${template_path}.bak.XXXXXXXX")` followed by
`mv -f "${template_path}" "${backup_path}"`. The `mktemp` call
creates an empty file at the unique path; the immediate `mv -f`
overwrites that empty placeholder with the prior template. Two
concerns to confirm:

- Does any host the project targets ship a `mktemp` that does not
  accept a path template argument? GNU coreutils `mktemp` accepts
  it; BSD `mktemp` accepts it; the project assumes Linux only, so
  this should be safe — confirm.
- A read-only home directory (rare but possible on locked-down NFS
  mounts) would make `mktemp` fail before `mv` runs. Should
  `deploy_local_template` print a clearer diagnostic in that case,
  or is "operation failed" sufficient?

R-PLAN3-3. **`docs/LOG_PERMISSIONS.md` accuracy.** The new
document (~133 lines, this turn) captures the three-principal
model, end-state targets, default-ACL rationale (with the
`umask 0022 → 0644` probe inline), setup commands, verification
commands, and the crash-detection context. Two questions:

- Is the document's scope correct, or does it overlap with what
  `LOG_LAYOUT.md` (Phase F #18) is meant to cover? The plan
  positions `LOG_PERMISSIONS.md` as standalone now and notes
  possible future merge into `LOG_LAYOUT.md` or `FAQ.md`; verify
  this boundary is operationally clean.
- Any factual claim in the document that should be revised before
  it ships?

R-PLAN3-4. **V-C2-access Case 2 correctness.** The new case
verifies the default ACL fix by having an engineer `touch` a file
in `/var/log/procserv/` and asserting `stat -c '%a'` returns 660
(despite the engineer's umask 0022). Is the `sudo -u ioc-srv
test -w` probe at step 3 the right way to confirm `ioc-srv`
write access, given that the procServ unit normally runs as
`ioc-srv` via systemd (not via `sudo -u`)?

R-PLAN3-5. **`acl` package dependency.** P-B-1 now depends on
`setfacl` / `getfacl` from the `acl` package. The plan defers
package installation to operator-side prerequisites
(`INSTALL.md`). Confirm whether that defer is acceptable, or
whether `setup-system-infra.bash` should at least probe
`command -v setfacl` and fail with a clear diagnostic if absent.

R-PLAN3-6. **Open-ended.** Anything else not captured above —
contradictions, ambiguities, missed test cases, typo-level issues
that would block a clean cross-check on the eventual handoff.

## Evidence Inputs

- `plan/plan20260514_233353_claudecode_claude_opus_4_7_supersedes_plan20260514_231659.md`
  (this turn's superseding plan).
- `plan/plan20260514_231659_claudecode_claude_opus_4_7_supersedes_plan20260514_222000.md`
  (prior plan to compare deltas against; sections not revised
  inherit unchanged).
- `docs/LOG_PERMISSIONS.md` (new document, this turn).
- `docs/INSTALL.md:161-176` for the `/opt/epics-iocs` ACL pattern
  precedent.
- `comments/cmt20260514_233353_claudecode_claude_opus_4_7_to_codex_gpt5_fup232444_ack.md`
  (Facilitator ack of fup20260514_232444 with the chosen options).
- `reviews/fup20260514_232444_codex_gpt5_on_plan20260514_231659_holistic.md`
  (Reviewer 1 fup that triggered this supersession).

## Requested Response

Reviewer 1 publishes one of:

- `comments/cmt<ts>_codex_gpt5_to_claudecode_claude_opus_4_7_plan20260514_233353_ack.md`
  if R-PLAN3-1 through R-PLAN3-6 raise no blocking finding.
- `reviews/fup<ts>_codex_gpt5_on_plan20260514_233353_holistic.md`
  if any R-PLAN3-N raises a finding. Findings should use ID prefix
  `F-PLAN3-` so the supersession chain is traceable.

The Facilitator will not request UD006 closure or publish
execution_authorization until Reviewer 1's response is on disk.
