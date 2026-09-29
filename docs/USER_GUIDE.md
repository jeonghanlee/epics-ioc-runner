# System-mode IOC operations guide

This guide shows an operator how to deploy, run, observe, and remove EPICS
IOCs that systemd runs as the `ioc-srv` service account. Local mode, which
runs IOCs under your own user account, has its own guide in
[USER_GUIDE_LOCAL.md](USER_GUIDE_LOCAL.md) and shares the console, listing,
and version sections of this page. The command reference, with every option
and exit status, is [CLI_REFERENCE.md](CLI_REFERENCE.md).

Prerequisites:

- An administrator has run the system setup and prepared the shared
  deployment directory `/opt/epics-iocs`; see [INSTALL.md](INSTALL.md).
- You are a member of the `ioc` group.

## Deploy an IOC in system mode

To deploy an IOC, you clone it into the shared directory, generate its
configuration, install the configuration, and start the service.

1. In `/opt/epics-iocs`, clone the IOC repository and change to its boot
   directory:

   ```bash
   cd /opt/epics-iocs
   git clone <ioc_repository_url>
   cd <ioc_repository>/iocBoot/<ioc_boot_dir>
   ```

   `<ioc_repository_url>` is the Git URL of the IOC, `<ioc_repository>` the
   directory the clone creates, and `<ioc_boot_dir>` the directory that holds
   the startup script.

2. Generate the configuration for this directory:

   ```bash
   ioc-runner generate .
   ```

   The runner writes `<ioc_boot_dir>.conf` with the absolute paths and the
   `ioc-srv` identity. The startup script named in `IOC_CMD` must be
   executable, or `install` rejects the configuration.

3. Install the configuration:

   ```bash
   ioc-runner install .
   ```

   `install .` reads `<ioc_boot_dir>.conf` from the current directory; you can
   also pass the file name. The runner asks before it overwrites an installed
   configuration; `-f` answers yes, for configuration management and CI/CD
   use.

4. Start the IOC:

   ```bash
   ioc-runner start <ioc_boot_dir>
   ```

   The runner checks the log path, starts the service, and reports whether
   the IOC reached `All initialization complete`.

### Verification

The runner prints `IOC '<ioc_boot_dir>' successfully started.`, and
`ioc-runner status <ioc_boot_dir>` shows the service as `active (running)`.

### Deployment directory requirement

In system mode the IOC runs as `ioc-srv` and writes runtime files, such as
`.iocsh_history`, autosave files, and save/restore snapshots, to its working
directory. `IOC_CHDIR` must therefore be writable by `ioc-srv`.

