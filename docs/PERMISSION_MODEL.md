# Filesystem permission model

This page gives the owner, mode, and ACL of every directory and file that
the setup script and the runner install, reference, or create, and the
principals that can create, manage, and read each one.

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

The runner's `IOC_CHDIR` writability check is satisfied by directory
group ownership and mode, not by an ACL. The `ioc-srv` account is in
the `ioc` group, so the shared payload permissions listed above let it create
runtime artifacts such as `.iocsh_history`, autosave files, and
save/restore state directly. This is the directory group-write bit
acting on the directory itself. It is distinct from the default ACL on
the log directory (see [Why the log directory carries default ACLs](#why-the-log-directory-carries-default-acls)), which governs
the ACL permissions and mask inherited by newly created entries, not
write access to the parent directory. `IOC_CHDIR` needs the group-write
model, not a default ACL.

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
falls back to the passwd database and, failing that, to `/tmp` - and a
`/tmp`-fallback HOME is treated as untrusted: `${HOME}/.local/bin` is then
excluded from the `con`/`procServ` executable search, so a world-writable
fallback home can never supply the executables the runner runs.

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

- Only members of the `ioc` group can have `ioc-runner` succeed in
  `start` / `stop` / `restart` / `enable` / `disable` /
  `daemon-reload` operations on `epics-@<name>.service` instances.
  For non-`ioc` users, the `sudo systemctl ...` call inside
  `ioc-runner` fails at the sudo gate.
- `ioc-runner` execution itself is not restricted - any user can
  invoke the script. The gate is the privileged systemctl
  invocation it makes internally.
- Read-only paths (`ioc-runner status`, `is-active`, `cat`, `show`)
  do not go through `sudo`. They rely on systemd's own permission
  for those queries (typically permissive) and on file system
  permissions for any log file reads.

File-mode permissions and default ACLs reinforce the boundary at
the file system layer: who can read log files, who can write, and
who can create files in the log directory.

Conf-file integrity follows the same containment principle: the runner
accepts any readable `.conf` regardless of its file mode - a group-writable
conf is the designed norm (any `ioc` engineer manages any IOC), and a
world-writable conf is neither detected nor rejected - so the integrity
boundary is directory containment (the [setup-managed configuration
directory](#setup-managed-paths) in system mode; the user's home in local
mode), not a per-file mode check. Do
not store secrets in a `.conf`: every key is exported into the procServ
process environment and inherited by the IOC process (see [IOC configuration metadata](FAQ.md#can-ioc-configuration-files-include-metadata)).

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

procServ uses `open(O_CREAT, 0644)` internally (`procServ.cc:924`,
`S_IRUSR|S_IWUSR|S_IRGRP|S_IROTH`). No upstream change is made;
the system unit carries no `UMask=` directive so the default system
umask `0022` preserves the file permissions listed above.

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

The lifecycle of every log object covers three operational phases:
Create, Manage, and Track (read).

### System mode

| Phase | Action | Principal | Object | Mechanism | Resulting state / Gate |
| --- | --- | --- | --- | --- | --- |
| Create | install log directory | `root` (via sudo) | `${SYSTEM_LOG_DIR}/` | `setup-system-infra.bash`: `install -d -o root -g ioc -m 2775` + `setfacl -d` | [System log permissions](#system-mode-log-directory-and-files) |
| Create | open log file | `ioc-srv` | `${SYSTEM_LOG_DIR}/<ioc>.log` | procServ `open(O_CREAT, 0644)` at IOC start; system unit umask `0022` | [System log permissions](#system-mode-log-directory-and-files) |
| Create | adhoc file (probe, manual archive) | engineer in `ioc` | `${SYSTEM_LOG_DIR}/<adhoc>` | shell `touch` (setgid + default ACL applied) | [System log permissions](#system-mode-log-directory-and-files) |
| Manage | preflight log-path probe for `start` / `restart` | engineer in `ioc` | effective `--logfile` directory | `ioc-runner` create-write-sync-delete transaction before systemd | shared-filesystem capacity and group-write availability; failure blocks the transition |
| Manage | append log records | `ioc-srv` | `<ioc>.log` | procServ `write(logFileFD, ...)` during IOC runtime | owner `w` bit |
| Manage | start / stop / restart IOC | engineer in `ioc` (sudo) | `epics-@<ioc>.service` | `ioc-runner` -> `sudo /usr/bin/systemctl ...` | sudoers gate `%ioc ALL=(root) NOPASSWD: ...` against `epics-@<name>.service` (regex form on sudo >= 1.9.10, glob fallback otherwise) |
| Manage | rotate (system mode, deployed) | `root` (the distribution's logrotate schedule) | `<ioc>.log` | `logrotate` with `/etc/logrotate.d/procserv` and `copytruncate` | mode and owner preserved; archives `<ioc>.log.N.gz` |
| Track | crash detection scan | engineer in `ioc` | `<ioc>.log` | `ioc-runner` byte-offset scan (no sudo, engineer's UID) | group `r--` grants read |
| Track | manual read | engineer in `ioc` | `<ioc>.log` | `cat` / `tail` / `grep` | group `r--` grants read |
| Track | read-only inspection | engineer outside `ioc` | `<ioc>.log` | direct shell read | dir `o+rx` traversal + file `o+r` |
| Track | `inspect` log-path and executable identity | `root`; probe changes to effective unit `User=` and `Group=` | effective log directory, `MainPID`, UDS, procServ executable | fixed `/usr/sbin/runuser -u <User> -g <Group>` probe plus read-only `/proc` and systemd queries | warnings only; no service-state change or nested sudoers rule |
| Track | directory listing | any user | `${SYSTEM_LOG_DIR}/` | `ls` | dir `o+rx` |
| Track | `ioc-runner status` / `is-active` | any user | service state | systemd query (no sudo) | systemd query ACL (permissive) |

### Local mode

| Phase | Action | Principal | Object | Mechanism | Resulting state |
| --- | --- | --- | --- | --- | --- |
| Create | install log directory | `<user>` | `${LOG_DIR}/` (local mode; default `${LOCAL_LOG_DIR}`) | `ioc-runner --local install`: `install -d -m 0750` | [Local log permissions](#local-mode-log-directory-and-files) |
| Create | open log file | `<user>` (via `systemd --user`) | `${LOG_DIR}/<ioc>.log` | procServ `open(O_CREAT, 0644)` + user unit `UMask=0027` | [Local log permissions](#local-mode-log-directory-and-files) |
| Manage | preflight log-path probe for `start` / `restart` | `<user>` | effective `--logfile` directory | create-write-sync-delete transaction before `systemctl --user` | failure blocks the transition |
| Manage | append / IOC lifecycle | `<user>` | log file, user unit | `systemctl --user ...` (no sudo) | self-managed |
| Track | crash scan / shell read | `<user>` | `<ioc>.log` | `ioc-runner --local`, `cat`, `tail` | owner `r` |
| Track | `--local inspect` log-path and executable identity | `<user>` | effective log directory, `MainPID`, UDS, procServ executable | unprivileged probe plus read-only `/proc` and user-systemd queries | warnings only; no service-state change |

### Container mode

| Phase | Action | Principal | Object | Mechanism | Resulting state |
| --- | --- | --- | --- | --- | --- |
| Create | scan directory | `root` (entrypoint) | `/run/s6-procserv/` | `mkdir` before `s6-svscan` starts as PID 1 | [Container paths](#container-mode-paths) |
| Create | service directory | `root` | `/run/s6-procserv/<ioc>/` | `ioc-runner --container install` renders `run`, `timeout-kill`, `down`, then `s6-svscanctl -a` | [Container paths](#container-mode-paths) |
| Create | socket directory | `root` | `/run/procserv/<ioc>/` | generated `run` script and CLI `start`/`restart`: `install -d -m 0770 -o ioc-srv -g ioc` | [Console socket permissions](#console-socket-permissions) |
| Create | control socket | `ioc-srv` | `/run/procserv/<ioc>/control` | procServ `--port=unix:ioc-srv:ioc:0660:...` | [Console socket permissions](#console-socket-permissions) |
| Manage | start / stop / restart | `root` | s6 service | `s6-svc -u -wu` / `-d -wd` / `-r -wr` with a bounded wait; readiness is the socket appearing | no sudoers gate; root-only |
| Manage | enable / disable | `root` | `down` file | remove / create `down` | starts or stays down at `s6-svscan` boot; the running IOC is untouched |
| Manage | restart of a dead procServ | `s6-supervise` | `run` | fixed one-second delay | stands in for `Restart=always` |
| Track | IOC output | any reader of the container stdout | `s6-svscan` stdout | procServ `--logfile=-` | `docker logs` or the runtime's log driver; no log file |
| Track | `status` / `list` | `root` | s6 state | `s6-svstat`, `/proc` | read-only |
| Track | `inspect` executable identity | `root` | supervised PID, UDS, procServ executable | `s6-svstat -o pid` plus read-only `/proc`; needs `CAP_SYS_PTRACE` in the container | warnings only |

## Why the log directory carries default ACLs

procServ's fixed `open(0644)` mode restricts the access ACL mask of the files
it creates to `r--` (no group write). The default ACLs serve two other
purposes:

1. **Engineer-created files in the log directory** (manual probe
   files, rotated archive copies created by an engineer) inherit
   group `ioc` with `rw` access. Without the default ACL, an
   engineer-created file under `umask 0022` would grant the group read access
   only. setgid supplies the group identity, while the default ACL supplies
   group write access. The resulting permissions are in the
   [system log table](#system-mode-log-directory-and-files).
2. **Cross-creator consistency** of group membership. setgid on the
   directory enforces the `ioc` group on every newly created entry
   regardless of the creator's primary group; the default ACL
   reinforces the same with explicit mask handling.

## How the model is set up

System mode setup is performed once at install time by
`setup-system-infra.bash`, running as `root` via `sudo`:

```bash
install -d -o root -g ioc -m 2775 "${SYSTEM_LOG_DIR}"
setfacl -d -m g:ioc:rw "${SYSTEM_LOG_DIR}"
setfacl -d -m o::r-- "${SYSTEM_LOG_DIR}"
setfacl -d -m m::rw "${SYSTEM_LOG_DIR}"
```

The system unit (`/etc/systemd/system/epics-@.service`) does NOT
set `UMask=`. systemd's default for system units is `0022`, which
preserves procServ's creation mode through to the resulting file.
`LogsDirectory=procserv` is intentionally NOT used in the unit -
the directive would chown the log directory to the unit's `User=`
/ `Group=` on every activation, overriding the log-directory ownership
specified in [System log permissions](#system-mode-log-directory-and-files).

Local mode setup is performed by `ioc-runner --local install` under
the invoking user:

```bash
install -d -m 0750 "${LOG_DIR}"
```

The local user systemd template carries `UMask=0027` so that
procServ-created logs have the [local log permissions](#local-mode-log-directory-and-files).

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

Note that wide read sits at the file-mode layer only. The sudoers
policy restricts the privileged `systemctl start`/`stop`/`restart`/
`enable`/`disable`/`daemon-reload` calls that `ioc-runner` makes
internally in system mode to `%ioc` group members. Non-`ioc` users
can run the `ioc-runner` binary itself and can `cat` the log
directly, but any IOC state change attempted through `ioc-runner`
fails at the sudo gate inside the script.

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

The `systemd-journal` group reads the entire host journal - sshd
authentication, kernel events, sudo usage, and every unrelated service -
not only IOC logs. Granting it to IOC operators exposes far more than their
role needs, so operators are not members of that group, and no procedure
adds them: the membership would reopen the same broad exposure. Crash
detection reads the dedicated log file as the single source of truth,
with no journal dependency to restore, so the supported recovery is to
fix the log-file path - not to widen operator privilege.

## Related permission documentation

- Architecture: [`ARCHITECTURE.md`](ARCHITECTURE.md)
- CLI surface: [`CLI_REFERENCE.md`](CLI_REFERENCE.md)
- Log paths and rotation: [`LOG_LAYOUT.md`](LOG_LAYOUT.md)
