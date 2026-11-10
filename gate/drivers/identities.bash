#!/bin/bash
# The scenario identities: every IOC name, the role mapping, and the S8 token.
#
# This is the one place a name is chosen. Nothing else under gate/drivers/ names
# an account or an IOC: the control drivers read the names from here and hand
# them to the host drivers as arguments, and the host drivers act only on what
# they are given. That is the exact place the per-run reinvention used to enter,
# so the file is short on purpose and carries no host facts. The EPICS
# environment path and the uids are per-host, and control/lib.bash resolves them
# at run time.
#
# Sourced, never run.

# shellcheck disable=SC2034  # sourced by the drivers; every name here is read elsewhere

# ---------------------------------------------------------------- accounts ---
# Provisioned by the test_users role in ansible-provision during the bake. The
# runbook's "Fixture accounts" verifies them and never creates them.
GATE_OP_A="opa"          # operator, in the ioc group
GATE_OP_B="opb"          # second operator, in the ioc group
GATE_OBS="obs"           # observer, NOT in the ioc group - the negative control
GATE_USER_A="usera"      # local user A, lingering
GATE_USER_B="userb"      # local user B, lingering
GATE_OP_C="opc"          # third operator, in the ioc group AND lingering: L4 runs one IOC in both modes

# ------------------------------------------------------------- ioc names -----
GATE_IOC_L_DUP="lioc1"   # installed under the same name by BOTH local users, for L1
GATE_IOC_L_OWNED="lioc2" # the owner's uniquely named local IOC - the L2 and L3 target
GATE_IOC_SHARED="sioc1"  # the one shared system IOC: S1 S2 S5 S6 S10-S15, destroyed by S4
GATE_IOC_S9="sioc9"      # S9 only; system-mode configuration with the payload in a home
GATE_IOC_S8="sioc8"      # S8's own IOC, which carries the crash token; then opa's half of S3
GATE_IOC_FRESH="sioc7"   # the fresh IOC: opb's half of S3, and all of S7
GATE_IOC_MODE="mioc1"    # L4 only; moved between local and system mode under /opt/epics-iocs

# ------------------------------------------------------------- S8 token ------
# A nonsense string of letters. A token an ordinary log line could carry is
# rejected at install and again at every start, and S8 never reaches the warning
# it exists to observe.
GATE_S8_TOKEN="ZQXWVJKMPL"

# --------------------------------------------------------- role mapping ------
# Fixed here rather than per run. Swapping any pair silently turns a negative
# into a principal probing its own asset, which proves nothing.
GATE_L_OWNER="${GATE_USER_A}"           # owns GATE_IOC_L_OWNED
GATE_L_ACTOR="${GATE_USER_B}"           # aims L2 and L3 at the owner's IOC
GATE_S_FIRST_OP="${GATE_OP_A}"          # installs the shared system IOC
GATE_S_SECOND_OP="${GATE_OP_B}"         # S1, S2, S5 against the first operator's IOC
GATE_S6_ACTOR="${GATE_OBS}"
GATE_S10_MEMBER="${GATE_OP_B}"          # in ioc: attaches and monitors
GATE_S10_OBSERVER="${GATE_OBS}"         # outside ioc: denied at configuration resolution
GATE_S11_ACTOR="${GATE_OP_A}"
GATE_S9_ACTOR="${GATE_OP_A}"
GATE_S8_ACTOR="${GATE_OP_A}"
GATE_S4_CLIENT="${GATE_OP_B}"           # holds the console
GATE_S4_SERVER="${GATE_OP_A}"           # removes the IOC underneath it
GATE_S3_OP_A_IOC="${GATE_IOC_S8}"       # in S3 each operator acts on the IOC it installed
GATE_S3_OP_B_IOC="${GATE_IOC_FRESH}"
GATE_S7_ACTOR="${GATE_OP_B}"            # owns the fresh IOC
GATE_S7_OBSERVER="${GATE_OP_A}"         # one principal cannot both move the state and observe it
GATE_S12_READER="${GATE_OP_B}"          # reads the shared IOC's log through the command
GATE_S12_OBSERVER="${GATE_OBS}"         # outside ioc: the command refuses, the 0644 file does not
GATE_S13_WRITER="${GATE_OP_A}"          # writes site.env, then restores it
GATE_S13_READER="${GATE_OP_B}"          # restarts the shared IOC and reads the value from its shell
GATE_S13_OBSERVER="${GATE_OBS}"         # outside ioc: cannot write site.env
GATE_S14_ATTACH="${GATE_OP_A}"          # attaches with a custom detach key
GATE_S14_MONITOR="${GATE_OP_B}"         # monitors the same IOC at the same time
GATE_S15_ACTOR="${GATE_OP_B}"           # regenerates the payload the first operator generated
GATE_L4_OWNER="${GATE_OP_C}"            # tests in local mode and moves the IOC between modes
GATE_L4_PEER="${GATE_OP_B}"             # stops, edits, regenerates, runs by hand, restarts
