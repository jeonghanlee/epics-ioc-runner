#!/bin/bash
# S3 - concurrency. Two operators act on different IOCs at the same time, each
# on the IOC it installed. A sequential run proves nothing about concurrency, so
# both are launched and the pair is waited for.
#
# Both output paths are ABSOLUTE. What this replaces was never a file: it was
# one inline line whose `cd <dir> && ( A ) &` bound the `cd` to the first
# background job only, so the second subshell ran in the shell's own working
# directory - during the 2026-08-01 run, the repository working tree - and
# dropped its output file there.
#
# The verdict reads the printed WORD against an inverted exit code.
# `systemctl is-failed` on a healthy unit prints `active` and exits nonzero, so
# a verdict taken from the code is wrong on every good run. `failed` is the
# failure; anything else is not.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

a_out="${GATE_LOG_DIR}/s3a.raw"
b_out="${GATE_LOG_DIR}/s3b.raw"

timeout 200 "${GATE_SSH[@]}" "${GATE_HOST}" \
    "sudo -niu ${GATE_OP_A} bash -c 'timeout -k 2 60 script -qec \"ioc-runner restart ${GATE_S3_OP_A_IOC}\" /dev/null </dev/null'" \
    > "${a_out}" 2>&1 &
pid_a=$!
timeout 200 "${GATE_SSH[@]}" "${GATE_HOST}" \
    "sudo -niu ${GATE_OP_B} bash -c 'timeout -k 2 60 script -qec \"ioc-runner restart ${GATE_S3_OP_B_IOC}\" /dev/null </dev/null'" \
    > "${b_out}" 2>&1 &
pid_b=$!
wait "${pid_a}"; rc_a=$?
wait "${pid_b}"; rc_b=$?

# A backgrounded call cannot be wrapped by `capture`, so the two raws above are
# written by direct redirection and their read forms are derived here, once both
# have been waited for. Without this the only captures in a run with no .txt and
# no .clean are these two, against the runbook's three files per capture.
read_forms s3a
read_forms s3b

printf '%s\n' "=== s3a (${GATE_OP_A} on ${GATE_S3_OP_A_IOC}) rc=${rc_a} ==="
cat -v "${a_out}" | tail -4
printf '%s\n' "=== s3b (${GATE_OP_B} on ${GATE_S3_OP_B_IOC}) rc=${rc_b} ==="
cat -v "${b_out}" | tail -4

capture s3-post timeout 60 "${GATE_SSH[@]}" "${GATE_HOST}" \
    "echo '--- is-active'; systemctl is-active epics-@${GATE_S3_OP_A_IOC}.service epics-@${GATE_S3_OP_B_IOC}.service; echo '--- is-failed'; systemctl is-failed epics-@${GATE_S3_OP_A_IOC}.service epics-@${GATE_S3_OP_B_IOC}.service"
cat "${GATE_LOG_DIR}/s3-post.txt"

clean="${GATE_LOG_DIR}/s3-post.clean"
n_active="$(sed -n '/^--- is-active$/,/^--- is-failed$/p' "${clean}" | grep -cx 'active')"
n_failed="$(sed -n '/^--- is-failed$/,$p' "${clean}" | grep -cx 'failed')"

if [ "${rc_a}" -eq 0 ] && [ "${rc_b}" -eq 0 ] && [ "${n_active}" -eq 2 ] && [ "${n_failed}" -eq 0 ]; then vrc=0; else vrc=1; fi
verdict S3 "${vrc}" "restart rc ${GATE_OP_A}/${GATE_S3_OP_A_IOC}=${rc_a} ${GATE_OP_B}/${GATE_S3_OP_B_IOC}=${rc_b}; is-active printed 'active' for ${n_active} of 2; is-failed printed 'failed' for ${n_failed} of 2 - the printed word decides, is-failed's own exit code inverts"
