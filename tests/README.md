# EPICS IOC Runner - Automated Lifecycle Tests

This directory contains automated integration tests to verify both local user-level and system-wide systemd management architectures.

## Overview
The scripts perform a complete end-to-end validation of the `ioc-runner` wrapper. They use a real EPICS IOC (ServiceTestIOC) to ensure that the entire lifecycle functions correctly in both isolated user spaces and system-wide environments.

## Prerequisites
Ensure that your EPICS environment variables are properly loaded before execution. The scripts require `EPICS_BASE` to generate the configuration and run Channel Access utilities.

```bash
source /opt/epics/setEpicsEnv.bash
```

The following utilities must also be available in your system path:
* `make`, `gcc`/`g++`
* `git`
* `caget`
* `con`, `procServ`

## Test Execution
Run the scripts directly from the terminal. The scripts handle workspace creation, compilation, and cleanup automatically.

**For Local User-level Validation:**
```bash
./test-local-lifecycle.bash
```

**For System-wide Validation:**
*(Requires the `ioc` group and sudoers policies to be configured via `setup-system-infra.bash`)*
```bash
./test-system-lifecycle.bash
```

## Lifecycle Steps Verified
1. **Environment Setup & Compilation**: Clones and builds ServiceTestIOC.
2. **Install**: Generates the `.service` unit and `.conf` file.
3. **Start**: Launches the IOC and verifies the active systemd state.
4. **List & Socket**: Validates the creation of the UNIX Domain Socket (UDS).
5. **Interactive Attach**: Pauses to allow attaching to the console, checking `iocInit` status, and detaching safely.
6. **Channel Access**: Reads PV values iteratively to verify actual EPICS network activity and data flow.
7. **Persistence**: Tests `enable` and `disable` commands to verify systemd boot symlink creation.
8. **Remove & Cleanup**: Completely purges the generated service units and stops the daemon.
