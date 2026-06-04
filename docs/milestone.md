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

**1.1.1 release target:** July 2026. A ~1-month testing and feedback window
(opened late May 2026) precedes the release; patches land on `release-1.1.1`
during that window.

**Next session entry point:** #76 dedicated-port fix prod-accepted on
`alsucl-psrv3` (2026-06-02): local installed 48/48, system infra 40/40,
system installed 74/74, CA 5/5 throughout, under live co-located IOCs
sharing UDP 5064. The confirmed `SO_REUSEPORT`-fanout mechanism is recorded
in the #76 body. #76 closed 2026-06-02; its code merges to master at the
1.1.1 release. #73 done 2026-06-02 (`a4d3bef`, verified top + both VM
gates, GitHub closed). #72 done 2026-06-03 (modular Makefile install
system, both VM gates + external review, GitHub closed). #74 done
2026-06-03 (`322171b`, `IOC_RUNNER_PROCSERV_TOOL` + home-bin search with a
trusted-HOME guard; top + both VM gates + external post-commit review;
GitHub closed). #75 done 2026-06-04 (`StandardOutput=syslog` -> `journal` in
both the local user unit and the system template; top static + both VM gates on
freshly rebaked goldens; debian13 systemd 257 root-cause control; closes
coherence finding CI-1; `Closes #75` on master merge). #79 done 2026-06-04
(CI-2, prerequisite wording aligned with the `~/.local/bin` resolver order,
docs only, external review accepted, `Closes #79` on master merge). #80 done 2026-06-04 (CI-3,
crash-detection comment updated to the log-file-scan contract, comment-only,
external review accepted, `Closes #80` on master merge). All 1.1.1 issues are
now Done (code-complete on `release-1.1.1`); next entry point is the 1.1.1
release sequence (master merge + annotated tag) after the testing window
closes, then the 1.2.0 items. Version
is `1.1.1-dev` (`bin/ioc-runner:14`). Do not start 1.2.0 items unless the owner
reorders them. Two #74 follow-ups are deferred to #77 (`_setup` suite-wide procServ
mock) and #78 (`-x`/`-f` executable-directory resolver policy common to con
and procServ).

## Active Register

