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
1, 2, 15, and 143 and the signals `SIGTERM` and `SIGKILL`. These settings classify
those exit statuses as successful; a separate unit failure, such as a stop
timeout, can still make the service `failed`. An ordinary stop or direct kill can therefore finish with `Result=success`.

Counting `SIGKILL` as success has one consequence for the restart policy. A direct `SIGKILL` of procServ is classified as a successful exit by
`SuccessExitStatus`; with no separate unit failure, `Restart=on-failure`
would leave the IOC down. An OOM event can also produce a separate unit
failure, depending on systemd's OOM policy. The templates therefore use `Restart=always`, which restarts procServ
after any exit that is not a stop request, 2 seconds later
(`RestartSec=2`). A stop through `ioc-runner stop` or `systemctl stop` does
not trigger a restart.

## Why the unit uses KillMode=mixed

procServ starts the IOC with `SIGTERM` blocked, so the IOC does not end on
`SIGTERM`. With `KillMode=control-group`, systemd sends `SIGTERM` to every process in
the unit. If a child remains after procServ exits, systemd can wait until
the stop timeout before sending `SIGKILL`. With `KillMode=mixed`, systemd
sends `SIGTERM` only to procServ and sends `SIGKILL` to remaining unit
processes after the main process exits; procServ normally kills the IOC
itself. When procServ itself dies, `KillMode=mixed` ends any remaining child
processes before the configured 2-second restart delay.

## Restart loops and the failed state

The templates set `StartLimitIntervalSec=0`, which turns off systemd's start
rate limit. Repeated automatic restarts are not stopped by that limit, but
other failures can still make the unit `failed`. Between automatic restart
attempts the unit is `activating (auto-restart)`, so `systemctl --failed` does
not list it in that state. `ioc-runner start` and `restart` detect a crash
loop from the IOC log; the
[CLI reference](CLI_REFERENCE.md#the-start-and-restart-commands) lists their
outcomes.

[ADR 0001](https://github.com/jeonghanlee/epics-ioc-runner/blob/master/docs/adr/0001-restart-supervision-c1h.md)
records the decision behind these settings.
