#!/bin/bash
# S14 - two operators' consoles on one IOC at once. The second operator's
# monitor is started first and held; the first operator attaches with a custom
# detach key, sends Ctrl-C and Ctrl-D, detaches, and has Ctrl-[ refused; then
# the monitor is checked and stopped. The check runs whatever the attach
# returned, so a failed attach never leaves the monitor running.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

mark="s14-${GATE_RUN_ID}"

capture s14-monitor-up sys_as 120 "${GATE_S14_MONITOR}" sys-s14-monitor.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S14_MONITOR}" start "${mark}"
relay s14-monitor-up S14-MONITOR-UP

vu="$(verdict_of s14-monitor-up S14-MONITOR-UP)"
if [ "${vu}" = PASS ]; then
    capture s14-attach sys_as 180 "${GATE_S14_ATTACH}" sys-s14-attach.bash \
        "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S14_ATTACH}" "${mark}"
    relay s14-attach S14-ATTACH
fi

capture s14-monitor sys_as 60 "${GATE_S14_MONITOR}" sys-s14-monitor.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S14_MONITOR}" check "${mark}"
relay s14-monitor S14-MONITOR

va="$(verdict_of s14-attach S14-ATTACH)"
vm="$(verdict_of s14-monitor S14-MONITOR)"
if [ "${vu}" = PASS ] && [ "${va}" = PASS ] && [ "${vm}" = PASS ]; then vrc=0; else vrc=1; fi
verdict S14 "${vrc}" "${GATE_S14_MONITOR} monitor up=${vu:-none}, ${GATE_S14_ATTACH} attach with ctrl-b, ignored Ctrl-C and Ctrl-D, refused ctrl-[=${va:-none}, monitor survived the detach and saw the output=${vm:-none}"
