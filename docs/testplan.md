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
| M2 | #128 | On a checkout under the golden's `root_squash` mount (`~vmadmin/gitsrc-nfs-sim`), after the denial precheck above passes: all three entry points — `sudo bash bin/setup-system-infra.bash`, `sudo make setup`, `make install` — stamp a real short hash and commit date with no layout WARN. On a local-disk checkout, behavior unchanged. With `bin/` copied into an unrelated git checkout, the run still warns and still stamps unknown. Delegation-unavailable is a separate fixture (`sudo` disabled with `chmod 000 /usr/bin/sudo` in setup/teardown, not a PATH edit — `sudo` lives in `/usr/bin` beside git/stat; run from the squashed checkout, owner a real resolvable account): the WARN names the two `declare -g` lines and the commands producing their values (UTC-normalized), and following that text alone restores a `-V` matching the deploy path's format. Note the fixture side effect: disabling `sudo` also fails `sudo_supports_regex_args`, harmlessly falling back to glob-form sudoers. `sudo make setup` (nested sudo, `SUDO_USER=root`) reaches a clean stamp: measured on both goldens 2026-07-28, a relative `stat bin` from cwd=repo succeeds under root_squash, so the `:634` invoker recovery works and this entry point fails only at the guard like the other two. All three entry points require a real `.git` on the mount — the standard `tar --exclude=.git` push omits it, so the M2 runs push or `git init` a real checkout on the mount first. | Read-only per the system-infra contract (the suite validates deployed components without modifying them): (a) READ the deployed `/usr/local/bin/ioc-runner -V` and assert a bare short hash (hex, optional `-dirty`), rejecting both `unknown` and the `(live)` fallback (a source-tree `-V` prints `(live)`, so the assertion must read the deployed path only) — the deploy-from-`nfs_sim` step is the orchestration/release-gate action, and a green read after a local-disk deploy is M2 evidence only alongside the same-deploy denial-precheck record; (b) a permanent R7-F9 negative that runs every time regardless of root_squash — `git init` a temp repo, copy `bin/` into it, run the stamping step, assert WARN + unknown (the fix rewrites exactly this predicate). The existing static grep guards stay but no longer stand alone. |
| M3 | #123 | (a) Loosen the mode of a deployed target by hand, re-run setup with identical content: the mode is reasserted rather than left as found. (b) Re-run setup three times with no code change: the runner accumulates no new backup (the `RUNNER_*` stamp lines are excluded from the comparison, owner decision 2026-07-27). Then change the runner source and re-run: exactly one backup is created. | New system-infra cases for both halves: mode reassertion on the identical-content path, and backup suppression across a no-change redeploy. |
| M4 | #120 | The local unit file (`bin/ioc-runner`) and the `install.user` injector (`configure/RULES_INSTALL` via `configure/inject-runner-version.bash`) deploy by same-directory `mktemp` + `mv`, never by in-place write: no half-written state is observable under the final name. `make install.user` still yields a correct `-V` — a new check on the injector, not a re-run of M2.T1 (the injector runs git as the user, has no layout guard, and shares no surface with M2's setup-path fix). | Local-lifecycle and system-infra suites green; a case pinning the staged-rename shape at the two extended sites, matching the existing M4-of-1.2.1 coverage. |
| M5 | #121 | Execute each remaining item and read the actual output: a failing `mktemp` in `do_generate` reports directory writability rather than the raw tool error; the `do_view` missing-conf path sends its whole error block to one stream; view/attach on another user's IOC names conf resolution where that is the real barrier; the local-mode gate error stops suggesting `ioc` group membership where local mode needs none. | Error-handling cases for the two items with a deterministic trigger (generate staging failure, view missing-conf stream); the wording items are pinned by the existing message assertions where they exist. |
| M6 | — | Release gate; see below. | — |

## Dependency Re-run Matrix

A milestone that passed individually can be invalidated by later work on a
shared surface. The matrix schedules the re-verification points; the batch
re-run at the release gate closes everything against the released tree.

| Trigger | Re-run | Shared surface |
| :--- | :--- | :--- |
| M3 (#123) | M2.T1 stamping verification | STEP 7 runner deploy and its backup comparison |
| M4 (#120) | M2.T1 (the setup-path stamping) | STEP 7 setup deploy — the `install.user` injector is a separate, root_squash-safe path (M4's own check), not a shared surface with M2 |
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
  measurement): the guard-move fix validated on the golden (delegated checks
  pass, real stamp); the repair-WARN keys off a delegation flag because
  direct-root `rev-parse` fails first (empty toplevel), not the layout verdict;
  `ls-files` runs exit-code-only with `:/`-anchored pathspecs. T2 reworded to a
  read-only deployed-`-V` assertion (the system-infra suite must not deploy);
  the R7-F9 negative promoted to a permanent suite asset (G5, owner-approved);
  the V3 delegation-unavailable fixture disables `sudo` via `chmod 000`; the
  M2 runs require a real `.git` on the mount. Doc scope widened to three
  works-in-place sites (`INSTALL.md:36`, `:58-69`, `README.md:23`) and reframed
  as a restore, not a deletion. M4.T3 relabeled (install.user is a new check,
  not an M2.T1 re-run).
