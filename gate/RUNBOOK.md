# Release Cycle Runbook

Operational procedure for verifying an `epics-ioc-runner` tree on the golden
images. The permission model lives in
[`../docs/PERMISSION_MODEL.md`](../docs/PERMISSION_MODEL.md) and the suite
contract in [`../tests/README.md`](../tests/README.md); this page
covers what to run, in what order, with which commands, and how to read the
result.

This runbook is standing. It is not cleared when a release cycle opens, it
names no version, and it applies to any tree. The strictest application is the
run immediately before a release, but the procedure is the same on a release
branch, on the default branch, or on any single commit.

## What is under test

Record these four facts before anything else. Every later result is meaningless
without them.

```bash
git -C <repo> rev-parse --abbrev-ref HEAD
git -C <repo> rev-parse --short HEAD
git -C <repo> status --porcelain | wc -l
ssh vmadmin@<host> '/usr/local/bin/ioc-runner -V'
```

Branch, commit, count of uncommitted paths, and the deployed identity on each
host — the last one read again after the deploy step, since that is when it
changes.

Record the same three facts for each supplying checkout, not only for the tree
under test. The bake reads them at the moment it runs, and a supplier updated
between one platform's bake and the next produces two goldens built from
different code — visible only afterwards, in their manifests:

```bash
for r in <cloud-provision> <ansible-provision>; do git -C "$r" rev-parse --abbrev-ref HEAD; git -C "$r" rev-parse --short HEAD; git -C "$r" status --porcelain | wc -l; done
```

Two separate `rev-parse` calls, not one: `--abbrev-ref` applies to every ref
after it, so a combined call prints the branch name twice and never the commit
— the one value this check exists to capture.

Read them again when the bake finishes and confirm they did not move. If they
did, the goldens are not a matched pair; rebake rather than reason about which
half is authoritative.

`IMAGE_DIR` is used from the first precondition onward. It is a make variable
in the supplying checkout, so reading it does not set it — read it and export
it now, expanding `$(HOME)` yourself:

```bash
grep -rn IMAGE_DIR <cloud-provision>/configure/CONFIG_SITE*
export IMAGE_DIR=<the printed value, with $(HOME) expanded>
```

A site may carry a local override file beside the shared one; the wildcard
catches it, and the last assignment read is the one that applies.

The consumers are libvirt domains on the system connection. Set the URI too, or
`virsh` shows an empty list and every domain check silently answers about
nothing:

```bash
export LIBVIRT_DEFAULT_URI=qemu:///system
```

`<host>` throughout this document is one of the two consumers, at the fixed
addresses their targets reserve:

| Platform | Consumer target | Address |
|---|---|---|
| Rocky 8 | `rocky8-iocrunner.server` | `192.168.122.150` |
| Debian 13 | `debian13-iocrunner.server` | `192.168.122.50` |

The deployed identity and the commit can differ legitimately: a tree with
uncommitted documentation edits deploys a `-dirty` stamp. Record both rather
than reconciling them.

## Two grades of result

One procedure, two grades. The grade follows the conditions of the run, not the
name of the branch.

| Grade | Conditions | What the result may be used for |
|---|---|---|
| Gate | Freshly baked goldens, freshly created consumer VMs, and every step below executed in this run | Release evidence |
| Check | Anything less — a reused test bed, a subset of steps, a single suite | Itself only |

A Check result is never cited as Gate evidence. Citing an earlier run in place
of executing a step produces neither grade.

## Preconditions

### Freshly baked goldens

Everything in this section runs from the `cloud-provision` checkout. That
checkout, like every placeholder path in this document, resolves from the tree
under test: `<repo>` is this repository's root, `<repo-parent>` is its parent
directory, and the sibling checkouts live beside it —

```bash
git -C <repo> rev-parse --show-toplevel
ls "$(dirname "$(git -C <repo> rev-parse --show-toplevel)")" | grep -E 'cloud-provision|ansible-provision'
```

**Destroy the consumer VMs first.** The bake scans defined domains and refuses
to publish while any disk resolves through the target golden as its backing
file, which is exactly what a running consumer does. A bake started with the
consumers still present stops before publication.

```bash
make rocky8-iocrunner.server.clean
make debian13-iocrunner.server.clean
```

Then check that the previous goldens still belong to the account that will
bake. Creating a consumer hands the whole backing chain to the hypervisor's
account, and removing that consumer by force does not hand it back, so this is
the normal state after any previous cycle:

```bash
ls -l ${IMAGE_DIR}/iocrunner-*.qcow2
```

Required before baking: both are owned by the baking account. Foreign ownership
is not a warning — it stops the bake at its publish step, and the stop is
silent. With the terminal the configuration step requires, the publish waits
on an overwrite question nobody can answer; observed hanging there with no
error until killed. Do not read a long-quiet Step 9 as slow work.

Two repairs, depending on what you have:

```bash
sudo chown "$(id -un):$(id -gn)" ${IMAGE_DIR}/iocrunner-rocky8.qcow2 ${IMAGE_DIR}/iocrunner-debian13.qcow2
```

```bash
rm -f ${IMAGE_DIR}/iocrunner-rocky8.qcow2 ${IMAGE_DIR}/iocrunner-debian13.qcow2
ls -l ${IMAGE_DIR}/iocrunner-*.qcow2*
```

The first is the direct repair and needs a privilege the bake does not have.

The second needs no privilege at all. Removal is governed by write permission
on the DIRECTORY, not on the file, and the image directory belongs to the
baking account — so it can unlink a golden the hypervisor took ownership of,
even though it cannot change that file's owner. Deleting the previous golden is
safe here for the same reason the bake can be re-run at all: the bake is about
to replace it, it publishes only after its own validation passes, and a golden
that is still needed is one no bake should be starting over.

Required after either repair: the listing shows no `iocrunner-*.qcow2` owned by
another account. Check it — do not infer it from an exit code. `rm -f` and
`mv -n` both report success when they did nothing.

The trailing wildcard in that listing also matches `iocrunner-*.qcow2.prevowner`
and its dated variants. Those are whole previous goldens, renamed aside rather
than removed by an earlier form of this same repair — foreign-owned and several
gigabytes each, and nothing in the bake reads them. The bake writes the exact
names `iocrunner-<os>.qcow2`, its temporary, and its sidecar, and its in-use
scan globs `*.qcow2`, which no `.prevowner` name matches. So they neither
satisfy this check nor stop it: read past them. Whether to reclaim the space is
the operator's call and no part of the gate.

**If the bake is already hung there**, it will not recover: the prompt is on a
terminal that cannot be written to from outside. End it, clean up per the bake
runbook's mid-way failure section, apply one of the two repairs, and start the
bake again.

