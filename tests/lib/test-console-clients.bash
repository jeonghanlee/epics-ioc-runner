# shellcheck shell=bash
# Exercise console client rejection through the shipped runner with con hidden
# and socat absent from PATH. Rejection happens before any connection, so no
# IOC fixture is required. Other tools on the host, including any nc, stay
# visible and must not be selected.

declare -g CONSOLE_CLIENT_CHILD
CONSOLE_CLIENT_CHILD="$(dirname "${BASH_SOURCE[0]}")/console-client-child.bash"
declare -g -r -a CONSOLE_CLIENT_TOOL_DIRS=(/usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin)
declare -g -r CONSOLE_CLIENT_ERROR="No suitable tool (con, socat) found for"
declare -g -r CONSOLE_CLIENT_HINT="Install 'con' (preferred) or 'socat'"

# Mirror every standard tool directory into one directory of symlinks so the
# caller can remove individual client names without touching the host.
function console_client_mirror_path {
    local bin="$1"
    local dir=""
    mkdir -m 700 -- "${bin}" || return 1
    for dir in "${CONSOLE_CLIENT_TOOL_DIRS[@]}"; do
        [[ -d "${dir}" ]] || continue
        ln -s -f -t "${bin}" "${dir}"/* 2>/dev/null || true
    done
}

function console_client_result {
    local action="$1" bin="$2" output_file="$3"
    local exit_code=0
    local -a args=()
    if (( EUID != 0 )); then
        args+=(--user --map-root-user)
    fi
    unshare "${args[@]}" --mount --propagation private /bin/bash -p "${CONSOLE_CLIENT_CHILD}" \
        "${bin%/*}/empty" "${bin}" "${RUNNER_SCRIPT}" --local "${action}" console_probe \
        > "${output_file}" 2>&1 || exit_code=$?
    printf '%s' "${exit_code}"
}

function verify_client_rejection {
    local description="$1" action="$2" bin="$3" output_file="$4"
    local exit_code="" output="" matched="false"
    exit_code=$(console_client_result "${action}" "${bin}" "${output_file}")
    output=$(< "${output_file}")
    if [[ "${exit_code}" == 1 &&
          "${output}" == *"${CONSOLE_CLIENT_ERROR} '${action}'"* &&
          "${output}" == *"${CONSOLE_CLIENT_HINT}"* &&
          "${output}" != *"Attaching to"* && "${output}" != *"Monitoring"* ]]; then
        matched="true"
    fi
    verify_state true "${matched}" "${description}"
    if [[ "${matched}" != true ]]; then
        _log WARN "Console client evidence: ${output_file}; exit=${exit_code}"
    fi
}

function test_console_clients {
    local step="$1"
    local root="${TEST_TMPDIR}/console-clients"
    local tool="" path="" ready=true
    local -a ns_args=()

    print_divider
    _log INFO "STEP ${step}: Console Client Selection"
    print_sub_divider
    for tool in unshare mount ln; do
        path=$(command -v "${tool}" || true)
        if [[ -z "${path}" || ! -x "${path}" ]]; then ready=false; fi
    done
    if (( EUID != 0 )); then
        ns_args+=(--user --map-root-user)
    fi
    if [[ "${ready}" == true ]] &&
       ! unshare "${ns_args[@]}" --mount --propagation private /bin/true >/dev/null 2>&1; then
        ready=false
    fi
    verify_state true "${ready}" "Console client isolation tools are available"
    if [[ "${ready}" != true ]]; then
        close_current_remaining SKIP "requires ${SUITE_ID}.S42.isolation-tools-available"
        return 0
    fi
    mkdir -m 700 -- "${root}"
    : > "${root}/empty"
    chmod 600 "${root}/empty"

    console_client_mirror_path "${root}/no-client"
    rm -f -- "${root}/no-client"/socat*
    verify_client_rejection "Attach rejects an environment without con or socat" \
        attach "${root}/no-client" "${root}/no-client-attach.log"
    verify_client_rejection "Monitor rejects an environment without con or socat" \
        monitor "${root}/no-client" "${root}/no-client-monitor.log"
}
