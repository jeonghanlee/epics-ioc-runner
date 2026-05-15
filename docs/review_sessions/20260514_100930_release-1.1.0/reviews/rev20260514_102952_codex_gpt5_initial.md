# Review Report: epics-ioc-runner 1.1.0 Release Readiness

Status: final
Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Artifact ID: rev20260514_102952
Artifact Type: review_report
Acting As Role: Reviewer 1 (Candidate)
Date: 2026-05-14
Start Time: 10:29:52
Finalized At: 2026-05-14 10:29:52
Author Agent ID: codex_gpt5
Author Transport: codex
Author Model: gpt-5
Target Artifact ID: none
Supersedes Artifact ID: none
Reviewer Agent ID: codex_gpt5
Reviewer Model: gpt-5
Repository: `/data/gitsrc/epics-ioc-runner`
Review Mode: static review
Workflow Size: L
Skill References: `agent-review-convergence`, `technical-discussion`

## Role Assertion

- Agent: codex_gpt5
- Acting As: Reviewer 1 (Candidate)
- Role Source: explicit User direction for session rs20260514_100930 on 2026-05-14; `README.md` row 2 pending registration.
- Artifact Type Allowed: yes (Reviewer may publish review_report).
- Target Path Allowed: yes (`reviews/` is within Reviewer write scope).
- Re-Anchor Trigger: none

## Executive Summary

