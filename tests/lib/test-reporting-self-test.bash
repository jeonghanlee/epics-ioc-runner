#!/usr/bin/env bash
#
# Exercises the shipped reporting library through its public catalog, event,
# finalization, and projection interfaces.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
readonly REPORTER="${SCRIPT_DIR}/test-reporting.bash"

SELF_TEST_TOTAL=0
SELF_TEST_PASSED=0
SELF_TEST_FAILED=0
SELF_TEST_PARENT=""
SELF_TEST_WORKSPACE=""
declare -a SELF_TEST_FAILURES=()

# shellcheck disable=SC2317
function cleanup {
    local rc=$?

    if [[ -n "${SELF_TEST_WORKSPACE}" && -d "${SELF_TEST_WORKSPACE}" ]]; then
        if [[ "${SELF_TEST_WORKSPACE}" != "${SELF_TEST_PARENT}/ioc-runner-report-self-test."* ]]; then
            printf 'Refusing to remove unexpected self-test workspace: %s\n' "${SELF_TEST_WORKSPACE}" >&2
            return 1
        fi
        if (( rc != 0 || SELF_TEST_FAILED > 0 )) || [[ "${KEEP_WORKSPACE:-0}" == "1" ]]; then
            printf 'Self-test workspace retained: %s\n' "${SELF_TEST_WORKSPACE}"
            return
        fi
        rm -rf -- "${SELF_TEST_WORKSPACE}"
    fi
}

function pass {
    local description="$1"

    SELF_TEST_TOTAL=$((SELF_TEST_TOTAL + 1))
    SELF_TEST_PASSED=$((SELF_TEST_PASSED + 1))
    printf '[ PASS ] %s\n' "${description}"
}

function fail {
    local description="$1"
    local expected="$2"
    local actual="$3"

    SELF_TEST_TOTAL=$((SELF_TEST_TOTAL + 1))
    SELF_TEST_FAILED=$((SELF_TEST_FAILED + 1))
    SELF_TEST_FAILURES+=("${description}")
    printf '[ FAIL ] %s\n' "${description}"
    printf '  Expected : %s\n' "${expected}"
    printf '  Actual   : %s\n' "${actual}"
}

function expect_status {
    local expected="$1"
    local actual="$2"
    local description="$3"

    if [[ "${actual}" == "${expected}" ]]; then
        pass "${description}"
    else
        fail "${description}" "${expected}" "${actual}"
    fi
}

function expect_contains {
    local file="$1"
    local expected="$2"
    local description="$3"

    if grep -Fq -- "${expected}" "${file}"; then
        pass "${description}"
    else
        fail "${description}" "contains ${expected}" "not found"
    fi
}

function expect_not_contains {
    local file="$1"
    local rejected="$2"
    local description="$3"

    if grep -Fq -- "${rejected}" "${file}"; then
        fail "${description}" "does not contain ${rejected}" "found"
    else
        pass "${description}"
    fi
}

function expect_count {
    local file="$1"
    local pattern="$2"
    local expected="$3"
    local description="$4"
    local actual=0

    actual=$(grep -cE -- "${pattern}" "${file}" || true)
    if [[ "${actual}" == "${expected}" ]]; then
        pass "${description}"
    else
        fail "${description}" "${expected}" "${actual}"
    fi
}

function expect_last_line {
    local file="$1"
    local expected="$2"
    local description="$3"
    local actual=""

    actual=$(tail -n 1 -- "${file}")
    if [[ "${actual}" == "${expected}" ]]; then
        pass "${description}"
    else
        fail "${description}" "${expected}" "${actual}"
    fi
}

function decode_b64url {
    local value="$1"
    local padding=""
    local standard=""

    standard="${value//-/+}"
    standard="${standard//_/\/}"
    case $((${#standard} % 4)) in
        0) padding="" ;;
        2) padding="==" ;;
        3) padding="=" ;;
        *) return 1 ;;
    esac
    printf '%s%s' "${standard}" "${padding}" | base64 -d
}

