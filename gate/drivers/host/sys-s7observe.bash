#!/bin/bash
# shellcheck disable=SC1090  # the environment file is a per-host argument
# S7 middle - the OTHER operator observes the intermediate state. One principal
# cannot both change the state and independently observe it.
#
# `is-enabled` inverts: a disabled unit prints `disabled` and exits nonzero,
# which is the expected result here, so the printed word decides. Match the whole
# word - `disabled` does not contain `enabled`, and a substring test reads a
# correct answer as a missing one.
#
# $1 setEpicsEnv path   $2 ioc name   $3 principal (the observing operator)
. "$(dirname "$0")/gate-lib.bash"
set +u; if [ -z "${EPICS_BASE:-}" ]; then . "$1"; fi; set -u

require_principal "$3" S7-OBSERVE

printf '%s\n' "### observer=$(id -un)"
a="$(systemctl is-active "epics-@$2.service")"; printf '%s\n' "### is-active ${a}"
e="$(systemctl is-enabled "epics-@$2.service")"; printf '%s\n' "### is-enabled ${e}"

if [ "${a}" != "active" ] && [ "${e}" = "disabled" ]; then vrc=0; else vrc=1; fi
verdict S7-OBSERVE "${vrc}" "intermediate state seen by the other operator: is-active=${a} is-enabled=${e} (words, not codes)"
