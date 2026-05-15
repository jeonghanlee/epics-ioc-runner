# Development Plan (Supersedes): Permission model widened to root:ioc 2770 + setgid + UMask=0007

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: plan20260514_231659
Artifact Type: development_plan
Acting As Role: Implementer
Date: 2026-05-14
Start Time: 23:16:59
Finalized At: 2026-05-14 23:16:59
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: conv20260514_112923
Supersedes Artifact ID: plan20260514_222000
Implementer Agent ID: claudecode_claude_opus_4_7
Implementer Model: claude-opus-4-7
Based On Artifact ID: conv20260514_112923
Based On: `convergence/conv20260514_112923_claudecode_claude_opus_4_7.md`
Revision Inputs:
  - `reviews/fup20260514_225309_codex_gpt5_on_plan20260514_222000_holistic.md`
  - `comments/cmt20260514_231659_claudecode_claude_opus_4_7_to_codex_gpt5_holistic_findings_ack.md`
  - User direction 2026-05-14 (three-principal `rw` invariant + Site canonical `root:ioc 2770` pattern + 1.0.x crash detection migration context)
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`, `doc-pipelines`, `git-workflow`, `bash-coding`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Implementer
- Role Source: `README.md` row 1 (Facilitator + Implementer dual role).
- Artifact Type Allowed: yes (only Implementer may publish
  development_plan, including a superseding development_plan).
- Target Path Allowed: yes (`plan/`).
- Re-Anchor Trigger: Reviewer 1 holistic fup `fup20260514_225309`
  raised three findings (F-PLAN-1/2/3) plus User direction widened
  the permission model itself; ack comment `cmt20260514_231659`
  recorded the acceptances.

## Inheritance (explicit per F-PLAN-1)

This artifact is a delta-style superseding development_plan against
`plan20260514_222000_claudecode_claude_opus_4_7_supersedes_plan20260514_114106.md`.

**Inherited unchanged from plan20260514_222000:**

- Header up to but not including `## Inheritance`.
- Plan Item Matrix rows for `P-A`, `P-Readiness`, `P-B-3`, `P-C1`,
  `P-D-1`, `P-D-2`, `P-D+`, `P-E`, `P-F-1`, `P-F-2`, `P-F-3`, `P-G`.
- `## Test Plan Carry-Over` statement.
- `## Authorization Scope This Plan Asks For` (combined P-B-1 +
  P-B-2 + P-C2; P-B-3 separate).

**Revised in this artifact (sections below):**

- `## Revised Sections` for P-B-1, P-B-2, P-C2 (full re-statement,
  not a delta).
- `## Plan Item Matrix Delta` for P-B-1, P-B-2, P-C2 rows.
- `## User Decision Needed Before Execution` (UD006 wording unchanged,
  target plan ID updated).
- `## Recovery Boundary` (split into pre-commit and post-commit per
  F-PLAN-3).

**Added in this artifact (no analog in prior plan):**

- `## Permission Model` block stating the three-principal `rw`
  invariant and the resulting mode/ownership/umask choices.

## Supersession Reason

`fup20260514_225309` raised three findings against
`plan20260514_222000`:

- F-PLAN-1 — Inheritance section understated superseding scope.
- F-PLAN-2 — P-B-2 did not state how existing local templates are
  updated; `deploy_local_template`'s `if [[ ! -f ${template_path} ]]`
  guard would silently skip the new `UMask=` line on any host that
  already has a template from 1.0.x.
- F-PLAN-3 — Recovery Boundary conflated pre-commit verification
  failure (no commit to revert yet) with post-commit rollback.

During the User direction turn that followed, the permission model
itself was reframed:

- Three-principal `rw` invariant is the operational requirement
  (`root`, `ioc-srv`, engineer ∈ `ioc` all read AND write any log
  file regardless of creator).
- The previously-planned `0640` file mode does not satisfy this
  invariant (engineer would have read-only).
- The Site canonical permission pattern is `root:ioc <setgid+rwx>`
  (User example: `sudo install -d -o root -g ioc -m 2775
  /opt/epics-iocs`). For log directories specifically the
  Facilitator adopts mode `2770` (other access blocked).
- `LogsDirectory=procserv` cannot deliver `root:ioc` ownership
  (systemd will chown to unit `User=`/`Group=` on every activation
  per `systemd.exec(5)`). The directive is therefore removed.
- `setup-system-infra.bash` becomes the install-time owner of
  the directory: it pre-creates with the correct ownership and
  mode, and it gains parity with `bin/ioc-runner`'s existing
  `IOC_RUNNER_SYSTEM_LOG_DIR` override variable.

