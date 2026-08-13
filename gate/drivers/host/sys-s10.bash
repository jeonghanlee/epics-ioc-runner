#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S10 - the console socket access probe, one half per principal.
#
# A successful member attach or monitor ends when the wrapper's own timeout kills
# it, so its exit code is the WRAPPER's and not the verb's. This driver ignores
# the code for those two verbs and judges by the connection banner, which names
# the IOC. inspect is different: its root gate fires before the configuration
# gate, so every non-root principal is refused regardless of group.
#
# Per-distribution wording and exit codes are not asserted.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal   $4 role: member or observer
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

case "$4" in
    member)   vid="S10-MEMBER";;
    observer) vid="S10-OBSERVER";;
    *)        printf '%s\n' "### unknown role $4"; exit 2;;
esac
require_principal "$3" "${vid}"

printf '%s\n' "### actor=$(id -un) role=$4 groups=$(id -nG)"

printf '%s\n' "### S10 attach"
a="$(cap_path attach)"
console 15 "ioc-runner attach $2" "${a}"; a_rc=$?; printf '%s\n' "### attach rc=${a_rc}"
grep -qaF "Child \"$2\"" "${a}.clean"; a_ban=$?
printf '%s\n' "### attach banner ${a_ban}"

printf '%s\n' "### S10 monitor"
m="$(cap_path monitor)"
console 15 "ioc-runner monitor $2" "${m}"; m_rc=$?; printf '%s\n' "### monitor rc=${m_rc}"
grep -qaF "Child \"$2\"" "${m}.clean"; m_ban=$?
printf '%s\n' "### monitor banner ${m_ban}"

printf '%s\n' "### S10 inspect"
i="$(cap_path inspect)"
console 15 "ioc-runner inspect $2" "${i}"; i_rc=$?; printf '%s\n' "### inspect rc=${i_rc}"

printf '%s\n' "### S10 socket permissions"
sock="$(stat -c '%U:%G %a' "/run/procserv/$2/control" 2>/dev/null)"
stat -c '%U:%G %a %n' "/run/procserv/$2" "/run/procserv/$2/control"; printf '%s\n' "### stat rc=$?"

if [ "$4" = member ]; then
    # The socket path is only readable from inside ioc, so its modes are asserted
    # on this half and merely recorded on the other.
    [ "${a_ban}" -eq 0 ] && [ "${m_ban}" -eq 0 ] && [ "${i_rc}" -ne 0 ] \
        && [ "${sock}" = "ioc-srv:ioc 660" ]
    verdict "${vid}" "$?" "banner attach=${a_ban} monitor=${m_ban} (wrapper owns the codes, ignored: attach rc=${a_rc} monitor rc=${m_rc}), inspect rc=${i_rc}, control socket=${sock:-unreadable}"
else
    # Denied at configuration resolution first, so the socket path is a second
    # gate this principal never reaches.
    [ "${a_ban}" -ne 0 ] && [ "${a_rc}" -ne 0 ] && [ "${m_ban}" -ne 0 ] \
        && [ "${m_rc}" -ne 0 ] && [ "${i_rc}" -ne 0 ]
    verdict "${vid}" "$?" "no banner (attach=${a_ban} monitor=${m_ban}), attach rc=${a_rc} monitor rc=${m_rc} inspect rc=${i_rc}, control socket=${sock:-unreadable}"
fi
