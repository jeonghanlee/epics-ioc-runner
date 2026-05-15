# Execution Handoff: P-B-1 + P-B-2 + P-C2 + LOG_PERMISSIONS.md

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: hand20260515_003138
Artifact Type: execution_handoff
Acting As Role: Implementer
Date: 2026-05-15
Start Time: 00:31:38
Finalized At: 2026-05-15 00:31:38
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: plan20260514_233353
Supersedes Artifact ID: none
Implementer Agent ID: claudecode_claude_opus_4_7
Implementer Model: claude-opus-4-7
Based On: `plan/plan20260514_233353_claudecode_claude_opus_4_7_supersedes_plan20260514_231659.md`
Authorized By: `plan/auth20260514_235635_claudecode_claude_opus_4_7_for_user.md`
Step 0-R Ack: `comments/cmt20260514_234412_codex_gpt5_to_claudecode_claude_opus_4_7_plan20260514_233353_ack.md`
Step 3-R Ack: `comments/cmt20260514_235907_codex_gpt5_to_claudecode_claude_opus_4_7_auth20260514_235635_ack.md`
Skill References: `agent-review-convergence`, `markdown-authoring`, `bash-coding`, `technical-discussion`, `git-workflow`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Implementer
- Role Source: `README.md` row 1 (Facilitator + Implementer dual role).
- Artifact Type Allowed: yes (only Implementer publishes
  execution_handoff).
- Target Path Allowed: yes (`handoff/`).
- Re-Anchor Trigger: Step 3-R authorization ack
  `cmt20260514_235907` and User-issued execution_authorization
  `auth20260514_235635`.

## Implemented Decisions

The combined P-B-1 + P-B-2 + P-C2 implementation against
`plan20260514_233353` is complete. All decisions tied to the
authorization scope:

- D-001..D-008 — log layout decoupled from journal; system log
  files at `${SYSTEM_LOG_DIR}/<ioc>.log`; local log files at
  `${LOCAL_LOG_DIR}/<ioc>.log`; permission model per
  `docs/LOG_PERMISSIONS.md`.
- Step 0-R / 3-R "Implementation-Time Refinements" both
  implemented:
  - **R-PLAN3-2** (`mktemp` failure / read-only home diagnostic):
    `deploy_local_template` emits a clear multi-line diagnostic
    naming the template path, listing likely causes (read-only
    `${SYSTEMD_DIR}`, full home directory, restrictive filesystem),
    and pointing to the corrective action before `exit 1`.
  - **R-PLAN3-5** (`setfacl` / `getfacl` preflight): the
    `--full` mode preflight loop in `setup-system-infra.bash` runs
    `command -v` for both tools and exits with an "Install the
    `acl` package" hint (Debian/Ubuntu and RHEL/Rocky/CentOS
    one-liners) before any privileged action.

## Completed Plan Items

- **P-B-1** — `bin/setup-system-infra.bash` and the system systemd
  template.
- **P-B-2** — `bin/ioc-runner` `deploy_local_template` and
  `do_install` local branch.
- **P-C2** — log file permission model verification.

## Plan Item Mapping

| Plan ID | Decision IDs | Files Changed | Verification | State |
| --- | --- | --- | --- | --- |
| P-B-1 | D-001..D-008; R-PLAN3-5 | `bin/setup-system-infra.bash` (vars + STEP 4 install/setfacl + STEP 5 unit heredoc), `docs/TEST_PLAN-1.1.0.md` (V-B-1, CC4), `docs/LOG_PERMISSIONS.md` (new, ~133 lines) | V-B-1 passed (see Verification Performed) | implemented |
| P-B-2 | D-001..D-008; R-PLAN3-2 | `bin/ioc-runner` `deploy_local_template` (mktemp backup + diagnostic + heredoc), `do_install` local branch (`install -d -m 0750`), `docs/TEST_PLAN-1.1.0.md` (V-B-2) | V-B-2 passed (see Verification Performed) | implemented |
| P-C2 | D-001, D-006, D-007 | (verification only; no new code beyond P-B-1/P-B-2), `docs/TEST_PLAN-1.1.0.md` (V-C2, Phase C2 matrix) | V-C2 Case 2 passed live; Case 1 inferred from POSIX semantics + verified state; commands ready for explicit runtime check | implemented |

## Changed Files

