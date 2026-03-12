# EPICS IOC Runner - Automated Local Lifecycle Tests

This directory contains automated integration tests to verify the local user-level systemd management architecture.

## Overview
The `test-local-lifecycle.bash` script performs a complete end-to-end validation of the `manage-process.bash` wrapper. It uses a real EPICS IOC ([ServiceTestIOC](https://github.com/jeonghanlee/ServiceTestIOC)) to ensure that the entire lifecycle—from deployment to cleanup—functions correctly in an isolated user space without root privileges.

## Prerequisites
Before running the test, ensure that your EPICS environment variables are properly loaded. The script strictly requires `EPICS_BASE` to generate the local configuration and run Channel Access utilities.

```bash
# Example: Source your site-specific EPICS environment
source /opt/epics/setEpicsEnv.bash
```

The following utilities must also be available in your system path:
* `make`, `gcc`/`g++` (for compiling the test IOC)
* `git` (to fetch the test IOC repository)
* `caget` (for Channel Access verification)
* `con` and `procServ` (core runner dependencies)

## Test Execution
Run the script directly from the terminal. The script will handle creating a workspace, compiling the IOC, and cleaning up afterward.

```bash
./test-local-lifecycle.bash
```

## Lifecycle Steps Verified
1. **Environment Setup & Compilation**: Clones and builds `ServiceTestIOC`.
2. **Install**: Generates the static user-level `.service` unit and `.conf` file.
3. **Start**: Launches the IOC and verifies the active systemd state.
4. **List & Socket**: Validates the creation of the UNIX Domain Socket (UDS).
5. **Interactive Attach**: Pauses to allow engineers to safely attach to the console, check `iocInit` status, and detach.
6. **Channel Access**: Reads PV values iteratively to verify actual EPICS network activity and data flow.
7. **Persistence**: Tests `enable` and `disable` commands to verify systemd boot symlink creation.
8. **Remove & Cleanup**: Completely purges the generated service units and stops the daemon to ensure idempotency.

