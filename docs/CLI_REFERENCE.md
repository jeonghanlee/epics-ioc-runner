# ioc-runner command reference

This page lists every `ioc-runner` command and option, the modes each one
applies to, and what each one prints and returns.

## Command line and options

`ioc-runner` takes options, one command, and at most one target:

```
ioc-runner [OPTIONS] COMMAND [TARGET]
```

Options can appear before or after the command. The first argument that is not
an option is the command and the second is the target; a third one is an error.
Without a command, `ioc-runner` prints its usage and exits 0. An unknown command
prints the usage and exits 1, and an unknown option prints an error and the
usage and exits 1.

| Option | Long form | Applies to | Effect |
| --- | --- | --- | --- |
| `--local` | `--user` | every command | Local mode: the invoking user's systemd instance, no `sudo` |
| `--container` | | every command | Container mode: root, s6 supervision, no systemd |
| `-f` | `--force` | `generate`, `install`, `log` | `generate` and `install`: answer every question with yes; `log`: follow the log |
| `-n <count>` | `--lines <count>` | `log` | Number of log lines to print, a positive integer; default 40 |
| `-v` | | `list` | Adds PID, CPU, and memory columns |
| `-vv` | | `list` | Adds kernel socket columns |
| `--detach-key <key>` | | `attach` | Console detach key for this connection; default `ctrl-a` |
| `-V` | `--version` | none | Prints the version, git hash, commit date, and install date, then exits 0 |
| `-h` | `--help` | none | Prints the usage, then exits 0 |

The runner enforces these combinations before it does anything else:

- `--local` and `--container` are mutually exclusive.
- `-v` and `-vv` are accepted only with `list`, and `--detach-key` only with
  `attach`; any other command exits 1.
- Other commands accept `-f` and `-n` and ignore them.

An IOC name is 1 to 64 characters from `A-Z`, `a-z`, `0-9`, `_`, and `-`, and
does not start with `-`. Every command that takes an IOC name checks it and
exits 1 with the rule when it does not match. `generate` and `install` take a
directory or a file and check the name derived from it.

## Execution modes and paths

The mode decides where configurations live, which service manager runs the
IOC, and who needs which privilege:

| Mode | Option | Configuration directory | Service | Console socket |
| --- | --- | --- | --- | --- |
| System | none | `/etc/procServ.d` | `epics-@<name>.service`, system instance | `/run/procserv/<name>/control` |
| Local | `--local` | `~/.config/procServ.d` | `epics-@<name>.service`, user instance | `/run/user/<uid>/procserv/<name>/control` |
| Container | `--container` | `/etc/procServ.d` | s6 service under `/run/s6-procserv` | `/run/procserv/<name>/control` |

In system mode, an operator in the `ioc` group runs every command without
`sudo` except `inspect`; the runner calls `sudo systemctl` itself for the
transitions the sudoers policy allows. Container mode runs as root. See
[PERMISSION_MODEL.md](PERMISSION_MODEL.md) for the owners and modes of these
paths.

## The `generate` command

`ioc-runner [--local|--container] [-f] generate <dir>` writes `<dir>/<name>.conf`,
where `<name>` is the directory's basename, for the executable `*.cmd` startup
script in `<dir>`. When there are several, it asks which one to use. The
configuration is staged in `<dir>` and renamed into place, so the directory must
be writable by the invoking user; system and container mode write mode `0660`,
local mode `0600`.

