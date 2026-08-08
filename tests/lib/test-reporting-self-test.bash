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
        BEHAVIOR direct-inspection "Directly observed installed state"
    report_close_catalog
    report_record system-infra.S01.direct-state PASS
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
    local ledger_mode=""

    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    report_init source-regression subshell system source debian-13 linux-x86_64 "${workspace}"
    register_step_and_check source-regression.P00.subshell INTEGRITY direct-inspection "Subshell ledger state"
    ledger_mode=$(stat -c '%a' -- "${REPORT_LEDGER_FILE}")
    printf 'LEDGER_MODE=%s\n' "${ledger_mode}"
    (report_record source-regression.P00.subshell PASS)
    report_finalize 0
    if [[ -f "${REPORT_LEDGER_FILE}" ]]; then
        printf '%s\n' "LEDGER_PERSISTED=true"
    else
        return 1
    fi
}

function scenario_fixed_command_path {
    local workspace="$1"
    local original_path="${PATH}"
    local empty_path="${workspace}/empty-path"
    local actual_status=0

    mkdir -p -- "${empty_path}"
    # shellcheck source=tests/lib/test-reporting.bash
    source "${REPORTER}"
    PATH="${empty_path}"
    report_init source-regression fixed-path system source debian-13 linux-x86_64 "${workspace}" || actual_status=$?
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
    case "${name}" in
        clean) scenario_clean "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        vector) scenario_vector "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        independent-axes) scenario_independent_axes "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        missing) scenario_missing_state "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        abort) scenario_abort "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        duplicate) scenario_duplicate_state "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        unknown) scenario_unknown_id "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        reason) scenario_missing_reason "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        malformed) scenario_malformed_catalog "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        subshell) scenario_subshell_ledger "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        fixed-path) scenario_fixed_command_path "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        invalid-exit) scenario_invalid_exit "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        duplicate-catalog) scenario_duplicate_catalog "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        late) scenario_late_registration "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        invalid-state) scenario_invalid_state "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        invalid-error-id) scenario_invalid_error_identity "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        unsafe-ledger) scenario_unsafe_ledger_directory "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        concurrent) scenario_concurrent_duplicate "${scenario_workspace}" > "${output_file}" 2>&1 || actual_status=$? ;;
        *) actual_status=99; printf 'Unknown self-test scenario: %s\n' "${name}" > "${output_file}" ;;
    esac
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

run_scenario clean 0
expect_contains "${SELF_TEST_WORKSPACE}/clean.out" "Total Assertions     : 1" "clean: human total"
expect_contains "${SELF_TEST_WORKSPACE}/clean.out" "STEP suite=source-regression run=clean step=S01 pass=0 fail=0 skip=0 na=0 err=0" "clean: zero-check STEP"
expect_contains "${SELF_TEST_WORKSPACE}/clean.out" "SUITE suite=source-regression run=clean scope=system runner=source os=debian-13 arch=linux-x86_64 total=1 pass=1 fail=0 skip=0 na=0 err=0" "clean: final suite vector"
expect_count "${SELF_TEST_WORKSPACE}/clean.out" '^SUITE ' 1 "clean: one SUITE record"
expect_last_line "${SELF_TEST_WORKSPACE}/clean.out" "SUITE suite=source-regression run=clean scope=system runner=source os=debian-13 arch=linux-x86_64 total=1 pass=1 fail=0 skip=0 na=0 err=0" "clean: SUITE is the final reporter record"

run_scenario vector 1
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "Total Assertions     : 5" "vector: human total"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "Passed               : 1" "vector: human pass count"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "Failed               : 1" "vector: human fail count"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "Skipped              : 1" "vector: human skip count"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "Not applicable       : 1" "vector: human NA count"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "Script Errors        : 1" "vector: human script-error count"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "source-regression.P00.skip [PREREQUISITE/direct-inspection] SKIP: missing tool" "vector: human projection fields"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "category=source-regression kind=PREREQUISITE method=direct-inspection state=SKIP reason_b64=bWlzc2luZyB0b29s" "vector: machine projection fields"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "source-regression.P00.fail [REQUIRED/direct-inspection] FAIL: expected failure" "vector: FAIL human projection"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "kind=REQUIRED method=direct-inspection state=FAIL reason_b64=ZXhwZWN0ZWQgZmFpbHVyZQ" "vector: FAIL machine projection"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "source-regression.P00.na [APPLICABILITY/direct-inspection] NA: not applicable" "vector: NA human projection"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "kind=APPLICABILITY method=direct-inspection state=NA reason_b64=bm90IGFwcGxpY2FibGU" "vector: NA machine projection"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "source-regression.P00.error [INTEGRITY/direct-inspection] SCRIPT_ERROR: explicit script error" "vector: SCRIPT_ERROR human projection"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "kind=INTEGRITY method=direct-inspection state=SCRIPT_ERROR reason_b64=ZXhwbGljaXQgc2NyaXB0IGVycm9y" "vector: SCRIPT_ERROR machine projection"
expect_contains "${SELF_TEST_WORKSPACE}/vector.out" "SUITE suite=source-regression run=vector scope=system runner=source os=rocky-8 arch=linux-x86_64 total=5 pass=1 fail=1 skip=1 na=1 err=1" "vector: projections share complete vector"

run_scenario independent-axes 0
expect_contains "${SELF_TEST_WORKSPACE}/independent-axes.out" "kind=BEHAVIOR method=direct-inspection state=PASS" "independent-axes: accepted catalog combination"
expect_contains "${SELF_TEST_WORKSPACE}/independent-axes.out" "SUITE suite=system-infra run=independent-axes scope=system runner=none os=debian-13 arch=linux-x86_64 total=1 pass=1 fail=0 skip=0 na=0 err=0" "independent-axes: complete suite vector"

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
expect_contains "${SELF_TEST_WORKSPACE}/subshell.out" "LEDGER_PERSISTED=true" "subshell: ledger persists through finalization"

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