This condition returns every cycle, because creating a consumer hands the
golden to the hypervisor's account and destroying it by force does not hand it
back. Until the supplying side separates the published archive from the images
consumers back onto, this check is a permanent step, not a one-time repair.

Then bake. These three are alternatives, not a sequence — the first does both
goldens, the other two do one platform each:

```bash
make bake
make bake.rocky8
make bake.debian13
```

A bake driven from a script rather than typed at a terminal needs a terminal
anyway. Backgrounded from an automated session it inherits channels that do not
wait, and the configuration step refuses to start on them — the bake stops at
its fourth step with a complaint about its input and output, having done
nothing wrong. Give it one:

```bash
setsid script -qec "make bake" /dev/null < /dev/null > <log> 2>&1 &
```

Bake failure handling, proxy handling, and slow-boot diagnosis belong to
`cloud-provision/docs/RUNBOOK_BAKE.md`. Do not diagnose a bake from here. Two
of its rules matter enough to name: a slow boot is not a failure while the
package manager is still working, and a bake that stopped leaves the build VM
running and half-provisioned, so a clean retry destroys it first.

### Freshly created consumer VMs

Create them from the images just published. Never reuse a test bed: it
accumulates state — a stale system user, a previously installed runner,
leftover accounts — and produces failures the tree under test does not have.

```bash
make rocky8-iocrunner.server
make debian13-iocrunner.server
```

Each target ends by printing `READY`; anything else is an incomplete boot,
handled by the bake runbook's slow-boot section, not here.

Recreated VMs reuse the deterministic addresses and present new host keys.
Clear the stale entries before the first connection:

```bash
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.122.150
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.122.50
```

### Golden acceptance

**Run this before anything touches the golden — before the deploy, and before
the tree under test is pushed anywhere.** The validator reads two things the
later steps overwrite:

- the installed runner's short hash, against the `app_ioc_runner` commit in the
  manifest. Once the deploy has replaced the runner, the check reports
  `installed ioc-runner identity mismatch` by construction.
- the retained checkout the bake left at `~/gitsrc/epics-ioc-runner`, against
  the repository the manifest records. The push in "The tree on each host"
  replaces exactly that directory, and the check then reports
  `retained repository mismatch`. A remote address written in the `git@` form
  where the manifest holds the `https://` form is enough on its own.

Neither red says anything about the bake. A VM that has been deployed to, or
pushed to, cannot be accepted afterwards — only rebuilt from the golden.

The acceptance procedure belongs to `cloud-provision/docs/RUNBOOK_BAKE.md`,
"Fresh consumer SSH host keys" — that section owns the command contract, and
these lines are its invocation. When it changes there, take the change; do not
maintain a second copy here.

Run them from the `cloud-provision` checkout and let the output print to the
terminal — do not wrap them in local redirection. `sudo -n` throughout: none of
these commands is in the runner's password-free policy, so a plain `sudo` that
decides to prompt has nowhere to ask and stalls until something times out.

Rocky 8 consumer:

```bash
ssh vmadmin@192.168.122.150 "sudo -n stat -c '%U:%G %a %n' /etc/iocrunner-bake.manifest"
ssh vmadmin@192.168.122.150 "sudo -n sha256sum /etc/iocrunner-bake.manifest"
ssh vmadmin@192.168.122.150 "sudo -n sed -n '1,80p' /etc/iocrunner-bake.manifest"
scp bin/validate_iocrunner_bake.bash vmadmin@192.168.122.150:/tmp/validate_iocrunner_bake.bash
ssh vmadmin@192.168.122.150 "sudo -n /bin/bash -p /tmp/validate_iocrunner_bake.bash"
```

Debian 13 consumer:

```bash
ssh vmadmin@192.168.122.50 "sudo -n stat -c '%U:%G %a %n' /etc/iocrunner-bake.manifest"
ssh vmadmin@192.168.122.50 "sudo -n sha256sum /etc/iocrunner-bake.manifest"
ssh vmadmin@192.168.122.50 "sudo -n sed -n '1,80p' /etc/iocrunner-bake.manifest"
scp bin/validate_iocrunner_bake.bash vmadmin@192.168.122.50:/tmp/validate_iocrunner_bake.bash
ssh vmadmin@192.168.122.50 "sudo -n /bin/bash -p /tmp/validate_iocrunner_bake.bash"
```

Compare each remote manifest hash against its sidecar on the control host,
using the `IMAGE_DIR` exported at the start:

```bash
sha256sum ${IMAGE_DIR}/iocrunner-rocky8.qcow2.manifest
sha256sum ${IMAGE_DIR}/iocrunner-debian13.qcow2.manifest
```

Also read the runner the golden already carries, before anything replaces it:

```bash
ssh vmadmin@<host> '/usr/local/bin/ioc-runner -V'
```

Read the bake date and the baseline the golden carries straight out of the
manifest rather than from the eighty-line listing:

```bash
ssh vmadmin@<host> "sudo -n grep -E '^(bake_date|os_type|app_ioc_runner)' /etc/iocrunner-bake.manifest"
```

The validator accepts a dirty application record as long as its tag is `-`, but
the bake runbook's rule is that dirty suffixes are for preliminary bakes and
final acceptance requires clean identities. Count them yourself:

```bash
ssh vmadmin@<host> "sudo -n grep -c 'state=dirty' /etc/iocrunner-bake.manifest"
```

`grep -c` exits nonzero when the count is `0` — which is the wanted result
here. Judge by the printed number, not the exit code, or a driver that watches
exit codes reads the pass as a failure.

Required to continue: the manifest is `root:root 644`, the remote hash equals
the sidecar hash, the validator reports the bake valid, and the dirty count is
`0`.

The `app_ioc_runner` record names the runner the golden already carries — the
starting state every later step deploys over. Record its `commit`, `state`, and
`tag` beside the suite results. A `state=clean-untagged` with `tag=-` means the
bake took whatever the default branch happened to be, which is a fact about the
golden, not about the tree under test.

### Fixture accounts

The multi-user accounts are baked in. Verify them; do not create them. An
account added by hand on a running VM invalidates the fixture, because the
scenario then proves nothing about the golden.

```bash
ssh vmadmin@<host> "getent group ioc; getent passwd obs; ls /var/lib/systemd/linger"
ssh vmadmin@<host> "stat -c '%U:%G %a %n' /opt/epics-iocs"
```

Or assert all of it at once:

