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

**Next session entry point:** #76 dedicated-port fix landed on
`release-1.1.1` and VM-verified on `rocky8-iocrunner` + `debian13-iocrunner`
(local 48/48 and 49/49, system 74/74 on both, CA step 5/5) under the
co-located-IOC condition; the confirmed `SO_REUSEPORT`-fanout mechanism is
recorded in the #76 body. Remaining for #76: prod acceptance on
`alsucl-psrv3` (full local + system lifecycle green). Then the 1.1.1
additive items: #73 (`--user` alias, smallest), #72, #74, #75. Version is
`1.1.1-dev` (`bin/ioc-runner:14`). Do not start 1.2.0 items unless the owner
reorders them.

## Active Register

| Topic | Work unit | Type | Status | Evidence or next action |
| :--- | :--- | :--- | :--- | :--- |
| 1.1.1 | #66 chdir precheck — reject `..` components / canonical-path policy | Carry-forward | Done (`release-1.1.1`) | System-mode install precheck rejects a `..` component (whole/leading/interior/trailing) as a hard error, no `realpath`. `tests/test-error-handling.bash` cases 5/5b. Closes on master merge. P2-medium. |
| 1.1.1 | #69 lifecycle test runner selection (`IOC_RUNNER_TEST_MODE`) | Carry-forward | Done (`release-1.1.1`, verified) | `fb7d5aa`: source/installed selection in both lifecycle suites, error suite split out as standalone, deployed-preference guard removed. Verified on top (Debian 13) 328/328 across all four binary-by-mode combinations. VM gate PASSED 2026-06-01 on both `rocky8-iocrunner` and `debian13-iocrunner`, per binary mode: rocky8 local source 48/48, local installed 48/48, system-infra 40/40, system installed 74/74; debian13 49/49, 49/49, 41/41, 74/74. root_squash positive control confirmed on both (root mapped to nobody cannot execve the source binary on NFS). Prod (`alsucl-psrv3`, 2026-06-01): setup --full 9/9; local lifecycle in installed mode 47/48 with runner selection logged correct — the sole failure is STEP 24 Channel Access, split to #76 (test camonitor not isolated from co-located IOCs; identical failure on master 1.1.0, so not a #69 regression). System-lifecycle on prod (installed, sudo, root_squash) ran directly: 74/74 — fully green including Channel Access (5/5). Note the CA failure is local-mode-only and non-deterministic on this host: system passed CA with the same co-located IOCs up, so #76 is intermittent host-coexistence flakiness, not an always-fail. #69 prod path verified. `Refs #69` (no auto-close). P3-low. |
| 1.1.1 | #72 modular Makefile install system (global + user-home) | Milestone | Not started | New `configure/` Makefile wrapping install to `/usr/local/bin` and `$(HOME)/.local/bin`, `CONFIG_SITE.local` layering. Tooling only; no runner runtime change. |
| 1.1.1 | #73 `--user` alias for `--local` runtime mode | Milestone | Not started | Thin additive alias aligning with `systemctl --user`; `--local` stays primary. |
| 1.1.1 | #74 procServ/con search paths overridable via env + home-bin default | Milestone | Not started | Add `IOC_RUNNER_PROCSERV_TOOL` (mirroring `IOC_RUNNER_CON_TOOL`) and `$(HOME)/.local/bin` defaults. Resolves user-built procServ in `~/.local/bin` without editing the script. |
| 1.1.1 | #75 Debian 13 systemd `syslog` output type obsolete warning | Milestone | Not started | `bin/setup-system-infra.bash:483` sets `StandardOutput=syslog`; Debian 13 systemd flags the `syslog` value as obsolete. Move to `journal`, retaining `SyslogIdentifier=epics-%i`. System-mode template only; no local-mode change. P3-low. |
| 1.1.1 | #76 lifecycle STEP 24 CA test not isolated from co-located IOCs | Milestone | Done (`release-1.1.1`, VM-verified) | Mechanism confirmed on `rocky8-iocrunner` + `debian13-iocrunner`: co-located IOCs share UDP 5064 via `SO_REUSEPORT` datagram fanout (not `SO_REUSEADDR` as first hypothesized), so a unicast `EPICS_CA_ADDR_LIST=127.0.0.1` search reaches only one socket in the group and the test PV resolves ~1/N (9/40 with four same-uid sockets). The UID hypothesis holds only halfway: same-uid co-tenants share one fanout group, but different-uid reachability is kernel-dependent (rocky8 40/40, debian13 non-deterministic 0/40·10/10·40/40), so the system-mode pass on `alsucl-psrv3` was a favorable-kernel accident, not a guarantee. Fix: assign the test IOC a free dedicated `EPICS_CA_SERVER_PORT` (probed from 5095), injected into the generated conf (loaded via the systemd `EnvironmentFile`), with the matching client port in STEP 24; both suites, loopback scope preserved. Verified under the #76 decoy condition (3 co-located same-user IOCs on 5064): local 48/48 (rocky8), 49/49 (debian13); system 74/74 on both; CA step 5/5 every run. Prod (`alsucl-psrv3`) acceptance pending. `Refs #76` (closes on master merge). P3-low. |
| 1.2.0 | #68 distro-independent sudoers parity via validating `systemctl` wrapper | Carry-forward | Open | Closes the sudo < 1.9.10 residual risk from #57 (Rocky 8 / alsucl-psrv3 = 1.9.5p2). P2-medium. |
| 1.2.0 | #67 replace start/restart fixed `sleep 5` with active-state polling | Carry-forward | Open | `bin/ioc-runner:1536-1547`; preserve the crash-pattern scan that follows. P3-low. |
| 1.2.0 | #54 add `Restart=` policy to system template unit | Carry-forward | Open | Evaluate `always` vs `on-failure`; interacts with #67 and #52. |
| 1.2.0 | #53 review missing `Requires`/`Wants` (and `Before`/`After`) in template unit | Carry-forward | Open | Per systemd unit-ordering guidance. |
| 1.2.0 | #52 review procServ child-exit signals for crash-loop detection | Carry-forward | Open | Follows up #11; extends #24 edge-case review. Clusters with #54, #67. |

