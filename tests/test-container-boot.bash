#!/usr/bin/env bash
# Exercise installed container services across real PID 1 restarts. Docker is
# the outer boundary; setup, CLI, s6, procServ and softIoc run without doubles.
set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
umask 022
unset BASH_ENV ENV CDPATH

declare -gr BOOT_USER="${IOC_RUNNER_SYSTEM_USER:-ioc-srv}"
declare -gr BOOT_GROUP="${IOC_RUNNER_SYSTEM_GROUP:-ioc}"
declare -gr BOOT_RUN="${IOC_RUNNER_RUN_DIR:-/run/procserv}"
declare -gr ENABLED="BootEnabled"
declare -gr DISABLED="BootDisabled"
declare -gr SCAN="/run/s6-procserv"
declare -gr PAYLOAD="/tmp/ioc-runner-boot"
declare -g CONTAINER_ID=""
declare -g REPORT=""

function fail {
    printf '[ FAIL ] %s\n' "$*" >&2
    exit 1
}

function pass {
    printf '[ PASS ] %s\n' "$*"
}

function runner {
    /usr/local/bin/ioc-runner --container "$@"
}

function assert_disabled {
    [[ "$(s6-svstat -o up "${SCAN}/${DISABLED}")" == false ]] || fail 'Disabled IOC started'
    [[ -f "${SCAN}/${DISABLED}/down" && ! -e "${BOOT_RUN}/${DISABLED}" ]] || fail 'Disabled IOC runtime changed'
}

function prepare {
    local name=""
    local softioc="${EPICS_BASE:?EPICS_BASE must be set}/bin/${EPICS_HOST_ARCH:-linux-x86_64}/softIoc"

    [[ -x "${softioc}" ]] || fail 'Native softIoc is missing'
    install -d -m 2775 -o root -g "${BOOT_GROUP}" "${PAYLOAD}"
    for name in "${ENABLED}" "${DISABLED}"; do
        install -d -m 2775 -o root -g "${BOOT_GROUP}" "${PAYLOAD}/${name}"
        printf '#!%s\niocInit()\n' "${softioc}" > "${PAYLOAD}/${name}/st.cmd"
        chmod 0775 "${PAYLOAD}/${name}/st.cmd"
        chgrp "${BOOT_GROUP}" "${PAYLOAD}/${name}/st.cmd"
        runner generate "${PAYLOAD}/${name}"
        runner install "${PAYLOAD}/${name}/${name}.conf"
        [[ ! -e "${BOOT_RUN}/${name}" ]] || fail 'Install created the socket parent before boot'
        [[ "$(s6-svstat -o up "${SCAN}/${name}")" == false ]] || fail 'Fresh IOC started before enable'
    done
    runner enable "${ENABLED}"
    runner disable "${DISABLED}"
    [[ ! -e "${SCAN}/${ENABLED}/down" ]] || fail 'Enable did not persist'
    assert_disabled
    sha256sum "${SCAN}/${ENABLED}/run" "${SCAN}/${DISABLED}/run" \
        "/etc/procServ.d/${ENABLED}.conf" "/etc/procServ.d/${DISABLED}.conf" > "${PAYLOAD}/installed.sha256"
    pass 'Installed and enabled without CLI start or restart'
    install -d "${PAYLOAD}/shadow"
    printf '#!/bin/sh\nprintf shadow > %s/shadow-install-ran\nexit 99\n' "${PAYLOAD}" > "${PAYLOAD}/shadow/install"
    chmod 0755 "${PAYLOAD}/shadow/install"
}

