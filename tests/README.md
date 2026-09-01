# EPICS IOC Runner - Automated Tests

## Scope

This directory contains source regression, installed conformance, lifecycle,
and error-contract tests for the EPICS IOC runner. This document defines their
classification, ownership, selection, invocation, workspace behavior, and
verified targets.

**Out of scope:** Release-grade multi-host execution is defined in
[`gate/RUNBOOK.md`](../gate/RUNBOOK.md). Current implementation and verification
status is tracked in
[`docs/milestone-46790f9.md`](../docs/milestone-46790f9.md).

## Test Classification

Every check has three independent classifications. Each axis answers a
different question and cannot substitute for another.

### Test Category

The category identifies the verification target and its valid execution
context. The canonical category definitions are in
[REPORTING_CONTRACT.md](REPORTING_CONTRACT.md).

| Category | Verification Target |
| :--- | :--- |
| `source-regression` | Behavior and source contracts of the shipped source tree |
| `installed-conformance` | State and policy of an installed, configured host |
| `lifecycle-behavior` | IOC lifecycle behavior through the selected runner binary |
| `error-contract` | Rejection, validation, and error behavior of the selected runner binary |

### Check Kind

The check kind identifies a check's role in the result contract. The canonical
definitions of `REQUIRED`, `PREREQUISITE`, `APPLICABILITY`, `BEHAVIOR`, and
`INTEGRITY` are in [REPORTING_CONTRACT.md](REPORTING_CONTRACT.md). Check kind
does not state how the evidence was obtained.

### Test Method

This section is the canonical definition of test method for this repository.
The method identifies how a check obtains its evidence.

| Method | Catalog Value | Evidence | Valid Claim |
| :--- | :--- | :--- | :--- |
| Real-path execution | `real-path` | Executes the shipped product path; only an outermost boundary such as filesystem target, HTTP transport, or clock may be redirected | May support a behavior-verification claim |
| Direct state inspection | `direct-inspection` | Reads actual source, configuration, installed-host, prerequisite, or fixture state without executing product behavior | Supports only the directly observed state or contract, not runtime behavior |
| Hand-built reproduction | `hand-built-reproduction` | Reimplements or reconstructs an internal product path in test code or a fixture instead of executing the shipped path | Invalid as verification evidence and must not appear in an accepted check catalog |

The three axes remain independent: one suite may contain multiple test methods
when all checks share one category and execution boundary. Different methods
are recorded as separate checks or STEPs; they do not create a new suite or
selector by themselves. A `BEHAVIOR` check may use either accepted method, but
the method limits its claim. Real-path execution may establish runtime
behavior; direct state inspection establishes only the state or contract it
observes. A hand-built reproduction cannot establish any verification result.
Tests may redirect or mock only the outermost boundary; they must not replace
an internal function or any other span of the product path under test.

## Test Organization

Lifecycle invocation varies along two selection axes. Source regression uses
one exclusive dispatcher selection, and error handling remains standalone.

**Permission mode** (set by `run-all-tests.bash --local` / `--system`):
- `--local`: the local lifecycle, as the current user. No `sudo`, no `ioc` group.
- `--system`: the system infrastructure check then the system lifecycle, via
  `sudo` and systemd.

**Runner binary origin** (set by `run-all-tests.bash --source` / `--installed`):
- `--source` (default): the source tree binary (`bin/ioc-runner`) — the
  developer inner loop, testing just-edited code.
- `--installed`: `/usr/local/bin/ioc-runner` — the deployed binary, for
  validating a finished build or a production install.

**Exclusive source-regression suite**:

- `--source-regression`: runs `test-source-regression.bash` by itself. It
  cannot be combined with a permission or runner selector.
- The suite starts through `sudo bash`. Setup runs as root with only its outer
  write targets redirected to an isolated temporary directory; source and Git
  operations run as the invoking identity from `SUDO_USER`.

**Standalone source-fixed suite** (not collected by the dispatcher):

- `test-error-handling.bash`: a source-fixed behavioral and parse suite —
  it parses the `ioc-runner` source for contract guards AND executes the
  source-tree binary against dummy inputs for the validation and error
  paths. It needs no EPICS environment or root privileges.

