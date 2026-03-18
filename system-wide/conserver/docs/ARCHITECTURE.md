# EPICS IOC conserver Integration Architecture

## 1. Overview

This document describes the architecture for integrating `conserver` with the
`epics-ioc-runner` management environment. The goal is to provide centralized,
multi-user console access to EPICS IOCs running under `procServ` across multiple
IOC servers, without modifying the existing `ioc-runner` deployment model.

---

## 2. Base Environment

| Component       | Detail                                          |
|-----------------|-------------------------------------------------|
| IOC servers     | Rocky 8.10                                      |
| Central server  | Rocky 8.10 (conserver daemon)                   |
| IOC management  | systemd + procServ + ioc-runner                 |
| IOC console     | con (UNIX Domain Socket client)                 |
| UDS path        | `/run/procserv/<ioc-name>/control` (mode 0660)  |
| Access control  | `ioc` group + `/etc/sudoers.d/10-epics-ioc`     |
| conserver port  | TCP 7782 (default)                              |

---

## 3. Architecture

```
[ Engineer ]
     |
     | console <ioc-name>              (conserver client, any host)
     |
[ Central Server ] Rocky 8.10
  - conserver daemon (1 instance)
  - SSH key: /etc/conserver/id_ed25519
     |
     | type exec + SSH (key-based, BatchMode)
     | ssh conserver-svc@<ioc-host> con -c /run/procserv/<ioc-name>/control
     |
[ IOC Server N ] Rocky 8.10
  - procServ  -->  /run/procserv/<ioc-name>/control  (UDS, 0660, ioc group)
  - con            (local UDS client, SSH exec target for conserver)
  - systemd:       epics-@<ioc-name>.service
  - /etc/procServ.d/<ioc-name>.conf
```

---

## 4. Key Design Decisions

**conserver uses `type exec` + SSH, not `type uds`.**
`type uds` is local-only. conserver reaches IOC servers over SSH and invokes
`con -c <uds-path>` on each IOC server. This requires no new open ports on IOC
servers and reuses the existing SSH infrastructure.

**`con` remains on every IOC server.**
It serves as the SSH exec target. Direct local access via `ioc-runner attach`
continues to work unchanged.

**One conserver daemon manages all IOC servers.**
All IOC console entries are registered in a single `/etc/conserver.cf` on the
central server. Adding or removing IOCs requires only a config regeneration and
a `SIGHUP` to conserver — no restart needed.

**IOC status is on-demand via conserver `task`.**
No polling daemon is introduced. Status is retrieved by firing `^Ec!s` inside
an active console session, which runs a remote SSH command to check
`systemctl is-active` and UDS connection count.

**SSH access uses a dedicated non-login service account.**
A `conserver-svc` account (member of `ioc` group) on each IOC server holds the
SSH public key. The `authorized_keys` entry restricts execution to `con` only,
preventing arbitrary command execution.

---

## 5. Access Control

```
[ ioc group membership ]
     |
     |-- /run/procserv/*/control   (socket mode 0660, owned by ioc-srv:ioc)
     |
     |-- conserver-svc account     (member of ioc group on each IOC server)
           |
           |-- authorized_keys     (restricted to: con -c <uds-path>)
           |-- SSH key source:     /etc/conserver/id_ed25519 (central server)

[ conserver client (engineer) ]
     |
     |-- console <ioc-name>        (connects to conserver TCP 7782)
     |-- conserver access block    (allowed hosts/users defined in conserver.cf)
```

---

## 6. conserver.cf Structure

```
/etc/conserver.cf
  |
  |-- config *          global settings (port, logfile, daemonmode)
  |-- access *          trusted hosts, allowed users
  |-- default epics-ioc shared IOC defaults (rw/ro, logfile, timestamp)
  |-- console <name>    one block per IOC (type exec, SSH command)
  |-- task s            on-demand IOC status (systemctl + UDS connection count)
```

### config block

```
config * {
    defaultaccess allowed;
    primaryport 7782;
    logfile /var/log/conserver/conserver.log;
    daemonmode yes;
}
```

### default block

```
default epics-ioc {
    rw @ioc;
    ro *;
    logfile /var/log/conserver/&.log;
    timestamp 1h;
    options !hupcl;
}
```

