# Comment: Ack on fup20260514_232444 — F-PLAN2-1 and F-PLAN2-2 accepted

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: cmt20260514_233353
Artifact Type: comment
Acting As Role: Facilitator
Date: 2026-05-14
Start Time: 23:33:53
Finalized At: 2026-05-14 23:33:53
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: fup20260514_232444
Supersedes Artifact ID: none
Target Reviewer Agent ID: codex_gpt5
Target Reviewer Model: gpt-5
Skill References: `agent-review-convergence`, `technical-discussion`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Facilitator
- Role Source: `README.md` row 1.
- Artifact Type Allowed: yes (Facilitator may ack a Reviewer follow-up
  before publishing the corrective superseding plan).
- Target Path Allowed: yes (`comments/`).
- Re-Anchor Trigger: review_followup fup20260514_232444 by codex_gpt5
  on plan20260514_231659; User direction 2026-05-14 selecting
  option (i) for the F-PLAN2-1 fix and authorizing the permission
  model to be captured in a standalone document.

## Acceptances

F-PLAN2-1 (setgid alone does not satisfy the creation-order rw
invariant): accepted. Facilitator independently reproduced the
finding:

```text
$ tmpdir=$(mktemp -d); chmod 2770 "$tmpdir"
$ (umask 0022; touch "$tmpdir/engineer-created.log")
$ stat -c '%a' "$tmpdir/engineer-created.log"
644
$ (umask 0007; touch "$tmpdir/procserv-style.log")
$ stat -c '%a' "$tmpdir/procserv-style.log"
660
```

Fix path adopted: option (β) from the Reviewer's fup — default ACLs
on the log directory, modeled on the existing Site pattern in
`docs/INSTALL.md:171-172` for `/opt/epics-iocs`. Per User direction
"i로 가고", the `other` default ACL entry is tightened to `o::---`
(logs remain private to the `ioc` group), differing from
`/opt/epics-iocs` which uses `o::rx` for the code tree.

Concrete setup ACLs (will appear in the superseding plan's revised
P-B-1 install STEP):

```bash
install -d -o root -g ioc -m 2770 "${SYSTEM_LOG_DIR}"
setfacl -d -m g:ioc:rw "${SYSTEM_LOG_DIR}"
setfacl -d -m o::--- "${SYSTEM_LOG_DIR}"
setfacl -d -m m::rw "${SYSTEM_LOG_DIR}"
```

The systemd unit retains `UMask=0007` for the procServ-creates-log
normal case. Default ACLs cover the exceptional case (engineer or
external process creates a file in the directory).

F-PLAN2-2 (local user-template backup name can collide): accepted.
Backup naming adopted: `mktemp` against a stable prefix, atomic
unique-name creation. Implementation sketch for the superseding
plan's revised P-B-2:

```bash
local backup_path
backup_path=$(mktemp "${template_path}.bak.XXXXXXXX")
mv -f "${template_path}" "${backup_path}"
```

`mktemp` creates an empty unique file atomically; the immediate
`mv -f` swaps in the prior template. No second-resolution
timestamp; no NFS concurrency window.

## Captured Decisions Doc

The permission model decisions (three-principal model, end-state
targets for system and local modes, default ACL rationale, the
verification commands, and the 1.1.0 crash-detection context) have
been captured in a new standalone document:

- `docs/LOG_PERMISSIONS.md` (133 lines).

This file is the durable record of the permission model arrived at
through fup20260514_201306, fup20260514_225309, fup20260514_232444,
and the User direction interleaved with each round. The forthcoming
superseding plan references this document as a deliverable that
lands with the P-B-1 + P-B-2 + P-C2 implementation commit. Possible
future consolidation paths (merge into `LOG_LAYOUT.md` at Phase F #18
or into `FAQ.md` Q8/Q9) are noted in the doc itself.

## Procedural Note

No new memory entries created in response to this session. The
project memory layer was flagged for bloat; new feedback signals
from this session are not auto-saved without explicit User direction.

## Requested Response

No response required to this ack. The Facilitator's next artifact
will be the superseding development_plan that applies F-PLAN2-1 and
F-PLAN2-2 fixes and lists `docs/LOG_PERMISSIONS.md` as part of the
P-B-1 + P-B-2 + P-C2 deliverable set; Reviewer 1 enters that plan
through the Step 0-R gate.
