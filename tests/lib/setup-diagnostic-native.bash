#!/bin/bash -p
# Run the shipped setup with native tools on a disposable systemd VM.
# Filesystem writes are confined to root-owned copies and redirected targets.
# The system manager remains real and is reloaded after the namespace exits.

set -euo pipefail
# Native tools must not inherit caller options, including TAR_OPTIONS.
while IFS= read -r exported_name; do export -n "${exported_name?}"; done < <(compgen -e)
export PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
export LC_ALL=C
umask 077
unset BASH_ENV ENV CDPATH GIT_DIR GIT_WORK_TREE

declare -gr WORK_PREFIX='/var/tmp/ioc-setup-native.'
declare -gr SELF="${BASH_SOURCE[0]}"
declare -gr -a PARSER_FORMS=(help short full-help container-help conflict-help help-unknown unknown-help conflict repeat-full-help repeat-container-help)
declare -gr -a DENIED_FORMS=(noargs full container repeat-full repeat-container)
declare -gr -a INTEGRATION_KEYS=(
    baseline.exit-zero
    invalid.exit-one invalid.abort-message invalid.policy-preserved
    invalid.cli-preserved invalid.completion-preserved invalid.cli-stage-absent
    invalid.temporaries-clean valid.exit-zero valid.policy-deployed
    valid.runner-deployed valid.completion-deployed valid.temporaries-clean
    cli.exit-zero repeated-full.exit-zero protected-state-restored manager-state-restored
)
declare -gr -a PROTECTED_PATHS=(
    /etc/passwd /etc/group /etc/shadow /etc/gshadow /etc/procServ.d
    /etc/sudoers /etc/sudoers.d /etc/systemd/system/epics-@.service
    /etc/logrotate.d/procserv /usr/local/bin/ioc-runner
    /usr/bin/ioc-runner /etc/bash_completion.d/ioc-runner /var/log/procserv
)
declare -g WORK='' SETUP='' INVOKER='' CHILD_PID='' FAILED=0

function require_private_paths {
    local path parent
    local -a targets=(
        /etc/passwd /etc/group /etc/shadow /etc/gshadow /etc/procServ.d
        /etc/sudoers /etc/sudoers.d/10-epics-ioc
        /etc/systemd/system/epics-@.service /etc/logrotate.d/procserv
        "${WORK}/etc" "${WORK}/deploy" "${WORK}/tmp"
    )
    for path in "${targets[@]}"; do
        parent="${path}"
        while [[ "${parent}" != / ]]; do
            if [[ -L "${parent}" ]]; then
                printf 'Unsupported symlink in setup destination: %s\n' "${parent}" >&2
                return 1
            fi
            parent="${parent%/*}"
            [[ -n "${parent}" ]] || parent=/
        done
    done
}

function catalog {
    local caller form key
    for caller in root user; do
        for form in "${PARSER_FORMS[@]}"; do
            printf 'parser.%s.%s\n' "${caller}" "${form}"
        done
    done
    for form in "${DENIED_FORMS[@]}"; do printf 'parser.user.%s\n' "${form}"; done
    printf '%s\n' parser.no-deployment
    for key in "${INTEGRATION_KEYS[@]}"; do printf '%s\n' "${key}"; done
}

function check {
    local key="$1" expected="$2" actual="$3" state=PASS
    if [[ "${expected}" != "${actual}" ]]; then
        state=FAIL
        FAILED=$((FAILED + 1))
        printf 'FAIL %s: expected <%s>; actual <%s>\n' "${key}" "${expected}" "${actual}" >&2
    fi
    printf 'CHECK|%s|%s\n' "${key}" "${state}"
}

function snapshot {
    local prefix="$1" path failed=0 code=0
    local -a paths=()
    : > "${prefix}.absent" || return 1
    for path in "${PROTECTED_PATHS[@]}"; do
        if [[ -e "${path}" || -L "${path}" ]]; then
            paths+=("${path#/}")
        else
            printf '%s\n' "${path}" >> "${prefix}.absent" || return 1
        fi
    done
    tar --acls --xattrs --selinux --pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
        -C / -cpf "${prefix}.tar" "${paths[@]}" 2> "${prefix}.tar.stderr" || code=$?
    printf '%s\n' "${code}" > "${prefix}.tar.exit" || return 1
    (( code == 0 )) || failed=1
    code=0
    systemctl list-units --all --plain --no-legend --no-pager 'epics-*' > "${prefix}.units" 2> "${prefix}.units.stderr" || code=$?
    printf '%s\n' "${code}" > "${prefix}.units.exit" || return 1
    (( code == 0 )) || failed=1
    code=0
    systemctl list-unit-files --no-legend --no-pager 'epics-*' > "${prefix}.unit-files" 2> "${prefix}.unit-files.stderr" || code=$?
    printf '%s\n' "${code}" > "${prefix}.unit-files.exit" || return 1
    (( code == 0 )) || failed=1
    return "${failed}"
}

