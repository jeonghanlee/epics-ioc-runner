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

## Why the Plan Runs in Full

Each cycle this plan runs in its entirety — every L and S scenario on both
goldens — not a spot-check of the scenarios a cycle happened to touch. The
full run is the contract, for three structural reasons:

- **A prior pass is not this tree's pass.** The release gate is the first
  state in which all of a cycle's changes coexist (`testplan_X.X.X.md`
  "Release Gate"). Multi-user behavior is an emergent property of the whole
  permission surface, not of any single change; a scenario that passed a
  previous cycle passed against a different tree, so it is re-established
  against the tree that actually ships.
- **The defect lives in the seam.** Each change can be individually correct
  while the fault sits in the overlap between two — a seam invisible to a
  reader of one issue or one file. Only running every scenario together, on
  the final tree, exercises those seams; a "what changed" spot-check is
  structurally blind to them.
- **A null result is a result worth recording.** "Re-ran, still passes" is
  not wasted work. Skipping a scenario because it passed before files the
  verdict in a private drawer, and the next cycle pays the full cost of
  asking the same question from the start. Recording the full run is what
  stops the question from being re-litigated every release.

The cost of the full run is bounded and known; the cost of a missed seam or
a re-litigated verdict is neither.

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

### User Fixtures

The scenarios require a fixed set of principal accounts, provisioned before
the run. These definitions are the canonical fixture and must match exactly:
a scenario's `ioc` / non-`ioc` outcome is meaningless if the membership is
wrong, so the fixture is specified here rather than left to the run.

| Account | Mode | `ioc` group | linger | Role in the plan |
| :--- | :--- | :---: | :---: | :--- |
| `opa` | system | yes | — | operator; state changes permitted |
| `opb` | system | yes | — | second operator; shared-asset and cross-operator scenarios |
| `obs` | system | no | — | observer negative control; denied at the sudo gate |
| `usera` | local | no | yes | local-mode user A; session isolation |
| `userb` | local | no | yes | local-mode user B; cross-user negative |
| `ioc-srv` | system | — | — | non-login service account; created by `setup-system-infra.bash` |
| `root` | system | — | — | installer actions only |

Provisioning is owned by the `ansible-provision` `test_users` role
(`roles/test_users`): `opa`/`opb` via `useradd` + `usermod -aG ioc`; `obs`
via `useradd` with no group; `usera`/`userb` via `useradd` + `loginctl
enable-linger`. **The role is baked into the iocrunner golden** (the bake
applies `07_test_users.yml` after the nfs_sim step — ansible-provision
Phase C, 2026-07-05): a fresh variant boots with the accounts present;
verify with `getent group ioc` (lists `opa,opb`) and the linger listing
(`usera userb`). The role is still never imported by `site.yml`. Only on
goldens baked BEFORE Phase C do the accounts need per-run provisioning
(apply the role, or its equivalent `useradd` commands, after
`setup-system-infra.bash --full` has created the `ioc` group).

## Execution Harness

The scenarios switch between principals and drive `ioc-runner`
non-interactively. The mechanics below are the validated way to do that
without a login terminal.

- **Principal switching**: `sudo -niu <user>`. For local mode (`systemctl
  --user`), also pass `env XDG_RUNTIME_DIR=/run/user/<uid>
  DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/<uid>/bus`, after
  `loginctl enable-linger <user>`. The runtime dir `/run/user/<uid>` can lag a
  few seconds behind `enable-linger` (seen on debian13); verify it exists
  before the local run, and force it with `systemctl start user@<uid>` if
  missing.