function verify_split_projection {
    local machine_file="$1"
    local human_file="$2"
    local line=""
    local check_id=""
    local check_kind=""
    local test_method=""
    local state=""
    local reason_b64=""
    local reason=""
    local total=""
    local pass_count=""
    local fail_count=""
    local skip_count=""
    local na_count=""
    local error_count=""
    local suite_state=""
    local non_pass_count=0

    while IFS= read -r line || [[ -n "${line:-}" ]]; do
        if [[ "${line}" =~ ^TEST[[:space:]].*[[:space:]]id=([^[:space:]]+)[[:space:]].*[[:space:]]kind=([^[:space:]]+)[[:space:]]method=([^[:space:]]+)[[:space:]]state=(FAIL|SKIP|NA|SCRIPT_ERROR)[[:space:]]reason_b64=([^[:space:]]+)$ ]]; then
            check_id="${BASH_REMATCH[1]}"
            check_kind="${BASH_REMATCH[2]}"
            test_method="${BASH_REMATCH[3]}"
            state="${BASH_REMATCH[4]}"
            reason_b64="${BASH_REMATCH[5]}"
            reason=$(decode_b64url "${reason_b64}") || {
                fail "split projection: ${check_id} reason decodes" "valid base64url" "${reason_b64}"
                continue
            }
            expect_contains "${human_file}" \
                "${check_id} [${check_kind}/${test_method}] ${state}: ${reason}" \
                "split projection: ${check_id} common fields agree"
            non_pass_count=$((non_pass_count + 1))
        fi
        if [[ "${line}" =~ ^SUITE[[:space:]].*[[:space:]]total=([0-9]+)[[:space:]]pass=([0-9]+)[[:space:]]fail=([0-9]+)[[:space:]]skip=([0-9]+)[[:space:]]na=([0-9]+)[[:space:]]err=([0-9]+)[[:space:]]state=(PASS|FAIL)$ ]]; then
            total="${BASH_REMATCH[1]}"
            pass_count="${BASH_REMATCH[2]}"
            fail_count="${BASH_REMATCH[3]}"
            skip_count="${BASH_REMATCH[4]}"
            na_count="${BASH_REMATCH[5]}"
            error_count="${BASH_REMATCH[6]}"
            suite_state="${BASH_REMATCH[7]}"
        fi
    done < "${machine_file}"

    expect_status 4 "${non_pass_count}" "split projection: every non-PASS record compared"
    expect_contains "${human_file}" "Total Assertions     : ${total}" "split projection: total agrees"
    expect_contains "${human_file}" "Passed               : ${pass_count}" "split projection: pass agrees"
    expect_contains "${human_file}" "Failed               : ${fail_count}" "split projection: fail agrees"
    expect_contains "${human_file}" "Skipped              : ${skip_count}" "split projection: skip agrees"
    expect_contains "${human_file}" "Not applicable       : ${na_count}" "split projection: NA agrees"
    expect_contains "${human_file}" "Script Errors        : ${error_count}" "split projection: error agrees"
    expect_contains "${human_file}" "Suite State          : ${suite_state}" "split projection: suite state agrees"
}

function register_step_and_check {
    local check_id="$1"
    local check_kind="$2"
    local test_method="$3"
    local description="$4"

    report_register_step P00 "Reporter self-test preflight"
    report_register_check "${check_id}" P00 source-regression "${check_kind}" "${test_method}" "${description}"
    report_close_catalog
}

function scenario_clean {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression clean system source debian-13 linux-x86_64 "${workspace}"
    report_register_step P00 "Reporter self-test preflight"
    report_register_step S01 "Zero-check setup STEP"
    report_register_check source-regression.P00.clean P00 source-regression REQUIRED direct-inspection "Clean reporter state"
    report_close_catalog
    report_record source-regression.P00.clean PASS
    report_finalize 0
}

function scenario_requested_exit_after_pass {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression requested-exit system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.requested-exit INTEGRITY direct-inspection \
        "Completed check before suite execution failure"
    report_record source-regression.P00.requested-exit PASS
    report_finalize 7
}

function scenario_vector {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression vector system source rocky-8 linux-x86_64 "${workspace}"
    report_register_step P00 "Reporter state vector"
    report_register_check source-regression.P00.pass P00 source-regression REQUIRED direct-inspection "PASS state"
    report_register_check source-regression.P00.fail P00 source-regression REQUIRED direct-inspection "FAIL state"
    report_register_check source-regression.P00.skip P00 source-regression PREREQUISITE direct-inspection "SKIP state"
    report_register_check source-regression.P00.na P00 source-regression APPLICABILITY direct-inspection "NA state"
    report_register_check source-regression.P00.error P00 source-regression INTEGRITY direct-inspection "SCRIPT_ERROR state"
    report_close_catalog
    report_record source-regression.P00.pass PASS
    report_record source-regression.P00.fail FAIL "expected failure"
    report_record source-regression.P00.skip SKIP "missing tool"
    report_record source-regression.P00.na NA "not applicable"
    report_record source-regression.P00.error SCRIPT_ERROR "explicit script error"
    report_finalize 0
}

