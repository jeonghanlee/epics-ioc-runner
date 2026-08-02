#!/bin/bash
# The fresh system IOC, installed by the SECOND operator, after S4 has destroyed
# the shared one. It is the second operator's half of S3 and the whole of S7.
#
# It is kept off S8's IOC deliberately: that payload emits its crash token on
# every start, so a start there raises S8's post-initialization warning again,
# and S7's claim is that only runtime state moves.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

capture sys-fresh sys_as 300 "${GATE_S_SECOND_OP}" sys-payload.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_FRESH}" "${GATE_S_SECOND_OP}" fresh
relay sys-fresh P-FRESH
