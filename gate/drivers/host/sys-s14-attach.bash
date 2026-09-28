#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S14 attach half, as the first operator, while the second operator monitors.
#
# The attach selects Ctrl-B as its detach key, types a command whose output the
# monitor must also receive, sends Ctrl-C and Ctrl-D, which procServ's ignore set
# discards, and detaches with Ctrl-B. The procServ and IOC process IDs and the
# unit state must be the same afterwards. Then an attach that selects Ctrl-[ is
# refused before any client is started.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal (the first operator)   $4 the distinctive value
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" S14-ATTACH

unit="epics-@$2.service"
function pids {
    local main
    main="$(systemctl show -p MainPID --value "${unit}" 2>/dev/null)"
    printf '%s/%s' "${main:-0}" "$(pgrep -P "${main:-0}" 2>/dev/null | head -1)"
}

printf '%s\n' "### actor=$(id -un)"
before="$(pids)"; act_b="$(systemctl is-active "${unit}")"
printf '%s\n' "### before pids=${before} active=${act_b}"

att="$(cap_path attach)"
console_fed 60 "ioc-runner attach $2 --detach-key ctrl-b" "${att}" \
    "epicsEnvSet GATE_S14_MARK $4\r" "epicsEnvShow GATE_S14_MARK\r" "\003" "\004" "\002"; arc=$?
printf '%s\n' "### attach rc=${arc}"
grep -qaF "GATE_S14_MARK=$4" "${att}.clean"; typed=$?

sleep 2
after="$(pids)"; act_a="$(systemctl is-active "${unit}")"
printf '%s\n' "### after pids=${after} active=${act_a}"

bad="$(cap_path bad-key)"
plain "${bad}" ioc-runner attach "$2" --detach-key 'ctrl-['; brc=$?
grep -qaF 'Invalid detach key' "${bad}.clean"; refused=$?
grep -qaF "Child \"$2\"" "${bad}.clean"; connected=$?
printf '%s\n' "### ctrl-[ rc=${brc} refused=${refused} connected=${connected}"

if [ "${arc}" -eq 0 ] && [ "${typed}" -eq 0 ] && [ "${before}" = "${after}" ] && [ "${before%%/*}" != 0 ] \
    && [ "${act_a}" = active ] && [ "${brc}" -eq 1 ] && [ "${refused}" -eq 0 ] && [ "${connected}" -ne 0 ]; then vrc=0; else vrc=1; fi
verdict S14-ATTACH "${vrc}" "attach with ctrl-b rc=${arc} command echoed=${typed}; Ctrl-C and Ctrl-D ignored: pids ${before} -> ${after}, unit ${act_b} -> ${act_a}; ctrl-[ rc=${brc} refused=${refused} never connected=${connected}"
