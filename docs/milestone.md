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

**Next session entry point:** the remaining 1.2.0 work is the **M8-M11 C1+H
cluster** (gated on U004/U007/U008 + the plan-v3 campaign) and the **M12** (#68)
sudoers wrapper. **M13** (#96) and **M14** (#97) closed 2026-06-17 (the no-op
IOCSH_HISTSIZE sweep across the two lifecycle probes, the install hint, and the
FAQ; commits 30cb8d7, 1f074cb). **M7** (#86) closed 2026-06-17 (Keep B: the
documented `do_inspect` alias is the end state, no code change). **M6**
(#84) closed 2026-06-16: the git-metadata injection guard landed (commit 96fc886,
error suite 141/141 on top, executed==counted); the same commit extended #87's
`test_system_identity_guard` with `SYSTEM_LOG_DIR` (CI-14, Refs #87). **M5** (#81)
closed 2026-06-16 (sub-2 `--autorestartcmd=''`, commit 77f1556) and **M16** (#99)
closed 2026-06-16 (commit 72b1351); both verified on both goldens. The M6 review
session (rs20260616_144324, convergence conv20260616_151322; local-only) recorded a
standing **examined-Keep -> guard promotion test** (now **M17**, #100) in the
Examined-Keep Ledger below. **U001 is authorized** (2026-06-16, User-delegated;
auth20260616_003202) on convergence **C005** (`conv20260616_002157`; Round 11
11/11 + Round 12 15/15, converged), governing amendment **amd v4**
(`17_strategy_amendment_v4_c1h.md`); **U002 closed**. The U006/`^T` correction and all Round-10/11
conditions are applied (amd v4 + ADR 0001 + this register); see C005 for the
close-out. The narrative below is the historical journey record (C003/amd v3
are superseded by C005/amd v4).

**Mechanism note (2026-06-16, #81 option 3):** M5/#81 is **examined-Keep + a
shared-contract guard**, not a single emitter (see CI-4 in the Examined-Keep
Ledger). Where this register says "via the M5 emitter" / "single emitter" (the
M9/M10 rows and the narrative below), read it as the **guarded two-copy
contract** — both modes stay identical, enforced by the guard, not one emitter.
Outcome unchanged.
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
2026-06-15 (U006), emitted by M5; now applied in amd v4 (`17_*`) + ADR 0001 and validated by
Round 11/12 (C005).** The durable architecture record is the tracked ADR
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
| M5 | 1.2.0 | #81 pin the duplicated procServ unit template with a shared-contract guard (examined-Keep, not merged) | Coherence (CI-4) | Done | **Re-scoped 2026-06-16 (#81 design conversation, option 3):** a true single emitter cuts against the runner's self-contained-single-file design (it cannot source a shared lib — cf. CI-15) and the two units are written in different contexts (system at install, local at `--local install` runtime); the duplication is therefore **examined-Keep (CI-4, see ledger)**, not merged. M5 adds a shared-contract guard pinning the must-agree rows across the two copies (`bin/ioc-runner:374-393`, `bin/setup-system-infra.bash:471-493`); drift fails the guard. `--autorestartcmd=''` (U006) is added to BOTH copies (sub-2), guard-pinned. M5.T1 reframes from byte-equivalence-pre/post-refactor to two-copy must-agree equivalence. The strategy docs' "single M5 emitter" wording is reconciled 2026-06-16 (mechanism note near the top + ADR 0001 + CI-4); outcome unchanged (identical in both modes). **Sub-2 (`--autorestartcmd=''`) landed + verified 2026-06-16:** both copies emit the flag (`bin/ioc-runner:385`, `bin/setup-system-infra.bash:485`); static guard 134/134 (top); both goldens render it into the system AND local units (rocky8/debian13), no-regression local 55/56 · infra 40/41 · system-lifecycle 74/74. All subs T1/T2/T3 green; #81 closed 2026-06-16 (sub-2 commit 77f1556). P3-low. |
| M5.T1 | 1.2.0 | must-agree equivalence across the two unit copies; guard fails on a one-sided edit | Test sub | Done | 2026-06-16: examined-Keep (CI-4, no refactor) — guard asserts the two copies' must-agree rows identical; negative one-sided drift (dropped local SIGKILL) -> guard FAIL (error-suite 133/134, exit 1). Commit 7a3aeb2. |
| M5.T2 | 1.2.0 | new shared-contract guard test (static) + dynamic rendered-unit check on both goldens | Test sub | Done | 2026-06-16: static guard `test_template_contract_guard` in `tests/test-error-handling.bash` (commit 7a3aeb2) — error-suite 134/134 (executed==counted, #98 tripwire intact); dynamic rendered-unit agreement on both goldens (rocky8/239, debian13/257), normalizing binary/logdir/CONF_DIR. quick-review accept. Re-confirmed 2026-06-16 with sub-2: rendered system AND local units on both goldens carry `--ignore=^D^C^] --autorestartcmd=''`. |
| M5.T3 | 1.2.0 | re-run M4.T2 (template emission rewritten in both scripts) | Test sub | Done | 2026-06-16: M4.T2 re-run in the sub-2 campaign — error-handling 134/134 (top, incl. STEP 12 system-identity guard), system-infra 40/40 rocky8 / 41/41 debian13 on the goldens; shared defaults + must-agree contract intact. |
| M6 | 1.2.0 | #84 pin the git-metadata injection contract with a guard test | Coherence (CI-9) | Done | **Closed 2026-06-16.** `test_metadata_contract_guard` (commit 96fc886) pins the three injected `RUNNER_*` names + their declaration anchor across the runner and both installers; error suite 141/141 on top (executed==counted). CI-10/CI-14 fold decided in the M6 ten-reviewer review (conv20260616_151322): CI-10 keep (Ledger), CI-14 promoted to #87 (same commit). refactor, P3-low. |
| M6.T1 | 1.2.0 | negative check per metadata copy; CI-10/CI-14 fold decision recorded | Test sub | Done | 2026-06-16: one-sided breaks fail the guard — dropped/renamed injector target -> set-mismatch FAIL; injected field with no anchor -> missing-anchor FAIL; anchor rename -> suite fails (runner breaks first). Fold decision recorded in conv20260616_151322 (CI-10 keep; CI-14 -> #87). |
| M6.T2 | 1.2.0 | new static guard test pinning the shared `declare -g RUNNER_*`/`sed` contract | Test sub | Done | 2026-06-16: `test_metadata_contract_guard` lands in `tests/test-error-handling.bash` (commit 96fc886); error suite 141/141 on top, executed==counted (#98 tripwire intact). Static guard; dynamic re-confirm rides the M18 release gate. |
| M7 | 1.2.0 | #86 reconsider unifying the socket-path reference across `resolve_sock_path` callers | Review follow-up (#85) | Done | **Keep B, closed 2026-06-17 (no code change).** The documented `do_inspect` alias (`bin/ioc-runner:1588-1591`, "the naming split is intentional", from #85) is the end state. By the M17 promotion-test discipline: cosmetic cross-caller naming only, no functional drift -> Gate B fails; option A / helper-contract refactor would touch a stable ~70-line block for uniformity alone (the Generalize trap). `Refs #85`/`#83`. refactor, P3-low. |
| M7.T1 | 1.2.0 | decision first (unify / contract change / Keep verdict); if code changes, identical socket-path resolution for all three callers | Test sub | Done | 2026-06-17: decision = Keep B (no code change). The intentional-alias comment at `bin/ioc-runner:1588-1590` stands; all three callers resolve via `resolve_sock_path` -> `RESOLVED_SOCK_PATH` identically (the alias is a local readability rebind, not a behavior difference). |
| M7.T2 | 1.2.0 | both lifecycle suites green (attach/monitor/inspect paths) | Test sub | Done | 2026-06-17: no code change -> attach/monitor/inspect paths unaffected; existing suite-green code stands. Re-run rides the M18 release gate. |
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
| M10 | 1.2.0 | #54 add `Restart=` policy to system template unit | Carry-forward | Open | Decided (rs20260612_143435 / C003, pending U001): `Restart=always` (forced by OOM/SIGKILL + `SuccessExitStatus`), `RestartSec=2` (the M11 poll owns the timing: poll max-bound > RestartSec + readiness, not RestartSec below the window), `StartLimitIntervalSec=0` + `StartLimitBurst=5` + `StartLimitAction=none` in `[Unit]`. Both modes via the M5 emitter. Coupled with M11 (poll first, then `Restart=`, one joint cutover gate). `=0` reverses #54's original acceptance criterion -> see U008. **Campaign finding (res20260614_210000, both goldens): procServ-death recovery is ~96 s (TimeoutStopSec-gated) — procServ execs its child with SIGTERM blocked, so `KillMode=control-group` cleanup stalls the full `TimeoutStopSec=90s` before `Restart=always` fires. M10 should add `KillMode=mixed` or a shorter `TimeoutStopSec` so an OOM/crash recovers in seconds, not ~96 s.** enhancement. |
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
| M13 | 1.2.0 | #96 replace the ineffective `IOCSH_HISTSIZE` history-disable line in `test_logrotate_boundary` | Review follow-up (#92) | Done | **Closed 2026-06-17 (commit 30cb8d7).** The `epicsEnvSet` line was a no-op (in-memory list only; file gated by `EPICS_IOCSH_HISTFILE`; in-`st.cmd` `epicsEnvSet` too late). Removed + comment corrected to name the group-writable probe dir as the real safeguard; identical line swept from the permission-enforcement probe too. tests, P3-low. |
| M13.T1 | 1.2.0 | line removed and comment corrected; `test_logrotate_boundary` green | Test sub | Done | 2026-06-17: line + both-probe sweep done; `test_logrotate_boundary` (STEP 28) green on both goldens. |
| M13.T2 | 1.2.0 | system-lifecycle suite green on both goldens | Test sub | Done | 2026-06-17: system-lifecycle 74/74 both goldens (rocky8, debian13), installed mode; STEP 28/29 green, 0 failed. |
| M14 | 1.2.0 | #97 replace the ineffective `IOCSH_HISTSIZE` recommendation in the install precheck hint | Review follow-up (#92) | Done | **Closed 2026-06-17 (commit 1f074cb).** Hint now points to `EPICS_IOCSH_HISTFILE=/dev/null` + the scan-exclusion note (not the no-op `IOCSH_HISTSIZE`). Also corrected the FAQ partial-mitigation note, which contradicted the Q5 history-file note in the same file. bug, P3-low. |
| M14.T1 | 1.2.0 | hint text replaced; consistent with FAQ Q5/Q8 as corrected by #92 | Test sub | Done | 2026-06-17: hint rewritten (`bin/ioc-runner`) + FAQ note corrected; consistent with FAQ Q5/Q6 (`EPICS_IOCSH_HISTFILE=/dev/null`, error already scan-excluded). |
| M14.T2 | 1.2.0 | error-handling suite green (install/precheck cases unchanged) | Test sub | Done | 2026-06-17: error-handling suite green on top (no assertion checks the hint text; install/precheck cases unchanged); `bash -n` clean both scripts. |
| M15 | 1.2.0 | #98 subshell assertions do not reach the error-suite counters | Review follow-up (#93) | Done | Closed 2026-06-12 (pulled forward before the cluster). Ten blocks de-subshelled (cd scoped in the command substitution) plus a permanent executed-vs-counted tripwire; quick-review gate, independent reviewer accept. Fix `36ad023`; Design Record in #98. tests, P2-medium. |
| M15.T1 | 1.2.0 | printed-assertion count equals counted total; a deliberate subshell FAIL fails the suite (negative check) | Test sub | Done | 2026-06-12: 132 printed = 132 counted = 132 executed; planted-FAIL and reintroduced-subshell negatives both fail the suite (exit 1). |
| M15.T2 | 1.2.0 | full error-handling suite green with reconciled counts; same-pattern sweep of the other suites recorded | Test sub | Done | 2026-06-12: error-handling 132/132 on top; sweep of the other three suites and the orchestrator clean (recorded in #98); summary format change breaks no consumer. |
| M16 | 1.2.0 | #99 stale install-decline exit-code assertion in test-system-lifecycle (post-#93 residue) | Review follow-up (#93) | Done | Verified 2026-06-16. Surfaced by the M5 sub-2 golden run: `test-system-lifecycle.bash` case 7b asserted exit 0 for an explicit `N` install decline, but #93 (`1e051ec`) made every interactive abort exit 1 and never updated this suite. Fix: line 1396 expected `0`->`1` + comment 1390 (no runner change). #99 manual close + fix commit pending. tests, P3-low. |
| M16.T1 | 1.2.0 | 7b assertion expected value + comment corrected; case 7b green | Test sub | Done | 2026-06-16: `Prompt explicit N declines install (exit 1)` PASS on both goldens. |
| M16.T2 | 1.2.0 | system-lifecycle suite green on both goldens | Test sub | Done | 2026-06-16: system-lifecycle 74/74 both goldens (rocky8, debian13), installed mode; 0 failed / 0 script errors. |
| M17 | 1.2.0 | #100 record the examined-Keep -> guard promotion test as the Ledger standing rule | Review follow-up (#84) | Done | Verified 2026-06-16. The M6 ten-reviewer session (conv20260616_151322) derived the promotion test; recorded in the Examined-Keep Ledger preamble below, validated against all ten Ledger rows (reproduces every Keep; CI-4/CI-9 the only promotes). docs, area/architecture, P3-low. |
| M17.T1 | 1.2.0 | the promotion test recorded in the Ledger in one-pass-applicable form | Test sub | Done | 2026-06-16: gates A/B/C/D + fate-ordering + cost framing recorded in the Examined-Keep Ledger preamble (Refs #100). |
| M18 | 1.2.0 | release gate (no GitHub issue; defined by `testplan_1.2.0.md` "Release Gate") | Release gate | Open | Runs after M1-M17 close; gates the master merge + `1.2.0` tag. |
| M18.T1 | 1.2.0 | cycle batch re-run of all M1-M17 change-specific verifications on the final tree | Test sub | Open | — |
| M18.T2 | 1.2.0 | all four suites, both modes, both goldens, clone-and-test + install-and-test | Test sub | Open | — |
| M18.T3 | 1.2.0 | `testplan_multiuser.md` executed identically (S6/S11 amendments in effect) | Test sub | Open | — |

**Tally:** milestones Open 6 (5 work + 1 gate), Done 12 (M1-M7, M13, M14, M15, M16, M17) · test subs Open 19, Done 25 (through M7.T1/T2, M13.T1/T2, M14.T1/T2, M15.T1/T2, M16.T1/T2, M17.T1) · empirical subs (strategy) 4: ALL PILOT/directional, none settled — E1/E2/E3 ran (single-run-per-point), E4 needs M11 code; authoritative results await the plan-v3 campaign · Blocked 0

## Open strategy decisions (rs20260612_143435 / C1+H)

External gate: cluster execution (M8-M11) is gated on these. Full text in the
session README; convergence C003 (`conv20260614_081643`) is the authority.

| ID | Decision | Blocking | State |
| --- | --- | --- | --- |
| U001 | Authorize the C1+H strategy for M8-M11 execution | M8-M11 | **authorized 2026-06-16** (User-delegated; convergence C005, auth20260616_003202) |
| U002 | Confirm support contract (all four initiators; external PV restart needs no special handling under C1+H) | M10 record | **closed 2026-06-16** (near-formality, with U001) |
| U003 | local-mode log-cap trade. **Owner inputs COMPLETE (User 2026-06-14): local disk 500 GB; IOC area 10 GB; unattended interval 1 month (30 d); N-IOC max 10; margin 50% (default).** Pre-registered threshold: per-IOC budget = 10 GB x 0.5 / 10 / 30 d = **~16.7 MB/day**. VERIFIED: local mode has NO log rotation (LOG_LAYOUT.md sec 5 + setup code — `logrotate.d/procserv` is system-only; local `$HOME/.local/state/procserv` is unbounded). Pilot-directional: default-holdoff child loop ~3 MB/day (UNDER 16.7) vs worst-case ~36-48 MB/day (OVER). Lean: add a local rotation/size-cap (cheap insurance; local has zero ceiling today); campaign confirms the actual rate vs 16.7 MB/day. | M10 reliability | **DECIDED 2026-06-14 (User): add a local-mode log size-cap/rotation** (per-user logrotate `copytruncate` or size trigger); system-mode weekly-rotation sufficiency verified by C9; full-scale campaign confirms the rate vs the 16.7 MB/day threshold. **CONFIRMED 2026-06-14 (res20260614_210000): C3 default-holdoff broken-IOC rate ~5 MB/day BOTH goldens (rocky8 5.1, debian13 4.9) — common case UNDER 16.7; realism caveat = terse softIoc init, so rotation covers the verbose/long-outage/multi-failure tail.** |
| U004 | Fleet-synchronized restart storm — record as operational boundary vs bring in scope | M10 / out-of-cluster | open |
| U005 | procServ `--holdoff` | M5/M10 emitter | **DECIDED 2026-06-14 (User): keep procServ DEFAULT `--holdoff`** (pilot + first principles: default is the most conservative; the lever for excess growth is U003 rotation, not a smaller holdoff). Full-scale campaign confirms the default-holdoff child-loop rate. |
| U006 | `^T` autorestart-toggle harden — mechanism + home. **CAMPAIGN FINDING (res20260614_210000, both goldens, procServ 2.9.0-dev source verified): the C1+H plan to add `^T` to `--ignore` does NOT disable the toggle.** `--ignore`/ignChars only filters bytes forwarded to the child IOC's stdin (`processClass::Send`); procServ's console command keys (`^T` toggle, `^X` kill, `^R` restart, `^Q` quit) are matched on the raw input in `clientItem::processInput()` with NO ignChars check, and `^T`/`^X` are auto-added to ignChars anyway. The real disable is **`--autorestartcmd=''`** (sets toggleRestartChar=0) — verified live on both goldens. | M5 emitter | **DECIDED 2026-06-15 (User, option a): use `--autorestartcmd=''` to truly close the toggle foot-gun** — a stray `^T` would otherwise silently disable the IOC's procServ inner autorestart while procServ stays alive (so the outer `Restart=always` never fires either), leaving the IOC down and nothing `failed`. Maintenance autorestart-stop goes through the operation verbs (`ioc-runner`/`systemctl stop`, OP1), not a console keystroke. `--ignore=^T` is dropped (redundant/misleading); `--ignore=^D^C^]` stays (real child-stdin filter). Home: M5 emitter (it builds the procServ command line). **Applied 2026-06-16:** the correction is in amd v4 (`17_strategy_amendment_v4_c1h.md`, supersedes `07_*`) and ADR 0001; convergence C005 (`conv20260616_002157`, supersedes C003) validated it (Round 11 11/11 + Round 12 15/15). |
| U007 | M10/M11 bookkeeping — merge #54+#67, or keep separate with order reversed + joint gate | scope/bookkeeping | open |
| U008 | #54 acceptance-criterion rewrite — `=0` reverses its "crash-loop -> diagnosable `failed`" criterion (follows U003) | scope/bookkeeping | open |

## Carry-forward (next round, out-of-cluster)

- **Running-IOC hang detection (continuous / passive liveness visibility).**
  A running IOC that *hangs* — process alive but not progressing (deadlock,
  blocked I/O, CA/PVA unresponsive); emits no crash pattern and never exits
  — is detected by NO current layer: systemd reads `active` / `NRestarts=0`
  (liveness only), procServ restarts only on child *exit*, and the
  `ioc-runner` crash scan is action-bound and matches crash *patterns*, not
  silence. Start-time hang-in-init IS covered by the M11 measured-window poll
  (max-timeout -> "initializing/failed"); the residual is the **running-time
  hang**, which would need active health probing (heartbeat PV / periodic
  `caget`/`pvget`) — new scope, to be examined together with U004
  (fleet/monitoring boundary). Origin: amd v3 Round 10 review
  (R9-F904 / R4-F002 / R8-F803; session rs20260612_143435). **Not a U001
  gate** — the C1+H restart-supervision design is unaffected; deferred to a
  future round.

## Milestone 1.2.0

Larger follow-ups requiring design or behavior changes beyond a patch.
GitHub milestone `1.2.0` — 6 open, 11 closed (#81, #84, #86, #87, #92, #93, #94, #96, #97, #98, #99), due 2026-07-31; #100 added 2026-06-16. The work order is
M1-M17 plus the M18 release gate in the Active Register above; M18 is
register-local with no GitHub issue. The three template items #53, #54,
and #81 form one cluster — all edit the system unit template, so it is
touched once as a group, with #81 first as the byte-equivalence-gated
refactor. #96 (M13) was added 2026-06-11 as a spin-off of the M1 design
review; #97 (M14) and #98 (M15) were added 2026-06-12 from the M2 sweep,
and #98 was pulled forward and closed the same day; #99 (M16) was added
2026-06-16 as a spin-off of the M5 sub-2 golden run (a #93 residue); #100
(M17) was added 2026-06-16 from the M6 review (the examined-Keep promotion test).

| Issue | Title | Priority | Notes |
| --- | --- | --- | --- |
| [#68](https://github.com/jeonghanlee/epics-ioc-runner/issues/68) | Distro-independent sudoers parity via a validating `systemctl` wrapper | P2-medium | sudoers cannot enforce "via the runner only" and old sudo cannot anchor argument regex; on sudo < 1.9.10 the glob stays broader than the runner's IOC-name model. A uniform boundary needs a wrapper, not sudoers globs/regex. Closes the #57 residual risk. |
| [#67](https://github.com/jeonghanlee/epics-ioc-runner/issues/67) | Replace start/restart fixed `sleep 5` with active-state polling | P3-low | `bin/ioc-runner:1740-1782`: fixed `sleep 5` then a single post-state check. A unit crash-looping with `Restart=` can momentarily read `active` at second 5 and pass. Re-check active state after the crash scan; preserve a minimum stabilization window. |
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
| [#99](https://github.com/jeonghanlee/epics-ioc-runner/issues/99) | Stale install-decline exit-code assertion in test-system-lifecycle after #93 | tests, P3-low | Spin-off from the M5 sub-2 golden run (Refs #93). `test-system-lifecycle.bash` case 7b asserted exit 0 for an explicit `N` install decline; #93 made every interactive abort exit 1 but never updated this suite. Fix: line 1396 expected `0`->`1` + comment 1390 (no runner change). |
| [#100](https://github.com/jeonghanlee/epics-ioc-runner/issues/100) | Record the examined-Keep to guard promotion test as the Ledger standing rule | docs, area/architecture, P3-low | From the M6 (#84) ten-reviewer review (conv20260616_151322). Record the promotion test (gates A/B/C/D + fate-ordering + cost) as the Ledger's standing rule. Refs #84. |

## Examined-Keep Ledger

Coherence-sweep findings examined and deliberately left as-is, carried
forward so the next sweep closes them fast instead of re-opening the same
seams. Full per-finding records (evidence offsets, fate reasoning) live in
the 1.1.1 register: `git show 1.1.1:docs/milestone.md`.

**Promotion test (the standing rule, #100 / M17, derived in the M6 review
conv20260616_151322).** Default is Keep; promotion to an enforced guard carries
the burden and runs four ordered gates (the first FAIL stops at Keep): **A** the
copies must be must-agree, not a principled divergence; **B** present reason = a
one-sided drift that is silent AND functional (not cosmetic, not
loud-self-guarding); **C** net of existing equivalent-kind direct coverage; **D**
placement decided separately from promotion, by contract kind (fold into an
existing guard only on matching mechanism + extraction shape, else a separate
guard — never pin multiple kinds in one guard). Try eliminate
(single-source / machine-derive) before guarding; a guard is second-best, built
only when elimination is blocked by an architectural invariant or is
disproportionate to blast radius. Record which fate was chosen and which
declined. The file-drawer dividend is banked once, at the Ledger line — price the
counterfactual as re-confirming a one-line verdict minus coverage, never full
re-derivation. The rule reproduces every Keep below; CI-4 and CI-9 are the only
promotes.

| ID | Sweep | Finding | Why Keep |
| --- | --- | --- | --- |
| CI-4 | #81 (examined-Keep 2026-06-16) | procServ systemd unit template duplicated in two copies (`bin/ioc-runner` local user unit, `bin/setup-system-infra.bash` system unit). | Structural: the runner is a single self-contained executable that cannot source a shared lib (cf. CI-15), and the two units are written in different contexts (system at install time, local at `--local install` runtime); a true single runtime emitter would need a new installed artifact against that self-containment. Kept as two copies, with the M5 shared-contract guard pinning the must-agree rows so they cannot drift. Supersedes #81's original "single emitter" framing (option 3, design conversation 2026-06-16). |
| CI-5 | 2026-06-04 | Tool resolution uses `-x` only in the search loop but `-f && -x` in the override branch. | Principled asymmetry: search paths are fixed trusted defaults, the override is arbitrary user input (#78 scoped to it deliberately). |
| CI-6 | 2026-06-04 | Keep-3 backup-prune policy implemented twice (system timestamp name vs local `mktemp`). | Mode-appropriate divergence: system setup is one-shot per file, so the same-second overwrite is unreachable; local install is repeatable and uses `mktemp`. |
| CI-10 | 2026-06-05 | Completion command/option list is a separate copy of the runner command set. | Examined-Keep, reaffirmed in the M6 review (2026-06-16, conv20260616_151322): fails promotion Gate B — drift is cosmetic; dispatch is fail-closed (`bin/ioc-runner:1820`), so a stale completion is a loud reject or discoverability gap, never a silent wrong action. `commands=` has never drifted; the one `opts=` co-edit (a4d3bef) stayed in sync (the seam holding, not drift). Eliminate (generate from the dispatch set) examined and declined (self-containment + cosmetic surface). |
| CI-11 | 2026-06-05 | `RUN_DIR` divergence aborts but `IOC_RUNNER_SYSTEM_CONF_DIR` divergence has no guard. | Principled asymmetry by failure mode: diverged RUN_DIR fails silently and aims `rm -rf` wrong; diverged CONF_DIR fails loudly at `start`. |
| CI-13 | 2026-06-08 | systemd unit-name prefix `epics-@` duplicated across setup and runner call sites. | Internal naming convention with no user reason to vary; local mode is self-consistent in one file. |
| CI-14 | 2026-06-08 | System log-dir default literal `/var/log/procserv` declared in both scripts. | **Promoted 2026-06-16** (M6 review, User decision): `SYSTEM_LOG_DIR` added to `test_system_identity_guard` (#87 `SYSTEM_*` family, commit 96fc886, Refs #87) — kind-correct home, not the CI-9 sed guard (which normalizes `${SYSTEM_LOG_DIR}` away). Closes the runner-side default drift the golden suites leave uncaught (their coverage is indirect/setup-side, missing `bin/ioc-runner:52`). No longer an open Keep. |
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
