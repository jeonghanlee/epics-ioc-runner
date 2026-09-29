# Install and configure EPICS IOC Runner

This guide describes the initial server setup required to deploy the `epics-ioc-runner` architecture system-wide. It covers the installation of prerequisite utilities, creation of isolated service accounts, strict directory permissions, systemd template deployment, and secure sudoers configuration.

## Prerequisites
* Root (sudo) access to the target server.
* For full setup, the `acl`, `logrotate`, and `sudo` packages, with
  `setfacl`, `getfacl`, `logrotate`, and `sudo` available in `PATH`.
  The setup script checks these tools before changing accounts or system
  configuration and exits with a package-installation hint if one is missing.
* Bash 4.3+ (the runner relies on `local -n` namerefs, introduced in Bash 4.3). Debian 8+, Ubuntu 14.04+, and RHEL/Rocky/AlmaLinux 8+ qualify; RHEL 7 / CentOS 7 ship Bash 4.2 and are not supported.
* Basic build tools installed (`gcc`, `g++`, `make`, `git`).
* Core utilities (`procServ` and `con`) compiled and installed system-wide.
* `util-linux` installed with `/usr/sbin/runuser` for system `inspect` identity switching.
* On a host with active SELinux, executable `/usr/sbin/restorecon` and
  `/usr/sbin/matchpathcon`. Hosts without active SELinux do not require these
  tools.

---

## Automated infrastructure setup
We provide a hardened, idempotent setup path that automatically configures isolated service accounts, strict directory permissions, and validated sudoers policies.

From the repository root, cache sudo credentials and run the staging launcher as the checkout owner for the initial complete setup:
```bash
sudo -v
./bin/run-setup-system-infra.bash --full
```

The privileged setup verifies every artefact it deploys and **exits 1 if any
verification check fails** - automated provisioning (ansible, CI) can trust
the exit status directly; a non-zero exit means the reported items must be
fixed and the script re-run.

When SELinux is active, the full setup restores the policy-defined context of
`/etc/sudoers.d/10-epics-ioc` and `/etc/logrotate.d/procserv` after each atomic
deployment and requires `matchpathcon -V` to accept both final paths. The
preflight requires both SELinux tools before any system mutation.

> **Important (custom service identity):** the service account and group are
> configurable via `IOC_RUNNER_SYSTEM_USER` / `IOC_RUNNER_SYSTEM_GROUP`, but
> the staging launcher forwards only its documented setup variables across
> the sudo boundary. Set both variables on the launcher invocation:
> `IOC_RUNNER_SYSTEM_USER=myuser IOC_RUNNER_SYSTEM_GROUP=mygroup ./bin/run-setup-system-infra.bash --full`
> The script prints the resolved identity as its first banner - confirm it
> before the run proceeds. The same overrides must then accompany every
> `ioc-runner` invocation (both scripts resolve the same variables).

