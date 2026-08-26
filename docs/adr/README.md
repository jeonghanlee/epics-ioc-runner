# Architecture Decision Records — index and decision-record map

This directory holds the project's Architecture Decision Records (ADRs).
This index also maps **where each kind of decision rationale lives**, so a
reader can find the "why" behind any choice without walking deleted working
sessions.

## ADRs

| ADR | Title | Status | Scope |
| --- | --- | --- | --- |
| [0001](0001-restart-supervision-c1h.md) | Restart Supervision: the C1+H bundle | Accepted (2026-06-15) | The systemd unit + procServ configuration supervising every IOC (template cluster M5-M11): the `Restart=`/`StartLimit*`/`KillMode=` policy, the `--autorestartcmd=''` `^T` harden, the **unit ordering and dependencies** (M9/#53), and the **startup-poll classification** (M11/#67). |
| [0002](0002-test-output-surfaces.md) | Test Output Surfaces | Accepted (2026-08-25) | The reporter, dispatcher, and two-host gate boundary between human output and validated machine records. |

## Decision-record map (the SOT for "why")

Decisions in this project are recorded at the layer that matches their kind;
each layer is in-repository and self-contained:

| Decision kind | SOT home | Example |
| --- | --- | --- |
| Architecture decision (cross-cutting, alternatives weighed, lasting) | **ADR** in this directory | Restart supervision, unit ordering, startup-poll classification (ADR 0001) |
| Coherence **Keep** decision | **[`CLOSED_DOORS.md`](../CLOSED_DOORS.md)** — one line per verdict; the commit named in the row carries the reasoning | CI-25 two-copy unit template; CI-27 socket-path alias |
| Coherence **guard-promotion** decision | the guarding milestone's **Active Register row** + the **promotion test** in [`CLOSED_DOORS.md`](../CLOSED_DOORS.md) | CI-4 two-copy unit template (M5); CI-9 git-metadata injection contract (M6/#84); CI-22 crash-scan token partition (M11) |
| Release strategy decision | **1.2.0 tagged register** (`git show 1.2.0:docs/milestone.md`) | U006 `^T` mechanism; U008 `=0` acceptance-criterion rewrite |
| Per-milestone fix decision | **1.2.0 tagged register row** (rationale inline) + GitHub issue body as original full record | M1/#92 crash-warning false positive; M2/#93 abort exit codes |
| Subsystem specification | **Topic doc** | `PERMISSION_MODEL.md`, `LOG_LAYOUT.md`, `EXIT_SIGNAL_HANDLING.md`, `ARCHITECTURE.md`, `FAQ.md` |

A decision is promoted to an ADR (rather than left in the Ledger or a register
row) when it is architecture-level: it weighs named alternatives, has lasting
consequences across the system, and benefits from a self-contained record that
outlives any single milestone. Coherence Keep/promote decisions stay in
`CLOSED_DOORS.md` by design — a one-line index over the commits that already
carry the reasoning is cheaper to sweep than a fan-out of single-finding ADRs.

## Conventions

- Filenames: `NNNN-short-slug.md`, zero-padded sequential number.
- Each ADR is **self-contained**: it states the decision, the alternatives, the
  evidence, and the consequences inline, so it remains readable independently of
  any working-session material (review sessions under `docs/review_sessions/`
  are `.gitignore`d and removed at closure — they are provenance, not the home
  of the rationale).
- A superseding decision adds a new ADR and marks the prior one `Superseded by
  NNNN`; ADRs are not rewritten in place once Accepted (correction notes are
  appended, as in ADR 0001).
