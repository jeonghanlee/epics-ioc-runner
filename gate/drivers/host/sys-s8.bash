#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S8 - the extra crash pattern. Self-contained: this scenario builds its own IOC
# and inherits no directory from an earlier one, because its payload carries the
# token.
#
# Order matters and is easy to get wrong: the runner re-reads the pattern from
# the INSTALLED configuration under /etc/procServ.d, so appending after the
# install leaves the token where nothing reads it and a scenario that never ran
# records as a clean pass. Create, generate, append, install, then start.
#
# The warning text is generic and does not name the token, and other scenarios'
# IOCs can raise the same wording, so the causal link is established here: the
# token is in the installed configuration, and the token is in THIS IOC's log.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal   $4 crash token
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" S8

boot="/opt/epics-iocs/$2"; rm -rf "${boot}"; mkdir -p "${boot}"; chmod 2775 "${boot}"
printf '#!%s\niocInit\nsystem "echo %s"\n' "$(command -v softIoc)" "$4" > "${boot}/st.cmd"
chmod 0775 "${boot}/st.cmd"
printf '%s\n' "### actor=$(id -un) token=$4"
cat "${boot}/st.cmd"

ioc-runner generate "${boot}"; printf '%s\n' "### generate rc=$?"
printf 'CRASH_LOG_PATTERNS_EXTRA="%s"\n' "$4" >> "${boot}/$2.conf"
console 60 "ioc-runner install ${boot}/$2.conf" "$(cap_path install)"; ins_rc=$?
printf '%s\n' "### install rc=${ins_rc}"

printf '%s\n' "### token in the INSTALLED configuration"
grep -aF 'CRASH_LOG_PATTERNS_EXTRA' "/etc/procServ.d/$2.conf"; printf '%s\n' "### grep rc=$?"
grep -qaF "$4" "/etc/procServ.d/$2.conf"; conf_tok=$?

st="$(cap_path start)"
console 90 "ioc-runner start $2" "${st}"; sta_rc=$?; printf '%s\n' "### start rc=${sta_rc}"
# The warning is raised inside the start poll. Its wording is generic by design,
# so it is matched generically and the token reads below carry the attribution.
grep -qai 'warn' "${st}.clean"; warned=$?
printf '%s\n' "### start warning ${warned}"

printf '%s\n' "### token in this IOC's log"
n="$(grep -acF "$4" "/var/log/procserv/$2.log" 2>/dev/null)"; n="${n:-0}"
printf '%s\n' "### logscan count=${n}"

if [ "${ins_rc}" -eq 0 ] && [ "${conf_tok}" -eq 0 ] && [ "${sta_rc}" -eq 0 ] \
    && [ "${warned}" -eq 0 ] && [ "${n}" -ge 1 ]; then vrc=0; else vrc=1; fi
verdict S8 "${vrc}" "install=${ins_rc} token-in-installed-conf=${conf_tok} start=${sta_rc} warning-raised=${warned} token-in-this-log=${n}"