function observe {
    local attempt=0
    local pid=""
    local child=""
    local owner=""
    local executable=""
    local ready=0

    owner="$(id -u "${BOOT_USER}"):$(getent group "${BOOT_GROUP}" | cut -d: -f3):770"
    [[ "$(readlink /proc/1/exe)" == */s6-svscan ]] || fail 's6-svscan is not PID 1'
    for ((attempt=0; attempt<100; attempt++)); do
        if [[ -S "${BOOT_RUN}/${ENABLED}/control" ]]; then
            pid=$(s6-svstat -o pid "${SCAN}/${ENABLED}")
            executable=$(setpriv --reuid "${BOOT_USER}" --regid "${BOOT_GROUP}" --init-groups \
                readlink "/proc/${pid}/exe" || true)
            if [[ "${pid}" =~ ^[1-9][0-9]*$ ]] && [[ "${executable}" == */procServ ]]; then
                child=$(pgrep -P "${pid}" || true)
                executable=$(setpriv --reuid "${BOOT_USER}" --regid "${BOOT_GROUP}" --init-groups \
                    readlink "/proc/${child}/exe" || true)
                if [[ "${child}" =~ ^[1-9][0-9]*$ && "${executable}" == */softIoc ]]; then
                    ready=1
                    break
                fi
            fi
        fi
        sleep 0.1
    done
    (( ready )) || fail 'Enabled IOC did not boot with its control socket and native softIoc'
    [[ "$(stat -c '%u:%g:%a' "${BOOT_RUN}/${ENABLED}")" == "${owner}" ]] || fail 'Socket directory identity or mode differs'
    [[ "$(stat -c %u "/proc/${pid}")" == "$(id -u "${BOOT_USER}")" ]] || fail 'procServ runs under wrong identity'
    [[ "$(stat -c %u "/proc/${child}")" == "$(id -u "${BOOT_USER}")" ]] || fail 'softIoc runs under wrong identity'
    assert_disabled
    sha256sum -c "${PAYLOAD}/installed.sha256"
    pass 'Native enabled IOC and socket are live; disabled IOC remains down'
}

function observe_environment {
    local pid="" child="" entry=""
    local parent_path="" child_path=""
    local console_pid="" attempt=0 console_result=0
    local caget="${EPICS_BASE:?}/bin/${EPICS_HOST_ARCH:-linux-x86_64}/caget"

    while IFS= read -r -d '' entry; do
        [[ "${entry}" != PATH=* ]] || parent_path="${entry#PATH=}"
    done < /proc/1/environ
    pid=$(s6-svstat -o pid "${SCAN}/${ENABLED}")
    child=$(pgrep -P "${pid}")
    while IFS= read -r -d '' entry; do
        [[ "${entry}" != PATH=* ]] || child_path="${entry#PATH=}"
    done < <(setpriv --reuid "${BOOT_USER}" --regid "${BOOT_GROUP}" --init-groups \
        cat "/proc/${child}/environ")
    printf 'Supervisor PATH: %s\nIOC PATH: %s\n' "${parent_path}" "${child_path}"

    # Keep console input open until the native IOC has executed the command.
    mkfifo "${PAYLOAD}/console.in"
    exec 3<> "${PAYLOAD}/console.in"
    timeout 10 socat - "UNIX-CONNECT:${BOOT_RUN}/${ENABLED}/control" \
        < "${PAYLOAD}/console.in" > "${PAYLOAD}/console.log" 2>&1 3>&- &
    console_pid=$!
    for ((attempt=0; attempt<50; attempt++)); do
        grep -q 'Welcome to procServ' "${PAYLOAD}/console.log" && break
        sleep 0.1
    done
    printf 'system "command -v caget; printf IOC_ENV_CHECK_DONE\\\\n"\n' >&3
    for ((attempt=0; attempt<50; attempt++)); do
        grep -q '^IOC_ENV_CHECK_DONE' "${PAYLOAD}/console.log" && break
        sleep 0.1
    done
    exec 3>&-
    wait "${console_pid}" || console_result=$?
    rm -- "${PAYLOAD}/console.in"
    cat "${PAYLOAD}/console.log"
    [[ "${console_result}" == 0 || "${console_result}" == 124 ]] || fail 'Console transport failed'
    grep -q '^IOC_ENV_CHECK_DONE' "${PAYLOAD}/console.log" || fail 'IOC console command did not complete'
    grep -Fx "${caget}" <(tr -d '\r' < "${PAYLOAD}/console.log") >/dev/null || fail 'IOC cannot resolve native caget'
    [[ -n "${parent_path}" && "${child_path}" == "${parent_path}" ]] || fail 'IOC PATH differs from supervisor PATH'
    [[ ! -e "${PAYLOAD}/shadow-install-ran" ]] || fail 'Root preparation used the inherited install command'
    pass 'IOC preserves supervisor PATH and resolves caget; root preparation ignores the shadow install'
}

