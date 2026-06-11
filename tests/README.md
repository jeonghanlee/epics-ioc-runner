# EPICS IOC Runner - Automated Tests

This directory contains automated integration and error handling tests to verify both local user-level and system-wide systemd management architectures.

## Test Organization

Test runs vary along two independent axes, plus one standalone static check.

**Permission mode** (set by `run-all-tests.bash --local` / `--system`):
- `--local`: the local lifecycle, as the current user. No `sudo`, no `ioc` group.
- `--system`: the system infrastructure check then the system lifecycle, via
  `sudo` and systemd.

**Runner binary origin** (set by `run-all-tests.bash --source` / `--installed`):
- `--source` (default): the source tree binary (`bin/ioc-runner`) — the
  developer inner loop, testing just-edited code.
- `--installed`: `/usr/local/bin/ioc-runner` — the deployed binary, for
  validating a finished build or a production install.

**Standalone static check** (run on its own, not through the dispatcher):
- `test-error-handling.bash`: parses the `ioc-runner` source for input
  validation and error paths. It reads the source as a file rather than
  executing it, so it is always source-fixed and needs no EPICS environment or
  root privileges.

| Script | Axis | Binary | Invocation |
| :--- | :--- | :--- | :--- |
| `test-error-handling.bash` | standalone static | source only | `bash tests/test-error-handling.bash` |
| `test-local-lifecycle.bash` | local lifecycle | source or installed | via `run-all-tests.bash --local` |
| `test-system-infra.bash` | system infra | n/a | via `run-all-tests.bash --system` |
| `test-system-lifecycle.bash` | system lifecycle | source or installed | via `run-all-tests.bash --system` |

The system lifecycle relies on Kernel Netlink diagnostics to map anonymous UDS
clients via the `inspect` command, which is why it runs under `sudo -E`.

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

### Runner Binary Selection
Both lifecycle suites resolve the `ioc-runner` binary under test from
`IOC_RUNNER_TEST_MODE`:

| Value | Binary |
| :--- | :--- |
| (unset) or `source` | source tree (`bin/ioc-runner`) |
| `installed` | `/usr/local/bin/ioc-runner`, or stop if absent |

The unset default is the source tree for both suites, matching the developer
inner loop. An NFS + `root_squash` host, where root cannot execute a
user-owned source binary, runs system tests with `IOC_RUNNER_TEST_MODE=installed`.
A missing binary, or an unrecognized value, stops the script before STEP 1 with
an explicit error.

`run-all-tests.bash` sets this from `--source` (default) / `--installed`. Both
suites print the resolved path and its `-V` output (version, git hash, commit
and install dates) before STEP 1, so captured output always shows which binary
ran.

---

## Test Execution

### 1. Run Tests (Master Script - Recommended)
The master script composes the two axes. Both flags are optional; the default is
all permission modes against the source binary.

```bash
# Default: both modes, source binary.
# Requires EPICS_BASE, 'ioc' group membership, sudo access, and lsof.
# A persistent user journal enables STEP 24 coverage; otherwise that step SKIPs with a WARN.
bash tests/run-all-tests.bash

# Local lifecycle, edited source (no sudo or 'ioc' group required).
bash tests/run-all-tests.bash --local --source

# System lifecycle (infra + lifecycle), edited source.
bash tests/run-all-tests.bash --system --source

# Local lifecycle against the installed binary.
bash tests/run-all-tests.bash --local --installed

# System lifecycle against the installed binary.
bash tests/run-all-tests.bash --system --installed
```

The eight-stage development-to-production scenario maps directly onto these
commands: stages 2-3 use `--source`, stages 4-5 and 7-8 use `--installed`,
stage 6 is the install step (`setup-system-infra.bash` / `make install`), and
the static error suite runs once per code change.

### 2. Run Individual Test Suites
To isolate one suite manually:

```bash
# Standalone static error suite (always source).
bash tests/test-error-handling.bash

# One lifecycle suite directly; IOC_RUNNER_TEST_MODE selects the binary.
IOC_RUNNER_TEST_MODE=source    bash tests/test-local-lifecycle.bash
sudo -E IOC_RUNNER_TEST_MODE=installed bash tests/test-system-lifecycle.bash

# System infrastructure check.
sudo bash tests/test-system-infra.bash
```

### 3. System Suite on an NFS Home with `root_squash`
Both suites run in place from an NFS home, including one exported with
`root_squash`. `--local` runs as the invoking user. `--system` with
`IOC_RUNNER_TEST_MODE=installed` runs the runner from `/usr/local/bin` and its
test workspace in `/dev/shm`, so `sudo` touches the NFS tree only to read the
suite scripts (relative path, world-readable). Verified 74/74 on `alsucl-psrv3`
(Rocky 8) and both VM gates.

`source` mode would `execve` the runner from its NFS source path, which
`root_squash` blocks — but running the source binary under `sudo` is out of
scope (production never does it). See `docs/INSTALL.md` for the mechanism.

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
