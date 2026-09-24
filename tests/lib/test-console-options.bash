# Exercise detach option parsing and the shipped completion handler.
# Accepted keys stop at an unavailable outer client path, before any connection.

function verify_detach_cli_result {
    local description="$1"
    local expected_message="$2"
    local output=""
    local exit_code=0
    local matched="false"
    shift 2

    output=$(IOC_RUNNER_CON_TOOL="${TEST_TMPDIR}/absent-console-client" \
        bash "${RUNNER_SCRIPT}" --local "$@" 2>&1) || exit_code=$?
    if [[ "${exit_code}" == 1 && "${output}" == *"${expected_message}"* ]]; then
        matched="true"
    fi
    verify_state true "${matched}" "${description}"
}

function test_console_options {
    local step="$1"
    local key=""
    local letter=""
    local output=""
    local exit_code=0
    local matched="false"
    local completion="${SC_TOP}/../bin/ioc-runner-completion.bash"
    local client_error="is not an executable file"
    local -a keys=()

    print_divider
    _log INFO "STEP ${step}: Console Detach Options and Completion"
    verify_detach_cli_result "Missing detach value is rejected" \
        "--detach-key requires a key" attach console_probe --detach-key
    verify_detach_cli_result "Empty detach value is rejected" \
        "--detach-key requires a key" attach console_probe --detach-key ""
    verify_detach_cli_result "Escape is not a named control key" \
        "--detach-key expects a control key" attach console_probe --detach-key escape
    verify_detach_cli_result "Digit detach suffix is rejected" \
        "Invalid detach key" attach console_probe --detach-key ctrl-1
    verify_detach_cli_result "Multi-character detach suffix is rejected" \
        "--detach-key expects a control key" attach console_probe --detach-key ctrl-aa
    verify_detach_cli_result "Ctrl-T remains reserved" \
        "Ctrl-T is reserved" attach console_probe --detach-key ctrl-t
    verify_detach_cli_result "Monitor rejects attach-only detach option" \
        "--detach-key is supported only for the 'attach' command" monitor console_probe --detach-key ctrl-b
    verify_detach_cli_result "List rejects attach-only detach option" \
        "--detach-key is supported only for the 'attach' command" list --detach-key ctrl-b

    for letter in {a..s} {u..z}; do keys+=("ctrl-${letter}"); done
    keys+=('ctrl-[' "ctrl-\\" 'ctrl-]' 'ctrl-^' 'ctrl-_')
    for key in "${keys[@]}"; do
        verify_detach_cli_result "${key} reaches client resolution" \
            "${client_error}" attach console_probe --detach-key "${key}"
    done
    verify_detach_cli_result "Uppercase key reaches client resolution" \
        "${client_error}" attach console_probe --detach-key CTRL-B
    verify_detach_cli_result "Detach option before command is accepted" \
        "${client_error}" --detach-key ctrl-b attach console_probe

    # Execute the documented single-quoted backslash spelling through Bash.
    exit_code=0
    output=$(IOC_RUNNER_CON_TOOL="${TEST_TMPDIR}/absent-console-client" \
        bash -c "bash \"\$1\" --local attach console_probe --detach-key 'ctrl-\\'" \
        bash "${RUNNER_SCRIPT}" 2>&1) || exit_code=$?
    matched="false"
    if [[ "${exit_code}" == 1 && "${output}" == *"${client_error}"* ]]; then matched="true"; fi
    verify_state true "${matched}" "Documented backslash quoting reaches client resolution"

    exit_code=0
    output=$(bash "${RUNNER_SCRIPT}" --help 2>&1) || exit_code=$?
    matched="false"
    if [[ "${exit_code}" == 0 && "${output}" == *"--detach-key KEY"* &&
          "${output}" == *"attach only; default: ctrl-a"* ]]; then matched="true"; fi
    verify_state true "${matched}" "Help describes attach-only option and default key"

    matched="false"
    [[ -r "${completion}" ]] && matched="true"
    verify_state true "${matched}" "Detach completion script is available"
    if [[ "${matched}" != true ]]; then
        close_current_remaining SKIP "requires ${SUITE_ID}.S41.completion-available"
        return 0
    fi
    output=$(
        # shellcheck source=/dev/null
        source "${completion}"
        COMP_WORDS=(ioc-runner attach console_probe --de)
        COMP_CWORD=3
        COMPREPLY=()
        _ioc_runner_completions
        printf '%s\n' "${COMPREPLY[@]}"
    )
    verify_state --detach-key "${output}" "Completion offers detach option"
    output=$(
        # shellcheck source=/dev/null
        source "${completion}"
        COMP_WORDS=(ioc-runner attach console_probe --detach-key "")
        COMP_CWORD=4
        COMPREPLY=()
        _ioc_runner_completions
        printf '%s\n' "${COMPREPLY[@]}"
    )
    verify_state $'ctrl-a\nctrl-b\nctrl-]' "${output}" "Completion offers supported example keys"
    output=$(
        # shellcheck source=/dev/null
        source "${completion}"
        COMP_WORDS=(ioc-runner attach console_probe --detach-key ctrl-b)
        COMP_CWORD=4
        COMPREPLY=()
        _ioc_runner_completions
        printf '%s\n' "${COMPREPLY[@]}"
    )
    verify_state ctrl-b "${output}" "Completion filters the key prefix"
    mkdir -p "${TEST_TMPDIR}/detach-completion"
    touch "${TEST_TMPDIR}/detach-completion/console_target.conf"
    output=$(
        # shellcheck source=/dev/null
        source "${completion}"
        export IOC_RUNNER_CONF_DIR="${TEST_TMPDIR}/detach-completion"
        COMP_WORDS=(ioc-runner --local attach --detach-key ctrl-b console_)
        COMP_CWORD=5
        COMPREPLY=()
        _ioc_runner_completions
        printf '%s\n' "${COMPREPLY[@]}"
    )
    verify_state console_target "${output}" "Completion resumes IOC targets after the detach value"
}