| File | Change summary | Lines |
| --- | --- | --- |
| `bin/setup-system-infra.bash` | New `SYSTEM_LOG_DIR`, `OWNER_LOG_DIR`, `PERM_LOG_DIR` vars; `setfacl`/`getfacl` preflight in `--full` block; new STEP 4 (System Log Directory Setup) with `install -d` + 3 × `setfacl -d -m`; STEP 4 renumbered to 5 (Systemd Template) and STEP 5 to 6 (CLI Wrapper); unit heredoc gains `UMask=0007` and `--logfile=${SYSTEM_LOG_DIR}/%i.log`. No `LogsDirectory=*` directive (would chown the dir away from `root:ioc`). | +49 / -3 |
| `bin/ioc-runner` | `deploy_local_template`: removed skip-if-exists guard, always emit; existing template preserved via `mktemp "${template_path}.bak.XXXXXXXX"` plus immediate `mv -f`; explicit diagnostic on `mktemp` failure (R-PLAN3-2); heredoc gains `UMask=0027` and `--logfile=${LOCAL_LOG_DIR}/%i.log`; `daemon-reload` runs unconditionally. `do_install` local branch: `install -d -m 0750 "${LOCAL_LOG_DIR}"` before `deploy_local_template`. | +28 / -10 |
| `docs/TEST_PLAN-1.1.0.md` | CC4 rewritten (POSIX ACL prerequisite, with negative statement on `LogsDirectory=`); Phase C2 acceptance matrix updated for `root:ioc 2770` + `*:ioc 0660` + default ACL + Case 2 row; V-B-1, V-B-2, V-C2 wording updated. | +12 / -7 |
| `docs/LOG_PERMISSIONS.md` | New file (~133 lines): three-principal model, end-state targets, default-ACL rationale with inline probe, setup commands, verification commands, crash-detection context, future consolidation note. | +133 |

Diffstat (from `git diff --stat` on working tree):

```
 bin/ioc-runner                | 38 +++++++++++++++++++++-----------------
 bin/setup-system-infra.bash   | 49 ++++++++++++++++++++++++++++++++++++++++++++++++--
 docs/LOG_PERMISSIONS.md       | 133 +++++++++++++++++++++++++++++++++++++++++++
 docs/TEST_PLAN-1.1.0.md       | 19 ++++++++++++-------
```

## Deviations From Plan

None. The plan's revised P-B-1 / P-B-2 / P-C2 sections, the new
`docs/LOG_PERMISSIONS.md` deliverable, and the two
Implementation-Time Refinements (R-PLAN3-2, R-PLAN3-5) were
applied verbatim. No additional scope creep.

## Verification Performed

### Phase preflight (R-PLAN3-5)

`bash -n` on both edited scripts passes. The preflight loop in
`setup-system-infra.bash` runs before any privileged action; on a
host with `acl` installed (Debian 13 default) it is silent.

### V-B-1 — system systemd template + log directory

`top` (Debian 13 13 trixie, systemd 257).

`sudo bash bin/setup-system-infra.bash --full` (user-side run; output captured):

```
====================================================================================================
[INFO   ] STEP 4: System Log Directory Setup
----------------------------------------------------------------------------------------------------
[INFO   ] Created /var/log/procserv
[SUCCESS] Verify PASSED : /var/log/procserv (root:ioc, 2770)
[SUCCESS] System log directory ready: /var/log/procserv (root:ioc, 2770)
====================================================================================================
[INFO   ] STEP 5: Systemd Template Unit Deployment
----------------------------------------------------------------------------------------------------
[INFO   ] Created backup of epics-@.service in /var/backups/epics-ioc-runner
[SUCCESS] Verify PASSED : /etc/systemd/system/epics-@.service (root:root, 0644)
[SUCCESS] Deployed systemd template to /etc/systemd/system/epics-@.service using /usr/local/bin/procServ
[SUCCESS] Reloaded systemd daemon.
...
[SUCCESS] Passed : 7/7
[INFO   ] Failed : 0/7
```

Post-deploy unit text assertions:

```
$ grep -E '^(User|Group|UMask|ExecStart)=' /etc/systemd/system/epics-@.service
User=ioc-srv
Group=ioc
UMask=0007
ExecStart=/usr/local/bin/procServ --foreground --logfile=/var/log/procserv/%i.log --name=%i --ignore=^D^C^] --chdir=${IOC_CHDIR} --port=${IOC_PORT} ${IOC_CMD}

$ grep LogsDirectory /etc/systemd/system/epics-@.service && echo FAIL || echo PASS: no LogsDirectory directive
PASS: no LogsDirectory directive
```

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
default:other::---
```

All V-B-1 assertions pass.

### V-B-2 — local user template + LOCAL_LOG_DIR

`top` (same host).

First install (fresh state, no prior template):

```
$ rm -f ~/.config/systemd/user/epics-@.service ~/.config/systemd/user/epics-@.service.bak.*
$ rm -rf ~/.local/state/procserv
$ /data/gitsrc/epics-ioc-runner/bin/ioc-runner --local install /tmp/probe.conf
Validating configuration file: /tmp/probe.conf...
Validation passed successfully.
Deploying user-level systemd template to /home/jeonglee/.config/systemd/user/epics-@.service...
IOC probe installed in local mode. Use 'start' command to run it.
```

Assertions on the emitted template + per-user state:

```
$ grep -nE '^(UMask|ExecStart)=' ~/.config/systemd/user/epics-@.service
7:UMask=0027
11:ExecStart=/usr/local/bin/procServ --foreground --logfile=/home/jeonglee/.local/state/procserv/%i.log --name=%i --ignore=^D^C^] --chdir=${IOC_CHDIR} --port=${IOC_PORT} ${IOC_CMD}

