# Test Reporting Contract

This document defines the producer contract for machine-readable test results.
It applies to the test suites under `tests/`.

## Result Dimensions

Each suite result identifies independent test dimensions. A field must not
carry information that belongs to another dimension.

| Field | Meaning | Allowed Values |
| --- | --- | --- |
| `suite` | Test suite identity | `error-handling`, `local-lifecycle`, `source-regression`, `system-infra`, `system-lifecycle` |
| `scope` | Operational scope under test | `local`, `system`, `none` |
| `runner` | `ioc-runner` binary origin under test | `source`, `installed`, `none` |
| `os` | Operating system family and major version | Normalized `<id>-<major>` value such as `debian-13` or `rocky-8` |
| `arch` | EPICS host architecture | `EPICS_HOST_ARCH`, such as `linux-x86_64` |
| `run` | One suite invocation | An identifier unique within the collected result set |

`scope` does not describe how a suite was launched. Direct execution and
execution through `run-all-tests.bash` do not change the suite result identity.

`runner` describes the binary origin requested for behavior testing. The value
remains `source` or `installed` when the requested binary is missing or is not
executable; the `P00` runner check records that failure. It does not describe
whether infrastructure has already been installed.

A lifecycle invocation that requests any other runner origin is rejected with
a nonzero exit before reporter initialization. It produces no `TEST`, `STEP`,
or `SUITE` record because it is not a supported suite invocation; the outer
runner treats the missing suite record as an invalid run.

`os` and `arch` are separate. `EPICS_HOST_ARCH` must not be reported as `os`.

## Suite Dimension Matrix

| Suite Invocation | `scope` | `runner` |
| --- | --- | --- |
| Error handling | `none` | `source` |
| Local lifecycle against the source tree | `local` | `source` |
| Local lifecycle against the installed binary | `local` | `installed` |
| Source regression | `system` | `source` |
| System infrastructure | `system` | `none` |
| System lifecycle against the source tree | `system` | `source` |
| System lifecycle against the installed binary | `system` | `installed` |

The system infrastructure suite validates installed accounts, directories,
policies, units, tools, and permissions. It does not select an `ioc-runner`
binary for lifecycle behavior, so its `runner` value is `none`.

## Test Categories

A test category identifies what is being verified and when that verification
is valid. It is independent of the result dimensions and check kinds.

| Category | Verification Target | Execution Context | Suite Assignment |
| --- | --- | --- | --- |
| `source-regression` | Shipped source-script behavior, including setup, runner metadata, injection, and test path safety | Source tree with writes redirected to isolated temporary targets | Source regression |
| `installed-conformance` | Installed accounts, files, ownership, permissions, policies, units, and tools | Host after installation or configuration | System infrastructure |
| `lifecycle-behavior` | IOC start, stop, status, console, and cleanup behavior | Real source or installed runner selected by `runner` | Local lifecycle and system lifecycle |
| `error-contract` | Rejection and safe failure behavior for invalid inputs | Real source runner and isolated outer boundaries | Error handling |

`source-regression` verifies shipped source scripts whose result is independent
of installed host state. This includes setup behavior, live runner metadata,
version injection, Git fixtures, and path-safety guards for test scripts. It
may redirect outer filesystem targets to an isolated temporary directory, but
it does not replace an internal function or reproduce script behavior in a
fixture. A passing source-regression result does not claim that the host is
installed correctly.

`installed-conformance` examines the actual installed host state. It does not
exercise source-tree installer logic and does not select a lifecycle runner.

`lifecycle-behavior` uses the same check identity for source and installed
runner origins when both origins implement the same requirement. The `runner`
dimension records the selected origin; it does not create a separate test
category.

`error-contract` exercises the shipped command path with invalid or unsafe
inputs and verifies its observable exit and output contract. Internal command
functions are not replaced.

One suite owns one primary category. Checks from another category belong in a
separate suite even when they share setup code or require the same operating
system.

## Check Execution Lifecycle

Each suite follows one ordered lifecycle:

1. Declare the complete ordered STEP and check catalog.
2. Close the catalog and compare its check and STEP counts with
   `reporting-counts.csv`.
