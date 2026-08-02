#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# L2, and the peer half of L3, run as the ACTOR against the OWNER's uniquely
# named IOC. Every path below names the owner, never the actor: if the actor's
# own IOC were named here the negative would prove nothing.
#
# L3's verdict combines this half with the owner half; control/l2-l3.bash makes
# both invocations and prints it.
#
# $1 setEpicsEnv path   $2 owner ioc name   $3 principal (the actor)
# $4 owner user   $5 owner uid
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" L2 L3-PEER

printf '%s\n' "### actor=$(id -un) owner=$4 owner-ioc=$2"

printf '%s\n' "### L2 attach"
c="$(cap_path l2-attach)"
console 20 "ioc-runner --local attach $2" "${c}"; att_rc=$?; printf '%s\n' "### attach rc=${att_rc}"
grep -qaF "Configuration for $2 not found" "${c}.clean"; att_msg=$?

printf '%s\n' "### L2 stop"
c="$(cap_path l2-stop)"
console 20 "ioc-runner --local stop $2" "${c}"; stp_rc=$?; printf '%s\n' "### stop rc=${stp_rc}"
grep -qaF "No configuration found for IOC '$2'" "${c}.clean"; stp_msg=$?

# Refused at configuration resolution, in the actor's own ~/.config/procServ.d,
# exit 1 - neither call reaches the socket path or addresses a user unit.
if [ "${att_rc}" -eq 1 ] && [ "${att_msg}" -eq 0 ] && [ "${stp_rc}" -eq 1 ] && [ "${stp_msg}" -eq 0 ]; then vrc=0; else vrc=1; fi
verdict L2 "${vrc}" "attach rc=${att_rc} message=${att_msg}, stop rc=${stp_rc} message=${stp_msg} (0 means the expected wording was found)"

printf '%s\n' "### L3 peer stat of owner log"
stat -c '%U:%G %a %n' "/home/$4/.local/state/procserv/$2.log"; pstat=$?
printf '%s\n' "### peer stat rc=${pstat}"
printf '%s\n' "### L3 peer read of owner log"
head -c 40 "/home/$4/.local/state/procserv/$2.log" >/dev/null; pread=$?
printf '%s\n' "### peer read rc=${pread}"

# The home mode is a distribution default the account fixture never promised.
# Observed, never asserted: a 0755 home is not a failure while the log mode holds.
printf '%s\n' "### owner home mode (observed, not asserted)"
stat -c '%a %n' "/home/$4"; printf '%s\n' "### home stat rc=$?"

# A 0700 runtime directory can only be probed by its owner, so this listing is
# recorded and not judged.
printf '%s\n' "### owner runtime socket dir (observed, not asserted)"
ls "/run/user/$5/procserv/$2/"; printf '%s\n' "### socket ls rc=$?"

printf '%s\n' "### actor own listing"
plain "$(cap_path list)" ioc-runner --local list; printf '%s\n' "### list rc=$?"

if [ "${pstat}" -ne 0 ] && [ "${pread}" -ne 0 ]; then vrc=0; else vrc=1; fi
verdict L3-PEER "${vrc}" "peer stat rc=${pstat} peer read rc=${pread}, both must be nonzero"
