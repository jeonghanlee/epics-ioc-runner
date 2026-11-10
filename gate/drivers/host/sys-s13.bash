#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S13 - the site environment file across principals, one role per invocation.
#
#   set       the first operator saves any existing site.env and writes one
#             whose last line carries a distinctive value
#   read      the second operator restarts the shared IOC and reads the value
#             from its shell with epicsEnvShow, detaching with the default key
#   observer  a principal outside ioc cannot write site.env
#   restore   the first operator puts the saved file back, or removes the file
#             when none existed before
#
# site.env reaches every IOC on the host at its next start, so the scenario
# leaves the file as it found it. The shared IOC keeps the value until its own
# next start; nothing after S13 reads it.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal   $4 role   $5 the distinctive value
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

site="/etc/procServ.d/site.env"
saved="${GATE_RUN_DIR}/s13-site.env.saved"
absent="${GATE_RUN_DIR}/s13-site.env.absent"
key="GATE_S13_MARK"

case "$4" in
    set)      vid="S13-SET";;
    read)     vid="S13-READ";;
    observer) vid="S13-OBSERVER";;
    restore)  vid="S13-RESTORE";;
    *)        printf '%s\n' "### unknown role $4"; exit 2;;
esac
require_principal "$3" "${vid}"
printf '%s\n' "### actor=$(id -un) role=$4"

case "$4" in
    set)
        rm -f "${saved}" "${absent}"
        if [ -e "${site}" ]; then
            cp -p "${site}" "${saved}"; sv=$?
            printf '%s\n' "### existing site.env saved rc=${sv}"
        else
            : > "${absent}"; sv=$?
            printf '%s\n' "### no site.env before the scenario"
        fi
        { [ -e "${saved}" ] && cat "${saved}"; printf '%s="%s"\n' "${key}" "$5"; } > "${site}.s13.tmp" \
            && mv -f "${site}.s13.tmp" "${site}"; wr=$?
        tail -1 "${site}"; grep -qxF "${key}=\"$5\"" "${site}"; has=$?
        if [ "${sv}" -eq 0 ] && [ "${wr}" -eq 0 ] && [ "${has}" -eq 0 ]; then vrc=0; else vrc=1; fi
        verdict "${vid}" "${vrc}" "saved-or-absent=${sv} write=${wr} value line present=${has}"
        ;;
    read)
        console 90 "ioc-runner restart $2" "$(cap_path restart)"; rst=$?
        printf '%s\n' "### restart rc=${rst}"
        att="$(cap_path attach)"
        console_fed 60 "ioc-runner attach $2" "${att}" "epicsEnvShow ${key}\r" "\001"; arc=$?
        printf '%s\n' "### attach rc=${arc}"
        grep -qaF "${key}=$5" "${att}.clean"; seen=$?
        if [ "${rst}" -eq 0 ] && [ "${seen}" -eq 0 ]; then vrc=0; else vrc=1; fi
        verdict "${vid}" "${vrc}" "restart=${rst} value read from the IOC shell=${seen} attach rc=${arc} (recorded, not judged)"
        ;;
    observer)
        printf 'X=1\n' >> "${site}" 2>/dev/null; wr=$?
        printf '%s\n' "### observer append rc=${wr}"
        if [ "${wr}" -ne 0 ]; then vrc=0; else vrc=1; fi
        verdict "${vid}" "${vrc}" "append to site.env as $(id -un) rc=${wr}, expected a refusal"
        ;;
    restore)
        if [ -e "${saved}" ]; then
            cp -p "${saved}" "${site}"; rs=$?
            cmp -s "${saved}" "${site}"; same=$?
            printf '%s\n' "### restored rc=${rs} identical=${same}"
        elif [ -e "${absent}" ]; then
            rm -f "${site}"; rs=$?
            [ ! -e "${site}" ]; same=$?
            printf '%s\n' "### removed rc=${rs} absent=${same}"
        else
            rs=1; same=1
            printf '%s\n' "### neither a saved file nor an absence marker: set did not run"
        fi
        rm -f "${saved}" "${absent}"
        if [ "${rs}" -eq 0 ] && [ "${same}" -eq 0 ]; then vrc=0; else vrc=1; fi
        verdict "${vid}" "${vrc}" "site.env returned to its state before the scenario: rc=${rs} matches=${same}"
        ;;
esac
