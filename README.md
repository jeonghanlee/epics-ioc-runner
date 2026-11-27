# EPICS IOC Runner

`epics-ioc-runner` manages EPICS Input/Output Controllers (IOCs) under
procServ. One Bash command generates configurations, controls services,
connects to consoles, and reports startup results.

| Mode | Supervisor | Runs as | Guide |
| --- | --- | --- | --- |
| System | systemd | Shared service account (`ioc-srv`) | [System operations](docs/USER_GUIDE.md) |
| Local | User systemd | Invoking user | [Local operations](docs/USER_GUIDE_LOCAL.md) |
| Container | s6 | Root manages; `ioc-srv` runs the IOC | [Container setup](docs/INSTALL.md#container-images---container) |

## Install and run IOCs

Start with the [installation guide](docs/INSTALL.md) for system or container
setup, or the [local guide](docs/USER_GUIDE_LOCAL.md) for a user installation.
The runner requires Bash 4.3+, procServ, and the selected service manager.
Console access uses [con](https://github.com/jeonghanlee/con), with `socat`
as a fallback; see the [console requirements and production limitation](docs/CLI_REFERENCE.md#comparison-of-attach-and-monitor).
The [procServ-env project](https://github.com/jeonghanlee/procServ-env)
provides a procServ build environment.

## Documentation and source layout

The [operator book](docs/README.md) links the installation and operations
guides, command reference, permission model, and log and network settings.
For common symptoms, use the [operations FAQ](docs/FAQ.md).

| Path | Contents |
| --- | --- |
| `bin/` | Runner, setup scripts, and completion |
| `configure/` | Make targets and installation settings |
| `docs/` | Operator book and project records |
| `policy/` | Access-control reference files |
| `system-wide/` | External management integrations |
| `tests/` | Verification suites |

## Acknowledgments

This project is inspired by the Python-based `procServUtils` maintained in
the [ralphlange/procServ](https://github.com/ralphlange/procServ/tree/master/procServUtils)
repository.
