#!/usr/bin/env bash
#
# Error path and negative-case tests for ioc-runner.
# Requires only mock con and procServ binaries, both exported by _setup via
# IOC_RUNNER_CON_TOOL / IOC_RUNNER_PROCSERV_TOOL. Does not require EPICS, a host
# procServ, or a running systemd service.

set -e

declare -g RED='\033[0;31m'
declare -g GREEN='\033[0;32m'
declare -g MAGENTA='\033[0;35m'
declare -g BLUE='\033[0;34m'
declare -g YELLOW='\033[0;33m'
declare -g NC='\033[0m'

declare -g TEST_TOTAL=0
declare -g TEST_PASSED=0
declare -g TEST_FAILED=0
declare -g SCRIPT_ERROR=0
declare -g -a FAILED_DETAILS=()

declare -g SC_RPATH
declare -g SC_TOP
SC_RPATH="$(realpath "$0")"
SC_TOP="${SC_RPATH%/*}"

declare -g RUNNER_SCRIPT="${SC_TOP}/../bin/ioc-runner"

# Extract CRASH_LOG_PATTERNS and CRASH_LOG_EXCLUDE_PATTERNS from runner script via
# zero-fork parameter expansion.
# Source-and-execute is not viable: the runner auto-dispatches commands at module bottom.
declare -g CRASH_LOG_PATTERNS=""
declare -g CRASH_LOG_PATTERNS_FATAL=""
declare -g CRASH_LOG_PATTERNS_AMBIGUOUS=""
declare -g CRASH_LOG_EXCLUDE_PATTERNS=""
declare _line
# Order matters: the _FATAL / _AMBIGUOUS clauses are tested before the bare
# CRASH_LOG_PATTERNS= clause. The bare glob anchors on '=' so it cannot capture
# the '_FATAL='/'_AMBIGUOUS=' lines, but listing the specific keys first keeps the
# intent explicit (M11/#67 subset extraction for the DRY-base guard).
while IFS= read -r _line; do
    if [[ "${_line}" == 'declare -g CRASH_LOG_PATTERNS_FATAL='* ]]; then
        CRASH_LOG_PATTERNS_FATAL="${_line#*\"}"
        CRASH_LOG_PATTERNS_FATAL="${CRASH_LOG_PATTERNS_FATAL%\"}"
    elif [[ "${_line}" == 'declare -g CRASH_LOG_PATTERNS_AMBIGUOUS='* ]]; then
        CRASH_LOG_PATTERNS_AMBIGUOUS="${_line#*\"}"
        CRASH_LOG_PATTERNS_AMBIGUOUS="${CRASH_LOG_PATTERNS_AMBIGUOUS%\"}"
    elif [[ "${_line}" == 'declare -g CRASH_LOG_PATTERNS='* ]]; then
        CRASH_LOG_PATTERNS="${_line#*\"}"
        CRASH_LOG_PATTERNS="${CRASH_LOG_PATTERNS%\"}"
    elif [[ "${_line}" == 'declare -g CRASH_LOG_EXCLUDE_PATTERNS='* ]]; then
        CRASH_LOG_EXCLUDE_PATTERNS="${_line#*\"}"
        CRASH_LOG_EXCLUDE_PATTERNS="${CRASH_LOG_EXCLUDE_PATTERNS%\"}"
    fi
    if [[ -n "${CRASH_LOG_PATTERNS}" && -n "${CRASH_LOG_PATTERNS_FATAL}" \
          && -n "${CRASH_LOG_PATTERNS_AMBIGUOUS}" && -n "${CRASH_LOG_EXCLUDE_PATTERNS}" ]]; then
        break
    fi
done < "${RUNNER_SCRIPT}"
unset _line


declare -g MOCK_CON_BIN
declare -g TEST_TMPDIR
# Issue #98: assertion-count integrity. Every verify_* call appends one line
# to TEST_TRACE_FILE; file appends survive subshells while the counter
# variables do not, so executed-vs-counted divergence exposes an assertion
# whose counter update was lost.
declare -g TEST_TRACE_FILE=""
declare -g TEST_EXECUTED=0

# --- Interrupt & Exit Handling ---
function _handle_exit {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        SCRIPT_ERROR=1
        printf "\n${RED}%s${NC}\n" "[ABORT] Script terminated unexpectedly. (Exit code: ${exit_code})"
    fi
    # Snapshot the executed-assertion count before _cleanup removes the
    # trace file with the rest of TEST_TMPDIR (#98).
    if [[ -n "${TEST_TRACE_FILE}" && -f "${TEST_TRACE_FILE}" ]]; then
        TEST_EXECUTED=$(wc -l < "${TEST_TRACE_FILE}")
    fi
    _cleanup
    print_summary

    # System Requirement: Propagate aggregate failure state to CI/CD pipeline
    if [[ ${TEST_FAILED} -gt 0 || ${SCRIPT_ERROR} -gt 0 ]]; then
        exit 1
    fi
    exit 0
}
trap _handle_exit EXIT
trap 'exit 1' SIGINT

# ==============================================================================
# Utilities
# ==============================================================================

function _log {
    local level="$1"
    local message="$2"
    local color="$NC"

    case "$level" in
        "INFO")    color="$BLUE" ;;
        "SUCCESS") color="$GREEN" ;;
        "WARN")    color="$YELLOW" ;;
        "ERROR")   color="$RED" ;;
    esac

    printf "${color}[%-7s] %s${NC}\n" "$level" "$message"
}

function print_divider {
    printf "${BLUE}%s${NC}\n" "===================================================================================================="
}

function print_sub_divider {
    printf "${BLUE}%s${NC}\n" "----------------------------------------------------------------------------------------------------"
}

function print_summary {
    printf "\n"
    printf "${BLUE}%s${NC}\n" "===================================================================================================="
    printf "${BLUE}%s${NC}\n" "                                   ERROR HANDLING TEST SUMMARY                                      "
    printf "${BLUE}%s${NC}\n" "===================================================================================================="

    # Issue #98: executed-vs-counted integrity. A mismatch means an assertion
    # ran where its counter update was lost (e.g. inside a subshell); the
    # suite result can no longer be trusted, so the run fails.
    if [[ ${TEST_EXECUTED} -ne ${TEST_TOTAL} ]]; then
        TEST_FAILED=$((TEST_FAILED + 1))
        FAILED_DETAILS+=("Assertion-count integrity: ${TEST_EXECUTED} executed vs ${TEST_TOTAL} counted (#98)")
    fi
    printf "  %-20s : %d (executed: %d)\n" "Total Assertions" "${TEST_TOTAL}" "${TEST_EXECUTED}"
    printf "${GREEN}  %-20s : %d${NC}\n" "Passed" "${TEST_PASSED}"

    if [[ ${TEST_FAILED} -gt 0 ]]; then
        printf "${RED}  %-20s : %d${NC}\n" "Failed" "${TEST_FAILED}"
    else
        printf "  %-20s : %d\n" "Failed" "0"
    fi

    if [[ ${SCRIPT_ERROR} -gt 0 ]]; then
        printf "${MAGENTA}  %-20s : %d${NC}\n" "Script Errors" "${SCRIPT_ERROR}"
    else
        printf "  %-20s : %d\n" "Script Errors" "0"
    fi

    if [[ ${TEST_FAILED} -gt 0 ]]; then
        printf "\n${RED}%s${NC}\n" "--- [ FAILED ASSERTIONS ] ---"
        for detail in "${FAILED_DETAILS[@]}"; do
            printf "${RED}  * %s${NC}\n" "$detail"
        done
        printf "${RED}%s${NC}\n" "-----------------------------"
    elif [[ ${SCRIPT_ERROR} -eq 0 ]]; then
        printf "\n${GREEN}%s${NC}\n" "[SUCCESS] All error handling tests completed perfectly!"
    fi

    printf "${BLUE}%s${NC}\n\n" "===================================================================================================="
}

# Validates string equality between expected and actual states, tracking aggregate test metrics.
function verify_state {
    local expected="$1"
    local actual="$2"
    local step_name="$3"

    if [[ -n "${TEST_TRACE_FILE}" ]]; then
        printf "%s\n" "${step_name}" >> "${TEST_TRACE_FILE}"
    fi
    TEST_TOTAL=$((TEST_TOTAL + 1))

    if [[ "${expected}" == "${actual}" ]]; then
        printf "${GREEN}[ PASS ]${NC} %s\n" "${step_name}"
        TEST_PASSED=$((TEST_PASSED + 1))
    else
        printf "${RED}[ FAIL ]${NC} %s\n" "${step_name}" >&2
        printf "  ${YELLOW}Expected : %s${NC}\n" "${expected}" >&2
        printf "  ${YELLOW}Actual   : %s${NC}\n" "${actual}" >&2
        TEST_FAILED=$((TEST_FAILED + 1))
        FAILED_DETAILS+=("${step_name} (Expected: ${expected}, Actual: ${actual})")
    fi
}

function verify_exit_code {
    local expected_exit="$1"
    local actual_exit="$2"
    local step_name="$3"

    if [[ -n "${TEST_TRACE_FILE}" ]]; then
        printf "%s\n" "${step_name}" >> "${TEST_TRACE_FILE}"
    fi
    TEST_TOTAL=$((TEST_TOTAL + 1))

    if [[ "${expected_exit}" == "${actual_exit}" ]]; then
        printf "${GREEN}[ PASS ]${NC} %s\n" "${step_name}"
        TEST_PASSED=$((TEST_PASSED + 1))
    else
        printf "${RED}[ FAIL ]${NC} %s\n" "${step_name}" >&2
        printf "  ${YELLOW}Expected exit : %s${NC}\n" "${expected_exit}" >&2
        printf "  ${YELLOW}Actual exit   : %s${NC}\n" "${actual_exit}" >&2
        TEST_FAILED=$((TEST_FAILED + 1))
        FAILED_DETAILS+=("${step_name} (Expected exit: ${expected_exit}, Actual exit: ${actual_exit})")
    fi
}

function _run {
    local cmd=("$@")
    local exit_code
    "${cmd[@]}" >/dev/null 2>&1; exit_code=$?; true
    printf "%d" "${exit_code}"
}

# Extracts LOG_DIR-related declarations and the set_local_mode function
# from RUNNER_SCRIPT, sources them in a clean subshell, and prints the
# resolved LOG_DIR for the requested mode. Use to validate Phase A LOG_DIR
# routing without requiring Phase B file-system side effects.
#
# Usage: _probe_log_dir <system|local> [env_modifier...]
#   env_modifier is any argument accepted by env(1), e.g.,
#   "IOC_RUNNER_LOG_DIR=/tmp/x" or "-u XDG_STATE_HOME".
function _probe_log_dir {
    local mode="$1"
    shift
    local probe
    probe=$(mktemp)
    {
        sed -n '/^declare -g SYSTEM_CONF_DIR=/,/^declare -g LOCAL_LOG_DIR=/p' "${RUNNER_SCRIPT}"
        sed -n '/^declare -g EXEC_MODE=/,/^declare -g LOG_DIR=/p' "${RUNNER_SCRIPT}"
        sed -n '/^function set_local_mode {/,/^}/p' "${RUNNER_SCRIPT}"
    } > "${probe}"
    env "$@" bash -c "source '${probe}'; if [[ '${mode}' == 'local' ]]; then set_local_mode; fi; printf '%s' \"\${LOG_DIR}\""
    rm -f "${probe}"
}

