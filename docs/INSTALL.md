# EPICS IOC Runner - System Installation & Configuration Guide

This guide describes the initial server setup required to deploy the `epics-ioc-runner` architecture. It covers the installation of prerequisite utilities, creation of service accounts, directory permissions, systemd generators, and sudoers configuration.

## Prerequisites
* Root (sudo) access to the target server.
* Basic build tools installed (`gcc`, `g++`, `make`, `git`, `autoconf`, `automake`).

---

## 0. System Prerequisites Installation
Before setting up the IOC environment, the core utilities (`procServ` and `con`) must be compiled and installed system-wide.


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

> **WARNING:** Do **NOT** mount this directory via NFS. To prevent Systemd boot race conditions and avoid Single Points of Failure (SPOF), this directory must reside on the server's local disk. Configuration files should be deployed here via GitOps (CI/CD or Ansible).

```bash
mkdir -p /etc/procServ.d/
chown root:ioc /etc/procServ.d/
chmod 2775 /etc/procServ.d/
```

## 3. Sudoers Configuration
Allow members of the `ioc` group to manage `procServ` related systemd services without requiring a password. 

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

## 4. Systemd Generator Deployment
Deploy the AWK-based systemd generator which translates `.conf` files into transient `.service` units.

Copy the generator script to the systemd generators directory:
```bash
cp bin/epics-ioc-generator.bash /usr/lib/systemd/system-generators/epics-ioc-generator
chmod +x /usr/lib/systemd/system-generators/epics-ioc-generator

# Trigger the generator
systemctl daemon-reload
```

## 5. CLI Wrapper Deployment
Deploy the frontend management script `manage-process.bash` to a standard binary path.

```bash
cp bin/manage-process.bash /usr/local/bin/manage-procs
chmod +x /usr/local/bin/manage-procs
```
