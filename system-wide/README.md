# System-Wide Integration Components

This directory contains architecture documentation for facility-wide
integration layers that extend the `epics-ioc-runner` management environment.

## Components

### conserver

Centralized multi-user console access to EPICS IOCs across all nodes.
Provides `console <ioc-name>` routing from a single server via SSH +
`conserver-exec` wrapper.

**Repository:** <https://github.com/jeonghanlee/conserver-env>

All build infrastructure, deployment rules, service accounts, and
architecture documentation are maintained in the `conserver-env` repository.

### cockpit

Web-based multi-host IOC monitoring dashboard via Cockpit custom plugin.

**Documentation:** [cockpit/docs/ARCHITECTURE.md](cockpit/docs/ARCHITECTURE.md)

