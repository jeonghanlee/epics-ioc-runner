#!/usr/bin/env bash
#
# Source-tree regression tests for privileged setup and metadata paths.
# Root owns suite startup and setup execution; the invoking user owns source,
# Git, and workspace operations.

set -euo pipefail
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
umask 077
unset BASH_ENV ENV CDPATH GIT_DIR GIT_WORK_TREE

declare -gr RED='\033[0;31m'
declare -gr GREEN='\033[0;32m'
declare -gr MAGENTA='\033[0;35m'
declare -gr BLUE='\033[0;34m'
declare -gr YELLOW='\033[0;33m'
declare -gr NC='\033[0m'

declare -g TEST_TOTAL=0
declare -g TEST_PASSED=0
declare -g TEST_FAILED=0
declare -g SCRIPT_ERROR=0
declare -g -a FAILED_DETAILS=()

declare -g SC_TOP
declare -g REPO_TOP
declare -g SC_PATH
declare -g INVOKING_USER="${SUDO_USER:-}"
declare -gr SUITE_ID="source-regression"
declare -gr SUITE_SCOPE="system"
declare -gr SUITE_RUNNER="source"
SC_PATH="${BASH_SOURCE[0]}"
if [[ "${SC_PATH}" != /* ]]; then
    SC_PATH="${PWD}/${SC_PATH}"
fi
SC_TOP="${SC_PATH%/*}"
REPO_TOP="${SC_TOP}/.."

function print_divider {
    printf "%b%s%b\n" "${BLUE}" \
        "====================================================================================================" "${NC}"
}

function print_summary {
    printf "\n"
    print_divider
    printf "%b%s%b\n" "${BLUE}" \
        "                              SOURCE REGRESSION TEST SUMMARY                                      " "${NC}"
    print_divider
    printf "  %-20s : %s\n" "Suite" "${SUITE_ID}"
    printf "  %-20s : %s\n" "Scope" "${SUITE_SCOPE}"
    printf "  %-20s : %s\n" "Runner" "${SUITE_RUNNER}"
    printf "  %-20s : %d\n" "Total Assertions" "${TEST_TOTAL}"
    printf "%b  %-20s : %d%b\n" "${GREEN}" "Passed" "${TEST_PASSED}" "${NC}"
    printf "%b  %-20s : %d%b\n" "${RED}" "Failed" "${TEST_FAILED}" "${NC}"
    printf "%b  %-20s : %d%b\n" "${MAGENTA}" "Script Errors" "${SCRIPT_ERROR}" "${NC}"

    if [[ ${TEST_FAILED} -gt 0 ]]; then
        printf "\n%b%s%b\n" "${RED}" "--- [ FAILED ASSERTIONS ] ---" "${NC}"
        local detail
        for detail in "${FAILED_DETAILS[@]}"; do
            printf "%b  * %s%b\n" "${RED}" "${detail}" "${NC}"
        done
    elif [[ ${SCRIPT_ERROR} -eq 0 ]]; then
        printf "\n%b%s%b\n" "${GREEN}" "[SUCCESS] All source regression checks passed." "${NC}"
    fi
    print_divider
}

function _handle_exit {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 && ${TEST_FAILED} -eq 0 ]]; then
        SCRIPT_ERROR=1
        printf "\n%b[ABORT]%b Script exited with code %d before all checks ran.\n" \
            "${RED}" "${NC}" "${exit_code}" >&2
    fi
    print_summary
    if [[ ${TEST_FAILED} -gt 0 || ${SCRIPT_ERROR} -gt 0 ]]; then
        exit 1
    fi
    exit 0
}
trap _handle_exit EXIT
trap 'exit 1' SIGINT

function verify_state {
    local expected="$1"
    local actual="$2"
    local check_id="$3"

    TEST_TOTAL=$((TEST_TOTAL + 1))
    if [[ "${expected}" == "${actual}" ]]; then
        printf "%b[ PASS ]%b %s\n" "${GREEN}" "${NC}" "${check_id}"
        TEST_PASSED=$((TEST_PASSED + 1))
        return
    fi

    printf "%b[ FAIL ]%b %s\n" "${RED}" "${NC}" "${check_id}" >&2
    printf "  %bExpected : %s%b\n" "${YELLOW}" "${expected}" "${NC}" >&2
    printf "  %bActual   : %s%b\n" "${YELLOW}" "${actual}" "${NC}" >&2
    TEST_FAILED=$((TEST_FAILED + 1))
    FAILED_DETAILS+=("${check_id} (expected ${expected}, actual ${actual})")
}

function run_as_invoker {
    sudo -u "${INVOKING_USER}" -n -- "$@"
}

function _log {
    local level="$1"
    local message="$2"
    local color="${NC}"

    case "${level}" in
        INFO) color="${BLUE}" ;;
        SUCCESS) color="${GREEN}" ;;
        WARN) color="${YELLOW}" ;;
        ERROR) color="${RED}" ;;
    esac
    printf "%b[%-7s] %s%b\n" "${color}" "${level}" "${message}" "${NC}"
}

function print_sub_divider {
    printf "%b%s%b\n" "${BLUE}" \
        "----------------------------------------------------------------------------------------------------" "${NC}"
}

function read_runner_value {
    local file="$1"
    local key="$2"
    local line
    local value

    while IFS= read -r line; do
        if [[ "${line}" == "declare -g ${key}="* ]]; then
            value="${line#*=}"
            value="${value#\"}"
            value="${value%\"}"
            printf "%s\n" "${value}"
            return 0
        fi
    done < "${file}"
    return 1
}

function run_setup_at {
    local cwd="$1"
    local invocation="$2"
    local prefix="$3"
    local source_override="${4:-}"
    local -a setup_env=(
        "IOC_RUNNER_SCRIPT_DEST=${prefix}.runner"
        "IOC_RUNNER_SCRIPT_SYMLINK=${prefix}.symlink"
        "IOC_RUNNER_BASH_COMP_DEST=${prefix}.completion"
        "IOC_RUNNER_BACKUP_DIR=${prefix}.backups"
    )

    if [[ -n "${source_override}" ]]; then
        setup_env+=("IOC_RUNNER_SCRIPT_SRC=${source_override}")
    fi
    (
        cd "${cwd}"
        env "${setup_env[@]}" bash "${invocation}"
    )
}

function test_preflight {
    print_divider
    printf "%b%s%b\n" "${BLUE}" "P00: Verify Source Regression Invocation Boundary" "${NC}"
    print_divider

    local root_invocation="false"
    [[ ${EUID} -eq 0 ]] && root_invocation="true"
    verify_state "true" "${root_invocation}" "${SUITE_ID}.P00.root-invocation"
    if [[ "${root_invocation}" != "true" ]]; then
        return 1
    fi

    local invoking_user="false"
    if [[ -n "${INVOKING_USER}" && "${INVOKING_USER}" != "root" ]] &&
       id -u "${INVOKING_USER}" >/dev/null 2>&1; then
        invoking_user="true"
    fi
    verify_state "true" "${invoking_user}" "${SUITE_ID}.P00.invoking-user"
    if [[ "${invoking_user}" != "true" ]]; then
        return 1
    fi

    local privilege_drop="false"
    if command -v sudo >/dev/null 2>&1 && run_as_invoker true; then
        privilege_drop="true"
    fi
    verify_state "true" "${privilege_drop}" "${SUITE_ID}.P00.privilege-drop"
    if [[ "${privilege_drop}" != "true" ]]; then
        return 1
    fi

    local git_command="false"
    if run_as_invoker git -C "${REPO_TOP}" rev-parse --git-dir >/dev/null 2>&1; then
        git_command="true"
    fi
    verify_state "true" "${git_command}" "${SUITE_ID}.P00.git-command"
    if [[ "${git_command}" != "true" ]]; then
        return 1
    fi

    local source_layout="true"
    local path
    for path in \
        "${REPO_TOP}/bin/setup-system-infra.bash" \
        "${REPO_TOP}/bin/ioc-runner" \
        "${REPO_TOP}/configure/inject-runner-version.bash" \
        "${SC_TOP}/test-system-lifecycle.bash"; do
        if ! run_as_invoker test -f "${path}"; then
            source_layout="false"
        fi
    done
    if ! run_as_invoker test -e "${REPO_TOP}/.git"; then
        source_layout="false"
    fi
    verify_state "true" "${source_layout}" "${SUITE_ID}.P00.source-layout"
    if [[ "${source_layout}" != "true" ]]; then
        return 1
    fi

    local workspace=""
    local workspace_ready="false"
    workspace=$(run_as_invoker mktemp -d 2>/dev/null || true)
    if [[ -n "${workspace}" ]] && run_as_invoker test -d "${workspace}" &&
       run_as_invoker rmdir "${workspace}"; then
        workspace_ready="true"
    fi
    verify_state "true" "${workspace_ready}" "${SUITE_ID}.P00.workspace"
    if [[ "${workspace_ready}" != "true" ]]; then
        return 1
    fi
}



function test_git_context_resolution {
    local step="$1"
    local work
    local expected_hash
    local stamped=""
    local stamped_hash=""
    local setup_rc=0
    local result="false"

    print_divider
    _log "INFO" "STEP ${step}: Verify Git Context Through the Real Setup Path"
    print_sub_divider

    work=$(run_as_invoker mktemp -d /tmp/ioc-runner-source-regression.XXXXXX)
    expected_hash=$(run_as_invoker git -C "${REPO_TOP}" rev-parse --short HEAD)
    run_setup_at "/tmp" "${REPO_TOP}/bin/setup-system-infra.bash" "${work}/s07" \
        >/dev/null 2>&1 || setup_rc=$?
    if [[ -f "${work}/s07.runner" ]]; then
        stamped=$(read_runner_value "${work}/s07.runner" "RUNNER_GIT_HASH" || true)
    fi
    # S07 isolates repository-context resolution. S10 independently verifies
    # clean and dirty suffix behavior through every version entry point.
    stamped_hash="${stamped%-dirty}"
    if [[ ${setup_rc} -eq 0 && "${stamped_hash}" == "${expected_hash}" ]]; then
        result="true"
    fi

    verify_state "true" "${result}" "${SUITE_ID}.S07.git-context.unrelated-cwd-hash"
    rm -rf "${work}"
}

function test_setup_script_dir_resolution {
    local step="$1"
    local work
    local canonicalization="false"
    local repo_root_ok="false"
    local bin_dir_ok="false"
    local absolute_ok="false"

    print_divider
    _log "INFO" "STEP ${step}: Verify Setup Invocation Path Resolution"
    print_sub_divider

    if grep -qE '="\\$\\([^)]*(readlink -f|realpath)|="\\$\\(cd[^)]*&& pwd' \
        "${BASH_SOURCE[0]}" "${SC_TOP}/test-system-lifecycle.bash" 2>/dev/null; then
        canonicalization="true"
    fi
    verify_state "false" "${canonicalization}" \
        "${SUITE_ID}.S08.sudo-tests.no-canonicalization"

    work=$(run_as_invoker mktemp -d /tmp/ioc-runner-source-regression.XXXXXX)

    if run_setup_at "${REPO_TOP}" "bin/setup-system-infra.bash" "${work}/root" \
        >/dev/null 2>&1 && [[ -s "${work}/root.runner" ]]; then
        repo_root_ok="true"
    fi
    verify_state "true" "${repo_root_ok}" \
        "${SUITE_ID}.S08.setup-script.repo-root-invocation"

    if run_setup_at "${REPO_TOP}/bin" "./setup-system-infra.bash" "${work}/bin" \
        >/dev/null 2>&1 && [[ -s "${work}/bin.runner" ]]; then
        bin_dir_ok="true"
    fi
    verify_state "true" "${bin_dir_ok}" \
        "${SUITE_ID}.S08.setup-script.bin-dir-invocation"

    if run_setup_at "/tmp" "${REPO_TOP}/bin/setup-system-infra.bash" "${work}/absolute" \
        >/dev/null 2>&1 && [[ -s "${work}/absolute.runner" ]]; then
        absolute_ok="true"
    fi
    verify_state "true" "${absolute_ok}" \
        "${SUITE_ID}.S08.setup-script.absolute-invocation"

    rm -rf "${work}"
}

function test_setup_stamp_layout_guard {
    local step="$1"
    local work
    local stamped=""
    local positive_ok="false"
    local positive_rc=0
    local fixture_built="false"
    local fixture_rc=0
    local negative_output=""
    local negative_rc=0
    local warning_seen="false"

    print_divider
    _log "INFO" "STEP ${step}: Verify Version-Stamp Layout Guard"
    print_sub_divider

    work=$(run_as_invoker mktemp -d /tmp/ioc-runner-source-regression.XXXXXX)

    run_setup_at "${REPO_TOP}" "bin/setup-system-infra.bash" "${work}/positive" \
        >/dev/null 2>&1 || positive_rc=$?
    if [[ -f "${work}/positive.runner" ]]; then
        stamped=$(read_runner_value "${work}/positive.runner" "RUNNER_GIT_HASH" || true)
    fi
    if [[ ${positive_rc} -eq 0 && -n "${stamped}" && "${stamped}" != "unknown" ]]; then
        positive_ok="true"
    fi
    verify_state "true" "${positive_ok}" \
        "${SUITE_ID}.S09.layout.real-checkout-hash"

    # Positional parameters are expanded by the delegated shell.
    # shellcheck disable=SC2016
    run_as_invoker bash -c '
        set -e
        mkdir -p "$1/xrepo/bin"
        cp "$2"/bin/* "$1/xrepo/bin/"
        cd "$1/xrepo"
        git init -q
        git config core.hooksPath /dev/null
        git config user.email test@example.invalid
        git config user.name test
        git add -A
        git commit -q -m init
    ' _ "${work}" "${REPO_TOP}" || fixture_rc=$?
    if [[ ${fixture_rc} -eq 0 ]] &&
       run_as_invoker git -C "${work}/xrepo" rev-parse --verify HEAD >/dev/null 2>&1; then
        fixture_built="true"
    fi
    verify_state "true" "${fixture_built}" \
        "${SUITE_ID}.S09.fixture.unrelated-checkout-built"
    if [[ "${fixture_built}" != "true" ]]; then
        rm -rf "${work}"
        return
    fi

    negative_output=$(run_setup_at "${work}/xrepo" \
        "bin/setup-system-infra.bash" "${work}/negative" 2>&1) || negative_rc=$?
    stamped=""
    if [[ -f "${work}/negative.runner" ]]; then
        stamped=$(read_runner_value "${work}/negative.runner" "RUNNER_GIT_HASH" || true)
    fi
    if [[ ${negative_rc} -ne 0 ]]; then
        stamped="setup-failed"
    fi
    verify_state "unknown" "${stamped:-none}" \
        "${SUITE_ID}.S09.layout.unrelated-checkout-unknown"

    if [[ ${negative_rc} -eq 0 ]] &&
       grep -qF "does not have the epics-ioc-runner layout" <<< "${negative_output}"; then
        warning_seen="true"
    fi
    verify_state "true" "${warning_seen}" \
        "${SUITE_ID}.S09.layout.unrelated-checkout-warning"

    rm -rf "${work}"
}
function test_stamp_relocated_clean_checkout {
    local step="$1"
    print_divider
    _log "INFO" "STEP ${step}: Version Stamp on a Relocated Checkout (#133, real runs)"
    print_sub_divider

    # No readlink/realpath/cd-pwd canonicalization here (#44): the relative
    # parent is enough for git clone, and canonicalizing would break under
    # root_squash where root cannot traverse the user-owned tree.
    local script_dir repo_top
    script_dir="$(dirname "${BASH_SOURCE[0]}")"
    repo_top="${script_dir}/.."

    local invoker="${SUDO_USER:-$(id -un)}"
    local as_invoker=(bash -c)
    if [[ "${invoker}" != "$(id -un)" ]] && command -v sudo >/dev/null 2>&1; then
        as_invoker=(sudo -u "${invoker}" -n bash -c)
    fi

    # Fixture family: one clean clone, then relocated copies produced without
    # any git invocation touching them. The copy is what leaves the index's
    # cached stat data stale (fresh inodes under an index written elsewhere);
    # a fixture built by git init/add/commit, or a clone used directly,
    # carries a freshly written index and asserts nothing (#133). Three
    # copies: clean, one real modification, and clean with an unwritable
    # index -- the state that separates a content comparison from an
    # index-refresh approach.
    local work
    local fixture_rc=0
    work=$("${as_invoker[@]}" 'mktemp -d')
    "${as_invoker[@]}" "git clone -q '${repo_top}' '${work}/clone' \
        && cp -a '${work}/clone' '${work}/fix' \
        && cp -a '${work}/clone' '${work}/mod' \
        && cp -a '${work}/clone' '${work}/lock' \
        && printf '\nprobe\n' >> '${work}/mod/README.md' \
        && chmod a-w '${work}/lock/.git' '${work}/lock/.git/index'" \
        >/dev/null 2>&1 || fixture_rc=$?
    local built="false"
    if [[ ${fixture_rc} -eq 0 && -d "${work}/fix/.git" &&
          -d "${work}/mod/.git" && -d "${work}/lock/.git" ]]; then
        built="true"
    fi
    verify_state "true" "${built}" "${SUITE_ID}.S10.fixture.clone-copy-built"
    if [[ "${built}" != "true" ]]; then
        "${as_invoker[@]}" "chmod -R u+w '${work}'" >/dev/null 2>&1 || true
        rm -rf "${work}" 2>/dev/null || true
        return
    fi

    stamp_of() {   # $1 = deployed or injected file
        grep -m1 '^declare -g RUNNER_GIT_HASH=' "$1" 2>/dev/null | sed 's/.*="\(.*\)"/\1/'
    }
    drive_setup() {   # $1 = fixture dir, $2 = tag; prints the stamped hash
        IOC_RUNNER_SCRIPT_DEST="${work}/$2-runner" \
        IOC_RUNNER_SCRIPT_SYMLINK="${work}/$2-symlink" \
        IOC_RUNNER_BASH_COMP_DEST="${work}/$2-completion" \
            bash "$1/bin/setup-system-infra.bash" >/dev/null 2>&1 || return $?
        stamp_of "${work}/$2-runner"
    }
    drive_live_v() {  # $1 = fixture dir; prints the -V version line
        local output
        # Read the complete response before selecting its first line so the
        # runner status cannot depend on an early-closing output consumer.
        output=$("${as_invoker[@]}" "bash '$1/bin/ioc-runner' -V 2>/dev/null") || return $?
        printf '%s\n' "${output%%$'\n'*}"
    }
    drive_inject() {  # $1 = fixture dir, $2 = tag; prints the injected hash
        "${as_invoker[@]}" "cp '$1/bin/ioc-runner' '${work}/$2-target' \
            && bash '$1/configure/inject-runner-version.bash' \
                '${work}/$2-target' '$1'" >/dev/null 2>&1 || return $?
        stamp_of "${work}/$2-target"
    }

    local stamped vline ok

    # Clean relocated checkout: every entry point stamps the bare hash.
    if ! stamped=$(drive_setup "${work}/fix" "fix"); then
        stamped=""
    fi
    ok="false"
    [[ -n "${stamped}" && "${stamped}" != "unknown" && "${stamped}" != *-dirty ]] && ok="true"
    verify_state "true" "${ok}" "${SUITE_ID}.S10.clean.setup-bare"

    if ! vline=$(drive_live_v "${work}/fix"); then
        vline=""
    fi
    ok="false"
    [[ "${vline}" == *"(live)"* && "${vline}" != *-dirty* && "${vline}" != *unknown* ]] && ok="true"
    verify_state "true" "${ok}" "${SUITE_ID}.S10.clean.live-version-bare"

    if ! stamped=$(drive_inject "${work}/fix" "fix"); then
        stamped=""
    fi
    ok="false"
    [[ -n "${stamped}" && "${stamped}" != "unknown" && "${stamped}" != *-dirty ]] && ok="true"
    verify_state "true" "${ok}" "${SUITE_ID}.S10.clean.injector-bare"

    # Negative control: one real modification keeps the suffix everywhere.
    if ! stamped=$(drive_setup "${work}/mod" "mod"); then
        stamped=""
    fi
    ok="false"
    [[ "${stamped}" == *-dirty ]] && ok="true"
    verify_state "true" "${ok}" "${SUITE_ID}.S10.modified.setup-dirty"

    if ! vline=$(drive_live_v "${work}/mod"); then
        vline=""
    fi
    ok="false"
    [[ "${vline}" == *"-dirty (live)"* ]] && ok="true"
    verify_state "true" "${ok}" "${SUITE_ID}.S10.modified.live-version-dirty"

    if ! stamped=$(drive_inject "${work}/mod" "mod"); then
        stamped=""
    fi
    ok="false"
    [[ "${stamped}" == *-dirty ]] && ok="true"
    verify_state "true" "${ok}" "${SUITE_ID}.S10.modified.injector-dirty"

    # Unwritable index: the verdict must not depend on refreshing the index.
    if ! stamped=$(drive_setup "${work}/lock" "lock"); then
        stamped=""
    fi
    ok="false"
    [[ -n "${stamped}" && "${stamped}" != "unknown" && "${stamped}" != *-dirty ]] && ok="true"
    verify_state "true" "${ok}" "${SUITE_ID}.S10.locked-index.setup-bare"

    if ! vline=$(drive_live_v "${work}/lock"); then
        vline=""
    fi
    ok="false"
    [[ "${vline}" == *"(live)"* && "${vline}" != *-dirty* && "${vline}" != *unknown* ]] && ok="true"
    verify_state "true" "${ok}" "${SUITE_ID}.S10.locked-index.live-version-bare"

    if ! stamped=$(drive_inject "${work}/lock" "lock"); then
        stamped=""
    fi
    ok="false"
    [[ -n "${stamped}" && "${stamped}" != "unknown" && "${stamped}" != *-dirty ]] && ok="true"
    verify_state "true" "${ok}" "${SUITE_ID}.S10.locked-index.injector-bare"

    "${as_invoker[@]}" "chmod -R u+w '${work}'" >/dev/null 2>&1 || true
    rm -rf "${work}" 2>/dev/null || true
}

# Behavioral regression for the runner backup filter (#123). Runs the REAL
# setup STEP 7 with the runner/symlink/completion destinations AND the backup
# directory (IOC_RUNNER_BACKUP_DIR) redirected to a scratch tree, so nothing
# system is touched. A no-change redeploy differs only in the three volatile
# RUNNER_* stamp lines and must NOT create a backup; a real source change must
# create exactly one. Counts "Created backup" log events, not .bak files
# (same-second timestamps would overwrite and undercount).

function test_setup_runner_backup_filter {
    local step="$1"
    local work
    local source_copy
    local prefix
    local fixture_built="false"
    local output_two
    local output_three
    local output_changed
    local nochange_backups
    local changed_backups
    local runner_basename
    local baseline_rc=0
    local output_two_rc=0
    local output_three_rc=0
    local source_change_rc=0
    local output_changed_rc=0

    print_divider
    _log "INFO" "STEP ${step}: Verify Runner Backup Filter"
    print_sub_divider

    work=$(run_as_invoker mktemp -d /tmp/ioc-runner-source-regression.XXXXXX)
    source_copy="${work}/src-ioc-runner"
    prefix="${work}/deploy"
    runner_basename="${prefix##*/}.runner"
    run_as_invoker cp "${REPO_TOP}/bin/ioc-runner" "${source_copy}"

    run_setup_at "${REPO_TOP}" "bin/setup-system-infra.bash" \
        "${prefix}" "${source_copy}" >/dev/null 2>&1 || baseline_rc=$?
    if [[ ${baseline_rc} -eq 0 && -s "${source_copy}" && -s "${prefix}.runner" ]]; then
        fixture_built="true"
    fi
    verify_state "true" "${fixture_built}" \
        "${SUITE_ID}.S11.fixture.source-copy-built"
    if [[ "${fixture_built}" != "true" ]]; then
        rm -rf "${work}"
        return
    fi

    output_two=$(run_setup_at "${REPO_TOP}" "bin/setup-system-infra.bash" \
        "${prefix}" "${source_copy}" 2>&1) || output_two_rc=$?
    output_three=$(run_setup_at "${REPO_TOP}" "bin/setup-system-infra.bash" \
        "${prefix}" "${source_copy}" 2>&1) || output_three_rc=$?
    nochange_backups=$(printf "%s\n%s\n" "${output_two}" "${output_three}" |
        grep -cF "Created backup of ${runner_basename}" || true)
    if [[ ${output_two_rc} -ne 0 || ${output_three_rc} -ne 0 ]]; then
        nochange_backups="setup-failed"
    fi
    verify_state "0" "${nochange_backups}" \
        "${SUITE_ID}.S11.backup.no-change-none"

    # Positional parameters are expanded by the delegated shell.
    # shellcheck disable=SC2016
    run_as_invoker bash -c 'printf "%s\n" "# real change" >> "$1"' _ "${source_copy}" ||
        source_change_rc=$?
    if [[ ${source_change_rc} -eq 0 ]]; then
        output_changed=$(run_setup_at "${REPO_TOP}" "bin/setup-system-infra.bash" \
            "${prefix}" "${source_copy}" 2>&1) || output_changed_rc=$?
    fi
    changed_backups=$(printf "%s\n" "${output_changed}" |
        grep -cF "Created backup of ${runner_basename}" || true)
    if [[ ${source_change_rc} -ne 0 || ${output_changed_rc} -ne 0 ]]; then
        changed_backups="setup-failed"
    fi
    verify_state "1" "${changed_backups}" \
        "${SUITE_ID}.S11.backup.source-change-one"

    rm -rf "${work}"
}
function test_setup_version_injection_guards {
    local step="$1"
    local setup_script="${REPO_TOP}/bin/setup-system-infra.bash"
    local sudo_user_ref="false"
    local sudo_u_drop="false"

    print_divider
    _log "INFO" "STEP ${step}: Verify Setup Version Injection Boundary"
    print_sub_divider

    if grep -qE 'SUDO_USER' "${setup_script}"; then
        sudo_user_ref="true"
    fi
    verify_state "true" "${sudo_user_ref}" \
        "${SUITE_ID}.S12.injection.sudo-user-reference"

    if grep -qE 'sudo[[:space:]]+-u[[:space:]]' "${setup_script}"; then
        sudo_u_drop="true"
    fi
    verify_state "true" "${sudo_u_drop}" \
        "${SUITE_ID}.S12.injection.sudo-user-drop"
}

