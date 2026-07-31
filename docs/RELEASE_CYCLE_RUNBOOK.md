# Release Cycle Runbook

Operational procedure for verifying an `epics-ioc-runner` tree on the golden
images. The permission model lives in [`PERMISSION_MODEL.md`](PERMISSION_MODEL.md)
and the suite contract in [`../tests/README.md`](../tests/README.md); this page
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

Everything in this section runs from the `cloud-provision` checkout.

**Destroy the consumer VMs first.** The bake scans defined domains and refuses
to publish while any disk resolves through the target golden as its backing
file, which is exactly what a running consumer does. A bake started with the
consumers still present stops before publication.

```bash
make rocky8-iocrunner.server.clean
make debian13-iocrunner.server.clean
```

Then bake. These three are alternatives, not a sequence — the first does both
goldens, the other two do one platform each:

```bash
make bake
make bake.rocky8
make bake.debian13
```

Bake failure handling, proxy handling, and slow-boot diagnosis belong to
`cloud-provision/docs/RUNBOOK_BAKE.md`. Do not diagnose a bake from here.

### Freshly created consumer VMs

Create them from the images just published. Never reuse a test bed: it
accumulates state — a stale system user, a previously installed runner,
leftover accounts — and produces failures the tree under test does not have.

```bash
make rocky8-iocrunner.server
make debian13-iocrunner.server
```

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

Compare each remote manifest hash against its sidecar on the control host.
`IMAGE_DIR` is the bake's image directory, a site override the bake scripts
honor, and it is a make variable — reading it does not set it in your shell.
Read it, then set it:

```bash
grep IMAGE_DIR <cloud-provision>/configure/CONFIG_SITE
export IMAGE_DIR=<the value that printed, with $(HOME) expanded>
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

Call the result `<epics-env>` below. Guard the source with `${EPICS_BASE:-}`,
never `$EPICS_BASE`: the environment script reads a variable that is normally
unset, so a driver running under `set -u` dies on the guard itself before it
sources anything.

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
grep -m1 -iE 'runner|binary' <log>
ssh vmadmin@<host> 'IOC_RUNNER_TEST_MODE=installed sudo -nE printenv IOC_RUNNER_TEST_MODE'
```

Keep each suite's whole summary block, not its last few lines. The counts the
evidence table asks for sit above the closing banner, so a driver that tails a
fixed number of lines records a green with no numbers behind it — and a green
without its count cannot be compared against the next run. Pull the numbers out
of a captured log with:

```bash
cat -v <log> | sed 's/\^\[\[[0-9;]*m//g' | grep -E 'Total|Passed|Failed|Skipped|Script Errors'
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

```bash
ssh vmadmin@<host> 'cd <abs-toplevel> && sudo -n bash bin/setup-system-infra.bash'
ssh vmadmin@<host> 'cd <abs-toplevel> && make install'
ssh vmadmin@<host> 'cd <abs-toplevel> && make setup'
ssh vmadmin@<host> '/usr/local/bin/ioc-runner -V'
```

The first deliberately omits `--full`, unlike the precondition deploy: what is
under test here is the stamping path, which the default form exercises. The two
make recipes call `sudo` internally and cannot be given `-n` from outside; they
run without prompting because the account's policy allows them, and if one does
prompt, the run stops there rather than hanging — treat that as the finding.

Required: each entry point stamps a real short hash and commit date, with no
layout warning, and the deployed `-V` carries that hash rather than `unknown`.

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

| Host | Golden bake date | Baseline in the manifest | Mode | Suite | Passed / total | Skipped |
|---|---|---|---|---|---|---|
| | | | | | | |

Record alongside it: the four facts from "What is under test", the golden
acceptance result, the denial precheck result, and the multi-user outcome per
scenario.

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

- **Switching principal**: `sudo -niu <user>`. For local mode also pass
  `env XDG_RUNTIME_DIR=/run/user/<uid> DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/<uid>/bus`.
  The runtime directory can lag a few seconds behind linger being enabled;
  verify it exists first and force it with `systemctl start user@<uid>`.
- **Commands that prompt or hold a console need a terminal, a timeout, and
  EOF.** End-of-file alone is not enough. Wrap them:
  `timeout -k 2 <N> script -qec "<cmd>" /dev/null </dev/null`. For a console
  held open on purpose, feed a fifo in place of `/dev/null` and let the
  server-side stop or remove end the client. A manual `st.cmd` run likewise
  needs held input (`sleep <N> | ./st.cmd`) or the shell exits at once.
- **Payload**: an executable-shebang `st.cmd` naming the absolute `softIoc`
  path, followed by `iocInit`, is a sufficient stay-alive IOC for every
  scenario on both goldens. Resolve the path with `command -v softIoc` after
  sourcing the EPICS environment; do not hard-code it. Place the directory
  where the running account can reach it: system mode `/opt/epics-iocs/<name>`
  under a `2775 root:ioc` setgid parent, local mode `~/iocBoot/<name>`.
- **Generate in the mode you will install in.** `ioc-runner generate <iocBoot>`
  writes the system-mode identity (`IOC_USER="ioc-srv"`, `IOC_GROUP="ioc"`),
  and a local install then refuses it with `Local IOCs must run as <user>`. A
  local payload needs `ioc-runner --local generate <iocBoot>`. Either form
  writes `<name>.conf` inside the iocBoot directory and prints the install
  command to run next; when a configuration is already there it prompts to
  overwrite, so it needs the same terminal wrapper as `install`.
- **A negative scenario needs a target the acting principal does not own.**
  L1 installs the same IOC name for both local users on purpose, so a later
  scenario that names that IOC while acting as the peer resolves the peer's own
  IOC and proves nothing. Give the observed principal a second, uniquely named
  IOC and aim the negatives at that.
- **Drive from a non-login shell.** A login shell pulls in aliases and
  environment banners that corrupt piped output. Run the steps from a script
  that sources the EPICS environment itself.
- **Where state lives** — the log-read and socket scenarios need the exact
  paths:
  - Log: system `/var/log/procserv/<name>.log`, owned `ioc-srv:ioc` with the
    group read bit set; local `~/.local/state/procserv/<name>.log`, `0640` and
    owned by the user, with a `0700` home blocking a peer at the home
    directory too. Assert the group read bit rather than a whole mode.
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
  from a helper before the banner; setting `LC_ALL` in the driver silences it,
  and it is noise either way.
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
- **The terminal wrapper can leave stray NUL bytes in captured output.** On one
  of the goldens the recorded stream carries a leading NUL before a line, so an
  equality comparison against the expected text fails while the text itself is
  correct. Compare by match, or strip control bytes before comparing.
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
| S3 | Concurrency | opa, opb | Simultaneous start and stop of different IOCs: no interference, both succeed, per-unit state correct. |
| S4 | Removal while in use | opa, opb | opb holds a console; opa stops and removes the IOC. opb's session terminates immediately with end-of-file, the socket directory is removed with the unit, and no hang or stale socket remains. |
| S5 | Cross-operator log read | opb to opa | opb reads an opa-started IOC's log under its own identity, with no sudo, through the group read bit on a file owned by the service account. There is no separate scan verb to run: crash-pattern scanning happens inside the runner's own start poll, so what this scenario establishes is the read boundary. |
| S6 | Observer negative control | obs | Reads and systemd queries succeed, including `systemctl is-active` on the unit. Start is denied at the sudo gate. Stop and remove are denied earlier, at configuration resolution: obs cannot read the `2770 root:ioc` `/etc/procServ.d`, so the runner names the access barrier and exits 1 before touching systemd. With IOCs running, the listing returns empty plus the permission hint, exit 0, since the `0770` socket directories are not traversable outside `ioc`. |
| S7 | Disable, manual run, re-enable | opa, opb | opa disables and stops, runs `st.cmd` by hand, then starts and enables. opb observes the intermediate state correctly; the configuration is unchanged and only runtime state moves. |
| S8 | Crash-loop detection | opa | An IOC whose configuration adds an extra crash pattern reaches initialization and then emits that token while staying active. The startup poll merges the per-IOC pattern and reports a post-initialization warning, exit 0 — the extra pattern corroborates, it does not stand alone. Choose a distinctive token: a word ordinary log lines carry is rejected at install and again at every start, and the scenario never reaches its warning. |
| S9 | Working-directory non-conformance | opa, root | Install with a working directory the service account cannot write: conformance warning and confirmation. Install with a path containing a parent reference: unconditional hard error before the warning flow, no prompt, and the force flag does not bypass it. Root and operator give the identical result. |
| S10 | Console socket access probe | opb, obs to opa | Layered: for `attach` and `monitor` a principal outside `ioc` is denied at configuration resolution first, so the socket path — directory `0770`, socket file `0660`, both `ioc-srv:ioc` — is a second gate it never reaches. A member of `ioc` attaches and monitors successfully. `inspect` is different: its root gate fires before the configuration gate, so every non-root principal gets the root requirement regardless of group, and the observer never sees the access-barrier message here. Per-distribution wording and exit codes are not asserted. |
| S11 | sudo-version residual risk | opa | Outside the runner, opa issues a privileged systemd verb against a malformed unit name. The expected result is opposite on the two branches, so determine the branch first — `sudo --version` and the emitted `/etc/sudoers.d/10-epics-ioc`: below 1.9.10 the setup emits the glob fallback and warns that it is doing so, at or above it emits the anchored per-verb form. On the glob branch the sudo gate passes and systemd rejects the name with an escaping complaint and a failed job. On the anchored branch the gate denies it, and the denial surfaces as `sudo: a password is required` — the fallthrough described in the traps, not a harness fault. This is a documented least-privilege drift, verified here rather than fixed. |

### Driving the scenarios

Everything below runs on the golden. Put the steps in a script, copy it to a
world-readable path, and run it through the principal switch — never paste them
into a login shell, whose banner corrupts captured output.

```bash
sudo -niu <operator> bash /tmp/<driver>.bash <setEpicsEnv-path> <ioc-name>
sudo -niu <local-user> env XDG_RUNTIME_DIR=/run/user/<uid> DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/<uid>/bus bash /tmp/<driver>.bash <setEpicsEnv-path> <ioc-name>
```

Every driver opens the same way:

```bash
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u
```

**Answering a prompt.** The wrapper shown throughout feeds immediate
end-of-file, which is an answer: it declines. That is the intended result
wherever a scenario's expected outcome is an abort — the conformance
confirmation in S9's first case, and any overwrite question from `generate`.
Where a scenario must proceed past a prompt instead, either supply the
affirmative input in place of `/dev/null`, or use the verb's `--force` form
where it has one. Decide per scenario which of the two it is; do not let a
scenario that was meant to proceed abort silently and read as a pass.

**Local payload — L1, and the target for L2 and L3.** Run once per local user
with the same name for L1, then once more for the observed user with a unique
name the other user does not have.

```bash
boot="${HOME}/iocBoot/$2"; conf="${boot}/$2.conf"
rm -rf "${boot}"; mkdir -p "${boot}"
printf '#!%s\niocInit\n' "$(command -v softIoc)" > "${boot}/st.cmd"; chmod +x "${boot}/st.cmd"
ioc-runner --local generate "${boot}"
timeout -k 2 60 script -qec "ioc-runner --local install ${conf}" /dev/null </dev/null
timeout -k 2 90 script -qec "ioc-runner --local start $2" /dev/null </dev/null
ioc-runner --local list
```

**L2 and L3.** Two principals with distinct roles: the **actor** is the one
running the commands, the **owner** is the other user, whose uniquely named IOC
is the target. Every placeholder below names the owner, never the actor — if
the actor's own IOC is named here, the negative proves nothing.

Run as the actor:

```bash
timeout -k 2 20 script -qec "ioc-runner --local attach <owner-ioc>" /dev/null </dev/null
timeout -k 2 20 script -qec "ioc-runner --local stop <owner-ioc>" /dev/null </dev/null
stat -c '%U:%G %a %n' "/home/<owner>/.local/state/procserv/<owner-ioc>.log"
stat -c '%a %n' "/home/<owner>"
ls "/run/user/<owner-uid>/procserv/<owner-ioc>/"
```

Then run as the owner, to establish the mode the actor could not see:

```bash
stat -c '%U:%G %a %n' "${HOME}/.local/state/procserv/<owner-ioc>.log"
```

**System payload — the target for S1 through S11.**

```bash
boot="/opt/epics-iocs/$2"; conf="${boot}/$2.conf"
rm -rf "${boot}"; mkdir -p "${boot}"; chmod 2775 "${boot}"
printf '#!%s\niocInit\n' "$(command -v softIoc)" > "${boot}/st.cmd"; chmod 0775 "${boot}/st.cmd"
ioc-runner generate "${boot}"
timeout -k 2 60 script -qec "ioc-runner install ${conf}" /dev/null </dev/null
timeout -k 2 90 script -qec "ioc-runner start $2" /dev/null </dev/null
ioc-runner status "$2"
```

**S1, S2, S5 — run as the second operator against the first operator's IOC.**

```bash
ioc-runner status "$2"
timeout -k 2 60 script -qec "ioc-runner stop $2" /dev/null </dev/null
timeout -k 2 90 script -qec "ioc-runner restart $2" /dev/null </dev/null
stat -c '%U:%G %a %n' "/etc/procServ.d/$2.conf"
printf '# touched by %s\n' "$(id -un)" >> "/etc/procServ.d/$2.conf"
stat -c '%U:%G %a %n' "/var/log/procserv/$2.log"
head -c 80 "/var/log/procserv/$2.log" >/dev/null
```

**S6 — run as the observer.** Capture the exit code of each, not only the text.

```bash
ioc-runner status "$2"; systemctl is-active "epics-@$2.service"
head -c 40 "/var/log/procserv/$2.log" >/dev/null; ioc-runner list
timeout -k 2 30 script -qec "ioc-runner start $2" /dev/null </dev/null
timeout -k 2 30 script -qec "ioc-runner stop $2" /dev/null </dev/null
timeout -k 2 30 script -qec "ioc-runner remove $2" /dev/null </dev/null
ls /etc/procServ.d/
```

**S3 — two principals at once.** A sequential run proves nothing about
concurrency, so launch both and wait for the pair:

```bash
( ssh -n vmadmin@<host> "sudo -niu <opA> bash -c 'timeout -k 2 60 script -qec \"ioc-runner restart <ioc-a>\" /dev/null </dev/null'" > /tmp/s3a.out 2>&1 ) &
( ssh -n vmadmin@<host> "sudo -niu <opB> bash -c 'timeout -k 2 60 script -qec \"ioc-runner restart <ioc-b>\" /dev/null </dev/null'" > /tmp/s3b.out 2>&1 ) &
wait
ssh -n vmadmin@<host> 'systemctl is-active epics-@<ioc-a>.service epics-@<ioc-b>.service'
```

**S4 — hold a console, then remove underneath it.** Client half, as the second
operator, fully detached from the driving connection:

```bash
fifo="/tmp/s4.fifo.$(id -un)"; rm -f "${fifo}" /tmp/s4.out; mkfifo "${fifo}"
( sleep 120 > "${fifo}" ) &
setsid bash -c "timeout -k 2 120 script -qec 'ioc-runner attach $2' /dev/null < ${fifo} > /tmp/s4.out 2>&1; echo client_rc=\$? >> /tmp/s4.out" &
```

Confirm the console is actually attached before touching the server side — a
removal that races an unattached client proves nothing, and a launch that never
happened reads as success:

```bash
grep -q 'connected' /tmp/s4.out && echo attached || echo NOT attached
```

Server half, as the first operator, then read the result:

```bash
timeout -k 2 40 script -qec "ioc-runner remove $2 --force" /dev/null </dev/null
tail -4 /tmp/s4.out
ls -d "/run/procserv/$2"
```

Expect the client's last lines to name the control socket and `EOF`, the
recorded exit code to be 0, and the socket directory to be gone.

**S7 — disable, run by hand, re-enable.** Hash the configuration before and
after; the manual run needs held input or the shell exits at once.

```bash
md5sum "/etc/procServ.d/$2.conf"
timeout -k 2 40 script -qec "ioc-runner disable $2" /dev/null </dev/null
timeout -k 2 40 script -qec "ioc-runner stop $2" /dev/null </dev/null
systemctl is-active "epics-@$2.service"; systemctl is-enabled "epics-@$2.service"
cd "/opt/epics-iocs/$2" && timeout -k 2 20 bash -c "sleep 6 | ./st.cmd"
timeout -k 2 90 script -qec "ioc-runner start $2" /dev/null </dev/null
timeout -k 2 40 script -qec "ioc-runner enable $2" /dev/null </dev/null
md5sum "/etc/procServ.d/$2.conf"
```

**S8 — the extra crash pattern.** Order matters and is easy to get wrong: the
runner re-reads the pattern from the INSTALLED configuration under
`/etc/procServ.d`, so appending after the install leaves the token where
nothing reads it, the warning never fires, and a scenario that never ran
records as a clean pass. Generate, append, install, then start:

```bash
printf '#!%s\niocInit\nsystem "echo %s"\n' "$(command -v softIoc)" "<TOKEN>" > "${boot}/st.cmd"
ioc-runner generate "${boot}"
printf 'CRASH_LOG_PATTERNS_EXTRA="%s"\n' "<TOKEN>" >> "${boot}/$2.conf"
timeout -k 2 60 script -qec "ioc-runner install ${boot}/$2.conf" /dev/null </dev/null
timeout -k 2 90 script -qec "ioc-runner start $2" /dev/null </dev/null
```

Confirm the token reached the installed copy before trusting the verdict:

```bash
grep CRASH_LOG_PATTERNS_EXTRA "/etc/procServ.d/$2.conf"
```

**S9 — the two non-conforming shapes.** Build the payload in the operator's own
home, which is what makes the working directory non-conforming; the directory
must carry `st.cmd` or the install aborts on a missing command long before it
reaches the conformance question this scenario is about.

```bash
boot="${HOME}/iocBoot/$2"; rm -rf "${boot}"; mkdir -p "${boot}"
printf '#!%s\niocInit\n' "$(command -v softIoc)" > "${boot}/st.cmd"; chmod +x "${boot}/st.cmd"
ioc-runner generate "${boot}"
timeout -k 2 40 script -qec "ioc-runner install ${boot}/$2.conf" /dev/null </dev/null
sed -i "s|^IOC_CHDIR=.*|IOC_CHDIR=\"${HOME}/iocBoot/../iocBoot/$2\"|" "${boot}/$2.conf"
timeout -k 2 40 script -qec "ioc-runner install ${boot}/$2.conf" /dev/null </dev/null
timeout -k 2 40 script -qec "ioc-runner install --force ${boot}/$2.conf" /dev/null </dev/null
```

The first install is expected to reach the conformance question and decline on
end-of-file — that is its result, not a harness failure. The scenario's claim
is that the operator and root reach identical verdicts, and one principal
cannot establish it, so run the same installs as root against the operator's
configuration:

```bash
ssh vmadmin@<host> "sudo -n timeout -k 2 40 script -qec 'ioc-runner install /home/<operator>/iocBoot/<name>/<name>.conf' /dev/null </dev/null"
```

**S10 — the console probe.** Run the same three verbs as an `ioc` member and as
the observer, and read the socket permissions from each side.

```bash
timeout -k 2 15 script -qec "ioc-runner attach $2" /dev/null </dev/null
timeout -k 2 15 script -qec "ioc-runner monitor $2" /dev/null </dev/null
timeout -k 2 15 script -qec "ioc-runner inspect $2" /dev/null </dev/null
stat -c '%U:%G %a %n' "/run/procserv/$2" "/run/procserv/$2/control"
```

**S11 — the malformed unit name, outside the runner.** Determine the branch
first; the two expected results are opposite, so a reader who guesses files a
defect against correct behavior:

```bash
ssh vmadmin@<host> 'sudo --version | head -1; sudo -n grep -c "epics-@\*" /etc/sudoers.d/10-epics-ioc'
```

A non-zero count is the glob branch. Then, as the operator:

```bash
sudo -n systemctl start 'epics-@bad name.service'
```

### Order within a run

Scenario order matters, because S4 destroys the IOC every earlier system
scenario shares. Run them in this order:

1. Local payloads, then L1, then L2 and L3.
2. One shared system IOC, then S1, S2, S5, S6, S10, S11 against it — every
   scenario that only observes or manages an existing IOC.
3. S9, which builds and discards its own payload in the operator's home.
4. S8, which needs its own IOC because its payload carries the token.
5. S4 last of the shared-IOC scenarios: it removes that IOC, and nothing that
   depends on it may run afterwards.
6. S3 and S7, each on an IOC that still exists — S8's, plus one more installed
   by the second operator so the concurrency scenario has two.

Local and system IOCs accumulate across a run. Between runs, remove them
through the runner rather than by hand, and clear anything a missing terminal
left stuck:

```bash
ssh vmadmin@<host> "sudo -niu <operator> bash -c 'for n in $(ioc-runner list | awk \"NR>2 {print \\\$1}\"); do timeout -k 2 40 script -qec \"ioc-runner remove \$n --force\" /dev/null </dev/null; done'"
ssh vmadmin@<host> "sudo -niu <local-user> env XDG_RUNTIME_DIR=/run/user/<uid> ioc-runner --local list"
ssh vmadmin@<host> 'sudo -n pkill -u <user> -f procServ'
```

## Upstream and downstream

| Document | What it owns |
|---|---|
| `cloud-provision/docs/RUNBOOK_BAKE.md` | Baking the goldens, bake failure handling, and the provenance contract this runbook accepts |
| `ansible-provision/docs/test_users_handoff.md` | Creating the fixture accounts this runbook verifies |
| [`../tests/README.md`](../tests/README.md) | The suite contract: permission modes, binary origin, workspace retention |
| [`PERMISSION_MODEL.md`](PERMISSION_MODEL.md) | The model the multi-user scenarios verify |
| `git-workflow` skill, release reference | The release sequence itself: merge, tag, published release, milestone close |

The release sequence is deliberately absent from this runbook. A Gate-grade
result is its precondition, not part of it.

## Where these rules came from

Each rule above was written after a run that went wrong in exactly that way.
The runs are preserved in the release-line registers: `git show <tag>:docs/milestone.md`.