$ stat -c '%U:%G %a' ~/.local/state/procserv
jeonglee:jeonglee 750

$ ls ~/.config/systemd/user/epics-@.service.bak.* 2>/dev/null | wc -l
0
```

Backup distinctness probe (two installs in quick succession):

```
$ /data/gitsrc/epics-ioc-runner/bin/ioc-runner --local install /tmp/probe.conf 2>&1 | grep 'Backed up'
Backed up existing user template to /home/jeonglee/.config/systemd/user/epics-@.service.bak.GV9cZQzD

$ /data/gitsrc/epics-ioc-runner/bin/ioc-runner --local install /tmp/probe.conf 2>&1 | grep 'Backed up'
Backed up existing user template to /home/jeonglee/.config/systemd/user/epics-@.service.bak.YcVItcdD

$ ls -1 ~/.config/systemd/user/epics-@.service.bak.*
/home/jeonglee/.config/systemd/user/epics-@.service.bak.GV9cZQzD
/home/jeonglee/.config/systemd/user/epics-@.service.bak.YcVItcdD
```

Two distinct backup files. `mktemp` provides race-free unique
suffixes. R-PLAN3-2 mechanism confirmed.

All V-B-2 assertions pass.

### V-C2 Case 2 — engineer-created file under default ACL (the F-PLAN2-1 fix)

`top` (same host), as user `jeonglee` ∈ `ioc` group, default shell
umask:

```
$ umask
0022
$ (umask 0022; touch /var/log/procserv/probe.log)
$ stat -c '%U:%G %a' /var/log/procserv/probe.log
jeonglee:ioc 660
$ getfacl -p /var/log/procserv/probe.log | grep -vE '^#'
user::rw-
group::rwx	#effective:rw-
group:ioc:rw-
mask::rw-
other::---
```

File mode is `660` (not `644`), file group is `ioc` (not
engineer's primary group). The default ACL on the parent
directory overrode the engineer's `umask 0022` and the parent's
setgid forced the group. This is the explicit demonstration of
the F-PLAN2-1 fix path.

Cleanup performed (`rm /var/log/procserv/probe.log`).

V-C2 Case 2 passes.

### V-C2 Case 1 — procServ-created file inference

Live `sudo systemctl start epics-@<name>.service` could not be
executed inside this Implementer session because the session
sandbox blocks `sudo`. The runtime check is deterministic from
already-verified state:

- The system unit emits `User=ioc-srv`, `Group=ioc`, `UMask=0007`,
  `--logfile=/var/log/procserv/%i.log` (V-B-1).
- procServ is invoked as `ioc-srv` with primary group `ioc`
  (`useradd -g ioc ioc-srv` in `setup-system-infra.bash:288`).
- The log directory has default ACL `g:ioc:rw`, `o::---`, `m::rw`
  (V-B-1).
- procServ creates `<ioc>.log` with `open(O_CREAT, 0666) &
  ~UMask`. With `UMask=0007` the base mode is `0660`; the default
  ACL preserves `g:ioc:rw`. The setgid parent forces group `ioc`.
- Result: `ioc-srv:ioc 0660`.
- Engineer in `ioc` reads/writes the file via group bit `rw`.
- Non-`ioc` user: dir mode `2770` + default ACL `o::---` blocks
  access.

V-C2 Case 1 runtime confirmation commands, ready for operator
execution:

```bash
# As an engineer in the ioc group:
sudo systemctl start epics-@testlab-tc32sim.service
sleep 2
stat -c '%U:%G %a' /var/log/procserv/testlab-tc32sim.log
# expected: ioc-srv:ioc 660
getfacl -p /var/log/procserv/testlab-tc32sim.log | grep -vE '^#'
# expected: user::rw-  group::rwx  group:ioc:rw-  mask::rw-  other::---

cat /var/log/procserv/testlab-tc32sim.log >/dev/null && echo "PASS: ioc engineer reads"
printf 'sentinel\n' >> /var/log/procserv/testlab-tc32sim.log && echo "PASS: ioc engineer writes"

# Negative probe (run as a user outside ioc):
sudo -u nobody cat /var/log/procserv/testlab-tc32sim.log 2>&1 | head -1
# expected: Permission denied

