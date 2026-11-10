#!/bin/bash
# S12 - `ioc-runner log` on the shared IOC: an ioc member reads it through the
# command, and a principal outside ioc is refused by the command while the 0644
# log file stays readable to it directly.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

capture s12-reader sys_as 120 "${GATE_S12_READER}" sys-s12.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S12_READER}" reader
relay s12-reader S12-READER

capture s12-observer sys_as 120 "${GATE_S12_OBSERVER}" sys-s12.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S12_OBSERVER}" observer
relay s12-observer S12-OBSERVER

vr="$(verdict_of s12-reader S12-READER)"
vo="$(verdict_of s12-observer S12-OBSERVER)"
if [ "${vr}" = PASS ] && [ "${vo}" = PASS ]; then vrc=0; else vrc=1; fi
verdict S12 "${vrc}" "ioc member ${GATE_S12_READER} reads the log through the command=${vr:-none}, ${GATE_S12_OBSERVER} outside ioc is refused by it and reads the 0644 file directly=${vo:-none}"
