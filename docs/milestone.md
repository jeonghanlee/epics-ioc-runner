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

**Next session entry point:** M2 (#128) — move the layout guard's three
checks in `bin/setup-system-infra.bash` to the same delegated principal as the
git queries, so a `root_squash` checkout stamps a real version; verify on the
golden `nfs_sim` mount. M1 (#122) landed 2026-07-28 (code + suites green on
top). Do not start Backlog items unless the owner explicitly reorders them.

## Work Register — 1.2.2

| ID | Work unit | Type | Status | Evidence / next action |
| --- | --- | --- | --- | --- |
| M1 | (#122) Runtime `CRASH_LOG_PATTERNS_EXTRA` re-validation reaches the install-time verdict while keeping the runtime disposition (warn, ignore that value, base set stays active). The three shared gates move into one classifier that both call sites invoke, returning which gate rejected the value so each site chooses its own disposition; the character whitelist stays install-only. The runtime warnings name the reason in plain terms and tell the operator to fix the value and re-run `install`; `FAQ.md` Q7's runtime sentence and the `testplan_multiuser.md` S8 token-choice note land in the same commit | Milestone | Done (code; M6 gate pending) | Elimination over guarding per the promotion test (`docs/CLOSED_DOORS.md`) — both call sites live in `bin/ioc-runner`, so the two-file constraint behind CI-25 and CI-26 does not apply here. Two review rounds (3 lenses each, 2026-07-28): whitespace-normalization gap between install and runtime found and closed by trimming before the empty-value guard; a whitespace-only value is now a silent no-op matching install. The general read_conf_var/read_conf_all divergence spun off to #129. Issue #122 left open for the landing review. |
| M1.T1 | Change-specific: seven cases (well-formed; bare dot; trailing pipe; unclosed group as regression; positive control; spaced assignment; whitespace-only) — see `testplan.md` | Verification | Done | Executed on top (Debian 13): local-lifecycle 82/82, STEP 31 all 19 assertions PASS. |
| M1.T2 | Suites: new local-lifecycle cases on the runtime path (the install-only error-handling fixtures cannot reach them); install path re-verified in error-handling | Verification | Done | error-handling 188/188 (install verdict unchanged after the shared-classifier refactor + fail-closed default). |
| M2 | (#128) Layout guard re-breaks stamping on root_squash homes: move the guard's three checks to the same delegated principal as the git queries; the tracked-file check uses repo-top-anchored pathspecs (`:/configure/RULES_INSTALL :/bin/ioc-runner` — a plain relative pathspec resolves under `-C bin` and fails on a genuine checkout); WARN hands over the manual repair when delegation is unavailable; INSTALL.md reconciled | Milestone | Not started (plan reviewed 2026-07-28; ready for code) | Cluster head; fixes the regression this cycle exists for. Three-lens plan review recorded in `work/review-m2-plan.md`: (B1) issue Proposed-Fix item 1 pathspec corrected to `:/`-anchored; (B2) RESOLVED by measurement on both fresh goldens 2026-07-28 — a relative `stat bin` from cwd=repo SUCCEEDS under root_squash (only the absolute-path stat is denied, barrier = the 0750 `gitsrc` ancestor), so the `:634` invoker recovery works even under nested sudo and all three entry points fail only at the guard; moving the guard fixes all three, no scope expansion; (B3) T2 must deploy from `nfs_sim` then assert, or it never goes red. |
| M2.T1 | Change-specific: three entry points on the golden `nfs_sim` mount stamp real metadata (after the denial precheck); local-disk unchanged; unrelated checkout still warns; delegation-unavailable is a separate fixture whose WARN-guided manual repair restores `-V` | Verification | Not started | Denial precheck (`sudo -n stat` denied to root, allowed to owner) gates trust in the result. |
| M2.T2 | Suites: system-infra case that deploys from the `nfs_sim` mount, then asserts the deployed `/usr/local/bin/ioc-runner -V` is a bare short hash — rejecting `unknown` AND the `(live)` fallback; a local-disk deployment passes on buggy code | Verification | Not started | |
| M2.T-doc | INSTALL.md: reconcile the now-false root_squash "works in place" claim and frame the manual stamp repair as the post-WARN procedure | Verification | Not started | AC4 doc deliverable; had no sub before the plan review. |
| M3 | (#123) Reassert modes on identical-skip paths, and exclude the `RUNNER_*` stamp lines from the backup comparison so a no-change redeploy stops rotating the 3-slot history | Milestone | Not started | Owner decision 2026-07-27: filter the stamp lines (option 1), not document the asymmetry. Depends on M2 fixing the stamp values. |
| M3.T1 | Change-specific: hand-loosened mode is reasserted on an identical redeploy; three no-change re-runs add no runner backup; a real source change adds exactly one | Verification | Not started | |
| M3.T2 | Suites: system-infra cases for mode reassertion and backup suppression | Verification | Not started | |
| M3.T3 | Re-run of M2.T1 (shared surface: STEP 7 runner deploy and its backup comparison) | Verification | Not started | |
| M4 | (#120) Extend same-directory staged rename to the local unit file and the `install.user` injector; the SELinux item stays out of scope | Milestone | Not started | Depends on M2: the injector mirrors the setup stamping path and has no layout guard of its own. |
| M4.T1 | Change-specific: both sites deploy by `mktemp` + `mv`, no half-written state under the final name; `make install.user` still yields a correct `-V` | Verification | Not started | |
| M4.T2 | Suites: local-lifecycle and system-infra green; staged-rename shape pinned at the two extended sites | Verification | Not started | |
| M4.T3 | Re-run of M2.T1 including the user-install path (shared surface: version injection) | Verification | Not started | |
| M5 | (#121) Remaining message and stream polish from the 1.2.1 landing precheck; the em-dash item already landed in 1.2.1 | Milestone | Not started | Last in the cluster so the wording settles on top of M2-M4 output changes. |
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

## External Gates

| Gate | State |
| --- | --- |
| ansible/cloud-provision U8 first joint tag (1.0) | Open; User-run. Deferred at the 1.2.1 release and not yet taken. |

**Tally:** 1.2.2 milestones 6 (M1-M5 work, M6 gate) with 14 verification subs
(M2 gained a doc sub in the 2026-07-28 plan review); M1 Done (code, top-host
suites green), M2-M5 not started, M6 gate not started · Backlog 8 open ·
external gates 1 open.

## Update Protocol

When a milestone is completed, update this register in the same commit as the
substantive change. Any commit that changes a playbook-equivalent contract
(unit template rows, sudoers emission, doc-pinned behavior) updates the
mirroring documents in the same commit. GitHub issue state changes are
reflected in the next documentation commit.
