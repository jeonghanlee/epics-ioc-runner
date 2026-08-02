#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# System payload - the shared IOC S1 through S11 act on, and the fresh IOC S3
# and S7 need. The role is an argument rather than an inference from the name:
# the two roles used to be separated only by the name that was passed in.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal   $4 role: shared or fresh
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

case "$4" in
    shared) vid="P-SHARED";;
    fresh)  vid="P-FRESH";;
    *)      printf '%s\n' "### unknown role $4"; exit 2;;
esac
require_principal "$3" "${vid}"

boot="/opt/epics-iocs/$2"; conf="${boot}/$2.conf"
rm -rf "${boot}"; mkdir -p "${boot}"; chmod 2775 "${boot}"
printf '#!%s\niocInit\n' "$(command -v softIoc)" > "${boot}/st.cmd"; chmod 0775 "${boot}/st.cmd"
printf '%s\n' "### installer=$(id -un) role=$4 softIoc=$(command -v softIoc)"

ioc-runner generate "${boot}"; gen_rc=$?; printf '%s\n' "### generate rc=${gen_rc}"
console 60 "ioc-runner install ${conf}" "$(cap_path install)"; ins_rc=$?
printf '%s\n' "### install rc=${ins_rc}"
console 90 "ioc-runner start $2" "$(cap_path start)"; sta_rc=$?
printf '%s\n' "### start rc=${sta_rc}"
ioc-runner status "$2"; st_rc=$?; printf '%s\n' "### status rc=${st_rc}"
act="$(systemctl is-active "epics-@$2.service")"
printf '%s\n' "### is-active ${act}"

if [ "${gen_rc}" -eq 0 ] && [ "${ins_rc}" -eq 0 ] && [ "${sta_rc}" -eq 0 ] \
    && [ "${st_rc}" -eq 0 ] && [ "${act}" = "active" ]; then vrc=0; else vrc=1; fi
verdict "${vid}" "${vrc}" "$2 as $(id -un) role=$4: generate=${gen_rc} install=${ins_rc} start=${sta_rc} status=${st_rc} is-active=${act}"
