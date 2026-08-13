#!/bin/bash
# Between-runs cleanup: the system operator first, then each local user. The
# same loop serves both modes and the local users need theirs, or their IOCs
# stay installed and running into the next run.
#
# The runner empties /etc/procServ.d and never reaches the payload directories,
# so what is left of them is LISTED here and removed nowhere: a driver that
# deletes trees under two roots on a host it did not build is not what this
# milestone is buying. The runbook names both paths and the operator clears them.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

capture cleanup-system sys_as 300 "${GATE_OP_A}" cleanup.bash \
    "${GATE_EPICS_ENV}" system "${GATE_OP_A}"
relay cleanup-system "P-CLEANUP-${GATE_OP_A}"

ua="$(gate_uid "${GATE_USER_A}")"
ub="$(gate_uid "${GATE_USER_B}")"

capture cleanup-usera local_as 300 "${GATE_USER_A}" "${ua}" cleanup.bash \
    "${GATE_EPICS_ENV}" local "${GATE_USER_A}"
relay cleanup-usera "P-CLEANUP-${GATE_USER_A}"

capture cleanup-userb local_as 300 "${GATE_USER_B}" "${ub}" cleanup.bash \
    "${GATE_EPICS_ENV}" local "${GATE_USER_B}"
relay cleanup-userb "P-CLEANUP-${GATE_USER_B}"

printf '%s\n' "### payload directories the runner does not reach"
capture cleanup-payloads timeout 60 "${GATE_SSH[@]}" "${GATE_HOST}" \
    "ls -1 /opt/epics-iocs/ 2>&1; sudo -n ls -1 /home/${GATE_OP_A}/iocBoot /home/${GATE_OP_B}/iocBoot /home/${GATE_USER_A}/iocBoot /home/${GATE_USER_B}/iocBoot 2>&1"
cat "${GATE_LOG_DIR}/cleanup-payloads.txt"
printf '%s\n' "### the listing above is a read; clearing it is the runbook's step"
