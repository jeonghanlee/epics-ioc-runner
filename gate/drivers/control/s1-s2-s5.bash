#!/bin/bash
# S1, S2 and S5 - the second operator against the first operator's IOC. All
# three verdicts are decided inside the driver; this half only switches the
# principal, captures, and lifts them.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

capture s1-s2-s5 sys_as 300 "${GATE_S_SECOND_OP}" sys-secondop.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S_SECOND_OP}"
relay s1-s2-s5 S1 S2 S5
