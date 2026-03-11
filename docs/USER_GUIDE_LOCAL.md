# EPICS IOC Local Execution Guide

This guide describes how to run and test EPICS IOCs in an isolated, user-level systemd environment without requiring root or sudo privileges.

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

## 3. Install and Start (Local Mode)
Use the `--local` flag with the `install` command. This will copy the configuration to `~/.config/procServ.d/`, trigger the user-level systemd generator, and start the service.

```bash
~/epics-ioc-runner/bin/manage-process.bash --local install iocctrlslab-tcmd.conf
```

## 4. Verify Service Status
Check if the IOC process has been successfully started by the user's systemd manager.

```bash
systemctl --user status epics-iocctrlslab-tcmd.service
```

## 5. List Managed IOCs
You can view the statuses of all locally managed IOCs at a glance using the `list` command.

```bash
~/epics-ioc-runner/bin/manage-process.bash --local list
```

## 6. Attach to the IOC Console
Connect to the UNIX Domain Socket (UDS) to interact with the EPICS shell.

```bash
~/epics-ioc-runner/bin/manage-process.bash --local attach iocctrlslab-tcmd
```
* **Press Enter** to display the `epics>` prompt if the screen is blank.
* **Press Ctrl-A** to safely detach from the console while leaving the IOC running in the background.

## 7. Service Control and Cleanup (Systemd Operations)
The wrapper script acts as a frontend for `systemctl`. It fully supports standard systemd service lifecycle commands, allowing you to easily manage the IOC.

```bash
# Stop the local IOC service
~/epics-ioc-runner/bin/manage-process.bash --local stop iocctrlslab-tcmd

# Start the local IOC service
~/epics-ioc-runner/bin/manage-process.bash --local start iocctrlslab-tcmd

# Restart the local IOC service
~/epics-ioc-runner/bin/manage-process.bash --local restart iocctrlslab-tcmd

# Check the status of the local IOC service
~/epics-ioc-runner/bin/manage-process.bash --local status iocctrlslab-tcmd
```

When the local testing is completely finished and you want to clean up the environment, use the `remove` command. This will stop the service, delete the generated user-level systemd unit, and remove the configuration file from the local test directory.

```bash
~/epics-ioc-runner/bin/manage-process.bash --local remove iocctrlslab-tcmd
```

## 8. Direct systemd Control (Alternative)
Since the wrapper script generates standard systemd unit files, you can also use native `systemctl` commands directly to manage your local IOCs. Just remember to use the `--user` flag and the `epics-` prefix for the service name.

```bash
# Start, stop, or restart the service directly
systemctl --user start epics-iocctrlslab-tcmd.service
systemctl --user stop epics-iocctrlslab-tcmd.service
systemctl --user restart epics-iocctrlslab-tcmd.service

# Check the detailed status
systemctl --user status epics-iocctrlslab-tcmd.service

# View the live logs directly from systemd journal
journalctl --user -u epics-iocctrlslab-tcmd.service -f
```
