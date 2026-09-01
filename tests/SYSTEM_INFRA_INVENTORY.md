# System Infrastructure Reporting Inventory

Status: M8 step 1 inventory after M9 suite separation
Source: `tests/test-system-infra.bash`
Expected Counts: [`reporting-counts.csv`](reporting-counts.csv)

## Dependency Policy

- `system-infra.P00.root-required` governs every numbered STEP.
- Each S02 existence check governs the owner and permission checks for the same
  installed path.
- The S02 sudoers existence check also governs S03 and S06.
- The S02 logrotate-policy existence check also governs S04.
- S06 regex applicability governs its prerequisite and behavior checks.
- S06 probe-user availability governs the two regex behavior checks.
- S07 SELinux applicability governs the context-tool and policy-context checks.
- S07 `/usr/sbin/matchpathcon` availability and the matching S02 policy-file
  existence check govern each policy-context check.
- An unexpected abort preserves closed states and closes every remaining open
  identity as `SCRIPT_ERROR`.

## Test Method Assignment

The S03 sudoers syntax check, the S04 logrotate syntax check, the two S06
authorization probes, and the two S07 policy-context checks use `real-path`.
All other rows use `direct-inspection` against the actual installed host state.

## Current Branch Mapping

- The root preflight maps to P00.
- Each verify_perm missing-path branch maps to that path's existence identity;
  its owner and permission identities become SKIP. The present-path branch
  closes owner and permission after the existence identity passes.
- The S05 missing-include branch closes include-directive-exists as FAIL and
  include-directive-final as SKIP. The present branch closes both normally.
- The S06 missing-policy branch reuses the S02 sudoers existence result instead
  of creating a duplicate identity. The glob-policy branch closes
  regex-policy-applicable and its dependents as NA. User creation failure
  closes probe-user-available and its behavior dependents as SKIP.
- The S07 inactive-SELinux branch closes all four identities as NA. On an
  active host, an unavailable `/usr/sbin/matchpathcon` fails its prerequisite
  and skips both context checks; a missing policy file skips only its matching
  check.

## Catalog

