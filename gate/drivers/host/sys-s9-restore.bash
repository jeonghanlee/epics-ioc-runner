#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S9 - operator-side rewrite of IOC_CHDIR, run before each root install. By the
# end of the operator half the configuration holds only the parent-reference
# shape, and the scenario's claim is that the operator and root reach identical
# verdicts on BOTH shapes, so each shape is restored before root sees it.
#
# The two sed lines run as the operator, who owns the file.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal (the operator)
# $4 shape: conforming or parentref
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" P-S9-RESTORE

conf="${HOME}/iocBoot/$2/$2.conf"
case "$4" in
    conforming) want="${HOME}/iocBoot/$2";;
    parentref)  want="${HOME}/iocBoot/../iocBoot/$2";;
    *)          printf '%s\n' "### unknown shape $4"; exit 2;;
esac

sed -i "s|^IOC_CHDIR=.*|IOC_CHDIR=\"${want}\"|" "${conf}"; rc=$?
printf '%s\n' "### rewrite rc=${rc} shape=$4"
line="$(grep '^IOC_CHDIR=' "${conf}")"
printf '%s\n' "${line}"
printf '%s\n' "### s9-conf ${conf}"

if [ "${rc}" -eq 0 ] && [ "${line}" = "IOC_CHDIR=\"${want}\"" ]; then vrc=0; else vrc=1; fi
verdict P-S9-RESTORE "${vrc}" "shape=$4 rewrite rc=${rc} line=${line}"