The crash-detection use case (engineer-side `ioc-runner status` +
inline byte-offset scan in `do_start_restart`) anchors this
decision: the engineer's own UID must be able to read and (for
operational cleanup) write the log file, without sudo, without a
`systemd-journal` group bit, and independent of distribution.

## Permission Model

End-state targets (system mode):

| Object | Owner:Group | Mode | Creator | Mechanism |
| --- | --- | --- | --- | --- |
| `${SYSTEM_LOG_DIR}/` (default `/var/log/procserv/`) | `root:ioc` | `2770` (setgid) | `setup-system-infra.bash` install-time | `install -d -o root -g ioc -m 2770 ${SYSTEM_LOG_DIR}` |
| `${SYSTEM_LOG_DIR}/<ioc>.log` | `ioc-srv:ioc` | `0660` | procServ at IOC start | systemd unit `UMask=0007` + setgid parent dir |

End-state targets (local mode):

| Object | Owner:Group | Mode | Creator | Mechanism |
| --- | --- | --- | --- | --- |
| `${LOCAL_LOG_DIR}/` (default `~/.local/state/procserv/`) | `<user>:<user>` | `0750` | `bin/ioc-runner` `do_install` local branch | `install -d -m 0750 ${LOCAL_LOG_DIR}` |
| `${LOCAL_LOG_DIR}/<ioc>.log` | `<user>:<user>` | `0640` | procServ at IOC start | user-mode systemd unit `UMask=0027` |

Three-principal `rw` invariant (system mode only; local mode is
single-principal by construction):

| Principal | On dir `2770` | On file `0660` | Mechanism |
| --- | --- | --- | --- |
| `root` (install) | owner rwx | bypass | direct owner; root reads any mode |
| `ioc-srv` (operate, primary group `ioc`) | group rwx | owner rw | dir group via primary-group membership; file owner |
| engineer ∈ `ioc` (manage) | group rwx | group rw | dir group via supplementary group; file group bit |
| other | --- | --- | locked out (2770 has no other bits) |

Creation-order invariance: the directory's setgid bit forces every
newly created file inside it to inherit group `ioc`, so file group
is `ioc` regardless of which UID created it. With mode `0660`,
both owner and group bits give `rw`, so both `ioc-srv` and ioc
engineers retain `rw` access whichever one created the file first.

## Revised Sections

### Revised — P-A baseline (clarification only, no code revisit)

`bin/ioc-runner:34` already exports
`SYSTEM_LOG_DIR=${IOC_RUNNER_SYSTEM_LOG_DIR:-/var/log/procserv}`
(Phase A, commit 5aa2e76). This declaration is the **single source
of truth** for the system log directory path on the runtime side.
P-B-1 below introduces the matching declaration on the install side
in `setup-system-infra.bash`, so the two sides agree under any
operator override. No revision to `bin/ioc-runner` Phase A code
is implied by this plan.

### Revised — P-B-1. `setup-system-infra.bash` + system systemd template

Replaces `plan20260514_222000` "Revised P-B-1".

Purpose:

(a) Install the system log directory with Site-canonical ownership
and mode before procServ ever runs against it. (b) Update the
emitted system systemd template so procServ writes to a dedicated
log file under that directory at mode `0660`. (c) Honor the
operator override `IOC_RUNNER_SYSTEM_LOG_DIR` symmetrically with
`bin/ioc-runner`.

Changes to `bin/setup-system-infra.bash`:

- Add a `SYSTEM_LOG_DIR` declaration near the existing path
  declarations (around lines 17-35 of the current file):
  `declare -g SYSTEM_LOG_DIR="${IOC_RUNNER_SYSTEM_LOG_DIR:-/var/log/procserv}"`.
- Add a `OWNER_LOG_DIR` and `PERM_LOG_DIR` pair near other ownership
  defaults: `OWNER_LOG_DIR="root:${SYSTEM_GROUP}"` and
  `PERM_LOG_DIR="2770"`. Naming follows the existing
  `OWNER_CONF_DIR` / `PERM_CONF_DIR` pattern at line 50 onward.
