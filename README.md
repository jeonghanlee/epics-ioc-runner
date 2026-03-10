# EPICS IOC Runner

> **⚠️ DISCLAIMER: NOT WORKING / PSEUDO-CODE** > This repository currently contains conceptual pseudo-code and architectural structures. It has been drafted to establish the core concepts and design before detailed testing. **The code is not yet functional and should not be used in a production environment.**

## Overview
`epics-ioc-runner` is a robust, dependency-free, and OS-native management environment for EPICS IOCs. It provides a streamlined approach to deploying, monitoring, and controlling IOCs running under `procServ` using standard Linux tools like `systemd`, `awk`, `bash`, and `sudo`.

By eliminating heavy dependencies (such as Python) and complex configuration engines, this architecture adheres strictly to the **KISS (Keep It Simple, Stupid)** and **DRY (Don't Repeat Yourself)** principles, ensuring long-term maintainability across different Linux distributions (e.g., Debian, Rocky Linux).

## Key Features
* **Zero External Dependencies**: Relies entirely on POSIX-standard tools (`bash`, `awk`) and native `systemd` mechanisms. No Python or external packages are required for the management wrapper.
* **Dynamic Systemd Generation**: Uses a native `systemd-generator` (written in AWK) to translate simple configuration files into transient `epics-*.service` units automatically during boot or daemon reload.
* **Local Test Environment Support**: Provides a `--local` flag allowing engineers to generate user-level systemd units and run isolated tests entirely within their own user space without requiring `sudo` privileges.
* **Role-Based Access Control (RBAC)**: Utilizes traditional `/etc/sudoers.d/` policies to securely grant trained engineers (`ioc` group) passwordless access to IOC service management, without the fragmentation of Polkit rules.
* **UNIX Domain Sockets (UDS)**: Eliminates TCP port conflicts and secures console access by forcing all `procServ` instances to communicate via UNIX Domain Sockets.
* **Native Console Tool (`con`)**: Includes a lightweight, custom C++ terminal emulator (`con`) that perfectly handles UDS connections, replacing finicky tools like `socat` or `minicom`.

## Configuration Management: GitOps & Local Storage
To ensure maximum reliability and prevent Systemd boot race conditions, **this architecture intentionally avoids mounting the configuration directory (`/etc/procServ.d/`) via NFS.** Instead, it adopts a **GitOps** approach:
1. **Single Source of Truth**: All IOC `.conf` files for all servers are centrally version-controlled in this Git repository.
2. **Local Execution**: Configurations are deployed directly to the local disk (SSD) of each target server via CI/CD pipelines (or Ansible).
3. **Resilience**: This guarantees that Systemd Generators can always read configurations during early boot stages, and ensures that a network/NFS outage does not bring down the entire accelerator control system.

## Local Test Workflow
Engineers can completely verify their IOC environments before system-wide deployment. Utilizing the `--local` flag isolates the execution to the user level.

```bash
# 1. Add and start the IOC locally
./bin/manage-procs --local add mockioc -C /tmp/mock_ioc -c ./st.cmd

# 2. Check the user-level systemd service status
systemctl --user status epics-mockioc.service

# 3. Attach to the isolated local UNIX Domain Socket
./bin/manage-procs --local attach mockioc

# 4. Remove the local test IOC
./bin/manage-procs --local remove mockioc
```
## Repository Structure

```text
epics-ioc-runner/
├── bin/
│   ├── epics-ioc-generator.bash  # AWK/Bash systemd generator script
│   └── manage-process.bash       # Front-end CLI wrapper for adding/removing/attaching IOCs
├── docs/
│   ├── ARCHITECTURE.md           # Architecture overview and security model
│   ├── INSTALL.md                # System installation and infrastructure setup guide
│   └── USER_GUIDE.md             # Daily operations and IOC management guide
├── LICENSE                       # MIT License
└── README.md                     # Project overview and key features
```

## Documentation
Please refer to the detailed documentation in the `docs/` directory to get started:

1. **[System Installation Guide](docs/INSTALL.md)**: For System Administrators & SREs.
2. **[Operations User Guide](docs/USER_GUIDE.md)**: For EPICS Engineers.

## Acknowledgments
This project is heavily inspired by the Python-based `procServUtils` originally contributed by Michael Davidsaver and maintained in the [ralphlange/procServ](https://github.com/ralphlange/procServ/tree/master/procServUtils) repository. We have re-architected these excellent concepts into pure Bash and AWK to eliminate external dependencies and maximize long-term maintainability for accelerator environments.
