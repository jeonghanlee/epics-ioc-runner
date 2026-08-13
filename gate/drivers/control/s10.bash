#!/bin/bash
# S10 - the console socket access probe, layered: an ioc member attaches and
# monitors, a principal outside ioc is denied at configuration resolution first
# and never reaches the socket path.
#
# The two halves run the same driver under two principals, which is exactly the
# case where a wrong principal used to yield a plausible transcript. The role is
# an argument and the driver checks it before acting.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

capture s10-member sys_as 300 "${GATE_S10_MEMBER}" sys-s10.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S10_MEMBER}" member
relay s10-member S10-MEMBER

capture s10-observer sys_as 300 "${GATE_S10_OBSERVER}" sys-s10.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S10_OBSERVER}" observer
relay s10-observer S10-OBSERVER

vm="$(verdict_of s10-member S10-MEMBER)"
vo="$(verdict_of s10-observer S10-OBSERVER)"
if [ "${vm}" = PASS ] && [ "${vo}" = PASS ]; then vrc=0; else vrc=1; fi
verdict S10 "${vrc}" "ioc member ${GATE_S10_MEMBER}=${vm:-none} (connection banner found, the wrapper's nonzero exit code ignored), non-member ${GATE_S10_OBSERVER}=${vo:-none}"
