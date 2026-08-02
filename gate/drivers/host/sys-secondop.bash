#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S1, S2 and S5 - run as the SECOND operator against the first operator's IOC.
# All three verdicts are computed here; every observation each needs is on this
# host under this principal.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal (the second operator)
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" S1 S2 S5

printf '%s\n' "### actor=$(id -un) groups=$(id -nG)"

printf '%s\n' "### S1 status"
ioc-runner status "$2"; sta_rc=$?; printf '%s\n' "### status rc=${sta_rc}"
printf '%s\n' "### S1 stop"
console 60 "ioc-runner stop $2" "$(cap_path s1-stop)"; stop_rc=$?; printf '%s\n' "### stop rc=${stop_rc}"
printf '%s\n' "### S1 restart"
console 90 "ioc-runner restart $2" "$(cap_path s1-restart)"; rst_rc=$?; printf '%s\n' "### restart rc=${rst_rc}"
if [ "${sta_rc}" -eq 0 ] && [ "${stop_rc}" -eq 0 ] && [ "${rst_rc}" -eq 0 ]; then vrc=0; else vrc=1; fi
verdict S1 "${vrc}" "second operator manages the first's IOC: status=${sta_rc} stop=${stop_rc} restart=${rst_rc}"

printf '%s\n' "### S2 conf dir and file before edit"
stat -c '%U:%G %a %n' /etc/procServ.d; printf '%s\n' "### dir stat rc=$?"
stat -c '%U:%G %a %n' "/etc/procServ.d/$2.conf"; printf '%s\n' "### conf stat rc=$?"
printf '%s\n' "### S2 edit by the second operator"
printf '# touched by %s\n' "$(id -un)" >> "/etc/procServ.d/$2.conf"; app_rc=$?
printf '%s\n' "### append rc=${app_rc}"
grp="$(stat -c '%G' "/etc/procServ.d/$2.conf" 2>/dev/null)"
stat -c '%U:%G %a %n' "/etc/procServ.d/$2.conf"; printf '%s\n' "### conf stat after rc=$?"
tail -1 "/etc/procServ.d/$2.conf"
# The setgid directory grants the second operator group write and the file keeps
# group ioc; that the group survived the edit is the half a bare rc cannot show.
if [ "${app_rc}" -eq 0 ] && [ "${grp}" = "ioc" ]; then vrc=0; else vrc=1; fi
verdict S2 "${vrc}" "append rc=${app_rc}, file group after the edit=${grp:-none}, expected ioc"

printf '%s\n' "### S5 log read under own identity, no sudo"
lmode="$(stat -c '%a' "/var/log/procserv/$2.log" 2>/dev/null)"
stat -c '%U:%G %a %n' "/var/log/procserv/$2.log"; lst_rc=$?; printf '%s\n' "### log stat rc=${lst_rc}"
head -c 80 "/var/log/procserv/$2.log" >/dev/null; lrd_rc=$?; printf '%s\n' "### log read rc=${lrd_rc}"
# Assert the group read bit, not a whole mode.
gbit=1
[ -n "${lmode}" ] && [ $(( (0${lmode} >> 5) & 1 )) -eq 1 ] && gbit=0
if [ "${lst_rc}" -eq 0 ] && [ "${lrd_rc}" -eq 0 ] && [ "${gbit}" -eq 0 ]; then vrc=0; else vrc=1; fi
verdict S5 "${vrc}" "log stat=${lst_rc} read=${lrd_rc} mode=${lmode:-none} group-read-bit=${gbit}"
