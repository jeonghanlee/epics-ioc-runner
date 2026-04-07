# EPICS IOC Local Execution Guide

This guide describes how to run and test EPICS IOCs in an isolated, user-level systemd environment without requiring root or sudo privileges.

## Prerequisites
Ensure that the core utilities **`procServ`** and **`con`** are installed on your system (`/usr/bin` or `/usr/local/bin`). You can build and install them from the following repositories:
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

# View the live logs directly from systemd journal
journalctl --user -u epics-@iocctrlslab-tcmd.service -f
```

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
