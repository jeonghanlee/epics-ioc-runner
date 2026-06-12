# EPICS IOC Runner — Test Plan 1.2.0

Cycle test plan for the 1.2.0 milestones M1-M13 (work order and issue
references in [`milestone.md`](milestone.md)). Drafted at cycle start
(2026-06-11); cases discovered during the work are added under "Added
During Cycle". Before the final release this plan is executed in full and
remains the cycle's verification record, preserved in the `1.2.0` tag.

The version-independent multi-user scenarios live in
[`testplan_multiuser.md`](testplan_multiuser.md) and run identically at
every release gate; this plan schedules their execution and records which
scenarios this cycle's changes amend.

## Verification Layers

Each milestone is verified in two layers:

1. **Change-specific verification** — designed per milestone in its design
   conversation, with depth chosen by blast radius: static checks, local
   suites on the dev host, system suites on a VM golden, up to the full
   two-golden VM gate (clone-and-test and install-and-test paths).
2. **Automated suites** — `tests/test-local-lifecycle.bash`,
   `tests/test-system-infra.bash`, `tests/test-system-lifecycle.bash`,
   `tests/test-error-handling.bash`. Where an issue's acceptance criteria
   name concrete cases, the cases are added to the suites as permanent
   regression assets, not run as one-off checks.

Suite baseline at cycle start: all suites green on both golden images at
the 1.1.1 release gate (record in `git show 1.1.1:docs/milestone.md`).

The milestone register tracks each verification as `M<n>.T<k>` subs that
map onto this plan: T1 = the "Change-specific verification" column, T2 =
the "Suite coverage and new cases" column, T3 = the milestone's row in the
Dependency Re-run Matrix, T4 = a standing-plan amendment. Sub status is
authoritative in each issue's Verification checkbox list on GitHub and
mirrored by the register; procedures live here. Every milestone closure
ends with a reconcile pass comparing issue state against the register.

## Per-Milestone Verification

| M | Issue | Change-specific verification | Suite coverage and new cases |
| :--- | :--- | :--- | :--- |
| M1 | #92 | Reproduce on a VM golden: an operator's manual `st.cmd` run leaves a `0600` cross-owned `.iocsh_history`; a subsequent service start must not warn after the fix. Verify the chosen design (per the #92 Design Record: `CRASH_LOG_EXCLUDE_PATTERNS` pre-filter + FAQ Q5 corrected knob) against a real history-load `ERROR` line, pinning the raw log bytes (`grep -a`; the line carries ANSI escapes). | New cases per the Design Record: raw-ANSI fixture set in error-handling (filter pins, `writing` variant, line-targeted proof, same-line residual) and root-free `chmod 0` probes with self-validation in local lifecycle; existing crash-detection cases stay green. |
| M2 | #93 | Both abort branches (prompt `n`, stdin EOF) exit with the chosen convention; behavior identical across install paths. | New error-suite cases pinning both branches' exit codes. |
| M3 | #94 | As a non-`ioc` principal with IOCs running: empty `list` result carries the permission hint (or the documented behavior). Amends `testplan_multiuser.md` S6. | Suite case where test mode permits a non-`ioc` probe; otherwise covered by the S6 re-run at the gate. |
| M4 | #87 | On a VM golden: run setup and runner with `IOC_RUNNER_SYSTEM_USER`/`IOC_RUNNER_SYSTEM_GROUP` overrides — both scripts resolve the same identity; the default path is unchanged. | New guard test pinning the shared `ioc-srv`/`ioc` defaults; system-infra suite green on defaults. |
| M5 | #81 | Byte-equivalence of the must-agree lines between pre- and post-refactor emitted units, both modes. Negative check: a one-sided edit of a must-agree line fails the new guard test. Re-runs the M4 guard test. | New shared-contract guard test; both lifecycle suites green on top and on both VM gates (issue acceptance). |
| M6 | #84 | The guard test is the deliverable: passes on the current tree; fails on a one-sided edit of each of the three metadata copies (negative check). Record the CI-10/CI-14 fold decision. | New static guard test pinning the shared `declare -g RUNNER_*`/`sed` contract. |
| M7 | #86 | Decision-first: unify the callers (option A), change the helper contract, or keep option B with a recorded verdict. If code changes: socket-path resolution identical pre/post for all three callers. | Both lifecycle suites (attach/monitor/inspect paths) green. |
| M8 | #52 | Positive: a silent child crash loop emitting `The process was killed by signal` after the new child starts is warned. Negative: a healthy `restart` does not warn. System-wide crash path verified on both goldens. Re-runs the M1 case. | New restart-negative and child-kill-positive cases; the existing crash-detection set stays green. |
| M9 | #53 | Review outcome first; may close as no-change with the verdict recorded in the register. If the template changes: `systemd-analyze verify` on a deployed unit; re-runs the M5 shared-contract guard. | Both lifecycle suites green. |
| M10 | #54 | `Restart=` policy chosen from the M8 exit-signal findings; crash-loop behavior under the chosen policy matches the design, including the `SuccessExitStatus` interplay. Re-runs the M5 guard and the crash-detection cases. | Both lifecycle suites green. |
| M11 | #67 | A crash-looping IOC is reported failed, not "successfully started"; a healthy start/restart is not slowed beyond the stabilization window. Re-runs the M1 and M8 crash cases. | Both lifecycle suites green (start/restart hot path). |
| M12 | #68 | The wrapper accepts in-contract IOC names and rejects out-of-contract names identically on both distros; the sudoers policy narrows to the wrapper; CI-20/CI-21 dispositions recorded. Amends `testplan_multiuser.md` S11 (residual risk closed). | System suites on both goldens (covering both sudoers emission branches); multi-user sudo-gate subset (S1, S6, S11) re-run. |
| M13 | #96 | The ineffective `epicsEnvSet("IOCSH_HISTSIZE","0")` line is removed and the adjacent comment names the actual safeguard (group-writable probe directory); `test_logrotate_boundary` passes unchanged in behavior. | System-lifecycle suite green on both goldens. |