# Asserts whether a fixture string matches CRASH_LOG_PATTERNS through the same
# pipeline the runner's startup-signal reader (read_startup_signals) uses: the
# case-sensitive benign-noise pre-filter (grep -vE), then the case-insensitive
# match (grep -qiE). Mirrors the runner's empty-value guard so the mirror never
# blanks its input.
function verify_match {
    local expected="$1"
    local fixture="$2"
    local step_name="$3"
    local actual="nomatch"

    if [[ -n "${CRASH_LOG_EXCLUDE_PATTERNS}" ]]; then
        if printf "%s\n" "${fixture}" | grep -vE "${CRASH_LOG_EXCLUDE_PATTERNS}" | grep -qiE "${CRASH_LOG_PATTERNS}"; then
            actual="match"
        fi
    elif printf "%s\n" "${fixture}" | grep -qiE "${CRASH_LOG_PATTERNS}"; then
        actual="match"
    fi
    verify_state "${expected}" "${actual}" "${step_name}"
}

# Asserts a fixture against CRASH_LOG_PATTERNS alone, bypassing the benign-noise
# pre-filter. Pins that an excluded fixture is cleared by the exclusion, not by a
# pattern-set change.
function verify_match_unfiltered {
    local expected="$1"
    local fixture="$2"
    local step_name="$3"
    local actual="nomatch"

    if printf "%s\n" "${fixture}" | grep -qiE "${CRASH_LOG_PATTERNS}"; then
        actual="match"
    fi
    verify_state "${expected}" "${actual}" "${step_name}"
}

# DRY-base guard (M11/#67): the spelled-out base CRASH_LOG_PATTERNS must be exactly
# the union of the fatal and ambiguous subsets, compared as SETS (split on '|',
# sorted) so token order and the outer parentheses do not matter. The base is a
# literal (the zero-fork scraper above cannot expand a derived form), so this guard
# is what enforces the subsets as the single source of truth.
function verify_base_subset_union {
    local step_name="$1"
    local base actual="unequal"
    base="${CRASH_LOG_PATTERNS#\(}"
    base="${base%\)}"
    if [[ "$(printf '%s' "${base}" | tr '|' '\n' | sort)" \
          == "$(printf '%s' "${CRASH_LOG_PATTERNS_FATAL}|${CRASH_LOG_PATTERNS_AMBIGUOUS}" | tr '|' '\n' | sort)" ]]; then
        actual="equal"
    fi
    verify_state "equal" "${actual}" "${step_name}"
}

# Asserts a fixture matches the named subset regex (fatal | ambiguous), pinning the
# fatal-vs-ambiguous split at the token level (M11/#67, D031).
function verify_match_subset {
    local subset="$1"
    local fixture="$2"
    local step_name="$3"
    local regex="" actual="nomatch"
    case "${subset}" in
        fatal)     regex="${CRASH_LOG_PATTERNS_FATAL}" ;;
        ambiguous) regex="${CRASH_LOG_PATTERNS_AMBIGUOUS}" ;;
    esac
    if [[ -n "${regex}" ]] && printf '%s\n' "${fixture}" | grep -qiE "${regex}"; then
        actual="match"
    fi
    verify_state "match" "${actual}" "${step_name}"
}

# ==============================================================================
# Setup & Teardown
# ==============================================================================

function _setup {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Setup Mock Environment"
    print_sub_divider

    TEST_TMPDIR=$(mktemp -d)

    # Issue #98: arm the assertion trace as early as possible so every
    # subsequent verify_* call is recorded.
    TEST_TRACE_FILE="${TEST_TMPDIR}/assertion_trace"
    : > "${TEST_TRACE_FILE}"

    # Isolate local-mode CONF / SYSTEMD / RUN / LOG directories under
    # TEST_TMPDIR so a direct or sudo-elevated run cannot corrupt the
    # user's ~/.config or ~/.local/state. Per-case unified env vars
    # (IOC_RUNNER_{CONF,SYSTEMD,RUN,LOG}_DIR) take precedence over these
    # namespaced defaults per ioc-runner's resolution order. (#70)
    export IOC_RUNNER_LOCAL_CONF_DIR="${TEST_TMPDIR}/local-config/procServ.d"
    export IOC_RUNNER_LOCAL_SYSTEMD_DIR="${TEST_TMPDIR}/local-config/systemd/user"
    export IOC_RUNNER_LOCAL_RUN_DIR="${TEST_TMPDIR}/local-run/procserv"
    export IOC_RUNNER_LOCAL_LOG_DIR="${TEST_TMPDIR}/local-state/procserv"

    # Create a mock con binary that exits successfully without doing anything.
    MOCK_CON_BIN="${TEST_TMPDIR}/con"
    printf "#!/usr/bin/env bash\nexit 0\n" > "${MOCK_CON_BIN}"
    chmod +x "${MOCK_CON_BIN}"

    export IOC_RUNNER_CON_TOOL="${MOCK_CON_BIN}"

    # Create a mock procServ binary so the install path (deploy_local_template ->
    # resolve_procserv_tool) resolves it instead of searching the host. The
    # install cases only bake this path into the unit template; they never exec
    # it, so a plain exit-0 stub is sufficient. This makes the suite truly
    # host-independent (#77). test_tool_resolution's home-bin search case unsets
    # this override (env -u) to exercise the real search path.
    MOCK_PROCSERV_BIN="${TEST_TMPDIR}/procServ"
    printf "#!/usr/bin/env bash\nexit 0\n" > "${MOCK_PROCSERV_BIN}"
    chmod +x "${MOCK_PROCSERV_BIN}"

    export IOC_RUNNER_PROCSERV_TOOL="${MOCK_PROCSERV_BIN}"

    _log "SUCCESS" "Mock environment ready at ${TEST_TMPDIR}"
}

function _cleanup {
    if [[ -d "${TEST_TMPDIR}" ]]; then
        rm -rf "${TEST_TMPDIR}"
    fi
}

# ==============================================================================
# Test Steps
# ==============================================================================
function test_usage {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Usage and Help"
    print_sub_divider

    local exit_code

    exit_code=$(_run bash "${RUNNER_SCRIPT}" --help)
    verify_exit_code "0" "${exit_code}" "--help exits 0"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" -h)
    verify_exit_code "0" "${exit_code}" "-h exits 0"

    exit_code=$(_run bash "${RUNNER_SCRIPT}")
    verify_exit_code "0" "${exit_code}" "no arguments exits 0"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" unknown_command)
    verify_exit_code "1" "${exit_code}" "unknown command exits 1"

    # Validates that -V reports the script's own repo identity regardless of CWD.
    local version_out
    local cwd_unrelated="${TEST_TMPDIR}/unrelated_dir"
    mkdir -p "${cwd_unrelated}"
    version_out=$(cd "${cwd_unrelated}" && bash "${RUNNER_SCRIPT}" -V 2>/dev/null)
    exit_code=$?
    verify_exit_code "0" "${exit_code}" "'-V' exits 0 from unrelated CWD"

    local has_version="false"
    if [[ "${version_out}" == *"epics-ioc-runner version"* ]]; then has_version="true"; fi
    verify_state "true" "${has_version}" "'-V' produces valid version output from unrelated CWD"

    # Validates that -v/-vv are rejected when paired with any command other than list.
    exit_code=$(_run bash "${RUNNER_SCRIPT}" -v start dummy_ioc)
    verify_exit_code "1" "${exit_code}" "'-v start' exits 1 (verbose restricted to list)"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" -vv status dummy_ioc)
    verify_exit_code "1" "${exit_code}" "'-vv status' exits 1 (verbose restricted to list)"

    exit_code=$(IOC_RUNNER_LOCAL_RUN_DIR="${TEST_TMPDIR}/empty_run" _run bash "${RUNNER_SCRIPT}" --local -v list)
    verify_exit_code "0" "${exit_code}" "'--local -v list' exits 0 (verbose valid for list)"
}

function test_missing_target {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Missing Target Name Errors"
    print_sub_divider

    local exit_code
    local cmd

    for cmd in start stop restart status enable disable; do
        exit_code=$(_run bash "${RUNNER_SCRIPT}" "${cmd}")
        verify_exit_code "1" "${exit_code}" "'${cmd}' without target exits 1"
    done

    exit_code=$(_run bash "${RUNNER_SCRIPT}" remove)
    verify_exit_code "1" "${exit_code}" "'remove' without target exits 1"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" attach)
    verify_exit_code "1" "${exit_code}" "'attach' without target exits 1"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" view)
    verify_exit_code "1" "${exit_code}" "'view' without target exits 1"
}

# Validates the zero-fork path expansion, interactive overwrite protections, and CI/CD bypass mechanisms.
function test_generate_logic {
    local step="$1"
    local exit_code
    local test_dir="${TEST_TMPDIR}/valid_ioc"

    print_divider
    _log "INFO" "STEP ${step}: Generate Logic and Diff Engine"
    print_sub_divider

    mkdir -p "${test_dir}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    local conf_file="${test_dir}/valid_ioc.conf"

    # Evaluates relative path expansion and automatic startup script resolution.
    # Issue #98: the cd stays scoped inside the command substitution (its own
    # subshell); the assertion runs in the parent shell so the counters hold.
    exit_code=$(cd "${test_dir}" && _run bash "${RUNNER_SCRIPT}" --local generate .)
    verify_exit_code "0" "${exit_code}" "Generate native dot path resolves successfully"

    local conf_exists="false"
    if [[ -f "${conf_file}" ]]; then conf_exists="true"; fi
    verify_state "true" "${conf_exists}" "Configuration artifact created dynamically"

    # Evaluates the internal cmp -s integration bypassing identical configuration files.
    exit_code=$(cd "${test_dir}" && _run bash "${RUNNER_SCRIPT}" --local generate .)
    verify_exit_code "0" "${exit_code}" "Identical artifact natively bypasses overwrite and exits 0"

    # Evaluates the ANSI diff engine and interactive prompt behavior using a mocked non-interactive shell.
    printf "\n# Modified\n" >> "${conf_file}"
    exit_code=$(cd "${test_dir}" && _run bash -c "bash \"${RUNNER_SCRIPT}\" --local generate . < /dev/null")
    verify_exit_code "1" "${exit_code}" "Differential artifact prompt exits 1 on EOF"

    # Issue #93: a user decline (n) is an abort like EOF; both exit nonzero
    # so a scripted caller cannot mistake a declined overwrite for success.
    exit_code=$(cd "${test_dir}" && _run bash -c "printf 'n\n' | bash \"${RUNNER_SCRIPT}\" --local generate .")
    verify_exit_code "1" "${exit_code}" "Differential artifact prompt exits 1 on user decline"

    # Evaluates the forced overwrite bypass mechanism for automation pipelines.
    exit_code=$(cd "${test_dir}" && _run bash "${RUNNER_SCRIPT}" --local -f generate .)
    verify_exit_code "0" "${exit_code}" "Forced overwrite ignores diff constraint and exits 0"
}