function deny_directory {
    runner stop "${ENABLED}"
    [[ "$(s6-svstat -o up "${SCAN}/${ENABLED}")" == false ]] || fail 'IOC did not stop'
    # Replace only this test IOC's runtime directory with a regular file.
    rm -f -- "${BOOT_RUN}/${ENABLED}/control"
    rmdir -- "${BOOT_RUN}/${ENABLED}"
    printf '%s\n' 'directory-creation-blocker' > "${BOOT_RUN}/${ENABLED}"
}

function regenerate {
    local name=""

    for name in "${ENABLED}" "${DISABLED}"; do
        runner stop "${name}"
        runner --force install "/etc/procServ.d/${name}.conf"
        runner view "${name}"
        [[ "$(s6-svstat -o up "${SCAN}/${name}")" == false ]] || fail 'Reinstall started the IOC'
    done
    [[ ! -e "${SCAN}/${ENABLED}/down" ]] || fail 'Reinstall disabled an enabled IOC'
    assert_disabled
    sha256sum -c "${PAYLOAD}/installed.sha256"
    pass 'Reinstall preserved service contents and boot state while stopped'
}

function observe_denial {
    local attempt=0
    local observed=0

    for ((attempt=0; attempt<100; attempt++)); do
        if [[ "$(s6-svstat -o up,exitcode "${SCAN}/${ENABLED}")" == 'false 1' ]]; then
            observed=1
            break
        fi
        sleep 0.1
    done
    (( observed )) || fail 'Preparation failure did not exit 1'
    [[ -f "${BOOT_RUN}/${ENABLED}" ]] || fail 'Failure replaced the blocker'
    [[ "$(cat "${BOOT_RUN}/${ENABLED}")" == directory-creation-blocker ]] || fail 'Failure changed the blocker'
    if pgrep -x procServ >/dev/null; then
        fail 'procServ ran despite directory preparation failure'
    fi
    assert_disabled
    sha256sum -c "${PAYLOAD}/installed.sha256"
    pass 'Directory preparation failed before procServ; blocker preserved'
}

function cleanup {
    local result=$?
    local cleanup_result=0

    trap - EXIT
    if [[ -n "${CONTAINER_ID}" ]]; then
        docker logs "${CONTAINER_ID}" > "${REPORT}/container.log" 2>&1 || cleanup_result=1
        docker cp "${CONTAINER_ID}:${SCAN}/${ENABLED}/run" "${REPORT}/generated-run" >/dev/null 2>&1 || cleanup_result=1
        docker stop --time 10 "${CONTAINER_ID}" > "${REPORT}/stop.log" 2>&1 || cleanup_result=1
        docker inspect "${CONTAINER_ID}" > "${REPORT}/final-inspect.json" || cleanup_result=1
        docker rm "${CONTAINER_ID}" > "${REPORT}/remove.log" 2>&1 || cleanup_result=1
    fi
    (( cleanup_result == 0 )) || result=1
    printf 'Exit: %s\nReports: %s\n' "${result}" "${REPORT}"
    exit "${result}"
}

function ready_scanner {
    local attempt=0

    for ((attempt=0; attempt<100; attempt++)); do
        if docker exec "${CONTAINER_ID}" s6-svscanctl -z "${SCAN}" >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.1
    done
    fail 'Native scanner did not become ready'
}

