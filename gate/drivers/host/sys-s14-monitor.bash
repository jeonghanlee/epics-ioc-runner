#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S14 monitor half, as the second operator, in two roles.
#
#   start  launch `ioc-runner monitor` fully detached from the driving
#          connection, as the S4 client is, and wait for its banner
#   check  after the first operator's attach has typed a command and detached,
#          the monitor must still be running, one of its processes must hold a
#          connected unix socket, and its capture must hold that command's
#          output; then the monitor is stopped
#
# The capture file and the pid file live in the per-run directory, which both
# operators can reach.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal   $4 role: start or check   $5 the distinctive value
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

out="${GATE_RUN_DIR}/s14-monitor.out"
pidf="${GATE_RUN_DIR}/s14-monitor.pid"
fifo="${GATE_RUN_DIR}/s14-monitor.fifo"
hold="${GATE_RUN_DIR}/s14-monitor-hold.pid"

case "$4" in
    start) vid="S14-MONITOR-UP";;
    check) vid="S14-MONITOR";;
    *)     printf '%s\n' "### unknown role $4"; exit 2;;
esac
require_principal "$3" "${vid}"
printf '%s\n' "### actor=$(id -un) role=$4"

case "$4" in
    start)
        # The monitor's standard input is a fifo held open by a sleeper, as in
        # S4: a closed input ends `script` at once and the monitor with it.
        rm -f "${out}" "${pidf}" "${hold}" "${fifo}"; mkfifo "${fifo}"
        setsid bash -c "echo \$\$ > ${hold}; exec sleep 300 > ${fifo}" < /dev/null > /dev/null 2>&1 &
        setsid bash -c "echo \$\$ > ${pidf}; exec timeout -k 2 300 script -qec 'ioc-runner monitor $2' /dev/null < ${fifo} > ${out} 2>&1" \
            < /dev/null > /dev/null 2>&1 &
        for _i in $(seq 30); do
            grep -qaF "Child \"$2\"" "${out}" 2>/dev/null && break
            sleep 1
        done
        chmod 0644 "${out}" 2>/dev/null
        grep -qaF "Child \"$2\"" "${out}"; up=$?
        printf '%s\n' "### monitor pid=$(cat "${pidf}" 2>/dev/null) banner=${up}"
        verdict "${vid}" "${up}" "monitor on $2 as $(id -un), connection banner found=${up}"
        ;;
    check)
        pid="$(cat "${pidf}" 2>/dev/null)"
        kill -0 "${pid}" 2>/dev/null; alive=$?
        # Every descendant of the monitor's leader, read from ss as their
        # owner: the console client among them holds the connection to
        # procServ. `script` runs its child in a session of its own on the new
        # terminal, so the walk follows parent links rather than the session.
        conn=0
        todo="${pid:-}"
        while [ -n "${todo}" ]; do
            next=""
            for p in ${todo}; do
                n="$(ss -xpH state connected 2>/dev/null | grep -c "pid=${p},")"
                conn=$((conn + n))
                next="${next} $(pgrep -P "${p}" 2>/dev/null | tr '\n' ' ')"
            done
            todo="$(printf '%s' "${next}" | xargs)"
        done
        printf '%s\n' "### connected unix sockets held by the monitor's processes=${conn}"
        gate_clean "${out}"
        grep -qaF "GATE_S14_MARK=$5" "${out}.clean"; seen=$?
        printf '%s\n' "### monitor pid=${pid:-none} alive=${alive} output seen=${seen}"
        tail -5 "${out}.clean"
        [ -n "${pid}" ] && kill -- "-${pid}" 2>/dev/null
        hp="$(cat "${hold}" 2>/dev/null)"
        [ -n "${hp}" ] && kill -- "-${hp}" 2>/dev/null
        rm -f "${pidf}" "${hold}" "${fifo}"
        if [ "${alive}" -eq 0 ] && [ "${conn}" -ge 1 ] && [ "${seen}" -eq 0 ]; then vrc=0; else vrc=1; fi
        verdict "${vid}" "${vrc}" "monitor still running after the attach detached=${alive}, connected unix sockets=${conn}, the attach's command output reached the monitor=${seen}"
        ;;
esac
