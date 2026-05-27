# EPICS IOC Runner 1.1.0 Development Roadmap

**Release codename:** Journal Decoupling Release
**Due:** 2026-05-29
**Milestone:** [1.1.0](https://github.com/jeonghanlee/epics-ioc-runner/milestone/3)
**Tracking epic:** [#7](https://github.com/jeonghanlee/epics-ioc-runner/issues/7)

## Overview

Release 1.1.0 re-routes procServ stdout from the systemd journal to a
dedicated, group-readable log file owned by the `ioc` group. The
runner reads crash patterns directly from that log file instead of
shelling out to `journalctl`, which removes the operational
requirement that IOC operators hold the `systemd-journal` supplementary
group.

A secondary scope item is a Rocky 8 compatibility gate for the
`inspect` command (Netlink/UDS rendering).

The release is structured as an ordered phase plan; each phase has a
narrow acceptance criterion and a permanent verification command. The
final phase bumps the runner version and tags the release.

## Motivation

Pre-1.1.0 crash detection executed `journalctl --user -u
epics-@<name>.service` and grepped the output for crash patterns.
Operators without `systemd-journal` group membership receive empty
journal output, which the runner misinterpreted as clean startup,
producing false "successfully started" messages on actual failures.

Granting `systemd-journal` to operators as a workaround over-exposes
the host journal (sshd, kernel, unrelated services) and violates least
privilege in multi-tenant lab environments.

## Target Architecture (post-1.1.0)

```text
IOC stdout
  -> procServ --logfile=${LOG_DIR}/${IOC_NAME}.log
    -> filesystem
       system mode:  /var/log/procserv/<name>.log  (0644, ioc-srv:ioc)
       --local mode: ${XDG_STATE_HOME:-${HOME}/.local/state}/procserv/<name>.log (0640, user)
      -> ioc-runner direct read
         byte-offset scan from the start-of-call cursor
```

systemd continues to receive procServ stderr for administrator
diagnostics via `StandardError=inherit`, but the journal is no longer
on the runner critical path. `inspect` continues to use file descriptor
diagnostics; #49 covers a Rocky 8 compatibility gap.

## Pre-1.1.0 Prerequisites (already delivered)

These satisfy `Depends On` references in #11, #12, and #21:

| Issue | Title | Closed in |
| --- | --- | --- |
| [#6](https://github.com/jeonghanlee/epics-ioc-runner/issues/6) | Align crash scan window with service start timestamp | 1.0.4 |
| [#13](https://github.com/jeonghanlee/epics-ioc-runner/issues/13) | Enable `set -o pipefail` | 1.0.5 |
| [#23](https://github.com/jeonghanlee/epics-ioc-runner/issues/23) | Adopt `set -u` with full variable audit | 1.0.8 |
| [#25](https://github.com/jeonghanlee/epics-ioc-runner/issues/25) | Per-IOC `CRASH_LOG_PATTERNS` override | 1.0.8 |

## Acceptance Amendments

Adopted during the 1.1.0 readiness session and recorded
2026-05-21 after the permission-model consolidation into
[`PERMISSION_MODEL.md`](PERMISSION_MODEL.md). Phase-section
acceptance text below is preserved verbatim for traceability; the
items listed here override it. `PERMISSION_MODEL.md` is the
authoritative source for the resulting end state.

| Phase | Original acceptance item | Amended end state | Reason |
| --- | --- | --- | --- |
| B-1 (#9) | `LogsDirectory=procserv`, `LogsDirectoryMode=0750` in system unit | `LogsDirectory=` NOT used; directory created by `setup-system-infra.bash` via `install -d -o root -g ioc -m 2775` + default ACLs | `LogsDirectory=` chowns the directory to `User=/Group=` on every activation, overriding the `root:ioc` ownership that the three-principal model requires |
| B-1 (#9) | Log file mode `0640` | Log file mode `0644` | procServ uses hardcoded `open(O_CREAT, 0644)` (`procServ.cc:924`); system unit carries no `UMask=` so the default `0022` preserves `0644` |
| C2 (#12) | System log directory mode `2770`; non-`ioc` user read denied | System log directory mode `2775`; non-`ioc` user read permitted at file-mode layer (sudoers gate still restricts state-changing `systemctl` verbs) | Site policy requires every host user to read every log file at minimum; access boundary for IOC state changes remains the `%ioc` sudoers gate, not file mode |

## Phase Plan

Phases execute in order. Each phase commits to the `release-1.1.0`
branch only after a Reviewer cross-check passes. Final merge to
`master` and tag `1.1.0` happen at Phase G.

| Phase | Issues | Scope | Cross-check |
| --- | --- | --- | --- |
| A | [#8](https://github.com/jeonghanlee/epics-ioc-runner/issues/8) | LOG_DIR configuration variables | required |
| B-1 | [#9](https://github.com/jeonghanlee/epics-ioc-runner/issues/9) | system systemd template emits log file | required |
| B-2 | [#10](https://github.com/jeonghanlee/epics-ioc-runner/issues/10) | `deploy_local_template` user unit log path | required |
| B-3 | [#15](https://github.com/jeonghanlee/epics-ioc-runner/issues/15) | `/etc/logrotate.d/procserv` deployment | required |
| C1 | [#11](https://github.com/jeonghanlee/epics-ioc-runner/issues/11) | byte-offset crash detection rewrite | required (P0) |
| C2 | [#12](https://github.com/jeonghanlee/epics-ioc-runner/issues/12) | log file permission model | required (security surface) |
| D | [#17](https://github.com/jeonghanlee/epics-ioc-runner/issues/17), [#24](https://github.com/jeonghanlee/epics-ioc-runner/issues/24) | journal grant removal; #24 fallback dropped | required |
| D+ | [#49](https://github.com/jeonghanlee/epics-ioc-runner/issues/49) | Rocky 8 `inspect` Netlink/UDS rendering | required |
| E | [#21](https://github.com/jeonghanlee/epics-ioc-runner/issues/21) | integration test expansion (T1-T5) | required |
| F | [#18](https://github.com/jeonghanlee/epics-ioc-runner/issues/18), [#19](https://github.com/jeonghanlee/epics-ioc-runner/issues/19), [#20](https://github.com/jeonghanlee/epics-ioc-runner/issues/20) | docs — LOG_LAYOUT, CHANGELOG, README migration | required for #18; SKIP-allowed for #19, #20 |
| G | [#22](https://github.com/jeonghanlee/epics-ioc-runner/issues/22) | RUNNER_VERSION bump to 1.1.0 + tag | required (release gate) |

## Current Tracking Status

Last checked: 2026-05-27 against GitHub milestone
[`1.1.0`](https://github.com/jeonghanlee/epics-ioc-runner/milestone/3).

| Work unit | Issues | Status | Pending dependency |
| --- | --- | --- | --- |
| Phase A | [#8](https://github.com/jeonghanlee/epics-ioc-runner/issues/8) | Done | none |
| Phase B-1 | [#9](https://github.com/jeonghanlee/epics-ioc-runner/issues/9) | Done | none |
| Phase B-2 | [#10](https://github.com/jeonghanlee/epics-ioc-runner/issues/10) | Done | none |
| Phase B-3 | [#15](https://github.com/jeonghanlee/epics-ioc-runner/issues/15) | Done | none |
| Phase C1 | [#11](https://github.com/jeonghanlee/epics-ioc-runner/issues/11) | Done | none |
| Phase C2 | [#12](https://github.com/jeonghanlee/epics-ioc-runner/issues/12) | Done | none |
| Phase D | [#17](https://github.com/jeonghanlee/epics-ioc-runner/issues/17), [#24](https://github.com/jeonghanlee/epics-ioc-runner/issues/24) | Done | none |
| Phase D+ | [#49](https://github.com/jeonghanlee/epics-ioc-runner/issues/49) | Done | none |
| Phase E | [#21](https://github.com/jeonghanlee/epics-ioc-runner/issues/21) | In progress | integration test expansion remains open; related open test/detection issues [#52](https://github.com/jeonghanlee/epics-ioc-runner/issues/52), [#55](https://github.com/jeonghanlee/epics-ioc-runner/issues/55) |
| Phase F | [#18](https://github.com/jeonghanlee/epics-ioc-runner/issues/18), [#19](https://github.com/jeonghanlee/epics-ioc-runner/issues/19), [#20](https://github.com/jeonghanlee/epics-ioc-runner/issues/20) | In progress | documentation issues remain open |
| Phase G | [#22](https://github.com/jeonghanlee/epics-ioc-runner/issues/22) | Not started | release version bump and tag remain open |
| Additional milestone fixes | [#56](https://github.com/jeonghanlee/epics-ioc-runner/issues/56) | In progress | permission-model install precheck remains open |

## Acceptance and Verification per Phase

### Phase A — LOG_DIR variables (#8)

**Acceptance:** `ioc-runner --local` resolves `LOG_DIR` to
`$XDG_STATE_HOME/procserv` (or fallback `$HOME/.local/state/procserv`);
system mode resolves to `/var/log/procserv`; environment overrides
`IOC_RUNNER_SYSTEM_LOG_DIR`, `IOC_RUNNER_LOCAL_LOG_DIR`, and
`IOC_RUNNER_LOG_DIR` all take effect; foot-gun warning fires when
`IOC_RUNNER_LOG_DIR` is set in system mode and differs from
`SYSTEM_LOG_DIR`.

**Verification:** `tests/test-error-handling.bash` STEP 10
(namespacing), STEP 11 (precedence), STEP 12 (foot-gun guard), STEP 13
(XDG fallback).

### Phase B-1 — system systemd template (#9)

**Acceptance:** `/etc/systemd/system/epics-@.service` contains
`--logfile=/var/log/procserv/%i.log` in `ExecStart=` and
`StandardError=inherit`. It does NOT use `LogsDirectory=` or
`LogsDirectoryMode=` (see the Acceptance Amendments table): the log
directory is created by `setup-system-infra.bash` via `install -d -o
root -g ioc -m 2775` plus default ACLs. Activation of a fresh service
creates `/var/log/procserv/<name>.log` owned by `ioc-srv:ioc` with mode
0644.

**Verification:** `systemctl cat epics-@<name>.service | grep -E
'(--logfile=|StandardError=)'` after deployment, and confirm no
`LogsDirectory=` line is present; `stat /var/log/procserv/<name>.log`.

### Phase B-2 — user systemd template (#10)

**Acceptance:** `ioc-runner --local install <conf>` creates
`${LOCAL_LOG_DIR}` with mode 0750. The rendered user unit at
`~/.config/systemd/user/epics-@.service` contains
`--logfile=${LOCAL_LOG_DIR}/%i.log`. Starting a fresh user IOC creates
the log file with mode 0640.

**Verification:** `ioc-runner --local install <conf>`, then `stat
${LOCAL_LOG_DIR}` and `systemctl --user cat epics-@<name>.service`.

### Phase B-3 — logrotate (#15)

**Acceptance:** `/etc/logrotate.d/procserv` exists with weekly
rotation, 8-week retention, and `copytruncate`. `logrotate -d` reports
no syntax errors. `logrotate -f` produces `<name>.log.1.gz` without
interrupting the IOC or invalidating its UDS socket.

**Verification:** `logrotate -d /etc/logrotate.d/procserv` and
`logrotate -f /etc/logrotate.d/procserv` followed by a successful
`ioc-runner restart`.

### Phase C1 — byte-offset crash detection (#11)

**Acceptance:** Crash detection succeeds with the operator removed
from `systemd-journal`. iocsh parse errors emitted within the first
second of startup are detected. Log rotation between two consecutive
`ioc-runner restart` calls does not produce false warnings.

**Verification:** `tests/run-all-tests.bash --local` STEP 25 (crash
detection); negative-permission probe (operator without
`systemd-journal`); rotation-boundary probe (T2 from Phase E).

### Phase C2 — permission model (#12)

**Acceptance:** `stat /var/log/procserv/<name>.log` shows mode 0644
and owner `ioc-srv:ioc`. A user in the `ioc` group reads the log, and a user outside `ioc` can
read it too at the file-mode layer (`0644`, `o+r`); the boundary for
state-changing operations is the `%ioc` sudoers gate, not file mode. No
operation requires `systemd-journal` membership.

**Verification:** post-install `stat`; `sudo -u <ioc-member> cat <log>`
succeeds; `sudo -u <non-ioc> cat <log>` also succeeds (file `0644`); the
`%ioc` sudoers gate denies a non-`ioc` `systemctl start` (T5 from Phase
E).

### Phase D — journal grant removal (#17); journal fallback dropped (#24)

**Acceptance for #17:** Operator accounts have no `systemd-journal`
supplementary group; `ioc-runner restart` on a faulty IOC under the
restricted account still emits the crash warning.

**#24 (journal fallback) — dropped as won't-fix.** Under the
dedicated-logfile architecture procServ writes child output only to the
log file, not the journal, so a journal fallback has nothing to scan.
An unreadable log yields a "startup logs could not be scanned" warning,
not a journal scan.

**Verification:** `id <operator>` after `gpasswd -d`; controlled probe
with `chmod 000 ${log}; ioc-runner restart <ioc>` now yields the
could-not-scan warning.

### Phase D+ — Rocky 8 inspect compatibility (#49)

**Acceptance:** On `testbed-rocky8-iocrunner-server`, both
`tests/test-local-lifecycle.bash` STEP 17 (local inspect) and
`tests/test-system-lifecycle.bash` STEP 24 (system inspect) pass. No
regression on Debian 13 hosts.

**Verification:** suite logs from the Rocky 8 testbed and the Debian
13 testbed.

### Phase E — integration test expansion (#21)

**Acceptance:** T1 through T5 are committed to `tests/`, fail on the
1.0.x baseline, pass on 1.1.0 HEAD on both Debian 13 and Rocky 8.

**Verification:** baseline-fail run on `1.0.8` tag; HEAD-pass run on
`release-1.1.0`. T1 through T5 are specified in
`docs/TEST_PLAN-1.1.0.md`.

### Phase F — documentation (#18, #19, #20)

**Acceptance for #18:** `docs/LOG_LAYOUT.md` is committed and linked
from `docs/README.md` index. Section coverage: data flow, system-mode
paths, local-mode paths, group membership, log rotation, troubleshooting.
Operator can follow the document without reading source.

**Acceptance for #19:** `CHANGELOG.md` has a 1.1.0 section covering
Breaking Changes, New Features, Fixes, Hardening, Migration.

**Acceptance for #20:** `docs/README.md` (or top-level `README.md`)
has a clearly linked "Upgrading from 1.0.x" section with ordered
upgrade steps and a troubleshooting quickref to `LOG_LAYOUT.md`.

**Verification:** rendered Markdown is clean; TOC links resolve.

### Phase G — release (#22)

**Acceptance:** `bin/ioc-runner` line 14 reads
`RUNNER_VERSION="1.1.0"`. `ioc-runner -V` prints `1.1.0` plus the
git hash. Git tag `1.1.0` exists at the merge commit on `master` and
the GitHub Release page links to `CHANGELOG.md`,
`docs/ROADMAP-1.1.0.md`, and `docs/LOG_LAYOUT.md`.

**Verification:** `ioc-runner -V`; `git tag --list '1.1.0'`; GitHub
Release URL.

## Migration Summary (from 1.0.x)

Site administrators upgrading from 1.0.x will:

1. Install the 1.1.0 runner binary.
2. Re-run `setup-system-infra.bash --full` to deploy the updated
   system systemd template and the logrotate config.
3. `systemctl daemon-reload` and restart each IOC; `procServ` will
   begin writing to `/var/log/procserv/<name>.log`.
4. Verify mode 0644 owned by `ioc-srv:ioc`.
5. Remove `systemd-journal` supplementary group from IOC operator
   accounts.

Detailed step-by-step migration lives in `docs/README.md` "Upgrading
from 1.0.x" section (delivered by #20) and the layout reference in
`docs/LOG_LAYOUT.md` (delivered by #18).

## Out of Scope

- Upstream procServ log-reopen behavior is not part of this release.
  This release uses logrotate `copytruncate`.
- `docs/ARCHITECTURE.md` and `docs/CLI_REFERENCE.md` rewrites. Only
  deltas necessary for 1.1.0 behavior are accepted.
- IPv6, TLS, or any transport-layer change.
- `bin/ioc-runner` start/restart uses a fixed `sleep 5` (around line 1536)
  before the active-state check. Replacing it with active-state polling plus
  a minimum stabilization window — preserving the crash-loop scan that
  follows — is deferred to a post-1.1.0 follow-up issue.

## Cross-References

- Architecture: [`ARCHITECTURE.md`](ARCHITECTURE.md)
- CLI surface: [`CLI_REFERENCE.md`](CLI_REFERENCE.md)
- Log layout (delivered by #18): `LOG_LAYOUT.md`
- Test plan: [`TEST_PLAN-1.1.0.md`](TEST_PLAN-1.1.0.md)
- Tracking epic: [#7](https://github.com/jeonghanlee/epics-ioc-runner/issues/7)
- Milestone: [1.1.0](https://github.com/jeonghanlee/epics-ioc-runner/milestone/3)
