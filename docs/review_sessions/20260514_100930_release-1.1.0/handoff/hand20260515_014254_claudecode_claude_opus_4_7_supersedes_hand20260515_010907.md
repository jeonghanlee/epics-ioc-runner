# Execution Handoff (Supersedes): Sudoers boundary narrowed per F-PLAN4-1

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: hand20260515_014254
Artifact Type: execution_handoff
Acting As Role: Implementer
Date: 2026-05-15
Start Time: 01:42:54
Finalized At: 2026-05-15 01:42:54
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: plan20260515_014254
Supersedes Artifact ID: hand20260515_010907
Implementer Agent ID: claudecode_claude_opus_4_7
Implementer Model: claude-opus-4-7
Based On: `plan/plan20260515_014254_claudecode_claude_opus_4_7_supersedes_plan20260515_010907.md`
Authorized By: `plan/auth20260514_235635_claudecode_claude_opus_4_7_for_user.md` (UD006 scope unchanged)
Step 4-R Fup: `reviews/fup20260515_011628_codex_gpt5_on_plan20260515_010907.md` (F-PLAN4-1)
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Implementer
- Role Source: `README.md` row 1 (Facilitator + Implementer dual role).
- Artifact Type Allowed: yes (only Implementer publishes
  execution_handoff; superseding form permitted).
- Target Path Allowed: yes (`handoff/`).
- Re-Anchor Trigger: Reviewer 1 fup `fup20260515_011628` raised
  F-PLAN4-1 (sudoers wording overstated). Plan was superseded
  to `plan20260515_014254`. This handoff aligns the
  implementation handoff text to the corrected plan wording. No
  code or runtime state changed; verification evidence carries
  forward verbatim.

## Supersession Reason

`hand20260515_010907` and `plan20260515_010907` both contained
the overstated sudoers wording flagged by F-PLAN4-1. The plan
was superseded by `plan20260515_014254` with narrowed wording.
This handoff supersedes `hand20260515_010907` so that the
implementation record cited against the active plan uses the
same narrowed wording.

No code, no runtime state, no V-* evidence is re-acquired. The
deltas relative to `hand20260515_010907` are wording-only in the
Implemented Decisions, Verification Performed (sudoers boundary
row), and Plan Item Mapping sections. All other content carries
forward identically.

## Implemented Decisions

- D-001..D-008 — log layout decoupled from journal; system log
  files at `${SYSTEM_LOG_DIR}/<ioc>.log`; local log files at
  `${LOCAL_LOG_DIR}/<ioc>.log`.
- D-006 / D-007 — Phase C2 verification matrix and per-phase
  verification commands consistent with the (b) permission model
  + narrowed sudoers boundary.
- (b) Revision — accept procServ open(0644) natural mode;
  default ACL `o::r--`; sudoers gates the privileged
  state-changing `systemctl` verbs that `ioc-runner` issues, not
  `ioc-runner` execution itself.
- **R-PLAN3-2** (`mktemp` failure / read-only home diagnostic):
  implemented in `bin/ioc-runner` `deploy_local_template`.
- **R-PLAN3-5** (`setfacl` / `getfacl` preflight): implemented
  in `bin/setup-system-infra.bash` `--full` mode preflight loop.
- **F-PLAN4-1 (this supersession)** — sudoers boundary wording
  narrowed: the policy gates privileged `systemctl` verbs only
  (`start` / `stop` / `restart` / `enable` / `disable` /
  `daemon-reload` + `status` on `epics-@*.service`). It does not
  gate `ioc-runner` process execution or read-only paths
  (`is-active`, `cat`, `show`) that `bin/ioc-runner` invokes
  without `sudo` in system mode.

## Completed Plan Items

Unchanged from `hand20260515_010907`. P-B-1, P-B-2, P-C2 against
the now-active `plan20260515_014254`.

## Plan Item Mapping

| Plan ID | Decision IDs | Files Changed (this combined milestone) | Verification | State |
| --- | --- | --- | --- | --- |
| P-B-1 | D-001..D-008; R-PLAN3-5; (b); F-PLAN4-1 wording | `bin/setup-system-infra.bash` (vars + preflight + STEP 4 install/setfacl with `o::r--` + STEP 5 unit heredoc with no `UMask=` and no `LogsDirectory=`); `docs/TEST_PLAN-1.1.0.md` (V-B-1, CC4, C2 matrix row narrowed); `docs/LOG_PERMISSIONS.md` (Access Boundary section narrowed) | V-B-1 passed live | implemented |
| P-B-2 | D-001..D-008; R-PLAN3-2 | `bin/ioc-runner` `deploy_local_template` (mktemp + diagnostic + heredoc `UMask=0027` + `--logfile=`); `do_install` local branch (`install -d -m 0750`); `docs/TEST_PLAN-1.1.0.md` (V-B-2) | V-B-2 passed live (carry-over from earlier round) | implemented |
| P-C2 | D-001, D-006, D-007; (b); F-PLAN4-1 wording | (verification only); `docs/TEST_PLAN-1.1.0.md` (Case 1 `0644`, Case 2 `0664`, narrowed sudoers row) | V-C2 Case 1 + Case 2 passed live; sudoers gate documented analytically with narrowed scope | implemented |

## Changed Files (working tree, this round of edits relative to hand20260515_010907)