3. Evaluate declared applicability and prerequisite checks.
4. Execute each permitted check through the real shipped path.
5. Close every declared check exactly once in catalog order.
6. Complete every producer cleanup action that can change suite status.
7. Resolve the ledger, clean the reporter workspace, emit the projections,
   and exit with the status represented by the final SUITE record.

No check is created after execution begins. A missing prerequisite or an
inapplicable boundary closes only already-declared checks according to the
dependency rules. An unexpected exit before finalization is invalid and the
reporter closes remaining declared checks as `SCRIPT_ERROR`.

## Catalog Count Boundary

`reporting-counts.csv` is the only current expected check and STEP count
source. `lib/reporting-suites.bash` owns the supported suite set independently,
and the CSV parser requires exactly one row for each supported suite. Runtime
catalog registration remains the independent actual side of the comparison.

Every normal suite invocation compares its closed runtime catalog before its
environment preflight. A mismatch exits nonzero and produces no valid `SUITE`
record. `REPORT_CATALOG_ONLY=1` performs the same registration, close, and
comparison, cleans the reporter workspace, and exits before environment,
privilege, systemd, or IOC setup. Its only machine record is:

```text
CATALOG suite=<suite> checks=<checks> steps=<steps> state=PASS
```

An unset or `0` value continues through normal execution. Any other value is
invalid.

## Stable Check Catalog

Each suite declares its complete ordered STEP and check catalog before any
environment probe or test body runs. Each declaration contains:

```text
suite_id step_id check_id category check_kind test_method description
```

`category` uses one value from Test Categories. `test_method` uses the accepted
catalog values `real-path` or `direct-inspection` from `README.md` "Test
Classification". `hand-built-reproduction` may describe a migration finding,
but it is invalid verification evidence and cannot be registered in an
accepted runtime catalog.

`check_kind` and `test_method` are independent catalog dimensions. The method
limits the evidence claim: a `BEHAVIOR` row using `direct-inspection` reports
only the directly observed state or contract and does not claim runtime
behavior verification.

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
| `BEHAVIOR` | An expected product condition whose evidence claim is bounded by `test_method` | `PASS`, `FAIL`, `SKIP`, `NA` |
| `INTEGRITY` | Reporter, ledger, and execution-completeness validation | `PASS`, `FAIL`, `SCRIPT_ERROR` |

`check_kind` is catalog metadata. It does not add another result state or
override the evidence limit imposed by `test_method`. A
`BEHAVIOR/direct-inspection` row can establish a directly observed product
state or contract, but it cannot establish runtime behavior.

The normal terminal states assume that governing applicability and prerequisite
checks permit the check group to run. If a governing applicability check closes
as `NA`, every dependent check closes as `NA` regardless of its kind. If a
governing prerequisite closes as `SKIP`, every dependent check closes as `SKIP`,
including a `REQUIRED` artifact inside that check group.

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
  field identifies the origin requested for that invocation.
- A check that applies to only one runner origin remains in both catalogs and
  closes as `NA` for the other origin.
- A missing required runner retains the requested `runner` origin, closes its
  preflight check as `FAIL`, and closes dependent behavior checks as `SKIP`.

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
TEST suite=<suite> run=<run_id> step=<step_id> id=<check_id> category=<category> kind=<check_kind> method=<test_method> state=<PASS|FAIL|SKIP|NA|SCRIPT_ERROR> reason_b64=<reason>
STEP suite=<suite> run=<run_id> step=<step_id> pass=<n> fail=<n> skip=<n> na=<n> err=<n>
SUITE suite=<suite> run=<run_id> scope=<scope> runner=<runner> os=<os_id> arch=<arch_id> total=<n> pass=<n> fail=<n> skip=<n> na=<n> err=<n> state=<PASS|FAIL>
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

## Shared Reporter Interface

The producer suites use `lib/test-reporting.bash` through this ordered
interface:

```text
report_init suite run scope runner os arch ledger_dir
report_register_step step_id description
report_register_check check_id step_id category check_kind test_method description
report_close_catalog
report_verify_catalog_counts
report_record check_id state [reason]
report_finalize original_exit_status
```