| Script | Category | Binary | Invocation |
| :--- | :--- | :--- | :--- |
| `test-error-handling.bash` | `error-contract` | source only | `bash tests/test-error-handling.bash` |
| `test-local-lifecycle.bash` | `lifecycle-behavior` | source or installed | via `run-all-tests.bash --local` |
| `test-source-regression.bash` | `source-regression` | source only | via `run-all-tests.bash --source-regression` |
| `test-system-infra.bash` | `installed-conformance` | n/a | via `run-all-tests.bash --system` |
| `test-system-lifecycle.bash` | `lifecycle-behavior` | source or installed | via `run-all-tests.bash --system` |

The system lifecycle runs under root for system-wide systemd control and
cross-user anonymous-peer mapping (`inspect` via Kernel Netlink); `sudo -E`
preserves the EPICS environment across that boundary.

Local lifecycle S29 declares an OS applicability check before its user-journal
prerequisite. Rocky ordinary-user runs close the complete S29 group as NA under
the journal least-privilege policy; applicable systems retain the real
user-unit journal and monitor-input isolation path.

## Result Reporting Contract

See [REPORTING_CONTRACT.md](REPORTING_CONTRACT.md) for the stable catalog,
result dimensions, terminal states, machine-readable grammar, invariants, and
producer boundary.

Normal suite and dispatcher invocations emit the operator report without the
full machine-record sequence. For a retained machine interface, set
`REPORT_MACHINE_OUTPUT=1`, capture standard output as machine records, and
capture standard error as the human report. `REPORT_CATALOG_ONLY=1` takes
precedence and still emits exactly one `CATALOG` record on standard output.

The dispatcher validates every child machine file with
`lib/test-record-validator.bash` before accepting or forwarding it. In machine
mode, its standard output contains only validated child blocks in selected
suite order; its own messages and child human output use standard error.

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

Invoke the master script as the current non-root user. It invokes `sudo`
internally for source-regression and system phases. Do not prefix the master
command with `sudo`: a nested `sudo` invocation sets `SUDO_USER` to `root` and
violates the source-regression invoking-user boundary.

Before system phases are captured, the dispatcher checks `sudo -n true`.
Accounts with a non-interactive sudo route continue without a credential
prompt; otherwise the dispatcher runs `sudo -v` before capture so any required
authentication remains attached to the operator terminal.

```bash
# Default: both modes, source binary.
# Requires EPICS_BASE, 'ioc' group membership, sudo access, and lsof.
# A persistent user journal enables the monitor-isolation step; otherwise it SKIPs with a WARN (the same class covers absent logrotate, socat, or softIoc).
bash tests/run-all-tests.bash

# Local lifecycle, edited source (no sudo or 'ioc' group required).
bash tests/run-all-tests.bash --local --source

# System lifecycle (infra + lifecycle), edited source.
bash tests/run-all-tests.bash --system --source

# Local lifecycle against the installed binary.
bash tests/run-all-tests.bash --local --installed

# System lifecycle against the installed binary.
bash tests/run-all-tests.bash --system --installed

# Source-tree setup, metadata, Git, and path regression checks only.
bash tests/run-all-tests.bash --source-regression
```

The development-to-production flow maps directly onto these commands:
develop and iterate with `--source`, validate a finished install with
`--installed` around the install step (`setup-system-infra.bash` /
`make install`), run `--source-regression` for source-tree setup and metadata
changes, and run the error suite once per code change.

### 2. Run Individual Test Suites
To isolate one suite manually:

```bash
# Standalone static error suite (always source).
bash tests/test-error-handling.bash

# Source regression directly. The dispatcher form above is preferred.
sudo bash tests/test-source-regression.bash

# One lifecycle suite directly; IOC_RUNNER_TEST_MODE selects the binary.
IOC_RUNNER_TEST_MODE=source    bash tests/test-local-lifecycle.bash
sudo -E IOC_RUNNER_TEST_MODE=installed bash tests/test-system-lifecycle.bash

# System infrastructure check.
sudo bash tests/test-system-infra.bash
```

### 3. System Tests on an NFS Home with `root_squash`

The lifecycle suites run in place from an NFS home, including one exported
with `root_squash`. `--local` runs as the invoking user. `--system` with
`IOC_RUNNER_TEST_MODE=installed` runs the runner from `/usr/local/bin` and its
test workspace in `/dev/shm`, so `sudo` touches the NFS tree only to read the
suite scripts (relative path, world-readable).

