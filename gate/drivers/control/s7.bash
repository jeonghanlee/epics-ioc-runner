#!/bin/bash
# S7 - disable, manual run, re-enable, on the fresh IOC. Three invocations under
# two principals, in this order: the acting operator, the OTHER operator
# observing the intermediate state, then the acting operator again.
#
# The configuration hash is taken in the first half and again in the third, and
# the comparison is made here, because it spans two invocations. S7's claim is
# that only runtime state moves.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

capture s7-a sys_as 300 "${GATE_S7_ACTOR}" sys-s7a.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_FRESH}" "${GATE_S7_ACTOR}"
relay s7-a S7-A

capture s7-observe sys_as 120 "${GATE_S7_OBSERVER}" sys-s7observe.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_FRESH}" "${GATE_S7_OBSERVER}"
relay s7-observe S7-OBSERVE

capture s7-b sys_as 300 "${GATE_S7_ACTOR}" sys-s7b.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_FRESH}" "${GATE_S7_ACTOR}"
relay s7-b S7-B

va="$(verdict_of s7-a S7-A)"
vo="$(verdict_of s7-observe S7-OBSERVE)"
vb="$(verdict_of s7-b S7-B)"
mb="$(fact s7-a md5-before)"
ma="$(fact s7-b md5-after)"

if [ "${va}" = PASS ] && [ "${vo}" = PASS ] && [ "${vb}" = PASS ] \
    && [ -n "${mb}" ] && [ "${mb}" != "none" ] && [ "${mb}" = "${ma}" ]; then vrc=0; else vrc=1; fi
verdict S7 "${vrc}" "halves disable/stop=${va:-none} observed=${vo:-none} manual+start+enable=${vb:-none}; configuration md5 before=${mb:-none} after=${ma:-none} - only runtime state moved"
