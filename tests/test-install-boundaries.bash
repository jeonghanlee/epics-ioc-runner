#!/usr/bin/env bash
# Full-CLI installation checks using real tools and filesystem failures.
# Run only in a disposable container prepared as described in tests/README.md.
set -euo pipefail
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export LC_ALL=C
umask 022

if [[ ${EUID} -ne 0 || ! -f /.dockerenv || ${IOC_RUNNER_DISPOSABLE_CONTAINER:-0} != 1 ]]; then
    printf '%s\n' 'Error: requires explicit disposable-container execution as root.' >&2
    exit 2
fi

readonly CASE="${1:?case required}"
readonly RUNNER="${2:?absolute runner path required}"
readonly EVIDENCE="${3:?absolute evidence directory required}"
readonly CASE_ROOT="/case/${CASE}"
readonly TEST_USER=m16check
declare -g FAILED=0
declare -g TOTAL=0
declare -g MODE=local
declare -g ACTOR="${TEST_USER}"
declare -g RESULT=0
declare -g TRACE=0
declare -g -a CLI_ENV=()
declare -g -a LEFTOVERS=()

case "${CASE}" in
    normal|write|replace|replace-existing-template|directory|site-local) ;;
    site-system) MODE=system; ACTOR=root ;;
    site-container) MODE=container; ACTOR=root ;;
    *) printf 'Error: unknown case: %s\n' "${CASE}" >&2; exit 2 ;;
