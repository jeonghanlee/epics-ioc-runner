#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# Local payload - both halves of L1, and the target L2 and L3 aim at.
#
# L1's verdict is a comparison across two separate invocations of this driver,
# so it is not printed here: this one prints its own precondition verdict plus
# the listing facts, and control/l1.bash computes L1 from both captures.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" P-LOCAL-PAYLOAD

boot="${HOME}/iocBoot/$2"; conf="${boot}/$2.conf"
rm -rf "${boot}"; mkdir -p "${boot}"
printf '#!%s\niocInit\n' "$(command -v softIoc)" > "${boot}/st.cmd"; chmod +x "${boot}/st.cmd"
printf '%s\n' "### softIoc=$(command -v softIoc)"

# Generate in the mode this will install in: the plain form writes the
# system-mode identity and a local install then refuses it.
ioc-runner --local generate "${boot}"; gen_rc=$?; printf '%s\n' "### generate rc=${gen_rc}"
console 60 "ioc-runner --local install ${conf}" "$(cap_path install)"; ins_rc=$?
printf '%s\n' "### install rc=${ins_rc}"
console 90 "ioc-runner --local start $2" "$(cap_path start)"; sta_rc=$?
printf '%s\n' "### start rc=${sta_rc}"

printf '%s\n' "### list as $(id -un)"
lst="$(cap_path list)"
plain "${lst}" ioc-runner --local list; lst_rc=$?; printf '%s\n' "### list rc=${lst_rc}"
rows="$(list_rows "${lst}.clean")"
grep -qaF "$2" "${lst}.clean"; own=$?
printf '%s\n' "### listing-rows ${rows}"
printf '%s\n' "### listing-has ${own}"

if [ "${gen_rc}" -eq 0 ] && [ "${ins_rc}" -eq 0 ] && [ "${sta_rc}" -eq 0 ] \
    && [ "${lst_rc}" -eq 0 ] && [ "${own}" -eq 0 ]; then vrc=0; else vrc=1; fi
verdict P-LOCAL-PAYLOAD "${vrc}" "$2 as $(id -un): generate=${gen_rc} install=${ins_rc} start=${sta_rc} list=${lst_rc} rows=${rows} has-own=${own}"