function scenario_independent_axes {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init system-infra independent-axes system none debian-13 linux-x86_64 "${workspace}"
    report_register_step S01 "Independent catalog dimensions"
    report_register_check system-infra.S01.direct-state S01 installed-conformance \
        BEHAVIOR direct-inspection "Directly observed installed state only"
    report_close_catalog
    report_record system-infra.S01.direct-state PASS
    report_finalize 0
}

function scenario_suite_dimension_matrix {
    local workspace="$1"
    local suite=""
    local scope=""
    local runner=""
    local category=""
    local specification=""
    local scenario_workspace=""
    local check_id=""
    local index=0
    local -a dimensions=(
        "error-handling none source error-contract"
        "local-lifecycle local source lifecycle-behavior"
        "local-lifecycle local installed lifecycle-behavior"
        "source-regression system source source-regression"
        "system-infra system none installed-conformance"
        "system-lifecycle system source lifecycle-behavior"
        "system-lifecycle system installed lifecycle-behavior"
    )

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    for specification in "${dimensions[@]}"; do
        read -r suite scope runner category <<< "${specification}"
        scenario_workspace="${workspace}/accepted-${index}"
        check_id="${suite}.P00.dimension-${index}"
        mkdir -m 0700 -- "${scenario_workspace}"
        report_init "${suite}" "dimension-${index}" "${scope}" "${runner}" host unknown "${scenario_workspace}"
        report_register_step P00 "Suite dimension matrix"
        report_register_check "${check_id}" P00 "${category}" REQUIRED direct-inspection "Accepted suite dimensions"
        report_close_catalog
        report_record "${check_id}" PASS
        report_finalize 0
        index=$((index + 1))
    done

    if report_init error-handling invalid-error-dimensions system installed host unknown "${workspace}"; then
        return 1
    fi
    if report_init system-infra invalid-infra-dimensions system source host unknown "${workspace}"; then
        return 1
    fi
}

function scenario_check_identity_step {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression check-identity system source debian-13 linux-x86_64 "${workspace}"
    report_register_step P00 "Check identity STEP"
    report_register_check source-regression.S99.mismatch P00 source-regression REQUIRED direct-inspection \
        "Mismatched STEP segment" || true
    report_register_check source-regression.missing-step P00 source-regression REQUIRED direct-inspection \
        "Missing STEP segment" || true
    report_register_check source-regression.S0A.malformed P00 source-regression REQUIRED direct-inspection \
        "Malformed STEP segment" || true
    report_register_check source-regression.P00. P00 source-regression REQUIRED direct-inspection \
        "Empty check key" || true
    report_close_catalog || true
    report_finalize 0
}

function scenario_missing_state {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression missing system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.missing INTEGRITY direct-inspection "Missing state"
    report_finalize 0
}

function scenario_abort {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression abort system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.abort INTEGRITY direct-inspection "Abort state"
    report_finalize 7
}

function scenario_duplicate_state {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression duplicate system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.duplicate INTEGRITY direct-inspection "Duplicate state"
    report_record source-regression.P00.duplicate PASS
    report_record source-regression.P00.duplicate PASS || true
    report_finalize 0
}

function scenario_unknown_id {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression unknown system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.known INTEGRITY direct-inspection "Known state"
    report_record source-regression.P00.known PASS
    report_record source-regression.P00.unknown PASS || true
    report_finalize 0
}

function scenario_missing_reason {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression reason system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.reason INTEGRITY direct-inspection "Missing reason"
    report_record source-regression.P00.reason FAIL "" || true
    report_finalize 0
}

function scenario_malformed_catalog {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression malformed system source debian-13 linux-x86_64 "${workspace}"
    report_register_step P00 "Malformed catalog"
    report_register_check source-regression.P00.malformed P00 installed-conformance REQUIRED direct-inspection "Wrong category" || true
    report_close_catalog || true
    report_finalize 0
}

function scenario_subshell_ledger {
    local workspace="$1"
    local ledger_file=""
    local ledger_mode=""

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression subshell system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.subshell INTEGRITY direct-inspection "Subshell ledger state"
    ledger_file="${REPORT_LEDGER_FILE}"
    ledger_mode=$(stat -c '%a' -- "${REPORT_LEDGER_FILE}")
    printf 'LEDGER_MODE=%s\n' "${ledger_mode}"
    (report_record source-regression.P00.subshell PASS)
    report_finalize 0
    if [[ ! -e "${ledger_file}" && ! -e "${workspace}" ]]; then
        printf '%s\n' "REPORTER_WORKSPACE_REMOVED=true"
    else
        return 1
    fi
}

