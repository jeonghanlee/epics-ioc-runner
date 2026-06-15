# ADR 0001 — Restart Supervision: the C1+H bundle

- Status: **Accepted** (2026-06-15). Implementation is gated on authorization
  U001; the design is final.
- Scope: the systemd unit + procServ configuration that supervises every IOC in
  the template cluster (milestones M5-M11), emitted identically into the system
  and local-user modes by the single M5 template emitter.
- Supersedes: none. First ADR in this repository.

This record is self-contained: it states the chosen architecture, the
alternatives weighed against it, the evidence, and the consequences, so it
remains readable independently of any working session material.

---

## Context

Each IOC is run under **two nested supervisors**:

- **Layer 1 — procServ** autorestarts the IOC child process and keeps the
  console UNIX socket open across child deaths.
- **Layer 2 — `ioc-runner`** runs a post-action health check plus a
  procServ-log crash scan.
- **Layer 3 — systemd** manages the procServ process via a template unit
  (`epics-@<name>.service`).

Two defects in this model drove the decision:

1. **The Layer-3 hole.** A *dead procServ* (OOM, SIGKILL, crash) goes silently
   `inactive`. Nothing revives it and nothing reports `failed`; the IOC is down
   with no supervisor.
2. **The silent `^T` trap.** procServ's console "toggle autorestart" key (`^T`)
   turns Layer 1 off with a single, silent keystroke. With the nested model, a
   stray `^T` followed by a child death leaves a **dead child under a live
   procServ under an `active` unit** — down, with no alarm and no self-healing.

The solution had to close both defects **without sacrificing the operator
workflows the architecture documents as load-bearing**:

| ID | Operating requirement (source) |
| --- | --- |
| OP1 | In-band recovery with no sysadmin and no root password: any `ioc`-group engineer recovers a crashed IOC with `ioc-runner restart <name>`. The sudoers allowlist is exactly seven verbs (`start/stop/restart/status/enable/disable/daemon-reload`). A model that can strand a unit in `failed` needing `reset-failed` (outside the seven) reintroduces the sysadmin bottleneck. (FAQ Q1; ARCH 2.2) |
| OP2 | Console attach survives the crash/restart cycle (`ioc-runner attach`). (FAQ Q6 L1; Q10) |
| OP3 | Complete Layer 3 (revive a dead procServ) without collapsing Layer 1. (FAQ Q6) |
| OP4 | One template logic across both modes via the M5 emitter. (ARCH 3.2) |
| OP5 | KISS / DRY, dependency-free — prefer no new deployment artifact. (ARCH 1; 3.1) |
| OP6 | Debug-by-hand workflow intact (disable → stop → manual `st.cmd` → start → enable). (FAQ Q5) |
| OP7 | The procServ-log crash scan stays the operator's detection signal. (FAQ Q6 L2; Q7) |

---

## Decision

Adopt the operator-first **C1+H** bundle ("belt + harden"): complete Layer 3
with a systemd restart belt, and harden the `^T` trap, while keeping the
procServ inner loop. Emitted identically into both modes through the M5 emitter
(modulo the principled mode divergences: `Wants=`/`After=`, `User=`/`Group=`,
`UMask`, `WantedBy`, `Description`).

```
[Unit]
  StartLimitIntervalSec=0      # limiter disabled: a unit can never strand in `failed`
  StartLimitBurst=5            # inert while interval=0; emitted for explicitness
  StartLimitAction=none        # never a host-level action on an accelerator floor

[Service]
  Restart=always               # forced (not on-failure); see "Why each value"
  RestartSec=2                 # pace the procServ-restart loop; < the M11 health window
  SuccessExitStatus=0 1 2 15 143 SIGTERM SIGKILL   # unchanged under `always`
  ExecStart= … procServ --ignore=^D^C^] --autorestartcmd='' …
```

- `--ignore=^D^C^]` filters `^C`/`^D`/`^]` out of the **child IOC's stdin**.
- `--autorestartcmd=''` (empty argument) **disables the `^T` autorestart-toggle
  key** by setting procServ's toggle character to 0; the inner autorestart
  itself stays ON.

**Excluded:** `--oneshot`; an `OnFailure=` alarm unit.

### Why each value

