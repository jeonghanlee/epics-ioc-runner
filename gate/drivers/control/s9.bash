#!/bin/bash
# S9 - working-directory non-conformance, both halves.
#
# The root half is here because it is the only part of the run that acts as root
# rather than through a principal switch. Two of this scenario's four verdicts
# come from it. Before this driver it was a hand-typed command whose single
# printed exit code was FALSE - `$?` was read at the end of a read pipeline, so
# an install that aborted reported rc=0, under a label naming the other shape -
# and whose second invocation printed no code at all. Here each root install is
# its own command with no pipeline behind it, so the code that is printed is the
# install's, and each shape is labelled with its own name.
#
# The exit codes are printed but not judged: all shapes exit nonzero and they
# exit alike, so the code separates a declined conformance prompt from a hard
# error not at all. The printed text decides.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

# --- operator half -----------------------------------------------------------
capture s9-operator sys_as 300 "${GATE_S9_ACTOR}" sys-s9.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_S9}" "${GATE_S9_ACTOR}"
relay s9-operator S9-OPERATOR

# --- root half, conforming shape ---------------------------------------------
# By the end of the operator half the configuration holds only the parent
# reference, so the conforming path is restored before root sees it.
capture s9-restore-conforming sys_as 120 "${GATE_S9_ACTOR}" sys-s9-restore.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_S9}" "${GATE_S9_ACTOR}" conforming
relay s9-restore-conforming P-S9-RESTORE
conf_path="$(fact s9-restore-conforming s9-conf)"

capture s9-root-conforming root_run 120 \
    "timeout -k 2 40 script -qec 'ioc-runner install ${conf_path}' /dev/null </dev/null"
rc_conforming=$?
cat "${GATE_LOG_DIR}/s9-root-conforming.txt"
printf '%s\n' "### root-install-nonconforming rc=${rc_conforming} (recorded, not judged)"

has s9-root-conforming 'is not writable by'; rw=$?
has s9-root-conforming 'Aborting installation'; ab=$?
if [ "${rw}" -eq 0 ] && [ "${ab}" -eq 0 ]; then ok_conforming=0; else ok_conforming=1; fi
verdict S9-ROOT-CONFORMING "${ok_conforming}" "root on the non-writable working directory: warning=${rw} decline on EOF=${ab}, install rc=${rc_conforming}"

# --- root half, parent-reference shape ---------------------------------------
capture s9-restore-parentref sys_as 120 "${GATE_S9_ACTOR}" sys-s9-restore.bash \
    "${GATE_EPICS_ENV}" "${GATE_IOC_S9}" "${GATE_S9_ACTOR}" parentref
relay s9-restore-parentref P-S9-RESTORE
pref_path="$(fact s9-restore-parentref s9-conf)"

capture s9-root-parentref root_run 120 \
    "timeout -k 2 40 script -qec 'ioc-runner install ${pref_path}' /dev/null </dev/null"
rc_parentref=$?
cat "${GATE_LOG_DIR}/s9-root-parentref.txt"
printf '%s\n' "### root-install-parentref rc=${rc_parentref} (recorded, not judged)"

has s9-root-parentref "contains a '..' component"; hard=$?
has s9-root-parentref 'is not writable by'; ahead=$?
if [ "${hard}" -eq 0 ] && [ "${ahead}" -ne 0 ]; then ok_parentref=0; else ok_parentref=1; fi
verdict S9-ROOT-PARENTREF "${ok_parentref}" "root on the parent reference: hard error=${hard} nothing prompted ahead of it=${ahead}, install rc=${rc_parentref}"

# --- the identity this scenario claims ----------------------------------------
vo="$(verdict_of s9-operator S9-OPERATOR)"
if [ "${vo}" = PASS ] && [ "${ok_conforming}" -eq 0 ] && [ "${ok_parentref}" -eq 0 ]; then vrc=0; else vrc=1; fi
verdict S9 "${vrc}" "operator half=${vo:-none}, root non-writable=${ok_conforming}, root parent reference=${ok_parentref}; root and operator reach identical verdicts on both shapes"