function phase {
    local action="$1"
    local label="${2:-$1}"

    docker exec "${CONTAINER_ID}" bash -p /boot-test "${action}" > "${REPORT}/${label}.log" 2>&1 || {
        cat "${REPORT}/${label}.log"
        fail "Phase ${action}"
    }
    cat "${REPORT}/${label}.log"
}

function reboot {
    local before=""
    local after=""

    before=$(docker inspect --format '{{.State.StartedAt}}' "${CONTAINER_ID}")
    docker stop --time 10 "${CONTAINER_ID}" >/dev/null
    docker start "${CONTAINER_ID}" >/dev/null
    ready_scanner
    after=$(docker inspect --format '{{.State.StartedAt}}' "${CONTAINER_ID}")
    [[ "${before}" != "${after}" ]] || fail 'Container lifetime did not change'
}

function initialized {
    local expected="$1"
    local attempt=0
    local count=0

    for ((attempt=0; attempt<100; attempt++)); do
        docker logs "${CONTAINER_ID}" > "${REPORT}/initialization.log" 2>&1
        count=$(grep -c 'All initialization complete' "${REPORT}/initialization.log" || true)
        if (( count >= expected )); then
            pass "Observed ${expected} genuine IOC initialization completions"
            return 0
        fi
        sleep 0.1
    done
    fail 'Native IOC initialization marker missing'
}

function main {
    local image="${1:?Usage: bash tests/test-container-boot.bash IMAGE}"
    local script=""
    local repo=""
    # Expand PATH in the container so native EPICS search paths are retained.
    # shellcheck disable=SC2016
    local launch='if [ ! -x /usr/local/bin/ioc-runner ]; then exit 1; fi; export PATH=/tmp/ioc-runner-boot/shadow:$PATH; exec s6-svscan /run/s6-procserv'

    script=$(realpath "${BASH_SOURCE[0]}")
    repo="${IOC_RUNNER_BOOT_SOURCE_ROOT:-$(dirname "$(dirname "${script}")")}"
    REPORT=$(mktemp -d "${IOC_RUNNER_CONTAINER_REPORT_DIR:-/tmp}/ioc-runner-boot.XXXXXX")
    trap cleanup EXIT
    docker image inspect "${image}" > "${REPORT}/image.json"
    sha256sum "${repo}/bin/ioc-runner" "${script}" > "${REPORT}/source.sha256"
    CONTAINER_ID=$(docker run -d --network none \
        --mount "type=bind,src=${repo},dst=/repo,readonly" \
        --mount "type=bind,src=${script},dst=/boot-test,readonly" \
        -e "IOC_RUNNER_SYSTEM_USER=${BOOT_USER}" -e "IOC_RUNNER_SYSTEM_GROUP=${BOOT_GROUP}" \
        -e "IOC_RUNNER_RUN_DIR=${BOOT_RUN}" -e EPICS_IOCSH_HISTFILE= \
        --entrypoint /bin/bash "${image}" -p -c \
        "if [ ! -f /setup-complete ]; then bash -p /repo/bin/setup-system-infra.bash --container && touch /setup-complete || exit 1; fi; ${launch}")
    ready_scanner
    phase prepare
    reboot
    phase observe cold-boot
    initialized 1
    phase observe-environment cold-environment
    reboot
    phase observe retained-parent
    initialized 2
    phase observe-environment retained-environment
    phase regenerate
    phase deny-directory
    reboot
    phase observe-denial
    docker logs "${CONTAINER_ID}" > "${REPORT}/denial.log" 2>&1
    grep -F "Error: IOC '${ENABLED}' cannot prepare socket directory" "${REPORT}/denial.log" >/dev/null || fail 'Missing preparation diagnostic'
    pass 'All container boot checks completed'
}

case "${1:-}" in
    prepare) prepare ;;
    observe) observe ;;
    observe-environment) observe_environment ;;
    regenerate) regenerate ;;
    deny-directory) deny_directory ;;
    observe-denial) observe_denial ;;
    *) main "$@" ;;
esac