| Knob | Value | Reason |
| --- | --- | --- |
| `Restart=` | `always` | Forced, not chosen: `SuccessExitStatus` classifies an OOM/SIGKILL procServ death as "success", so `on-failure` would not revive it. `always` revives on any death. |
| `RestartSec=` | `2` | Above systemd's 100 ms default so a fast-failing supervisor does not spin, but shorter than the M11 stabilization window so the health poll never reads the restart gap. |
| `StartLimitIntervalSec=` | `0` | Disabling the limiter makes OP1 absolute — a unit can never strand in `failed` needing `reset-failed`. The side effect (a hopeless procServ retries forever) is paced by `RestartSec`, bounded by logrotate, and is loud (`activating (auto-restart)`, `NRestarts`, health-check), never silent. |
| `StartLimitBurst=` / `StartLimitAction=` | `5` / `none` | Burst is inert while interval=0 (emitted for explicitness); a host-level action on an accelerator floor is never acceptable. |
| `--ignore` | `^D^C^]` | Filters control characters out of the child IOC's stdin. `^T` is intentionally NOT here — `--ignore` does not disable procServ command keys (see "Mechanism note"). |
| `--autorestartcmd=` | `''` | The mechanism that actually disables the `^T` toggle, closing the silent dead-child/live-procServ trap. |
| `--oneshot` | excluded | Breaks OP2 (drops the console socket on every child exit) and OP1 (its start-limit `failed` needs `reset-failed`). |
| `OnFailure=` | excluded | New infrastructure (OP5); under C1+H every down-state is loud or self-healing, so there is nothing silent left to alarm on. |

### Mechanism note (the corrected `^T` harden)

An earlier draft wrote `--ignore=^D^C^]^T`, on the belief that adding `^T` to
`--ignore` disables the autorestart toggle. **That is false**, confirmed by
measurement and by procServ source review (procServ 2.9.0-dev): `--ignore` /
`ignChars` only filters bytes forwarded to the child IOC's stdin
(`processClass::Send`). procServ's own console command keys — `^T` toggle, `^X`
kill, `^R` restart, `^Q` quit — are matched against the raw input in
`clientItem::processInput()` with no `ignChars` check, and procServ auto-adds
`^T`/`^X` to `ignChars` anyway. The working disable is `--autorestartcmd=''`,
which sets the toggle character to 0 so the guard `if (toggleRestartChar && …)`
short-circuits.

---

## Alternatives considered

`--oneshot` (C2) was carried only as the documented loser; the live contest was
C0 / C1 / C1+H.

| Option | What it is | Outcome |
| --- | --- | --- |
| **C0** | Today: nested supervisors, no `Restart=`, `--ignore=^D^C^]`. Both defects open. | rejected |
| **C1** | "Belt": add `Restart=always` + `StartLimitIntervalSec=0`. Closes the Layer-3 hole; `^T` trap stays open. | rejected |
| **C1+H** | C1 plus close the `^T` trap (via `--autorestartcmd=''`). | **chosen** |
| **C2** | `--oneshot`: drop the procServ inner loop; systemd restarts procServ per child life. Closes Layer 3 by replacing Layer 1. | excluded |

### Scoring (operator-first weights)

Cells `-2..+2`; weights set so operator-facing workflows dominate (cell 4
console and OP1 recovery at top; truthful-state demoted as non-operator-facing).

| # | Criterion | w | C0 | C1 | C1+H |
| --- | --- | :---: | :---: | :---: | :---: |
| 1 | Availability across the 4 initiators | 5 | +1 | +2 | +2 |
| 2 | In-band recovery within the 7-verb allowlist | 5 | +2 | +2 | +2 |
| 3 | Truthful systemd state / `NRestarts` | 1 | -2 | -1 | -1 |
| 4 | Console continuity (attach survives restart) | 5 | +2 | +2 | +2 |
| 5 | start-limit safety under legitimate bursts | 4 | +2 | +2 | +2 |
| 6 | procServ-death coverage | 4 | -2 | +2 | +2 |
| 7 | **Silent `^T` trap closed** | 3 | -2 | -2 | **+2** |
| 8 | Impl scope fits cluster | 3 | +2 | +1 | +1 |
| 9 | Deployment surface / KISS-DRY | 4 | +2 | +2 | +2 |
| 10 | Reversibility | 2 | +2 | +2 | +2 |
| 11 | Detection simplicity (M11) | 2 | 0 | +1 | +1 |
| | **Weighted total (/76)** | | **35** | **56** | **68** |

**C1+H (68) > C1 (56) > C0 (35); C2 ≈ -23 (excluded).** The entire
C1+H-over-C1 margin is cell 7 (the `^T` trap, 12 weighted points); every other
criterion converged. The decision was therefore narrow: close the `^T` trap,
using a mechanism that does not break OP1/OP2.

### Cost / trade comparison

| Cost axis | C0 | C1 | **C1+H** | C2 |
| --- | --- | --- | --- | --- |
| Recovery of a dead procServ | none (silent) | automatic | automatic | automatic |
| Recovery verb (operator) | in 7 verbs | in 7 verbs | in 7 verbs | **needs `reset-failed`** |
| Live console during restarts | preserved | preserved | preserved | **destroyed** |
| `^T` foot-gun | open | open | **closed** | n/a |
| New deployment artifact | none | none | none | alarm unit (against OP5) |
| Implementation scope | — | `Restart=` | `Restart=` + one procServ arg | `Restart=` + alarm + workflow rewrite |
| Local-mode log growth | unbounded | unbounded | bounded by rotation | bounded |
| procServ-death recovery latency | ∞ | ~96 s | ~96 s → seconds w/ the M10 fix | per-life cost |
| Reversibility | — | high | high | low |

