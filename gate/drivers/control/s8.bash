#!/bin/bash
# S8 - crash-loop detection through an extra per-IOC pattern. The IOC and the
# token are its own; S3 later uses this IOC as the first operator's half.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

capture s8 sys_as 300 "${GATE_S8_ACTOR}" sys-s8.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_S8}" "${GATE_S8_ACTOR}" "${GATE_S8_TOKEN}"
relay s8 S8
