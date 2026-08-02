#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S4 client half - hold a console, fully detached from the driving connection.
#
# Both halves of the client, the fifo feeder and the attach, are detached and
# carry their own redirection. A feeder left attached holds the driving
# connection's output open, so the driver stalls until the client's own budget
# expires and the attempt dies as a timeout that looks like a product failure.
#
# The result file is removed first: a leftover from a dead attempt satisfies the
# attachment check for a client that never launched, so the removal races
# nothing and the scenario silently records a pass.
#
# The wait loop is why this ends here and not one line earlier. A detached
# `script` has written nothing at the instant it is launched. It is bounded, so
# the case it exists to catch ends at the deadline instead of hanging.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal (the second operator)
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" S4-CLIENT

out="$(s4_out)"; fifo="$(s4_fifo)"
rm -f "${fifo}" "${out}"; mkfifo "${fifo}"
setsid bash -c "sleep 120 > ${fifo}" < /dev/null > /dev/null 2>&1 &
setsid bash -c "timeout -k 2 120 script -qec 'ioc-runner attach $2' /dev/null < ${fifo} > ${out} 2>&1; echo client_rc=\$? >> ${out}" < /dev/null > /dev/null 2>&1 &
for _i in $(seq 30); do
    grep -qaF "Child \"$2\"" "${out}" 2>/dev/null && break
    sleep 1
done
# The result file is written by one operator and read by the other.
chmod 0644 "${out}" 2>/dev/null
printf '%s\n' "### s4-out ${out}"

# The banner names the IOC, so a stale file from a different attempt cannot
# satisfy this.
grep -qaF "Child \"$2\"" "${out}"; att=$?
verdict S4-CLIENT "${att}" "held console on $2 as $(id -un), connection banner found=${att}, result file ${out}"
