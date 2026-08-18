# Source Regression Move Inventory

## Scope

This document preserves the pre-move inventory for S07 through S14 in `tests/test-system-infra.bash` and records later accepted source-regression additions. The original move accounts for every result-producing branch and validity prerequisite before assigning a reviewed `retain`, `replace`, or `remove` disposition.

**Out of scope:** Reporter implementation, terminal-state emission, gate consumption, and changes to product behavior. Those remain in #137, #135, or the product issue that owns the behavior.

## Suite Boundary

The destination suite ID is `source-regression`, with `scope=system` and `runner=source`. Existing moved STEP identities remain S07 through S14 as required by `REPORTING_CONTRACT.md`; M8 extends the pipeline through S21, M7 adds S22, and M19 adds S23 without renumbering them.

The suite runs through `sudo bash`. Source and Git operations run as the invoking identity retained in `SUDO_USER`. Product scripts are executed from their real shipped paths. Earlier setup checks redirect their outer write destinations to an invoking-user-owned temporary workspace. S22 runs the full setup in a private mount namespace with root-owned scratch mounts and isolated `systemctl` and filesystem boundaries.

## STEP Inventory

| STEP | Current Function | Verification Target | Real Product Paths | Write Boundary |
| --- | --- | --- | --- | --- |
| S07 | `test_git_context_resolution` | Repository hash lookup from an unrelated current directory | Git metadata for the repository containing `bin/` | None |
| S08 | `test_setup_script_dir_resolution` | Setup and sudo-mode test path resolution without canonicalization | `bin/setup-system-infra.bash`, `bin/ioc-runner`, `tests/test-system-lifecycle.bash` | None |
| S09 | `test_setup_stamp_layout_guard` | Setup version stamping for the real layout and an unrelated checkout | `bin/setup-system-infra.bash`, `bin/ioc-runner` | Runner, symlink, and completion destinations under the temporary workspace |
| S10 | `test_stamp_relocated_clean_checkout` | Setup, live `-V`, and injector behavior on relocated clean, modified, and locked-index checkouts | `bin/setup-system-infra.bash`, `bin/ioc-runner`, `configure/inject-runner-version.bash` | Clone, copies, deployed runners, symlinks, completion files, and injection targets under the temporary workspace |
| S11 | `test_setup_runner_backup_filter` | Backup creation for stamp-only redeploys and a real source change | `bin/setup-system-infra.bash`, `bin/ioc-runner` | Source copy, deployed runner, symlink, completion file, and backup directory under the temporary workspace |
| S12 | `test_setup_version_injection_guards` | Privilege-drop and unknown-hash guards in setup | `bin/setup-system-infra.bash` | None |
| S13 | `test_metadata_field_naming` | Version metadata declarations, legacy-name absence, and setup injection | `bin/ioc-runner`, `bin/setup-system-infra.bash` | None |
| S14 | `test_runner_version_path_resolution` | Live `-V` path resolution without canonicalization | `bin/ioc-runner` | None |
| S15 | `test_system_identity_contract` | Shared system user, group, and log-directory declarations and defaults | `bin/ioc-runner`, `bin/setup-system-infra.bash` | None |
| S16 | `test_unit_template_contract` | Shared procServ unit-template rows and required directives | `bin/ioc-runner`, `bin/setup-system-infra.bash` | None |
| S17 | `test_metadata_injection_contract` | Shared metadata injection targets and runner declaration anchors | `bin/ioc-runner`, `bin/setup-system-infra.bash`, `configure/inject-runner-version.bash` | None |
| S18 | `test_pipefail_help_probe_contract` | Forbidden helper help-output pipeline form | `bin/ioc-runner` | None |
| S19 | `test_ioc_name_source_contract` | Runner and regex-form sudoers IOC-name source agreement | `bin/ioc-runner`, `bin/setup-system-infra.bash` | None |
| S20 | `test_crash_pattern_source_contract` | Base crash-pattern membership and fatal/ambiguous subset agreement | `bin/ioc-runner` | None |
| S21 | `test_crash_exclusion_source_contract` | Benign-history exclusion regex and line-filter ordering | `bin/ioc-runner` | None |
| S22 | `test_setup_path_type_expectations` | File-target directory impostors and valid directory targets | `bin/setup-system-infra.bash` | Root-owned scratch trees bind-mounted over the system destinations in a private mount namespace |

## Current Assertion Mapping

These 36 identities account for every current `verify_state` call reachable from S07 through S14. Six required-artifact checks are fail-only branches today: S08-01, S09-01, S11-01, S12-01, S13-01, and S14-01. A normal successful run therefore emits 30 assertions. The inventory records all 36 so the later fixed catalog does not lose the failure branches.

All rows have the proposed category `source-regression`. Eighteen use direct state inspection: seven artifact or fixture conditions and eleven source-contract conditions. Fourteen execute real shipped paths. Four intended behavior assertions use a hand-built reproduction and cannot supply behavior-verification evidence in their current form.

Disposition status: All 36 assertions and all eight validity prerequisites have accepted dispositions under D13. The destination check IDs below are accepted, and M9 step 1 is complete.