| Topic | Work unit | Type | Status | Evidence or next action |
| :--- | :--- | :--- | :--- | :--- |
| 1.1.1 | #66 chdir precheck — reject `..` components / canonical-path policy | Carry-forward | Done (`release-1.1.1`) | System-mode install precheck rejects a `..` component (whole/leading/interior/trailing) as a hard error, no `realpath`. `tests/test-error-handling.bash` cases 5/5b — full static suite 94/94 on `release-1.1.1`. GitHub issue closed manually 2026-06-02; code merges to master at the 1.1.1 release. P2-medium. |
| 1.1.1 | #69 lifecycle test runner selection (`IOC_RUNNER_TEST_MODE`) | Carry-forward | Done (`release-1.1.1`, verified) | `fb7d5aa`: source/installed selection in both lifecycle suites, error suite split out as standalone, deployed-preference guard removed. Verified on top (Debian 13) 328/328 across all four binary-by-mode combinations. VM gate PASSED 2026-06-01 on both `rocky8-iocrunner` and `debian13-iocrunner`, per binary mode: rocky8 local source 48/48, local installed 48/48, system-infra 40/40, system installed 74/74; debian13 49/49, 49/49, 41/41, 74/74. root_squash positive control confirmed on both (root mapped to nobody cannot execve the source binary on NFS). Prod (`alsucl-psrv3`, 2026-06-01): setup --full 9/9; local lifecycle in installed mode 47/48 with runner selection logged correct — the sole failure is STEP 24 Channel Access, split to #76 (test camonitor not isolated from co-located IOCs; identical failure on master 1.1.0, so not a #69 regression). System-lifecycle on prod (installed, sudo, root_squash) ran directly: 74/74 — fully green including Channel Access (5/5). Note the CA failure is local-mode-only and non-deterministic on this host: system passed CA with the same co-located IOCs up, so #76 is intermittent host-coexistence flakiness, not an always-fail. #69 prod path verified. `Refs #69` (no auto-close — GitHub issue closed manually 2026-06-01). P3-low. |
| 1.1.1 | #72 modular Makefile install system (global + user-home) | Milestone | Done (`release-1.1.1`, both VM gates + external review) | `Makefile` + `configure/` front end (EPICS pattern). `install`/`setup` delegate to `setup-system-infra.bash` (STEP 7 / `--full`), run as the user with sudo inside the recipe via a relative script path, so they work in place on an NFS root_squash home; `install.user` is a no-root user-home copy with version injection. `install` <-> `uninstall` parity (CLI only); full teardown stays in `docs/UNINSTALL.md`. System path fixed to the script defaults (`/usr/local/bin`, `/etc/bash_completion.d`, `/usr/bin` symlink); `CONFIG_SITE.local` overrides the user-home path (`HOME_BIN`). Verified top static + both VM gates (rocky8 local 51/51, system 74/74; debian13 local 52/52, system 74/74; Rocky symlink created, absent on Debian). External review accepted (R1 `mkdir -p` preserves existing home-dir perms; R2 symlink removal guarded by `readlink`). `Closes #72` (auto-close on master merge); GitHub closed manually 2026-06-03. Enhancement. |
| 1.1.1 | #73 `--user` alias for `--local` runtime mode | Milestone | Done (`release-1.1.1`) | `a4d3bef`: single-parse-case merge `--local\|--user` (same `set_local_mode`), help alias note, completion opts + local-path detection, `CLI_REFERENCE` alias line, new local-lifecycle STEP `test_user_alias` (cross-query — a `--local`-started IOC observed through `--user`). Verified top 52/52, rocky8-iocrunner 51/51, debian13-iocrunner 52/52 (each base + 3 alias assertions), STEP 23 3/3 on all three. `Closes #73` (auto-close on master merge); GitHub issue also closed manually 2026-06-02. Enhancement. |
| 1.1.1 | #74 procServ/con search paths overridable via env + home-bin default | Milestone | Done (`release-1.1.1`, both VM gates + external review) | `322171b`: `IOC_RUNNER_PROCSERV_TOOL` added (mirrors `resolve_con_tool` override/search skeleton, `-x` check, no socat/nc fallback); `deploy_local_template` calls `resolve_procserv_tool` instead of an inline loop. `${HOME}/.local/bin` prepended to both `CON_SEARCH_PATHS`/`PROCSERV_SEARCH_PATHS`, gated on `HOME_TRUSTED` so a bare-sudo `/tmp` fallback HOME (world-writable) is never a trusted executable source. New `test_tool_resolution` (4 cases / 7 assertions) in `test-error-handling.bash`, `_setup` untouched. Verified top (error 101/101, local 52/52) + both VM gates: rocky8 error 101/101 · local 51/51 · system-infra 40/40 · system 74/74 (re-run on the 2026-06-03 rebaked golden carrying the includedir fix); debian13 101/101 · 52/52 · 41/41 · 74/74. External post-commit review accepted (trusted-HOME gate + resolver mirror confirmed; the 7 SC1090 are pre-existing completion-test warnings). `Closes #74` (auto-close on master merge); GitHub closed manually 2026-06-03. Deferred to #77 (`_setup` suite-wide procServ mock) and #78 (`-x`/`-f` executable-directory resolver policy). Enhancement. |
| 1.1.1 | #75 Debian 13 systemd `syslog` output type obsolete warning | Milestone | Done (`release-1.1.1`, both VM gates + root-cause control) | `StandardOutput=syslog` -> `journal` in both generated units: the local user unit (`bin/ioc-runner:376`, the line the issue reproduced via `systemctl --user`) and the system template (`bin/setup-system-infra.bash:483`); `docs/INSTALL.md` template copy and `docs/LOG_LAYOUT.md` (section 1 wording) aligned. `StandardError=inherit`/`SyslogIdentifier=epics-%i` unchanged. (Earlier register text mis-scoped this system-mode only; original evidence is local-mode. Closes coherence finding CI-1.) Verified on freshly rebaked goldens (2026-06-04, ansible failed=0, corrupt:false): top static 101/101; rocky8-iocrunner local 51/51 · setup 9/9 · system-infra 40/40 · system 74/74; debian13-iocrunner local 52/52 · setup 8/8 · system-infra 41/41 · system 74/74; deployed templates show `journal` on both. Root cause confirmed on debian13 systemd 257 by control: a `journal` unit emits no obsolete warning, a `syslog` unit still does. `Closes #75` (auto-close on master merge). P3-low. |
| 1.1.1 | #79 align local-mode tool prerequisite wording with the `~/.local/bin` resolver order | Coherence (CI-2) | Done (`release-1.1.1`) | `README.md:9` now lists `~/.local/bin` (with a local-mode qualifier), `/usr/local/bin`, `/usr/bin`; `docs/USER_GUIDE_LOCAL.md:6` states the local search order + `IOC_RUNNER_*_TOOL` override and defers the full order to section 14 (`:210`). Docs only; static suite parses source not docs, so no regression surface; `git diff --check` clean. External review accepted. `Closes #79` (auto-close on master merge). documentation, P3-low. |
| 1.1.1 | #80 update system-lifecycle crash-detection comments to the log-file-scan contract | Coherence (CI-3) | Done (`release-1.1.1`) | `tests/test-system-lifecycle.bash:777-778` comment replaced: it claimed `test_crash_detection` disabled/journal-dependent, but the test is active (L1478) and passes via the inline log-file scan (1.1.0 decoupling, `PERMISSION_MODEL.md:338-345`). Comment-only; `bash -n` clean, `git diff --check` clean, function body unchanged. System 74/74 holds transitively from the #75 gate (same function, comment cannot affect execution). External review accepted. `Closes #80` (auto-close on master merge). tests, P3-low. |
| 1.1.1 | #76 lifecycle STEP 24 CA test not isolated from co-located IOCs | Milestone | Done (`release-1.1.1`, prod-accepted) | Mechanism confirmed on `rocky8-iocrunner` + `debian13-iocrunner`: co-located IOCs share UDP 5064 via `SO_REUSEPORT` datagram fanout (not `SO_REUSEADDR` as first hypothesized), so a unicast `EPICS_CA_ADDR_LIST=127.0.0.1` search reaches only one socket in the group and the test PV resolves ~1/N (9/40 with four same-uid sockets). The UID hypothesis holds only halfway: same-uid co-tenants share one fanout group, but different-uid reachability is kernel-dependent (rocky8 40/40, debian13 non-deterministic 0/40·10/10·40/40), so the system-mode pass on `alsucl-psrv3` was a favorable-kernel accident, not a guarantee. Fix: assign the test IOC a free dedicated `EPICS_CA_SERVER_PORT` (probed from 5095), injected into the generated conf (loaded via the systemd `EnvironmentFile`), with the matching client port in STEP 24; both suites, loopback scope preserved. Verified under the #76 decoy condition (3 co-located same-user IOCs on 5064): local 48/48 (rocky8), 49/49 (debian13); system 74/74 on both; CA step 5/5 every run. Prod (`alsucl-psrv3`, 2026-06-02) accepted under live co-located IOCs (`lakeshore211`, `tcmd` sharing UDP 5064 as `jeonglee`): local installed 48/48 (CA 5/5), system infra 40/40, system installed 74/74 (CA 5/5) — the `ioc-srv` test IOC ran against different-uid co-tenants, the exact case the dedicated port hardens. System suite executed from a `/tmp` copy of the tree because the NFS home (`0700`) + `root_squash` blocks `sudo` from reading the source scripts; procedure in `tests/README.md`. GitHub issue closed 2026-06-02; code merges to master at the 1.1.1 release. P3-low. |
| 1.2.0 | #68 distro-independent sudoers parity via validating `systemctl` wrapper | Carry-forward | Open | Closes the sudo < 1.9.10 residual risk from #57 (Rocky 8 / alsucl-psrv3 = 1.9.5p2). P2-medium. |
| 1.2.0 | #67 replace start/restart fixed `sleep 5` with active-state polling | Carry-forward | Open | `bin/ioc-runner:1536-1547`; preserve the crash-pattern scan that follows. P3-low. |
| 1.2.0 | #54 add `Restart=` policy to system template unit | Carry-forward | Open | Evaluate `always` vs `on-failure`; interacts with #67 and #52. |
| 1.2.0 | #53 review missing `Requires`/`Wants` (and `Before`/`After`) in template unit | Carry-forward | Open | Per systemd unit-ordering guidance. |
| 1.2.0 | #52 review procServ child-exit signals for crash-loop detection | Carry-forward | Open | Follows up #11; extends #24 edge-case review. Clusters with #54, #67. |
| 1.2.0 | #77 error suite host-independent of procServ via a `_setup` mock | Spin-off (#74) | Open | Existing `--local install` cases still resolve a host procServ via `deploy_local_template`; export a `_setup` procServ mock (mirror the con mock), resolution tests override/unset it. tests, P3-low. |
| 1.2.0 | #78 tighten `IOC_RUNNER_*_TOOL` override to reject directories | Spin-off (#74) | Open | Both `resolve_con_tool` and `resolve_procserv_tool` check `-x` only, so an executable directory passes; apply `-f && -x` to both. enhancement, P3-low. |

