# EPICS IOC Integrated Management Architecture

## 1. Architecture Overview
This architecture defines a robust, dependency-free environment for managing EPICS IOCs. It adheres to the KISS and DRY principles by utilizing POSIX-standard tools (`AWK`, `Bash`), traditional Unix security (`sudoers`), Systemd Generators, and a lightweight C++ terminal emulator (`con`).

### 1.1. High-Level Architecture
```text
[ Trained Engineers (ioc group) ]
        │
        ├── (1. Config) ──> [ /etc/procServ.d/ (Shared config dir, 2775) ]
        │                       │
        │                       ▼
        │                 [ Systemd Generator (AWK) ] ──> Generates transient .service files
        │                       │
        ├── (2. Control) ──> [ sudo systemctl ] ──> [ systemd ]
        │                                               │ (Spawn & Manage)
        │                                               ▼
        │                                       [ procServ Daemon (ioc-srv) ]
        │                                               │
        │                                               ├───> Run ──> [ EPICS IOC ]
        │                                               │
        │                                               └───> Comm ──> [ UNIX Domain Socket ]
        │                                                                    ▲
        └── (3. Local Access) ──> [ con Utility ] ───────────────────────────┘
```

---

## 2. Access Control and Security

### 2.1. System Accounts
* **`ioc-srv`**: A dedicated system account with no login shell (`/sbin/nologin`). Runs all `procServ` daemons.
* **`ioc` group**: The management group for trained engineers. Grants write access to `/etc/procServ.d/`.

### 2.2. Sudoers Configuration
Instead of relying on fragmented Polkit rules, service control is delegated explicitly via `/etc/sudoers.d/10-ioc`.
```bash
# Allow trained engineers to manage ONLY procServ-related services
%ioc ALL=(root) NOPASSWD: /bin/systemctl start procserv-*, \
                          /bin/systemctl stop procserv-*, \
                          /bin/systemctl restart procserv-*, \
                          /bin/systemctl status procserv-*, \
                          /bin/systemctl daemon-reload
```

---

## 3. Core Components

### 3.1. Systemd Generator (AWK + Bash)
A native systemd generator executable located in `/usr/lib/systemd/system-generators/`. During the system boot or `daemon-reload`, it parses simple configuration files in `/etc/procServ.d/` using `AWK` and dynamically translates them into transient systemd `.service` files.

### 3.2. manage-procs (Wrapper Script)
A pure Bash utility to manage IOC configurations. It creates the config file and invokes `sudo systemctl daemon-reload` to trigger the Systemd Generator. It also invokes the `con` tool for native console access to the UNIX Domain Socket.

### 3.3. con (Local Console Access)
A C++ based terminal emulator replacing `socat` or `minicom` to provide seamless terminal session control to the UDS.