| Source | Proposed Check ID | Current Kind | Current Test Method | Current Expected Result |
| --- | --- | --- | --- | --- |
| S07-01 | `source-regression.S07.git-context.unrelated-cwd-hash` | `BEHAVIOR` | Hand-built reproduction - invalid evidence | `git -C` returns the repository hash from an unrelated current directory |
| S08-01 | `source-regression.S08.setup-script.available` | `REQUIRED` | Direct state inspection | `bin/setup-system-infra.bash` exists |
| S08-02 | `source-regression.S08.setup-script.sc-dir-no-readlink-f` | `REQUIRED` | Direct state inspection | `SC_DIR` does not use `readlink -f` |
| S08-03 | `source-regression.S08.sudo-tests.no-canonicalization` | `REQUIRED` | Direct state inspection | Sudo-mode test files do not use `readlink -f`, `realpath`, or `cd ... && pwd` for their own path |
| S08-04 | `source-regression.S08.setup-script.repo-root-invocation` | `BEHAVIOR` | Hand-built reproduction - invalid evidence | Invocation as `bin/setup-system-infra.bash` locates `bin/ioc-runner` |
| S08-05 | `source-regression.S08.setup-script.bin-dir-invocation` | `BEHAVIOR` | Hand-built reproduction - invalid evidence | Invocation as `./setup-system-infra.bash` from `bin/` locates `ioc-runner` |
| S08-06 | `source-regression.S08.setup-script.absolute-invocation` | `BEHAVIOR` | Hand-built reproduction - invalid evidence | Absolute invocation from an unrelated directory locates `bin/ioc-runner` |
| S09-01 | `source-regression.S09.source-artifacts.available` | `REQUIRED` | Direct state inspection | Setup and runner source files exist |
| S09-02 | `source-regression.S09.layout.real-checkout-hash` | `BEHAVIOR` | Real-path execution | The real checkout stamps a non-unknown hash |
| S09-03 | `source-regression.S09.layout.unrelated-checkout-unknown` | `BEHAVIOR` | Real-path execution | An unrelated Git checkout stamps `unknown` |
| S09-04 | `source-regression.S09.layout.unrelated-checkout-warning` | `BEHAVIOR` | Real-path execution | An unrelated Git checkout emits the layout warning |
| S10-01 | `source-regression.S10.fixture.clone-copy-built` | `REQUIRED` | Direct state inspection | Clean, modified, and locked-index clone-copy fixtures exist |
| S10-02 | `source-regression.S10.clean.setup-bare` | `BEHAVIOR` | Real-path execution | Setup stamps a bare hash on the relocated clean checkout |
| S10-03 | `source-regression.S10.clean.live-version-bare` | `BEHAVIOR` | Real-path execution | Live `-V` reports a bare hash on the relocated clean checkout |
| S10-04 | `source-regression.S10.clean.injector-bare` | `BEHAVIOR` | Real-path execution | The injector stamps a bare hash on the relocated clean checkout |
| S10-05 | `source-regression.S10.modified.setup-dirty` | `BEHAVIOR` | Real-path execution | Setup retains `-dirty` for a real modification |
| S10-06 | `source-regression.S10.modified.live-version-dirty` | `BEHAVIOR` | Real-path execution | Live `-V` retains `-dirty` for a real modification |
| S10-07 | `source-regression.S10.modified.injector-dirty` | `BEHAVIOR` | Real-path execution | The injector retains `-dirty` for a real modification |
| S10-08 | `source-regression.S10.locked-index.setup-bare` | `BEHAVIOR` | Real-path execution | Setup stamps a bare hash with an unwritable index |
| S10-09 | `source-regression.S10.locked-index.live-version-bare` | `BEHAVIOR` | Real-path execution | Live `-V` reports bare with an unwritable index |
| S10-10 | `source-regression.S10.locked-index.injector-bare` | `BEHAVIOR` | Real-path execution | The injector stamps a bare hash with an unwritable index |
| S11-01 | `source-regression.S11.setup-script.available` | `REQUIRED` | Direct state inspection | `bin/setup-system-infra.bash` exists |
| S11-02 | `source-regression.S11.backup.no-change-none` | `BEHAVIOR` | Real-path execution | Two stamp-only redeploys create no runner backup |
| S11-03 | `source-regression.S11.backup.source-change-one` | `BEHAVIOR` | Real-path execution | One real source change creates exactly one runner backup |
| S12-01 | `source-regression.S12.setup-script.available` | `REQUIRED` | Direct state inspection | `bin/setup-system-infra.bash` exists |
| S12-02 | `source-regression.S12.injection.sudo-user-reference` | `REQUIRED` | Direct state inspection | Version injection references `SUDO_USER` |
| S12-03 | `source-regression.S12.injection.sudo-user-drop` | `REQUIRED` | Direct state inspection | Version injection uses `sudo -u` |
| S12-04 | `source-regression.S12.injection.unknown-dirty-guard` | `REQUIRED` | Direct state inspection | The dirty marker requires a non-unknown current hash |
| S13-01 | `source-regression.S13.source-artifacts.available` | `REQUIRED` | Direct state inspection | Runner and setup source files exist |
| S13-02 | `source-regression.S13.runner.commit-date-declaration` | `REQUIRED` | Direct state inspection | The runner declares `RUNNER_COMMIT_DATE` |
| S13-03 | `source-regression.S13.runner.install-date-declaration` | `REQUIRED` | Direct state inspection | The runner declares `RUNNER_INSTALL_DATE` |
| S13-04 | `source-regression.S13.metadata.legacy-build-date-absent` | `REQUIRED` | Direct state inspection | `RUNNER_BUILD_DATE` and the legacy build-date label are absent |
| S13-05 | `source-regression.S13.setup.commit-date-injection` | `REQUIRED` | Direct state inspection | Setup injects `RUNNER_COMMIT_DATE` |
| S13-06 | `source-regression.S13.setup.install-date-injection` | `REQUIRED` | Direct state inspection | Setup injects `RUNNER_INSTALL_DATE` |
| S14-01 | `source-regression.S14.runner.available` | `REQUIRED` | Direct state inspection | `bin/ioc-runner` exists |
| S14-02 | `source-regression.S14.live-version.no-readlink-f` | `REQUIRED` | Direct state inspection | The live `-V` handler does not derive its path with `readlink -f` |

## Validity Prerequisite Mapping