- Add a new STEP block (after the existing conf-directory STEP that
  ends near line 305) that creates the log directory:

  ```bash
  print_divider
  _log "INFO" "STEP <N>: System Log Directory Setup"

  if [[ ! -e "${SYSTEM_LOG_DIR}" ]]; then
      install -d -o "root" -g "${SYSTEM_GROUP}" -m "${PERM_LOG_DIR}" "${SYSTEM_LOG_DIR}"
  fi

  chown "${OWNER_LOG_DIR}" "${SYSTEM_LOG_DIR}"
  chmod "${PERM_LOG_DIR}" "${SYSTEM_LOG_DIR}"
  verify_path "${SYSTEM_LOG_DIR}" "${OWNER_LOG_DIR}" "${PERM_LOG_DIR}" "System log directory ready"
  ```

  The unconditional `chown`/`chmod` after `install -d` is defensive:
  on a host where the directory already existed (re-run of setup),
  it re-asserts the Site invariant rather than silently honoring
  drift.

- Modify the existing systemd template heredoc (`setup-system-infra.bash:351-373`):
  - **Remove** any reference to `LogsDirectory=procserv` and
    `LogsDirectoryMode=` (these are not present in the current file
    and must remain absent in the new heredoc as well — recording
    this explicitly here so a future contributor does not
    re-introduce them).
  - **Add** `UMask=0007` in the `[Service]` block before `ExecStart=`.
  - **Modify** `ExecStart=` to use the new `--logfile=` path:
    replace `--logfile=-` with `--logfile=${SYSTEM_LOG_DIR}/%i.log`.
    The `${SYSTEM_LOG_DIR}` here is a shell-resolved value at heredoc
    emission time (the path is baked into the unit text); systemd
    sees a literal path with `%i` interpolated at activation.
  - Leave `User=${SYSTEM_USER}`, `Group=${SYSTEM_GROUP}`,
    `StandardOutput=syslog`, `StandardError=inherit`,
    `SyslogIdentifier=epics-%i` unchanged.

Dependencies the implementation relies on:

- `bin/setup-system-infra.bash:288` continues to create `ioc-srv`
  with primary group `ioc` (`useradd -g ${SYSTEM_GROUP} ${SYSTEM_USER}`).
- The `verify_path` helper continues to compare `owner:group` and
  mode as it does for existing system objects (sudoers file, conf
  dir, etc.).
- POSIX `install` is available on both Debian 13 and Rocky 8 (it is
  in coreutils on both).

Verification:

- V-B-1: `systemctl cat epics-@<name>.service` confirms the new
  directives. Asserted via:
  - `grep -E '^User=' /etc/systemd/system/epics-@.service` returns
    `User=ioc-srv`.
  - `grep -E '^Group=' ...` returns `Group=ioc`.
  - `grep -E '^UMask=' ...` returns `UMask=0007`.
  - `grep -E '^ExecStart=' ...` contains
    `--logfile=/var/log/procserv/%i.log` (or the operator-overridden
    path).
  - `grep -E 'LogsDirectory' ...` returns no match (negative
    assertion — directive must be absent).
- V-B-1-dir: `stat -c '%U:%G %a' /var/log/procserv` returns
  `root:ioc 2770`. `verify_path` log line in the STEP output
  records the same.
- TEST_PLAN-1.1.0.md V-B-1 verification command updated to match
  in the same P-B-1 commit.

### Revised — P-B-2. `bin/ioc-runner` local user template (always overwrite + backup)

Replaces `plan20260514_222000` "Revised P-B-2 dependency carry-over".

Purpose:

Apply the same `--logfile=` + `UMask=` discipline to the local user
mode unit, and adopt the system-side `backup_if_exists` pattern so
an existing template from a prior install is migrated cleanly.

Changes to `bin/ioc-runner` `deploy_local_template` (around lines
295-336):

- Remove the `if [[ ! -f "${template_path}" ]]` guard. The function
  now always emits the template.
- Before emitting, back up an existing template to
  `${template_path}.bak-<timestamp>` (timestamp format
  `YYYYMMDD-HHMMSS`). The backup is only created when a prior file
  exists; the timestamp suffix preserves multiple historical
  templates if reinstall happens repeatedly.
- The heredoc body adds two lines relative to current 1.0.x:
  - `UMask=0027` in the `[Service]` block before `ExecStart=`.
  - `ExecStart=` modified: `--logfile=-` becomes
    `--logfile=${LOCAL_LOG_DIR}/%i.log`. `${LOCAL_LOG_DIR}` is the
    `deploy_local_template` shell variable at emission time
    (baked into the unit text).
- The `run_systemctl daemon-reload` call (currently inside the
  if-guard at line 334) moves outside the removed guard and runs
  unconditionally after every emission.

Changes to `bin/ioc-runner` `do_install` local branch (around line
872-882):

- Before `deploy_local_template` runs, ensure `${LOCAL_LOG_DIR}`
  exists with the correct user-owned mode:
  `install -d -m 0750 "${LOCAL_LOG_DIR}"`. No `chown` needed —
  the directory is created as the invoking user (local mode is
  single-principal).