```bash
ssh vmadmin@<host> 'ok=1; for u in opa opb; do getent group ioc | grep -qw "$u" || ok=0; done; id -nG obs | grep -qw ioc && ok=0; for u in usera userb; do [ -e /var/lib/systemd/linger/$u ] || ok=0; done; [ "$(stat -c "%U:%G %a" /opt/epics-iocs)" = "root:ioc 2775" ] || ok=0; [ $ok -eq 1 ] && echo "FIXTURES OK" || echo "FIXTURES FAIL"'
```

Required to continue: `ioc` includes `opa` and `opb`, `obs` exists and is not
in `ioc`, the linger directory lists `usera` and `userb`, and `/opt/epics-iocs`
exists as `root:ioc` with the setgid bit and group write. The account that ran
the setup also appears in `ioc` and is expected there. If any is missing, stop
— all of it comes from the bake, not from this run. The accounts belong to the
`test_users` role in `ansible-provision` and the shared directory to its
`app_ioc_runner` role; the setup script does not create either, so no amount of
re-running it here will repair them.

An operator who creates the accounts by hand at this point has not repaired
anything: the scenarios then prove something about the hand-built state rather
than about the golden.

### The tree on each host

Push the tree with its `.git` directory. The system infrastructure suite reads
the version stamp a real checkout produces, so a `--exclude=.git` push stamps
`unknown` and fails an assertion for a reason unrelated to the code under test.

```bash
ssh vmadmin@192.168.122.150 'mkdir -p ~/gitsrc && rm -rf ~/gitsrc/epics-ioc-runner'
tar -C <repo-parent> -cf - epics-ioc-runner | ssh vmadmin@192.168.122.150 'tar -C ~/gitsrc -xf -'
```

Then deploy. `--full` is required: with no argument the setup script updates
only the command wrapper and skips the log directory, the sudoers policy, and
the unit template.

```bash
ssh vmadmin@192.168.122.150 'cd ~/gitsrc/epics-ioc-runner && sudo -nE bash bin/setup-system-infra.bash --full'
```

Repeat both for `192.168.122.50`.

### The EPICS environment

On one golden the environment is loaded from the profile; on the other it is
not, and there a lifecycle suite exits before its first step with
`ERROR: The EPICS_BASE environment variable is not set.` Resolve the path and
source it in every command that runs a suite.

Never glob across the tree: a golden carries one tree per OS under
`/opt/epics/<env-version>/<os>/<base-version>/setEpicsEnv.bash`, and a bare
glob picks the alphabetically first, which is the wrong OS on Rocky. Derive the
OS directory from the host itself:

```bash
ssh vmadmin@<host> 'os="$(. /etc/os-release; echo "${ID}-${VERSION_ID}")"; ls -d /opt/epics/*/"${os}"/*/setEpicsEnv.bash'
```

Call the result `<epics-env>` below. The line that sources it carries two
separate protections, and a driver that keeps only one still fails. Guard the
test with `${EPICS_BASE:-}`, never `$EPICS_BASE`: the test reads the variable it
is asking about, so under `set -u` the bare form aborts the driver at the test
itself, before it reaches the source. Wrap the source in `set +u` and `set -u`
for a different reason — a variable read inside the environment script — which
"Traps that cost a run" below covers.

```bash
set +u; if [ -z "${EPICS_BASE:-}" ]; then . <epics-env>; fi; set -u
```

## Gate steps

Execute in this order.

### 1. The cycle's own change-specific checks

Re-run every change-specific verification the cycle's work defined, against
this tree. This is the first state in which all of the cycle's changes coexist;
each was previously verified against a tree that had only its own change.

They are recorded in the release line's own register, `docs/milestone.md`, one
Test Plan per work item — that document is where to find them, and a released
line keeps its copy at its tag (`git show <tag>:docs/milestone.md`). Executing
them is this step; owning them is not this runbook's business.

Not every row is executable here, and the three kinds part cleanly.

**A row whose method is "run this runbook"** is skipped. A verification-only
cycle can define its work as the gate itself, and re-running the gate inside
its own first step would not terminate. Record it as satisfied by this run.

**A row naming one gate step** — the `root_squash` path, the suites, the
multi-user scenarios — is satisfied by that step when it runs below. Do not run
it twice; note which step carried it.

**A row that reads this run's own record** cannot be executed from inside the
run, because the record does not exist until the run ends and this step is not
where records are written. Carry it out of the gate: leave it pending, and
gather the values it will need while they are in front of you — the baked
baseline, the bake dates, the deployed identity. Whoever writes the gate record
closes the row then. A row like this is not a failure and not a skip; it
belongs to the writing, not to the running.

Execute everything else.

### 2. The four suites, both modes, both goldens

The standalone static and behavioral suite needs no privileges and no EPICS
environment:

```bash
ssh vmadmin@<host> 'cd ~/gitsrc/epics-ioc-runner && bash tests/test-error-handling.bash'
```

The local lifecycle runs as the invoking user, once against the source tree and
once against the deployed binary. Both need the EPICS environment:

```bash
ssh vmadmin@<host> 'cd ~/gitsrc/epics-ioc-runner && . <epics-env> && IOC_RUNNER_TEST_MODE=source bash tests/test-local-lifecycle.bash'
ssh vmadmin@<host> 'cd ~/gitsrc/epics-ioc-runner && . <epics-env> && IOC_RUNNER_TEST_MODE=installed bash tests/test-local-lifecycle.bash'
```

The system lifecycle runs against the deployed binary. On a host where the
privileged account cannot execute a user-owned binary out of a private home —
an NFS `root_squash` home, among others — source mode cannot run at all, and
the mode is not a preference but the only one the suite contract allows
(`../tests/README.md`, "Runner Binary Selection"). The system infrastructure
suite has no binary axis at all: it reads deployed components rather than
running the runner, so the variable is inert there and is set only to keep one
form for both commands:

```bash
ssh vmadmin@<host> 'cd ~/gitsrc/epics-ioc-runner && . <epics-env> && IOC_RUNNER_TEST_MODE=installed sudo -nE bash tests/test-system-infra.bash'
ssh vmadmin@<host> 'cd ~/gitsrc/epics-ioc-runner && . <epics-env> && IOC_RUNNER_TEST_MODE=installed sudo -nE bash tests/test-system-lifecycle.bash'
```

`sudo -nE` is what carries both the environment and the mode across the
privilege boundary. Do not take that on trust: each lifecycle suite prints the
binary it resolved, with its `-V`, before its first step. Read that line back —
an unset mode silently defaults to the source tree, which is a green in the
wrong mode rather than an error:

```bash
ssh vmadmin@<host> "cat -v <log> | sed 's/\^\[\[[0-9;]*m//g' | grep -A1 'Runner under test'"
ssh vmadmin@<host> 'IOC_RUNNER_TEST_MODE=installed sudo -nE printenv IOC_RUNNER_TEST_MODE'
```

