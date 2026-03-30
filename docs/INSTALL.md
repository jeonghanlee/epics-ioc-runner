# EPICS IOC Runner - System Installation & Configuration Guide

This guide describes the initial server setup required to deploy the `epics-ioc-runner` architecture system-wide. It covers the installation of prerequisite utilities, creation of isolated service accounts, strict directory permissions, systemd template deployment, and secure sudoers configuration.

## Prerequisites
* Root (sudo) access to the target server.
* Basic build tools installed (`gcc`, `g++`, `make`, `git`).
* Core utilities (`procServ` and `con`) compiled and installed system-wide.

---

## 1. Automated Infrastructure Setup (Recommended)
We provide a hardened, idempotent setup script that automatically configures isolated service accounts, strict directory permissions, and validated sudoers policies.

From the root of the repository, execute the following script as root using the `--full` flag for the initial complete setup:
```bash
sudo ./bin/setup-system-infra.bash --full
```

> **Tip for Operations:** Later, if you only need to update the `ioc-runner` CLI script to a newer version without touching the underlying systemd templates or permissions, simply run the script without any arguments:
> `sudo ./bin/setup-system-infra.bash`

Once the script completes successfully, manually add your authorized engineers to the `ioc` management group:
```bash
sudo usermod -aG ioc <username>
```

To apply the new group membership immediately to your current terminal session without logging out, run:
```bash
newgrp ioc
```

### Troubleshooting: NFS `root_squash` Error
If you execute the setup script from an NFS-mounted directory (such as a networked home directory, common in RHEL/Rocky environments), you may encounter an error indicating that `ioc-runner` could not be found or read.

This occurs because the NFS `root_squash` security feature forcibly downgrades the `sudo` (root) execution privileges to the anonymous `nobody` user, blocking the script from reading the repository files.

**Workaround:** Copy the repository to a local filesystem partition (e.g., `/tmp` or `/opt`) before running the setup script.
```bash
cp -r /path/to/epics-ioc-runner /tmp/
cd /tmp/epics-ioc-runner
sudo ./bin/setup-system-infra.bash --full
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

Sudo requires absolute paths for strict security. Determine the exact path to `systemctl` on your operating system and generate the sudoers file:
```bash
SYSTEMCTL_BIN=$(command -v systemctl)

cat <<EOF > /etc/sudoers.d/10-epics-ioc
%ioc ALL=(root) NOPASSWD: ${SYSTEMCTL_BIN} start epics-@*.service, \\
                          ${SYSTEMCTL_BIN} stop epics-@*.service, \\
                          ${SYSTEMCTL_BIN} restart epics-@*.service, \\
                          ${SYSTEMCTL_BIN} status epics-@*.service, \\
                          ${SYSTEMCTL_BIN} enable epics-@*.service, \\
                          ${SYSTEMCTL_BIN} disable epics-@*.service, \\
                          ${SYSTEMCTL_BIN} daemon-reload
EOF

chmod 0440 /etc/sudoers.d/10-epics-ioc
```

### 2.4. Systemd Template Unit Deployment
Deploy the single systemd template unit (`@.service`) that will dynamically manage all IOC instances system-wide. Resolve the `procServ` path dynamically to accommodate different installation targets (e.g., `/usr/bin` vs `/usr/local/bin`).

**Note on Time Synchronization:** The template explicitly requires `time-sync.target` to ensure that NTP/PTP time synchronization is fully established before the IOC daemon starts. This is critical for maintaining accurate timestamps for the Archiver Appliance and MRF timing systems.


```bash
PROCSERV_BIN=$(command -v procServ)

cat <<EOF > /etc/systemd/system/epics-@.service
[Unit]
Description=procServ for %i
Wants=time-sync.target
After=network.target remote-fs.target time-sync.target
AssertFileNotEmpty=/etc/procServ.d/%i.conf

[Service]
Type=simple
User=ioc-srv
Group=ioc
EnvironmentFile=/etc/procServ.d/%i.conf
RuntimeDirectory=procserv/%i
RuntimeDirectoryMode=0770
ExecStart=${PROCSERV_BIN} --foreground --logfile=- --name=%i --ignore=^D^C^] --chdir=\${IOC_CHDIR} --port=\${IOC_PORT} \${IOC_CMD}
SuccessExitStatus=0 1 2 15 143 SIGTERM SIGKILL
StandardOutput=syslog
StandardError=inherit
SyslogIdentifier=epics-%i

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
```

---

## 3. CLI Wrapper Deployment
Deploy the frontend management script `ioc-runner` to a standard binary path. To ensure strict traceability, the current Git hash and build timestamp must be injected into the script during deployment.

```bash
# 1. Copy the script to the system path
sudo cp bin/ioc-runner /usr/local/bin/ioc-runner

# 2. Inject version traceability information
GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || printf "unknown")
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

sudo sed -i "s/^declare -g RUNNER_GIT_HASH=.*/declare -g RUNNER_GIT_HASH=\"${GIT_HASH}\"/" /usr/local/bin/ioc-runner
sudo sed -i "s/^declare -g RUNNER_BUILD_DATE=.*/declare -g RUNNER_BUILD_DATE=\"${BUILD_DATE}\"/" /usr/local/bin/ioc-runner

# 3. Apply execution permissions
sudo chmod 0755 /usr/local/bin/ioc-runner
```

## 4. Shared Deployment Directory Setup (/opt/epics-iocs)
Before engineers can deploy IOCs, a shared payload directory must be established. This directory must be accessible and writable by the `ioc` group.

### Option A: Local Disk
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

### 4.1. EPICS Environment and Shared Libraries Permissions
The `ioc-srv` account must have execute (`+x`) and read (`+r`) permissions for the entire EPICS environment where the Base and modules (e.g., `asyn`, `seq`) are installed.

If the EPICS environment is compiled inside a restricted user directory (e.g., `/home/username/epics`), you must ensure the `ioc-srv` user can traverse the parent directories and read the shared libraries. Otherwise, the dynamic linker (`ld.so`) will fail with Exit Code 127.

Example for opening permissions on a local user's EPICS build:
```bash
chmod o+x /home/username
chmod -R o+rx /home/username/epics
```
