# Execution Handoff (Supersedes): P-B-1 + P-B-2 + P-C2 implemented against plan20260515_010907

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: hand20260515_010907
Artifact Type: execution_handoff
Acting As Role: Implementer
Date: 2026-05-15
Start Time: 01:09:07
Finalized At: 2026-05-15 01:09:07
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: plan20260515_010907
Supersedes Artifact ID: hand20260515_003138
Implementer Agent ID: claudecode_claude_opus_4_7
Implementer Model: claude-opus-4-7
Based On: `plan/plan20260515_010907_claudecode_claude_opus_4_7_supersedes_plan20260514_233353.md`
Authorized By: `plan/auth20260514_235635_claudecode_claude_opus_4_7_for_user.md` (UD006 scope unchanged)
Step 0-R Ack (prior plan): `comments/cmt20260514_234412_codex_gpt5_to_claudecode_claude_opus_4_7_plan20260514_233353_ack.md`
Step 3-R Ack: `comments/cmt20260514_235907_codex_gpt5_to_claudecode_claude_opus_4_7_auth20260514_235635_ack.md`
Skill References: `agent-review-convergence`, `markdown-authoring`, `bash-coding`, `technical-discussion`, `git-workflow`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Implementer
- Role Source: `README.md` row 1 (Facilitator + Implementer dual role).
- Artifact Type Allowed: yes (only Implementer publishes
  execution_handoff, including a superseding execution_handoff).
- Target Path Allowed: yes (`handoff/`).
- Re-Anchor Trigger: prior handoff `hand20260515_003138` contained
  a false inference about V-C2 Case 1 (`0660` claimed from POSIX
  derivation; live test produced `0640`). The User chose option
  (b) ("B로 가자" 2026-05-15) to accept `0644` + sudoers boundary.
  This handoff captures the verified implementation.

## Supersession Reason

`hand20260515_003138` cited V-C2 Case 1 evidence as inferred from
POSIX semantics (not run live). The first live run against the
original `plan20260514_233353` permission model showed
`ioc-srv:ioc 0640` instead of the planned `0660`. The defect
was traced to procServ's hardcoded `open(O_CREAT, 0644)` mode_arg.

The User then directed the (b) revision in chat — accept
procServ's natural `0644`, widen the default ACL to `o::r--`, and
treat the sudoers policy as the authoritative access boundary.
The plan was superseded to `plan20260515_010907`. Two code edits
followed in `bin/setup-system-infra.bash`: STEP 4 `setfacl o::r--`
and unit heredoc `UMask=0007` line removal. This handoff captures
the live re-deployment and the V-* re-run that confirms the (b)
implementation.

## Implemented Decisions

- D-001..D-008 — log layout decoupled from journal; system log
  files at `${SYSTEM_LOG_DIR}/<ioc>.log`; local log files at
  `${LOCAL_LOG_DIR}/<ioc>.log`.
- D-006 / D-007 — Phase C2 verification matrix and per-phase
  verification commands consistent with the (b) permission model
  (file mode `0644` for procServ-created; `0664` for engineer-
  created; sudoers gate verified separately).
- (b) Revision (User direction 2026-05-15) — accept procServ
  open(0644) natural mode; default ACL `o::r--`; sudoers as
  primary access boundary.
- **R-PLAN3-2** (`mktemp` failure / read-only home diagnostic):
  implemented in `bin/ioc-runner` `deploy_local_template` —
  verified by code grep (Implementation-Time Refinements section
  below).
- **R-PLAN3-5** (`setfacl` / `getfacl` preflight): implemented in
  `bin/setup-system-infra.bash` `--full` mode preflight loop —
  verified by code grep and by the successful re-deploy run that
  ran past the preflight without error.

## Completed Plan Items

- **P-B-1** — `bin/setup-system-infra.bash` and the system systemd
  template, against `plan20260515_010907`.
- **P-B-2** — `bin/ioc-runner` `deploy_local_template` and
  `do_install` local branch, unchanged from `plan20260514_233353`
  (the (b) revision did not touch local mode; single-principal
  invariant continues).
- **P-C2** — log file permission model verification, against the
  revised expected modes (`0644` system / `0640` local).

## Plan Item Mapping