function scenario_reporter_cleanup_failure {
    local workspace="$1"
    local cleanup_blocker="${workspace}/cleanup-blocker"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression cleanup-failure system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.cleanup-failure INTEGRITY direct-inspection \
        "Completed check before reporter workspace cleanup"
    report_record source-regression.P00.cleanup-failure PASS
    printf '%s\n' "outer filesystem cleanup blocker" > "${cleanup_blocker}"
    report_finalize 0
}

function scenario_fixed_command_path {
    local workspace="$1"
    local original_path="${PATH}"
    local empty_path="${workspace}/empty-path"
    local report_workspace="${workspace}/report"
    local actual_status=0

    mkdir -p -- "${empty_path}"
    mkdir -m 0700 -- "${report_workspace}"
    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    PATH="${empty_path}"
    report_init source-regression fixed-path system source debian-13 linux-x86_64 \
        "${report_workspace}" || actual_status=$?
    if (( actual_status == 0 )); then
        register_step_and_check source-regression.P00.fixed-path INTEGRITY direct-inspection "Fixed command path"
        report_record source-regression.P00.fixed-path FAIL "encoded through fixed path"
        report_finalize 0 || actual_status=$?
    fi
    PATH="${original_path}"
    return "${actual_status}"
}

function scenario_invalid_exit {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression invalid-exit system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.invalid-exit INTEGRITY direct-inspection "Invalid exit status"
    report_record source-regression.P00.invalid-exit PASS
    report_finalize invalid
}

function scenario_duplicate_catalog {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression duplicate-catalog system source debian-13 linux-x86_64 "${workspace}"
    report_register_step P00 "Duplicate catalog"
    report_register_check source-regression.P00.duplicate-catalog P00 source-regression INTEGRITY direct-inspection "Duplicate catalog"
    report_register_check source-regression.P00.duplicate-catalog P00 source-regression INTEGRITY direct-inspection "Duplicate catalog" || true
    report_close_catalog || true
    report_finalize 0
}

function scenario_late_registration {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression late system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.late INTEGRITY direct-inspection "Late registration"
    report_register_step S01 "Late STEP" || true
    report_finalize 0
}

function scenario_invalid_state {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression invalid-state system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.invalid-state INTEGRITY direct-inspection "Invalid state"
    report_record source-regression.P00.invalid-state INVALID || true
    report_finalize 0
}

function scenario_invalid_error_identity {
    local workspace="$1"

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression invalid-error-id system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.known INTEGRITY direct-inspection "Known state"
    report_record source-regression.P00.known PASS
    report_record $'source-regression.P00.unknown\ninjected' PASS || true
    report_finalize 0
}

function scenario_unsafe_ledger_directory {
    local workspace="$1"
    local unsafe_directory="${workspace}/unsafe"

    mkdir -p -- "${unsafe_directory}"
    chmod 0777 -- "${unsafe_directory}"
    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression unsafe-ledger system source debian-13 linux-x86_64 "${unsafe_directory}"
}

function scenario_concurrent_duplicate {
    local workspace="$1"
    local first_pid=0
    local second_pid=0

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression concurrent system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.concurrent INTEGRITY direct-inspection "Concurrent duplicate state"
    (report_record source-regression.P00.concurrent PASS) &
    first_pid=$!
    (report_record source-regression.P00.concurrent PASS) &
    second_pid=$!
    wait "${first_pid}" || true
    wait "${second_pid}" || true
    report_finalize 0
}

