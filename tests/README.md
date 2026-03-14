# EPICS IOC Runner - Automated Tests

This directory contains automated integration and error handling tests to verify both local user-level and system-wide systemd management architectures.

## Overview
The scripts perform a complete end-to-end validation of the `ioc-runner` wrapper. The lifecycle tests use a real EPICS IOC (ServiceTestIOC) to ensure that the entire lifecycle functions correctly in both isolated user spaces and system-wide environments. The error handling test verifies all negative exit paths without requiring EPICS or a running systemd service.

## Prerequisites

### Lifecycle Tests
Ensure that your EPICS environment variables are properly loaded before execution. The scripts require `EPICS_BASE` to generate the configuration and run Channel Access utilities.

```bash
source /opt/epics/setEpicsEnv.bash
```

The following utilities must also be available in your system path:
* `make`, `gcc`/`g++`
* `git`
* `caget`
* `con`, `procServ`

### Error Handling Test
No EPICS environment is required. A mock `con` binary is created automatically by the test script via `IOC_RUNNER_CON_TOOL`.

## Test Execution

**For Local User-level Validation:**
```bash
./test-local-lifecycle.bash
```

**For System-wide Validation:**
*(Requires the `ioc` group and sudoers policies to be configured via `setup-system-infra.bash`)*
```bash
./test-system-lifecycle.bash
```

**For Error Handling Validation:**
*(No EPICS environment or system privileges required)*
```bash
./test-error-handling.bash
```

## Lifecycle Steps Verified

### test-local-lifecycle.bash / test-system-lifecycle.bash
1. **Environment Setup & Compilation**: Clones and builds ServiceTestIOC.
2. **Install**: Generates the `.service` unit and `.conf` file.
3. **Start**: Launches the IOC and verifies the active systemd state.
4. **List & Socket**: Validates the creation of the UNIX Domain Socket (UDS).
5. **Interactive Attach**: Pauses to allow attaching to the console, checking `iocInit` status, and detaching safely.
6. **Channel Access**: Reads PV values iteratively to verify actual EPICS network activity and data flow.
7. **Persistence**: Tests `enable` and `disable` commands to verify systemd boot symlink creation.
8. **Remove & Cleanup**: Completely purges the generated service units and stops the daemon.

### test-error-handling.bash
1. **Usage and Help**: Verifies `--help`, `-h`, no-args exit 0 and unknown command exits 1.
2. **Missing Target**: Verifies all commands exit 1 when no target IOC name is provided.
3. **Install Error Paths**: Verifies exit 1 for missing conf file and missing system template.
4. **Attach Error Paths**: Verifies exit 1 when conf file is missing for the target IOC.
5. **List Empty**: Verifies exit 0 when no active sockets are present.
