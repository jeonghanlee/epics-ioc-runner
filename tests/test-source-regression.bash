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
declare -gr BLUE='\033[0;34m'
declare -gr YELLOW='\033[0;33m'
declare -gr NC='\033[0m'

declare -g SC_TOP
declare -g REPO_TOP
declare -g SC_PATH
declare -g INVOKING_USER="${SUDO_USER:-}"
declare -gr SUITE_ID="source-regression"
declare -gr SUITE_SCOPE="system"
declare -gr SUITE_RUNNER="source"
declare -gr SUITE_CATEGORY="source-regression"
declare -g REPORT_DIR=""
declare -g REPORT_READY=0
declare -g -a SOURCE_CHECK_IDS=(
    "${SUITE_ID}.P00.root-invocation"
    "${SUITE_ID}.P00.invoking-user"
    "${SUITE_ID}.P00.privilege-drop"
    "${SUITE_ID}.P00.git-command"
    "${SUITE_ID}.P00.source-layout"
    "${SUITE_ID}.P00.workspace"
    "${SUITE_ID}.S07.git-context.unrelated-cwd-hash"
    "${SUITE_ID}.S08.sudo-tests.no-canonicalization"
    "${SUITE_ID}.S08.setup-script.repo-root-invocation"
    "${SUITE_ID}.S08.setup-script.bin-dir-invocation"
    "${SUITE_ID}.S08.setup-script.absolute-invocation"
    "${SUITE_ID}.S09.layout.real-checkout-hash"
    "${SUITE_ID}.S09.fixture.unrelated-checkout-built"
    "${SUITE_ID}.S09.layout.unrelated-checkout-unknown"
    "${SUITE_ID}.S09.layout.unrelated-checkout-warning"
    "${SUITE_ID}.S10.fixture.clone-copy-built"
    "${SUITE_ID}.S10.clean.setup-bare"
    "${SUITE_ID}.S10.clean.live-version-bare"
    "${SUITE_ID}.S10.clean.injector-bare"
    "${SUITE_ID}.S10.modified.setup-dirty"
    "${SUITE_ID}.S10.modified.live-version-dirty"
    "${SUITE_ID}.S10.modified.injector-dirty"
    "${SUITE_ID}.S10.locked-index.setup-bare"
    "${SUITE_ID}.S10.locked-index.live-version-bare"
    "${SUITE_ID}.S10.locked-index.injector-bare"
    "${SUITE_ID}.S11.fixture.source-copy-built"
    "${SUITE_ID}.S11.backup.no-change-none"
    "${SUITE_ID}.S11.backup.source-change-one"
    "${SUITE_ID}.S12.injection.sudo-user-reference"
    "${SUITE_ID}.S12.injection.sudo-user-drop"
    "${SUITE_ID}.S13.runner.commit-date-declaration"
    "${SUITE_ID}.S13.runner.install-date-declaration"
    "${SUITE_ID}.S13.metadata.legacy-build-date-absent"
    "${SUITE_ID}.S13.setup.commit-date-injection"
    "${SUITE_ID}.S13.setup.install-date-injection"
    "${SUITE_ID}.S14.live-version.readlink-failure-hash"
    "${SUITE_ID}.S15.runner-user-override-declaration"
    "${SUITE_ID}.S15.setup-user-override-declaration"
    "${SUITE_ID}.S15.runner-user-default-ioc-srv"
    "${SUITE_ID}.S15.user-defaults-agree"
    "${SUITE_ID}.S15.runner-group-override-declaration"
    "${SUITE_ID}.S15.setup-group-override-declaration"
    "${SUITE_ID}.S15.runner-group-default-ioc"
    "${SUITE_ID}.S15.group-defaults-agree"
    "${SUITE_ID}.S15.runner-log-dir-override-declaration"
    "${SUITE_ID}.S15.setup-log-dir-override-declaration"
    "${SUITE_ID}.S15.runner-log-dir-default"
    "${SUITE_ID}.S15.log-dir-defaults-agree"
    "${SUITE_ID}.S16.templates.extracted"
    "${SUITE_ID}.S16.templates.must-agree"
    "${SUITE_ID}.S16.restart-directives.present"
    "${SUITE_ID}.S16.runtime-directory-preserve.present"
    "${SUITE_ID}.S17.metadata.targets-extracted"
    "${SUITE_ID}.S17.metadata.injectors-agree"
    "${SUITE_ID}.S17.metadata.declaration-anchors-present"
    "${SUITE_ID}.S18.pipefail-help-probe-pattern.absent"
    "${SUITE_ID}.S19.sudoers-regex.count-six"
    "${SUITE_ID}.S19.sudoers-regex.identical"
    "${SUITE_ID}.S19.runner-name.max-length-64"
    "${SUITE_ID}.S19.runner-sudoers-name-contracts.agree"
    "${SUITE_ID}.S20.pattern-unbalanced-quote"
    "${SUITE_ID}.S20.pattern-invalid-directory-path"
    "${SUITE_ID}.S20.pattern-can-t-open"
    "${SUITE_ID}.S20.pattern-cannot-open"
    "${SUITE_ID}.S20.pattern-undefined-symbol"
    "${SUITE_ID}.S20.pattern-no-such-file-or-directory"
    "${SUITE_ID}.S20.case-insensitive-error-upper"
    "${SUITE_ID}.S20.case-insensitive-error-title"
    "${SUITE_ID}.S20.case-insensitive-error-lower"
    "${SUITE_ID}.S20.case-insensitive-fatal-upper"
    "${SUITE_ID}.S20.case-insensitive-fatal-lower"
    "${SUITE_ID}.S20.regression-segmentation-fault"
    "${SUITE_ID}.S20.negative-procserv-child-start-line"
    "${SUITE_ID}.S20.negative-iocinit-complete-line"
    "${SUITE_ID}.S20.negative-epics-banner"
    "${SUITE_ID}.S20.negative-startup-banner"
    "${SUITE_ID}.S20.base-patterns.equal-subset-union"
    "${SUITE_ID}.S20.subset-fatal-is-fatal"
    "${SUITE_ID}.S20.subset-undefined-symbol-is-fatal"
    "${SUITE_ID}.S20.subset-can-t-open-is-ambiguous"
    "${SUITE_ID}.S20.subset-error-is-ambiguous"
    "${SUITE_ID}.S20.subset-invalid-directory-path-is-ambiguous"
    "${SUITE_ID}.S21.exclude-pattern.nonempty"
    "${SUITE_ID}.S21.exclude-pattern.compiles"
    "${SUITE_ID}.S21.history-load.matches-base-patterns"
    "${SUITE_ID}.S21.history-write.matches-exclude-pattern"
    "${SUITE_ID}.S21.line-filter.precedes-crash-scans"
)
SC_PATH="${BASH_SOURCE[0]}"
if [[ "${SC_PATH}" != /* ]]; then
    SC_PATH="${PWD}/${SC_PATH}"
fi
SC_TOP="${SC_PATH%/*}"
REPO_TOP="${SC_TOP}/.."
# shellcheck source=lib/test-reporting.bash
source "${SC_TOP}/lib/test-reporting.bash"

function print_divider {
    printf "%b%s%b\n" "${BLUE}" \
        "====================================================================================================" "${NC}"
}

function _handle_exit {
    local exit_code=$?
    local final_status="${exit_code}"

    trap - EXIT
    if (( REPORT_READY )); then
        report_finalize "${exit_code}" || final_status=1
    fi
    if [[ -n "${REPORT_DIR}" && "${REPORT_DIR}" == /tmp/ioc-runner-source-report.* &&
          -d "${REPORT_DIR}" && ! -L "${REPORT_DIR}" ]]; then
        "${REPORT_RM_BIN:-/bin/rm}" -rf -- "${REPORT_DIR}" || final_status=1
    fi
    exit "${final_status}"
}
trap _handle_exit EXIT
trap 'exit 1' SIGINT

function verify_state {
    local expected="$1"
    local actual="$2"
    local check_id="$3"

    if [[ "${expected}" == "${actual}" ]]; then
        printf "%b[ PASS ]%b %s\n" "${GREEN}" "${NC}" "${check_id}"
        report_record "${check_id}" PASS
        return
    fi

    printf "%b[ FAIL ]%b %s\n" "${RED}" "${NC}" "${check_id}" >&2
    printf "  %bExpected : %s%b\n" "${YELLOW}" "${expected}" "${NC}" >&2
    printf "  %bActual   : %s%b\n" "${YELLOW}" "${actual}" "${NC}" >&2
    report_record "${check_id}" FAIL "expected ${expected}, actual ${actual}"
}

function source_check_metadata {
    local check_id="$1"
    local kind_name="$2"
    local method_name="$3"
    local required_direct="false"

    case "${check_id}" in
        "${SUITE_ID}.P00."*|\
        "${SUITE_ID}.S08.sudo-tests.no-canonicalization"|\
        "${SUITE_ID}.S09.fixture.unrelated-checkout-built"|\
        "${SUITE_ID}.S10.fixture.clone-copy-built"|\
        "${SUITE_ID}.S11.fixture.source-copy-built"|\
        "${SUITE_ID}.S12."*|\
        "${SUITE_ID}.S13.runner."*|\
        "${SUITE_ID}.S13.metadata."*|\
        "${SUITE_ID}.S15."*|\
        "${SUITE_ID}.S16."*|\
        "${SUITE_ID}.S17."*|\
        "${SUITE_ID}.S18."*|\
        "${SUITE_ID}.S19."*|\
        "${SUITE_ID}.S20."*|\
        "${SUITE_ID}.S21."*) required_direct="true" ;;
    esac
    if [[ "${required_direct}" == "true" ]]; then
        printf -v "${kind_name}" '%s' REQUIRED
        printf -v "${method_name}" '%s' direct-inspection
    else
        printf -v "${kind_name}" '%s' BEHAVIOR
        printf -v "${method_name}" '%s' real-path
    fi
}

function register_reporting_catalog {
    local check_id=""
    local description=""
    local kind=""
    local method=""
    local remainder=""
    local step_id=""
    local -a step_ids=(P00 S07 S08 S09 S10 S11 S12 S13 S14 S15 S16 S17 S18 S19 S20 S21)

    for step_id in "${step_ids[@]}"; do
        report_register_step "${step_id}" "Source regression ${step_id}"
    done
    for check_id in "${SOURCE_CHECK_IDS[@]}"; do
        remainder="${check_id#${SUITE_ID}.}"
        step_id="${remainder%%.*}"
        description="${remainder#*.}"
        source_check_metadata "${check_id}" kind method
        report_register_check "${check_id}" "${step_id}" "${SUITE_CATEGORY}" \
            "${kind}" "${method}" "${description}"
    done
    report_close_catalog
}

function read_os_release_value {
    local wanted="$1"
    local key=""
    local value=""

    while IFS='=' read -r key value || [[ -n "${key:-}" ]]; do
        if [[ "${key}" == "${wanted}" ]]; then
            value="${value#\"}"
            value="${value%\"}"
            printf '%s' "${value}"
            return 0
        fi
    done < /etc/os-release
    return 1
}

function initialize_reporting {
    local os_name="unknown"
    local os_version="0"
    local os_id=""
    local arch_id="${EPICS_HOST_ARCH:-unknown}"
    local run_id="${SUITE_ID}.$$.${BASHPID}"

    if [[ -r /etc/os-release ]]; then
        os_name=$(read_os_release_value ID || true)
        os_version=$(read_os_release_value VERSION_ID || true)
    fi
    os_name="${os_name:-unknown}"
    os_version="${os_version%%.*}"
    os_version="${os_version:-0}"
    os_id="${os_name}-${os_version}"
    REPORT_DIR=$(mktemp -d /tmp/ioc-runner-source-report.XXXXXX)
    report_init "${SUITE_ID}" "${run_id}" "${SUITE_SCOPE}" "${SUITE_RUNNER}" \
        "${os_id}" "${arch_id}" "${REPORT_DIR}"
    REPORT_READY=1
    register_reporting_catalog
}

function skip_catalog_from {
    local start_index="$1"
    local failed_check="$2"
    local check_id=""

    for check_id in "${SOURCE_CHECK_IDS[@]:${start_index}}"; do
        report_record "${check_id}" SKIP "requires ${failed_check}"
    done
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
        skip_catalog_from 1 "${SUITE_ID}.P00.root-invocation"
        return 1
    fi

    local invoking_user="false"
    if [[ -n "${INVOKING_USER}" && "${INVOKING_USER}" != "root" ]] &&
       id -u "${INVOKING_USER}" >/dev/null 2>&1; then
        invoking_user="true"
    fi
    verify_state "true" "${invoking_user}" "${SUITE_ID}.P00.invoking-user"
    if [[ "${invoking_user}" != "true" ]]; then
        skip_catalog_from 2 "${SUITE_ID}.P00.invoking-user"
        return 1
    fi

    local privilege_drop="false"
    if command -v sudo >/dev/null 2>&1 && run_as_invoker true; then
        privilege_drop="true"
    fi
    verify_state "true" "${privilege_drop}" "${SUITE_ID}.P00.privilege-drop"
    if [[ "${privilege_drop}" != "true" ]]; then
        skip_catalog_from 3 "${SUITE_ID}.P00.privilege-drop"
        return 1
    fi

    local git_command="false"
    if run_as_invoker git -C "${REPO_TOP}" rev-parse --git-dir >/dev/null 2>&1; then
        git_command="true"
    fi
    verify_state "true" "${git_command}" "${SUITE_ID}.P00.git-command"
    if [[ "${git_command}" != "true" ]]; then
        skip_catalog_from 4 "${SUITE_ID}.P00.git-command"
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
        skip_catalog_from 5 "${SUITE_ID}.P00.source-layout"
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
        skip_catalog_from 6 "${SUITE_ID}.P00.workspace"
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
        report_record "${SUITE_ID}.S09.layout.unrelated-checkout-unknown" SKIP \
            "requires ${SUITE_ID}.S09.fixture.unrelated-checkout-built"
        report_record "${SUITE_ID}.S09.layout.unrelated-checkout-warning" SKIP \
            "requires ${SUITE_ID}.S09.fixture.unrelated-checkout-built"
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
    local dependent_id=""
    local -a dependent_ids=(
        "${SUITE_ID}.S10.clean.setup-bare"
        "${SUITE_ID}.S10.clean.live-version-bare"
        "${SUITE_ID}.S10.clean.injector-bare"
        "${SUITE_ID}.S10.modified.setup-dirty"
        "${SUITE_ID}.S10.modified.live-version-dirty"
        "${SUITE_ID}.S10.modified.injector-dirty"
        "${SUITE_ID}.S10.locked-index.setup-bare"
        "${SUITE_ID}.S10.locked-index.live-version-bare"
        "${SUITE_ID}.S10.locked-index.injector-bare"
    )
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
        for dependent_id in "${dependent_ids[@]}"; do
            report_record "${dependent_id}" SKIP \
                "requires ${SUITE_ID}.S10.fixture.clone-copy-built"
        done
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
        report_record "${SUITE_ID}.S11.backup.no-change-none" SKIP \
            "requires ${SUITE_ID}.S11.fixture.source-copy-built"
        report_record "${SUITE_ID}.S11.backup.source-change-one" SKIP \
            "requires ${SUITE_ID}.S11.fixture.source-copy-built"
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

# Extracts the procServ unit-template heredoc through the invoking-user
# boundary, normalizes fields that differ by mode, and returns only the rows
# that form the shared source contract.
function _unit_must_agree_block {
    local source_file="$1"

    # The parser and normalization expressions must preserve literal shell
    # parameter syntax from the source templates.
    # shellcheck disable=SC2016
    run_as_invoker awk '/<<EOF/{cap=1;buf="";next} cap&&/^[[:space:]]*EOF[[:space:]]*$/{if(buf~/Description=procServ for/){printf "%s",buf;exit} cap=0;next} cap{buf=buf $0 "\n"}' \
        "${source_file}" \
        | sed 's/${procserv_bin}/@BIN@/g; s/${RESOLVED_PROCSERV_BIN}/@BIN@/g; s/${LOG_DIR}/@LOGDIR@/g; s/${SYSTEM_LOG_DIR}/@LOGDIR@/g' \
        | grep -vE '^(Description=|Wants=|After=|UMask=|User=|Group=|WantedBy=)'
}

# Verifies the rows that must agree between the local and system procServ unit
# templates. The comparison is byte-exact after documented mode differences
# are removed, and required restart rows are pinned against two-sided removal.
function test_unit_template_contract {
    local step="$1"
    local runner_script="${REPO_TOP}/bin/ioc-runner"
    local setup_script="${REPO_TOP}/bin/setup-system-infra.bash"
    local runner_block=""
    local setup_block=""
    local extracted="empty"
    local restart_row
    local restart_rows="all"
    local preserve_state="present"
    local source_file

    print_divider
    _log "INFO" "STEP ${step}: Verify procServ Unit Template Source Contract"
    print_sub_divider

    runner_block=$(_unit_must_agree_block "${runner_script}" || true)
    setup_block=$(_unit_must_agree_block "${setup_script}" || true)

    if [[ -n "${runner_block}" && -n "${setup_block}" ]]; then
        extracted="nonempty"
    fi
    verify_state "nonempty" "${extracted}" \
        "${SUITE_ID}.S16.templates.extracted"

    if [[ "${runner_block}" != "${setup_block}" ]]; then
        printf "%b%s%b\n" "${YELLOW}" \
            "  must-agree drift (local < > system):" "${NC}"
        diff <(printf '%s\n' "${runner_block}") \
            <(printf '%s\n' "${setup_block}") || true
    fi
    verify_state "${runner_block}" "${setup_block}" \
        "${SUITE_ID}.S16.templates.must-agree"

    for restart_row in \
        "StartLimitIntervalSec=0" \
        "StartLimitBurst=5" \
        "StartLimitAction=none" \
        "Restart=always" \
        "RestartSec=2" \
        "KillMode=mixed"; do
        if ! grep -qxF "${restart_row}" <<< "${runner_block}"; then
            restart_rows="missing:${restart_row}"
            break
        fi
    done
    verify_state "all" "${restart_rows}" \
        "${SUITE_ID}.S16.restart-directives.present"

    for source_file in "${runner_script}" "${setup_script}"; do
        if ! run_as_invoker grep -qxF \
            "RuntimeDirectoryPreserve=restart" "${source_file}"; then
            preserve_state="missing:${source_file##*/}"
            break
        fi
    done
    verify_state "present" "${preserve_state}" \
        "${SUITE_ID}.S16.runtime-directory-preserve.present"
}

