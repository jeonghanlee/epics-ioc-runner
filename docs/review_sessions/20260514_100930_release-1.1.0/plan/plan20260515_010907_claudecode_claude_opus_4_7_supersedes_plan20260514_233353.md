# Development Plan (Supersedes): Accept procServ open(0644) + sudoers-as-access-boundary

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: plan20260515_010907
Artifact Type: development_plan
Acting As Role: Implementer
Date: 2026-05-15
Start Time: 01:09:07
Finalized At: 2026-05-15 01:09:07
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: conv20260514_112923
Supersedes Artifact ID: plan20260514_233353
Implementer Agent ID: claudecode_claude_opus_4_7
Implementer Model: claude-opus-4-7
Based On Artifact ID: conv20260514_112923
Based On: `convergence/conv20260514_112923_claudecode_claude_opus_4_7.md`
Revision Inputs:
  - In-implementation discovery (Step 4 verification round 1): procServ `open(O_CREAT, 0644)` verified by `umask 0` probe → mode_arg = `0644` (hardcoded upstream)
  - User direction 2026-05-15 ("B로 가자") authorizing the access-model revision
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`, `doc-pipelines`, `bash-coding`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Implementer
- Role Source: `README.md` row 1 (Facilitator + Implementer dual role).
- Artifact Type Allowed: yes (only Implementer publishes
  development_plan, including a superseding development_plan).
- Target Path Allowed: yes (`plan/`).
- Re-Anchor Trigger: in-implementation discovery that
  `plan20260514_233353`'s "three principals all `rw`" invariant is
  not achievable without upstream procServ patch or systemd
  workarounds; User direction "B로 가자" 2026-05-15 chose the
  alternative access model.

## Inheritance (explicit)

This is a delta-style superseding development_plan against
`plan20260514_233353`. Two localized revisions only.

**Inherited unchanged from plan20260514_233353:**

- Header up to `## Inheritance`.
- `bin/setup-system-infra.bash` Phase A baseline reference (`SYSTEM_LOG_DIR` parity).
- `bin/setup-system-infra.bash` STEP 4 install-time directory creation:
  `install -d -o root -g ioc -m 2770 ${SYSTEM_LOG_DIR}` plus
  `verify_path` plus `setfacl -d -m g:ioc:rw` plus `setfacl -d -m m::rw`.
- `bin/setup-system-infra.bash` `setfacl`/`getfacl` preflight (R-PLAN3-5).
- `bin/ioc-runner` `deploy_local_template` always-overwrite + `mktemp`
  atomic backup + read-only home diagnostic (R-PLAN3-2) +
  local-mode `UMask=0027` in heredoc + `--logfile=${LOCAL_LOG_DIR}/%i.log`.
- `bin/ioc-runner` `do_install` local branch `install -d -m 0750`.
- All Plan Item Matrix rows for `P-A`, `P-Readiness`, `P-B-3`,
  `P-C1`, `P-D-1`, `P-D-2`, `P-D+`, `P-E`, `P-F-1`, `P-F-2`, `P-F-3`,
  `P-G`.
- `docs/LOG_PERMISSIONS.md` as a P-B-1 deliverable (rewritten this
  turn to reflect the new model).
- Authorization Scope (combined P-B-1 + P-B-2 + P-C2; P-B-3 separate).
- Recovery Boundary (pre-commit / post-commit split).

**Revised in this artifact (sections below):**

- `## Permission Model` (system mode: target mode revised from
  `0660` to `0644`; access boundary clarified as sudoers + file
  mode dual-layer).
- `### Revised — P-B-1` unit text (`UMask=0007` line removed from
  heredoc).
- `### Revised — P-B-1` install STEP `setfacl` (`o::---` → `o::r--`).
- V-B-1 and V-C2 wording updates in `docs/TEST_PLAN-1.1.0.md`
  (already applied in working tree).

**Unchanged within revised sections:**

- P-B-2 (local mode) is entirely unchanged. Local mode is
  single-principal; `UMask=0027` + `0640` target stays as in
  `plan20260514_233353`.

## Supersession Reason

`plan20260514_233353` specified system log file target
`ioc-srv:ioc 0660` based on the "three principals all `rw`"
invariant. During Step 4 implementation verification (V-C2 Case 1
runtime check after Step 4-R-blocking inference), the live IOC
start produced `ioc-srv:ioc 0640`, not `0660`. Root cause analysis:

- procServ uses `open(O_CREAT, 0644)` for the log file
  (hardcoded upstream; verified by `umask 0` standalone probe
  yielding mode `0644`).