**Tally:** Done 3 · Open 5 · Not started 4 · In progress 0 · Blocked 0

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
| [#72](https://github.com/jeonghanlee/epics-ioc-runner/issues/72) | Add a modular Makefile install system (global and user-home install) | enhancement | New `configure/` Makefile (EPICS configure/ pattern, as in `linux-home-env`). Global install to `/usr/local/bin`, user-home install to `$(HOME)/.local/bin`, `CONFIG_SITE.local` override layering. Tooling only; `bin/ioc-runner` runtime behavior unchanged. |
| [#73](https://github.com/jeonghanlee/epics-ioc-runner/issues/73) | Add `--user` as an alias for `--local` runtime mode | enhancement | Accept `--user` wherever `--local` is accepted; route to the same code path. Aligns with `systemctl --user`. `--local` stays primary and documented. Backward-compatible additive change. |
| [#74](https://github.com/jeonghanlee/epics-ioc-runner/issues/74) | Make procServ/con search paths overridable via env, with home-bin default | enhancement | Add `IOC_RUNNER_PROCSERV_TOOL` mirroring the existing `IOC_RUNNER_CON_TOOL`, and add `${HOME}/.local/bin` to both default search lists. Resolution order: `IOC_RUNNER_*_TOOL` -> `${HOME}/.local/bin` -> `/usr/local/bin` -> `/usr/bin`. `PROCSERV_SEARCH_PATHS` is local-mode only, so no system-mode shadowing. |
| [#75](https://github.com/jeonghanlee/epics-ioc-runner/issues/75) | Debian 13 systemd warns about output type "syslog" being obsolete | P3-low | `bin/setup-system-infra.bash:483` sets `StandardOutput=syslog` in the systemd template unit; Debian 13 systemd logs that the `syslog` output type is obsolete. Switch to `journal`; `SyslogIdentifier=epics-%i` continues to tag entries. System-mode template only. |
| [#76](https://github.com/jeonghanlee/epics-ioc-runner/issues/76) | Lifecycle STEP 24 CA test not isolated from co-located IOCs | P3-low | STEP 24 of both lifecycle suites forces a unicast `EPICS_CA_ADDR_LIST=127.0.0.1` CA search; on a host already running other IOCs that share UDP 5064 the search reaches the wrong server and the PV is never found. Assign the test IOC a dedicated `EPICS_CA_SERVER_PORT`. Test harness only; reproduces on master 1.1.0. Surfaced verifying #69 on `alsucl-psrv3`. |

## Milestone 1.2.0

Larger follow-ups requiring design or behavior changes beyond a patch. GitHub
milestone `1.2.0` — 5 open.

| Issue | Title | Priority | Notes |
| --- | --- | --- | --- |
| [#68](https://github.com/jeonghanlee/epics-ioc-runner/issues/68) | Distro-independent sudoers parity via a validating `systemctl` wrapper | P2-medium | sudoers cannot enforce "via the runner only" and old sudo cannot anchor argument regex; on sudo < 1.9.10 the glob stays broader than the runner's IOC-name model. A uniform boundary needs a wrapper, not sudoers globs/regex. Closes the #57 residual risk. |
| [#67](https://github.com/jeonghanlee/epics-ioc-runner/issues/67) | Replace start/restart fixed `sleep 5` with active-state polling | P3-low | `bin/ioc-runner:1536-1547`: fixed `sleep 5` then a single post-state check. A unit crash-looping with `Restart=` can momentarily read `active` at second 5 and pass. Re-check active state after the crash scan; preserve a minimum stabilization window. |
| [#54](https://github.com/jeonghanlee/epics-ioc-runner/issues/54) | Add restart policy to system template unit | enhancement | Template unit defines no `Restart=`; evaluate `always` vs `on-failure`. Couples with #67 (timing) and #52 (exit-signal semantics). |
| [#53](https://github.com/jeonghanlee/epics-ioc-runner/issues/53) | Possibly missing `Requires`/`Wants` in template systemd unit | enhancement | Per systemd unit docs, review `Requires`/`Wants` and `Before`/`After` ordering for the template unit. |
| [#52](https://github.com/jeonghanlee/epics-ioc-runner/issues/52) | Review procServ child-exit signals for crash-loop detection | enhancement | Follows #11 (byte-offset crash detection) and extends the #24 journal-fallback edge-case review. Current pattern set catches explicit fatal output; review child-exit signal handling for crash-loop cases. |

## Notes

- The `Backlog` GitHub milestone is empty; all post-1.1.0 carry-forwards have
  been triaged into `1.1.1` and `1.2.0`.
- The released 1.1.0 record (phase plan, acceptance, test plan) lives in git
  tag `1.1.0`: `git show 1.1.0:docs/MILESTONE-1.1.0.md` and
  `git show 1.1.0:docs/TEST_PLAN-1.1.0.md`. The permission-model end state
  remains current in `docs/PERMISSION_MODEL.md`.