These conditions are required for the current checks to mean what they claim. They are not all explicit assertions in the current suite. Their proposed identities remain subject to D13 disposition review; adding terminal-state records remains #137 work.

All validity prerequisites have category `source-regression` and use direct state inspection.

| Proposed Check ID | Owner | Current Kind | Current Test Method | Required Condition | Current Failure Form |
| --- | --- | --- | --- | --- | --- |
| `source-regression.P00.root-invocation` | P00 | `REQUIRED` | Direct state inspection | The suite starts as root through `sudo bash` | Exit before S07 |
| `source-regression.P00.invoking-user` | P00 | `REQUIRED` | Direct state inspection | `SUDO_USER` names the caller whose source tree and Git metadata are under test | Source and Git work may run as the wrong identity |
| `source-regression.P00.privilege-drop` | P00 | `REQUIRED` | Direct state inspection | `sudo -u <SUDO_USER> -n` can run source and Git operations | A command aborts or runs as root |
| `source-regression.P00.git-command` | P00 | `REQUIRED` | Direct state inspection | `git` is available to the invoking identity | Hash comparisons can collapse to `unknown` or fixture construction fails |
| `source-regression.P00.source-layout` | P00 | `REQUIRED` | Direct state inspection | The checkout contains the real setup, runner, injector, system-lifecycle test, and Git metadata paths | A fail-only artifact check, later behavior failure, or false green |
| `source-regression.P00.workspace` | P00 | `REQUIRED` | Direct state inspection | The invoking identity can create and clean an isolated temporary workspace | Fixture construction or cleanup aborts |
| `source-regression.S09.fixture.unrelated-checkout-built` | S09 | `REQUIRED` | Direct state inspection | The copied `bin/` tree is committed in an unrelated Git repository | Negative layout assertions do not exercise the intended boundary |
| `source-regression.S11.fixture.source-copy-built` | S11 | `REQUIRED` | Direct state inspection | The scratch runner source copy and baseline deployment succeed | Backup counts can describe failed setup runs instead of redeploy behavior |

Normal shell utilities used only to implement the harness are invocation dependencies. Their unexpected absence is a script error, not a product test result.

## Disposition Decisions

