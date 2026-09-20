# Network Environment Reference

This document is the topic reference for the Channel Access (CA) and PV Access
(PVA) network environment variables an IOC managed by `epics-ioc-runner` reads.
It states where each variable belongs — a value shared by every IOC on a host,
or a value specific to one IOC — and documents the CA/PVA asymmetries that most
often lead to a wrong placement.

It carries no site addresses. Every address below is drawn from the RFC 5737
documentation ranges (`192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`).

## How an IOC receives its network environment

Under the systemd backends, an IOC's environment is assembled from two files,
read in order by the unit template:

1. `${CONF_DIR}/site.env` — an optional site-wide file, loaded first. It is the
   place for values identical across every IOC on the host.
2. `${CONF_DIR}/<ioc>.conf` — the per-IOC file, loaded second. It carries the
   `IOC_*` operational keys and may also carry any environment variable specific
   to that IOC.

`${CONF_DIR}` is the runner's configuration directory: `${HOME}/.config/procServ.d`
in local mode and `/etc/procServ.d` in system-wide mode.

systemd applies later files over earlier ones, so a key set in both files takes
the per-IOC value. A key set only in `site.env` reaches every IOC; a key set
only in a conf reaches that IOC alone. The mechanism, its optional-file wiring,
and the grammar rule for `site.env` are defined in
[ADR 0003](https://github.com/jeonghanlee/epics-ioc-runner/blob/master/docs/adr/0003-site-environment-layer.md); the conf as an `EnvironmentFile`
is covered in [FAQ.md](FAQ.md) Q2.

The layering does not apply to the container backend, whose run script exports
no conf environment (see ADR 0003, Consequences).

## Usage scenarios

The three scenarios below cover the placements a site actually meets. Each names
the variables it needs and the file they belong in.

### Scenario 1 — One shared discovery network

Every IOC on the host reads PVs from the same CA/PVA network, and no IOC needs a
non-default server binding. This is the common case and the reason the site
layer exists.

Place the client discovery lists in `site.env` once. They are identical for
every IOC on the network, so a single shared value removes the per-conf
duplication that ADR 0003 (Context) and issue #152 describe.

```bash
# ${CONF_DIR}/site.env
EPICS_CA_ADDR_LIST="192.0.2.10 192.0.2.11"
EPICS_CA_AUTO_ADDR_LIST="NO"
EPICS_PVA_ADDR_LIST="192.0.2.10 192.0.2.11"
EPICS_PVA_AUTO_ADDR_LIST="NO"
```

Each `<ioc>.conf` then carries only its `IOC_*` keys and needs no network
variable at all.

### Scenario 2 — A multi-homed IOC

The host has more than one interface, and an IOC's server must be reachable on a
specific one — the client discovery network stays shared, but the server binding
is particular to the IOC.

Client discovery stays in `site.env` (Scenario 1). The server interface binding
is a per-IOC value, so it belongs in that IOC's conf:

```bash
# ${CONF_DIR}/multihomed-ioc.conf
IOC_USER="ioc-srv"
IOC_GROUP="ioc"
IOC_CHDIR="/opt/epics-iocs/multihomed-ioc/iocBoot/iocMultihomed"
IOC_CMD="./st.cmd"
EPICS_CAS_INTF_ADDR_LIST="198.51.100.5"
EPICS_PVAS_INTF_ADDR_LIST="198.51.100.5"
```

The full worked form of this scenario, including the beacon consequences of the
binding, is in [Worked example](#worked-example--a-multi-homed-ioc) below.

### Scenario 3 — A per-IOC exception

Most IOCs share the discovery network from `site.env`, but one IOC must search a
different network (a test subnet, a segregated device network).

Set the exception in that IOC's conf. Because the conf is read after `site.env`,
its value overrides the shared one for that IOC only; every other IOC keeps the
`site.env` value.

```bash
# ${CONF_DIR}/test-ioc.conf — overrides the shared discovery list
EPICS_CA_ADDR_LIST="203.0.113.20"
EPICS_PVA_ADDR_LIST="203.0.113.20"
```

## Variable reference

The variables split by role. Client variables (`EPICS_CA_*`, `EPICS_PVA_*`)
govern where an IOC's *client* side searches for PVs and are identical across
IOCs on a network — the site-layer candidates. Server variables (`EPICS_CAS_*`,
`EPICS_PVAS_*`) bind an IOC's *server* and differ per IOC on a multi-homed host.

Defaults for the CA variables are from `configure/CONFIG_ENV` in EPICS Base
R7.0.10; PVA defaults are from the PVXS 1.5.1 references.

### CA client discovery

| Variable | Default | Role | Source |
| --- | --- | --- | --- |
| `EPICS_CA_ADDR_LIST` | empty | Unicast/broadcast destinations for CA searches | `configure/CONFIG_ENV` |
| `EPICS_CA_AUTO_ADDR_LIST` | `YES` | Auto-add every local broadcast address to the search list | `configure/CONFIG_ENV` |
| `EPICS_CA_NAME_SERVERS` | empty | TCP name-server destinations for CA searches | `configure/CONFIG_ENV` |
| `EPICS_CA_SERVER_PORT` | `5064` | Destination UDP search port and default TCP server port | `configure/CONFIG_ENV` |
| `EPICS_CA_CONN_TMO` | `30.0` | Seconds before an unresponsive circuit is declared disconnected | `configure/CONFIG_ENV` |

### CA server binding and beacons

| Variable | Default | Role | Source |
| --- | --- | --- | --- |
| `EPICS_CAS_INTF_ADDR_LIST` | empty (binds all interfaces) | Local interfaces the CA server binds to | `configure/CONFIG_ENV`, `modules/database/src/ioc/rsrv/caservertask.c` (interface list) |
| `EPICS_CAS_BEACON_ADDR_LIST` | empty | Explicit beacon destinations, augmenting the auto list | `configure/CONFIG_ENV`, `caservertask.c` (beacon address list) |
| `EPICS_CAS_AUTO_BEACON_ADDR_LIST` | empty → auto (`YES`) | Auto-populate beacon destinations from local broadcast addresses | `caservertask.c` (`envGetBoolConfigParam`, default 1) |
| `EPICS_CAS_SERVER_PORT` | empty (falls back to `EPICS_CA_SERVER_PORT`) | TCP/UDP port the CA server binds | `configure/CONFIG_ENV`, `caservertask.c` (server port) |
| `EPICS_CAS_IGNORE_ADDR_LIST` | empty | Client addresses whose name-resolution requests are ignored | `configure/CONFIG_ENV` |

### PVA client discovery

| Variable | Default | Role | Source |
| --- | --- | --- | --- |
| `EPICS_PVA_ADDR_LIST` | auto (see `EPICS_PVA_AUTO_ADDR_LIST`) | Unicast/multicast/broadcast destinations for PVA searches | `netconfig.rst` (PV Search Process) |
| `EPICS_PVA_AUTO_ADDR_LIST` | `YES` | Auto-populate the search list with local IPv4 broadcast addresses | `netconfig.rst` (PV Search Process) |
| `EPICS_PVA_NAME_SERVERS` | empty | TCP name-server destinations for PVA searches | `netconfig.rst` (PV Search Process) |
| `EPICS_PVA_BROADCAST_PORT` | `5076` | UDP search port | `netconfig.rst` (PV Search Process) |
| `EPICS_PVA_SERVER_PORT` | `5075` | TCP data port | `config.cpp` (`tcp_port` default); `netconfig.rst` (variable table) |

### PVA server binding and beacons

A PVA server prefers the `EPICS_PVAS_*` variable and falls back to the paired
`EPICS_PVA_*` when the server form is unset (`server.rst`, configuration list).

| Variable | Default | Role | Source |
| --- | --- | --- | --- |
| `EPICS_PVAS_INTF_ADDR_LIST` | empty (binds all interfaces) | Local interfaces the PVA server binds to | `server.rst` (sets `Config::interfaces`) |
| `EPICS_PVAS_BEACON_ADDR_LIST` | falls back to `EPICS_PVA_ADDR_LIST` | Beacon destinations, supplemented with the broadcast addresses of the bound interfaces when auto-beacon is `YES` (all local broadcasts when the interface list is the default wildcard) | `server.rst` (sets `Config::beaconDestinations`) |
| `EPICS_PVAS_AUTO_BEACON_ADDR_LIST` | falls back to `EPICS_PVA_AUTO_ADDR_LIST` (`YES`) | Whether beacon destinations are auto-populated | `server.rst` (sets `Config::auto_beacon`) |
| `EPICS_PVAS_SERVER_PORT` | falls back to `EPICS_PVA_SERVER_PORT` (`5075`) | Preferred TCP port to bind | `server.rst` (sets `Config::tcp_port`); default `5075` in `config.cpp` |
| `EPICS_PVAS_BROADCAST_PORT` | falls back to `EPICS_PVA_BROADCAST_PORT` (`5076`) | UDP port to bind | `server.rst` (sets `Config::udp_port`) |

## Points that mislead

### The client address list feeds the PVA server beacon, but not the CA server beacon

This is the asymmetry that most often places a value wrongly.

- **PVA.** The server beacon destination list is `EPICS_PVAS_BEACON_ADDR_LIST`
  or, when that is unset, `EPICS_PVA_ADDR_LIST` — the client discovery list
  (`server.rst`, configuration list: "`EPICS_PVA_ADDR_LIST` is only checked if
  `EPICS_PVAS_BEACON_ADDR_LIST` is unset"). A client discovery list set in
  `site.env` therefore also steers PVA server beacons.
- **CA.** The CA server no longer reads `EPICS_CA_ADDR_LIST` for its beacon
  list. The CA reference (`modules/ca/src/client/CAref.html`) records this as a
  version change: "Prior to R3.15.4 CA servers would build the beacon address
  list using `EPICS_CA_ADDR_LIST` if `EPICS_CAS_BEACON_ADDR_LIST` was not set."
  From R3.15.4 on — and so in R7.0.10 — the CA server builds beacons from
  `EPICS_CAS_AUTO_BEACON_ADDR_LIST` and `EPICS_CAS_BEACON_ADDR_LIST` only.

The consequence: the same client discovery list in `site.env` reaches PVA
server beacons but not CA server beacons.

### `EPICS_CA_SERVER_PORT` plays two roles

`EPICS_CA_SERVER_PORT` is read by the client as the destination UDP search port,
and it is also the fallback the CA server binds to when `EPICS_CAS_SERVER_PORT`
is unset (`caservertask.c`, server port). One value in `site.env` therefore
moves both the client search port and the server bind port together. Split the
two roles with `EPICS_CAS_SERVER_PORT` only when they must differ.

### Binding to a specific interface narrows the beacon list (CA and PVA alike)

Binding a server to a specific interface also narrows its automatic beacon
list — for both protocols. When `EPICS_CAS_INTF_ADDR_LIST` or
`EPICS_PVAS_INTF_ADDR_LIST` names one interface, the auto-beacon populates the
beacon list with only that interface's broadcast address, not every local
broadcast address. Binding a server is therefore not a pure receive-side change;
it also limits where beacons go.

- **CA.** For each named interface the server populates the beacon list with
  that interface's broadcast address and disables the wildcard auto-population
  (`caservertask.c`, interface-list processing; `CAref.html`: "beacon address
  list automatic configuration is constrained to the network interfaces
  specified therein").
- **PVA.** The auto-beacon expands the beacon list from the interface list: the
  default wildcard interface adds every local broadcast address, while a
  specific interface adds only that interface's broadcast (`config.cpp`,
  `Config::expand` and `expandAddrList`). Observed on a four-interface host
  (PVXS 1.5.1, `pvxsr 1`): with the wildcard interface the beacon list held the
  loopback broadcast and all four interface broadcasts; with one interface named
  it held the loopback broadcast and that one interface's broadcast only.

The `server.rst` phrasing "supplemented all local broadcast addresses if
auto-beacon is `YES`" holds only for the default wildcard interface; with a
named interface the supplement is that interface's broadcast alone.

### One UDP search port is shared by every IOC on a host

CA searches leave on `EPICS_CA_SERVER_PORT` (`5064`) and PVA searches on
`EPICS_PVA_BROADCAST_PORT` (`5076`). These are destination ports, not
per-process bindings, so every IOC on a host shares them without conflict —
which is exactly why the client discovery values are host-common and belong in
`site.env`. The server *bind* ports (`EPICS_CAS_SERVER_PORT`,
`EPICS_PVAS_SERVER_PORT`) are a different matter: two CA or two PVA servers on
one host bind ports independently, and the second to start takes a random free
port if the preferred one is in use (PVA: `server.rst`, `Config::tcp_port`; CA:
`caservertask.c` retries on `EADDRINUSE`).

## Worked example — a multi-homed IOC

A host has two interfaces: `198.51.100.5` on the accelerator control network and
`203.0.113.5` on a device network. Every IOC on the host reads PVs from the
control network, but one IOC, `dev-gateway`, must present its server only on the
device interface.

Shared client discovery, for all IOCs, in `site.env`:

```bash
# ${CONF_DIR}/site.env
EPICS_CA_ADDR_LIST="198.51.100.10 198.51.100.11"
EPICS_CA_AUTO_ADDR_LIST="NO"
EPICS_PVA_ADDR_LIST="198.51.100.10 198.51.100.11"
EPICS_PVA_AUTO_ADDR_LIST="NO"
```

Per-IOC server binding, in `dev-gateway.conf` only:

```bash
# ${CONF_DIR}/dev-gateway.conf
IOC_USER="ioc-srv"
IOC_GROUP="ioc"
IOC_CHDIR="/opt/epics-iocs/dev-gateway/iocBoot/iocDevGateway"
IOC_CMD="./st.cmd"
EPICS_CAS_INTF_ADDR_LIST="203.0.113.5"
EPICS_PVAS_INTF_ADDR_LIST="203.0.113.5"
```

Consequences to expect, from the asymmetries above:

- `dev-gateway`'s CA server binds `203.0.113.5`, and its CA beacons narrow to
  that interface's broadcast address (`EPICS_CAS_INTF_ADDR_LIST` narrowing).
- `dev-gateway`'s PVA server binds `203.0.113.5`, and with auto-beacon `YES` its
  PVA beacons narrow the same way — to that interface's broadcast, not every
  local broadcast address.
- Every other IOC keeps the shared control-network discovery from `site.env` and
  binds its servers to all interfaces (the empty-list default).

## See also

- [ADR 0003 — Site-Wide Environment Layer](https://github.com/jeonghanlee/epics-ioc-runner/blob/master/docs/adr/0003-site-environment-layer.md)
  — the decision, the optional-file wiring, and the `site.env` grammar rule.
- [FAQ.md](FAQ.md) — the shared-variable question and the conf as an
  `EnvironmentFile`.
- [USER_GUIDE.md](USER_GUIDE.md) — installing and managing system-wide IOCs.
