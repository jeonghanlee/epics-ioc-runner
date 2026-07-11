# Operations FAQ (Frequently Asked Questions)

This document addresses common operational questions and scenarios regarding the `epics-ioc-runner` architecture, particularly for facilities transitioning from legacy management scripts or custom databases.

---

### Q1: Do we need a sysadmin (root password) to restart a crashed IOC at 11 PM?

**No.** We specifically designed the architecture to avoid this bottleneck.

Engineers in the `ioc` UNIX group are granted targeted, passwordless sudo privileges via `/etc/sudoers.d/10-epics-ioc`. This means any `ioc` group member can immediately run:

```bash
ioc-runner restart myioc
```

or equivalently:

```bash
sudo systemctl restart epics-@myioc.service
```

No root password is required, and no sysadmin needs to be contacted. The `sudo` command is still used under the hood — `ioc-runner` internally calls `sudo systemctl ...` for system-wide operations — but the sudoers policy grants `NOPASSWD` to the `ioc` group, so no password prompt ever appears. The key distinction is: **`sudo` (the command) is required, but `sudo` (the password) is not.** Additionally, the policy is scoped exclusively to EPICS IOC template instances (`epics-@<name>.service`, where `<name>` follows the runner IOC-name model), so engineers cannot accidentally affect unrelated system services.

---

### Q2: Our current database includes metadata like `gitRepo` and `groupName`. Can we include this information in the `.conf` files?

**Yes.** The `<ioc_name>.conf` files are loaded by `systemd` as standard `EnvironmentFile`s, and every `KEY="VALUE"` pair — not only the `IOC_*` keys the runner acts on — is exported into the procServ process environment and inherited by the IOC process itself (visible via `epicsEnvShow` or `/proc/<pid>/environ`). Metadata keys should use the `IOC_META_` prefix (a documentation contract — no code enforces the prefix): it keeps them clearly inert to the runner and avoids colliding with EPICS, vendor, or system environment variables that could change IOC behavior. Do not store secrets in the conf; anything in it becomes process environment. Example:

```bash
IOC_USER="ioc-srv"
IOC_GROUP="ioc"
IOC_CHDIR="/opt/epics-iocs/flux-capacitor/iocBoot/iocFluxCap"
IOC_PORT=""
IOC_CMD="./st.cmd"
IOC_META_GIT_REPO="https://github.com/jeonghanlee/flux-capacitor-ioc"
IOC_META_GROUP="time-travel"
IOC_META_CONTACT="jeonghan.lee@gmail.com"
```

This approach lets the `.conf` file serve as the single source of truth. Because the `IOC_META_` prefix is the documented convention for metadata, external tools (Python scripts, web dashboards, CI/CD pipelines) can parse these files directly — and IOC-side logic can read the same values from its environment — to generate or sync with legacy databases like `siocmgr`, following the DRY principle. Note that only the `IOC_*` operational keys and `CRASH_LOG_PATTERNS_EXTRA` are validated at install time; `IOC_META_*` values pass only the shell-syntax check.

---

### Q3: Is there a way to show all running IOCs on a specific host?

**Yes.** The `list` command provides three levels of detail:

```bash
# Basic: name, status, start time, socket path
ioc-runner list

# Verbose: adds PID, CPU time, memory usage
ioc-runner -v list

# Extended: adds Recv-Q, Send-Q, socket permissions
ioc-runner -vv list
```

Additionally, the registered IOC inventory (regardless of whether they are currently running) can be determined by listing the configuration directory:

```bash
ls /etc/procServ.d/*.conf
```

---

### Q4: How do we determine which IOC runs on which host across the entire facility?

For a single host, `ioc-runner list` provides the answer. For facility-wide visibility, the architecture integrates with higher-level tools:

**SSH loop (simple):**
```bash
for host in proton electron kaon photon up down strange bottom top muon neutrino tauon; do
    printf "=== %s ===\n" "${host}"
    ssh "${host}" ioc-runner list
done
```

**Conserver (`conserver.cf`)** *(in design)*: Will act as the global routing inventory. An engineer will simply type `console <ioc_name>` on the central server, and the connection will be automatically routed to the correct host without the engineer needing to know which server it runs on. See `system-wide/conserver/docs/ARCHITECTURE.md` for the current design.

**Cockpit Multi-host** *(in design)*: Will use Cockpit with a custom plugin to provide a single web-based dashboard that monitors all IOCs across 20+ servers simultaneously. See `system-wide/cockpit/docs/ARCHITECTURE.md` for the current design.