function run_scenario {
    local name="$1"
    local expected_status="$2"
    local output_file="${SELF_TEST_WORKSPACE}/${name}.out"
    local scenario_workspace="${SELF_TEST_WORKSPACE}/${name}"
    local actual_status=0

    mkdir -m 0700 -- "${scenario_workspace}"
    (
        REPORT_MACHINE_OUTPUT=1
        case "${name}" in
            clean) scenario_clean "${scenario_workspace}" ;;
            requested-exit) scenario_requested_exit_after_pass "${scenario_workspace}" ;;
            vector) scenario_vector "${scenario_workspace}" ;;
            independent-axes) scenario_independent_axes "${scenario_workspace}" ;;
            dimension-matrix) scenario_suite_dimension_matrix "${scenario_workspace}" ;;
            check-identity) scenario_check_identity_step "${scenario_workspace}" ;;
            missing) scenario_missing_state "${scenario_workspace}" ;;
            abort) scenario_abort "${scenario_workspace}" ;;
            duplicate) scenario_duplicate_state "${scenario_workspace}" ;;
            unknown) scenario_unknown_id "${scenario_workspace}" ;;
            reason) scenario_missing_reason "${scenario_workspace}" ;;
            malformed) scenario_malformed_catalog "${scenario_workspace}" ;;
            subshell) scenario_subshell_ledger "${scenario_workspace}" ;;
            cleanup-failure) scenario_reporter_cleanup_failure "${scenario_workspace}" ;;
            fixed-path) scenario_fixed_command_path "${scenario_workspace}" ;;
            invalid-exit) scenario_invalid_exit "${scenario_workspace}" ;;
            duplicate-catalog) scenario_duplicate_catalog "${scenario_workspace}" ;;
            late) scenario_late_registration "${scenario_workspace}" ;;
            invalid-state) scenario_invalid_state "${scenario_workspace}" ;;
            invalid-error-id) scenario_invalid_error_identity "${scenario_workspace}" ;;
            unsafe-ledger) scenario_unsafe_ledger_directory "${scenario_workspace}" ;;
            concurrent) scenario_concurrent_duplicate "${scenario_workspace}" ;;
            *) printf 'Unknown self-test scenario: %s\n' "${name}"; exit 99 ;;
        esac
    ) > "${output_file}" 2>&1 || actual_status=$?
    expect_status "${expected_status}" "${actual_status}" "${name}: exit status"
}

function print_summary {
    local detail=""

    printf '%s\n' ""
    printf '%s\n' "===================================================================================================="
    printf '%s\n' "REPORTING LIBRARY SELF-TEST SUMMARY"
    printf '%s\n' "===================================================================================================="
    printf '  %-20s : %d\n' "Total Assertions" "${SELF_TEST_TOTAL}"
    printf '  %-20s : %d\n' "Passed" "${SELF_TEST_PASSED}"
    printf '  %-20s : %d\n' "Failed" "${SELF_TEST_FAILED}"
    if (( SELF_TEST_FAILED > 0 )); then
        printf '%s\n' ""
        printf '%s\n' "--- [ FAILED ASSERTIONS ] ---"
        for detail in "${SELF_TEST_FAILURES[@]}"; do
            printf '  * %s\n' "${detail}"
        done
    fi
    printf '%s\n' "===================================================================================================="
}

trap cleanup EXIT

SELF_TEST_PARENT=$(cd -- "${TMPDIR:-/tmp}" && pwd -P)
readonly SELF_TEST_PARENT
SELF_TEST_WORKSPACE=$(mktemp -d "${SELF_TEST_PARENT}/ioc-runner-report-self-test.XXXXXX")

mkdir -m 0700 -- "${SELF_TEST_WORKSPACE}/split-vector"
split_status=0
(
    REPORT_MACHINE_OUTPUT=1
    scenario_vector "${SELF_TEST_WORKSPACE}/split-vector"
) > "${SELF_TEST_WORKSPACE}/split-vector.machine" \
  2> "${SELF_TEST_WORKSPACE}/split-vector.human" || split_status=$?
expect_status 1 "${split_status}" "split projection: exit status"
expect_count "${SELF_TEST_WORKSPACE}/split-vector.machine" '^(TEST|STEP|SUITE) ' 7 \
    "split projection: machine output contains only complete record block"
expect_not_contains "${SELF_TEST_WORKSPACE}/split-vector.machine" "TEST SUMMARY" \
    "split projection: machine output excludes human summary"
verify_split_projection \
    "${SELF_TEST_WORKSPACE}/split-vector.machine" \
    "${SELF_TEST_WORKSPACE}/split-vector.human"

mkdir -m 0700 -- "${SELF_TEST_WORKSPACE}/default-mode"
default_status=0
(
    REPORT_MACHINE_OUTPUT=0
    scenario_clean "${SELF_TEST_WORKSPACE}/default-mode"
) > "${SELF_TEST_WORKSPACE}/default-mode.out" \
  2> "${SELF_TEST_WORKSPACE}/default-mode.err" || default_status=$?
expect_status 0 "${default_status}" "default mode: exit status"
expect_contains "${SELF_TEST_WORKSPACE}/default-mode.out" "source-regression TEST SUMMARY" \
    "default mode: human output remains on standard output"