esac
[[ "${RUNNER}" == /* && -r "${RUNNER}" && "${EVIDENCE}" == /* && -d "${EVIDENCE}" ]] || exit 2
trap 'printf "%s\n" "$?" > "${EVIDENCE}/${CASE}.test-status"' EXIT
id "${TEST_USER}"
for tool in procServ logrotate systemctl runuser; do
    command -v "${tool}"
done
[[ -x "${EPICS_BASE:?}/bin/${EPICS_HOST_ARCH:-linux-x86_64}/softIoc" ]] || exit 2
[[ ! -e "${CASE_ROOT}/boot" ]] || { printf 'Error: case already exists: %s\n' "${CASE_ROOT}" >&2; exit 2; }

function expect {
    local description="$1"
    local expected="$2"
    local actual="$3"
    TOTAL=$((TOTAL + 1))
    if [[ "${expected}" == "${actual}" ]]; then
        printf '[ PASS ] %s\n' "${description}"
    else
        printf '[ FAIL ] %s: expected=%s actual=%s\n' "${description}" "${expected}" "${actual}"
        FAILED=$((FAILED + 1))
    fi
}

function run_cli {
    local -a mode_args=()
    local -a bash_args=()
    [[ "${MODE}" == system ]] || mode_args+=("--${MODE}")
    (( TRACE == 0 )) || bash_args+=(-x)
    runuser -u "${ACTOR}" -- env "${CLI_ENV[@]}" bash "${bash_args[@]}" "${RUNNER}" "${mode_args[@]}" -f "$@"
}

mkdir -p "${CASE_ROOT}" "${CASE_ROOT}/boot" "${CASE_ROOT}/conf" \
    "${CASE_ROOT}/sysd" "${CASE_ROOT}/run" "${CASE_ROOT}/log"
if [[ "${MODE}" == local ]]; then
    chown "${TEST_USER}:${TEST_USER}" "${CASE_ROOT}" "${CASE_ROOT}"/*
else
    chown root:ioc "${CASE_ROOT}" "${CASE_ROOT}/boot"
    chmod 2775 "${CASE_ROOT}" "${CASE_ROOT}/boot"
fi
printf '#!%s\niocInit()\n' "${EPICS_BASE}/bin/${EPICS_HOST_ARCH:-linux-x86_64}/softIoc" \
    > "${CASE_ROOT}/boot/st.cmd"
chmod 0755 "${CASE_ROOT}/boot/st.cmd"
CLI_ENV=(
    "IOC_RUNNER_CONF_DIR=${CASE_ROOT}/conf"
    "IOC_RUNNER_LOG_DIR=${CASE_ROOT}/log"
)
[[ "${MODE}" == system ]] || CLI_ENV+=("IOC_RUNNER_RUN_DIR=${CASE_ROOT}/run")
if [[ "${MODE}" == local ]]; then
    CLI_ENV+=("IOC_RUNNER_SYSTEMD_DIR=${CASE_ROOT}/sysd")
fi
if [[ "${MODE}" == container ]]; then
    CLI_ENV+=("IOC_RUNNER_SCAN_DIR=/run/m16-install")
fi

run_cli generate "${CASE_ROOT}/boot" > "${EVIDENCE}/${CASE}.generate.stdout" \
    2> "${EVIDENCE}/${CASE}.generate.stderr"

case "${CASE}" in
    write)
        # The caller mounts only the rotation directory as a one-page tmpfs.
        [[ "$(stat -f -c %T "${CASE_ROOT}/ioc-runner")" == tmpfs ]] || exit 2
        chown "${TEST_USER}:${TEST_USER}" "${CASE_ROOT}/ioc-runner"
        dd if=/dev/zero of="${CASE_ROOT}/ioc-runner/fill" bs=4096 count=1 status=none
        df -B1 "${CASE_ROOT}/ioc-runner" > "${EVIDENCE}/${CASE}.filesystem"
        ;;
    replace|replace-existing-template)
        if [[ "${CASE}" == replace-existing-template ]]; then
            run_cli install "${CASE_ROOT}/boot/boot.conf" > "${EVIDENCE}/${CASE}.prime.stdout" \
                2> "${EVIDENCE}/${CASE}.prime.stderr"
            mv "${CASE_ROOT}/sysd/epics-logrotate.timer" "${CASE_ROOT}/saved-timer"
            TRACE=1
        fi
        # A non-owner cannot replace another user's file in a sticky directory.
        chown root:root "${CASE_ROOT}/sysd"
        chmod 1777 "${CASE_ROOT}/sysd"
        if [[ -e "${CASE_ROOT}/sysd/epics-logrotate.service" ]]; then
            chown root:root "${CASE_ROOT}/sysd/epics-logrotate.service"
        fi
        printf '%s\n' '# Protected pre-existing rotation service' > "${CASE_ROOT}/sysd/epics-logrotate.service"
        chown root:root "${CASE_ROOT}/sysd/epics-logrotate.service"
        ;;
    directory)
        install -d -o "${TEST_USER}" -g "${TEST_USER}" \
            "${CASE_ROOT}/ioc-runner" "${CASE_ROOT}/ioc-runner/logrotate.conf"
        ;;
    site-*)
        printf '%s\n' 'BROKEN="unterminated' > "${CASE_ROOT}/conf/site.env"
        ;;
esac

run_cli install "${CASE_ROOT}/boot/boot.conf" > "${EVIDENCE}/${CASE}.stdout" \
    2> "${EVIDENCE}/${CASE}.stderr" || RESULT=$?
printf '%s\n' "${RESULT}" > "${EVIDENCE}/${CASE}.status"
if [[ "${CASE}" == site-local || "${CASE}" == site-system ]]; then
    expect 'malformed site environment is rejected' 1 "${RESULT}"
    expect 'no IOC configuration deployed' absent "$(test ! -e "${CASE_ROOT}/conf/boot.conf" && printf absent || printf present)"
    expect 'grammar diagnostic identifies site environment' yes "$(grep -q 'failed the grammar check' "${EVIDENCE}/${CASE}.stderr" && printf yes || printf no)"
else
    expect 'IOC installation succeeds' 0 "${RESULT}"
    expect 'IOC configuration is retained' present "$(test -s "${CASE_ROOT}/conf/boot.conf" && printf present || printf absent)"
fi

case "${CASE}" in
    write)
        expect 'write fault reached the CLI' yes "$(grep -q 'No space left on device' "${EVIDENCE}/${CASE}.stderr" && printf yes || printf no)"
        expect 'rotation failure warns' yes "$(grep -q 'Warning: cannot write local log rotation' "${EVIDENCE}/${CASE}.stderr" && printf yes || printf no)"
        expect 'incomplete rotation config is not deployed' absent "$(test ! -e "${CASE_ROOT}/ioc-runner/logrotate.conf" && printf absent || printf present)"
        ;;
    replace|replace-existing-template)
        expect 'replacement fault reached the CLI' yes "$(grep -Eq 'Operation not permitted|Permission denied' "${EVIDENCE}/${CASE}.stderr" && printf yes || printf no)"
        expect 'rotation failure warns' yes "$(grep -q 'Warning: cannot deploy local log rotation' "${EVIDENCE}/${CASE}.stderr" && printf yes || printf no)"
        expect 'protected service remains unchanged' yes "$(grep -Fxq '# Protected pre-existing rotation service' "${CASE_ROOT}/sysd/epics-logrotate.service" && printf yes || printf no)"
        if [[ "${CASE}" == replace-existing-template ]]; then
            expect 'existing IOC template is retained' no "$(grep -q '^+ TEMPLATE_CHANGED=1$' "${EVIDENCE}/${CASE}.stderr" && printf yes || printf no)"
            expect 'changed rotation unit requests reload after later failure' yes "$(grep -q '^+ /usr/bin/systemctl --user daemon-reload$' "${EVIDENCE}/${CASE}.stderr" && printf yes || printf no)"
        fi
        ;;
    directory)
        expect 'directory target is rejected' yes "$(grep -q 'Warning: cannot deploy local log rotation' "${EVIDENCE}/${CASE}.stderr" && printf yes || printf no)"
        expect 'directory target stays empty' 0 "$(find "${CASE_ROOT}/ioc-runner/logrotate.conf" -mindepth 1 -maxdepth 1 -type f | wc -l)"
        ;;
    normal)
        for destination in ioc-runner/logrotate.conf sysd/epics-logrotate.service sysd/epics-logrotate.timer; do
            expect "rotation file ${destination} exists" present "$(test -s "${CASE_ROOT}/${destination}" && printf present || printf absent)"
        done
        ;;
    site-container)
        expect 'Container run script is rendered' present "$(test -x /run/m16-install/boot/run && printf present || printf absent)"
        expect 'unused site environment is preserved' yes "$(grep -Fxq 'BROKEN="unterminated' "${CASE_ROOT}/conf/site.env" && printf yes || printf no)"
        ;;
esac

shopt -s nullglob
LEFTOVERS=("${CASE_ROOT}"/ioc-runner/logrotate.conf.?????? "${CASE_ROOT}"/sysd/epics-logrotate.service.?????? "${CASE_ROOT}"/sysd/epics-logrotate.timer.??????)
expect 'rotation staging files are removed' 0 "${#LEFTOVERS[@]}"
printf 'INSTALL BOUNDARY case=%s total=%d failed=%d\n' "${CASE}" "${TOTAL}" "${FAILED}"
(( FAILED == 0 ))