function test_generate_errors {
    local step="$1"
    local exit_code
    local dummy_dir="${TEST_TMPDIR}/dummy_gen"
    local bad_name_dir="${TEST_TMPDIR}/bad name ioc"

    print_divider
    _log "INFO" "STEP ${step}: Generate Error Paths"
    print_sub_divider

    mkdir -p "${dummy_dir}"
    mkdir -p "${bad_name_dir}"

    # Validates path resolution rejecting illegal characters before native evaluation
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local generate "${bad_name_dir}")
    verify_exit_code "1" "${exit_code}" "Generate with invalid directory name exits 1"

    # Validates script discovery aborting when zero executables exist
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local generate "${dummy_dir}")
    verify_exit_code "1" "${exit_code}" "Generate with no executable scripts exits 1"

    # Validates interactive prompt aborting safely under non-interactive stdin
    touch "${dummy_dir}/st1.cmd" "${dummy_dir}/st2.cmd"
    chmod +x "${dummy_dir}/st1.cmd" "${dummy_dir}/st2.cmd"
    exit_code=$(_run bash -c "bash \"${RUNNER_SCRIPT}\" --local generate \"${dummy_dir}\" < /dev/null")
    verify_exit_code "1" "${exit_code}" "Generate with multiple candidates aborts interactively"

    # Validates CI/CD bypass flag safely handling multiple candidates
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local -f generate "${dummy_dir}")
    verify_exit_code "0" "${exit_code}" "Generate with force flag resolves multiple candidates and exits 0"

    # Validates that multi-candidate cmd selection refuses to proceed on EOF.
    local multi_cmd_dir="${TEST_TMPDIR}/multi_cmd_ioc"
    mkdir -p "${multi_cmd_dir}"
    touch "${multi_cmd_dir}/st.cmd" "${multi_cmd_dir}/alt.cmd"
    chmod +x "${multi_cmd_dir}/st.cmd" "${multi_cmd_dir}/alt.cmd"

    exit_code=$(_run bash -c "bash \"${RUNNER_SCRIPT}\" --local generate \"${multi_cmd_dir}\" < /dev/null")
    verify_exit_code "1" "${exit_code}" "Multiple cmd candidates without input exits 1 (no default)"
    # Validates EOF path on the overwrite prompt when an existing, differing
    # .conf forces the interactive diff-preview branch (not the identical-bypass).
    local overwrite_dir="${TEST_TMPDIR}/overwrite_eof_ioc"
    mkdir -p "${overwrite_dir}"
    touch "${overwrite_dir}/st.cmd"
    chmod +x "${overwrite_dir}/st.cmd"

    # Seed an initial conf, then tamper with it so regeneration hits the diff path.
    ( cd "${overwrite_dir}" && bash "${RUNNER_SCRIPT}" --local -f generate . >/dev/null 2>&1 )
    local existing_conf="${overwrite_dir}/overwrite_eof_ioc.conf"
    printf "# tampered marker\n" >> "${existing_conf}"

    local pre_sum post_sum preserved="false"
    pre_sum=$(md5sum "${existing_conf}" | awk '{print $1}')

    exit_code=$(_run bash -c "bash \"${RUNNER_SCRIPT}\" --local generate \"${overwrite_dir}\" < /dev/null")
    verify_exit_code "1" "${exit_code}" "Generate overwrite prompt exits 1 on EOF"

    post_sum=$(md5sum "${existing_conf}" | awk '{print $1}')
    [[ "${pre_sum}" == "${post_sum}" ]] && preserved="true"
    verify_state "true" "${preserved}" "Generate EOF abort preserves existing conf unchanged"

}

# Validates directory-based artifact resolution and target routing functionality.
function test_install_logic {
    local step="$1"
    local exit_code
    local test_dir="${TEST_TMPDIR}/install_ioc"
    local mock_conf_dir="${TEST_TMPDIR}/mock_etc"
    local mock_sysd_dir="${TEST_TMPDIR}/mock_sysd"

    print_divider
    _log "INFO" "STEP ${step}: Install Routing and Resolution"
    print_sub_divider

    mkdir -p "${test_dir}" "${mock_conf_dir}" "${mock_sysd_dir}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    # Pre-generates the artifact for the installation pipeline evaluation.
    ( cd "${test_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1 )

    # Evaluates implicit artifact location and syntax validation prior to routing.
    exit_code=$(cd "${test_dir}" && IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" _run bash "${RUNNER_SCRIPT}" --local -f install .)
    verify_exit_code "0" "${exit_code}" "Directory-based installation resolves artifact correctly"

    local installed_conf="${mock_conf_dir}/install_ioc.conf"
    local install_exists="false"
    if [[ -f "${installed_conf}" ]]; then install_exists="true"; fi
    verify_state "true" "${install_exists}" "Artifact successfully routed to configuration directory"

    # Validates EOF path on install overwrite prompt: exits 0 AND preserves
    # the existing conf. A tamper marker is injected BEFORE the EOF attempt so
    # that even a byte-identical reinstall would be detectable (cp+sed-strip+
    # append would drop the marker).
    local eof_marker="# T5_EOF_PRESERVE_MARKER"
    printf "%s\n" "${eof_marker}" >> "${installed_conf}"

    exit_code=$(cd "${test_dir}" && IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
        _run bash -c "bash \"${RUNNER_SCRIPT}\" --local install . < /dev/null")
    verify_exit_code "1" "${exit_code}" "Install overwrite prompt exits 1 on EOF"

    local preserved="false"
    if [[ -f "${installed_conf}" ]] && grep -qF "${eof_marker}" "${installed_conf}" 2>/dev/null; then
        preserved="true"
    fi
    verify_state "true" "${preserved}" "Install EOF abort preserves existing conf (marker retained)"

    # Issue #93: user decline (n) on the install overwrite prompt exits 1
    # and preserves the existing conf, matching the EOF abort convention.
    exit_code=$(cd "${test_dir}" && IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
        _run bash -c "printf 'n\n' | bash \"${RUNNER_SCRIPT}\" --local install .")
    verify_exit_code "1" "${exit_code}" "Install overwrite prompt exits 1 on user decline"

    local declined_preserved="false"
    if [[ -f "${installed_conf}" ]] && grep -qF "${eof_marker}" "${installed_conf}" 2>/dev/null; then
        declined_preserved="true"
    fi
    verify_state "true" "${declined_preserved}" "Install decline abort preserves existing conf (marker retained)"
}

# T3 (Phase E): IOC_PORT atomic install. The write path in do_install
# (mktemp + mv -f) must leave the target conf valid-or-untouched under any
# interruption -- a partially written conf must never be observable.
function test_ioc_port_atomic_install {
    local step="$1"
    local test_dir="${TEST_TMPDIR}/atomic_ioc"
    local mock_conf_dir="${TEST_TMPDIR}/atomic_etc"
    local mock_sysd_dir="${TEST_TMPDIR}/atomic_sysd"
    local target_conf="${mock_conf_dir}/atomic_ioc.conf"

    print_divider
    _log "INFO" "STEP ${step}: IOC_PORT Atomic Install (T3)"
    print_sub_divider

    mkdir -p "${test_dir}" "${mock_conf_dir}" "${mock_sysd_dir}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    # Pre-generate the source conf the install loop consumes.
    ( cd "${test_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1 )

    # Hammer install under a tight timeout that interrupts at varied points.
    local iterations=120
    local i rc port_count partial_writes=0 unexpected_exit=0
    for ((i = 1; i <= iterations; i = i + 1)); do
        if (
            cd "${test_dir}" || exit 1
            IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
            timeout 0.01 bash "${RUNNER_SCRIPT}" --local -f install . >/dev/null 2>&1
        ); then
            rc=0
        else
            rc=$?
        fi
        # timeout completion (0) and timeout kill (124) are both expected.
        if [[ "${rc}" -ne 0 && "${rc}" -ne 124 ]]; then
            unexpected_exit=$((unexpected_exit + 1))
        fi
        # When present, the target must hold exactly one valid IOC_PORT= line.
        if [[ -f "${target_conf}" ]]; then
            port_count=$(grep -c '^IOC_PORT=' "${target_conf}" 2>/dev/null) || true
            if [[ "${port_count:-0}" -ne 1 ]] \
               || ! grep -qE '^IOC_PORT="unix:[^:]+:[^:]+:0660:.*/atomic_ioc/control"$' "${target_conf}" 2>/dev/null; then
                partial_writes=$((partial_writes + 1))
            fi
        fi
    done

    verify_state "0" "${partial_writes}" "Atomic install: no partial conf across ${iterations} interrupted installs"
    verify_state "0" "${unexpected_exit}" "Atomic install: install exits only 0 or 124 under interruption"
}

function test_install_errors {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Install Error Paths"
    print_sub_divider

    local exit_code
    local fake_conf="${TEST_TMPDIR}/test.conf"
    printf "IOC_NAME=test\n" > "${fake_conf}"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local -f install "${TEST_TMPDIR}/nonexistent.conf")
    verify_exit_code "1" "${exit_code}" "'install' with missing conf file exits 1"

    exit_code=$(IOC_RUNNER_SYSTEMD_DIR="${TEST_TMPDIR}" _run bash "${RUNNER_SCRIPT}" -f install "${fake_conf}")
    verify_exit_code "1" "${exit_code}" "'install' with missing system template exits 1"

    local dummy_dir="${TEST_TMPDIR}/dummy_install"
    mkdir -p "${dummy_dir}"
    touch "${dummy_dir}/wrong_name.conf"

    # Validates strict naming constraint mapping during directory-based installation
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local install "${dummy_dir}")
    verify_exit_code "1" "${exit_code}" "Install directory with mismatched conf name exits 1"

    # Regression guard: IOC name validation must also apply when a .conf
    # file is supplied directly (not via its parent directory). Without
    # the convergence-point check, names like 'myioc@' would propagate
    # into systemd unit names where '@' is reserved.
    local invalid_named_conf="${TEST_TMPDIR}/myioc@.conf"
    touch "${invalid_named_conf}"
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local install "${invalid_named_conf}")
    verify_exit_code "1" "${exit_code}" "Install file-direct with invalid IOC name exits 1"
}


