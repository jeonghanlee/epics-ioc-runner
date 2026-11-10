#!/bin/bash -p
# Run the real console client inside script(1)'s terminal and record its exit.
set -eu
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
unset BASH_ENV ENV IOC_RUNNER_CON_TOOL
umask 077

case "$1" in
    --without-con)
        shift
        empty="$1"
        shift
        # These mounts exist only in the caller's private mount namespace.
        for candidate in "${HOME}/.local/bin/con" /usr/local/bin/con /usr/bin/con; do
            if [[ -e "${candidate}" ]]; then
                mount --bind "${empty}" "${candidate}"
            fi
        done
        ;;
esac

result_dir="$1"
shift
stty -echo
stty -g > "${result_dir}/before"
printf '%s\n' "${BASHPID}" > "${result_dir}/wrapper.pid"
# A caught signal lets the wrapper inspect the terminal after socat receives
# the PTY's Ctrl-C. The foreground external command retains default handling.
trap ':' INT
rc=0
"$@" || rc=$?
stty -g > "${result_dir}/after"
printf '%s\n' "${rc}" > "${result_dir}/exit"
exit "${rc}"