Only the three lifecycle blocks print that line — the standalone suite and the
system infrastructure suite resolve no binary, so expect three matches from a
five-block log, not five. Anchor on the phrase, not on a first match: a loose
pattern over a concatenated log returns an assertion line from an unrelated
block.

Capture all five runs of a host into ONE log on that host, appending after the
first — the verdict command below reads that single file, and keeping it beside
the run keeps the counts with the machine that produced them:

```bash
bash tests/<first-suite>.bash > /tmp/gate.log 2>&1
bash tests/<next-suite>.bash >> /tmp/gate.log 2>&1
```

Truncating instead of appending leaves one block behind, and the verdict then
prints `SUITES OK (1 blocks)` — a green for four suites that were thrown away.
The block count is what catches it, which is why it is part of the verdict.

Keep each suite's whole summary block, not its last few lines. The counts the
evidence table asks for sit above the closing banner, so a driver that tails a
fixed number of lines records a green with no numbers behind it — and a green
without its count cannot be compared against the next run. Pull the numbers out
of a captured log with:

```bash
cat -v <log> | sed 's/\^\[\[[0-9;]*m//g' | grep -E 'Total|Passed|Failed|Script Errors'
```

Skips do not appear in the summary block — the suites report them as prose
warnings in the body, so they need their own read:

```bash
cat -v <log> | sed 's/\^\[\[[0-9;]*m//g' | grep -iE 'SKIP|WARN'
```

Drive the system suites directly, not through `tests/run-all-tests.bash`, when
there is no terminal. The orchestrator caches credentials with `sudo -v` before
the system phases, and a host carrying both a password rule and NOPASSWD
entries prompts there even though every individual command would pass. The
orchestrator's local path has no such preflight and is safe to use.

Required to continue: every suite run on every host reports zero failures and
zero script errors, and the resolved binary line matches the mode intended.
Assert it from the captured log, with the guard that refuses to call an empty
log a pass:

```bash
ssh vmadmin@<host> "cat -v <log> | sed 's/\^\[\[[0-9;]*m//g' | awk '/Passed/{p++} /Failed/{f+=\$NF} /Script Errors/{e+=\$NF} END{ if (p==0) print \"NO SUMMARY FOUND\"; else print (f==0 && e==0) ? \"SUITES OK (\" p \" blocks)\" : \"SUITES FAIL f=\" f \" e=\" e }'"
```

Count the blocks against the number of suite runs you launched. A verdict that
reports fewer blocks than you ran is a truncated log, not a pass.

A skip is not a pass. The local lifecycle skips its monitor-isolation control
when the host has no persistent user journal, and skips other steps when an
optional tool is absent — so the same suite legitimately reports two different
totals, and a shorter green is not comparable with a longer one. Record the
skips beside the counts, and carry each one into "When a check cannot be
induced" rather than letting a total stand in for coverage.

The system infrastructure suite differs across the goldens the same way, for a
reason of its own: the sudoers branch a host's sudo version selects decides
which policy assertions apply, so the glob-branch host skips the regex-deny
probe and records that skip as an assertion in its own right. Its two totals are
as legitimate as the lifecycle's. Expect a per-host total from both suites and
compare a host against itself, never one golden's total against the other's.

The standalone suite prints its count in a shape of its own,
`Total Assertions : N (executed: N)`. The first number is the total the evidence
table's Passed / total column wants; the parenthetical is an integrity counter
for assertions that ran, and the two are meant to agree. When they disagree the
suite has already scored itself a failure for the mismatch, so the row to record
is still the first number and the verdict command still catches it.

### 3. The root_squash deployment path

Neither of the paths above deploys from a squashed mount, so this state is set
up explicitly or the behavior is never exercised.

The golden carries a simulated NFS export for exactly this: `~vmadmin/gitsrc-nfs-sim`,
a link into an `nfs4` mount with `root_squash`, provisioned by the
`ansible-provision` `nfs_sim` role at bake time. Verify it before using it, and
if it is absent stop — it is a bake property, not something to construct here:

```bash
ssh vmadmin@<host> 'ls -ld ~/gitsrc-nfs-sim; mount | grep "type nfs4"'
```

Place the **tree under test**, at the gate commit and including `.git`, on that
mount. Not any checkout: step 4 runs its scenarios against whatever binary this
step last deployed, so a different tree here silently gates the wrong code.

```bash
ssh vmadmin@<host> 'rm -rf ~/gitsrc-nfs-sim/epics-ioc-runner'
tar -C <repo-parent> -cf - epics-ioc-runner | ssh vmadmin@<host> 'tar -C ~/gitsrc-nfs-sim -xf -'
```

`<abs-toplevel>` below is that checkout's root through the mount's real path,
not through the home-directory link — the guard under test stats an absolute
path, and the link would hide the barrier. Read it once:

```bash
ssh vmadmin@<host> 'cd ~/gitsrc-nfs-sim/epics-ioc-runner && pwd -P'
```

Then prove the denial before trusting any result from this mount. Confirming
that the export exists proves nothing: a world-traversable tree reproduces no
bug. The reproduction needs root denied where the owner is allowed.

```bash
ssh vmadmin@<host> "sudo -n stat -c %U <abs-toplevel>/bin"
ssh vmadmin@<host> "stat -c %U <abs-toplevel>/bin"
ssh vmadmin@<host> "sudo -n stat -c %U /usr/local/bin"
```

Or as one verdict:

```bash
ssh vmadmin@<host> "sudo -n stat -c %U <abs-toplevel>/bin >/dev/null 2>&1; a=\$?; stat -c %U <abs-toplevel>/bin >/dev/null 2>&1; b=\$?; sudo -n stat -c %U /usr/local/bin >/dev/null 2>&1; c=\$?; [ \$a -ne 0 ] && [ \$b -eq 0 ] && [ \$c -eq 0 ] && echo 'SQUASH REPRODUCED' || echo \"NOT REPRODUCED (root=\$a owner=\$b control=\$c)\""
```

Required to continue: the first is denied, the second succeeds, and the third
succeeds. The third is the control — without it, a denial from a sudo policy
looks exactly like a denial from `root_squash`, and only one of those is the
condition being reproduced. The verdict prints the three codes when it fails,
so an owner-side failure (the tree is not on the mount) is not mistaken for a
missing barrier.

Then deploy from that mount through each documented entry point and read the
stamp the deploy produced. Run the make recipes as the invoking user — they
call `sudo` internally, and make running as root cannot read the Makefile
includes on a squashed mount:

Read the stamp after EACH entry point, not once at the end. With an unchanged
tree all three stamps are identical, so a single read cannot tell three
successful deploys from one deploy and two silent no-ops. Read the file's
modification time alongside it — that is what moves when a deploy actually
replaced the binary.

