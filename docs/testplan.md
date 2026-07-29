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
`rw,sync,root_squash` and links it from `~vmadmin/gitsrc-nfs-sim`. The
precheck is a *denial* check, not a presence check — confirming the export
exists proves nothing, because a world-statable tree reproduces no bug.
Before trusting any M2 result, assert the field asymmetry on the golden:
as root, `sudo -n stat -c %U <abs-toplevel>/bin` returns Permission denied
while the owning user can stat the same path. An honest reproduction needs
all of: root_squash active; the checkout owned by a real, resolvable
non-root user; files world-readable so the delegated git query still
succeeds; and at least one non-traversable (0700-equivalent) ancestor in
the absolute toplevel path the guard stats. Only when the denial is proven
is a passing M2 result meaningful.

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
| M1 | #122 | Seven cases, each in local mode with a real unit started, editing the installed conf by hand between runs. **A** a well-formed pattern: no warning, start succeeds. **B** the value replaced by a bare dot: one warning naming ordinary-log-text as the reason, that value ignored, exit 0 — and no post-initialization error warning, whose disappearance is the point of the change. **C** the value replaced by a trailing pipe: one warning naming the empty alternation, exit 0. **D** the value replaced by an unclosed group: the existing invalid-expression warning, unchanged (regression check). **E** a well-formed pattern matching a token the log actually emits: the pattern still takes effect and raises its warning (positive control). **F** a value written with spaces around `=` and no quotes: reaches the same verdict install reaches on the trimmed value, not silently accepted. **G** a whitespace-only value: a silent no-op matching install, not a spurious warning on an empty pattern. | New local-lifecycle cases (STEP 31, all seven). The runtime re-read sits after `run_systemctl` and needs a real start, so it cannot be exercised from the install-only error-handling fixtures at `tests/test-error-handling.bash:1622-1670`, which stay where they are and keep guarding the install-time verdict for the same eight bad values. |
| M2 | #128 | On a checkout under the golden's `root_squash` mount (`~vmadmin/gitsrc-nfs-sim`), after the denial precheck above passes, the three documented entry points — `sudo bash bin/setup-system-infra.bash`, and `make install` / `make setup` run AS YOUR USER (the recipe calls `sudo` inside) — stamp a real short hash and commit date with no layout WARN. VERIFIED on both goldens 2026-07-28 (each stamped `86ad4f7-dirty`, zero layout WARN). Not an entry point on root_squash: `sudo make setup` (make itself running as root) fails at make level — root maps to nobody and cannot read the Makefile's absolute-path `include configure/RULES`, so it aborts before the script runs; this is a make-level limitation independent of #128, and the documented form is `make setup` as your user (`sudo make setup` still works on a non-squash host, which is #119's context). On a local-disk checkout, behavior unchanged. With `bin/` copied into an unrelated git checkout, the run still warns and still stamps unknown. When a checkout genuinely stamps unknown (not a git checkout, or the metadata query fails), the WARN carries the manual repair: as the owner, set `RUNNER_GIT_HASH` and `RUNNER_COMMIT_DATE` in the deployed script from `git rev-parse --short HEAD` and the UTC-normalized `git show -s --format=%ct HEAD`; following it restores a `-V` matching the deploy path's format (verified end-to-end on the golden). A separate delegation-unavailable branch was considered and dropped: it is unreachable — no-sudo plus an unreadable tree means root cannot read the setup script at all, and with sudo present or a readable tree the stamp simply succeeds. The invoker recovery at `:634` (relative `stat bin` succeeds under root_squash, measured on both goldens) covers the direct-root-shell case, not `sudo make setup`. All three entry points require a real `.git` on the mount — the standard `tar --exclude=.git` push omits it, so the M2 runs push or `git init` a real checkout on the mount first. | Read-only per the system-infra contract (the suite validates deployed components without modifying them): (a) READ the deployed `/usr/local/bin/ioc-runner -V` and assert a bare short hash (hex, optional `-dirty`), rejecting both `unknown` and the `(live)` fallback (a source-tree `-V` prints `(live)`, so the assertion must read the deployed path only) — the deploy-from-`nfs_sim` step is the orchestration/release-gate action, and a green read after a local-disk deploy is M2 evidence only alongside the same-deploy denial-precheck record; (b) a permanent R7-F9 negative that runs every time regardless of root_squash — `git init` a temp repo, copy `bin/` into it, run the stamping step, assert WARN + unknown (the fix rewrites exactly this predicate). The existing static grep guards stay but no longer stand alone. |
| M3 | #123 | (a) Mode reassertion — hand-loosen the mode of a conf, re-run the shipped `generate` with byte-identical content: the "already up-to-date (Identical)" marker confirms the skip path ran, and the conf mode is reasserted (0600 local / 0660 system) rather than left as found. Scoped to `do_generate` only — the setup mv-sites already reassert the mode (CLOSED_DOORS CI-28). (b) Backup suppression — run the shipped setup runner deploy (redirect-to-scratch + `IOC_RUNNER_BACKUP_DIR`) three times with no source change: zero new runner backups (the three `RUNNER_*` stamp lines are excluded from the comparison at the call site); then a real source change creates exactly one. | Mode case in `test-error-handling.bash` (extends `test_generate_logic`; `generate` is an `ioc-runner` behavior, and system-infra is read-only); backup case in `test-system-infra.bash` via the redirect-to-scratch pattern. Count "Created backup" log events, not `.bak` files (same-second timestamp collisions overwrite). |
| M4 | #120 | RETIRED (examined-Keep). The three-lens review 2026-07-28 found no meaningful defect at the two sites: the `install.user` injector's `sed -i` is already atomic (temp + rename), and the local template's `cat >` write has no reachable concurrent reader in the single-user `--local install` flow; the stamp-injection coherence is already guarded by #84/CI-9. No test to add. See `CLOSED_DOORS.md` CI-29. Item 3 (SELinux) stays in Backlog, conditional on a production SELinux-enforcing decision. | — |
| M5 | #121 | Execute each fix and read the real output, each case asserting the barrier branch ran (positive marker) so no green comes from a skipped path: (1) a non-writable target dir makes `do_generate` name the directory rather than leak the raw `mktemp:` line; (2) `do_view` on an empty conf dir sends its closing divider to stderr with the error (stdout keeps only the one header divider); (4) a `chmod 0` conf dir holding a real `.conf` makes `view` and `attach` name the access barrier, not "not found" — `inspect` is examined-Keep (system-mode root gate reads the dir; local-mode dir is the caller's own); (5) a valid conf under a `0500` conf dir makes local `install` state no write permission without the `ioc` group question (Site B `do_install:1577`; Site A `require_installed_conf:234` is system-mode-only, examined-Keep). Items 1/4/5 skip under EUID 0 (root ignores the DAC bits). VERIFIED 2026-07-28 on top and both goldens (error-handling 206/206 each, 16 new assertions); honest-red confirmed on the un-fixed tree. | Four `test-error-handling.bash` cases driving the real `bin/ioc-runner` with real filesystem permissions (no stub, no internal-function mock): generate staging-perm, view stderr-divider, view + attach access-barrier, local-install perm hint. Each pins the barrier branch with a positive marker before the phrase check (anti-vacuous, per #123). Item 4's cross-user fidelity (another user's unreadable dir) is the multi-user harness S6/S10; the unit cases cover the degraded single-user self-`chmod` form. |
| M6 | — | Release gate; see below. | — |