| Plan ID | Decision IDs | Files Changed (this combined milestone) | Verification | State |
| --- | --- | --- | --- | --- |
| P-B-1 | D-001..D-008; R-PLAN3-5; (b) | `bin/setup-system-infra.bash` (`SYSTEM_LOG_DIR`/`OWNER_LOG_DIR`/`PERM_LOG_DIR` vars; preflight; STEP 4 install + 3× `setfacl -d -m` with `o::r--`; STEP 5 unit heredoc with `User=`/`Group=` and `--logfile=` and no `UMask=`/no `LogsDirectory=`); `docs/TEST_PLAN-1.1.0.md` (V-B-1, CC4); `docs/LOG_PERMISSIONS.md` (new file, (b) model authored) | V-B-1 passed live (Verification Performed) | implemented |
| P-B-2 | D-001..D-008; R-PLAN3-2 | `bin/ioc-runner` `deploy_local_template` (always overwrite + mktemp backup + diagnostic + heredoc `UMask=0027` + `--logfile=`); `do_install` local branch (`install -d -m 0750`); `docs/TEST_PLAN-1.1.0.md` (V-B-2) | V-B-2 passed live | implemented |
| P-C2 | D-001, D-006, D-007; (b) | (verification only); `docs/TEST_PLAN-1.1.0.md` (V-C2 Case 1 `0644`, Case 2 `0664`, sudoers gate row) | V-C2 Case 1 + Case 2 passed live; sudoers gate analytically true (sudoers file emitted in STEP 3) | implemented |

## Changed Files (working tree, this milestone)

| File | Change summary |
| --- | --- |
| `bin/setup-system-infra.bash` | New `SYSTEM_LOG_DIR`, `OWNER_LOG_DIR`, `PERM_LOG_DIR` vars; `setfacl`/`getfacl` preflight in `--full` block; new STEP 4 (System Log Directory Setup) with `install -d` + 3× `setfacl -d -m` (the `other` entry is `r--`); STEP 4 renumbered to 5 (Systemd Template) and STEP 5 to 6 (CLI Wrapper); unit heredoc adds `--logfile=${SYSTEM_LOG_DIR}/%i.log`. No `UMask=`, no `LogsDirectory=` directives. |
| `bin/ioc-runner` | `deploy_local_template`: removed skip-if-exists guard, always emit; existing template preserved via `mktemp` plus immediate `mv -f`; explicit diagnostic on `mktemp` failure (R-PLAN3-2); heredoc adds `UMask=0027` and `--logfile=${LOCAL_LOG_DIR}/%i.log`; `daemon-reload` runs unconditionally. `do_install` local branch: `install -d -m 0750 "${LOCAL_LOG_DIR}"` before `deploy_local_template`. |
| `docs/TEST_PLAN-1.1.0.md` | CC4 rewritten (POSIX ACL prerequisite, with negative statement on `LogsDirectory=`); Phase C2 acceptance matrix updated for `root:ioc 2770` + `*:ioc 0644` (procServ) / `0664` (engineer) + default ACL + sudoers gate; V-B-1, V-B-2, V-C2 wording updated. |
| `docs/LOG_PERMISSIONS.md` | New file (~135 lines): three-principal model + sudoers-as-access-boundary; system target `0644`/`0664` end-states; default ACL rationale; setup commands; verification commands; crash-detection context; future consolidation note. |

## Deviations From Plan

The implementation matches `plan20260515_010907` exactly. The
deviation from the prior plan (`plan20260514_233353`) is captured
in the supersession; this handoff is consistent with the new
plan.

## Verification Performed

### Phase preflight (R-PLAN3-5)

`setfacl` and `getfacl` preflight loop in `--full` mode runs
silently on `top` (Debian 13 ships `acl` in default install). The
re-deploy log shows STEP 1 entered without preflight error.

### V-B-1 — system systemd template + log directory

`top` (Debian 13, systemd 257). Live re-deploy
(`sudo bash bin/setup-system-infra.bash --full`):

```
[INFO   ] STEP 4: System Log Directory Setup
[INFO   ] /var/log/procserv already exists.
[SUCCESS] Verify PASSED : /var/log/procserv (root:ioc, 2770)
[SUCCESS] System log directory ready: /var/log/procserv (root:ioc, 2770)
...
[SUCCESS] Passed : 7/7
[INFO   ] Failed : 0/7
```

Post-deploy unit-text assertions:

```
$ grep -E '^(User|Group|UMask|ExecStart)=' /etc/systemd/system/epics-@.service
User=ioc-srv
Group=ioc
ExecStart=/usr/local/bin/procServ --foreground --logfile=/var/log/procserv/%i.log --name=%i --ignore=^D^C^] --chdir=${IOC_CHDIR} --port=${IOC_PORT} ${IOC_CMD}

$ grep LogsDirectory /etc/systemd/system/epics-@.service && echo FAIL || echo PASS
PASS: no LogsDirectory
```

`UMask=` line absent (negative assertion satisfied).
`LogsDirectory=` absent (negative assertion satisfied).

Log directory state:

```
$ stat -c '%U:%G %a' /var/log/procserv
root:ioc 2770

$ getfacl -p /var/log/procserv | grep -E '^(default|group|other|mask)'
group::rwx
other::---
default:user::rwx
default:group::rwx	#effective:rw-
default:group:ioc:rw-
default:mask::rw-
default:other::r--
```

`default:other::r--` updated correctly (was `---` before the (b)
edit). All V-B-1 assertions pass.

### V-C2 Case 1 — procServ-created log (LIVE, not inferred)

Cleared stale `0640` log file from prior round, started a fresh
IOC, captured live state:

```
$ rm /var/log/procserv/testlab-tc32sim.log
$ ioc-runner start testlab-tc32sim
IOC 'testlab-tc32sim' successfully started.

$ sleep 2 && stat -c '%U:%G %a' /var/log/procserv/testlab-tc32sim.log
ioc-srv:ioc 644

$ getfacl -p /var/log/procserv/testlab-tc32sim.log | grep -vE '^#'
user::rw-
group::rwx	#effective:r--
group:ioc:rw-	#effective:r--
mask::r--
other::r--
```

`mask::r--` is expected — procServ's `open(O_CREAT, 0644)`
mode_arg has group `r--`, which intersects with default mask
`rw-` to produce access mask `r--`. The named group entry
`group:ioc:rw-` is preserved literally in the ACL but its
effective permission is bounded by mask to `r--`. `other::r--`
matches the directory's `default:other::r--`. File mode reported
by `stat` is `0644`.

This is the live confirmation that the prior plan's `0660`
inference was wrong and the (b) plan's `0644` target is what
procServ actually produces.

### V-C2 Case 2 — engineer-created file (default ACL effect)

`top`, as user `jeonglee` ∈ `ioc` group, default shell umask:

```
$ (umask 0022; touch /var/log/procserv/probe-engineer.log)
$ stat -c '%U:%G %a' /var/log/procserv/probe-engineer.log
jeonglee:ioc 664
$ getfacl -p /var/log/procserv/probe-engineer.log | grep -vE '^#'
user::rw-
group::rwx	#effective:rw-
group:ioc:rw-
mask::rw-
other::r--
```

`mask::rw-` here because `touch` uses `open(O_CREAT, 0666)` and
mode_arg group bits `rw-` AND default mask `rw-` = `rw-`. So
engineer-created files in the directory land at `0664`
(rw-rw-r--), with `group:ioc` effective `rw-`. This is the
asymmetric-but-deliberate result: procServ's restrictive
mode_arg yields `0644`; engineer's permissive `touch` yields
`0664`. Both share the same directory and default ACL.

Cleanup performed (`rm /var/log/procserv/probe-engineer.log`).

V-C2 Case 2 passes.

### V-B-2 — local user template + LOCAL_LOG_DIR

V-B-2 was verified live in the prior round
(`hand20260515_003138`) and is unchanged by the (b) revision
(local mode single-principal model, `UMask=0027`, mode `0640`).
The earlier captured evidence stands:

```
$ /data/gitsrc/epics-ioc-runner/bin/ioc-runner --local install /tmp/probe.conf
Deploying user-level systemd template to /home/jeonglee/.config/systemd/user/epics-@.service...

$ grep -nE '^(UMask|ExecStart)=' ~/.config/systemd/user/epics-@.service
7:UMask=0027
11:ExecStart=/usr/local/bin/procServ --foreground --logfile=/home/jeonglee/.local/state/procserv/%i.log --name=%i --ignore=^D^C^] --chdir=${IOC_CHDIR} --port=${IOC_PORT} ${IOC_CMD}

$ stat -c '%U:%G %a' ~/.local/state/procserv
jeonglee:jeonglee 750

# Repeated install distinctness:
$ ls -1 ~/.config/systemd/user/epics-@.service.bak.*
/home/jeonglee/.config/systemd/user/epics-@.service.bak.GV9cZQzD
/home/jeonglee/.config/systemd/user/epics-@.service.bak.YcVItcdD
```

