# EPICS IOC Runner - Automated Tests

This directory contains automated integration and error handling tests to verify both local user-level and system-wide systemd management architectures.

## Recommended Test Sequence (SOP)

To ensure maximum reliability and prevent unintended system-wide outages, follow this specific testing order depending on your current task.

### Phase 1: Logic & Unit Validation (Development)
Execute these tests during the initial development phase or when modifying the internal logic of the `ioc-runner` script.
1. **test-error-handling.bash**: Verifies that the script's input validation and error paths work as expected. No EPICS environment or root privileges are required.

### Phase 2: Functional Validation (User-level)
Execute this test to verify the full IOC management lifecycle without affecting system-wide services.
2. **test-local-lifecycle.bash**: Validates the end-to-end workflow (install, start, attach, list, stop, remove) within the current user's systemd session. Requires an active EPICS environment.

### Phase 3: Infrastructure & Integration (Deployment)
Execute these tests when deploying to a new server or when modifying the infrastructure setup script (`setup-system-infra.bash`).
3. **test-system-infra.bash**: Verifies that the system accounts, group permissions, directory ACLs, and sudoers policies are correctly established. **Requires root privileges**.
4. **test-system-lifecycle.bash**: The final integration test. Verifies that the architecture functions correctly under the isolated `ioc-srv` account with strict system-wide permissions. **Requires prior infrastructure setup and 'ioc' group membership**.

---

## Debugging and Workspace Retention

By default, all lifecycle tests create a temporary workspace under `/tmp/epics-ioc-test.*` and remove it automatically upon successful completion to keep the system clean.

### Automatic Retention
If a test fails or the script terminates unexpectedly (Abort), the workspace is **automatically retained**. This allows engineers to inspect generated `.conf` files, build logs, or the compiled IOC environment immediately.

### Manual Retention (`KEEP_WORKSPACE`)
To force the script to keep the workspace regardless of the test result (e.g., for manual auditing of a successful build), set the `KEEP_WORKSPACE` environment variable to `1`:

```bash
# Force retention for system-wide lifecycle test
KEEP_WORKSPACE=1 bash tests/test-system-lifecycle.bash

# Force retention for local lifecycle test
KEEP_WORKSPACE=1 bash tests/test-local-lifecycle.bash
```

*Note: When a workspace is retained, you are responsible for manually removing the directory after inspection.*

---

## Test Execution Guide

| Mode | Command | Requirements |
| :--- | :--- | :--- |
| **Local Lifecycle** | `bash tests/test-local-lifecycle.bash` | `EPICS_BASE` loaded |
| **System Lifecycle** | `bash tests/test-system-lifecycle.bash` | `EPICS_BASE`, `ioc` group |
| **Error Handling** | `bash tests/test-error-handling.bash` | None (Mocked) |
| **System Infra** | `sudo bash tests/test-system-infra.bash` | Root/Sudo |

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