After writing the configuration, `generate` attempts to create
`<dir>/.iocsh_history` if it is absent. It also attempts to set that file's mode
to `0664` in system and container mode, or `0600` in local mode, including when
the file already exists. Creation or permission errors for this history file
are ignored and do not fail configuration generation. These are the runner's
actions during `generate`; iocsh's history-save behavior is described in the
[history-file FAQ](FAQ.md#why-does-ioc-shell-history-report-permission-denied).

| Existing `<name>.conf` | Result |
| --- | --- |
| None | Written; exit 0. |
| Identical content, owned by the invoking user | Rewritten without a question, which restores the mode; exit 0. |
| Identical content, owned by another user | Names that owner (the account name, or the numeric UID when no account exists) and asks before rewriting. `y` rewrites it; a refusal or a closed standard input exits 1 and leaves the file unchanged. |
| Different content | Shows the difference and asks before overwriting. `y` overwrites it; a refusal or a closed standard input exits 1 and leaves the file unchanged. |

- **Forced mode**: `-f` skips every question, for configuration management and
  CI/CD use: it selects the first of several startup scripts in name order and
  rewrites or overwrites an existing configuration.
- **Ownership**: every rewrite replaces the file, so the invoking user becomes
  its owner, and the file takes its group from the directory. In the documented
  shared payload tree (`root:ioc`, mode `2775`, see
  [INSTALL.md](INSTALL.md#shared-deployment-directory-setup-optepics-iocs))
  the group stays `ioc`, so any `ioc` group member can regenerate an IOC another
  member created, including one whose creator's account no longer exists.

## The `install` command

`ioc-runner [--local|--container] [-f] install <target>` copies an IOC
configuration into the configuration directory of the mode. `<target>` is a
`.conf` file, or a directory that holds `<name>.conf` where `<name>` is the
directory's basename; the IOC name is the file name without `.conf`.

The runner checks, in order, and exits 1 at the first failure:

1. The IOC name matches the name rule, and the configuration sets `IOC_USER`,
   `IOC_GROUP`, `IOC_CHDIR`, and `IOC_CMD` with no illegal characters.
   `IOC_USER` and `IOC_GROUP` must be `ioc-srv` and `ioc` in system and
   container mode, and the invoking user and primary group in local mode; a
   configuration generated for another mode fails with `Configuration mode
   mismatch` and the `generate` command that fixes it.
2. System and container mode: `IOC_CHDIR` has no `..` component. When
   `IOC_CHDIR` is not writable by the service account through a `2775` tree
   group-owned by `ioc`, the runner prints a warning and asks `Proceed anyway?
   [y/N]`; `-f` answers yes, and a closed standard input aborts.
3. System mode: the template `/etc/systemd/system/epics-@.service` exists.
4. The service is not `active`, `activating`, or `deactivating`; stop it first.
5. `IOC_PORT`, when set, is the standard socket
   `unix:<user>:<group>:0660:<run_dir>/<name>/control`. System and container
   mode reject any other value; local mode replaces it with a warning. When
   `IOC_PORT` is absent, the runner adds the standard value.
6. The configuration directory exists and is writable. System and container
   mode require an administrator-created directory; local mode creates it.
7. `site.env` in the configuration directory, when present, passes the same
   grammar check as a configuration.
8. An existing `<name>.conf` is overwritten only after `Do you want to
   overwrite it? [y/N]`; `-f` answers yes.

The installed file is written through a temporary file and a rename, mode
`0660` in system and container mode and `0600` in local mode. Then:

- System mode runs `systemctl daemon-reload`.
- Local mode creates the log directory with mode `0750` and deploys the user
  unit template and the logrotate units. When an installed template or
  logrotate unit differs from the shipped one, the runner asks `Update it now?
  [y/N]` on a terminal, keeps the installed file without a terminal, and
  updates it with `-f`. It reloads the user instance only when a unit changed.
- Container mode renders the s6 service directory and rescans it.

On success the runner prints `IOC <name> installed in <mode> mode. Use 'start'
command to run it.` and exits 0. `install` does not start the IOC.

## The `remove` command

`ioc-runner [--local|--container] remove <name>` stops the IOC, disables it,
and deletes its configuration and socket directory. It exits 1 when no
configuration for `<name>` exists in the mode.

- System and local mode stop and disable `epics-@<name>.service`. When the
  service is still `active`, `activating`, or `deactivating` afterwards, the
  runner prints what `systemctl stop` reported and exits 1 without deleting
  anything. When the service is still enabled, it prints a warning and
  continues.
- Container mode stops the s6 service, deletes its service directory, and
  rescans; a service that does not stop aborts the removal the same way.

The runner then deletes `<name>.conf` and `<run_dir>/<name>`, reloads the
service manager in system and local mode, prints `IOC <name> removed.`, and
exits 0. The IOC's own directory, such as `/opt/epics-iocs/<name>`, is not
touched.

## The `start` and `restart` commands

`ioc-runner [--local|--container] start <name>` and `restart <name>` change the
service state and then report whether the IOC came up.

In system and local mode, before calling systemd, the runner:

1. In local mode, reloads the user instance and warns when the installed
   `IOC_PORT` socket differs from the current runtime directory.
2. Resolves procServ and `--logfile` from the effective `ExecStart` of the
   unit.
3. Probes the log directory with a create, one-byte write, sync, and delete
   transaction. System mode runs the probe as the invoking operator, which
   checks the group-writable shared path, not a quota of the service account.
   A failure blocks the transition with `Error: IOC '<name>' <action> was
   blocked: <reason>.` and exit 1.
4. For `restart` of an active IOC, warns when `<name>.conf` changed after the
   unit started, because the restart applies edits that `install` has not
   validated.

After the transition the runner reads the log from its previous end and waits
up to 30 seconds for `All initialization complete`:

| Outcome | Output | Exit |
| --- | --- | --- |
| Initialization completes with no error pattern | `IOC '<name>' successfully started.` | 0 |
| `start` on an IOC that is running and healthy | `IOC '<name>' is already running.` | 0 |
| Error lines after initialization | A warning with the matching lines | 0 |
| Active, but no completion line within the time limit | A warning | 0 |
| A fatal error before `iocInit` | `Error: IOC '<name>' failed to initialize (fatal error before iocInit).` | 1 |
| Repeated restarts | `Error: IOC '<name>' is crash-looping.` or `Error: IOC '<name>' is crash-looping before reaching iocInit.` | 1 |
| The service is not active | `Error: IOC '<name>' failed to start or crashed immediately (State: <state>).` | 1 |

A configuration can extend the error patterns with `CRASH_LOG_PATTERNS_EXTRA`;
an invalid value is ignored for the run with a warning. Direct `systemctl`
commands start and stop the same units but skip the probe and this report.

Container mode has no log file and no probe. The runner creates the socket
directory, starts the s6 service, and waits up to 30 seconds for the control
socket to appear. `start` on an active service prints `IOC '<name>' is already
running.` and exits 0. Otherwise the runner prints `IOC '<name>' successfully
started.` when the socket appears, a warning when the service is up without the socket, and an
error with exit 1 when the service goes down; procServ output is in the
container's standard output.

## The `stop`, `enable`, and `disable` commands

`ioc-runner [--local|--container] stop|enable|disable <name>` exits 1 when no
configuration for `<name>` exists in the mode, and otherwise returns the exit
status of the underlying command:

| Command | System mode | Local mode | Container mode |
| --- | --- | --- | --- |
| `stop` | `sudo systemctl stop epics-@<name>.service` | `systemctl --user stop epics-@<name>.service` | `s6-svc -d -wd` on the service |
| `enable` | `sudo systemctl enable epics-@<name>.service` | `systemctl --user enable epics-@<name>.service` | Deletes the service's `down` file |
| `disable` | `sudo systemctl disable epics-@<name>.service` | `systemctl --user disable epics-@<name>.service` | Creates the service's `down` file |

`enable` and `disable` decide only whether the IOC starts at boot; they do not
start or stop a running IOC.

## The `status` command

`ioc-runner [--local|--container] status <name>` prints the service state and
returns the exit status of the underlying command. System mode runs
`systemctl status epics-@<name>.service` without `sudo`, local mode runs
`systemctl --user status`, and container mode prints `<name>: ` followed by
the `s6-svstat` line, for example `myioc: up (pid 123) 42 seconds`. `status`
does not require the configuration file.

## The `view` command

`ioc-runner [--local|--container] view <name>` prints two sections: the
installed `<name>.conf`, and then the unit as systemd resolves it
(`systemctl cat epics-@<name>.service`) or, in container mode, the rendered s6
`run` script. A missing configuration exits 1.

## The `log` command

`ioc-runner [--local] [-f] [-n <count>] log <name>` prints the last lines of the
IOC's effective procServ log: the `--logfile` path of the deployed unit, the
same file that `start` and `restart` check. `-f` follows the log until you
interrupt it, and `-n <count>` sets the number of lines, 40 by default. The
command exits 1 when the IOC is not installed, when the unit does not resolve a
log file, and when the log file does not exist yet because the IOC has never
started. Container mode has no log file, because IOC output goes to the
container's standard output, and exits 1.

## The `list` command

The `list` command provides a real-time dashboard of all active EPICS IOCs managed by `epics-ioc-runner`. It supports three verbosity levels, each adding progressively deeper system and kernel-level diagnostic data.

### Invocation forms for `list`

```bash
ioc-runner list           # basic view
ioc-runner list -v        # with PID, CPU, memory
ioc-runner list -vv       # with kernel socket internals
ioc-runner --local list   # local user mode
ioc-runner --user list    # alias of --local (identical local-mode path)
ioc-runner --container list   # container mode (root, s6 supervision, no systemd)
```

In container mode the STATUS column comes from `s6-svstat` (`active` while procServ is up, `inactive` otherwise) and the `-v` CPU and MEM columns are summed over procServ and its descendants from `/proc`, since no cgroup accounting exists for an s6 service.

### Output columns by verbosity

#### Default columns without a flag

| Column | Source | Description |
|--------|--------|-------------|
| IOC NAME | Socket path | Derived from the parent directory name under `RUN_DIR` |
| STATUS | `systemctl list-units` | systemd active state (active, inactive, failed, unknown) |
| STARTED | `find -printf %T` | Socket file modification timestamp (proxy for start time) |
| UDS PATH | `find -type s` | Full path to the UNIX domain socket file |

#### Columns added by `-v`

Adds three columns from `systemctl show --property`:

| Column | Source | Description |
|--------|--------|-------------|
| PID | `MainPID` | procServ main process ID. "N/A" if stopped or PID is 0 |
| CPU | `CPUUsageNSec` | Cumulative CPU time converted to seconds with 1 decimal place |
| MEM | `MemoryCurrent` | Current memory usage converted to MB with 1 decimal place |

The sentinel value `18446744073709551615` (UINT64_MAX) and `[not set]` from systemd indicate the property is unavailable, displayed as "N/A".

#### Columns added by `-vv`

Adds seven columns from `ss -lx` and `/proc/net/unix`:

| Column | Source | Description |
|--------|--------|-------------|
| RQ | `ss -lx` Recv-Q | Receive queue depth (same value as CON for listening sockets) |
| SQ | `ss -lx` Send-Q | Send queue depth (backlog limit for listening sockets) |
| REF | `/proc/net/unix` RefCount | Kernel reference count on the socket (hex-to-decimal converted) |
| K-STATE | `/proc/net/unix` St + Flags | Kernel socket state (see state mapping below) |
| INODE | `/proc/net/unix` Inode | Kernel inode number (matches the NODE column in `lsof -U`) |
| PERM | `find -printf %M` | File permission string of the socket file |
| UDS PATH | (moved to last) | Full socket path |

### Kernel socket state mapping

The `K-STATE` column is derived from `/proc/net/unix`, which exposes the kernel `socket_state` enum and the `__SO_ACCEPTCON` flag.

**Source: `include/uapi/linux/net.h`**
```c
typedef enum {
    SS_FREE = 0,            /* not allocated               */
    SS_UNCONNECTED,         /* 1: unconnected to any socket   */
    SS_CONNECTING,          /* 2: in process of connecting    */
    SS_CONNECTED,           /* 3: connected to socket         */
    SS_DISCONNECTING        /* 4: in process of disconnecting */
} socket_state;
```

**State Resolution Logic:**
The listener socket is identified first by checking the `__SO_ACCEPTCON` flag, which takes priority over the `St` field:

| Condition | K-STATE | Description |
|-----------|---------|-------------|
| Flags & 0x10000 | `LISTEN` | Socket is accepting connections (procServ listener) |
| St = 01 | `UNCONN` | Allocated but not connected (SS_UNCONNECTED) |
| St = 02 | `CONNECTING` | Connection in progress (SS_CONNECTING) |
| St = 03 | `ESTAB` | Established connection (SS_CONNECTED) |
| St = 04 | `DISCONN` | Disconnection in progress (SS_DISCONNECTING) |

For a healthy running IOC, the expected state is `LISTEN`. Other states are transient and typically appear only during connection setup or teardown.

### How `list` collects its data

All data is collected in a single pass per source with zero per-IOC subprocess overhead:

1. `find -printf`: socket paths, timestamps, permissions
2. `systemctl list-units`: service active states
3. `ss -lx`: queue depths, connection counts (only if `-vv`)
4. `/proc/net/unix`: ref count, kernel state, inode (only if `-vv`)
5. `systemctl show`: PID, CPU, memory (only if `-v` or `-vv`)

At `-vv`, `ss` (iproute2) is required: a missing or failing `ss` is a
named exit-1 error. Plain and `-v` list do not use `ss` at all.

Each phase streams its output through a `while read` loop that populates O(1) associative arrays (hash maps). The final output loop performs hash map lookups only.

## Console access with `attach` and `monitor`

The `epics-ioc-runner` provides two distinct methods for interacting with an active IOC console via its UNIX Domain Socket. These commands differ fundamentally in their data flow architecture and input handling to prevent operational conflicts.

### Comparison of `attach` and `monitor`

| Feature | `attach` | `monitor` |
|---------|----------|-----------|
| **Data Flow** | Bi-directional (TX / RX) | Uni-directional (RX only) |
| **Input Mapping** | TTY `stdin` to socket | Disconnected / Read-only |
| **Primary Use Case** | Debugging, issuing IOC shell commands | Safe observation, live log tailing |
| **Interleaving Risk** | High (if multiple active clients) | Zero |
| **UDS Tooling** | `con`, `socat` | `con -r`, `socat -u UNIX-CONNECT:<socket> STDOUT` |

**Supported clients**: Both `attach` and `monitor` use only `con` or `socat`; `nc` is not supported. If neither supported client is available, the command fails with an installation hint. For `monitor`, `con` must support `-r`; otherwise `socat` is required.

**Production use**: Prefer `con` for production console access. `socat` is supported as a fallback for ordinary console use, but has not been validated for production workloads with sustained heavy output or sudden bursts of IOC output. General-use support does not establish system stability under those loads. This limitation applies to both `attach` and `monitor`.

### `attach` (read/write mode)

The `attach` command establishes a standard, bi-directional terminal session with the IOC.

- **Usage**: `ioc-runner attach <ioc_name> [--detach-key <key>]`
- **Tool Selection**: Uses `con` when available, otherwise `socat`. If neither is installed, the command fails with an installation hint, even if `nc` is available.
- **Detach**: Press the key shown in the attach banner to detach from the console while leaving the IOC running. The default is `Ctrl-A`. Both `con` and `socat` consume the selected key when it is typed, so it does not reach the IOC shell. Inside pasted text, `con` forwards it to the IOC shell, while `socat` detaches at it. With the default key, `Ctrl-A` cannot move the cursor to the beginning of the input line. The runner passes the same byte value through `con -x` and `socat`'s `escape` option.
- **Custom Key**: `--detach-key ctrl-]` selects `Ctrl-]` for that connection only; it does not change the default for later connections or direct `con` invocations. Names are case-insensitive: `ctrl-a` through `ctrl-z`, plus `ctrl-\`, `ctrl-]`, `ctrl-^`, and `ctrl-_`. `ctrl-t` is rejected because `con` reserves it for diagnostics, and `ctrl-[` because it is the Escape byte that arrow and function keys begin with. Quote the backslash form as `'ctrl-\'` in the shell. Missing or invalid values, or using the option with a command other than `attach`, fail before connection.
- **Ignored Input**: The runner's procServ configuration uses `--ignore=^D^C`, so `Ctrl-C` and `Ctrl-D` are discarded before reaching the IOC. Every other byte, including `Ctrl-]`, is forwarded; procServ converts `^` only before `A` through `Z`, so a `^]` entry would instead drop the printable `^` and `]` characters. If `Ctrl-C` or `Ctrl-D` is selected as the detach key, the client handles it locally and detaches first.
- **Functional Specification**: Routes both standard input (`stdin`) and standard output (`stdout`) between the user's current TTY and the target UNIX Domain Socket.
- **Architecture Constraints**: If multiple users `attach` to the same IOC simultaneously, their keystrokes will be interleaved at the kernel level before reaching the IOC shell. This can lead to malformed commands and hardware misoperation.

### `monitor` (read-only mode)

The `monitor` command establishes a strictly uni-directional session, designed for observing IOC outputs without the risk of accidental input injection.

- **Usage**: `ioc-runner monitor <ioc_name>`
- **Exit**: Press `Ctrl-A` with `con`, or `Ctrl-C` with `socat`. The `--detach-key` option applies only to `attach`.
- **Functional Specification**: Captures and displays the `stdout` from the UNIX Domain Socket while explicitly detaching or blocking the client's `stdin`.
- **Data Flow & Implementation**:
  - Uses the native `-r` (read-only) flag if the primary `con` client supports it.
  - **Fallback Architecture**: If `con` is unavailable or lacks `-r`, the runner uses `socat`. A `con` without `-r` produces a warning when falling back to `socat`. If no read-only client is available, the command fails with an installation hint.
    - **socat**: Executes `socat -u UNIX-CONNECT:<path> STDOUT`. The `-u` (unidirectional) flag transfers data only from the socket to standard output; nothing is read from the terminal.

## The `inspect` command

The `inspect` command provides a deep trace of a specific IOC's UNIX domain socket, mapping file descriptors to their corresponding server and client process contexts. In system mode this command requires root privileges (`sudo`) to access cross-user file descriptors and Netlink socket diagnostics. In local mode it runs unprivileged, because the invoking user owns both the socket and the client processes, and `sudo` must not be used, since it would address the wrong user session.

### Invocation forms for `inspect`

```bash
sudo ioc-runner inspect <ioc_name>
ioc-runner --local inspect <ioc_name>
ioc-runner --container inspect <ioc_name>   # root inside the container
```

### Output sections of `inspect`

#### Socket file descriptors from `lsof -U`

Displays the raw file descriptor allocations for the target socket path.

| Column | Description |
|--------|-------------|
| COMMAND | Process name holding the file descriptor |
| PID | Process ID |
| USER | Owner of the process |
| FD | File descriptor number and access mode (e.g., `3u` for read/write) |
| TYPE | Socket type (`unix`) |
| DEVICE | Device number |
| SIZE/OFF | File size or offset |
| NODE | Kernel inode number (matches the `INODE` column in `list -vv`) |
| NAME | Socket path and protocol state (`(LISTEN)` or `(CONNECTED)`) |

**State Definitions:**
- `(LISTEN)`: Server socket waiting for inbound connections. Typically held by `procServ` and its child IOC processes via FD inheritance.
- `(CONNECTED)`: Server-side socket representing an active session with a client.

#### Server process context from `ps`

Displays the daemon and payload processes associated with the `(LISTEN)` socket.

- **Data Flow**: PIDs are extracted from the `lsof -U` output where the `NAME` contains the target socket path.
- **Purpose**: Verifies the uptime, state, and execution arguments of the `procServ` daemon and the underlying IOC binary.

#### Client process context from `ps`

Displays external processes (e.g., `con`, `socat`) currently attached to the IOC console.

- **Data Flow**:
  1. Identifies the server-side PIDs from `lsof`.
  2. Queries kernel Netlink diagnostics via `ss -x -a -p` to map the target socket path to its peer inode.
  3. Extracts the client PID associated with the local inode of the peer connection.
  4. Filters out known server PIDs to isolate true external clients.
- **Purpose**: Identifies active users or automated scripts occupying the console, bypassing the path-stripping limitation of anonymous client sockets in UNIX domain communications.

#### procServ executable identity check

`inspect` captures systemd `MainPID:starttime`, confirms that `MainPID` owns
the target UDS, and compares the device and inode of `/proc/<MainPID>/exe`
with the procServ path in the effective `ExecStart`. A missing, unreadable,
deleted, or replaced executable produces a warning without changing service
state. If `MainPID:starttime` changes while inspection is running, the result
is reported as an unstable snapshot rather than executable drift.

Before the socket and process report, `inspect` also probes the effective
`--logfile` directory with a create, one-byte write, filesystem sync, and
delete transaction. Local mode runs the probe as the local owner. System mode
runs it with both the effective unit `User=` and `Group=`. Probe failure is a
warning; `inspect` continues and returns success when no independent fatal
inspection error occurs. The already-root system command uses
`/usr/sbin/runuser` for this one probe, so it requires no nested sudoers rule
or additional password prompt.

In container mode `inspect` runs as root, as in system mode, and skips the
log-path probe. Mapping another user's file descriptors inside a container also
requires the `CAP_SYS_PTRACE` capability, for example
`docker run --cap-add SYS_PTRACE`; without it the socket and server sections
report no processes and the executable identity is not attributed.
