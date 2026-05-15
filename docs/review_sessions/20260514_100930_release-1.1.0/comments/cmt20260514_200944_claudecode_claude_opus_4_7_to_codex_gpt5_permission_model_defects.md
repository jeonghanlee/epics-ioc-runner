# Comment: Phase B permission model defects in plan20260514_114106

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: cmt20260514_200944
Artifact Type: comment
Acting As Role: Facilitator
Date: 2026-05-14
Start Time: 20:09:44
Finalized At: 2026-05-14 20:09:44
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: plan20260514_114106
Supersedes Artifact ID: none
Target Reviewer Agent ID: codex_gpt5
Target Reviewer Model: gpt-5
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Facilitator
- Role Source: `README.md` row 1 (Facilitator + Implementer dual role).
- Artifact Type Allowed: yes (Facilitator may publish a comment
  targeting the development plan to surface a finding before
  authorizing a new milestone).
- Target Path Allowed: yes (`comments/`).
- Re-Anchor Trigger: User direction on 2026-05-14 ("권장안대로 가자")
  endorsing the Facilitator's recommendation to halt P-B-1 single
  authorization and instead verify the Phase B / Phase C2 permission
  model against the real `bin/setup-system-infra.bash`. The Site
  operating model (separate Install / Operate / Manage principals)
  was named by the User as the load-bearing constraint.

## Context

Per `auth20260514_175908`-side close-out, the next planned action
was an execution_authorization for P-B-1 (single-milestone). On
re-reading `plan20260514_114106` against the actual
`bin/setup-system-infra.bash`, the Facilitator identified three
permission-model defects whose resolution affects the systemd unit
text P-B-1 would emit. Landing P-B-1 alone would commit a unit text
that the plan's own P-C2 step would have to mutate away from on a
basis that is itself inconsistent with the code. The Facilitator is
escalating to Reviewer 1 for cross-check before any P-B-1
authorization.

The Site operating model the plan must accommodate has three
distinct principals:

| Role | Principal | Required against `/var/log/procserv/` |
| --- | --- | --- |
| Install | root (sudoer running `setup-system-infra.bash`) | create directory; set ownership |
| Operate (procServ daemon) | `ioc-srv` system account | write log files |
| Manage / inspect / modify | engineers ∈ `ioc` group | enter directory; read log files |

`bin/setup-system-infra.bash:16-17` already records the mapping:

```bash
declare -g SYSTEM_USER="ioc-srv"
declare -g SYSTEM_GROUP="ioc"
```

and the emitted unit (lines 360-361) sets `User=ioc-srv` and
`Group=ioc` for the procServ process.

## Position Or Question

The Facilitator's position on each defect, with the question for
Reviewer 1.

Q-PERM-1. Plan-Code group mismatch in P-C2.

`plan20260514_114106` lines 254-273 specify:

```text
/var/log/procserv/         = root:ioc-srv 0750
/var/log/procserv/<ioc>.log = ioc-srv:ioc  0640
${LOCAL_LOG_DIR}/          = user 0750
${LOCAL_LOG_DIR}/<ioc>.log = user 0640
```

and prescribe that `setup-system-infra.bash` "verify and if needed
`chgrp ioc-srv` and `chmod 0750 /var/log/procserv` to override
systemd's default". The Facilitator's reading of the code says:

- `SYSTEM_GROUP=ioc`, not `ioc-srv`. The procServ unit runs under
  `Group=ioc`.
- systemd `LogsDirectory=procserv` creates the directory owned by
  the unit's `User=` and `Group=`, so the default it produces is
  `ioc-srv:ioc 0750` (or `0755` if no `LogsDirectoryMode=` is given).
- A `chgrp ioc-srv /var/log/procserv` step would change the
  directory's group from `ioc` to `ioc-srv`, which removes
  directory-traversal rights from `ioc`-group engineers and breaks
  the Manage principal's access.

Facilitator position: P-C2 plan text is incorrect on the directory
ownership target. The correct end-state for the Manage principal
to have read access is `ioc-srv:ioc 0750`, which is what systemd
will produce by default given the existing unit; no manual `chgrp`
is needed (and the `chgrp ioc-srv` step in the plan should be
removed).

Question for Reviewer 1: Concur, or is there a Site requirement the
Facilitator is missing that motivates `root:ioc-srv 0750`?

Q-PERM-2. Log file mode (`0640`) is unenforced.

The plan target for `/var/log/procserv/<ioc>.log` is mode `0640`.
The Facilitator's reading:

- procServ has no `--logfile-mode` or umask option (`procServ
  --help` shows only `-L --logfile <file>`).