# #105 U-5: ss feeds only the -vv columns. Plain list must succeed
# without a working ss; list -vv must fail loudly with a named error.
# find is replaced by a PATH stub that emits one fake socket entry so
# the collection path is actually reached; ss is stubbed to exit 1.
function test_list_ss_vv_contract {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: list ss Contract (-vv only, #105)"
    print_sub_divider

    local mock_bin="${TEST_TMPDIR}/ss_fail_bin"
    local mock_run="${TEST_TMPDIR}/ss_fail_run"
    local fake_sock="${mock_run}/test_ioc/control"

    mkdir -p "${mock_bin}" "${mock_run}/test_ioc"

    cat > "${mock_bin}/find" <<STUB
#!/usr/bin/env bash
printf '%s\0%s\0%s\0' "${fake_sock}" "2024-01-01 12:00" "srwxrwxr-x"
STUB
    chmod +x "${mock_bin}/find"

    printf '#!/usr/bin/env bash\nexit 1\n' > "${mock_bin}/ss"
    chmod +x "${mock_bin}/ss"

    local exit_code
    exit_code=$(PATH="${mock_bin}:${PATH}" \
        IOC_RUNNER_LOCAL_RUN_DIR="${mock_run}" \
        _run bash "${RUNNER_SCRIPT}" --local list)
    verify_exit_code "0" "${exit_code}" "plain list succeeds with broken ss (no -vv dependency)"

    exit_code=$(PATH="${mock_bin}:${PATH}" \
        IOC_RUNNER_LOCAL_RUN_DIR="${mock_run}" \
        _run bash "${RUNNER_SCRIPT}" --local -vv list)
    verify_exit_code "1" "${exit_code}" "list -vv with broken ss exits 1"

    local out match_rc=1
    out=$(PATH="${mock_bin}:${PATH}" IOC_RUNNER_LOCAL_RUN_DIR="${mock_run}" \
        bash "${RUNNER_SCRIPT}" --local -vv list 2>&1 || true)
    if [[ "${out}" == *"ss -lx"* ]]; then match_rc=0; fi
    verify_exit_code "0" "${match_rc}" "list -vv failure names ss in the error"
}

# #105 U-4: mutation verbs on a never-installed name are a hard error
# with the gate message, not systemd template-instantiation exit 0;
# view exits nonzero on a missing conf (U-5).
function test_unknown_name_verb_gate {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Unknown-Name Verb Gate (#105)"
    print_sub_divider

    local verb exit_code
    for verb in stop enable disable remove view; do
        exit_code=$(_run bash "${RUNNER_SCRIPT}" --local "${verb}" no_such_ioc_105)
        verify_exit_code "1" "${exit_code}" "${verb} on a never-installed name exits 1"
    done

    local out match_rc=1
    out=$(bash "${RUNNER_SCRIPT}" --local stop no_such_ioc_105 2>&1 || true)
    if [[ "${out}" == *"No configuration found"* ]]; then match_rc=0; fi
    verify_exit_code "0" "${match_rc}" "gate message names the missing configuration"
}

# #105: local mode replaces a mismatching conf IOC_PORT with the
# standard socket path — now with exactly one Warning.
function test_local_ioc_port_replacement_warns {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Local IOC_PORT Replacement Warning (#105)"
    print_sub_divider

    local wdir="${TEST_TMPDIR}/warn105"
    mkdir -p "${wdir}"
    cat > "${wdir}/warnioc.conf" <<CONF
IOC_NAME="warnioc"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CMD="/bin/echo"
IOC_CHDIR="${wdir}"
IOC_PORT="unix:someone:somegroup:0660:/definitely/not/standard"
CONF

    local out count
    out=$(IOC_RUNNER_PROCSERV_TOOL=/bin/true \
        bash "${RUNNER_SCRIPT}" --local install "${wdir}/warnioc.conf" -f 2>&1 >/dev/null || true)
    count=$(grep -c "Warning: IOC_PORT" <<< "${out}" || true)
    verify_exit_code "1" "${count}" "exactly one IOC_PORT replacement warning"
}

# Validates that the new namespaced env vars (IOC_RUNNER_LOCAL_*) route install
# targets independently of the legacy unified IOC_RUNNER_*_DIR overrides.
function test_env_var_namespacing {
    local step="$1"
    local exit_code
    local test_dir="${TEST_TMPDIR}/ns_ioc"
    local ns_conf_dir="${TEST_TMPDIR}/ns_conf"
    local ns_sysd_dir="${TEST_TMPDIR}/ns_sysd"
    local ns_log_dir="${TEST_TMPDIR}/ns_log"
    local legacy_conf_dir="${TEST_TMPDIR}/legacy_conf"
    local legacy_sysd_dir="${TEST_TMPDIR}/legacy_sysd"

    print_divider
    _log "INFO" "STEP ${step}: Env Var Namespacing and Precedence"
    print_sub_divider

    mkdir -p "${test_dir}" "${ns_conf_dir}" "${ns_sysd_dir}" "${ns_log_dir}" \
             "${legacy_conf_dir}" "${legacy_sysd_dir}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    ( cd "${test_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1 )

    # Case 1: Namespaced IOC_RUNNER_LOCAL_* variables route install to ns dirs.
    exit_code=$(cd "${test_dir}" && \
                IOC_RUNNER_LOCAL_CONF_DIR="${ns_conf_dir}" \
                IOC_RUNNER_LOCAL_SYSTEMD_DIR="${ns_sysd_dir}" \
                _run bash "${RUNNER_SCRIPT}" --local -f install .)
    verify_exit_code "0" "${exit_code}" "IOC_RUNNER_LOCAL_* routes --local install"

    local ns_installed="${ns_conf_dir}/ns_ioc.conf"
    local ns_exists="false"
    [[ -f "${ns_installed}" ]] && ns_exists="true"
    verify_state "true" "${ns_exists}" "IOC_RUNNER_LOCAL_CONF_DIR resolves to namespaced path"

    # Case 2: Namespaced IOC_RUNNER_LOCAL_LOG_DIR resolves LOG_DIR in --local mode.
    local actual_log_dir
    actual_log_dir=$(_probe_log_dir "local" "IOC_RUNNER_LOCAL_LOG_DIR=${ns_log_dir}")
    verify_state "${ns_log_dir}" "${actual_log_dir}" "IOC_RUNNER_LOCAL_LOG_DIR resolves LOG_DIR in --local"

}

# Validates that unified legacy IOC_RUNNER_*_DIR vars consistently
# override their namespaced IOC_RUNNER_{LOCAL,SYSTEM}_*_DIR counterparts
# for CONF_DIR, SYSTEMD_DIR, and RUN_DIR (via IOC_PORT path resolution).
function test_env_var_precedence {
    local step="$1"
    local exit_code
    local test_dir="${TEST_TMPDIR}/prec_ioc"
    local unified_conf="${TEST_TMPDIR}/prec_unified_conf"
    local unified_sysd="${TEST_TMPDIR}/prec_unified_sysd"
    local unified_run="${TEST_TMPDIR}/prec_unified_run"
    local ns_conf="${TEST_TMPDIR}/prec_ns_conf"
    local ns_sysd="${TEST_TMPDIR}/prec_ns_sysd"
    local ns_run="${TEST_TMPDIR}/prec_ns_run"

    print_divider
    _log "INFO" "STEP ${step}: Env Var Precedence (unified > namespaced)"
    print_sub_divider

    mkdir -p "${test_dir}" "${unified_conf}" "${unified_sysd}" "${unified_run}" \
             "${ns_conf}" "${ns_sysd}" "${ns_run}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    ( cd "${test_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1 )

    # Install with contradicting unified + namespaced vars across all three pairs.
    exit_code=$(cd "${test_dir}" && \
                IOC_RUNNER_CONF_DIR="${unified_conf}" \
                IOC_RUNNER_SYSTEMD_DIR="${unified_sysd}" \
                IOC_RUNNER_RUN_DIR="${unified_run}" \
                IOC_RUNNER_LOCAL_CONF_DIR="${ns_conf}" \
                IOC_RUNNER_LOCAL_SYSTEMD_DIR="${ns_sysd}" \
                IOC_RUNNER_LOCAL_RUN_DIR="${ns_run}" \
                _run bash "${RUNNER_SCRIPT}" --local -f install .)
    verify_exit_code "0" "${exit_code}" "Install succeeds with full precedence matrix"

    # CONF_DIR precedence: conf file lands in unified, not namespaced.
    local conf_in_unified="false" conf_in_ns="false"
    [[ -f "${unified_conf}/prec_ioc.conf" ]] && conf_in_unified="true"
    [[ -f "${ns_conf}/prec_ioc.conf" ]] && conf_in_ns="true"
    verify_state "true"  "${conf_in_unified}" "CONF_DIR: unified var wins"
    verify_state "false" "${conf_in_ns}"      "CONF_DIR: namespaced var ignored"

    # RUN_DIR precedence: installed conf's IOC_PORT path points into unified_run,
    # not ns_run (process_ioc_port composes the path from RUN_DIR).
    local port_line="" port_in_unified="false" port_in_ns="false"
    port_line=$(grep '^IOC_PORT=' "${unified_conf}/prec_ioc.conf" 2>/dev/null || true)
    [[ "${port_line}" == *"${unified_run}/prec_ioc/control"* ]] && port_in_unified="true"
    [[ "${port_line}" == *"${ns_run}/prec_ioc/control"* ]] && port_in_ns="true"
    verify_state "true"  "${port_in_unified}" "RUN_DIR: unified var wins in IOC_PORT"
    verify_state "false" "${port_in_ns}"      "RUN_DIR: namespaced var ignored in IOC_PORT"

    # SYSTEMD_DIR precedence: local template landed in unified, not namespaced.
    local tpl_in_unified="false" tpl_in_ns="false"
    [[ -f "${unified_sysd}/epics-@.service" ]] && tpl_in_unified="true"
    [[ -f "${ns_sysd}/epics-@.service" ]] && tpl_in_ns="true"
    verify_state "true"  "${tpl_in_unified}" "SYSTEMD_DIR: unified var wins"
    verify_state "false" "${tpl_in_ns}"      "SYSTEMD_DIR: namespaced var ignored"

    # LOG_DIR precedence: unified IOC_RUNNER_LOG_DIR wins over namespaced
    # IOC_RUNNER_LOCAL_LOG_DIR in --local mode; namespaced honored when no unified.
    local unified_log="${TEST_TMPDIR}/prec_unified_log"
    local ns_log="${TEST_TMPDIR}/prec_ns_log"
    local actual_log_dir
    actual_log_dir=$(_probe_log_dir "local" \
                       "IOC_RUNNER_LOG_DIR=${unified_log}" \
                       "IOC_RUNNER_LOCAL_LOG_DIR=${ns_log}")
    verify_state "${unified_log}" "${actual_log_dir}" "LOG_DIR: unified var wins"
    actual_log_dir=$(_probe_log_dir "local" "IOC_RUNNER_LOCAL_LOG_DIR=${ns_log}")
    verify_state "${ns_log}" "${actual_log_dir}" "LOG_DIR: namespaced var honored when no unified"
}

# Validates the system-mode foot-gun warning for IOC_RUNNER_LOG_DIR:
# warning fires when IOC_RUNNER_LOG_DIR diverges from SYSTEM_LOG_DIR in
# system mode; suppressed when they match; suppressed in --local mode.
function test_log_dir_guard {
    local step="$1"
    local stderr_cap
    stderr_cap=$(mktemp)
    local has_warn

    print_divider
    _log "INFO" "STEP ${step}: LOG_DIR Foot-Gun Guard"
    print_sub_divider

    # Case 1: system mode + IOC_RUNNER_LOG_DIR differs from default SYSTEM_LOG_DIR.
    IOC_RUNNER_LOG_DIR=/tmp/log_dir_guard_test_diff \
        bash "${RUNNER_SCRIPT}" status fake-ioc >/dev/null 2>"${stderr_cap}" || true
    has_warn="false"
    grep -q 'IOC_RUNNER_LOG_DIR.*differs from SYSTEM_LOG_DIR' "${stderr_cap}" && has_warn="true"
    verify_state "true" "${has_warn}" "system + differing IOC_RUNNER_LOG_DIR triggers warning"

    # Case 2: system mode + IOC_RUNNER_LOG_DIR matches overridden SYSTEM_LOG_DIR.
    IOC_RUNNER_SYSTEM_LOG_DIR=/tmp/log_dir_guard_test_match \
    IOC_RUNNER_LOG_DIR=/tmp/log_dir_guard_test_match \
        bash "${RUNNER_SCRIPT}" status fake-ioc >/dev/null 2>"${stderr_cap}" || true
    has_warn="false"
    grep -q 'IOC_RUNNER_LOG_DIR.*differs from SYSTEM_LOG_DIR' "${stderr_cap}" && has_warn="true"
    verify_state "false" "${has_warn}" "system + matching IOC_RUNNER_LOG_DIR suppresses warning"

    # Case 3: --local mode + IOC_RUNNER_LOG_DIR set to non-default.
    IOC_RUNNER_LOG_DIR=/tmp/log_dir_guard_test_local \
        bash "${RUNNER_SCRIPT}" --local status fake-ioc >/dev/null 2>"${stderr_cap}" || true
    has_warn="false"
    grep -q 'IOC_RUNNER_LOG_DIR.*differs from SYSTEM_LOG_DIR' "${stderr_cap}" && has_warn="true"
    verify_state "false" "${has_warn}" "--local mode suppresses LOG_DIR guard"

    rm -f "${stderr_cap}"
}

# Validates XDG_STATE_HOME fallback semantics for LOCAL_LOG_DIR:
# when XDG_STATE_HOME is unset, LOCAL_LOG_DIR falls back to
# $HOME/.local/state/procserv; when set, LOCAL_LOG_DIR uses
# $XDG_STATE_HOME/procserv.
function test_log_dir_xdg_fallback {
    local step="$1"
    local actual

    print_divider
    _log "INFO" "STEP ${step}: LOG_DIR XDG_STATE_HOME Fallback"
    print_sub_divider

    # Case 1: XDG_STATE_HOME unset -> $HOME/.local/state/procserv.
    actual=$(_probe_log_dir "local" "-u" "XDG_STATE_HOME" "-u" "IOC_RUNNER_LOG_DIR" "-u" "IOC_RUNNER_LOCAL_LOG_DIR")
    verify_state "${HOME}/.local/state/procserv" "${actual}" \
        "XDG_STATE_HOME unset: LOCAL_LOG_DIR falls back to \$HOME/.local/state/procserv"

    # Case 2: XDG_STATE_HOME set -> <XDG_STATE_HOME>/procserv.
    # env(1) requires options before VAR=value pairs.
    actual=$(_probe_log_dir "local" "-u" "IOC_RUNNER_LOG_DIR" "-u" "IOC_RUNNER_LOCAL_LOG_DIR" "XDG_STATE_HOME=/tmp/xdg_fallback_test")
    verify_state "/tmp/xdg_fallback_test/procserv" "${actual}" \
        "XDG_STATE_HOME set: LOCAL_LOG_DIR uses <XDG_STATE_HOME>/procserv"
}

# Validates the bash completion script by sourcing it in isolated subshells
# and invoking _ioc_runner_completions with synthesized COMP_WORDS/COMP_CWORD.
# Targets the env-var refactor to ensure completion picks up namespaced vars.
function test_completion {
    local step="$1"
    local comp_script="${SC_TOP}/../bin/ioc-runner-completion.bash"

    print_divider
    _log "INFO" "STEP ${step}: Bash Completion Smoke Tests"
    print_sub_divider

    if [[ ! -f "${comp_script}" ]]; then
        _log "ERROR" "Completion script not found at ${comp_script}"
        (( TEST_FAILED++ )) || true
        return
    fi

    local sys_conf="${TEST_TMPDIR}/comp_sys"
    local loc_conf="${TEST_TMPDIR}/comp_loc"
    local unified_conf="${TEST_TMPDIR}/comp_unified"
    mkdir -p "${sys_conf}" "${loc_conf}" "${unified_conf}"
    touch "${sys_conf}/sys_ioc.conf" \
          "${loc_conf}/loc_ioc.conf" \
          "${unified_conf}/unified_ioc.conf"

    local got

    # S1: bare "ioc-runner <TAB>" -> top-level commands are offered.
    got=$(
        # shellcheck source=/dev/null
        source "${comp_script}"
        COMP_WORDS=(ioc-runner "")
        COMP_CWORD=1
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}" | grep -cxE '(generate|install|list)' || true
    )
    verify_state "3" "${got}" "Bare invocation offers generate/install/list"

    # S2: "ioc-runner -<TAB>" -> global options are offered.
    got=$(
        source "${comp_script}"
        COMP_WORDS=(ioc-runner "-")
        COMP_CWORD=1
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}" | grep -cxE '(--local|-V|--version|-h)' || true
    )
    verify_state "4" "${got}" "Dash prefix offers global options"

    # S3: system mode reads IOC_RUNNER_SYSTEM_CONF_DIR.
    got=$(
        source "${comp_script}"
        unset IOC_RUNNER_CONF_DIR
        export IOC_RUNNER_SYSTEM_CONF_DIR="${sys_conf}"
        COMP_WORDS=(ioc-runner start "")
        COMP_CWORD=2
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}"
    )
    verify_state "sys_ioc" "${got}" "System mode reads IOC_RUNNER_SYSTEM_CONF_DIR"

    # S4: --local mode reads IOC_RUNNER_LOCAL_CONF_DIR.
    got=$(
        source "${comp_script}"
        unset IOC_RUNNER_CONF_DIR
        export IOC_RUNNER_LOCAL_CONF_DIR="${loc_conf}"
        COMP_WORDS=(ioc-runner --local start "")
        COMP_CWORD=3
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}"
    )
    verify_state "loc_ioc" "${got}" "--local mode reads IOC_RUNNER_LOCAL_CONF_DIR"

    # S5: unified IOC_RUNNER_CONF_DIR overrides LOCAL_CONF_DIR in completion.
    got=$(
        source "${comp_script}"
        export IOC_RUNNER_CONF_DIR="${unified_conf}"
        export IOC_RUNNER_LOCAL_CONF_DIR="${loc_conf}"
        COMP_WORDS=(ioc-runner --local start "")
        COMP_CWORD=3
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}"
    )
    verify_state "unified_ioc" "${got}" "IOC_RUNNER_CONF_DIR overrides LOCAL var in completion"

    # S6: "list <TAB>" -> verbosity flags.
    got=$(
        source "${comp_script}"
        COMP_WORDS=(ioc-runner list "")
        COMP_CWORD=2
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}" | grep -cxE '(-v|-vv)' || true
    )
    verify_state "2" "${got}" "'list' command suggests -v and -vv"

    # S7: prefix filter "st<TAB>" narrows to start/stop/status.
    got=$(
        source "${comp_script}"
        COMP_WORDS=(ioc-runner "st")
        COMP_CWORD=1
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s\n" "${COMPREPLY[@]}" | grep -cxE '(start|stop|status)' || true
    )
    verify_state "3" "${got}" "'st' prefix narrows to start/stop/status"

    # S8: nonexistent conf dir yields empty completion, not an error.
    got=$(
        source "${comp_script}"
        unset IOC_RUNNER_CONF_DIR
        export IOC_RUNNER_SYSTEM_CONF_DIR="${TEST_TMPDIR}/does_not_exist"
        COMP_WORDS=(ioc-runner start "")
        COMP_CWORD=2
        COMPREPLY=()
        _ioc_runner_completions
        printf "%s" "${#COMPREPLY[@]}"
    )
    verify_state "0" "${got}" "Missing conf_dir yields empty COMPREPLY"
}


