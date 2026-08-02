#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S11 - the malformed unit name, issued outside the runner by the operator.
#
# The two branches expect OPPOSITE results, so the branch is an argument: this
# driver cannot determine it, because the lookup needs sudo rights the operator
# does not have. control/s11.bash determines it as the driving account and
# passes it in. Without that the driver could report an exit code but not say
# whether it was the correct one.
#
# $2 is the ioc name for shape only; the malformed unit name is a constant.
#
# $1 setEpicsEnv path   $2 ioc name (unused)   $3 principal   $4 branch: glob or anchored
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

case "$4" in
    glob|anchored) : ;;
    *) printf '%s\n' "### unknown branch $4"; exit 2;;
esac
require_principal "$3" S11

printf '%s\n' "### actor=$(id -un) branch=$4 ioc-under-test=$2"
c="$(cap_path start)"
plain "${c}" sudo -n systemctl start 'epics-@bad name.service'; rc=$?
printf '%s\n' "### start rc=${rc}"

if [ "$4" = glob ]; then
    # The sudo gate passes and systemd rejects the name. The command's own output
    # is the whole evidence: no unit was ever created, so there is no unit state
    # to confirm it with, and `systemctl is-failed` on that name reads wrong twice
    # over.
    grep -qaF 'Assertion failed on job for' "${c}.clean"; ev=$?
    verdict S11 "${ev}" "glob branch: sudo gate passes, systemd refuses the job, refusal found=${ev} (rc=${rc} is not the evidence)"
else
    # The gate denies it, and the denial surfaces through the sudoers catch-all
    # as a password demand. That is the denial, not a harness fault.
    grep -qaF 'a password is required' "${c}.clean"; ev=$?
    [ "${ev}" -eq 0 ] && [ "${rc}" -ne 0 ]
    verdict S11 "$?" "anchored branch: denied at the sudo gate, password fallthrough found=${ev} rc=${rc}"
fi
