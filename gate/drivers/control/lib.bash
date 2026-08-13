#!/bin/bash
# Shared machinery for the control-side drivers: the ssh forms, the principal
# switch, the capture form, and the verdict relay.
#
# Everything in this directory runs ON THE CONTROL HOST. The drivers it invokes
# live in ../host and run on the VM. That split is the layout's whole job: a
# file's directory states which side it runs on, which `sys-`/`local-` never
# did - those mark the runner's MODE.
#
# Sourced, never run. No `set -e`: almost every command's nonzero exit is the
# observation itself.

GATE_DRIVERS_DIR="${GATE_DRIVERS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
. "${GATE_DRIVERS_DIR}/identities.bash"

# Per-run scratch, on both sides. /tmp/s4.out was a fixed name two runs collide
# on. Exported by run-all.bash so one whole run lands in one directory; a driver
# invoked on its own gets a directory of its own.
GATE_RUN_ID="${GATE_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
GATE_LOG_DIR="${GATE_LOG_DIR:-/tmp/gate-run-${GATE_RUN_ID}}"
GATE_REMOTE_RUN="${GATE_REMOTE_RUN:-/tmp/gate-run-${GATE_RUN_ID}}"
GATE_REMOTE_DRIVERS="${GATE_REMOTE_DRIVERS:-/tmp/gate-drivers}"

# `-n` redirects stdin from /dev/null. That is right for a call that only issues
# a command and WRONG for one that must read a stream: measured 2026-08-01, `-n`
# on the receiving end of the push feeds tar an empty stream and it answers
# `This does not look like a tar archive`. Every call made from this directory
# only issues a command, so every call carries `-n`; the push driver, which
# reads a stream, keeps its own two option lists.
GATE_SSH=(ssh -n -o BatchMode=yes -o ConnectTimeout=10)

# ------------------------------------------------------------------ setup ---

function gate_init {   # $1 host, as user@address
    GATE_HOST="$1"
    mkdir -p "${GATE_LOG_DIR}" || return 1
    # 1777 because five principals write into it and none owns the others' files.
    "${GATE_SSH[@]}" "${GATE_HOST}" \
        "mkdir -p '${GATE_REMOTE_RUN}' && chmod 1777 '${GATE_REMOTE_RUN}'" >/dev/null 2>&1
    if [ -z "${GATE_EPICS_ENV:-}" ]; then
        # Derived from the host, never globbed blindly and never hard-coded.
        # Take the last line: a remote shell can speak ahead of the command.
        GATE_EPICS_ENV="$("${GATE_SSH[@]}" "${GATE_HOST}" \
            'os="$(. /etc/os-release; echo "${ID}-${VERSION_ID}")"; ls -d /opt/epics/*/"${os}"/*/setEpicsEnv.bash' \
            2>/dev/null | tail -1)"
    fi
    if [ -z "${GATE_EPICS_ENV}" ]; then
        printf '%s\n' "gate: cannot resolve the EPICS environment on ${GATE_HOST}" >&2
        return 1
    fi
    printf '### host=%s env=%s remote-run=%s log=%s\n' \
        "${GATE_HOST}" "${GATE_EPICS_ENV}" "${GATE_REMOTE_RUN}" "${GATE_LOG_DIR}"
}

function gate_uid {   # $1 account
    "${GATE_SSH[@]}" "${GATE_HOST}" "id -u $1" 2>/dev/null | tail -1
}

# --------------------------------------------------- the principal switch ---
# The whole section assumes the driving account holds password-free sudo to an
# arbitrary target user. A host that does not stops the section at its first
# switch, and that stop is a property of the host rather than of the tree.
#
# Arguments are passed as bare words. No identity or path in identities.bash
# carries whitespace, and none may.

function sys_as {   # $1 seconds  $2 principal  $3 host driver  [args...]
    local secs="$1" user="$2" drv="$3"; shift 3
    timeout "${secs}" "${GATE_SSH[@]}" "${GATE_HOST}" \
        "sudo -niu ${user} env GATE_RUN_DIR=${GATE_REMOTE_RUN} bash ${GATE_REMOTE_DRIVERS}/${drv} $* 2>&1"
}

function local_as {   # $1 seconds  $2 principal  $3 uid  $4 host driver  [args...]
    local secs="$1" user="$2" uid="$3" drv="$4"; shift 4
    timeout "${secs}" "${GATE_SSH[@]}" "${GATE_HOST}" \
        "sudo -niu ${user} env GATE_RUN_DIR=${GATE_REMOTE_RUN} XDG_RUNTIME_DIR=/run/user/${uid} DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/${uid}/bus bash ${GATE_REMOTE_DRIVERS}/${drv} $* 2>&1"
}

function root_run {   # $1 seconds  $2 command line, run as root on the VM
    local secs="$1" cmd="$2"
    timeout "${secs}" "${GATE_SSH[@]}" "${GATE_HOST}" "sudo -n ${cmd}"
}

