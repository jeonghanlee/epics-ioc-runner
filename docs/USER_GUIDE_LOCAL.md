# Local-mode IOC guide

This guide shows how to run and test an EPICS IOC under your own user
account, with your user instance of systemd and without `root` or `sudo`.
Console access, listing, direct `con` access, and the version check work as in
system mode with `--local` added; they are described once, in
[USER_GUIDE.md](USER_GUIDE.md), and linked from this page.

Prerequisites:

- `procServ` and `con` are installed. In local mode the runner searches
  `~/.local/bin`, then `/usr/local/bin`, then `/usr/bin`, or uses the path in
  `IOC_RUNNER_PROCSERV_TOOL` or `IOC_RUNNER_CON_TOOL`. You can build them
  from [con](https://github.com/jeonghanlee/con) and
  [procServ-env](https://github.com/jeonghanlee/procServ-env), or ask your
  system administrator; [INSTALL.md](INSTALL.md) lists the requirements.
- `ioc-runner` is on your `PATH`. `make install.user` in the
  `epics-ioc-runner` checkout installs the command in `~/.local/bin` and its
  Bash completion in `~/.local/share/bash-completion/completions`, without
  `root`; `~/.local/bin` must be on your `PATH`.

## Run an IOC in local mode

To run an IOC locally, you generate its configuration, install it into your
user configuration directory, and start it.

1. In your workspace, clone the IOC repository and change to its boot
   directory:

   ```bash
   git clone <ioc_repository_url>
   cd <ioc_repository>/iocBoot/<ioc_boot_dir>
   ```

   `<ioc_repository_url>` is the Git URL of the IOC, `<ioc_repository>` the
   directory the clone creates, and `<ioc_boot_dir>` the directory that holds
   the startup script.

2. Generate the configuration with your user and primary group:

   ```bash
   ioc-runner --local generate .
   ```

3. Install the configuration:

   ```bash
   ioc-runner --local install .
   ```

   The first local install creates `~/.config/procServ.d`, the log directory,
   the user unit template `~/.config/systemd/user/epics-@.service`, and the
   log rotation units. `-f` answers every question with yes, for
   configuration management and CI/CD use.

4. Start the IOC:

   ```bash
   ioc-runner --local start <ioc_boot_dir>
   ```

   The runner checks the log directory that the user unit names, starts the
   service, and reports whether the IOC reached `All initialization
   complete`.

### Verification

The runner prints `IOC '<ioc_boot_dir>' successfully started.`, and
`ioc-runner --local status <ioc_boot_dir>` shows the service as
`active (running)`.

### Write a local configuration by hand

A hand-written local configuration names your user and primary group:

```bash
cat <<EOF > <ioc_boot_dir>.conf
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="$(pwd)"
IOC_PORT=""
IOC_CMD="./st.cmd"
EOF
```

The configuration syntax is the same in both modes; see
[Configuration file syntax](USER_GUIDE.md#configuration-file-syntax). A file
with multiline values, continuations, or unsupported quote and escape forms is
rejected before the installed configuration is replaced.

## Start local IOCs at boot

`install` does not enable the IOC. `enable` makes it start with your user
instance of systemd, and `disable` reverts that:

```bash
ioc-runner --local enable <ioc_name>
ioc-runner --local disable <ioc_name>
```

Your user instance runs at boot only when lingering is enabled for your
account:

```bash
loginctl enable-linger "$(id -un)"
```

## Operate and remove local IOCs

The service commands take `--local`:

```bash
ioc-runner --local status <ioc_name>
ioc-runner --local view <ioc_name>
ioc-runner --local stop <ioc_name>
ioc-runner --local restart <ioc_name>
ioc-runner --local log <ioc_name>
```

`view` prints the installed configuration and the unit as systemd resolves
it. `log` prints the last 40 lines of the IOC log; `-n <count>` sets the
number of lines and `-f` follows the file.

When you finish testing, `remove` stops and disables the service and deletes
the configuration; your IOC directory stays in place:

```bash
ioc-runner --local remove <ioc_name>
```

For the console, the IOC list, direct `con` access, and the runner version,
use the sections of the system-mode guide with `--local`:

- [Attach to the IOC console](USER_GUIDE.md#attach-to-the-ioc-console)
- [List managed IOCs](USER_GUIDE.md#list-managed-iocs)
- [Connect to the console directly with con](USER_GUIDE.md#connect-to-the-console-directly-with-con)
- [Check the runner version](USER_GUIDE.md#check-the-runner-version)

## Control the user unit with systemctl directly

Each local IOC is an instance of the user unit template, so
`systemctl --user` works on it directly. It skips the runner's log-path check
and startup report, so use it only when you intend that:

```bash
systemctl --user restart epics-@<ioc_name>.service
systemctl --user status epics-@<ioc_name>.service
journalctl --user -u epics-@<ioc_name>.service
```

The IOC log is `~/.local/state/procserv/<ioc_name>.log`, or the
`procserv` directory under `$XDG_STATE_HOME` when that variable is set:

```bash
tail -f ~/.local/state/procserv/<ioc_name>.log
```

The per-user rotation described in [Local log rotation](#local-log-rotation)
bounds its growth.

## Override the runner directories and tools

For isolated testing, CI pipelines, or multi-tenant workstations, the runner supports environment variable overrides that redirect the configuration, systemd, and runtime directories without touching the installed script.

### Namespaced variables (per execution mode)

| Variable | Default | Affects |
|---|---|---|
| `IOC_RUNNER_LOCAL_CONF_DIR`    | `${HOME}/.config/procServ.d`     | `--local` conf storage |
| `IOC_RUNNER_LOCAL_SYSTEMD_DIR` | `${HOME}/.config/systemd/user`   | `--local` unit template |
| `IOC_RUNNER_LOCAL_RUN_DIR`     | `/run/user/$(id -u)/procserv`   | `--local` socket path in `IOC_PORT` |
| `IOC_RUNNER_LOCAL_LOG_DIR`     | `${XDG_STATE_HOME:-${HOME}/.local/state}/procserv` | `--local` procServ log directory (baked into the unit `--logfile` at install; also the crash-scan path) |
| `IOC_RUNNER_SYSTEM_CONF_DIR`    | `/etc/procServ.d`              | system-mode conf storage |
| `IOC_RUNNER_SYSTEM_SYSTEMD_DIR` | `/etc/systemd/system`          | system-mode unit template |
| `IOC_RUNNER_SYSTEM_RUN_DIR`     | `/run/procserv`                | system-mode socket path in `IOC_PORT` |
| `IOC_RUNNER_SYSTEM_LOG_DIR`     | `/var/log/procserv`            | no effect in the runner; the system setup reads its own variable of this name to set the `--logfile` directory of the system template |

### Unified runtime overrides (take precedence over both)

| Variable | Behavior |
|---|---|
| `IOC_RUNNER_CONF_DIR`    | Overrides both `LOCAL_CONF_DIR` and `SYSTEM_CONF_DIR` |
| `IOC_RUNNER_SYSTEMD_DIR` | Overrides both `LOCAL_SYSTEMD_DIR` and `SYSTEM_SYSTEMD_DIR` |
| `IOC_RUNNER_RUN_DIR`     | Overrides both `LOCAL_RUN_DIR` and `SYSTEM_RUN_DIR` |
| `IOC_RUNNER_LOG_DIR`     | Overrides `LOCAL_LOG_DIR`; system mode reads the log path from the installed unit |
| `IOC_RUNNER_CON_TOOL`    | Absolute path to a custom `con`-compatible binary |
| `IOC_RUNNER_PROCSERV_TOOL` | Absolute path to a custom `procServ` binary, used for the local-mode template and the container-mode run script |
| `IOC_RUNNER_LOGROTATE_TOOL` | Preferred executable for local rotation deployment; see [Local log rotation](LOG_LAYOUT.md#local-mode-log-rotation) for fallback search and installed paths |

Resolution order (highest wins): `IOC_RUNNER_<VAR>` > `IOC_RUNNER_{LOCAL,SYSTEM}_<VAR>` > built-in default. When `IOC_RUNNER_CON_TOOL` / `IOC_RUNNER_PROCSERV_TOOL` are unset, the tool is searched in `~/.local/bin`, then `/usr/local/bin`, then `/usr/bin` (the `~/.local/bin` entry is skipped when HOME cannot be resolved to a real home).

### Configuration and log path requirements

The resolved configuration directory must be absolute and contain no
whitespace, including spaces and tabs. The runner checks this in every mode
after the backend preflight and exits 1 on failure, before dispatching the
command. Help, version, and the no-command usage exit before this check.
Correct `IOC_RUNNER_CONF_DIR` or the applicable mode-specific configuration
override when the error names an invalid directory.

Local `install` applies the same absolute-path and no-whitespace requirements
to the resolved log directory. It exits 1 before copying the configuration or
deploying shared local assets if that check fails. Correct `IOC_RUNNER_LOG_DIR`,
`IOC_RUNNER_LOCAL_LOG_DIR`, or `XDG_STATE_HOME`, according to which value supplies
the path. Quoting a value in the shell does not make whitespace acceptable.

Changing the local configuration directory also changes where the runner
stores its logrotate configuration. The [log reference](LOG_LAYOUT.md#local-mode-log-rotation)
gives that calculation and the paths to use for cleanup when overrides apply.

### System setup override (`bin/setup-system-infra.bash`)

System-mode setup reads a separate variable, `IOC_RUNNER_PROCSERV_PATH`, distinct from the runner's `IOC_RUNNER_PROCSERV_TOOL`. It applies only while `bin/setup-system-infra.bash` generates the system template: system-mode setup uses this path as the procServ executable embedded in the system template's `ExecStart`. It takes a single path and replaces the default search list (`/usr/local/bin/procServ`, then `/usr/bin/procServ`) rather than prepending to it.

| Variable | Default | Affects |
|---|---|---|
| `IOC_RUNNER_PROCSERV_PATH` | `/usr/local/bin/procServ`, then `/usr/bin/procServ` | system-mode setup: procServ executable in the generated template `ExecStart` |

### Example: sandboxed local run

```bash
export IOC_RUNNER_LOCAL_CONF_DIR="/tmp/sandbox/conf"
export IOC_RUNNER_LOCAL_SYSTEMD_DIR="/tmp/sandbox/systemd"

~/epics-ioc-runner/bin/ioc-runner --local generate .
~/epics-ioc-runner/bin/ioc-runner --local install .
```

**Caveat: the system-mode runtime directory is fixed**

The deployed systemd template hardcodes `RuntimeDirectory=procserv/%i` (resolving to `/run/procserv/%i`). In system mode, moving the runtime directory off `/run/procserv` via `IOC_RUNNER_RUN_DIR` or `IOC_RUNNER_SYSTEM_RUN_DIR` would split the `IOC_PORT` socket path from where the kernel creates the UDS, so the runner rejects it with an error. Use these overrides only in `--local` mode or for test scaffolding.

**Install-time paths are read from the effective unit**

The local unit and conf bake paths at install time. Runtime commands use the
effective installed unit rather than reconstructing its logfile from the
current environment:

- `start`, `restart`, and `inspect` resolve `--logfile` from effective
  `ExecStart`; startup readiness scans therefore follow the same path procServ
  uses.
- If the installed `IOC_PORT` socket path no longer matches the current `RUN_DIR` resolution, it prints `Warning: the installed IOC_PORT socket (...) does not match the current RUN_DIR resolution (...).` Then `attach` and `list` look in the wrong place; re-run `install` after changing `IOC_RUNNER_LOCAL_RUN_DIR` / `IOC_RUNNER_RUN_DIR`.

After changing any install-time override, re-run `ioc-runner --local install`
so the unit, configuration, socket lookup, and log path remain aligned.

## Local log rotation

`ioc-runner --local install` also deploys per-user log rotation, because a
crash-looping IOC under `Restart=always` would otherwise grow its log without
limit. One user timer, `epics-logrotate.timer`, rotates every log in the local
log directory weekly, or as soon as a log exceeds 50 MB. The timer runs only
while your user instance of systemd runs, so enable lingering on a headless
host, and `remove` leaves it in place. [LOG_LAYOUT.md](LOG_LAYOUT.md#local-mode-log-rotation)
gives the files, the policy, and how to remove rotation.