expect_count "${SELF_TEST_WORKSPACE}/default-mode.out" '^(TEST|STEP|SUITE) ' 0 \
    "default mode: no execution records on standard output"

invalid_mode_status=0
(
    REPORT_MACHINE_OUTPUT=invalid
    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
) > "${SELF_TEST_WORKSPACE}/invalid-mode.out" \
  2> "${SELF_TEST_WORKSPACE}/invalid-mode.err" || invalid_mode_status=$?
expect_status 1 "${invalid_mode_status}" "invalid mode: source fails"
expect_contains "${SELF_TEST_WORKSPACE}/invalid-mode.err" \
    "REPORT_MACHINE_OUTPUT must be 0, 1, or unset" \
    "invalid mode: diagnostic identifies the contract"
expect_count "${SELF_TEST_WORKSPACE}/invalid-mode.out" '^(TEST|STEP|SUITE) ' 0 \
    "invalid mode: no valid execution records"

catalog_status=0
REPORT_CATALOG_ONLY=1 REPORT_MACHINE_OUTPUT=1 \
    bash "${SCRIPT_DIR}/../test-source-regression.bash" \
    > "${SELF_TEST_WORKSPACE}/catalog-precedence.out" \
    2> "${SELF_TEST_WORKSPACE}/catalog-precedence.err" || catalog_status=$?
expect_status 0 "${catalog_status}" "catalog precedence: real producer exit status"
expect_count "${SELF_TEST_WORKSPACE}/catalog-precedence.out" '^CATALOG ' 1 \
    "catalog precedence: exactly one catalog record"
expect_count "${SELF_TEST_WORKSPACE}/catalog-precedence.out" '^(TEST|STEP|SUITE) ' 0 \
    "catalog precedence: no execution records"
expect_last_line "${SELF_TEST_WORKSPACE}/catalog-precedence.out" \
    "CATALOG suite=source-regression checks=128 steps=20 state=PASS" \
    "catalog precedence: exact standard-output contract"

run_scenario clean 0
expect_contains "${SELF_TEST_WORKSPACE}/clean.out" "Total Assertions     : 1" "clean: human total"
expect_contains "${SELF_TEST_WORKSPACE}/clean.out" "Suite State          : PASS" "clean: human suite state"
expect_contains "${SELF_TEST_WORKSPACE}/clean.out" "STEP suite=source-regression run=clean step=S01 pass=0 fail=0 skip=0 na=0 err=0" "clean: zero-check STEP"
expect_contains "${SELF_TEST_WORKSPACE}/clean.out" "SUITE suite=source-regression run=clean scope=system runner=source os=debian-13 arch=linux-x86_64 total=1 pass=1 fail=0 skip=0 na=0 err=0 state=PASS" "clean: final suite vector"
expect_count "${SELF_TEST_WORKSPACE}/clean.out" '^SUITE ' 1 "clean: one SUITE record"
expect_last_line "${SELF_TEST_WORKSPACE}/clean.out" "SUITE suite=source-regression run=clean scope=system runner=source os=debian-13 arch=linux-x86_64 total=1 pass=1 fail=0 skip=0 na=0 err=0 state=PASS" "clean: SUITE is the final reporter record"

run_scenario requested-exit 1
expect_contains "${SELF_TEST_WORKSPACE}/requested-exit.out" "Passed               : 1" "requested-exit: check vector remains PASS"
expect_contains "${SELF_TEST_WORKSPACE}/requested-exit.out" "Suite State          : FAIL" "requested-exit: human suite state is FAIL"
expect_last_line "${SELF_TEST_WORKSPACE}/requested-exit.out" "SUITE suite=source-regression run=requested-exit scope=system runner=source os=debian-13 arch=linux-x86_64 total=1 pass=1 fail=0 skip=0 na=0 err=0 state=FAIL" "requested-exit: final state matches return status"