# Extracts the sorted RUNNER_* variable names targeted by one metadata
# injector. The source file is read through the invoking-user boundary.
function _metadata_injection_targets {
    local source_file="$1"

    run_as_invoker grep -oE 's/\^declare -g RUNNER_[A-Z_]+=' \
        "${source_file}" 2>/dev/null \
        | grep -oE 'RUNNER_[A-Z_]+' \
        | sort -u
}

# Verifies that both metadata injectors target the same RUNNER_* declaration
# set and that every injected name has a declaration anchor in the runner.
function test_metadata_injection_contract {
    local step="$1"
    local runner_script="${REPO_TOP}/bin/ioc-runner"
    local setup_script="${REPO_TOP}/bin/setup-system-infra.bash"
    local inject_script="${REPO_TOP}/configure/inject-runner-version.bash"
    local setup_set=""
    local inject_set=""
    local anchor_set=""
    local missing=""
    local extracted="empty"

    print_divider
    _log "INFO" "STEP ${step}: Verify Metadata Injection Source Contract"
    print_sub_divider

    setup_set=$(_metadata_injection_targets "${setup_script}" || true)
    inject_set=$(_metadata_injection_targets "${inject_script}" || true)
    anchor_set=$(run_as_invoker grep -oE '^declare -g RUNNER_[A-Z_]+=' \
        "${runner_script}" 2>/dev/null \
        | grep -oE 'RUNNER_[A-Z_]+' \
        | sort -u || true)

    if [[ -n "${setup_set}" && -n "${inject_set}" ]]; then
        extracted="nonempty"
    fi
    verify_state "nonempty" "${extracted}" \
        "${SUITE_ID}.S17.metadata.targets-extracted"

    if [[ "${setup_set}" != "${inject_set}" ]]; then
        printf "%b%s%b\n" "${YELLOW}" \
            "  injector drift (setup < > inject):" "${NC}"
        diff <(printf '%s\n' "${setup_set}") \
            <(printf '%s\n' "${inject_set}") || true
    fi
    verify_state "${setup_set}" "${inject_set}" \
        "${SUITE_ID}.S17.metadata.injectors-agree"

    missing=$(comm -23 \
        <(printf '%s\n' "${setup_set}") \
        <(printf '%s\n' "${anchor_set}"))
    if [[ -n "${missing}" ]]; then
        printf "%b%s%b\n%s\n" "${YELLOW}" \
            "  injected names with no declaration anchor:" "${NC}" \
            "${missing}"
    fi
    verify_state "" "${missing}" \
        "${SUITE_ID}.S17.metadata.declaration-anchors-present"
}