function test_ioc_name_validation {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: IOC Name Validation Helper"
    print_sub_divider

    # Site 1 (early validation): non-generate/non-install commands route
    # the regex via 'view'. Names with characters outside [a-zA-Z0-9_-]
    # must be rejected before the dispatcher reaches do_view.
    local exit_code
    exit_code=$(_run bash "${RUNNER_SCRIPT}" view 'bad name')
    verify_exit_code "1" "${exit_code}" "view 'bad name' (whitespace) exits 1 via name validation"

    exit_code=$(_run bash "${RUNNER_SCRIPT}" view 'bad@name')
    verify_exit_code "1" "${exit_code}" "view 'bad@name' (special char) exits 1 via name validation"

    # Path-separator inputs cannot reach the regex: 'basename' strips the
    # path before the regex check. Use period instead, which survives
    # basename and is rejected by [a-zA-Z0-9_-].
    exit_code=$(_run bash "${RUNNER_SCRIPT}" view 'bad.name')
    verify_exit_code "1" "${exit_code}" "view 'bad.name' (period) exits 1 via name validation"

    # Verify the error message format remains 'Invalid IOC name ...' so
    # log scrapers and regression observers can rely on the contract.
    local err_out
    # Suffix '|| true' so that the validation rejection (exit 1) does not
    # propagate through command substitution and trip 'set -e' in this
    # test driver.
    err_out=$(bash "${RUNNER_SCRIPT}" view 'bad@name' 2>&1 >/dev/null || true)
    local has_phrase="false"
    if [[ "${err_out}" == *"Invalid IOC name"* ]]; then has_phrase="true"; fi
    verify_state "true" "${has_phrase}" "view 'bad@name' produces 'Invalid IOC name' error message"
}

function test_validation_errors {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Configuration Validation Errors"
    print_sub_divider

    local exit_code
    local bad_conf="${TEST_TMPDIR}/bad_validation.conf"
    local dummy_dir="${TEST_TMPDIR}/dummy_ioc"
    mkdir -p "${dummy_dir}"

    # 1. Illegal characters check
    cat <<EOF > "${bad_conf}"
IOC_NAME="test"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${dummy_dir}"
IOC_CMD="rm -rf /; echo hacked"
EOF
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local -f install "${bad_conf}")
    verify_exit_code "1" "${exit_code}" "Install with illegal characters in CMD exits 1"

    # 2. Identity mismatch check (Wrong user)
    cat <<EOF > "${bad_conf}"
IOC_NAME="test"
IOC_USER="fake_user_999"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${dummy_dir}"
IOC_CMD="./st.cmd"
EOF
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local -f install "${bad_conf}")
    verify_exit_code "1" "${exit_code}" "Install with wrong local user exits 1"

