# EPICS IOC Runner - Automated Tests

This directory contains automated integration and error handling tests to verify both local user-level and system-wide systemd management architectures.

## Overview
The scripts perform a complete end-to-end validation of the `ioc-runner` wrapper. The lifecycle tests use a real EPICS IOC (ServiceTestIOC) to ensure that the entire lifecycle functions correctly in both isolated user spaces and system-wide environments. The error handling test verifies all negative exit paths without requiring EPICS or a running systemd service. The system infra test verifies the `setup-system-infra.bash` deployment script.

Both lifecycle tests create a temporary workspace under `/tmp` at runtime and remove it automatically upon completion or failure.

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

### System Infra Test
Requires `sudo` or root privileges. `procServ` must be installed on the system.

## Test Execution

**For Local User-level Validation:**
```bash
bash tests/test-local-lifecycle.bash
```

**For System-wide Validation:**
*(Requires `setup-system-infra.bash` to have been run. The current user must belong to the `ioc` group.)*
```bash
bash tests/test-system-lifecycle.bash
```

**For Error Handling Validation:**
*(No EPICS environment or system privileges required)*
```bash
bash tests/test-error-handling.bash
```

**For System Infrastructure Validation:**
*(Requires root privileges and `procServ` installed)*
```bash
sudo bash tests/test-system-infra.bash
```

## Lifecycle Steps Verified

### test-local-lifecycle.bash
1. **Workspace Setup**: Creates a temporary workspace under `/tmp`. Removed automatically on exit.
2. **Cleanup Previous State**: Removes residual processes, templates, and configurations.
3. **Environment Setup & Compilation**: Clones and builds ServiceTestIOC.
4. **Install**: Generates the `.service` unit and `.conf` file in user space.
5. **Start**: Launches the IOC and verifies the active systemd user service state.
6. **Status**: Verifies that the status output contains `active`.
7. **View**: Verifies that the conf file content appears in the output.
8. **Restart**: Restarts the service and verifies it remains active.
9. **Stop**: Stops the service, verifies inactive state, then restarts and verifies active state.
10. **List & Socket**: Validates UDS socket creation and verifies list output contains IOC name, socket path, and divider lines.
11. **Console Attach**: Verifies UDS socket permissions, `con` availability, and socket listening state via `ss -lx`.
12. **Channel Access**: Reads PV values iteratively to verify actual EPICS network activity and data flow.
13. **Persistence**: Tests `enable` and `disable` commands to verify systemd boot symlink creation.
14. **Remove & Cleanup**: Completely purges the generated service units and stops the daemon.

### test-system-lifecycle.bash
1. **Verify System Infrastructure**: Confirms configuration directory, write access, and system template unit exist.
2. **Workspace Setup**: Creates a temporary workspace under `/tmp` with `root:ioc` ownership and `2770` permissions. Removed automatically on exit.
3. **Cleanup Previous State**: Removes residual processes and configurations.
4. **Environment Setup & Compilation**: Clones and builds ServiceTestIOC.
5. **Install**: Deploys the `.conf` file to the system configuration directory.
6. **Start**: Launches the IOC and verifies the active systemd system service state.
7. **Status**: Verifies that the status output contains `active`.
8. **View**: Verifies that the conf file content appears in the output.
9. **Restart**: Restarts the service and verifies it remains active.
10. **Stop**: Stops the service, verifies inactive state, then restarts and verifies active state.
11. **List & Socket**: Validates UDS socket creation and verifies list output contains IOC name, socket path, and divider lines.
12. **Console Attach**: Verifies UDS socket permissions, `con` availability, and socket listening state via `ss -lx`.
13. **Channel Access**: Reads PV values iteratively to verify actual EPICS network activity and data flow.
14. **Persistence**: Tests `enable` and `disable` commands to verify systemd boot symlink creation.
15. **Remove & Cleanup**: Completely purges the generated service units and stops the daemon.

### test-error-handling.bash
1. **Setup Mock Environment**: Creates a temporary directory with a mock `con` binary.
2. **Usage and Help**: Verifies `--help`, `-h`, no-args exit 0 and unknown command exits 1.
3. **Missing Target**: Verifies all commands exit 1 when no target IOC name is provided.
4. **Install Error Paths**: Verifies exit 1 for missing conf file and missing system template.
5. **Attach Error Paths**: Verifies exit 1 when conf file is missing for the target IOC.
6. **List Empty**: Verifies exit 0 when no active sockets are present.

### test-system-infra.bash
1. **Setup Test Environment**: Creates a temporary directory with a mock `ioc-runner` source script.
2. **Non-root Rejection**: Verifies exit 1 when executed without root privileges.
3. **Missing procServ**: Verifies exit 1 when procServ is not found in the configured search paths.
4. **Missing ioc-runner Source**: Verifies exit 1 when the source script is not found.
5. **Successful Installation**: Verifies exit 0 and validates group, user, file ownership, and permissions.
6. **Idempotency**: Verifies exit 0 on second run with no duplicate accounts or files.
7. **Backup Rotation**: Verifies that at most 3 backup files are retained per managed file.
