#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S7 second half - the manual run by hand, then start and enable. The manual run
# needs held input or the shell exits at once; its own exit code is the held
# input's timeout and carries nothing, so it is recorded and not judged.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal (the acting operator)
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" S7-B

printf '%s\n' "### actor=$(id -un)"
printf '%s\n' "### manual st.cmd run with held input"
cd "/opt/epics-iocs/$2" && timeout -k 2 20 bash -c "sleep 6 | ./st.cmd"; man=$?
printf '%s\n' "### manual rc=${man} (recorded, not asserted)"

console 90 "ioc-runner start $2" "$(cap_path start)"; sta=$?; printf '%s\n' "### start rc=${sta}"
console 40 "ioc-runner enable $2" "$(cap_path enable)"; ena=$?; printf '%s\n' "### enable rc=${ena}"

md5a="$(md5sum "/etc/procServ.d/$2.conf" 2>/dev/null | awk '{print $1}')"
printf '%s\n' "### md5-after ${md5a:-none}"

if [ "${sta}" -eq 0 ] && [ "${ena}" -eq 0 ] && [ -n "${md5a}" ]; then vrc=0; else vrc=1; fi
verdict S7-B "${vrc}" "manual=${man} start=${sta} enable=${ena} configuration md5 after=${md5a:-none}"
