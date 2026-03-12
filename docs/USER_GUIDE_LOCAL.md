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
Create a `.conf` file for your IOC. Use absolute paths or reliable command outputs (`pwd`, `id`) to ensure the configuration is portable.

```bash
cat <<EOF > iocctrlslab-tcmd.conf
IOC_NAME="iocctrlslab-tcmd"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="$(pwd)"
IOC_PORT="unix:$(id -un):$(id -gn):0660:/run/user/$(id -u)/procserv/iocctrlslab-tcmd/control"
IOC_CMD="./st.cmd"
EOF
```

## 3. Install the Configuration (Local Mode)
Use the `--local` flag with the `install` command. This will copy the configuration to `~/.config/procServ.d/` and dynamically generate the user-level systemd template (`epics-@.service`) if it does not exist.

```bash
~/epics-ioc-runner/bin/manage-process.bash --local install iocctrlslab-tcmd.conf
```

## 4. View the Service Configuration
To verify that the unit file template is correctly loaded for your IOC, you can view its contents.

```bash
~/epics-ioc-runner/bin/manage-process.bash --local view iocctrlslab-tcmd
```

## 5. Start the IOC
Once the configuration is installed, start the IOC process explicitly.

```bash
~/epics-ioc-runner/bin/manage-process.bash --local start iocctrlslab-tcmd
```

## 6. Enable Auto-Start on Boot (Persistence)
By default, the `install` command deploys the configuration but does not enable it for auto-start. To ensure the IOC starts automatically after a system reboot, use the `enable` command.

```bash
# Enable the service to start on boot
~/epics-ioc-runner/bin/manage-process.bash --local enable iocctrlslab-tcmd

# Disable the service from starting on boot
~/epics-ioc-runner/bin/manage-process.bash --local disable iocctrlslab-tcmd
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
~/epics-ioc-runner/bin/manage-process.bash --local list
```

## 9. Attach to the IOC Console
Connect to the UNIX Domain Socket (UDS) to interact with the EPICS shell.

```bash
~/epics-ioc-runner/bin/manage-process.bash --local attach iocctrlslab-tcmd
```
* **Press Enter** to display the `epics>` prompt if the screen is blank.
* **Press Ctrl-A** to safely detach from the console while leaving the IOC running in the background.

## 10. Service Control and Cleanup (Systemd Operations)
The wrapper script acts as a frontend for `systemctl`. It fully supports standard systemd service lifecycle commands.

```bash
# Stop the local IOC service
~/epics-ioc-runner/bin/manage-process.bash --local stop iocctrlslab-tcmd

# Restart the local IOC service
~/epics-ioc-runner/bin/manage-process.bash --local restart iocctrlslab-tcmd
```

When the local testing is completely finished and you want to clean up the environment, use the `remove` command. This will stop the service and remove the configuration file from the local directory.

```bash
~/epics-ioc-runner/bin/manage-process.bash --local remove iocctrlslab-tcmd
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
~/epics-ioc-runner/bin/manage-process.bash --local list
```

The output will display the full path, which typically follows this pattern for local user sessions:
`/run/user/$(id -u)/procserv/<ioc_name>/control`

You can then connect directly using `con`:
```bash
con -c /run/user/1000/procserv/iocctrlslab-tcmd/control
```
* **To exit the console session**: Press `Ctrl-A`.

