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

# ------------------------------------------------------------- ioc names -----
GATE_IOC_L_DUP="lioc1"   # installed under the same name by BOTH local users, for L1
GATE_IOC_L_OWNED="lioc2" # the owner's uniquely named local IOC - the L2 and L3 target
GATE_IOC_SHARED="sioc1"  # the one shared system IOC: S1 S2 S5 S6 S10 S11, destroyed by S4
GATE_IOC_S9="sioc9"      # S9 only; system-mode configuration with the payload in a home
GATE_IOC_S8="sioc8"      # S8's own IOC, which carries the crash token; then opa's half of S3
GATE_IOC_FRESH="sioc7"   # the fresh IOC: opb's half of S3, and all of S7

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
