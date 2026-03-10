# EPICS IOC Runner - Operations User Guide

This guide provides instructions for trained engineers on how to deploy, monitor, and manage EPICS IOCs using the `manage-procs` utility and native `systemd` commands.

## 1. Adding a New IOC
To deploy a new IOC, use the `manage-procs add` command. This creates the configuration file and automatically starts the IOC as a background service.

**Syntax:**
```bash
manage-procs add <ioc_name> -C <working_directory> -c <command> [args...]
```

**Example:**
```bash
manage-procs add myioc -C /opt/epics/ioc/myioc -c /opt/epics/ioc/myioc/st.cmd
```
*Note: The command automatically assigns the UNIX Domain Socket, sets the user/group to `ioc-srv:ioc`, and starts the service.*

## 2. Attaching to the IOC Console
To interact with the IOC shell, use the `attach` command. This invokes the `con` utility to securely connect to the UNIX Domain Socket.

```bash
manage-procs attach myioc
```
* **To exit the console session**: Press `Ctrl-A`.
* *Do not use `Ctrl-C` or `Ctrl-D` as it may terminate the IOC depending on the shell settings.*

## 3. Daily Operations (Systemd Native Commands)
Because the IOCs are managed by `systemd`, you can use native `systemctl` commands. Thanks to the sudoers policy, members of the `ioc` group do not need to enter a password for these commands.

**Check IOC Status:**
```bash
sudo systemctl status procserv-myioc.service
```

**Restart the IOC:**
```bash
sudo systemctl restart procserv-myioc.service
```

**Stop the IOC temporarily:**
```bash
sudo systemctl stop procserv-myioc.service
```

## 4. Viewing IOC Logs
All standard output (stdout/stderr) from the IOC is automatically captured by the system journal. You can view and filter these logs using `journalctl`.

**Watch logs in real-time (like tail -f):**
```bash
journalctl -u procserv-myioc.service -f
```

**View logs from the last 1 hour:**
```bash
journalctl -u procserv-myioc.service --since "1 hour ago"
```

## 5. Removing an IOC
To permanently stop and remove an IOC from the system, use the `remove` command. This will stop the service, delete the configuration file, and reload the systemd daemon.

```bash
manage-procs remove myioc
```
