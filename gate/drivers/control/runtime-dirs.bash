#!/bin/bash
# Force the local users' runtime directories, before any local-mode driver runs.
#
# One of the three parts of the run that had no driver at all. The directory can
# lag a few seconds behind linger being enabled, and `systemctl start user@<uid>`
# is privileged: issued unprivileged over a connection with no terminal it
# answers `Interactive authentication required` and fails outright rather than
# asking, so it is issued through the driving account's sudo.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

ua="$(gate_uid "${GATE_USER_A}")"
ub="$(gate_uid "${GATE_USER_B}")"
printf '%s\n' "### uids ${GATE_USER_A}=${ua} ${GATE_USER_B}=${ub}"

capture runtime-dirs timeout 60 "${GATE_SSH[@]}" "${GATE_HOST}" \
    "sudo -n systemctl start user@${ua}; echo start-${ua}-rc=\$?; sudo -n systemctl start user@${ub}; echo start-${ub}-rc=\$?; ls -ld /run/user/${ua} /run/user/${ub}"
cat "${GATE_LOG_DIR}/runtime-dirs.txt"

n="$(grep -ac "^d.* /run/user/" "${GATE_LOG_DIR}/runtime-dirs.clean")"
if [ -n "${ua}" ] && [ -n "${ub}" ] && [ "${n}" -ge 2 ]; then vrc=0; else vrc=1; fi
verdict P-RUNTIME "${vrc}" "runtime directories for ${GATE_USER_A}=${ua} and ${GATE_USER_B}=${ub}, listing rows=${n} of 2"
