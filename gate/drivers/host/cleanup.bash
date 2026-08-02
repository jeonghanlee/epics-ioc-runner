#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# Between-runs cleanup, inside the convention: the mode is an argument and not
# an undocumented environment variable, and the principal is checked before
# anything is removed.
#
# This removes IOCs THROUGH THE RUNNER, which empties /etc/procServ.d but leaves
# every payload directory behind - /opt/epics-iocs/<name> and ~/iocBoot/<name>.
# Those are the runbook's to name and to clear; a scenario that passes because a
# prior run's IOC happened to exist is the false green the gate exists to end.
#
# $1 setEpicsEnv path   $2 mode: system or local   $3 principal
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" "P-CLEANUP-$3"

case "$2" in
    system) m="";;
    local)  m="--local";;
    *)      printf '%s\n' "### unknown mode $2"; exit 2;;
esac

printf '%s\n' "### cleanup as $(id -un) mode=$2"
for n in $(ioc-runner ${m} list 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | awk 'NR>2 && NF>0 {print $1}'); do
    printf '%s\n' "### removing ${n}"
    console 40 "ioc-runner ${m} remove ${n} --force" "$(cap_path "remove-${n}")"
done

lst="$(cap_path list)"
plain "${lst}" ioc-runner ${m} list; printf '%s\n' "### list rc=$?"
rows="$(list_rows "${lst}.clean")"; printf '%s\n' "### listing-rows ${rows}"

if [ "${rows}" -eq 0 ]; then vrc=0; else vrc=1; fi
verdict "P-CLEANUP-$(id -un)" "${vrc}" "mode=$2, rows remaining=${rows}; payload directories are NOT reached by this and are cleared from the runbook"
