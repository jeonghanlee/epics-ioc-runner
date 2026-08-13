#!/bin/bash
# S6 - the observer negative control.
#
# S6 aims a removal at the shared IOC and expects to be refused. survival.bash
# runs next and confirms the IOC is still there, so a regression in that refusal
# lands on S6 rather than on S10 and S11.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

capture s6 sys_as 300 "${GATE_S6_ACTOR}" sys-obs.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S6_ACTOR}"
relay s6 S6
