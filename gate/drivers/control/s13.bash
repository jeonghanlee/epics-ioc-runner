#!/bin/bash
# S13 - the site environment file across principals: the first operator writes
# a value, the second restarts the shared IOC and reads it from the IOC's shell,
# a principal outside ioc cannot write the file, and the first operator returns
# the file to its state before the scenario. The restore runs whatever the
# earlier halves returned, so a failed half never leaves site.env behind.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

mark="s13-${GATE_RUN_ID}"

capture s13-set sys_as 120 "${GATE_S13_WRITER}" sys-s13.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S13_WRITER}" set "${mark}"
relay s13-set S13-SET

capture s13-read sys_as 240 "${GATE_S13_READER}" sys-s13.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S13_READER}" read "${mark}"
relay s13-read S13-READ

capture s13-observer sys_as 60 "${GATE_S13_OBSERVER}" sys-s13.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S13_OBSERVER}" observer "${mark}"
relay s13-observer S13-OBSERVER

capture s13-restore sys_as 60 "${GATE_S13_WRITER}" sys-s13.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S13_WRITER}" restore "${mark}"
relay s13-restore S13-RESTORE

vs="$(verdict_of s13-set S13-SET)"
vr="$(verdict_of s13-read S13-READ)"
vo="$(verdict_of s13-observer S13-OBSERVER)"
vx="$(verdict_of s13-restore S13-RESTORE)"
if [ "${vs}" = PASS ] && [ "${vr}" = PASS ] && [ "${vo}" = PASS ] && [ "${vx}" = PASS ]; then vrc=0; else vrc=1; fi
verdict S13 "${vrc}" "${GATE_S13_WRITER} wrote site.env=${vs:-none}, ${GATE_S13_READER} restarted and read the value=${vr:-none}, ${GATE_S13_OBSERVER} refused=${vo:-none}, restored=${vx:-none}"