Local-mode permission rationale (PM-5 from ack):

- `--local` mode is single-principal (one engineer is install,
  operate, and manage at once). The three-principal `rw`
  invariant does not apply.
- Local file mode stays at `0640` (UMask `0027`); the engineer's
  own primary group (typically equal to the engineer's user
  group) gets read access. This matches existing per-user log
  conventions and avoids accidentally widening visibility to
  other engineers who happen to share a UNIX group.

Verification:

- V-B-2: after `ioc-runner --local install <conf>` on a host with
  an existing 1.0.x template:
  - `~/.config/systemd/user/epics-@.service.bak-<timestamp>` exists
    (backup confirmed).
  - `~/.config/systemd/user/epics-@.service` contains
    `UMask=0027` and the new `--logfile=` path (greps as for
    V-B-1).
  - `systemctl --user daemon-reload` ran (unit emission triggers it
    every install now).
  - `stat -c '%U:%G %a' ${LOCAL_LOG_DIR}` returns `<user>:<user> 750`.
- V-B-2 also runs on a host with no prior template (fresh
  install) — no `.bak-*` file is created in that case.
- TEST_PLAN-1.1.0.md V-B-2 verification command updated
  accordingly.

### Revised — P-C2. Permission model verification (no override of unit-created state)

Replaces `plan20260514_222000` "Revised P-C2".

Purpose:

Verify the post-activation state matches the Permission Model
above. No manual `chgrp`/`chmod` is applied during this phase —
the install-time creation in P-B-1 plus the unit-level `UMask=` in
P-B-1 / P-B-2 are the sole permission setters.

Changes:

- No new code in `bin/setup-system-infra.bash` beyond what P-B-1
  already adds.
- No new code in `bin/ioc-runner` beyond what P-B-2 already adds.
- `docs/TEST_PLAN-1.1.0.md` V-C2 verification commands updated.

Verification:

- V-C2-system: post-IOC-start `stat` returns:
  - `stat -c '%U:%G %a' /var/log/procserv` → `root:ioc 2770`.
  - `stat -c '%U:%G %a' /var/log/procserv/<ioc>.log` →
    `ioc-srv:ioc 660`.
- V-C2-local: post-IOC-start `stat` returns:
  - `stat -c '%U:%G %a' ${LOCAL_LOG_DIR}` → `<user>:<user> 750`.
  - `stat -c '%U:%G %a' ${LOCAL_LOG_DIR}/<ioc>.log` →
    `<user>:<user> 640`.
- V-C2-access (system mode):
  - As an engineer in the `ioc` group: `cat <log>` succeeds;
    `printf 'sentinel\n' >> <log>` succeeds (group write).
  - As a user **not** in the `ioc` group: `cat <log>` returns
    permission denied; `ls /var/log/procserv` returns permission
    denied.
  - `id <engineer>` confirms `systemd-journal` group is not required.

## Plan Item Matrix Delta

Only the cells listed below differ from `plan20260514_222000`.
All other rows remain as in `plan20260514_222000` (which inherited
unchanged from `plan20260514_114106` except for the cells already
revised there).

| Plan ID | Source Decisions | Issues | Files | Verification | State |
| --- | --- | --- | --- | --- | --- |
| P-B-1 | D-001..D-008 | #9 | `bin/setup-system-infra.bash` (system unit heredoc — remove `LogsDirectory=*`, add `UMask=0007`, modify `ExecStart=` `--logfile=`; new STEP for `install -d` of `${SYSTEM_LOG_DIR}`; new `SYSTEM_LOG_DIR` variable); `docs/TEST_PLAN-1.1.0.md` (V-B-1 wording) | V-B-1 + V-B-1-dir (see Revised P-B-1) | planned |
| P-B-2 | D-001..D-008 | #10 | `bin/ioc-runner` `deploy_local_template` (always overwrite + backup, heredoc gains `UMask=0027` + `--logfile=`); `do_install` local branch (`install -d -m 0750` for `${LOCAL_LOG_DIR}`) | V-B-2 (see Revised P-B-2) | planned |
| P-C2 | D-001, D-006, D-007 | #12 | (verification only; no new code beyond P-B-1/P-B-2); `docs/TEST_PLAN-1.1.0.md` (V-C2 wording) | V-C2-system + V-C2-local + V-C2-access | planned |

## Test Plan Carry-Over

`docs/TEST_PLAN-1.1.0.md` was committed in `a3acc80` as part of
P-Readiness. The V-B-1 and V-C2 wording updates described above
land in the same commit as the corresponding implementation
phase. Combined-authorization scope means a single commit carries
the P-B-1, P-B-2, P-C2 code changes plus the TEST_PLAN updates;
P-B-3 (logrotate) remains a later separate commit.

