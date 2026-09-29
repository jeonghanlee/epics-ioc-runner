# Log layout

procServ writes each IOC's console output to a dedicated log file, and the
runner's crash detection reads that file directly. This page gives the log
paths, how the runner finds them, and the rotation policy in system and local
mode. The owners and modes of these paths are in
[PERMISSION_MODEL.md](PERMISSION_MODEL.md), and container mode, which writes
IOC output to the container's standard output, has no log file.

## Data flow from the IOC to the log file

The IOC's output passes through procServ into the log file, which the runner
scans:

```text
IOC process (st.cmd)
   |  stdout + stderr
   v
procServ --foreground --logfile=<log_dir>/<name>.log --name=<name> ...
   |  writes child output to the log file
   v
<log_dir>/<name>.log
   ^
   |  byte-offset scan (no journal, no sudo)
ioc-runner crash detection on start and restart
```

procServ runs in the foreground under systemd, and `--logfile` names the file.
The systemd journal also receives procServ's own standard output and standard
error for service-manager diagnostics; the IOC console output and the crash
detection use only the log file.

`log`, `start`, `restart`, and `inspect` read the path from the `--logfile`
argument of the installed unit, so they follow the file procServ writes even
when the environment of the current shell differs.

## System-mode log paths

The system setup writes the log directory into the `--logfile` argument of
the system unit template. The directory is `/var/log/procserv`, or the value
of `IOC_RUNNER_SYSTEM_LOG_DIR` in the environment of `setup-system-infra.bash`
when it deploys the template. The runner's own `IOC_RUNNER_LOG_DIR` and
`IOC_RUNNER_SYSTEM_LOG_DIR` do not change system-mode logging.

| Path | Created by |
| --- | --- |
| `/var/log/procserv/` | `setup-system-infra.bash` |
| `/var/log/procserv/<name>.log` | procServ at IOC start |
| `/var/log/procserv/<name>.log.N.gz` | `logrotate` |

## Local-mode log paths

The local log directory is `$XDG_STATE_HOME/procserv`, or
`~/.local/state/procserv` when `XDG_STATE_HOME` is unset.
`IOC_RUNNER_LOCAL_LOG_DIR` changes that default, and `IOC_RUNNER_LOG_DIR`
overrides the result. `ioc-runner --local install` creates the directory and
writes it into the `--logfile` argument of the user unit template.

| Path | Created by |
| --- | --- |
| `<log_dir>/` | `ioc-runner --local install` |
| `<log_dir>/<name>.log` | procServ at IOC start |
| `<log_dir>/<name>.log.N.gz` | `logrotate` from the user timer |

## Who can read the logs

`ioc-runner [--local] log <name>` prints the tail of the effective log file,
so an operator does not build the path by hand. In system mode every user can
read the log files, and changing a service requires the `ioc` group; the
three-principal model in [PERMISSION_MODEL.md](PERMISSION_MODEL.md) gives each
principal's access. Reading a log does not require membership in the
`systemd-journal` group.

## System-mode log rotation

`setup-system-infra.bash` deploys `/etc/logrotate.d/procserv`:

- **Schedule:** weekly.
- **Retention:** 8 rotations.
- **Method:** `copytruncate`: logrotate copies the file and truncates it in
  place, so procServ keeps writing to the same path, the console socket is
  unaffected, and the IOC needs no restart.
- **Archives:** `<name>.log.1.gz`, `<name>.log.2.gz`, and onward, compressed.

To check the policy without rotating, and to force a rotation:

```bash
sudo logrotate -d /etc/logrotate.d/procserv
sudo logrotate -f /etc/logrotate.d/procserv
```

## Local-mode log rotation

`ioc-runner --local install` deploys per-user rotation without `root` or
`/etc/logrotate.d`: a logrotate configuration at
`~/.config/ioc-runner/logrotate.conf` by default and a user systemd timer that runs it.
One timer rotates every `*.log` in the local log directory.

