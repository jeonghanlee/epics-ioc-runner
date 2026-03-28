# EPICS IOC Integrated Management Architecture

## 1. Architecture Overview
This architecture defines a robust, dependency-free environment for managing EPICS IOCs. It adheres to the KISS and DRY principles by utilizing POSIX-standard tools, traditional Unix security (`sudoers`), native Systemd Template Units (`@.service`), and a lightweight C++ terminal emulator (`con`).

### 1.1. High-Level Architecture
```text
[ Trained Engineers (ioc group) ]
        |
        |-- (1. Config) --> [ /etc/procServ.d/myioc.conf (Shared config dir, 2770) ]
        |
        |-- (2. Control) --> [ sudo systemctl start epics-@myioc.service ]
                                                |
                                                V
                                        [ systemd ] ---> Reads /etc/systemd/system/epics-@.service
                                                | (Spawn & Manage)
                                                V
                                        [ procServ Daemon (ioc-srv) ]
                                                |
                                                |---> Run --> [ EPICS IOC ]
                                                |
                                                |---> Comm --> [ UNIX Domain Socket ]
                                                                     A
        |-- (3. Console Access) --> [ con Utility ] -----------------|
```

---

## 2. Access Control and Security

### 2.1. System Accounts
* **`ioc-srv`**: A dedicated, fully isolated system account with no login shell (`/sbin/nologin`) and no home directory (`/nonexistent`). Runs all `procServ` daemons to prevent shell-based exploits.
* **`ioc` group**: The management group for trained engineers. Grants passwordless write access to `/etc/procServ.d/` via strict SetGID (`2770`) permissions, ensuring other unauthorized users cannot read or modify configurations.

### 2.2. Sudoers Configuration
Instead of relying on fragmented Polkit rules or overly broad wildcards, service control is delegated explicitly and strictly via `/etc/sudoers.d/10-epics-ioc`. 

*Note: The absolute path to `systemctl` may vary depending on the Linux distribution (e.g., `/usr/bin/systemctl`). The deployment script resolves this automatically.*

```bash
# Allow trained engineers to manage ONLY EPICS template services
%ioc ALL=(root) NOPASSWD: /bin/systemctl start epics-@*.service, \
                          /bin/systemctl stop epics-@*.service, \
                          /bin/systemctl restart epics-@*.service, \
                          /bin/systemctl status epics-@*.service, \
                          /bin/systemctl enable epics-@*.service, \
                          /bin/systemctl disable epics-@*.service, \
                          /bin/systemctl daemon-reload
```

---

## 3. Core Components

### 3.1. Systemd Template Unit (`epics-@.service`)
The core of this architecture is a single, static systemd template file located at `/etc/systemd/system/epics-@.service`. When an engineer starts an instance (e.g., `epics-@myioc.service`), systemd dynamically loads the corresponding environment variables from `/etc/procServ.d/myioc.conf`. This eliminates the need for dynamic generator scripts and multiple daemon reloads.

### 3.2. ioc-runner (Wrapper Script)
A pure Bash utility to manage IOC configurations. It copies user-defined `.conf` files to the target directory and issues the appropriate `systemctl` commands. It inherently supports the symmetry of this architecture by allowing both system-wide deployment (`sudo systemctl`) and isolated local testing (`systemctl --user` via the `--local` flag) using the exact same template logic.

### 3.3. con (Local Console Access)
A C++ based terminal emulator replacing `socat` or `minicom`. It provides seamless terminal session control by connecting directly to the secure UNIX Domain Sockets created by `procServ`.