| Source | Disposition | Destination STEP | Destination Check ID | Category | Check Kind | Test Method | Decision Reason |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S07-01 | `replace` | S07 | `source-regression.S07.git-context.unrelated-cwd-hash` | `source-regression` | `BEHAVIOR` | Real-path execution | Replace the direct `git -C` reproduction with the real shipped `bin/setup-system-infra.bash` invoked from an unrelated current directory. Redirect only the runner, symlink, completion, and backup destinations to the temporary workspace, then remove an optional `-dirty` suffix from the deployed stamp and require the remaining hash to equal the checkout's short `HEAD`. S07 therefore isolates Git-context resolution while S10 independently owns clean and dirty suffix behavior. Owner accepted 2026-08-05 and approved the suffix normalization 2026-08-06. |
| S08-01 | `remove` | — | — | — | — | — | Remove the fail-only setup-script existence assertion because the accepted P00 source-layout prerequisite checks the same required path before S08 begins. Keeping both would count one prerequisite twice and make the assertion inventory depend on which missing-artifact branch was reached. Owner accepted 2026-08-05. |
| S08-02 | `remove` | — | — | — | — | — | Remove the implementation-specific assertion that forbids `readlink -f`. The accepted S07 replacement verifies the unrelated-CWD failure boundary through the real setup path, while this assertion would reject a future implementation solely because of the primitive it uses rather than because path resolution failed. Owner accepted 2026-08-05. |
| S08-03 | `retain` | S08 | `source-regression.S08.sudo-tests.no-canonicalization` | `source-regression` | `REQUIRED` | Direct state inspection | Retain the explicit path-safety contract for the sudo-mode test scripts. This check makes no product-behavior claim; it directly verifies the test-source constraint preserved by D10 so root execution on a user-owned root-squash path does not depend on canonicalization that root cannot perform. Owner accepted 2026-08-05. |
| S08-04 | `replace` | S08 | `source-regression.S08.setup-script.repo-root-invocation` | `source-regression` | `BEHAVIOR` | Real-path execution | Replace the reconstruction of `SC_DIR` with the real shipped `bin/setup-system-infra.bash` invoked by its repository-root-relative path. Redirect only the runner, symlink, and completion destinations to the temporary workspace, then require successful deployment of the real runner. This observes whether the supported invocation resolves its sibling source through the product path itself. Owner accepted 2026-08-05. |
| S08-05 | `replace` | S08 | `source-regression.S08.setup-script.bin-dir-invocation` | `source-regression` | `BEHAVIOR` | Real-path execution | Replace the reconstruction of `SC_DIR` with the real shipped `./setup-system-infra.bash` invoked from the repository's `bin/` directory. Redirect only the runner, symlink, and completion destinations to the temporary workspace, then require successful deployment of the real runner. This keeps the supported bin-directory invocation as a distinct observed product path. Owner accepted 2026-08-05. |
| S08-06 | `replace` | S08 | `source-regression.S08.setup-script.absolute-invocation` | `source-regression` | `BEHAVIOR` | Real-path execution | Replace the reconstruction of `SC_DIR` with the real shipped setup script invoked by absolute path from an unrelated current directory. Share the setup execution with S07 where practical, but keep this identity separate: S07 verifies the stamped Git hash, while S08-06 verifies that the absolute invocation resolves and deploys the sibling runner. Owner accepted 2026-08-05. |
| S09-01 | `remove` | — | — | — | — | — | Remove the fail-only setup-and-runner existence assertion because the accepted P00 source-layout prerequisite checks both required paths before S09 begins. Keeping it would make the same missing source artifact both a suite prerequisite and a conditional assertion. Owner accepted 2026-08-05. |
| S09-02 | `retain` | S09 | `source-regression.S09.layout.real-checkout-hash` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the real setup execution that requires a non-unknown stamp from the actual repository layout. This verifies that the layout guard accepts the shipped checkout; S07 separately verifies that the resulting Git lookup is independent of the caller's current directory. Owner accepted 2026-08-05. |
| S09-03 | `retain` | S09 | `source-regression.S09.layout.unrelated-checkout-unknown` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the real copied setup script executed inside a committed unrelated Git checkout and require the deployed runner to carry the `unknown` stamp. The separate S09 fixture prerequisite establishes that the checkout boundary exists; this check then observes the shipped layout guard's negative behavior rather than reproducing it. Owner accepted 2026-08-05. |
| S09-04 | `retain` | S09 | `source-regression.S09.layout.unrelated-checkout-warning` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the operator-visible layout warning observed from the same real unrelated-checkout setup execution as S09-03. The `unknown` stamp and the diagnostic are separate product contracts: one controls recorded identity and the other explains why that identity could not be established. Owner accepted 2026-08-05. |
| S10-01 | `retain` | S10 | `source-regression.S10.fixture.clone-copy-built` | `source-regression` | `REQUIRED` | Direct state inspection | Retain the fixture-validity check for the clean, modified, and locked-index clone-copy trees. It is not product-behavior evidence; it prevents the nine following behavior checks from reporting on incomplete or misconstructed inputs. Owner accepted 2026-08-05. |
| S10-02 | `retain` | S10 | `source-regression.S10.clean.setup-bare` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the real setup execution against the relocated clean checkout and require the deployed runner to carry the bare fixture hash. This is the setup entry point of the M4 regression and directly distinguishes clean relocated content from a false `-dirty` stamp. Owner accepted 2026-08-05. |
| S10-03 | `retain` | S10 | `source-regression.S10.clean.live-version-bare` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the real relocated runner's live `-V` execution and require its fallback lookup to report the bare fixture hash. This is a distinct M4 entry point from setup-time injection and directly verifies the source-mode version path. Owner accepted 2026-08-05. |
| S10-04 | `retain` | S10 | `source-regression.S10.clean.injector-bare` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the real `configure/inject-runner-version.bash` execution against an isolated target copied from the relocated clean checkout and require the injected bare fixture hash. This is the third independent M4 entry point and verifies the user-install injection path without replacing its internal logic. Owner accepted 2026-08-05. |
| S10-05 | `retain` | S10 | `source-regression.S10.modified.setup-dirty` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the real setup execution against the modified fixture and require the deployed runner to carry the `-dirty` suffix. This is the opposite-direction guard for S10-02 and prevents an implementation that removes the suffix from every checkout from passing the clean relocation case. Owner accepted 2026-08-05. |
| S10-06 | `retain` | S10 | `source-regression.S10.modified.live-version-dirty` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the modified runner's real live `-V` execution and require the `-dirty` suffix. This is the opposite-direction guard for S10-03 on the independent source-mode version entry point. Owner accepted 2026-08-05. |
| S10-07 | `retain` | S10 | `source-regression.S10.modified.injector-dirty` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the real injector execution against the modified fixture and require the injected `-dirty` suffix. This is the opposite-direction guard for S10-04 on the independent user-install injection path. Owner accepted 2026-08-05. |
| S10-08 | `retain` | S10 | `source-regression.S10.locked-index.setup-bare` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the real setup execution against the clean fixture whose Git index is unwritable and require the deployed runner to carry the bare hash. This directly verifies that the M4 setup path does not need an index refresh or write to distinguish clean content. Owner accepted 2026-08-05. |
| S10-09 | `retain` | S10 | `source-regression.S10.locked-index.live-version-bare` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the locked-index runner's real live `-V` execution and require the bare fixture hash. This verifies the same no-index-write boundary through the independent source-mode version entry point. Owner accepted 2026-08-05. |
| S10-10 | `retain` | S10 | `source-regression.S10.locked-index.injector-bare` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the real injector execution against the clean fixture whose Git index is unwritable and require the injected bare hash. This verifies the same no-index-write boundary through the independent user-install injection entry point. Owner accepted 2026-08-05. |
| S11-01 | `remove` | — | — | — | — | — | Remove the fail-only setup-script existence assertion because the accepted P00 source-layout prerequisite checks the same required path before S11 begins. Keeping both would duplicate one missing-artifact condition in the fixed inventory. Owner accepted 2026-08-05. |
| S11-02 | `retain` | S11 | `source-regression.S11.backup.no-change-none` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the two real setup redeployments of the unchanged source fixture and require zero runner backups. The separate S11 fixture prerequisite establishes the baseline deployment; this check then verifies that stamp-only differences do not consume backup retention. Owner accepted 2026-08-05. |
| S11-03 | `retain` | S11 | `source-regression.S11.backup.source-change-one` | `source-regression` | `BEHAVIOR` | Real-path execution | Retain the real setup redeployment after one source change and require exactly one runner backup. This is the opposite-direction guard for S11-02 and verifies that suppressing stamp-only backups does not suppress backups for real source changes. Owner accepted 2026-08-05. |
| S12-01 | `remove` | — | — | — | — | — | Remove the fail-only setup-script existence assertion because the accepted P00 source-layout prerequisite checks the same required path before S12 begins. Keeping it would count the same required artifact again without adding evidence. Owner accepted 2026-08-05. |
| S12-02 | `retain` | S12 | `source-regression.S12.injection.sudo-user-reference` | `source-regression` | `REQUIRED` | Direct state inspection | Retain the source-contract guard requiring version injection to reference `SUDO_USER`. It makes no runtime-behavior claim; it directly pins the invoking-identity input of the root-to-user boundary fixed by D10, while real setup executions provide the separate behavior evidence. Owner accepted 2026-08-05. |
| S12-03 | `retain` | S12 | `source-regression.S12.injection.sudo-user-drop` | `source-regression` | `REQUIRED` | Direct state inspection | Retain the source-contract guard requiring version-injection source and Git commands to execute through `sudo -u`. Together with S12-02, it verifies that the accepted invoking identity is used for the operation rather than merely read, without claiming runtime behavior from source inspection alone. Owner accepted 2026-08-05. |
| S12-04 | `remove` | — | — | — | — | — | Remove the implementation-specific source guard around the dirty-suffix condition. S09-03 already executes the real setup path in an unrelated checkout and requires the final stamp to be exactly `unknown`, so the product behavior fails if `unknown-dirty` can be produced without pinning the internal conditional form. Owner accepted 2026-08-05. |
| S13-01 | `remove` | — | — | — | — | — | Remove the fail-only runner-and-setup existence assertion because the accepted P00 source-layout prerequisite checks both required paths before S13 begins. Keeping it would add no independent contract or behavior evidence. Owner accepted 2026-08-05. |
| S13-02 | `retain` | S13 | `source-regression.S13.runner.commit-date-declaration` | `source-regression` | `REQUIRED` | Direct state inspection | Retain the source metadata contract requiring the runner to declare `RUNNER_COMMIT_DATE`. This makes no runtime-behavior claim; it prevents the runner metadata schema from dropping the commit-date field while separate real-path checks verify populated values. Owner accepted 2026-08-05. |
| S13-03 | `retain` | S13 | `source-regression.S13.runner.install-date-declaration` | `source-regression` | `REQUIRED` | Direct state inspection | Retain the source metadata contract requiring the runner to declare `RUNNER_INSTALL_DATE`. This makes no runtime-behavior claim; it preserves the installation-time field as distinct from source commit time while separate real-path checks verify populated values. Owner accepted 2026-08-05. |
| S13-04 | `retain` | S13 | `source-regression.S13.metadata.legacy-build-date-absent` | `source-regression` | `REQUIRED` | Direct state inspection | Retain the negative source contract requiring `RUNNER_BUILD_DATE` and the legacy build-date label to remain absent from the runner and setup paths. This prevents a partial metadata-schema reversal in which setup targets a retired field and silently leaves the deployed value unchanged. Owner accepted 2026-08-05. |
| S13-05 | `replace` | S13 | `source-regression.S13.setup.commit-date-injection` | `source-regression` | `BEHAVIOR` | Real-path execution | Replace the implementation-specific `sed` source inspection with a real setup execution against the checkout and require the deployed runner's `RUNNER_COMMIT_DATE` to equal the UTC timestamp of the checkout's HEAD commit. This verifies the shipped setup path and final metadata value without pinning its editing mechanism. Owner accepted 2026-08-05. |
| S13-06 | `replace` | S13 | `source-regression.S13.setup.install-date-injection` | `source-regression` | `BEHAVIOR` | Real-path execution | Replace the implementation-specific `sed` source inspection with a real setup execution bracketed by UTC timestamps and require the deployed runner's `RUNNER_INSTALL_DATE` to fall within that inclusive interval. This verifies the shipped setup path and final installation-time value without pinning its editing mechanism. Owner accepted 2026-08-05. |
| S14-01 | `remove` | — | — | — | — | — | Remove the fail-only runner existence assertion because the accepted P00 source-layout prerequisite checks the same required path before S14 begins. Keeping it would duplicate one missing-artifact condition without adding behavior evidence. Owner accepted 2026-08-05. |
| S14-02 | `replace` | S14 | `source-regression.S14.live-version.readlink-failure-hash` | `source-regression` | `BEHAVIOR` | Real-path execution | Replace the implementation-specific source inspection with the real runner's live `-V` execution from a non-Git current directory while an outer `readlink -f` boundary returns failure. Require the output to carry the fixture's short HEAD hash and `(live)` marker. This preserves the root-squash regression boundary without treating an internal implementation choice as behavior evidence. Owner accepted 2026-08-05. |
| `source-regression.P00.root-invocation` | `retain` | P00 | `source-regression.P00.root-invocation` | `source-regression` | `REQUIRED` | Direct state inspection | Require the suite to start as root through `sudo bash`. The S07-S14 paths exercise root-to-invoking-user boundaries, so results from a non-root start would not describe the supported system invocation. Owner accepted 2026-08-05. |
| `source-regression.P00.invoking-user` | `retain` | P00 | `source-regression.P00.invoking-user` | `source-regression` | `REQUIRED` | Direct state inspection | Require `SUDO_USER` to identify the caller whose source tree and Git metadata are under test. Without that identity, source and Git work may run as root or against the wrong ownership boundary. Owner accepted 2026-08-05. |
| `source-regression.P00.privilege-drop` | `retain` | P00 | `source-regression.P00.privilege-drop` | `source-regression` | `REQUIRED` | Direct state inspection | Require a non-interactive `sudo -u <SUDO_USER>` probe to succeed before source and Git checks begin. This establishes that the real invoking-user path is available rather than allowing later commands to abort or run as root. Owner accepted 2026-08-05. |
| `source-regression.P00.git-command` | `retain` | P00 | `source-regression.P00.git-command` | `source-regression` | `REQUIRED` | Direct state inspection | Require the invoking identity to execute the real Git command before hash and fixture checks begin. Git is part of the evidence path for this suite; without it, hashes can collapse to `unknown` and Git-backed fixtures cannot establish their claimed state. Owner accepted 2026-08-05. |
| `source-regression.P00.source-layout` | `retain` | P00 | `source-regression.P00.source-layout` | `source-regression` | `REQUIRED` | Direct state inspection | Require the checkout to contain the real setup, runner, injector, system-lifecycle test, and Git metadata paths before any behavior check runs. This is a validity prerequisite, not behavior evidence: without it, later results can describe missing test inputs rather than the shipped paths they claim to verify. Owner accepted 2026-08-05. |
| `source-regression.P00.workspace` | `retain` | P00 | `source-regression.P00.workspace` | `source-regression` | `REQUIRED` | Direct state inspection | Require the invoking identity to create and remove an isolated temporary workspace before fixture construction. This prevents later product results from describing an unavailable or root-owned test boundary. Owner accepted 2026-08-05. |
| `source-regression.S09.fixture.unrelated-checkout-built` | `retain` | S09 | `source-regression.S09.fixture.unrelated-checkout-built` | `source-regression` | `REQUIRED` | Direct state inspection | Require the copied `bin/` tree to be committed in a distinct Git repository before the S09 negative layout checks run. This establishes the unrelated-checkout boundary those behavior results claim to exercise. Owner accepted 2026-08-05. |
| `source-regression.S11.fixture.source-copy-built` | `retain` | S11 | `source-regression.S11.fixture.source-copy-built` | `source-regression` | `REQUIRED` | Direct state inspection | Require the scratch runner source copy and baseline deployment to succeed before backup counts begin. Otherwise a zero or one count could describe failed setup executions rather than unchanged and changed redeployment behavior. Owner accepted 2026-08-05. |

