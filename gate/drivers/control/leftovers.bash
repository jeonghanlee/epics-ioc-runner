#!/bin/bash
# What a prior run left on the consumer, read before anything is driven.
#
# The plan requires the consumer to be read and cleared before a run: a scenario
# that passes because a prior run's IOC happens to exist is the false green the
# gate exists to end. The reading itself had no driver - three `ioc-runner list`
# invocations and a payload listing, rebuilt by hand every run.
#
# THIS DRIVER READS AND REPORTS ONLY. It removes nothing. `remove` never reaches
# the payload directories, and clearing them is the runbook's step; a driver that
# deletes trees under two roots on a host it did not build is not what this
# milestone is buying. A FAIL here says the consumer was not clear when the run
# started. It does not stop the run, and it is not a scenario verdict.
#
# It is the FIRST step of a run, ahead of stage.bash, so no host driver exists on
# the VM yet and every read is issued directly over the connection. The EPICS
# environment is not sourced: the runner reads none of it for a listing, and the
# login shell that would source it speaks a banner ahead of the command - which
# is why the row count anchors on the listing's own header and never on a line
# number.
#
# $1 host, as user@address
set -u
. "$(dirname "$0")/lib.bash"
gate_init "$1" || exit 1

# Rows of an `ioc-runner list` inside a capture that may carry a banner ahead of
# it. The header line is the anchor; the divider under it carries no column
# separator and is not counted; an empty listing prints no header at all and
# counts zero.
function listing_rows {   # $1 capture label
    awk -F'|' '/^IOC NAME[[:space:]]*\|/ {h=1; next} h && NF>1 {c++} END{print c+0}' \
        "${GATE_LOG_DIR}/$1.clean" 2>/dev/null
}

ua="$(gate_uid "${GATE_USER_A}")"
ub="$(gate_uid "${GATE_USER_B}")"
uc="$(gate_uid "${GATE_OP_C}")"

# --- system mode, as the operator that installs the shared IOC ----------------
capture leftovers-system timeout 60 "${GATE_SSH[@]}" "${GATE_HOST}" \
    "sudo -niu ${GATE_OP_A} ioc-runner list"
rc_sys=$?
cat "${GATE_LOG_DIR}/leftovers-system.txt"

# --- local mode, as each local user -------------------------------------------
# The per-user systemd instance is reached only through the runtime directory and
# the session bus, exactly as the local principal switch passes them.
capture leftovers-usera timeout 60 "${GATE_SSH[@]}" "${GATE_HOST}" \
    "sudo -niu ${GATE_USER_A} env XDG_RUNTIME_DIR=/run/user/${ua} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${ua}/bus ioc-runner --local list"
rc_ua=$?
cat "${GATE_LOG_DIR}/leftovers-usera.txt"

capture leftovers-userb timeout 60 "${GATE_SSH[@]}" "${GATE_HOST}" \
    "sudo -niu ${GATE_USER_B} env XDG_RUNTIME_DIR=/run/user/${ub} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${ub}/bus ioc-runner --local list"
rc_ub=$?
cat "${GATE_LOG_DIR}/leftovers-userb.txt"

# The third operator is a local-mode user as well, for L4.
capture leftovers-opc timeout 60 "${GATE_SSH[@]}" "${GATE_HOST}" \
    "sudo -niu ${GATE_OP_C} env XDG_RUNTIME_DIR=/run/user/${uc} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${uc}/bus ioc-runner --local list"
rc_uc=$?
cat "${GATE_LOG_DIR}/leftovers-opc.txt"

rs="$(listing_rows leftovers-system)"
ra="$(listing_rows leftovers-usera)"
rb="$(listing_rows leftovers-userb)"
rc="$(listing_rows leftovers-opc)"
printf '%s\n' "### leftover-rows ${GATE_OP_A}=${rs} ${GATE_USER_A}=${ra} ${GATE_USER_B}=${rb} ${GATE_OP_C}=${rc}"

