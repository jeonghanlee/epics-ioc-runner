# Error Handling Reporting Inventory

## Scope

This document is the M8 step 1 inventory for tests/test-error-handling.bash.
It assigns one stable identity to every current assertion and every
result-producing conditional branch. It does not claim that the current suite
passes, and it does not accept a hand-built reproduction as verification
evidence.

The suite identity is error-handling, with scope=none, os=host, and
runner=source. Its primary category is error-contract.

## Inventory Basis

The source pipeline contains S01 through S40. Its full non-root branch contains
190 current behavior identities. Source review adds eight result-producing
conditions that currently disappear from the counters:

- one P00 required runner-source check;
- one S23 required completion-script check;
- one S40 required exact-function extraction check;
- one applicability check in each of S27, S29, S30, S31, and S32.

The current expected check and STEP counts are owned by
[`reporting-counts.csv`](reporting-counts.csv). S01, S12, S13, S14, S15, S16,
S18, S20, S22, S33, and S34 are setup-only and own no check. Each loop case has its own semantic key. The 30
interruption trials inside S06 remain evidence for two aggregate checks and
are not separate catalog identities.

## Dependency Policy

- error-handling.P00.runner-source-readable governs all numbered STEPs.
- error-handling.S23.completion-script-available governs the eight S23 behavior
  checks. If the file is absent, the required check is FAIL and the dependent
  checks are SKIP.
- Each nonroot-permission-probes-applicable check governs only the permission
  branch in its own STEP. Under effective UID 0, that applicability check and
  its dependent behavior checks are NA.
- The three S38 non-writable-`IOC_CHDIR` behavior identities are NA under
  effective UID 0 because Bash `-w` cannot reproduce the non-root permission
  boundary there; the remaining S38 identities still execute.
- `error-handling.S40.reader-equivalence.exact-function-extraction` governs the
  eight direct reader fixtures. If exact extraction fails, the required check
  is FAIL and the dependent checks are SKIP.
- An unexpected abort preserves closed states and closes every remaining open
  identity as SCRIPT_ERROR.

## Current Method and Category Findings

The former S12 checks have an accepted disposition: they move to
local-lifecycle S35, and the LOG_DIR check executes the real install path and
reads the emitted unit rather than reconstructing the runner's internal
function.

S13's accepted disposition moves eight checks to local-lifecycle S35 and
removes one check duplicated by the existing namespaced LOG_DIR artifact
check. S14's accepted disposition moves twelve source contracts to
source-regression S15 as REQUIRED direct inspections. S15's accepted
disposition moves four unit-template source contracts to source-regression S16
as REQUIRED direct inspections. S16's accepted disposition moves three
metadata-injection source contracts to source-regression S17 as REQUIRED direct
inspections. S18's accepted disposition replaces two internal LOG_DIR
reproductions with real local installs in local-lifecycle S35. S20's accepted
disposition moves one source contract to source-regression S18 as a REQUIRED
direct inspection. S22's accepted disposition moves three source contracts and
one normalized exact source-contract replacement to source-regression S19 as REQUIRED
direct inspections. S33's accepted disposition moves all twenty-two pattern
source contracts to source-regression S20 and removes the exclusion pipeline
from the sixteen base-pattern fixtures. S34's accepted disposition moves five
source contracts to source-regression S21 and removes two behavior checks
already covered through real softIoc paths in local-lifecycle S30.

Every source check now has an accepted category, kind, method, and evidence
path before reporter implementation begins.

## Accepted S13 Disposition

| Source Check ID | Disposition | Destination Check ID | Category | Kind | Method | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| `error-handling.S13.install-succeeds-with-full-precedence-matrix` | `move` | `local-lifecycle.S35.precedence-install-succeeds` | `lifecycle-behavior` | `BEHAVIOR` | `real-path` | The selected runner completes a local install while unified path variables override namespaced variables. |
| `error-handling.S13.conf-dir-unified-var-wins` | `move` | `local-lifecycle.S35.unified-conf-path-used` | `lifecycle-behavior` | `BEHAVIOR` | `real-path` | The real install emits configuration under the unified path. |
| `error-handling.S13.conf-dir-namespaced-var-ignored` | `move` | `local-lifecycle.S35.namespaced-conf-path-unused` | `lifecycle-behavior` | `BEHAVIOR` | `real-path` | The real install does not emit configuration under the namespaced fallback path. |
| `error-handling.S13.run-dir-unified-var-wins-in-ioc-port` | `move` | `local-lifecycle.S35.unified-run-path-baked-into-ioc-port` | `lifecycle-behavior` | `BEHAVIOR` | `real-path` | The emitted configuration records the unified runtime path in `IOC_PORT`. |
| `error-handling.S13.run-dir-namespaced-var-ignored-in-ioc-port` | `move` | `local-lifecycle.S35.namespaced-run-path-unused` | `lifecycle-behavior` | `BEHAVIOR` | `real-path` | The emitted `IOC_PORT` does not record the namespaced fallback runtime path. |
| `error-handling.S13.systemd-dir-unified-var-wins` | `move` | `local-lifecycle.S35.unified-systemd-path-used` | `lifecycle-behavior` | `BEHAVIOR` | `real-path` | The real install emits the unit under the unified systemd path. |
| `error-handling.S13.systemd-dir-namespaced-var-ignored` | `move` | `local-lifecycle.S35.namespaced-systemd-path-unused` | `lifecycle-behavior` | `BEHAVIOR` | `real-path` | The real install does not emit the unit under the namespaced fallback path. |
| `error-handling.S13.log-dir-unified-var-wins` | `replace-and-move` | `local-lifecycle.S35.unified-log-path-baked-into-unit` | `lifecycle-behavior` | `BEHAVIOR` | `real-path` | The emitted unit replaces the former internal-function reconstruction as LOG_DIR evidence. |
| `error-handling.S13.log-dir-namespaced-var-honored-when-no-unified` | `remove` | - | - | - | - | Existing `local-lifecycle.S35.namespaced-log-path-baked-into-unit` verifies the same contract through the real emitted unit. |

Owner accepted all S13 dispositions on 2026-08-06.

## Accepted S14 Disposition

