# EPICS IOC Runner - System Installation & Configuration Guide

This guide describes the initial server setup required to deploy the `epics-ioc-runner` architecture. It covers the installation of prerequisite utilities, creation of service accounts, directory permissions, systemd template deployment, and sudoers configuration.

## Prerequisites
* Root (sudo) access to the target server.
* Basic build tools installed (`gcc`, `g++`, `make`, `git`).
* Core utilities (`procServ` and `con`) compiled and installed system-wide.

---

## 1. Account and Group Setup
Create a dedicated service account and a management group. Only trained engineers should be added to the management group.

```bash
# Create the management group
groupadd ioc

# Create the service account with no login shell
useradd -r -g ioc -s /sbin/nologin ioc-srv

# Add authorized engineers to the management group
usermod -aG ioc userA
usermod -aG ioc userB
```

## 2. Shared Configuration Directory Setup
Create the directory where IOC configuration files will reside. This directory must be writable by the `ioc` group to allow engineers to deploy configurations without sudo.

```bash
mkdir -p /etc/procServ.d/
chown root:ioc /etc/procServ.d/
chmod 2775 /etc/procServ.d/
```

## 3. Sudoers Configuration
Allow members of the `ioc` group to manage `epics-*` systemd services without requiring a password.

Create the file `/etc/sudoers.d/10-epics-ioc`:
```bash
# /etc/sudoers.d/10-epics-ioc

# Allow trained engineers to manage ONLY EPICS-related services
%ioc ALL=(root) NOPASSWD: /bin/systemctl start epics-*, \
                          /bin/systemctl stop epics-*, \
                          /bin/systemctl restart epics-*, \
                          /bin/systemctl status epics-*, \
                          /bin/systemctl daemon-reload
```
Apply strict permissions to the sudoers file:
```bash
chmod 0440 /etc/sudoers.d/10-epics-ioc
```

## 4. Systemd Template Unit Deployment
Deploy the single systemd template unit (`@.service`) that will dynamically manage all IOC instances system-wide.

Create `/etc/systemd/system/epics-@.service`:
```ini
[Unit]
Description=procServ for %i
After=network.target remote-fs.target
AssertFileNotEmpty=/etc/procServ.d/%i.conf

[Service]
Type=simple
User=ioc-srv
Group=ioc
EnvironmentFile=/etc/procServ.d/%i.conf
RuntimeDirectory=procserv/%i
ExecStart=/usr/bin/procServ --foreground --logfile=- --name=%i --ignore=^D^C^] --chdir=${IOC_CHDIR} --port=${IOC_PORT} ${IOC_CMD}
StandardOutput=syslog
StandardError=inherit
SyslogIdentifier=epics-%i

[Install]
WantedBy=multi-user.target
```

Reload the systemd daemon to recognize the new template:
```bash
systemctl daemon-reload
```

## 5. CLI Wrapper Deployment
Deploy the frontend management script `manage-process.bash` to a standard binary path.

```bash
cp bin/manage-process.bash /usr/local/bin/manage-procs
chmod +x /usr/local/bin/manage-procs
```
