# Test Reporting Inventory

## Scope

This document is the M8 step 1 index for every result-producing script under
tests/. It fixes the suite boundaries, stable identity counts, STEP ownership,
and conditional-result mappings that the shared reporter implementation must
preserve.

## Suite Inventory

| Suite | Script | Scope | Runner | Category | Inventory | Fixed Total |
| --- | --- | --- | --- | --- | --- | ---: |
| error-handling | test-error-handling.bash | none | source | error-contract | ERROR_HANDLING_INVENTORY.md | 146 |
| local-lifecycle | test-local-lifecycle.bash | local | source or installed | lifecycle-behavior | LOCAL_LIFECYCLE_INVENTORY.md | 126 |
| source-regression | test-source-regression.bash | system | source | source-regression | SOURCE_REGRESSION_INVENTORY.md | 87 |
| system-infra | test-system-infra.bash | system | none | installed-conformance | SYSTEM_INFRA_INVENTORY.md | 36 |
| system-lifecycle | test-system-lifecycle.bash | system | source or installed | lifecycle-behavior | SYSTEM_LIFECYCLE_INVENTORY.md | 93 |
| All suites | - | - | - | - | - | 488 |

run-all-tests.bash is a collector and dispatcher. It owns no product check ID
and must not create a terminal state for a suite check.

## Fixed-Vector Rules

- Every suite declares its complete ordered identity set before the first
  environment probe or behavior check.
- Source and installed lifecycle runs share identities; runner records origin.
- OS-specific and permission-specific branches retain their identities and
  close them through explicit prerequisite or applicability states.
- A required missing artifact fails its own identity and skips its dependents.
- An unexpected abort closes all remaining identities as SCRIPT_ERROR.
- Human and machine output use the same ledger and the same 488 identities.

## Method and Category Boundary

The former error-handling S12 checks and eight S13 checks have an accepted
destination at local-lifecycle S35; one duplicate S13 check is removed. Twelve
S14 through S16 source contracts have accepted destinations at
source-regression S15 through S17. S18 has an accepted real-path destination
at local-lifecycle S35. S20 has an accepted destination at source-regression
S18. S22 through S34 have accepted destinations at source-regression S19
through S21. Two S34 behavior checks duplicate real softIoc coverage in
local-lifecycle S30 and are removed. No accepted catalog check uses a
hand-built reproduction.

## Completeness Conditions

Step 1 is complete when all five inventory totals are unique within each suite,
their sum is 488, every source assertion and conditional result branch has one
mapping, and no moved S07-S14 source-regression identity remains in
system-infra.
