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

**Next session entry point:** M5 (#81), opening the template and
guard-test cluster (M5-M11). The standalone items M1-M4 (#92 fix
`0baa9df`, #93 fix `1e051ec`, #94 fix `1e6cdbc`, #87 fix `234a580`)
closed 2026-06-12, each verified on both goldens; M5 re-runs the M4
guard per the dependency matrix. The 1.2.0 work order M1-M12 was set
2026-06-11: standalone items first (M1-M4), then the template and guard-test
cluster (M5-M11), then the #68 wrapper design (M12). Cluster-internal order
is grounded in the issue records: #81 (M5) runs first as a pure refactor
gated by its own byte-equivalence acceptance criterion, so #53/#54 land
afterward as one-place content edits through the single emitter; #84 (M6)
folds its guard test with #81 while the emitter contract is fresh
(CI-10/CI-14 drift guards may join); #86 (M7) rides the same helper-contract
review; #52's exit-signal review (M8) feeds the #54 `Restart=` decision
(M10); #67's polling design (M11) follows #54 because `Restart=` changes
what a momentary `active` read means. The #68 wrapper (M12) owns the
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
| M8 | 1.2.0 | #52 review procServ child-exit signals for crash-loop detection | Carry-forward | Open | Follows up #11; extends #24 edge-case review. Exit-signal semantics feed the M10 `Restart=` decision. |
| M8.T1 | 1.2.0 | child-kill positive and healthy-restart negative behavior on both goldens | Test sub | Open | — |
| M8.T2 | 1.2.0 | new restart-negative and child-kill-positive cases; existing crash-detection set green | Test sub | Open | — |
| M8.T3 | 1.2.0 | re-run M1.T2 (`CRASH_LOG_PATTERNS` / scan logic shared) | Test sub | Open | — |
| M9 | 1.2.0 | #53 review missing `Requires`/`Wants` (and `Before`/`After`) in template unit | Carry-forward | Open | Per systemd unit-ordering guidance; system unit already carries `Wants`/`After` (mode-divergent fields per #81). One-place edit through the M5 emitter. |
| M9.T1 | 1.2.0 | review first (Keep verdict if no change); `systemd-analyze verify` on a deployed unit if changed | Test sub | Open | — |
| M9.T2 | 1.2.0 | both lifecycle suites green | Test sub | Open | — |
| M9.T3 | 1.2.0 | re-run the M5 shared-contract guard (template content via the emitter) | Test sub | Open | — |
| M10 | 1.2.0 | #54 add `Restart=` policy to system template unit | Carry-forward | Open | Evaluate `always` vs `on-failure` using the M8 exit-signal findings; edits through the M5 emitter. |
| M10.T1 | 1.2.0 | policy chosen from M8 findings; crash-loop behavior matches design incl. `SuccessExitStatus` interplay | Test sub | Open | — |
| M10.T2 | 1.2.0 | both lifecycle suites green | Test sub | Open | — |
| M10.T3 | 1.2.0 | re-run the M5 guard and the crash-detection cases | Test sub | Open | — |
| M11 | 1.2.0 | #67 replace start/restart fixed `sleep 5` with active-state polling | Carry-forward | Open | `bin/ioc-runner:1536-1547`; preserve the crash-pattern scan that follows. Designed after M10 because `Restart=` changes what a momentary `active` read means. P3-low. |
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
| M15 | 1.2.0 | #98 subshell assertions do not reach the error-suite counters | Review follow-up (#93) | Open | `( cd ... )` blocks lose `TEST_*` increments: 121 PASS printed vs 111 counted, and a subshell FAIL cannot fail the suite. Fix design options in #98; add a printed-equals-counted self-check. Worth closing before the next T2-heavy milestone. tests, P2-medium. |
| M15.T1 | 1.2.0 | printed-assertion count equals counted total; a deliberate subshell FAIL fails the suite (negative check) | Test sub | Open | — |
| M15.T2 | 1.2.0 | full error-handling suite green with reconciled counts; same-pattern sweep of the other suites recorded | Test sub | Open | — |
| M16 | 1.2.0 | release gate (no GitHub issue; defined by `testplan_1.2.0.md` "Release Gate") | Release gate | Open | Runs after M1-M15 close; gates the master merge + `1.2.0` tag. |
| M16.T1 | 1.2.0 | cycle batch re-run of all M1-M15 change-specific verifications on the final tree | Test sub | Open | — |
| M16.T2 | 1.2.0 | all four suites, both modes, both goldens, clone-and-test + install-and-test | Test sub | Open | — |
| M16.T3 | 1.2.0 | `testplan_multiuser.md` executed identically (S6/S11 amendments in effect) | Test sub | Open | — |

**Tally:** milestones Open 12 (11 work + 1 gate), Done 4 (M1-M4) · test subs Open 32, Done 9 (M1.T1/T2, M2.T1/T2, M3.T1/T2/T4, M4.T1/T2) · Blocked 0

## Milestone 1.2.0

Larger follow-ups requiring design or behavior changes beyond a patch.
GitHub milestone `1.2.0` — 11 open, 4 closed (#92, #93, #94, #87), due 2026-07-31. The work order is
M1-M15 plus the M16 release gate in the Active Register above; M16 is
register-local with no GitHub issue. The three template items #53, #54,
and #81 form one cluster — all edit the system unit template, so it is
touched once as a group, with #81 first as the byte-equivalence-gated
refactor. #96 (M13) was added 2026-06-11 as a spin-off of the M1 design
review; #97 (M14) and #98 (M15) were added 2026-06-12 from the M2 sweep,
with #98 worth pulling forward before the next T2-heavy milestone.

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
