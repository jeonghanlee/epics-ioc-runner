# EPICS IOC Runner — Cycle Test Plan

Current cycle: **1.2.2**. This plan and the milestone register
([`milestone.md`](milestone.md)) are the two halves of one cycle record —
the register tracks status and the work order, this file holds the
verification procedures. Drafted at cycle start (2026-07-27); cases
discovered during the work are added under "Added During Cycle". Before
the final release this plan is executed in full and remains the cycle's
verification record.

**File convention:** like the register, this file is overwritten when a
cycle opens; the previous cycle's plan is preserved in its release tag.
Cycle plans through 1.2.0 carried the version in the filename, so a
historical lookup uses that name (`git show
1.2.0:docs/testplan_1.2.0.md`); from 1.2.2 onward the name is fixed
(`git show <tag>:docs/testplan.md`). 1.2.1 ran without a cycle plan and
its verification record is in `git show 1.2.1:docs/milestone.md`.

1.2.2 is a patch cycle: five deployment-path and validation-path defects,
no redesign. The version-independent multi-user scenarios live in
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
the 1.2.1 landing re-gate (record in `git show 1.2.1:docs/milestone.md`,
M10 row).

This cycle's verification depends on a golden-image capability that must
be confirmed present before M2 begins: the `nfs_sim` role of
`ansible-provision` exports `/home/nfs/simulation/vmadmin/gitsrc` with
`rw,sync,root_squash` and links it from `~vmadmin/gitsrc-nfs-sim`. A
checkout placed there reproduces the root-cannot-stat condition that M2
addresses, so no separate production host is required for the gate.

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
| M1 | #122 | Edit the installed conf after install to a compiling-degenerate `CRASH_LOG_PATTERNS_EXTRA` (bare dot; trailing pipe) and start/restart: the runtime re-read now reaches the same verdict as the install-time checks while keeping the runtime disposition — one warning, that value ignored, base set still active — instead of accepting it and pinning the chronic corroboration Warning. A well-formed extra pattern still takes effect unchanged. The character whitelist stays install-only per the `FAQ.md` Q7 contract, and Q7's runtime sentence is updated in the same commit. | New local-lifecycle cases: the runtime re-read sits after `run_systemctl` and needs a real start, so it cannot be exercised from the install-only error-handling fixtures at `tests/test-error-handling.bash:1622-1670`. One case for structural rejection and one for the canary probe on the runtime path; the install-time cases stay where they are. |
| M2 | #128 | On a checkout under the golden's `root_squash` mount (`~vmadmin/gitsrc-nfs-sim`): all three entry points — `sudo bash bin/setup-system-infra.bash`, `sudo make setup`, `make install` — stamp a real short hash and commit date with no layout WARN. On a local-disk checkout, behavior unchanged. With `bin/` copied into an unrelated git checkout, the run still warns and still stamps unknown. With delegation made unavailable, the WARN names the two `declare -g` lines and the commands producing their values, and following that text alone restores a correct `-V`. | New system-infra case asserting the observable outcome: the deployed `/usr/local/bin/ioc-runner` reports a non-`unknown` hash and commit date after a setup run. The existing static guards stay, but they no longer stand alone. |
| M3 | #123 | (a) Loosen the mode of a deployed target by hand, re-run setup with identical content: the mode is reasserted rather than left as found. (b) Re-run setup three times with no code change: the runner accumulates no new backup (the `RUNNER_*` stamp lines are excluded from the comparison, owner decision 2026-07-27). Then change the runner source and re-run: exactly one backup is created. | New system-infra cases for both halves: mode reassertion on the identical-content path, and backup suppression across a no-change redeploy. |
| M4 | #120 | The local unit file (`bin/ioc-runner`) and the `install.user` injector (`configure/RULES_INSTALL` via `configure/inject-runner-version.bash`) deploy by same-directory `mktemp` + `mv`, never by in-place write: no half-written state is observable under the final name. `make install.user` still yields a correct `-V`. Re-runs M2.T1 on the user-install path. | Local-lifecycle and system-infra suites green; a case pinning the staged-rename shape at the two extended sites, matching the existing M4-of-1.2.1 coverage. |
| M5 | #121 | Execute each remaining item and read the actual output: a failing `mktemp` in `do_generate` reports directory writability rather than the raw tool error; the `do_view` missing-conf path sends its whole error block to one stream; view/attach on another user's IOC names conf resolution where that is the real barrier; the local-mode gate error stops suggesting `ioc` group membership where local mode needs none. | Error-handling cases for the two items with a deterministic trigger (generate staging failure, view missing-conf stream); the wording items are pinned by the existing message assertions where they exist. |
| M6 | — | Release gate; see below. | — |

## Dependency Re-run Matrix

A milestone that passed individually can be invalidated by later work on a
shared surface. The matrix schedules the re-verification points; the batch
re-run at the release gate closes everything against the released tree.

| Trigger | Re-run | Shared surface |
| :--- | :--- | :--- |
| M3 (#123) | M2.T1 stamping verification | STEP 7 runner deploy and its backup comparison |
| M4 (#120) | M2.T1 including the `install.user` path | version injection into the deployed script |
| M5 (#121) | M2.T1 WARN-text check | deployment-path output strings |

Standing-plan amendments this cycle: none expected. M2's documentation of
the manual stamp repair lands in `docs/INSTALL.md`, which the standing
multi-user plan does not cover; should any milestone change a multi-user
scenario's expected result, that amendment lands as its T4.

## Release Gate

Executed in order before the final 1.2.2 release:

1. **Cycle batch re-run** — all M1-M5 change-specific verifications
   against the final tree, the first state in which all five changes
   coexist.
2. **Full suites and VM gate** — all four suites, local and system modes,
   on both goldens (`rocky8-iocrunner`, `debian13-iocrunner`), through the
   clone-and-test and install-and-test paths.
3. **root_squash path** — M2.T1 executed on both goldens from the
   `nfs_sim` mount, since neither the clone-and-test nor the
   install-and-test path uses that location by default.
4. **Multi-user plan** — `testplan_multiuser.md` executed identically.

## Added During Cycle

Cases discovered during the work are recorded here with the date and the
milestone that surfaced them.

- 2026-07-27 (M1 plan review): M1.T2 moved from the error-handling suite to
  local-lifecycle — the runtime re-read runs after `run_systemctl`, so the
  install-only fixtures cannot reach it. Two scope points settled against
  prior decisions rather than re-opened: the character whitelist stays
  install-only ("Install time is the strict gate", `FAQ.md` Q7, written at
  1.2.1 M9 from the M3 second-round decision), and the runtime disposition
  stays warn-and-ignore because `CRASH_LOG_PATTERNS_EXTRA` is corroborating
  only (D033) and a bad value must never block a restart. M1 therefore
  carries a one-sentence Q7 update.