run_scenario vector 1
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "Total Assertions     : 5" "vector: human total"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "Passed               : 1" "vector: human pass count"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "Failed               : 1" "vector: human fail count"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "Skipped              : 1" "vector: human skip count"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "Not applicable       : 1" "vector: human NA count"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "Script Errors        : 1" "vector: human script-error count"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "Suite State          : FAIL" "vector: human suite state"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "source-regression.P00.skip [PREREQUISITE/direct-inspection] SKIP: missing tool" "vector: human projection fields"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "category=source-regression kind=PREREQUISITE method=direct-inspection state=SKIP reason_b64=bWlzc2luZyB0b29s" "vector: machine projection fields"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "source-regression.P00.fail [REQUIRED/direct-inspection] FAIL: expected failure" "vector: FAIL human projection"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "kind=REQUIRED method=direct-inspection state=FAIL reason_b64=ZXhwZWN0ZWQgZmFpbHVyZQ" "vector: FAIL machine projection"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "source-regression.P00.na [APPLICABILITY/direct-inspection] NA: not applicable" "vector: NA human projection"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "kind=APPLICABILITY method=direct-inspection state=NA reason_b64=bm90IGFwcGxpY2FibGU" "vector: NA machine projection"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "source-regression.P00.error [INTEGRITY/direct-inspection] SCRIPT_ERROR: explicit script error" "vector: SCRIPT_ERROR human projection"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "kind=INTEGRITY method=direct-inspection state=SCRIPT_ERROR reason_b64=ZXhwbGljaXQgc2NyaXB0IGVycm9y" "vector: SCRIPT_ERROR machine projection"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "SUITE suite=source-regression run=vector scope=system runner=source os=rocky-8 arch=linux-x86_64 total=5 pass=1 fail=1 skip=1 na=1 err=1 state=FAIL" "vector: projections share complete vector"

run_scenario independent-axes 0
expect_contains "${SELF_TEST_WORKSPACE}/independent-axes.out" "kind=BEHAVIOR method=direct-inspection state=PASS" "independent-axes: state-only BEHAVIOR claim accepted"
expect_contains "${SELF_TEST_WORKSPACE}/independent-axes.out" "SUITE suite=system-infra run=independent-axes scope=system runner=none os=debian-13 arch=linux-x86_64 total=1 pass=1 fail=0 skip=0 na=0 err=0 state=PASS" "independent-axes: complete suite vector"

run_scenario dimension-matrix 0
expect_count "${SELF_TEST_WORKSPACE}/dimension-matrix.out" '^SUITE ' 7 "dimension-matrix: all accepted combinations finalize"
expect_contains "${SELF_TEST_WORKSPACE}/dimension-matrix.out" \
    "unsupported scope/runner combination for error-handling: scope=system runner=installed" \
    "dimension-matrix: invalid error-handling combination rejected"
expect_contains "${SELF_TEST_WORKSPACE}/dimension-matrix.out" \
    "unsupported scope/runner combination for system-infra: scope=system runner=source" \
    "dimension-matrix: invalid system-infra combination rejected"

run_scenario check-identity 1
expect_count "${SELF_TEST_WORKSPACE}/check-identity.out" 'invalid check identity:' 4 \
    "check-identity: every malformed identity rejected"
expect_contains "${SELF_TEST_WORKSPACE}/check-identity.out" "source-regression.S99.mismatch" \
    "check-identity: mismatched STEP segment rejected"
expect_contains "${SELF_TEST_WORKSPACE}/check-identity.out" "source-regression.missing-step" \
    "check-identity: missing STEP segment rejected"
expect_contains "${SELF_TEST_WORKSPACE}/check-identity.out" "source-regression.S0A.malformed" \
    "check-identity: malformed STEP segment rejected"
expect_contains "${SELF_TEST_WORKSPACE}/check-identity.out" "source-regression.P00." \
    "check-identity: empty check key rejected"
expect_not_contains "${SELF_TEST_WORKSPACE}/check-identity.out" "SUITE suite=" \
    "check-identity: invalid catalog has no SUITE record"

run_scenario missing 1
expect_contains "${SELF_TEST_WORKSPACE}/missing.out" "state=SCRIPT_ERROR" "missing: unclosed check becomes SCRIPT_ERROR"
expect_not_contains "${SELF_TEST_WORKSPACE}/missing.out" "state=NA" "missing: no synthetic NA"

run_scenario abort 1
expect_contains "${SELF_TEST_WORKSPACE}/abort.out" "SCRIPT_ERROR: suite exited with status 7 before check completed" "abort: requested exit preserved in reason"

run_scenario duplicate 1
expect_count "${SELF_TEST_WORKSPACE}/duplicate.out" '^TEST .*id=source-regression\.P00\.duplicate ' 1 "duplicate: one TEST record"
expect_contains "${SELF_TEST_WORKSPACE}/duplicate.out" "state=SCRIPT_ERROR" "duplicate: known identity becomes SCRIPT_ERROR"

run_scenario unknown 1
expect_contains "${SELF_TEST_WORKSPACE}/unknown.out" "REPORTING ERROR: no valid projection was produced" "unknown: invalid projection diagnostic"
expect_not_contains "${SELF_TEST_WORKSPACE}/unknown.out" "SUITE suite=" "unknown: no valid SUITE record"

