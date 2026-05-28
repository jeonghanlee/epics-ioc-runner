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

**Yes, absolutely.** The `<ioc_name>.conf` files are sourced by `systemd` as standard `EnvironmentFile`s. Any `KEY="VALUE"` pair can be added freely. `systemd` and `procServ` simply ignore keys they do not recognize:

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

This approach lets the `.conf` file serve as the single source of truth. External tools (Python scripts, web dashboards, CI/CD pipelines) can parse these files directly to generate or sync with legacy databases like `siocmgr`, following the DRY principle.

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

# 3. Run the IOC manually for debugging
cd /opt/epics-iocs/flux-capacitor/iocBoot/iocFluxCap
./st.cmd

# 4. When debugging is complete, return to managed mode
ioc-runner start myioc
ioc-runner enable myioc
```

While the service is stopped, the `.conf` file remains in `/etc/procServ.d/` and the systemd template is unchanged. Only the runtime state is affected.

---

### Q6: What happens when an IOC crashes on boot or hangs trying to connect to hardware?

The architecture provides multiple layers of protection for these scenarios:

**Layer 1 — procServ (child process management):**
If the IOC process crashes (e.g., Segmentation fault, assertion failure), `procServ` does not die. It catches the child exit, logs the event, and automatically restarts the child process. The UNIX Domain Socket remains open throughout, so an engineer can attach to the console at any time to observe the crash-restart cycle in real time:

```bash
ioc-runner attach myioc
```

**Layer 2 — ioc-runner health checks (startup verification):**
When `ioc-runner start` is executed, it performs a two-stage health check:

1. **Primary check:** After a 5-second settling period (to account for hardware connection timeouts), it verifies `systemctl is-active`. If the service has already failed, an error is reported immediately with the procServ log file path for troubleshooting.

2. **Secondary check:** If the service appears active, it scans the new procServ log content from the current start or restart operation. If the log file cannot be read, it reports that startup logs could not be scanned rather than claiming a clean start. The case-insensitive crash indicators cover fatal process failures (`Segmentation fault`), generic fatal markers (`ERROR`, `FATAL`), iocsh parser failures (`Unbalanced quote`, `Invalid directory path`), and missing-file or linker errors (`Can't open`, `cannot open`, `undefined symbol`, `No such file or directory`, `error while loading`). If any pattern matches, it warns the engineer:

   *"Warning: IOC is active, but procServ may be crash-looping or reporting fatal errors."*

**Layer 3 — systemd (daemon lifecycle):**
`systemd` manages the `procServ` process itself. If `procServ` is killed by the OOM killer or encounters an unrecoverable error, `systemd` handles the cleanup. The `SuccessExitStatus` directive ensures that normal shutdown signals (SIGTERM, SIGKILL) are not falsely reported as failures. See `docs/EXIT_SIGNAL_HANDLING.md` for the full technical explanation.

---

### Q7: How are the crash detection patterns configured?

The patterns used by the secondary health check are defined as a global variable at the top of the `ioc-runner` script:

```bash
CRASH_LOG_PATTERNS="(error while loading|FATAL|Segmentation fault|ERROR|Unbalanced quote|Invalid directory path|Can't open|cannot open|undefined symbol|No such file or directory)"
```

For hardware-specific or vendor-module error strings that should only apply to one IOC, set `CRASH_LOG_PATTERNS_EXTRA` in the IOC conf file. The runner appends this to the global pattern set at `start`/`restart` time without modifying the script:

```bash
# In the IOC conf
CRASH_LOG_PATTERNS_EXTRA="Bergoz link lost|NPCT overrange|Keithley buffer full"
```

Allowed characters are alphanumerics, `_ . / : space - | ( ) \`. Invalid regex syntax is rejected at install time, not at runtime.

---

### Q8: Can I deploy IOCs from my home directory or a personal NFS mount?

**No, not in system mode.** `procServ` runs as the `ioc-srv` service account, and the IOC payload inherits `IOC_CHDIR` as its working directory. At runtime, the IOC writes `.iocsh_history`, autosave files, save/restore snapshots, and any site-specific artifacts created by `st.cmd` to this directory. If the directory is not writable by `ioc-srv`, these writes fail silently.

Personal home directories (`/home/<user>`) and NFS mounts without `ioc` group access do not grant `ioc-srv` write permission. The `.iocsh_history` failure emits `ERROR` lines into the procServ log file, which match the crash detection pattern (Q7) and cause `ioc-runner start` to report a crash-loop warning.

The correct location is `/opt/epics-iocs/` (or any tree owned `root:ioc` with mode `2775`, or equivalent setgid + group write/execute, so `ioc-srv` writes via `ioc` group membership; see `INSTALL.md` Section 4).

**Detection:** During `install`, the runner checks that `IOC_CHDIR` conforms to the permission model: an absolute, non-symlinked directory group-owned by `ioc` with setgid plus group write and execute (mode `2775`, or equivalent permissions), and every parent traversable by `ioc-srv`. It reads file metadata directly (no `sudo`), so it gives the same result for `root` and for an `ioc`-group operator. A quick leaf check:

```bash
stat -c '%G %a' "${IOC_CHDIR}"
```

Expect group `ioc` and mode `2775`. This checks the leaf only; the install-time check also validates the absolute path, the non-symlinked leaf, and parent traversal. If the directory does not conform, a warning is emitted and confirmation is required before proceeding. Use `-f` (or `--force`) to suppress the prompt in CI/CD contexts, though the underlying condition remains.

**Partial mitigation:** Adding `epicsEnvSet("IOCSH_HISTSIZE", "0")` to `st.cmd` suppresses only the history error. Autosave and save/restore write failures remain, and will surface later when those modules attempt to persist state.

**Local mode:** `--local` deployments run as the invoking user, so this constraint does not apply.


### Q9: Can we read system logs for IOCs running in system-wide mode?

IOC console output is written to the dedicated procServ log file (`/var/log/procserv/<name>.log`, mode `0644`), so reading it needs no `systemd-journal` membership — `ioc` group membership gates privileged IOC management, not log reads. The systemd journal is only an optional service-metadata diagnostic: reading it with `journalctl -u epics-@myioc.service` still requires the `adm` or `systemd-journal` group and returns empty without it.

`ioc-runner`'s secondary crash-loop detection reads the procServ log file, so crash detection does not require journal group membership. If the procServ log file cannot be read, the runner reports that startup logs could not be scanned instead of claiming a clean start. The primary health check (`systemctl is-active`) is unaffected.

For local mode (`--local`), `journalctl --user` works during an active login session by default. Linger (`loginctl enable-linger <user>`) and a persistent `/var/log/journal/<machine-id>` make the user journal durable across logout. The lifecycle test (`tests/test-local-lifecycle.bash`) detects an empty or inactive journal and SKIPs STEP 24 monitor-isolation coverage with a WARN.
