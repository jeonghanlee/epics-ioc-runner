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
```

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
3. `ss -lx` → queue depths, connection counts
4. `/proc/net/unix` → ref count, kernel state, inode
5. `systemctl show` → PID, CPU, memory (only if `-v` or `-vv`)

Each phase streams its output through a `while read` loop that populates O(1) associative arrays (hash maps). The final output loop performs hash map lookups only.

---

## 2. IOC Inspect Command (`inspect`)

The `inspect` command provides a deep trace of a specific IOC's UNIX domain socket, mapping file descriptors to their corresponding server and client process contexts. This command requires root privileges (`sudo`) to access cross-user file descriptors and Netlink socket diagnostics.

### Usage

```bash
sudo ioc-runner inspect <ioc_name>
sudo ioc-runner --local inspect <ioc_name>
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

## 3. Console Access Commands (`attach` vs `monitor`)

The `epics-ioc-runner` provides two distinct methods for interacting with an active IOC console via its UNIX Domain Socket. These commands differ fundamentally in their data flow architecture and input handling to prevent operational conflicts.

### Command Comparison

| Feature | `attach` | `monitor` |
|---------|----------|-----------|
| **Data Flow** | Bi-directional (TX / RX) | Uni-directional (RX only) |
| **Input Mapping** | TTY `stdin` → Socket | Disconnected / Read-only |
| **Primary Use Case** | Debugging, issuing IOC shell commands | Safe observation, live log tailing |
| **Interleaving Risk** | High (if multiple active clients) | Zero |
| **UDS Tooling** | `con`, `socat`, `nc` | `con -r`, `socat -u`, `nc -d` |

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
  - **Fallback Architecture**: If `con` is unavailable or lacks read-only support, the runner enforces unidirectional data flow using the built-in features of alternative tools:
    - **socat**: Executes `socat -u STDIN,readbytes=0 UNIX-CONNECT:<path>`, utilizing the `-u` (unidirectional) flag and explicitly reading 0 bytes from `stdin`.
    - **nc**: Executes `nc -U <path> -d`, utilizing the `-d` flag to prevent reading from `stdin`.