| Source Check ID | Disposition | Destination Check ID | Category | Kind | Method | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| `error-handling.S14.runner-user-identity-resolves-the-ioc-runner-system-user-override` | `move` | `source-regression.S15.runner-user-override-declaration` | `source-regression` | `REQUIRED` | `direct-inspection` | The check reads the runner declaration; it does not execute override behavior. |
| `error-handling.S14.setup-user-identity-resolves-the-same-override-variable` | `move` | `source-regression.S15.setup-user-override-declaration` | `source-regression` | `REQUIRED` | `direct-inspection` | The check reads the setup declaration for the shared user override. |
| `error-handling.S14.runner-user-default-pinned-to-ioc-srv` | `move` | `source-regression.S15.runner-user-default-ioc-srv` | `source-regression` | `REQUIRED` | `direct-inspection` | The check pins the runner source contract for the user default. |
| `error-handling.S14.user-defaults-agree-across-both-scripts` | `move` | `source-regression.S15.user-defaults-agree` | `source-regression` | `REQUIRED` | `direct-inspection` | The check prevents one-sided drift between the two source declarations. |
| `error-handling.S14.runner-group-identity-resolves-the-ioc-runner-system-group-override` | `move` | `source-regression.S15.runner-group-override-declaration` | `source-regression` | `REQUIRED` | `direct-inspection` | The check reads the runner declaration; it does not execute override behavior. |
| `error-handling.S14.setup-group-identity-resolves-the-same-override-variable` | `move` | `source-regression.S15.setup-group-override-declaration` | `source-regression` | `REQUIRED` | `direct-inspection` | The check reads the setup declaration for the shared group override. |
| `error-handling.S14.runner-group-default-pinned-to-ioc` | `move` | `source-regression.S15.runner-group-default-ioc` | `source-regression` | `REQUIRED` | `direct-inspection` | The check pins the runner source contract for the group default. |
| `error-handling.S14.group-defaults-agree-across-both-scripts` | `move` | `source-regression.S15.group-defaults-agree` | `source-regression` | `REQUIRED` | `direct-inspection` | The check prevents one-sided drift between the two source declarations. |
| `error-handling.S14.runner-log-dir-resolves-the-ioc-runner-system-log-dir-override` | `move` | `source-regression.S15.runner-log-dir-override-declaration` | `source-regression` | `REQUIRED` | `direct-inspection` | The check reads the runner declaration; it does not execute override behavior. |
| `error-handling.S14.setup-log-dir-resolves-the-same-override-variable` | `move` | `source-regression.S15.setup-log-dir-override-declaration` | `source-regression` | `REQUIRED` | `direct-inspection` | The check reads the setup declaration for the shared log-directory override. |
| `error-handling.S14.runner-log-dir-default-pinned-to-var-log-procserv` | `move` | `source-regression.S15.runner-log-dir-default` | `source-regression` | `REQUIRED` | `direct-inspection` | The check pins the runner source contract for the system log default. |
| `error-handling.S14.log-dir-defaults-agree-across-both-scripts` | `move` | `source-regression.S15.log-dir-defaults-agree` | `source-regression` | `REQUIRED` | `direct-inspection` | The check prevents one-sided drift between the two source declarations. |

Owner accepted all S14 dispositions on 2026-08-06.

## Accepted S15 Disposition

| Source Check ID | Disposition | Destination Check ID | Category | Kind | Method | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| `error-handling.S15.both-unit-templates-extracted-from-source` | `move` | `source-regression.S16.templates.extracted` | `source-regression` | `REQUIRED` | `direct-inspection` | The check establishes that both source contracts were extracted before comparison; it does not execute unit behavior. |
| `error-handling.S15.unit-template-must-agree-rows-identical-across-both-scripts` | `move` | `source-regression.S16.templates.must-agree` | `source-regression` | `REQUIRED` | `direct-inspection` | The check compares normalized source rows and prevents one-sided drift between the two templates. |
| `error-handling.S15.m10-restart-directives-present-in-the-unit-must-agree-block` | `move` | `source-regression.S16.restart-directives.present` | `source-regression` | `REQUIRED` | `direct-inspection` | The check pins required restart directives against two-sided source removal. |
| `error-handling.S15.runtimedirectorypreserve-restart-present-in-both-unit-templates-m5-108` | `move` | `source-regression.S16.runtime-directory-preserve.present` | `source-regression` | `REQUIRED` | `direct-inspection` | The check pins `RuntimeDirectoryPreserve=restart` in both source templates. |

Owner accepted all S15 dispositions on 2026-08-07.

## Accepted S16 Disposition

| Source Check ID | Disposition | Destination Check ID | Category | Kind | Method | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| `error-handling.S16.metadata-sed-targets-extracted-from-both-injectors` | `move` | `source-regression.S17.metadata.targets-extracted` | `source-regression` | `REQUIRED` | `direct-inspection` | The check establishes that both injector source contracts were extracted before comparison; it does not execute injection behavior. |
| `error-handling.S16.both-injectors-target-the-same-runner-metadata-set` | `move` | `source-regression.S17.metadata.injectors-agree` | `source-regression` | `REQUIRED` | `direct-inspection` | The check compares the source-level `RUNNER_*` target sets and prevents one-sided drift. |
| `error-handling.S16.every-injected-runner-has-a-declaration-anchor-in-the-runner` | `move` | `source-regression.S17.metadata.declaration-anchors-present` | `source-regression` | `REQUIRED` | `direct-inspection` | The check requires every injected source name to retain a runner declaration anchor. |

Owner accepted all S16 dispositions on 2026-08-07.

## Accepted S18 Disposition

| Source Check ID | Disposition | Destination Check ID | Category | Kind | Method | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| `error-handling.S18.xdg-state-home-unset-local-log-dir-falls-back-to-home-local-state-procserv` | `replace-and-move` | `local-lifecycle.S35.xdg-state-home-unset-log-path-baked-into-unit` | `lifecycle-behavior` | `BEHAVIOR` | `real-path` | The selected runner performs a real local install with all log overrides and `XDG_STATE_HOME` unset; the emitted unit must use the isolated `HOME/.local/state/procserv` path. |
| `error-handling.S18.xdg-state-home-set-local-log-dir-uses-xdg-state-home-procserv` | `replace-and-move` | `local-lifecycle.S35.xdg-state-home-log-path-baked-into-unit` | `lifecycle-behavior` | `BEHAVIOR` | `real-path` | The selected runner performs a real local install with log overrides unset and `XDG_STATE_HOME` set; the emitted unit must use `<XDG_STATE_HOME>/procserv`. |

Owner accepted both S18 dispositions on 2026-08-07.

## Accepted S20 Disposition

| Source Check ID | Disposition | Destination Check ID | Category | Kind | Method | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| `error-handling.S20.no-h-2-1-grep-q-pipeline-probes-remain-in-bin-ioc-runner-110` | `move` | `source-regression.S18.pipefail-help-probe-pattern.absent` | `source-regression` | `REQUIRED` | `direct-inspection` | The check enforces a runner source rule and does not execute helper capability behavior. |

Owner accepted the S20 disposition on 2026-08-07.

## Accepted S22 Disposition

| Source Check ID | Disposition | Destination Check ID | Category | Kind | Method | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| `error-handling.S22.six-regex-form-cmnd-eres-found-in-setup` | `move` | `source-regression.S19.sudoers-regex.count-six` | `source-regression` | `REQUIRED` | `direct-inspection` | The check pins the six regex-form command source entries and makes no deployed-policy behavior claim. |
| `error-handling.S22.all-six-cmnd-eres-are-identical` | `move` | `source-regression.S19.sudoers-regex.identical` | `source-regression` | `REQUIRED` | `direct-inspection` | The check prevents one-sided IOC-name expression drift among the six source entries. |
| `error-handling.S22.runner-length-rule-extracted-64` | `move` | `source-regression.S19.runner-name.max-length-64` | `source-regression` | `REQUIRED` | `direct-inspection` | The check pins the runner source maximum and makes no IOC-name acceptance behavior claim. |
| `error-handling.S22.runner-and-sudoers-charsets-agree-across-21-candidates` | `replace-and-move` | `source-regression.S19.runner-sudoers-name-contracts.agree` | `source-regression` | `REQUIRED` | `direct-inspection` | Normalized exact comparison of the extracted source contracts replaces the finite candidate reproduction while permitting only equivalent ASCII letter-range order. |

Owner accepted all S22 dispositions on 2026-08-07.

## Accepted S33 Disposition

