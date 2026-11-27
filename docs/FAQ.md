# Operations FAQ (frequently asked questions)

Use this page to identify an operational symptom and find its remedy. Exact
command behavior, path values, and permissions are linked to their references.

### Do I need a root password to restart an IOC?

The installed sudoers policy grants the `ioc` group passwordless service
control. Restart through the runner to include its startup checks:

```bash
ioc-runner restart myioc
```

A later matching sudo rule can override `NOPASSWD`, including a rule supplied
through SSSD/LDAP. If a password is requested, ask the site administrator to
check the effective sudo policy and rule order. A site `sudoRole` for EPICS
commands must take precedence over a broad password-required grant.
See [sudoers deployment](INSTALL.md#restricted-sudoers-configuration) and the
[older-sudo glob risk](PERMISSION_MODEL.md#residual-risk-on-sudo--1910-hosts).

### Can IOC configuration files include metadata?

In system and local modes, systemd exports configuration assignments to
procServ and the IOC. Use the `IOC_META_` prefix for metadata to avoid
collisions with operational environment variables. The prefix is a convention,
not an enforced rule. For example, add these assignments to an IOC conf:

```bash
IOC_META_GIT_REPO="https://github.com/jeonghanlee/flux-capacitor-ioc"
IOC_META_GROUP="time-travel"
```

Do not store secrets in the configuration: its values become process
environment. Every assignment must pass the
[configuration grammar](USER_GUIDE.md#configuration-file-syntax), even when
the runner does not use the key. Container run scripts do not export the conf
environment; see [environment layering](NETWORK_ENV.md#how-an-ioc-receives-its-network-environment).

### How do I list running IOCs on a host?

`list` reports discovered console sockets and service state. Add `-v` for
PID, CPU, and memory, or `-vv` for socket details:

```bash
ioc-runner list
ioc-runner -v list
ioc-runner -vv list
```

Installed configurations also include stopped IOCs:

```bash
ls /etc/procServ.d/*.conf
```

See the [list reference](CLI_REFERENCE.md#the-list-command) for columns and
access restrictions.

### How do I locate IOCs across the facility?

The runner reports one host at a time. Collect `ioc-runner list` results from
your site's host inventory through SSH or an external management tool.
Conserver and Cockpit integrations are designs, not facility inventory
features of the runner; see the
[integration directory](https://github.com/jeonghanlee/epics-ioc-runner/tree/master/system-wide).

### Can I run a managed IOC manually for testing?

Stop the managed IOC before running its startup script manually. This example
also disables boot startup during debugging:

```bash
# 1. Disable auto-start on boot
ioc-runner disable myioc

# 2. Stop the running service (procServ + IOC)
ioc-runner stop myioc

# 3. Run the IOC manually for debugging (see the history-file note below)
cd /opt/epics-iocs/flux-capacitor/iocBoot/iocFluxCap
export EPICS_IOCSH_HISTFILE=   # empty string disables the history file (EPICS docs)
./st.cmd

# 4. When debugging is complete, return to managed mode
ioc-runner start myioc
ioc-runner enable myioc
```

This procedure changes the IOC's runtime state and boot-time auto-start setting.
The `.conf` file remains in `/etc/procServ.d/`, and the systemd template is unchanged.

The empty `EPICS_IOCSH_HISTFILE` prevents the manual session from replacing
a shared history file. Set it before launch; setting it inside `st.cmd` is too
late. See [history ownership](#why-does-ioc-shell-history-report-permission-denied).

### What happens when IOC startup crashes or hangs?

procServ restarts a crashed IOC child while keeping the console socket open.
The systemd template separately restarts procServ if it exits without a stop
request. See [exit and signal handling](EXIT_SIGNAL_HANDLING.md).

System/local `start` and `restart` inspect the IOC log for readiness, child
exits, and error markers. A nonzero child exit can fail startup even while
procServ remains active. An active unit without a readiness marker gets a
warning; initialization with module errors also gets a warning. Neither
`active` nor exit 0 alone establishes that every IOC function works.

The [startup reference](CLI_REFERENCE.md#the-start-and-restart-commands)
defines the time limits, outcomes, and precedence. Container startup checks
only the control socket because container mode has no log file.

### How are crash detection patterns configured?

Add `CRASH_LOG_PATTERNS_EXTRA` to the IOC conf for module-specific phrases:

```bash
CRASH_LOG_PATTERNS_EXTRA="Bergoz link lost|NPCT overrange|Keithley buffer full"
```

Matches produce warnings, never standalone startup failures. Do not edit the
runner's built-in patterns. The [pattern reference](CLI_REFERENCE.md#startup-error-patterns)
defines matching, allowed characters, and install/runtime validation.

### Can I deploy IOCs from personal directories?

System-mode IOCs need service-account access to the payload and every runtime
file destination, including history and autosave paths. Relative paths follow
the IOC's working directory, which `st.cmd` can change. A private home or NFS
path can block access even when the operator can use it.

Use the [shared deployment directory](INSTALL.md#shared-deployment-directory-setup-optepics-iocs).
`install` checks an absolute, non-symlinked `IOC_CHDIR`, group ownership,
setgid, group write/execute, and parent traversal. A model mismatch requires
confirmation; `-f` accepts it without repairing permissions. Relative paths
and `..` components are hard errors that `-f` cannot bypass. The
[install reference](CLI_REFERENCE.md#the-install-command) gives the full checks.

Disabling history removes only history-file errors; other persistence failures
remain. Local mode runs as the invoking user instead of `ioc-srv`.

### How do I read logs in system mode?

Use `ioc-runner log <name>`, adding `-f` to follow output. It reads the
procServ logfile from the installed unit and requires no journal-group
membership. Default system logs are readable by other users.

The journal contains service-manager diagnostics, not IOC console output;
access follows host policy. An active login does not guarantee a readable
per-user journal. See [log layout](LOG_LAYOUT.md) for paths and
[permissions](PERMISSION_MODEL.md) for access.

### What happens to console sessions when an IOC stops?

Stopping procServ closes its console connections; clients receive EOF.
Reconnect after the IOC starts. A child-only restart keeps the socket open.

If `remove` cannot stop the service, it reports the state and keeps the
configuration. Check sudo access and unit state before retrying; see the
[remove reference](CLI_REFERENCE.md#the-remove-command).

### Why can attach not read the configuration directory?

With default system permissions, a user outside `ioc` cannot read the IOC
configuration or traverse its socket directory. `attach`, `monitor`, and
`view` report a configuration-directory permission error; `list` finds no
sockets. Ask the administrator for group membership when your role requires
console access. Service state remains readable with `ioc-runner status <name>`.
See the [access boundary](PERMISSION_MODEL.md#access-boundary-sudoers-policy-and-file-mode).

### How do I share environment values across IOCs?

In system and local modes, place shared assignments in optional `site.env`
beside the IOC confs. Per-IOC values override it. `install` validates its
syntax and rejects `IOC_ARGS` there; put arguments in each IOC conf.
The [network reference](NETWORK_ENV.md) gives file locations, examples, and
CA/PVA placement rules. Container mode does not use this environment layer.

### Why does IOC shell history report permission denied?

A shared `.iocsh_history` often belongs to the previous operator or to
`ioc-srv`, with mode `0600`. Another principal cannot read it and gets
`ERROR Permission denied (13) loading` on the console. This does not prevent
IOC initialization or change its exit status; the runner excludes that
history error from crash matching.

History defaults to the IOC's working directory. `EPICS_IOCSH_HISTFILE`
selects another path, expands a leading `~/` from `HOME`, or disables history
when empty. Set it before starting iocsh. Changing `IOCSH_HISTSIZE` does not
disable file access.

On normal iocsh exit, readline attempts to save history by writing a temporary
`0600` file and renaming it over the old file. A successful non-root save makes
the saving principal the owner; root can restore the previous owner. Changing
the old file's mode does not preserve that mode on the next save.

- The directory must be writable; the existing file need not be writable.
- Without a sticky bit, the last successful writer owns the replacement,
  including when two local users share an IOC directory.
- A sticky directory blocks replacement of another owner's file. Readline 8
  reports `Operation not permitted (1) writing`; readline 7 can report
  `Unknown error -1 (-1) writing`. The old file remains.
- A service stop can terminate the IOC before it saves history.

Give each principal its own history path outside the shared IOC directory.
Set `EPICS_IOCSH_HISTFILE` in the launch environment; a nonexistent file is
accepted on first use.

| Launch path | Setting location | History path |
| --- | --- | --- |
| System service | `/etc/systemd/system/epics-@.service.d/history.conf` | `/var/log/procserv/%i.iocsh_history` |
| Local service | `${HOME}/.config/systemd/user/epics-@.service.d/history.conf` | `%h/.iocsh_history-%i` |
| Manual shell | Site EPICS environment or operator profile | `~/.iocsh_history`, or empty to disable |

In each service drop-in, use `[Service]` and an
`Environment=EPICS_IOCSH_HISTFILE=<path>` assignment with the table's path.
The system path uses the default writable log directory; adjust it for a
custom installation. `site.env` also accepts this variable, but does not
expand `%i`, so one fixed value shares a file across IOCs.

Apply the service drop-in and verify the running IOC:

1. For a system service, ask an administrator to run
   `sudo systemctl daemon-reload` after saving the drop-in.
2. Restart each affected IOC with `ioc-runner restart <ioc_name>` for system
   mode, or `ioc-runner --local restart <ioc_name>` for local mode. Local
   restart reloads the user manager automatically. `start` alone does not
   replace the environment of an already-running IOC.
3. In the [IOC console](USER_GUIDE.md#attach-to-the-ioc-console), check
   `EPICS_IOCSH_HISTFILE` against the intended path. `%i` must resolve to the
   IOC name and local `%h` to the user's home. Check the startup log for
   history permission errors; startup success alone does not exclude them.

With either drop-in, iocsh uses the configured path; its successful history
save creates the file. A later start by the same principal can read it.
A manual shell without that environment uses the default shared-directory
file; the runner does not configure the shell.

### Why is an active IOC's startup log unreadable?

The runner reads the log file named by the unit's `--logfile` to judge the
startup, and that file was missing or unreadable when it looked. Check that
the file and its directory exist with the owners and modes in
[PERMISSION_MODEL.md](PERMISSION_MODEL.md), for example with
`stat /var/log/procserv/<name>.log` in system mode. The unit is active, but the unreadable log prevents the runner from confirming IOC initialization.

### Why does the journal show no IOC output?

procServ writes the IOC's console output to the log file, not to the journal;
the journal holds only systemd's and procServ's own messages about the
service. Read the IOC output with `ioc-runner log <name>`, or the file itself
as [LOG_LAYOUT.md](LOG_LAYOUT.md) describes.

### Why are log lines missing after rotation?

Rotation uses `copytruncate`: logrotate copies the live file to
`<name>.log.1.gz` and truncates the original in place. The earlier lines are in
the rotated archive; read it with `zcat` or `zless`.

### Where is the log of a local-mode IOC?

Use `ioc-runner --local log <name>` to follow the installed unit's logfile
path, including install-time overrides. The default and override precedence
are in [local log paths](LOG_LAYOUT.md#local-mode-log-paths).

### Why are my local-mode logs not rotated?

The user timer is not running, lingering is off, or `logrotate` was missing
when you installed. Check the timer, enable it, and enable lingering:

```bash
systemctl --user list-timers | grep epics-logrotate
systemctl --user enable --now epics-logrotate.timer
loginctl enable-linger "$(id -un)"
```

When `logrotate` was missing, `install` deployed no rotation units. Install
`logrotate`, stop one local IOC, and run `ioc-runner --local -f install <ioc_dir>`
for it again, where `<ioc_dir>` is the IOC directory that holds its conf; `install` refuses an IOC that is running.

### Why do manually created files have different log permissions?

The directory's default ACL gives the `ioc` group write access to files that
operators create there, while procServ creates its log files with a fixed mode
that the ACL does not widen. Both results are intended;
[PERMISSION_MODEL.md](PERMISSION_MODEL.md) gives the values and the reason.