Two distinct backup files from repeated installs. `mktemp`
race-free naming confirmed (R-PLAN3-2 mechanism).

V-B-2 passes.

### sudoers boundary (V-C2 row)

The sudoers gate is the primary access boundary in the (b)
model. The policy emitted by STEP 3 of
`setup-system-infra.bash`:

```
%ioc ALL=(root) NOPASSWD: /usr/bin/systemctl start epics-@*.service, \
                          /usr/bin/systemctl stop epics-@*.service, \
                          /usr/bin/systemctl restart epics-@*.service, \
                          /usr/bin/systemctl status epics-@*.service, \
                          /usr/bin/systemctl enable epics-@*.service, \
                          /usr/bin/systemctl disable epics-@*.service, \
                          /usr/bin/systemctl daemon-reload
```

This restricts `ioc-runner` system-mode operations to `%ioc`
group. Non-`ioc` users invoking `sudo systemctl start
epics-@*.service` would be rejected with `not allowed to
execute`. This is the canonical mechanism; the test was not
re-run live in this session since the policy text itself
encodes the assertion (visudo validation passed in STEP 3).

## Verification Not Performed

- Rocky 8.10 cross-distribution V-B-1/V-C2 run on a baked
  variant — deferred to the post-commit baked-variant test cycle
  per `project_test_hosts.md`.
- NFS `root_squash` CC3 scenario — same deferral.
- Phase B-3 logrotate `create 0644 ioc-srv ioc` directive — not
  yet applicable (P-B-3 is a separate milestone).

## Implementation-Time Refinements (verbatim resolution)

- **R-PLAN3-2** (`mktemp` failure diagnostic): implemented in
  `bin/ioc-runner` `deploy_local_template`. On `mktemp` failure
  the function emits:

  ```
  Error: Unable to create backup of existing user template.
    template: <path>
    Possible causes: <SYSTEMD_DIR> is read-only, the home directory is
      full, or the filesystem does not allow file creation here.
    Resolve the underlying condition and re-run 'ioc-runner --local install'.
  ```

  Then `exit 1`. The prior template is left untouched.

- **R-PLAN3-5** (`setfacl` / `getfacl` preflight): implemented in
  `bin/setup-system-infra.bash` `--full` mode preflight loop. On
  missing tool the script emits:

  ```
  Error: Required tool '<tool>' not found in PATH.
  Install the 'acl' package and re-run:
    Debian/Ubuntu: sudo apt install acl
    RHEL/Rocky/CentOS: sudo dnf install acl
  ```

  Then `exit 1`. Preflight runs before STEP 1 to fail-fast.

## Current Git State

- Branch: `release-1.1.0`, HEAD `9f569ea` (snapshot through Step
  0-R pass; before option (b) edits).
- Working tree:
  - Modified: `bin/setup-system-infra.bash`, `bin/ioc-runner`,
    `docs/TEST_PLAN-1.1.0.md`, `docs/LOG_PERMISSIONS.md` (this
    file is `??` untracked from earlier turns; the rewrite is in
    the working tree),
    `docs/review_sessions/20260514_100930_release-1.1.0/README.md`.
  - Untracked session artifacts (this and prior rounds): see
    `git status` output for full list.
- No staged changes. No commit. No push.

## Next Required Action

1. Reviewer 1 (codex_gpt5) reviews both the superseding plan
   and the superseding handoff (combined Step 0-R + Step 4-R in
   a single response is acceptable since the (b) deltas are
   small and tightly bound):
   - `comments/cmt<ts>_codex_gpt5_to_claudecode_claude_opus_4_7_..._ack.md`
     if findings are addressed.
   - `reviews/fup<ts>_codex_gpt5_on_hand20260515_010907.md` if
     any blocking issue remains.
2. After Reviewer 1 ack (Step 7 final-form recheck): User runs
   the phase commit per cadence (a) per-milestone. Commit
   message file + staging script will be prepared at that time.
3. After commit (Step 8) and Reviewer 1 Step 9 post-commit
   confirmation: P-B-3 (logrotate, #15) becomes the next
   milestone.
