# Development Plan (Supersedes): Narrow sudoers boundary wording per F-PLAN4-1

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: plan20260515_014254
Artifact Type: development_plan
Acting As Role: Implementer
Date: 2026-05-15
Start Time: 01:42:54
Finalized At: 2026-05-15 01:42:54
Author Agent ID: claudecode_claude_opus_4_7
Author Transport: claude_code
Author Model: claude-opus-4-7
Target Artifact ID: conv20260514_112923
Supersedes Artifact ID: plan20260515_010907
Implementer Agent ID: claudecode_claude_opus_4_7
Implementer Model: claude-opus-4-7
Based On Artifact ID: conv20260514_112923
Based On: `convergence/conv20260514_112923_claudecode_claude_opus_4_7.md`
Revision Inputs:
  - `reviews/fup20260515_011628_codex_gpt5_on_plan20260515_010907.md` (F-PLAN4-1)
  - User direction 2026-05-15 ("a") authorizing the formal supersession path
Skill References: `agent-review-convergence`, `markdown-authoring`, `technical-discussion`

## Role Assertion

- Agent: claudecode_claude_opus_4_7
- Acting As: Implementer
- Role Source: `README.md` row 1 (Facilitator + Implementer dual role).
- Artifact Type Allowed: yes (only Implementer publishes
  development_plan; superseding form permitted).
- Target Path Allowed: yes (`plan/`).
- Re-Anchor Trigger: Reviewer 1 follow-up `fup20260515_011628`
  identified F-PLAN4-1 as blocking for Step 0-R + Step 4-R
  acceptance; User direction "a" chose the formal supersession
  path over the lighter targeted-correction comment.

## Inheritance (explicit)

This is a delta-style superseding development_plan against
`plan20260515_010907`. Wording-only revision; no code-side
intent changes.

**Inherited unchanged from plan20260515_010907:**

- Header up to `## Inheritance`.
- The implementation deltas relative to `plan20260514_233353`:
  (a) `setfacl -d -m o::---` → `o::r--`; (b) unit heredoc
  `UMask=0007` line removed. These deltas are already in the
  working tree and have been verified live.
- End-state mode targets: `root:ioc 2770` directory; procServ-
  created log `ioc-srv:ioc 0644`; engineer-touch file
  `<engineer>:ioc 0664`; local-mode unchanged at `<user>:<user> 0640`.
- Plan Item Matrix (P-A, P-Readiness, P-B-1, P-B-2, P-B-3, P-C1,
  P-C2, P-D-1, P-D-2, P-D+, P-E, P-F-1, P-F-2, P-F-3, P-G).
- Authorization Scope (combined P-B-1 + P-B-2 + P-C2 under
  `auth20260514_235635`; no fresh User authorization required for
  this wording-only supersession).
- Recovery Boundary (pre-commit / post-commit split).
- Implementation-Time Refinements (R-PLAN3-2 `mktemp` diagnostic,
  R-PLAN3-5 `setfacl`/`getfacl` preflight).

**Revised in this artifact (sections below):**

- `## Permission Model` — Access boundary description narrowed
  to match the actual sudoers scope.
- Verification narrative — negative probe target narrowed to a
  privileged systemctl invocation.

**Unchanged code surface:** `bin/setup-system-infra.bash` and
`bin/ioc-runner` are not edited as part of this supersession.

## Supersession Reason

`fup20260515_011628` raised F-PLAN4-1 as blocking. The
finding text (verbatim):

> The revised permission model is technically coherent if the
> sudoers layer is described as the gate for privileged
> system-mode state changes. However, the current plan, test
> plan, handoff, and `LOG_PERMISSIONS.md` repeatedly describe
> sudoers as if it restricts `ioc-runner` execution or all
> system-mode operations to `%ioc`. That is broader than the
> code actually enforces.

Reviewer 1 evidence cited:

- `bin/setup-system-infra.bash` emits sudoers rules only for
  privileged `systemctl` verbs on `epics-@*.service`.
- `bin/ioc-runner` does not check group membership before
  executing.
- `bin/ioc-runner` calls `systemctl status`, `cat`, `show`, and
  `is-active` without `sudo` in system mode.
- Therefore sudoers does not prevent a non-`ioc` user from
  invoking `ioc-runner` itself or running read-only status-style
  paths.