# Verifies that capability probes in the runner do not pipe helper usage output
# directly into grep -q. Under pipefail, a helper usage exit or an early-match
# SIGPIPE can otherwise turn a supported capability into a false negative.
function test_pipefail_help_probe_contract {
    local step="$1"
    local runner_script="${REPO_TOP}/bin/ioc-runner"
    local hits=""

    print_divider
    _log "INFO" "STEP ${step}: Verify Pipefail Help-Probe Source Contract"
    print_sub_divider

    hits=$(run_as_invoker grep -cE -- \
        '-h 2>&1 \| grep -q' "${runner_script}" || true)
    verify_state "0" "${hits}" \
        "${SUITE_ID}.S18.pipefail-help-probe-pattern.absent"
}

# Verifies that the runner IOC-name source contract and the regex-form sudoers
# source contract use the same character classes and maximum length. The glob
# fallback for sudo versions older than 1.9.10 is intentionally outside this
# parity contract.
function test_ioc_name_source_contract {
    local step="$1"
    local runner_script="${REPO_TOP}/bin/ioc-runner"
    local setup_script="${REPO_TOP}/bin/setup-system-infra.bash"
    local eres=""
    local ere_count=0
    local unique_ere=""
    local unique_count=0
    local runner_regex=""
    local runner_length=""
    local first_class=""
    local remaining_class=""
    local expected_ere=""
    local normalized_expected_ere=""
    local normalized_unique_ere=""

    print_divider
    _log "INFO" "STEP ${step}: Verify IOC-Name Source Contract"
    print_sub_divider

    eres=$(run_as_invoker grep -oE \
        'epics-@\[[^]]*\]\[[^]]*\]\{[0-9]+,[0-9]+\}[\\]+\.service[\\]\$' \
        "${setup_script}" || true)
    ere_count=$(printf '%s\n' "${eres}" | grep -c . || true)
    verify_state "6" "${ere_count}" \
        "${SUITE_ID}.S19.sudoers-regex.count-six"

    unique_ere=$(printf '%s\n' "${eres}" | sort -u)
    unique_count=$(printf '%s\n' "${unique_ere}" | grep -c . || true)
    verify_state "1" "${unique_count}" \
        "${SUITE_ID}.S19.sudoers-regex.identical"

    runner_regex=$(run_as_invoker grep -oE \
        '\^\[[^]]*\]\[[^]]*\]\*\$' "${runner_script}" \
        | head -n1 || true)
    # The sed expression must preserve the literal ${#name} source text.
    # shellcheck disable=SC2016
    runner_length=$(run_as_invoker sed -n \
        's/.*"\${#name}" -le \([0-9]\+\).*/\1/p' \
        "${runner_script}" | head -n1 || true)
    verify_state "64" "${runner_length}" \
        "${SUITE_ID}.S19.runner-name.max-length-64"

    first_class=$(printf '%s\n' "${runner_regex}" \
        | sed -n 's/^\^\(\[[^]]*\]\)\(\[[^]]*\]\)\*\$/\1/p')
    remaining_class=$(printf '%s\n' "${runner_regex}" \
        | sed -n 's/^\^\(\[[^]]*\]\)\(\[[^]]*\]\)\*\$/\2/p')
    if [[ -n "${first_class}" && -n "${remaining_class}" \
          && "${runner_length}" =~ ^[0-9]+$ \
          && ${runner_length} -gt 0 ]]; then
        printf -v expected_ere 'epics-@%s%s{0,%d}\\\\.service\\$' \
            "${first_class}" "${remaining_class}" \
            "$((runner_length - 1))"
    fi
    # POSIX ERE character-class order is not semantic. Normalize only the
    # equivalent ASCII letter-range order before comparing every other byte.
    normalized_expected_ere="${expected_ere//a-zA-Z/A-Za-z}"
    normalized_unique_ere="${unique_ere//a-zA-Z/A-Za-z}"
    verify_state "${normalized_expected_ere}" "${normalized_unique_ere}" \
        "${SUITE_ID}.S19.runner-sudoers-name-contracts.agree"
}