Inspect each deploy's output as it runs, in the same invocation that produced
it. The layout count below is folded in for exactly that reason: asking it
separately would run the entry point a second time — six deploys per pass
instead of three — and each extra deploy overwrites the state the stamp read
beside it has just described. `tee` keeps the deploy's own text, which the count
alone throws away; give each entry point its own log:

```bash
ssh vmadmin@<host> 'cd <abs-toplevel> && sudo -n bash bin/setup-system-infra.bash 2>&1' | tee <log> | grep -icE 'layout|not a git|unknown'
ssh vmadmin@<host> 'stat -c "%y" /usr/local/bin/ioc-runner; /usr/local/bin/ioc-runner -V'
ssh vmadmin@<host> 'cd <abs-toplevel> && make install 2>&1' | tee <log> | grep -icE 'layout|not a git|unknown'
ssh vmadmin@<host> 'stat -c "%y" /usr/local/bin/ioc-runner; /usr/local/bin/ioc-runner -V'
ssh vmadmin@<host> 'cd <abs-toplevel> && make setup 2>&1' | tee <log> | grep -icE 'layout|not a git|unknown'
ssh vmadmin@<host> 'stat -c "%y" /usr/local/bin/ioc-runner; /usr/local/bin/ioc-runner -V'
```

The first deliberately omits `--full`, unlike the precondition deploy: what is
under test here is the stamping path, which the default form exercises. The two
make recipes call `sudo` internally and cannot be given `-n` from outside; they
run without prompting because the account's policy allows them, and if one does
prompt, the run stops there rather than hanging — treat that as the finding.

Required: each entry point stamps a real short hash and commit date, the
modification time moves at each one, and the deployed `-V` carries that hash
rather than `unknown`.

No layout warning means specifically none of the deploy-time warnings about
the checkout's shape — not a git checkout, tracked files missing, metadata
unavailable, or a stamp of `unknown`. That is what the folded count answers, and
each of the three must print `0`. Read the printed number, not the exit code:
`grep -c` exits nonzero on a count of `0`, which is the wanted result here, and
in a pipeline that code is the one the shell reports.

One warning is expected and is not this class: the golden whose
sudo predates the anchored form reports which sudoers form it emitted. S11
determines which golden that is, and verifies the consequence deliberately.

### 4. The multi-user scenarios

Run every scenario in "Multi-user scenarios" below, on both goldens, in full.
Not a subset chosen by what the cycle touched: multi-user behavior is a
property of the whole permission surface, so a scenario that passed against a
different tree has not been established against this one.

These run against the deployed binary, always. The principals invoke
`ioc-runner` from the command path the way an operator does, so there is no
source-mode variant of this step. The deployed binary at this point is the one
step 3 last stamped — read it back before starting, and stop if it is not the
tree under test:

```bash
ssh vmadmin@<host> '/usr/local/bin/ioc-runner -V'
```

## Evidence

Record one row per suite per host. Measure the numbers; do not estimate them.
A run whose counts were transcribed from a previous run is not evidence.

The verdict command reads one concatenated log per host and answers a single
question — did anything fail. This table is the other half: it wants the rows
back out of that log, in the order the suites were launched, which is the order
the blocks appear. The Skipped column holds text, not a number: the suites
report skips as prose in the body, so name what was skipped and why.

| Host | Golden bake date | Baseline in the manifest | Mode | Suite | Passed / total | Skipped |
|---|---|---|---|---|---|---|
| | | | | | | |

Record alongside it: the four facts from "What is under test", the golden
acceptance result, the denial precheck result, and the multi-user outcome per
scenario.

## Driver forms

Each line below replaces a form that produced a false result or a stall.

```bash
# background launch of anything that runs ansible or expects a terminal
setsid script -qec "<cmd>" /dev/null < /dev/null > <log> 2>&1 &

# confirm it started, by output - a process search matches the searching shell
[ -s <log> ] && tail -1 <log> || echo "NOT STARTED"

# wait for a long step in the foreground, bounded - a wait handed to an event
# that cannot wake the waiter is a silent stop, not a wait. Wait on the log,
# never on a process name: a name search matches the polling shell itself and
# the loop never exits.
until [ "$(grep -c '<completion-line>' <log>)" -ge <expected> ]; do sleep 60; done
tail -2 <log>

# for the bake: the line is "Bake complete:" and a both-platform bake prints it
# once per golden, so wait for two - waiting for one returns halfway through
until [ "$(grep -c 'Bake complete:' <log>)" -ge 2 ]; do sleep 60; done

# one invocation per line: a command chained behind a blocking one never runs
ssh -n vmadmin@<host> '<cmd>'

# hold a console without holding the connection
mkfifo <fifo>; ( sleep 120 > <fifo> ) &
setsid bash -c "timeout -k 2 120 script -qec 'ioc-runner attach <name>' /dev/null < <fifo> > <out> 2>&1; echo rc=\$? >> <out>" &

# every privileged command over a connection with no terminal
sudo -n <cmd>

# EPICS path: derive from the host, never glob
ssh vmadmin@<host> 'os="$(. /etc/os-release; echo "${ID}-${VERSION_ID}")"; ls -d /opt/epics/*/"${os}"/*/setEpicsEnv.bash'

# source it in the form that survives set -u
set +u; if [ -z "${EPICS_BASE:-}" ]; then . <epics-env>; fi; set -u

# capture a suite whole, then read the counts out of it
bash tests/<suite>.bash > <log> 2>&1
cat -v <log> | sed 's/\^\[\[[0-9;]*m//g' | grep -E 'Total|Passed|Failed|Skipped|Script Errors'

# a verdict that cannot score an empty log as a pass
cat -v <log> | sed 's/\^\[\[[0-9;]*m//g' | awk '/Passed/{p++} /Failed/{f+=$NF} /Script Errors/{e+=$NF} END{ if (p==0) print "NO SUMMARY FOUND"; else print (f==0 && e==0) ? "SUITES OK (" p " blocks)" : "SUITES FAIL f=" f " e=" e }'

# read a make variable, then set it - reading does not set it, and the value
# printed is make syntax: expand $(HOME) yourself before exporting
grep IMAGE_DIR <cloud-provision>/configure/CONFIG_SITE
export IMAGE_DIR=<the printed value, with $(HOME) expanded>

# before the acceptance: prove nothing has touched the golden yet
ssh vmadmin@<host> 'git -C ~/gitsrc/epics-ioc-runner rev-parse --short HEAD; /usr/local/bin/ioc-runner -V'
```

## When a red appears

A red is not yet a defect. Take it through this order and stop at the first
step that explains it.

