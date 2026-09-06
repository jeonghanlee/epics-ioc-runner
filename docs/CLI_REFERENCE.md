# EPICS IOC Runner — CLI Technical Reference

This document provides the technical specifications, data flow architecture, and kernel-level integration details for the diagnostic commands provided by the `epics-ioc-runner`.

---

## 1. IOC List Command (`list`)

The `list` command provides a real-time dashboard of all active EPICS IOCs managed by `epics-ioc-runner`. It supports three verbosity levels, each adding progressively deeper system and kernel-level diagnostic data.

### Usage

```bash
ioc-runner list           # basic view
ioc-runner list -v        # with PID, CPU, memory
ioc-runner list -vv       # with kernel socket internals
ioc-runner --local list   # local user mode
ioc-runner --user list    # alias of --local (identical local-mode path)
ioc-runner --container list   # container mode (root, s6 supervision, no systemd)
```

In container mode the STATUS column comes from `s6-svstat` (`active` while procServ is up, `inactive` otherwise) and the `-v` CPU and MEM columns are summed over procServ and its descendants from `/proc`, since no cgroup accounting exists for an s6 service.

### Output Columns

#### Default (no flag)

| Column | Source | Description |
|--------|--------|-------------|
| IOC NAME | Socket path | Derived from the parent directory name under `RUN_DIR` |
| STATUS | `systemctl list-units` | systemd active state (active, inactive, failed, unknown) |
| STARTED | `find -printf %T` | Socket file modification timestamp (proxy for start time) |
| UDS PATH | `find -type s` | Full path to the UNIX domain socket file |

#### Verbose (`-v`)

Adds three columns from `systemctl show --property`:

| Column | Source | Description |
|--------|--------|-------------|
| PID | `MainPID` | procServ main process ID. "N/A" if stopped or PID is 0 |
| CPU | `CPUUsageNSec` | Cumulative CPU time converted to seconds with 1 decimal place |
| MEM | `MemoryCurrent` | Current memory usage converted to MB with 1 decimal place |

The sentinel value `18446744073709551615` (UINT64_MAX) and `[not set]` from systemd indicate the property is unavailable, displayed as "N/A".

#### Full Detail (`-vv`)

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

### Kernel Socket State Mapping

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


### Data Collection Architecture

All data is collected in a single pass per source with zero per-IOC subprocess overhead:

1. `find -printf` → socket paths, timestamps, permissions
2. `systemctl list-units` → service active states
3. `ss -lx` → queue depths, connection counts (only if `-vv`)
4. `/proc/net/unix` → ref count, kernel state, inode (only if `-vv`)
5. `systemctl show` → PID, CPU, memory (only if `-v` or `-vv`)

At `-vv`, `ss` (iproute2) is required: a missing or failing `ss` is a
named exit-1 error. Plain and `-v` list do not use `ss` at all.

Each phase streams its output through a `while read` loop that populates O(1) associative arrays (hash maps). The final output loop performs hash map lookups only.

---

## 2. IOC Inspect Command (`inspect`)

The `inspect` command provides a deep trace of a specific IOC's UNIX domain socket, mapping file descriptors to their corresponding server and client process contexts. In system mode this command requires root privileges (`sudo`) to access cross-user file descriptors and Netlink socket diagnostics. In local mode it runs unprivileged — the invoking user owns both the socket and the client processes — and `sudo` must not be used, since it would address the wrong user session.

### Usage

```bash
sudo ioc-runner inspect <ioc_name>
ioc-runner --local inspect <ioc_name>
ioc-runner --container inspect <ioc_name>   # root inside the container
```

### Output Sections

#### 1. UNIX Domain Socket FDs (`lsof -U`)

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

#### 2. Server Process Context (`ps`)

Displays the daemon and payload processes associated with the `(LISTEN)` socket.

- **Data Flow**: PIDs are extracted from the `lsof -U` output where the `NAME` contains the target socket path.
- **Purpose**: Verifies the uptime, state, and execution arguments of the `procServ` daemon and the underlying IOC binary.

#### 3. Client Process Context (`ps`)

Displays external processes (e.g., `con`, `socat`, `nc`) currently attached to the IOC console.