The [setup environment reference](#setup-environment-and-launcher-forwarding)
lists the variables the launcher forwards and the paths it sets itself.

### Makefile front end
A `configure/` Makefile wraps the staging launcher. Cache sudo credentials, then run the targets as the checkout owner:

```bash
sudo -v
make setup     # full system infrastructure
make install   # CLI update only
```

`make help` lists targets; `make vars` prints the resolved paths.

> **Tip for Operations:** To update only `ioc-runner`, Bash completion, and the RHEL secure-path symlink without changing the remaining infrastructure, run `./bin/run-setup-system-infra.bash` without arguments.

Once the script completes successfully, manually add your authorized engineers to the `ioc` management group:
```bash
sudo usermod -aG ioc <username>
```

To apply the new group membership immediately to your current terminal session without logging out, run:
```bash
newgrp ioc
```

### NFS `root_squash`
On an NFS export with `root_squash`, server-side access maps root requests to
the anonymous identity. Root therefore may be unable to traverse or read a
checkout that remains readable to its owning user.

`run-setup-system-infra.bash` reads three fixed setup sources as the checkout
owner and sends them to a root-owned temporary directory under `/tmp`. The
privileged setup runs from that local directory. Git metadata and layout checks
refer to the original checkout and execute as the invoking owner, so the
installed version still identifies the candidate repository. The temporary
directory is removed on exit.

Use the launcher directly, or use `make install` and `make setup`, as the
checkout owner. Do not run the Make targets under `sudo`: root may be unable to
read the Makefile includes before the launcher can establish the local staging
boundary. Direct execution of `setup-system-infra.bash` is reserved for a
root-readable local source tree.

If the version ever stamps as `unknown` (for example the checkout is not a git
tree, or its metadata is unreadable), the setup emits a WARN naming the repair:
as the repository owner, set `RUNNER_GIT_HASH` and `RUNNER_COMMIT_DATE` in the
deployed script from `git -C bin rev-parse --short HEAD` and the UTC-normalized
`git -C bin show -s --format=%ct HEAD`. This is the same procedure as the manual
injection block below.

The system test execution boundary is documented separately in
`tests/README.md`.

---

### Container images (`--container`)

A systemd-less container image uses s6 supervision instead of the unit
template. With s6 (2.13 or later) present in the image, run at image build
time:
```bash
sudo /bin/bash -p ./bin/setup-system-infra.bash --container
```

It creates the `ioc` group and the `ioc-srv` account, `/etc/procServ.d`, the
scan directory skeleton `/run/s6-procserv`, and
deploys the CLI and the Bash completion. It deploys no sudoers policy, unit
template, log directory, or logrotate policy, and its preflight requires the
six s6 binaries (`s6-svscan`, `s6-supervise`, `s6-svc`, `s6-svstat`,
`s6-svscanctl`, `s6-setuidgid`) instead of `systemctl`. `--full` and
`--container` are mutually exclusive.

The container entrypoint must create `/run/s6-procserv` (a runtime that mounts
`/run` as tmpfs discards the build-time directory) and run
`s6-svscan /run/s6-procserv` as PID 1; `ioc-runner --container <command>` then
runs as root inside the container. IOC output reaches the container stdout
through `s6-svscan`. Deep `inspect` additionally needs the `CAP_SYS_PTRACE`
capability. See the [s6 service directory](ARCHITECTURE.md#s6-service-directory---container-mode) for the
service directory layout.

### Setup options and exit behavior

The launcher passes its arguments unchanged to `setup-system-infra.bash`.
The privileged script accepts these options:

| Option | Result |
| --- | --- |
| No option | Updates the runner, completion, and the RHEL-family secure-path symlink |
| `--full` | Sets up the system-mode infrastructure and updates the CLI |
| `--container` | Sets up the container-mode infrastructure and updates the CLI |
| `-h`, `--help` | Prints usage and exits 0 when encountered during option parsing |

The script rejects an unknown argument with `Error: Unknown option` and
exit 1. After parsing, it rejects a combination of `--full` and
`--container` with exit 1. Help exits during parsing, before that combination
check or the service-manager preflight.

The root check precedes option parsing. Direct setup execution as a non-root
user therefore exits 1 even for help. Through the launcher, help also requires
the source-file checks, executable dependencies, checkout-owner invocation,
and cached sudo credentials described below.

### Setup environment and launcher forwarding

Set setup variables in the launcher's environment. It explicitly forwards
only the following eight variables across sudo when they are set:

| Variable | Setup use |
| --- | --- |
| `IOC_RUNNER_SYSTEM_USER` | Service account; default `ioc-srv` |
| `IOC_RUNNER_SYSTEM_GROUP` | Service group; default `ioc` |
| `IOC_RUNNER_BACKUP_DIR` | Backup directory; default `/var/backups/epics-ioc-runner` |
| `IOC_RUNNER_SYSTEM_LOG_DIR` | System log directory embedded in the system template; default `/var/log/procserv` |
| `IOC_RUNNER_PROCSERV_PATH` | One executable path replacing setup's procServ search list |
| `IOC_RUNNER_SCRIPT_DEST` | Installed runner path; default `/usr/local/bin/ioc-runner` |
| `IOC_RUNNER_BASH_COMP_DEST` | Installed completion path; default `/etc/bash_completion.d/ioc-runner` |
| `IOC_RUNNER_SCRIPT_SYMLINK` | RHEL-family symlink path; default `/usr/bin/ioc-runner` |

Unset or empty values use the setup defaults. The procServ search order and
its distinction from the runner's tool override are documented in
[System setup override](USER_GUIDE_LOCAL.md#system-setup-override-binsetup-system-infrabash).
The [log reference](LOG_LAYOUT.md#system-mode-log-paths) describes how the
installed template determines system logging.

The launcher sets these three variables itself. Caller values do not select
alternative sources or metadata through the launcher:

| Variable | Launcher value | Direct setup default |
| --- | --- | --- |
| `IOC_RUNNER_SCRIPT_SRC` | `ioc-runner` in the temporary stage | `ioc-runner` beside the setup script |
| `IOC_RUNNER_BASH_COMP_SRC` | `ioc-runner-completion.bash` in the temporary stage | `ioc-runner-completion.bash` beside the setup script |
| `IOC_RUNNER_METADATA_DIR` | The original checkout's `bin` directory | The setup script's directory |

Direct privileged setup accepts overrides for those three variables.
It also accepts `IOC_RUNNER_SCAN_DIR` for the container scan directory,
defaulting to `/run/s6-procserv`. The launcher does not forward this variable;
use direct setup for a custom scan directory and configure the container
entrypoint and runner to use the same path.

Setup reads `ID` and `ID_LIKE` from `/etc/os-release`. It creates the
secure-path symlink when `ID` is `rhel` or `ID_LIKE` contains the word `rhel`.
For a redirected runner or symlink destination, setup creates a missing
parent directory as `root:root`, mode `0755`; it leaves an existing parent's
metadata unchanged. The completion destination's parent must already exist.

### Launcher checks and failure conditions

Before invoking sudo, the launcher requires all three source files beside
it: `setup-system-infra.bash`, `ioc-runner`, and `ioc-runner-completion.bash`.
Each must be a regular file, not a symbolic link. A missing or unsuitable
source produces `required setup source is not a regular file` and exit 1.

The launcher also requires executable `/usr/bin/sudo`, `/usr/bin/tar`, and
`/bin/bash`. A failed executable check names the command and exits 1.
It rejects root invocation and missing cached sudo credentials with exit 1;
the latter message asks the checkout owner to cache credentials and retry.

The privileged stage extracts the three sources into
`/tmp/ioc-runner-system-setup.XXXXXX` and repeats the regular-file and
non-symlink checks before setup. A failed check exits 1 and names the source.
Exit and interruption handlers remove the stage while preserving the setup
exit status on normal exit. Cleanup refuses a nonempty path outside the
expected `/tmp/ioc-runner-system-setup.*` pattern and exits 1.

### Setup diagnostics and partial deployment

The CLI-only and full forms require executable `/usr/bin/systemctl`.
Container setup instead checks the six s6 tools listed above in `PATH`.
A missing backend tool exits 1 before infrastructure changes.

Full setup resolves procServ before changing accounts or configuration.
When no candidate is executable, it lists the searched paths, recommends
installing procServ or setting `IOC_RUNNER_PROCSERV_PATH`, and exits 1.
The template deployment also aborts if the resolved executable value is empty.

During deployment, `STEP` banners identify the account, configuration,
supervisor, logging, and CLI stages that apply to the selected mode.
Existing accounts and groups produce reuse notices. Each artifact check
prints `Verify PASSED` or `Verify FAILED`; the final `Verification Summary`
reports passed and failed counts. Any recorded verification failure makes
the final exit status 1.

These conditions have distinct outcomes:

- If the sudo version probe fails or its output cannot be parsed, setup
  warns and selects the glob-form policy. The same policy applies to sudo
  versions below 1.9.10; see the [permission model](PERMISSION_MODEL.md#residual-risk-on-sudo--1910-hosts).
- If the generated sudoers policy fails syntax validation, setup exits 1
  before replacing the installed policy.
- If `/etc/sudoers` is missing, lacks the required includedir, or has active
  rules after it, setup records a verification failure. For trailing rules,
  it prints the offending lines and asks you to move includedir to the end
  with `visudo`.
- If the generated system logrotate policy fails validation, setup exits 1
  before replacing that policy. The message says `Skipping deployment`, but
  the setup run stops; it does not continue to CLI deployment.
- If the runner source is missing, direct setup exits 1 and names the path.
  If only the completion source is missing, direct setup prints a skip
  notice and continues. The launcher rejects either missing source earlier.

Setup does not roll back artifacts already deployed when a later stage
fails. Correct the reported condition and rerun setup; inspect the final
verification result before treating the installation as complete.

## Manual setup reference
If you prefer to configure the system manually or need to audit the security changes made by the automated script, follow these steps.

### Account and group setup
Create an isolated service account and a management group.
```bash
# Create the management group
groupadd ioc

# Create the isolated service account with no home directory and no login shell
useradd -r -M -d /nonexistent -g ioc -s /sbin/nologin -c "EPICS procServ Daemon Account" ioc-srv
```

### Shared configuration directory setup
Create the directory where IOC configuration files reside. [PERMISSION_MODEL.md](PERMISSION_MODEL.md) lists the owner and mode it must carry.
```bash
mkdir -p /etc/procServ.d/
chown root:ioc /etc/procServ.d/
chmod 2770 /etc/procServ.d/
```

### Restricted sudoers configuration
Allow members of the `ioc` group to manage only specific `epics-@<name>.service` systemd instances securely.

Sudo requires absolute paths for strict security. Determine the exact path to `systemctl` on your operating system and generate the sudoers file. `setup-system-infra.bash` emits one of two forms based on the local sudo version (OS-agnostic). The canonical regex form (sudo >= 1.9.10) achieves parity with `validate_ioc_name` in `bin/ioc-runner`:
```bash

SYSTEMCTL_BIN="/usr/bin/systemctl"

cat <<EOF > /etc/sudoers.d/10-epics-ioc
%ioc ALL=(root) NOPASSWD: ${SYSTEMCTL_BIN} ^start epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\\.service\$, \\
                          ${SYSTEMCTL_BIN} ^stop epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\\.service\$, \\
                          ${SYSTEMCTL_BIN} ^restart epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\\.service\$, \\
                          ${SYSTEMCTL_BIN} ^status epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\\.service\$, \\
                          ${SYSTEMCTL_BIN} ^enable epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\\.service\$, \\
                          ${SYSTEMCTL_BIN} ^disable epics-@[A-Za-z0-9_][A-Za-z0-9_-]{0,63}\\.service\$, \\
                          ${SYSTEMCTL_BIN} ^daemon-reload\$
EOF

chmod 0440 /etc/sudoers.d/10-epics-ioc

# Required when SELinux is active
/usr/sbin/restorecon /etc/sudoers.d/10-epics-ioc
/usr/sbin/matchpathcon -V /etc/sudoers.d/10-epics-ioc
```

On hosts with sudo < 1.9.10, replace each `^<verb> ... $` form with the glob form (`<verb> epics-@*.service`); the deployment script handles this automatically and emits a `WARN` line plus a residual-risk header comment. The boundary is the `%ioc` sudoers gate, not the argument pattern; see [`PERMISSION_MODEL.md`](PERMISSION_MODEL.md).

> **Note (regex form):** the regex form requires sudo >= 1.9.10 (regex
> command-argument matching); below that version the setup script deploys the
> glob fallback automatically. The block above reproduces the generator's
> single-space spelling exactly - do not re-introduce alignment padding
> between the verb and the pattern, since sudo matches the regex against the
> literal argument string.

> **Important:** The `@includedir /etc/sudoers.d` (or legacy `#includedir`) directive in `/etc/sudoers` must be the final active line. Any user-specific rules placed after it (e.g., `alice ALL=(ALL) ALL`) will be evaluated *after* the drop-in policies and silently override the NOPASSWD rule installed above. Verify with `sudo -l` on a group member account: the `(root) NOPASSWD: /usr/bin/systemctl ...` entry must appear last.

### systemd template unit deployment
Deploy the single systemd template unit (`@.service`) that will dynamically manage all IOC instances system-wide. Resolve the `procServ` path dynamically to accommodate different installation targets (e.g., `/usr/bin` vs `/usr/local/bin`).

**Note on Time Synchronization:** The template explicitly requires `time-sync.target` to ensure that NTP/PTP time synchronization is fully established before the IOC daemon starts. This is critical for maintaining accurate timestamps for the Archiver Appliance and MRF timing systems.

The `StartLimit*` rows must stay in `[Unit]` - a `[Service]` placement is silently rejected on systemd 239 (see ADR 0001, Evidence).


```bash
PROCSERV_BIN=$(command -v procServ)

cat <<EOF > /etc/systemd/system/epics-@.service
[Unit]
Description=procServ for %i
Wants=time-sync.target
After=network.target remote-fs.target time-sync.target
AssertFileNotEmpty=/etc/procServ.d/%i.conf
StartLimitIntervalSec=0
StartLimitBurst=5
StartLimitAction=none

[Service]
Type=simple
User=ioc-srv
Group=ioc
EnvironmentFile=-/etc/procServ.d/site.env
EnvironmentFile=/etc/procServ.d/%i.conf
RuntimeDirectory=procserv/%i
RuntimeDirectoryMode=0770
RuntimeDirectoryPreserve=restart
ExecStart=${PROCSERV_BIN} --foreground --logfile=/var/log/procserv/%i.log --name=%i --ignore=^D^C --autorestartcmd='' --chdir=\${IOC_CHDIR} --port=\${IOC_PORT} \${IOC_CMD}
SuccessExitStatus=0 1 2 15 143 SIGTERM SIGKILL
Restart=always
RestartSec=2
KillMode=mixed
StandardOutput=journal
StandardError=inherit
SyslogIdentifier=epics-%i

[Install]
WantedBy=multi-user.target
EOF

chmod 0644 /etc/systemd/system/epics-@.service
systemctl daemon-reload
```

### Log directory and rotation
Create the directory that receives procServ console output. [PERMISSION_MODEL.md](PERMISSION_MODEL.md) gives the owner, mode, and default ACL of the directory and of the log files, and why the ACL does not reach the procServ logs.
```bash
mkdir -p /var/log/procserv
chown root:ioc /var/log/procserv
chmod 2775 /var/log/procserv

# Default ACLs: engineer-created files inherit ioc-group rw; procServ logs
# stay 0644 (open(0644) restricts the ACL mask to r--, group read only)
setfacl -d -m g:ioc:rw /var/log/procserv
setfacl -d -m o::r-- /var/log/procserv
setfacl -d -m m::rw /var/log/procserv
```

Deploy weekly rotation with `copytruncate` so rotation does not interrupt the running IOC or invalidate its Unix domain socket:
```bash
cat <<EOF > /etc/logrotate.d/procserv
/var/log/procserv/*.log {
    su root ioc
    weekly
    rotate 8
    compress
    missingok
    notifempty
    copytruncate
    nodateext
}
EOF

chmod 0644 /etc/logrotate.d/procserv

# Required when SELinux is active
/usr/sbin/restorecon /etc/logrotate.d/procserv
/usr/sbin/matchpathcon -V /etc/logrotate.d/procserv
```

---

## CLI wrapper and Bash completion deployment
Deploy the frontend management script `ioc-runner` to a standard binary path, and install the Bash completion script to provide context-aware suggestions. The staging launcher in [Automated infrastructure setup](#automated-infrastructure-setup) calls `setup-system-infra.bash` to perform the steps below, including injecting the Git hash, commit date, and install date for traceability. The manual procedure is documented for reference.

```bash
# 1. Copy the main script to the system path
sudo cp bin/ioc-runner /usr/local/bin/ioc-runner

# 2. Inject version traceability information
GIT_HASH=$(git rev-parse --short HEAD 2>/dev/null || printf "unknown")
COMMIT_TS=$(git show -s --format=%ct HEAD 2>/dev/null || printf "")
if [[ -n "${COMMIT_TS}" ]]; then
    COMMIT_DATE=$(date -u -d "@${COMMIT_TS}" +"%Y-%m-%dT%H:%M:%SZ")
else
    COMMIT_DATE="unknown"
fi
INSTALL_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

sudo sed -i "s/^declare -g RUNNER_GIT_HASH=.*/declare -g RUNNER_GIT_HASH=\"${GIT_HASH}\"/" /usr/local/bin/ioc-runner
sudo sed -i "s/^declare -g RUNNER_COMMIT_DATE=.*/declare -g RUNNER_COMMIT_DATE=\"${COMMIT_DATE}\"/" /usr/local/bin/ioc-runner
sudo sed -i "s/^declare -g RUNNER_INSTALL_DATE=.*/declare -g RUNNER_INSTALL_DATE=\"${INSTALL_DATE}\"/" /usr/local/bin/ioc-runner

# 3. Apply execution permissions
sudo chmod 0755 /usr/local/bin/ioc-runner

# 4. Deploy the Bash completion script
sudo cp bin/ioc-runner-completion.bash /etc/bash_completion.d/ioc-runner
sudo chmod 0644 /etc/bash_completion.d/ioc-runner
```

### Bash completion suggestions and limits

The installed completion handler supplies these command and option names,
filtered by the prefix you have typed:

| Kind | Suggestions |
| --- | --- |
| Commands | `generate`, `install`, `remove`, `start`, `stop`, `restart`, `status`, `enable`, `disable`, `view`, `list`, `attach`, `monitor`, `inspect` |
| Options | `--local`, `--user`, `--container`, `-f`, `--force`, `-v`, `-vv`, `--detach-key`, `-V`, `--version`, `-h`, `--help` |
| Value immediately after `--detach-key` | `ctrl-a`, `ctrl-b`, `ctrl-]` |

Completion omits `log`, `-n`, and `--lines`; type those names explicitly.
The three suggested detach keys are a subset of the accepted values in the
[command reference](CLI_REFERENCE.md#attach-readwrite-mode).
Completion suggests options without checking whether the selected command
accepts them; the runner validates their use when you execute it.

For service, console, `view`, `remove`, and `inspect` commands, completion
finds names by listing existing `*.conf` entries and removing the `.conf`
suffix. It does not query service state or validate the configuration content.
The configuration directory is selected as follows:

| Command-line mode | Configuration directory, in precedence order |
| --- | --- |
| Any argument is `--local` or `--user` | `IOC_RUNNER_CONF_DIR`, `IOC_RUNNER_LOCAL_CONF_DIR`, then `${HOME}/.config/procServ.d` |
| Otherwise, including `--container` | `IOC_RUNNER_CONF_DIR`, `IOC_RUNNER_SYSTEM_CONF_DIR`, then `/etc/procServ.d` |

Empty overrides fall through to the next value. Name suggestions depend on
the invoking user's access to the directory and its entries.
For `generate` and `install`, completion suggests filesystem paths.
For `list`, it suggests `-v` and `-vv`; a word beginning with `-` uses the
general option list instead. Immediately after `--detach-key`, the key
suggestions take precedence over command, option, and IOC-name suggestions.

## Shared deployment directory setup (`/opt/epics-iocs`)
Before engineers can deploy IOCs, a shared payload directory must be established. This directory must be accessible and writable by the `ioc` group.

### Local disk deployment
If the IOCs will reside on the local server's filesystem, you must configure the directory with POSIX ACLs (Access Control Lists). This ensures that when individual engineers run `git clone`, the resulting directories and files automatically inherit the `ioc` group ownership and appropriate read/write permissions, overriding their personal `umask` settings.

```bash
sudo mkdir -p /opt/epics-iocs
sudo chown root:ioc /opt/epics-iocs
sudo chmod 2775 /opt/epics-iocs

# Force default ACLs: All newly created files/directories inside will inherit the 'ioc' group
# Directories will be 2775 (rwxrwsr-x), Files will be 0664 (rw-rw-r--)
sudo setfacl -d -m g:ioc:rwx /opt/epics-iocs
sudo setfacl -d -m o::rx /opt/epics-iocs
```

### NFS mount for centralized storage
For environments using a central storage server, ensure the NFS export is configured with the `ioc` GID and `2775` permissions.

Mount the directory persistently via `/etc/fstab`:
```text
# /etc/fstab
nfs-storage.local:/export/epics-iocs  /opt/epics-iocs  nfs  defaults,_netdev  0  0
```

Apply the mount:
```bash
sudo mount /opt/epics-iocs
```

### EPICS environment and shared library permissions
The `ioc-srv` account must have execute (`+x`) and read (`+r`) permissions for the entire EPICS environment where the Base and modules (e.g., `asyn`, `seq`) are installed.

If the EPICS environment is compiled inside a restricted user directory (e.g., `/home/username/epics`), you must ensure the `ioc-srv` user can traverse the parent directories and read the shared libraries. Otherwise, the dynamic linker (`ld.so`) will fail with Exit Code 127.

Example for opening permissions on a local user's EPICS build:
```bash
chmod o+x /home/username
chmod -R o+rx /home/username/epics
```

The same traverse requirement applies to the IOC or `ioc-runner` **source tree**
when it is run in system mode from under a restricted home. Because the
`procServ` daemon runs as `ioc-srv`, a clone kept beneath a `0700` home is
unreachable by the service account. The failure is a plain `Permission denied`
on the path under the home - the account is stopped at the home's traverse bit,
not at the code - and a shell exec of the runner returns exit code `126`
(distinct from the `127` shared-library (`ld.so`) case above). On a distribution
that defaults
interactive homes to `0700` (`HOME_MODE 0700` in `/etc/login.defs`) this is the
default state. Open the parent the same way:

```bash
chmod o+x /home/username
```

Install mode (the world-readable `/usr/local/bin/ioc-runner`) and local mode
(each user runs its own IOCs, traversing its own home as owner) do not need
this.