## Accepted M8 S15 Addition

S15 adds twelve REQUIRED direct-inspection identities accepted by the owner on 2026-08-06. Both source files are read through the invoking-user boundary established by P00.

| Check ID | Kind | Test Method | Source Contract |
| --- | --- | --- | --- |
| `source-regression.S15.runner-user-override-declaration` | `REQUIRED` | `direct-inspection` | Runner declares the `IOC_RUNNER_SYSTEM_USER` override. |
| `source-regression.S15.setup-user-override-declaration` | `REQUIRED` | `direct-inspection` | Setup declares the same user override. |
| `source-regression.S15.runner-user-default-ioc-srv` | `REQUIRED` | `direct-inspection` | Runner user default is `ioc-srv`. |
| `source-regression.S15.user-defaults-agree` | `REQUIRED` | `direct-inspection` | Runner and setup user defaults agree. |
| `source-regression.S15.runner-group-override-declaration` | `REQUIRED` | `direct-inspection` | Runner declares the `IOC_RUNNER_SYSTEM_GROUP` override. |
| `source-regression.S15.setup-group-override-declaration` | `REQUIRED` | `direct-inspection` | Setup declares the same group override. |
| `source-regression.S15.runner-group-default-ioc` | `REQUIRED` | `direct-inspection` | Runner group default is `ioc`. |
| `source-regression.S15.group-defaults-agree` | `REQUIRED` | `direct-inspection` | Runner and setup group defaults agree. |
| `source-regression.S15.runner-log-dir-override-declaration` | `REQUIRED` | `direct-inspection` | Runner declares the `IOC_RUNNER_SYSTEM_LOG_DIR` override. |
| `source-regression.S15.setup-log-dir-override-declaration` | `REQUIRED` | `direct-inspection` | Setup declares the same log-directory override. |
| `source-regression.S15.runner-log-dir-default` | `REQUIRED` | `direct-inspection` | Runner system log default is `/var/log/procserv`. |
| `source-regression.S15.log-dir-defaults-agree` | `REQUIRED` | `direct-inspection` | Runner and setup log-directory defaults agree. |

