#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S4 server half - as the FIRST operator, remove the IOC underneath the held
# console, then read the client's result out of the shared per-run file.
#
# Expect the client's last lines to name the control socket and EOF, the
# recorded exit code to be 0, and the socket directory to be gone. A client that
# timed out instead records a nonzero client_rc and the wrapper's closing
# message, which is a driver failure and not a product one. Both differ by host
# and neither is asserted here: the code is 124 where the wrapper's timeout kills
# it and 137 where the kill signal is recorded instead, and the closing message
# is `Session terminated.` on one golden and `Session terminated, killing
# shell...` without a trailing newline on the other.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal (the first operator)
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" S4-SERVER

out="$(s4_out)"
printf '%s\n' "### actor=$(id -un) s4-out ${out}"

console 40 "ioc-runner remove $2 --force" "$(cap_path remove)"; rem_rc=$?
printf '%s\n' "### remove rc=${rem_rc}"

printf '%s\n' "### client tail"
tail -4 "${out}" | cat -v
grep -qaF 'EOF' "${out}"; eof=$?
grep -qaF 'client_rc=0' "${out}"; crc=$?

printf '%s\n' "### socket directory"
ls -d "/run/procserv/$2"; sock=$?; printf '%s\n' "### ls rc=${sock}"

if [ "${rem_rc}" -eq 0 ] && [ "${eof}" -eq 0 ] && [ "${crc}" -eq 0 ] && [ "${sock}" -ne 0 ]; then vrc=0; else vrc=1; fi
verdict S4-SERVER "${vrc}" "remove=${rem_rc} client EOF found=${eof} client_rc=0 found=${crc} socket directory gone=${sock}"
