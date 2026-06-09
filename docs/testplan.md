# EPICS IOC Runner — Test Plan

This document is the test plan for `epics-ioc-runner` verification. The
automated single-user suites and their invocation axes are documented in
[`../tests/README.md`](../tests/README.md); this plan covers verification
scenarios that span **multiple user principals** and **operational
workflows** the automated lifecycle suites do not exercise. New test plans
are added here.

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
| S4 | Removal while in use | opa, opb | opb has an IOC under `attach` / `monitor`; opa `stop` / `remove` it -> observe console-session and socket handling. **Assertion finalized after first run.** | FAQ Q6 |
| S5 | Cross-operator log read | opb -> opa | opb reads an opa-started IOC log and runs the crash scan -> group `r--` read; the scan runs under opb's UID with no sudo. | PERMISSION_MODEL.md "Permission Lifecycle"; FAQ Q9 |
| S6 | Observer negative control | obs | obs runs `status` / `is-active` / `list` / `cat <log>` / `ls` (succeed) versus `start` / `stop` / `remove` (all denied at the sudo gate). | PERMISSION_MODEL.md "Access Boundary"; FAQ Q1 |
| S7 | Disable / manual run / re-enable | opa (+ opb) | opa `disable` + `stop` -> run `st.cmd` manually -> `start` + `enable`; opb observes the intermediate state -> conf unchanged, only runtime state changes, opb sees disabled/inactive correctly. | FAQ Q5 |
| S8 | Crash-loop detection | opa | opa starts a deliberately failing IOC whose conf sets `CRASH_LOG_PATTERNS_EXTRA` -> the two-stage health check warns and the extra pattern matches. | FAQ Q6, Q7 |
| S9 | `IOC_CHDIR` non-conformance | opa, root | `install` with an `IOC_CHDIR` not writable by `ioc-srv` (a home / NFS path, and a path containing `..`) -> conformance warning + confirmation; root and operator give the identical result (metadata read, no sudo). | FAQ Q8; PERMISSION_MODEL.md "Site-provisioned paths"; #66 |
| S10 | Console socket access probe | opb, obs -> opa | opb and obs attempt `attach` / `monitor` / `inspect` on opa's IOC -> **to be determined empirically**; the UDS mode governs and is not covered by PERMISSION_MODEL.md. | FAQ Q6 |
| S11 | sudo-version residual risk | opa | Outside `ioc-runner`, opa issues `sudo systemctl start 'epics-@bad name.service'` -> on `rocky8` (glob) the sudo gate passes but systemd rejects the name; on `debian13` (regex) the gate denies it. | PERMISSION_MODEL.md "Residual risk on sudo < 1.9.10 hosts"; #68 |

## Notes

- S4 is observational and S10 is a probe: their assertions are recorded after
  the first run rather than asserted up front, because the behavior is not
  fixed by the current permission model.
- S11 documents a known least-privilege drift on sudo < 1.9.10, not an
  escalation path (`PERMISSION_MODEL.md` "Residual risk"). It is verified, not
  fixed, here; the fix is tracked as #68 (1.2.0).
