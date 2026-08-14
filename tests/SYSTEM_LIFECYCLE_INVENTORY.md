# System Lifecycle Reporting Inventory

## Scope

This document is the M8 step 1 inventory for
tests/test-system-lifecycle.bash. It assigns stable identities to every current
assertion and every result-producing preflight, prerequisite, and early-return
branch. The suite identity is system-lifecycle, its scope is system, and its
primary category is lifecycle-behavior. Source and installed runner origins use
the same identity set.

## Inventory Basis

The source contains 77 catalog behavior assertion call sites. Repeated pipeline
functions and the three-call boundary helper add ten runtime occurrences:
explicit install at S06 and S12, cleanup install at S07, S09, and S13,
directory install at S08 and S14, and six additional boundary assertions at
S26. The camonitor
availability assertion is currently fail-only, so the maximum successful path
reports 86 assertions although 87 assertion branches exist.

The fixed catalog adds four P00 checks and eleven prerequisite or required
conditions currently represented only by early returns. The resulting catalog
contains 102 identities. S02, S03, and S04 are setup-only STEPs and own no
checks.

## Dependency Policy

- The four P00 checks govern all numbered STEPs.
- S23 camonitor availability governs the Channel Access behavior check.
- S25 system-journal availability governs both monitor-isolation checks.
- S26 softIoc availability governs all eleven crash-detection checks.
- S27 softIoc and probe-user-name prerequisites govern its four behavior
  checks.
- S28 the installed policy, softIoc, and logrotate conditions govern its ten
  behavior checks.
- S29 the installed policy, softIoc, probe-user-name, and probe-user group
  conditions govern its two behavior checks.
- A failed required condition is FAIL and closes dependent checks as SKIP. An
  unavailable optional facility is SKIP and closes dependent checks as SKIP.
- An unexpected abort preserves closed states and closes every remaining open
  identity as SCRIPT_ERROR.

## Test Method Assignment

Invocation, installed-state, executable, journal, user-fixture, and policy
conditions use direct-inspection. Lifecycle command behavior uses real-path
against the selected shipped runner. S22 observes the actual deployed socket
and executable paths directly. No row uses hand-built-reproduction.

## Stable Identity Mapping