function setup_call {
    local key="$1" caller="$2" exit_code=0
    local -a prefix=()
    shift 2
    [[ "${caller}" == root ]] || prefix=(runuser -u "${INVOKER}" --)
    printf '%q ' "${prefix[@]}" env -i PATH="${PATH}" \
        "TMPDIR=${WORK}/tmp" "IOC_RUNNER_SYSTEM_LOG_DIR=${WORK}/logs" \
        "IOC_RUNNER_BACKUP_DIR=${WORK}/backups" "IOC_RUNNER_SCRIPT_DEST=${WORK}/deploy/runner" \
        "IOC_RUNNER_SCRIPT_SYMLINK=${WORK}/deploy/link" "IOC_RUNNER_BASH_COMP_DEST=${WORK}/deploy/completion" \
        /bin/bash -p "${SETUP}" "$@" > "${WORK}/${key}.argv"
    "${prefix[@]}" env -i PATH="${PATH}" \
        "TMPDIR=${WORK}/tmp" "IOC_RUNNER_SYSTEM_LOG_DIR=${WORK}/logs" \
        "IOC_RUNNER_BACKUP_DIR=${WORK}/backups" "IOC_RUNNER_SCRIPT_DEST=${WORK}/deploy/runner" \
        "IOC_RUNNER_SCRIPT_SYMLINK=${WORK}/deploy/link" "IOC_RUNNER_BASH_COMP_DEST=${WORK}/deploy/completion" \
        /bin/bash -p "${SETUP}" "$@" > "${WORK}/${key}.stdout" 2> "${WORK}/${key}.stderr" || exit_code=$?
    printf '%s\n' "${exit_code}" > "${WORK}/${key}.exit"
}

function parser_matrix {
    local caller form key expected_code expected_text out err actual
    local -a args=()
    snapshot "${WORK}/parser-before"
    for caller in root user; do
        for form in "${PARSER_FORMS[@]}"; do
            expected_code=0
            expected_text='Usage:'
            case "${form}" in
                help) args=(--help) ;;
                short) args=(-h) ;;
                full-help) args=(--full --help) ;;
                container-help) args=(--container -h) ;;
                conflict-help) args=(--full --container --help) ;;
                help-unknown) args=(--help --unknown) ;;
                unknown-help) args=(--unknown --help); expected_code=1; expected_text='Error: Unknown option' ;;
                conflict) args=(--full --container); expected_code=1; expected_text='are mutually exclusive' ;;
                repeat-full-help) args=(--full --full --help) ;;
                repeat-container-help) args=(--container --container --help) ;;
            esac
            key="parser.${caller}.${form}"
            setup_call "${key}" "${caller}" "${args[@]}"
            out=$(< "${WORK}/${key}.stdout")
            err=$(< "${WORK}/${key}.stderr")
            actual=false
            if [[ "$(< "${WORK}/${key}.exit")" == "${expected_code}" ]]; then
                if [[ ${expected_code} -eq 0 && "${out}" == *"${expected_text}"* && -z "${err}" ]]; then
                    actual=true
                elif [[ ${expected_code} -eq 1 && "${err}" == *"${expected_text}"* && -z "${out}" ]]; then
                    actual=true
                fi
            fi
            check "${key}" true "${actual}"
        done
    done
    for form in "${DENIED_FORMS[@]}"; do
        case "${form}" in
            noargs) args=() ;;
            full) args=(--full) ;;
            container) args=(--container) ;;
            repeat-full) args=(--full --full) ;;
            repeat-container) args=(--container --container) ;;
        esac
        key="parser.user.${form}"
        setup_call "${key}" user "${args[@]}"
        err=$(< "${WORK}/${key}.stderr")
        actual=false
        [[ "$(< "${WORK}/${key}.exit")" == 1 && "${err}" == *'must be run as root'* && ! -s "${WORK}/${key}.stdout" ]] && actual=true
        check "${key}" true "${actual}"
    done
    snapshot "${WORK}/parser-after"
    actual=false
    if cmp -s "${WORK}/parser-before.tar" "${WORK}/parser-after.tar" &&
       [[ -z "$(find "${WORK}/deploy" "${WORK}/tmp" -mindepth 1 -print -quit)" ]]; then actual=true; fi
    check parser.no-deployment true "${actual}"
}