- **Prompt- or console-bearing commands need a pty, a timeout, and EOF.**
  Under a non-interactive `sudo -niu`, commands that can prompt (`install`
  confirmation, `remove`) or hold a console (`attach`, `monitor`) hang. EOF
  alone (`</dev/null`) is not enough: such a command requires a terminal, so
  wrap it in a pty --
  `timeout -k 2 <N> script -qec "<cmd>" /dev/null </dev/null`. For an
  interactive console hold, feed a fifo-held stdin in place of `/dev/null` and
  let the server-side `stop` / `remove` end the client with EOF. A **manual
  `./st.cmd` run** (S7) likewise needs a held stdin (`sleep <N> | ./st.cmd`) or
  iocsh exits at once on EOF; expect a benign cross-owned `.iocsh_history`
  ERROR that the crash scan excludes (#92).
- **Payload and where to put it**: a `softIoc` executable-shebang `st.cmd`
  (`#!<abs softIoc>` then `iocInit`) is a sufficient stay-alive IOC, reused
  across local and system modes and both goldens; `ioc-runner generate
  <iocBoot>` produces the `.conf`. Put the iocBoot dir where the running
  account can reach it: **system mode `/opt/epics-iocs/<name>`** (setgid
  `2770 root:ioc`, so an operator can write it and `ioc-srv` can read/exec),
  **local mode `~/iocBoot/<name>`**. For S8, append `system "echo <TOKEN>"`
  after `iocInit` in `st.cmd` and set `CRASH_LOG_PATTERNS_EXTRA="<TOKEN>"` in
  the `.conf`.
- **Avoid login shells for the driver.** `bash -lc` pulls in shell aliases and
  EPICS-env banners that corrupt piped output; run the steps from a driver
  script (non-login `bash <file>`) that sources the EPICS environment itself.
- **EPICS env on a multi-OS golden: never glob `*/*`.** A golden can carry
  several OS EPICS trees (`/opt/epics/1.2.0/{debian-13,rocky-8.10,rocky-10.1,
  ubuntu-24.04}`), so `source /opt/epics/1.2.0/*/*/setEpicsEnv.bash` picks the
  alphabetically-first (debian-13) and is wrong on rocky8 (its `snc` then fails
  on a missing `libreadline`). Guard the source with `[ -z "$EPICS_BASE" ]`
  (rocky8 auto-loads via `profile.d`; debian13 does not), or source the exact
  per-OS path.
- **Where state lives** (the log-read and socket scenarios need exact paths):
  - Log: system `/var/log/procserv/<name>.log` (`ioc-srv:ioc`, group `r--`);
    local `~/.local/state/procserv/<name>.log` (`0640 <user>:<user>`, and
    `$HOME` is `0700` so a peer is blocked at the home dir too).
  - Socket: system `/run/procserv/<name>/control`; local
    `/run/user/<uid>/procserv/<name>/control`.

## Local-Mode Scenarios

Local mode runs as the invoking user through `systemctl --user`; the
verification target is isolation between users.

| ID | Scenario | Principals | Action -> Expected result | Reference |
| :--- | :--- | :--- | :--- | :--- |
| L1 | Session isolation | usera, userb | Each runs `ioc-runner --local install <conf>` then `--local start` (a duplicate conf name is permitted) -> each `--local list` shows only the invoker's IOC; user units are separated by `/run/user/<uid>`. | PERMISSION_MODEL.md "Local mode" |
| L2 | Cross-user interference blocked | userb -> usera | userb attempts `attach` / `stop` on usera's local IOC -> `attach` fails at socket resolution (distinct per-user paths); `stop` is refused by the U-4 gate (`No configuration found` in userb's own CONF_DIR, exit 1) before any `--user` unit is addressed. | per-user `XDG_RUNTIME_DIR` |
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
| S6 | Observer negative control | obs | obs runs `status` / `is-active` / `list` / `cat <log>` / `ls` (succeed) versus `start` (denied at the sudo gate) and `stop` / `remove` (denied by the runner's conf-resolution gate: obs cannot read the `2770` CONF_DIR, so the runner reports `Cannot read /etc/procServ.d ... (ioc group membership required)` and exits 1 before touching systemd). With IOCs running, obs `list` returns the empty result plus the permission hint `(socket directories are not readable by this user; ...)` since the `0770` socket dirs are not traversable outside `ioc` (#94); exit 0 unchanged. | PERMISSION_MODEL.md "Access Boundary"; FAQ Q1 |
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
- Scenario order matters where an IOC is torn down: **S4 removes its IOC**, so
  run any IOC-dependent probe (e.g. S10 on the same IOC) before S4, and
  re-create the payload for a later scenario that needs it. Local IOCs (L1-L3)
  and system IOCs (S1-S10) accumulate across a run; between runs clean up with
  `ioc-runner [--local] remove <name>`, and `pkill -u <user>` any process left
  stuck by a missing pty.
