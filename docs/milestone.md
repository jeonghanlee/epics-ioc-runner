# EPICS IOC Runner — Milestone Register

Single, unified, repository-local source of truth for milestone and backlog
status. Every agent and contributor reads this file instead of chat history or
memory.

**Mode:** remote-authoritative. Each issue's Verification checkbox list is the
authoritative sub-status; this register mirrors it, and every milestone closure
ends with a reconcile pass against GitHub.

**Register convention:** the register carries the current release milestone and
the Backlog, and both are overwritten when a cycle opens; the released cycle's
full record is preserved in the matching git tag
(`git show 1.2.1:docs/milestone.md`). Verdicts that examined something and left
it alone are not cycle state and live in [`CLOSED_DOORS.md`](CLOSED_DOORS.md),
which no cycle clears. The cycle test plan
([`testplan.md`](testplan.md)) is the other half of the same record and follows
the same rule: this register tracks status and the work order, the plan holds
the verification procedures. Plans through 1.2.0 carried the version in the
filename (`git show 1.2.0:docs/testplan_1.2.0.md`); from 1.2.2 onward the name
is fixed. The version-independent scenarios in
[`testplan_multiuser.md`](testplan_multiuser.md) are not part of either cycle
file and persist across releases.

**1.2.2 cycle:** patch release — five deployment-path and validation-path
defects pulled from the Backlog, no redesign. The cycle exists because #128
reopened, through a different cause, the stamping symptom #119 closed in 1.2.1.
Target date: 2026-08-28, per the GitHub milestone `1.2.2` due date.

