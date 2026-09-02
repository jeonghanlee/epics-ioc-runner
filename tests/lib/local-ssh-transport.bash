#!/usr/bin/env bash
# Executes one SSH remote command locally for push-driver transport tests.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
umask 077
unset BASH_ENV ENV CDPATH

declare -g stdin_null=0
declare -g remote_command=""
declare -g remote_rc=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n)
            stdin_null=1
            shift
            ;;
        -o)
            [[ $# -ge 2 ]] || exit 2
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            exit 2
            ;;
        *)
            break
            ;;
    esac
done

[[ $# -eq 2 ]] || exit 2
shift
remote_command="$1"

if [[ ${stdin_null} -eq 1 ]]; then
    /bin/bash -c "${remote_command}" </dev/null || remote_rc=$?
else
    /bin/bash -c "${remote_command}" || remote_rc=$?
fi
if [[ ${remote_rc} -ne 0 ]]; then
    exit "${remote_rc}"
fi

if [[ "${PUSH_TEST_MUTATE_REMOTE:-0}" == "1" ]] \
   && [[ "${remote_command}" == tar\ -C* ]]; then
    [[ -n "${PUSH_TEST_MUTATE_PATH:-}" ]] || exit 2
    printf '%s\n' "remote mutation" >> "${PUSH_TEST_MUTATE_PATH}"
fi
