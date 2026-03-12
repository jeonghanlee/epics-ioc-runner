# EPICS IOC Runner - System Installation & Configuration Guide

This guide describes the initial server setup required to deploy the `epics-ioc-runner` architecture system-wide. It covers the installation of prerequisite utilities, creation of isolated service accounts, strict directory permissions, systemd template deployment, and secure sudoers configuration.

## Prerequisites
* Root (sudo) access to the target server.
* Basic build tools installed (`gcc`, `g++`, `make`, `git`).
* Core utilities (`procServ` and `con`) compiled and installed system-wide.

---

## 1. Automated Infrastructure Setup (Recommended)
We provide a hardened, idempotent setup script that automatically configures isolated service accounts, strict directory permissions, and validated sudoers policies.

From the root of the repository, execute the following script as root:
```bash
sudo ./bin/setup-system-infra.bash
```

Once the script completes successfully, manually add your authorized engineers to the `ioc` management group:
```bash
sudo usermod -aG ioc <username>
```

---

## 2. Manual Setup Reference (Under the Hood)
If you prefer to configure the system manually or need to audit the security changes made by the automated script, follow these steps.

### 2.1. Account and Group Setup
Create an isolated service account and a management group.
```bash
# Create the management group
groupadd ioc

# Create the isolated service account with no home directory and no login shell
useradd -r -M -d /nonexistent -g ioc -s /sbin/nologin -c "EPICS procServ Daemon Account" ioc-srv
```

### 2.2. Shared Configuration Directory Setup (Strict ACL)
Create the directory where IOC configuration files will reside. This directory is strictly restricted to `root` and the `ioc` group using `2770` permissions.
```bash
mkdir -p /etc/procServ.d/
chown root:ioc /etc/procServ.d/
chmod 2770 /etc/procServ.d/
```

### 2.3. Sudoers Configuration (Restricted)
Allow members of the `ioc` group to manage only specific `epics-@*.service` systemd instances securely.

Create the file `/etc/sudoers.d/10-epics-ioc`:
```bash
# Allow trained engineers to manage ONLY EPICS template services
%ioc ALL=(root) NOPASSWD: /bin/systemctl start epics-@*.service, \
                          /bin/systemctl stop epics-@*.service, \
                          /bin/systemctl restart epics-@*.service, \
                          /bin/systemctl status epics-@*.service, \
                          /bin/systemctl enable epics-@*.service, \
                          /bin/systemctl disable epics-@*.service, \
                          /bin/systemctl daemon-reload
```
Apply strict permissions to the sudoers file:
```bash
chmod 0440 /etc/sudoers.d/10-epics-ioc
```

### 2.4. Systemd Template Unit Deployment
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

---

## 3. CLI Wrapper Deployment
Deploy the frontend management script `ioc-runner` to a standard binary path for all engineers to use.

```bash
sudo cp bin/ioc-runner /usr/local/bin/ioc-runner
sudo chmod +x /usr/local/bin/ioc-runner
```

## 4. Shared Deployment Directory Setup (/opt/epics-iocs)
Before engineers can deploy IOCs, a shared payload directory must be established. This directory must be accessible and writable by the `ioc` group.

### Option A: Local Local Disk
If the IOCs will reside on the local server's filesystem:

```bash
sudo mkdir -p /opt/epics-iocs
sudo chown root:ioc /opt/epics-iocs
sudo chmod 2775 /opt/epics-iocs
```

### Option B: NFS Mount (Centralized Storage)
For environments using a central storage server, ensure the NFS export is configured with the `ioc` GID and `2775` permissions.

Mount the directory persistently via `/etc/fstab`:
```text
# /etc/fstab
nfs-storage.local:/export/epics-iocs  /opt/epics-iocs  nfs  defaults,_netdev  0  0
```

Apply the mount:
```bash
sudo mount /opt/epics-iocs
```
