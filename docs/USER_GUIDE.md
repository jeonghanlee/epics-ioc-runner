# EPICS IOC Runner - Operations User Guide

This guide provides instructions for trained engineers on how to deploy, monitor, and manage EPICS IOCs system-wide using the `ioc-runner` utility.

It assumes the system administrator has already configured the shared deployment directory (`/opt/epics-iocs`) and that you are a member of the `ioc` group.

## 1. IOC Deployment Workflow
The standard procedure for deploying a new IOC involves cloning the repository into the shared directory, generating a `.conf` file, and installing it into the system manager.

**Step 1: Clone the IOC Repository**
Navigate to the shared deployment directory and clone your IOC repository.
```bash
cd /opt/epics-iocs
git clone https://your_git_url/myioc.git
cd myioc/iocBoot/iocmyioc
```

**Deployment Directory Requirement**

In system mode, the IOC process runs as `ioc-srv` and writes runtime artifacts (`.iocsh_history`, autosave files, save/restore snapshots) to its working directory. `IOC_CHDIR` must therefore be writable by `ioc-srv`.

The shared `/opt/epics-iocs` tree (`root:ioc`, mode `2775`, or equivalent setgid + group write/execute) satisfies this requirement automatically, since `ioc-srv` writes via `ioc` group membership. Personal home directories and NFS mounts without `ioc` group access do not, and will cause silent runtime failures under `procServ`.

During `install`, the runner checks that `IOC_CHDIR` is group-owned by `ioc` with setgid + group write/execute and is traversable by `ioc-srv`, reading file metadata directly (no `sudo`). If it does not conform, a warning is emitted and confirmation is required before proceeding.

**Step 2: Create the Configuration File**
Select either the automated generation tool or manual creation.

* **Option A: Automated Generation (Recommended)**
  Dynamically resolves absolute paths and generates the configuration based on the target `iocBoot` directory.
  ```bash
  ioc-runner generate .
  ```

* **Option B: Manual Creation**
  Manually define parameters. To use directory-based installation (`install .`), the filename must exactly match the directory name.
  ```bash
  cat <<EOF > iocmyioc.conf
  IOC_USER="ioc-srv"
  IOC_GROUP="ioc"
  IOC_CHDIR="$(pwd)"
  IOC_PORT=""
  IOC_CMD="./st.cmd"
  EOF
  ```
*Important: Ensure your `IOC_CMD` (e.g., `st.cmd`) has execute permissions (`chmod +x st.cmd`), otherwise the installation will be strictly rejected.*

### Configuration File Syntax

The runner accepts a bounded, single-line subset of systemd
`EnvironmentFile` syntax:

- Each assignment is `KEY=VALUE`. A key must be an environment identifier:
  ASCII letters or `_` first, followed by ASCII letters, digits, or `_`.
- Spaces and tabs around the line, key, `=`, and value are ignored. CRLF line
  endings are accepted.
- A value may be unquoted or enclosed by one matching pair of single or double
  quotes. The outer pair is removed after surrounding whitespace is trimmed;
  whitespace inside the quotes is preserved.
- A value may be empty and may contain additional `=` characters. The first
  `=` separates the key from the value.
- Inside a double-quoted value, `\\` produces one literal backslash. This is
  the supported form for regular-expression backslashes.
- Blank lines and lines whose first nonblank character is `#` are ignored.
- If a key appears more than once, the later assignment takes effect in both
  the runner and systemd.

For example, a regular-expression value that needs literal parentheses uses
two backslashes in the double-quoted configuration value:

```bash
CRASH_LOG_PATTERNS_EXTRA="Broken pipe|net_ex\\(status\\)"
```

Multiline quoted values, backslash continuations, unmatched or embedded quote
forms, unquoted or single-quoted backslashes, and double-quoted escapes other
than `\\` are rejected during `install`. A rejected file does not replace an
existing installed configuration. Use generated files or the simple forms
above rather than the wider systemd grammar. Every key must pass this syntax
check; operational `IOC_*` keys and `CRASH_LOG_PATTERNS_EXTRA` also receive
their field-specific validation.

**Step 3: Install the Configuration**
Deploy the configuration to the system manager. Pass the explicit filename or use the current directory (`.`) if generated automatically.
```bash
# For explicitly named files:
ioc-runner install myioc.conf

# For auto-generated configurations in the current directory:
ioc-runner install .
```

### CI/CD and Automated Deployments
If you are deploying IOCs via configuration management tools (e.g., Ansible) or CI/CD pipelines, the interactive overwrite prompt will halt the process. Use the `-f` (or `--force`) flag to force installation:

```bash
ioc-runner -f install myioc.conf
```

**Step 4: Start the Service**
Start the IOC process.
```bash
ioc-runner start myioc
```

