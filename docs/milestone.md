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

**Next session entry point:** bump `RUNNER_VERSION` in `bin/ioc-runner:14` from
`1.1.0` to `1.1.1-dev` on `master`, then start #66 (chdir precheck) in
`bin/ioc-runner:860-883`. Preserve the 1.1.0 per-segment symlink rejection
posture — do not introduce `realpath` canonicalization that weakens it. Do not
start 1.2.0 items unless the owner reorders them.

## Active Register

| Topic | Work unit | Type | Status | Evidence or next action |
| :--- | :--- | :--- | :--- | :--- |
| 1.1.1 | #66 chdir precheck — reject `..` components / canonical-path policy | Carry-forward | Open | Start in `bin/ioc-runner:860-883`; parent walk diverges from resolved path on `..`. P2-medium. |
| 1.1.1 | #69 lifecycle test runner selection (`IOC_RUNNER_TEST_MODE`) | Carry-forward | Open | Unify binary resolution + log resolved binary in `tests/test-system-lifecycle.bash` and `tests/test-local-lifecycle.bash`. P3-low. |
| 1.2.0 | #68 distro-independent sudoers parity via validating `systemctl` wrapper | Carry-forward | Open | Closes the sudo < 1.9.10 residual risk from #57 (Rocky 8 / alsucl-psrv3 = 1.9.5p2). P2-medium. |
| 1.2.0 | #67 replace start/restart fixed `sleep 5` with active-state polling | Carry-forward | Open | `bin/ioc-runner:1536-1547`; preserve the crash-pattern scan that follows. P3-low. |
| 1.2.0 | #54 add `Restart=` policy to system template unit | Carry-forward | Open | Evaluate `always` vs `on-failure`; interacts with #67 and #52. |
| 1.2.0 | #53 review missing `Requires`/`Wants` (and `Before`/`After`) in template unit | Carry-forward | Open | Per systemd unit-ordering guidance. |
| 1.2.0 | #52 review procServ child-exit signals for crash-loop detection | Carry-forward | Open | Follows up #11; extends #24 edge-case review. Clusters with #54, #67. |

**Tally:** Open 7 · In progress 0 · Blocked 0

## Milestone 1.1.1

Patch-level carry-forwards from the 1.1.0 audit. GitHub milestone `1.1.1` — 2 open.

| Issue | Title | Priority | Notes |
| --- | --- | --- | --- |
| [#66](https://github.com/jeonghanlee/epics-ioc-runner/issues/66) | chdir precheck: reject `..` components / canonical-path policy | P2-medium | `chdir_conforms_to_system_model` walks parents lexically; `..` in `IOC_CHDIR` diverges the validated parent set from the resolved path. Deferred from 1.1.0 because `realpath` canonicalization would change the per-segment symlink-rejection posture for a check that only gates a warning + y/N prompt. |
| [#69](https://github.com/jeonghanlee/epics-ioc-runner/issues/69) | Lifecycle test runner selection: `IOC_RUNNER_TEST_MODE` | P3-low | Lifecycle scripts choose the runner binary by inconsistent, unlogged rules; an out-of-date installed binary once masked a passing fix. Add explicit mode selection and log the resolved binary. The low-risk observability half shipped in 1.1.0 as #71. |

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
