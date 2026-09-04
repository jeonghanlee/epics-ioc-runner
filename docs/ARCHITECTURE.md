# EPICS IOC Integrated Management Architecture

## 1. Architecture Overview
This architecture defines a robust, dependency-free environment for managing EPICS IOCs. It adheres to the KISS and DRY principles by utilizing standard Linux tools, traditional Unix security (`sudoers`), native Systemd Template Units (`@.service`), and a lightweight C++ terminal emulator (`con`).

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

`setup-system-infra.bash` emits one of two forms based on the local sudo version (OS-agnostic, decided by `sudo -V`). The canonical regex form (sudo >= 1.9.10) achieves parity with `validate_ioc_name` in `bin/ioc-runner`:

```
# Allow trained engineers to manage ONLY EPICS template services
%ioc ALL=(root) NOPASSWD: /usr/bin/systemctl ^start   epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\.service$, \
                          /usr/bin/systemctl ^stop    epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\.service$, \
                          /usr/bin/systemctl ^restart epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\.service$, \
                          /usr/bin/systemctl ^status  epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\.service$, \
                          /usr/bin/systemctl ^enable  epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\.service$, \
                          /usr/bin/systemctl ^disable epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\.service$, \
                          /usr/bin/systemctl ^daemon-reload$
```

On hosts with sudo < 1.9.10, the deployment script falls back to a glob form (`epics-@*.service`) with a generation-time `WARN` line and a residual-risk comment in the deployed file. The boundary is the `%ioc` sudoers gate, not the argument pattern; see [`PERMISSION_MODEL.md`](PERMISSION_MODEL.md).

---

## 3. Core Components

### 3.1. Systemd Template Unit (`epics-@.service`)
The core of this architecture is a single, static systemd template file located at `/etc/systemd/system/epics-@.service`. When an engineer starts an instance (e.g., `epics-@myioc.service`), systemd dynamically loads the corresponding environment variables from `/etc/procServ.d/myioc.conf`. This eliminates the need for dynamic generator scripts and multiple daemon reloads.

### 3.2. ioc-runner (Wrapper Script)
A pure Bash utility to manage IOC configurations. It copies user-defined `.conf` files to the target directory and issues the appropriate `systemctl` commands. It inherently supports the symmetry of this architecture by allowing both system-wide deployment (`sudo systemctl`) and isolated local testing (`systemctl --user` via the `--local` flag) using the exact same template logic. A third backend, selected by `--container`, drives the same configuration through s6 supervision for systemd-less container images (section 3.4).

### 3.3. con (Local Console Access)
A C++ based terminal emulator replacing traditional serial tools. It provides seamless terminal session control by connecting directly to the secure UNIX Domain Sockets created by `procServ`.
*Note: If `con` is unavailable, the architecture is designed to automatically fall back to standard data pipes like `socat` or `nc`.*

### 3.4. s6 Service Directory (`--container` mode)
Container images run without systemd. In container mode the runner supervises `procServ` through s6: the container entrypoint runs `s6-svscan` as PID 1 on the scan directory `/run/s6-procserv`, and every installed IOC owns one service directory beneath it.

```text
[ root inside the container ]
        |
        |-- (1. Config)  --> [ /etc/procServ.d/myioc.conf (root:ioc, 2770 directory) ]
        |
        |-- (2. install) --> [ /run/s6-procserv/myioc/{run,down,timeout-kill} ] --> s6-svscanctl -a
        |
        |-- (3. Control) --> [ s6-svc -u / -d / -r ]
                                        |
                                        V
                                [ s6-supervise ] ---> execs ./run
                                        | (Spawn & Restart)
                                        V
                                [ procServ (ioc-srv) --logfile=- ] --> stdout --> container stdout
                                        |
                                        |---> Run  --> [ EPICS IOC ]
                                        |---> Comm --> [ /run/procserv/myioc/control ]
```

* `install` renders `run`, a POSIX sh script that execs `s6-setuidgid ioc-srv procServ ...` with the same procServ argument list as the systemd unit template except that the log goes to stdout (`--logfile=-`); `timeout-kill` (90000 ms, the SIGTERM-to-SIGKILL grace period, systemd's `TimeoutStopSec` default); and, for a new service, `down` (disabled until `enable`). A static source check keeps the three procServ argument renderings (system unit, local unit, s6 run script) in agreement.
* `start`, `stop`, and `restart` are `s6-svc -u`, `-d`, and `-r` with a bounded wait; readiness is the control socket appearing under `/run/procserv/<ioc>`, which the runner creates (`0770 ioc-srv:ioc`) in place of systemd's `RuntimeDirectory`. `enable` and `disable` only remove or create `down` (start at container boot); `status` and `list` read `s6-svstat`; `list -v` sums CPU and memory over procServ and its descendants from `/proc`; `view` prints the rendered `run`; `remove` brings the service down, deletes the directory, and prunes the supervisor with `s6-svscanctl -h`.
* s6-supervise restarts a dead procServ after its fixed one-second delay (the unit template's `Restart=always` / `RestartSec=2`); procServ itself keeps supervising the IOC child.
* The mode is root-only: the runner rejects a non-root EUID, and the `ioc` group holds no operator role (it remains the owning group of the socket directory). There is no sudoers policy, unit template, log directory, or logrotate policy; IOC output is read from the container stdout (for example `docker logs`).
* Requirements: s6 2.13 or later in `PATH` (`s6-svscan`, `s6-supervise`, `s6-svc`, `s6-svstat`, `s6-svscanctl`, `s6-setuidgid`); the runner does not use s6-overlay's `/init` or s6-rc. `setup-system-infra.bash --container` prepares the image at build time (accounts, configuration directory, CLI, completion, scan directory skeleton); see [`INSTALL.md`](INSTALL.md).