## Dependency Re-run Matrix

A milestone that passed individually can be invalidated by later work on a
shared surface. The matrix schedules the re-verification points; the batch
re-run at the release gate closes everything against the released tree.

| Trigger | Re-run | Shared surface |
| :--- | :--- | :--- |
| M5 (#81) | M4 guard test + both lifecycle suites | template emission in both scripts |
| M8 (#52) | M1 crash-scan case | `CRASH_LOG_PATTERNS` / scan logic |
| M9, M10 | M5 shared-contract guard + both lifecycle suites | template content via the emitter |
| M11 (#67) | M1 + M8 crash-detection cases | restart scan-window timing |
| M12 (#68) | system suites + multi-user sudo-gate subset (S1, S6, S11) | sudoers boundary |

Standing-plan amendments this cycle: M3 amends S6 and M12 amends S11 in
`testplan_multiuser.md`; each amendment lands with the milestone that
causes it.

## Release Gate

Executed in order before the final 1.2.0 release:

1. **Cycle batch re-run** — all M1-M13 change-specific verifications
   against the final tree, the first state in which all thirteen changes
   coexist.
2. **Full suites and VM gate** — all four suites, local and system modes,
   on both goldens (`rocky8-iocrunner`, `debian13-iocrunner`), through the
   clone-and-test and install-and-test paths. The two goldens' sudo
   versions cover both sudoers emission branches.
3. **Multi-user plan** — `testplan_multiuser.md` executed identically,
   with the S6 and S11 amendments in effect.

## Added During Cycle

Cases discovered during the work are recorded here with the date and the
milestone that surfaced them.

- 2026-06-11 (M1 design review): #96 added as M13 — the
  `test_logrotate_boundary` probe's `IOCSH_HISTSIZE` history-disable line
  is a no-op (EPICS source-verified); the release gate renumbered M13 to
  M14. M1's suite coverage was placed in error-handling fixtures plus
  root-free local-lifecycle probes rather than the system-lifecycle suite
  (root bypasses the `chmod 0` read denial); the cross-owned `0600`
  reproduction stays in M1.T1 on the VM goldens.
- 2026-06-12 (M2): scope extended from the install prompts to the
  generate overwrite prompt (same `n`=0 / EOF=1 split, owner-approved);
  decline-branch cases pin all three prompts at exit 1. Two findings
  spun off: the install precheck hint still recommends the ineffective
  `IOCSH_HISTSIZE` knob (M1 residue), and `test-error-handling.bash`
  assertions inside `( cd ... )` subshells print PASS/FAIL without
  reaching the suite counters, so a subshell FAIL cannot fail the suite
  (pre-existing; about ten assertions affected).
