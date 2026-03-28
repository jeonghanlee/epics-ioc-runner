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

**Step 2: Create the Configuration File**
Generate the `.conf` file directly inside the target boot directory. 
*Note: You can leave `IOC_PORT` empty. The `ioc-runner` will automatically generate the standard secure UNIX Domain Socket path for the system.*

```bash
cat <<EOF > myioc.conf
IOC_USER="ioc-srv"
IOC_GROUP="ioc"
IOC_CHDIR="$(pwd)"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF
```

*Important: Ensure your `IOC_CMD` (e.g., `st.cmd`) has execute permissions (`chmod +x st.cmd`), otherwise the installation will be strictly rejected.*

**Step 3: Install the Configuration**
Deploy the configuration to the system manager.
```bash
ioc-runner install myioc.conf
```

**Step 4: Start the Service**
Start the IOC process.
```bash
ioc-runner start myioc
```

## 2. Attaching to the IOC Console
To interact with the IOC shell, connect to the UNIX Domain Socket.

```bash
ioc-runner attach myioc
```
* **To exit the console session**: Press `Ctrl-A`.
* *Note: Do not use `Ctrl-C` or `Ctrl-D` as it may terminate the IOC depending on the shell settings.*

## 3. Daily Operations (Systemd Native Commands)
Because the IOCs are managed by `systemd` templates, you can use native `systemctl` commands without a password.

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
All standard output (stdout/stderr) from the IOC is automatically captured by the system journal.

**Watch logs in real-time:**
```bash
journalctl -u epics-@myioc.service -f
```

**View logs from the last 1 hour:**
```bash
journalctl -u epics-@myioc.service --since "1 hour ago"
```

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


## 8. Version Tracking
To verify the exact version, Git commit hash, and build timestamp of the deployment tool you are using:

```bash
ioc-runner -V
```