function test_metadata_field_naming {
    local step="$1"
    local runner_script="${REPO_TOP}/bin/ioc-runner"
    local setup_script="${REPO_TOP}/bin/setup-system-infra.bash"
    local commit_decl="false"
    local install_decl="false"
    local build_residue="false"
    local work
    local expected_commit_date
    local deployed_commit_date=""
    local deployed_install_date=""
    local install_before
    local install_after
    local actual_install_epoch=0
    local install_in_range="false"
    local setup_rc=0

    print_divider
    _log "INFO" "STEP ${step}: Verify Version Metadata Contract and Injection"
    print_sub_divider

    if grep -qE '^declare -g RUNNER_COMMIT_DATE=' "${runner_script}"; then
        commit_decl="true"
    fi
    verify_state "true" "${commit_decl}" \
        "${SUITE_ID}.S13.runner.commit-date-declaration"

    if grep -qE '^declare -g RUNNER_INSTALL_DATE=' "${runner_script}"; then
        install_decl="true"
    fi
    verify_state "true" "${install_decl}" \
        "${SUITE_ID}.S13.runner.install-date-declaration"

    if grep -qE 'RUNNER_BUILD_DATE|build date:' "${runner_script}" "${setup_script}"; then
        build_residue="true"
    fi
    verify_state "false" "${build_residue}" \
        "${SUITE_ID}.S13.metadata.legacy-build-date-absent"

    work=$(run_as_invoker mktemp -d /tmp/ioc-runner-source-regression.XXXXXX)
    expected_commit_date=$(date -u -d \
        "@$(run_as_invoker git -C "${REPO_TOP}" show -s --format=%ct HEAD)" \
        +"%Y-%m-%dT%H:%M:%SZ")
    install_before=$(date -u +%s)
    run_setup_at "${REPO_TOP}" "bin/setup-system-infra.bash" "${work}/metadata" \
        >/dev/null 2>&1 || setup_rc=$?
    install_after=$(date -u +%s)

    if [[ -f "${work}/metadata.runner" ]]; then
        deployed_commit_date=$(read_runner_value \
            "${work}/metadata.runner" "RUNNER_COMMIT_DATE" || true)
        deployed_install_date=$(read_runner_value \
            "${work}/metadata.runner" "RUNNER_INSTALL_DATE" || true)
        actual_install_epoch=$(date -u -d "${deployed_install_date}" +%s 2>/dev/null || printf "0")
    fi
    if [[ ${setup_rc} -ne 0 ]]; then
        deployed_commit_date="setup-failed"
        actual_install_epoch=0
    fi

    verify_state "${expected_commit_date}" "${deployed_commit_date}" \
        "${SUITE_ID}.S13.setup.commit-date-injection"

    if [[ ${actual_install_epoch} -ge ${install_before} &&
          ${actual_install_epoch} -le ${install_after} ]]; then
        install_in_range="true"
    fi
    verify_state "true" "${install_in_range}" \
        "${SUITE_ID}.S13.setup.install-date-injection"

    rm -rf "${work}"
}