### console block (one per IOC)

```
console <ioc-name> {
    master localhost;
    include epics-ioc;
    type exec;
    exec ssh -i /etc/conserver/id_ed25519 \
             -o StrictHostKeyChecking=yes \
             -o BatchMode=yes \
             conserver-svc@<ioc-host> \
             con -c /run/procserv/<ioc-name>/control;
}
```

### task block (on-demand status)

```
task s {
    cmd ssh -i /etc/conserver/id_ed25519 \
            -o BatchMode=yes \
            conserver-svc@<ioc-host> \
            "systemctl is-active epics-@<ioc-name>.service && \
             ss -lx /run/procserv/<ioc-name>/control 2>/dev/null | \
             awk 'NR>1 {print \"connections:\", \$3}'";
    description IOC service status and UDS connection count;
    confirm no;
}
```

---

## 7. IOC Inventory Source

conserver.cf is generated from the existing `ioc-runner` configuration files.
No separate inventory is maintained.

```
/etc/procServ.d/<ioc-name>.conf
  |
  |-- IOC_PORT  -->  unix:ioc-srv:ioc:0660:/run/procserv/<ioc-name>/control
                                                          ^
                                                          UDS path extracted here
```

The `IOC_PORT` field written by `ioc-runner install` contains the full UDS path
as the last colon-delimited field. The conserver.cf generator parses this field
to resolve each IOC's socket path.

---

## 8. SSH Key Setup

```
Central server
  - Key pair:  /etc/conserver/id_ed25519  (no passphrase)
  - Owner:     root:root, mode 0600

Each IOC server
  - Account:   conserver-svc  (member of ioc group, no login shell)
  - authorized_keys entry (restricted):
      restrict,command="con -c /run/procserv/${SSH_ORIGINAL_COMMAND##* }/control" \
      ssh-ed25519 AAAA... conserver@central
```

---

## 9. conserver.cf Lifecycle

```
IOC added    -->  ioc-runner install <name>.conf
                  -->  /etc/procServ.d/<name>.conf written

Config regen -->  generate-conserver-cf (reads /etc/procServ.d/*.conf)
                  -->  /etc/conserver.cf.new

Validate     -->  conserver -t -C /etc/conserver.cf.new

Apply        -->  mv /etc/conserver.cf.new /etc/conserver.cf
                  kill -HUP $(pidof conserver)       (no restart required)
```

---

## 10. Deployment Phases

```
Phase 1. Local test environment
         - 2x Rocky 8.10 VMs
         - alsu-rocky8-gui-test : central server (conserver)
         - alsu-rocky8-test     : IOC server (procServ + ioc-runner + con)

Phase 2. SSH key setup
         - Generate key on central server
         - Deploy to conserver-svc account on IOC server
         - Verify: ssh conserver-svc@<ioc-host> con -c <uds-path>

Phase 3. conserver installation and configuration
         - Install conserver on central server
         - Generate conserver.cf from /etc/procServ.d/
         - Validate: conserver -t
         - Start: systemctl enable --now conserver

Phase 4. Validation
         - console <ioc-name>    attach
         - ^Ec!s                 status task
         - console -i            list all consoles
         - Two concurrent sessions on same IOC

Phase 5. Production rollout
         - Deploy conserver-svc account to all IOC servers
         - Regenerate conserver.cf for full IOC inventory
         - Validate and reload
```

---

## 11. Validation Checklist

```
[ ] procServ + con + ioc-runner running on IOC server
[ ] UDS confirmed: ss -lx /run/procserv/<ioc-name>/control
[ ] SSH key generated on central server
[ ] conserver-svc account exists on IOC server, member of ioc group
[ ] SSH exec verified: ssh conserver-svc@<ioc-host> con -c <uds-path>
[ ] conserver installed on central server
[ ] conserver.cf generated and validated: conserver -t
[ ] conserver daemon started: systemctl start conserver
[ ] console <ioc-name> attaches successfully
[ ] ^Ec!s returns systemctl status and connection count
[ ] Two concurrent console sessions verified
[ ] /var/log/conserver/<ioc-name>.log written
[ ] IOC restart: console session recovers automatically
```
