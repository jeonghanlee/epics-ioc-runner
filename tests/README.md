# EPICS IOC Runner - Automated Tests

This directory contains automated integration and error handling tests to verify both local user-level and system-wide systemd management architectures.

## Recommended Test Sequence (Standard Operating Procedure - SOP)

To ensure maximum reliability and prevent unintended system-wide outages, follow this specific testing order depending on your current task.

### Phase 1: Logic & Unit Validation (Development)
Execute these tests during the initial development phase or when modifying the internal logic of the `ioc-runner` script.
1. `test-error-handling.bash`: Verifies that the script's input validation and error paths work as expected. No EPICS environment or root privileges are required.

### Phase 2: Functional Validation (User-level)
Execute this test to verify the full IOC management lifecycle without affecting system-wide services.
2. `test-local-lifecycle.bash`: Validates the end-to-end workflow (install, start, attach, list, stop, remove) within the current user's systemd session. Requires an active EPICS environment.

### Phase 3: Infrastructure & Integration (Deployment)
Execute these tests when deploying to a new server or when modifying the infrastructure setup script (`setup-system-infra.bash`).
3. `test-system-infra.bash`: Verifies that the system accounts, group permissions, directory ACLs, and sudoers policies are correctly established. Requires root privileges.

### Phase 4: System Lifecycle (Deployment)
4. `test-system-lifecycle.bash`: The final integration test. Verifies that the architecture functions correctly under the isolated `ioc-srv` account with strict system-wide permissions. Requires prior infrastructure setup and 'ioc' group membership.

---

## Debugging and Workspace Retention

By default, all lifecycle tests create a temporary workspace in shared memory under `/dev/shm/epics-ioc-test.*` and remove it automatically upon successful completion.

### Automatic Retention
If a test fails or the script terminates unexpectedly, the workspace is **automatically retained** for inspection of generated files and logs.

### Manual Retention (`KEEP_WORKSPACE`)
To force retention regardless of the result, set the `KEEP_WORKSPACE` environment variable to `1`:

```bash
KEEP_WORKSPACE=1 bash tests/run-all-tests.bash --local
```

---

## Test Execution

### 1. Run Tests (Master Script - Recommended)
The master script executes tests in the recommended SOP sequence and supports selective execution via arguments.

```bash
# Default: Runs ALL phases (1 through 4)
# Requires EPICS_BASE, 'ioc' group membership, and sudo access.
bash tests/run-all-tests.bash

# Local Mode: Runs Phase 1 and 2 only
# Requires EPICS_BASE. No sudo or 'ioc' group required.
bash tests/run-all-tests.bash --local

# System Mode: Runs Phase 3 and 4 only
# Requires EPICS_BASE, 'ioc' group, and sudo access.
bash tests/run-all-tests.bash --system
```

### 2. Run Individual Test Suites
If you need to isolate and run a specific phase manually:

#### Phase 1: Error Handling
```bash
bash tests/test-error-handling.bash
```
#### Phase 2: Local Lifecycle
```bash
bash tests/test-local-lifecycle.bash
```
#### Phase 3: System Infrastructure
```bash
sudo bash tests/test-system-infra.bash
```
#### Phase 4: System Lifecycle
```bash
bash tests/test-system-lifecycle.bash
```

---

## Verified Behaviors

### Lifecycle Workflows (Local & System)
Both `test-local-lifecycle.bash` and `test-system-lifecycle.bash` validate:
* **Setup & Build**: Compiles a test IOC (`ServiceTestIOC`) in a temporary workspace.
* **Deployment**: Installs `.conf` and verifies systemd template generation.
* **Service Control**: Verifies `start`, `status`, `view`, `restart`, and `stop`.
* **Monitoring**: Validates UDS creation, `list` outputs (PID, CPU, MEM), and `con` attachability.
* **EPICS Functionality**: Live PV reads via `caget` for Channel Access verification.
* **Teardown**: Verifies `enable`/`disable` persistence and complete `remove` cleanup.

### Error Handling (`test-error-handling.bash`)
* Validates CLI arguments, missing targets, and invalid configuration syntax.
* Ensures safe failure paths for missing files or templates.

### Infrastructure State (`test-system-infra.bash`)
* **Accounts & Permissions**: Confirms `ioc-srv` user, `ioc` group, and `2770` SetGID directories.
* **Security Policies**: Validates `/etc/sudoers.d/10-epics-ioc` syntax using `visudo`.