`start` and `restart` verify the effective procServ log path before asking
systemd to change service state. A create, write, sync, or cleanup failure
blocks the transition. `sudo ioc-runner inspect myioc` reports the same
log-path condition as a warning and also checks whether the running procServ
executable still matches the effective unit.

## 2. Attaching to the IOC Console
To interact with the IOC shell, connect to the UNIX Domain Socket.

```bash
ioc-runner attach myioc
```
* **To exit the console session**: Press `Ctrl-A`.
* *Note: Do not use `Ctrl-C` or `Ctrl-D` as it may terminate the IOC depending on the shell settings.*

## 3. Daily Operations (Systemd Native Commands)
Because the IOCs are managed by `systemd` templates, you can use native `systemctl` commands without a password.

Direct `systemctl` lifecycle commands bypass `ioc-runner` preflight checks,
warnings, and readiness reporting. Use `ioc-runner start` and
`ioc-runner restart` for normal lifecycle operations; use direct `systemctl`
when that bypass is intentional.

**Check IOC Status:**
```bash
sudo systemctl status epics-@myioc.service
```

**Restart the IOC:**
```bash
sudo systemctl restart epics-@myioc.service
```

**Stop the IOC temporarily:**
```bash
sudo systemctl stop epics-@myioc.service
```

**Enable/Disable IOC auto-start on boot:**
```bash
sudo systemctl enable epics-@myioc.service
sudo systemctl disable epics-@myioc.service
```


## 4. Viewing IOC Logs
By default, procServ writes IOC standard output and standard error to a dedicated log file under `/var/log/procserv/`.

**Watch logs in real-time:**
```bash
tail -f /var/log/procserv/myioc.log
```

**View recent IOC output:**
```bash
tail -n 200 /var/log/procserv/myioc.log
```

Use `journalctl -u epics-@myioc.service` when you need systemd service-manager diagnostics rather than IOC console output.

**Log rotation:** `/var/log/procserv/*.log` is rotated weekly with 8-week retention via `/etc/logrotate.d/procserv` (deployed by `setup-system-infra.bash --full`). Rotated files are compressed as `myioc.log.1.gz`, `myioc.log.2.gz`, and so on; read them with `zcat` or `zless`. Rotation uses `copytruncate`, so the running IOC keeps writing to the same path without a restart.

## 5. Removing an IOC
To permanently stop and remove an IOC from the system:

```bash
ioc-runner remove myioc
```
*This command stops the service and removes the configuration file from `/etc/procServ.d/`. It leaves your cloned repository in `/opt/epics-iocs` untouched.*


## 6. List Managed IOCs
You can view the active UNIX Domain Sockets and statuses for all system-wide managed IOCs using the `list` command.

```bash
ioc-runner list
```
*(For detailed metrics including PID, CPU, and Memory, use `ioc-runner -v list`)*


## 7. Direct Console Access (Alternative)
While the `attach` command automatically resolves the socket path, you can also connect to the UNIX Domain Socket directly using the `con` utility.

First, find the exact UDS path for your active IOCs using the `list` command:
```bash
ioc-runner list
```

The output will display the full path, which typically follows this pattern for system-wide sessions:
`/run/procserv/<ioc_name>/control`

You can then connect directly using `con`:
```bash
con -c /run/procserv/myioc/control
```
* **To exit the console session**: Press `Ctrl-A`.


## 8. Container Mode (`--container`)

Inside a systemd-less container image prepared with
`setup-system-infra.bash --container` (see [`INSTALL.md`](INSTALL.md)), the
same commands run as root with `--container` instead of `sudo`; s6
supervises `procServ` and there is no `systemctl`.

```bash
ioc-runner --container generate /opt/epics-iocs/myioc
ioc-runner --container install  /opt/epics-iocs/myioc
ioc-runner --container start    myioc     # readiness: the control socket appears
ioc-runner --container status   myioc     # s6-svstat line, e.g. "up (pid 123) 42 seconds"
ioc-runner --container list -v
ioc-runner --container attach   myioc
ioc-runner --container stop     myioc
ioc-runner --container enable   myioc     # start at container boot (removes the s6 "down" file)
ioc-runner --container disable  myioc     # stay down at container boot; the running IOC is untouched
ioc-runner --container remove   myioc
```

IOC output goes to the container stdout (`docker logs <container>`); there
is no log file, log rotation, or `journalctl`. The runner requires a live
`s6-svscan` on `/run/s6-procserv`, which the container entrypoint starts as
PID 1, and refuses to run as a non-root user.

## 9. Version Tracking
To verify the exact version, Git commit hash, commit date, and install date of the deployment tool you are using:

```bash
ioc-runner -V
```

Example output (values shown as placeholders):

```text
epics-ioc-runner version X.Y.Z (<hash>)
commit date:  <commit date>
install date: <install date>
```

The commit date answers which revision is on this host; the install date answers how long the deployed artefact has been in place.
