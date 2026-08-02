#!/bin/bash
# The shared IOC must still be there after S6's refused removal, before S10 and
# S11 run against it.
#
# One of the three parts of the run that had no driver at all. A FAIL here is
# attributed to S6, whose refusal it measures, and not to the scenarios that
# would then fail for want of a target.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

capture survival timeout 60 "${GATE_SSH[@]}" "${GATE_HOST}" \
    "systemctl is-active epics-@${GATE_IOC_SHARED}.service; ls -d /run/procserv/${GATE_IOC_SHARED}; sudo -n ls /etc/procServ.d/"
cat "${GATE_LOG_DIR}/survival.txt"

hasline survival "active"; unit=$?
has survival "/run/procserv/${GATE_IOC_SHARED}"; sock=$?
has survival "${GATE_IOC_SHARED}.conf"; conf=$?

if [ "${unit}" -eq 0 ] && [ "${sock}" -eq 0 ] && [ "${conf}" -eq 0 ]; then vrc=0; else vrc=1; fi
verdict P-SURVIVAL "${vrc}" "${GATE_IOC_SHARED} survived S6's refused removal: unit active=${unit} socket dir=${sock} configuration=${conf} (a FAIL here is S6's)"
