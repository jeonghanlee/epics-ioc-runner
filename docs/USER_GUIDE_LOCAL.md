# EPICS IOC Local Execution Guide

This guide describes how to run and test EPICS IOCs in an isolated, user-level systemd environment without requiring root or sudo privileges.

## Prerequisites
Ensure that the core utilities **`procServ`** and **`con`** are available. In local mode the runner searches `~/.local/bin`, then `/usr/local/bin`, then `/usr/bin`, or honors an explicit path in `IOC_RUNNER_PROCSERV_TOOL` / `IOC_RUNNER_CON_TOOL` (full resolution order in the environment-variable section below). You can build and install them from the following repositories:
* **con**: https://github.com/jeonghanlee/con
* **procServ**: https://github.com/jeonghanlee/procServ-env

If they are not installed, please refer to the [System Installation Guide](INSTALL.md) or contact your system administrator before proceeding.

## 1. Preparation: Clone the Repository
Create a local workspace and clone the target IOC repository. Navigate to the specific IOC boot directory.

```bash
mkdir -p ~/gitsrc
cd ~/gitsrc
git clone https://your_git_url/tcmd.git
cd tcmd/iocBoot/iocctrlslab-tcmd/
```

> **Tip:** To call `ioc-runner` directly instead of the full `~/epics-ioc-runner/bin/ioc-runner` path, run `make install.user` from the `epics-ioc-runner` checkout. It deploys the CLI and Bash completion under `~/.local/bin` with no root. Ensure `~/.local/bin` is on your `PATH`.

## 2. Create the Configuration File
Prepare the configuration file for the local isolated environment.

* **Option A: Automated Generation (Recommended)**
  Automatically maps `IOC_USER` and `IOC_GROUP` to the current local session.
  ```bash
  ~/epics-ioc-runner/bin/ioc-runner generate --local .
  ```

* **Option B: Manual Creation**
  Ensure the user and group variables match your current local session ID.
  ```bash
  cat <<EOF > iocctrlslab-tcmd.conf
  IOC_USER="$(id -un)"
  IOC_GROUP="$(id -gn)"
  IOC_CHDIR="$(pwd)"
  IOC_PORT=""
  IOC_CMD="./st.cmd"
  EOF
  ```

## 3. Install the Configuration (Local Mode)
Deploy the configuration to the user-level systemd directory. The wrapper automatically generates the local `epics-@.service` template if missing.

```bash
# For explicitly named files:
~/epics-ioc-runner/bin/ioc-runner --local install iocctrlslab-tcmd.conf

# For auto-generated configurations in the current directory:
~/epics-ioc-runner/bin/ioc-runner --local install .
```

### CI/CD and Automated Deployments
If deploying via configuration management tools, bypass interactive overwrite prompts using the `-f` flag:
```bash
~/epics-ioc-runner/bin/ioc-runner -f generate --local .
~/epics-ioc-runner/bin/ioc-runner -f install --local .
```


## 4. View the Service Configuration
To verify that the unit file template is correctly loaded for your IOC, you can view its contents.

```bash
~/epics-ioc-runner/bin/ioc-runner --local view iocctrlslab-tcmd
```

## 5. Start the IOC
Once the configuration is installed, start the IOC process explicitly.

```bash
~/epics-ioc-runner/bin/ioc-runner --local start iocctrlslab-tcmd
```

## 6. Enable Auto-Start on Boot (Persistence)
By default, the `install` command deploys the configuration but does not enable it for auto-start. To ensure the IOC starts automatically after a system reboot, use the `enable` command.

```bash
# Enable the service to start on boot
~/epics-ioc-runner/bin/ioc-runner --local enable iocctrlslab-tcmd

# Disable the service from starting on boot
~/epics-ioc-runner/bin/ioc-runner --local disable iocctrlslab-tcmd
```
> **Note:** For user-level services (`--local`), the user session must be active or "lingering" for the service to start on boot. You can enable lingering with: `loginctl enable-linger $(id -un)`

## 7. Verify Service Status
Check if the IOC process has been successfully started by the user's systemd manager.

```bash
systemctl --user status epics-@iocctrlslab-tcmd.service
```

## 8. List Managed IOCs
You can view the active UNIX Domain Sockets for all locally managed IOCs using the `list` command.

```bash
~/epics-ioc-runner/bin/ioc-runner --local list
```

## 9. Attach to the IOC Console
Connect to the UNIX Domain Socket (UDS) to interact with the EPICS shell.

```bash
~/epics-ioc-runner/bin/ioc-runner --local attach iocctrlslab-tcmd
```
* **Press Enter** to display the `epics>` prompt if the screen is blank.
* **Press Ctrl-A** to safely detach from the console while leaving the IOC running in the background.

## 10. Service Control and Cleanup (Systemd Operations)
The wrapper script acts as a frontend for `systemctl`. It fully supports standard systemd service lifecycle commands.