- POSIX ACL inheritance: when default ACL is present, the access
  ACL's mask entry = (default mask) AND (mode_arg's group bits).
  procServ's `0644` group bits are `r--`, so the access mask
  becomes `r--` regardless of how permissive the default mask is
  set.
- Effective group permission = (group ACL entry) AND (mask) =
  `rw-` AND `r--` = `r--`. Group write is not achievable.

Three corrective paths were considered (recorded in chat
discussion):

- (I) Accept the natural `0640` mode + sudoers as access boundary.
- (II') Pre-create the log file via `ExecStartPre` so procServ's
  later `open(O_CREAT)` finds an existing file and preserves
  the pre-set mode.
- (III) procServ wrapper script.
- (IV) Upstream procServ patch.

The User chose option (b) — closely related to (I) but with
slightly relaxed `other` access. Concretely:

- Accept procServ's natural `0644` mode (no `UMask=` directive in
  the system unit).
- Default ACL on the log directory becomes `g:ioc:rw`, `o::r--`,
  `m::rw` (the `o::---` of `plan20260514_233353` is widened to
  `o::r--`).
- Access boundary for `ioc-runner` system-mode operations is
  enforced by the sudoers policy (`%ioc` group), not by file mode
  alone.
- The file-mode layer is defense-in-depth: ioc group can read
  (group bit), other can read (other bit) — `ioc-runner` use is
  still gated to ioc group via sudo.

The User direction, verbatim, captured for audit:

> B로 가자