| Source Check ID | Disposition | Destination Check ID | Category | Kind | Method | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| `error-handling.S33.pattern-unbalanced-quote` | `replace-and-move` | `source-regression.S20.pattern-unbalanced-quote` | `source-regression` | `REQUIRED` | `direct-inspection` | Evaluate the extracted base regex directly; runtime crash behavior remains in the lifecycle suites. |
| `error-handling.S33.pattern-invalid-directory-path` | `replace-and-move` | `source-regression.S20.pattern-invalid-directory-path` | `source-regression` | `REQUIRED` | `direct-inspection` | Evaluate the extracted base regex directly without reproducing the exclusion pipeline. |
| `error-handling.S33.pattern-can-t-open` | `replace-and-move` | `source-regression.S20.pattern-can-t-open` | `source-regression` | `REQUIRED` | `direct-inspection` | Evaluate the extracted base regex directly without reproducing the exclusion pipeline. |
| `error-handling.S33.pattern-cannot-open` | `replace-and-move` | `source-regression.S20.pattern-cannot-open` | `source-regression` | `REQUIRED` | `direct-inspection` | Evaluate the extracted base regex directly without reproducing the exclusion pipeline. |
| `error-handling.S33.pattern-undefined-symbol` | `replace-and-move` | `source-regression.S20.pattern-undefined-symbol` | `source-regression` | `REQUIRED` | `direct-inspection` | Evaluate the extracted base regex directly; runtime fatal detection remains in the lifecycle suites. |
| `error-handling.S33.pattern-no-such-file-or-directory` | `replace-and-move` | `source-regression.S20.pattern-no-such-file-or-directory` | `source-regression` | `REQUIRED` | `direct-inspection` | Evaluate the extracted base regex directly without reproducing the exclusion pipeline. |
| `error-handling.S33.case-insensitive-error-upper` | `replace-and-move` | `source-regression.S20.case-insensitive-error-upper` | `source-regression` | `REQUIRED` | `direct-inspection` | Pin case-insensitive base-regex membership without claiming runtime behavior. |
| `error-handling.S33.case-insensitive-error-title` | `replace-and-move` | `source-regression.S20.case-insensitive-error-title` | `source-regression` | `REQUIRED` | `direct-inspection` | Pin case-insensitive base-regex membership without claiming runtime behavior. |
| `error-handling.S33.case-insensitive-error-lower` | `replace-and-move` | `source-regression.S20.case-insensitive-error-lower` | `source-regression` | `REQUIRED` | `direct-inspection` | Pin case-insensitive base-regex membership without claiming runtime behavior. |
| `error-handling.S33.case-insensitive-fatal-upper` | `replace-and-move` | `source-regression.S20.case-insensitive-fatal-upper` | `source-regression` | `REQUIRED` | `direct-inspection` | Pin case-insensitive base-regex membership without claiming runtime behavior. |
| `error-handling.S33.case-insensitive-fatal-lower` | `replace-and-move` | `source-regression.S20.case-insensitive-fatal-lower` | `source-regression` | `REQUIRED` | `direct-inspection` | Pin case-insensitive base-regex membership without claiming runtime behavior. |
| `error-handling.S33.regression-segmentation-fault` | `replace-and-move` | `source-regression.S20.regression-segmentation-fault` | `source-regression` | `REQUIRED` | `direct-inspection` | Pin base-regex membership; runtime fatal detection remains in the lifecycle suites. |
| `error-handling.S33.negative-procserv-child-start-line` | `replace-and-move` | `source-regression.S20.negative-procserv-child-start-line` | `source-regression` | `REQUIRED` | `direct-inspection` | Require the extracted base regex not to match routine procServ output. |
| `error-handling.S33.negative-iocinit-complete-line` | `replace-and-move` | `source-regression.S20.negative-iocinit-complete-line` | `source-regression` | `REQUIRED` | `direct-inspection` | Require the extracted base regex not to match the ready marker. |
| `error-handling.S33.negative-epics-banner` | `replace-and-move` | `source-regression.S20.negative-epics-banner` | `source-regression` | `REQUIRED` | `direct-inspection` | Require the extracted base regex not to match a normal EPICS banner. |
| `error-handling.S33.negative-startup-banner` | `replace-and-move` | `source-regression.S20.negative-startup-banner` | `source-regression` | `REQUIRED` | `direct-inspection` | Require the extracted base regex not to match a normal startup line. |
| `error-handling.S33.dry-base-crash-log-patterns-fatal-ambiguous-subsets` | `move` | `source-regression.S20.base-patterns.equal-subset-union` | `source-regression` | `REQUIRED` | `direct-inspection` | Require the base regex to be composed directly from the two subsets without a runtime behavior claim. |
| `error-handling.S33.subset-fatal-is-fatal` | `move` | `source-regression.S20.subset-fatal-is-fatal` | `source-regression` | `REQUIRED` | `direct-inspection` | Pin fatal-subset source membership. |
| `error-handling.S33.subset-undefined-symbol-is-fatal` | `move` | `source-regression.S20.subset-undefined-symbol-is-fatal` | `source-regression` | `REQUIRED` | `direct-inspection` | Pin fatal-subset source membership. |
| `error-handling.S33.subset-can-t-open-is-ambiguous` | `move` | `source-regression.S20.subset-can-t-open-is-ambiguous` | `source-regression` | `REQUIRED` | `direct-inspection` | Pin ambiguous-subset source membership. |
| `error-handling.S33.subset-error-is-ambiguous` | `move` | `source-regression.S20.subset-error-is-ambiguous` | `source-regression` | `REQUIRED` | `direct-inspection` | Pin ambiguous-subset source membership. |
| `error-handling.S33.subset-invalid-directory-path-is-ambiguous-benign-epics-warning` | `move` | `source-regression.S20.subset-invalid-directory-path-is-ambiguous` | `source-regression` | `REQUIRED` | `direct-inspection` | Pin ambiguous-subset source membership. |

Owner accepted all S33 dispositions on 2026-08-07.

## Accepted S34 Disposition

| Source Check ID | Disposition | Destination Check ID | Category | Kind | Method | Reason |
| --- | --- | --- | --- | --- | --- | --- |
| `error-handling.S34.exclusion-constant-extracted-non-empty-from-runner-script` | `move` | `source-regression.S21.exclude-pattern.nonempty` | `source-regression` | `REQUIRED` | `direct-inspection` | Pin the extracted exclusion source constant without a runtime behavior claim. |
| `error-handling.S34.exclusion-constant-compiles-under-grep-e` | `move` | `source-regression.S21.exclude-pattern.compiles` | `source-regression` | `REQUIRED` | `direct-inspection` | Validate the extracted exclusion regex as a source contract. |
| `error-handling.S34.exclusion-pin-history-load-line-matches-patterns-without-filter` | `replace-and-move` | `source-regression.S21.history-load.matches-base-patterns` | `source-regression` | `REQUIRED` | `direct-inspection` | Retain the source-level positive control without reproducing the exclusion pipeline. |
| `error-handling.S34.exclusion-history-load-line-cleared-through-pipeline` | `remove-duplicate` | `local-lifecycle.S30.history-noise-exits-zero` | `lifecycle-behavior` | `BEHAVIOR` | `real-path` | Local lifecycle already emits the history-load diagnostic and verifies healthy startup through the shipped path. |
| `error-handling.S34.exclusion-history-write-variant-cleared-through-pipeline` | `replace-and-move` | `source-regression.S21.history-write.matches-exclude-pattern` | `source-regression` | `REQUIRED` | `direct-inspection` | Narrow the unsupported behavior claim to exclusion-regex source membership. |
| `error-handling.S34.exclusion-fatal-on-another-line-in-the-window-still-matches` | `remove-duplicate` | `local-lifecycle.S30.history-fatal-exits-one` | `lifecycle-behavior` | `BEHAVIOR` | `real-path` | Local lifecycle already verifies a real fatal event beside emitted history noise through the shipped path. |
| `error-handling.S34.exclusion-same-line-collision-excluded-documented-residual` | `replace-and-move` | `source-regression.S21.line-filter.precedes-crash-scans` | `source-regression` | `REQUIRED` | `direct-inspection` | Narrow the constructed collision claim to the shipped line-filter ordering contract. |

