# EPICS IOC Runner - Operations User Guide

This guide provides instructions for trained engineers on how to deploy, monitor, and manage EPICS IOCs system-wide using the `manage-procs` utility and native `systemd` commands.

## 1. Adding a New IOC
To deploy a new IOC to the system, you must first create a configuration file (`.conf`) and then install it using `manage-procs`.

**1. Create the Configuration File (`myioc.conf`):**
```bash
cat <<EOF > myioc.conf
IOC_NAME="myioc"
IOC_CHDIR="/opt/epics-iocs/myioc/iocBoot/iocmyioc"
IOC_PORT="unix:ioc-srv:ioc:0660:/run/procserv/myioc/control"
IOC_CMD="./st.cmd"
EOF
```

**2. Install the Configuration:**
Deploy the configuration to the system. Since the target directory (`/etc/procServ.d/`) is writable by the `ioc` group, you do not need `sudo`.
```bash
manage-procs install myioc.conf
```

**3. Start the Service:**
```bash
manage-procs start myioc
```

## 2. Attaching to the IOC Console
To interact with the IOC shell, use the `attach` command. This invokes the `con` utility to securely connect to the UNIX Domain Socket.

```bash
manage-procs attach myioc
```
* **To exit the console session**: Press `Ctrl-A`.
* *Do not use `Ctrl-C` or `Ctrl-D` as it may terminate the IOC depending on the shell settings.*

## 3. Daily Operations (Systemd Native Commands)
Because the IOCs are managed by `systemd` templates, you can use native `systemctl` commands. Thanks to the sudoers policy, members of the `ioc` group do not need to enter a password.

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

## 4. Viewing IOC Logs
All standard output (stdout/stderr) from the IOC is automatically captured by the system journal. You can view and filter these logs using `journalctl`.

**Watch logs in real-time (like tail -f):**
```bash
journalctl -u epics-@myioc.service -f
```

**View logs from the last 1 hour:**
```bash
journalctl -u epics-@myioc.service --since "1 hour ago"
```

## 5. Removing an IOC
To permanently stop and remove an IOC from the system, use the `remove` command. This will stop the service and delete the configuration file.

```bash
manage-procs remove myioc
```
