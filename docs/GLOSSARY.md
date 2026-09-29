# Glossary

This page defines the terms used in the EPICS IOC Runner operator book.
The linked pages give configuration values, command syntax, and procedures.

## Components and execution modes

- **EPICS (Experimental Physics and Industrial Control System):** The
  control-system software used by the IOCs that this runner manages.
- **IOC (Input/Output Controller):** An EPICS application that runs device
  support and a database of records. The runner manages each IOC as a named
  service.
- **iocsh:** The IOC shell that executes startup commands and accepts
  commands through the IOC console.
- **ioc-runner:** The command-line program that generates and installs IOC
  configurations, manages services, and provides console and diagnostic
  access. See the [CLI reference](CLI_REFERENCE.md).
- **procServ:** The process supervisor between the service manager and the
  IOC. It starts the IOC child process and provides its console socket and
  output logging.
- **Service manager:** The component that starts, stops, and supervises
  procServ: systemd in system and local mode, or s6 in container mode.
- **systemd:** The service manager used for system services and per-user
  services. The runner operates it through `systemctl`.
- **s6:** The supervision tools used in container mode. `s6-svscan` watches
  the scan directory, and `s6-supervise` supervises each IOC service.
- **System mode:** The default execution mode, using the system instance of
  systemd and a shared service account. See the
  [system guide](USER_GUIDE.md).
- **Local mode:** Execution under the invoking user's account and user
  instance of systemd, selected by `--local` or `--user`. See the
  [local guide](USER_GUIDE_LOCAL.md).
- **Container mode:** Execution under s6 inside a container, selected by
  `--container`. The runner requires root in this mode and sends IOC output
  to the container's standard output. See [architecture](ARCHITECTURE.md).

## Configuration and service files

- **IOC name:** The identifier used in the installed configuration file,
  service name, and console socket path. The
  [CLI reference](CLI_REFERENCE.md) states the allowed characters.
- **Startup script:** The executable command file that starts an IOC and
  loads its configuration, commonly named `st.cmd` under `iocBoot`.
- **Working directory:** The directory selected by `IOC_CHDIR` before
  procServ starts `IOC_CMD`.
- **Per-IOC configuration:** The `<name>.conf` file containing operational
  keys such as `IOC_USER`, `IOC_GROUP`, `IOC_CHDIR`, `IOC_CMD`, and
  `IOC_PORT`, together with environment values for that IOC.
- **Site environment:** The optional `site.env` file in the configuration
  directory. It supplies shared environment values; the per-IOC
  configuration overrides matching keys. See
  [network environment](NETWORK_ENV.md).
- **EnvironmentFile:** A systemd directive that loads environment
  assignments from a file. The runner's systemd templates load `site.env`
  before the per-IOC configuration.
- **Template unit:** The shared `epics-@.service` definition used to run IOC
  services under systemd.
- **Unit instance:** A named use of the template, such as
  `epics-@myioc.service`. Its instance name replaces `%i` in the template.
- **Drop-in:** An additional systemd configuration file that supplements or
  overrides settings in a unit. See [installation](INSTALL.md).
- **Scan directory:** The directory that `s6-svscan` watches for service
  directories in container mode.
- **Service directory:** An s6 directory containing the generated `run`
  script and supervision state for one IOC.
- **Runtime directory:** A directory holding service runtime files, such as
  the IOC's `control` socket. See the mode-specific paths in the
  [CLI reference](CLI_REFERENCE.md).

## Accounts and file permissions

- **Principal:** A user or group whose permissions determine access to a
  file or operation. The [permission model](PERMISSION_MODEL.md) separates
  administrator, service-account, and operator-group roles.
- **Service account:** The account that runs procServ and the IOC in system
  and container mode; its default name is `ioc-srv`.
- **Operator group:** The group whose members manage shared IOC
  configurations and services; its default name is `ioc`.
- **sudoers policy:** Rules that authorize commands through `sudo`. The
  installed policy permits the operator group to manage IOC units.
- **ACL (Access Control List):** File permissions that specify access for
  named users or groups in addition to the owner, group, and other bits.
- **Default ACL:** Directory permissions inherited by files and directories
  created beneath it, subject to the creation mode.
- **ACL mask:** The limit on effective access granted to named users and
  group entries in an ACL.
- **Setgid directory:** A directory whose set-group-ID bit makes created
  entries inherit its group ownership.
- **Umask:** The process setting that restricts permissions when it creates
  files or directories. The [permission model](PERMISSION_MODEL.md) gives
  the resulting permissions for runner-managed paths.

## Console connections and diagnostics

- **UDS (UNIX domain socket):** A local interprocess communication endpoint.
  The runner uses a filesystem socket named `control` for each IOC console.
- **Console client:** A program that connects to the IOC's console socket.
  The runner prefers `con` and supports `socat` as a fallback.
- **Attach:** A console connection that accepts terminal input and displays
  IOC output. See the [console guide](USER_GUIDE.md).
- **Monitor:** A console connection that displays IOC output without sending
  terminal input to the IOC.
- **Detach key:** The key that ends an attach connection while leaving the
  IOC running. `--detach-key` selects it for one connection.
- **TTY:** A terminal interface through which a process receives input and
  writes output.
- **PTY (pseudoterminal):** A pair of software terminal endpoints that
  provides terminal behavior to a process without a physical terminal.
- **Standard streams:** A process's standard input (`stdin`), standard
  output (`stdout`), and standard error (`stderr`).
- **TX and RX:** Transmit and receive. In the console comparison, TX is
  input sent to the IOC and RX is output received from it.
- **PID (process ID):** The numeric identifier of a running process.
  systemd's `MainPID` identifies procServ for an IOC unit.
- **FD (file descriptor):** A process-local number referring to an open
  file, socket, or other input/output resource. `inspect` associates socket
  descriptors with processes.
- **Inode:** A filesystem object's identifier within its filesystem. The
  runner compares device and inode values when checking procServ executable
  identity.
- **cgroup (control group):** A Linux grouping of processes used for
  resource accounting and control. The systemd backend reads service
  resource usage from cgroup data.
- **Readiness marker:** The `All initialization complete` line that the
  runner looks for in the IOC log during systemd startup checks.
- **Crash loop:** Repeated process exits and restarts. The runner detects
  IOC child restarts through procServ death banners in the log.
- **Exit status:** The result of a process ending, expressed as an exit
  code or terminating signal. See [exit and signal handling](EXIT_SIGNAL_HANDLING.md).

## Logs and network terms

- **IOC log:** The file where procServ records IOC console output in system
  and local mode. See [log layout](LOG_LAYOUT.md).
- **Journal:** systemd's collection of service messages, including
  procServ's own standard output and standard error. The runner's startup
  checks read the IOC log file.
- **Log rotation:** Archiving log contents according to a time or size
  policy, managed here by `logrotate`.
- **copytruncate:** The rotation method that copies a log and truncates the
  active file in place so the writer can keep its open file.
- **Linger:** The systemd user setting that lets a user's service manager
  run without an active login session. See the [local guide](USER_GUIDE_LOCAL.md).
- **PV (process variable):** A named value exposed by EPICS for clients to
  read, monitor, or write.
- **CA (Channel Access):** An EPICS network protocol for accessing PVs.
- **PVA (PV Access):** An EPICS network protocol for accessing structured
  PV data. See [network environment](NETWORK_ENV.md) for CA and PVA settings.
- **Discovery:** The process by which a client finds the server for a PV.
- **Beacon:** A server announcement used by the EPICS network protocols.
- **Multi-homed host:** A host with more than one network interface or
  address, where client discovery and server binding can use different
  networks.