function test_runner_version_path_resolution {
    local step="$1"
    local runner_script="${REPO_TOP}/bin/ioc-runner"
    local work
    local expected_hash
    local version_output=""
    local version_line=""
    local version_rc=0
    local result="false"

    print_divider
    _log "INFO" "STEP ${step}: Verify Live Version with a Failed Readlink Boundary"
    print_sub_divider

    work=$(run_as_invoker mktemp -d /tmp/ioc-runner-source-regression.XXXXXX)
    run_as_invoker mkdir -p "${work}/bin"
    # Positional parameters are expanded by the delegated shell.
    # shellcheck disable=SC2016
    run_as_invoker bash -c \
        'printf "%s\\n" "#!/usr/bin/env bash" "exit 1" > "$1"; chmod 0755 "$1"' \
        _ "${work}/bin/readlink"

    expected_hash=$(run_as_invoker git -C "${REPO_TOP}" rev-parse --short HEAD)
    # Positional parameters are expanded by the delegated shell.
    # shellcheck disable=SC2016
    version_output=$(run_as_invoker env \
        "PATH=${work}/bin:/usr/local/bin:/usr/bin:/bin" \
        bash -c 'cd /tmp && bash "$1" -V' _ "${runner_script}" 2>/dev/null) ||
        version_rc=$?
    version_line="${version_output%%$'\n'*}"
    if [[ ${version_rc} -eq 0 && "${version_line}" == *"${expected_hash}"* &&
          "${version_line}" == *"(live)"* ]]; then
        result="true"
    fi

    verify_state "true" "${result}" \
        "${SUITE_ID}.S14.live-version.readlink-failure-hash"
    rm -rf "${work}"
}