Owner accepted all S34 dispositions on 2026-08-07.

## Stable Identity Mapping

| STEP | Check ID | Kind | Current Method | Current Assertion or Condition |
| --- | --- | --- | --- | --- |
| P00 | `error-handling.P00.runner-source-readable` | `REQUIRED` | `direct-inspection` | The shipped runner source is readable before suite execution. |
| S02 | `error-handling.S02.help-exits-0` | `BEHAVIOR` | `real-path` | --help exits 0 |
| S02 | `error-handling.S02.h-exits-0` | `BEHAVIOR` | `real-path` | -h exits 0 |
| S02 | `error-handling.S02.no-arguments-exits-0` | `BEHAVIOR` | `real-path` | no arguments exits 0 |
| S02 | `error-handling.S02.unknown-command-exits-1` | `BEHAVIOR` | `real-path` | unknown command exits 1 |
| S02 | `error-handling.S02.v-exits-0-from-unrelated-cwd` | `BEHAVIOR` | `real-path` | '-V' exits 0 from unrelated CWD |
| S02 | `error-handling.S02.v-produces-valid-version-output-from-unrelated-cwd` | `BEHAVIOR` | `real-path` | '-V' produces valid version output from unrelated CWD |
| S02 | `error-handling.S02.v-start-exits-1-verbose-restricted-to-list` | `BEHAVIOR` | `real-path` | '-v start' exits 1 (verbose restricted to list) |
| S02 | `error-handling.S02.vv-status-exits-1-verbose-restricted-to-list` | `BEHAVIOR` | `real-path` | '-vv status' exits 1 (verbose restricted to list) |
| S02 | `error-handling.S02.local-v-list-exits-0-verbose-valid-for-list` | `BEHAVIOR` | `real-path` | '--local -v list' exits 0 (verbose valid for list) |
| S03 | `error-handling.S03.start-without-target-exits-1` | `BEHAVIOR` | `real-path` | 'start' without target exits 1 |
| S03 | `error-handling.S03.stop-without-target-exits-1` | `BEHAVIOR` | `real-path` | 'stop' without target exits 1 |
| S03 | `error-handling.S03.restart-without-target-exits-1` | `BEHAVIOR` | `real-path` | 'restart' without target exits 1 |
| S03 | `error-handling.S03.status-without-target-exits-1` | `BEHAVIOR` | `real-path` | 'status' without target exits 1 |
| S03 | `error-handling.S03.enable-without-target-exits-1` | `BEHAVIOR` | `real-path` | 'enable' without target exits 1 |
| S03 | `error-handling.S03.disable-without-target-exits-1` | `BEHAVIOR` | `real-path` | 'disable' without target exits 1 |
| S03 | `error-handling.S03.remove-without-target-exits-1` | `BEHAVIOR` | `real-path` | 'remove' without target exits 1 |
| S03 | `error-handling.S03.attach-without-target-exits-1` | `BEHAVIOR` | `real-path` | 'attach' without target exits 1 |
| S03 | `error-handling.S03.view-without-target-exits-1` | `BEHAVIOR` | `real-path` | 'view' without target exits 1 |
| S04 | `error-handling.S04.generate-native-dot-path-resolves-successfully` | `BEHAVIOR` | `real-path` | Generate native dot path resolves successfully |
| S04 | `error-handling.S04.configuration-artifact-created-dynamically` | `BEHAVIOR` | `real-path` | Configuration artifact created dynamically |
| S04 | `error-handling.S04.identical-artifact-natively-bypasses-overwrite-and-exits-0` | `BEHAVIOR` | `real-path` | Identical artifact natively bypasses overwrite and exits 0 |
| S04 | `error-handling.S04.identical-re-generate-takes-the-skip-path` | `BEHAVIOR` | `real-path` | Identical re-generate takes the skip path |
| S04 | `error-handling.S04.identical-skip-reasserts-conf-mode-0600-123` | `BEHAVIOR` | `real-path` | Identical-skip reasserts conf mode 0600 (#123) |
| S04 | `error-handling.S04.differential-artifact-prompt-exits-1-on-eof` | `BEHAVIOR` | `real-path` | Differential artifact prompt exits 1 on EOF |
| S04 | `error-handling.S04.differential-artifact-prompt-exits-1-on-user-decline` | `BEHAVIOR` | `real-path` | Differential artifact prompt exits 1 on user decline |
| S04 | `error-handling.S04.forced-overwrite-ignores-diff-constraint-and-exits-0` | `BEHAVIOR` | `real-path` | Forced overwrite ignores diff constraint and exits 0 |
| S05 | `error-handling.S05.directory-based-installation-resolves-artifact-correctly` | `BEHAVIOR` | `real-path` | Directory-based installation resolves artifact correctly |
| S05 | `error-handling.S05.artifact-successfully-routed-to-configuration-directory` | `BEHAVIOR` | `real-path` | Artifact successfully routed to configuration directory |
| S05 | `error-handling.S05.install-overwrite-prompt-exits-1-on-eof` | `BEHAVIOR` | `real-path` | Install overwrite prompt exits 1 on EOF |
| S05 | `error-handling.S05.install-eof-abort-preserves-existing-conf-marker-retained` | `BEHAVIOR` | `real-path` | Install EOF abort preserves existing conf (marker retained) |
| S05 | `error-handling.S05.install-overwrite-prompt-exits-1-on-user-decline` | `BEHAVIOR` | `real-path` | Install overwrite prompt exits 1 on user decline |
| S05 | `error-handling.S05.install-decline-abort-preserves-existing-conf-marker-retained` | `BEHAVIOR` | `real-path` | Install decline abort preserves existing conf (marker retained) |
| S06 | `error-handling.S06.atomic-install-no-partial-conf-across-120-interrupted-installs` | `BEHAVIOR` | `real-path` | Atomic install: no partial conf across 120 interrupted installs |
| S06 | `error-handling.S06.atomic-install-install-exits-only-0-or-124-under-interruption` | `BEHAVIOR` | `real-path` | Atomic install: install exits only 0 or 124 under interruption |
| S07 | `error-handling.S07.generate-with-invalid-directory-name-exits-1` | `BEHAVIOR` | `real-path` | Generate with invalid directory name exits 1 |
| S07 | `error-handling.S07.generate-with-no-executable-scripts-exits-1` | `BEHAVIOR` | `real-path` | Generate with no executable scripts exits 1 |
| S07 | `error-handling.S07.generate-with-multiple-candidates-aborts-interactively` | `BEHAVIOR` | `real-path` | Generate with multiple candidates aborts interactively |
| S07 | `error-handling.S07.generate-with-force-flag-resolves-multiple-candidates-and-exits-0` | `BEHAVIOR` | `real-path` | Generate with force flag resolves multiple candidates and exits 0 |
| S07 | `error-handling.S07.multiple-cmd-candidates-without-input-exits-1-no-default` | `BEHAVIOR` | `real-path` | Multiple cmd candidates without input exits 1 (no default) |
| S07 | `error-handling.S07.generate-overwrite-prompt-exits-1-on-eof` | `BEHAVIOR` | `real-path` | Generate overwrite prompt exits 1 on EOF |
| S07 | `error-handling.S07.generate-eof-abort-preserves-existing-conf-unchanged` | `BEHAVIOR` | `real-path` | Generate EOF abort preserves existing conf unchanged |
| S07 | `error-handling.S07.generate-abort-leaves-no-staged-tmp-in-the-target-dir-107` | `BEHAVIOR` | `real-path` | Generate abort leaves no staged tmp in the target dir (#107) |
| S07 | `error-handling.S07.generate-succeeds-with-a-poisoned-tmpdir-107-same-dir-staging` | `BEHAVIOR` | `real-path` | Generate succeeds with a poisoned TMPDIR (#107 same-dir staging) |
| S07 | `error-handling.S07.local-generate-writes-the-conf-0600-107` | `BEHAVIOR` | `real-path` | Local generate writes the conf 0600 (#107) |
| S07 | `error-handling.S07.system-mode-generate-succeeds-with-a-poisoned-tmpdir-107` | `BEHAVIOR` | `real-path` | System-mode generate succeeds with a poisoned TMPDIR (#107) |
| S07 | `error-handling.S07.system-mode-generate-writes-the-conf-0660-107` | `BEHAVIOR` | `real-path` | System-mode generate writes the conf 0660 (#107) |
| S08 | `error-handling.S08.install-with-missing-conf-file-exits-1` | `BEHAVIOR` | `real-path` | 'install' with missing conf file exits 1 |
| S08 | `error-handling.S08.install-with-missing-system-template-exits-1` | `BEHAVIOR` | `real-path` | 'install' with missing system template exits 1 |
| S08 | `error-handling.S08.install-directory-with-mismatched-conf-name-exits-1` | `BEHAVIOR` | `real-path` | Install directory with mismatched conf name exits 1 |
| S08 | `error-handling.S08.install-file-direct-with-invalid-ioc-name-exits-1` | `BEHAVIOR` | `real-path` | Install file-direct with invalid IOC name exits 1 |
| S09 | `error-handling.S09.plain-list-succeeds-with-broken-ss-no-vv-dependency` | `BEHAVIOR` | `real-path` | plain list succeeds with broken ss (no -vv dependency) |
| S09 | `error-handling.S09.list-vv-with-broken-ss-exits-1` | `BEHAVIOR` | `real-path` | list -vv with broken ss exits 1 |
| S09 | `error-handling.S09.list-vv-failure-names-ss-in-the-error` | `BEHAVIOR` | `real-path` | list -vv failure names ss in the error |
| S10 | `error-handling.S10.stop-on-a-never-installed-name-exits-1` | `BEHAVIOR` | `real-path` | stop on a never-installed name exits 1 |
| S10 | `error-handling.S10.enable-on-a-never-installed-name-exits-1` | `BEHAVIOR` | `real-path` | enable on a never-installed name exits 1 |
| S10 | `error-handling.S10.disable-on-a-never-installed-name-exits-1` | `BEHAVIOR` | `real-path` | disable on a never-installed name exits 1 |
| S10 | `error-handling.S10.remove-on-a-never-installed-name-exits-1` | `BEHAVIOR` | `real-path` | remove on a never-installed name exits 1 |
| S10 | `error-handling.S10.view-on-a-never-installed-name-exits-1` | `BEHAVIOR` | `real-path` | view on a never-installed name exits 1 |
| S10 | `error-handling.S10.gate-message-names-the-missing-configuration` | `BEHAVIOR` | `real-path` | gate message names the missing configuration |
| S11 | `error-handling.S11.exactly-one-ioc-port-replacement-warning` | `BEHAVIOR` | `real-path` | exactly one IOC_PORT replacement warning |
| S17 | `error-handling.S17.system-differing-ioc-runner-log-dir-triggers-warning` | `BEHAVIOR` | `real-path` | system + differing IOC_RUNNER_LOG_DIR triggers warning |
| S17 | `error-handling.S17.system-matching-ioc-runner-log-dir-suppresses-warning` | `BEHAVIOR` | `real-path` | system + matching IOC_RUNNER_LOG_DIR suppresses warning |
| S17 | `error-handling.S17.local-mode-suppresses-log-dir-guard` | `BEHAVIOR` | `real-path` | --local mode suppresses LOG_DIR guard |
| S19 | `error-handling.S19.relative-ioc-runner-conf-dir-exits-1-on-list` | `BEHAVIOR` | `real-path` | relative IOC_RUNNER_CONF_DIR exits 1 on list |
| S19 | `error-handling.S19.relative-conf-dir-error-names-the-resolved-directory` | `BEHAVIOR` | `real-path` | relative CONF_DIR error names the resolved directory |
| S19 | `error-handling.S19.whitespace-conf-dir-exits-1-on-status` | `BEHAVIOR` | `real-path` | whitespace CONF_DIR exits 1 on status |
| S19 | `error-handling.S19.whitespace-conf-dir-error-names-the-resolved-directory` | `BEHAVIOR` | `real-path` | whitespace CONF_DIR error names the resolved directory |
| S19 | `error-handling.S19.absolute-conf-dir-passes-the-guard` | `BEHAVIOR` | `real-path` | absolute CONF_DIR passes the guard |
| S21 | `error-handling.S21.install-proceeds-when-the-rotation-cfg-dir-is-uncreatable-110` | `BEHAVIOR` | `real-path` | install proceeds when the rotation cfg_dir is uncreatable (#110) |
| S21 | `error-handling.S21.uncreatable-cfg-dir-warns-and-skips-rotation-110` | `BEHAVIOR` | `real-path` | uncreatable cfg_dir warns and skips rotation (#110) |
| S23 | `error-handling.S23.completion-script-available` | `REQUIRED` | `direct-inspection` | The shipped completion script exists before its eight behavior checks run. |
| S23 | `error-handling.S23.bare-invocation-offers-generate-install-list` | `BEHAVIOR` | `real-path` | Bare invocation offers generate/install/list |
| S23 | `error-handling.S23.dash-prefix-offers-global-options` | `BEHAVIOR` | `real-path` | Dash prefix offers global options |
| S23 | `error-handling.S23.system-mode-reads-ioc-runner-system-conf-dir` | `BEHAVIOR` | `real-path` | System mode reads IOC_RUNNER_SYSTEM_CONF_DIR |
| S23 | `error-handling.S23.local-mode-reads-ioc-runner-local-conf-dir` | `BEHAVIOR` | `real-path` | --local mode reads IOC_RUNNER_LOCAL_CONF_DIR |
| S23 | `error-handling.S23.ioc-runner-conf-dir-overrides-local-var-in-completion` | `BEHAVIOR` | `real-path` | IOC_RUNNER_CONF_DIR overrides LOCAL var in completion |
| S23 | `error-handling.S23.list-command-suggests-v-and-vv` | `BEHAVIOR` | `real-path` | 'list' command suggests -v and -vv |
| S23 | `error-handling.S23.st-prefix-narrows-to-start-stop-status` | `BEHAVIOR` | `real-path` | 'st' prefix narrows to start/stop/status |
| S23 | `error-handling.S23.missing-conf-dir-yields-empty-compreply` | `BEHAVIOR` | `real-path` | Missing conf_dir yields empty COMPREPLY |
| S24 | `error-handling.S24.view-bad-name-whitespace-exits-1-via-name-validation` | `BEHAVIOR` | `real-path` | view 'bad name' (whitespace) exits 1 via name validation |
| S24 | `error-handling.S24.view-bad-name-special-char-exits-1-via-name-validation` | `BEHAVIOR` | `real-path` | view 'bad@name' (special char) exits 1 via name validation |
| S24 | `error-handling.S24.view-bad-name-period-exits-1-via-name-validation` | `BEHAVIOR` | `real-path` | view 'bad.name' (period) exits 1 via name validation |
| S24 | `error-handling.S24.view-bad-name-produces-invalid-ioc-name-error-message` | `BEHAVIOR` | `real-path` | view 'bad@name' produces 'Invalid IOC name' error message |
| S25 | `error-handling.S25.install-with-illegal-characters-in-cmd-exits-1` | `BEHAVIOR` | `real-path` | Install with illegal characters in CMD exits 1 |
| S25 | `error-handling.S25.install-with-wrong-local-user-exits-1` | `BEHAVIOR` | `real-path` | Install with wrong local user exits 1 |
| S25 | `error-handling.S25.wrong-local-user-field-error-retained` | `BEHAVIOR` | `real-path` | Wrong local user retains the field-level error |
| S25 | `error-handling.S25.wrong-local-user-summary-singular` | `BEHAVIOR` | `real-path` | Wrong local user reports the singular validation summary |
| S25 | `error-handling.S25.install-without-directory-execute-permission-exits-1` | `BEHAVIOR` | `real-path` | Install without directory execute permission exits 1 |
| S25 | `error-handling.S25.install-with-missing-required-key-ioc-cmd-exits-1` | `BEHAVIOR` | `real-path` | Install with missing required key (IOC_CMD) exits 1 |
| S25 | `error-handling.S25.install-with-in-system-ioc-chdir-exits-1` | `BEHAVIOR` | `real-path` | Install with '..' in system IOC_CHDIR exits 1 |
| S25 | `error-handling.S25.rejection-error-references-the-component` | `BEHAVIOR` | `real-path` | '..' rejection error references the '..' component |
| S25 | `error-handling.S25.install-with-bare-ioc-chdir-exits-1` | `BEHAVIOR` | `real-path` | Install with bare '..' IOC_CHDIR exits 1 |
| S25 | `error-handling.S25.bare-rejected-by-the-absolute-path-requirement-m6-109` | `BEHAVIOR` | `real-path` | bare '..' rejected by the absolute-path requirement (M6/#109) |
| S25 | `error-handling.S25.install-with-relative-ioc-chdir-exits-1` | `BEHAVIOR` | `real-path` | Install with relative IOC_CHDIR exits 1 |
| S25 | `error-handling.S25.relative-ioc-chdir-error-names-the-absolute-path-requirement` | `BEHAVIOR` | `real-path` | relative IOC_CHDIR error names the absolute-path requirement |
| S25 | `error-handling.S25.install-with-multi-word-ioc-cmd-exits-1` | `BEHAVIOR` | `real-path` | Install with multi-word IOC_CMD exits 1 |
| S25 | `error-handling.S25.multi-word-ioc-cmd-error-names-the-single-word-contract` | `BEHAVIOR` | `real-path` | multi-word IOC_CMD error names the single-word contract |
| S26 | `error-handling.S26.attach-with-missing-conf-exits-1` | `BEHAVIOR` | `real-path` | 'attach' with missing conf exits 1 |
| S26 | `error-handling.S26.attach-with-missing-ioc-port-key-exits-1` | `BEHAVIOR` | `real-path` | 'attach' with missing IOC_PORT key exits 1 |
| S26 | `error-handling.S26.attach-error-references-missing-ioc-port-key` | `BEHAVIOR` | `real-path` | 'attach' error references missing IOC_PORT key |
| S27 | `error-handling.S27.nonroot-permission-probes-applicable` | `APPLICABILITY` | `direct-inspection` | The non-traversable socket-directory probes apply to the effective user. |
| S27 | `error-handling.S27.list-with-no-active-sockets-exits-0` | `BEHAVIOR` | `real-path` | 'list' with no active sockets exits 0 |
| S27 | `error-handling.S27.genuinely-empty-list-carries-no-permission-hint` | `BEHAVIOR` | `real-path` | Genuinely empty list carries no permission hint |
| S27 | `error-handling.S27.list-with-a-non-traversable-socket-dir-exits-0` | `BEHAVIOR` | `real-path` | 'list' with a non-traversable socket dir exits 0 |
| S27 | `error-handling.S27.non-traversable-socket-dir-appends-the-permission-hint` | `BEHAVIOR` | `real-path` | Non-traversable socket dir appends the permission hint |
| S28 | `error-handling.S28.inspect-without-root-privileges-exits-1` | `BEHAVIOR` | `real-path` | 'inspect' without root privileges exits 1 |
| S29 | `error-handling.S29.nonroot-permission-probes-applicable` | `APPLICABILITY` | `direct-inspection` | The generate staging-permission probes apply to the effective user. |
| S29 | `error-handling.S29.generate-into-a-non-writable-directory-exits-1` | `BEHAVIOR` | `real-path` | Generate into a non-writable directory exits 1 |
| S29 | `error-handling.S29.generate-staging-failure-names-directory-writability` | `BEHAVIOR` | `real-path` | Generate staging failure names directory writability |
| S29 | `error-handling.S29.generate-staging-failure-hides-the-raw-mktemp-error` | `BEHAVIOR` | `real-path` | Generate staging failure hides the raw mktemp error |
| S30 | `error-handling.S30.nonroot-permission-probes-applicable` | `APPLICABILITY` | `direct-inspection` | The view access-barrier probes apply to the effective user. |
| S30 | `error-handling.S30.view-of-an-absent-conf-exits-1` | `BEHAVIOR` | `real-path` | View of an absent conf exits 1 |
| S30 | `error-handling.S30.view-missing-conf-error-rides-stderr` | `BEHAVIOR` | `real-path` | View missing-conf error rides stderr |
| S30 | `error-handling.S30.view-missing-conf-closing-divider-joins-the-error-on-stderr` | `BEHAVIOR` | `real-path` | View missing-conf closing divider joins the error on stderr |
| S30 | `error-handling.S30.view-missing-conf-stdout-keeps-only-the-header-divider` | `BEHAVIOR` | `real-path` | View missing-conf stdout keeps only the header divider |
| S30 | `error-handling.S30.view-of-an-unreadable-conf-dir-exits-1` | `BEHAVIOR` | `real-path` | View of an unreadable CONF_DIR exits 1 |
| S30 | `error-handling.S30.view-names-the-access-barrier-for-an-unreadable-conf-dir` | `BEHAVIOR` | `real-path` | View names the access barrier for an unreadable CONF_DIR |
| S30 | `error-handling.S30.view-does-not-misreport-an-unreadable-conf-dir-as-not-found` | `BEHAVIOR` | `real-path` | View does not misreport an unreadable CONF_DIR as not found |
| S31 | `error-handling.S31.nonroot-permission-probes-applicable` | `APPLICABILITY` | `direct-inspection` | The attach access-barrier probes apply to the effective user. |
| S31 | `error-handling.S31.attach-to-an-unreadable-conf-dir-exits-1` | `BEHAVIOR` | `real-path` | Attach to an unreadable CONF_DIR exits 1 |
| S31 | `error-handling.S31.attach-names-the-access-barrier-for-an-unreadable-conf-dir` | `BEHAVIOR` | `real-path` | Attach names the access barrier for an unreadable CONF_DIR |
| S31 | `error-handling.S31.attach-does-not-misreport-an-unreadable-conf-dir-as-not-found` | `BEHAVIOR` | `real-path` | Attach does not misreport an unreadable CONF_DIR as not found |
| S32 | `error-handling.S32.nonroot-permission-probes-applicable` | `APPLICABILITY` | `direct-inspection` | The local-install permission probes apply to the effective user. |
| S32 | `error-handling.S32.local-install-into-a-non-writable-conf-dir-exits-1` | `BEHAVIOR` | `real-path` | Local install into a non-writable CONF_DIR exits 1 |
| S32 | `error-handling.S32.local-install-names-the-non-writable-conf-dir-branch-reached` | `BEHAVIOR` | `real-path` | Local install names the non-writable CONF_DIR (branch reached) |
| S32 | `error-handling.S32.local-install-drops-the-ioc-group-question` | `BEHAVIOR` | `real-path` | Local install drops the ioc group question |
| S35 | `error-handling.S35.valid-crash-log-patterns-extra-accepted-at-install` | `BEHAVIOR` | `real-path` | Valid CRASH_LOG_PATTERNS_EXTRA accepted at install |
| S35 | `error-handling.S35.illegal-characters-in-crash-log-patterns-extra-rejected-at-install` | `BEHAVIOR` | `real-path` | Illegal characters in CRASH_LOG_PATTERNS_EXTRA rejected at install |
| S35 | `error-handling.S35.invalid-regex-in-crash-log-patterns-extra-rejected-at-install` | `BEHAVIOR` | `real-path` | Invalid regex in CRASH_LOG_PATTERNS_EXTRA rejected at install |
| S35 | `error-handling.S35.extra.dot-rejected` | `BEHAVIOR` | `real-path` | Degenerate/empty-alternation _EXTRA '.' rejected at install (#106) |
| S35 | `error-handling.S35.extra.internal-empty-alternation-rejected` | `BEHAVIOR` | `real-path` | Degenerate/empty-alternation _EXTRA 'a\|\|b' rejected at install (#106) |
| S35 | `error-handling.S35.extra.leading-empty-alternation-rejected` | `BEHAVIOR` | `real-path` | Degenerate/empty-alternation _EXTRA '\|a' rejected at install (#106) |
| S35 | `error-handling.S35.extra.trailing-empty-alternation-rejected` | `BEHAVIOR` | `real-path` | Degenerate/empty-alternation _EXTRA 'a\|' rejected at install (#106) |
| S35 | `error-handling.S35.extra.grouped-leading-empty-alternation-rejected` | `BEHAVIOR` | `real-path` | Degenerate/empty-alternation _EXTRA '(\|a)' rejected at install (#106) |
| S35 | `error-handling.S35.extra.grouped-trailing-empty-alternation-rejected` | `BEHAVIOR` | `real-path` | Degenerate/empty-alternation _EXTRA '(a\|)' rejected at install (#106) |
| S35 | `error-handling.S35.extra.ordinary-lowercase-rejected` | `BEHAVIOR` | `real-path` | Degenerate/empty-alternation _EXTRA 'healthy log line' rejected at install (#106) |
| S35 | `error-handling.S35.extra.ordinary-uppercase-rejected` | `BEHAVIOR` | `real-path` | Degenerate/empty-alternation _EXTRA 'ORDINARY HEALTHY' rejected at install (#106) |
| S35 | `error-handling.S35.legitimate-multi-alternation-extra-accepted-at-install-106` | `BEHAVIOR` | `real-path` | Legitimate multi-alternation _EXTRA accepted at install (#106) |
| S36 | `error-handling.S36.non-executable-ioc-runner-procserv-tool-exits-1` | `BEHAVIOR` | `real-path` | Non-executable IOC_RUNNER_PROCSERV_TOOL exits 1 |
| S36 | `error-handling.S36.non-executable-override-error-names-the-variable` | `BEHAVIOR` | `real-path` | Non-executable override error names the variable |
| S36 | `error-handling.S36.executable-directory-ioc-runner-procserv-tool-exits-1` | `BEHAVIOR` | `real-path` | Executable-directory IOC_RUNNER_PROCSERV_TOOL exits 1 |
| S36 | `error-handling.S36.executable-directory-override-error-names-the-variable` | `BEHAVIOR` | `real-path` | Executable-directory override error names the variable |
| S36 | `error-handling.S36.executable-ioc-runner-procserv-tool-accepted` | `BEHAVIOR` | `real-path` | Executable IOC_RUNNER_PROCSERV_TOOL accepted |
| S36 | `error-handling.S36.template-execstart-references-the-override-binary` | `BEHAVIOR` | `real-path` | Template ExecStart references the override binary |
| S36 | `error-handling.S36.home-bin-procserv-resolves-without-an-override` | `BEHAVIOR` | `real-path` | Home-bin procServ resolves without an override |
| S36 | `error-handling.S36.template-execstart-references-the-home-bin-binary` | `BEHAVIOR` | `real-path` | Template ExecStart references the home-bin binary |
| S36 | `error-handling.S36.con-search-path-prepends-home-bin-when-home-is-trusted` | `BEHAVIOR` | `real-path` | con search path prepends home-bin when HOME is trusted |
| S37 | `error-handling.S37.install-proceeds-with-logrotate-boundary` | `BEHAVIOR` | `real-path` | Install proceeds with the mock logrotate boundary (M13/#143) |
| S37 | `error-handling.S37.rotation-cfg-deployed` | `BEHAVIOR` | `real-path` | Rotation config is deployed after validation |
| S37 | `error-handling.S37.debug-validation-passes-explicit-state` | `BEHAVIOR` | `real-path` | Debug validation passes an explicit --state |
| S37 | `error-handling.S37.state-off-system-default` | `BEHAVIOR` | `real-path` | Validation state is off the system default |
| S38 | `error-handling.S38.local-mode-mismatch-exits-1` | `BEHAVIOR` | `real-path` | Local-mode pair mismatch exits 1 |
| S38 | `error-handling.S38.local-mode-mismatch-diagnostic-exact` | `BEHAVIOR` | `real-path` | Local-mode pair mismatch diagnostic is exact |
| S38 | `error-handling.S38.local-mode-mismatch-summary-singular` | `BEHAVIOR` | `real-path` | Local-mode pair mismatch reports the singular summary |
| S38 | `error-handling.S38.local-mode-mismatch-source-preserved` | `BEHAVIOR` | `real-path` | Local-mode pair mismatch preserves its source configuration |
| S38 | `error-handling.S38.local-mode-mismatch-target-absent` | `BEHAVIOR` | `real-path` | Local-mode pair mismatch creates no installed configuration |
| S38 | `error-handling.S38.system-mode-mismatch-exits-1` | `BEHAVIOR` | `real-path` | System-mode pair mismatch exits 1 |
| S38 | `error-handling.S38.system-mode-mismatch-diagnostic-exact` | `BEHAVIOR` | `real-path` | System-mode pair mismatch diagnostic is exact |
| S38 | `error-handling.S38.system-mode-mismatch-summary-singular` | `BEHAVIOR` | `real-path` | System-mode pair mismatch reports the singular summary |
| S38 | `error-handling.S38.system-mode-mismatch-source-preserved` | `BEHAVIOR` | `real-path` | System-mode pair mismatch preserves its source configuration |
| S38 | `error-handling.S38.system-mode-mismatch-target-absent` | `BEHAVIOR` | `real-path` | System-mode pair mismatch creates no installed configuration |
| S38 | `error-handling.S38.third-account-mismatch-exits-1` | `BEHAVIOR` | `real-path` | Third-account pair mismatch exits 1 |
| S38 | `error-handling.S38.third-account-mismatch-diagnostic-exact` | `BEHAVIOR` | `real-path` | Third-account pair mismatch diagnostic is exact |
| S38 | `error-handling.S38.third-account-mismatch-summary-singular` | `BEHAVIOR` | `real-path` | Third-account pair mismatch reports the singular summary |
| S38 | `error-handling.S38.third-account-mismatch-source-preserved` | `BEHAVIOR` | `real-path` | Third-account pair mismatch preserves its source configuration |
| S38 | `error-handling.S38.third-account-mismatch-target-absent` | `BEHAVIOR` | `real-path` | Third-account pair mismatch creates no installed configuration |
| S38 | `error-handling.S38.relative-chdir-pair-not-aggregated` | `BEHAVIOR` | `real-path` | Relative IOC_CHDIR pair mismatch is not aggregated |
| S38 | `error-handling.S38.relative-chdir-pair-retains-field-and-path-errors` | `BEHAVIOR` | `real-path` | Relative IOC_CHDIR pair mismatch retains field and path errors |
| S38 | `error-handling.S38.relative-chdir-pair-summary-three-errors` | `BEHAVIOR` | `real-path` | Relative IOC_CHDIR pair mismatch reports three errors |
| S38 | `error-handling.S38.non-writable-chdir-pair-not-aggregated` | `BEHAVIOR` | `real-path` | Non-writable IOC_CHDIR pair mismatch is not aggregated |
| S38 | `error-handling.S38.non-writable-chdir-pair-retains-field-errors` | `BEHAVIOR` | `real-path` | Non-writable IOC_CHDIR pair mismatch retains field errors |
| S38 | `error-handling.S38.non-writable-chdir-pair-summary-two-errors` | `BEHAVIOR` | `real-path` | Non-writable IOC_CHDIR pair mismatch reports two errors |
| S38 | `error-handling.S38.invalid-identity-whitelist-error-retained` | `BEHAVIOR` | `real-path` | Invalid identity retains its whitelist error |
| S38 | `error-handling.S38.invalid-identity-not-rendered` | `BEHAVIOR` | `real-path` | Invalid identity is not rendered in a combined diagnostic |
| S38 | `error-handling.S38.invalid-identity-summary-three-errors` | `BEHAVIOR` | `real-path` | Invalid identity pair mismatch reports three errors |
| S39 | `error-handling.S39.conf-parser.spaces-accepted-and-deployed` | `BEHAVIOR` | `real-path` | Surrounding spaces are accepted through file-direct install and reach the deployed target. |
| S39 | `error-handling.S39.conf-parser.tabs-accepted-and-deployed` | `BEHAVIOR` | `real-path` | Surrounding tabs are accepted through file-direct install and reach the deployed target. |
| S39 | `error-handling.S39.conf-parser.single-quotes-accepted-and-deployed` | `BEHAVIOR` | `real-path` | Matching single quotes are accepted through file-direct install and reach the deployed target. |
| S39 | `error-handling.S39.conf-parser.double-quotes-accepted-and-deployed` | `BEHAVIOR` | `real-path` | Matching double quotes are accepted through file-direct install and reach the deployed target. |
| S39 | `error-handling.S39.conf-parser.crlf-accepted-and-deployed` | `BEHAVIOR` | `real-path` | CRLF assignments are accepted through file-direct install and reach the deployed target. |
| S39 | `error-handling.S39.conf-parser.empty-value-accepted-and-deployed` | `BEHAVIOR` | `real-path` | An empty optional value is accepted and deployed. |
| S39 | `error-handling.S39.conf-parser.embedded-equals-accepted-and-deployed` | `BEHAVIOR` | `real-path` | A quoted value containing `=` is accepted and deployed. |
| S39 | `error-handling.S39.conf-parser.duplicate-last-assignment-accepted-and-deployed` | `BEHAVIOR` | `real-path` | The later duplicate assignment supplies the valid install value. |
| S39 | `error-handling.S39.conf-parser.regex-backslashes-accepted-and-deployed` | `BEHAVIOR` | `real-path` | Double-quoted escaped regex backslashes are accepted and decoded consistently. |
| S39 | `error-handling.S39.conf-parser.empty-key-remains-present-at-runtime-lookup` | `BEHAVIOR` | `real-path` | Runtime lookup distinguishes an empty IOC_PORT from a missing IOC_PORT. |
| S39 | `error-handling.S39.conf-parser.unmatched-quote-rejected-and-target-preserved` | `BEHAVIOR` | `real-path` | An unmatched quote is rejected before the prior target changes. |
| S39 | `error-handling.S39.conf-parser.continuation-rejected-and-target-preserved` | `BEHAVIOR` | `real-path` | A backslash continuation is rejected before the prior target changes. |
| S39 | `error-handling.S39.conf-parser.multiline-quote-rejected-and-target-preserved` | `BEHAVIOR` | `real-path` | A multiline quoted value is rejected before the prior target changes. |
| S40 | `error-handling.S40.reader-equivalence.exact-function-extraction` | `REQUIRED` | `direct-inspection` | The selected runner contains exactly one complete definition of each reader function, and the generated source is nonempty and valid Bash. |
| S40 | `error-handling.S40.reader-equivalence.surrounding-spaces` | `BEHAVIOR` | `real-path` | Both shipped reader APIs return the independent expected value for an assignment with surrounding spaces. |
| S40 | `error-handling.S40.reader-equivalence.surrounding-tabs` | `BEHAVIOR` | `real-path` | Both shipped reader APIs return the independent expected value for an assignment with surrounding tabs. |
| S40 | `error-handling.S40.reader-equivalence.single-quoted-interior-whitespace` | `BEHAVIOR` | `real-path` | Both shipped reader APIs preserve the expected single-quoted interior whitespace. |
| S40 | `error-handling.S40.reader-equivalence.double-quoted-interior-whitespace` | `BEHAVIOR` | `real-path` | Both shipped reader APIs preserve the expected double-quoted interior whitespace. |
| S40 | `error-handling.S40.reader-equivalence.single-quoted-whitespace-only` | `BEHAVIOR` | `real-path` | Both shipped reader APIs preserve a single-quoted whitespace-only value. |
| S40 | `error-handling.S40.reader-equivalence.double-quoted-whitespace-only` | `BEHAVIOR` | `real-path` | Both shipped reader APIs preserve a double-quoted whitespace-only value. |
| S40 | `error-handling.S40.reader-equivalence.quoted-empty-present` | `BEHAVIOR` | `real-path` | Both shipped reader APIs retain a quoted empty value as present. |
| S40 | `error-handling.S40.reader-equivalence.missing-key-api-states` | `BEHAVIOR` | `real-path` | Full-file parsing leaves a missing key absent while the single-key reader returns 1. |

## Completeness Cross-check

| Source Shape | Count |
| --- | ---: |
| Current BEHAVIOR identities | 190 |
| P00 required condition | 1 |
| S23 required condition | 1 |
| Per-STEP applicability conditions | 5 |
| Expected catalog counts | See [`reporting-counts.csv`](reporting-counts.csv) |

The mapping is complete only while all 190 current behavior identities map
once, the eight added conditions map once, no STEP-local key is duplicated,
and the source pipeline remains S01 through S40.