## Accepted M8 S16 Addition

S16 adds four REQUIRED direct-inspection identities accepted by the owner on 2026-08-07. Both source files are read through the invoking-user boundary established by P00.

| Check ID | Kind | Test Method | Source Contract |
| --- | --- | --- | --- |
| `source-regression.S16.templates.extracted` | `REQUIRED` | `direct-inspection` | Both procServ unit-template source contracts are extracted before comparison. |
| `source-regression.S16.templates.must-agree` | `REQUIRED` | `direct-inspection` | Normalized must-agree rows are byte-identical across the local and system templates. |
| `source-regression.S16.restart-directives.present` | `REQUIRED` | `direct-inspection` | All required restart directives remain in the shared source contract. |
| `source-regression.S16.runtime-directory-preserve.present` | `REQUIRED` | `direct-inspection` | Both templates retain `RuntimeDirectoryPreserve=restart`. |

## Accepted M8 S17 Addition

S17 adds three REQUIRED direct-inspection identities accepted by the owner on 2026-08-07. All three source files are read through the invoking-user boundary established by P00.

| Check ID | Kind | Test Method | Source Contract |
| --- | --- | --- | --- |
| `source-regression.S17.metadata.targets-extracted` | `REQUIRED` | `direct-inspection` | Both metadata injector target sets are extracted before comparison. |
| `source-regression.S17.metadata.injectors-agree` | `REQUIRED` | `direct-inspection` | Setup and standalone injectors target the same `RUNNER_*` names. |
| `source-regression.S17.metadata.declaration-anchors-present` | `REQUIRED` | `direct-inspection` | Every injected name retains a declaration anchor in the runner. |

## Accepted M8 S18 Addition

S18 adds one REQUIRED direct-inspection identity accepted by the owner on 2026-08-07. The runner source is read through the invoking-user boundary established by P00.

| Check ID | Kind | Test Method | Source Contract |
| --- | --- | --- | --- |
| `source-regression.S18.pipefail-help-probe-pattern.absent` | `REQUIRED` | `direct-inspection` | The runner contains no helper `-h` output pipeline directly connected to `grep -q`. |

## Accepted M8 S19 Addition

S19 adds four REQUIRED direct-inspection identities accepted by the owner on 2026-08-07. Both source files are read through the invoking-user boundary established by P00.

