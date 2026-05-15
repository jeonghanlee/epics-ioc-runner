# Source Context: epics-ioc-runner 1.1.0

Session ID: rs20260514_100930
Session Root: `docs/review_sessions/20260514_100930_release-1.1.0/`
Compiled At: 2026-05-14 10:09:30
Compiled By: claudecode_claude_opus_4_7 (Facilitator)

This document is the authoritative inventory of inputs for the 1.1.0
convergence session. It freezes the state at compile time so reviewers
work from a shared snapshot. Live GitHub state may drift; cite this
document, not `gh issue list`, when authoring review artifacts.

## Repository State

- Branch: `master`
- HEAD: `ea89e80` (Bump RUNNER_VERSION to 1.0.8)
- Released: 1.0.8 on 2026-05-14
- Next planned release: 1.1.0 (milestone #3, due 2026-05-29)

## Existing Docs Inventory

Already present and considered baseline:

- `docs/ARCHITECTURE.md` — system architecture (pre-1.1.0 baseline)
- `docs/CLI_REFERENCE.md` — CLI contract (pre-1.1.0 baseline)
- `docs/EXIT_SIGNAL_HANDLING.md`
- `docs/FAQ.md`
- `docs/INSTALL.md`
- `docs/README.md`
- `docs/UNINSTALL.md`
- `docs/USER_GUIDE.md`
- `docs/USER_GUIDE_LOCAL.md`

Missing (referenced by milestone issues, must be produced by 1.1.0):

- `docs/ROADMAP-1.1.0.md` — Development Milestones (target of this
  session)
- `docs/TEST_PLAN-1.1.0.md` — Test Plan (target of this session)
- `docs/LOG_LAYOUT.md` — referenced by #18 (Phase F)

## Test Infrastructure

`tests/` contains:

- `run-all-tests.bash`
- `test-error-handling.bash`
- `test-local-lifecycle.bash`
- `test-system-lifecycle.bash`
- `test-system-infra.bash`
- `README.md`

The five test cases proposed in #21 (Detection without journal,
logrotate boundary, IOC_PORT atomic install, do_inspect bounded
runtime, permission enforcement) are not yet implemented.

## Verification Environments

Per memory record `project_test_hosts.md` and
`reference_iocrunner_bake_stack.md`:

- `top` — Debian 13 host, baseline pass environment
- `alsucl-psrv3` — Rocky NFS production-like environment
- `testbed-rocky8-iocrunner-server` (192.168.122.150) — baked from
  cloud-provision + nfs_sim, Rocky Linux 8.10
- `testbed-debian13-iocrunner-server` — baked Debian 13 testbed

## 1.1.0 Milestone — Issue Inventory

Status snapshot at compile time. 15 open + 1 closed.

### Phase A — Foundations

| # | Title | Priority | Labels | State |
| --- | --- | --- | --- | --- |
| 8 | Add LOG_DIR configuration variables | P0-blocker | feature, area/shell | OPEN |

### Phase B — Templates and Rotation

| # | Title | Priority | Labels | State |
| --- | --- | --- | --- | --- |
| 9 | Update system systemd template for log file output | P0-blocker | feature, area/template | OPEN |
| 10 | Update deploy_local_template for user units | P0-blocker | feature, area/template | OPEN |
| 15 | Deploy /etc/logrotate.d/procserv | P2-medium | ops, area/template | OPEN |

### Phase C — Detection and Permissions

| # | Title | Priority | Labels | State |
| --- | --- | --- | --- | --- |
| 11 | Rewrite crash detection as byte-offset log file scan | P0-blocker | refactor, area/detection | OPEN |
| 12 | Log file permission model | P1-high | feature, area/permissions | OPEN |

### Phase D — Extensions and Operations

| # | Title | Priority | Labels | State |
| --- | --- | --- | --- | --- |
| 17 | Remove systemd-journal group grants from operators | P2-medium | ops, area/permissions | OPEN |
| 24 | Dual-path crash detection with journal fallback | P2-medium | feature, area/detection | OPEN |

Note: per-IOC `CRASH_LOG_PATTERNS_EXTRA` override (originally numbered
#25 in epic #7) shipped earlier as commit `f0e4ebf` in 1.0.8. The epic
text references "#25" — to be resolved at convergence (decision: drop
from 1.1.0 epic phase list vs document as already-delivered).

### Phase D+ — Rocky 8 Compatibility (proposed addition)

| # | Title | Priority | Labels | State |
| --- | --- | --- | --- | --- |
| 49 | ioc-runner inspect Netlink/UDS rendering fails on Rocky 8 | P2-medium | bug, tests | OPEN |

Originally floating, moved to milestone 1.1.0 during pre-session
review (2026-05-14). Not present in epic #7 phase list. UD002
in README requires User decision on phase placement.

Working hypothesis: #49 may auto-resolve when #11 (crash detection
rewrite) and a parallel inspect rework move to log-file basis,
removing the `ss`/Netlink path dependency on Rocky 8.

