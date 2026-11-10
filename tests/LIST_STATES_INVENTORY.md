# Native List-State Inventory

## Scope

`test-list-states.bash` tests the host `list -vv` path with actual systemd,
procServ, softIoc, and kernel socket state. It selects local or system mode
and a source or installed runner. The Bash entry point owns the catalog and
shared reporter; `lib/list-states-native.py` controls native fixtures and
emits check events. Expected counts live only in `reporting-counts.csv`.

Container mode, production IOC interruption, and release Gate execution are
outside this suite. Invocation requirements are in [README.md](README.md#native-list-state-supplement).

## Requirement Mapping

The document clause IDs identify the retained M8 list-verification inventory.
They are traceability references, not extra runtime check identities.

| Clause | Requirement | Checks below |
| --- | --- | --- |
| LL009 | An inactive unit can appear in list output | S02 |
| LL016 | Unavailable CPU and memory render `N/A`, including numeric sentinel handling | S03 |
| LL021 | Kernel socket state selection, including listener precedence | S04, S05, S07 |
| LL025 | `UNCONN` rendering | S04 |
| LL026 | `CONNECTING` rendering | S05 |
| LL027 | `ESTAB` rendering | S05 |
| LL028 | `DISCONN` rendering | S07 |
| LL030 | First non-listening row selection and connection persistence | S05, S06 |

This mapping describes test intent. Only retained native execution can close
a document clause. A successful S06 establishes the measured duration of
that connection; it does not verify a general claim that non-listening states
are brief or occur only during startup and shutdown.

## Stable Catalog

Every ID has the `list-states.` prefix. All checks use the
`lifecycle-behavior` category and retain their identity across all four
scope/runner combinations.

| ID suffix | Kind | Method | Required observation |
| --- | --- | --- | --- |
| P00.root | REQUIRED | direct-inspection | Effective UID is root |
| P00.tools | REQUIRED | direct-inspection | Required native tools are executable |
| P00.prepared-host | REQUIRED | direct-inspection | Account, runner, softIoc, template, directories and workspace are usable |
| P00.network-namespace | REQUIRED | direct-inspection | A private network namespace exists |
| S01.native-ioc-started | BEHAVIOR | real-path | CLI generate/install/start creates an active native procServ with one softIoc child |
| S02.inactive-job-visible | BEHAVIOR | real-path | CLI list shows the queued IOC as inactive |
| S03.dbus-unavailable-values | BEHAVIOR | real-path | Native CPU and memory D-Bus properties both return UINT64_MAX |
| S03.unavailable-values-render-na | BEHAVIOR | real-path | CLI list renders both unavailable properties as N/A |
| S03.numeric-sentinel-input | PREREQUISITE | direct-inspection | Actual systemctl output contains both raw numeric sentinels |
| S03.numeric-sentinel-render-na | BEHAVIOR | real-path | CLI list renders those raw numeric inputs as N/A |
| S04.bound-before-listen | BEHAVIOR | real-path | Native procServ has a bound, non-listening socket |
| S04.unconnected-rendered | BEHAVIOR | real-path | CLI list reports UNCONN |
| S05.listener-priority | BEHAVIOR | real-path | CLI list chooses LISTEN and the listener inode over a same-path accepted socket |
| S05.connecting-rendered | BEHAVIOR | real-path | CLI list reports CONNECTING for a pending native connection |
| S05.established-rendered | BEHAVIOR | real-path | CLI list reports ESTAB and the accepted socket inode |
| S05.first-nonlistener-selected | BEHAVIOR | real-path | Two same-path non-listening rows retain their order around the CLI call, which selects the first inode |
| S05.native-processes-preserved | BEHAVIOR | real-path | procServ and softIoc keep their PID, start time and executable |
| S06.established-held-thirty-seconds | BEHAVIOR | real-path | CLI samples retain ESTAB and one inode; the last query starts at least thirty seconds after the first query completes |
| S07.disconnecting-input-observed | PREREQUISITE | direct-inspection | Native state 04 or actual CLI DISCONN is observed during bounded teardown sampling |
| S07.disconnecting-rendered | BEHAVIOR | real-path | CLI list itself reports DISCONN |
| S07.closed-connection-unknown | BEHAVIOR | real-path | CLI list reports UNKNOWN and N/A inode after connection teardown in the client namespace |
| S08.owned-resources-cleaned | INTEGRITY | direct-inspection | Owned processes, installed configuration, runtime directory and unit overrides are gone |
| S08.shared-assets-preserved | INTEGRITY | direct-inspection | Shared files retain their content, owner, mode, inode and modification time |

## Native Fixtures and Observation Boundaries

The fixture uses the real runner's `generate`, `install`, `start`, `stop`,
and `remove` commands. An instance-only override disables accounting and
automatic restart, retains the socket directory after stop, and uses SIGKILL
to retain the native socket file. No existing IOC is selected.

The system fixture directory is root-owned, group-writable by `ioc`, and
uses mode `2775`; the local fixture directory belongs to the selected account.
Native readiness requires an active procServ and exactly one child executing
the configured softIoc. A bounded poll allows systemd activation to precede
creation of the IOC child. Tool checks resolve `ss` through the fixed system
PATH because its installed directory differs between the supported OSes.

S02 queues a real start job behind an eight-second oneshot dependency. The
previously stopped IOC remains inactive while the dependency runs; the
retained socket gives the runner an IOC row to render.

S03 compares raw D-Bus properties, native `systemctl show`, and the actual
CLI table. If systemctl formats UINT64_MAX as `[not set]`, the numeric-input
prerequisite and numeric-fallback check are `SKIP`. The unavailable-value
checks remain independent. No command output is replaced to force a number.

S04 prepends strace to the existing instance ExecStart with timing-only
`listen:delay_enter`. ProcServ executes its real bind and listen calls.
This instrumented start uses native systemctl because the runner's start
preflight requires procServ as the unit executable. The claim is full CLI
`list` coverage, not coverage of CLI `start` under tracing. The override is
removed before subsequent normal starts.

S05 first opens a same-namespace client to test listener precedence. It then
pauses the verified procServ, opens a real client in a separate network
namespace through the shared pathname, and resumes procServ. The CLI runs
in the client namespace so it can observe the pending or accepted connection
without the server namespace's listener row taking precedence. The test does
not replace `/proc/net/unix`, `ss`, systemctl, or any runner function.

S05 then opens a second client in the same observer namespace. Two real
connections must have distinct inodes and the same socket path, with no
visible listener. Kernel rows before and after the CLI query must retain
the same order, flags, states and inodes; the CLI must select the first inode.
Both clients remain open during S06 and are tracked for cleanup.

S06 records the start and completion of every actual CLI query. Its duration
is the last query's start minus the first query's completion. Every sample
must show ESTAB and the same selected inode, with both clients alive. The
second client closes after the final sample; the first connection must
remain before teardown sampling begins. S07 makes
twenty bounded close/list observations with native clients. Missing state 04
is `SKIP`, not proof that DISCONN is unreachable. A raw state observation
without a CLI DISCONN observation also leaves the rendering check `SKIP`.

## Failure, Cleanup and Evidence

A failed required preflight records `FAIL`; checks that depend on it record
`SKIP` naming that preflight. Unexpected execution aborts leave unclosed
checks for the shared reporter to mark `SCRIPT_ERROR`. Failed assertions
remain in the ledger while independent observations continue.

INT and TERM request driver cleanup. Native command timeouts terminate their
owned process group. Cleanup resumes any paused procServ, closes clients and
the namespace holder, stops the test units, invokes CLI removal, and removes
only the test's own overrides and dependency unit. It checks the resulting
state and shared-file fingerprints before reporter finalization. SIGKILL or
host loss can prevent cleanup; retained evidence identifies the owned names.

Each `/tmp/ioc-list-states.*` workspace retains fixture sources, per-command
arguments/output/status, check events, errors, trace output, duration samples,
and cleanup results. Native IOC console logs remain in the configured log
directory. Accounts, group membership, shared templates, installed runner,
and existing test evidence are not intentionally changed.

A suite `PASS` with `SKIP` entries means the executed checks succeeded;
the skipped requirements remain unverified. Catalog-only checks and failure
preflight checks do not establish native socket-state coverage.