# Extracts one double-quoted global declaration from runner source through the
# invoking-user boundary. The runner cannot be sourced because it dispatches at
# module load time.
function _runner_quoted_global {
    local variable_name="$1"
    local runner_script="$2"
    local declaration=""

    declaration=$(run_as_invoker grep -m1 -E \
        "^declare -g ${variable_name}=\".*\"$" \
        "${runner_script}" || true)
    declaration="${declaration#*\"}"
    declaration="${declaration%\"}"
    printf '%s' "${declaration}"
}

# Evaluates an extracted regex against one contract fixture. This verifies
# source-level pattern membership only; runtime crash behavior remains owned by
# the local lifecycle suite's real softIoc paths.
function _verify_regex_source_fixture {
    local expected="$1"
    local regex="$2"
    local fixture="$3"
    local check_id="$4"
    local actual="nomatch"

    if [[ -n "${regex}" ]] \
       && grep -qiE -- "${regex}" <<< "${fixture}"; then
        actual="match"
    fi
    verify_state "${expected}" "${actual}" "${check_id}"
}

# Verifies base crash-pattern membership and the fatal/ambiguous source split.
# The benign-noise exclusion pipeline is intentionally absent; S21 owns that
# separate source contract.
function test_crash_pattern_source_contract {
    local step="$1"
    local runner_script="${REPO_TOP}/bin/ioc-runner"
    local base_patterns=""
    local fatal_patterns=""
    local ambiguous_patterns=""
    local base_tokens=""
    local union_state="unequal"

    print_divider
    _log "INFO" "STEP ${step}: Verify Crash Pattern Source Contract"
    print_sub_divider

    base_patterns=$(_runner_quoted_global \
        "CRASH_LOG_PATTERNS" "${runner_script}")
    fatal_patterns=$(_runner_quoted_global \
        "CRASH_LOG_PATTERNS_FATAL" "${runner_script}")
    ambiguous_patterns=$(_runner_quoted_global \
        "CRASH_LOG_PATTERNS_AMBIGUOUS" "${runner_script}")

    _verify_regex_source_fixture "match" "${base_patterns}" \
        "ERROR st.cmd line 52: Unbalanced quote." \
        "${SUITE_ID}.S20.pattern-unbalanced-quote"
    _verify_regex_source_fixture "match" "${base_patterns}" \
        "Invalid directory path: /opt/ioc/missing" \
        "${SUITE_ID}.S20.pattern-invalid-directory-path"
    _verify_regex_source_fixture "match" "${base_patterns}" \
        "Can't open db/example.db" \
        "${SUITE_ID}.S20.pattern-can-t-open"
    _verify_regex_source_fixture "match" "${base_patterns}" \
        "iocsh: cannot open '/etc/protocol/foo.proto'" \
        "${SUITE_ID}.S20.pattern-cannot-open"
    _verify_regex_source_fixture "match" "${base_patterns}" \
        "symbol lookup error: undefined symbol: epicsRingNew" \
        "${SUITE_ID}.S20.pattern-undefined-symbol"
    _verify_regex_source_fixture "match" "${base_patterns}" \
        "/opt/ioc/iocBoot/iocX/st.cmd: No such file or directory" \
        "${SUITE_ID}.S20.pattern-no-such-file-or-directory"
    _verify_regex_source_fixture "match" "${base_patterns}" \
        "ERROR: device timeout" \
        "${SUITE_ID}.S20.case-insensitive-error-upper"
    _verify_regex_source_fixture "match" "${base_patterns}" \
        "Error: cannot allocate" \
        "${SUITE_ID}.S20.case-insensitive-error-title"
    _verify_regex_source_fixture "match" "${base_patterns}" \
        "error: nullptr deref" \
        "${SUITE_ID}.S20.case-insensitive-error-lower"
    _verify_regex_source_fixture "match" "${base_patterns}" \
        "FATAL: aborting" \
        "${SUITE_ID}.S20.case-insensitive-fatal-upper"
    _verify_regex_source_fixture "match" "${base_patterns}" \
        "fatal allocation failure" \
        "${SUITE_ID}.S20.case-insensitive-fatal-lower"
    _verify_regex_source_fixture "match" "${base_patterns}" \
        "Segmentation fault (core dumped)" \
        "${SUITE_ID}.S20.regression-segmentation-fault"
    _verify_regex_source_fixture "nomatch" "${base_patterns}" \
        "procServ: Restarting child" \
        "${SUITE_ID}.S20.negative-procserv-child-start-line"
    _verify_regex_source_fixture "nomatch" "${base_patterns}" \
        "iocInit: All initialization complete" \
        "${SUITE_ID}.S20.negative-iocinit-complete-line"
    _verify_regex_source_fixture "nomatch" "${base_patterns}" \
        "## EPICS R7.0.7 banner" \
        "${SUITE_ID}.S20.negative-epics-banner"
    _verify_regex_source_fixture "nomatch" "${base_patterns}" \
        "Starting iocsh.bash" \
        "${SUITE_ID}.S20.negative-startup-banner"

    base_tokens="${base_patterns#\(}"
    base_tokens="${base_tokens%\)}"
    if [[ "$(printf '%s' "${base_tokens}" | tr '|' '\n' | sort)" \
          == "$(printf '%s' "${fatal_patterns}|${ambiguous_patterns}" \
              | tr '|' '\n' | sort)" ]]; then
        union_state="equal"
    fi
    verify_state "equal" "${union_state}" \
        "${SUITE_ID}.S20.base-patterns.equal-subset-union"

    _verify_regex_source_fixture "match" "${fatal_patterns}" \
        "FATAL: aborting" \
        "${SUITE_ID}.S20.subset-fatal-is-fatal"
    _verify_regex_source_fixture "match" "${fatal_patterns}" \
        "undefined symbol: epicsRingNew" \
        "${SUITE_ID}.S20.subset-undefined-symbol-is-fatal"
    _verify_regex_source_fixture "match" "${ambiguous_patterns}" \
        "Can't open db/example.db" \
        "${SUITE_ID}.S20.subset-can-t-open-is-ambiguous"
    _verify_regex_source_fixture "match" "${ambiguous_patterns}" \
        "ERROR: device timeout" \
        "${SUITE_ID}.S20.subset-error-is-ambiguous"
    _verify_regex_source_fixture "match" "${ambiguous_patterns}" \
        "config: Invalid directory path, ignored" \
        "${SUITE_ID}.S20.subset-invalid-directory-path-is-ambiguous"
}