C1+H adds the least over C1 (one procServ argument) and is the only live option
that closes the `^T` trap. C2's apparent simplicity hides the two largest
operational costs (broken console, `reset-failed` recovery) plus a new artifact.

---

## Evidence

Validated on both golden testbeds — **rocky8-iocrunner (Rocky 8.10, systemd
239)** and **debian13-iocrunner (Debian 13, systemd 257)**, procServ 2.9.0-dev
on each.

| Check | Result (both goldens) |
| --- | --- |
| `^T` harden | `--ignore=^T` does NOT disable the toggle; **`--autorestartcmd=''` does** |
| Layer-3 belt | a killed procServ is revived by `Restart=always` |
| procServ-death latency | **~96 s** (TimeoutStopSec-gated) — drives the `KillMode` consequence below |
| OP1 stop semantics | an admin `stop` stays inactive (not revived) |
| OP2 console | console survives a child crash/restart (EOFs only on procServ death) |
| Assert-gated unit | an `Assert*=` failure = `inactive`/`success` (not `failed`, not in `--failed`); a plain `systemctl restart` recovers it in-band, no `reset-failed` |
| local log growth | broken-IOC crash loop ≈ **5 MB/day**, under the 16.7 MB/day budget |
| logrotate | `copytruncate` works against the fd-holding procServ; plain `create` silently breaks |

Version facts: every directive is valid on systemd 239 and 257; support floor
is **systemd 229** (`StartLimit*` introduced v229). **`StartLimit*` must be in
`[Unit]`** — a `[Service]` placement is silently rejected (`Unknown lvalue`),
observed live on systemd 239.

---

## Consequences

**Preserved:** OP1 (in-band recovery within the seven verbs; `reset-failed`
never needed), OP2 (console continuity), OP3 (Layer 3 completed, Layer 1 kept),
OP4-OP7.

**Required follow-on design (settled):**

- **`KillMode=mixed` or a shorter `TimeoutStopSec` in M10.** procServ execs its
  child with SIGTERM blocked, so on procServ death `KillMode=control-group`'s
  cleanup stalls the full `TimeoutStopSec` (90 s) before `Restart=always` fires
  — measured ~96 s. The M10 unit must reduce this to seconds.
- **A local-mode log size-cap / rotation** (`copytruncate`). Local mode has no
  rotation today; the per-IOC budget is 16.7 MB/day (10 GB area × 0.5 margin /
  10 IOC / 30 d). The common broken-IOC case is ~5 MB/day, so rotation is
  prudent insurance covering the verbose / long-outage / multi-failure tail.

**Accepted trade-off:** `--autorestartcmd=''` removes the operator's console
autorestart toggle. Maintenance autorestart-stop now goes through the operation
verbs (`ioc-runner` / `systemctl stop`, OP1), not a console keystroke.

**Monitoring note:** an `Assert*=`-gated unit that fails its assert is
`inactive`, not `failed`, and is invisible to `systemctl --failed`. If the
cluster ever gates a unit on an `Assert*=`, health monitoring must check
`ActiveState` / the start exit code, not just `--failed`.

---

## Implementation plan

Gate: **U001** authorizes this bundle (and the M10/M11 coupling and the
confirmation activity) for M8-M11 execution. M5 authorization is already in
force.

1. **M5** — the single template emitter emits the procServ command line
   (`--ignore=^D^C^]`, `--autorestartcmd=''`) and the systemd rows identically
   into both modes; the M5 dual guard pins them as must-agree rows and adds a
   `systemd-analyze verify` cell. Pure-refactor first step.
2. **M8** — run the confirmation checks (above) on both goldens as the
   acceptance gate.
3. **M11 before M10, one joint cutover gate.** The polling health check (M11)
   lands first — safe and beneficial even under C0; it must treat
   `activating (auto-restart)` as not-settled, be `RestartSec`-aware, keep a
   measured (not inherited) minimum stabilization window, and treat `failed` as
   non-terminal. Then `Restart=` (M10) lands onto the poll-aware wrapper,
   including the `KillMode`/`TimeoutStopSec` fix.
4. **Documentation, with the code:** `ARCHITECTURE.md` (systemd ≥ 239 floor;
   `StartLimit*` in `[Unit]` vs `Restart*` in `[Service]`); `INSTALL.md`
   (systemd prerequisite; sync the triplicated `--ignore` string); `FAQ.md` +
   `ioc-runner` help (console-control change: `^T` toggle removed, `^X` kept).

**Out of scope for U001:** `--oneshot`, an `OnFailure=` alarm unit, any
sudoers-surface change (`reset-failed` stays out — #68/M12), and M12-M15.

---

## References

The full working record (scoring derivation, operating-intent grounding,
ten-reviewer convergence, and the raw measurement campaign) was produced in
review session `rs20260612_143435`. Key facts are inlined above so this ADR
stands alone.
