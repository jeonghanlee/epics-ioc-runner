# EPICS IOC Runner - Documentation

This directory contains the complete documentation for deploying, managing, and understanding the `epics-ioc-runner` architecture. The documentation is divided into architectural overviews, system administrator guides, and end-user operational manuals.

## Documentation Index

### 1. Architecture and Design
* **[ARCHITECTURE.md](ARCHITECTURE.md)**
  Describes the core design principles, the zero-dependency approach, and the native systemd template (`@.service`) architecture. It also details the security model, including Role-Based Access Control (RBAC) via traditional Unix groups and sudoers policies.

### 2. Infrastructure Setup (System Administrators)
* **[INSTALL.md](INSTALL.md)**
  Provides step-by-step instructions for the initial server setup. It covers creating dedicated service accounts, setting up shared configuration directories with SetGID permissions, configuring sudoers, and deploying the static system-wide systemd template unit.

### 3. System-Wide Operations (Engineers)
* **[USER_GUIDE.md](USER_GUIDE.md)**
  The primary manual for engineers deploying and managing production IOCs globally on the server. It explains how to use the `ioc-runner` CLI wrapper to install configurations and how to use native `systemctl` and `journalctl` commands for daily operations.

### 4. Local Isolated Testing (Engineers)
* **[USER_GUIDE_LOCAL.md](USER_GUIDE_LOCAL.md)**
  A guide for running and testing IOCs completely within an isolated user space. It demonstrates how to utilize the `--local` flag to dynamically generate user-level systemd templates, allowing engineers to verify their IOC configurations safely without requiring root privileges.