The A-G phase outline is directionally correct for a 1.1.0 release, but it needs three convergence corrections before implementation starts: normalize stale dependency references (#6, #13, and already-delivered #25), split Phase C into detection and permission gates, and keep #49 as a standalone D+ compatibility gate rather than treating it as an automatic consequence of the log-file crash detection work.

The schedule can still fit the 2026-05-29 due date if the readiness packet makes verification phase-gated instead of deferring most new tests to Phase E. The highest risk is late discovery across Rocky 8, local mode, and NFS root_squash after the template and permission model have already landed.

## Reviewed Scope

- Session state: `README.md` for rs20260514_100930, especially objective, cross-check policy, participant state, and open decisions.
- Source snapshot: `00_source_release-1.1.0.md`, especially issue inventory, dependency graph, CC1-CC4, and Reviewer 1 focus questions.
- Baseline docs: `docs/ARCHITECTURE.md` and `docs/CLI_REFERENCE.md`.
- Current implementation touchpoints: `bin/ioc-runner` local template generation, `do_inspect`, and lifecycle inspect assertions.
- Live issue bodies for detail only: #8, #9, #10, #11, #12, #15, #17, #21, #24, #49. The source snapshot remains the authoritative inventory.

## Findings

### F-001 (High): Dependency normalization is required before planning

The source snapshot records #6 and #13 as dependency references that are not in the open 1.1.0 milestone list, and also records #25 as already delivered in 1.0.8 via `f0e4ebf`. Phase D still lists #25 in the README cross-check table, so the plan would otherwise carry a stale work item into execution.

Evidence:

- `00_source_release-1.1.0.md` records #25 as already shipped and needing convergence resolution.
- The dependency graph names #6 and #13 as missing or possibly orphan references.
- `README.md` Phase D still lists #25.

Recommendation: record a convergence decision that #25 is documented as already delivered, and resolve #6/#13 as either satisfied prerequisites or out-of-scope blockers before authorizing Phase A.

### F-002 (High): Phase C should be split into two review gates

Phase C currently combines #11 crash detection rewrite and #12 log permission model. They are coupled by the release goal, but they fail in different ways: #11 is detection correctness and rotation behavior, while #12 is an access-control and least-privilege surface.

Recommendation: keep the roadmap heading as Phase C if desired, but define C1 as crash detection byte-offset scan and C2 as log permission model, each with its own acceptance and Reviewer 1 cross-check. This preserves phase granularity while preventing a permission regression from being hidden inside a detection refactor.

### F-003 (High): #49 should remain a standalone D+ compatibility phase

#49 should not be folded into Phase B and should not be deferred if 1.1.0 is intended to be release-ready on Rocky 8. The inspect path is still Netlink/UDS based in the CLI contract, while #11 changes crash detection to file-log scanning; those are separate behavioral surfaces.

Evidence:

- `docs/CLI_REFERENCE.md` defines `inspect` as file descriptor, `lsof`, and `ss -x -a -p` based.
- `bin/ioc-runner` still implements `do_inspect` through `lsof -a -U` and `ss -x -a -p`.
- #49 acceptance is specifically Rocky 8 local STEP 17 and system STEP 24 passing without Debian regression.

Recommendation: keep D+ as an independent compatibility gate after the template/logging work is stable and before Phase E test expansion. Do not claim #49 auto-resolved without the Rocky 8 STEP 17 and STEP 24 logs.

### F-004 (Medium): Acceptance criteria for #11 and #12 need release-gate wording

The issue bodies for #11 and #12 contain useful acceptance points, but the implementation readiness packet should turn them into explicit release gates for both modes and both supported distributions. In particular, #11 should require first-second iocsh parse error detection, rotation/truncation behavior, and no journal dependency for the primary path. #12 should require ownership/mode checks for system and local modes plus negative access by a non-`ioc` user.

Recommendation: add a phase acceptance matrix with columns for local mode, system mode, Debian 13, Rocky 8, NFS root_squash, and negative permission checks.

### F-005 (Medium): Phase E is too late for first discovery of B/C/D regressions

Phase E owns #21 integration test expansion, but CC1-CC3 require evidence during B/C/D work. If tests for permission enforcement, logrotate boundary, and detection without journal access are written only after implementation, failures will appear after several dependent phases have landed.

Recommendation: require each phase handoff to include at least a narrow verification command for its new behavior, then let Phase E consolidate those checks into the permanent test suite.

### F-006 (Medium): Phase F SKIP-allowed is only partly defensible

Skipping Reviewer 1 for mechanical CHANGELOG and README migration edits is defensible. Skipping `docs/LOG_LAYOUT.md` is not, because it records operator-facing paths, permissions, retention behavior, and the systemd version floor from CC4.

Recommendation: mark Phase F as SKIP-allowed only for #19 and #20. Require Reviewer 1 cross-check for #18 unless its content was already cross-checked as part of Phase B/C/D handoffs.

### F-007 (Medium): Schedule risk is moderate, not low

The 2026-05-29 date is achievable, but only if the team avoids late cross-platform discovery. The source snapshot includes 15 open issues plus #49, two supported distributions, two execution modes, NFS root_squash, and at least one security-sensitive permission change.

Recommendation: treat Phase A-C and D+ as the critical path. Phase F/G can stay small, but Phase E must not become the first complete verification point.

## Required Decisions

- RD-001: Confirm `codex_gpt5` as the stable Reviewer 1 agent ID for UD001.
- RD-002: Confirm #49 as standalone Phase D+ for UD002. My recommendation is D+ standalone.
- RD-003: Resolve #25 as already delivered and remove it from Phase D execution scope, while retaining a documentation note if needed.
- RD-004: Resolve #6 and #13 dependency references before development authorization.
- RD-005: Decide whether #18 `docs/LOG_LAYOUT.md` requires Reviewer 1 cross-check despite Phase F being marked SKIP-allowed.

## Recommended Implementation Order

1. Normalize scope: close or document stale references (#25, #6, #13) in the convergence report.
2. Phase A: add LOG_DIR variables and mode rebinding.
3. Phase B1: system template log output and directory behavior.
4. Phase B2: local template log output and local directory creation.
5. Phase B3: logrotate deployment and forced-rotation verification.
6. Phase C1: byte-offset crash detection rewrite.
7. Phase C2: permission model enforcement and negative access checks.
8. Phase D: journal grant removal and dual-path fallback.
9. Phase D+: #49 Rocky 8 inspect compatibility verification or fix.
10. Phase E: convert phase checks into permanent integration tests.
11. Phase F: LOG_LAYOUT, CHANGELOG, README migration.
12. Phase G: version bump and release gate.

## Verification Notes

- Required matrix: local/system mode on Debian 13 and Rocky 8 for phases touching templates, logs, permissions, journal access, or inspect diagnostics.
- Required Rocky 8 gate for #49: local STEP 17 and system STEP 24 pass on `testbed-rocky8-iocrunner-server`.
- Required Debian regression gate for #49: inspect-related tests pass on `top` or `testbed-debian13-iocrunner-server`.
- Required NFS gate: Phase B/C changes do not reintroduce the Phase 4 NFS root_squash limitation recorded in the source snapshot.
- Required security gate: an operator in `ioc` can read the log, a user outside `ioc` cannot, and no IOC operator requires `systemd-journal`.
