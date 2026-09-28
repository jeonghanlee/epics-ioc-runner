#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S12 - `ioc-runner log` on the shared IOC, one half per principal.
#
# A member of ioc reads the tail through the command. A principal outside ioc is
# refused by the command, because it resolves the IOC through /etc/procServ.d,
# which only ioc can read; the log file itself is created by procServ as 0644 and
# stays readable to that principal directly. Both halves are recorded, because
# the second is the documented file mode and not a leak the command opens.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal   $4 role: reader or observer
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

case "$4" in
    reader)   vid="S12-READER";;
    observer) vid="S12-OBSERVER";;
    *)        printf '%s\n' "### unknown role $4"; exit 2;;
esac
require_principal "$3" "${vid}"

printf '%s\n' "### actor=$(id -un) role=$4 groups=$(id -nG)"
out="$(cap_path log)"
plain "${out}" ioc-runner log "$2" -n 3; rc=$?
printf '%s\n' "### log rc=${rc}"
lines="$(grep -cav '^[[:space:]]*$' "${out}.clean")"
printf '%s\n' "### log-lines ${lines}"

case "$4" in
    reader)
        if [ "${rc}" -eq 0 ] && [ "${lines}" -ge 1 ]; then vrc=0; else vrc=1; fi
        verdict "${vid}" "${vrc}" "log rc=${rc} lines=${lines}, expected rc 0 and at least one line"
        ;;
    observer)
        grep -qaF 'ioc group membership required' "${out}.clean"; msg=$?
        head -c 1 "/var/log/procserv/$2.log" > /dev/null 2>&1; direct=$?
        printf '%s\n' "### direct-read rc=${direct} mode=$(stat -c '%U:%G %a' "/var/log/procserv/$2.log" 2>&1)"
        if [ "${rc}" -eq 1 ] && [ "${msg}" -eq 0 ] && [ "${direct}" -eq 0 ]; then vrc=0; else vrc=1; fi
        verdict "${vid}" "${vrc}" "log rc=${rc} membership message found=${msg} direct file read=${direct}, expected rc 1, the message, and a readable 0644 file"
        ;;
esac