### Phase E — Tests

| # | Title | Priority | Labels | State |
| --- | --- | --- | --- | --- |
| 21 | Integration test suite expansion | P3-low | ops, area/detection | OPEN |

### Phase F — Documentation

| # | Title | Priority | Labels | State |
| --- | --- | --- | --- | --- |
| 18 | Add docs/LOG_LAYOUT.md | P3-low | docs | OPEN |
| 19 | Update CHANGELOG.md for v1.1.0 | P3-low | docs | OPEN |
| 20 | Update README.md migration section | P3-low | docs | OPEN |

### Phase G — Release

| # | Title | Priority | Labels | State |
| --- | --- | --- | --- | --- |
| 22 | Bump RUNNER_VERSION to 1.1.0 | P3-low | ops | OPEN |

### Epic Container

| # | Title | Priority | Labels | State |
| --- | --- | --- | --- | --- |
| 7 | [epic] Redirect procServ output to dedicated log file | P0-blocker | feature, area/detection, area/template | OPEN |

### Closed In Scope

| # | Title | Priority | State | Resolution |
| --- | --- | --- | --- | --- |
| 50 | Local-lifecycle STEP 25 crash detection fails on Rocky 8 (inactive user journal) | P2-medium | CLOSED | Closed in 1.0.8 via journal-readability preflight |

## Dependency Graph (per issue bodies)

```
#8 (LOG_DIR vars)
  -> #9 (system template)
  -> #10 (local template)
  -> #11 (crash detection rewrite)
  -> #12 (permission model)        depends #6, #7
  -> #15 (logrotate)               depends #6
  -> #17 (remove journal grants)   depends #8
  -> #24 (journal fallback)        depends #8
  -> #49 (Rocky 8 inspect)         independent / parallel
  -> #21 (test expansion)          depends #8, #11, #12, #13
  -> #18, #19, #20 (docs)          depend on prior phases
  -> #22 (version bump)            depends on all above
```

Note: #6 and #13 do not appear in the 1.1.0 milestone open list. They
may be already-merged precursors or orphan references. Decision needed
at convergence (recorded as F-001 candidate in the initial review).

## Cross-Cutting Concerns

### CC1. Two-mode coverage

Every Phase B/C/D change must hold for both `--local` (XDG_STATE_HOME)
and system (`/var/log/procserv`) modes. Test coverage must demonstrate
both.

### CC2. Rocky 8 vs Debian 13 parity

Verification matrix must include both distros for any phase touching
journal, file permissions, or system socket diagnostics. Confirmed
gaps from 1.0.x:

- STEP 25 (crash detection) — fixed in 1.0.8 (#50)
- STEP 17 / 24 (inspect Netlink/UDS) — #49 OPEN

### CC3. NFS root_squash compatibility

Phase 4 lifecycle test documented an NFS root_squash limitation in
1.0.8 (`d0bb7a9`). Phase B template work must not regress this.

### CC4. systemd version floor

`LogsDirectory=` requires systemd >= 235. Both supported distros meet
this:

- Debian 13: systemd 256
- Rocky 8: systemd 239

Stated in #9 acceptance, must be recorded in `LOG_LAYOUT.md`
prerequisites.

## Backlog Reference (out of scope)

| # | Title | Notes |
| --- | --- | --- |
| 26 | Upstream procServ SIGUSR1 log reopen | External upstream work. UD003: confirm whether referenced from 1.1.0 docs (as forward-looking note) or not. |

## Source Inputs For Reviewer 1

The Reviewer 1 initial review_report should cover:

1. Phase boundaries — are A~G the right granularity, or should B/C be
   split or merged?
2. Cross-Check Policy — is the SKIP-allowed designation for Phase F
   defensible?
3. #49 phase placement — D+ standalone, fold into B (template), or
   defer to a separate milestone?
4. Acceptance criteria sufficiency per phase, especially for #11
   (crash detection) and #12 (permission model).
5. Test coverage gaps per Phase B/C/D vs CC1 / CC2 / CC3.
6. Risk assessment for executing all Phases by 2026-05-29 due date.

Reviewer 1 produces `reviews/rev<ts>_<reviewer1_agent_model>_initial.md`
per the `agent-review-convergence` review_report template.
