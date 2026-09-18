# ADR 0003 — Site-Wide Environment Layer

- Status: **Accepted** (2026-09-18).
- Scope: an optional site-wide `EnvironmentFile` layered under the per-IOC
  `<ioc>.conf` in the local and system systemd unit templates.
- Supersedes: none.

## Context

Under the systemd backends, each IOC's `<ioc>.conf` is loaded as the unit's
`EnvironmentFile` (`bin/ioc-runner` local template, `bin/setup-system-infra.bash`
system template). Every `KEY="VALUE"` in that file — not only the `IOC_*` keys
the runner acts on — is exported into the procServ process environment and
inherited by the IOC (`docs/FAQ.md` Q2, on the conf as an `EnvironmentFile`).
Setting an EPICS environment variable in the conf is therefore the supported
path today, not a workaround. (The container backend does not load the conf as
environment; see the Consequences.)

Some of those variables are the same for every IOC on a host or site. The
Channel Access and PV Access client discovery lists are the clearest case: an
IOC that reads PVs from other IOCs needs `EPICS_CA_ADDR_LIST` /
`EPICS_PVA_ADDR_LIST` (or the `*_AUTO_ADDR_LIST` toggles) pointed at the same
network for every IOC on that plane. With only the per-IOC conf, that common
value is copied into every conf and drifts independently. Issue #152 asks for a
standard way to avoid the repetition.

The variables split by role, and the split decides what belongs in a shared
layer:

- **Host- or site-common (client discovery).** `EPICS_CA_ADDR_LIST`,
  `EPICS_CA_AUTO_ADDR_LIST`, `EPICS_CA_NAME_SERVERS`, and the `EPICS_PVA_*`
  counterparts govern where an IOC's *client* side searches for PVs. On a given
  network they are identical across IOCs.
- **Per-IOC (server binding).** `EPICS_CAS_INTF_ADDR_LIST` /
  `EPICS_PVAS_INTF_ADDR_LIST` bind an IOC's *server* to specific local
  interfaces; on a multi-homed host these differ per IOC and interact with
  beacon scope.

One asymmetry matters for anyone reasoning about the shared layer: on the PVA
side `EPICS_PVA_ADDR_LIST` is read by both the client and, as a fallback beacon
destination, the server (PVXS `server.rst`); on the CA side the client
`EPICS_CA_ADDR_LIST` no longer feeds the server beacon list (removed in
R3.15.4; `caservertask.c` reads only the `EPICS_CAS_*` set). A value placed in
a shared layer therefore reaches slightly different consumers for CA and PVA.

## Decision

Add one optional site-wide environment file, read by every IOC unit before its
per-IOC conf.

1. **Location and name:** `${CONF_DIR}/site.env`. The `.env` extension, not
   `.conf`, keeps it from colliding with the `<ioc>.conf` pattern — a file
   named `site.conf` would be indistinguishable from the conf of an IOC named
   `site`.
2. **Wiring:** each unit template gains one `EnvironmentFile=-${CONF_DIR}/site.env`
   line placed *before* the existing `EnvironmentFile=${CONF_DIR}/%i.conf`. The
   leading `-` marks the file optional, so an installation without it behaves
   exactly as today. systemd applies later files over earlier ones, so the
   per-IOC conf overrides any key also set in the site file.
3. **Grammar-only validation:** the site file uses the same
   `EnvironmentFile`-compatible `KEY=VALUE` grammar as the conf, but it is not a
   conf — it carries EPICS environment variables, not the `IOC_*` keys. It is
   therefore validated at the grammar layer only: when the file exists,
   `install` checks that the bounded parser accepts it (`read_conf_all`, over
   the single `parse_conf_file` grammar established by #113) and reports a
   syntax error if it does not. It is deliberately **not** run through
   `validate_conf`, whose required-key check
   (`IOC_USER` / `IOC_GROUP` / `IOC_CHDIR` / `IOC_CMD`, `bin/ioc-runner:1458`)
   would reject a legitimate site file. An absent file is not an error.
4. **Ownership of values:** the runner ships the mechanism and the
   documentation only. The site file's contents — the actual addresses — are
   site-specific and live outside this repository. No value is baked into
   ioc-runner.

The new line must be added to both template copies and pinned by the two-copy
contract guard (`test_unit_template_contract`); if the line falls outside the
guard's current must-agree block, the guard is extended to cover it (M3).

## Alternatives

- **Per-IOC conf only (status quo).** Rejected: it is correct and already
  works, but forces the common discovery values to be repeated in every conf,
  which is exactly the drift #152 reports.
- **A systemd drop-in per host** (`<unit>.d/*.conf` with `Environment=`).
  Rejected: it moves configuration out of the runner's conf model into
  hand-edited systemd territory, splits the source of an IOC's environment
  across two mechanisms, and does not apply to the container backend at all.
- **Bake site defaults into the runner.** Rejected by the ownership decision
  above: deployment-specific addresses do not belong in a general-purpose tool.

## Consequences

- Backward compatible: with no `site.env`, every existing installation is
  unchanged (the `-` optional prefix).
- The precedence is explicit and testable: a key set only in the site file
  reaches the IOC; a key set in both takes the per-IOC value.
- The container backend is out of scope. Its s6 run script passes only
  `IOC_USER`, `IOC_CHDIR`, `IOC_PORT`, and `IOC_CMD` to procServ and exports no
  conf environment at all (`bin/ioc-runner` s6 renderer), so a site layer there
  is a separate, later decision, not part of this ADR.
- The variable semantics, the CA/PVA asymmetry, and a multi-homed worked
  example (on the RFC 5737 documentation ranges) are documented in a companion
  network-environment reference, not in this ADR.