| STEP | Check ID | Kind | Description |
| --- | --- | --- | --- |
| P00 | `system-infra.P00.root-required` | `REQUIRED` | Effective user is root. |
| S01 | `system-infra.S01.ioc-group-exists` | `BEHAVIOR` | System group `ioc` exists. |
| S01 | `system-infra.S01.ioc-service-user-exists` | `BEHAVIOR` | System user `ioc-srv` exists. |
| S02 | `system-infra.S02.conf-dir.exists` | `REQUIRED` | `/etc/procServ.d` exists. |
| S02 | `system-infra.S02.conf-dir.owner` | `BEHAVIOR` | Configuration directory owner is `root:ioc`. |
| S02 | `system-infra.S02.conf-dir.permission` | `BEHAVIOR` | Configuration directory permission is `2770`. |
| S02 | `system-infra.S02.sudoers-policy.exists` | `REQUIRED` | `/etc/sudoers.d/10-epics-ioc` exists. |
| S02 | `system-infra.S02.sudoers-policy.owner` | `BEHAVIOR` | Sudoers policy owner is `root:root`. |
| S02 | `system-infra.S02.sudoers-policy.permission` | `BEHAVIOR` | Sudoers policy permission is `0440`. |
| S02 | `system-infra.S02.systemd-template.exists` | `REQUIRED` | `/etc/systemd/system/epics-@.service` exists. |
| S02 | `system-infra.S02.systemd-template.owner` | `BEHAVIOR` | Systemd template owner is `root:root`. |
| S02 | `system-infra.S02.systemd-template.permission` | `BEHAVIOR` | Systemd template permission is `0644`. |
| S02 | `system-infra.S02.logrotate-policy.exists` | `REQUIRED` | `/etc/logrotate.d/procserv` exists. |
| S02 | `system-infra.S02.logrotate-policy.owner` | `BEHAVIOR` | Logrotate policy owner is `root:root`. |
| S02 | `system-infra.S02.logrotate-policy.permission` | `BEHAVIOR` | Logrotate policy permission is `0644`. |
| S02 | `system-infra.S02.installed-runner.exists` | `REQUIRED` | `/usr/local/bin/ioc-runner` exists. |
| S02 | `system-infra.S02.installed-runner.owner` | `BEHAVIOR` | Installed runner owner is `root:root`. |
| S02 | `system-infra.S02.installed-runner.permission` | `BEHAVIOR` | Installed runner permission is `0755`. |
| S02 | `system-infra.S02.bash-completion.exists` | `REQUIRED` | `/etc/bash_completion.d/ioc-runner` exists. |
| S02 | `system-infra.S02.bash-completion.owner` | `BEHAVIOR` | Bash completion owner is `root:root`. |
| S02 | `system-infra.S02.bash-completion.permission` | `BEHAVIOR` | Bash completion permission is `0644`. |
| S03 | `system-infra.S03.sudoers-syntax-valid` | `BEHAVIOR` | Deployed sudoers policy passes `visudo -cf`. |
| S04 | `system-infra.S04.logrotate-syntax-valid` | `BEHAVIOR` | Deployed logrotate policy passes debug validation. |
| S04 | `system-infra.S04.log-glob-pinned` | `BEHAVIOR` | Policy contains the configured log directory glob. |
| S04 | `system-infra.S04.su-directive-pinned` | `BEHAVIOR` | Policy contains `su root ioc`. |
| S04 | `system-infra.S04.copytruncate-pinned` | `BEHAVIOR` | Policy contains `copytruncate`. |
| S04 | `system-infra.S04.compress-pinned` | `BEHAVIOR` | Policy contains `compress`. |
| S04 | `system-infra.S04.weekly-pinned` | `BEHAVIOR` | Policy contains `weekly`. |
| S04 | `system-infra.S04.rotate-eight-pinned` | `BEHAVIOR` | Policy contains `rotate 8`. |
| S04 | `system-infra.S04.nodateext-pinned` | `BEHAVIOR` | Policy contains `nodateext`. |
| S05 | `system-infra.S05.include-directive-exists` | `REQUIRED` | Main sudoers policy contains the sudoers.d include directive. |
| S05 | `system-infra.S05.include-directive-final` | `BEHAVIOR` | No active rule follows the include directive. |
| S06 | `system-infra.S06.regex-policy-applicable` | `APPLICABILITY` | Deployed sudoers policy uses anchored regex commands. |
| S06 | `system-infra.S06.probe-user-available` | `PREREQUISITE` | A safe ioc-group probe user is available. |
| S06 | `system-infra.S06.bad-name-denied` | `BEHAVIOR` | Anchored policy denies an out-of-model service name. |
| S06 | `system-infra.S06.good-name-allowed` | `BEHAVIOR` | Anchored policy allows a valid service name. |
| S07 | `system-infra.S07.selinux-active` | `APPLICABILITY` | SELinux is active on the installed host. |
| S07 | `system-infra.S07.matchpathcon-available` | `PREREQUISITE` | `/usr/sbin/matchpathcon` is executable when SELinux is active. |
| S07 | `system-infra.S07.sudoers-policy-context-valid` | `BEHAVIOR` | The sudoers policy context matches active SELinux policy. |
| S07 | `system-infra.S07.logrotate-policy-context-valid` | `BEHAVIOR` | The logrotate policy context matches active SELinux policy. |

## Fixed Vector Rule

Every supported installed-conformance invocation declares the same identities
in this order and compares the closed catalog with `reporting-counts.csv`.
Missing required paths do not reduce `Total`; they close the existence check as
`FAIL` and dependent checks as `SKIP`. A glob-form sudoers policy closes the
S06 applicability branch as `NA`; inactive SELinux closes S07 as `NA`.
Unexpected termination closes every remaining open identity as `SCRIPT_ERROR`.
