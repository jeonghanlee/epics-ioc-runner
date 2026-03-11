# EPICS IOC Runner

> **⚠️ DISCLAIMER: WORK IN PROGRESS**
> The local testing environment (user-level systemd integration) is fully functional and verified. However, system-wide deployment components—including service accounts, user groups, and global systemd integration—are currently under active development and testing. **Do not use this in a production environment yet.**

## Overview
`epics-ioc-runner` is a robust, dependency-free, and OS-native management environment for EPICS IOCs. It provides a streamlined approach to deploying, monitoring, and controlling IOCs running under `procServ` using standard Linux tools like `systemd`, `awk`, `bash`, and `sudo`.

By eliminating heavy dependencies and complex configuration engines, this architecture adheres strictly to the **KISS (Keep It Simple, Stupid)** and **DRY (Don't Repeat Yourself)** principles, ensuring long-term maintainability across different Linux distributions.

## Prerequisites
This architecture requires the following core utilities to be installed on your system (e.g., in `/usr/bin` or `/usr/local/bin`):
* **procServ**: https://github.com/jeonghanlee/procServ-env
* **con**: https://github.com/jeonghanlee/con

## Key Features
* **Zero External Dependencies**: Relies entirely on POSIX-standard tools (`bash`, `awk`) and native `systemd` mechanisms.
* **Dynamic Systemd Generation**: Uses a native `systemd-generator` (written in AWK) to translate simple configuration files into transient `epics-*.service` units.
* **Local Test Environment Support**: Provides a `--local` flag allowing engineers to generate user-level systemd units and run isolated tests entirely within their own user space without requiring `sudo` privileges.
* **Role-Based Access Control (RBAC)**: Utilizes traditional `/etc/sudoers.d/` policies to securely grant trained engineers (`ioc` group) passwordless access to IOC service management.
* **UNIX Domain Sockets (UDS)**: Secures console access and eliminates TCP port conflicts.
* **Native Console Tool (`con`)**: Includes a lightweight, custom C++ terminal emulator for seamless UDS connections.

## Repository Structure

```text
epics-ioc-runner/
├── bin/
│   ├── epics-ioc-generator.bash  # AWK/Bash systemd generator script
│   └── manage-process.bash       # Front-end CLI wrapper for install/remove/attach/list
├── docs/
│   ├── ARCHITECTURE.md           # Architecture overview and security model
│   ├── INSTALL.md                # System installation and infrastructure setup guide
│   ├── USER_GUIDE.md             # System-wide operations and IOC management guide
│   └── USER_GUIDE_LOCAL.md       # Local isolated testing guide for engineers
├── policy/
│   └── 10-epics-ioc              # Sudoers configuration for RBAC
├── LICENSE                       # MIT License
└── README.md                     # Project overview and key features
```

## Documentation
Please refer to the detailed documentation in the `docs/` directory to get started:

1. **[System Installation Guide](docs/INSTALL.md)**: For System Administrators & SREs.
2. **[Operations User Guide](docs/USER_GUIDE.md)**: For EPICS Engineers managing system-wide IOCs.
3. **[Local Execution Guide](docs/USER_GUIDE_LOCAL.md)**: For engineers testing IOCs in local user space.
4. **[Architecture Overview](docs/ARCHITECTURE.md)**: Details on the security model and system design.

## Acknowledgments
This project is heavily inspired by the Python-based `procServUtils` originally contributed by Michael Davidsaver and maintained in the [ralphlange/procServ](https://github.com/ralphlange/procServ/tree/master/procServUtils) repository.
