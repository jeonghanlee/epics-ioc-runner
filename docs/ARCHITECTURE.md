# EPICS IOC management architecture

## IOC management architecture
The runner coordinates IOC configuration, service control and console access using the components below. It adheres to the KISS and DRY principles by utilizing standard Linux tools, traditional Unix security (`sudoers`), native Systemd Template Units (`@.service`), and a lightweight C++ terminal emulator (`con`).

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
* **`ioc-srv`**: The default System service account. When this account is absent, setup creates it with `/sbin/nologin` as its shell and `/nonexistent` as its home path. It runs the System procServ daemons and their IOC child processes.
* **`ioc` group**: The management group for trained engineers. Its members can write IOC configurations in `/etc/procServ.d/`, which users outside the group cannot read or modify; [`PERMISSION_MODEL.md`](PERMISSION_MODEL.md) gives the owners and modes.

### Restricted sudoers configuration
Service control is delegated through `/etc/sudoers.d/10-epics-ioc`.
Its argument restrictions depend on the installed sudo version.

*Note: Setup and the runner use `/usr/bin/systemctl` for systemd operations. Setup checks that this fixed path is executable.*

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

On hosts with sudo < 1.9.10, the deployment script falls back to a glob form
(`epics-@*.service`). That form can match additional unit arguments and
authorize control of unrelated services. The
[permission model](PERMISSION_MODEL.md#residual-risk-on-sudo--1910-hosts)
describes this broader delegation.

---

## Core management components

### Setup launcher

`bin/run-setup-system-infra.bash` stages the setup sources before invoking
`setup-system-infra.bash` as root. Its privileged shell initializes
`stage_dir` to an empty value, then assigns the output of
`/usr/bin/mktemp -d /tmp/ioc-runner-system-setup.XXXXXX`. Command-line
arguments and forwarded environment variables do not set this internal value.

The cleanup handler checks the path string before removal. An empty value
requires no removal; a value matching `/tmp/ioc-runner-system-setup.*` is
passed to `rm -rf --`. Any other nonempty value is rejected with exit status 1.
This is an internal defensive check on the path string, not a check of the
resolved filesystem location. The fixed `mktemp` invocation supplies a
matching path on success; the public CLI provides no alternate staging-path
argument for exercising the rejection branch.

### systemd template unit (`epics-@.service`)
The core of this architecture is a single, static systemd template file located at `/etc/systemd/system/epics-@.service`. When an engineer starts an instance (e.g., `epics-@myioc.service`), systemd dynamically loads the corresponding environment variables from `/etc/procServ.d/myioc.conf`. Each System IOC instance uses the shared template rather than a separately generated unit file.

### ioc-runner wrapper script
A pure Bash utility to manage IOC configurations. It copies user-defined `.conf` files to the target directory and issues the appropriate `systemctl` commands. System mode uses the system manager, while `--local` uses the invoking user's manager. Their templates launch procServ with the same argument structure and mode-specific identities, paths and permissions. Privileged System operations use sudo for non-root callers. A third backend, selected by `--container`, drives the same configuration through s6 supervision for systemd-less container images (see [s6 service directory](#s6-service-directory---container-mode)).

#### Internal log-path probe

`probe_effective_log_path` checks whether the logfile directory supports a
create-write-sync-delete transaction. Its optional service identity is either
absent or a complete user/group pair. The helper rejects a lone user or group
with return status 1 before attempting the transaction.

System `inspect` passes both values only after the identity resolver has
validated them. An incomplete identity is rejected by that resolver;
`inspect` warns and skips the probe. Local `inspect` and System/Local
`start` and `restart` call the helper without either identity value.
Container `inspect` skips the logfile probe. These callers do not supply
a partial pair, so the helper's rejection is an internal defensive condition
rather than a separately reachable CLI failure.

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
* On every service launch, `run` prepares the socket parent from the installed `IOC_PORT` with the configured service user and group and mode `0770`, before dropping privileges. This includes automatic startup without an earlier CLI `start`. Preparation failure exits 1 before procServ and reports the directory in the container log.
* s6-supervise restarts a dead procServ after its fixed one-second delay (the unit template's `Restart=always` / `RestartSec=2`); procServ itself keeps supervising the IOC child.
* The mode is root-only: the runner rejects a non-root EUID, and the `ioc` group holds no operator role (it remains the owning group of the socket directory). Container setup does not deploy a sudoers policy, systemd unit template, IOC log directory, or logrotate policy; IOC output is read from the container stdout (for example `docker logs`).
* Requirements: s6 2.13 or later in `PATH` (`s6-svscan`, `s6-supervise`, `s6-svc`, `s6-svstat`, `s6-svscanctl`, `s6-setuidgid`); the runner does not use s6-overlay's `/init` or s6-rc. `setup-system-infra.bash --container` prepares the image at build time (accounts, configuration directory, CLI, completion, scan directory skeleton); see [`INSTALL.md`](INSTALL.md).
