# EPICS IOC management architecture

## IOC management architecture
This architecture defines a robust, dependency-free environment for managing EPICS IOCs. It adheres to the KISS and DRY principles by utilizing standard Linux tools, traditional Unix security (`sudoers`), native Systemd Template Units (`@.service`), and a lightweight C++ terminal emulator (`con`).

### Components and data flow
```text
[ Trained Engineers (ioc group) ]
        |
        |-- (1. Config) --> [ /etc/procServ.d/myioc.conf (shared configuration directory) ]
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

## Access control and security

### System service accounts
* **`ioc-srv`**: A dedicated, fully isolated system account with no login shell (`/sbin/nologin`) and no home directory (`/nonexistent`). Runs all `procServ` daemons to prevent shell-based exploits.
* **`ioc` group**: The management group for trained engineers. Its members can write IOC configurations in `/etc/procServ.d/`, which users outside the group cannot read or modify; [`PERMISSION_MODEL.md`](PERMISSION_MODEL.md) gives the owners and modes.

### Restricted sudoers configuration
Instead of relying on fragmented Polkit rules or overly broad wildcards, service control is delegated explicitly and strictly via `/etc/sudoers.d/10-epics-ioc`.

*Note: The absolute path to `systemctl` may vary depending on the Linux distribution (e.g., `/usr/bin/systemctl`). The deployment script resolves this automatically.*

`setup-system-infra.bash` emits one of two forms based on the local sudo version (OS-agnostic, decided by `sudo -V`). The canonical regex form (sudo >= 1.9.10) achieves parity with `validate_ioc_name` in `bin/ioc-runner`:

```
# Allow trained engineers to manage ONLY EPICS template services
%ioc ALL=(root) NOPASSWD: /usr/bin/systemctl ^start epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\.service$, \
                          /usr/bin/systemctl ^stop epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\.service$, \
                          /usr/bin/systemctl ^restart epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\.service$, \
                          /usr/bin/systemctl ^status epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\.service$, \
                          /usr/bin/systemctl ^enable epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\.service$, \
                          /usr/bin/systemctl ^disable epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\.service$, \
                          /usr/bin/systemctl ^daemon-reload$
```

On hosts with sudo < 1.9.10, the deployment script falls back to a glob form (`epics-@*.service`) with a generation-time `WARN` line and a residual-risk comment in the deployed file. The boundary is the `%ioc` sudoers gate, not the argument pattern; see [`PERMISSION_MODEL.md`](PERMISSION_MODEL.md).

---

## Core management components

### systemd template unit (`epics-@.service`)
The core of this architecture is a single, static systemd template file located at `/etc/systemd/system/epics-@.service`. When an engineer starts an instance (e.g., `epics-@myioc.service`), systemd dynamically loads the corresponding environment variables from `/etc/procServ.d/myioc.conf`. This eliminates the need for dynamic generator scripts and multiple daemon reloads.

### ioc-runner wrapper script
A pure Bash utility to manage IOC configurations. It copies user-defined `.conf` files to the target directory and issues the appropriate `systemctl` commands. It inherently supports the symmetry of this architecture by allowing both system-wide deployment (`sudo systemctl`) and isolated local testing (`systemctl --user` via the `--local` flag) using the exact same template logic. A third backend, selected by `--container`, drives the same configuration through s6 supervision for systemd-less container images (see [s6 service directory](#s6-service-directory---container-mode)).

### con for local console access
A C++ based terminal emulator replacing traditional serial tools. It provides seamless terminal session control by connecting directly to the secure UNIX Domain Sockets created by `procServ`.
Both `attach` and `monitor` support only `con` and the `socat` fallback. Monitor requires `con -r` or `socat`; if no suitable client is available, console access fails. **Production use**: Prefer `con` for production console access. `socat` is supported as a fallback for ordinary console use, but has not been validated for production workloads with sustained heavy output or sudden bursts of IOC output. General-use support does not establish system stability under those loads. This limitation applies to both `attach` and `monitor`.

### s6 service directory (`--container` mode)
Container images run without systemd. In container mode the runner supervises `procServ` through s6: the container entrypoint runs `s6-svscan` as PID 1 on the scan directory `/run/s6-procserv`, and every installed IOC owns one service directory beneath it.

```text
[ root inside the container ]
        |
        |-- (1. Config)  --> [ /etc/procServ.d/myioc.conf (shared configuration directory) ]
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
* `start`, `stop`, and `restart` are `s6-svc -u`, `-d`, and `-r` with a bounded wait; readiness is the control socket appearing under `/run/procserv/<ioc>`, which the runner creates in place of systemd's `RuntimeDirectory`. `enable` and `disable` only remove or create `down` (start at container boot); `status` and `list` read `s6-svstat`; `list -v` sums CPU and memory over procServ and its descendants from `/proc`; `view` prints the rendered `run`; `remove` brings the service down, deletes the directory, and prunes the supervisor with `s6-svscanctl -h`.
* s6-supervise restarts a dead procServ after its fixed one-second delay (the unit template's `Restart=always` / `RestartSec=2`); procServ itself keeps supervising the IOC child.
* The mode is root-only: the runner rejects a non-root EUID, and the `ioc` group holds no operator role (it remains the owning group of the socket directory). There is no sudoers policy, unit template, log directory, or logrotate policy; IOC output is read from the container stdout (for example `docker logs`).
* Requirements: s6 2.13 or later in `PATH` (`s6-svscan`, `s6-supervise`, `s6-svc`, `s6-svstat`, `s6-svscanctl`, `s6-setuidgid`); the runner does not use s6-overlay's `/init` or s6-rc. `setup-system-infra.bash --container` prepares the image at build time (accounts, configuration directory, CLI, completion, scan directory skeleton); see [`INSTALL.md`](INSTALL.md).
