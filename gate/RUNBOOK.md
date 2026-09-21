# Release Cycle Runbook

## Scope

This runbook defines the release Gate for an `epics-ioc-runner` tree on fresh
Rocky 8 and Debian 13 consumers. It owns Gate ordering, runner deployment,
runner verification, result interpretation, and evidence requirements.

**Out of scope:** image baking, VM lifecycle, generated Ansible inventory,
operator implementation, fixture provisioning, milestone planning, and release
mutation. Those procedures remain in their owning repositories or skills.

This Gate runs the installed `--system` suites in place on a consumer's
simulated `root_squash` export itself, in step 5. Running them in place on a
server that is not a Gate consumer, including a real NFS `root_squash` home, is
a different procedure, defined in
[`../tests/README.md`](../tests/README.md#3-system-tests-on-an-nfs-home-with-root_squash).
The `ssh vmadmin@<host>` and `sudo -n` forms below assume the Gate consumer
account and do not apply there.

## Required Reading

Before running any step, read this runbook in full, then read in full every
document listed under External Authorities, including
[`../tests/README.md`](../tests/README.md). No step is self-sufficient: suite
modes, account and `sudo` assumptions, and path constraints are defined in those
documents and are not repeated here. Do not act from one step, a summary, or
memory of an earlier run.

## External Authorities

| Authority | Owned Contract |
| --- | --- |
| `cloud-provision/docs/RUNBOOK_BAKE.md` | Image bake, version pinning, fresh consumer acceptance, proxy lifecycle, and bake failure handling |
| `cloud-provision/README.md` | Consumer lifecycle targets and status operations |
| `cloud-provision/docs/RUNBOOK_ANSIBLE_INVENTORY.md` | Runtime inventory generation for an existing VM |
| `cloud-provision/docs/OPERATOR_MODEL.md` | Operator order, species composition, and realization modes |
| `ansible-provision/README.md` | Species and single-operator Make targets |
| `ansible-provision/docs/ANSIBLE_CLI.md` | Runtime inventory and operator invocation contract |
| [`../tests/README.md`](../tests/README.md) | Suite modes, binary origin, result format, and workspace retention |
| [`../docs/PERMISSION_MODEL.md`](../docs/PERMISSION_MODEL.md) | Permission behavior verified by the multi-user scenarios |

Open each external procedure from the recorded supplier checkout at the commit
used for the Gate run. Do not follow a moving branch URL and do not copy the
external implementation steps into this runbook.

## Gate Identity

Set `<release-register>` to the canonical milestone document selected by the
release-cycle workflow. Record its repository, path, commit, and status. It is
the authority for the baseline ref and the applicable Test Plans used below.

Record the runner tree before any remote work:

```bash
git -C <repo> rev-parse --abbrev-ref HEAD
git -C <repo> rev-parse --short HEAD
git -C <repo> status --porcelain
```

Record the branch, commit, and status of the cloud-provision and
ansible-provision checkouts before and after the image pair is created. The
supplier commits must not move between the two image builds.

Record the installed runner identity on both consumers after each deployment:

```bash
ssh vmadmin@<host> '/usr/local/bin/ioc-runner -V'
```

The Gate uses this fixed consumer pair:

| Platform | Consumer Target | Address | Domain |
| --- | --- | --- | --- |
| Rocky 8 | `rocky8-iocrunner.main` | `192.168.123.150` | `lab-rocky8-iocrunner-main` |
| Debian 13 | `debian13-iocrunner.main` | `192.168.123.50` | `lab-debian13-iocrunner-main` |

## Result Grades

| Grade | Required State | Permitted Use |
| --- | --- | --- |
| Gate | New image pair, fresh consumers, accepted provenance, and every Gate step executed against one unchanged candidate commit | Release evidence |
| Check | Reused consumer, incomplete preconditions, or a subset of Gate steps | The observed check only |

A failed precondition either stops the run or changes the run to Check grade.
Record the failed condition and the grade change before continuing. Evidence
from an earlier consumer pair or candidate commit cannot fill a missing step.

## Preconditions

### 1. New image pair and fresh consumers

From the cloud-provision checkout, follow the canonical Bake Runbook and README
to:

1. select the explicit baseline ref required by `<release-register>`;
2. bake one new Rocky 8 image and one new Debian 13 image from unchanged
   supplier commits;
3. validate each image, creation record, and manifest sidecar;
4. remove the deterministic consumers and create both consumers from the new
   images; and
5. perform the canonical fresh-consumer acceptance before candidate deployment.

Required to continue:

- both manifests record the selected baseline ref and clean tagged runner
  provenance;
- each remote manifest hash matches its published sidecar;
- the canonical validator accepts both consumers;
- the retained checkout and installed runner match the manifest runner commit;
- neither manifest contains a dirty source record; and
- both consumers were created in this Gate run.

Capture the complete canonical Golden acceptance output for each host in one
control-host file. Start a terminal capture before running the owning Bake
Runbook host block; do not add output redirection to that block:

```bash
script -q -e <golden-acceptance-log>
```

Run the canonical host block unchanged in the child terminal, then finish and
hash the capture:

```bash
exit
sha256sum <golden-acceptance-log>
```

`script` from `util-linux` is a control-host prerequisite. Record the capture
file and its SHA-256 digest in the Evidence table.

Consumer creation owns any site proxy precondition. Do not apply or seal proxy
state from this runbook.

### 2. Fixture state

The Golden `P_testusers` operator provides the multi-user accounts, and
`P_iocrunner` provides the shared IOC infrastructure. This runbook verifies the
result and never creates or repairs it.

```bash
ssh vmadmin@<host> 'ok=1; for u in opa opb; do getent group ioc | grep -qw "$u" || ok=0; done; getent passwd obs >/dev/null || ok=0; id -nG obs | grep -qw ioc && ok=0; for u in usera userb; do [ -e /var/lib/systemd/linger/$u ] || ok=0; done; [ "$(stat -c "%U:%G %a" /opt/epics-iocs)" = "root:ioc 2775" ] || ok=0; [ $ok -eq 1 ] && echo "FIXTURES OK" || echo "FIXTURES FAIL"'
```

Required to continue:

- `opa` and `opb` belong to `ioc`;
- `obs` exists and does not belong to `ioc`;
- `usera` and `userb` have systemd linger enabled; and
- `/opt/epics-iocs` is `root:ioc` with mode `2775`.

### 3. Candidate tree and installed runner

Push the candidate with the shipped driver. It preserves `.git`, excludes the
source tree's ignored paths, and requires identical source and remote status.

```bash
bash gate/drivers/push.bash vmadmin@<host> <repo-root> '~/gitsrc'
```

Deploy the full system infrastructure from the pushed tree on both consumers:

```bash
set -o pipefail
ssh vmadmin@<host> 'cd ~/gitsrc/epics-ioc-runner && bin/run-setup-system-infra.bash --full 2>&1' | tee <full-setup-log>
sha256sum <full-setup-log>
```

Required to continue:

- source and remote `git status --porcelain` outputs agree;
- both remote repositories resolve to the candidate commit;
- both setup runs pass their verification summary; and
- each installed `ioc-runner -V` reports the candidate commit.

### 4. EPICS environment

Resolve one exact environment path on each consumer. Do not pass a glob to a
suite driver.

```bash
ssh vmadmin@<host> 'os="$(. /etc/os-release; echo "${ID}-${VERSION_ID}")"; ls -d /opt/epics/*/"${os}"/*/setEpicsEnv.bash'
```

When a direct shell command must source the environment under `set -u`, use:

```bash
set +u; if [ -z "${EPICS_BASE:-}" ]; then . <epics-env>; fi; set -u
```

## Gate Steps

Execute the following steps in order against one unchanged candidate commit.

### 1. Change-specific verification

Run each applicable Test Plan from `<release-register>` against the integrated
candidate tree. A Test Plan carried by a later Gate step is recorded against
that step and is not executed twice. A Test Plan that reads the completed Gate
record remains pending until that record is written.

### 2. Complete suite matrix

Run the shipped control-side driver from the candidate repository root:

```bash
DEBIAN_HOST="vmadmin@<debian-host>"
DEBIAN_EPICS_ENV="<absolute-debian-epics-env>"
ROCKY_HOST="vmadmin@<rocky-host>"
ROCKY_EPICS_ENV="<absolute-rocky-epics-env>"
bash gate/drivers/control/suites.bash "$DEBIAN_HOST" "$DEBIAN_EPICS_ENV" "$ROCKY_HOST" "$ROCKY_EPICS_ENV"
```

The driver runs six suites on each host:

1. error handling, source;
2. source regression, source;
3. local lifecycle, source;
4. local lifecycle, installed;
5. system infrastructure, installed state; and
6. system lifecycle, installed.

Required to continue:

- both `VERDICT host=... rc=0` lines are present;
- each host verdict file ends with `SUITES OK`;
- each host contains six complete suite records;
- no result is `FAIL`, `SKIP`, or `SCRIPT_ERROR`;
- every `NA` is an examined OS applicability result;
- remote source and installed runner identities match the candidate commit; and
- the final line reports `GATE SUITES PASS`.

`CROSS_HOST rc=1` means the normalized host results differ. It is nonfatal only
after every line in `cross-host.diff` is confirmed as an expected applicability
difference. A comparison status greater than 1 is a Gate failure.

#### Check-identity pin

The driver holds a SHA-256 over the full check-identity list: the suite, scope,
runner, step, check id, category, kind, and method of every check the matrix
ran. A mismatch reports `SUITES FAIL identity_sha256=<actual> expected=<pinned>`
and is a Gate failure by default, because the check list changed.

When the candidate changed that list on purpose, by adding, removing, or
renaming a check, repin the driver instead of reading the mismatch as a
regression:

1. Confirm the run is otherwise clean. Never repin from a run that carries a
   `FAIL`, `SKIP`, or `SCRIPT_ERROR`.
2. Set `EXPECTED_IDENTITY_SHA256` in `gate/drivers/control/suites.bash` to the
   `identity_sha256` value the run reported on stdout and in
   `<run-dir>/<host>.verdict`.
3. Commit the repin. Carry it in the same commit as the change that moved the
   list while that change is still uncommitted; once that change has landed,
   the repin is its own commit on top of it.
4. Treat the repin as a candidate tree change. Under Failure and Invalidation
   Rules it invalidates every completed Gate step, so restart the Gate at the
   new candidate commit. Rerunning step 2 alone confirms the pin but produces
   a Check result, not Gate evidence.

The pin is a contract that moves with the check list, like
`tests/reporting-counts.csv`. A stale pin fails every later Gate run for a
reason unrelated to the code under test.

### 3. root_squash deployment

After step 2, compose `P_nfs-sim` onto the same consumers. Follow the canonical
cloud-provision inventory runbook for each running VM and select
`iocrunner-nfs` as the generated inventory species. Then follow the
ansible-provision single-operator workflow for `op.nfs_sim.<vacuum>`. Do not
run the role directly and do not construct the export by hand.

Required operator result:

- the Rocky 8 and Debian 13 plays report no unreachable or failed host;
- the cloud-provision and ansible-provision commits are recorded; and
- each consumer provides `~vmadmin/gitsrc-nfs-sim` over an `nfs4` mount with
  `root_squash`.

If either operator run fails, the consumer pair is no longer a Gate pair.
Destroy and recreate both consumers, repeat all preconditions, and rerun step 2.

Verify the produced state:

```bash
ssh vmadmin@<host> 'ls -ld ~/gitsrc-nfs-sim; mount | grep "type nfs4"'
```

Push the candidate tree, including `.git`, to the NFS-backed parent:

```bash
bash gate/drivers/push.bash vmadmin@<host> <repo-root> '~/gitsrc-nfs-sim'
ssh vmadmin@<host> 'cd ~/gitsrc-nfs-sim/epics-ioc-runner && pwd -P'
```

Call the resolved path `<abs-toplevel>`. Establish the barrier before testing a
deployment:

```bash
set -o pipefail
ssh vmadmin@<host> "sudo -n stat -c %U <abs-toplevel>/bin >/dev/null 2>&1; a=\$?; stat -c %U <abs-toplevel>/bin >/dev/null 2>&1; b=\$?; sudo -n stat -c %U /usr/local/bin >/dev/null 2>&1; c=\$?; [ \$a -ne 0 ] && [ \$b -eq 0 ] && [ \$c -eq 0 ] && echo 'SQUASH REPRODUCED' || echo \"NOT REPRODUCED (root=\$a owner=\$b control=\$c)\"" | tee <barrier-log>
sha256sum <barrier-log>
```

Required to continue: root is denied under the NFS-backed tree, the owning user
can read it, and root can read the local control path.

The check above establishes traversal. The suites fail on `source`, one syscall
layer below it, so confirm that layer with the real reporting library the suites
read. Root sources it once by a relative path from the inherited working
directory and once by an absolute path, and the run is read by the permission
denial rather than by the library's own exit status:

```bash
set -o pipefail
ssh vmadmin@<host> "cd <abs-toplevel> || exit 1; rel=\$(sudo -n bash -c '. ./tests/lib/test-reporting.bash' 2>&1 >/dev/null | grep -c 'Permission denied'); abs=\$(sudo -n bash -c '. <abs-toplevel>/tests/lib/test-reporting.bash' 2>&1 >/dev/null | grep -c 'Permission denied'); [ \$rel -eq 0 ] && [ \$abs -ge 1 ] && echo 'SOURCE CONTROL OK' || echo \"SOURCE CONTROL FAILED (relative=\$rel absolute=\$abs)\"" | tee <source-control-log>
sha256sum <source-control-log>
```

Required to continue: the relative source raises no permission denial and the
absolute source raises one, which the command reports as `SOURCE CONTROL OK`.
A source that succeeds in both forms — reported as `SOURCE CONTROL FAILED` with
`absolute=0` — means the export is not squashing root as this Gate requires,
and the suite evidence below would be meaningless. A log carrying neither
verdict line means the working directory was never reached and the control did
not run; that is not a pass.

Define the setup-owned configuration fingerprint on the control host. It
records content and owner-mode metadata, and deliberately excludes the runner
binary that each entry point is expected to replace:

```bash
config_fingerprint() {
    ssh vmadmin@<host> 'sudo -n stat -c "%U:%G %a %n" /etc/sudoers /etc/sudoers.d/10-epics-ioc /etc/systemd/system/epics-@.service /etc/logrotate.d/procserv /etc/bash_completion.d/ioc-runner; sudo -n sha256sum /etc/sudoers /etc/sudoers.d/10-epics-ioc /etc/systemd/system/epics-@.service /etc/logrotate.d/procserv /etc/bash_completion.d/ioc-runner'
}
config_fingerprint | tee <config-baseline>
```

Run all three deployment entry points as the invoking user. Use one control-host
log per entry point. Record the installed stamp immediately before the first
deployment, then read it and the configuration fingerprint again after each
deployment.

```bash
set -o pipefail
ssh vmadmin@<host> 'stat -c "%y" /usr/local/bin/ioc-runner; /usr/local/bin/ioc-runner -V' | tee <stamp-baseline>
ssh vmadmin@<host> 'cd <abs-toplevel> && bin/run-setup-system-infra.bash 2>&1' | tee <setup-log>
ssh vmadmin@<host> 'stat -c "%y" /usr/local/bin/ioc-runner; /usr/local/bin/ioc-runner -V' | tee <stamp-after-setup>
config_fingerprint | tee <config-after-setup>
ssh vmadmin@<host> 'cd <abs-toplevel> && make install 2>&1' | tee <install-log>
ssh vmadmin@<host> 'stat -c "%y" /usr/local/bin/ioc-runner; /usr/local/bin/ioc-runner -V' | tee <stamp-after-install>
config_fingerprint | tee <config-after-install>
ssh vmadmin@<host> 'cd <abs-toplevel> && make setup 2>&1' | tee <make-setup-log>
ssh vmadmin@<host> 'stat -c "%y" /usr/local/bin/ioc-runner; /usr/local/bin/ioc-runner -V' | tee <stamp-after-make-setup>
config_fingerprint | tee <config-after-make-setup>
```

Read the three control-host logs once, after all three deployments:

```bash
grep -icE 'layout|not a git|unknown' <setup-log> <install-log> <make-setup-log>
```

Each printed count must be `0`. `grep -c` returns status 1 when it finds zero
matches, so status 1 is expected here; read the counts rather than treating
that status as a failed Gate command. A missing or unreadable log is a failure.

Compare every post-deployment configuration fingerprint with the baseline and
hash all retained deployment, fingerprint, and stamp records:

```bash
cmp -s <config-baseline> <config-after-setup>
cmp -s <config-baseline> <config-after-install>
cmp -s <config-baseline> <config-after-make-setup>
sha256sum <setup-log> <install-log> <make-setup-log>
sha256sum <config-baseline> <config-after-setup> <config-after-install> <config-after-make-setup>
sha256sum <stamp-baseline> <stamp-after-setup> <stamp-after-install> <stamp-after-make-setup>
```

Required result for each entry point:

- the deployment finishes without a password prompt or error;
- the installed file modification time moves;
- `ioc-runner -V` reports the candidate commit and commit date; and
- no output reports a missing Git checkout, missing tracked content, invalid
  layout, unavailable metadata, or an `unknown` stamp.

### 4. Multi-user verification

Confirm that the installed runner still reports the candidate commit, then run
the complete driver on both `iocrunner-nfs` consumers:

```bash
ssh vmadmin@<host> '/usr/local/bin/ioc-runner -V'
bash gate/drivers/control/run-all.bash vmadmin@<host>
```

Required result: each host reports Pass for every printed `P-*` prerequisite
verdict, Pass for every scenario in the Multi-User Contract below, and a final
`VERDICT RUN PASS`. Prerequisite verdicts, including `P-LEFTOVERS`, are not
included in the fourteen-scenario tally and must be reviewed separately.

### 5. root_squash suite execution

Step 2 runs the suite matrix from a path root can traverse. A suite that
resolves its own libraries by an absolute path passes there and fails on an
NFS `root_squash` home, so that class reaches production without the following
step. Run it last: the system lifecycle suite creates and removes IOCs, and
placing it before step 4 disturbs that step's `P-FRESH` and `P-LEFTOVERS`
prerequisites.

This step covers one axis — whether a suite that root must read from the
candidate tree can be invoked at all from a squashed export. Only the installed
`--system` suites belong here. The local lifecycle and error-handling suites run
as the invoking user, and the container lifecycle suite runs as root inside a
container image rather than from this tree, so none of them is affected by
`root_squash` and none is repeated here.

Two paths are out of scope because `root_squash` blocks them by design, not
because they are untested. Source-mode `--system` would `execve` a user-owned
source binary from the squashed tree. The source-regression suite reads and
executes `bin/` as root as part of its own contract, so its steps covering the
setup invocation, the git-context and version-stamp declarations, the
root-to-invoking-user injection boundary, and the SELinux deployment boundary
cannot run from a squashed export; a run there fails those steps on the export,
not on the code.
This leaves one gap the Gate does not close: the source-regression suite's own
library-source path is exercised only from a root-readable tree. The class this
step exists for — a suite that cannot start at all under `root_squash` — is
covered for the two `--system` suites, which are the ones production runs in
place.

Confirm the installed runner still reports the candidate commit, then resolve
the environment path as in precondition 4 and run the installed `--system`
suites on each consumer from `<abs-toplevel>`, one control-host log per host:

```bash
set -o pipefail
ssh vmadmin@<host> '/usr/local/bin/ioc-runner -V'
ssh vmadmin@<host> "cd <abs-toplevel> || exit 1; set +u; if [ -z \"\${EPICS_BASE:-}\" ]; then . <epics-env>; fi; set -u; bash tests/run-all-tests.bash --system --installed 2>&1" | tee <nfs-system-log>; printf 'SYSTEM_RC=%s\n' "$?" | tee -a <nfs-system-log>
sha256sum <nfs-system-log>
```

Required result on each host:

- the installed runner reports the candidate commit;
- the run ends with `ALL SELECTED TEST SUITES COMPLETED SUCCESSFULLY.` and the
  `SYSTEM_RC` line appended to the log is `0`;
- no result is `FAIL`, `SKIP`, or `SCRIPT_ERROR`, and every `NA` is an examined
  OS applicability result, which the run reports on its `Not applicable` line;
  and
- no permission denial names a suite library or dispatcher path.

Read that last condition with the check below rather than by eye. A passing run
carries benign denials of its own: the test IOC reports
`ERROR st.cmd line <n>: Can't open '<record>': Permission denied` for records it
cannot open, and those lines appear on a run that ends successfully.

```bash
grep -nE 'Permission denied' <nfs-system-log> | grep -vE 'st\.cmd line'
```

Required result: no output. A remaining denial, in particular one naming
`tests/lib/` or `run-all-tests.bash`, is the defect this step exists to catch
and not an environment fault — the barrier and its source control above already
established that the export squashes root and that a relative read succeeds.

## Evidence

Record one row per platform for image publication, one row per host for
consumer acceptance, and one row per suite result.

The suite-result table below covers step 2's matrix, whose driver emits those
fields. Step 5 is run by hand and emits no such record, so it is recorded by its
logs, digests, completion lines, and `SYSTEM_RC` values in the list after the
tables, not as rows in that table.

| Platform | Bake Date | Baseline Ref | Image | Image SHA-256 | Creation Record | Manifest Sidecar | Manifest SHA-256 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| | | | | | | | |

| Host | Baseline Commit/State/Tag | Host Verdict | Acceptance Evidence Path | Acceptance Evidence SHA-256 |
| --- | --- | --- | --- | --- |
| | | | | |

| Host | Suite | Scope | Runner | PASS | FAIL | SKIP | NA | SCRIPT_ERROR | State | Elapsed |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| | | | | | | | | | | |

Also record:

- candidate branch, commit, and status;
- release-register repository, path, commit, and status;
- cloud-provision and ansible-provision commits and status;
- image-pair names and SHA-256 digests, creation records, and manifest-sidecar
  names and SHA-256 digests;
- Golden acceptance results;
- both full-setup logs and SHA-256 digests;
- suite evidence directory and `cross-host.diff`;
- both `P_nfs-sim` play recaps;
- both `root_squash` barrier logs and SHA-256 digests;
- both `root_squash` source-control logs and SHA-256 digests;
- three deployment logs and their SHA-256 digests, the baseline stamp log,
  three post-deployment stamp logs, and all four stamp-log SHA-256 digests per
  host;
- the baseline and three post-deployment configuration fingerprints, their
  SHA-256 digests, and all three successful comparisons; and
- both complete multi-user `run-all.log` files and SHA-256 digests, including
  every printed `P-*` verdict, all fourteen scenario verdicts, and the final
  `VERDICT RUN`; and
- both `root_squash` `--system --installed` suite logs, one per host, with their
  SHA-256 digests, their completion lines, and their appended `SYSTEM_RC`
  values.

Step 2's suite evidence describes the `iocrunner` state before `P_nfs-sim`. The
`root_squash` evidence — the barrier, the source control, the deployment entry
points, and step 5's suite logs — and the multi-user evidence describe the same
consumers after they reach `iocrunner-nfs`.

## Failure and Invalidation Rules

- A candidate tree change invalidates every completed Gate step. Restart at the
  final candidate commit.
- A commit that changes only the `<release-register>` document is the one
  exception, and only while it changes neither a baseline ref the register
  records nor a Test Plan step 1 executes. The register is where a completed
  Gate's result is written, so treating that write as a candidate change would
  leave a Gate unreachable: every run would be invalidated by the act of
  recording it. The register is still a Gate input through step 1, so a change
  that moves such a Test Plan, or a baseline ref where the register carries one,
  is an ordinary candidate change under the rule above.

  Call the commit the Gate steps ran against `<gated-commit>` and the current
  branch tip `<current-tip>`. The first command settles the exception on its
  own; the second is read for the two things named above, and a register that
  records no baseline ref has nothing to compare there:

  ```bash
  git -C <repo> diff --name-only <gated-commit> <current-tip>
  git -C <repo> diff <gated-commit> <current-tip> -- <release-register>
  ```

  Required result: the first command prints the register's path and nothing
  else, and the second shows no change to a recorded baseline ref or to a Test
  Plan step 1 executes. A Test Plan the Gate does not execute may be added or
  recorded freely — a plan verified after the release merge, for instance. Gate
  Identity already records the register's commit and the runner tree's commit;
  under this exception the two may differ, and both belong in the evidence.
- A supplier change between image builds invalidates the image pair.
- A consumer change before Golden acceptance requires a fresh consumer.
- A failed `P_nfs-sim` run requires a fresh pair and a new step 2 result.
- A failed step 5 is a defect in the candidate, not in the consumer pair. The
  pair stays usable; fixing the defect changes the candidate tree, and the
  first rule above then restarts the Gate at the new candidate commit.
- A missing or malformed evidence record is a Gate failure.
- A condition that cannot be induced is recorded as an unverified gap, never as
  Pass.

## Multi-User Contract

### Principals and accounts

| Account | Mode | `ioc` Group | Linger | Role |
| --- | --- | :-: | :-: | --- |
| `opa` | system | yes | no | operator |
| `opb` | system | yes | no | second operator |
| `obs` | system | no | no | observer negative control |
| `usera` | local | no | yes | local user A |
| `userb` | local | no | yes | local user B |

`ioc-srv` is the non-login service account. System state changes require an
operator in `ioc`; local mode remains per-user.

### Local-mode scenarios

| ID | Scenario | Expected Result |
| --- | --- | --- |
| L1 | Session isolation | Both users may use the same IOC name, and each listing shows only the invoker's IOC. |
| L2 | Cross-user interference | A peer cannot attach to or stop another user's IOC. |
| L3 | Log isolation | A peer cannot stat or read another user's log; the owner observes mode `0640`. |

### System-mode scenarios

| ID | Scenario | Expected Result |
| --- | --- | --- |
| S1 | Shared management | Either operator can query, stop, restart, and observe one shared IOC. |
| S2 | Configuration collaboration | Both operators can update the shared `root:ioc` configuration. |
| S3 | Concurrency | Concurrent operations on separate IOCs succeed without failed units or crossed state. |
| S4 | Removal while attached | Removing an IOC ends the peer console and leaves no socket. |
| S5 | Shared log read | A second operator reads the service-account log without sudo. |
| S6 | Observer boundary | Read-only queries succeed; state changes are denied before reaching a privileged mutation. |
| S7 | Disable, manual run, and re-enable | Operators observe the runtime transition while configuration remains unchanged. |
| S8 | Crash-pattern detection | A configured distinctive token produces the documented post-initialization warning. |
| S9 | Working-directory conformance | An unwritable directory warns; a parent-reference path is rejected without override. |
| S10 | Console access | Operators attach and monitor; observers and non-root inspect callers are denied at their defined gates. |
| S11 | Sudo-version boundary | The emitted sudoers branch produces its documented malformed-name result. |

### Driver contract

`gate/drivers/control/run-all.bash` owns staging, principal changes, scenario
order, capture normalization, and verdict counting. Do not reproduce those
operations by hand for Gate evidence.

Every scenario prints:

```
VERDICT <id> <PASS|FAIL> <detail>
```

The final driver verdict must account for all fourteen scenario IDs. A missing
verdict is Fail, not an omitted result.

Between Check-grade diagnostic reruns, use the shipped cleanup driver:

```bash
bash gate/drivers/control/cleanup.bash vmadmin@<host>
```

The runner removes IOC registrations but does not remove payload directories.
Read the payload paths printed by the cleanup driver, then remove only the
named IOC directories. Never use a glob over a parent directory:

```bash
ssh vmadmin@<host> 'sudo -n rm -rf /opt/epics-iocs/<name>'
ssh vmadmin@<host> 'sudo -n rm -rf /home/<user>/iocBoot/<name>'
```

Confirm the resulting state with the shipped reader:

```bash
bash gate/drivers/control/leftovers.bash vmadmin@<host>
```

Required result: `P-LEFTOVERS PASS`. It requires successful reads and empty
system, local, and payload state.

Gate-grade evidence always comes from the complete driver on the fresh pair,
not from individual scenario reruns.

## Release Boundary

This runbook produces Gate evidence. It does not authorize or perform commits,
pushes, version changes, tags, GitHub mutations, or release publication.

| Authority | Owned Action |
| --- | --- |
| `milestone-tracking` | Milestone plan, status, verification record, and closure |
| `release-cycle` | Release ordering, version changes, integrated verification, and publication sequence |
| `git-workflow` | Commit, push, issue, tag, and release mutations |