---

### Q5: Can an IOC be "disabled" temporarily and run manually for testing?

**Yes.** The architecture fully supports this workflow using standard systemd lifecycle commands:

```bash
# 1. Disable auto-start on boot
ioc-runner disable myioc

# 2. Stop the running service (procServ + IOC)
ioc-runner stop myioc

# 3. Run the IOC manually for debugging (see the history-file note below)
cd /opt/epics-iocs/flux-capacitor/iocBoot/iocFluxCap
export EPICS_IOCSH_HISTFILE=   # empty string disables the history file (EPICS docs)
./st.cmd

# 4. When debugging is complete, return to managed mode
ioc-runner start myioc
ioc-runner enable myioc
```

While the service is stopped, the `.conf` file remains in `/etc/procServ.d/` and the systemd template is unchanged. Only the runtime state is affected.

**History-file note:** iocsh saves `.iocsh_history` as `0600`, owned by whichever principal ran the IOC last. A plain manual run leaves an operator-owned file the next service run (as `ioc-srv`) cannot read, and in the reverse direction a service-owned file prints a benign `ERROR Permission denied ... loading '.iocsh_history'` on the manual console. Setting `EPICS_IOCSH_HISTFILE` to an empty string disables the history file for the manual run, so no cross-owned file is left behind. `IOCSH_HISTSIZE` only bounds the in-memory history list, and an `epicsEnvSet` inside `st.cmd` runs after history setup; neither prevents the file. EPICS documents the empty-string disable in the EPICS Base 7.0 release notes (https://docs.epics-controls.org/projects/base/en/r7.0.9/RELEASE_NOTES.html).

---

### Q6: What happens when an IOC crashes on boot or hangs trying to connect to hardware?

The architecture provides multiple layers of protection for these scenarios:

**Layer 1 — procServ (child process management):**
If the IOC process crashes (e.g., Segmentation fault, assertion failure), `procServ` does not die. It catches the child exit, logs the event, and automatically restarts the child process. The UNIX Domain Socket remains open throughout, so an engineer can attach to the console at any time to observe the crash-restart cycle in real time:

```bash
ioc-runner attach myioc
```

The attached console is hardened against accidents: `^C`, `^D`, and `^]` are filtered out of the IOC's input (`--ignore=^D^C^]`), and procServ's `^T` autorestart-toggle key is disabled (`--autorestartcmd=''`). A stray `^T` can therefore no longer leave a dead child under a live procServ with the socket still open — the child autorestart is always on and cannot be switched off from the console. To stop an IOC intentionally, use `ioc-runner stop` (see Q5 for the manual-debug workflow).

**Layer 2 — ioc-runner health checks (startup verification):**
When `ioc-runner start` (or `restart`) is executed, it polls the procServ log for the EPICS readiness marker (`All initialization complete`) instead of waiting a fixed interval. The verdict depends on what appears before, at, and after that marker:

1. **Before the marker (up to a 30-second readiness timeout):** a fatal-subset token — `FATAL`, `Segmentation fault`, `undefined symbol`, `error while loading`, `Unbalanced quote` — reports an immediate hard failure (`Error: IOC '<name>' failed to initialize (fatal error before iocInit).`, exit 1). A procServ death banner that recurs (the child dies and relaunches before initialization) reports a pre-iocInit crash loop (`Error: IOC '<name>' is crash-looping before reaching iocInit.`, exit 1). Ambiguous tokens — `ERROR`, `Can't open`, `cannot open`, `No such file or directory`, `Invalid directory path` — never fail on their own: a healthy IOC may print them (a missing optional file, a skipped path) and reach initialization a moment later.

2. **At the marker (confirmed over a short ~3-second dwell):** a procServ death banner emitted after the marker reports a crash loop (`Error: IOC '<name>' is crash-looping.`, exit 1) — the only standalone failure trigger in this phase. A crash pattern emitted while the IOC stays alive (for example a device-connection `ERROR`) is reported as a warning, not a failure:

   *"Warning: IOC is active but reported errors after initialization (check device connections)."*

3. **Readiness timeout (no marker within the window):** if the unit is still active, it reports that the IOC is active but did not report initialization complete (a warning, exit 0 — the case of a slow device connection or a gateway IOC); if the unit is not active, it reports a hard failure (exit 1). If the log cannot be read, it says the startup log could not be read rather than claiming a clean start.

A `start` on an IOC that is already running short-circuits to `IOC '<name>' is already running.` once a clean, marked startup is confirmed in the existing log. Known benign startup noise is removed line by line before crash matching (`CRASH_LOG_EXCLUDE_PATTERNS`): the iocsh history-file load/save failure (`ERROR Permission denied ... '.iocsh_history'`, see Q5) is never a crash indicator.

**Layer 3 — systemd (daemon lifecycle):**
`systemd` supervises the `procServ` process itself. If `procServ` dies for any reason — OOM kill, unrecoverable error, stray signal — `systemd` restarts it (`Restart=always`, `RestartSec=2`); the restart limiter is disabled (`StartLimitIntervalSec=0`), so the unit never strands in a `failed` state that would need manual `reset-failed`. `Restart=always` rather than `on-failure` is deliberate: the `SuccessExitStatus` directive classifies normal shutdown signals (SIGTERM, SIGKILL) as success so they are not falsely reported as failures, which means an OOM kill also counts as "success" and only `always` revives it. See `docs/EXIT_SIGNAL_HANDLING.md` and ADR 0001 (`docs/adr/0001-restart-supervision-c1h.md`) for the full rationale.

---

### Q7: How are the crash detection patterns configured?

The patterns used by the startup health check are defined as a global variable at the top of the `ioc-runner` script:

```bash
CRASH_LOG_PATTERNS="(error while loading|FATAL|Segmentation fault|ERROR|Unbalanced quote|Invalid directory path|Can't open|cannot open|undefined symbol|No such file or directory)"
```

This set is partitioned into two subsets (`CRASH_LOG_PATTERNS_FATAL` and `CRASH_LOG_PATTERNS_AMBIGUOUS`, whose union is the set above): fatal tokens are a standalone failure before the readiness marker, while ambiguous tokens never participate in a failure verdict at all — crash-loop failures are triggered by the procServ death banner alone. The only effect of an ambiguous token is the post-initialization warning on a still-alive IOC ("active but reported errors after initialization"). See Q6 for the full phase-by-phase behavior.

For hardware-specific or vendor-module error strings that should only apply to one IOC, set `CRASH_LOG_PATTERNS_EXTRA` in the IOC conf file. The runner appends this to the global pattern set at `start`/`restart` time without modifying the script. All pattern matching — the built-in set and `CRASH_LOG_PATTERNS_EXTRA` alike — is case-insensitive, so `Bergoz link lost` also matches `BERGOZ LINK LOST`; write tokens in their natural case and do not add case variants. These per-IOC tokens are corroborating only — they raise a warning on a still-alive IOC, never a standalone startup failure:

```bash
# In the IOC conf
CRASH_LOG_PATTERNS_EXTRA="Bergoz link lost|NPCT overrange|Keithley buffer full"
```

Allowed characters are alphanumerics, `_ . / : space - | ( ) \`. Install time is the strict gate: it rejects illegal characters, regex that does not compile, empty alternations (a leading, trailing, or doubled `|` would match every log line), and degenerate patterns that match ordinary log text (such as a bare `.`). The pattern is also re-read at every `start`/`restart`; if the conf was edited since install and the value no longer compiles, the runner warns and ignores it for that run — the built-in pattern set remains active, so one bad per-IOC key can never disable crash detection.

---

### Q8: Can I deploy IOCs from my home directory or a personal NFS mount?

**No, not in system mode.** `procServ` runs as the `ioc-srv` service account, and the IOC payload inherits `IOC_CHDIR` as its working directory. At runtime, the IOC writes `.iocsh_history`, autosave files, save/restore snapshots, and any site-specific artifacts created by `st.cmd` to this directory. If the directory is not writable by `ioc-srv`, these writes fail silently.

Personal home directories (`/home/<user>`) and NFS mounts without `ioc` group access do not grant `ioc-srv` write permission. The `.iocsh_history` failure still emits `ERROR` lines into the procServ log file, but they are benign noise excluded from the crash scan (Q6), so the start warning does not surface this misconfiguration; the install-time `IOC_CHDIR` permission check described below is the dedicated guard.

The correct location is `/opt/epics-iocs/` (or any tree owned `root:ioc` with mode `2775`, or equivalent setgid + group write/execute, so `ioc-srv` writes via `ioc` group membership; see `INSTALL.md` Section 4).

**Detection:** During `install`, the runner checks that `IOC_CHDIR` conforms to the permission model: an absolute, non-symlinked directory group-owned by `ioc` with setgid plus group write and execute (mode `2775`, or equivalent permissions), and every parent traversable by `ioc-srv`. It reads file metadata directly (no `sudo`), so it gives the same result for `root` and for an `ioc`-group operator. A quick leaf check:

```bash
stat -c '%G %a' "${IOC_CHDIR}"
```

Expect group `ioc` and mode `2775`. This checks the leaf only; a non-absolute `IOC_CHDIR` is rejected outright at validation time (hard error, `--force` does not bypass it; M6/#109), and the install-time check further validates the non-symlinked leaf and parent traversal. If the directory does not conform to the group/mode model, a warning is emitted and confirmation is required before proceeding. Use `-f` (or `--force`) to suppress the prompt in CI/CD contexts, though the underlying condition remains. One case is excluded from this warning flow: an `IOC_CHDIR` containing a `..` path component is malformed input, not a permission mismatch — `install` rejects it outright with a hard error, no confirmation prompt, and `--force` does not bypass it.

**Partial mitigation:** Setting `EPICS_IOCSH_HISTFILE` to an empty string disables the history file and so removes the error (see Q5); `IOCSH_HISTSIZE` does not (it only bounds the in-memory history list, and an `epicsEnvSet` inside `st.cmd` runs after history setup). Autosave and save/restore write failures remain, and will surface later when those modules attempt to persist state.

**Local mode:** `--local` deployments run as the invoking user, so this constraint does not apply.


### Q9: Can we read system logs for IOCs running in system-wide mode?

IOC console output is written to the dedicated procServ log file (`/var/log/procserv/<name>.log`, mode `0644`), so reading it needs no `systemd-journal` membership — `ioc` group membership gates privileged IOC management, not log reads. The systemd journal is only an optional service-metadata diagnostic: reading it with `journalctl -u epics-@myioc.service` still requires the `adm` or `systemd-journal` group and returns empty without it.

`ioc-runner`'s startup crash detection reads the procServ log file (it polls that file for the readiness marker and for crash indicators), so crash detection does not require journal group membership. If the procServ log file cannot be read, the runner reports that the startup log could not be read instead of claiming a clean start. The `systemctl is-active` check used at the readiness timeout is unaffected.

For local mode (`--local`), `journalctl --user` works during an active login session by default. Linger (`loginctl enable-linger <user>`) and a persistent `/var/log/journal/<machine-id>` make the user journal durable across logout. The lifecycle test (`tests/test-local-lifecycle.bash`) detects an empty or inactive journal and SKIPs STEP 24 monitor-isolation coverage with a WARN.

---

### Q10: What happens to my `attach` or `monitor` session when a colleague stops or removes the IOC?

The session ends immediately and cleanly. When another operator runs `stop` or `remove` on the IOC whose console you are holding, your console client receives EOF and exits as soon as the service goes down; the socket directory (`/run/procserv/<name>/`) is removed together with the unit, so no stale socket or hung session remains. Nothing needs to be cleaned up on your side — reconnect with `ioc-runner attach <name>` after the IOC is started again. (Verified on both reference platforms in the multi-user test plan, scenario S4.)

If `remove` itself cannot stop the service, it aborts BEFORE deleting anything: the configuration stays in place, the runner reports `Error: Removal aborted. Service '<name>' did not stop (State: ...)` together with systemctl's own stderr, and the recovery is to check your sudo permissions and the unit state (`systemctl status epics-@<name>.service`), then re-run `remove`. Since 1.2.1 the removal outcome is verified rather than assumed — a `remove` that prints success has really deleted the configuration.

---

### Q11: `attach` says "Configuration for `<name>` not found" but the IOC is clearly running. Why?

This is almost always a permission gate, not a missing configuration. Resolving a console target reads the IOC's `.conf` in `/etc/procServ.d/`, and that directory is `2770 root:ioc` — a user outside the `ioc` group cannot read it, so the lookup reports the configuration as not found before any socket access is attempted. The console socket sits behind a second gate: its directory (`/run/procserv/<name>/`, `0770 ioc-srv:ioc`) is not traversable outside the `ioc` group, and the socket file itself is `0660 ioc-srv:ioc`. Ask to be added to the `ioc` group if your role requires console access; read-only observation of service state works without it via `ioc-runner status <name>` or `systemctl status epics-@<name>.service`. The same boundary makes `ioc-runner list` show no sockets for non-`ioc` users (see the principal model in `PERMISSION_MODEL.md` and `testplan_multiuser.md` scenarios S6/S10).
