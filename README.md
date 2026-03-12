# EPICS IOC Runner

## Overview
`epics-ioc-runner` is a robust, dependency-free, and OS-native management environment for EPICS IOCs. It provides a streamlined approach to deploying, monitoring, and controlling IOCs running under `procServ` using standard Linux tools like `systemd`, `bash`, and `sudo`.

By eliminating heavy dependencies, this architecture adheres strictly to the **KISS (Keep It Simple, Stupid)** and **DRY (Don't Repeat Yourself)** principles, ensuring long-term maintainability across different Linux distributions without any version dependencies.

## Prerequisites
This architecture requires the following core utilities to be installed on your system (e.g., in `/usr/bin` or `/usr/local/bin`):
* **procServ**: https://github.com/jeonghanlee/procServ-env
* **con**: https://github.com/jeonghanlee/con

## Key Features
* **Zero External Dependencies**: Relies entirely on POSIX-standard tools (`bash`) and native `systemd` mechanisms. We profoundly despise `pip` dependency hell, so absolutely no Python or external packages are required.
* **Native Systemd Templates**: Utilizes a single systemd template unit (`epics-@.service`) to dynamically manage all IOC instances, eliminating the need for complex generator scripts or multiple daemon reloads.
* **Local Test Environment Support**: Provides a `--local` flag allowing engineers to run isolated tests entirely within their own user space using systemd user sessions, without requiring `sudo` privileges.
* **Role-Based Access Control (RBAC)**: Utilizes traditional `/etc/sudoers.d/` policies and SetGID directory permissions to securely grant trained engineers (`ioc` group) passwordless access to IOC service management.
* **UNIX Domain Sockets (UDS)**: Secures console access and eliminates TCP port conflicts.
* **Native Console Tool (`con`)**: Includes a lightweight, custom C++ terminal emulator for seamless UDS connections.

## Repository Structure

```text
epics-ioc-runner/
├── bin/
│   ├── ioc-runner                # Front-end CLI wrapper for install/remove/attach/list
│   └── setup-system-infra.bash   # Automated system infrastructure setup script
├── docs/
│   ├── ARCHITECTURE.md           # Architecture overview and security model
│   ├── INSTALL.md                # System installation and infrastructure setup guide
│   ├── README.md                 # Documentation index for the docs directory
│   ├── USER_GUIDE.md             # System-wide operations and IOC management guide
│   └── USER_GUIDE_LOCAL.md       # Local isolated testing guide for engineers
├── policy/
│   └── 10-epics-ioc              # Sudoers configuration for RBAC
├── tests/
│   ├── test-local-lifecycle.bash # Automated integration tests for local execution
│   └── README.md                 # Test execution guide
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
