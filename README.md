# EPICS IOC Runner

> **⚠️ DISCLAIMER: NOT WORKING / PSEUDO-CODE** > This repository currently contains conceptual pseudo-code and architectural structures. It has been drafted to establish the core concepts and design before detailed testing. **The code is not yet functional and should not be used in a production environment.**

## Overview
`epics-ioc-runner` is a robust, dependency-free, and OS-native management environment for EPICS IOCs. It provides a streamlined approach to deploying, monitoring, and controlling IOCs running under `procServ` using standard Linux tools like `systemd`, `awk`, `bash`, and `sudo`.

By eliminating heavy dependencies (such as Python) and complex configuration engines, this architecture adheres strictly to the **KISS (Keep It Simple, Stupid)** and **DRY (Don't Repeat Yourself)** principles, ensuring long-term maintainability across different Linux distributions (e.g., Debian, Rocky Linux).

## Key Features
* **Zero External Dependencies**: Relies entirely on POSIX-standard tools (`bash`, `awk`) and native `systemd` mechanisms. No Python or external packages are required for the management wrapper.
* **Dynamic Systemd Generation**: Uses a native `systemd-generator` (written in AWK) to translate simple configuration files into transient `.service` units automatically during boot or daemon reload.
* **Role-Based Access Control (RBAC)**: Utilizes traditional `/etc/sudoers.d/` policies to securely grant trained engineers (`ioc` group) passwordless access to IOC service management, without the fragmentation of Polkit rules.
* **UNIX Domain Sockets (UDS)**: Eliminates TCP port conflicts and secures console access by forcing all `procServ` instances to communicate via UNIX Domain Sockets.
* **Native Console Tool (`con`)**: Includes a lightweight, custom C++ terminal emulator (`con`) that perfectly handles UDS connections, replacing finicky tools like `socat` or `minicom`.

## Documentation
Please refer to the detailed documentation in the `docs/` directory to get started:

1. **[System Installation Guide](docs/INSTALL.md)**: For System Administrators & SREs. Covers user/group creation, directory setup, sudoers policy deployment, and systemd generator installation.
2. **[Operations User Guide](docs/USER_GUIDE.md)**: For EPICS Engineers. Covers how to add new IOCs, attach to consoles using the `con` tool, and manage processes using native `systemctl` and `journalctl` commands.

## Acknowledgments
This project is heavily inspired by the Python-based `procServUtils` (specifically `manage-procs` and the systemd generators) originally contributed by Michael Davidsaver and maintained in the [ralphlange/procServ](https://github.com/ralphlange/procServ/tree/master/procServUtils) repository. We have re-architected these excellent concepts into pure Bash and AWK to eliminate external dependencies and maximize long-term maintainability for accelerator environments.
