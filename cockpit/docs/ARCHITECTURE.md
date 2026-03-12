# EPICS IOC Integrated Management System

## Goal

A single browser interface to manage hundreds of EPICS IOCs
distributed across 20+ servers.

---

## Base Environment

- All servers: Rocky 8.10
- IOC management: systemd template unit + procServ + ioc-runner
- IOC console: con (unix domain socket)
- Access control: ioc group + sudoers

---

## Selected Tools

- **Cockpit** - browser-based server management platform
- **Cockpit multi-host** - manage all IOC servers from a single central server
- **Cockpit custom plugin** - EPICS IOC management UI developed in-house

---

## Development and Verification Procedure

```
Phase 1. Local Verification Environment
         4x Rocky 8.10 VMs on KVM/libvirt (Debian 13 host)
         - 1x Central server
         - 3x IOC servers

Phase 2. Infrastructure Setup
         - SSH key generation and distribution
         - Cockpit installation on central server
         - cockpit-bridge installation on IOC servers
         - Cockpit multi-host registration

Phase 3. IOC Environment Setup
         - ioc group, ioc-srv account, sudoers configuration
         - procServ, con, ioc-runner installation
         - Bring up one test IOC and verify ioc-runner operation

Phase 4. Cockpit Plugin Development
         - IOC list and status view
         - IOC control (start / stop / restart)
         - IOC log viewer
         - IOC console (procServ access via con)

Phase 5. Production Rollout
         - Verify on 4 physical servers
         - Roll out to full server fleet
```

---

## Architecture

```
[ Browser ]
     |
     | HTTPS :9090
     |
[ Central Server ] Rocky 8.10
  - Cockpit (multi-host)
  - Cockpit EPICS IOC Manager plugin
  - SSH key-based auth
     |
     | SSH
     |---> [ IOC Server 01 ] Rocky 8.10
     |---> [ IOC Server 02 ] Rocky 8.10
     |---> [ IOC Server .. ] Rocky 8.10
     |---> [ IOC Server 20+] Rocky 8.10
           - cockpit-bridge
           - systemd (epics-@.service)
           - procServ (/run/procserv/{ioc_name}/control)
           - ioc-runner
           - con
           - /etc/procServ.d/
           - /opt/epics-iocs/
```

---

## Access Control

```
[ ioc group ]
     |
     |-- /etc/procServ.d/          (SetGID 2770)
     |-- /run/procserv/*/control   (socket mode 0660)
     |
     |-- sudoers (/etc/sudoers.d/10-epics-ioc)
           |
           |-- systemctl start   epics-@*.service
           |-- systemctl stop    epics-@*.service
           |-- systemctl restart epics-@*.service
           |-- systemctl status  epics-@*.service
           |-- systemctl enable  epics-@*.service
           |-- systemctl disable epics-@*.service
           |-- systemctl daemon-reload

[ Cockpit login account ]
     |
     |-- member of ioc group
     |-- SSH key-based auth to all IOC servers
```

---

## Cockpit Plugin - Function Map

```
[ Cockpit EPICS IOC Manager Plugin ]
     |
     |-- IOC List
     |     reads /etc/procServ.d/*.conf per server
     |
     |-- IOC Status
     |     systemctl is-active epics-@{ioc_name}.service
     |
     |-- IOC Control
     |     ioc-runner start   {ioc_name}
     |     ioc-runner stop    {ioc_name}
     |     ioc-runner restart {ioc_name}
     |
     |-- IOC Log
     |     journalctl -u epics-@{ioc_name}.service
     |
     |-- IOC Console
           ioc-runner attach {ioc_name}
                |
                con -c /run/procserv/{ioc_name}/control
```

---

## IOC Console Data Flow

```
[ Browser ]
     |
     | WebSocket
     |
[ Cockpit ]
     |
     | SSH
     |
[ IOC Server ]
     |
     | ioc-runner attach {ioc_name}
     |
     | con -c /run/procserv/{ioc_name}/control
     |
[ procServ unix domain socket ]
     |
[ EPICS IOC process ]
```
