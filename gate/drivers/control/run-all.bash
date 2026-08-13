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
# Ahead of all of it, `leftovers` reads what a prior run left on the consumer.
# It removes nothing - clearing is the runbook's step - but a scenario that
# passes because a prior run's IOC happens to exist is a false green, so what is
# standing before the run is recorded in the run's own log.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"

here="$(cd "$(dirname "$0")" && pwd)"
host="$1"
log="${GATE_LOG_DIR}/run-all.log"

gate_init "${host}" || exit 1
export GATE_RUN_ID GATE_LOG_DIR GATE_REMOTE_RUN GATE_REMOTE_DRIVERS GATE_EPICS_ENV

{
    for step in \
        leftovers stage runtime-dirs \
        l1 l2-l3 \
        sys-shared s1-s2-s5 s6 survival s10 s11 \
        s9 s8 s4 \
        sys-fresh s3 s7 \
        cleanup
    do
        printf '\n========================================= %s\n' "${step}"
        bash "${here}/${step}.bash" "${host}"
    done
} 2>&1 | tee "${log}"

# `tally` READS the log the loop just wrote, so it cannot run inside the tee
# above: the file is not complete while the loop is still writing it. It runs
# here, and its output is computed WHOLE into a variable before a single byte is
# appended - the command substitution ends only when tally has exited, so every
# read of the log finishes before the append opens it. Piping tally straight into
# `tee -a` would leave the reader and the writer on the same file at once.
#
# Without the append the run's own verdict went to the terminal only: measured on
# the 2026-08-01 run, `grep -c 'VERDICT RUN' run-all.log` returned 0.
summary="$(tally "${log}")"
{
    printf '%s\n' "${summary}"
    printf '%s\n' "### transcripts and captures: ${GATE_LOG_DIR}"
} | tee -a "${log}"