| STEP | Check ID | Kind | Test Method | Current Assertion or Condition |
| --- | --- | --- | --- | --- |
| P00 | `system-lifecycle.P00.epics-base-set` | `REQUIRED` | `direct-inspection` | EPICS_BASE is set. |
| P00 | `system-lifecycle.P00.lsof-available` | `REQUIRED` | `direct-inspection` | lsof is available. |
| P00 | `system-lifecycle.P00.root-invocation` | `REQUIRED` | `direct-inspection` | The effective user is root. |
| P00 | `system-lifecycle.P00.selected-runner-executable` | `REQUIRED` | `direct-inspection` | The selected source or installed runner is executable. |
| S01 | `system-lifecycle.S01.system-configuration-directory-exists-conf-dir` | `REQUIRED` | `direct-inspection` | System configuration directory exists (${CONF_DIR}) |
| S01 | `system-lifecycle.S01.system-configuration-directory-is-writable-by-current-user` | `REQUIRED` | `direct-inspection` | System configuration directory is writable by current user |
| S01 | `system-lifecycle.S01.system-template-unit-exists-systemd-dir-epics-service` | `REQUIRED` | `direct-inspection` | System template unit exists (${SYSTEMD_DIR}/epics-@.service) |
| S05 | `system-lifecycle.S05.manual-configuration-artifact-created` | `BEHAVIOR` | `real-path` | Manual configuration artifact created |
| S06 | `system-lifecycle.S06.explicit-file-installation-succeeded` | `BEHAVIOR` | `real-path` | Explicit file installation succeeded |
| S07 | `system-lifecycle.S07.deployed-configuration-safely-removed` | `BEHAVIOR` | `real-path` | Deployed configuration safely removed |
| S08 | `system-lifecycle.S08.directory-based-installation-succeeded` | `BEHAVIOR` | `real-path` | Directory-based installation succeeded |
| S09 | `system-lifecycle.S09.deployed-configuration-safely-removed` | `BEHAVIOR` | `real-path` | Deployed configuration safely removed |
| S10 | `system-lifecycle.S10.workspace-configuration-artifact-removed` | `BEHAVIOR` | `real-path` | Workspace configuration artifact removed |
| S11 | `system-lifecycle.S11.configuration-artifact-auto-generated-natively` | `BEHAVIOR` | `real-path` | Configuration artifact auto-generated natively |
| S12 | `system-lifecycle.S12.explicit-file-installation-succeeded` | `BEHAVIOR` | `real-path` | Explicit file installation succeeded |
| S13 | `system-lifecycle.S13.deployed-configuration-safely-removed` | `BEHAVIOR` | `real-path` | Deployed configuration safely removed |
| S14 | `system-lifecycle.S14.directory-based-installation-succeeded` | `BEHAVIOR` | `real-path` | Directory-based installation succeeded |
| S15 | `system-lifecycle.S15.service-active` | `BEHAVIOR` | `real-path` | Service state is 'active' (Startup time: ${elapsed}s) |
| S16 | `system-lifecycle.S16.status-output-shows-active-active` | `BEHAVIOR` | `real-path` | Status output shows 'Active: active' |
| S17 | `system-lifecycle.S17.view-output-renders-the-configuration-ioc-cmd` | `BEHAVIOR` | `real-path` | View output renders the configuration (IOC_CMD=) |
| S18 | `system-lifecycle.S18.service-remains-active-after-restart` | `BEHAVIOR` | `real-path` | Service remains active after restart |
| S19 | `system-lifecycle.S19.service-is-inactive-after-stop` | `BEHAVIOR` | `real-path` | Service is inactive after stop |
| S19 | `system-lifecycle.S19.service-is-active-after-restart-following-stop` | `BEHAVIOR` | `real-path` | Service is active after restart following stop |
| S20 | `system-lifecycle.S20.unix-domain-socket-explicitly-created` | `BEHAVIOR` | `real-path` | UNIX Domain Socket explicitly created |
| S20 | `system-lifecycle.S20.ioc-name-appears-in-list-output` | `BEHAVIOR` | `real-path` | IOC name appears in list output |
| S20 | `system-lifecycle.S20.uds-socket-path-appears-in-list-output` | `BEHAVIOR` | `real-path` | UDS socket path appears in list output |
| S20 | `system-lifecycle.S20.list-v-output-contains-pid-column` | `BEHAVIOR` | `real-path` | List -v output contains PID column |
| S20 | `system-lifecycle.S20.list-v-output-contains-cpu-column` | `BEHAVIOR` | `real-path` | List -v output contains CPU column |
| S20 | `system-lifecycle.S20.list-v-output-contains-mem-column` | `BEHAVIOR` | `real-path` | List -v output contains MEM column |
| S20 | `system-lifecycle.S20.list-vv-output-contains-recv-q-column` | `BEHAVIOR` | `real-path` | List -vv output contains Recv-Q column |
| S20 | `system-lifecycle.S20.list-vv-output-contains-send-q-column` | `BEHAVIOR` | `real-path` | List -vv output contains Send-Q column |
| S20 | `system-lifecycle.S20.list-vv-output-contains-perm-column` | `BEHAVIOR` | `real-path` | List -vv output contains PERM column |
| S21 | `system-lifecycle.S21.parsed-list-v` | `BEHAVIOR` | `real-path` | Parsed: list -v |
| S21 | `system-lifecycle.S21.parsed-v-list` | `BEHAVIOR` | `real-path` | Parsed: -v list |
| S22 | `system-lifecycle.S22.uds-socket-has-correct-permissions-srw-rw` | `BEHAVIOR` | `direct-inspection` | UDS socket has correct permissions (srw-rw----) |
| S22 | `system-lifecycle.S22.con-available` | `REQUIRED` | `direct-inspection` | con utility is available |
| S22 | `system-lifecycle.S22.uds-socket-is-in-listening-state` | `BEHAVIOR` | `direct-inspection` | UDS socket is in listening state |
| S23 | `system-lifecycle.S23.camonitor-available` | `REQUIRED` | `direct-inspection` | camonitor executable availability |
| S23 | `system-lifecycle.S23.expected-updates-observed` | `BEHAVIOR` | `real-path` | Channel Access monitored ${CAMONITOR_COUNT} updates successfully (Time: ${elapsed}s) |
| S24 | `system-lifecycle.S24.inspect-command-successfully-retrieved-server-netlink-context` | `BEHAVIOR` | `real-path` | Inspect command successfully retrieved server Netlink context |
| S24 | `system-lifecycle.S24.inspect-section-1-references-the-target-socket-path` | `BEHAVIOR` | `real-path` | Inspect section 1 references the target socket path |
| S24 | `system-lifecycle.S24.inspect-section-1-excludes-unrelated-systemd-uds-entries` | `BEHAVIOR` | `real-path` | Inspect section 1 excludes unrelated systemd UDS entries |
| S25 | `system-lifecycle.S25.system-journal-available` | `PREREQUISITE` | `direct-inspection` | System journal output is available. |
| S25 | `system-lifecycle.S25.journal-channel-visible-for-unit-positive-control` | `BEHAVIOR` | `real-path` | Journal channel visible for unit (positive control) |
| S25 | `system-lifecycle.S25.input-securely-blocked-in-monitor-mode` | `BEHAVIOR` | `real-path` | Input securely blocked in monitor mode |
| S26 | `system-lifecycle.S26.softioc-available` | `PREREQUISITE` | `direct-inspection` | softIoc is executable. |
| S26 | `system-lifecycle.S26.leading-boundary-identifier-adjacent-exits-zero` | `BEHAVIOR` | `real-path` | `fatal` preceded by an identifier character and followed by a boundary does not fail startup. |
| S26 | `system-lifecycle.S26.leading-boundary-identifier-adjacent-avoids-failed-verdict` | `BEHAVIOR` | `real-path` | The isolated leading-boundary case produces no failed-initialization verdict. |
| S26 | `system-lifecycle.S26.leading-boundary-identifier-adjacent-emitted` | `BEHAVIOR` | `real-path` | The isolated leading-boundary fixture is present in the procServ log. |
| S26 | `system-lifecycle.S26.trailing-boundary-identifier-adjacent-exits-zero` | `BEHAVIOR` | `real-path` | `fatal` preceded by a boundary and followed by an identifier character does not fail startup. |
| S26 | `system-lifecycle.S26.trailing-boundary-identifier-adjacent-avoids-failed-verdict` | `BEHAVIOR` | `real-path` | The isolated trailing-boundary case produces no failed-initialization verdict. |
| S26 | `system-lifecycle.S26.trailing-boundary-identifier-adjacent-emitted` | `BEHAVIOR` | `real-path` | The isolated trailing-boundary fixture is present in the procServ log. |
| S26 | `system-lifecycle.S26.identifier-contained-fatal-exits-zero` | `BEHAVIOR` | `real-path` | `fatal` adjacent to identifier characters on both sides does not fail startup. |
| S26 | `system-lifecycle.S26.identifier-contained-fatal-avoids-failed-verdict` | `BEHAVIOR` | `real-path` | The both-sides identifier case produces no failed-initialization verdict. |
| S26 | `system-lifecycle.S26.identifier-contained-fatal-emitted` | `BEHAVIOR` | `real-path` | The both-sides identifier fixture is present in the procServ log. |
| S26 | `system-lifecycle.S26.broken-softioc-fatal-pre-init-exit-1` | `BEHAVIOR` | `real-path` | Broken softIoc (FATAL pre-init) -> exit 1 |
| S26 | `system-lifecycle.S26.broken-softioc-failed-to-initialize-verdict` | `BEHAVIOR` | `real-path` | Broken softIoc -> failed-to-initialize verdict |
| S27 | `system-lifecycle.S27.softioc-available` | `PREREQUISITE` | `direct-inspection` | softIoc is executable. |
| S27 | `system-lifecycle.S27.probe-user-name-available` | `PREREQUISITE` | `direct-inspection` | The journal-less probe user name is not already in use. |
| S27 | `system-lifecycle.S27.operator-is-an-ioc-group-member-sudoers-gate-reachable` | `BEHAVIOR` | `real-path` | Operator is an ioc-group member (sudoers gate reachable) |
| S27 | `system-lifecycle.S27.operator-is-not-in-systemd-journal` | `BEHAVIOR` | `real-path` | Operator is NOT in systemd-journal |
| S27 | `system-lifecycle.S27.journal-less-operator-crash-exit-1` | `BEHAVIOR` | `real-path` | Journal-less operator: crash -> exit 1 |
| S27 | `system-lifecycle.S27.journal-less-operator-failed-to-initialize-verdict-reads-log-file-not-journal` | `BEHAVIOR` | `real-path` | Journal-less operator: failed-to-initialize verdict (reads log file, not journal) |
| S28 | `system-lifecycle.S28.logrotate-policy-exists` | `REQUIRED` | `direct-inspection` | The installed procServ logrotate policy exists. |
| S28 | `system-lifecycle.S28.softioc-available` | `PREREQUISITE` | `direct-inspection` | softIoc is executable. |
| S28 | `system-lifecycle.S28.logrotate-available` | `PREREQUISITE` | `direct-inspection` | logrotate is executable. |
| S28 | `system-lifecycle.S28.pre-rotate-fatal-pattern-moved-into-rotated-log-boundary-created` | `BEHAVIOR` | `real-path` | Pre-rotate FATAL pattern moved into rotated log (boundary created) |
| S28 | `system-lifecycle.S28.active-log-cleared-of-the-pre-rotate-fatal-pattern-after-rotation` | `BEHAVIOR` | `real-path` | Active log cleared of the pre-rotate FATAL pattern after rotation |
| S28 | `system-lifecycle.S28.no-false-crash-verdict-from-rotated-historical-fatal-pattern` | `BEHAVIOR` | `real-path` | No false crash verdict from rotated historical FATAL pattern |
| S28 | `system-lifecycle.S28.t2-sub-case-a-restart-activation-observed-before-log-mutation` | `BEHAVIOR` | `real-path` | T2 sub-case A: restart activation observed before log mutation |
| S28 | `system-lifecycle.S28.t2-sub-case-a-log-mv-to-side-name-succeeded` | `BEHAVIOR` | `real-path` | T2 sub-case A: log mv to side-name succeeded |
| S28 | `system-lifecycle.S28.t2-sub-case-a-replacement-log-install-succeeded` | `BEHAVIOR` | `real-path` | T2 sub-case A: replacement log install succeeded |
| S28 | `system-lifecycle.S28.t2-sub-case-a-active-log-inode-actually-changed-after-replacement` | `BEHAVIOR` | `real-path` | T2 sub-case A: active log inode actually changed after replacement |
| S28 | `system-lifecycle.S28.t2-sub-case-a-in-window-new-inode-replacement-triggers-crash-verdict-exit-1` | `BEHAVIOR` | `real-path` | T2 sub-case A: in-window new-inode replacement triggers crash verdict (exit 1) |
| S28 | `system-lifecycle.S28.t2-sub-case-b-restart-activation-observed-before-log-mutation` | `BEHAVIOR` | `real-path` | T2 sub-case B: restart activation observed before log mutation |
| S28 | `system-lifecycle.S28.t2-sub-case-b-in-window-same-inode-regrow-past-triggers-crash-verdict-via-tailhash-mismatch` | `BEHAVIOR` | `real-path` | T2 sub-case B: in-window same-inode regrow-past triggers crash verdict via tailhash mismatch |
| S29 | `system-lifecycle.S29.sudoers-policy-exists` | `REQUIRED` | `direct-inspection` | The installed ioc-runner sudoers policy exists. |
| S29 | `system-lifecycle.S29.softioc-available` | `PREREQUISITE` | `direct-inspection` | softIoc is executable. |
| S29 | `system-lifecycle.S29.probe-user-name-available` | `PREREQUISITE` | `direct-inspection` | The non-ioc probe user name is not already in use. |
| S29 | `system-lifecycle.S29.probe-user-not-ioc-member` | `REQUIRED` | `direct-inspection` | The created probe user is outside the ioc group. |
| S29 | `system-lifecycle.S29.non-ioc-user-can-read-the-log-file-mode-0644` | `BEHAVIOR` | `real-path` | Non-ioc user can read the log file (mode 0644) |
| S29 | `system-lifecycle.S29.non-ioc-user-denied-systemctl-start-by-ioc-sudoers-gate` | `BEHAVIOR` | `real-path` | Non-ioc user denied systemctl start by %ioc sudoers gate |
| S30 | `system-lifecycle.S30.conforming-root-ioc-2775-dir-emits-no-warning` | `BEHAVIOR` | `real-path` | Conforming root:ioc 2775 dir emits no warning |
| S30 | `system-lifecycle.S30.conforming-install-exits-0` | `BEHAVIOR` | `real-path` | Conforming install exits 0 |
| S30 | `system-lifecycle.S30.group-mismatch-dir-not-ioc-warns` | `BEHAVIOR` | `real-path` | Group-mismatch dir (not ioc) warns |
| S30 | `system-lifecycle.S30.group-mismatch-install-with-f-exits-0` | `BEHAVIOR` | `real-path` | Group-mismatch install with -f exits 0 |
| S30 | `system-lifecycle.S30.untraversable-0700-parent-warns` | `BEHAVIOR` | `real-path` | Untraversable 0700 parent warns |
| S30 | `system-lifecycle.S30.untraversable-parent-install-with-f-exits-0` | `BEHAVIOR` | `real-path` | Untraversable-parent install with -f exits 0 |
| S30 | `system-lifecycle.S30.relative-ioc-chdir-is-a-hard-validation-error-m6-109` | `BEHAVIOR` | `real-path` | Relative IOC_CHDIR is a hard validation error (M6/#109) |
| S30 | `system-lifecycle.S30.relative-path-install-exits-1-despite-f` | `BEHAVIOR` | `real-path` | Relative-path install exits 1 despite -f |
| S30 | `system-lifecycle.S30.symlinked-ioc-chdir-warns-symlinked-leaf-rejected` | `BEHAVIOR` | `real-path` | Symlinked IOC_CHDIR warns (symlinked leaf rejected) |
| S30 | `system-lifecycle.S30.symlinked-leaf-install-with-f-exits-0` | `BEHAVIOR` | `real-path` | Symlinked-leaf install with -f exits 0 |
| S30 | `system-lifecycle.S30.missing-setgid-0775-dir-warns` | `BEHAVIOR` | `real-path` | Missing-setgid 0775 dir warns |
| S30 | `system-lifecycle.S30.missing-setgid-install-with-f-exits-0` | `BEHAVIOR` | `real-path` | Missing-setgid install with -f exits 0 |
| S30 | `system-lifecycle.S30.prompt-eof-aborts-install-exit-1` | `BEHAVIOR` | `real-path` | Prompt EOF aborts install (exit 1) |
| S30 | `system-lifecycle.S30.prompt-explicit-n-declines-install-exit-1` | `BEHAVIOR` | `real-path` | Prompt explicit N declines install (exit 1) |
| S30 | `system-lifecycle.S30.prompt-explicit-y-proceeds-with-install-exit-0` | `BEHAVIOR` | `real-path` | Prompt explicit Y proceeds with install (exit 0) |
| S30 | `system-lifecycle.S30.prompt-y-path-deploys-the-conf-file` | `BEHAVIOR` | `real-path` | Prompt Y path deploys the conf file |
| S31 | `system-lifecycle.S31.symlink-created-in-multi-user-wants-enable` | `BEHAVIOR` | `real-path` | Symlink created in multi-user.wants (Enable) |
| S31 | `system-lifecycle.S31.symlink-strictly-removed-disable` | `BEHAVIOR` | `real-path` | Symlink strictly removed (Disable) |
| S32 | `system-lifecycle.S32.configuration-file-safely-removed` | `BEHAVIOR` | `real-path` | Configuration file safely removed |
| S32 | `system-lifecycle.S32.service-completely-stopped-inactive` | `BEHAVIOR` | `real-path` | Service completely stopped (inactive) |

## Completeness Cross-check

| Source Shape | Count |
| --- | ---: |
| Static assertion call sites | 77 |
| Repeated pipeline and boundary-helper occurrences | 10 |
| Current assertion branches | 87 |
| Added P00 checks | 4 |
| Added prerequisite or required conditions | 11 |
| Fixed catalog total | 102 |

The mapping is complete only while every source assertion branch maps once,
every early return maps to its governing identity, repeated functions retain
their STEP-specific IDs, and the pipeline remains S01 through S32.
