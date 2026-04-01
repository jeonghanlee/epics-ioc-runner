# EPICS IOC Runner

## Overview
`epics-ioc-runner` is a robust, dependency-free, and OS-native management environment for EPICS IOCs. It provides a streamlined approach to deploying, monitoring, and controlling IOCs running under `procServ` using standard Linux tools like `systemd`, `bash`, and `sudo`.

By eliminating heavy dependencies, this architecture adheres strictly to the **KISS (Keep It Simple, Stupid)** and **DRY (Don't Repeat Yourself)** principles, ensuring long-term maintainability across different Linux distributions.

## Prerequisites
This architecture requires the following core utilities to be installed on your system (e.g., in `/usr/bin` or `/usr/local/bin`):
* **procServ**: https://github.com/jeonghanlee/procServ-env
* **con**: https://github.com/jeonghanlee/con (Recommended for clean detachment via Ctrl-A)
  * *Fallback*: If `con` is unavailable, the `attach` command automatically falls back to `socat` or `nc` (with `-U` UNIX Domain Socket support).

## Key Highlights
* **Zero External Dependencies**: Relies entirely on POSIX-standard `bash` and native `systemd` mechanisms. No Python or external packages are required.
* **High-Performance Minimal-Fork Architecture**: Utilizes pure Bash stream parsing and O(1) associative arrays to batch-fetch socket and systemd states, eliminating per-IOC subprocess overhead.
* **Dual Execution Modes**: Supports both system-wide deployment (via RBAC and sudoers) and isolated local user environments for testing.

## Repository Structure

```text
epics-ioc-runner/
├── bin/
│   ├── ioc-runner                # Front-end CLI wrapper
│   └── setup-system-infra.bash   # Automated system infrastructure setup script
├── docs/                         # Detailed system documentation
├── policy/                       # RBAC and Sudoers reference configurations
├── system-wide/                  # External management tool integrations
├── tests/                        # Automated integration test suites
├── LICENSE                       # MIT License
└── README.md                     # Project overview and entry point
```

## Documentation
For detailed operational instructions, security models, and architectural notes, please refer to the dedicated documentation in the `docs/` directory:

1. **[System Installation Guide](docs/INSTALL.md)**: Infrastructure setup for System Administrators & SREs.
2. **[Operations User Guide](docs/USER_GUIDE.md)**: Managing system-wide IOCs for EPICS Engineers.
3. **[Local Execution Guide](docs/USER_GUIDE_LOCAL.md)**: Testing IOCs in isolated local user space.
4. **[Architecture Overview](docs/ARCHITECTURE.md)**: Security model, SetGID policies, and system design.
5. **[Exit Signal Handling](docs/EXIT_SIGNAL_HANDLING.md)**: Signal propagation and systemd exit status technical notes.
6. **[Operations FAQ](docs/FAQ.md)**: Common operational questions and answers for facility engineers.

## Acknowledgments
This project is inspired by the Python-based `procServUtils` originally contributed by Michael Davidsaver and maintained in the [ralphlange/procServ](https://github.com/ralphlange/procServ/tree/master/procServUtils) repository.