sudo systemctl stop epics-@testlab-tc32sim.service
```

### ACL pattern probe (isolated)

Before live verification, the `setfacl` recipe was probed in
`/tmp` to confirm the umask-override mechanism:

```
$ tmpdir=$(mktemp -d); chgrp ioc "$tmpdir"; chmod 2770 "$tmpdir"
$ setfacl -d -m g:ioc:rw "$tmpdir"
$ setfacl -d -m o::--- "$tmpdir"
$ setfacl -d -m m::rw "$tmpdir"
$ (umask 0022; touch "$tmpdir/engineer.log"); stat -c '%U:%G %a' "$tmpdir/engineer.log"
jeonglee:ioc 660
$ (umask 0007; touch "$tmpdir/procserv.log"); stat -c '%U:%G %a' "$tmpdir/procserv.log"
jeonglee:ioc 660
```

Both creators produced `*:ioc 660` regardless of umask. ACL
pattern verified before live deployment.

### Permanent regression

`bash tests/run-all-tests.bash --local` from the pre-1.1.0 suite
was not re-run in this Implementer session; the 1.0.x tests do
not exercise the new system log directory STEP or the local
template's `UMask=0027`. The Phase E expansion (T1-T5) is the
next milestone to incorporate runtime regression coverage of the
new permission model.

## Verification Not Performed

- Live `sudo systemctl start <ioc>` for a running IOC under
  `epics-@*.service` (V-C2 Case 1 runtime confirmation). Reason:
  sandbox blocks `sudo`. Inference from V-B-1 + V-C2 Case 2 +
  POSIX semantics is documented above; the explicit operator
  commands are ready in this handoff.
- Rocky 8.10 cross-distribution verification (`alsucl-psrv3` or
  baked variant). Reason: not part of this Implementer session;
  the next Rocky-side test run cycles through the same V-* set.
- NFS root_squash impact on `/var/log/procserv` (CC3). Reason:
  `top` is a local-disk host; the NFS scenario is covered by the
  later baked variant runs.

## Current Git State

- Branch: `release-1.1.0`, HEAD `9f569ea` (snapshot through Step
  0-R pass).
- Working tree:
  - Modified: `bin/setup-system-infra.bash`, `bin/ioc-runner`,
    `docs/TEST_PLAN-1.1.0.md`,
    `docs/review_sessions/20260514_100930_release-1.1.0/README.md`.
  - Untracked: `docs/LOG_PERMISSIONS.md`,
    `docs/review_sessions/20260514_100930_release-1.1.0/handoff/hand20260515_003138_*.md` (this artifact),
    `docs/review_sessions/20260514_100930_release-1.1.0/comments/cmt20260514_233353_002_*` (Step 0-R request),
    and prior Step 0-R round artifacts pending in this turn.
- No staged changes. No commit. No push.

## Implementation-Time Refinements (verbatim resolution)

- **R-PLAN3-2** (`mktemp` failure diagnostic for read-only home):
  `bin/ioc-runner` `deploy_local_template` now emits the
  following on `mktemp` failure:

  ```
  Error: Unable to create backup of existing user template.
    template: <path>
    Possible causes: <SYSTEMD_DIR> is read-only, the home directory is
      full, or the filesystem does not allow file creation here.
    Resolve the underlying condition and re-run 'ioc-runner --local install'.
  ```

  Diagnostic is the last output before `exit 1`. The prior
  template is left in place untouched.

- **R-PLAN3-5** (`setfacl` / `getfacl` preflight):
  `bin/setup-system-infra.bash` `--full` mode preflight loop:

  ```
  Error: Required tool 'setfacl' not found in PATH.
  Install the 'acl' package and re-run:
    Debian/Ubuntu: sudo apt install acl
    RHEL/Rocky/CentOS: sudo dnf install acl
  ```

  Preflight runs after `--full` argument is detected, before STEP
  1. Both `setfacl` and `getfacl` are required.

## Next Required Action

1. Reviewer 1 (codex_gpt5) Step 4-R review of this handoff:
   - `comments/cmt<ts>_codex_gpt5_to_claudecode_claude_opus_4_7_hand20260515_003138_ack.md`
     if findings are addressed.
   - `reviews/fup<ts>_codex_gpt5_on_hand20260515_003138.md` if
     any blocking issue remains. `F-HAND-N` ID convention.
2. After Reviewer 1 ack (Step 7 final-form recheck): User runs
   the phase commit per cadence (a) per-milestone. Commit message
   file + staging script will be prepared at that time.
3. After commit (Step 8) and Reviewer 1 Step 9 post-commit
   confirmation: P-B-3 (logrotate, #15) becomes the next
   milestone.

The Facilitator will publish the Step 4-R review request comment
in this same turn.