The Facilitator concurs. The prior plan's wording was overstated.
This supersession narrows the description to what the code
actually enforces.

## Permission Model (revised — wording only)

End-state mode targets are unchanged from `plan20260515_010907`.
Only the access boundary description changes.

| Object | Owner:Group | Mode | Default ACL | Creator |
| --- | --- | --- | --- | --- |
| `${SYSTEM_LOG_DIR}/` | `root:ioc` | `2770` (setgid) | `g:ioc:rw`, `o::r--`, `m::rw` | `setup-system-infra.bash` install-time |
| `${SYSTEM_LOG_DIR}/<ioc>.log` (procServ) | `ioc-srv:ioc` | `0644` | (inherited; mask `r--`) | procServ at IOC start |
| `${SYSTEM_LOG_DIR}/<adhoc>` (engineer touch) | `<engineer>:ioc` | `0664` | (inherited; mask `rw-`) | engineer's shell `touch` |

### Access boundary, narrowed

| Layer | Mechanism | What it actually restricts |
| --- | --- | --- |
| 1 (sudoers) | `/etc/sudoers.d/10-epics-ioc`: `%ioc ALL=(root) NOPASSWD: /usr/bin/systemctl start|stop|restart|status|enable|disable|daemon-reload epics-@*.service` | The `sudo systemctl <verb> epics-@*.service` invocations that `ioc-runner` makes internally for state-changing operations. Non-`ioc` users get rejected at the `sudo` gate inside `ioc-runner` when they attempt `start` / `stop` / `restart` / `enable` / `disable` / install / remove. |
| 2 (file mode + default ACL) | `2770` directory + `0644`/`0664` file mode | procServ writes (owner); `ioc` group reads (group bit + ACL); other reads (other bit). Engineer-created files in dir gain `ioc` group write via default ACL. |

### What the sudoers layer does NOT restrict (per F-PLAN4-1)

- Execution of `bin/ioc-runner` itself. Any user with shell
  access can invoke the script.
- `ioc-runner status`, `is-active`, `cat`, `show` — these are
  implemented in `bin/ioc-runner` `run_systemctl()` without
  going through `sudo` for system mode (see lines 280-291 of
  `bin/ioc-runner`).
- Direct file system reads on the log directory and log files.
  These are governed by Layer 2.

### Implication for operators outside the `ioc` group

A user outside the `ioc` group on a host with this deployment can:

- Invoke `ioc-runner <verb>` for read-only verbs (`status`,
  `is-active`, etc.) — the call may still succeed or fail
  depending on systemd's own ACL for that verb, but `sudo` is
  not involved.
- `cat` log files directly under `o::r--` of the default ACL.
- NOT start, stop, restart, enable, disable, install, or remove
  IOCs through `ioc-runner` — the internal `sudo systemctl ...`
  call is rejected.

This is the precise scope. The prior plan's wording overstated
the sudoers reach to "ioc-runner execution itself".

## Revised Sections (verification narrative only)

### V-B-1 (unchanged)

System unit text + dir state + default ACL assertions remain as
in `plan20260515_010907`. No edits.

### V-C2 (negative probe narrowed)

The Phase C2 matrix and V-C2 wording in
`docs/TEST_PLAN-1.1.0.md` were updated in the working tree this
turn:

- Phase C2 matrix row "Privileged `systemctl` verbs ... gated by
  sudoers ..." replaces the prior "ioc-runner execution
  restricted ..." row.
- V-C2 wording: negative probe is `sudo /usr/bin/systemctl start
  epics-@<name>.service` as a non-`ioc` user (expected exit
  with "not allowed to execute"), not generic `ioc-runner`
  invocation.

`docs/LOG_PERMISSIONS.md` "Access Boundary" section was
rewritten this turn with the narrowed scope.

## Plan Item Matrix Delta

No cells differ from `plan20260515_010907`. The supersession is
wording-only; the matrix is unchanged.

## Authorization Scope This Plan Asks For

Unchanged. `auth20260514_235635` (combined P-B-1 + P-B-2 + P-C2)
covers the implementation; the (b) revision and the F-PLAN4-1
wording correction are both within the authorized boundary.

## Recovery Boundary

Inherited from `plan20260515_010907`. Pre-commit / post-commit
split unchanged.
