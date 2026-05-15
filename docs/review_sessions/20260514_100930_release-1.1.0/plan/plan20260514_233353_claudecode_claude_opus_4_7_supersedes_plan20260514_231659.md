# Development Plan (Supersedes): Default ACL + mktemp backup + LOG_PERMISSIONS.md deliverable

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: plan20260514_233353
Artifact Type: development_plan
Acting As Role: Implementer
Date: 2026-05-14
Start Time: 23:33:53
Finalized At: 2026-05-14 23:33:53
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: conv20260514_112923
Supersedes Artifact ID: plan20260514_231659
Implementer Agent ID: claudecode_claude_opus_4_7
Implementer Model: claude-opus-4-7
Based On Artifact ID: conv20260514_112923
Based On: `convergence/conv20260514_112923_claudecode_claude_opus_4_7.md`
Revision Inputs:
  - `reviews/fup20260514_232444_codex_gpt5_on_plan20260514_231659_holistic.md`
  - `comments/cmt20260514_233353_claudecode_claude_opus_4_7_to_codex_gpt5_fup232444_ack.md`
  - `docs/LOG_PERMISSIONS.md` (new, this turn)
  - User direction 2026-05-14 ("i로 가고, 그리고 이 퍼미션 부분들을 정리해서 따로 문서에 남겨")
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`, `doc-pipelines`, `bash-coding`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Implementer
- Role Source: `README.md` row 1 (Facilitator + Implementer dual role).
- Artifact Type Allowed: yes (only Implementer publishes development_plan).
- Target Path Allowed: yes (`plan/`).
- Re-Anchor Trigger: Reviewer 1 fup `fup20260514_232444` raised
  F-PLAN2-1 (setgid insufficient) and F-PLAN2-2 (backup name
  collision); ack `cmt20260514_233353` recorded the acceptances and
  the User-directed option (i) (`o::---`).

## Inheritance (explicit)

This is a delta-style superseding development_plan against
`plan20260514_231659`. Three localized revisions only.

**Inherited unchanged from plan20260514_231659:**

- Header up to `## Inheritance`.
- `## Permission Model` block, except the directory-row entry gains
  a "Default ACL" column value populated (was absent).
- All Plan Item Matrix rows for `P-A`, `P-Readiness`, `P-B-3`,
  `P-C1`, `P-D-1`, `P-D-2`, `P-D+`, `P-E`, `P-F-1`, `P-F-2`, `P-F-3`,
  `P-G`.
- `## Test Plan Carry-Over`.
- `## Authorization Scope This Plan Asks For` (combined P-B-1 +
  P-B-2 + P-C2; P-B-3 separate).
- `## Recovery Boundary` (pre-commit / post-commit split unchanged).

**Revised in this artifact (sections below):**

- `### Revised — P-B-1`: install STEP gains three `setfacl -d` lines;
  unit text unchanged from prior plan; V-B-1 gains a `getfacl`
  assertion; `docs/LOG_PERMISSIONS.md` added as a P-B-1 deliverable.
- `### Revised — P-B-2`: `deploy_local_template` backup naming
  changes from `YYYYMMDD-HHMMSS` timestamp to `mktemp`-based atomic
  unique-name creation; V-B-2 gains a backup-distinctness assertion.
- `### Revised — P-C2`: V-C2-access gains an engineer-created file
  case to verify that procServ can append to a file the engineer
  created (the case F-PLAN2-1 named).

**Added in this artifact:**

- `docs/LOG_PERMISSIONS.md` as a documentation deliverable shipped
  with the P-B-1 implementation commit.

## Supersession Reason

`fup20260514_232444` identified two defects in `plan20260514_231659`:

- F-PLAN2-1 — setgid alone does not enforce group `rw` on
  newly-created files. The Facilitator's "creation-order
  invariance" claim was true only for the procServ-creates-log
  path (where `UMask=0007` applies). An engineer-created file with
  default `umask 0022` ends up at mode `0644`, breaking the
  invariant for `ioc-srv` writes. Facilitator independently
  reproduced the finding.
- F-PLAN2-2 — `${template_path}.bak-YYYYMMDD-HHMMSS` is not
  collision-resistant for repeated installs in the same second or
  for concurrent installs against an NFS-shared home.

Both fixes are mechanically narrow:

- F-PLAN2-1 fix: default ACLs on the log directory, following the
  Site pattern already documented in `docs/INSTALL.md:171-172` for
  `/opt/epics-iocs`. Per User direction "i로 가고", `o::---` (logs
  remain private to the `ioc` group) replaces `/opt/epics-iocs`'s
  `o::rx`.
- F-PLAN2-2 fix: `mktemp` against a stable prefix produces an
  atomic unique backup name with no timestamp resolution dependency.

