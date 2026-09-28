#!/bin/bash
# S15 - `generate` by another operator on the shared IOC's payload: without -f
# the owner is named and nothing changes, with -f the file is taken over. The
# verdict is decided inside the host driver.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

capture s15 sys_as 120 "${GATE_S15_ACTOR}" sys-s15.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S15_ACTOR}" "${GATE_S_FIRST_OP}"
relay s15 S15
