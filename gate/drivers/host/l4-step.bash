#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# L4 - one IOC carried between local and system mode by the operators who use
# it, one step per invocation. Only one mode runs the IOC at any time.
#
#   local-first     the third operator builds the payload under /opt/epics-iocs,
#                   generates, installs, starts, and stops it in local mode
#   to-system       a system install of the local-mode configuration is refused
#                   for its mode; -f generate rewrites it, and install and start
#                   succeed
#   peer            the second operator stops the service, edits st.cmd,
#                   regenerates with -f (taking the file over), runs st.cmd by
#                   hand, and starts the service again
#   to-local        the third operator stops the service; a local install of the
#                   system-mode configuration is refused; --local -f generate,
#                   a forced local install, start, and stop succeed
#   back-to-system  the same move back, ending with the service active
#
# The iocsh history loading message that a change of principal produces is
# expected and benign (FAQ Q13); it is counted, not judged. A start that reports
# a crash warning fails its step.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal   $4 step
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

boot="/opt/epics-iocs/$2"; conf="${boot}/$2.conf"
vid="L4-$(printf '%s' "$4" | tr '[:lower:]' '[:upper:]')"
require_principal "$3" "${vid}"
printf '%s\n' "### actor=$(id -un) step=$4"

# A step's commands, each recorded as "### <tag> rc=<n>".
function step {   # $1 tag   $2... command
    local tag="$1" out rc; shift
    out="$(cap_path "$tag")"
    (cd "${boot}" 2>/dev/null && plain "${out}" "$@" < /dev/null); rc=$?
    printf '%s\n' "### ${tag} rc=${rc}"
    return "${rc}"
}
function refused_for_mode {   # $1 tag -> 0 when the capture carries the mode refusal
    grep -qaF 'Configuration mode mismatch' "$(cap_path "$1").clean"
}
function crash_warned {   # $1 tag -> 0 when the start capture carries a crash warning
    grep -qaE 'failed to initialize|matching an error pattern' "$(cap_path "$1").clean"
}

case "$4" in
    local-first)
        rm -rf "${boot}"; mkdir -p "${boot}"; chmod 2775 "${boot}"
        printf '#!%s\niocInit\n' "$(command -v softIoc)" > "${boot}/st.cmd"; chmod 0775 "${boot}/st.cmd"
        step gen ioc-runner --local generate .; g=$?
        step install ioc-runner --local install "${conf}"; i=$?
        step start ioc-runner --local start "$2"; s=$?
        crash_warned start; cw=$?
        step stop ioc-runner --local stop "$2"; t=$?
        if [ "${g}" -eq 0 ] && [ "${i}" -eq 0 ] && [ "${s}" -eq 0 ] && [ "${cw}" -ne 0 ] && [ "${t}" -eq 0 ]; then vrc=0; else vrc=1; fi
        verdict "${vid}" "${vrc}" "local generate=${g} install=${i} start=${s} crash warning=$([ "${cw}" -eq 0 ] && echo yes || echo no) stop=${t}"
        ;;
    to-system|back-to-system)
        step refuse ioc-runner install "${conf}"; r=$?
        refused_for_mode refuse; rm_=$?
        step gen ioc-runner -f generate .; g=$?
        step install ioc-runner -f install "${conf}"; i=$?
        step start ioc-runner start "$2"; s=$?
        crash_warned start; cw=$?
        act="$(systemctl is-active "epics-@$2.service")"
        printf '%s\n' "### active ${act}"
        if [ "${r}" -ne 0 ] && [ "${rm_}" -eq 0 ] && [ "${g}" -eq 0 ] && [ "${i}" -eq 0 ] && [ "${s}" -eq 0 ] \
            && [ "${cw}" -ne 0 ] && [ "${act}" = active ]; then vrc=0; else vrc=1; fi
        verdict "${vid}" "${vrc}" "system install of the local configuration rc=${r} refused for its mode=${rm_}; -f generate=${g} install=${i} start=${s} active=${act} crash warning=$([ "${cw}" -eq 0 ] && echo yes || echo no)"
        ;;
    peer)
        step stop ioc-runner stop "$2"; t=$?
        printf 'epicsEnvSet GATE_L4_EDITED_BY %s\n' "$(id -un)" >> "${boot}/st.cmd"; e=$?
        printf '%s\n' "### edit rc=${e}"
        step gen ioc-runner -f generate .; g=$?
        owner="$(stat -c '%U' "${conf}")"
        printf '%s\n' "### configuration owner ${owner}"
        man="$(cap_path manual)"
        (cd "${boot}" && timeout -k 2 20 bash -c "sleep 6 | ./st.cmd" > "${man}" 2>&1); m=$?
        gate_clean "${man}"
        hist="$(grep -ac "iocsh_history" "${man}.clean")"
        printf '%s\n' "### manual rc=${m} (recorded, not judged) history messages=${hist}"
        step start ioc-runner start "$2"; s=$?
        crash_warned start; cw=$?
        if [ "${t}" -eq 0 ] && [ "${e}" -eq 0 ] && [ "${g}" -eq 0 ] && [ "${owner}" = "$(id -un)" ] \
            && [ "${s}" -eq 0 ] && [ "${cw}" -ne 0 ]; then vrc=0; else vrc=1; fi
        verdict "${vid}" "${vrc}" "stop=${t} edit=${e} -f generate=${g} owner=${owner} manual=${m} history messages=${hist} start=${s} crash warning=$([ "${cw}" -eq 0 ] && echo yes || echo no)"
        ;;
    to-local)
        step stop ioc-runner stop "$2"; t=$?
        step refuse ioc-runner --local install "${conf}"; r=$?
        refused_for_mode refuse; rm_=$?
        step gen ioc-runner --local -f generate .; g=$?
        step install ioc-runner --local -f install "${conf}"; i=$?
        step start ioc-runner --local start "$2"; s=$?
        crash_warned start; cw=$?
        step lstop ioc-runner --local stop "$2"; l=$?
        if [ "${t}" -eq 0 ] && [ "${r}" -ne 0 ] && [ "${rm_}" -eq 0 ] && [ "${g}" -eq 0 ] && [ "${i}" -eq 0 ] \
            && [ "${s}" -eq 0 ] && [ "${cw}" -ne 0 ] && [ "${l}" -eq 0 ]; then vrc=0; else vrc=1; fi
        verdict "${vid}" "${vrc}" "system stop=${t}; local install of the system configuration rc=${r} refused for its mode=${rm_}; --local -f generate=${g} install=${i} start=${s} stop=${l} crash warning=$([ "${cw}" -eq 0 ] && echo yes || echo no)"
        ;;
    *)
        printf '%s\n' "### unknown step $4"; exit 2
        ;;
esac
