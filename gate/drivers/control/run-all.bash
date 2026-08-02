#!/bin/bash
# The whole scenario step, in order, on one host.
#
# The order lived only in a notes file. It is part of the instrument, not a
# convenience: S4 destroys the IOC every earlier system scenario shares, and
# nothing that depends on it may run afterwards. The rest of the constraints, in
# the order they bind:
#
#   local payloads, then L1, then L2 and L3
#   one shared system IOC, then S1 S2 S5 S6 - every scenario that only observes
#     or manages an existing IOC
#   the survival check, so a regression in S6's refused removal lands on S6
#   then S10 and S11 against the IOC that survived
#   S9, which builds and discards its own payload in the operator's home
#   S8, which needs its own IOC because its payload carries the token
#   S4 last of the shared-IOC scenarios
#   a fresh IOC installed by the second operator, then S3 and S7 - S3 pairs each
#     operator with the IOC it installed, S7 runs entirely on the fresh one and
#     is kept off S8's, whose payload emits its token on every start
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"

here="$(cd "$(dirname "$0")" && pwd)"
host="$1"

gate_init "${host}" || exit 1
export GATE_RUN_ID GATE_LOG_DIR GATE_REMOTE_RUN GATE_REMOTE_DRIVERS GATE_EPICS_ENV

{
    for step in \
        stage runtime-dirs \
        l1 l2-l3 \
        sys-shared s1-s2-s5 s6 survival s10 s11 \
        s9 s8 s4 \
        sys-fresh s3 s7 \
        cleanup
    do
        printf '\n========================================= %s\n' "${step}"
        bash "${here}/${step}.bash" "${host}"
    done
} 2>&1 | tee "${GATE_LOG_DIR}/run-all.log"

tally "${GATE_LOG_DIR}/run-all.log"
printf '%s\n' "### transcripts and captures: ${GATE_LOG_DIR}"