1. **Compare it against "Traps that cost a run"** below. Every entry there
   reads as a product failure until it is recognized as a harness defect.
2. **Check whether the step was run in the mode this runbook names.** A suite
   run in a mode the host cannot support fails for a reason that has nothing to
   do with the tree.
3. **Rebake and reproduce.** A red seen only on a reused test bed is not
   attributable: the drift factor is gone the moment the test bed is destroyed,
   and it cannot be told from a real defect afterwards.
4. **Only then classify it as a defect**, and record what was observed, on
   which host, in which mode, at which commit.

The reverse order is what produces a defect report against code that was never
at fault.

## When the tree changes during a gate

Any change to the tree after a step has run invalidates that step. Re-run the
gate at the final commit and record that commit. Do not cite the earlier run
for the steps that were already green: the tree that shipped is not the tree
they were measured against.

This applies to a one-line documentation edit as much as to a code change. If
the edit demonstrably cannot reach the step — a different file, a different
subsystem — record that reasoning explicitly rather than leaving the reader to
assume it.

## When a check cannot be induced

Some conditions cannot be produced on demand. A deployment that self-heals
before its own verification step cannot be made to fail that step; a code path
guarded by a state the harness cannot construct cannot be reached.

Record the gap as a gap. Name what could not be induced and why, and name what
covers it instead, if anything does. An honest blank is usable by the next
reader; a green that was never observed is not, and it removes the one signal
that would have caught the defect.

Record in the same place whatever the tree does not verify at all — a
behavior with no automated coverage, or a known limitation of a check that
passes. A green result that a reader takes for more than it is costs more than
a stated gap.

## Multi-user scenarios

The automated suites are single-principal. These scenarios cover what spans
several user identities, and they run in full at every Gate-grade run.

### Principals

System mode gates privileged state changes on `ioc` group membership at one
point: the sudoers policy granting `%ioc` password-free access to the
privileged systemd verbs for the runner's units. The boundary is binary on
`ioc` membership, not on general sudo rights.

| Role | Identity | `ioc` group | State changes | Reads |
|---|---|:-:|---|---|
| installer | `root` via sudo | — | one-time setup only | — |
| operator | engineer in `ioc` | yes | permitted | permitted |
| observer | user not in `ioc` | no | denied — `start` at the sudo gate, `stop` and `remove` earlier still, at configuration resolution | permitted |

`ioc-srv` is the non-login service account that runs procServ, not a human
principal. Local mode is single-principal by construction.

### Accounts

| Account | Mode | `ioc` group | Linger | Role |
|---|---|:-:|:-:|---|
| `opa` | system | yes | — | operator |
| `opb` | system | yes | — | second operator |
| `obs` | system | no | — | observer negative control |
| `usera` | local | no | yes | local user A |
| `userb` | local | no | yes | local user B |

Provisioning is owned by the `test_users` role in `ansible-provision` and is
applied during the bake. This runbook verifies the accounts in "Fixture
accounts" above and never creates them.

### Environment

Both goldens carry a real systemd and sudo and differ in sudo version, which
selects the two sudoers emission branches. The pair therefore covers both
branches without extra setup: the older sudo takes the glob fallback, the newer
one the anchored per-verb form.

### Harness

The drivers under `gate/drivers/` carry the harness: the principal switch, the
console wrapper, the payload shape, the generate mode, and the capture form are
all inside them. What is left here is what a driver cannot decide for itself.

- **The host must grant the driving account password-free sudo to an arbitrary
  target user.** Every scenario is driven through `sudo -niu <user>`, so a host
  that does not stops the section at its first switch, before any scenario, and
  that stop is a property of the host rather than of the tree. The goldens grant
  it.
- **A negative scenario needs a target the acting principal does not own.**
  `gate/drivers/identities.bash` fixes that once: `lioc1` is installed under the
  same name by both local users on purpose, and `lioc2` is the owner's uniquely
  named IOC, which is what L2 and L3 aim at. Reverse a role there and every
  negative in this section becomes a principal probing its own asset. No other
  file names an account or an IOC.
- **Where state lives** — the specification the log-read and socket verdicts are
  computed against:
  - Log: system `/var/log/procserv/<name>.log`, owned `ioc-srv:ioc` with the
    group read bit set; local `~/.local/state/procserv/<name>.log`, `0640` and
    owned by the user, with a `0700` home blocking a peer at the home
    directory too. The group read bit is the assertion, never a whole mode.
  - Socket: system `/run/procserv/<name>/control`; local
    `/run/user/<uid>/procserv/<name>/control`.

### Traps that cost a run

Each entry turned a green expectation red, or silent, during a real run. They
are harness defects, and every one reads as a product failure until recognized.

- **Never source the EPICS environment under `set -u`.** The environment script
  reads a variable that is normally unset, so a driver running with `set -u`
  dies the instant it sources the file — silently, when the source is
  redirected away. Wrap the source in `set +u` and `set -u`. The trap is
  invisible on the golden whose profile has already set `EPICS_BASE`.
- **A login shell speaks before the command does.** `sudo -niu <user>` is a
  login shell and may print an environment banner ahead of the command's own
  output, so a captured single-value read returns the banner with the value
  glued to its tail. Take the last line, or compare by match rather than
  equality. On one golden the same shell also emits a block of locale warnings
  before the banner. They cannot be silenced from the driver: the check runs in
  the login shell before the driver starts, and passing `LC_ALL` there only
  adds it to what the warning lists. Take the last line and read past it.
- **Probe a `0700` runtime directory as its owner.** A third party cannot
  distinguish "socket absent" from "directory not traversable", so a negative
  from anyone else proves nothing.
- **A fixture directory must carry its own payload.** Install validates that
  the command resolves and is executable relative to the working directory, and
  that validation runs before the conformance check. A configuration pointing
  at a bare home directory therefore aborts early and never reaches the warning
  the scenario is about. Stage the whole directory, `st.cmd` included.
- **Denial wears two faces on a password-free host.** The golden sudoers
  carries both a password-requiring catch-all and the runner's password-free
  entries, so a command the per-verb rule does not match falls through to the
  password rule. `sudo: a password is required` is the denial, not a harness
  fault. Assert on that string as well as the explicit refusal wording.
