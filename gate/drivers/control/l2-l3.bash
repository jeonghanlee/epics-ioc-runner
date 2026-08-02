#!/bin/bash
# L2 and L3 - cross-user interference and log read, both aimed at the OWNER's
# uniquely named IOC.
#
# The owner's second IOC is installed here first. L1 installs the same name for
# both local users on purpose, so a negative that named THAT IOC would resolve
# the actor's own and prove nothing.
#
# L2 is decided inside the actor's driver. L3 is not: its peer denial and its
# owner-side mode come from two invocations under two principals, and this
# driver makes both.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

uo="$(gate_uid "${GATE_L_OWNER}")"
uc="$(gate_uid "${GATE_L_ACTOR}")"

capture l3-payload local_as 300 "${GATE_L_OWNER}" "${uo}" local-payload.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_L_OWNED}" "${GATE_L_OWNER}"
relay l3-payload P-LOCAL-PAYLOAD

capture l2l3-actor local_as 300 "${GATE_L_ACTOR}" "${uc}" local-actor.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_L_OWNED}" "${GATE_L_ACTOR}" "${GATE_L_OWNER}" "${uo}"
relay l2l3-actor L2 L3-PEER

capture l3-owner local_as 300 "${GATE_L_OWNER}" "${uo}" local-owner.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_L_OWNED}" "${GATE_L_OWNER}"
relay l3-owner L3-OWNER

vp="$(verdict_of l2l3-actor L3-PEER)"
vo="$(verdict_of l3-owner L3-OWNER)"
if [ "${vp}" = PASS ] && [ "${vo}" = PASS ]; then vrc=0; else vrc=1; fi
verdict L3 "${vrc}" "peer denial as ${GATE_L_ACTOR}=${vp:-none}, owner-side 0640 log mode as ${GATE_L_OWNER}=${vo:-none}"
