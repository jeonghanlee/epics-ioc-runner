#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S15 - the second operator regenerates the shared IOC's payload, whose
# configuration the first operator generated. The content is identical, so the
# runner rewrites it and hands it to the invoking user: without -f it names the
# owner, and on a closed standard input it exits 1 and leaves the file; with -f
# it takes the file over at mode 0660, group ioc.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal (the second operator)   $4 the owner expected before
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" S15

boot="/opt/epics-iocs/$2"; conf="${boot}/$2.conf"
before="$(stat -c '%U' "${conf}" 2>&1)"
printf '%s\n' "### actor=$(id -un) owner-before=${before}"

ask="$(cap_path ask)"
(cd "${boot}" && plain "${ask}" ioc-runner generate . < /dev/null); ask_rc=$?
grep -qaF "It is owned by $4;" "${ask}.clean"; named=$?
kept="$(stat -c '%U' "${conf}" 2>&1)"
printf '%s\n' "### ask rc=${ask_rc} owner-named=${named} owner-after-refusal=${kept}"

take="$(cap_path take)"
(cd "${boot}" && plain "${take}" ioc-runner -f generate . < /dev/null); take_rc=$?
after="$(stat -c '%a %U %G' "${conf}" 2>&1)"
printf '%s\n' "### take rc=${take_rc} after=${after}"

if [ "${before}" = "$4" ] && [ "${ask_rc}" -eq 1 ] && [ "${named}" -eq 0 ] && [ "${kept}" = "$4" ] \
    && [ "${take_rc}" -eq 0 ] && [ "${after}" = "660 $(id -un) ioc" ]; then vrc=0; else vrc=1; fi
verdict S15 "${vrc}" "owner before=${before}; without -f rc=${ask_rc} owner named=${named} owner kept=${kept}; with -f rc=${take_rc} after=${after}, expected 660 $(id -un) ioc"
