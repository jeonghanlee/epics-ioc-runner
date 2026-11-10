#!/bin/bash -p
# Run the shipped runner with every fixed con search path hidden and with a
# PATH that omits the excluded console clients. The bind mounts exist only in
# the caller's private mount namespace; host installation files stay unchanged.
set -eu
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
unset BASH_ENV ENV IOC_RUNNER_CON_TOOL
umask 077

empty="$1"
bin="$2"
shift 2
for candidate in "${HOME}/.local/bin/con" /usr/local/bin/con /usr/bin/con; do
    if [[ -e "${candidate}" ]]; then
        mount --bind "${empty}" "${candidate}"
    fi
done
export PATH="${bin}"
exec /bin/bash "$@"