**Tally:** Done 9 · Open 7 · Not started 0 · In progress 0 · Blocked 0

## Milestone 1.1.1

Target: July 2026. Two carry-forwards from the 1.1.0 audit, three small
additive items (Makefile install front end, `--user` alias, procServ/con
search-path override), plus a Debian 13 systemd logging-deprecation fix (#75)
and a lifecycle CA test isolation fix (#76), both surfaced during the testing
window. Release after a ~1-month testing and feedback window.

GitHub milestone `1.1.1` (number 10), due `2026-07-31`. Description: `Patch
plus small additive items: chdir precheck, test-mode selection, Makefile
install front end, --user alias, procServ/con search-path override`.

| Issue | Title | Priority | Notes |
| --- | --- | --- | --- |
| [#66](https://github.com/jeonghanlee/epics-ioc-runner/issues/66) | chdir precheck: reject `..` components / canonical-path policy | P2-medium | `chdir_conforms_to_system_model` walks parents lexically; `..` in `IOC_CHDIR` diverges the validated parent set from the resolved path. Deferred from 1.1.0 because `realpath` canonicalization would change the per-segment symlink-rejection posture for a check that only gates a warning + y/N prompt. |
| [#69](https://github.com/jeonghanlee/epics-ioc-runner/issues/69) | Lifecycle test runner selection: `IOC_RUNNER_TEST_MODE` | P3-low | Lifecycle scripts choose the runner binary by inconsistent, unlogged rules; an out-of-date installed binary once masked a passing fix. Add explicit mode selection and log the resolved binary. The low-risk observability half shipped in 1.1.0 as #71. |
| [#72](https://github.com/jeonghanlee/epics-ioc-runner/issues/72) | Add a modular Makefile install system (global and user-home install) | enhancement | New `configure/` Makefile (EPICS configure/ pattern, as in `linux-home-env`). Global install to `/usr/local/bin`, user-home install to `$(HOME)/.local/bin`. Implemented scope: the system path is fixed to the `setup-system-infra.bash` defaults; `CONFIG_SITE.local` overrides the user-home path (`HOME_BIN`) only. Tooling only; `bin/ioc-runner` runtime behavior unchanged. |
| [#73](https://github.com/jeonghanlee/epics-ioc-runner/issues/73) | Add `--user` as an alias for `--local` runtime mode | enhancement | Accept `--user` wherever `--local` is accepted; route to the same code path. Aligns with `systemctl --user`. `--local` stays primary and documented. Backward-compatible additive change. |
| [#74](https://github.com/jeonghanlee/epics-ioc-runner/issues/74) | Make procServ/con search paths overridable via env, with home-bin default | enhancement | Add `IOC_RUNNER_PROCSERV_TOOL` mirroring the existing `IOC_RUNNER_CON_TOOL`, and add `${HOME}/.local/bin` to both default search lists. Resolution order: `IOC_RUNNER_*_TOOL` -> `${HOME}/.local/bin` -> `/usr/local/bin` -> `/usr/bin`. `PROCSERV_SEARCH_PATHS` is local-mode only, so no system-mode shadowing. |
| [#75](https://github.com/jeonghanlee/epics-ioc-runner/issues/75) | Debian 13 systemd warns about output type "syslog" being obsolete | P3-low | Both generated units set `StandardOutput=syslog`: the local user unit (`bin/ioc-runner:376`, where the issue reproduced via `systemctl --user`) and the system template (`bin/setup-system-infra.bash:483`). Debian 13 systemd logs that the `syslog` output type is obsolete. Switch both to `journal`; `SyslogIdentifier=epics-%i` continues to tag entries. |
| [#76](https://github.com/jeonghanlee/epics-ioc-runner/issues/76) | Lifecycle STEP 24 CA test not isolated from co-located IOCs | P3-low | STEP 24 of both lifecycle suites forces a unicast `EPICS_CA_ADDR_LIST=127.0.0.1` CA search; on a host already running other IOCs that share UDP 5064 the search reaches the wrong server and the PV is never found. Assign the test IOC a dedicated `EPICS_CA_SERVER_PORT`. Test harness only; reproduces on master 1.1.0. Surfaced verifying #69 on `alsucl-psrv3`. |
| [#79](https://github.com/jeonghanlee/epics-ioc-runner/issues/79) | Align local-mode tool prerequisite wording with the `~/.local/bin` resolver order | documentation, P3-low | Coherence finding CI-2. Prerequisite intros (`docs/USER_GUIDE_LOCAL.md:6`, `README.md:9`) still require `/usr/bin` or `/usr/local/bin` only, omitting the `~/.local/bin` search added by #74. Align with the order already documented at `USER_GUIDE_LOCAL.md:210`. Docs only. |
| [#80](https://github.com/jeonghanlee/epics-ioc-runner/issues/80) | Update system-lifecycle crash-detection comments to the log-file-scan contract | tests, P3-low | Coherence finding CI-3. The comment at `tests/test-system-lifecycle.bash:777-778` marks `test_crash_detection` disabled and journal-dependent, but it is active (L1478) and passes via the log-file scan since the 1.1.0 journal decoupling. Comment-only correction. |

## Milestone 1.2.0

Larger follow-ups requiring design or behavior changes beyond a patch. GitHub
milestone `1.2.0` — 7 open.

| Issue | Title | Priority | Notes |
| --- | --- | --- | --- |
| [#68](https://github.com/jeonghanlee/epics-ioc-runner/issues/68) | Distro-independent sudoers parity via a validating `systemctl` wrapper | P2-medium | sudoers cannot enforce "via the runner only" and old sudo cannot anchor argument regex; on sudo < 1.9.10 the glob stays broader than the runner's IOC-name model. A uniform boundary needs a wrapper, not sudoers globs/regex. Closes the #57 residual risk. |
| [#67](https://github.com/jeonghanlee/epics-ioc-runner/issues/67) | Replace start/restart fixed `sleep 5` with active-state polling | P3-low | `bin/ioc-runner:1536-1547`: fixed `sleep 5` then a single post-state check. A unit crash-looping with `Restart=` can momentarily read `active` at second 5 and pass. Re-check active state after the crash scan; preserve a minimum stabilization window. |
| [#54](https://github.com/jeonghanlee/epics-ioc-runner/issues/54) | Add restart policy to system template unit | enhancement | Template unit defines no `Restart=`; evaluate `always` vs `on-failure`. Couples with #67 (timing) and #52 (exit-signal semantics). |
| [#53](https://github.com/jeonghanlee/epics-ioc-runner/issues/53) | Possibly missing `Requires`/`Wants` in template systemd unit | enhancement | Per systemd unit docs, review `Requires`/`Wants` and `Before`/`After` ordering for the template unit. |
| [#52](https://github.com/jeonghanlee/epics-ioc-runner/issues/52) | Review procServ child-exit signals for crash-loop detection | enhancement | Follows #11 (byte-offset crash detection) and extends the #24 journal-fallback edge-case review. Current pattern set catches explicit fatal output; review child-exit signal handling for crash-loop cases. |
| [#77](https://github.com/jeonghanlee/epics-ioc-runner/issues/77) | Make the error suite host-independent of procServ via a `_setup` mock | tests, P3-low | Spin-off from #74. The existing `--local install` cases reach `deploy_local_template` -> `resolve_procserv_tool` and still require a host procServ, contradicting the suite header. Export a mock procServ in `_setup` (mirror the con mock); resolution tests override or unset it within scope. |
| [#78](https://github.com/jeonghanlee/epics-ioc-runner/issues/78) | Tighten `IOC_RUNNER_*_TOOL` override check to reject directories (`-f && -x`) | enhancement, P3-low | Spin-off from #74. Both `resolve_con_tool` and `resolve_procserv_tool` validate the override with `-x` only; an executable directory passes. Apply `-f && -x` to both resolvers in one change. |

## Coherence Sweep Findings (2026-06-04)

Findings from a whole-codebase conceptual-integrity sweep: seams where
independently finished pieces need a fate decision. Status uses the register
markers; a resolved finding links to the work unit that closed it. The
`Evidence` line offsets are as recorded by the sweep.

| ID | Finding | Evidence | Status | Resolution / fate |
| --- | --- | --- | --- | --- |
| CI-1 | The obsolete systemd `syslog` output policy is duplicated across both generated units, while #75 was first scoped system-mode only. | `bin/ioc-runner:376`, `bin/setup-system-infra.bash:483`, `docs/INSTALL.md:130` | Resolved (#75) | Generalized #75 to both units (`StandardOutput=journal`); register scope corrected to name both. |
| CI-2 | The prerequisite intros still require `procServ`/`con` in `/usr/bin` or `/usr/local/bin`, omitting the trusted `~/.local/bin` search added by #74. Stale spots: `docs/USER_GUIDE_LOCAL.md:6`, `README.md:9`. Note `docs/USER_GUIDE_LOCAL.md:210` already states the correct resolver order, so it is the alignment reference, not a defect. | `docs/USER_GUIDE_LOCAL.md:6`, `README.md:9` (stale); `docs/USER_GUIDE_LOCAL.md:210`, `bin/ioc-runner:66-72` (correct refs) | Resolved (#79) | Aligned the two prerequisite intros with the resolver search order documented at `USER_GUIDE_LOCAL.md:210`. Filed and fixed as #79 (1.1.1). |
| CI-3 | System-lifecycle crash-detection comments describe a disabled, journal-dependent test, but the test is active and the log-file scan is the current contract (1.1.0 journal decoupling). | `tests/test-system-lifecycle.bash:777-779`, `tests/test-system-lifecycle.bash:1478`, `docs/PERMISSION_MODEL.md:338-345` | Resolved (#80) | Replaced the stale comment with the log-file-scan premise. Filed and fixed as #80 (1.1.1). |

## Notes

- The `Backlog` GitHub milestone is empty; all post-1.1.0 carry-forwards have
  been triaged into `1.1.1` and `1.2.0`.
- The released 1.1.0 record (phase plan, acceptance, test plan) lives in git
  tag `1.1.0`: `git show 1.1.0:docs/MILESTONE-1.1.0.md` and
  `git show 1.1.0:docs/TEST_PLAN-1.1.0.md`. The permission-model end state
  remains current in `docs/PERMISSION_MODEL.md`.
