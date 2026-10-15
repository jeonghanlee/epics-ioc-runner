#!/usr/bin/env bash
# Exercise the complete shipped Bash completion registration in fresh shells.
# Usage: bash completion-contract.bash COMPLETION_FILE NEW_EVIDENCE_DIRECTORY
# Catalog mode emits stable keys without touching the filesystem.

set -euo pipefail
export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
umask 077
unset BASH_ENV ENV CDPATH

declare -gr COMMANDS='generate install remove start stop restart status enable disable view log list attach monitor inspect'
declare -gr OPTIONS='--local --user --container -f --force -n --lines -v -vv --detach-key -V --version -h --help'
declare -gr TARGET_COMMANDS='remove start stop restart status enable disable view log attach monitor inspect'
declare -gr PROBE='
source "$1" || exit
cd "$2" || exit
shift 2
registration=$(complete -p ioc-runner) || exit
[[ "${registration}" == "complete -F _ioc_runner_completions ioc-runner" ]] || exit 90
read -r _ _ handler _ <<< "${registration}"
COMP_WORDS=("$@")
COMP_CWORD=$((${#COMP_WORDS[@]} - 1))
COMPREPLY=()
"${handler}" || exit
if ((${#COMPREPLY[@]})); then printf "%s\n" "${COMPREPLY[@]}"; fi
'
declare -g CATALOG=0 FAILED=0
declare -g COMPLETION_FILE='' EVIDENCE='' FIXTURE=''

function normalize {
    LC_ALL=C sort -u | sed '/^$/d'
}

# The probe receives only external Bash completion inputs. No product function
# is extracted or replaced; the registered function is obtained from complete.
function expect_completion {
    local key="$1" expected="$2"
    local exit_code=0 actual='' state=PASS
    local -a environment=() words=()
    shift 2
    if (( CATALOG )); then
        printf '%s\n' "${key}"
        return 0
    fi
    while [[ "$1" != -- ]]; do
        environment+=("$1")
        shift
    done
    shift
    words=(ioc-runner "$@")
    if [[ "${key}" == directory.unreadable && ${EUID} -eq 0 ]]; then
        printf 'CHECK|%s|NA\n' "${key}"
        return 0
    fi
    printf '%q ' env -i "HOME=${FIXTURE}/home" PATH="${PATH}" LC_ALL=C \
        "${environment[@]}" /bin/bash --noprofile --norc -c "${PROBE}" \
        _ "${COMPLETION_FILE}" "${FIXTURE}/paths" "${words[@]}" > "${EVIDENCE}/${key}.argv"
    env -i "HOME=${FIXTURE}/home" PATH="${PATH}" LC_ALL=C \
        "${environment[@]}" /bin/bash --noprofile --norc -c "${PROBE}" \
        _ "${COMPLETION_FILE}" "${FIXTURE}/paths" "${words[@]}" \
        > "${EVIDENCE}/${key}.stdout" 2> "${EVIDENCE}/${key}.stderr" || exit_code=$?
    printf '%s\n' "${exit_code}" > "${EVIDENCE}/${key}.exit"
    actual=$(normalize < "${EVIDENCE}/${key}.stdout")
    expected=$(printf '%s\n' "${expected}" | normalize)
    printf '%s\n' "${expected}" > "${EVIDENCE}/${key}.expected"
    if [[ "${actual}" != "${expected}" || ${exit_code} -ne 0 || -s "${EVIDENCE}/${key}.stderr" ]]; then
        state=FAIL
        FAILED=$((FAILED + 1))
        printf 'FAIL %s: expected <%s>; actual <%s>; exit=%s\n' \
            "${key}" "${expected}" "${actual}" "${exit_code}" >&2
    fi
    printf 'CHECK|%s|%s\n' "${key}" "${state}"
}

function completion_cases {
    local command mode prefix position option option_key value value_key name expected
    local sys="${FIXTURE}/system" loc="${FIXTURE}/local" unified="${FIXTURE}/unified"
    local -a flag=() words=()
    local all_names="${COMMANDS} ${OPTIONS}"
    all_names="${all_names// /$'\n'}"

    expect_completion exact-interface "${all_names}" -- ''
    expect_completion exact-options "${OPTIONS// /$'\n'}" -- '-'
    expect_completion command-prefix $'start\nstop\nstatus' -- st
    for command in ${COMMANDS}; do
        prefix="${command:0:${#command}-1}"
        expected=''
        for name in ${COMMANDS}; do
            [[ "${name}" == "${prefix}"* ]] && expected+="${name}"$'\n'
        done
        expect_completion "command.${command}" "${expected}" -- "${prefix}"
    done
    for option in ${OPTIONS}; do
        expected=''
        for name in ${OPTIONS}; do
            [[ "${name}" == "${option}"* ]] && expected+="${name}"$'\n'
        done
        expect_completion "option.${option}" "${expected}" -- "${option}"
    done
    for mode in system local user container; do
        flag=()
        [[ "${mode}" == system ]] || flag=("--${mode}")
        prefix=sys
        [[ "${mode}" != local && "${mode}" != user ]] || prefix=loc
        for command in ${TARGET_COMMANDS}; do
            for position in before after; do
                if [[ "${position}" == before ]]; then
                    words=("${flag[@]}" "${command}")
                else
                    words=("${command}" "${flag[@]}")
                fi
                expect_completion "target.${mode}.${command}.${position}" "${prefix}_one" \
                    "IOC_RUNNER_SYSTEM_CONF_DIR=${sys}" "IOC_RUNNER_LOCAL_CONF_DIR=${loc}" -- "${words[@]}" ''
                expect_completion "prefix.${mode}.${command}.${position}" "${prefix}_one" \
                    "IOC_RUNNER_SYSTEM_CONF_DIR=${sys}" "IOC_RUNNER_LOCAL_CONF_DIR=${loc}" -- "${words[@]}" "${prefix}_"
            done
        done
        expect_completion "precedence.${mode}.unified" unified_one \
            "IOC_RUNNER_CONF_DIR=${unified}" "IOC_RUNNER_SYSTEM_CONF_DIR=${sys}" \
            "IOC_RUNNER_LOCAL_CONF_DIR=${loc}" -- "${flag[@]}" log ''
        expect_completion "precedence.${mode}.empty-unified" "${prefix}_one" \
            IOC_RUNNER_CONF_DIR= "IOC_RUNNER_SYSTEM_CONF_DIR=${sys}" \
            "IOC_RUNNER_LOCAL_CONF_DIR=${loc}" -- "${flag[@]}" log ''
        expect_completion "list.${mode}" $'-v\n-vv' -- "${flag[@]}" list ''
        expect_completion "list-options.${mode}" "${OPTIONS// /$'\n'}" -- "${flag[@]}" list '-'
    done
    for mode in local user; do
        expect_completion "default.${mode}" home_one -- "--${mode}" log ''
        expect_completion "default.${mode}.empty" home_one \
            IOC_RUNNER_CONF_DIR= IOC_RUNNER_LOCAL_CONF_DIR= -- "--${mode}" log ''
    done
    expected=''
    if (( ! CATALOG )); then
        for name in /etc/procServ.d/*.conf; do
            [[ -e "${name}" ]] || continue
            name="${name##*/}"
            expected+="${name%.conf}"$'\n'
        done
    fi
    expect_completion default.system "${expected}" -- log ''
    expect_completion default.system.empty "${expected}" \
        IOC_RUNNER_CONF_DIR= IOC_RUNNER_SYSTEM_CONF_DIR= -- log ''
    expect_completion default.container "${expected}" -- --container log ''
    expect_completion directory.empty '' "IOC_RUNNER_CONF_DIR=${FIXTURE}/empty" -- log ''
    expect_completion directory.missing '' "IOC_RUNNER_CONF_DIR=${FIXTURE}/missing" -- log ''
    expect_completion directory.unreadable '' "IOC_RUNNER_CONF_DIR=${FIXTURE}/unreadable" -- log ''
    expect_completion directory.names $'_under\nhyphen-name\n123numeric' \
        "IOC_RUNNER_CONF_DIR=${FIXTURE}/names" -- log ''
    expect_completion directory.no-match '' "IOC_RUNNER_CONF_DIR=${sys}" -- log unmatched
    for command in generate install; do
        expect_completion "paths.${command}" $'payload\ninput.conf' -- "${command}" ''
        expect_completion "paths.${command}.prefix" payload -- "${command}" pay
        expect_completion "paths.${command}.options" "${OPTIONS// /$'\n'}" -- "${command}" '-'
    done
    for option in -n --lines; do
        option_key="${option//-/}"
        for value_key in empty partial dash; do
            case "${value_key}" in empty) value='' ;; partial) value=5 ;; dash) value=- ;; esac
            expect_completion "number.${option_key}.${value_key}.before" '' -- "${option}" "${value}"
            expect_completion "number.${option_key}.${value_key}.after" '' -- log "${option}" "${value}"
        done
        expect_completion "number.${option_key}.resume-command" "${all_names}" -- "${option}" 5 ''
        expect_completion "number.${option_key}.resume-target-before" sys_one \
            "IOC_RUNNER_SYSTEM_CONF_DIR=${sys}" -- "${option}" 5 log ''
        expect_completion "number.${option_key}.resume-target-after" sys_one \
            "IOC_RUNNER_SYSTEM_CONF_DIR=${sys}" -- log "${option}" 5 ''
    done
    expect_completion detach.keys $'ctrl-a\nctrl-b\nctrl-]' -- attach --detach-key ''
    expect_completion detach.prefix ctrl-a -- attach --detach-key ctrl-a
    expect_completion detach.dash '' -- attach --detach-key '-'
    expect_completion detach.resume sys_one "IOC_RUNNER_SYSTEM_CONF_DIR=${sys}" -- attach --detach-key ctrl-b ''
    expect_completion existing-target sys_one "IOC_RUNNER_SYSTEM_CONF_DIR=${sys}" -- log sys_one ''
}

if [[ $# -eq 1 && "$1" == --catalog ]]; then
    CATALOG=1
elif [[ $# -eq 2 && -r "$1" && ! -e "$2" ]]; then
    COMPLETION_FILE=$(realpath -- "$1")
    mkdir -- "$2"
    EVIDENCE=$(realpath -- "$2")
    FIXTURE="${EVIDENCE}/fixture"
    mkdir -p "${FIXTURE}"/{system,local,unified,empty,unreadable,names,paths/payload,home/.config/procServ.d}
    touch "${FIXTURE}/system/sys_one.conf" "${FIXTURE}/local/loc_one.conf" \
        "${FIXTURE}/unified/unified_one.conf" "${FIXTURE}/home/.config/procServ.d/home_one.conf" \
        "${FIXTURE}/unreadable/hidden.conf" "${FIXTURE}/names/_under.conf" \
        "${FIXTURE}/names/hyphen-name.conf" "${FIXTURE}/names/123numeric.conf" \
        "${FIXTURE}/names/ignored.txt" "${FIXTURE}/paths/input.conf"
    chmod 000 "${FIXTURE}/unreadable"
    trap 'chmod 700 "${FIXTURE}/unreadable"' EXIT
else
    printf 'Usage: %s --catalog | COMPLETION_FILE NEW_EVIDENCE_DIRECTORY\n' "$0" >&2
    exit 2
fi
completion_cases
(( FAILED == 0 ))