`docs/LOG_PERMISSIONS.md` is added as a User-directed deliverable
("이 퍼미션 부분들을 정리해서 따로 문서에 남겨"). It captures the
three-principal model, end-state targets, default-ACL rationale,
verification commands, and the 1.1.0 crash-detection context as a
standalone reference. The 1.1.0 release does not consolidate the
file into `LOG_LAYOUT.md` (Phase F #18) or `FAQ.md`; later phases
may.

## Revised Sections

### Revised — P-B-1. `setup-system-infra.bash` + system systemd template

Replaces `plan20260514_231659` "Revised P-B-1".

The unit-text portion of the change is unchanged from
`plan20260514_231659`. Only the install-time STEP and the
verification list expand.

Changes to `bin/setup-system-infra.bash`:

(unchanged from prior plan — see prior plan for the
`SYSTEM_LOG_DIR`, `OWNER_LOG_DIR`, `PERM_LOG_DIR` declarations and
the systemd template heredoc edits.)

The new STEP body becomes:

```bash
print_divider
_log "INFO" "STEP <N>: System Log Directory Setup"

if [[ ! -e "${SYSTEM_LOG_DIR}" ]]; then
    install -d -o "root" -g "${SYSTEM_GROUP}" -m "${PERM_LOG_DIR}" "${SYSTEM_LOG_DIR}"
fi

chown "${OWNER_LOG_DIR}" "${SYSTEM_LOG_DIR}"
chmod "${PERM_LOG_DIR}" "${SYSTEM_LOG_DIR}"

# Default ACLs: ensure files created in this directory carry group=ioc:rw
# regardless of the creating process umask. setgid alone is insufficient
# (it controls group inheritance, not mode bits).
setfacl -d -m g:"${SYSTEM_GROUP}":rw "${SYSTEM_LOG_DIR}"
setfacl -d -m o::--- "${SYSTEM_LOG_DIR}"
setfacl -d -m m::rw "${SYSTEM_LOG_DIR}"

verify_path "${SYSTEM_LOG_DIR}" "${OWNER_LOG_DIR}" "${PERM_LOG_DIR}" "System log directory ready"
```

The three `setfacl -d -m` lines run unconditionally on every
setup invocation, matching the unconditional `chown`/`chmod`
pattern (defensive re-assertion against drift).

Dependencies:

- `acl` package must be present (`setfacl` / `getfacl` binaries).
  Debian 13 and Rocky 8 ship `acl` by default on minimal installs;
  the script does not install it. A pre-flight check or a
  documented prerequisite in `INSTALL.md` is sufficient (the latter
  is the lower-risk path because installing packages from a setup
  script crosses an authority boundary).

Documentation deliverable shipped with this commit:

- `docs/LOG_PERMISSIONS.md` (new; ~133 lines). Authored this turn
  and referenced by the plan. The file is the source of truth for
  the permission model.

Verification (V-B-1):

`systemctl cat epics-@<name>.service` assertions unchanged from
prior plan (User=, Group=, UMask=0007, ExecStart= contains
`--logfile=`, negative on `LogsDirectory=`).

Filesystem assertions:

```bash
stat -c '%U:%G %a' /var/log/procserv
# expected: root:ioc 2770

getfacl /var/log/procserv | grep -E 'default:'
# expected to contain (order may vary):
#   default:user::rwx
#   default:group::rwx
#   default:group:ioc:rw-
#   default:mask::rw-
#   default:other::---
```

TEST_PLAN-1.1.0.md V-B-1 wording updated to match in the same
P-B-1 commit.

### Revised — P-B-2. `bin/ioc-runner` local user template (mktemp backup)

Replaces `plan20260514_231659` "Revised P-B-2".

The heredoc body (gains `UMask=0027` and `--logfile=` path) and
the always-overwrite behavior are unchanged from the prior plan.
Only the backup naming changes.

Backup sketch:

```bash
function deploy_local_template {
    local procserv_bin=""
    local template_path="${SYSTEMD_DIR}/epics-@.service"
    local backup_path=""

    # ... procserv resolution unchanged ...

    if [[ -f "${template_path}" ]]; then
        backup_path=$(mktemp "${template_path}.bak.XXXXXXXX")
        mv -f "${template_path}" "${backup_path}"
        printf "Backed up existing user template to %s\n" "${backup_path}"
    fi

    printf "Deploying user-level systemd template to %s...\n" "${template_path}"
    mkdir -p "${SYSTEMD_DIR}"
    cat > "${template_path}" <<EOF
... heredoc with UMask=0027 and --logfile=${LOCAL_LOG_DIR}/%i.log ...
EOF
    run_systemctl daemon-reload
}
```

`mktemp` creates an empty unique file atomically (race-free against
concurrent invocations sharing the same home, including NFS-backed
homes). The immediate `mv -f` swaps the existing template into
that unique path; no two backups can ever collide.

Verification (V-B-2) — expands prior plan:

- Fresh install (no prior template): `~/.config/systemd/user/epics-@.service.bak.*`
  files do not appear.
- Upgrade install (prior template present): exactly one
  `epics-@.service.bak.XXXXXXXX` file appears, containing the prior
  template content.
- **Repeated install** (run `ioc-runner --local install <conf>` twice
  in the same second): two distinct `bak.*` files appear, both
  preserved, with different XXXXXXXX suffixes. This is the
  F-PLAN2-2 evidence.
- Heredoc content checks unchanged from prior plan (`UMask=0027`,
  `--logfile=` path, `systemctl --user daemon-reload` ran).

TEST_PLAN-1.1.0.md V-B-2 wording updated to match in the same
P-B-2 commit.

### Revised — P-C2. Permission model verification

Replaces `plan20260514_231659` "Revised P-C2".

The `stat`-based assertions for the procServ-creates-log normal
case are unchanged. The engineer-creates-file exceptional case is
added to verify that the default ACL fix from F-PLAN2-1 is in
effect.

V-C2-system unchanged from prior plan (`stat -c '%U:%G %a'`
expectations).

V-C2-local unchanged from prior plan.

V-C2-access extends to two cases:

Case 1 (normal — procServ-created file, engineer reads/writes):

- As an engineer in the `ioc` group: `cat /var/log/procserv/<ioc>.log`
  succeeds.
- `printf 'sentinel\n' >> /var/log/procserv/<ioc>.log` succeeds.
- As a user **not** in the `ioc` group: same two operations return
  `Permission denied`. `ls /var/log/procserv` returns
  `Permission denied`.

Case 2 (exceptional — engineer-created file, procServ appends):

Procedure on `top` after `setup-system-infra.bash` ran:

1. As an engineer in `ioc`: `touch /var/log/procserv/probe.log`
   (the engineer's `umask` is 0022 in a default shell).
2. `stat -c '%U:%G %a' /var/log/procserv/probe.log` returns
   `<engineer>:ioc 660`. (The mode is 660, not 644, because the
   default ACL on the directory adds group write to the access
   ACL regardless of umask. This is the F-PLAN2-1 confirmation.)
3. `sudo -u ioc-srv test -w /var/log/procserv/probe.log` exits 0
   (ioc-srv has group write through `group=ioc 0660`).
4. Cleanup: `rm /var/log/procserv/probe.log`.

This case is for verification only; normal operation does not
involve engineer-created files in the log directory.

TEST_PLAN-1.1.0.md V-C2 wording updated to match in the same
P-C2 commit.

## Plan Item Matrix Delta

Only the cells below differ from `plan20260514_231659`. All other
rows remain as in `plan20260514_231659`.

| Plan ID | Source Decisions | Issues | Files | Verification | State |
| --- | --- | --- | --- | --- | --- |
| P-B-1 | D-001..D-008 | #9 | `bin/setup-system-infra.bash` (system unit heredoc + new STEP with `install -d` + 3 `setfacl -d -m` lines + `verify_path`); `docs/TEST_PLAN-1.1.0.md` (V-B-1); `docs/LOG_PERMISSIONS.md` (new) | V-B-1 (extended — see Revised P-B-1) | planned |
| P-B-2 | D-001..D-008 | #10 | `bin/ioc-runner` `deploy_local_template` (always overwrite + `mktemp`-based atomic backup, heredoc with `UMask=0027` + `--logfile=`); `do_install` local branch (`install -d -m 0750` for `${LOCAL_LOG_DIR}`) | V-B-2 (extended — see Revised P-B-2) | planned |
| P-C2 | D-001, D-006, D-007 | #12 | (verification only; no new code beyond P-B-1/P-B-2); `docs/TEST_PLAN-1.1.0.md` (V-C2) | V-C2-system + V-C2-local + V-C2-access Case 1 + V-C2-access Case 2 | planned |

## Permission Model Reference

The full Permission Model section moves to `docs/LOG_PERMISSIONS.md`
(this turn). The plan retains a one-paragraph summary plus a
pointer:

The system mode permission model has three principals (root /
ioc-srv / engineer ∈ ioc). End-state for the system log directory
is `root:ioc 2770` with default ACLs `g:ioc:rw`, `o::---`,
`m::rw`. End-state for files is `<creator>:ioc 0660` enforced by
the combination of systemd `UMask=0007` (procServ path) and default
ACLs (exceptional creator path). `LogsDirectory=procserv` is not
used in the unit because systemd would chown the directory to
`User=`/`Group=` on activation, overriding the `root:ioc` owner.
Local mode is single-principal and uses `0750` dir / `0640` file
with `UMask=0027`. See `docs/LOG_PERMISSIONS.md` for derivation,
verification commands, and the crash-detection context.
