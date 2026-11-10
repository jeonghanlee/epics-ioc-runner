# shellcheck shell=bash
# Real runner/client/IOC checks using util-linux script and a FIFO input feed.
# The lifecycle producer owns reporting and the running ServiceTestIOC fixture.

declare -g CONSOLE_PTY_ROOT=""
declare -g CONSOLE_PTY_HELPER=""
declare -g CONSOLE_PTY_PID=""
declare -g CONSOLE_PTY_FD=""
declare -g CONSOLE_PTY_DIR=""
declare -g CONSOLE_PTY_SEQUENCE=0
declare -g CONSOLE_PTY_ERROR=""
declare -g CONSOLE_PTY_CHILD_SOURCE
CONSOLE_PTY_CHILD_SOURCE=$(cat "$(dirname "${BASH_SOURCE[0]}")/console-pty-child.bash")
declare -gr CONSOLE_PTY_WAIT_SECONDS=10
declare -gr CONSOLE_PTY_SESSION_SECONDS=30

function console_pty_wait {
    local file="$1" pattern="$2"
    local deadline=$((SECONDS + CONSOLE_PTY_WAIT_SECONDS))
    while (( SECONDS < deadline )); do
        if [[ -f "${file}" ]] && grep -aqE -- "${pattern}" "${file}"; then
            return 0
        fi
        [[ ! -s "${CONSOLE_PTY_DIR}/exit" ]] || break
        sleep 0.05
    done
    CONSOLE_PTY_ERROR="missing output: ${pattern}"
    return 1
}

function console_pty_close {
    local rc=0
    if [[ -n "${CONSOLE_PTY_PID}" ]]; then
        # timeout owns a separate process group; terminate only that group.
        kill -TERM -- "-${CONSOLE_PTY_PID}" 2>/dev/null || true
        wait "${CONSOLE_PTY_PID}" 2>/dev/null || true
        CONSOLE_PTY_PID=""
    fi
    if [[ -n "${CONSOLE_PTY_FD}" ]]; then
        exec {CONSOLE_PTY_FD}>&- || rc=1
        CONSOLE_PTY_FD=""
    fi
    if [[ -n "${CONSOLE_PTY_DIR}" ]]; then
        rm -f -- "${CONSOLE_PTY_DIR}/input" || rc=1
    fi
    return "${rc}"
}

function console_pty_start {
    local client="$1" action="$2" key="$3"
    local command="" wrapper_pid="" client_pid="" actual_client=""
    local -a args=() runner_args=()
    console_pty_close || return 1
    CONSOLE_PTY_SEQUENCE=$((CONSOLE_PTY_SEQUENCE + 1))
    CONSOLE_PTY_DIR="${CONSOLE_PTY_ROOT}/${BASHPID}-${CONSOLE_PTY_SEQUENCE}"
    mkdir -m 700 -- "${CONSOLE_PTY_DIR}" || return 1
    mkfifo -m 600 "${CONSOLE_PTY_DIR}/input" || return 1
    exec {CONSOLE_PTY_FD}<> "${CONSOLE_PTY_DIR}/input" || return 1
    if [[ "${SUITE_SCOPE}" == local ]]; then
        runner_args+=(--local)
    fi
    runner_args+=("${action}" "${IOC_NAME}")
    [[ -z "${key}" ]] || runner_args+=(--detach-key "${key}")
    if [[ "${client}" == socat ]]; then
        args+=(unshare --mount --propagation private)
        if (( EUID != 0 )); then
            args+=(--user --map-root-user)
        fi
    fi
    args+=(/bin/bash -p "${CONSOLE_PTY_HELPER}")
    if [[ "${client}" == socat ]]; then
        args+=(--without-con "${CONSOLE_PTY_ROOT}/empty")
    fi
    args+=("${CONSOLE_PTY_DIR}" "${RUNNER_SCRIPT}" "${runner_args[@]}")
    printf -v command '%q ' "${args[@]}"
    # Preserve the host user's runtime directory when UID 0 is mapped locally.
    IOC_RUNNER_LOCAL_RUN_DIR="${RUN_DIR}" \
        timeout --kill-after=2 "${CONSOLE_PTY_SESSION_SECONDS}" \
        script -q -e -f -c "${command}" "${CONSOLE_PTY_DIR}/output" \
        < "${CONSOLE_PTY_DIR}/input" > "${CONSOLE_PTY_DIR}/script.log" 2>&1 &
    CONSOLE_PTY_PID=$!
    console_pty_wait "${CONSOLE_PTY_DIR}/output" '@@@.*PID' || return 1
    wrapper_pid=$(< "${CONSOLE_PTY_DIR}/wrapper.pid")
    read -r client_pid < "/proc/${wrapper_pid}/task/${wrapper_pid}/children" || [[ -n "${client_pid}" ]] || return 1
    client_pid="${client_pid//[[:space:]]/}"
    actual_client=$(< "/proc/${client_pid}/comm")
    printf 'pid=%s client=%s\n' "${client_pid}" "${actual_client}" > "${CONSOLE_PTY_DIR}/client" || return 1
    if [[ "${actual_client}" != "${client}" ]]; then
        CONSOLE_PTY_ERROR="expected client=${client}; observed=${actual_client}"
        return 1
    fi
}

