#!/bin/bash
# S4 - removal while in use. Two principals, in this order and no other: the
# second operator holds a console, the first removes the IOC underneath it.
#
# This is the last of the shared-IOC scenarios. It destroys that IOC, and
# nothing depending on it may run afterwards.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

capture s4-client sys_as 180 "${GATE_S4_CLIENT}" sys-s4-client.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S4_CLIENT}"
relay s4-client S4-CLIENT

# A removal that races an unattached client proves nothing, so the client half's
# own verdict gates the server half.
vc="$(verdict_of s4-client S4-CLIENT)"
if [ "${vc}" != PASS ]; then
    verdict S4 1 "the console was not attached (client=${vc:-none}); the removal was not run, because a removal that races an unattached client proves nothing"
    exit 1
fi

capture s4-server sys_as 180 "${GATE_S4_SERVER}" sys-s4-server.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S4_SERVER}"
relay s4-server S4-SERVER

vs="$(verdict_of s4-server S4-SERVER)"
if [ "${vc}" = PASS ] && [ "${vs}" = PASS ]; then vrc=0; else vrc=1; fi
verdict S4 "${vrc}" "client ${GATE_S4_CLIENT} held the console=${vc:-none}, server ${GATE_S4_SERVER} removed it=${vs:-none}"
