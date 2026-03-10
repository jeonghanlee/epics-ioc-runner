# EPICS IOC Runner - System Installation & Configuration Guide

This guide describes the initial server setup required to deploy the `epics-ioc-runner` architecture. It covers the creation of service accounts, directory permissions, systemd generators, and sudoers configuration.

## Prerequisites
* Root (sudo) access to the target server.
* `procServ` installed on the system (`/usr/bin/procServ`).
* `con` utility compiled and placed in `/usr/local/bin/con`.

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

## 2. Shared Configuration Directory Setup (Local Storage Only)
Create the directory where IOC configuration files will reside. This directory must be writable by the `ioc` group.

> **⚠️ IMPORTANT (SRE Guideline):** Do **NOT** mount this directory via NFS. To prevent Systemd boot race conditions and avoid Single Points of Failure (SPOF), this directory must reside on the server's local disk.

```bash
sudo mkdir -p /etc/procServ.d/
sudo chown root:ioc /etc/procServ.d/
sudo chmod 2775 /etc/procServ.d/
```

## 3. Sudoers Configuration
Allow members of the `ioc` group to manage `procServ` related systemd services without requiring a password. We use `Cmnd_Alias` to ensure security (absolute paths) while maintaining compatibility across different Linux distributions.

Create the file `/etc/sudoers.d/10-epics-ioc`:
```bash
# /etc/sudoers.d/10-epics-ioc

# Define paths for systemctl to cover both Debian and RHEL/Rocky families
Cmnd_Alias SYSTEMCTL = /bin/systemctl, /usr/bin/systemctl

# Allow trained engineers to manage ONLY procServ-related services
%ioc ALL=(root) NOPASSWD: SYSTEMCTL start epics-*, \
                          SYSTEMCTL stop epics-*, \
                          SYSTEMCTL restart epics-*, \
                          SYSTEMCTL status epics-*, \
                          SYSTEMCTL daemon-reload
```
Apply strict permissions to the sudoers file:
```bash
chmod 0440 /etc/sudoers.d/10-ioc
```

## 4. Systemd Generator Deployment
Deploy the AWK-based systemd generator which translates `.conf` files into transient `.service` units.

Copy the generator script to the systemd generators directory:
```bash
cp src/epics-ioc-generator /usr/lib/systemd/system-generators/epics-ioc-generator
chmod +x /usr/lib/systemd/system-generators/epics-ioc-generator

# Trigger the generator
systemctl daemon-reload
```

## 5. CLI Wrapper Deployment
Deploy the frontend management script `manage-procs` to a standard binary path.

```bash
cp bin/manage-procs /usr/local/bin/manage-procs
chmod +x /usr/local/bin/manage-procs
```