function console_pty_send {
    printf '%s' "$1" >&"${CONSOLE_PTY_FD}"
}

function console_pty_echo {
    local token="$1"
    console_pty_send "echo ${token}"$'\r' || return 1
    console_pty_wait "${CONSOLE_PTY_DIR}/output" "^${token}"$'\r*$'
}

function console_pty_detach {
    local byte="$1" expected_rc="$2"
    local deadline=$((SECONDS + CONSOLE_PTY_WAIT_SECONDS)) rc=0 actual=""
    if [[ -e "${CONSOLE_PTY_DIR}/exit" ]] || ! kill -0 "${CONSOLE_PTY_PID}" 2>/dev/null; then
        CONSOLE_PTY_ERROR="client exited before the detach key"
        return 1
    fi
    console_pty_send "${byte}" || return 1
    while [[ ! -s "${CONSOLE_PTY_DIR}/exit" ]] && (( SECONDS < deadline )); do
        sleep 0.05
    done
    if [[ ! -s "${CONSOLE_PTY_DIR}/exit" ]]; then
        CONSOLE_PTY_ERROR="detach did not exit before deadline"
        return 1
    fi
    wait "${CONSOLE_PTY_PID}" || rc=$?
    CONSOLE_PTY_PID=""
    actual=$(< "${CONSOLE_PTY_DIR}/exit")
    if [[ "${actual}" != "${expected_rc}" || "${rc}" != "${expected_rc}" ]]; then
        CONSOLE_PTY_ERROR="client exit=${actual}; script exit=${rc}; expected=${expected_rc}"
        return 1
    fi
    if ! cmp -s "${CONSOLE_PTY_DIR}/before" "${CONSOLE_PTY_DIR}/after"; then
        CONSOLE_PTY_ERROR="terminal settings were not restored"
        return 1
    fi
    console_pty_close
}

function console_pty_snapshot {
    local main="" child="" inode=""
    main=$("${SYSTEMCTL_CMD[@]}" show "epics-@${IOC_NAME}.service" -p MainPID --value) || return 1
    [[ "${main}" =~ ^[1-9][0-9]*$ ]] || return 1
    read -r child < "/proc/${main}/task/${main}/children" || [[ -n "${child}" ]] || return 1
    [[ "${child}" =~ ^[1-9][0-9]*[[:space:]]*$ ]] || return 1
    child="${child//[[:space:]]/}"
    [[ -d "/proc/${child}" ]] || return 1
    "${SYSTEMCTL_CMD[@]}" is-active --quiet "epics-@${IOC_NAME}.service" || return 1
    inode=$(stat -c '%d:%i' "${UDS_PATH}") || return 1
    printf '%s:%s:%s\n' "${main}" "${child}" "${inode}"
}

function console_pty_attach_case {
    local client="$1" key="$2" byte="$3" label="$4"
    local before="" after="" token="PTY_${BASHPID}_${RANDOM}"
    before=$(console_pty_snapshot) || return 1
    console_pty_start "${client}" attach "${key}" || return 1
    printf '%s\n' "${before}" > "${CONSOLE_PTY_DIR}/ioc-before" || return 1
    console_pty_wait "${CONSOLE_PTY_DIR}/output" "Attaching to ${IOC_NAME} via ${client}:" || return 1
    grep -qF "Press ${label} to detach" "${CONSOLE_PTY_DIR}/output" || return 1
    console_pty_echo "${token}" || return 1
    if [[ -n "${key}" ]]; then
        # Prefix a command with the IOC's Ctrl-A line editor, then execute it.
        console_pty_send "${token}_EDIT"$'\001'"echo "$'\r' || return 1
        console_pty_wait "${CONSOLE_PTY_DIR}/output" "^${token}_EDIT"$'\r*$' || return 1
    fi
    console_pty_detach "${byte}" 0 || return 1
    after=$(console_pty_snapshot) || return 1
    printf '%s\n' "${after}" > "${CONSOLE_PTY_DIR}/ioc-after" || return 1
    [[ "${before}" == "${after}" ]] || return 1
    console_pty_start "${client}" attach "" || return 1
    console_pty_echo "${token}_RECONNECTED" || return 1
    console_pty_detach $'\001' 0 || return 1
    after=$(console_pty_snapshot) || return 1
    [[ "${before}" == "${after}" ]]
}

function console_pty_control {
    # An independent real attachment supplies output and checks IOC state while
    # the parent retains its monitor terminal. Never close the parent's client.
    local input="$1" expected="$2"
    (
        CONSOLE_PTY_PID=""
        if [[ -n "${CONSOLE_PTY_FD}" ]]; then exec {CONSOLE_PTY_FD}>&-; fi
        CONSOLE_PTY_FD=""
        CONSOLE_PTY_DIR=""
        trap console_pty_close EXIT
        console_pty_start con attach "" || return 1
        console_pty_send "${input}"$'\r' || return 1
        console_pty_wait "${CONSOLE_PTY_DIR}/output" "^${expected}"$'\r*$' || return 1
        console_pty_detach $'\001' 0
    )
}

