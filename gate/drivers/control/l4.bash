#!/bin/bash
# L4 - one IOC carried between local and system mode by the operators who use
# it: the third operator, who is both an ioc member and a lingering local user,
# and the second operator. The steps run in order, and a failed step stops the
# sequence, because every later step starts from the state the earlier one left.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

uc="$(gate_uid "${GATE_L4_OWNER}")"
res=""
failed=""
for spec in \
    "local-first local ${GATE_L4_OWNER}" \
    "to-system system ${GATE_L4_OWNER}" \
    "peer system ${GATE_L4_PEER}" \
    "to-local local ${GATE_L4_OWNER}" \
    "back-to-system system ${GATE_L4_OWNER}"
do
    read -r st mode who <<< "${spec}"
    vid="L4-$(printf '%s' "${st}" | tr '[:lower:]' '[:upper:]')"
    if [ -n "${failed}" ]; then
        res="${res} ${st}=not-run"
        continue
    fi
    if [ "${mode}" = local ]; then
        capture "l4-${st}" local_as 300 "${who}" "${uc}" l4-step.bash \
            "${GATE_EPICS_ENV}" "${GATE_IOC_MODE}" "${who}" "${st}"
    else
        capture "l4-${st}" sys_as 300 "${who}" l4-step.bash \
            "${GATE_EPICS_ENV}" "${GATE_IOC_MODE}" "${who}" "${st}"
    fi
    relay "l4-${st}" "${vid}"
    v="$(verdict_of "l4-${st}" "${vid}")"
    res="${res} ${st}=${v:-none}"
    [ "${v}" = PASS ] || failed="${st}"
done

if [ -z "${failed}" ]; then vrc=0; else vrc=1; fi
verdict L4 "${vrc}" "${GATE_IOC_MODE} carried between modes by ${GATE_L4_OWNER} and ${GATE_L4_PEER}:${res}"