| File | Change since hand20260515_010907 |
| --- | --- |
| `bin/setup-system-infra.bash` | No new edits |
| `bin/ioc-runner` | No new edits |
| `docs/TEST_PLAN-1.1.0.md` | Phase C2 matrix row "ioc-runner execution restricted ..." rewritten to "Privileged systemctl verbs ... gated by sudoers ..."; V-C2 wording narrowed to target a privileged systemctl call as the negative probe |
| `docs/LOG_PERMISSIONS.md` | "Access Boundary: sudoers Policy + File Mode" section rewritten with explicit scope (what it does / does not restrict); later passage on "wide read at file-mode layer only" similarly narrowed |

## Deviations From Plan

None. The implementation matches `plan20260515_014254` exactly.
The deltas from the prior plan (`plan20260515_010907`) are
wording-only and are documented in the plan's Supersession
Reason.

## Verification Performed

All V-* live evidence from `hand20260515_010907` carries forward
verbatim. The implementation behavior is unchanged; only the
description of the sudoers boundary changed.

### V-B-1 (carried over from hand20260515_010907)

```
$ grep -E '^(User|Group|UMask|ExecStart)=' /etc/systemd/system/epics-@.service
User=ioc-srv
Group=ioc
ExecStart=/usr/local/bin/procServ --foreground --logfile=/var/log/procserv/%i.log --name=%i --ignore=^D^C^] --chdir=${IOC_CHDIR} --port=${IOC_PORT} ${IOC_CMD}

$ grep LogsDirectory /etc/systemd/system/epics-@.service && echo FAIL || echo PASS: no LogsDirectory
PASS: no LogsDirectory

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

### V-C2 Case 1 (carried over)

```
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

### V-C2 Case 2 (carried over)

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

### V-B-2 (carried over from hand20260515_003138)

mktemp-based backup distinctness verified live earlier:

```
$ ls -1 ~/.config/systemd/user/epics-@.service.bak.*
/home/jeonglee/.config/systemd/user/epics-@.service.bak.GV9cZQzD
/home/jeonglee/.config/systemd/user/epics-@.service.bak.YcVItcdD
```

### sudoers boundary verification (narrowed per F-PLAN4-1)

The sudoers gate scope as actually enforced:

- `bin/setup-system-infra.bash:311-317` emits the policy with
  exactly seven privileged systemctl verbs on `epics-@*.service`.
- `bin/ioc-runner:280-291` `run_systemctl()` routes `is-active`,
  `status`, `cat`, `show` WITHOUT `sudo` in system mode; the
  other verbs use `sudo systemctl`.
- `bin/ioc-runner` does not perform a group-membership check at
  process startup.

Therefore the sudoers layer restricts only the privileged
state-changing verbs that `ioc-runner` issues, and only when
issued via `sudo` from a non-root caller. Non-`ioc` users can:

- Run `bin/ioc-runner` itself.
- Run `ioc-runner status`, `is-active`, `cat`, `show`
  (subject to systemd's own ACLs for those queries; typically
  permissive).
- Read log files under `o::r--` of the default ACL.

Non-`ioc` users cannot:

- Issue `start` / `stop` / `restart` / `enable` / `disable` /
  `daemon-reload` on `epics-@*.service` through `sudo`. The
  internal `sudo systemctl ...` call inside `ioc-runner` fails
  with `not allowed to execute`.

The negative verification probe is therefore a privileged
systemctl call, not `ioc-runner` execution itself:

```
# As a non-ioc user:
sudo /usr/bin/systemctl start epics-@<name>.service
# expected: ... not allowed to execute ...
```

Live runtime of this probe was not run in this Implementer
session (would require provisioning a test user outside `ioc`
and may interact with the existing testlab IOC). The negative
assertion follows directly from the sudoers policy text and the
sudo evaluation contract.

## Verification Not Performed

Unchanged from `hand20260515_010907`:

- Rocky 8.10 cross-distribution V-B-1/V-C2 — deferred to baked-
  variant test cycle.
- NFS `root_squash` CC3 — same deferral.
- Phase B-3 logrotate `create 0644 ioc-srv ioc` directive —
  separate milestone.

Additional this round:

- Live negative probe `sudo /usr/bin/systemctl start
  epics-@<name>.service` as a non-`ioc` user. Reason: the
  sudoers policy text encodes the assertion; visudo validated
  the policy in STEP 3. Adding a provisioned non-`ioc` test
  user is operational overhead disproportionate to the wording
  correction.

## Implementation-Time Refinements (verbatim resolution, unchanged)

R-PLAN3-2 and R-PLAN3-5 implementations are unchanged from
`hand20260515_010907`. Diagnostic strings carry forward verbatim.

## Current Git State

- Branch: `release-1.1.0`, HEAD `9f569ea`.
- Working tree:
  - Modified: `bin/setup-system-infra.bash`, `bin/ioc-runner`,
    `docs/TEST_PLAN-1.1.0.md` (Phase C2 matrix + V-C2 wording),
    `docs/review_sessions/20260514_100930_release-1.1.0/README.md`.
  - Untracked: `docs/LOG_PERMISSIONS.md` (with corrected Access
    Boundary section), this handoff, the corresponding plan
    supersession, and prior round session artifacts.
- No staged changes. No commit. No push.

## Next Required Action

1. Reviewer 1 re-review of `plan20260515_014254` +
   `hand20260515_014254`:
   - `comments/cmt<ts>_codex_gpt5_to_claudecode_claude_opus_4_7_..._ack.md`
     if F-PLAN4-1 wording correction is satisfactory.
   - `reviews/fup<ts>_codex_gpt5_on_hand20260515_014254.md` if
     any residual issue remains.
2. After Reviewer 1 ack: User runs the phase commit (Step 8)
   per cadence (a) per-milestone.