# Verifies that the runner and privileged setup declare the same supported
# system identity overrides and defaults. Source content is read as the
# invoking user so a root-started suite does not bypass checkout ownership.
function test_system_identity_contract {
    local step="$1"
    local runner_script="${REPO_TOP}/bin/ioc-runner"
    local setup_script="${REPO_TOP}/bin/setup-system-infra.bash"
    local runner_source=""
    local setup_source=""
    local line
    local field
    local -A runner_contract_env=()
    local -A runner_contract_def=()
    local -A setup_contract_env=()
    local -A setup_contract_def=()
    local -A runner_decl=(
        [USER]="TARGET_SYSTEM_USER"
        [GROUP]="TARGET_SYSTEM_GROUP"
        [LOG_DIR]="SYSTEM_LOG_DIR"
    )

    print_divider
    _log "INFO" "STEP ${step}: Verify System Identity Source Contract"
    print_sub_divider

    runner_source=$(run_as_invoker cat -- "${runner_script}" 2>/dev/null) || runner_source=""
    setup_source=$(run_as_invoker cat -- "${setup_script}" 2>/dev/null) || setup_source=""

    while IFS= read -r line || [[ -n "${line:-}" ]]; do
        for field in USER GROUP LOG_DIR; do
            if [[ "${line}" == "declare -g ${runner_decl[${field}]}="* ]]; then
                runner_contract_env[${field}]="${line#*\$\{}"
                runner_contract_env[${field}]="${runner_contract_env[${field}]%%:-*}"
                runner_contract_def[${field}]="${line#*:-}"
                runner_contract_def[${field}]="${runner_contract_def[${field}]%%\}*}"
            fi
        done
    done <<< "${runner_source}"

    while IFS= read -r line || [[ -n "${line:-}" ]]; do
        for field in USER GROUP LOG_DIR; do
            if [[ "${line}" == "declare -g SYSTEM_${field}="* ]]; then
                setup_contract_env[${field}]="${line#*\$\{}"
                setup_contract_env[${field}]="${setup_contract_env[${field}]%%:-*}"
                setup_contract_def[${field}]="${line#*:-}"
                setup_contract_def[${field}]="${setup_contract_def[${field}]%%\}*}"
            fi
        done
    done <<< "${setup_source}"

    verify_state "IOC_RUNNER_SYSTEM_USER" "${runner_contract_env[USER]:-}" \
        "${SUITE_ID}.S15.runner-user-override-declaration"
    verify_state "IOC_RUNNER_SYSTEM_USER" "${setup_contract_env[USER]:-}" \
        "${SUITE_ID}.S15.setup-user-override-declaration"
    verify_state "ioc-srv" "${runner_contract_def[USER]:-}" \
        "${SUITE_ID}.S15.runner-user-default-ioc-srv"
    verify_state "${runner_contract_def[USER]:-runner-unset}" \
        "${setup_contract_def[USER]:-setup-unset}" \
        "${SUITE_ID}.S15.user-defaults-agree"
    verify_state "IOC_RUNNER_SYSTEM_GROUP" "${runner_contract_env[GROUP]:-}" \
        "${SUITE_ID}.S15.runner-group-override-declaration"
    verify_state "IOC_RUNNER_SYSTEM_GROUP" "${setup_contract_env[GROUP]:-}" \
        "${SUITE_ID}.S15.setup-group-override-declaration"
    verify_state "ioc" "${runner_contract_def[GROUP]:-}" \
        "${SUITE_ID}.S15.runner-group-default-ioc"
    verify_state "${runner_contract_def[GROUP]:-runner-unset}" \
        "${setup_contract_def[GROUP]:-setup-unset}" \
        "${SUITE_ID}.S15.group-defaults-agree"
    verify_state "IOC_RUNNER_SYSTEM_LOG_DIR" "${runner_contract_env[LOG_DIR]:-}" \
        "${SUITE_ID}.S15.runner-log-dir-override-declaration"
    verify_state "IOC_RUNNER_SYSTEM_LOG_DIR" "${setup_contract_env[LOG_DIR]:-}" \
        "${SUITE_ID}.S15.setup-log-dir-override-declaration"
    verify_state "/var/log/procserv" "${runner_contract_def[LOG_DIR]:-}" \
        "${SUITE_ID}.S15.runner-log-dir-default"
    verify_state "${runner_contract_def[LOG_DIR]:-runner-unset}" \
        "${setup_contract_def[LOG_DIR]:-setup-unset}" \
        "${SUITE_ID}.S15.log-dir-defaults-agree"
}

function run_all_tests {
    if ! test_preflight; then
        return
    fi
    test_git_context_resolution "S07"
    test_setup_script_dir_resolution "S08"
    test_setup_stamp_layout_guard "S09"
    test_stamp_relocated_clean_checkout "S10"
    test_setup_runner_backup_filter "S11"
    test_setup_version_injection_guards "S12"
    test_metadata_field_naming "S13"
    test_runner_version_path_resolution "S14"
    test_system_identity_contract "S15"
}

run_all_tests