- **Data Flow**:
  1. Identifies the server-side PIDs from `lsof`.
  2. Queries kernel Netlink diagnostics via `ss -x -a -p` to map the target socket path to its peer inode.
  3. Extracts the client PID associated with the local inode of the peer connection.
  4. Filters out known server PIDs to isolate true external clients.
- **Purpose**: Identifies active users or automated scripts occupying the console, bypassing the path-stripping limitation of anonymous client sockets in UNIX domain communications.

#### 4. procServ Executable Identity

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

## 3. Lifecycle Preflight Diagnostics

`start` and `restart` resolve procServ and `--logfile` from the effective
systemd `ExecStart`. They run the same create-write-sync-delete log-path probe
before calling systemd, then use that exact logfile for readiness and startup
failure scans. Probe failure blocks the requested transition.

In system mode the ordinary authorized operator runs the probe before the
restricted `sudo systemctl` transition. This checks the established
group-writable shared-filesystem path; it is not a service-UID quota check.
Local mode runs the probe as the local owner. Direct `systemctl` commands
remain supported but bypass these diagnostics and readiness reporting.

Container mode has no log-path probe and no log-file scan: procServ writes
to stdout, the launch command is the rendered s6 `run` script, and readiness
is the control socket appearing under `/run/procserv/<ioc>` after `s6-svc`
reports the process up. `inspect` in container mode runs as root like system
mode; mapping another user's file descriptors inside a container additionally
requires the `CAP_SYS_PTRACE` capability (for example
`docker run --cap-add SYS_PTRACE`), otherwise sections 1 and 2 report no
processes and the executable identity is not attributed.

## 4. Console Access Commands (`attach` vs `monitor`)

The `epics-ioc-runner` provides two distinct methods for interacting with an active IOC console via its UNIX Domain Socket. These commands differ fundamentally in their data flow architecture and input handling to prevent operational conflicts.

### Command Comparison

| Feature | `attach` | `monitor` |
|---------|----------|-----------|
| **Data Flow** | Bi-directional (TX / RX) | Uni-directional (RX only) |
| **Input Mapping** | TTY `stdin` → Socket | Disconnected / Read-only |
| **Primary Use Case** | Debugging, issuing IOC shell commands | Safe observation, live log tailing |
| **Interleaving Risk** | High (if multiple active clients) | Zero |
| **UDS Tooling** | `con`, `socat`, `nc` | `con -r`, `socat -u UNIX-CONNECT:<socket> STDOUT`, `nc -U <socket> < /dev/null` |

---

### `attach` (Read/Write Mode)

The `attach` command establishes a standard, bi-directional terminal session with the IOC.

- **Usage**: `ioc-runner attach <ioc_name>`
- **Functional Specification**: Routes both standard input (`stdin`) and standard output (`stdout`) between the user's current TTY and the target UNIX Domain Socket.
- **Architecture Constraints**: If multiple users `attach` to the same IOC simultaneously, their keystrokes will be interleaved at the kernel level before reaching the IOC shell. This can lead to malformed commands and hardware misoperation.

### `monitor` (Read-Only Mode)

The `monitor` command establishes a strictly uni-directional session, designed for observing IOC outputs without the risk of accidental input injection.

- **Usage**: `ioc-runner monitor <ioc_name>`
- **Functional Specification**: Captures and displays the `stdout` from the UNIX Domain Socket while explicitly detaching or blocking the client's `stdin`.
- **Data Flow & Implementation**:
  - Uses the native `-r` (read-only) flag if the primary `con` client supports it.
  - **Fallback Architecture**: If `con` is not installed, the runner selects `socat`, then `nc` (an `nc` build must support `-U`). If `con` is installed but lacks `-r`, `monitor` falls back to `socat` when available, otherwise `nc`, and prints a warning naming the substitute tool. Each fallback enforces the unidirectional flow itself:
    - **socat**: Executes `socat -u UNIX-CONNECT:<path> STDOUT`. The `-u` (unidirectional) flag transfers data only from the socket to standard output; nothing is read from the terminal.
    - **nc**: Executes `nc -U <path> < /dev/null`. Standard input is redirected from `/dev/null`, so no keystroke can reach the console. The `nc` fallback is variant-sensitive, and the runner's probe (an `nc` whose help advertises `-U`) cannot tell variants apart: `nc.openbsd` (the default `nc` on Debian) is not a supported monitor fallback — install `con` (preferred) or `socat` for monitor use.
