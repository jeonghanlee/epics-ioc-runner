# EPICS IOC Runner — Milestone Register

Single, unified, repository-local source of truth for milestone and
carry-forward status. Every agent and contributor reads this file instead of
chat history or memory. GitHub milestone state and issue `Closes`/`Refs`
footers are authoritative; this register reconciles them into one readable
view.

**Release convention:** this is one unified register, not a per-version file.
On each release the register is cleared and restarted for the next cycle; the
released milestone's full record is preserved in the matching git tag
(`git show <tag>:docs/milestone.md`). Released versions are therefore not
retained in this file.

**1.2.0 release target:** 2026-07-31, per the GitHub milestone `1.2.0` due
date. 1.1.1 was released 2026-06-11 (merge `25f6adc`, tag `1.1.1`,
GitHub release with curated notes from the changelog, milestone closed,
`release-1.1.0` branch deleted per the two-releases-back retention rule).

**Next session entry point:** U001 — authorize the C1+H restart-supervision
strategy — then M5 (#81) opens the template and guard-test cluster (M5-M11).
The strategy is decided in review session rs20260612_143435 (local-only root
`docs/review_sessions/20260612_143435_template_cluster_strategy/`): the
C2/`--oneshot` direction was withdrawn; the operator-first **C1+H** bundle
(`Restart=always` + `StartLimitIntervalSec=0`, both modes via the M5 emitter;
no `--oneshot`, no alarm unit) was confirmed by a ten-reviewer Round 4
(convergence C003, `conv20260614_081643`). Eight open decisions **U001-U008**
(see "Open strategy decisions" below) precede execution; the empirical
measurements feeding them are M8.E1-E4 (E1/E2 done) plus the full-scale
confirmatory campaign (res20260614_210000, both goldens). **The campaign
overturned the bundle's `^T` harden: `--ignore=^T` does NOT disable the
autorestart toggle; the real mechanism is `--autorestartcmd=''` — DECIDED
2026-06-15 (U006), emitted by M5; the converged amendment text still needs that
correction at U001.** The durable architecture record is the tracked ADR
`docs/adr/0001-restart-supervision-c1h.md` (Accepted 2026-06-15; matrix,
cost/trade, alternatives, evidence, application plan, self-contained); the
session-local capstone `14_decision_summary_c1h.md` (ds20260615_093000) is its
working origin.
Note the **M10/M11 reversal**: the polling health check (M11) lands BEFORE
`Restart=` (M10). The standalone items M1-M4 (#92 fix `0baa9df`, #93 fix
`1e051ec`, #94 fix `1e6cdbc`, #87 fix `234a580`) closed 2026-06-12, each
verified on both goldens; M15 (#98, fix `36ad023`) was pulled forward and
closed the same day, so the error suite counts are trustworthy for the
cluster's guard tests. M5 re-runs
the M4 guard per the dependency matrix. The 1.2.0 work order M1-M12 was set
2026-06-11: standalone items first (M1-M4), then the template and guard-test
cluster (M5-M11), then the #68 wrapper design (M12). Cluster-internal order
is grounded in the issue records: #81 (M5) runs first as a pure refactor
gated by its own byte-equivalence acceptance criterion, so #53/#54 land
afterward as one-place content edits through the single emitter; #84 (M6)
folds its guard test with #81 while the emitter contract is fresh
(CI-10/CI-14 drift guards may join); #86 (M7) rides the same helper-contract
review; #52's exit-signal review (M8) feeds the #54 `Restart=` decision
(M10); #67's polling design (M11) — **reversed under C1+H: M11 lands before
M10** (poll-first, then `Restart=`, joint cutover gate), because the
`Restart=always` auto-restart would make the old single `is-active` read
misfire. The #68 wrapper (M12) owns the
sudoers verb-scope questions (examined-Keep CI-20/CI-21 cluster there).
The cycle test plan is `testplan_1.2.0.md` (per-milestone verification,
dependency re-run matrix, release-gate sequence); the multi-user plan was
renamed to `testplan_multiuser.md` as the standing release-gate step.
Each milestone carries its verification as `M<n>.T<k>` subs in the Active
Register, and M16 (release gate, no GitHub issue) closes the cycle. The
gate renumbers to stay on the last number as cycle-added items join:
M13 (#96) added 2026-06-11 from the M1 design review; M14 (#97) and M15
(#98) added 2026-06-12 from the M2 sweep.
Version is `1.2.0-dev` (`bin/ioc-runner:14`).

## Active Register

Each milestone row is followed by its verification subs (`M<n>.T<k>`):
T1 = change-specific verification, T2 = suite/regression cases, T3 =
re-run of an earlier milestone's verification on a shared surface, T4 =
amendment of the standing multi-user plan. Sub procedures are defined in
[`testplan_1.2.0.md`](testplan_1.2.0.md). Each issue carries the same
subs as a checkbox list in its Verification section on GitHub — GitHub
is authoritative for sub status; this register mirrors it, the Evidence
column of a sub is filled at completion, and every milestone closure
ends with a reconcile pass comparing issue state against this register.

| M | Topic | Work unit | Type | Status | Evidence or next action |
| :--- | :--- | :--- | :--- | :--- | :--- |
| M1 | 1.2.0 | #92 crash-warning false positive after a manual `st.cmd` run | Run finding (#91, S7 / F-M2-1) | Done | Closed 2026-06-12. Design Record in #92 (three-reviewer session rs20260611_163202): line-targeted `CRASH_LOG_EXCLUDE_PATTERNS` pre-filter + FAQ Q5 corrected knob (`EPICS_IOCSH_HISTFILE=/dev/null`). Fix `0baa9df`; T1/T2 verified on both goldens; verification record in the issue body. bug, P3-low. |
| M1.T1 | 1.2.0 | reproduce the cross-owned `.iocsh_history` warning on a VM golden; no warning after the fix | Test sub | Done | PASS 2026-06-12, both goldens, system mode: service run naturally leaves `ioc-srv:ioc 0600`; operator manual run prints the benign `ERROR` and leaves `opa:ioc 0600`; subsequent `start` raises no warning. Raw-byte pin: exclusion regex matches exactly 1 line per real log (ANSI escapes + trailing CR confirmed). Evidence: session `evidence/<vm>/T1.txt` (local-only). |
| M1.T2 | 1.2.0 | new history-load crash-scan case; existing crash-detection set green | Test sub | Done | 2026-06-12: error-handling 110/110 (top, rocky8, debian13); local lifecycle 55/55 rocky8, 56/56 debian13, 56/56 top — incl. 7 exclusion fixtures + 4 history-noise probe assertions; existing crash set green unchanged. |
| M2 | 1.2.0 | #93 align install abort exit codes (`n` vs EOF) | Run finding (#91, PF8/S9 / OBS-1) | Done | Closed 2026-06-12. Convention: every interactive abort exits 1; scope extended (owner-approved) to all three prompts sharing the split — generate overwrite, install precheck, install overwrite. Fix `1e051ec`; Design Record + verification record in #93. enhancement, P3-low. |
| M2.T1 | 1.2.0 | both abort branches follow the chosen convention across install paths | Test sub | Done | PASS 2026-06-12, both goldens, 8/8 each: precheck n/EOF + nothing installed, overwrite n/EOF, generate n/EOF (installed runner). |
| M2.T2 | 1.2.0 | two new error-suite cases pinning both exit codes | Test sub | Done | 2026-06-12: decline-branch cases + existing-conf preservation marker added; EOF pins pre-existed; error-handling green on top. Subshell-assertion counting defect found in the harness — separate issue. |
| M3 | 1.2.0 | #94 observer `list` shows no sockets while IOCs run | Run finding (#91, S6 / OBS-2) | Done | Closed 2026-06-12. Design Record in #94: empty-enumeration hint gated on unreadable entries; operator output byte-identical; exit 0 unchanged. Fix `1e6cdbc`. enhancement, P3-low. |
| M3.T1 | 1.2.0 | non-`ioc` empty `list` carries the permission hint (or documented behavior) | Test sub | Done | PASS 2026-06-12, both goldens, 6/6 each: obs gets empty result + hint at exit 0; opa table unchanged, no hint. |
| M3.T2 | 1.2.0 | suite case where test mode permits a non-`ioc` probe | Test sub | Done | 2026-06-12: three parent-shell assertions (genuine-empty no hint; `chmod 0` subdir hint + exit 0, `EUID` guard); error-handling 114/114 on top; local lifecycle 56/56 regression on top. |
| M3.T4 | 1.2.0 | amend `testplan_multiuser.md` S6 expected result | Test sub | Done | S6 asserts the hint for the observer while IOCs run (committed with the fix, `1e6cdbc`). |
| M4 | 1.2.0 | #87 generalize the hardcoded system user/group (`ioc-srv`/`ioc`) into a single configurable source | Coherence (CI-12) | Done | Closed 2026-06-12. Both scripts resolve `IOC_RUNNER_SYSTEM_USER`/`IOC_RUNNER_SYSTEM_GROUP`, defaults unchanged; guard pins the shared contract; PERMISSION_MODEL.md documents the override. Fix `234a580`; Design Record + accepted residual (unvalidated admin env) in #87. enhancement, P2-medium. |
| M4.T1 | 1.2.0 | user/group override honored by both scripts on a VM golden; default path unchanged | Test sub | Done | PASS 2026-06-12, both goldens, 11/11 each: override setup/install/start E2E incl. single-source negative (no-override install rejects); default restore verified, infra suite green on restored defaults. |
| M4.T2 | 1.2.0 | new shared-defaults guard test; system-infra suite green on defaults | Test sub | Done | 2026-06-12: 8 guard assertions (names + defaults agree, `ioc-srv`/`ioc` pinned); error-handling 122/122 top; one-off negative edit fails the guard; infra 40/40 rocky8, 41/41 debian13. |
| M5 | 1.2.0 | #81 generalize the duplicated procServ systemd unit template into one emitter | Coherence (CI-4) | Open | The unit contract is hand-maintained in two copies (`bin/ioc-runner:363-382` local user unit, `bin/setup-system-infra.bash:467-489` system unit); CI-1 (#75) already paid the round-trip. Single emitter + shared-contract guard test; pure refactor gated by byte-equivalence, so it precedes the #53/#54 content edits. P3-low. |
| M5.T1 | 1.2.0 | must-agree byte-equivalence pre/post refactor, both modes; guard fails on a one-sided edit | Test sub | Open | — |
| M5.T2 | 1.2.0 | new shared-contract guard test; both lifecycle suites green on top and on both VM gates | Test sub | Open | — |
| M5.T3 | 1.2.0 | re-run M4.T2 (template emission rewritten in both scripts) | Test sub | Open | — |
| M6 | 1.2.0 | #84 pin the git-metadata injection contract with a guard test | Coherence (CI-9) | Open | The hash/commit/install metadata + `sed` contract is triplicated (`bin/ioc-runner:14-17`/`199-214`, `setup:563-585`, `inject-runner-version.bash:16-31`); add a static guard test pinning the shared declaration/`sed` lines. Side effect of #72; folds with the M5 guard test (CI-10/CI-14 may join). refactor, P3-low. |
| M6.T1 | 1.2.0 | negative check per metadata copy; CI-10/CI-14 fold decision recorded | Test sub | Open | — |
| M6.T2 | 1.2.0 | new static guard test pinning the shared `declare -g RUNNER_*`/`sed` contract | Test sub | Open | — |
| M7 | 1.2.0 | #86 reconsider unifying the socket-path reference across `resolve_sock_path` callers | Review follow-up (#85) | Open | Revisits option A (unify the three caller references) or a helper-contract change; #85 documented the `do_inspect` alias as intentional (option B) in 1.1.1. Rides the M5 helper-contract review. `Refs #85`/`#83`. refactor, P3-low. |
| M7.T1 | 1.2.0 | decision first (unify / contract change / Keep verdict); if code changes, identical socket-path resolution for all three callers | Test sub | Open | — |
| M7.T2 | 1.2.0 | both lifecycle suites green (attach/monitor/inspect paths) | Test sub | Open | — |
| M8 | 1.2.0 | #52 review procServ child-exit signals for crash-loop detection | Carry-forward | Open | Reframed by the rs20260612_143435 strategy (C1+H, conv C003): now the C1+H confirmation census feeding the M10/M11 coupled pair. Empirical sub-measurements E1-E4 below. **These are PILOT/directional only — single-run-per-point, with instruments refined (and some flagged) in Round 6; do NOT treat the pilot numbers as settled (R10-F607). The authoritative results come from the plan-v3 measurement campaign (`09_measurement_plan_v2.md` -> v3).** Exit-signal semantics feed the M10 `Restart=` decision. |
| M8.T1 | 1.2.0 | child-kill positive and healthy-restart negative behavior on both goldens | Test sub | Open | — |
| M8.T2 | 1.2.0 | new restart-negative and child-kill-positive cases; existing crash-detection set green | Test sub | Open | — |
| M8.T3 | 1.2.0 | re-run M1.T2 (`CRASH_LOG_PATTERNS` / scan logic shared) | Test sub | Open | — |
| M8.E1 | 1.2.0 | stabilization window: measure healthy IOC procServ-fork -> `iocRun: All initialization complete` on both goldens; sets the M11 poll window and the `RestartSec` ceiling | Empirical (PILOT) | Pilot | 2026-06-14 (pilot, trivial softIoc = lower bound per R4-F501): **~0.82 s** both goldens (rocky8 0.815-0.828, debian13 0.815-0.820), marker `iocRun: All initialization complete` confirmed. Window is sub-second for a no-device IOC and is NOT device-connect (asyn is async, does not gate `is-active`). 5 s unjustified -> M11 polls the marker, not `sleep 5`. |
| M8.E2 | 1.2.0 | log growth under `Restart=always`+`StartLimitIntervalSec=0` infinite loop (local vs system); decides U003 (=0 safety / log-cap need) | Empirical (PILOT) | Pilot | 2026-06-14 (pilot, single run per point; 664 B banner is NOT constant per R2-F503/R4-F502) fine RestartSec sweep (1.0-5.0s, 9 values), both goldens, faithful 664 B/launch (= measured procServ startup banner), `=0` loop. Never `failed` at any value (all `activating (auto-restart)`). Rate ∝ 1/RestartSec (0.80/s@1.0s -> 0.17/s@5.0s). **procServ logfile growth 48 MB/day@1.0s -> 27@2.0s -> 11 MB/day@5.0s** (LESS with larger RestartSec). So a broken `=0` loop costs tens of MB/day in the procServ logfile; local mode (no rotation) accrues it unbounded -> **U003 NEEDS a log size-cap / rotation, esp. the local-mode procServ logfile**; larger RestartSec also helps. Journal column DISCARDED (cumulative across the reused unit name — an artifact; the journal is operationally unused per FAQ Q9 and journald-capped anyway). |
| M8.E3 | 1.2.0 | procServ `--holdoff` pacing: child crash loop with vs without `--holdoff`, measure restart rate; decides U005 | Empirical (PILOT) | Pilot | 2026-06-14 `--holdoff` sweep, both goldens, **single run per point; instrument flagged in Round 6 (R2-F603/R7-F604: child-level events need a child-restart detector, not unit state)**. Directional only: default holdoff was the slowest (~0.08/s, ~3 MB/day), `--holdoff=1` faster (~36 MB/day). **U005 is NOT settled by this** — the "keep default" lean is provisional pending the rigorous, replicated, fixed-instrument C3 in plan v3. |
| M8.E4 | 1.2.0 | raw cycling trajectory (`ActiveState`/`SubState`/`NRestarts`) under `Restart=always`+`=0` for the M11 poll-bound design (M11 poll code not yet present) | Empirical (strategy) | In progress | 2026-06-14: raw trajectory captured via E2 — `activating (auto-restart)`, `NRestarts` monotonic, never `failed` on both goldens. The poll-logic test (max-timeout, verdict) still needs M11 code. |
| M9 | 1.2.0 | #53 review missing `Requires`/`Wants` (and `Before`/`After`) in template unit | Carry-forward | Open | Per systemd unit-ordering guidance; system unit already carries `Wants`/`After` (mode-divergent fields per #81). One-place edit through the M5 emitter. |
| M9.T1 | 1.2.0 | review first (Keep verdict if no change); `systemd-analyze verify` on a deployed unit if changed | Test sub | Open | — |
| M9.T2 | 1.2.0 | both lifecycle suites green | Test sub | Open | — |
| M9.T3 | 1.2.0 | re-run the M5 shared-contract guard (template content via the emitter) | Test sub | Open | — |
| M10 | 1.2.0 | #54 add `Restart=` policy to system template unit | Carry-forward | Open | Decided (rs20260612_143435 / C003, pending U001): `Restart=always` (forced by OOM/SIGKILL + `SuccessExitStatus`), `RestartSec` provisional (pin below the M8.E1 window), `StartLimitIntervalSec=0` + `StartLimitBurst=5` + `StartLimitAction=none` in `[Unit]`. Both modes via the M5 emitter. Coupled with M11 (poll first, then `Restart=`, one joint cutover gate). `=0` reverses #54's original acceptance criterion -> see U008. **Campaign finding (res20260614_210000, both goldens): procServ-death recovery is ~96 s (TimeoutStopSec-gated) — procServ execs its child with SIGTERM blocked, so `KillMode=control-group` cleanup stalls the full `TimeoutStopSec=90s` before `Restart=always` fires. M10 should add `KillMode=mixed` or a shorter `TimeoutStopSec` so an OOM/crash recovers in seconds, not ~96 s.** enhancement. |
| M10.T1 | 1.2.0 | policy chosen from M8 findings; crash-loop behavior matches design incl. `SuccessExitStatus` interplay | Test sub | Open | — |
| M10.T2 | 1.2.0 | both lifecycle suites green | Test sub | Open | — |
| M10.T3 | 1.2.0 | re-run the M5 guard and the crash-detection cases | Test sub | Open | — |
| M11 | 1.2.0 | #67 replace start/restart fixed `sleep 5` with active-state polling | Carry-forward | Open | `bin/ioc-runner:1740-1782` (corrected from stale `1536-1547`); preserve the crash-pattern scan that follows. Coupled with M10 (rs20260612_143435 / C003): the poll lands FIRST (before `Restart=`), must use a MEASURED stabilization window (M8.E1, not a fixed 5 s), be `RestartSec`-aware, and carry a max-timeout (`failed` is non-terminal under `=0`). The `sleep 5` "device connection timeout" rationale is wrong (Type=simple: `is-active` is active at fork). **DECIDED 2026-06-14: poll reports "initializing" (not failed) while a slow IOC is still in iocInit; the max-timeout is derived per-IOC at M11 implementation time, NOT a fixed constant.** P3-low. |
| M11.T1 | 1.2.0 | crash-looping IOC reported failed; healthy start/restart not slowed beyond the stabilization window | Test sub | Open | — |
| M11.T2 | 1.2.0 | both lifecycle suites green (start/restart hot path) | Test sub | Open | — |
| M11.T3 | 1.2.0 | re-run M1 + M8 crash cases (restart scan-window timing shared) | Test sub | Open | — |
| M12 | 1.2.0 | #68 distro-independent sudoers parity via validating `systemctl` wrapper | Carry-forward | Open | Closes the sudo < 1.9.10 residual risk from #57 (Rocky 8 / alsucl-psrv3 = 1.9.5p2). sudoers verb-scope redesign (CI-20) and IOC-name contract enforcement (CI-21) cluster here. Largest design item; independent of M1-M11. P2-medium. |
| M12.T1 | 1.2.0 | wrapper accepts in-contract and rejects out-of-contract names identically on both distros; sudoers narrowed; CI-20/CI-21 dispositions recorded | Test sub | Open | — |
| M12.T2 | 1.2.0 | system suites on both goldens (two sudoers emission branches) | Test sub | Open | — |
| M12.T3 | 1.2.0 | re-run multi-user sudo-gate subset S1/S6/S11 | Test sub | Open | — |
| M12.T4 | 1.2.0 | amend `testplan_multiuser.md` S11 (residual risk closed) | Test sub | Open | — |
| M13 | 1.2.0 | #96 replace the ineffective `IOCSH_HISTSIZE` history-disable line in `test_logrotate_boundary` | Review follow-up (#92) | Open | The `epicsEnvSet` line cannot gate the history file (in-memory list only, EPICS source-verified); the probe passes because its directory is group-writable (`tests/test-system-lifecycle.bash:928-941`). Remove the line and correct the comment. Added 2026-06-11 from the M1 design review. tests, P3-low. |
| M13.T1 | 1.2.0 | line removed and comment corrected; `test_logrotate_boundary` green | Test sub | Open | — |
| M13.T2 | 1.2.0 | system-lifecycle suite green on both goldens | Test sub | Open | — |
| M14 | 1.2.0 | #97 replace the ineffective `IOCSH_HISTSIZE` recommendation in the install precheck hint | Review follow-up (#92) | Open | The hint (`bin/ioc-runner:1128-1130`) sends operators to a knob proven a no-op in the #92 review; replace with guidance consistent with FAQ Q5/Q8 (`EPICS_IOCSH_HISTFILE=/dev/null`, scan exclusion note). M1 residue found in the M2 sweep. bug, P3-low. |
| M14.T1 | 1.2.0 | hint text replaced; consistent with FAQ Q5/Q8 as corrected by #92 | Test sub | Open | — |
| M14.T2 | 1.2.0 | error-handling suite green (install/precheck cases unchanged) | Test sub | Open | — |
| M15 | 1.2.0 | #98 subshell assertions do not reach the error-suite counters | Review follow-up (#93) | Done | Closed 2026-06-12 (pulled forward before the cluster). Ten blocks de-subshelled (cd scoped in the command substitution) plus a permanent executed-vs-counted tripwire; quick-review gate, independent reviewer accept. Fix `36ad023`; Design Record in #98. tests, P2-medium. |
| M15.T1 | 1.2.0 | printed-assertion count equals counted total; a deliberate subshell FAIL fails the suite (negative check) | Test sub | Done | 2026-06-12: 132 printed = 132 counted = 132 executed; planted-FAIL and reintroduced-subshell negatives both fail the suite (exit 1). |
| M15.T2 | 1.2.0 | full error-handling suite green with reconciled counts; same-pattern sweep of the other suites recorded | Test sub | Done | 2026-06-12: error-handling 132/132 on top; sweep of the other three suites and the orchestrator clean (recorded in #98); summary format change breaks no consumer. |
| M16 | 1.2.0 | release gate (no GitHub issue; defined by `testplan_1.2.0.md` "Release Gate") | Release gate | Open | Runs after M1-M15 close; gates the master merge + `1.2.0` tag. |
| M16.T1 | 1.2.0 | cycle batch re-run of all M1-M15 change-specific verifications on the final tree | Test sub | Open | — |
| M16.T2 | 1.2.0 | all four suites, both modes, both goldens, clone-and-test + install-and-test | Test sub | Open | — |
| M16.T3 | 1.2.0 | `testplan_multiuser.md` executed identically (S6/S11 amendments in effect) | Test sub | Open | — |

**Tally:** milestones Open 11 (10 work + 1 gate), Done 5 (M1-M4, M15) · test subs Open 30, Done 11 (M1.T1/T2, M2.T1/T2, M3.T1/T2/T4, M4.T1/T2, M15.T1/T2) · empirical subs (strategy) 4: ALL PILOT/directional, none settled — E1/E2/E3 ran (single-run-per-point), E4 needs M11 code; authoritative results await the plan-v3 campaign · Blocked 0

## Open strategy decisions (rs20260612_143435 / C1+H)

External gate: cluster execution (M8-M11) is gated on these. Full text in the
session README; convergence C003 (`conv20260614_081643`) is the authority.

| ID | Decision | Blocking | State |
| --- | --- | --- | --- |
| U001 | Authorize the C1+H strategy (+ amd v3 conditions) for M8-M11 execution | M8-M11 | open — awaiting C003 acceptance + amd v3 |
| U002 | Confirm support contract (all four initiators; external PV restart needs no special handling under C1+H) | M10 record | open (near-formality) |
| U003 | local-mode log-cap trade. **Owner inputs COMPLETE (User 2026-06-14): local disk 500 GB; IOC area 10 GB; unattended interval 1 month (30 d); N-IOC max 10; margin 50% (default).** Pre-registered threshold: per-IOC budget = 10 GB x 0.5 / 10 / 30 d = **~16.7 MB/day**. VERIFIED: local mode has NO log rotation (LOG_LAYOUT.md sec 5 + setup code — `logrotate.d/procserv` is system-only; local `$HOME/.local/state/procserv` is unbounded). Pilot-directional: default-holdoff child loop ~3 MB/day (UNDER 16.7) vs worst-case ~36-48 MB/day (OVER). Lean: add a local rotation/size-cap (cheap insurance; local has zero ceiling today); campaign confirms the actual rate vs 16.7 MB/day. | M10 reliability | **DECIDED 2026-06-14 (User): add a local-mode log size-cap/rotation** (per-user logrotate `copytruncate` or size trigger); system-mode weekly-rotation sufficiency verified by C9; full-scale campaign confirms the rate vs the 16.7 MB/day threshold. **CONFIRMED 2026-06-14 (res20260614_210000): C3 default-holdoff broken-IOC rate ~5 MB/day BOTH goldens (rocky8 5.1, debian13 4.9) — common case UNDER 16.7; realism caveat = terse softIoc init, so rotation covers the verbose/long-outage/multi-failure tail.** |
| U004 | Fleet-synchronized restart storm — record as operational boundary vs bring in scope | M10 / out-of-cluster | open |
| U005 | procServ `--holdoff` | M5/M10 emitter | **DECIDED 2026-06-14 (User): keep procServ DEFAULT `--holdoff`** (pilot + first principles: default is the most conservative; the lever for excess growth is U003 rotation, not a smaller holdoff). Full-scale campaign confirms the default-holdoff child-loop rate. |
| U006 | `^T` autorestart-toggle harden — mechanism + home. **CAMPAIGN FINDING (res20260614_210000, both goldens, procServ 2.9.0-dev source verified): the C1+H plan to add `^T` to `--ignore` does NOT disable the toggle.** `--ignore`/ignChars only filters bytes forwarded to the child IOC's stdin (`processClass::Send`); procServ's console command keys (`^T` toggle, `^X` kill, `^R` restart, `^Q` quit) are matched on the raw input in `clientItem::processInput()` with NO ignChars check, and `^T`/`^X` are auto-added to ignChars anyway. The real disable is **`--autorestartcmd=''`** (sets toggleRestartChar=0) — verified live on both goldens. | M5 emitter | **DECIDED 2026-06-15 (User, option a): use `--autorestartcmd=''` to truly close the toggle foot-gun** — a stray `^T` would otherwise silently disable the IOC's procServ inner autorestart while procServ stays alive (so the outer `Restart=always` never fires either), leaving the IOC down and nothing `failed`. Maintenance autorestart-stop goes through the operation verbs (`ioc-runner`/`systemctl stop`, OP1), not a console keystroke. `--ignore=^T` is dropped (redundant/misleading); `--ignore=^D^C^]` stays (real child-stdin filter). Home: M5 emitter (it builds the procServ command line). **Carry-over:** the converged amendment `07_strategy_amendment_v2_c1h.md` and convergence C003 still spell the old `^T`→`--ignore` harden — correct that text when the bundle is revised at U001 authorization. |
| U007 | M10/M11 bookkeeping — merge #54+#67, or keep separate with order reversed + joint gate | scope/bookkeeping | open |
| U008 | #54 acceptance-criterion rewrite — `=0` reverses its "crash-loop -> diagnosable `failed`" criterion (follows U003) | scope/bookkeeping | open |

## Milestone 1.2.0

Larger follow-ups requiring design or behavior changes beyond a patch.
GitHub milestone `1.2.0` — 10 open, 5 closed (#92, #93, #94, #87, #98), due 2026-07-31. The work order is
M1-M15 plus the M16 release gate in the Active Register above; M16 is
register-local with no GitHub issue. The three template items #53, #54,
and #81 form one cluster — all edit the system unit template, so it is
touched once as a group, with #81 first as the byte-equivalence-gated
refactor. #96 (M13) was added 2026-06-11 as a spin-off of the M1 design
review; #97 (M14) and #98 (M15) were added 2026-06-12 from the M2 sweep,
and #98 was pulled forward and closed the same day.

| Issue | Title | Priority | Notes |
| --- | --- | --- | --- |
| [#68](https://github.com/jeonghanlee/epics-ioc-runner/issues/68) | Distro-independent sudoers parity via a validating `systemctl` wrapper | P2-medium | sudoers cannot enforce "via the runner only" and old sudo cannot anchor argument regex; on sudo < 1.9.10 the glob stays broader than the runner's IOC-name model. A uniform boundary needs a wrapper, not sudoers globs/regex. Closes the #57 residual risk. |
| [#67](https://github.com/jeonghanlee/epics-ioc-runner/issues/67) | Replace start/restart fixed `sleep 5` with active-state polling | P3-low | `bin/ioc-runner:1536-1547`: fixed `sleep 5` then a single post-state check. A unit crash-looping with `Restart=` can momentarily read `active` at second 5 and pass. Re-check active state after the crash scan; preserve a minimum stabilization window. |
| [#54](https://github.com/jeonghanlee/epics-ioc-runner/issues/54) | Add restart policy to system template unit | enhancement | Template unit defines no `Restart=`; evaluate `always` vs `on-failure`. Couples with #67 (timing) and #52 (exit-signal semantics). |
| [#53](https://github.com/jeonghanlee/epics-ioc-runner/issues/53) | Possibly missing `Requires`/`Wants` in template systemd unit | enhancement | Per systemd unit docs, review `Requires`/`Wants` and `Before`/`After` ordering for the template unit. |
| [#52](https://github.com/jeonghanlee/epics-ioc-runner/issues/52) | Review procServ child-exit signals for crash-loop detection | enhancement | Follows #11 (byte-offset crash detection) and extends the #24 journal-fallback edge-case review. Current pattern set catches explicit fatal output; review child-exit signal handling for crash-loop cases. |
| [#81](https://github.com/jeonghanlee/epics-ioc-runner/issues/81) | Generalize the duplicated procServ systemd unit template into a single emitter | refactor, P3-low | Coherence finding CI-4. The unit contract is hand-maintained in two near-identical copies (`bin/ioc-runner:363-382`, `bin/setup-system-infra.bash:467-489`); the must-agree lines currently match but nothing enforces it, and CI-1 (#75) already paid the round-trip. Slight generalization to a single emitter plus a shared-contract guard test. Clusters with #53/#54. |
| [#84](https://github.com/jeonghanlee/epics-ioc-runner/issues/84) | Pin the shared git-metadata injection contract with a guard test | refactor, P3-low | Coherence finding CI-9. The hash/commit/install metadata + `sed` contract is implemented in three places (`bin/ioc-runner`, `bin/setup-system-infra.bash`, `configure/inject-runner-version.bash`); add a static guard test pinning the shared `declare -g RUNNER_*` / `sed` contract. Side effect of #72; clusters with #81. |
| [#86](https://github.com/jeonghanlee/epics-ioc-runner/issues/86) | Reconsider unifying the socket-path reference across resolve_sock_path callers | refactor, P3-low | Follow-up from #85 (1.1.1 took option B, documenting the `do_inspect` alias). Revisit option A (unify all three callers) or a helper-contract refactor in the 1.2.0 helper review; clusters with #81. No behavior change. |
| [#87](https://github.com/jeonghanlee/epics-ioc-runner/issues/87) | Make the system service account and group configurable from a single source | enhancement, P2-medium | Coherence finding CI-12 (2026-06-08 sweep). The system account/group is hardcoded as `ioc-srv`/`ioc` independently in `bin/ioc-runner:85-86` and `bin/setup-system-infra.bash:16-17`; deploying under a site-specific identity needs both edited in lockstep. Generalize to `IOC_RUNNER_SYSTEM_USER`/`IOC_RUNNER_SYSTEM_GROUP` honored by both (default `ioc-srv`/`ioc`), plus a guard test pinning the shared defaults. Latent today; this is a Generalize, not a bug. |
| [#92](https://github.com/jeonghanlee/epics-ioc-runner/issues/92) | Crash-warning false positive after manual st.cmd run | bug, P3-low | Run finding F-M2-1 from #91 (S7). Cross-owned `0600 .iocsh_history` between operator manual runs and `ioc-srv` service runs; the history-load `ERROR` matches the global `CRASH_LOG_PATTERNS`, tripping the start health-check warning on a conforming directory. FAQ Q5 note and/or scan exclusion. |
| [#93](https://github.com/jeonghanlee/epics-ioc-runner/issues/93) | Align install abort exit codes (n vs EOF) | enhancement, P3-low | Run finding OBS-1 from #91 (PF8/S9). Prompt `n` exits 0, EOF abort exits 1; both mean not installed. Pick one convention, apply to both branches, pin with error-suite cases. |
| [#94](https://github.com/jeonghanlee/epics-ioc-runner/issues/94) | Observer list shows no sockets while IOCs run | enhancement, P3-low | Run finding OBS-2 from #91 (S6). Non-`ioc` `list` exits 0 with an empty result while IOCs run (socket dirs `0770` untraversable); add a permission hint to the empty case or document. |
| [#96](https://github.com/jeonghanlee/epics-ioc-runner/issues/96) | test_logrotate_boundary history knob is a no-op | tests, P3-low | Spin-off from the #92 design review (Independent). The `epicsEnvSet("IOCSH_HISTSIZE","0")` line in the probe `st.cmd` cannot disable the history file (EPICS source-verified: in-memory list only; path variable is `EPICS_IOCSH_HISTFILE`; in-`st.cmd` `epicsEnvSet` is too late); the test passes because the probe directory is group-writable. Remove the line, correct the comment. |
| [#97](https://github.com/jeonghanlee/epics-ioc-runner/issues/97) | install precheck hint recommends the ineffective IOCSH_HISTSIZE knob | bug, P3-low | M1 residue found in the M2 sweep (Refs #92). The runtime hint (`bin/ioc-runner:1128-1130`) recommends the knob the #92 review proved a no-op; replace with FAQ Q5/Q8-consistent guidance. |
| [#98](https://github.com/jeonghanlee/epics-ioc-runner/issues/98) | test-error-handling subshell assertions do not reach the suite counters | tests, P2-medium | Found adding the #93 decline cases. `( cd ... )` blocks lose counter increments (121 PASS printed vs 111 counted) and a subshell FAIL cannot fail the suite; fix options in the issue, plus a printed-equals-counted self-check and a same-pattern sweep of the other suites. |

## Examined-Keep Ledger

Coherence-sweep findings examined and deliberately left as-is, carried
forward so the next sweep closes them fast instead of re-opening the same
seams. Full per-finding records (evidence offsets, fate reasoning) live in
the 1.1.1 register: `git show 1.1.1:docs/milestone.md`.

| ID | Sweep | Finding | Why Keep |
| --- | --- | --- | --- |
| CI-5 | 2026-06-04 | Tool resolution uses `-x` only in the search loop but `-f && -x` in the override branch. | Principled asymmetry: search paths are fixed trusted defaults, the override is arbitrary user input (#78 scoped to it deliberately). |
| CI-6 | 2026-06-04 | Keep-3 backup-prune policy implemented twice (system timestamp name vs local `mktemp`). | Mode-appropriate divergence: system setup is one-shot per file, so the same-second overwrite is unreachable; local install is repeatable and uses `mktemp`. |
| CI-10 | 2026-06-05 | Completion command/option list is a separate copy of the runner command set. | Copies agree (14 commands, identical options); a drift-guard could fold into the #84/#81 guard-test cluster. |
| CI-11 | 2026-06-05 | `RUN_DIR` divergence aborts but `IOC_RUNNER_SYSTEM_CONF_DIR` divergence has no guard. | Principled asymmetry by failure mode: diverged RUN_DIR fails silently and aims `rm -rf` wrong; diverged CONF_DIR fails loudly at `start`. |
| CI-13 | 2026-06-08 | systemd unit-name prefix `epics-@` duplicated across setup and runner call sites. | Internal naming convention with no user reason to vary; local mode is self-consistent in one file. |
| CI-14 | 2026-06-08 | System log-dir default literal `/var/log/procserv` declared in both scripts. | Both read the same `IOC_RUNNER_SYSTEM_LOG_DIR` override, so the user case is already generalized; only the default literal could diverge by source edit (could fold into the #84 guard test). |
| CI-15 | 2026-06-08 | Bash-completion re-derives the conf-dir fallback chain and default literals. | Architectural: a sourced completion function cannot source the runner; it reads the same env overrides, and drift degrades only tab-completion. |
| CI-20 | 2026-06-09 | sudoers policy grants `status` although the runner never uses sudo for status. | Principled superset serving operators running `sudo systemctl status` by hand; read-only verb. Verb-scope redesign belongs to #68. |
| CI-21 | 2026-06-09 | IOC-name contract regex maintained in four copies (runner, setup, example, INSTALL.md). | Copies agree and the parity is documented on both sides; enforcement is exactly the #68 wrapper scope. |

## Notes

- The `Backlog` GitHub milestone is empty.
- The cycle test plan is [`testplan_1.2.0.md`](testplan_1.2.0.md) —
  per-milestone verification, dependency re-run matrix, and release-gate
  sequence. The version-independent multi-user scenarios live in
  [`testplan_multiuser.md`](testplan_multiuser.md) (renamed from
  `testplan.md` this cycle), executed identically at every release gate.
  Test plans are V&V artifacts, not milestone register items.
- The released 1.1.1 record (full register including the four coherence
  sweeps and the #91 release-gate run) lives in git tag `1.1.1`:
  `git show 1.1.1:docs/milestone.md`.
- The released 1.1.0 record (phase plan, acceptance, test plan) lives in git
  tag `1.1.0`: `git show 1.1.0:docs/MILESTONE-1.1.0.md` and
  `git show 1.1.0:docs/TEST_PLAN-1.1.0.md`. The permission-model end state
  remains current in `docs/PERMISSION_MODEL.md`.