Lifecycle `source` mode would `execve` the runner from its NFS source path, which
`root_squash` blocks — but running the source binary under `sudo` is out of
scope for lifecycle verification. The source-regression suite has a different
boundary: root owns suite startup and real setup execution, while every source
and Git operation runs as `SUDO_USER`. See `docs/INSTALL.md` for the deployment
mechanism.

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
* **Monitoring**: Validates UNIX Domain Socket (UDS) creation and `list` outputs (PID, CPU, MEM, RQ/SQ queue columns).
* **Connection & Isolation**: Validates `attach` (r/w access via `con`), `monitor` (read-only isolation securely blocking stdin).
* **Netlink Diagnostics**: Validates the `inspect` command in both modes (unprivileged local inspect included); system mode adds anonymous-peer mapping via Kernel Netlink under root.
* **EPICS Functionality**: Live PV reads via `caget` ensuring actual Channel Access (CA) broadcasting.
* **Teardown**: Verifies `enable`/`disable` persistence in systemd `.wants` and complete `remove` cleanup.

The system lifecycle suite also installs a dedicated healthy `softIoc`, sends
`SIGKILL` only to its verified child, and proves procServ recovery through a
new ready child while the unit remains active and the procServ `MainPID` and
systemd `NRestarts` remain unchanged.

It also installs a dedicated configuration-parser probe through the shipped
runner. The probe proves that install validation, runtime lookup, and the real
systemd `EnvironmentFile` consumer agree for surrounding spaces and tabs,
single and double quotes, CRLF, empty values, embedded `=`, later duplicate
values, and escaped regular-expression backslashes. Probe removal must leave
no active unit or installed configuration.

### 3. Error Handling (`test-error-handling.bash`)
* **Interactive Protections**: Verifies safe aborts and infinite-loop prevention (EOF handling) during non-interactive piping (`< /dev/null`).
* **Validation & Syntax**: Rejects illegal characters, missing executables, and improper directory permissions before taking any native action.
* **Configuration Parser**: Drives spaces, tabs, matching quotes, CRLF, empty values, embedded `=`, duplicates, and double-quoted escaped regex backslashes through real file-direct installs; unsupported multiline, continuation, and unmatched-quote forms must preserve the prior target. A separate logic-level STEP extracts the exact shipped parser and reader definitions, requires one valid definition of each, and verifies both reader APIs against independent whitespace, quote, empty, and missing-key expectations.
* **Diff Engine**: Evaluates ANSI-colored diff output prompting and force-overwrite (`-f`) bypass mechanisms.

### 4. Source Regression (`test-source-regression.bash`)

* **Setup Invocation**: Executes the shipped setup path from the repository
  root, its `bin/` directory, and an unrelated current directory.
* **Version Identity**: Verifies real checkout and unrelated-checkout stamps,
  commit and install dates, and live version lookup.
* **Relocated Checkout**: Drives setup, live version, and injection through
  clean, modified, and unwritable-index checkout fixtures.
* **Deployment Backup**: Distinguishes stamp-only redeployment from a real
  runner source change.
* **Source Boundary**: Verifies the root-to-invoking-user Git boundary and test
  path-safety contracts.
* **SELinux Deployment Boundary**: Runs the shipped full setup in a private
  mount namespace with only filesystem and SELinux tool boundaries isolated;
  verifies preflight failures, both policy deployments, and final-context
  rejection.

### 5. Infrastructure State (`test-system-infra.bash`)

* **Accounts & Permissions**: Confirms `ioc-srv` user, `ioc` group, and `2770` SetGID collaborative directories.
* **Security Policies**: Validates `/etc/sudoers.d/10-epics-ioc` syntax natively using `visudo`.
* **Policy Ordering**: Confirms the `includedir` directive is the final active line in `/etc/sudoers`, ensuring drop-in NOPASSWD policies are not overridden by trailing user-specific rules.
* **Installed Files**: Confirms installed runner, completion, systemd,
  logrotate, configuration, and log paths with their required ownership and
  permissions.
* **SELinux Contexts**: On an active SELinux host, requires
  `/usr/sbin/matchpathcon -V` to accept the deployed sudoers and logrotate
  policies; records the checks as not applicable when SELinux is inactive.
