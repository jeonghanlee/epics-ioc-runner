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

> **Correction note (2026-06-16, per Round 11 review / convergence C004,
> `conv20260615_184033`).** The `RestartSec` and `StartLimitIntervalSec`
> rationale below is corrected; the decision (C1+H, `--autorestartcmd=''`) is
> unchanged and the Status stays Accepted. Two directives settled after this ADR
> was first drafted are part of the current emitted unit: `KillMode=mixed` (see
> Consequences) and `RuntimeDirectoryPreserve=restart` (the console-socket
> directory is kept across an auto-restart). The full current directive set is in
> C004.
>
> **Mechanism (2026-06-16, #81 option 3):** M5/#81 is examined-Keep + a
> shared-contract guard, NOT a single emitter (the runner is self-contained —
> cf. CI-15; see register CI-4). Read "the single M5 template emitter" / "via
> the M5 emitter" below as the guarded two-copy contract — identical in both
> modes, enforced by the guard. (C005 `conv20260616_002157` supersedes C004.)

> **Addendum (2026-07-07, M5/#108, commit `04f18dc`).** The
> `RuntimeDirectoryPreserve=restart` emission described in the C004/C005
> notes above is now actually emitted by both template writers
> (`bin/setup-system-infra.bash` and `bin/ioc-runner`) and pinned by the
> shared-contract guard. Between the C004 note (2026-06-16) and this commit
> the directive was documented intent only — the 1.2.0 templates did not
> carry it (found as R10 RA-1 in the 1.2.0 full-code review; adopted as U-1).
> Preserve semantics verified on systemd 239 `--user`.
>
> **Trust note (U-9, same review):** the M11 readiness poll and crash scan
> trust the procServ log's content — the readiness marker
> (`All initialization complete`) and the crash tokens are accepted from
> whatever the supervised IOC writes. The log is a cooperative signal from
> the operator's own IOC, not an adversarial input; an `st.cmd` that prints
> the marker without initializing defeats readiness detection by design,
> and no integrity check on the marker is planned.

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
`UMask`, `WantedBy`, `Description`). The `Wants=`/`After=` divergence is
structural, not an omission: the system unit orders against `network.target`,
`remote-fs.target`, and `time-sync.target`, none of which exist in the
`systemctl --user` instance, so the local unit cannot name them; its
`basic.target` ordering is supplied implicitly by `DefaultDependencies=yes`.
(Confirmed by the M9/#53 ordering review, rs20260623_095055 — examined-Keep on
`Requires`/`Wants`/`Before`/`After`.)

```
[Unit]
  StartLimitIntervalSec=0      # limiter disabled: a unit can never strand in `failed`
  StartLimitBurst=5            # inert while interval=0; emitted for explicitness
  StartLimitAction=none        # never a host-level action on an accelerator floor

[Service]
  Restart=always               # forced (not on-failure); see "Why each value"
  RestartSec=2                 # pace the loop; the M11 poll (not RestartSec) owns the timing
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
| `RestartSec=` | `2` | Above systemd's 100 ms default so a fast-failing supervisor does not spin. The timing invariant lives in the M11 poll (poll max-bound > RestartSec + readiness time), not in RestartSec being below the window. |
| `StartLimitIntervalSec=` | `0` | Disabling the limiter keeps OP1 in-band — a unit never strands in the `reset-failed`-requiring start-limit-hit state. Honest trade: no automatic circuit breaker (a hopeless procServ retries forever). systemd surfaces only procServ death (`activating (auto-restart)`, `NRestarts`); a child crash loop is caught by the Layer-2 log scan, and a `=0` loop is invisible to `systemctl --failed`. Log growth is bounded by the U003 local rotation, not by `=0`. |
| `StartLimitBurst=` / `StartLimitAction=` | `5` / `none` | Burst is inert while interval=0 (emitted for explicitness); a host-level action on an accelerator floor is never acceptable. |
| `--ignore` | `^D^C^]` | Filters control characters out of the child IOC's stdin. `^T` is intentionally NOT here — `--ignore` does not disable procServ command keys (see "Mechanism note"). |
| `--autorestartcmd=` | `''` | The mechanism that actually disables the `^T` toggle, closing the silent dead-child/live-procServ trap. |
| `--oneshot` | excluded | Breaks OP2 (drops the console socket on every child exit) and OP1 (its start-limit `failed` needs `reset-failed`). |
| `OnFailure=` | excluded | New infrastructure (OP5); down-states are covered by Layer-3 revival and the Layer-2 crash scan (a silent hang is tracked as an out-of-cluster carry-forward, not an alarm-unit case), so an alarm unit adds deployment surface without closing a real gap. |

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

### Unit ordering and dependencies (M9 / #53)

The `[Unit]` ordering/dependency directives were reviewed separately (M9/#53,
**examined-Keep on all four** of `Requires`/`Wants`/`Before`/`After`; 5-reviewer
convergence `rs20260623_095055`, no code change). The system unit carries
`Wants=time-sync.target` + `After=network.target remote-fs.target
time-sync.target` and no `Requires=`/`Before=`; the local user unit carries no
ordering at all. Both are deliberate — the reasons and the rejected scenarios:

- **No `Requires=` (Q1).** `Requires=` carries no start ordering (that is
  `After=`'s role per `systemd.unit(5)`), so it adds nothing on the start side;
  its stop-propagation would couple a running IOC's lifetime to a passive
  target. Concrete hazard: `Requires=remote-fs.target` on a control IOC means a
  transient NFS-server blip *stops the live IOC* — converting a degraded
  file-access condition into a loss of control, and amplifying one NFS outage
  into mass IOC teardown across the floor. The one hard startup prerequisite
  (the conf file) is gated by `AssertFileNotEmpty=` instead, which gates *start*
  without coupling *teardown*. Passive `.target` units are ordered with
  `After=`, never bound with `Requires=`.

- **No `network-online.target` (Q2) — the rejected scenario, recorded so it is
  not re-opened.** The apparent case: a CA/PVA server binds network addresses,
  and `After=network.target` is a passive sync point that does not guarantee an
  address is configured; the documented pattern for "needs an address at start"
  is `Wants=` + `After=network-online.target`. Rejected on four grounds:
  (1) the EPICS CA server (`rsrv`) and the PVA server bind the **wildcard
  address** (`INADDR_ANY`), not a specific interface, so the listener accepts
  connections on addresses configured after start; (2) discovery is **pull as
  well as push** — the IOC answers inbound UDP name searches on the interface
  that received them, so connectivity does not depend on the outbound beacon
  address list being correct at start; (3) `network-online.target` is a **weak
  guarantee on this project's multi-homed hosts** (Service / PVA-CA / Access
  subnets) — wait-online can report "online" on one interface while the
  PVA-bearing one is still coming up, so it would not even reliably fix the
  enumeration it appears to fix; (4) it pulls in `*-wait-online`, a
  **per-instance boot-time regression** (long timeouts / hangs on no-carrier or
  multi-homed interfaces) imposed on every enabled IOC. `nss-lookup.target` does
  not apply (address lists are IP/broadcast; CA/PVA self-identity uses
  `gethostname()`, not a blocking DNS lookup at start). The source-on-NFS need
  is already met by the `remote-fs.target` already present in `After=`.
  - **Operational escape hatch:** a site that genuinely needs early beacon
    interface-enumeration on a reliably-late-addressed interface adds a
    **per-host systemd drop-in**
    (`…/epics-@<inst>.service.d/*.conf` with `Wants=`/`After=network-online.target`),
    decided per host — not a template default.

- **Local user unit carries no ordering (Q3).** See the Decision paragraph
  above: the system targets do not exist in the `systemctl --user` instance, so
  copying them would be dead text; `basic.target` ordering is implicit via
  `DefaultDependencies=yes`; the unit is a leaf with no peer user unit, and the
  NFS-home prerequisite is satisfied (via PAM/login) before `systemd --user`
  starts.

- **No `Before=` (Q4).** `Before=` is warranted only when a consumer unit must
  start after the IOC. EPICS CA/PVA is asynchronous and late-binding: clients
  (OPIs, archivers, gateways) search and reconnect whenever the server appears,
  in any order, and are typically off-host and independently supervised;
  same-host in-process consumers (autosave, sequencer) run inside the IOC via
  `st.cmd`, not as separate units. A `Before=` would assert an ordering the
  protocol does not need and couple unrelated lifecycles.

### Startup poll classification (M11 / #67)

`do_start_restart` replaces the former fixed `sleep 5` + single state read with
an **active-state poll of the procServ log** for the readiness marker
`All initialization complete` (10-round design, plan v9; 5 OQ measurements both
goldens; 3 code-review rounds; closure `rs20260617_170153`). The classification
rules and the reasons they were chosen:

- **Why poll, not `sleep 5`.** The M8/#52 census measured healthy
  procServ-fork → readiness at **~0.82 s** for a no-device IOC (both goldens), so
  `sleep 5` was both too slow for the common case and, worse, **unsafe**: a unit
  crash-looping under `Restart=` (M10) can momentarily read `active` at second 5
  and pass (the original #67 defect). The poll waits for the marker, not a fixed
  duration, and treats `activating (auto-restart)` as not-settled.

- **Token partition.** `CRASH_LOG_PATTERNS` = `CRASH_LOG_PATTERNS_FATAL` (5) |
  `CRASH_LOG_PATTERNS_AMBIGUOUS` (5); the base set is the union (set-equal,
  guard-pinned — register CI-22). The split lets a pre-marker **fatal** token
  fail fast (exit 1) while an **ambiguous** token does not, by itself, condemn a
  start that otherwise reaches the marker.

- **D031 — `Invalid directory path` reclassified fatal → ambiguous.**
  Golden-confirmed as a **benign EPICS pre-iocInit warning** (an IOC printing it
  still initializes), so classifying it fatal produced false start failures.
  Moved to the ambiguous subset; the base 10-token union is unchanged, so the
  crash-scan coverage CI-22 pins is unaffected.

- **D034 — marker-less-but-active → Warning, exit 0.** An IOC that reaches
  `active` but never emits the readiness marker (e.g. a custom `st.cmd` that does
  not call `iocInit`) must not be reported as a failure — the operator's IOC is
  running. The poll emits a Warning and exits 0 rather than condemning a live IOC
  on a missing string.

- **D035 — verb-aware teardown (OQ6).** Measured on both goldens: the teardown
  path differs by verb, so the poll's failure handling is verb-aware, not uniform.

- **Recurring death banner (≥ 2) → crash-loop.** A **silent** pre-iocInit crash
  loop (child killed by signal, no fatal token) emits no fatal string; it is
  caught by counting the recurring death banner `@@@ Child process is shutting
  down` (≥ 2 → exit 1). This is the M8/#52 silent-loop disposition.

- **Post-marker dwell (~3 s).** After the marker, a short dwell catches an IOC
  that initializes then immediately crash-loops (post-marker banner → exit 1). A
  `start` on an already-running IOC short-circuits via a clean-tail check.

The literals (`All initialization complete`, `@@@ Child process is shutting
down`) and the fatal/ambiguous partition must agree across `bin/ioc-runner`, the
tests, and the docs; the agreement is **guard-pinned** (CI-22:
`verify_base_subset_union` set-equality + `verify_match_subset` membership), not
refactored, because the `test-error-handling.bash` scraper reads the script as
text and cannot expand a derived form.

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

Version facts: every directive is valid on systemd 239 and 257. The `StartLimit*`
directive-support floor is **systemd 229**; `RuntimeDirectoryPreserve=restart`
raises the directive-support floor to **v235**, still well under the **v239**
deployment floor. **`StartLimit*` must be in `[Unit]`** — a `[Service]` placement
is silently rejected (`Unknown lvalue`), observed live on systemd 239.

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
   (systemd prerequisite; sync the triplicated `--autorestartcmd=''` token — the
   `--ignore` string is unchanged; the manual-setup unit needs the full C1+H
   `[Unit]`/`[Service]` set); `FAQ.md` +
   `ioc-runner` help (console-control change: `^T` toggle removed, `^X` kept).

**Out of scope for U001:** `--oneshot`, an `OnFailure=` alarm unit, any
sudoers-surface change (`reset-failed` stays out — #68/M12), and M12-M15.

---

## References

The full working record (scoring derivation, operating-intent grounding,
ten-reviewer convergence, and the raw measurement campaign) was produced in
review session `rs20260612_143435`. Key facts are inlined above so this ADR
stands alone.