**Next session entry point:** M3 (#123) — reassert the conf mode on
`do_generate`'s identical-content skip (`bin/ioc-runner`), and at the runner
backup call site (`bin/setup-system-infra.bash`) exclude the three `RUNNER_*`
stamp lines from the comparison (moved past the stamp injection) so a no-change
redeploy stops rotating the 3-slot history; add `IOC_RUNNER_BACKUP_DIR` for test
isolation. Plan reviewed and de-knotted 2026-07-28. M1 (#122) and M2 (#128)
landed 2026-07-28 (code + suites green on both goldens). Do not start Backlog
items unless the owner explicitly reorders them.

## Work Register — 1.2.2

| ID | Work unit | Type | Status | Evidence / next action |
| --- | --- | --- | --- | --- |
| M1 | (#122) Runtime `CRASH_LOG_PATTERNS_EXTRA` re-validation reaches the install-time verdict while keeping the runtime disposition (warn, ignore that value, base set stays active). The three shared gates move into one classifier that both call sites invoke, returning which gate rejected the value so each site chooses its own disposition; the character whitelist stays install-only. The runtime warnings name the reason in plain terms and tell the operator to fix the value and re-run `install`; `FAQ.md` Q7's runtime sentence and the `testplan_multiuser.md` S8 token-choice note land in the same commit | Milestone | Done (code; M6 gate pending) | Elimination over guarding per the promotion test (`docs/CLOSED_DOORS.md`) — both call sites live in `bin/ioc-runner`, so the two-file constraint behind CI-25 and CI-26 does not apply here. Two review rounds (3 lenses each, 2026-07-28): whitespace-normalization gap between install and runtime found and closed by trimming before the empty-value guard; a whitespace-only value is now a silent no-op matching install. The general read_conf_var/read_conf_all divergence spun off to #129. Issue #122 left open for the landing review. |
| M1.T1 | Change-specific: seven cases (well-formed; bare dot; trailing pipe; unclosed group as regression; positive control; spaced assignment; whitespace-only) — see `testplan.md` | Verification | Done | Executed on top (Debian 13): local-lifecycle 82/82, STEP 31 all 19 assertions PASS. |
| M1.T2 | Suites: new local-lifecycle cases on the runtime path (the install-only error-handling fixtures cannot reach them); install path re-verified in error-handling | Verification | Done | error-handling 188/188 (install verdict unchanged after the shared-classifier refactor + fail-closed default). |
| M2 | (#128) Layout guard re-breaks stamping on root_squash homes: move the guard's three checks to the same delegated principal as the git queries; the tracked-file check uses repo-top-anchored pathspecs (`:/configure/RULES_INSTALL :/bin/ioc-runner` — a plain relative pathspec resolves under `-C bin` and fails on a genuine checkout); WARN hands over the manual repair when delegation is unavailable; INSTALL.md reconciled | Milestone | Done (code + suite + docs; both goldens green 2026-07-28; M6 gate re-runs) | Cluster head; fixes the regression this cycle exists for. Three-lens plan review recorded in `work/review-m2-plan.md`: (B1) issue Proposed-Fix item 1 pathspec corrected to `:/`-anchored; (B2) RESOLVED by measurement on both fresh goldens 2026-07-28 — a relative `stat bin` from cwd=repo SUCCEEDS under root_squash (only the absolute-path stat is denied, barrier = the 0750 `gitsrc` ancestor), so the `:634` invoker recovery works and the failure is only at the guard; moving the guard fixes it, no scope expansion. Entry-point correction (implementation verify 2026-07-28): the three documented root_squash entry points are `sudo bash bin/setup-system-infra.bash`, `make install`, `make setup` (the last two AS THE USER), all verified stamping `86ad4f7-dirty` on both goldens; `sudo make setup` is NOT viable on root_squash (make-as-root cannot read the Makefile includes, aborts before the script) and is dropped from the entry-point list; (B3) T2 must deploy from `nfs_sim` then assert, or it never goes red. Round-2 review 2026-07-28 (implementation readiness / verification / coherence) + golden measurement: guard-move validated on the golden (delegated checks pass); `ls-files` is exit-code-only with `:/`-anchored pathspecs; the R7-F9 negative is promoted to a permanent suite asset (G5); the doc scope widened to three works-in-place sites and reframed as a restore, not a deletion. Implementation finding: the separate delegation-unavailable repair-WARN branch was unreachable dead code (no-sudo + unreadable-tree means root cannot read the setup script itself; with sudo present, or a readable tree, the stamp succeeds) and was removed; the manual-repair guidance now rides the reachable "metadata unavailable" WARN, verified end-to-end on the golden. Code done and verified. |
| M2.T1 | Change-specific: the three documented entry points (`sudo bash bin/setup-system-infra.bash`; `make install` / `make setup` as the user) on the golden `nfs_sim` mount stamp real metadata (after the denial precheck); local-disk unchanged; the unknown-stamp WARN carries the manual repair, and following it restores `-V` in the deploy path's UTC format | Verification | Done | Requires a real `.git` on the mount (the `--exclude=.git` push omits it). Denial precheck (`sudo -n stat` denied to root, allowed to owner) gates trust. Verified 2026-07-28 on BOTH goldens: the three entry points stamp `86ad4f7-dirty`, zero layout WARN; `sudo make setup` dropped (make-as-root cannot read the Makefile on root_squash, a make-level limit, not #128). Manual-repair path verified end-to-end: a non-git checkout stamps unknown with the guidance WARN, and following it (owner runs the two git queries + `sudo sed` the two `declare -g` lines) restores `86ad4f7` with the correct UTC commit date. |
| M2.T2 | Suite: `test_setup_stamp_layout_guard` runs the REAL setup STEP 7 with the runner/symlink/completion destinations redirected to a scratch tree (no system component touched), and observes the injected `RUNNER_GIT_HASH` — a permanent every-run asset (no root_squash needed, G5 promotion): (a) the real checkout stamps a non-unknown hash; (b) `bin/` copied into an unrelated git checkout stamps unknown and emits the layout WARN | Verification | Done | Added to `tests/test-system-infra.bash`; passes on both goldens 2026-07-28 (rocky8 43/43, debian13 44/44). Replaces the reproduction-style guard with a real-run observation, so it would have gone red on the bug. |
| M2.T-doc | Docs: M2 RESTORES works-in-place; the `INSTALL.md` root_squash section keeps the claim, re-anchors the 1.2.1-era "verified on alsucl-psrv3" line to the 1.2.2 goldens, states `make setup` runs as the user (not `sudo make setup`), and adds the post-WARN manual repair matching the WARN string. `INSTALL.md:36` and `README.md:23` one-liners stay true post-fix (no edit) | Verification | Done | AC4 doc deliverable. `docs/INSTALL.md` NFS root_squash section reconciled 2026-07-28. |
| M3 | (#123) Reassert the conf mode on `do_generate`'s identical-content skip (`bin/ioc-runner`), and exclude the three `RUNNER_*` stamp lines from the runner's backup comparison at the call site so a no-change redeploy stops rotating the 3-slot history | Milestone | Not started | Conceptual-integrity review 2026-07-28 (three lenses + essays) removed two invented knots: item 1's `backup_if_exists` half is dropped (the five setup mv-sites already reassert the mode unconditionally, so only `do_generate` bypasses it), and the stated M2 dependency is dropped (the filter excludes the three lines by NAME, so M2's stamp VALUES are irrelevant; M3 is sequenced after M2 only as work-ordering on the shared STEP 7 surface, re-gated by M3.T3). Owner decisions 2026-07-28: filter at the call site (not a `backup_if_exists` arg); add `IOC_RUNNER_BACKUP_DIR` to isolate the backup dir for the test; the sibling `deploy_local_logrotate` cmp-skip is examined-Keep (CLOSED_DOORS CI-28). |
| M3.T1 | Change-specific: a hand-loosened conf mode is reasserted on a byte-identical `generate` re-run (the "Identical" skip marker confirms the skip path ran); three no-change setup re-runs add no runner backup, and a real source change adds exactly one | Verification | Not started | |
| M3.T2 | Suites: the mode-reassertion case in `test-error-handling.bash` (`generate` is an `ioc-runner` behavior; system-infra is read-only and never runs `generate`), the backup-suppression case in `test-system-infra.bash` via the redirect-to-scratch pattern plus `IOC_RUNNER_BACKUP_DIR` | Verification | Not started | |
| M3.T3 | Re-run of M2.T2's every-run deployed-`-V` read after M3 reorders the STEP 7 backup call past the stamp injection (shared surface: STEP 7 runner deploy); the full M2.T1 root_squash stamping stays at the M6 gate | Verification | Not started | |
| M4 | (#120) Extend same-directory staged rename to the local unit file and the `install.user` injector; the SELinux item stays out of scope | Milestone | Not started | Sequenced after M2 as work-ordering; no code dependency — the injector runs git as the user with no layout guard, so it is independent of M2's guard-move. |
| M4.T1 | Change-specific: both sites deploy by `mktemp` + `mv`, no half-written state under the final name; `make install.user` still yields a correct `-V` | Verification | Not started | |
| M4.T2 | Suites: local-lifecycle and system-infra green; staged-rename shape pinned at the two extended sites | Verification | Not started | |
| M4.T3 | Change-specific (not a re-run of M2.T1 — the injector shares no surface with M2's setup-path guard and is root_squash-safe): `make install.user` stamps a correct `-V` through the staged-rename injector | Verification | Not started | |
| M5 | (#121) Remaining message and stream polish from the 1.2.1 landing precheck; the em-dash item already landed in 1.2.1 | Milestone | Not started | Last in the cluster. M2 authors and finalizes its own delegation-unavailable repair-WARN (AC4); M5.T3 only re-verifies that string survived M5's edits — it is not one of M5's four polish items. |
| M5.T1 | Change-specific: generate staging failure names directory writability; view missing-conf error block uses one stream; view/attach names conf resolution; local-mode gate stops suggesting `ioc` membership | Verification | Not started | |
| M5.T2 | Suites: error-handling cases for the two deterministically triggerable items | Verification | Not started | |
| M5.T3 | Re-run of M2.T1 WARN text (shared surface: deployment-path output strings) | Verification | Not started | |
| M6 | Release gate: cycle batch re-run, full suites on both goldens through clone-and-test and install-and-test, the root_squash path from the `nfs_sim` mount, and the multi-user plan | Release gate | Not started | Register-local, no issue. Gates the merge, the `1.2.2` tag, and the release. |

## Backlog

Open work not scheduled into a release cycle. Mirrors the GitHub `Backlog`
milestone; the 1.3.0 theme is the detection layer (#102).

| Issue | Work unit | Type | Status | Note |
| --- | --- | --- | --- | --- |
| #102 | Fleet-layer reliability: restart-storm boundary and running-IOC hang detection | Backlog | Open | The 1.3.0 theme. |
| #113 | Conf parser unification (single parse core, trim + last-wins + tab) with divergence fixtures | Backlog | Open | Behavior-visible; needs its own review. |
| #114 | FATAL-subset boundary hygiene (portable class) with golden re-run | Backlog | Open | Pairs with the E2E probe. |
| #115 | Restart-supervision E2E probe on the goldens | Backlog | Open | Test-infrastructure block with #116. |
| #116 | Suite integrity: executed-vs-counted tripwire ported to the three lifecycle suites, and the logrotate oneshot run through systemd | Backlog | Open | Issue body scopes it to 1.3.0. |
| #117 | Reorder local install so deployment follows the abort gates | Backlog | Open | Issue body scopes it to 1.3.0; includes an upgrade-vehicle decision. |
| #118 | Type expectation for `verify_path` (false-green directory impostors) | Backlog | Open | Helper-signature change; issue body asks for its own review. |
| #127 | Container execution mode without systemd | Backlog | Open | Feature. |
| #129 | Unify conf-value normalization between `read_conf_var` and `read_conf_all` (trim + trim-before-unquote ordering) | Backlog | Open | Spun off from M1 (#122), 2026-07-28; M1 closed its specific gap at one call site, this is the general reader divergence. |

## External Gates

| Gate | State |
| --- | --- |
| ansible/cloud-provision U8 first joint tag (1.0) | Open; User-run. Deferred at the 1.2.1 release and not yet taken. |

**Tally:** 1.2.2 milestones 6 (M1-M5 work, M6 gate) with 14 verification subs;
M1 and M2 Done (code + suites green on both goldens 2026-07-28), M3-M5 not
started, M6 gate not started · Backlog 9 open · external gates 1 open. (Backlog
was 8; #129 added 2026-07-28 in the reconcile against GitHub.)

## Update Protocol

When a milestone is completed, update this register in the same commit as the
substantive change. Any commit that changes a playbook-equivalent contract
(unit template rows, sudoers emission, doc-pinned behavior) updates the
mirroring documents in the same commit. GitHub issue state changes are
reflected in the next documentation commit.
