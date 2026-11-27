# Filesystem permission model

This page describes ownership, modes, and ACLs for managed configuration,
service, socket, log, and backup paths, together with site-provisioned
dependency requirements and the principals that manage or read them.

Scope:

- System-mode paths managed by `setup-system-infra.bash`
- Site-provisioned paths the runner only reads (procServ binary,
  EPICS base, `/opt/epics-iocs/`)
- Local-mode paths created by `ioc-runner --local install`
- Container-mode paths created by `setup-system-infra.bash --container` and
  `ioc-runner --container`
- Three-principal model and end-state targets for the log directory
- Permission lifecycle (Create / Manage / Track) per principal

## Managed filesystem paths

### Setup-managed paths

Paths created or installed by `setup-system-infra.bash`, which sets the owner
and mode of each one when it deploys it. A re-run restores the owner, mode,
and default ACL of the log directory.

| Path | Owner:Group | Mode | Variable | Notes |
| --- | --- | --- | --- | --- |
| `/etc/procServ.d/` | `root:ioc` | `2770` (setgid) | `CONF_DIR` / `PERM_CONF_DIR` | per-IOC `.conf` files; group rw for engineers |
| `/etc/sudoers.d/10-epics-ioc` | `root:root` | `0440` | `SUDOERS_FILE` / `PERM_SUDOERS` | sudo policy granting `%ioc` the privileged systemctl verbs |
| `/etc/systemd/system/epics-@.service` | `root:root` | `0644` | `SYSTEMD_TEMPLATE` | system-mode unit template |
| `/var/backups/epics-ioc-runner/` | `root:root` | `0700` | `BACKUP_DIR` / `PERM_BACKUP_DIR` | created at the first backup; holds `cp -a` copies of the sudoers file, unit template, logrotate policy, runner, and completion taken before setup replaces them |
| `/usr/local/bin/ioc-runner` | `root:root` | `0755` | `RUNNER_SCRIPT_DEST` | runner script |
| `/usr/bin/ioc-runner` | symlink -> `/usr/local/bin/ioc-runner` | - | `RUNNER_SCRIPT_SYMLINK` | RHEL-family `secure_path` workaround |
| `/etc/bash_completion.d/ioc-runner` | `root:root` | `0644` | `BASH_COMP_DEST` | tab completion |
| `/etc/logrotate.d/procserv` | `root:root` | `0644` | `LOGROTATE_FILE` / `PERM_LOGROTATE` | weekly rotation policy for the system log directory |