| Check ID | Kind | Test Method | Source Contract |
| --- | --- | --- | --- |
| `source-regression.S19.sudoers-regex.count-six` | `REQUIRED` | `direct-inspection` | Setup contains one regex-form IOC unit rule for each of the six permitted systemctl verbs. |
| `source-regression.S19.sudoers-regex.identical` | `REQUIRED` | `direct-inspection` | All six setup rules use one identical IOC-name expression. |
| `source-regression.S19.runner-name.max-length-64` | `REQUIRED` | `direct-inspection` | The runner IOC-name source contract retains the maximum length of 64. |
| `source-regression.S19.runner-sudoers-name-contracts.agree` | `REQUIRED` | `direct-inspection` | After normalizing equivalent ASCII letter-range order, the setup expression exactly matches the runner character classes and derived remaining-character limit. |

## S20 - Crash Pattern Source Contract

S20 defines twenty-eight REQUIRED direct-inspection identities. The runner source is read through the invoking-user boundary established by P00. Runtime crash behavior remains in the lifecycle suites.

| Check ID | Kind | Test Method | Source Contract |
| --- | --- | --- | --- |
| `source-regression.S20.pattern-unbalanced-quote` | `REQUIRED` | `direct-inspection` | The base regex matches an unbalanced-quote line. |
| `source-regression.S20.pattern-invalid-directory-path` | `REQUIRED` | `direct-inspection` | The base regex matches an invalid-directory line. |
| `source-regression.S20.pattern-can-t-open` | `REQUIRED` | `direct-inspection` | The base regex matches a `Can't open` line. |
| `source-regression.S20.pattern-cannot-open` | `REQUIRED` | `direct-inspection` | The base regex matches a `cannot open` line. |
| `source-regression.S20.pattern-undefined-symbol` | `REQUIRED` | `direct-inspection` | The base regex matches an undefined-symbol line. |
| `source-regression.S20.pattern-no-such-file-or-directory` | `REQUIRED` | `direct-inspection` | The base regex matches a missing-file line. |
| `source-regression.S20.case-insensitive-error-upper` | `REQUIRED` | `direct-inspection` | Base matching recognizes uppercase `ERROR`. |
| `source-regression.S20.case-insensitive-error-title` | `REQUIRED` | `direct-inspection` | Base matching recognizes title-case `Error`. |
| `source-regression.S20.case-insensitive-error-lower` | `REQUIRED` | `direct-inspection` | Base matching recognizes lowercase `error`. |
| `source-regression.S20.case-insensitive-fatal-upper` | `REQUIRED` | `direct-inspection` | Base matching recognizes uppercase `FATAL`. |
| `source-regression.S20.case-insensitive-fatal-lower` | `REQUIRED` | `direct-inspection` | Base matching recognizes lowercase `fatal`. |
| `source-regression.S20.negative-identifier-prefix-fatal` | `REQUIRED` | `direct-inspection` | The base regex excludes `fatal` preceded by an identifier character and followed by a boundary. |
| `source-regression.S20.negative-fatal-identifier-suffix` | `REQUIRED` | `direct-inspection` | The base regex excludes `fatal` followed by an identifier character. |
| `source-regression.S20.negative-identifier-contained-fatal` | `REQUIRED` | `direct-inspection` | The base regex excludes `fatal` inside an identifier on both sides. |
| `source-regression.S20.regression-segmentation-fault` | `REQUIRED` | `direct-inspection` | The base regex matches a segmentation-fault line. |
| `source-regression.S20.negative-procserv-child-start-line` | `REQUIRED` | `direct-inspection` | The base regex excludes a routine procServ child line. |
| `source-regression.S20.negative-iocinit-complete-line` | `REQUIRED` | `direct-inspection` | The base regex excludes the IOC-ready line. |
| `source-regression.S20.negative-epics-banner` | `REQUIRED` | `direct-inspection` | The base regex excludes a normal EPICS banner. |
| `source-regression.S20.negative-startup-banner` | `REQUIRED` | `direct-inspection` | The base regex excludes a normal startup line. |
| `source-regression.S20.base-patterns.equal-subset-union` | `REQUIRED` | `direct-inspection` | The base regex is composed directly from the fatal and ambiguous subsets. |
| `source-regression.S20.subset-fatal-is-fatal` | `REQUIRED` | `direct-inspection` | `FATAL` remains in the fatal subset. |
| `source-regression.S20.subset-identifier-prefix-fatal-is-benign` | `REQUIRED` | `direct-inspection` | The fatal subset excludes `fatal` preceded by an identifier character and followed by a boundary. |
| `source-regression.S20.subset-fatal-identifier-suffix-is-benign` | `REQUIRED` | `direct-inspection` | The fatal subset excludes `fatal` followed by an identifier character. |
| `source-regression.S20.subset-identifier-contained-fatal-is-benign` | `REQUIRED` | `direct-inspection` | The fatal subset excludes `fatal` inside an identifier on both sides. |
| `source-regression.S20.subset-undefined-symbol-is-fatal` | `REQUIRED` | `direct-inspection` | `undefined symbol` remains in the fatal subset. |
| `source-regression.S20.subset-can-t-open-is-ambiguous` | `REQUIRED` | `direct-inspection` | `Can't open` remains in the ambiguous subset. |
| `source-regression.S20.subset-error-is-ambiguous` | `REQUIRED` | `direct-inspection` | `ERROR` remains in the ambiguous subset. |
| `source-regression.S20.subset-invalid-directory-path-is-ambiguous` | `REQUIRED` | `direct-inspection` | `Invalid directory path` remains in the ambiguous subset. |

## Accepted M8 S21 Addition

