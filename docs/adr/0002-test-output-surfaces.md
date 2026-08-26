# ADR 0002 — Test Output Surfaces

- Status: **Accepted** (2026-08-25).
- Scope: the shared reporter, `run-all-tests.bash`, and the canonical two-host
  gate.
- Supersedes: none.

## Context

The test reporter derives a human summary and a stable `TEST`, `STEP`, and
`SUITE` record sequence from one file-backed ledger. Emitting both projections
to one stream made normal operator output difficult to read and allowed a
consumer to search mixed prose for a terminal record without proving that the
complete machine sequence was valid.

The boundary must preserve one catalog, one ledger, the existing record
grammar, `reporting-counts.csv`, and the canonical six-run identity digest.
Privileged producers must not receive caller-selected evidence paths.

## Decision

Default producer and dispatcher invocations emit human output and no execution
records. `REPORT_MACHINE_OUTPUT=1` reserves the process's original standard
output for the complete machine-record sequence and routes subsequent human
output to standard error. `REPORT_CATALOG_ONLY=1` has precedence and preserves
its single standard-output `CATALOG` record.

`tests/lib/test-record-validator.bash` is the single structural acceptance
boundary for one suite machine file. It validates exact grammar and phase
order, suite dimensions, identities, count and state vectors, the final
`SUITE`, and producer-status agreement. Expected suite membership and counts
come from the maintained reporting libraries; exact six-run identity remains
owned by the gate digest.

The dispatcher opens private child machine and human files outside child
privilege boundaries and accepts only validated machine files. The two-host
gate opens a machine and human file per remote run in the login shell, verifies
login-account ownership and hashes, copies both through that account, and
validates each machine file before aggregation. Human text is used only for
operator and runner-path evidence. Machine files alone feed count, state,
identity, matrix, and cross-host checks.

## Alternatives

### Keep one mixed stream

Rejected because operator output remains dominated by machine records and a
consumer must distinguish records from prose after capture.

### Add separate human and machine calculations

Rejected because independent counters and state resolution could disagree.
Both projections remain outputs of the existing reporter ledger.

### Pass output paths into producers

Rejected because privileged producers would then open caller-selected paths.
The caller owns redirection and evidence files outside the privilege boundary.

### Add a second expected identity manifest

Rejected because it would duplicate the gate's exact identity authority.
Structural validation and the existing identity digest remain separate checks.

## Consequences

- Human-only output is the default interface.
- Machine consumers must request machine mode and capture both descriptors.
- Missing, mixed, malformed, duplicate, incomplete, or status-inconsistent
  machine files fail before aggregation.
- Gate evidence contains per-run and per-host machine and human files with
  separate hashes.
- The record grammar, catalog membership, expected counts, and six-run identity
  digest remain unchanged.

## Verification

The shipped reporter self-test compares both descriptors from one reporter
process, including a non-PASS result. The validator self-test creates its valid
baseline through the reporter public API and mutates only the serialized file
boundary. The canonical Debian 13 and Rocky Linux 8 gate validates all twelve
per-run machine files and completes six runs and 758 checks per host.