The system log directory, its files, and their default ACL are specified in
[System mode log directory and files](#system-mode-log-directory-and-files).

### Site-provisioned paths

Paths the runner references but does not manage. The site is
responsible for owner and mode at provisioning time (typically via
`cloud-provision` / `ansible-provision`).

| Path | Typical Owner:Group | Typical Mode | Source | Runner's role |
| --- | --- | --- | --- | --- |
| `/opt/epics-iocs/` | `root:ioc` | `2775` | site provisioning | `bin/ioc-runner` runs a metadata-based model-conformance check on `IOC_CHDIR` |
| `/opt/epics-iocs/epics/<base-suite>/<distro>/<base-ver>/base` | site | site-defined | site provisioning | unused by the runner - IOC `.conf` references it via environment |
| `/usr/local/bin/procServ` or `/usr/bin/procServ` | site | site-defined | package or site build | discovered via `PROCSERV_SEARCH_PATHS` |

`IOC_CHDIR` must grant the service account group write and traversal access.
The runner checks directory metadata, not effective ACL access. Default ACLs
on the payload tree preserve permissions on newly created checkout entries;
see [deployment setup](INSTALL.md#shared-deployment-directory-setup-optepics-iocs).
The log directory has a separate default ACL and creation-mode contract below.

The service identity itself is configurable from a single source:
both `bin/ioc-runner` and `bin/setup-system-infra.bash` resolve
`IOC_RUNNER_SYSTEM_USER` / `IOC_RUNNER_SYSTEM_GROUP` with the shipped
defaults `ioc-srv` / `ioc`. A site deploying under a different account
or group sets the two variables once, for both the setup run and every
runner invocation. The staging launcher forwards both variables across the
sudo boundary; set them on the launcher invocation, as [INSTALL.md](INSTALL.md)
shows.

### Local-mode paths

Paths created by `ioc-runner --local install` under the invoking
user's account. The log directory and files have their own
[permission table](#local-mode-log-directory-and-files).
Here `<user>` is the invoking account and `<primary-group>` is its primary
group, returned by `id -un` and `id -gn`, respectively; the names can differ.

| Path | Owner:Group | Mode | Variable | Notes |
| --- | --- | --- | --- | --- |
| `~/.config/procServ.d/` | `<user>:<primary-group>` | umask-dependent | `CONF_DIR` | created by the first `--local install` with `mkdir -p` |
| `~/.config/procServ.d/<ioc>.conf` | `<user>:<primary-group>` | `0600` | - | staged with `mktemp` and renamed into place |
| `~/.config/systemd/user/epics-@.service` | `<user>:<primary-group>` | `0600` | - | staged with `mktemp` and renamed into place by `deploy_local_template` |
| `~/.config/systemd/user/epics-@.service.bak.*` | `<user>:<primary-group>` | the replaced template's mode | - | the previous template, kept when an update replaces it; the three newest are kept |
| `~/.config/ioc-runner/` | `<user>:<primary-group>` | `0700` | - | local logrotate config dir (M19/#103), created by `deploy_local_logrotate` |
| `~/.config/ioc-runner/logrotate.conf` | `<user>:<primary-group>` | `0600` | - | mktemp-staged; deployed when absent; when it differs from the shipped content, `--local install` asks on a terminal, keeps it without one, and replaces it with `-f` |
| `~/.config/systemd/user/epics-logrotate.service`, `.timer` | `<user>:<primary-group>` | `0600` | - | oneshot rotation service + hourly timer; timer enabled, service never |
| `/run/user/<uid>/ioc-runner-logrotate.state` | `<user>:<primary-group>` | logrotate-managed | - | rotation state, host-local via the `%t` specifier |

When `HOME` is unset (bare sudo, some cron/systemd contexts) the runner
falls back to the passwd database and, failing that, to `/tmp`. A
`/tmp`-fallback HOME is treated as untrusted: `${HOME}/.local/bin` is
excluded from the default `con`/`procServ` search paths. Explicit
`IOC_RUNNER_CON_TOOL` and `IOC_RUNNER_PROCSERV_TOOL` overrides are validated
separately and are not excluded by this HOME fallback rule.

## Access boundary: sudoers policy and file mode

An installed system configuration is owned by the operator who ran `install`,
because the runner creates a temporary file and renames it into place.
In the default setgid configuration directory, its group is `ioc`.
Container installation uses the same replacement operation as root.
The local template has `WantedBy=default.target`, so enabling an IOC links
its instance to the user's default target.

The sudoers policy at `/etc/sudoers.d/10-epics-ioc` gates the
privileged state-changing systemctl verbs that `ioc-runner` issues
in system mode. `setup-system-infra.bash` emits one of two forms
based on the local sudo version (decided by
`sudo_supports_regex_args`, OS-agnostic):

- sudo >= 1.9.10: an anchored regular expression per verb that accepts the
  same IOC names as `validate_ioc_name` in `bin/ioc-runner`, and
  `daemon-reload`. [INSTALL.md](INSTALL.md) shows the exact policy text.

- sudo < 1.9.10: glob fallback (`epics-@*.service`), broader than
  the runner IOC-name model. See the residual-risk subsection below.

Effective scope:

- For non-root callers, the shipped sudoers policy grants members of the
  configured operator group (`ioc` by default) the listed privileged
  systemctl operations. Root invokes systemctl directly. Other administrative
  grants are controlled by the host's sudo policy. Configuration-directory
  or log-path permissions may reject a non-root caller before sudo;
  calls that reach sudo require an applicable grant.
- `ioc-runner` execution itself is not restricted - any user can
  invoke the script. The gate is the privileged systemctl
  invocation it makes internally.
- `ioc-runner status` queries systemd without sudo. The runner also makes
  internal `systemctl is-active`, `is-enabled`, `cat`, and `show` queries
  without sudo; those names are not public ioc-runner commands. Access to
  unit state and log files still depends on systemd and filesystem permissions.

File-mode permissions and default ACLs reinforce the boundary at
the file system layer: who can read log files, who can write, and
who can create files in the log directory.

Conf-file integrity follows the same containment principle: the runner
accepts any readable `.conf` regardless of its file mode - a group-writable
conf is the designed norm (any `ioc` engineer manages any IOC), and a
world-writable conf is neither detected nor rejected - so the integrity
boundary is directory containment (the [setup-managed configuration
directory](#setup-managed-paths) in system mode; the user's home in local
mode), not a per-file mode check. Do not store secrets in a `.conf`. In System and Local modes, every key is exported into the procServ process environment and inherited by the IOC process (see [IOC configuration metadata](FAQ.md#can-ioc-configuration-files-include-metadata)).

### Residual risk on sudo < 1.9.10 hosts

The glob fallback (`epics-@*.service`) matches the complete command-argument
string. Its `*` can span whitespace and additional unit arguments, so the
policy can authorize operations on unrelated services.

For example, the arguments `start epics-@myioc.service sshd.service`
match the glob policy. systemctl treats them as two unit names, not as one
malformed IOC name. Unit-name escaping and a root-owned IOC template do not
prevent this authorization.

The runner validates one IOC name per invocation, but an operator can invoke
systemctl directly through sudo. The operator group therefore has broader
privileges under this fallback than the runner's command interface exposes.
Sites requiring delegation restricted to IOC instances must use the anchored
regex policy or a separately validated site policy that restricts each unit
argument.

`setup-system-infra.bash` emits a `WARN` line at generation time when the
glob form is selected. The warning and generated policy comments identify
the authorization of unrelated services.

### Container-mode paths

Paths used by `ioc-runner --container` inside a systemd-less container image.
The configuration directory follows the [setup-managed path](#setup-managed-paths).
Container installation replaces each conf as root using the file mode
described in the [install reference](CLI_REFERENCE.md#the-install-command).
s6 replaces systemd as the supervisor. The generated `run` script and CLI
`start`/`restart` create the socket
directory, whose ownership and mode follow
[Console socket permissions](#console-socket-permissions).

| Path | Owner:Group | Mode | Variable | Notes |
| --- | --- | --- | --- | --- |
| `/run/s6-procserv/` | `root:root` | `0755` | `SCAN_DIR` (`IOC_RUNNER_SCAN_DIR`) | scan directory; the container entrypoint creates it before `s6-svscan` (setup's build-time copy is a convenience) |
| `/run/s6-procserv/<ioc>/` | `root:root` | `0755` | - | service directory rendered by `install`; deleted by `remove` |
| `/run/s6-procserv/<ioc>/run` | `root:root` | `0755` | - | POSIX sh script: prepares the socket parent as root, then `exec s6-setuidgid ioc-srv procServ ... --logfile=-`; preparation failure exits 1 |
| `/run/s6-procserv/<ioc>/down`, `timeout-kill` | `root:root` | umask-dependent, `0644` under `umask 022` | - | `down` present while disabled; `timeout-kill` holds the SIGKILL grace period (ms) |
| `/run/s6-procserv/<ioc>/supervise/`, `event/` | `root:root` | s6-managed | - | created and owned by `s6-supervise` |

## Three-principal model (system mode)

The system-wide mode has three distinct principals against the log
directory and log files. A fourth class - any user outside `ioc` -
has read-only access via the directory's `o+rx` bits and the file's
`o+r` bit.

| Principal | Role | Required access |
| --- | --- | --- |
| `root` | install | create directories; verify ownership and mode at install time |
| `ioc-srv` | operate | write log records during procServ execution |
| engineer in `ioc` group | manage | read logs (status, crash detection); engineer-created files in the dir get group `ioc` write |
| any user (other) | observe | read logs and list the directory at the file-mode layer |

The `--local` mode is single-principal by construction (one
engineer is install, operate, manage, and observe at the same
time). It does not use the three-principal model.

The `--container` mode is root-only: root installs, manages, and
observes, and the runner rejects a non-root EUID. `ioc-srv` still
operates procServ, but the `ioc` group holds no operator role; it
remains only the owning group of the socket directory and the
configuration files, so a future non-root reader can be granted
access without changing the layout.

## Required ownership and permissions

### System mode log directory and files

| Object | Owner:Group | Mode | Default ACL | Creator |
| --- | --- | --- | --- | --- |
| `${SYSTEM_LOG_DIR}/` | `root:ioc` | `2775` (setgid) | `g:ioc:rw`, `o::r--`, `m::rw` | `setup-system-infra.bash` at install time |
| `${SYSTEM_LOG_DIR}/<ioc>.log` (procServ-created) | `ioc-srv:ioc` | `0644` | (inherited from parent default ACL) | procServ at IOC start: `open(O_CREAT, 0644)` |
| `${SYSTEM_LOG_DIR}/<adhoc>` (engineer-created) | `<engineer>:ioc` | `0664` | (default ACL `g:ioc:rw` raises mask above `0644`) | engineer's shell `touch` under default `umask 0022` |

Result by principal on a procServ-created `<ioc>.log`:

| Principal | Bit | Effect |
| --- | --- | --- |
| `ioc-srv` (owner) | `rw-` | append log entries during procServ runtime |
| `ioc` group (engineer) | `r--` | read via `cat`, `tail`, `grep`, crash detection scan |
| other | `r--` | read at the file-mode layer; state-changing IOC management through `ioc-runner` remains sudoers-gated |

procServ creates logs with mode `0644`, limiting the inherited ACL mask to
group read. The system unit leaves `UMask=` unset.

### Local mode log directory and files

`LOG_DIR` defaults to `LOCAL_LOG_DIR` in local mode. For path overrides,
see [Log path configuration](LOG_LAYOUT.md).

| Object | Owner:Group | Mode | Creator |
| --- | --- | --- | --- |
| `${LOG_DIR}/` (local mode; default `${LOCAL_LOG_DIR}`) | `<user>:<primary-group>` | `0750` | `bin/ioc-runner` `do_install` local branch |
| `${LOG_DIR}/<ioc>.log` | `<user>:<primary-group>` | `0640` | procServ at IOC start, with user-mode unit `UMask=0027` |

Local mode keeps `UMask=0027` in the user-mode unit. The engineer
is the only principal. The file permissions listed above give their primary
group read access and deny access to other users on the host.

## Console socket permissions

The console UNIX domain socket involves two objects with two distinct modes;
they must not be conflated:

| Object | System and container modes | Local mode | Mode | Created by |
| --- | --- | --- | --- | --- |
| Socket directory `${RUN_DIR}/<ioc>/` | `/run/procserv/<ioc>/`, `ioc-srv:ioc` | `/run/user/<uid>/procserv/<ioc>/`, `<user>:<primary-group>` | `0770` | systemd runtime directory; container mode uses the generated `run` script and CLI `start`/`restart` |
| Socket file `control` | `ioc-srv:ioc` | `<user>:<primary-group>` | `0660` | procServ, per the `IOC_PORT` spec `unix:<user>:<group>:0660:<path>` emitted by `process_ioc_port` |

`RuntimeDirectoryPreserve=restart` keeps the socket directory in place
across a systemd-driven auto-restart, so the socket path stays stable and a
console can re-attach at the same path once procServ is revived; a client
attached at the moment procServ dies still sees EOF. Console continuity
across IOC child restarts needs no systemd directive - procServ holds the
socket open while only the child dies. The socket directory is not
traversable outside the owning group: for non-`ioc` users `ioc-runner list`
shows no sockets and prints a permission hint (#94). In the attach path the
conf-directory gate described in [Setup-managed paths](#setup-managed-paths) is reached first; the socket
boundary sits behind it.

## Permissions through the IOC lifecycle

Ownership is established at setup or installation and used during operation:

| Mode | Create and configure | Operate | Read and inspect |
| --- | --- | --- | --- |
| System | Root sets shared paths; operators install IOC confs | `ioc-srv` writes logs; operators control units through sudo | Logs are readable by default; full `inspect` requires root |
| Local | Invoking user creates configuration, units, and logs | Same user controls user units and rotation timer | Same user reads logs and runs `inspect` |
| Container | Root creates confs and s6 service directories | s6 starts procServ as `ioc-srv`; root controls services | Runtime log readers see stdout; full `inspect` needs `CAP_SYS_PTRACE` |

System/local `start` and `restart` probe the effective log directory as the
invoking operator before changing service state. System `inspect` instead
probes as the effective unit user/group; local inspection uses its owner.
Inspection warnings do not themselves change service state or fail the command.
See [startup checks](CLI_REFERENCE.md#the-start-and-restart-commands) and
[inspection checks](CLI_REFERENCE.md#procserv-executable-identity-check).

Rotation runs as root in system mode and as the user in local mode;
[log layout](LOG_LAYOUT.md) defines scheduling and retention. Container mode
has no runner-managed log file or rotation policy.

## Why the log directory carries default ACLs

setgid makes created entries inherit group `ioc`. The directory default ACL
gives group write access to files created with a permissive creation mode,
such as an operator's `touch` under `umask 0022`.

procServ explicitly creates logs with `0644`, which limits their inherited ACL
mask to group read. The default ACL cannot add group write beyond that
creation mode. Both results are listed in the
[system log table](#system-mode-log-directory-and-files).

## How the model is set up

System setup creates the shared log directory and its default ACL;
[manual setup](INSTALL.md#log-directory-and-rotation) shows the commands.
The system template does not use `LogsDirectory=`, which would change
directory ownership on activation. Directory metadata remains under setup
control.

Local `install` creates a `0750` log directory and deploys a user template with
`UMask=0027`. Its resulting log permissions are in the
[local log table](#local-mode-log-directory-and-files).

## Verification

System mode (after `setup-system-infra.bash` + IOC start):

```bash
stat -c '%U:%G %a' /var/log/procserv
# expected: root:ioc 2775

getfacl -p /var/log/procserv | grep -E 'default:'
# expected (order may vary):
#   default:user::rwx
#   default:group::rwx
#   default:group:ioc:rw-
#   default:mask::rw-
#   default:other::r--

stat -c '%U:%G %a' /var/log/procserv/<ioc>.log
# expected: ioc-srv:ioc 644
```

Engineer-side access probes (run as a user in the `ioc` group):

```bash
cat /var/log/procserv/<ioc>.log              # succeeds (group r--)
```

Engineer-created file in the directory (default ACL effect):

```bash
(umask 0022; touch /var/log/procserv/probe.log)
stat -c '%U:%G %a' /var/log/procserv/probe.log
# expected: <engineer>:ioc 664
```

A user outside the `ioc` group:

```bash
sudo -u nobody cat /var/log/procserv/<ioc>.log
# succeeds: dir 2775 grants o+rx traversal; file 0644 grants o+r
```

Wide log access is a filesystem permission. Privileged systemctl operations
by non-root callers require an applicable sudo grant; the shipped policy
grants them to the configured operator group. Root calls systemctl directly.
Configuration-directory or log-path checks can reject a command before sudo
is invoked.

Local mode, with `XDG_STATE_HOME` and the log directory overrides unset
(after `ioc-runner --local install <conf>` and IOC start):

```bash
stat -c '%U:%G %a' ~/.local/state/procserv
# expected: <user>:<primary-group> 750

stat -c '%U:%G %a' ~/.local/state/procserv/<ioc>.log
# expected: <user>:<primary-group> 640
```

## Log access for crash detection

`start` and `restart` scan the IOC log file in the same `ioc-runner` process
that the operator invoked, under the operator's UID and without `sudo`. The
permission model above is the precondition: members of the `ioc` group can
`stat`, `tail`, and `grep` the log file directly, without `sudo` and without
membership in the `systemd-journal` group.

### No journal-group re-grant

The `systemd-journal` group grants access to unrelated host events as well as
IOC diagnostics. Do not grant it to repair startup detection: the runner reads
the dedicated IOC logfile. Restore the logfile's path and read permissions
instead.

## Related permission documentation

- Architecture: [`ARCHITECTURE.md`](ARCHITECTURE.md)
- CLI surface: [`CLI_REFERENCE.md`](CLI_REFERENCE.md)
- Log paths and rotation: [`LOG_LAYOUT.md`](LOG_LAYOUT.md)
