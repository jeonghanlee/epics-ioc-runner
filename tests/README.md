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

By default, all lifecycle tests create a temporary workspace in shared memory under `/dev/shm/epics-ioc-test.*` (falling back to `/tmp` if unavailable) and remove it automatically upon successful completion to keep the system clean.

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

## Test Execution

**1. Run All Tests (Master Script - Recommended)**
Executes tests in the recommended SOP sequence. 

```bash
# Safe mode: Runs Phase 1 and 2 only (Requires EPICS_BASE)
bash tests/run-all-tests.bash

# System mode: Runs all Phases 1 through 4 (Requires EPICS_BASE, ioc group, and sudo)
bash tests/run-all-tests.bash --system
```

**2. Run Individual Test Suites**
If you need to isolate and run a specific phase instead of the master script:

* **Phase 1: Error Handling** (No EPICS environment or root required)
    ```bash
    bash tests/test-error-handling.bash
    ```
* **Phase 2: Local Lifecycle** (Requires `EPICS_BASE`)
    ```bash
    bash tests/test-local-lifecycle.bash
    ```
* **Phase 3: System Infrastructure** (Requires `sudo`)
    ```bash
    sudo bash tests/test-system-infra.bash
    ```
* **Phase 4: System Lifecycle** (Requires `EPICS_BASE` and `ioc` group)
    ```bash
    bash tests/test-system-lifecycle.bash
    ```

---

## Verified Behaviors

### Lifecycle Workflows (Local & System)
Both `test-local-lifecycle.bash` and `test-system-lifecycle.bash` validate the complete end-to-end IOC management process:
* **Setup & Build**: Compiles a test IOC (`ServiceTestIOC`) in a temporary `/dev/shm` workspace.
* **Deployment**: Installs the `.conf` file and verifies the systemd `@.service` template generation.
* **Service Control**: Executes and verifies `start`, `status`, `view`, `restart`, and `stop` commands.
* **Connectivity & Monitoring**: Validates UNIX Domain Socket creation, `list` command outputs (including PID, CPU, MEM), and `con` attachability.
* **EPICS Functionality**: Performs live PV reads using `caget` to ensure functional Channel Access.
* **Persistence & Teardown**: Tests `enable`/`disable` boot persistence, followed by a complete `remove` and workspace cleanup.

### Error Handling (`test-error-handling.bash`)
* Validates command-line arguments, missing targets, and invalid configuration syntax.
* Ensures safe failure paths for missing `.conf` files or missing systemd templates.

### Infrastructure State (`test-system-infra.bash`)
* **Accounts & Permissions**: Confirms the existence of the `ioc-srv` user, `ioc` group, and strict `2770` SetGID directories.
* **Security Policies**: Validates the syntax and safety of the deployed `/etc/sudoers.d/10-epics-ioc` file using `visudo`.