The configuration path is `${CONF_DIR%/*}/ioc-runner/logrotate.conf`, using
the resolved local configuration directory. The expression removes the last
slash and everything after it, then appends `/ioc-runner/logrotate.conf`.
For example, `/tmp/sandbox/conf` produces
`/tmp/sandbox/ioc-runner/logrotate.conf`. A trailing slash changes the result:
`/tmp/sandbox/conf/` produces `/tmp/sandbox/conf/ioc-runner/logrotate.conf`.
Use directory overrides without a trailing slash for a sibling configuration
directory. The rotation units live in the resolved `SYSTEMD_DIR`, which defaults
to `~/.config/systemd/user`; the [local guide](USER_GUIDE_LOCAL.md#override-the-runner-directories-and-tools)
lists the overrides and path restrictions.

At deployment, the runner selects the logrotate executable in this order:

1. `IOC_RUNNER_LOGROTATE_TOOL`, if nonempty and executable.
2. `/usr/sbin/logrotate`, `/sbin/logrotate`, then `/usr/bin/logrotate`, taking
   the first executable path.
3. The result of looking up `logrotate` in the invoking shell's `PATH`.

An unset, empty, or nonexecutable override falls through to the search.
Use an absolute executable path for the override: the runner embeds the
selected value in the rotation service's `ExecStart` at install time.
If no executable is found, it warns and skips rotation deployment while
allowing the IOC installation to continue. System setup uses its own
`logrotate` lookup through `PATH` and does not read this override.

- **Units:** `epics-logrotate.service` (`Type=oneshot`) and
  `epics-logrotate.timer`, under `systemctl --user`; `install` enables the
  timer. Inspect it with `systemctl --user status epics-logrotate.timer`.
- **Schedule:** `OnCalendar=hourly`, `Persistent=true`,
  `RandomizedDelaySec=5m`. The hourly run makes the size limit effective;
  `weekly` drives time-based rotation.
- **Policy:** `weekly`, `maxsize 50M`, `rotate 8`, `copytruncate`,
  `compress`, `missingok`, `notifempty`, and `nodateext`. `maxsize` rotates a
  log that exceeds 50 MB before the week ends, which bounds a crash loop.
- **State:** the logrotate state file is `%t/ioc-runner-logrotate.state`, in
  the host-local `$XDG_RUNTIME_DIR`, so timers on several hosts that share an
  NFS home do not race on one state file.
- **Console socket:** the socket lives under `/run/user/<uid>`, not in the log
  directory, so rotation never touches it.
- **Linger:** the timer runs only while your user instance of systemd runs;
  on a headless host, enable lingering with `loginctl enable-linger <user>`.
- **Best effort:** a missing `logrotate`, a configuration that fails
  `logrotate -d`, or an unreachable user bus prints a warning and skips
  rotation; the IOC install succeeds. Fix the cause, stop the IOC, and run
  `ioc-runner --local install` again; `install` refuses an IOC that is
  running.
- **Generated files:** do not edit `logrotate.conf` or the `epics-logrotate.*`
  units by hand. When one of them differs from the shipped content,
  `ioc-runner --local install` asks `Update it now? [y/N]` on a terminal,
  keeps it without a terminal, and replaces it with `-f`; an update discards
  the edits. Site rotation policy belongs in a separate logrotate
  configuration.

Rotation directory creation and configuration or unit staging failures each
print a warning and skip rotation deployment without failing IOC installation.
The staging files are created beside their intended destinations.
Validation uses a temporary `.logrotate-validate-state.XXXXXX` under the rotation
configuration directory, falling back to the system temporary directory and
then `/dev/null` if needed. The temporary state file is removed after either
successful or failed validation; it is separate from the timer's persistent
state. Refusing an update or closing input at the update prompt retains the
installed rotation files and continues installation.
- **Monitoring:** `ioc-runner --local list` warns when the timer is installed
  but inactive.
- **Removal:** `remove` deletes one IOC and leaves the shared timer. To remove
  rotation, run `systemctl --user disable --now epics-logrotate.timer`, delete
  `~/.config/ioc-runner/logrotate.conf`,
  `~/.config/systemd/user/epics-logrotate.service`, and
  `~/.config/systemd/user/epics-logrotate.timer`, and then run
  `systemctl --user daemon-reload`.

The removal paths above assume default directories. With overrides, use the
configuration path calculated above and the two unit files under the
`SYSTEMD_DIR` used at installation. Changing an environment variable does not
relocate an installed file; inspect the installed rotation service to identify
its executable and configuration path.

Log symptoms, such as an unreadable startup log or an empty journal, are
answered in [FAQ.md](FAQ.md).
