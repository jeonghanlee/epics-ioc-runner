# EPICS IOC Runner - Automated Tests

## Scope

This directory contains source regression, installed conformance, lifecycle,
and error-contract tests for the EPICS IOC runner. This document defines their
classification, ownership, selection, invocation, workspace behavior, and
verified targets.

**Out of scope:** Release-grade multi-host execution on fresh Gate consumers,
including the simulated `root_squash` deployment, is defined in
[`gate/RUNBOOK.md`](../gate/RUNBOOK.md). Its in-place counterpart for one server
is [System Tests on an NFS Home with `root_squash`](#3-system-tests-on-an-nfs-home-with-root_squash)
below. Current implementation and verification
status is tracked in
[`docs/milestone-1.4.2.md`](../docs/milestone-1.4.2.md).

## Required Reading

Before running any suite on a host, read this document in full, then read in
full [`gate/RUNBOOK.md`](../gate/RUNBOOK.md) and
[`docs/INSTALL.md`](../docs/INSTALL.md). The invocation account, `sudo` handling,
binary origin, and path constraints are defined across these documents. Do not
act from one section, a summary, or memory of an earlier run.

## VM Preparation and Handoff

Declare the exact test before requesting or reusing a VM. A raw OS guest for
manual installation must retain the accounts and files that the test expects
to be absent. An installed-conformance or lifecycle test requires its named
infrastructure. A successful SSH connection or administrative `sudo` check
does not establish either test's prerequisites.

Each request and handoff records:

| Field | Required Content |
| --- | --- |
| Purpose | Selected test, mode, binary origin, and expected evidence |
| Guest state | OS/image provenance, resources, required present and absent assets |
| Provider checks | Capacity, guest identity, pinned SSH key, boot completion, access, and agreed observations |
| Requester prerequisites | Required packages, accounts, permissions, service state, and the person or session responsible for preparation |
| Observed readiness | Dated checks and their actual results; pending preparation named separately |
| Restoration and lifetime | Temporary changes to restore, approved corrections to retain, evidence location, and finished notice |

Before each use window, including reuse of a retained VM, the requester checks
the actual guest against the selected test's prerequisites. Record native tool
versions, EPICS paths, account access, and the relevant system or user service
state. Check journald persistence, lingering, timers, or SELinux only where the
selected test depends on them. Do not infer preparation from another VM or an
earlier handoff. If a prerequisite fails, stop dependent tests and record that
failure separately from intentional error cases.

Use a separate administrative connection for teardown. For an account created
exclusively for the test, stop and remove its IOCs, disable its temporary linger,
terminate its login sessions, and stop both `user@<uid>.service` and
`user-runtime-dir@<uid>.service` before deleting the account. Verify that its
processes and `/run/user/<uid>` are absent first. A stopped user manager does not
by itself prove that the runtime unit has stopped; the runtime cleanup helper
can require the account to exist. Preserve the run's evidence and restore the
recorded account-file metadata after deleting only the task-created account.

### Lifecycle IOC build prerequisites

The Local and System lifecycle suites clone and build `ServiceTestIOC`.
`EPICS_BASE` must name a built native EPICS Base installation, and
`EPICS_HOST_ARCH` must match that build. EPICS Base alone is insufficient.
The fixture resolves its support modules under `${EPICS_BASE}/../modules`;
prepare `asyn`, `seq`, `std`, `recsync`, and `autosave` there before running
the suite. Build `asyn` and `seq` before `std`, using the same EPICS Base.
The fixture needs the asyn and std libraries and DBD files, the sequencer's
`snc` compiler and libraries, `recsync/db/reccaster.db`, and
`autosave/db/save_restoreStatus.db`.

The native build also requires Make, C/C++ compilers, Perl, Python 3, and
`re2c`. Install the RPC and SNMP development packages: `libtirpc-dev` and
`libsnmp-dev` on Debian, or `libtirpc-devel` and `net-snmp-devel` on Rocky.
On Rocky 8, `re2c` is available from the PowerTools repository. The suite
writes `configure/RELEASE.local` for EPICS Base and builds the IOC; it does
not build these support modules or install their OS dependencies. Check the
fixture's build requirements again when its external revision changes.

### Original generated startup fixture

Both lifecycle suites also build the original generator at revision
`ee214deedc5594bb93cd0a77d42615b99783bbd0`. Set
`IOC_RUNNER_STARTUP_GENERATOR` to a trusted local Git repository containing
that commit. The shared helper exports the commit into its own workspace,
runs `generate_ioc_structure.bash`, and builds the generated main unchanged.
It requires `makeBaseApp.pl`, Git, tar, make, timeout, and socat.

The generator is supplied by the EPICS-env maintainer through the site's
approved source-access channel; it is not included in this public repository.
Request the `generate_ioc_structure.bash` repository at the exact revision
above. If you lack direct access, request a self-contained Git bundle from
that maintainer, clone it locally, and verify that it contains that commit
before setting `IOC_RUNNER_STARTUP_GENERATOR` to the clone's absolute path.
Record the source identity and bundle digest in the private VM handoff.
The account running the suite must be able to read the repository and its
parent directories. An unrelated generator or a reconstructed main does not
satisfy this prerequisite.

For an approved bundle, substitute its local path and the intended clone path:

```bash
git clone /path/to/generator.bundle /path/to/startup-generator
export IOC_RUNNER_STARTUP_GENERATOR=/path/to/startup-generator
git -C "$IOC_RUNNER_STARTUP_GENERATOR" cat-file -e 'ee214deedc5594bb93cd0a77d42615b99783bbd0^{commit}'
```

The final command must exit 0. Preserve this exported variable when invoking
the System suite with `sudo -E`.

The generated application additionally requires built `retools`, `caPutLog`,
`iocStats`, `pvxs`, `asyn`, and `StreamDevice` modules. The latter two must
provide `drvAsynIPPort.dbd`, `stream.dbd`, and `devaaoStream` support in the
generated DBD. Supply `ASYN` and `STREAM` RELEASE assignments for those built
modules. If their paths differ from the template's
layout, set `IOC_RUNNER_STARTUP_RELEASE` to a readable file containing the
required RELEASE assignments. The helper appends that trusted build input to
the generated `configure/RELEASE.local` after setting `EPICS_BASE`; it does not
change the original generator, main, or installed dependencies. A missing
source or failed build records a required-check failure and skips dependent
checks.

System S27 keeps its operator outside `systemd-journal` and compares a genuine
terminating quote error with a continued quote error. System S36 and Local S41
exercise original generated startup scripts through the selected whole runner.
They retain production startup timing, use task-owned output paths and ports,
and capture runner output, native child records, unit state, and an IOC console
response. Original startup files and task registrations are restored on exit
and TERM; failed workspaces remain available. The suites pin ServiceTestIOC to
`91d42b2ceadec81a065d4cdf35936dbb8d77e202` for their existing lifecycle fixture.

### Native severity and controlled log inputs

The same original generated IOC loads `fixtures/startup-severity.db` and
`fixtures/startup-severity.proto`. An `aao` DOUBLE array with a `%s` output
converter triggers a real StreamDevice error. The suite requires the actual
conversion diagnostic, `STAT`/`SEVR`/`NORD`/`PACT`, readiness order, live child,
unit state and console response. These observations distinguish a failed output
function from a responsive, initialized IOC.

Each of the three placements (separated pre-marker, ordinary initialization,
and post-marker processing) runs under stopped start, active restart and
stopped restart. Active start is a historical-log no-op control. A separate
case terminates the original IOC after severity and readiness, checking that
its native nonzero exit retains priority. Native cases use production timing.

Supplementary cases keep the actual IOC, procServ, systemd and complete runner
while controlling only the external log file read through `tail`. They cover
exact matching, poll order, retained evidence across inode replacement,
copytruncate and regrowth, missing readiness, unreadable logs and partial child
status records. These cases use the existing test timing overrides; their
supplied text is not native module-fault evidence. Their saved original log,
actual child PID and file inode/size trace identify the boundary being controlled.

### Local linger and logout verification

Local S32 observes the invoking user's native linger state. It checks enable
status and advice, unchanged linger and service activity, and enable/disable
links. The suite does not change lingering or require sudo. To cover both
states, prepare a disposable account on a verification VM and have a separate
administrator set lingering off and on before separate whole-suite runs.
Run each Local suite in that account's real SSH session with its own HOME and
runtime directory; run privileged suites from the administrator account.

Logout lifetime requires a separate native observation with the original IOC.
Record the installed systemd version, effective logind/user-manager policy and
supported stop delay. Identify two real SSH/PAM session IDs, close one and then
the last, and observe the user manager and IOC from another account. Classify
any remaining sessions: a separately verified manager-class session is not an
SSH login. Keep process start times and cgroups with PIDs to detect PID reuse.
Use a finite window covering the effective stop delay; infinite or unknown
retention does not establish last-logout termination. Do not stop the manager
manually or create a test-user login while measuring. Restore task-owned
resources through the independent administrator after sealing the observation.

### Full System Setup Prerequisite

Before testing successful `setup-system-infra.bash --full` execution, inspect
`/etc/sudoers` as well as administrative access. The required include must
exist, with no active rule after it, as described in
[Setup diagnostics and partial deployment](../docs/INSTALL.md#setup-diagnostics-and-partial-deployment).
Valid syntax and passwordless administrative sudo alone do not prove this
ordering condition. Tests deliberately exercising a failed condition preserve
and identify that fixture instead of correcting it before execution.

For VMs managed with `ansible-provision`, the existing correction is the
common-role task `Ensure includedir is the final active directive in /etc/sudoers`,
under `roles/common/tasks/main.yml`. Its entry point is
`playbooks/operators/common.yml`, with the repository's group inventory and
the provider-generated host inventory. When only ordering needs correction,
limit execution to that guest and task with `--start-at-task` and `--step`;
decline every other configuration task. Do not apply the complete common role
or IOC setup to a raw manual-install fixture. The task requires
`common_manage_sudo=true`; it leaves a file without the include unchanged,
so an `unchanged` result cannot replace inspection.

For an authorized ordering correction, use this sequence:

1. Confirm that the required include exists exactly once. As root on the
   selected guest, retain a backup of `/etc/sudoers` in a root-owned `0700`
   directory outside `/etc/sudoers.d`, using `cp -a` to preserve metadata.
   Set `SUDOERS_BACKUP` to that backup's absolute path. Record and compare
   its bytes, ownership, mode and extended attributes with the original;
   also record all drop-ins and effective administrative grants. Verify
   `visudo -c` and retain root access for recovery before applying the task.
2. Run only the selected Ansible task described above. If it replaces
   `/etc/sudoers` on a guest with SELinux enabled, immediately run
   `chcon --reference="$SUDOERS_BACKUP" /etc/sudoers` as root on that guest.
   The reference is the original backup, not a copy of the replaced file.
   Compare the complete original context, including its user component;
   checking only the type does not establish preservation.
3. Require unchanged rule text apart from the include's position, unchanged
   drop-ins, original ownership, mode and extended attributes, and no active
   rule after the include. Require full `visudo -c` success. From a fresh
   SSH connection, check administrative sudo without cached credentials
   and compare effective grants with the recorded original grants.
4. Repeat the same selected task and require an `unchanged` result. Repeat
   the metadata, syntax, ordering and fresh-access checks. Record the
   corrected state as the baseline for subsequent tests; distinguish this
   retained correction from temporary test assets restored afterward.

If the task, context restoration or any validation fails, stop dependent
tests and restore the original policy through the retained root access.
First verify the backup against the recorded original bytes and metadata,
and require `visudo -cf "$SUDOERS_BACKUP"` to succeed. Copy it with `cp -a`
to a unique root-owned staging file under `/etc`, then atomically rename that
file over `/etc/sudoers` on the same filesystem. Verify the restored bytes,
ownership, mode and extended attributes, unchanged drop-ins, full `visudo -c`,
and administrative access and grants from a fresh connection. A restored
original can still have the ordering defect; it does not make the VM ready
for successful full-setup tests. Retain the failed checks and restoration
evidence before retrying the correction.

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
- Native setup diagnostics (S27) require a disposable prepared systemd VM,
  the existing `ioc-srv`/`ioc` identity, and native setup tools. The helper uses
  a private copy of `/etc` and redirected destinations, then verifies original
  files and manager state. It retains root-owned evidence under `/var/tmp`.

**Standalone source-fixed suite** (not collected by the dispatcher):

- `test-error-handling.bash`: a source-fixed behavioral and parse suite —
  it parses the `ioc-runner` source for contract guards AND executes the
  source-tree binary against dummy inputs for the validation and error
  paths. It needs no EPICS environment or root privileges.
  Run the complete suite as a dedicated non-root verification-VM account with
  its own native user manager. Its Local install checks can reload that manager
  and enable a rotation timer. Record the account's initial state, then stop and
  disable task-created units and restore its files after the suite.

**Container lifecycle suite** (not collected by the dispatcher):

- `test-container-lifecycle.bash`: the systemd-less `--container` backend,
  driven against a real soft IOC supervised by s6. It runs as root INSIDE a
  container image, so the host dispatcher does not collect it;
  `run-container-tests.bash` runs it per image through `docker run`.

| Script | Category | Binary | Invocation |
| :--- | :--- | :--- | :--- |
| `test-container-lifecycle.bash` | `lifecycle-behavior` | source or installed | inside a container, via `run-container-tests.bash` |
| `test-error-handling.bash` | `error-contract` | source only | `bash tests/test-error-handling.bash` |
| `test-list-states.bash` | `lifecycle-behavior` | source or installed | standalone, root on a prepared verification host |
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

The local and system lifecycle suites create a temporary workspace in shared memory under `/dev/shm/epics-ioc-test.*` and remove it automatically upon successful completion. The standalone list-state suite always retains its evidence under `/tmp/ioc-list-states.*`.

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

# Container lifecycle, one run per systemd-less runtime image.
bash tests/run-container-tests.bash
bash tests/run-container-tests.bash --image jeonghanlee/debian13-epics:latest
```

The separate boot regression uses native `s6-svscan` as PID 1 and restarts
the actual container. It checks absent and existing socket parents, disabled
services, service identity and permissions, and failure before procServ when
a regular file blocks directory creation. It also compares the IOC and
supervisor `PATH`, resolves `caget` through the native IOC console, and
checks that directory preparation ignores an `install` placed earlier in
the inherited `PATH`:

```bash
bash tests/test-container-boot.bash <image>
```

Replace `<image>` with a locally available EPICS image or its immutable image
ID. The boot test requires `socat`, `timeout`, `setpriv`, and native `softIoc`
and `caget` binaries in that image. The test uses the installed runner, adds no capabilities, disables
network access, and removes its own container on exit. Reports remain under
`/tmp/ioc-runner-boot.*`. Set `IOC_RUNNER_BOOT_SOURCE_ROOT` to a separate
checkout to run the same regression against an earlier implementation.

The container harness needs `docker` on the host and images that already ship
s6 (2.13 or later), procServ, con or socat, and an EPICS base providing
`softIoc`. For each image it starts `s6-svscan` on the scan directory so the
IOC output lands on the container stdout, adds `CAP_SYS_PTRACE` for the deep
`inspect` step, and writes one report per image under
`/tmp/ioc-runner-container-tests/`. Run
`setup-system-infra.bash --container` in the image (at build time or before
the suite) so the accounts, the configuration directory, and the scan
directory exist.

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

# Container lifecycle directly, from inside a prepared container.
IOC_RUNNER_TEST_MODE=source bash tests/test-container-lifecycle.bash
```

### Native List-State Supplement

`test-list-states.bash` exercises the full `list -vv` command with native
systemd, procServ, softIoc, and UNIX sockets. It is an opt-in host suite and
is not selected by `run-all-tests.bash`. Its detailed case definitions,
check IDs, and observation limits are in
[LIST_STATES_INVENTORY.md](LIST_STATES_INVENTORY.md).

Use a prepared verification VM and a trusted, root-readable local checkout.
The suite requires Python 3.6 or later at `/usr/bin/python3`, systemd tools,
strace with `delay_enter` support, socat, util-linux (`unshare`, `nsenter`,
`setpriv`), procps (`pgrep`), and iproute2 (`ss`). `/tmp` must permit IOC
execution. `EPICS_BASE` must identify an existing native `softIoc` build;
`EPICS_HOST_ARCH` defaults to `linux-x86_64`. No package or infrastructure
installation is performed by this suite.

Both modes start as root for network namespace and process control. With
`--local-user`, IOC commands and user systemd commands run as the named
existing non-root account, which must already have a running user manager
and local IOC infrastructure with its rotation timer enabled and active.
The suite creates no accounts and does not
change lingering. System mode requires the default `ioc-srv` account, `ioc`
group, and installed system template.

```bash
sudo -E bash -p tests/test-list-states.bash --system
sudo -E bash -p tests/test-list-states.bash --local-user <account>
sudo -E IOC_RUNNER_TEST_MODE=installed bash -p tests/test-list-states.bash --system
REPORT_CATALOG_ONLY=1 bash -p tests/test-list-states.bash --system
```

`IOC_RUNNER_TEST_MODE` selects source (default) or installed for either mode.
The suite uses a unique IOC, task-specific unit overrides, a private network
namespace, and read-only socat clients. It temporarily pauses only its own
procServ and delays its first `listen` syscall to make native states
observable. Cleanup stops its processes and removes its configuration,
runtime directory, and unit overrides. Generated fixture files, IOC logs,
command results, and trace output remain as evidence.

Machine output uses the shared reporting contract. `SKIP` for an unobserved
numeric sentinel or `DISCONN` does not establish coverage, even if the suite
exits 0. The suite makes no container-mode claim. Native execution status is
recorded in the milestone document, separately from catalog validation.

### 3. System Tests on an NFS Home with `root_squash`

The lifecycle suites run in place from an NFS home, including one exported
with `root_squash`. `--local` runs as the invoking user. `--system` with
`IOC_RUNNER_TEST_MODE=installed` runs the runner from `/usr/local/bin` and its
test workspace in `/dev/shm`, so `sudo` touches the NFS tree only to read the
suite scripts (relative path, world-readable).

Run from the repository root as the checkout owner. The dispatcher and the
suites locate their libraries relative to the invocation path, so root reads
them through the inherited working directory. An absolute path is re-traversed
from `/` through the home directory, which `root_squash` denies when the home
is `0700`. Dispatcher and suite code must therefore not canonicalize its own
path (`realpath`, `readlink -f`, a `${PWD}` prefix) before `source` or `bash`.

Procedure for an account with `sudo` rights on such a server:

```bash
# 1. Deploy the candidate ('make install' when the infrastructure exists).
sudo -v
bash bin/run-setup-system-infra.bash --full
/usr/local/bin/ioc-runner -V

# 2. Set EPICS_BASE by sourcing the EPICS environment script of the host.
#    Example: /opt/epics/<env-version>/<os>-<os-version>/<base-version>/
source /opt/epics/1.3.0/rocky-8.10/7.0.10/setEpicsEnv.bash

# 3. Run the system phases against the installed binary.
bash tests/run-all-tests.bash --system --installed
```

`ioc-runner -V` must report the candidate commit before step 3. The dispatcher
asks for the `sudo` password itself when the account has no non-interactive
route. The run passes when it ends with
`ALL SELECTED TEST SUITES COMPLETED SUCCESSFULLY.` and exit status 0.

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
* **Re-generation**: An identical re-generate by the file's owner rewrites the configuration without a question and restores its mode (error-handling S04); a second `ioc` group operator takes over, with `-f`, an identical configuration that root generated, leaving mode 0660 and the operator as owner (system-lifecycle S27).
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
* **Connection & Isolation**: Runs real `ioc-runner attach` and `monitor`
  sessions through `con` and `socat`, using `script(1)` and FIFO input.
  Attach checks cover default Ctrl-A and custom Ctrl-] and Ctrl-B. Monitor
  checks cover con/Ctrl-A and direct socat/Ctrl-C, actual IOC output, and
  input isolation verified through an IOC environment value.
* **Netlink Diagnostics**: Validates the `inspect` command in both modes (unprivileged local inspect included); system mode adds anonymous-peer mapping via Kernel Netlink under root.
* **EPICS Functionality**: Live PV reads via `caget` ensuring actual Channel Access (CA) broadcasting.
* **Teardown**: Verifies `enable`/`disable` persistence in systemd `.wants` and complete `remove` cleanup.

The PTY checks run in local S27 and system S22 against the selected runner
origin and the suite's running ServiceTestIOC. Each case checks the banner,
actual client process name, key-driven exit, exact terminal restoration,
unchanged procServ/IOC PIDs and socket identity, active service, and a command
through a fresh attachment. Custom-key cases also execute an IOC command using
Ctrl-A line editing and reconnect with the default key. A timeout or forced
termination fails the case. Socat monitor's key-driven SIGINT returns 130;
the other successful client exits return 0.

Required test tools are Bash, util-linux `script`, `unshare`, and `mount`,
core utilities, and both con and socat. Local socat checks require enabled
unprivileged user and mount namespaces; system checks use the suite's existing
root privilege. Private bind mounts hide all fixed con search paths for the
socat cases, leaving host installation files unchanged. Local checks do not
invoke sudo. No Python, bubblewrap, or strace dependency is added.

PTY output, client PID/name, runner version, terminal attributes, exit status,
and IOC snapshots are retained in the `/tmp/ioc-console-pty.*` directory named
in the human report. Input FIFOs and client processes are cleaned up. These
checks do not trace individual bytes between client, procServ, and IOC, exercise
old con's fallback, or establish production behavior under heavy IOC output.

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
* **Console Detach Options**: Executes the shipped CLI to reject missing,
  empty, invalid, reserved Ctrl-T, Escape-byte `ctrl-[`, and non-attach option
  forms. All 29 accepted control-key names, uppercase input, option placement,
  and the documented single-quoted backslash form must reach client
  resolution. An unavailable client path bounds these checks before
  connection; they verify parsing, not actual detach.
* **Console Help and Completion**: Checks the attach-only option and Ctrl-A
  default in help, then invokes the shipped completion handler for the option,
  suggested keys, a key prefix, and the IOC target after a supplied key.
* **Complete Help and Completion**: Compares all 15 command names and 14 option
  spellings, every IOC-target command across System/Local/user-alias/Container
  forms, directory precedence and access, path/list suggestions, and numeric
  value positions. The shared helper loads the complete registration script
  in fresh Bash processes; installed-copy checks use a separately deployed file.
* **Console Client Selection**: Runs the shipped attach and monitor commands
  inside a private mount namespace that hides every fixed con search path,
  with a mirrored PATH that omits socat. Both commands must exit 1 with the
  installation hint before any connection. Without unprivileged user and mount
  namespaces, the required isolation-tools check fails and the client checks
  SKIP. Old con without read-only support is not exercised.

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
* **Staged System Setup**: Invokes the shipped staging launcher through real
  sudo, redirects only final deployment paths to `/tmp`, and verifies that the
  installed runner retains the original checkout commit.
* **Candidate Transfer**: Runs the shipped push driver against a real Git
  repository, replacing only SSH transport, and verifies both identical and
  externally changed destination states.
* **Test Library Self-Tests**: Runs the reporting, record-validator, and
  reporting-counts self-tests under `tests/lib/` as the invoking user and
  requires each to exit 0. The reporting self-test derives its catalog and
  suite-dimension expectations from `tests/reporting-counts.csv` and its own
  combination list.
* **Native Setup Diagnostics**: Executes the whole setup with native tools and
  real root/non-root callers. It verifies help/parser ordering, deployment
  denials, a real invalid logrotate policy, preservation of the preceding
  baseline, valid deployment, and temporary-file cleanup. The helper rejects
  symlinks at write paths and their parents, clears inherited tool environment,
  and checks original protected files and manager state after namespace exit.
  See [the check inventory](SOURCE_REGRESSION_INVENTORY.md#native-setup-diagnostics).

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