# 3. Missing execute permission check
    chmod -x "${dummy_dir}"
    cat <<EOF > "${bad_conf}"
IOC_NAME="test"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${dummy_dir}"
IOC_CMD="./st.cmd"
EOF
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local -f install "${bad_conf}")
    verify_exit_code "1" "${exit_code}" "Install without directory execute permission exits 1"
    chmod +x "${dummy_dir}"

    # 4. Missing required key check (IOC_CMD absent)
    cat <<EOF > "${bad_conf}"
IOC_USER="$(id -un)"
IOC_GROUP="$(id -gn)"
IOC_CHDIR="${dummy_dir}"
IOC_PORT=""
EOF
    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local -f install "${bad_conf}")
    verify_exit_code "1" "${exit_code}" "Install with missing required key (IOC_CMD) exits 1"

    # 5. Reject a '..' path component in IOC_CHDIR (system-mode precheck, #66).
    #    Driven in system mode (no --local) so the chdir precheck fires. The
    #    check is pure string work that exits before any privileged copy, so it
    #    needs neither the ioc-srv account nor sudo: validate_conf compares the
    #    IOC_USER/IOC_GROUP strings only, and the '..' path resolves to an
    #    existing directory so validate_conf's earlier -d test passes. The -f
    #    flag also confirms force does not bypass the rejection.
    cat <<EOF > "${bad_conf}"
IOC_NAME="test"
IOC_USER="ioc-srv"
IOC_GROUP="ioc"
IOC_CHDIR="${dummy_dir}/../dummy_ioc"
IOC_CMD="true"
EOF
    local dotdot_stderr="${TEST_TMPDIR}/dotdot_stderr"
    local dotdot_ec=0
    bash "${RUNNER_SCRIPT}" -f install "${bad_conf}" >/dev/null 2>"${dotdot_stderr}" || dotdot_ec=$?
    verify_exit_code "1" "${dotdot_ec}" "Install with '..' in system IOC_CHDIR exits 1"

    local has_dotdot_msg="false"
    grep -q "contains a '..' component" "${dotdot_stderr}" 2>/dev/null && has_dotdot_msg="true"
    verify_state "true" "${has_dotdot_msg}" "'..' rejection error references the '..' component"

    # 5b. Boundary form: IOC_CHDIR exactly '..'. The interior/trailing globs do
    #     not match a bare '..', so this closes the whole-string position. '..'
    #     always resolves to an existing directory (the CWD parent), so it
    #     reaches the precheck independent of the test's working directory.
    cat <<EOF > "${bad_conf}"
IOC_NAME="test"
IOC_USER="ioc-srv"
IOC_GROUP="ioc"
IOC_CHDIR=".."
IOC_CMD="true"
EOF
    local bare_stderr="${TEST_TMPDIR}/bare_dotdot_stderr"
    local bare_ec=0
    bash "${RUNNER_SCRIPT}" -f install "${bad_conf}" >/dev/null 2>"${bare_stderr}" || bare_ec=$?
    verify_exit_code "1" "${bare_ec}" "Install with bare '..' IOC_CHDIR exits 1"

    local has_bare_msg="false"
    grep -q "contains a '..' component" "${bare_stderr}" 2>/dev/null && has_bare_msg="true"
    verify_state "true" "${has_bare_msg}" "bare '..' rejection error references the '..' component"
}

function test_attach_errors {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Attach Error Paths"
    print_sub_divider

    local exit_code

    exit_code=$(_run bash "${RUNNER_SCRIPT}" --local attach "nonexistent_ioc")
    verify_exit_code "1" "${exit_code}" "'attach' with missing conf exits 1"

    # Regression guard: a conf file with no IOC_PORT key should yield a
    # distinct 'not configured' error rather than the generic socket-file
    # error, exercising read_conf_var's missing-vs-empty signal.
    local missing_port_dir="${TEST_TMPDIR}/missing_port_conf"
    mkdir -p "${missing_port_dir}"
    printf "IOC_NAME=missing_port\nIOC_USER=%s\n" "$(id -un)" > "${missing_port_dir}/missing_port.conf"

    local stderr_cap="${TEST_TMPDIR}/missing_port_stderr"
    local ec=0
    IOC_RUNNER_LOCAL_CONF_DIR="${missing_port_dir}" \
        bash "${RUNNER_SCRIPT}" --local attach "missing_port" >/dev/null 2>"${stderr_cap}" \
        || ec=$?
    verify_exit_code "1" "${ec}" "'attach' with missing IOC_PORT key exits 1"

    local has_port_msg="false"
    grep -q "IOC_PORT not configured" "${stderr_cap}" 2>/dev/null && has_port_msg="true"
    verify_state "true" "${has_port_msg}" "'attach' error references missing IOC_PORT key"
}

function test_list_empty {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: List with No Active Sockets"
    print_sub_divider

    local exit_code

    exit_code=$(IOC_RUNNER_RUN_DIR="${TEST_TMPDIR}/empty_run" _run bash "${RUNNER_SCRIPT}" --local list)
    verify_exit_code "0" "${exit_code}" "'list' with no active sockets exits 0"

    # Issue #94: an empty result caused by non-traversable (0770-style)
    # socket directories carries a permission hint; a genuinely empty run
    # dir does not. chmod 0 cannot deny root, so the hint case is skipped
    # under EUID 0.
    local output
    local genuine_run="${TEST_TMPDIR}/genuine_empty_run"
    mkdir -p "${genuine_run}"
    output=$(IOC_RUNNER_RUN_DIR="${genuine_run}" bash "${RUNNER_SCRIPT}" --local list 2>&1)
    local hint_absent="true"
    if printf "%s" "${output}" | grep -q "not readable by this user"; then
        hint_absent="false"
    fi
    verify_state "true" "${hint_absent}" "Genuinely empty list carries no permission hint"

    if [[ ${EUID} -eq 0 ]]; then
        _log "WARN" "Running as root: skipping the non-traversable hint case (chmod 0 cannot deny root)."
    else
        local denied_run="${TEST_TMPDIR}/denied_run"
        local denied_exit=0
        local hint_present="false"
        mkdir -p "${denied_run}/secret_ioc"
        chmod 0 "${denied_run}/secret_ioc"
        output=$(IOC_RUNNER_RUN_DIR="${denied_run}" bash "${RUNNER_SCRIPT}" --local list 2>&1) || denied_exit=$?
        if printf "%s" "${output}" | grep -q "not readable by this user"; then
            hint_present="true"
        fi
        verify_exit_code "0" "${denied_exit}" "'list' with a non-traversable socket dir exits 0"
        verify_state "true" "${hint_present}" "Non-traversable socket dir appends the permission hint"
        chmod 700 "${denied_run}/secret_ioc"
    fi
}


