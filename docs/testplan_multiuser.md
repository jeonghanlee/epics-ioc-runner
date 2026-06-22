# EPICS IOC Runner — Multi-User Test Plan

This document is the version-independent multi-user test plan for
`epics-ioc-runner`. It covers verification scenarios that span **multiple
user principals** and **operational workflows** the automated single-user
suites (documented in [`../tests/README.md`](../tests/README.md)) do not
exercise.

Execution cadence: this plan runs identically at the end of every release
cycle, as the final release-gate step after the cycle's `testplan_X.X.X.md`
items are closed, and may additionally run on demand after any change that
touches the permission model. Cycle-specific test plans live in
`testplan_X.X.X.md`, not here; a scenario's expected result changes only
when a released change alters the model, amended by the cycle plan that
introduced the change.

The permission model these scenarios verify is defined in
[`PERMISSION_MODEL.md`](PERMISSION_MODEL.md); operational behavior is
described in [`FAQ.md`](FAQ.md). This plan references both rather than
restating them.

## Principal Model

System mode gates privileged state changes on `ioc` group membership at a
single point — the sudoers policy `/etc/sudoers.d/10-epics-ioc`, which grants
`%ioc` `NOPASSWD` on the privileged `systemctl` verbs against
`epics-@<name>.service` (`PERMISSION_MODEL.md` "Access Boundary"). The
boundary is therefore binary on `ioc` membership, not on general sudo rights.

| Role | Identity | `ioc` group | State changes (start/stop/remove) | Reads (status/log/list) |
| :--- | :--- | :---: | :--- | :--- |
| installer | `root` via sudo | — | one-time `setup-system-infra.bash` | — |
| operator | engineer ∈ `ioc` | yes | permitted | permitted (group `r--`) |
| observer | user ∉ `ioc` | no | denied at the sudo gate | permitted (other `r--`, systemd query) |

`ioc-srv` is the non-login service account that runs procServ; it is not a
human principal. Local mode is single-principal by construction
(`PERMISSION_MODEL.md` "Three-Principal Model").

## Test Environment

Both golden images carry a real systemd and sudo and run the full lifecycle.
They differ in sudo version, which selects the two sudoers emission branches,
so the pair covers both branches of scenario S11 without extra setup.

| Image | sudo | sudoers branch (`PERMISSION_MODEL.md` "Access Boundary") |
| :--- | :--- | :--- |
| `rocky8-iocrunner` | 1.9.5p2 | glob fallback (`epics-@*.service`) |
| `debian13-iocrunner` | >= 1.9.10 | anchored per-verb regex |

Required accounts (precondition for a run; the accounts and group
memberships must exist before the scenarios execute):

| Mode | Accounts |
| :--- | :--- |
| system | `opa`, `opb` in the `ioc` group (two operators); `obs` not in `ioc` (observer); `root` for installer actions. `ioc-srv` is created by `setup-system-infra.bash`. |
| local | `usera`, `userb` — ordinary login users, no `ioc` group, no sudo. |

Baking these accounts into the golden image (consistent with the existing
`ansible-provision` flow) keeps each run focused on behavior rather than
environment setup.

## Local-Mode Scenarios

Local mode runs as the invoking user through `systemctl --user`; the
verification target is isolation between users.

| ID | Scenario | Principals | Action -> Expected result | Reference |
| :--- | :--- | :--- | :--- | :--- |
| L1 | Session isolation | usera, userb | Each runs `ioc-runner --local install <conf>` then `--local start` (a duplicate conf name is permitted) -> each `--local list` shows only the invoker's IOC; user units are separated by `/run/user/<uid>`. | PERMISSION_MODEL.md "Local mode" |
| L2 | Cross-user interference blocked | userb -> usera | userb attempts `attach` / `stop` on usera's local IOC -> distinct session buses, userb cannot address usera's `--user` units. | per-user `XDG_RUNTIME_DIR` |
| L3 | Log read blocked | userb -> usera | userb reads usera's `<ioc>.log` -> `0640 <user>:<user>`, other has no read bit. | PERMISSION_MODEL.md "Local mode log directory" |

## System-Mode Scenarios

System mode runs IOCs as the shared `ioc-srv` account; the verification
target is the shared-asset and permission-boundary behavior across the three
roles.

