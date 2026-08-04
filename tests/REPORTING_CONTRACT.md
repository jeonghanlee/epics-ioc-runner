# Test Reporting Contract

This document defines the producer contract for machine-readable test results.
It applies to the four shipped test suites under `tests/`.

## Result Dimensions

Each suite result identifies independent test dimensions. A field must not
carry information that belongs to another dimension.

| Field | Meaning | Allowed Values |
| --- | --- | --- |
| `suite` | Test suite identity | `error-handling`, `local-lifecycle`, `system-infra`, `system-lifecycle` |
| `scope` | Operational scope under test | `local`, `system`, `none` |
| `runner` | `ioc-runner` binary origin under test | `source`, `installed`, `none` |
| `os` | Operating system family and major version | Normalized `<id>-<major>` value such as `debian-13` or `rocky-8` |
| `arch` | EPICS host architecture | `EPICS_HOST_ARCH`, such as `linux-x86_64` |
| `run` | One suite invocation | An identifier unique within the collected result set |

`scope` does not describe how a suite was launched. Direct execution and
execution through `run-all-tests.bash` do not change the suite result identity.

`runner` describes the binary selected for behavior testing. It does not
describe whether infrastructure has already been installed.

`os` and `arch` are separate. `EPICS_HOST_ARCH` must not be reported as `os`.

## Suite Dimension Matrix

| Suite Invocation | `scope` | `runner` |
| --- | --- | --- |
| Error handling | `none` | `source` |
| Local lifecycle against the source tree | `local` | `source` |
| Local lifecycle against the installed binary | `local` | `installed` |
| System infrastructure | `system` | `none` |
| System lifecycle against the source tree | `system` | `source` |
| System lifecycle against the installed binary | `system` | `installed` |

The system infrastructure suite validates installed accounts, directories,
policies, units, tools, and permissions. It does not select an `ioc-runner`
binary for lifecycle behavior, so its `runner` value is `none`.

## Stable Check Catalog

Each suite declares its complete ordered STEP and check catalog before any
environment probe or test body runs. Each declaration contains:

```text
suite_id step_id check_id check_kind description
```

Check IDs use this form:

```text
<suite>.P00.<check-key>
<suite>.SNN.<check-key>
```

For example:

```text
system-infra.S02.conf-dir.exists
system-infra.S02.conf-dir.owner
system-infra.S02.conf-dir.permission
```

The check key states the tested meaning. IDs are not generated from source line
numbers or execution order. Existing IDs are never renumbered when a check is
added.

`P00` owns invocation preflight checks. Existing pipeline STEPs retain their
`S01`, `S02`, and later identities.

## Check Kinds

| Kind | Purpose | Normal Terminal States |
| --- | --- | --- |
| `REQUIRED` | A condition required for a supported run or a required shipped artifact | `PASS`, `FAIL` |
| `PREREQUISITE` | A facility needed by a check group but allowed to be unavailable | `PASS`, `SKIP` |
| `APPLICABILITY` | A declared OS, permission, policy, or runner boundary | `PASS`, `NA` |
| `BEHAVIOR` | A functional assertion against the real shipped path | `PASS`, `FAIL`, `SKIP`, `NA` |
| `INTEGRITY` | Reporter, ledger, and execution-completeness validation | `PASS`, `FAIL`, `SCRIPT_ERROR` |

`check_kind` is catalog metadata. It does not add another result state.

## Terminal States

| State | Meaning |
| --- | --- |
| `PASS` | The declared check ran and its expected condition was observed. |
| `FAIL` | The declared check ran and its expected condition was not observed. |
| `SKIP` | The check applies to this invocation but could not run because a declared prerequisite was unavailable or failed. |
| `NA` | The applicability boundary was examined and the check does not apply to this invocation. |
| `SCRIPT_ERROR` | Suite execution or reporting could not close the declared check normally. |

Every declared check closes exactly once. An unexpected abort preserves closed
states and closes every remaining open check as `SCRIPT_ERROR`.

## OS and Runner Applicability

The catalog identity set and `Total` remain fixed across supported operating
systems and runner origins.

- A shared requirement with different OS paths or expected values uses one
  check ID. The suite selects the expected value from `os`.
- A truly OS-specific check has a stable catalog ID on every OS. It runs on the
  applicable OS and closes as `NA` on other OS families.
- A behavior checked against both runner origins uses the same ID. The `runner`
  field identifies which binary produced the result.
- A check that applies to only one runner origin remains in both catalogs and
  closes as `NA` for the other origin.
- A missing required runner closes its preflight check as `FAIL` and dependent
  behavior checks as `SKIP`.

## Dependency Rules

- A required artifact has an existence check and separate dependent semantic
  checks.
- If the artifact is absent, existence is `FAIL`; dependent checks are `SKIP`
  and name the failed check ID in their reason.
- An unavailable optional facility closes its prerequisite and dependent
  checks as `SKIP`.
- A check outside an applicability boundary closes the applicability check and
  dependent checks as `NA`.
- A failed behavior check does not suppress later independent checks.

Each file and permission target uses three checks:

```text
<path-key>.exists
<path-key>.owner
<path-key>.permission
```

An absent path produces `FAIL`, `SKIP`, and `SKIP` respectively.

A required executable and its behavior use separate checks. For example:

```text
camonitor.available
channel-access.updates
```

An absent required executable produces `FAIL` and `SKIP`; the dependent command
is not executed.

## STEP Records

Every declared STEP emits exactly one ordered `STEP` record. A setup-only STEP
may own zero checks and emits a zero-count record. Each check belongs to exactly
one STEP, and all STEP vectors must sum to the final suite vector.

## Machine-Readable Records

Record type and field order are fixed:

```text
TEST suite=<suite> run=<run_id> step=<step_id> id=<check_id> state=<PASS|FAIL|SKIP|NA|SCRIPT_ERROR> reason_b64=<reason>
STEP suite=<suite> run=<run_id> step=<step_id> pass=<n> fail=<n> skip=<n> na=<n> err=<n>
SUITE suite=<suite> run=<run_id> scope=<scope> runner=<runner> os=<os_id> arch=<arch_id> total=<n> pass=<n> fail=<n> skip=<n> na=<n> err=<n>
```

Identifier and scalar values contain no spaces and match
`[A-Za-z0-9._:/+-]+`.

`PASS` uses `reason_b64=-`. Every non-PASS reason uses RFC 4648 base64url
without padding or a newline and matches `[A-Za-z0-9_-]+`.

Records are emitted in this order:

1. One `TEST` record for every check, in catalog order.
2. One `STEP` record for every STEP, in STEP order.
3. Exactly one final `SUITE` record.

No reporter record may follow `SUITE`.

## Invariants

Every completed suite result satisfies:

```text
Total = PASS + FAIL + SKIP + NA + SCRIPT_ERROR
```

The following conditions invalidate a result and produce a nonzero suite exit:

- duplicate, unknown, late, or missing check registration;
- duplicate or missing terminal state;
- missing reason for a non-PASS state;
- malformed field or field order;
- duplicate or missing STEP record;
- STEP vectors that do not reconcile with the suite vector;
- duplicate, missing, or non-final SUITE record;
- different catalog identity sets across supported environments.

## Producer and Consumer Boundary

The machine-readable records are additive to existing human-readable suite
output. The test suites and shared reporter own the producer contract. Gate
consumption remains outside this contract until the gate parser adopts these
records.
