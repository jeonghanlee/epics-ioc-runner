# EPICS IOC Runner - Documentation

**The `epics-ioc-runner` is a zero-dependency, systemd-native architecture designed for securely deploying and managing EPICS IOCs in both production and isolated local environments.**

This directory contains the complete documentation for deploying, managing, and understanding the architecture. The documentation is divided into architectural overviews, system administrator guides, and end-user operational manuals.

## Prerequisites and Operational Facts
* **EPICS Environment Permissions**: When running in system-wide mode, the IOC daemon operates under the restricted `ioc-srv` user account. If your EPICS environment is dynamically linked, you must ensure that the `ioc-srv` user has directory traversal (`+x`) and read (`+r`) permissions for the entire path where EPICS Base and modules are installed. Restricted parent directories (like a user's home directory) will cause dynamic linker (`ld.so`) failures (Exit Code 127).
* **Systemd Exit Status Handling**: The generated systemd templates are configured with specific `SuccessExitStatus` codes (0, 1, 2, 15, 143, SIGTERM, SIGKILL). This ensures that standard termination signals sent to `procServ` and the underlying IOC process are evaluated as clean exits (`inactive`) rather than failure states (`failed`). For a detailed technical explanation, see **[EXIT_SIGNAL_HANDLING.md](EXIT_SIGNAL_HANDLING.md)**.

## Documentation Index

### 1. Architecture and Design
* **[ARCHITECTURE.md](ARCHITECTURE.md)**
  Describes the core design principles, the zero-dependency approach, and the native systemd template (`@.service`) architecture. It also details the security model, including Role-Based Access Control (RBAC) via traditional Unix groups and sudoers policies.
* **[EXIT_SIGNAL_HANDLING.md](EXIT_SIGNAL_HANDLING.md)**
  Provides a technical deep dive into the signaling mechanics between systemd and procServ. It explains why specific exit codes (e.g., 143) are whitelisted to ensure reliable service monitoring.

### 2. Infrastructure Setup (System Administrators)
* **[INSTALL.md](INSTALL.md)**
  Provides step-by-step instructions for the initial server setup. It covers creating dedicated service accounts, setting up shared configuration directories with SetGID permissions, configuring sudoers, and deploying the static system-wide systemd template unit.

### 3. System-Wide Operations (Engineers)
* **[USER_GUIDE.md](USER_GUIDE.md)**
  The primary manual for engineers deploying and managing production IOCs globally on the server. It explains how to use the `ioc-runner` CLI wrapper to install configurations and how to use native `systemctl` and `journalctl` commands for daily operations.

### 4. Local Isolated Testing (Engineers)
* **[USER_GUIDE_LOCAL.md](USER_GUIDE_LOCAL.md)**
  A guide for running and testing IOCs completely within an isolated user space. It demonstrates how to utilize the `--local` flag to dynamically generate user-level systemd templates, allowing engineers to verify their IOC configurations safely without requiring root privileges.

### 5. Operations FAQ
* **[FAQ.md](FAQ.md)**
  Answers common operational questions including emergency access without root passwords, metadata extensions for legacy database migration, facility-wide IOC visibility, manual debugging workflows, and crash detection behavior.
