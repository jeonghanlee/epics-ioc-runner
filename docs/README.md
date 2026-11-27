# EPICS IOC Runner

This operator book covers host setup and the deployment, operation, and
removal of EPICS Input/Output Controllers (IOCs) managed by procServ.
It assumes familiarity with EPICS and Linux services; the task guides serve
as the worked procedures rather than a separate tutorial.

## Choose an execution mode

| Mode | Service manager | IOC identity | Start here |
| --- | --- | --- | --- |
| System | System systemd | Shared account, default `ioc-srv` | [Install](INSTALL.md), then [operate](USER_GUIDE.md) |
| Local | User systemd | Your account | [Run locally](USER_GUIDE_LOCAL.md) |
| Container | s6 | Service account; root manages | [Prepare the image](INSTALL.md#container-images---container), then [operate](USER_GUIDE.md#run-iocs-in-container-mode) |

To remove infrastructure, follow [Uninstall EPICS IOC Runner](UNINSTALL.md).
For operational symptoms, use the [FAQ](FAQ.md).

## Find detailed behavior

Each reference owns one topic; the guides link to it when a task needs detail.

| Topic | Page |
| --- | --- |
| Components and supervision | [Architecture](ARCHITECTURE.md) |
| Ownership, modes, ACLs, and sudo | [Permission model](PERMISSION_MODEL.md) |
| Stop signals and automatic restart | [Exit and signal handling](EXIT_SIGNAL_HANDLING.md) |
| Commands, options, output, and exit status | [CLI reference](CLI_REFERENCE.md) |
| Shared and per-IOC network environment | [Network environment](NETWORK_ENV.md) |
| Log paths and rotation | [Log layout](LOG_LAYOUT.md) |
| Terms used in this book | [Glossary](GLOSSARY.md) |