# ------------------------------------------------------- the capture form ---
# Capture WHOLE, then read. A console scenario piped through `tail` loses the
# connection banner that is its only evidence - measured on S10, 2026-08-01.
#
# Three files per capture, all absolute:
#   <label>.raw    byte-for-byte, because the telnet negotiation bytes and the
#                  glued closing message are themselves evidence
#   <label>.txt    the runbook's read form, `cat -v` with the colour escapes cut
#   <label>.clean  colour and carriage returns removed, what the verdict logic
#                  greps, so a whole-word match means what it says

# The two read forms, derived from a <label>.raw that already exists. It is a
# function of its own because `capture` cannot wrap every call that produces a
# raw: S3 launches two in the background and redirects each into its own file,
# so it calls this after its `wait` and the run keeps the runbook's promise of
# three files per capture. One place, two callers.
function read_forms {   # $1 label
    local raw="${GATE_LOG_DIR}/$1.raw"
    cat -v "${raw}" | sed -e 's/\^\[\[[0-9;]*m//g' > "${GATE_LOG_DIR}/$1.txt"
    sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\r//g' "${raw}" > "${GATE_LOG_DIR}/$1.clean" 2>/dev/null
}

function capture {   # $1 label  $2... the command to run
    local label="$1"; shift
    local raw="${GATE_LOG_DIR}/${label}.raw" rc
    "$@" > "${raw}" 2>&1
    rc=$?
    read_forms "${label}"
    printf '### capture %s rc=%s file=%s\n' "${label}" "${rc}" "${GATE_LOG_DIR}/${label}.txt"
    return "${rc}"
}

# --------------------------------------------------------------- verdicts ---
# One form, on both sides of the split:
#
#     VERDICT <id> <PASS|FAIL> <detail>
#
# The fourteen scenario verdicts of a run are exactly the lines matching
#     VERDICT (L[1-3]|S[1-9]|S1[01]) (PASS|FAIL)
# and nothing else does: halves carry "<ID>-<HALF>" and preconditions "P-<WHAT>".
#
# Matched UNANCHORED everywhere. Where `script` closes a killed session with
# `Session terminated, killing shell...` it writes no trailing newline and the
# next line is glued to it, so an anchored read loses the line silently.

function verdict {   # $1 id   $2 rc, 0 is PASS   $3 detail
    local v=FAIL
    [ "$2" -eq 0 ] && v=PASS
    printf '\nVERDICT %s %s %s\n' "$1" "${v}" "$3"
}

# Lift the verdicts a host driver printed out of its capture. A driver that
# printed none is an honest red here rather than a silent absence.
function relay {   # $1 label  $2... the verdict ids expected
    local label="$1"; shift
    local id line
    for id in "$@"; do
        line="$(grep -aoE "VERDICT ${id} (PASS|FAIL).*" "${GATE_LOG_DIR}/${label}.clean" 2>/dev/null | tail -1)"
        if [ -n "${line}" ]; then
            printf '%s\n' "${line}"
        else
            printf 'VERDICT %s FAIL the driver printed no verdict; see %s\n' \
                "${id}" "${GATE_LOG_DIR}/${label}.txt"
        fi
    done
}

function verdict_of {   # $1 label  $2 verdict id  -> PASS, FAIL, or empty
    grep -aoE "VERDICT $2 (PASS|FAIL)" "${GATE_LOG_DIR}/$1.clean" 2>/dev/null | tail -1 | awk '{print $3}'
}

function fact {   # $1 label  $2 key  -> the value of the last "### <key> <value>" line
    grep -aoE "### $2 .*" "${GATE_LOG_DIR}/$1.clean" 2>/dev/null | tail -1 | cut -d' ' -f3-
}

function has {   # $1 label  $2 literal text
    grep -qaF "$2" "${GATE_LOG_DIR}/$1.clean" 2>/dev/null
}

function hasline {   # $1 label  $2 literal whole line
    grep -qaxF "$2" "${GATE_LOG_DIR}/$1.clean" 2>/dev/null
}

# ------------------------------------------------------------------ tally ---

function tally {   # $1 a log holding a whole run's verdicts
    local log="$1" id line pass=0 fail=0 missing=""
    for id in L1 L2 L3 S1 S2 S3 S4 S5 S6 S7 S8 S9 S10 S11; do
        line="$(grep -aoE "VERDICT ${id} (PASS|FAIL)" "${log}" 2>/dev/null | tail -1)"
        case "${line}" in
            *PASS) pass=$((pass + 1));;
            *FAIL) fail=$((fail + 1));;
            *)     missing="${missing} ${id}";;
        esac
    done
    [ "${pass}" -eq 14 ]
    verdict RUN "$?" "14 scenarios: pass=${pass} fail=${fail} missing=${missing:-none}"
}
