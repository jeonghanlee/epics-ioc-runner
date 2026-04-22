# Guard against `includedir` ordering that overrides drop-in NOPASSWD policy

## Milestone
1.0.5

## Labels
bug, setup, tests, docs, security

## Summary
On a host where `/etc/sudoers` places the `includedir /etc/sudoers.d` directive
*before* user-specific rules, the NOPASSWD policy deployed by
`setup-system-infra.bash` to `/etc/sudoers.d/10-epics-ioc` is silently
overridden. `ioc-runner start|stop|restart|...` then prompts for a password
even though the group membership and the drop-in file are correct.

## Root Cause
Sudo evaluates all matching rules and the **last match wins**. The `includedir`
directive loads drop-in files inline at its position in `/etc/sudoers`. When a
user-specific `ALL=(ALL) ALL` line appears *after* the directive, it is
evaluated after the drop-in and overrides the `NOPASSWD` grant.

Observed ordering on the affected host:
```
line 107  %wheel   ALL=(ALL) ALL
line 110  %wheel   ALL=(ALL) NOPASSWD: ALL
line 120  #includedir /etc/sudoers.d            <- drop-in loaded here
line 122  jeonglee ALL=(ALL) ALL                <- last match, wins
```

`sudo -l` confirmation from the affected user:
```
(ALL) ALL
(ALL) NOPASSWD: ALL
(ALL) ALL                                        <- overrides below
(root) NOPASSWD: /usr/bin/systemctl start ...
```

## Scope
The condition is a property of `/etc/sudoers` on the target host and is
independent of group membership, so it can be validated at setup time before
any user is added to the `ioc` group.

## Proposed Changes

### 1. `bin/setup-system-infra.bash`
- Remove the redundant `-z "${SYSTEMCTL_BIN}"` check that became unreachable
  after `SYSTEMCTL_BIN` was pinned to `/usr/bin/systemctl`.
- Add `verify_sudoers_includedir_order` helper that scans `/etc/sudoers` for
  the final `includedir` directive and fails if any active rule follows it.
- Invoke the helper in STEP 3, immediately after the drop-in file is
  installed. The check contributes to the existing `VERIFY_PASS` /
  `VERIFY_FAIL` counters so the final summary reflects the condition.
- On failure, surface the offending lines and instruct the operator to move
  the `includedir` directive to the end of `/etc/sudoers` with `visudo`.

### 2. `tests/test-system-infra.bash`
- Add `test_sudoers_includedir_order` that asserts the ordering invariant on
  `/etc/sudoers`.
- Register it in the `run_all_tests` pipeline after `test_sudoers_syntax`.
- Assertion failure is fatal to the phase, so CI and `test-system-infra.bash`
  reject hosts where the drop-in policy cannot take effect.

### 3. `tests/README.md`
Add a bullet under `Infrastructure State` describing the new Policy Ordering
check.

### 4. `docs/INSTALL.md`
Add a note to section 2.3 explaining the ordering requirement and the
`sudo -l` verification step.

## Acceptance Criteria
- Running `sudo ./bin/setup-system-infra.bash --full` on a host whose
  `/etc/sudoers` has trailing user rules reports a FAIL in the summary with
  the offending lines and remediation hint.
- `sudo bash tests/test-system-infra.bash` fails on the same condition.
- On a correctly ordered host both commands pass.
- `sudo -l` for a member of the `ioc` group shows the
  `(root) NOPASSWD: /usr/bin/systemctl ...` entry as the last match.

## Out of Scope
- Automatically rewriting `/etc/sudoers`. The file is security-critical and
  must stay under operator control via `visudo`.
- Supporting sudoers layouts that do not use `includedir`.