The shared `/opt/epics-iocs` tree carries a default ACL, described in
[INSTALL.md](INSTALL.md#shared-deployment-directory-setup-optepics-iocs),
so that `IOC_CHDIR` is writable by `ioc-srv`. The setgid bit of the
`root:ioc 2775` parent alone is not enough: it passes the `ioc` group to a
directory that `git clone` creates, but the mode bits follow the creating
user's `umask`, so a clone made under `umask 022` is `2755` and `ioc-srv`
cannot write to it. The default ACL gives the group `rwx` on new entries
regardless of `umask`. Without it, clone under `umask 002`, or correct the
clone with `chmod -R g+w /opt/epics-iocs/<clone>`. Home directories and NFS
mounts without `ioc` group access are not writable by `ioc-srv` and cause
runtime failures under procServ.

During `install`, the runner checks that `IOC_CHDIR` is group-owned by `ioc`
with setgid and group write and execute, and that `ioc-srv` can traverse it.
It reads the file metadata directly, without `sudo`. When the directory does
not conform, the runner prints a warning and asks before it continues.

### Write a configuration by hand

A configuration can also be written by hand. For `install .` to find it, the
file name must be the directory name followed by `.conf`:

```bash
cat <<EOF > <ioc_boot_dir>.conf
IOC_USER="ioc-srv"
IOC_GROUP="ioc"
IOC_CHDIR="$(pwd)"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF
```

`install` fills an empty `IOC_PORT` with the standard socket path.

### Configuration file syntax

The runner accepts a bounded, single-line subset of systemd
`EnvironmentFile` syntax:

- Each assignment is `KEY=VALUE`. A key must be an environment identifier:
  ASCII letters or `_` first, followed by ASCII letters, digits, or `_`.
- Spaces and tabs around the line, key, `=`, and value are ignored. CRLF line
  endings are accepted.
- A value may be unquoted or enclosed by one matching pair of single or double
  quotes. The outer pair is removed after surrounding whitespace is trimmed;
  whitespace inside the quotes is preserved.
- A value may be empty and may contain additional `=` characters. The first
  `=` separates the key from the value.
- Inside a double-quoted value, `\\` produces one literal backslash. This is
  the supported form for regular-expression backslashes.
- Blank lines and lines whose first nonblank character is `#` are ignored.
- If a key appears more than once, the later assignment takes effect in both
  the runner and systemd.

For example, a regular-expression value that needs literal parentheses uses
two backslashes in the double-quoted configuration value:

```bash
CRASH_LOG_PATTERNS_EXTRA="Broken pipe|net_ex\\(status\\)"
```

Multiline quoted values, backslash continuations, unmatched or embedded quote
forms, unquoted or single-quoted backslashes, and double-quoted escapes other
than `\\` are rejected during `install`. A rejected file does not replace an
existing installed configuration. Use generated files or the simple forms
above rather than the wider systemd grammar. Every key must pass this syntax
check; operational `IOC_*` keys and `CRASH_LOG_PATTERNS_EXTRA` also receive
their field-specific validation.

An environment variable that is identical for every IOC on the host, most
commonly the Channel Access and PV Access client discovery lists, can be set
once in an optional site-wide file, `site.env`, alongside the per-IOC confs,
rather than repeated in each conf. Each IOC reads it before its own conf, and a
per-IOC conf overrides it. See [NETWORK_ENV.md](NETWORK_ENV.md) for which
variables belong in the shared layer and [ADR 0003](https://github.com/jeonghanlee/epics-ioc-runner/blob/master/docs/adr/0003-site-environment-layer.md)
for the mechanism.

## Attach to the IOC console

`attach` connects your terminal to the IOC shell through the console socket.
It is the same in both modes; local mode adds `--local`:

```bash
ioc-runner attach <ioc_name>
ioc-runner --local attach <ioc_name>
```

Press Enter to show the `epics>` prompt when the screen is blank.

- **Detach**: Press `Ctrl-A`, the default, to detach and leave the IOC
  running. The runner selects `con`, or `socat` when `con` is unavailable;
  both consume the key when you type it, so it does not reach the IOC shell.
  Inside pasted text, `con` forwards the key to the IOC shell, while `socat`
  detaches at it. With the default key, `Ctrl-A` cannot move the cursor to the
  beginning of the input line.
- **Ignored keys**: The runner starts procServ with `--ignore=^D^C`, which
  discards `Ctrl-C` and `Ctrl-D` before they reach the IOC; every other byte,
  including `Ctrl-]`, is forwarded. When `Ctrl-C` or `Ctrl-D` is the detach
  key, the client handles it and detaches first.
- **Supported clients**: `attach` and `monitor` use only `con` or `socat`.
  When neither is available, the command fails with an installation hint.
  For `monitor`, `con` must support `-r`; otherwise `socat` is required.
- **Production use**: Prefer `con` for production console access. `socat` is
  supported for ordinary console use, but it has not been validated for
  production workloads with sustained heavy output or sudden bursts of IOC
  output. This limitation applies to both `attach` and `monitor`.

To use another key for one connection, pass `--detach-key`; the attach banner
names the selected key, and later connections use `Ctrl-A` again. The
[CLI reference](CLI_REFERENCE.md#attach-readwrite-mode) lists the accepted key
names.

```bash
ioc-runner attach <ioc_name> --detach-key ctrl-]
```

### Read-only monitor

`monitor` shows the console without sending input. It selects `con -r`, or
`socat` when `con` is unavailable or lacks `-r`; terminal input never reaches
the IOC. Press `Ctrl-A` to exit with `con`, or `Ctrl-C` with `socat`; the
monitor banner names the exit key. `--detach-key` applies only to `attach`.

```bash
ioc-runner monitor <ioc_name>
ioc-runner --local monitor <ioc_name>
```

## Operate the IOC service

The runner commands operate the service and are the normal path; the
[CLI reference](CLI_REFERENCE.md) gives their checks and exit status:

```bash
ioc-runner status <ioc_name>
ioc-runner stop <ioc_name>
ioc-runner restart <ioc_name>
ioc-runner enable <ioc_name>
ioc-runner disable <ioc_name>
```

`enable` and `disable` decide only whether the IOC starts at boot. `start` and
`restart` check the log path first and report whether the IOC came up.

Because each IOC is an instance of the `epics-@.service` template, the
`systemctl` commands work on the same unit without a password. They skip the
runner's log-path check and startup report, so use them only when you intend
that:

```bash
sudo systemctl restart epics-@<ioc_name>.service
```

## Read IOC logs

procServ writes the IOC's standard output and standard error to
`/var/log/procserv/<ioc_name>.log`. `log` resolves the file from the
installed unit and prints its last 40 lines; `-n <count>` sets the number of
lines and `-f` follows the file:

```bash
ioc-runner log <ioc_name>
ioc-runner -n 200 log <ioc_name>
ioc-runner -f log <ioc_name>
```

For systemd's own messages about the service, rather than IOC output, read
the journal:

```bash
journalctl -u epics-@<ioc_name>.service
```

`/etc/logrotate.d/procserv` rotates the logs into compressed archives,
`<ioc_name>.log.1.gz` and onward; read them with `zcat` or `zless`. The IOC
keeps writing to the same path during rotation.
[LOG_LAYOUT.md](LOG_LAYOUT.md#system-mode-log-rotation) gives the policy.

## Remove an IOC

`remove` stops and disables the service and deletes the installed
configuration:

```bash
ioc-runner remove <ioc_name>
```

The IOC's own directory under `/opt/epics-iocs` stays in place.

## List managed IOCs

`list` shows each IOC's console socket and service state; `-v` adds PID, CPU,
and memory, and `-vv` adds kernel socket details:

```bash
ioc-runner list
ioc-runner --local list
ioc-runner list -v
```

In system mode, a user outside the `ioc` group sees no sockets.

## Connect to the console directly with con

`attach` resolves the socket path for you; `con` can also connect to the
socket directly. The socket path depends on the mode:

| Mode | Socket path |
| --- | --- |
| System | `/run/procserv/<ioc_name>/control` |
| Local | `/run/user/<uid>/procserv/<ioc_name>/control` |

`<uid>` is your numeric user ID, as `id -u` prints it. `ioc-runner list`
prints the full path of each socket. To connect to a system-mode IOC:

```bash
con -c /run/procserv/<ioc_name>/control
```

Press `Ctrl-A` to detach and leave the IOC running.

## Run IOCs in container mode

Inside a systemd-less container image prepared with
`setup-system-infra.bash --container` (see [INSTALL.md](INSTALL.md)), the
same commands run as root with `--container`; s6 supervises procServ and
there is no `systemctl`:

```bash
ioc-runner --container generate /opt/epics-iocs/<ioc_name>
ioc-runner --container install /opt/epics-iocs/<ioc_name>
ioc-runner --container start <ioc_name>
ioc-runner --container status <ioc_name>
ioc-runner --container list -v
ioc-runner --container attach <ioc_name>
ioc-runner --container stop <ioc_name>
ioc-runner --container remove <ioc_name>
```

`start` waits for the control socket to appear. `status` prints the IOC name
and the `s6-svstat` line, for example `myioc: up (pid 123) 42 seconds`.
`enable` deletes the service's s6 `down` file so the IOC starts when the
container starts, and `disable` creates it; neither touches the running IOC.

IOC output goes to the container's standard output (`docker logs
<container>`); there is no log file, no log rotation, and no journal. The
runner requires a running `s6-svscan` on `/run/s6-procserv`, which the
container entrypoint starts as PID 1, and refuses to run as a non-root user.

## Check the runner version

`-V` prints the runner version, Git commit, commit date, and install date:

```bash
ioc-runner -V
```

An installed runner prints its recorded values:

```text
epics-ioc-runner version <version> (<hash>)
commit date:  <commit date>
install date: <install date>
```

A runner run from a Git checkout without installation prints the live commit
and `install date: live`; uncommitted changes add `-dirty` to the hash:

```text
epics-ioc-runner version <version> (<hash> (live))
commit date:  <commit date>
install date: live
```

The commit date identifies the revision on this host, and the install date
shows how long it has been in place.