function integration {
    local invalid_exit=0 output actual path
    setup_call baseline root --full
    check baseline.exit-zero 0 "$(< "${WORK}/baseline.exit")"
    [[ "$(< "${WORK}/baseline.exit")" == 0 ]] || return 1
    cp -p /etc/logrotate.d/procserv "${WORK}/policy-before"
    cp -p "${WORK}/deploy/runner" "${WORK}/runner-before"
    cp -p "${WORK}/deploy/completion" "${WORK}/completion-before"

    printf '%q ' env -i PATH="${PATH}" "TMPDIR=${WORK}/tmp" \
        "IOC_RUNNER_SYSTEM_LOG_DIR=${WORK}/bad}tail" "IOC_RUNNER_BACKUP_DIR=${WORK}/backups" \
        "IOC_RUNNER_SCRIPT_DEST=${WORK}/deploy/runner" "IOC_RUNNER_SCRIPT_SYMLINK=${WORK}/deploy/link" \
        "IOC_RUNNER_BASH_COMP_DEST=${WORK}/deploy/completion" /bin/bash -p "${SETUP}" --full > "${WORK}/invalid.argv"
    env -i PATH="${PATH}" "TMPDIR=${WORK}/tmp" \
        "IOC_RUNNER_SYSTEM_LOG_DIR=${WORK}/bad}tail" "IOC_RUNNER_BACKUP_DIR=${WORK}/backups" \
        "IOC_RUNNER_SCRIPT_DEST=${WORK}/deploy/runner" "IOC_RUNNER_SCRIPT_SYMLINK=${WORK}/deploy/link" \
        "IOC_RUNNER_BASH_COMP_DEST=${WORK}/deploy/completion" /bin/bash -p "${SETUP}" --full \
        > "${WORK}/invalid.stdout" 2> "${WORK}/invalid.stderr" || invalid_exit=$?
    printf '%s\n' "${invalid_exit}" > "${WORK}/invalid.exit"
    check invalid.exit-one 1 "${invalid_exit}"
    output=$(< "${WORK}/invalid.stdout")
    actual=false
    [[ "${output}" == *'Setup aborted; logrotate policy not deployed.'* ]] && actual=true
    check invalid.abort-message true "${actual}"
    actual=false; cmp -s "${WORK}/policy-before" /etc/logrotate.d/procserv && actual=true
    check invalid.policy-preserved true "${actual}"
    actual=false; cmp -s "${WORK}/runner-before" "${WORK}/deploy/runner" && actual=true
    check invalid.cli-preserved true "${actual}"
    actual=false; cmp -s "${WORK}/completion-before" "${WORK}/deploy/completion" && actual=true
    check invalid.completion-preserved true "${actual}"
    actual=false; [[ "${output}" != *'STEP 7:'* ]] && actual=true
    check invalid.cli-stage-absent true "${actual}"
    actual=false; [[ -z "$(find "${WORK}/tmp" -mindepth 1 -print -quit)" ]] && actual=true
    check invalid.temporaries-clean true "${actual}"

    setup_call valid root --full
    check valid.exit-zero 0 "$(< "${WORK}/valid.exit")"
    actual=false; grep -qF -- "${WORK}/logs/*.log" /etc/logrotate.d/procserv && actual=true
    check valid.policy-deployed true "${actual}"
    grep -Ev '^declare -g RUNNER_(GIT_HASH|COMMIT_DATE|INSTALL_DATE)=' "${SETUP%/*}/ioc-runner" > "${WORK}/runner-source.normalized"
    grep -Ev '^declare -g RUNNER_(GIT_HASH|COMMIT_DATE|INSTALL_DATE)=' "${WORK}/deploy/runner" > "${WORK}/runner-deployed.normalized"
    actual=false
    if [[ -f "${WORK}/deploy/runner" && ! -L "${WORK}/deploy/runner" && "$(stat -c '%u:%g:%a' "${WORK}/deploy/runner")" == 0:0:755 ]] &&
       cmp -s "${WORK}/runner-source.normalized" "${WORK}/runner-deployed.normalized"; then actual=true; fi
    for path in GIT_HASH COMMIT_DATE INSTALL_DATE; do
        [[ "$(grep -c "^declare -g RUNNER_${path}=" "${WORK}/deploy/runner")" == 1 ]] || actual=false
        grep -Eq "^declare -g RUNNER_${path}=\"[^\"]+\"$" "${WORK}/deploy/runner" || actual=false
    done
    check valid.runner-deployed true "${actual}"
    actual=false; cmp -s "${SETUP%/*}/ioc-runner-completion.bash" "${WORK}/deploy/completion" && actual=true
    check valid.completion-deployed true "${actual}"
    actual=false; [[ -z "$(find "${WORK}/tmp" -mindepth 1 -print -quit)" ]] && actual=true
    check valid.temporaries-clean true "${actual}"
    setup_call cli root
    check cli.exit-zero 0 "$(< "${WORK}/cli.exit")"
    setup_call repeated-full root --full --full
    check repeated-full.exit-zero 0 "$(< "${WORK}/repeated-full.exit")"
    # Preserve private deployment artifacts and their permissions for readback.
    for path in /etc/procServ.d /etc/sudoers.d/10-epics-ioc /etc/systemd/system/epics-@.service /etc/logrotate.d/procserv; do
        stat -c '%n %U:%G %a' "${path}"
        getfacl -p "${path}"
        ls -Zd "${path}"
    done > "${WORK}/namespace-final-state.txt"
}