```bash
# Stop the local IOC service
~/epics-ioc-runner/bin/ioc-runner --local stop iocctrlslab-tcmd

# Restart the local IOC service
~/epics-ioc-runner/bin/ioc-runner --local restart iocctrlslab-tcmd
```

When the local testing is completely finished and you want to clean up the environment, use the `remove` command. This will stop the service and remove the configuration file from the local directory.

```bash
~/epics-ioc-runner/bin/ioc-runner --local remove iocctrlslab-tcmd
```

## 11. Direct systemd Control (Alternative)
Since the architecture relies on standard systemd templates, you can also use native `systemctl` commands directly. Just remember to use the `--user` flag and the `epics-@` prefix for the service name.

```bash
# Start, stop, or restart the service directly
systemctl --user start epics-@iocctrlslab-tcmd.service
systemctl --user stop epics-@iocctrlslab-tcmd.service
systemctl --user restart epics-@iocctrlslab-tcmd.service

# Check the detailed status
systemctl --user status epics-@iocctrlslab-tcmd.service

# View live IOC console output
tail -f ~/.local/state/procserv/iocctrlslab-tcmd.log

# View user service-manager diagnostics if needed
journalctl --user -u epics-@iocctrlslab-tcmd.service
```

Log growth in this directory is bounded by the per-user rotation deployed at `--local install`; see section 15.

## 12. Direct Console Access (Alternative)
While the `attach` command automatically resolves the socket path, you can also connect to the UNIX Domain Socket directly using the `con` utility.

First, find the exact UDS path for your active IOCs using the `list` command:
```bash
~/epics-ioc-runner/bin/ioc-runner --local list
```

The output will display the full path, which typically follows this pattern for local user sessions:
`/run/user/$(id -u)/procserv/<ioc_name>/control`

You can then connect directly using `con`:
```bash
con -c /run/user/$(id -u)/procserv/iocctrlslab-tcmd/control
```
* **To exit the console session**: Press `Ctrl-A`.


## 13. Version Tracking
To verify the version of the local runner script, including the live Git hash if executing directly from a cloned repository:

```bash
~/epics-ioc-runner/bin/ioc-runner -V
```

Example output when running directly from a clone (no `setup-system-infra.bash` install step; values shown as placeholders):

```text
epics-ioc-runner version X.Y.Z (<hash> (live))
commit date:  <commit date>
install date: live
```

`install date: live` indicates the script is being executed straight from the working tree rather than from an installed deployment, so the install timestamp is not pinned.


## 14. Advanced: Environment Variable Overrides

For isolated testing, CI pipelines, or multi-tenant workstations, the runner supports environment variable overrides that redirect the configuration, systemd, and runtime directories without touching the installed script.

### Namespaced variables (per execution mode)

| Variable | Default | Affects |
|---|---|---|
| `IOC_RUNNER_LOCAL_CONF_DIR`    | `${HOME}/.config/procServ.d`     | `--local` conf storage |
| `IOC_RUNNER_LOCAL_SYSTEMD_DIR` | `${HOME}/.config/systemd/user`   | `--local` unit template |
| `IOC_RUNNER_LOCAL_RUN_DIR`     | `/run/user/$(id -u)/procserv`   | `--local` socket path in `IOC_PORT` |
| `IOC_RUNNER_LOCAL_LOG_DIR`     | `${XDG_STATE_HOME:-${HOME}/.local/state}/procserv` | `--local` procServ log directory (baked into the unit `--logfile` at install; also the crash-scan path) |
| `IOC_RUNNER_SYSTEM_CONF_DIR`    | `/etc/procServ.d`              | system-mode conf storage |
| `IOC_RUNNER_SYSTEM_SYSTEMD_DIR` | `/etc/systemd/system`          | system-mode unit template |
| `IOC_RUNNER_SYSTEM_RUN_DIR`     | `/run/procserv`                | system-mode socket path in `IOC_PORT` |
| `IOC_RUNNER_SYSTEM_LOG_DIR`     | `/var/log/procserv`            | system-mode procServ log directory |

### Unified runtime overrides (take precedence over both)

| Variable | Behavior |
|---|---|
| `IOC_RUNNER_CONF_DIR`    | Overrides both `LOCAL_CONF_DIR` and `SYSTEM_CONF_DIR` |
| `IOC_RUNNER_SYSTEMD_DIR` | Overrides both `LOCAL_SYSTEMD_DIR` and `SYSTEM_SYSTEMD_DIR` |
| `IOC_RUNNER_RUN_DIR`     | Overrides both `LOCAL_RUN_DIR` and `SYSTEM_RUN_DIR` |
| `IOC_RUNNER_LOG_DIR`     | Overrides both `LOCAL_LOG_DIR` and `SYSTEM_LOG_DIR` |
| `IOC_RUNNER_CON_TOOL`    | Absolute path to a custom `con`-compatible binary |
| `IOC_RUNNER_PROCSERV_TOOL` | Absolute path to a custom `procServ` binary (local-mode template generation) |

