#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# Helpers shared by every driver in this directory, which runs ON THE VM under
# the principal named in the invocation. Each driver sources this as its first
# action, ahead of the EPICS environment line, so that verdict() exists for the
# principal check that must precede any action.
#
# GATE_RUN_DIR is the per-run scratch directory. control/lib.bash sets it on
# every principal switch; the default below only keeps a driver run by hand off
# a fixed name that two runs collide on.
#
# Sourced, never run.

GATE_RUN_DIR="${GATE_RUN_DIR:-/tmp/gate-run-manual}"
mkdir -p "${GATE_RUN_DIR}" 2>/dev/null

# One verdict form, printed by the driver that owns the scenario:
#
#     VERDICT <id> <PASS|FAIL> <detail>
#
# A driver that owns half a scenario prints "<ID>-<HALF>" and the control driver
# that makes both invocations prints the combined "<ID>". A precondition prints
# "P-<WHAT>". So the fourteen scenario verdicts of a run are exactly the lines
# matching  VERDICT (L[1-3]|S[1-9]|S1[01]) (PASS|FAIL)  and nothing else does.
#
# The leading newline keeps the verdict off the tail of a `script` closing
# message, which carries no trailing newline of its own. A reader must still
# match it UNANCHORED: a glued line puts text ahead of it on the same line.
function verdict {   # $1 id   $2 rc, 0 is PASS   $3 detail
    local v=FAIL
    [ "$2" -eq 0 ] && v=PASS
    printf '\nVERDICT %s %s %s\n' "$1" "${v}" "$3"
}

# The principal is an argument, checked before the driver acts. It used to be a
# value reported afterwards, so a wrong one produced a plausible transcript.
function require_principal {   # $1 expected principal   $2... the verdict ids to fail
    local want="$1"; shift
    local me id
    me="$(id -un)"
    [ "${me}" = "${want}" ] && return 0
    for id in "$@"; do
        verdict "${id}" 1 "wrong principal: expected ${want}, running as ${me}"
    done
    exit 2
}

# An absolute, per-run, per-driver, per-principal capture path. A relative one
# drops files into whatever directory the driver was started from.
function cap_path {   # $1 step tag
    printf '%s/%s.%s.%s.out\n' "${GATE_RUN_DIR}" "$(basename "$0" .bash)" "$(id -un)" "$1"
}

# Strip the colour escapes and the carriage returns `script` leaves behind, so a
# whole-word match means what it says. Writes <file>.clean beside the capture and
# leaves the capture itself byte-for-byte, because the telnet negotiation bytes
# and the glued closing message are evidence.
function gate_clean {   # $1 capture file
    sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\r//g' "$1" > "$1.clean" 2>/dev/null
}

# The console wrapper: a terminal, a bounded timeout, and end-of-file. EOF is an
# answer - it declines any prompt, which is the wanted result wherever the
# expected outcome is an abort. Where a scenario must proceed past a prompt, use
# the verb's --force form instead.
function console {   # $1 seconds   $2 command   $3 capture file
    local rc
    timeout -k 2 "$1" script -qec "$2" /dev/null </dev/null > "$3" 2>&1
    rc=$?
    gate_clean "$3"
    cat "$3"
    return "${rc}"
}

# The same capture around a command that needs no terminal.
function plain {   # $1 capture file   $2... command and arguments
    local out="$1" rc; shift
    "$@" > "${out}" 2>&1
    rc=$?
    gate_clean "${out}"
    cat "${out}"
    return "${rc}"
}

# Both halves of S4 read one file, so its name is fixed inside the per-run
# directory rather than at a fixed path in /tmp.
s4_out()  { printf '%s/s4-client.out\n' "${GATE_RUN_DIR}"; }
s4_fifo() { printf '%s/s4-fifo.%s\n' "${GATE_RUN_DIR}" "$(id -un)"; }

# Rows of an `ioc-runner list`, which prints two header lines ahead of them.
function list_rows {   # $1 cleaned listing capture
    awk 'NR>2 && NF>0 {c++} END{print c+0}' "$1"
}
