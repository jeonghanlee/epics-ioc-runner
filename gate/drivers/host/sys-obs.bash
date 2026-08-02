#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S6 - the observer negative control. Reads and systemd queries succeed; start
# is denied at the sudo gate; stop and remove are denied earlier still, at
# configuration resolution, exit 1. The exit code of each is the observation, so
# every one is captured rather than only its text.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal (the observer)
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" S6

printf '%s\n' "### actor=$(id -un) groups=$(id -nG)"

printf '%s\n' "### S6 status"
ioc-runner status "$2"; printf '%s\n' "### status rc=$?"
printf '%s\n' "### S6 systemctl is-active"
act="$(systemctl is-active "epics-@$2.service")"; printf '%s\n' "### is-active ${act}"
printf '%s\n' "### S6 log read"
head -c 40 "/var/log/procserv/$2.log" >/dev/null; rd_rc=$?; printf '%s\n' "### log read rc=${rd_rc}"

printf '%s\n' "### S6 list"
lst="$(cap_path list)"
plain "${lst}" ioc-runner list; lst_rc=$?; printf '%s\n' "### list rc=${lst_rc}"
rows="$(list_rows "${lst}.clean")"; printf '%s\n' "### listing-rows ${rows}"

printf '%s\n' "### S6 start (expect denial at the sudo gate)"
console 30 "ioc-runner start $2" "$(cap_path start)"; sta_rc=$?; printf '%s\n' "### start rc=${sta_rc}"
printf '%s\n' "### S6 stop (expect denial at configuration resolution)"
console 30 "ioc-runner stop $2" "$(cap_path stop)"; stp_rc=$?; printf '%s\n' "### stop rc=${stp_rc}"
printf '%s\n' "### S6 remove (expect denial at configuration resolution)"
console 30 "ioc-runner remove $2" "$(cap_path remove)"; rem_rc=$?; printf '%s\n' "### remove rc=${rem_rc}"

printf '%s\n' "### S6 conf dir listing"
ls /etc/procServ.d/; printf '%s\n' "### ls rc=$?"

# With IOCs running the listing returns empty plus the permission hint, exit 0:
# the 0770 socket directories are not traversable outside ioc.
if [ "${act}" = "active" ] && [ "${rd_rc}" -eq 0 ] && [ "${lst_rc}" -eq 0 ] && [ "${rows}" -eq 0 ] \
    && [ "${sta_rc}" -ne 0 ] && [ "${stp_rc}" -eq 1 ] && [ "${rem_rc}" -eq 1 ]; then vrc=0; else vrc=1; fi
verdict S6 "${vrc}" "is-active=${act} log-read=${rd_rc} list=${lst_rc} rows=${rows} start=${sta_rc} stop=${stp_rc} remove=${rem_rc}"
