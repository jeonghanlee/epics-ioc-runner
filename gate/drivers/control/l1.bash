#!/bin/bash
# L1 - session isolation.
#
# The verdict is a comparison ACROSS TWO SEPARATE INVOCATIONS, which is why it
# is computed here and not inside the driver either half runs. Both local users
# install and start an IOC under the same name on purpose; the claim is that
# each listing shows one IOC and it is the invoker's own, the user units being
# separated by the per-user runtime directory. Either half alone cannot see that.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

ua="$(gate_uid "${GATE_L_OWNER}")"
ub="$(gate_uid "${GATE_L_ACTOR}")"

capture l1-a local_as 300 "${GATE_L_OWNER}" "${ua}" local-payload.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_L_DUP}" "${GATE_L_OWNER}"
relay l1-a P-LOCAL-PAYLOAD

capture l1-b local_as 300 "${GATE_L_ACTOR}" "${ub}" local-payload.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_L_DUP}" "${GATE_L_ACTOR}"
relay l1-b P-LOCAL-PAYLOAD

va="$(verdict_of l1-a P-LOCAL-PAYLOAD)"; vb="$(verdict_of l1-b P-LOCAL-PAYLOAD)"
ra="$(fact l1-a listing-rows)";          rb="$(fact l1-b listing-rows)"
ha="$(fact l1-a listing-has)";           hb="$(fact l1-b listing-has)"

if [ "${va}" = PASS ] && [ "${vb}" = PASS ] \
    && [ "${ra}" = "1" ] && [ "${rb}" = "1" ] \
    && [ "${ha}" = "0" ] && [ "${hb}" = "0" ]; then vrc=0; else vrc=1; fi
verdict L1 "${vrc}" "${GATE_IOC_L_DUP} installed and started by both: ${GATE_L_OWNER} payload=${va} rows=${ra:-none} has-own=${ha:-none}; ${GATE_L_ACTOR} payload=${vb} rows=${rb:-none} has-own=${hb:-none}; each listing must show exactly one IOC and it must be its own"
