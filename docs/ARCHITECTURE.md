# EPICS IOC management architecture

## IOC management architecture

The runner coordinates configuration, service control, and console access.
System and local modes use systemd; container mode uses s6. procServ runs
the IOC child and provides its console in every mode.

### Components and data flow

In system mode, operators configure and control the service while procServ
owns the IOC process and console socket:

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

## Access control and security

### System service accounts

The default service account, `ioc-srv`, runs procServ and its IOC child.
Setup creates an absent account with shell `/sbin/nologin` and home
`/nonexistent`. Operators in the `ioc` group manage shared configurations
and services. See the [permission model](PERMISSION_MODEL.md) for ownership,
modes, and configurable identities.

### Restricted sudoers configuration

System mode delegates privileged operations through
`/etc/sudoers.d/10-epics-ioc`, using the fixed `/usr/bin/systemctl` path.
Sudo 1.9.10 or later supports an anchored argument regex for IOC instances.
Older sudo uses a glob that can authorize unrelated services; see the
[glob-policy risk](PERMISSION_MODEL.md#residual-risk-on-sudo--1910-hosts).
The [installation reference](INSTALL.md#restricted-sudoers-configuration)
contains the policy text.

## Core management components

### Setup launcher

`bin/run-setup-system-infra.bash` reads setup sources as the checkout owner
and stages them locally before invoking privileged setup. Root therefore
needs no access to an NFS checkout. The temporary stage is removed on exit;
see the [setup checks](INSTALL.md#launcher-checks-and-failure-conditions).

### systemd template unit (`epics-@.service`)

Each system IOC is an instance of `/etc/systemd/system/epics-@.service`.
The instance name selects its configuration, such as
`/etc/procServ.d/myioc.conf` for `epics-@myioc.service`. Local mode uses a
shared user template. Both load optional `site.env` before the per-IOC file;
see [environment layering](NETWORK_ENV.md#how-an-ioc-receives-its-network-environment).

### ioc-runner wrapper script

The Bash CLI validates and installs `.conf` files, then controls the selected
service manager. System mode uses sudo for privileged operations by non-root
callers; local mode uses the invoking user's manager. Container mode renders
an s6 service instead of a systemd unit.

#### Internal log-path probe

The runner probes the effective log directory with a create-write-sync-delete
transaction. A failed probe blocks system/local `start` and `restart`.
`inspect` reports probe failure as a warning: system inspection uses the
validated unit user/group pair, local inspection uses the invoking user, and
container inspection skips the probe. The helper rejects an incomplete
identity pair internally; public callers do not supply one.

### con for local console access

`con` connects a terminal to the UNIX domain socket (UDS) that procServ owns.
`attach` sends input and receives output; `monitor` receives output only.
Supported clients, keys, and production limitations are in the
[console reference](CLI_REFERENCE.md#console-access-with-attach-and-monitor).

### s6 service directory (`--container` mode)

The container entrypoint runs `s6-svscan` as PID 1. Each installed IOC has a
service directory under `/run/s6-procserv`, with its own `s6-supervise` process:

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

`install` renders a service directory with `run`, `timeout-kill` (90000 ms),
and, for a new service, `down`. The `run` script prepares the socket parent as
root, then runs procServ as `ioc-srv`. Preparation failure stops that launch.
The entrypoint must restore service definitions and enable state when `/run`
is recreated; an empty scan directory does not restore installed IOCs.

s6 supervises procServ, restarting it after a fixed one-second delay;
procServ supervises the IOC child. IOC output goes to container stdout through
`--logfile=-`. Container mode requires root and s6 2.13 or later, and uses
neither sudoers nor systemd. See [container setup](INSTALL.md#container-images---container)
for requirements and [container operations](USER_GUIDE.md#run-iocs-in-container-mode)
for the workflow.
