#!/bin/bash
# The one shared system IOC, installed by the FIRST operator. S1, S2, S5, S6,
# S10 and S11 all act on it, and S4 destroys it.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

capture sys-shared sys_as 300 "${GATE_S_FIRST_OP}" sys-payload.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S_FIRST_OP}" shared
relay sys-shared P-SHARED