## Dependency Re-run Matrix

A milestone that passed individually can be invalidated by later work on a
shared surface. The matrix schedules the re-verification points; the batch
re-run at the release gate closes everything against the released tree.

| Trigger | Re-run | Shared surface |
| :--- | :--- | :--- |
| M3 (#123) | M2.T2 every-run deployed-`-V` read | STEP 7 runner deploy — M3 reorders the backup call past the stamp injection |
| ~~M4 (#120)~~ | — | Retired (examined-Keep); no code change, so no re-run to trigger. |
| M5 (#121) | M2.T1 WARN-text check | deployment-path output strings |

Standing-plan amendments this cycle: none expected. M2's documentation of
the manual stamp repair lands in `docs/INSTALL.md`, which the standing
multi-user plan does not cover; should any milestone change a multi-user
scenario's expected result, that amendment lands as its T4.

## Release Gate

Executed in order before the final 1.2.2 release:

1. **Cycle batch re-run** — the M1, M2, M3, M5 change-specific
   verifications against the final tree, the first state in which all the
   changes coexist (M4 retired as examined-Keep, no code change).
2. **Full suites and VM gate** — all four suites, local and system modes,
   on both goldens (`rocky8-iocrunner`, `debian13-iocrunner`), through the
   clone-and-test and install-and-test paths.
3. **root_squash path** — push (or `git init`) a real checkout WITH `.git` on
   the `nfs_sim` mount, confirm the denial precheck passes on each golden, then
   deploy from that mount and run M2.T1 (the change-specific checks) and read
   M2.T2's deployed-`-V` assertion against that root_squash deployment. Neither
   the clone-and-test nor the install-and-test path deploys from that location,
   so this state must be set up explicitly or the bug is never exercised.
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
- 2026-07-28 (M1 code review, two rounds of three reviewers): cases F and G
  added. The runtime read (`read_conf_var`) does not trim whitespace while
  install (`read_conf_all`) does, so a `KEY = value` line with spaces around
  `=` reached opposite verdicts (F), and a whitespace-only value raised a
  spurious warning where install was silent (G). Both closed by trimming the
  runtime value before its empty-value guard. The general reader divergence,
  including a quoted-whitespace ordering corner, is out of M1 scope and filed
  as #129.
- 2026-07-28 (M2 plan review, two rounds of three reviewers + golden
  measurement + implementation): the guard-move fix validated on both goldens
  (three entry points stamp a real hash, zero WARN); `ls-files` runs
  exit-code-only with `:/`-anchored pathspecs. Entry-point correction:
  `sudo make setup` is not viable on root_squash (make-as-root cannot read the
  Makefile), so the third documented entry point is `make setup` as the user.
  Simplification: the separate delegation-unavailable repair-WARN branch was
  found unreachable (no-sudo + unreadable-tree means root cannot read the setup
  script) and removed; the manual-repair guidance now rides the reachable
  "metadata unavailable" WARN and was verified end-to-end (unknown -> follow the
  WARN -> `-V` restored). T2 reworded to a read-only deployed-`-V` assertion; the
  R7-F9 negative promoted to a permanent suite asset (G5); the M2 runs require a
  real `.git` on the mount. Doc scope widened to three works-in-place sites
  (`INSTALL.md:36`, `:58-69`, `README.md:23`) and reframed as a restore, not a
  deletion. M4.T3 relabeled (install.user is a new check, not an M2.T1 re-run).
- 2026-07-28 (M3 conceptual-integrity review, three lenses + the essays): two
  invented knots removed from the M3 plan. Item 1's `backup_if_exists` half was
  dropped — the five setup mv-sites already reassert the mode unconditionally
  (`chmod` temp then `mv`), so only `do_generate` bypasses a real mode
  assertion. The stated M2 dependency was dropped — the backup filter excludes
  the three `RUNNER_*` lines by name, so M2's stamp values are irrelevant and
  M3 is correct with or without M2 (work-ordering only, re-gated by M3.T3).
  Owner decisions: filter at the call site; add `IOC_RUNNER_BACKUP_DIR` for
  test isolation; the sibling `deploy_local_logrotate` cmp-skip is
  examined-Keep (asserts no mode; CLOSED_DOORS CI-28). M3.T2 split: the mode
  case moves to error-handling since system-infra never runs `generate`.
- 2026-07-28 (M4 conceptual-integrity review, three lenses + the essays):
  M4 retired as examined-Keep — no meaningful defect at the two sites. The
  `install.user` injector's `sed -i` is already atomic (temp + rename), and the
  local template's `cat >` write has no reachable concurrent reader in the
  single-user `--local install` flow; the stamp-injection coherence is already
  guarded by #84/CI-9, and both sites were deliberately excluded from the 1.2.0
  #107 sweep. Recorded as CLOSED_DOORS CI-29; #120 item 3 (SELinux, RHEL-only)
  stays in Backlog, conditional on a production SELinux-enforcing decision. This
  is the owner gate producing a Keep, not a change.