S21 adds five REQUIRED direct-inspection identities accepted by the owner on 2026-08-07. Real history-noise startup outcomes remain in local lifecycle S30.

| Check ID | Kind | Test Method | Source Contract |
| --- | --- | --- | --- |
| `source-regression.S21.exclude-pattern.nonempty` | `REQUIRED` | `direct-inspection` | The exclusion source constant is nonempty. |
| `source-regression.S21.exclude-pattern.compiles` | `REQUIRED` | `direct-inspection` | The exclusion source constant is valid for `grep -E`. |
| `source-regression.S21.history-load.matches-base-patterns` | `REQUIRED` | `direct-inspection` | The emitted history-load diagnostic remains a base-pattern positive control before exclusion. |
| `source-regression.S21.history-write.matches-exclude-pattern` | `REQUIRED` | `direct-inspection` | The exclusion source constant recognizes the history-write diagnostic. |
| `source-regression.S21.line-filter.precedes-crash-scans` | `REQUIRED` | `direct-inspection` | The runner filters whole lines before fatal and corroborating scans consume the filtered window. |

## M7 S22 Addition

S22 adds one prerequisite and ten real-path behavior identities. It invokes
the complete shipped setup in a private mount namespace. The five file targets
use directory impostors, while the configuration and log directory targets
remain valid directories.

| Check ID | Kind | Test Method | Verification Contract |
| --- | --- | --- | --- |
| `source-regression.S22.isolation.prerequisites` | `PREREQUISITE` | `direct-inspection` | Required tools, identities, mount targets, and private mount capability are available. |
| `source-regression.S22.impostor.setup-exits-one` | `BEHAVIOR` | `real-path` | The shipped full setup exits 1 when file targets are directory impostors. |
| `source-regression.S22.impostor.success-banner-absent` | `BEHAVIOR` | `real-path` | The failed setup does not emit the final success banner. |
| `source-regression.S22.impostor.sudoers-directory-rejected` | `BEHAVIOR` | `real-path` | The sudoers file target rejects a directory. |
| `source-regression.S22.impostor.systemd-template-directory-rejected` | `BEHAVIOR` | `real-path` | The systemd template file target rejects a directory. |
| `source-regression.S22.impostor.logrotate-directory-rejected` | `BEHAVIOR` | `real-path` | The logrotate file target rejects a directory. |
| `source-regression.S22.impostor.runner-directory-rejected` | `BEHAVIOR` | `real-path` | The runner file target rejects a directory. |
| `source-regression.S22.impostor.completion-directory-rejected` | `BEHAVIOR` | `real-path` | The completion file target rejects a directory. |
| `source-regression.S22.valid.setup-exits-zero` | `BEHAVIOR` | `real-path` | The shipped full setup exits 0 with valid target types. |
| `source-regression.S22.valid.configuration-directory-accepted` | `BEHAVIOR` | `real-path` | The configuration directory target passes its explicit directory check. |
| `source-regression.S22.valid.log-directory-accepted` | `BEHAVIOR` | `real-path` | The log directory target passes its explicit directory check. |

The fixed source-regression catalog contains 108 identities: 36 moved
identities, 57 source-contract identities in S15 through S21, 11 M7
identities in S22, and 4 M19 identities in S23.

## M19 S23 Addition

S23 adds four real-path behavior identities. It drives the shipped
`setup-system-infra.bash` against an absent `IOC_RUNNER_SCRIPT_DEST` parent and
verifies destination-parent creation without disturbing the default path
(M19/#147). The symlink identity runs on RHEL-family setup and is NA elsewhere.

| Check ID | Kind | Test Method | Verification Contract |
| --- | --- | --- | --- |
| `source-regression.S23.absent-parent.setup-exits-zero` | `BEHAVIOR` | `real-path` | The shipped setup exits 0 deploying to a destination whose parent is absent. |
| `source-regression.S23.absent-parent.runner-deployed` | `BEHAVIOR` | `real-path` | The runner is deployed at the non-default destination. |
| `source-regression.S23.default.parent-unchanged` | `BEHAVIOR` | `real-path` | An existing destination parent keeps its mode (the guard skips install -d). |
| `source-regression.S23.symlink.absent-parent-created` | `BEHAVIOR` | `real-path` | On RHEL-family setup the redirected symlink parent is created; NA elsewhere. |

## Move Invariants

1. Each current assertion and prerequisite receives exactly one accepted D13 disposition and reason.
2. A `retain` row appears once in the destination suite with valid current evidence.
3. A `replace` row appears once through an accepted valid evidence path and records what it supersedes.
4. A `remove` row has no destination check and carries an owner-approved reason.
5. Retained and replacement checks keep the accepted STEP identities and order.
6. No accepted behavior check replaces an internal product function or path.
7. Only accepted outer boundaries may be redirected.
8. The invoking identity owns Git and source-tree operations; root owns suite startup and the real setup invocation where the accepted check requires it.
9. S01 through S06 remain in `tests/test-system-infra.bash` and do not appear in the destination suite.
10. No `test-harness-integrity` suite or additional suite result is created.

## Verification Method

Before the move, count the 36 mapped result branches, confirm every S07 through S14 `verify_state` call has one row, and confirm all eight validity prerequisites remain represented. Review each row's current claim, kind, method, evidence validity, and proposed ID before accepting one disposition and reason. After the move, reconcile the destination suite against those accepted dispositions, then confirm the system-infrastructure pipeline contains only S01 through S06. M8 adds the fifty-seven accepted S15 through S21 identities without changing the original move dispositions. M7 adds the eleven S22 identities through the shipped full setup in a private mount namespace. M19 adds the four S23 identities through the shipped setup deploying to an absent destination parent. Runtime verification uses the real source-regression and installed-conformance suites on Debian 13 and Rocky 8; a hand-built reproduction does not satisfy this inventory.