## Authorization Scope This Plan Asks For

The Facilitator will request execution_authorization for a combined
**P-B-1 + P-B-2 + P-C2** scope. Rationale (carried from
`plan20260514_222000`, reaffirmed):

- `UMask=` discipline must land in both unit emitters (P-B-1 system
  side + P-B-2 local side) together so intermediate commits do not
  ship one mode for system and another for local. The mode values
  differ between modes (system `0007`, local `0027`) but both
  emitters need their value before any V-* verification runs.
- P-C2's `stat`/access verification is only observable after a unit
  exists (P-B-1 emit) and an IOC has run under it (procServ writes
  the first log file).
- Combined scope: one cross-check round per Phase B (4-R) + one
  recheck on the final-form handoff (gate 7).
- P-B-3 (logrotate, #15) excluded — its verification surface
  (logrotate dry-run + rotation behavior) is independent of unit
  text and permissions.

## User Decision Needed Before Execution

- UD006. Approve revised plan `plan20260514_231659` and authorize
  combined P-B-1 + P-B-2 + P-C2 scope. The Facilitator will publish
  the corresponding execution_authorization once approved. Holistic
  Reviewer 1 response on this plan (gate 0-R per the updated
  Cross-Check Gate Model) must be on disk before UD006 closure.

## Recovery Boundary (split per F-PLAN-3)

The combined milestone touches three independent state surfaces:
working-tree code, generated systemd units on disk, and runtime
filesystem state under `${SYSTEM_LOG_DIR}` and `${LOCAL_LOG_DIR}`.
Recovery procedure depends on whether a phase commit has landed.

### Pre-commit failure (Implementer + Reviewer 1 still iterating)

State: code edits exist in working tree; the operator has run
`sudo setup-system-infra.bash` and/or `ioc-runner --local install`
on a probe host (`top`), so generated unit files reflect the new
text; possibly `/var/log/procserv/` exists with the new ownership.

Recovery:

1. Working-tree code: `git -C <repo> checkout -- bin/setup-system-infra.bash bin/ioc-runner docs/TEST_PLAN-1.1.0.md`.
2. System unit: re-run `sudo bash bin/setup-system-infra.bash` from
   the now-reverted working tree to regenerate the previous unit
   text (the script overwrites the unit file unconditionally via
   `backup_if_exists` + heredoc emission).
3. User unit: delete `~/.config/systemd/user/epics-@.service` and
   any `*.bak-*` files created by the new always-overwrite path,
   then run `ioc-runner --local install <any-conf>` to let the
   reverted `deploy_local_template` emit the prior text.
4. systemd: `sudo systemctl daemon-reload` (system) and
   `systemctl --user daemon-reload` (local).
5. Runtime filesystem: `/var/log/procserv/` and any log files
   under it may persist with the new ownership / mode / setgid bit.
   If the prior milestone state matters (it usually does not — the
   directory was created by the new plan, not the prior plan), the
   operator removes it (`sudo rm -rf /var/log/procserv`) or
   re-asserts the prior owner/mode by hand.

### Post-commit rollback (User has committed the phase)

State: a single combined commit on `release-1.1.0` carries the
P-B-1+P-B-2+P-C2 code + TEST_PLAN edits.

Recovery:

1. `git -C <repo> revert <commit>` against `release-1.1.0`.
2. Re-run `sudo bash bin/setup-system-infra.bash` to regenerate
   the now-reverted system unit and to NOT touch `/var/log/procserv/`
   (the reverted script no longer carries the log-dir STEP, but it
   leaves the existing directory alone — `install -d` on a missing
   directive simply does not run).
3. Local-mode regeneration: same as pre-commit case (delete
   existing user unit and re-install). Backups remain as
   `*.bak-*` files for forensic comparison.
4. Runtime filesystem: `/var/log/procserv/` persists with
   `root:ioc 2770`. The operator decides whether to:
   - Keep it (no operational impact; old unit still writes to
     `--logfile=-` → syslog, so the directory becomes orphaned but
     harmless).
   - Remove it (`sudo rm -rf /var/log/procserv` — caller's
     judgement; existing log files are not auto-removed by
     `git revert`).
   Existing `<ioc>.log` files must be inspected rather than
   assumed gone.
5. Backup files (`*.bak-*` under
   `~/.config/systemd/user/`) remain on disk and are not removed
   by revert. The operator removes them after verifying the
   revert produced the desired unit text.
