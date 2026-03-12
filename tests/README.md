# EPICS IOC Runner - Automated Local Lifecycle Tests

This directory contains automated integration tests to verify the local user-level systemd management architecture.

## Overview
The `test-local-lifecycle.bash` script performs a complete end-to-end validation of the `manage-process.bash` wrapper. It uses a real EPICS IOC (ServiceTestIOC) to ensure that the entire lifecycle functions correctly in an isolated user space without root privileges.

## Prerequisites
Ensure that your EPICS environment variables are properly loaded before execution. The script requires `EPICS_BASE` to generate the local configuration and run Channel Access utilities.

```bash
source /opt/epics/setEpicsEnv.bash
```

The following utilities must also be available in your system path:
* `make`, `gcc`/`g++`
* `git`
* `caget`
* `con`, `procServ`

## Test Execution
Run the script directly from the terminal. The script handles workspace creation, compilation, and cleanup automatically.

```bash
./test-local-lifecycle.bash
```

## Lifecycle Steps Verified
1. **Environment Setup & Compilation**: Clones and builds ServiceTestIOC.
2. **Install**: Generates the static user-level `.service` unit and `.conf` file.
3. **Start**: Launches the IOC and verifies the active systemd state.
4. **List & Socket**: Validates the creation of the UNIX Domain Socket (UDS).
5. **Interactive Attach**: Pauses to allow attaching to the console, checking `iocInit` status, and detaching safely.
6. **Channel Access**: Reads PV values iteratively to verify actual EPICS network activity and data flow.
7. **Persistence**: Tests `enable` and `disable` commands to verify systemd boot symlink creation.
8. **Remove & Cleanup**: Completely purges the generated service units and stops the daemon.