- **A console capture carries telnet negotiation bytes, and its closing line can
  swallow the next one.** Two traps sit in the same place and neither is a NUL:
  measured over every console capture on both goldens, the count of `0x00` is
  zero. What is there is procServ's negotiation sequence `FF FB 01 FF FD 22`
  (IAC WILL ECHO, IAC DO LINEMODE) on a line of its own just before the
  wrapper's closing message, so an equality comparison fails while the text
  itself is correct. Separately, where `script` closes a killed session with
  `Session terminated, killing shell...` it writes no trailing newline and the
  driver's next line is glued to it — measured on that line, `grep -c '<text>'`
  returns 1 while `grep -c '^<text>'` returns 0, a silent loss. Where the
  closing message reads `Session terminated.` nothing is glued. Compare by
  match, never anchored with `^`, and read past the closing message. Stripping
  control bytes fixes neither half: the negotiation bytes are high bytes rather
  than C0 controls, and the glued line holds no stray byte at all. `cat -v` on
  the raw capture shows both.
- **A console held from a remote driver keeps the driving connection open.**
  A backgrounded `attach` inherits the connection's output descriptors, so the
  remote shell does not return and the driver appears to hang until its own
  timeout. Detach the held client — its own session, its own output file — and
  let the driver return immediately. The scenario was never at fault; the
  driver was.
- **Confirm a background launch by its output, not by a process search.**
  A search for the script name matches the searching shell's own command line,
  so a launch that never happened reads as running. Check that the log file
  exists and is growing. The same applies to a launch chained behind other
  commands: when a remote invocation blocks, everything after it in the same
  line silently never runs.

### Local-mode scenarios

Local mode runs as the invoking user through the per-user systemd instance; the
target is isolation between users.

| ID | Scenario | Principals | Action and expected result |
|---|---|---|---|
| L1 | Session isolation | usera, userb | Each installs and starts a local IOC, a duplicate name being permitted. Each listing shows only the invoker's IOC; the user units are separated by the per-user runtime directory. |
| L2 | Cross-user interference blocked | userb to usera | Both `attach` and `stop` are refused at configuration resolution, in userb's own `~/.config/procServ.d`, exit 1 — `Configuration for <name> not found` and `No configuration found for IOC '<name>'` respectively. Neither reaches the socket path or addresses a user unit. |
| L3 | Log read blocked | userb to usera | As userb, both `stat` and read of usera's log are denied. Assert that denial as the peer, and assert the `0640 <user>:<user>` mode as the owner — the mode is the boundary the product owns. On both goldens the home directory is also `0700`, which stops the peer one level earlier, but that is a distribution default the account fixture never promised: record it as observed, do not assert it, and do not read a `0755` home as a failure while the log mode still holds. |

### System-mode scenarios

System mode runs IOCs as the shared service account; the target is shared-asset
and permission-boundary behavior across the three roles.

| ID | Scenario | Principals | Action and expected result |
|---|---|---|---|
| S1 | Shared management | opa, opb | opa installs and starts; opb queries, stops, and restarts the same IOC successfully — both are in `ioc` and it is one shared unit. |
| S2 | Configuration collaboration | opa, opb | opa creates `/etc/procServ.d/<name>.conf`; opb edits it. The `2770 root:ioc` setgid directory grants opb group write and the file keeps group `ioc`. |
| S3 | Concurrency | opa, opb | Two operators act on different IOCs at the same time — the drive block restarts one each. Both invocations succeed, both units end `active`, and neither IOC's state reflects the other's action: an IOC that was running is running, and no unit reports a failed job. That is what counts as no interference here; overlapping wall-clock windows are the setup, not the assertion. |
| S4 | Removal while in use | opa, opb | opb holds a console; opa stops and removes the IOC. opb's session terminates immediately with end-of-file, the socket directory is removed with the unit, and no hang or stale socket remains. |
| S5 | Cross-operator log read | opb to opa | opb reads an opa-started IOC's log under its own identity, with no sudo, through the group read bit on a file owned by the service account. There is no separate scan verb to run: crash-pattern scanning happens inside the runner's own start poll, so what this scenario establishes is the read boundary. |
| S6 | Observer negative control | obs | Reads and systemd queries succeed, including `systemctl is-active` on the unit. Start is denied at the sudo gate. Stop and remove are denied earlier, at configuration resolution: obs cannot read the `2770 root:ioc` `/etc/procServ.d`, so the runner names the access barrier and exits 1 before touching systemd. With IOCs running, the listing returns empty plus the permission hint, exit 0, since the `0770` socket directories are not traversable outside `ioc`. |
| S7 | Disable, manual run, re-enable | opa, opb | opa disables and stops, runs `st.cmd` by hand, then starts and enables. opb observes the intermediate state correctly; the configuration is unchanged and only runtime state moves. |
| S8 | Crash-loop detection | opa | An IOC whose configuration adds an extra crash pattern reaches initialization and then emits that token while staying active. The startup poll merges the per-IOC pattern and reports a post-initialization warning, exit 0 — the extra pattern corroborates, it does not stand alone. Choose a distinctive token: a word ordinary log lines carry is rejected at install and again at every start, and the scenario never reaches its warning. The warning text is generic and does not name the token, and other scenarios' IOCs can raise the same wording, so establish the causal link yourself: the token is present in the installed configuration, and the token appears in this IOC's log at the moment the warning was raised. Without both reads the scenario has observed a warning, not this warning. |
| S9 | Working-directory non-conformance | opa, root | Install with a working directory the service account cannot write: conformance warning and confirmation. Install with a path containing a parent reference: unconditional hard error before the warning flow, no prompt, and the force flag does not bypass it. Root and operator give the identical result. |
| S10 | Console socket access probe | opb, obs to opa | Layered: for `attach` and `monitor` a principal outside `ioc` is denied at configuration resolution first, so the socket path — directory `0770`, socket file `0660`, both `ioc-srv:ioc` — is a second gate it never reaches. A member of `ioc` attaches and monitors successfully. `inspect` is different: its root gate fires before the configuration gate, so every non-root principal gets the root requirement regardless of group, and the observer never sees the access-barrier message here. Per-distribution wording and exit codes are not asserted. |
| S11 | sudo-version residual risk | opa | Outside the runner, opa issues a privileged systemd verb against a malformed unit name. The expected result is opposite on the two branches, so determine the branch first — `sudo --version` and the emitted `/etc/sudoers.d/10-epics-ioc`: below 1.9.10 the setup emits the glob fallback and warns that it is doing so, at or above it emits the anchored per-verb form. On the glob branch the sudo gate passes and systemd rejects the name, with an escaping complaint and a failed job assertion in the command's own output — that output is the evidence, not any unit state. On the anchored branch the gate denies it, and the denial surfaces as `sudo: a password is required` — the fallthrough described in the traps, not a harness fault. This is a documented least-privilege drift, verified here rather than fixed. |

### Driving the scenarios

The drivers are repository assets under `gate/drivers/`. Nothing in this section
is typed by hand and nothing is written per run: the instrument is the same one
every cycle, so one run's green is the same green as the next's.

