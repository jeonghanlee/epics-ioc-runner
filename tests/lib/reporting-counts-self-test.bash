#!/usr/bin/env bash
#
# Exercises the shipped expected-count parser against valid and invalid CSVs.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
readonly COMMITTED_COUNTS="${SCRIPT_DIR}/../reporting-counts.csv"

# shellcheck source=reporting-counts.bash
source "${SCRIPT_DIR}/reporting-counts.bash"

TEST_TOTAL=0
TEST_PASSED=0
TEST_FAILED=0
TEST_WORKSPACE=""
committed_tsv=""
crlf_tsv=""
declare -a TEST_FAILURES=()

# shellcheck disable=SC2317
function cleanup {
    local rc=$?

    if [[ -n "${TEST_WORKSPACE}" && -d "${TEST_WORKSPACE}" ]]; then
        if [[ "${TEST_WORKSPACE}" != "${TMPDIR:-/tmp}/ioc-runner-counts-self-test."* ]]; then
            printf 'Refusing to remove unexpected self-test workspace: %s\n' \
                "${TEST_WORKSPACE}" >&2
            return 1
        fi
        if (( rc != 0 || TEST_FAILED > 0 )) || [[ "${KEEP_WORKSPACE:-0}" == "1" ]]; then
            printf 'Self-test workspace retained: %s\n' "${TEST_WORKSPACE}"
            return
        fi
        rm -rf -- "${TEST_WORKSPACE}"
    fi
}

function pass {
    local description="$1"

    TEST_TOTAL=$((TEST_TOTAL + 1))
    TEST_PASSED=$((TEST_PASSED + 1))
    printf '[ PASS ] %s\n' "${description}"
}

function fail {
    local description="$1"
    local expected="$2"
    local actual="$3"

    TEST_TOTAL=$((TEST_TOTAL + 1))
    TEST_FAILED=$((TEST_FAILED + 1))
    TEST_FAILURES+=("${description}")
    printf '[ FAIL ] %s\n' "${description}"
    printf '  Expected : %s\n' "${expected}"
    printf '  Actual   : %s\n' "${actual}"
}

function expect_load_pass {
    local counts_file="$1"
    local description="$2"
    local output_file="${TEST_WORKSPACE}/last-load.out"
    local output=""

    : > "${output_file}"
    if reporting_counts_load "${counts_file}" > "${output_file}" 2>&1; then
        pass "${description}"
    else
        output=$(< "${output_file}")
        fail "${description}" "exit 0" "${output}"
    fi
}

function expect_load_failure {
    local counts_file="$1"
    local expected_text="$2"
    local description="$3"
    local output_file="${TEST_WORKSPACE}/last-load.out"
    local output=""

    : > "${output_file}"
    if reporting_counts_load "${counts_file}" > "${output_file}" 2>&1; then
        fail "${description}" "failure containing ${expected_text}" "exit 0"
    else
        output=$(< "${output_file}")
        if [[ "${output}" == *"${expected_text}"* ]]; then
            pass "${description}"
        else
            fail "${description}" "failure containing ${expected_text}" "${output}"
        fi
    fi
}

function copy_with_crlf {
    local source_file="$1"
    local target_file="$2"
    local line=""

    while IFS= read -r line || [[ -n "${line:-}" ]]; do
        printf '%s\r\n' "${line}" >> "${target_file}"
    done < "${source_file}"
}

function copy_without_suite {
    local source_file="$1"
    local target_file="$2"
    local omitted_suite="$3"
    local line=""

    while IFS= read -r line || [[ -n "${line:-}" ]]; do
        if [[ "${line}" != "${omitted_suite},"* ]]; then
            printf '%s\n' "${line}" >> "${target_file}"
        fi
    done < "${source_file}"
}

function copy_with_nonnumeric_count {
    local source_file="$1"
    local target_file="$2"
    local line=""
    local row_steps=""

    while IFS= read -r line || [[ -n "${line:-}" ]]; do
        if [[ "${line}" == "error-handling,"* ]]; then
            row_steps="${line##*,}"
            printf 'error-handling,invalid,%s\n' "${row_steps}" >> "${target_file}"
        else
            printf '%s\n' "${line}" >> "${target_file}"
        fi
    done < "${source_file}"
}

function append_first_data_row {
    local source_file="$1"
    local target_file="$2"
    local line=""
    local line_number=0

    while IFS= read -r line || [[ -n "${line:-}" ]]; do
        line_number=$((line_number + 1))
        if (( line_number == 2 )); then
            printf '%s\n' "${line}" >> "${target_file}"
            return 0
        fi
    done < "${source_file}"
    return 1
}

function print_summary {
    local failure=""

    printf '%s\n' ""
    printf '%s\n' "REPORTING COUNTS SELF-TEST SUMMARY"
    printf '  %-20s : %d\n' "Total Assertions" "${TEST_TOTAL}"
    printf '  %-20s : %d\n' "Passed" "${TEST_PASSED}"
    printf '  %-20s : %d\n' "Failed" "${TEST_FAILED}"
    for failure in "${TEST_FAILURES[@]}"; do
        printf '  * %s\n' "${failure}"
    done
}

trap cleanup EXIT
TEST_WORKSPACE=$(mktemp -d "${TMPDIR:-/tmp}/ioc-runner-counts-self-test.XXXXXX")

expect_load_pass "${COMMITTED_COUNTS}" "committed CSV passes"
committed_tsv=$(reporting_counts_emit_tsv)

copy_with_crlf "${COMMITTED_COUNTS}" "${TEST_WORKSPACE}/crlf.csv"
expect_load_pass "${TEST_WORKSPACE}/crlf.csv" "CRLF CSV normalizes and passes"
crlf_tsv=$(reporting_counts_emit_tsv)
if [[ "${crlf_tsv}" == "${committed_tsv}" ]]; then
    pass "CRLF CSV preserves every parsed value"
else
    fail "CRLF CSV preserves every parsed value" "${committed_tsv}" "${crlf_tsv}"
fi

cp -- "${COMMITTED_COUNTS}" "${TEST_WORKSPACE}/duplicate.csv"
append_first_data_row "${COMMITTED_COUNTS}" "${TEST_WORKSPACE}/duplicate.csv"
expect_load_failure "${TEST_WORKSPACE}/duplicate.csv" "duplicate suite" \
    "duplicate suite fails"

copy_without_suite "${COMMITTED_COUNTS}" "${TEST_WORKSPACE}/missing.csv" \
    "system-lifecycle"
expect_load_failure "${TEST_WORKSPACE}/missing.csv" "missing suite: system-lifecycle" \
    "missing suite fails"

cp -- "${COMMITTED_COUNTS}" "${TEST_WORKSPACE}/unknown.csv"
printf '%s\n' "unknown-suite,1,1" >> "${TEST_WORKSPACE}/unknown.csv"
expect_load_failure "${TEST_WORKSPACE}/unknown.csv" "unknown suite" \
    "unknown suite fails"

copy_with_nonnumeric_count "${COMMITTED_COUNTS}" "${TEST_WORKSPACE}/nonnumeric.csv"
expect_load_failure "${TEST_WORKSPACE}/nonnumeric.csv" "nonnumeric count" \
    "nonnumeric count fails"

printf '%s\n' "suite,checks,steps,extra" > "${TEST_WORKSPACE}/malformed.csv"
expect_load_failure "${TEST_WORKSPACE}/malformed.csv" "invalid header" \
    "malformed header fails"

print_summary
if (( TEST_FAILED > 0 )); then
    exit 1
fi
exit 0