run_scenario reason 1
expect_contains "${SELF_TEST_WORKSPACE}/reason.out" "state=SCRIPT_ERROR" "reason: known identity becomes SCRIPT_ERROR"
expect_contains "${SELF_TEST_WORKSPACE}/reason.out" "FAIL requires a one-line reason" "reason: human detail names defect"

run_scenario malformed 1
expect_contains "${SELF_TEST_WORKSPACE}/malformed.out" "REPORTING ERROR: no valid projection was produced" "catalog: invalid metadata diagnostic"
expect_not_contains "${SELF_TEST_WORKSPACE}/malformed.out" "SUITE suite=" "catalog: invalid metadata has no SUITE record"

run_scenario subshell 0
expect_contains "${SELF_TEST_WORKSPACE}/subshell.out" "LEDGER_MODE=600" "subshell: ledger has owner-only permissions"
expect_contains "${SELF_TEST_WORKSPACE}/subshell.out" "state=PASS" "subshell: child event reaches parent finalizer"
expect_contains "${SELF_TEST_WORKSPACE}/subshell.out" "REPORTER_WORKSPACE_REMOVED=true" "subshell: reporter workspace removed before return"

run_scenario cleanup-failure 1
expect_contains "${SELF_TEST_WORKSPACE}/cleanup-failure.out" "failed to remove reporter workspace" "cleanup-failure: cleanup error reported"
expect_contains "${SELF_TEST_WORKSPACE}/cleanup-failure.out" "Suite State          : FAIL" "cleanup-failure: human suite state is FAIL"
expect_last_line "${SELF_TEST_WORKSPACE}/cleanup-failure.out" "SUITE suite=source-regression run=cleanup-failure scope=system runner=source os=debian-13 arch=linux-x86_64 total=1 pass=1 fail=0 skip=0 na=0 err=0 state=FAIL" "cleanup-failure: final state matches return status"

run_scenario fixed-path 1
expect_contains "${SELF_TEST_WORKSPACE}/fixed-path.out" "encoded through fixed path" "fixed-path: reporter ignores caller PATH for helpers"

run_scenario invalid-exit 1
expect_contains "${SELF_TEST_WORKSPACE}/invalid-exit.out" "REPORTING ERROR: invalid suite exit status: invalid" "invalid-exit: malformed status is rejected"
expect_not_contains "${SELF_TEST_WORKSPACE}/invalid-exit.out" "SUITE suite=" "invalid-exit: malformed status has no SUITE record"

run_scenario duplicate-catalog 1
expect_contains "${SELF_TEST_WORKSPACE}/duplicate-catalog.out" "duplicate check registration" "duplicate-catalog: duplicate registration is rejected"
expect_not_contains "${SELF_TEST_WORKSPACE}/duplicate-catalog.out" "SUITE suite=" "duplicate-catalog: invalid catalog has no SUITE record"

run_scenario late 1
expect_contains "${SELF_TEST_WORKSPACE}/late.out" "late STEP registration" "late: registration after close is rejected"
expect_not_contains "${SELF_TEST_WORKSPACE}/late.out" "SUITE suite=" "late: invalid catalog has no SUITE record"

run_scenario invalid-state 1
expect_contains "${SELF_TEST_WORKSPACE}/invalid-state.out" "state=SCRIPT_ERROR" "invalid-state: known identity becomes SCRIPT_ERROR"

run_scenario invalid-error-id 1
expect_contains "${SELF_TEST_WORKSPACE}/invalid-error-id.out" "reporter error input contained invalid text" "invalid-error-id: malformed error input is normalized"
expect_not_contains "${SELF_TEST_WORKSPACE}/invalid-error-id.out" "injected" "invalid-error-id: raw multiline identity is not emitted"
expect_not_contains "${SELF_TEST_WORKSPACE}/invalid-error-id.out" "SUITE suite=" "invalid-error-id: unknown identity has no SUITE record"

run_scenario unsafe-ledger 1
expect_contains "${SELF_TEST_WORKSPACE}/unsafe-ledger.out" "ledger directory is group- or world-writable" "unsafe-ledger: writable directory is rejected"

run_scenario concurrent 1
expect_contains "${SELF_TEST_WORKSPACE}/concurrent.out" "state=SCRIPT_ERROR" "concurrent: duplicate race becomes SCRIPT_ERROR"

print_summary
if (( SELF_TEST_FAILED > 0 )); then
    exit 1
fi
exit 0