function console_pty_monitor_case {
    local client="$1" byte="$2" expected_rc="$3"
    local before="" after="" token="PTY_${BASHPID}_${RANDOM}" input="" label=Ctrl-A
    before=$(console_pty_snapshot) || return 1
    input="epicsEnvSet(\"IOC_RUNNER_PTY_CHECK\", \"${token}\")"$'\r'"echo \$(IOC_RUNNER_PTY_CHECK)"
    console_pty_control "${input}" "${token}" || return 1
    console_pty_start "${client}" monitor "" || return 1
    printf '%s\n' "${before}" > "${CONSOLE_PTY_DIR}/ioc-before" || return 1
    console_pty_wait "${CONSOLE_PTY_DIR}/output" "Monitoring ${IOC_NAME} .* via ${client}:" || return 1
    [[ "${client}" != socat ]] || label=Ctrl-C
    grep -qF "Use ${label} to exit." "${CONSOLE_PTY_DIR}/output" || return 1
    console_pty_control "echo ${token}_OUTPUT" "${token}_OUTPUT" || return 1
    console_pty_wait "${CONSOLE_PTY_DIR}/output" "^${token}_OUTPUT"$'\r*$' || return 1
    console_pty_send 'epicsEnvSet("IOC_RUNNER_PTY_CHECK", "CHANGED")'$'\r' || return 1
    console_pty_control "echo ${token}_BARRIER" "${token}_BARRIER" || return 1
    console_pty_wait "${CONSOLE_PTY_DIR}/output" "^${token}_BARRIER"$'\r*$' || return 1
    console_pty_detach "${byte}" "${expected_rc}" || return 1
    after=$(console_pty_snapshot) || return 1
    printf '%s\n' "${after}" > "${CONSOLE_PTY_DIR}/ioc-after" || return 1
    [[ "${before}" == "${after}" ]] || return 1
    console_pty_control "echo \$(IOC_RUNNER_PTY_CHECK)" "${token}" || return 1
    after=$(console_pty_snapshot) || return 1
    [[ "${before}" == "${after}" ]]
}

function test_console_pty {
    local tool="" path="" ready=true client="" key="" byte="" label="" ok=false
    local -a keys=("" 'ctrl-]' ctrl-b) bytes=($'\001' $'\035' $'\002') labels=(Ctrl-A 'Ctrl-]' Ctrl-B)
    local index=0
    for tool in script timeout unshare mount socat stty mkfifo; do
        path=$(command -v "${tool}" || true)
        if [[ -z "${path}" || ! -x "${path}" ]]; then ready=false; fi
    done
    verify_state true "${ready}" "Console PTY tools are available"
    if [[ "${ready}" != true ]]; then
        close_current_remaining SKIP "requires console PTY tools"
        return
    fi
    CONSOLE_PTY_ROOT=$(mktemp -d /tmp/ioc-console-pty.XXXXXX)
    CONSOLE_PTY_HELPER="${CONSOLE_PTY_ROOT}/child.bash"
    printf '%s\n' "${CONSOLE_PTY_CHILD_SOURCE}" > "${CONSOLE_PTY_HELPER}"
    "${RUNNER_SCRIPT}" -V > "${CONSOLE_PTY_ROOT}/runner-version"
    _log INFO "Console PTY evidence: ${CONSOLE_PTY_ROOT}"
    : > "${CONSOLE_PTY_ROOT}/empty"
    chmod 600 "${CONSOLE_PTY_ROOT}/empty"
    for client in con socat; do
        for index in "${!keys[@]}"; do
            key="${keys[index]}" byte="${bytes[index]}" label="${labels[index]}"
            CONSOLE_PTY_ERROR=""
            ok=false
            if console_pty_attach_case "${client}" "${key}" "${byte}" "${label}"; then ok=true; fi
            console_pty_close || ok=false
            verify_state true "${ok}" "${client}/${label}: detach, terminal restoration, IOC continuity and reconnect"
            if [[ "${ok}" != true ]]; then
                _log WARN "Console PTY evidence: ${CONSOLE_PTY_ROOT}; ${CONSOLE_PTY_ERROR}"
            fi
        done
    done
    for client in con socat; do
        CONSOLE_PTY_ERROR=""
        ok=false
        if [[ "${client}" == con ]]; then
            if console_pty_monitor_case con $'\001' 0; then ok=true; fi
        else
            if console_pty_monitor_case socat $'\003' 130; then ok=true; fi
        fi
        console_pty_close || ok=false
        verify_state true "${ok}" "${client} monitor: output, input isolation, key exit, terminal and IOC continuity"
        if [[ "${ok}" != true ]]; then
            _log WARN "Console PTY evidence: ${CONSOLE_PTY_ROOT}; ${CONSOLE_PTY_ERROR}"
        fi
    done
}
