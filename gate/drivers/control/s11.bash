#!/bin/bash
# S11 - sudo-version residual risk.
#
# The branch determination is inside the driver rather than a separate lookup
# the operator has to remember: the two expected results are OPPOSITE, so a
# reader who guesses files a defect against correct behavior. The lookup needs
# rights the operator account does not have, so it runs as the driving account
# here and the branch is handed to the host driver as an argument.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

capture s11-branch timeout 60 "${GATE_SSH[@]}" "${GATE_HOST}" \
    'sudo --version | head -1; sudo -n grep -c "epics-@\*" /etc/sudoers.d/10-epics-ioc'
cat "${GATE_LOG_DIR}/s11-branch.txt"

# A nonzero count is the glob branch. `grep -c` exits nonzero on a count of 0,
# which is a wanted result here, so the count is read and the code is not.
n="$(tail -1 "${GATE_LOG_DIR}/s11-branch.clean")"
case "${n}" in
    ""|0)      branch=anchored;;
    *[!0-9]*)  branch=unknown;;
    *)         branch=glob;;
esac
printf '%s\n' "### s11-branch ${branch} (glob count=${n})"

if [ "${branch}" = unknown ]; then
    verdict S11 1 "the sudoers branch could not be determined; the lookup answered: ${n}"
    exit 1
fi

capture s11 sys_as 120 "${GATE_S11_ACTOR}" sys-s11.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_SHARED}" "${GATE_S11_ACTOR}" "${branch}"
relay s11 S11