# Validates the #87 single-source identity contract: bin/ioc-runner and
# bin/setup-system-infra.bash resolve the same IOC_RUNNER_SYSTEM_USER /
# IOC_RUNNER_SYSTEM_GROUP / IOC_RUNNER_SYSTEM_LOG_DIR overrides with the same
# shipped defaults. A one-sided edit of either declaration fails here before it
# can ship. LOG_DIR joins the family per CI-14 (Refs #87): the runner declares
# it as SYSTEM_LOG_DIR (no TARGET_ prefix, unlike USER/GROUP), so the runner
# side maps each field to its declaration name explicitly.
function test_system_identity_guard {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: System Identity Single-Source Guard (#87)"
    print_sub_divider

    local setup_script="${SC_TOP}/../bin/setup-system-infra.bash"
    local line field
    local -A runner_env=() runner_def=() setup_env=() setup_def=()
    # The runner names USER/GROUP with a TARGET_ prefix but the log dir as a
    # bare SYSTEM_LOG_DIR; map each field to its runner-side declaration name.
    local -A runner_decl=( [USER]="TARGET_SYSTEM_USER" [GROUP]="TARGET_SYSTEM_GROUP" [LOG_DIR]="SYSTEM_LOG_DIR" )

    while IFS= read -r line; do
        for field in USER GROUP LOG_DIR; do
            if [[ "${line}" == "declare -g ${runner_decl[${field}]}="* ]]; then
                runner_env[${field}]="${line#*\$\{}"
                runner_env[${field}]="${runner_env[${field}]%%:-*}"
                runner_def[${field}]="${line#*:-}"
                runner_def[${field}]="${runner_def[${field}]%%\}*}"
            fi
        done
    done < "${RUNNER_SCRIPT}"

    while IFS= read -r line; do
        for field in USER GROUP LOG_DIR; do
            if [[ "${line}" == "declare -g SYSTEM_${field}="* ]]; then
                setup_env[${field}]="${line#*\$\{}"
                setup_env[${field}]="${setup_env[${field}]%%:-*}"
                setup_def[${field}]="${line#*:-}"
                setup_def[${field}]="${setup_def[${field}]%%\}*}"
            fi
        done
    done < "${setup_script}"

    verify_state "IOC_RUNNER_SYSTEM_USER" "${runner_env[USER]:-}" "Runner user identity resolves the IOC_RUNNER_SYSTEM_USER override"
    verify_state "IOC_RUNNER_SYSTEM_USER" "${setup_env[USER]:-}" "Setup user identity resolves the same override variable"
    verify_state "ioc-srv" "${runner_def[USER]:-}" "Runner user default pinned to ioc-srv"
    verify_state "${runner_def[USER]:-runner-unset}" "${setup_def[USER]:-setup-unset}" "User defaults agree across both scripts"
    verify_state "IOC_RUNNER_SYSTEM_GROUP" "${runner_env[GROUP]:-}" "Runner group identity resolves the IOC_RUNNER_SYSTEM_GROUP override"
    verify_state "IOC_RUNNER_SYSTEM_GROUP" "${setup_env[GROUP]:-}" "Setup group identity resolves the same override variable"
    verify_state "ioc" "${runner_def[GROUP]:-}" "Runner group default pinned to ioc"
    verify_state "${runner_def[GROUP]:-runner-unset}" "${setup_def[GROUP]:-setup-unset}" "Group defaults agree across both scripts"
    verify_state "IOC_RUNNER_SYSTEM_LOG_DIR" "${runner_env[LOG_DIR]:-}" "Runner log dir resolves the IOC_RUNNER_SYSTEM_LOG_DIR override"
    verify_state "IOC_RUNNER_SYSTEM_LOG_DIR" "${setup_env[LOG_DIR]:-}" "Setup log dir resolves the same override variable"
    verify_state "/var/log/procserv" "${runner_def[LOG_DIR]:-}" "Runner log dir default pinned to /var/log/procserv"
    verify_state "${runner_def[LOG_DIR]:-runner-unset}" "${setup_def[LOG_DIR]:-setup-unset}" "Log dir defaults agree across both scripts"
}

# Extract the procServ unit-template heredoc body from a script (the block whose
# Description names procServ), normalize the known mode-divergent variables
# (procServ binary, log dir), and drop the mode-divergent rows. The remaining
# lines are the must-agree contract. Assumes the heredoc uses the unquoted
# <<EOF delimiter; converting it to <<'EOF' or <<-EOF yields an empty block,
# which the caller catches loudly via its nonempty sentinel (fail-closed, never
# a false pass).
function _unit_must_agree_block {
    awk '/<<EOF/{cap=1;buf="";next} cap&&/^[[:space:]]*EOF[[:space:]]*$/{if(buf~/Description=procServ for/){printf "%s",buf;exit} cap=0;next} cap{buf=buf $0 "\n"}' "$1" \
      | sed 's/${procserv_bin}/@BIN@/g; s/${RESOLVED_PROCSERV_BIN}/@BIN@/g; s/${LOG_DIR}/@LOGDIR@/g; s/${SYSTEM_LOG_DIR}/@LOGDIR@/g' \
      | grep -vE '^(Description=|Wants=|After=|UMask=|User=|Group=|WantedBy=)'
}

# Validates the #81 / CI-4 shared-contract: the must-agree rows of the procServ
# systemd unit template are byte-identical between bin/ioc-runner (local user
# unit) and bin/setup-system-infra.bash (system unit), after normalizing the
# known mode-divergent variables. The two copies are examined-Keep (the runner
# is self-contained and cannot share a sourced lib); this guard forbids a
# one-sided drift of any must-agree row. Comparison is byte-exact (row order and
# blank lines included) — deliberate lockstep. The dropped rows are principled
# mode-divergences: UMask=0027 is local-only (the system unit keeps the default
# for group-readable logs, see LOG_LAYOUT.md); User/Group and Wants/After are
# system-only; WantedBy/Description differ by mode.
function test_template_contract_guard {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: procServ Unit Template Shared-Contract Guard (#81/CI-4)"
    print_sub_divider

    local setup_script="${SC_TOP}/../bin/setup-system-infra.bash"
    local local_blk system_blk extracted="empty"
    local_blk="$(_unit_must_agree_block "${RUNNER_SCRIPT}")"
    system_blk="$(_unit_must_agree_block "${setup_script}")"

    if [[ -n "${local_blk}" && -n "${system_blk}" ]]; then extracted="nonempty"; fi
    verify_state "nonempty" "${extracted}" "Both unit templates extracted from source"

    if [[ "${local_blk}" != "${system_blk}" ]]; then
        printf "${YELLOW}  must-agree drift (local < > system):${NC}\n"
        diff <(printf '%s\n' "${local_blk}") <(printf '%s\n' "${system_blk}") || true
    fi
    verify_state "${local_blk}" "${system_blk}" "Unit template must-agree rows identical across both scripts"

    # M10/#54 (M10.T1): the byte-exact compare above catches a one-sided drift, but
    # a two-sided removal of a shared row would still agree. Assert each M10 restart
    # directive is PRESENT in the must-agree block so a both-copies removal fails.
    local m10_row m10_present="all"
    for m10_row in "StartLimitIntervalSec=0" "StartLimitBurst=5" "StartLimitAction=none" \
                   "Restart=always" "RestartSec=2" "KillMode=mixed"; do
        if ! printf '%s\n' "${local_blk}" | grep -qxF "${m10_row}"; then
            m10_present="missing:${m10_row}"
            break
        fi
    done
    verify_state "all" "${m10_present}" "M10 restart directives present in the unit must-agree block"
}

# Extract the set of RUNNER_* metadata variables an installer injects via sed,
# i.e. the names targeted by s/^declare -g RUNNER_X=. Sorted and deduplicated.
# An empty result trips the caller's nonempty sentinel (fail-closed), so a
# rewrite of the injection lines that stops matching fails loudly, not silently.
function _metadata_injection_targets {
    grep -oE 's/\^declare -g RUNNER_[A-Z_]+=' "$1" 2>/dev/null \
      | grep -oE 'RUNNER_[A-Z_]+' \
      | sort -u
}

# Validates the #84 / CI-9 shared-contract: the git-metadata injection targets
# agree across the runner declaration anchor (bin/ioc-runner) and the two
# installers that sed them in (bin/setup-system-infra.bash,
# configure/inject-runner-version.bash). The metadata is hand-maintained in
# three places; a one-sided rename, a dropped injection line, or a field added
# to one injector only would silently leave the installed binary reporting the
# placeholder value with no install error. The guard forbids that drift:
# (1) both injectors must target the same RUNNER_* set, and (2) every injected
# name must have a matching declaration anchor in the runner, so the sed regex
# keeps matching its target. RUNNER_VERSION is the source-controlled value (not
# injected) and is intentionally excluded.
function test_metadata_contract_guard {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Git-Metadata Injection Shared-Contract Guard (#84/CI-9)"
    print_sub_divider

    local setup_script="${SC_TOP}/../bin/setup-system-infra.bash"
    local inject_script="${SC_TOP}/../configure/inject-runner-version.bash"
    local setup_set inject_set anchor_set missing extracted="empty"

    setup_set="$(_metadata_injection_targets "${setup_script}")"
    inject_set="$(_metadata_injection_targets "${inject_script}")"
    anchor_set="$(grep -oE '^declare -g RUNNER_[A-Z_]+=' "${RUNNER_SCRIPT}" | grep -oE 'RUNNER_[A-Z_]+' | sort -u)"

    if [[ -n "${setup_set}" && -n "${inject_set}" ]]; then extracted="nonempty"; fi
    verify_state "nonempty" "${extracted}" "Metadata sed targets extracted from both injectors"

    if [[ "${setup_set}" != "${inject_set}" ]]; then
        printf "${YELLOW}  injector drift (setup < > inject):${NC}\n"
        diff <(printf '%s\n' "${setup_set}") <(printf '%s\n' "${inject_set}") || true
    fi
    verify_state "${setup_set}" "${inject_set}" "Both injectors target the same RUNNER_* metadata set"

    missing="$(comm -23 <(printf '%s\n' "${setup_set}") <(printf '%s\n' "${anchor_set}"))"
    if [[ -n "${missing}" ]]; then
        printf "${YELLOW}  injected names with no declaration anchor:${NC}\n%s\n" "${missing}"
    fi
    verify_state "" "${missing}" "Every injected RUNNER_* has a declaration anchor in the runner"
}

function test_inspect_errors {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Inspect Error Paths"
    print_sub_divider

    local exit_code

    exit_code=$(_run bash "${RUNNER_SCRIPT}" inspect "dummy_ioc")
    verify_exit_code "1" "${exit_code}" "'inspect' without root privileges exits 1"
}


function test_crash_pattern_matching {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Crash Log Pattern Matching"
    print_sub_divider

    # Issue #4: iocsh parser, dynamic linker, and startup path failures
    verify_match "match"   "ERROR st.cmd line 52: Unbalanced quote."             "Pattern: Unbalanced quote"
    verify_match "match"   "Invalid directory path: /opt/ioc/missing"            "Pattern: Invalid directory path"
    verify_match "match"   "Can't open db/example.db"                            "Pattern: Can't open"
    verify_match "match"   "iocsh: cannot open '/etc/protocol/foo.proto'"        "Pattern: cannot open"
    verify_match "match"   "symbol lookup error: undefined symbol: epicsRingNew" "Pattern: undefined symbol"
    verify_match "match"   "/opt/ioc/iocBoot/iocX/st.cmd: No such file or directory" "Pattern: No such file or directory"

    # Issue #5: case-insensitive matching across casing variants
    verify_match "match"   "ERROR: device timeout"                  "Case-insensitive: ERROR (upper)"
    verify_match "match"   "Error: cannot allocate"                 "Case-insensitive: Error (title)"
    verify_match "match"   "error: nullptr deref"                   "Case-insensitive: error (lower)"
    verify_match "match"   "FATAL: aborting"                        "Case-insensitive: FATAL (upper)"
    verify_match "match"   "fatal allocation failure"               "Case-insensitive: fatal (lower)"

    # Regression: fatal startup patterns continue to match
    verify_match "match"   "Segmentation fault (core dumped)"       "Regression: Segmentation fault"

    # Negative: routine startup lines must not trigger crash detection
    verify_match "nomatch" "procServ: Restarting child"             "Negative: procServ child start line"
    verify_match "nomatch" "iocInit: All initialization complete"   "Negative: iocInit complete line"
    verify_match "nomatch" "## EPICS R7.0.7 banner"                 "Negative: EPICS banner"
    verify_match "nomatch" "Starting iocsh.bash"                    "Negative: startup banner"

    # M11/#67: the spelled-out base must equal the fatal|ambiguous union (set eq).
    verify_base_subset_union "DRY-base CRASH_LOG_PATTERNS == fatal|ambiguous subsets"

    # M11/#67: subset membership — fatal tokens are the standalone pre-marker
    # exit-1 triggers; ambiguous tokens are corroborating-only. Asserted via the
    # extracted subset regexes so a future mis-split is caught here.
    verify_match_subset "fatal"     "FATAL: aborting"                  "Subset: FATAL is fatal"
    verify_match_subset "fatal"     "undefined symbol: epicsRingNew"   "Subset: undefined symbol is fatal"
    verify_match_subset "ambiguous" "Can't open db/example.db"         "Subset: Can't open is ambiguous"
    verify_match_subset "ambiguous" "ERROR: device timeout"            "Subset: ERROR is ambiguous"
    verify_match_subset "ambiguous" "config: Invalid directory path, ignored" "Subset: Invalid directory path is ambiguous (benign EPICS warning)"
}


# Validates the issue #92 benign-noise exclusion contract: the iocsh history
# load/save failure line is removed before pattern matching, the exclusion is
# line-targeted, and the constant itself is pinned non-empty and well-formed.
# Fixtures carry the raw ANSI escape bytes the EPICS errlog ERL_ERROR macro
# emits around 'ERROR'; a regex spanning the escape boundary would not match.
function test_crash_scan_exclusion {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Crash Scan Benign-Noise Exclusion (#92)"
    print_sub_divider

    local benign_loading=$'\033[31;1mERROR\033[0m Permission denied (13) loading \'/opt/epics-iocs/demo/iocBoot/iocdemo/.iocsh_history\''
    local benign_writing=$'\033[31;1mERROR\033[0m Permission denied (13) writing \'.iocsh_history\''
    local benign_plus_fatal="${benign_loading}"$'\nFATAL: real crash in the same window'
    local same_line_collision="${benign_loading} FATAL: marker on the same physical line"

    # Guard pins: an empty or invalid exclude regex must fail here, not at runtime.
    local exclude_state="empty"
    if [[ -n "${CRASH_LOG_EXCLUDE_PATTERNS}" ]]; then
        exclude_state="nonempty"
    fi
    verify_state "nonempty" "${exclude_state}" "Exclusion: constant extracted non-empty from runner script"

    local compile_state="invalid"
    if printf "%s\n" "compile probe" | grep -vE "${CRASH_LOG_EXCLUDE_PATTERNS}" >/dev/null 2>&1; then
        compile_state="valid"
    fi
    verify_state "valid" "${compile_state}" "Exclusion: constant compiles under grep -E"

    # The benign line matches the raw pattern set; the exclusion is what clears it.
    verify_match_unfiltered "match"   "${benign_loading}" "Exclusion pin: history-load line matches patterns without filter"
    verify_match "nomatch" "${benign_loading}"            "Exclusion: history-load line cleared through pipeline"
    verify_match "nomatch" "${benign_writing}"            "Exclusion: history-write variant cleared through pipeline"

    # Line-targeted proof: a real fatal marker on another line in the same window still matches.
    verify_match "match"   "${benign_plus_fatal}"         "Exclusion: FATAL on another line in the window still matches"

    # Accepted residual (#92 design record): a marker sharing the benign line is
    # excluded with it; pinned as documented semantics, not engineered around.
    verify_match "nomatch" "${same_line_collision}"       "Exclusion: same-line collision excluded (documented residual)"
}


# Validates the install-time CRASH_LOG_PATTERNS_EXTRA contract from #25:
# valid extras are accepted, illegal characters and invalid regex syntax
# are rejected before the conf reaches the runtime grep call.
function test_crash_pattern_extra {
    local step="$1"
    local exit_code
    local test_dir="${TEST_TMPDIR}/extra_pattern_ioc"
    local mock_conf_dir="${TEST_TMPDIR}/extra_pattern_etc"
    local mock_sysd_dir="${TEST_TMPDIR}/extra_pattern_sysd"
    local conf_file="${test_dir}/extra_pattern_ioc.conf"

    print_divider
    _log "INFO" "STEP ${step}: CRASH_LOG_PATTERNS_EXTRA Validation"
    print_sub_divider

    mkdir -p "${test_dir}" "${mock_conf_dir}" "${mock_sysd_dir}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    local base_conf
    base_conf=$(printf "IOC_USER=%s\nIOC_GROUP=%s\nIOC_CHDIR=%s\nIOC_CMD=./st.cmd\n" \
        "$(id -un)" "$(id -gn)" "${test_dir}")

    printf "%s\nCRASH_LOG_PATTERNS_EXTRA=\"Bergoz link lost|NPCT overrange\"\n" "${base_conf}" > "${conf_file}"
    exit_code=$(IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
        _run bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}")
    verify_exit_code "0" "${exit_code}" "Valid CRASH_LOG_PATTERNS_EXTRA accepted at install"

    printf "%s\nCRASH_LOG_PATTERNS_EXTRA=\"foo;rm -rf /\"\n" "${base_conf}" > "${conf_file}"
    exit_code=$(IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
        _run bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}")
    verify_exit_code "1" "${exit_code}" "Illegal characters in CRASH_LOG_PATTERNS_EXTRA rejected at install"

    printf "%s\nCRASH_LOG_PATTERNS_EXTRA=\"unclosed(group\"\n" "${base_conf}" > "${conf_file}"
    exit_code=$(IOC_RUNNER_CONF_DIR="${mock_conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${mock_sysd_dir}" \
        _run bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}")
    verify_exit_code "1" "${exit_code}" "Invalid regex in CRASH_LOG_PATTERNS_EXTRA rejected at install"
}


# Validates #74/#78 tool resolution: IOC_RUNNER_PROCSERV_TOOL override semantics
# and the home-bin search-path default. Each case is self-contained -- it
# supplies its own stub via the override or a HOME-redirected ~/.local/bin.
# _setup now exports a suite-wide mock IOC_RUNNER_PROCSERV_TOOL (#77), so the
# home-bin search case below unsets it (env -u) to exercise the real search.
function test_tool_resolution {
    local step="$1"
    local test_dir="${TEST_TMPDIR}/toolres_ioc"
    local conf_dir="${TEST_TMPDIR}/toolres_conf"
    local sysd_dir="${TEST_TMPDIR}/toolres_sysd"
    local template="${sysd_dir}/epics-@.service"
    local conf_file="${test_dir}/toolres_ioc.conf"

    print_divider
    _log "INFO" "STEP ${step}: Tool Resolution (IOC_RUNNER_PROCSERV_TOOL + home-bin)"
    print_sub_divider

    mkdir -p "${test_dir}" "${conf_dir}" "${sysd_dir}"
    touch "${test_dir}/st.cmd"
    chmod +x "${test_dir}/st.cmd"

    # Pre-generate a valid conf the install path consumes. IOC_CHDIR resolves to
    # an absolute path, so later installs need no cwd change and can verify in
    # the function body (subshell verify calls would not update the counters).
    ( cd "${test_dir}" && bash "${RUNNER_SCRIPT}" --local generate . >/dev/null 2>&1 )

    # --- Case 1: a non-executable IOC_RUNNER_PROCSERV_TOOL is rejected. ---
    local nonexec="${TEST_TMPDIR}/nonexec_procserv"
    printf "#!/usr/bin/env bash\nexit 0\n" > "${nonexec}"   # intentionally not +x
    local c1_stderr="${TEST_TMPDIR}/toolres_c1_stderr"
    local c1_ec=0
    IOC_RUNNER_PROCSERV_TOOL="${nonexec}" \
        IOC_RUNNER_CONF_DIR="${conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${sysd_dir}" \
        bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}" >/dev/null 2>"${c1_stderr}" || c1_ec=$?
    verify_exit_code "1" "${c1_ec}" "Non-executable IOC_RUNNER_PROCSERV_TOOL exits 1"

    local c1_msg="false"
    if grep -q "IOC_RUNNER_PROCSERV_TOOL" "${c1_stderr}" 2>/dev/null \
       && grep -q "not an executable" "${c1_stderr}" 2>/dev/null; then
        c1_msg="true"
    fi
    verify_state "true" "${c1_msg}" "Non-executable override error names the variable"

    # --- Case 1b: an executable directory as the override is rejected (#78). ---
    # A directory carries the execute bit, so a bare -x check would accept it;
    # the override must be a regular executable file (-f && -x).
    local execdir="${TEST_TMPDIR}/execdir_procserv"
    mkdir -p "${execdir}"
    chmod +x "${execdir}"   # guarantee the fixture is an executable directory
    local c1b_stderr="${TEST_TMPDIR}/toolres_c1b_stderr"
    local c1b_ec=0
    IOC_RUNNER_PROCSERV_TOOL="${execdir}" \
        IOC_RUNNER_CONF_DIR="${conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${sysd_dir}" \
        bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}" >/dev/null 2>"${c1b_stderr}" || c1b_ec=$?
    verify_exit_code "1" "${c1b_ec}" "Executable-directory IOC_RUNNER_PROCSERV_TOOL exits 1"

    local c1b_msg="false"
    if grep -q "IOC_RUNNER_PROCSERV_TOOL" "${c1b_stderr}" 2>/dev/null \
       && grep -q "not an executable" "${c1b_stderr}" 2>/dev/null; then
        c1b_msg="true"
    fi
    verify_state "true" "${c1b_msg}" "Executable-directory override error names the variable"

    # --- Case 2: an executable IOC_RUNNER_PROCSERV_TOOL is honored. ---
    local stub="${TEST_TMPDIR}/stub_procserv"
    printf "#!/usr/bin/env bash\nexit 0\n" > "${stub}"
    chmod +x "${stub}"
    rm -f "${template}"
    local c2_ec=0
    IOC_RUNNER_PROCSERV_TOOL="${stub}" \
        IOC_RUNNER_CONF_DIR="${conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${sysd_dir}" \
        bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}" >/dev/null 2>&1 || c2_ec=$?
    verify_exit_code "0" "${c2_ec}" "Executable IOC_RUNNER_PROCSERV_TOOL accepted"

    local c2_ref="false"
    grep -q -F "${stub}" "${template}" 2>/dev/null && c2_ref="true"
    verify_state "true" "${c2_ref}" "Template ExecStart references the override binary"

    # --- Case 3: procServ resolves from ${HOME}/.local/bin via the search path. ---
    local fake_home="${TEST_TMPDIR}/toolres_home"
    local home_stub="${fake_home}/.local/bin/procServ"
    mkdir -p "${fake_home}/.local/bin"
    printf "#!/usr/bin/env bash\nexit 0\n" > "${home_stub}"
    chmod +x "${home_stub}"
    rm -f "${template}"
    local c3_ec=0
    env -u IOC_RUNNER_PROCSERV_TOOL HOME="${fake_home}" \
        IOC_RUNNER_CONF_DIR="${conf_dir}" IOC_RUNNER_SYSTEMD_DIR="${sysd_dir}" \
        bash "${RUNNER_SCRIPT}" --local -f install "${conf_file}" >/dev/null 2>&1 || c3_ec=$?
    verify_exit_code "0" "${c3_ec}" "Home-bin procServ resolves without an override"

    local c3_ref="false"
    grep -q -F "${home_stub}" "${template}" 2>/dev/null && c3_ref="true"
    verify_state "true" "${c3_ref}" "Template ExecStart references the home-bin binary"

    # --- Case 4: con search path prepends home-bin under a trusted HOME. ---
    # Static: con resolution is observable only through the final exec, which
    # do_attach guards behind a live socket (resolve_sock_path), absent in this
    # suite. Source the trust-flag and array-construction fragments with HOME
    # set (trusted), then assert the home-bin entry is first.
    local fake_home_con="${TEST_TMPDIR}/toolres_home_con"
    local c4_got
    c4_got=$(env HOME="${fake_home_con}" bash -c '
        source <(sed -n "/^declare -g HOME_TRUSTED=/,/^fi$/p" "'"${RUNNER_SCRIPT}"'")
        source <(sed -n "/^declare -g -a CON_SEARCH_PATHS=/,/^fi$/p" "'"${RUNNER_SCRIPT}"'")
        printf "%s" "${CON_SEARCH_PATHS[0]}"
    ' 2>/dev/null)
    verify_state "${fake_home_con}/.local/bin/con" "${c4_got}" \
        "con search path prepends home-bin when HOME is trusted"
}



function run_all_tests {
    local -a pipeline=(
        "_setup"
        "test_usage"
        "test_missing_target"
        "test_generate_logic"
        "test_install_logic"
        "test_ioc_port_atomic_install"
        "test_generate_errors"
        "test_install_errors"
        "test_list_ss_vv_contract"
        "test_unknown_name_verb_gate"
        "test_local_ioc_port_replacement_warns"
        "test_env_var_namespacing"
        "test_env_var_precedence"
        "test_system_identity_guard"
        "test_template_contract_guard"
        "test_metadata_contract_guard"
        "test_log_dir_guard"
        "test_log_dir_xdg_fallback"
        "test_completion"
        "test_ioc_name_validation"
        "test_validation_errors"
        "test_attach_errors"
        "test_list_empty"
        "test_inspect_errors"
        "test_crash_pattern_matching"
        "test_crash_scan_exclusion"
        "test_crash_pattern_extra"
        "test_tool_resolution"
    )
    local step=1
    local func
    for func in "${pipeline[@]}"; do
        "${func}" "${step}"
        step=$((step + 1))
    done
}

run_all_tests
