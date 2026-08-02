#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S9 operator half - the two non-conforming shapes.
#
# The payload is built in the operator's own home, which is what makes the
# working directory non-conforming; the directory must carry st.cmd or the
# install aborts on a missing command long before it reaches the conformance
# question the scenario is about.
#
# Judged by the printed verdict, never by an exit code: all three cases exit
# nonzero and they exit alike, so the code separates a declined conformance
# prompt from a hard error not at all.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal (the operator)
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" S9-OPERATOR

boot="${HOME}/iocBoot/$2"; rm -rf "${boot}"; mkdir -p "${boot}"
printf '#!%s\niocInit\n' "$(command -v softIoc)" > "${boot}/st.cmd"; chmod +x "${boot}/st.cmd"
printf '%s\n' "### actor=$(id -un) boot=${boot}"
printf '%s\n' "### s9-conf ${boot}/$2.conf"
ioc-runner generate "${boot}"; printf '%s\n' "### generate rc=$?"

printf '%s\n' "### S9 case 1: non-writable working directory, expect warning then EOF abort"
c1="$(cap_path case1)"
console 40 "ioc-runner install ${boot}/$2.conf" "${c1}"; printf '%s\n' "### install-nonconforming rc=$?"
grep -qaF 'is not writable by' "${c1}.clean"; w1=$?
grep -qaF 'Aborting installation' "${c1}.clean"; a1=$?

sed -i "s|^IOC_CHDIR=.*|IOC_CHDIR=\"${HOME}/iocBoot/../iocBoot/$2\"|" "${boot}/$2.conf"
grep '^IOC_CHDIR=' "${boot}/$2.conf"

printf '%s\n' "### S9 case 2: parent reference, expect a hard error with no prompt"
c2="$(cap_path case2)"
console 40 "ioc-runner install ${boot}/$2.conf" "${c2}"; printf '%s\n' "### install-parentref rc=$?"
grep -qaF "contains a '..' component" "${c2}.clean"; e2=$?
grep -qaF 'is not writable by' "${c2}.clean"; n2=$?

printf '%s\n' "### S9 case 2 with --force, expect the same hard error"
c3="$(cap_path case3)"
console 40 "ioc-runner install --force ${boot}/$2.conf" "${c3}"; printf '%s\n' "### install-parentref-force rc=$?"
grep -qaF "contains a '..' component" "${c3}.clean"; e3=$?

if [ "${w1}" -eq 0 ] && [ "${a1}" -eq 0 ] && [ "${e2}" -eq 0 ] && [ "${n2}" -ne 0 ] && [ "${e3}" -eq 0 ]; then vrc=0; else vrc=1; fi
verdict S9-OPERATOR "${vrc}" "non-writable: warning=${w1} abort=${a1}; parent reference: hard error=${e2} nothing prompted ahead of it=${n2}; under --force: hard error=${e3}"