function finish {
    local rc=$? actual=false attempt stopped=true reload_code=0
    trap '' HUP INT TERM
    trap - EXIT
    set +e
    if [[ -n "${CHILD_PID}" ]] && kill -0 -- "-${CHILD_PID}" 2>/dev/null; then
        kill -TERM -- "-${CHILD_PID}" 2>/dev/null
        for ((attempt=0; attempt<20; attempt+=1)); do
            kill -0 -- "-${CHILD_PID}" 2>/dev/null || break
            sleep 0.1
        done
        if kill -0 -- "-${CHILD_PID}" 2>/dev/null; then kill -KILL -- "-${CHILD_PID}" 2>/dev/null; fi
    fi
    if [[ -n "${CHILD_PID}" ]]; then
        wait "${CHILD_PID}" 2>/dev/null
        for ((attempt=0; attempt<20; attempt+=1)); do
            kill -0 -- "-${CHILD_PID}" 2>/dev/null || break
            sleep 0.1
        done
        if kill -0 -- "-${CHILD_PID}" 2>/dev/null; then
            stopped=false
            rc=1
            printf 'Setup process group is still present: %s\n' "${CHILD_PID}" >&2
        fi
    fi
    printf '%s\n' "${stopped}" > "${WORK}/children-stopped"
    # PID 1 reads its original filesystem view, including during private setup.
    systemctl daemon-reload > "${WORK}/restore-reload.stdout" 2> "${WORK}/restore-reload.stderr" || reload_code=$?
    printf '%s\n' "${reload_code}" > "${WORK}/restore-reload.exit"
    (( reload_code == 0 )) || rc=1
    if snapshot "${WORK}/after"; then
        if [[ "${stopped}" == true ]] && cmp -s "${WORK}/before.tar" "${WORK}/after.tar" &&
           cmp -s "${WORK}/before.absent" "${WORK}/after.absent"; then actual=true; fi
        check protected-state-restored true "${actual}"
        actual=false
        if [[ "${stopped}" == true && ${reload_code} -eq 0 ]] && cmp -s "${WORK}/before.units" "${WORK}/after.units" &&
           cmp -s "${WORK}/before.unit-files" "${WORK}/after.unit-files"; then actual=true; fi
        check manager-state-restored true "${actual}"
    else
        rc=1
    fi
    printf 'Evidence: %s\n' "${WORK}" >&2
    [[ ${FAILED} -eq 0 ]] || rc=1
    exit "${rc}"
}

if [[ $# -eq 1 && "$1" == --catalog ]]; then catalog; exit 0; fi
[[ ${EUID} -eq 0 && $- == *p* ]] || { printf 'Run with root /bin/bash -p.\n' >&2; exit 2; }
if [[ $# -eq 4 && "$1" == --inside ]]; then
    WORK="$2" SETUP="$3" INVOKER="$4"
    [[ "${WORK}" == "${WORK_PREFIX}"* && -d "${WORK}" && ! -L "${WORK}" && "$(stat -c '%u:%g:%a' "${WORK}")" == 0:0:700 ]] || exit 2
    [[ "$(readlink /proc/self/ns/mnt)" != "$(readlink /proc/1/ns/mnt)" ]] || exit 2
    require_private_paths
    mount --make-rprivate /
    mount --bind "${WORK}/etc" /etc
    require_private_paths
    parser_matrix
    integration
    (( FAILED == 0 ))
    exit
fi
[[ $# -eq 2 && "$1" == /* && -f "$1" && "$2" != root ]] || exit 2
SETUP="$1" INVOKER="$2"
[[ "$(id -u "${INVOKER}")" != 0 && "$(cat /proc/1/comm)" == systemd ]] || exit 2
getent passwd ioc-srv >/dev/null
getent group ioc >/dev/null
for required in unshare mount tar runuser logrotate getfacl setfacl systemctl setsid; do
    resolved=$(command -v "${required}")
    [[ -x "${resolved}" ]] || exit 2
done
WORK=$(mktemp -d "${WORK_PREFIX}XXXXXX")
mkdir "${WORK}/deploy" "${WORK}/tmp"
require_private_paths
snapshot "${WORK}/before"
trap finish EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM
cp -a /etc "${WORK}/etc"
setsid unshare --mount -- /bin/bash -p "${SELF}" --inside "${WORK}" "${SETUP}" "${INVOKER}" &
CHILD_PID=$!
wait "${CHILD_PID}"
