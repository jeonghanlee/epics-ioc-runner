# EPICS IOC Runner - System Uninstallation Guide

This guide describes how to remove the system-wide `epics-ioc-runner` infrastructure deployed by `bin/setup-system-infra.bash --full`. It reverses the installation steps in [INSTALL.md](INSTALL.md) in safe order.

This document is **not** for removing a single IOC. To remove one IOC configuration while keeping the infrastructure intact, use:
```bash
ioc-runner remove <ioc-name>
```

## Prerequisites
* Root (sudo) access to the target server.
* No active `epics-@*.service` instances.
* No IOC configuration files remaining in `/etc/procServ.d`.

---

## 1. Pre-Removal Safety Checks

Before removing anything, verify no IOC is running and no operator configuration is left behind.

### 1.1 Active services
```bash
systemctl list-units 'epics-@*.service' --state=active
```
If any service is listed, stop and remove it first via `ioc-runner remove <ioc-name>` for each active instance.

### 1.2 Existing IOC configurations
```bash
ls /etc/procServ.d/*.conf 2>/dev/null
```
If any `.conf` file appears, the corresponding IOC has not been removed. Run `ioc-runner remove <ioc-name>` for each one before proceeding.

> **Tip for Operations:** The uninstall steps below assume a clean state. Do not force-delete `/etc/procServ.d` contents — always go through `ioc-runner remove` so systemd units are cleanly disabled first.

---

## 2. Ordered Removal Steps

Execute each step as root. The order reverses the installation sequence so that dependencies are torn down before their dependents.

### 2.1 Bash completion
```bash
rm -f /etc/bash_completion.d/ioc-runner
```

### 2.2 CLI wrapper
The second line applies to Rocky/RHEL only, where a symlink under `/usr/bin` is installed to satisfy sudo's `secure_path`. `rm -f` is a no-op on Debian.
```bash
rm -f /usr/local/bin/ioc-runner
rm -f /usr/bin/ioc-runner
```

### 2.3 Systemd template
```bash
rm -f /etc/systemd/system/epics-@.service
systemctl daemon-reload
```

### 2.4 Sudoers drop-in
```bash
rm -f /etc/sudoers.d/10-epics-ioc
```

### 2.5 Shared configuration directory
The `rmdir` below refuses if the directory is not empty. If it fails, return to section 1.2.
```bash
rmdir /etc/procServ.d
```

### 2.6 Service account and group
```bash
userdel ioc-srv
groupdel ioc
```
See the Troubleshooting section if either command reports that the account is in use.

---

## 3. Verification

Run the following checks. Each command should report the artefact as absent.
```bash
getent passwd ioc-srv
getent group ioc
which ioc-runner
ls /etc/procServ.d
ls /etc/sudoers.d/10-epics-ioc
ls /etc/systemd/system/epics-@.service
ls /etc/bash_completion.d/ioc-runner
ls /usr/bin/ioc-runner
```
The last line applies to Rocky/RHEL; on Debian the path was never installed.

---

## 4. Backup Retention

The installer writes timestamped backups of replaced files into `/var/backups/epics-ioc-runner`. Uninstall intentionally leaves this directory in place so the previous configuration can be restored later.

To wipe backups as well:
```bash
rm -rf /var/backups/epics-ioc-runner
```

---

## Troubleshooting

### `userdel: user ioc-srv is currently used by process`
A lingering `procServ` or shell process is still owned by the service account. Identify and stop it, then retry:
```bash
ps -u ioc-srv
```
If the process belongs to a stale IOC instance, reboot the host or kill the process explicitly before rerunning `userdel`.

### `groupdel: cannot remove the primary group of user`
Another account still has `ioc` as its primary group. Use `getent group ioc` to identify membership and remove or reassign those accounts first. Supplementary memberships added via `usermod -aG ioc <username>` are not a blocker for `groupdel`, but the membership entries on those user records become orphaned after removal — this is harmless.

### NFS `root_squash`
If the repository lives on an NFS share with `root_squash`, the install script cannot read its own files under sudo. The uninstall steps above do not read repository files, so this is not an issue for removal. See [INSTALL.md](INSTALL.md) for the install-side workaround.