`report_register_step` permits a declared setup-only STEP with zero checks.
Every check references a previously declared STEP. `report_close_catalog`
ends registration before any result event. `report_verify_catalog_counts`
enforces the Catalog Count Boundary before execution. `report_record` is the
only path for a test-owned terminal state; `PASS` carries no reason and every
other state requires one non-empty, single-line reason.

The caller supplies a dedicated real directory for the private file-backed
ledger. The directory must be owned by the current effective user, must not be
a symbolic link, must not be writable by group or other users, and must remain
otherwise empty. The reporter creates the ledger with an unpredictable name,
verifies its ownership and `0600` mode, retains it while checks execute, then
removes the ledger and its empty directory during finalization. A cleanup
failure produces suite state `FAIL`; the reporter does not recursively remove
unexpected directory contents. This preserves events from subshell execution
without allowing the reporter to infer a state from human output or
independent counters.

The reporter resolves its required helper commands through a fixed system
search path without changing the caller's `PATH`. Each root-run producer suite
also establishes its own fixed `PATH`; that suite boundary is applied during
producer integration rather than by the shared library.

`report_finalize` preserves completed states, turns every unclosed declared
check into `SCRIPT_ERROR`, validates the ledger, calculates one complete
vector, cleans the reporter workspace, derives the final suite state, and
emits both projections. A recoverable event defect tied to a known check
resolves that check to `SCRIPT_ERROR`. An unknown identity or invalid catalog
prevents a valid projection, exits nonzero, and emits no `SUITE` record for a
consumer to mistake as complete.

## Invariants

Every completed suite result satisfies:

```text
Total = PASS + FAIL + SKIP + NA + SCRIPT_ERROR
```

The final suite state is `PASS` only when the requested exit status is zero,
the check vector contains no `FAIL` or `SCRIPT_ERROR`, reporter integrity is
valid, and producer and reporter workspace cleanup succeeded. Every other
completed projection uses suite state `FAIL`, and `report_finalize` returns
nonzero.

The following conditions invalidate a result and produce a nonzero suite exit:

- duplicate, unknown, late, or missing check registration;
- duplicate or missing terminal state;
- missing reason for a non-PASS state;
- malformed field or field order;
- duplicate or missing STEP record;
- STEP vectors that do not reconcile with the suite vector;
- duplicate, missing, or non-final SUITE record;
- SUITE state that disagrees with the process status or check vector;
- different catalog identity sets across supported environments.

## Human And Machine Projections

One recording path combines the canonical catalog metadata with each observed
terminal state in one ledger. The final human-readable summary and the
machine-readable `TEST`, `STEP`, and `SUITE` records are generated from that
ledger. Neither projection maintains independent counters or infers a state
that is absent from the ledger.

The human summary carries the complete state vector and final suite state, and
names every non-PASS check with its identity, check kind, test method, state,
and reason. Category and description remain catalog context and are not
repeated in the human exception list.

The machine-readable `TEST` record carries suite, run, STEP, check identity,
category, check kind, test method, state, and encoded reason in the fixed
grammar above. `STEP` and `SUITE` carry the corresponding complete vectors,
and `SUITE` also carries the final suite execution state.

Projection agreement compares the complete vector and the common check fields:
identity, check kind, test method, state, and reason. Machine-only routing
fields and catalog context are validated against the ledger separately. Both
projections must reconcile with the ledger before `SUITE` is emitted.

## Producer and Consumer Boundary

The test suites and shared reporter own the catalog, recording path, ledger,
and both output projections. Gate consumption is separate and reads only the
machine-readable records after M8 implements this producer contract; it does
not infer states from human-readable prose.

`run-all-tests.bash` collects the final record together with the producer exit
status. It accepts `state=PASS` only with producer status zero and no `FAIL` or
`SCRIPT_ERROR` count. It accepts `state=FAIL` only with a nonzero producer
status. An all-PASS check vector may therefore carry suite state `FAIL` when
producer or reporter cleanup failed, while the fixed check identities remain
unchanged.
