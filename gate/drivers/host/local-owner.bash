#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# L3 owner half - the mode the actor could not see. The 0640 <user>:<user> log
# mode is the boundary the product owns, so it is asserted here; the peer denial
# is asserted in local-actor.bash and control/l2-l3.bash combines the two.
#
# $1 setEpicsEnv path   $2 owner ioc name   $3 principal (the owner)
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" L3-OWNER

printf '%s\n' "### owner=$(id -un)"
log="${HOME}/.local/state/procserv/$2.log"
mode="$(stat -c '%a' "${log}" 2>/dev/null)"
ug="$(stat -c '%U:%G' "${log}" 2>/dev/null)"
stat -c '%U:%G %a %n' "${log}"; printf '%s\n' "### owner stat rc=$?"
printf '%s\n' "### l3-owner-log ${ug:-none} ${mode:-none}"

printf '%s\n' "### owner socket dir"
ls -ld "/run/user/$(id -u)/procserv/$2" "/run/user/$(id -u)/procserv/$2/control"
printf '%s\n' "### owner socket rc=$?"

printf '%s\n' "### owner listing"
plain "$(cap_path list)" ioc-runner --local list; printf '%s\n' "### list rc=$?"

if [ "${mode}" = "640" ] && [ "${ug}" = "$(id -un):$(id -gn)" ]; then vrc=0; else vrc=1; fi
verdict L3-OWNER "${vrc}" "owner log mode=${mode:-none} owner=${ug:-none}, expected 640 $(id -un):$(id -gn)"