Resolution order (highest wins): `IOC_RUNNER_<VAR>` > `IOC_RUNNER_{LOCAL,SYSTEM}_<VAR>` > built-in default. When `IOC_RUNNER_CON_TOOL` / `IOC_RUNNER_PROCSERV_TOOL` are unset, the tool is searched in `~/.local/bin`, then `/usr/local/bin`, then `/usr/bin` (the `~/.local/bin` entry is skipped when HOME cannot be resolved to a real home).

### System-mode setup override (`bin/setup-system-infra.bash`)

System-mode setup reads a separate variable, `IOC_RUNNER_PROCSERV_PATH`, distinct from the runner's `IOC_RUNNER_PROCSERV_TOOL`. It applies only while `bin/setup-system-infra.bash` generates the system template: system-mode setup uses this path as the procServ executable embedded in the system template's `ExecStart`. It takes a single path and replaces the default search list (`/usr/local/bin/procServ`, then `/usr/bin/procServ`) rather than prepending to it.

| Variable | Default | Affects |
|---|---|---|
| `IOC_RUNNER_PROCSERV_PATH` | `/usr/local/bin/procServ`, then `/usr/bin/procServ` | system-mode setup: procServ executable in the generated template `ExecStart` |

### Example: sandboxed local run

```bash
export IOC_RUNNER_LOCAL_CONF_DIR="/tmp/sandbox/conf"
export IOC_RUNNER_LOCAL_SYSTEMD_DIR="/tmp/sandbox/systemd"

~/epics-ioc-runner/bin/ioc-runner --local generate .
~/epics-ioc-runner/bin/ioc-runner --local install .
```

**Caveat: the system-mode runtime directory is fixed**

The deployed systemd template hardcodes `RuntimeDirectory=procserv/%i` (resolving to `/run/procserv/%i`). In system mode, moving the runtime directory off `/run/procserv` via `IOC_RUNNER_RUN_DIR` or `IOC_RUNNER_SYSTEM_RUN_DIR` would split the `IOC_PORT` socket path from where the kernel creates the UDS, so the runner now rejects it with a hard error. Use these overrides only in `--local` mode or for test scaffolding.

**Drift warnings: install-time values are baked**

The local unit and conf bake paths at install time, so changing an override afterwards silently splits the writer from the reader. The runner detects this at `start`/`restart` and warns instead of guessing:

- If the resolved log directory no longer matches the one baked into the installed unit, it prints `Warning: LOG_DIR resolves to ... but the installed user unit logs to ... (baked at install).` — the startup poll would watch the wrong file; export the install-time value or re-run `install`.
- If the installed `IOC_PORT` socket path no longer matches the current `RUN_DIR` resolution, it prints `Warning: the installed IOC_PORT socket (...) does not match the current RUN_DIR resolution (...).` — `attach`/`list` would look in the wrong place; re-run `install` after changing `IOC_RUNNER_LOCAL_RUN_DIR` / `IOC_RUNNER_RUN_DIR`.
- Independently of any divergence, local mode reminds you at conf parse time whenever `IOC_RUNNER_LOG_DIR` / `IOC_RUNNER_LOCAL_LOG_DIR` is set at all that the value is baked into the user unit's `--logfile` at install time — export the same value when you start or restart the IOC.

Treat either warning as "install and runtime disagree": re-export the install-time environment or re-run `ioc-runner --local install` before relying on `start` verdicts, `attach`, or `list`.

## 15. Local Log Rotation

`--local install` also deploys best-effort per-user log rotation, because a crash-looping user IOC under `Restart=always` would otherwise grow its log without bound:

- **Objects**: `~/.config/ioc-runner/logrotate.conf`, plus `epics-logrotate.service` (oneshot) and `epics-logrotate.timer` in the user systemd directory. One timer rotates every `*.log` in the local log directory.
- **Policy**: rotate weekly, or as soon as a log exceeds 50 MB (`maxsize 50M`); keep 8 compressed rotations; `copytruncate` so procServ keeps writing to the same open file during rotation.
- **Schedule**: the timer fires hourly (`OnCalendar=hourly`, `Persistent=true`, randomized by up to 5 minutes) and each tick evaluates the weekly/size policy.
- **Best effort**: a missing `logrotate` binary, an invalid generated config, or an unreachable user bus prints a warning and skips rotation — the IOC install itself always succeeds. Re-run `ioc-runner --local install` after fixing the cause.
- **Generated files**: Do not hand-edit `~/.config/ioc-runner/logrotate.conf` or the `epics-logrotate.*` units: every `ioc-runner --local install` re-renders them and replaces any file whose content differs, so local edits are not preserved. Site-specific rotation policy belongs in a separate operator-owned logrotate config, not in these generated files.
- **Never auto-removed**: `remove` deletes only the IOC; the rotation config and units stay until you remove them yourself (`systemctl --user disable --now epics-logrotate.timer`, then delete the three files).
- **Monitoring**: `ioc-runner --local list` warns when the timer is installed but inactive. Like the IOC units, the timer only fires while your user manager is running — enable lingering (`loginctl enable-linger $(id -un)`) on headless hosts.
