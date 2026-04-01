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

No root password is required, and no sysadmin needs to be contacted. The `sudo` command is still used under the hood — `ioc-runner` internally calls `sudo systemctl ...` for system-wide operations — but the sudoers policy grants `NOPASSWD` to the `ioc` group, so no password prompt ever appears. The key distinction is: **`sudo` (the command) is required, but `sudo` (the password) is not.** Additionally, the policy is scoped exclusively to `epics-@*.service` units, so engineers cannot accidentally affect unrelated system services.

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
# Basic: name, status, connections, start time, socket path
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

1. **Primary check:** After a 2-second settling period (to account for hardware connection timeouts), it verifies `systemctl is-active`. If the service has already failed, an error is reported immediately with a `journalctl` command for troubleshooting.

2. **Secondary check:** If the service appears active, it scans the recent system journal for crash-loop indicators including `Restarting child`, `FATAL`, `Segmentation fault`, and `Connection timed out`. If any pattern matches, it warns the engineer:

   *"Warning: IOC is active, but procServ may be crash-looping or reporting fatal errors."*

**Layer 3 — systemd (daemon lifecycle):**
`systemd` manages the `procServ` process itself. If `procServ` is killed by the OOM killer or encounters an unrecoverable error, `systemd` handles the cleanup. The `SuccessExitStatus` directive ensures that normal shutdown signals (SIGTERM, SIGKILL) are not falsely reported as failures. See `docs/EXIT_SIGNAL_HANDLING.md` for the full technical explanation.

---

### Q7: How are the crash detection patterns configured?

The patterns used by the secondary health check are defined as a global variable at the top of the `ioc-runner` script:

```bash
CRASH_LOG_PATTERNS="(Restarting child|error while loading|Connection timed out|FATAL|Segmentation fault)"
```

Site operators can extend this pattern with additional strings specific to their hardware or EPICS modules (separated by `|`) without modifying any internal logic.

---

### Q8: Can we read system logs for IOCs running in system-wide mode?

Reading system journal logs for `ioc-srv` services requires membership in the `adm` or `systemd-journal` group. Without this, commands like `journalctl -u epics-@myioc.service` may return empty results.

`ioc-runner` handles this gracefully: if journal access is unavailable, the secondary crash-loop check silently skips without producing false results. The primary health check (`systemctl is-active`) always works regardless of journal permissions.

For local mode (`--local`), journal access is always available since the user owns their own session logs.