# Verifies the benign-history exclusion as source contracts only. Real startup
# outcomes remain owned by local lifecycle S30 through shipped softIoc paths.
function test_crash_exclusion_source_contract {
    local step="$1"
    local runner_script="${REPO_TOP}/bin/ioc-runner"
    local base_patterns=""
    local exclude_patterns=""
    local nonempty_state="empty"
    local compile_state="invalid"
    local compile_exit=2
    local writing_state="nomatch"
    local filter_line=""
    local fatal_scan_line=""
    local corroborating_scan_line=""
    local filter_needle=""
    local fatal_scan_needle=""
    local corroborating_scan_needle=""
    local order_state="invalid"
    local benign_loading=$'\033[31;1mERROR\033[0m Permission denied (13) loading \'/opt/epics-iocs/demo/iocBoot/iocdemo/.iocsh_history\''
    local benign_writing=$'\033[31;1mERROR\033[0m Permission denied (13) writing \'.iocsh_history\''

    print_divider
    _log "INFO" "STEP ${step}: Verify Crash Exclusion Source Contract"
    print_sub_divider

    base_patterns=$(_runner_quoted_global \
        "CRASH_LOG_PATTERNS" "${runner_script}")
    exclude_patterns=$(_runner_quoted_global \
        "CRASH_LOG_EXCLUDE_PATTERNS" "${runner_script}")

    if [[ -n "${exclude_patterns}" ]]; then
        nonempty_state="nonempty"
    fi
    verify_state "nonempty" "${nonempty_state}" \
        "${SUITE_ID}.S21.exclude-pattern.nonempty"

    if grep -E -- "${exclude_patterns}" </dev/null >/dev/null 2>&1; then
        compile_exit=0
    else
        compile_exit=$?
    fi
    if [[ -n "${exclude_patterns}" && ${compile_exit} -le 1 ]]; then
        compile_state="valid"
    fi
    verify_state "valid" "${compile_state}" \
        "${SUITE_ID}.S21.exclude-pattern.compiles"

    _verify_regex_source_fixture "match" "${base_patterns}" \
        "${benign_loading}" \
        "${SUITE_ID}.S21.history-load.matches-base-patterns"

    if [[ -n "${exclude_patterns}" ]] \
       && grep -qE -- "${exclude_patterns}" <<< "${benign_writing}"; then
        writing_state="match"
    fi
    verify_state "match" "${writing_state}" \
        "${SUITE_ID}.S21.history-write.matches-exclude-pattern"

    filter_needle="filtered=\$(grep -avE -- \"\${CRASH_LOG_EXCLUDE_PATTERNS}\" 2>/dev/null <<< \"\${window}\" || true)"
    fatal_scan_needle="if grep -qaiE -- \"\${CRASH_LOG_PATTERNS_FATAL}\" 2>/dev/null <<< \"\${filtered}\"; then"
    corroborating_scan_needle="if grep -qaiE -- \"\${effective_patterns}\" 2>/dev/null <<< \"\${filtered}\"; then"
    filter_line=$(run_as_invoker grep -nFm1 \
        "${filter_needle}" "${runner_script}" || true)
    fatal_scan_line=$(run_as_invoker grep -nFm1 \
        "${fatal_scan_needle}" "${runner_script}" || true)
    corroborating_scan_line=$(run_as_invoker grep -nFm1 \
        "${corroborating_scan_needle}" "${runner_script}" || true)
    filter_line="${filter_line%%:*}"
    fatal_scan_line="${fatal_scan_line%%:*}"
    corroborating_scan_line="${corroborating_scan_line%%:*}"
    if [[ "${filter_line}" =~ ^[0-9]+$ \
          && "${fatal_scan_line}" =~ ^[0-9]+$ \
          && "${corroborating_scan_line}" =~ ^[0-9]+$ \
          && ${filter_line} -lt ${fatal_scan_line} \
          && ${filter_line} -lt ${corroborating_scan_line} ]]; then
        order_state="valid"
    fi
    verify_state "valid" "${order_state}" \
        "${SUITE_ID}.S21.line-filter.precedes-crash-scans"
}

function run_all_tests {
    initialize_reporting
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
    test_unit_template_contract "S16"
    test_metadata_injection_contract "S17"
    test_pipefail_help_probe_contract "S18"
    test_ioc_name_source_contract "S19"
    test_crash_pattern_source_contract "S20"
    test_crash_exclusion_source_contract "S21"
}

run_all_tests