```
gate/drivers/
  identities.bash    the six IOC names, the role mapping, the S8 token
  push.bash          the tree push, used by the gate steps above, not a scenario
  control/           runs on the CONTROL HOST
  host/              copied to the VM and run there as a principal
```

A file's directory states which side it runs on. The `sys-` and `local-`
prefixes inside `host/` mark the runner's mode and never the side.

Each control driver takes one argument, the host as `user@address`. It switches
the principal itself, captures whole before reading anything, and prints the
scenario's verdict. The principal is an argument each host driver checks before
it acts, so a wrong one is a refusal rather than a plausible transcript.

**Stage once per host**, before anything else. A copied file keeps the mode of
its source, which the destination umask can narrow but never widen, so the
drivers are opened to the principals that run them after the copy:

```bash
bash gate/drivers/control/stage.bash vmadmin@<host>
```

**Then drive the whole step:**

```bash
bash gate/drivers/control/run-all.bash vmadmin@<host>
```

That is the invocation. The table below is for driving one scenario on its own
after a red; every line takes the same single argument and is the same command
`run-all.bash` issues.

| | Driver |
|---|---|
| preconditions | `control/runtime-dirs.bash`, `control/sys-shared.bash`, `control/sys-fresh.bash`, `control/survival.bash` |
| L1 | `control/l1.bash` |
| L2, L3 | `control/l2-l3.bash` |
| S1, S2, S5 | `control/s1-s2-s5.bash` |
| S3 | `control/s3.bash` |
| S4 | `control/s4.bash` |
| S6 | `control/s6.bash` |
| S7 | `control/s7.bash` |
| S8 | `control/s8.bash` |
| S9 | `control/s9.bash` |
| S10 | `control/s10.bash` |
| S11 | `control/s11.bash` |
| between runs | `control/cleanup.bash` |

A single scenario re-driven this way is only valid where the state it needs is
still standing. After S4 the shared IOC is gone, and the order below says which
scenarios that ends.

**The verdict.** Every driver computes and prints its own, in one form:

```
VERDICT <id> <PASS|FAIL> <detail>
```

The fourteen scenario verdicts of a run are exactly the lines matching
`VERDICT (L[1-3]|S[1-9]|S1[01]) (PASS|FAIL)`, and nothing else matches it:
a driver that owns half a scenario prints `<ID>-<HALF>` and the other half's
driver the rest, with the control driver that makes both invocations printing
the combined `<ID>`; a precondition prints `P-<WHAT>`. So the count is a
command and not a reading:

```bash
grep -coE 'VERDICT (L[1-3]|S[1-9]|S1[01]) PASS' <run-all.log>
```

`run-all.bash` prints that count itself as a final `VERDICT RUN` line, naming
any scenario whose verdict never appeared. A driver that printed no verdict is
reported as a FAIL naming the transcript, never as an absence.

Match a verdict UNANCHORED. Where `script` closes a killed session with
`Session terminated, killing shell...` it writes no trailing newline and the
next line is glued to its tail, so an anchored read loses the line silently.

Three verdicts are not a reading of one command's exit code, and a run that
takes them as one is wrong:

- **L1** is a comparison across two separate invocations — each local user's
  listing must show exactly one IOC and it must be its own — so no single
  driver can reach it. `control/l1.bash` makes both and compares.
- **S3** reads the printed word against an inverted exit code. `systemctl
  is-failed` on a healthy unit prints `active` and exits nonzero, so a verdict
  taken from the code is wrong on every good run. `failed` is the failure.
- **S10** ignores a nonzero exit code and looks for the connection banner. A
  successful member `attach` or `monitor` ends when the wrapper's timeout kills
  it, so the code is the wrapper's and not the verb's.

**Reading a run.** Each driver leaves three files per capture in the run
directory it names on its first line, all absolute:

| | |
|---|---|
| `<label>.raw` | byte for byte, because the telnet negotiation bytes and the glued closing message are themselves evidence |
| `<label>.txt` | the `cat -v` read form, colour escapes removed |
| `<label>.clean` | colour and carriage returns removed; what the verdict logic greps, so a whole-word match means what it says |

Capture whole, then read. A console scenario piped through `tail` loses the
banner that is its only evidence — measured on S10, where the first attempt
read `NOT attached` for a client that was connecting correctly.

### Order within a run

`control/run-all.bash` holds the order and is the reason it is not a reading
task. It is part of the instrument, not a convenience:

1. Local payloads, then L1, then L2 and L3.
2. One shared system IOC, then S1, S2, S5 and S6 against it — every scenario
   that only observes or manages an existing IOC.
3. The survival check. S6 aims a removal at the shared IOC and is expected to be
   refused, so a regression in that refusal must land on S6 rather than on the
   scenarios that would then fail for want of a target.
4. S10 and S11, against the IOC that survived.
5. S9, which builds and discards its own payload in the operator's home.
6. S8, which needs its own IOC because its payload carries the token.
7. S4 last of the shared-IOC scenarios: it removes that IOC, and nothing that
   depends on it may run afterwards.
8. A fresh IOC installed by the second operator, then S3 and S7. In S3 each
   operator acts on the IOC it installed: the first on S8's, the second on the
   fresh one. S7 runs entirely on the fresh one, acting as the second operator
   and observed by the first — kept off S8's IOC, whose payload emits its crash
   token on every start, which would raise S8's warning again while S7 claims
   that only runtime state moves.

Local and system IOCs accumulate across a run. Between runs:

```bash
bash gate/drivers/control/cleanup.bash vmadmin@<host>
```

That removes them through the runner, system operator first and then each local
user, and confirms each listing empty rather than assuming it. Reach for `pkill`
only for a process a missing terminal left stuck — killing a process the runner
still tracks leaves the configuration behind, which is the state this step
exists to clear.

## Upstream and downstream

| Document | What it owns |
|---|---|
| `cloud-provision/docs/RUNBOOK_BAKE.md` | Baking the goldens, bake failure handling, and the provenance contract this runbook accepts |
| `ansible-provision/docs/test_users_handoff.md` | Creating the fixture accounts this runbook verifies |
| [`../tests/README.md`](../tests/README.md) | The suite contract: permission modes, binary origin, workspace retention |
| [`../docs/PERMISSION_MODEL.md`](../docs/PERMISSION_MODEL.md) | The model the multi-user scenarios verify |
| `git-workflow` skill, release reference | The release sequence itself: merge, tag, published release, milestone close |

The release sequence is deliberately absent from this runbook. A Gate-grade
result is its precondition, not part of it.

## Where these rules came from

Each rule above was written after a run that went wrong in exactly that way.
The runs are preserved in the release-line registers: `git show <tag>:docs/milestone.md`.
