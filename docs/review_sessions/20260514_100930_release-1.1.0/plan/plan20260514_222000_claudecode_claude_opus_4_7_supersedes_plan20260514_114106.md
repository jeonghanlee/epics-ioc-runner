# Development Plan (Supersedes): Phase B/C2 permission model corrections

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: plan20260514_222000
Artifact Type: development_plan
Acting As Role: Implementer
Date: 2026-05-14
Start Time: 22:20:00
Finalized At: 2026-05-14 22:20:00
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: conv20260514_112923
Supersedes Artifact ID: plan20260514_114106
Implementer Agent ID: claudecode_claude_opus_4_7
Implementer Model: claude-opus-4-7
Based On Artifact ID: conv20260514_112923
Based On: `convergence/conv20260514_112923_claudecode_claude_opus_4_7.md`
Revision Inputs:
  - `comments/cmt20260514_200944_claudecode_claude_opus_4_7_to_codex_gpt5_permission_model_defects.md`
  - `reviews/fup20260514_201306_codex_gpt5_on_plan20260514_114106.md`
  - `comments/cmt20260514_221507_claudecode_claude_opus_4_7_to_codex_gpt5_permission_model_ack.md`
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`, `doc-pipelines`, `git-workflow`, `bash-coding`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Implementer
- Role Source: `README.md` row 1 (Facilitator + Implementer dual role).
- Artifact Type Allowed: yes (only Implementer may publish
  development_plan, including a superseding development_plan).
- Target Path Allowed: yes (`plan/`).
- Re-Anchor Trigger: Reviewer 1 follow-up fup20260514_201306 accepted in
  full per cmt20260514_221507; plan revision is the response action.

## Inheritance

This artifact is a delta-style superseding development_plan. Every
section of `plan20260514_114106_claudecode_claude_opus_4_7.md` is
inherited unchanged **except** the four blocks explicitly named under
"Revised Sections" below. Readers should consult the prior plan for
all unaffected sections (Objective, In Scope, Out Of Scope, Plan Item
Matrix excluding the verification text columns named below, all P-A,
P-Readiness, P-B-2, P-B-3, P-C1, P-D-1, P-D-2, P-D+, P-E, P-F-1,
P-F-2, P-F-3, P-G sections, ADR Promotion Plan, Recovery Boundary,
User Decisions Needed Before Execution).

## Supersession Reason

Reviewer 1 (codex_gpt5) follow-up `fup20260514_201306` identified two
defects in the prior plan against the actual repository state:

- P-C2 directory ownership target was inconsistent with
  `SYSTEM_GROUP=ioc` in `bin/setup-system-infra.bash:17` and would
  break the Manage principal's directory traversal (Q-PERM-1).
- P-B-1 emitted unit text did not include `UMask=0027`, so the
  procServ-created log file would not satisfy the stated `0640`
  target under the default system unit umask of `0022` (Q-PERM-2).

Reviewer 1 also revised the Facilitator's proposed Q-PERM-3 fix:
`LogsDirectoryGroup=` is not present in local Debian 13 systemd 257
`systemd.exec(5)`, so the directory-group dependency on `Group=`
must be expressed in plan text rather than as a unit directive.

The Facilitator independently re-ran the manpage check (`man
systemd.exec` plus `grep -nE 'DirectoryGroup|DirectoryOwner|DirectoryUser'`
returning no match) and accepted the revision in
`cmt20260514_221507`. This plan applies the three accepted revisions.

## Revised Sections

### Revised — Plan Item Matrix verification column for P-B-1 and P-C2

The Plan Item Matrix (`plan20260514_114106` lines 79-97) keeps its
shape. Two cells in the Verification column gain a sub-spec:

- P-B-1 Verification: V-B-1 expanded to include
  `Group=${SYSTEM_GROUP}`, `LogsDirectoryMode=0750`, `UMask=0027`, and
  `--logfile=/var/log/procserv/%i.log` assertions.
- P-C2 Verification: V-C2 expanded to assert post-activation
  filesystem state `ioc-srv:ioc 0750` on the directory and
  `ioc-srv:ioc 0640` on each `<ioc>.log` file.

### Revised — P-B-1. `setup-system-infra.bash` — system systemd template

Replaces `plan20260514_114106` lines 160-180.

Purpose:

Update the system systemd template emitted to
`/etc/systemd/system/epics-@.service` to direct procServ output to a
dedicated log file and to enforce a group-only log file mode at file
creation time.

Changes:

- Modify the heredoc producing the system template:
  - Add `LogsDirectory=procserv` and `LogsDirectoryMode=0750`. Directory
    ownership defaults to `User=${SYSTEM_USER}` and
    `Group=${SYSTEM_GROUP}` (yielding `ioc-srv:ioc` under current
    values), as documented in local `systemd.exec(5)`. No
    `LogsDirectoryGroup=` directive is added — that directive does not
    exist in Debian 13 systemd 257.
  - Add `UMask=0027` to enforce `0640` on log files created by procServ.
    Without `UMask=`, system units default to `0022`, yielding `0644`,
    which does not satisfy the Manage-principal-only read target.
  - Replace existing `ExecStart=` to append
    `--logfile=/var/log/procserv/%i.log` before `--name=%i`.
  - Keep `StandardError=inherit`. `StandardOutput=` remains as currently
    set (`syslog` in the existing unit); the log file becomes the
    primary on-disk store, so the `StandardOutput=` channel choice does
    not affect operator workflows.

Dependencies the unit relies on (must remain true for the permission
model to hold):

- `bin/setup-system-infra.bash:16-17` continues to define
  `SYSTEM_USER="ioc-srv"` and `SYSTEM_GROUP="ioc"`.
- `bin/setup-system-infra.bash:360-361` continues to emit
  `User=${SYSTEM_USER}` and `Group=${SYSTEM_GROUP}` into the unit.

Verification:

- V-B-1: `systemctl cat epics-@<name>.service` shows the new directives.
  Asserted via:
  - `grep -E '^Group=' /etc/systemd/system/epics-@.service` returns
    `Group=ioc`.
  - `grep -E '^LogsDirectory=' ...` returns `LogsDirectory=procserv`.
  - `grep -E '^LogsDirectoryMode=' ...` returns `LogsDirectoryMode=0750`.
  - `grep -E '^UMask=' ...` returns `UMask=0027`.
  - `grep -E '^ExecStart=' ...` contains
    `--logfile=/var/log/procserv/%i.log`.
- TEST_PLAN-1.1.0.md V-B-1 verification command is updated to match,
  landing in the same P-B-1 implementation commit.

### Revised — P-C2. `setup-system-infra.bash` and `bin/ioc-runner` — permission model

Replaces `plan20260514_114106` lines 254-279.

Purpose:

Enforce and verify the log file permission model the unit has already
set up. P-B-1 directives produce the correct end-state by default;
P-C2 verifies it rather than overriding it.

End-state targets:

- `/var/log/procserv/` = `ioc-srv:ioc 0750`. Created by systemd via
  `LogsDirectory=procserv` + `LogsDirectoryMode=0750` against unit
  `User=${SYSTEM_USER}`, `Group=${SYSTEM_GROUP}`.
- `/var/log/procserv/<ioc>.log` = `ioc-srv:ioc 0640`. Created by
  procServ under unit umask `0027`.
- `${LOCAL_LOG_DIR}/` = `<user>:<user> 0750`. Created by
  `install -d -m 0750 "${LOCAL_LOG_DIR}"` in `do_install` local branch.
- `${LOCAL_LOG_DIR}/<ioc>.log` = `<user>:<user> 0640`. Created by
  procServ in local mode; local mode equivalent umask handling is
  addressed under P-B-2 (see below).

Changes:

- `setup-system-infra.bash`: no additional `chgrp` or `chmod` against
  `/var/log/procserv` is performed. The unit directives created in
  P-B-1 are the single source of truth for system-mode directory
  ownership and mode. Any earlier "verify and if needed `chgrp
  ioc-srv`" prescription is **removed**.
- `bin/ioc-runner` `do_install` local branch:
  `install -d -m 0750 "${LOCAL_LOG_DIR}"` is added per the prior plan
  (P-C2 still owns this line; not affected by Reviewer 1 revisions).

P-B-2 dependency note:

- Local-mode log file `0640` requires the local user systemd template
  emitted by `deploy_local_template` to also carry `UMask=0027`.
  `plan20260514_114106` P-B-2 (lines 182-204) currently specifies only
  `--logfile=` insertion. The Implementer will carry the same
  `UMask=0027` line into the local-mode heredoc inside P-B-2 to keep
  the system and local file modes aligned.

Verification:

- V-C2: post-activation `stat` asserts the end-state above on `top`
  (system mode) and on `top` (local mode). Specifically:
  - `stat -c '%U:%G %a' /var/log/procserv` returns `ioc-srv:ioc 750`.
  - `stat -c '%U:%G %a' /var/log/procserv/<ioc>.log` returns
    `ioc-srv:ioc 640`.
  - Local-mode `stat -c '%U:%G %a' ${LOCAL_LOG_DIR}` returns
    `<user>:<user> 750`.
  - Local-mode `stat -c '%U:%G %a' ${LOCAL_LOG_DIR}/<ioc>.log` returns
    `<user>:<user> 640`.
- `cat <log>` succeeds for a user in the `ioc` group, fails for a user
  outside both `ioc` and `ioc-srv`. No `systemd-journal` group
  membership is required.
- TEST_PLAN-1.1.0.md V-C2 wording is updated to match in the same
  TEST_PLAN edit that lands with P-B-1 (so V-B-1 and V-C2 ship
  together).

### Revised — P-B-2 dependency carry-over

`plan20260514_114106` P-B-2 (lines 182-204) is unchanged in its file
list and `do_install` `install -d` step, but the heredoc edit acquires
one new line:

- `bin/ioc-runner` `deploy_local_template`: heredoc additionally
  emits `UMask=0027` in the `[Service]` block.

This keeps the local-mode log file mode aligned with the system-mode
target (`0640`) and avoids a second-class permission model for
`--local`. V-B-2 verification gains a `grep -E '^UMask=' ~/.config/systemd/user/epics-@.service`
assertion equivalent to V-B-1's.

## Plan Item Matrix Delta

Only the cells listed below differ from `plan20260514_114106`.

| Plan ID | Source Decisions | Issues | Files | Verification | State |
| --- | --- | --- | --- | --- | --- |
| P-B-1 | D-001..D-008 | #9 | `setup-system-infra.bash` (system systemd template emission, including `UMask=0027`); `docs/TEST_PLAN-1.1.0.md` (V-B-1 wording update) | V-B-1 (expanded — see Revised P-B-1) | planned |
| P-B-2 | D-001..D-008 | #10 | `bin/ioc-runner` `deploy_local_template` (heredoc, including `UMask=0027`) and `do_install` local branch | V-B-2 (expanded — `UMask=` assertion added) | planned |
| P-C2 | D-001, D-006, D-007 | #12 | `setup-system-infra.bash` (verification only — no override of unit-created dir), `bin/ioc-runner` `do_install` local mkdir mode, `docs/TEST_PLAN-1.1.0.md` (V-C2 wording update) | V-C2 (expanded — see Revised P-C2) | planned |

All other rows of the Plan Item Matrix remain as in
`plan20260514_114106`.

## Test Plan Carry-Over

`docs/TEST_PLAN-1.1.0.md` is a checked-in artifact (committed in
`a3acc80` as part of P-Readiness). The V-B-1 and V-C2 wording updates
described above land in the same commit as the corresponding
implementation phase (P-B-1 for V-B-1; P-C2 for V-C2 — typically the
two are landed together since the combined authorization is the
recommended path forward), not as a standalone TEST_PLAN-only commit.

## Authorization Scope This Plan Asks For

The Facilitator will request execution_authorization for a combined
**P-B-1 + P-B-2 + P-C2** scope rather than P-B-1 alone, because:

- The `UMask=0027` discipline now applies to both the system unit
  (P-B-1) and the local-user unit (P-B-2). Splitting the two would
  ship an intermediate state where `--local` log files default to
  `0644`.
- P-C2 verification (`stat` assertions) is only meaningful after the
  unit is installed and an IOC has started under it, i.e. after P-B-1
  emits the unit and an IOC writes the first log file. Combining
  P-B-1 + P-C2 lets a single cross-check round verify both the
  emitted unit text and the realized filesystem state.

P-B-3 (logrotate, #15) is **not** folded into this combined scope —
its verification surface is independent (logrotate dry-run + rotation
behavior) and Phase B's cross-check policy YES applies cleanly to a
separate cross-check round for P-B-3.

## User Decision Needed Before Execution

- UD-PERM. Approve revised plan plan20260514_222000 and authorize
  combined P-B-1 + P-B-2 + P-C2 scope. The Facilitator will publish
  the corresponding execution_authorization once approved.

## Recovery Boundary

If P-B-1 + P-B-2 + P-C2 execution fails verification on `top`, revert
is by `git revert` of the single combined commit (no partial
landings). The system unit is regenerated on the next
`setup-system-infra.bash` run; the user unit is regenerated on the
next `ioc-runner --local install` (with the `deploy_local_template`
function only emitting when the template is missing — manual delete
of `~/.config/systemd/user/epics-@.service` may be required as part
of revert if a regression is observed against the new template).
