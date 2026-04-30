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
3. `test-system-infra.bash`: Verifies that the system accounts, group permissions, directory ACLs, and sudoers policies are correctly established. **Requires execution via `sudo`.**

### Phase 4: System Lifecycle (Deployment)
4. `test-system-lifecycle.bash`: The final integration test. Verifies that the architecture functions correctly under the isolated `ioc-srv` account with strict system-wide permissions. **Crucially, this phase relies on Kernel Netlink diagnostics to map anonymous UDS clients via the `inspect` command, which also enforces execution via `sudo -E`.**

---

## Known Limitations

### NFS root_squash homes (Rocky 8 with autofs)

Phase 4 (`test-system-lifecycle.bash`) cannot run under `sudo` when the
source tree lives on an NFS export with `root_squash`. The test invokes
the source-tree `bin/ioc-runner`, but root maps to `nobody` on the NFS
server and cannot `execve` a user-owned file, aborting at exit code 126
(Permission denied). Phases 1-3 are unaffected: Phase 1 and 2 run as the
invoking user, and Phase 3 was hardened in #44 to drop privileges via
`SUDO_USER` for any access to the user-owned source tree.

To run Phase 4 on such a host, clone the repository onto a local (non-NFS)
filesystem, for example `/opt/<user>/epics-ioc-runner`, and invoke the
test from there. See issue #45 for the full diagnosis.

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
sudo -E bash tests/test-system-lifecycle.bash
```

---
## Verified Behaviors

### 1. Zero-Config & Automation Pipeline
* **Auto-Generation (`generate .`)**: Validates dynamic configuration creation by scanning native EPICS directory structures (`iocBoot/iocName/st.cmd`) without requiring manual file authoring.
* **Directory-based Routing (`install .`)**: Verifies that the runner can implicitly resolve and install configuration artifacts based on the current working directory's basename.
* **2x2 Cross-Validation Matrix**: Ensures absolute routing stability by testing all four deployment combinations:
  1. Manual Gen $\rightarrow$ Explicit Install
  2. Manual Gen $\rightarrow$ Directory Install
  3. Auto Gen $\rightarrow$ Explicit Install
  4. Auto Gen $\rightarrow$ Directory Install

### 2. Lifecycle Workflows (Local & System)
Both `test-local-lifecycle.bash` and `test-system-lifecycle.bash` validate:
* **Setup & Build**: Clones and compiles a test IOC (`ServiceTestIOC`) natively matching standard EPICS layouts (`TOP_DIR` and `BOOT_DIR`).
* **Deployment**: Installs `.conf` and verifies systemd template generation (`@.service`).
* **Service Control**: Verifies state transitions via `start`, `status`, `view`, `restart`, and `stop`.
* **Monitoring**: Validates UNIX Domain Socket (UDS) creation and `list` outputs (PID, CPU, MEM, Recv-Q, Send-Q).
* **Connection & Isolation**: Validates `attach` (r/w access via `con`), `monitor` (read-only isolation securely blocking stdin).
* **Netlink Diagnostics**: In system mode, validates the `inspect` command mapping anonymous UDS clients via Kernel Netlink contexts.
* **EPICS Functionality**: Live PV reads via `caget` ensuring actual Channel Access (CA) broadcasting.
* **Teardown**: Verifies `enable`/`disable` persistence in systemd `.wants` and complete `remove` cleanup.

### 3. Error Handling (`test-error-handling.bash`)
* **Interactive Protections**: Verifies safe aborts and infinite-loop prevention (EOF handling) during non-interactive piping (`< /dev/null`).
* **Validation & Syntax**: Rejects illegal characters, missing executables, and improper directory permissions before taking any native action.
* **Diff Engine**: Evaluates ANSI-colored diff output prompting and force-overwrite (`-f`) bypass mechanisms.

### 4. Infrastructure State (`test-system-infra.bash`)
* **Accounts & Permissions**: Confirms `ioc-srv` user, `ioc` group, and `2770` SetGID collaborative directories.
* **Security Policies**: Validates `/etc/sudoers.d/10-epics-ioc` syntax natively using `visudo`.
* **Policy Ordering**: Confirms the `includedir` directive is the final active line in `/etc/sudoers`, ensuring drop-in NOPASSWD policies are not overridden by trailing user-specific rules.
* **Version Metadata Injection**: Verifies that `git -C` resolves the source repository's HEAD hash regardless of the caller's working directory, ensuring the `RUNNER_GIT_HASH` injection reflects the source repository.
* **Setup Script Path Resolution**: Confirms `SC_DIR` in `setup-system-infra.bash` resolves to the script's directory across plausible invocation forms (from the repository root, from `bin/`, or via absolute path) without depending on absolute-path canonicalization.
