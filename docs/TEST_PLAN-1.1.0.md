# EPICS IOC Runner 1.1.0 Test Plan

**Companion to:** [`ROADMAP-1.1.0.md`](ROADMAP-1.1.0.md)
**Milestone:** [1.1.0](https://github.com/jeonghanlee/epics-ioc-runner/milestone/3)

## Scope

This document defines the verification surface for the 1.1.0 release.
It covers:

- Phase acceptance matrices for the two highest-risk phases
  ([#11](https://github.com/jeonghanlee/epics-ioc-runner/issues/11)
  crash detection rewrite, and
  [#12](https://github.com/jeonghanlee/epics-ioc-runner/issues/12)
  log file permission model).
- Per-phase narrow verification commands, run at each handoff and
  consolidated into the permanent test suite in Phase E.
- Specifications for the five integration tests
  ([T1-T5](#t1-t5-integration-tests)) added by
  [#21](https://github.com/jeonghanlee/epics-ioc-runner/issues/21).
- Host coverage matrix for cross-platform validation.
- Cross-cutting concerns CC1-CC4.

## Cross-Cutting Concerns

| ID | Concern | Applies to phases |
| --- | --- | --- |
| CC1 | Two-mode parity (system + `--local`) | B, C, D |
| CC2 | Distribution parity (Debian 13 + Rocky 8.10) | B, C, D, D+, E |
| CC3 | NFS root_squash compatibility | B, C |
| CC4 | POSIX ACL support (`setfacl`, `getfacl` from the `acl` package) | B-1, C2 |

CC4 is satisfied by both supported distributions: Debian 13 and
Rocky 8.10 ship `acl` as a default package on minimal installs.
`setup-system-infra.bash` runs a `command -v setfacl getfacl`
preflight in `--full` mode and exits with an install hint if the
binaries are missing. The 1.1.0 unit text does NOT use systemd's
`LogsDirectory=` directive — it would chown the log directory to
the unit `User=`/`Group=` on every activation, overriding the
`root:ioc` ownership the permission model requires.

## Phase Acceptance Matrix

The two phases below require explicit acceptance across the full
matrix. Cells reference test IDs defined later in this document.

### Phase C1 — `#11` Byte-offset crash detection

| Aspect | Local | System | Debian 13 | Rocky 8 | NFS root_squash | Negative perm |
| --- | --- | --- | --- | --- | --- | --- |
| Byte-offset scan on healthy IOC | T-C1a-L | T-C1a-S | required | required | required | n/a |
| iocsh parse error detected within 1s | T-C1b-L | T-C1b-S | required | required | required | n/a |
| Rotation or truncation mid-run does not false-positive | T-C1c-L | T-C1c-S | required | required | required | n/a |
| Primary path requires no journalctl access | T-C1d-L | T-C1d-S | required | required | n/a | n/a |

### Phase C2 — `#12` Permission model

System mode targets `root:ioc 2770` directory + `ioc-srv:ioc 0644`
procServ-created files (procServ's hardcoded `open(O_CREAT, 0644)`
mode_arg is preserved; system unit does NOT set `UMask=`). Default
ACLs raise engineer-created files in the same directory to
`<engineer>:ioc 0664` for cross-creator group consistency. Local
mode targets `<user>:<user> 0750` directory + `<user>:<user> 0640`
files (single principal, user-mode unit keeps `UMask=0027`).
Access boundary for `ioc-runner` system operations is enforced by
the sudoers policy (`%ioc` group). See `docs/LOG_PERMISSIONS.md`.

| Aspect | Local | System | Debian 13 | Rocky 8 | NFS root_squash | Negative perm |
| --- | --- | --- | --- | --- | --- | --- |
| Directory mode at install (system: `2770` setgid; local: `0750`) | T-C2a-L | T-C2a-S | required | required | NFS-aware | n/a |
| Default ACLs present on system log dir (`g:ioc:rw`, `o::r--`, `m::rw`) | n/a | T-C2a2-S | required | required | NFS-aware | n/a |
| Log file mode after start (system: `0644`; local: `0640`) | T-C2b-L | T-C2b-S | required | required | NFS-aware | n/a |
| `ioc` group member reads log (system) | n/a | T-C2c-S | required | required | NFS-aware | n/a |
| Engineer-created file inside dir lands at `*:ioc 0664` (default ACL effect on engineer's `open(0666)` mode_arg) | n/a | T-C2c2-S | required | required | NFS-aware | n/a |
| Privileged `systemctl` verbs (`start`/`stop`/`restart`/`enable`/`disable`/`daemon-reload`) on `epics-@*.service` gated by sudoers to `%ioc`; non-`ioc` `sudo systemctl start epics-@<name>.service` rejected | n/a | T-C2d-S | required | required | n/a | required |
| No `systemd-journal` membership required | T-C2e-L | T-C2e-S | required | required | n/a | n/a |

## Per-Phase Verification Commands

Each phase handoff carries at least the following verification. Phase
E consolidates these into the permanent suite where useful; ad-hoc
commands run by the implementer remain valid as evidence in handoff
artifacts.

| Phase | ID | Representative command |
| --- | --- | --- |
| A | V-A | `tests/test-error-handling.bash` STEP 10, 11, 12, 13 |
| B-1 | V-B-1 | `systemctl cat epics-@<name>.service \| grep -E '^(User\|Group)='` returns `User=ioc-srv`, `Group=ioc`; `grep '^UMask='` returns nothing (system unit relies on systemd default `0022` to preserve procServ's `0644` mode_arg); `grep -E '^ExecStart='` contains `--logfile=${SYSTEM_LOG_DIR}/%i.log`; `grep LogsDirectory` returns nothing; `stat -c '%U:%G %a' ${SYSTEM_LOG_DIR}` returns `root:ioc 2770`; `getfacl ${SYSTEM_LOG_DIR}` shows default entries `g:ioc:rw-`, `o::r--`, `m::rw-` |
| B-2 | V-B-2 | `ioc-runner --local install <conf>`; `grep -E '^(UMask\|ExecStart)' ~/.config/systemd/user/epics-@.service` shows `UMask=0027` and `--logfile=${LOCAL_LOG_DIR}/%i.log`; `stat ${LOCAL_LOG_DIR}` returns `<user>:<user> 750`; repeated install in same second produces two distinct `~/.config/systemd/user/epics-@.service.bak.*` files |
| B-3 | V-B-3 | `logrotate -d /etc/logrotate.d/procserv`; `logrotate -f /etc/logrotate.d/procserv`; `ioc-runner restart <ioc>` |
| C1 | V-C1 | `ioc-runner --local start <bad-ioc>` under operator without `systemd-journal`; expect crash warning |
| C2 | V-C2 | Case 1 (procServ-created): `stat -c '%U:%G %a' ${SYSTEM_LOG_DIR}/<ioc>.log` returns `ioc-srv:ioc 644`; `sudo -u <ioc-member> cat <log>` succeeds; `getfacl` shows `mask::r--` (procServ's `0644` mode_arg restricts mask to `r--`). Case 2 (engineer-created, default ACL effect): engineer in `ioc` runs `touch ${SYSTEM_LOG_DIR}/probe.log` under shell `umask 0022`; `stat -c '%U:%G %a' ${SYSTEM_LOG_DIR}/probe.log` returns `<engineer>:ioc 664` (`touch` uses `open(0666)` mode_arg; default ACL `g:ioc:rw` + `m::rw` preserves group write); `sudo -u ioc-srv test -w <probe.log>` exits 0. sudoers gate (narrow): as a non-`ioc` user, `sudo /usr/bin/systemctl start epics-@<name>.service` exits with `not allowed to execute`. Non-`ioc` `ioc-runner` invocation and read-only `ioc-runner status`/`is-active` are not gated by sudoers |
| D | V-D-1 / V-D-2 | `id <operator>` shows `systemd-journal` absent; `chmod 000 <log>; ioc-runner restart` falls back to journal or informs |
| D+ | V-Dplus | `bash tests/run-all-tests.bash --local` STEP 17 on Rocky 8; `sudo -E bash tests/test-system-lifecycle.bash` STEP 24 on Rocky 8 |
| E | V-E | `bash tests/run-all-tests.bash --local` clean PASS on 1.1.0 HEAD; T1-T5 FAIL on `1.0.8` tag |
| F-1 | V-F-1 | rendered Markdown clean; `docs/README.md` links to `LOG_LAYOUT.md` |
| F-2 | V-F-2 | `CHANGELOG.md` 1.1.0 section follows existing format; all in-scope merged issues represented |
| F-3 | V-F-3 | TOC link to migration section; commands copy-pastable |
| G | V-G | `ioc-runner -V` outputs `1.1.0` plus git hash; `git tag --list '1.1.0'` |

## T1-T5 Integration Tests

Defined by [#21](https://github.com/jeonghanlee/epics-ioc-runner/issues/21).
Each test exercises new 1.1.0 behavior and must fail on the `1.0.8`
baseline (proof of behavioral coverage).

### T1 — Detection without journal access

**Validates:** Phase C1, Phase D-2.
**Setup:** Fresh IOC with malformed `st.cmd` (unbalanced quote).
**Action:** `sudo -u <operator-without-systemd-journal> ioc-runner
start <ioc>`.
**Expected:** Crash warning is emitted; warning message references
the crash pattern match.

### T2 — Detection across logrotate boundary

**Validates:** Phase B-3, Phase C1.
**Setup:** Running IOC with active log file.
**Action:** `logrotate -f /etc/logrotate.d/procserv`, then
`ioc-runner restart <ioc>`.
**Expected:** New log file created; crash detection reads new content;
no false positives from rotated historical log entries.

### T3 — IOC_PORT atomic install

**Validates:** Phase A foundations (file write atomicity around
`IOC_PORT` resolution).
**Setup:** Prepared conf file.
**Action:** `timeout 0.01 ioc-runner install <conf>` in a loop for at
least 100 iterations.
**Expected:** Every surviving `<ioc>.conf` in `${CONF_DIR}` contains a
valid `IOC_PORT=` line, or no file exists at all. Partially-written
conf files are never observed.

### T4 — `do_inspect` bounded runtime

**Validates:** Phase D+ (#49) and general `inspect` performance.
**Setup:** Host with 500+ unrelated UDS sockets (spawn via `socat`).
**Action:** `time ioc-runner inspect <healthy-ioc>`.
**Expected:** Wall-clock time under 1 second.

### T5 — Permission enforcement

**Validates:** Phase C2.
**Setup:** Post-install state with one IOC running and its log file
present.
**Action:** `sudo -u <user-not-in-ioc-group> cat <log>`.
**Expected:** `cat` fails with permission denied.

## Host Coverage Matrix

| Host | Role | Required validations |
| --- | --- | --- |
| `top` (Debian 13) | Dev baseline | Every per-phase verification; T1-T5; 1.0.x baseline fail-then-pass for T1-T5 |
| `testbed-debian13-iocrunner-server` | Clone-and-test, install-and-test | System mode for B-1, C2, D-2, F-1 reference |
| `testbed-rocky8-iocrunner-server` | Rocky 8 gate | V-Dplus (STEP 17 + STEP 24); V-C1 and V-C2 cross-distro; T1, T2, T4 |
| `alsucl-psrv3` | Rocky NFS production-like | install-and-test; NFS root_squash regression for B and C |

## Acceptance Gate Summary

The 1.1.0 release is acceptable when:

1. Every phase handoff has Reviewer cross-check accepted, except F-2
   and F-3 which are SKIP-allowed.
2. The Phase Acceptance Matrices for #11 (C1) and #12 (C2) are
   complete across the matrix.
3. T1-T5 fail on the 1.0.8 tag and pass on `release-1.1.0` HEAD.
4. `ioc-runner -V` reports `1.1.0` plus the git hash at the tagged
   commit.
5. The migration steps in `docs/README.md` "Upgrading from 1.0.x"
   produce a clean upgrade on at least one of `top`,
   `testbed-debian13-iocrunner-server`, and
   `testbed-rocky8-iocrunner-server`.

## Cross-References

- Roadmap: [`ROADMAP-1.1.0.md`](ROADMAP-1.1.0.md)
- Architecture: [`ARCHITECTURE.md`](ARCHITECTURE.md)
- CLI: [`CLI_REFERENCE.md`](CLI_REFERENCE.md)
- Tracking epic: [#7](https://github.com/jeonghanlee/epics-ioc-runner/issues/7)
- Milestone: [1.1.0](https://github.com/jeonghanlee/epics-ioc-runner/milestone/3)