| ID | Scenario | Principals | Action -> Expected result | Reference |
| :--- | :--- | :--- | :--- | :--- |
| S1 | Shared management | opa, opb | opa `install` + `start foo`; opb `status` / `stop` / `restart foo` -> opb succeeds (both `%ioc`, one shared unit). | PERMISSION_MODEL.md "Access Boundary"; FAQ Q1 |
| S2 | setgid conf collaboration | opa, opb | opa creates `/etc/procServ.d/foo.conf`; opb edits it -> directory `2770 root:ioc` setgid grants opb group-rw edit, file stays group `ioc`. | PERMISSION_MODEL.md "Setup-managed paths"; FAQ Q2 |
| S3 | Concurrency | opa, opb | opa and opb `start` / `stop` different IOCs simultaneously -> no interference, both succeed, per-unit state correct. | independent systemd instances |
| S4 | Removal while in use | opa, opb | opb has an IOC under `attach` / `monitor`; opa `stop` / `remove` it -> opb's console session terminates immediately with EOF (clean client exit); the socket directory is removed with the unit; no hang and no stale socket remain. | FAQ Q6 |
| S5 | Cross-operator log read | opb -> opa | opb reads an opa-started IOC log and runs the crash scan -> group `r--` read; the scan runs under opb's UID with no sudo. | PERMISSION_MODEL.md "Permission Lifecycle"; FAQ Q9 |
| S6 | Observer negative control | obs | obs runs `status` / `is-active` / `list` / `cat <log>` / `ls` (succeed) versus `start` / `stop` (denied at the sudo gate) and `remove` (aborted by the runner stop-failure guard when its embedded stop is sudo-denied). With IOCs running, obs `list` returns the empty result plus the permission hint `(socket directories are not readable by this user; ...)` since the `0770` socket dirs are not traversable outside `ioc` (#94); exit 0 unchanged. | PERMISSION_MODEL.md "Access Boundary"; FAQ Q1 |
| S7 | Disable / manual run / re-enable | opa (+ opb) | opa `disable` + `stop` -> run `st.cmd` manually -> `start` + `enable`; opb observes the intermediate state -> conf unchanged, only runtime state changes, opb sees disabled/inactive correctly. | FAQ Q5 |
| S8 | Crash-loop detection | opa | opa starts an IOC whose conf sets `CRASH_LOG_PATTERNS_EXTRA` and that reaches initialization, then emits the extra token while staying active -> the startup poll merges the per-IOC pattern and reports a post-initialization warning (exit 0), confirming `CRASH_LOG_PATTERNS_EXTRA` is corroborating, not a standalone failure. | FAQ Q6, Q7 |
| S9 | `IOC_CHDIR` non-conformance | opa, root | `install` with an `IOC_CHDIR` not writable by `ioc-srv` (a home / NFS path) -> conformance warning + confirmation. `install` with a path containing `..` -> unconditional hard error before the warning flow, no prompt, `--force` does not bypass (#66). In both variants root and operator give the identical result (metadata read, no sudo). | FAQ Q8; PERMISSION_MODEL.md "Site-provisioned paths"; #66 |
| S10 | Console socket access probe | opb, obs -> opa | opb and obs attempt `attach` / `monitor` / `inspect` on opa's IOC -> layered: a non-`ioc` principal is denied at conf resolution first (`/etc/procServ.d` `2770 root:ioc`), so the socket mode (`0770 ioc-srv:ioc`) is a second gate it never reaches; an `ioc` member attaches and monitors successfully; `inspect` is root-gated in system mode for every non-root principal regardless of `ioc` membership. Per-distro error wording and exit codes are not asserted. | FAQ Q6 |
| S11 | sudo-version residual risk | opa | Outside `ioc-runner`, opa issues `sudo systemctl start 'epics-@bad name.service'` -> on `rocky8` (glob) the sudo gate passes but systemd rejects the name; on `debian13` (regex) the gate denies it. | PERMISSION_MODEL.md "Residual risk on sudo < 1.9.10 hosts"; #68 |

## Notes

- The S4 and S10 expected results were finalized from the first plan run
  (2026-06-10, both golden images) — they began as an observational scenario
  and a probe because the behavior is not fixed by the permission model.
- S11 documents a known least-privilege drift on sudo < 1.9.10, not an
  escalation path (`PERMISSION_MODEL.md` "Residual risk"). It is verified, not
  fixed, here; the fix is tracked as #68 (1.2.0).