# --- the payload directories the runner does not reach ------------------------
# One line per entry so the count is a command and not a reading. An absent
# directory is a fact about the consumer, not a failed read: only some of these
# roots are ever created, since opb is a system-mode operator and nothing writes
# to its ~/iocBoot. So the existence test is INSIDE the loop and each root
# reports itself, and the one exit code this capture returns then means what the
# gate below needs it to mean - the read ran - rather than folding "a named path
# is absent" into "the read broke". A single find over all five roots exits 1
# when any one is missing, which made this verdict permanently FAIL on a consumer
# that was correctly clear.
capture leftovers-payloads timeout 60 "${GATE_SSH[@]}" "${GATE_HOST}" \
    "sudo -n sh -c 'for p in /opt/epics-iocs /home/${GATE_OP_A}/iocBoot /home/${GATE_OP_B}/iocBoot /home/${GATE_USER_A}/iocBoot /home/${GATE_USER_B}/iocBoot; do if [ -d \"\$p\" ]; then find \"\$p\" -mindepth 1 -maxdepth 1 -printf \"### payload %p\\n\"; else printf \"### absent %s\\n\" \"\$p\"; fi; done'"
rc_pay=$?
cat "${GATE_LOG_DIR}/leftovers-payloads.txt"
np="$(grep -ac '^### payload ' "${GATE_LOG_DIR}/leftovers-payloads.clean")"
printf '%s\n' "### leftover-payload-entries ${np}"

# --- a site.env value S13 left behind -----------------------------------------
# S13 writes a marked value into /etc/procServ.d/site.env and restores the file
# afterwards. A run cut off inside S13 leaves the value, and it reaches every IOC
# on the host at its next start, so its presence fails this read. An absent file
# is the normal state and counts zero.
capture leftovers-site timeout 60 "${GATE_SSH[@]}" "${GATE_HOST}" \
    "sudo -n sh -c 'if [ -e /etc/procServ.d/site.env ]; then grep -c GATE_S13_MARK /etc/procServ.d/site.env || true; else echo 0; fi'"
rc_site=$?
ns="$(tail -1 "${GATE_LOG_DIR}/leftovers-site.clean" 2>/dev/null)"
case "${ns}" in ''|*[!0-9]*) ns=1;; esac
printf '%s\n' "### leftover-site-env-marks ${ns}"

# Every read must have SUCCEEDED before a count of zero may be believed. A
# capture that is missing altogether already fails: awk never reaches its END and
# the comparison below errors out. But a read that connected and then failed -
# a changed sudo policy, a wrong principal, a runner that is not installed -
# leaves an error message in the capture, and both counts read zero from it. That
# would report a consumer clear because the reading broke, which is the exact
# false green this driver exists to prevent.
if [ "${rc_sys}" -eq 0 ] && [ "${rc_ua}" -eq 0 ] && [ "${rc_ub}" -eq 0 ] && [ "${rc_uc}" -eq 0 ] && [ "${rc_pay}" -eq 0 ] \
    && [ "${rc_site}" -eq 0 ] && [ "${rs}" -eq 0 ] && [ "${ra}" -eq 0 ] && [ "${rb}" -eq 0 ] && [ "${rc}" -eq 0 ] \
    && [ "${np}" -eq 0 ] && [ "${ns}" -eq 0 ]; then vrc=0; else vrc=1; fi
verdict P-LEFTOVERS "${vrc}" "consumer before the run: ${GATE_OP_A} system rows=${rs}, ${GATE_USER_A} local rows=${ra}, ${GATE_USER_B} local rows=${rb}, ${GATE_OP_C} local rows=${rc}, payload entries=${np}, site.env S13 marks=${ns}; read exit codes system=${rc_sys} ${GATE_USER_A}=${rc_ua} ${GATE_USER_B}=${rc_ub} ${GATE_OP_C}=${rc_uc} payloads=${rc_pay} site.env=${rc_site}, all six must be 0 or a count of zero means the read broke; this driver reads and removes nothing, and clearing what it names is the runbook's step"
