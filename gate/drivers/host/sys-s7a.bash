#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S7 first half - the acting operator disables and stops. The configuration hash
# is taken here and again in sys-s7b.bash; control/s7.bash compares the two,
# because S7's claim is that only runtime state moves.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal (the acting operator)
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" S7-A

printf '%s\n' "### actor=$(id -un)"
md5b="$(md5sum "/etc/procServ.d/$2.conf" 2>/dev/null | awk '{print $1}')"
printf '%s\n' "### md5-before ${md5b:-none}"

console 40 "ioc-runner disable $2" "$(cap_path disable)"; dis=$?; printf '%s\n' "### disable rc=${dis}"
console 40 "ioc-runner stop $2" "$(cap_path stop)"; stp=$?; printf '%s\n' "### stop rc=${stp}"

if [ -n "${md5b}" ] && [ "${dis}" -eq 0 ] && [ "${stp}" -eq 0 ]; then vrc=0; else vrc=1; fi
verdict S7-A "${vrc}" "disable=${dis} stop=${stp} configuration md5 before=${md5b:-none}"
