#!/bin/bash
# Copy the host-side drivers to the VM and open them to the principals that run
# them.
#
# A copied file keeps the mode of its source, which the destination umask can
# narrow further but never widen, so a driver written restrictively arrives
# unreadable to the principal that must run it and the switch fails with a
# permission error. The mode is set after the copy rather than left to the umask
# of the machine the driver was written on.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

"${GATE_SSH[@]}" "${GATE_HOST}" "mkdir -p '${GATE_REMOTE_DRIVERS}'" >/dev/null 2>&1

want="$(find "${GATE_DRIVERS_DIR}/host" -maxdepth 1 -name '*.bash' | wc -l)"
timeout 120 scp -q -o BatchMode=yes -o ConnectTimeout=10 \
    "${GATE_DRIVERS_DIR}"/host/*.bash "${GATE_HOST}:${GATE_REMOTE_DRIVERS}/"
cp_rc=$?
got="$("${GATE_SSH[@]}" "${GATE_HOST}" \
    "chmod 0644 ${GATE_REMOTE_DRIVERS}/*.bash 2>/dev/null; ls -1 ${GATE_REMOTE_DRIVERS}/*.bash 2>/dev/null | wc -l" | tail -1)"

printf '%s\n' "### staged ${got}/${want} to ${GATE_HOST}:${GATE_REMOTE_DRIVERS} (scp rc=${cp_rc})"
if [ "${cp_rc}" -eq 0 ] && [ "${got}" = "${want}" ]; then vrc=0; else vrc=1; fi
verdict P-STAGE "${vrc}" "host drivers copied and opened: ${got}/${want}, scp rc=${cp_rc}"