(referring to option (b) presented in chat: "0644 + sudoers
boundary + default ACL `o::r--`").

## Permission Model (revised)

End-state targets (system mode):

| Object | Owner:Group | Mode | Default ACL | Creator |
| --- | --- | --- | --- | --- |
| `${SYSTEM_LOG_DIR}/` | `root:ioc` | `2770` (setgid) | `g:ioc:rw`, `o::r--`, `m::rw` | `setup-system-infra.bash` install-time |
| `${SYSTEM_LOG_DIR}/<ioc>.log` (procServ) | `ioc-srv:ioc` | `0644` | (inherited; mask `r--` because procServ mode_arg `0644` has group `r--`) | procServ at IOC start |
| `${SYSTEM_LOG_DIR}/<adhoc>` (engineer touch) | `<engineer>:ioc` | `0664` | (inherited; mask `rw-` because touch mode_arg `0666` has group `rw-`) | engineer's shell `touch` |

End-state targets (local mode): unchanged. `<user>:<user> 0750`
directory + `<user>:<user> 0640` file with user-unit `UMask=0027`.

Access boundary, layered:

| Layer | Mechanism | Restricts |
| --- | --- | --- |
| 1 (primary) | `/etc/sudoers.d/10-epics-ioc` | `ioc-runner` system-mode start/stop/restart/status/enable/disable + `daemon-reload`. Only `%ioc` group can invoke. |
| 2 (defense-in-depth) | Log file mode + default ACLs | procServ writes (owner); `ioc` group reads (group bit + ACL); other reads (other bit). Engineer-created files in dir gain `ioc` group write via default ACL. |

The two layers are consistent: ioc group members are the
intended `ioc-runner` operators, and ioc group members read log
files freely. Non-`ioc` users cannot run `ioc-runner` (sudoers
layer) and have only read access to log files (mode layer); they
cannot start, stop, or modify IOC state.

## Revised Sections

### Revised — P-B-1. `setup-system-infra.bash` + system systemd template

Replaces `plan20260514_233353` "Revised P-B-1".

Two narrow edits relative to the prior plan:

1. STEP 4 install STEP `setfacl` line:
   - Was: `setfacl -d -m o::--- "${SYSTEM_LOG_DIR}"`
   - Now: `setfacl -d -m o::r-- "${SYSTEM_LOG_DIR}"`

   Rationale: with `o::---`, the access ACL's `other` entry on
   procServ-created files collapses to `---` regardless of
   mode_arg, breaking the readability invariant for users
   outside the `ioc` group on hosts where wider read is
   appropriate. `o::r--` aligns with the system log convention
   for non-privileged logs (`/var/log/dpkg.log`,
   `/var/log/apt/history.log`).

2. system unit heredoc:
   - Was: `UMask=0007` (between `Group=` and `EnvironmentFile=`)
   - Now: line removed; systemd default `UMask=0022` applies

   Rationale: with `UMask=0007` the procServ log would have ended
   up at `0640` (group r--, no other). The User's (b) choice
   widens to `0644`. systemd's default `UMask=0022` preserves
   procServ's natural mode_arg through to the resulting file.

All other heredoc lines in the unit (`User=`, `Group=`,
`EnvironmentFile=`, `RuntimeDirectory=`, `RuntimeDirectoryMode=`,
`ExecStart=`, `SuccessExitStatus=`, `StandardOutput=`,
`StandardError=`, `SyslogIdentifier=`, `[Install]`/`WantedBy=`)
remain identical to `plan20260514_233353`.

### Verification (V-B-1 + V-C2)

V-B-1 assertions (system unit + dir + default ACL):

- `grep -E '^(User|Group)=' /etc/systemd/system/epics-@.service`
  returns `User=ioc-srv` and `Group=ioc`.
- `grep '^UMask=' /etc/systemd/system/epics-@.service` returns
  no match (negative assertion).
- `grep -E '^ExecStart=' ...` contains
  `--logfile=${SYSTEM_LOG_DIR}/%i.log`.
- `grep LogsDirectory ...` returns no match.
- `stat -c '%U:%G %a' ${SYSTEM_LOG_DIR}` returns `root:ioc 2770`.
- `getfacl ${SYSTEM_LOG_DIR}` shows default entries
  `g:ioc:rw-`, `o::r--`, `m::rw-`.

V-C2-system assertions:

- Case 1 (procServ-created): `stat -c '%U:%G %a'
  ${SYSTEM_LOG_DIR}/<ioc>.log` returns `ioc-srv:ioc 644`.
  `getfacl` shows `mask::r--`, `other::r--`,
  `group:ioc:rw- #effective:r--`.
- Case 2 (engineer touch with umask 0022):
  `stat -c '%U:%G %a' ${SYSTEM_LOG_DIR}/probe.log` returns
  `<engineer>:ioc 664`. `getfacl` shows `mask::rw-`,
  `other::r--`, `group:ioc:rw-`.
- Access probe: `cat <log>` succeeds as a user in `ioc`; also
  succeeds for any user (since other has `r--`).
- sudoers gate: `sudo systemctl start epics-@*.service` as a
  user not in `ioc` exits with "not allowed to execute".

V-C2-local unchanged from `plan20260514_233353`.

## Plan Item Matrix Delta

Only the cells below differ from `plan20260514_233353`. All other
rows remain as in the prior plan.

| Plan ID | Source Decisions | Issues | Files | Verification | State |
| --- | --- | --- | --- | --- | --- |
| P-B-1 | D-001..D-008; R-PLAN3-5 | #9 | `bin/setup-system-infra.bash` (STEP 4 `setfacl o::r--`; unit heredoc no `UMask=`); `docs/TEST_PLAN-1.1.0.md` (V-B-1 / Phase C2 / V-C2 wording — already updated in working tree); `docs/LOG_PERMISSIONS.md` (rewritten this turn) | V-B-1 (see Revised P-B-1) | implemented (this turn) |
| P-C2 | D-001, D-006, D-007 | #12 | (verification only); `docs/TEST_PLAN-1.1.0.md` (V-C2 expected mode `0644`/`0664` instead of `0660`) | V-C2-system Case 1 (`0644`) + Case 2 (`0664`) + V-C2-local + sudoers gate | implemented |

P-B-2 row is unchanged from `plan20260514_233353` (local mode
single-principal model, no edits this round).

## Authorization Scope This Plan Asks For

The combined P-B-1 + P-B-2 + P-C2 scope from
`auth20260514_235635` remains in effect for this superseding
plan. The (b) revision falls within the originally authorized
boundary (P-B-1 setup-system-infra.bash + P-B-2 ioc-runner +
P-C2 verification); only the expected mode targets change. The
Facilitator does not request a fresh execution_authorization;
the original `auth20260514_235635` covers the implementation
under this revised plan, with the (b) corrections being the
authorized "Implementation-Time Refinements" that Reviewer 1
explicitly invited at Step 3-R for resolution during the
implementation turn.

## User Decision Status

- UD006 (Approve combined P-B-1 + P-B-2 + P-C2 against the
  latest plan): remains closed via auth20260514_235635 +
  the User's "B로 가자" 2026-05-15 confirming the (b) revision
  within the authorized scope.
- No new UD pending for plan supersession.

## Recovery Boundary

Inherited from `plan20260514_233353`. Pre-commit recovery: revert
working-tree edits and re-run `setup-system-infra.bash`.
Post-commit rollback: `git revert` of the combined commit,
regenerate units. `/var/log/procserv` may persist with the new
default ACL; the operator decides whether to remove or re-assert
the prior `o::---` policy if reverting.