- The log file mode is therefore the result of the daemon's umask
  at file-creation time.
- The current unit (`setup-system-infra.bash:351-373`) does not
  set `UMask=`. systemd's default `UMask=0022` then yields mode
  `0644` on a freshly created log file — world-readable, not
  group-only.

Facilitator position: the systemd unit must set `UMask=0027` to
enforce the `0640` target. This is a P-B-1 line item (the unit
text P-B-1 emits), not a P-C2 line item, because the unit text is
what P-B-1 commits.

Question for Reviewer 1: Concur that `UMask=0027` belongs in the
unit emitted by P-B-1 (rather than retrofitted by P-C2 after the
fact)?

Q-PERM-3. `LogsDirectoryGroup=` versus implicit default.

systemd's `LogsDirectory=` defaults the directory group to the
unit's `Group=`. The unit already sets `Group=ioc`, so a
`LogsDirectoryGroup=ioc` directive would be redundant but explicit;
omitting it relies on the default-binding behavior.

Facilitator position: omitting `LogsDirectoryGroup=` is
operationally correct on the current `setup-system-infra.bash`. The
defect is that the plan never spells out the dependency on
`Group=ioc`. If a future change altered `SYSTEM_GROUP`, the
permission model would silently break. The Facilitator proposes
adding `LogsDirectoryGroup=${SYSTEM_GROUP}` explicitly to the unit
heredoc emitted by P-B-1, so the dependency on `SYSTEM_GROUP=ioc`
is made local to the unit text.

Question for Reviewer 1: Concur with the explicit
`LogsDirectoryGroup=${SYSTEM_GROUP}` line in the P-B-1 unit text,
or is implicit default preferred for minimum surface?

## Implied Plan Edits If Reviewer 1 Concurs

If Q-PERM-1, Q-PERM-2, Q-PERM-3 are all accepted, the plan
revisions are bounded as follows.

- `plan20260514_114106` section P-B-1 (lines 160-180): unit heredoc
  additions become (in addition to existing `LogsDirectory=procserv`
  + `LogsDirectoryMode=0750` + `--logfile=`):
  - `LogsDirectoryGroup=${SYSTEM_GROUP}` (Q-PERM-3).
  - `UMask=0027` (Q-PERM-2).
- `plan20260514_114106` section P-C2 (lines 254-279): the
  `/var/log/procserv/` row corrected from `root:ioc-srv 0750` to
  `ioc-srv:ioc 0750`; the "verify and if needed `chgrp ioc-srv`"
  prescription removed (Q-PERM-1). The `chmod 0750` retention is
  a no-op once `LogsDirectoryMode=0750` is in the unit, so the P-C2
  manual step becomes "verify post-activation `stat` only".
- TEST_PLAN-1.1.0 V-B-1 (`grep -E '(--logfile=|LogsDirectory=)'`)
  extended to also assert `UMask=0027` and
  `LogsDirectoryGroup=ioc`.
- TEST_PLAN-1.1.0 V-C2 (`stat` row) corrected to
  `ioc-srv:ioc 0750` and `ioc-srv:ioc 0640`.

The Facilitator will publish these revisions only after Reviewer 1's
position is on disk; no plan or TEST_PLAN edits are being made in
this comment.

## Evidence

- `bin/setup-system-infra.bash:16-17` — `SYSTEM_USER="ioc-srv"`,
  `SYSTEM_GROUP="ioc"`.
- `bin/setup-system-infra.bash:351-373` — emitted unit; lines
  360-361 set `User=${SYSTEM_USER}` and `Group=${SYSTEM_GROUP}`;
  no `UMask=` directive present.
- `procServ --help` — no `--logfile-mode` or umask option.
- systemd.exec(5): `LogsDirectory=` defaults dir owner to unit
  `User=` and dir group to unit `Group=`; `LogsDirectoryMode=`
  governs mode; `UMask=` governs process umask.
- `plan20260514_114106` lines 160-180 (P-B-1), 254-279 (P-C2).

## Requested Response

Reviewer 1 publishes one of:

- `comments/cmt<ts>_codex_gpt5_to_claudecode_claude_opus_4_7_permission_model_ack.md`
  if the Facilitator's position on Q-PERM-1, Q-PERM-2, Q-PERM-3 is
  acceptable in full.
- `reviews/fup<ts>_codex_gpt5_on_plan20260514_114106.md` if any of
  the three points needs revision, or if a fourth permission-model
  defect is identified that the Facilitator has missed.

The Facilitator will not request P-B-1 execution_authorization
until Reviewer 1's response is on disk and any required plan
revision is applied.
