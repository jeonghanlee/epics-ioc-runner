# Exit and signal handling

systemd decides from procServ's exit how to record an IOC service: as a clean
stop, or as a failure that the restart policy acts on. This page describes
how a stop reaches procServ and the IOC, what procServ returns, and why the
unit templates list the exit statuses and restart settings they do. The
system and local unit templates carry the same settings; container mode uses
s6, which has none of them.

## Stop sequence from systemd to the IOC

The templates set these directives:

```ini
SuccessExitStatus=0 1 2 15 143 SIGTERM SIGKILL
Restart=always
RestartSec=2
KillMode=mixed
```

They set no `TimeoutStopSec=`, so systemd's default of 90 seconds applies, and
procServ runs without `--killsig`, so its kill signal is the default
`SIGKILL`.

When `ioc-runner stop` or `systemctl stop` stops an IOC:

1. With `KillMode=mixed`, systemd sends `SIGTERM` to the main process,
   procServ, and not to the other processes in the unit.
2. procServ handles `SIGTERM`: it sends its kill signal, `SIGKILL`, to the
   IOC, closes its connections, and exits.
3. procServ's exit code is the IOC's most recent normal exit status, or 0 when
   the IOC has only ever ended by a signal. A stop by `SIGKILL` therefore
   usually ends procServ with exit code 0.
4. When procServ has not exited when the stop timeout expires, systemd sends
   `SIGKILL` to every process that remains in the unit.

## Exit statuses counted as success

systemd counts exit code 0 and the signals `SIGHUP`, `SIGINT`, `SIGTERM`, and
`SIGPIPE` as a clean exit by default. `SuccessExitStatus` adds the exit codes
1, 2, 15, and 143 and the signals `SIGTERM` and `SIGKILL`, so none of these
ends marks the service `failed`. The list is deliberately wide: a stop or a
killed procServ is recorded as a clean exit rather than a failure.

Counting `SIGKILL` as success has one consequence for the restart policy. A
procServ killed by `SIGKILL`, for example by the kernel's out-of-memory
killer, is a success to systemd, so `Restart=on-failure` would leave the IOC
down. The templates therefore use `Restart=always`, which restarts procServ
after any exit that is not a stop request, 2 seconds later
(`RestartSec=2`). A stop through `ioc-runner stop` or `systemctl stop` does
not trigger a restart.

## Why the unit uses KillMode=mixed

procServ starts the IOC with `SIGTERM` blocked, so the IOC does not end on
`SIGTERM`. With the default `KillMode=control-group`, systemd would send
`SIGTERM` to every process in the unit and then wait the full stop timeout
for the IOC before it sends `SIGKILL`. `KillMode=mixed` sends `SIGTERM` only
to procServ, which ends the IOC itself with `SIGKILL`, and sends `SIGKILL` to
the processes that remain after procServ exits. When procServ itself dies,
the unit is therefore restarted in about 2 seconds instead of after the stop
timeout.

## Restart loops and the failed state

The templates set `StartLimitIntervalSec=0`, which turns off systemd's start
rate limit, so a procServ that dies repeatedly stays in
`activating (auto-restart)` and never reaches `failed`. `systemctl --failed`
therefore does not show a crash-looping IOC. `ioc-runner start` and `restart`
detect a crash loop from the IOC log instead; the
[CLI reference](CLI_REFERENCE.md#the-start-and-restart-commands) lists their
outcomes.

[ADR 0001](https://github.com/jeonghanlee/epics-ioc-runner/blob/master/docs/adr/0001-restart-supervision-c1h.md)
records the decision behind these settings.
