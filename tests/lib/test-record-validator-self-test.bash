#!/usr/bin/env bash
#
# Exercises the shared machine-record validator at its serialized file boundary.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
readonly REPORTER="${SCRIPT_DIR}/test-reporting.bash"
readonly VALIDATOR="${SCRIPT_DIR}/test-record-validator.bash"

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
        if [[ "${SELF_TEST_WORKSPACE}" != "${SELF_TEST_PARENT}/ioc-runner-record-validator-self-test."* ]]; then
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

function generate_baseline {
    local record_file="$1"
    local human_file="$2"
    local report_workspace="$3"
    local index=0
    local step_index=0
    local step_id=""
    local check_id=""
    local -a step_ids=(P00 S01 S02 S03 S04 S05 S06)
    local -a check_ids=()

    mkdir -m 0700 -- "${report_workspace}"
    (
        export REPORT_MACHINE_OUTPUT=1
        # shellcheck source=tests/lib/test-reporting.bash
        source "${REPORTER}"
        report_init system-infra validator-baseline system none test-host linux-x86_64 \
            "${report_workspace}"
        for step_id in "${step_ids[@]}"; do
            report_register_step "${step_id}" "Validator baseline STEP ${step_id}"
        done
        for ((index = 1; index <= 36; index++)); do
            step_index=$(((index - 1) / 6))
            step_id="${step_ids[${step_index}]}"
            printf -v check_id 'system-infra.%s.validator-%02d' "${step_id}" "${index}"
            report_register_check "${check_id}" "${step_id}" installed-conformance \
                REQUIRED direct-inspection "Validator baseline check ${index}"
            check_ids+=("${check_id}")
        done
        report_close_catalog
        for check_id in "${check_ids[@]}"; do
            report_record "${check_id}" PASS
        done
        report_finalize 0
    ) > "${record_file}" 2> "${human_file}"
}

function expect_accept {
    local name="$1"
    local record_file="$2"
    local producer_status="$3"
    local stdout_file="${SELF_TEST_WORKSPACE}/${name}.stdout"
    local stderr_file="${SELF_TEST_WORKSPACE}/${name}.stderr"
    local validated_run=""
    local validated_suite=""
    local actual_status=0

    test_record_validate_file "${record_file}" system-infra system none \
        "${producer_status}" validated_run validated_suite \
        > "${stdout_file}" 2> "${stderr_file}" || actual_status=$?
    expect_status 0 "${actual_status}" "${name}: accepted"
    expect_status validator-baseline "${validated_run}" "${name}: returned run ID"
    expect_contains <(printf '%s\n' "${validated_suite}") \
        "SUITE suite=system-infra run=validator-baseline" \
        "${name}: returned SUITE record"
    expect_status 0 "$(wc -c < "${stdout_file}")" "${name}: validator standard output is empty"
}

function expect_reject {
    local name="$1"
    local record_file="$2"
    local producer_status="$3"
    local expected_error="$4"
    local stderr_file="${SELF_TEST_WORKSPACE}/${name}.stderr"
    local validated_run="unchanged-run"
    local validated_suite="unchanged-suite"
    local actual_status=0

    test_record_validate_file "${record_file}" system-infra system none \
        "${producer_status}" validated_run validated_suite \
        > "${SELF_TEST_WORKSPACE}/${name}.stdout" 2> "${stderr_file}" || actual_status=$?
    expect_status 1 "${actual_status}" "${name}: rejected"
    expect_contains "${stderr_file}" "${expected_error}" "${name}: diagnostic"
    expect_status unchanged-run "${validated_run}" "${name}: run result unchanged"
    expect_status unchanged-suite "${validated_suite}" "${name}: suite result unchanged"
}

function print_summary {
    local detail=""

    printf '%s\n' ""
    printf '%s\n' "===================================================================================================="
    printf '%s\n' "TEST RECORD VALIDATOR SELF-TEST SUMMARY"
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

# shellcheck source=tests/lib/test-record-validator.bash
source "${VALIDATOR}"
SELF_TEST_PARENT=$(cd -- "${TMPDIR:-/tmp}" && pwd -P)
readonly SELF_TEST_PARENT
SELF_TEST_WORKSPACE=$(mktemp -d "${SELF_TEST_PARENT}/ioc-runner-record-validator-self-test.XXXXXX")
baseline="${SELF_TEST_WORKSPACE}/baseline.records"
generate_baseline "${baseline}" "${SELF_TEST_WORKSPACE}/baseline.human" \
    "${SELF_TEST_WORKSPACE}/reporter"

expect_accept valid "${baseline}" 0

: > "${SELF_TEST_WORKSPACE}/empty.records"
expect_reject empty "${SELF_TEST_WORKSPACE}/empty.records" 0 "record file is empty"

sed '1s/^TEST /BROKEN /' "${baseline}" > "${SELF_TEST_WORKSPACE}/malformed.records"
expect_reject malformed "${SELF_TEST_WORKSPACE}/malformed.records" 0 "unknown machine record"

cp -- "${baseline}" "${SELF_TEST_WORKSPACE}/after-suite.records"
printf '%s\n' "UNKNOWN record" >> "${SELF_TEST_WORKSPACE}/after-suite.records"
expect_reject after-suite "${SELF_TEST_WORKSPACE}/after-suite.records" 0 "record follows final SUITE"

awk 'NR == 1 { print; print; next } { print }' "${baseline}" \
    > "${SELF_TEST_WORKSPACE}/duplicate-test.records"
expect_reject duplicate-test "${SELF_TEST_WORKSPACE}/duplicate-test.records" 0 "duplicate TEST identity"

sed '1d' "${baseline}" > "${SELF_TEST_WORKSPACE}/missing-test.records"
expect_reject missing-test "${SELF_TEST_WORKSPACE}/missing-test.records" 0 "STEP vector mismatch"

awk 'NR == 1 { held = $0 } /^STEP / && ! copied { print; print held; copied = 1; next } { print }' \
    "${baseline}" > "${SELF_TEST_WORKSPACE}/cross-phase.records"
expect_reject cross-phase "${SELF_TEST_WORKSPACE}/cross-phase.records" 0 "TEST record outside TEST phase"

awk '/^STEP / && ! copied { print; print; copied = 1; next } { print }' "${baseline}" \
    > "${SELF_TEST_WORKSPACE}/duplicate-step.records"
expect_reject duplicate-step "${SELF_TEST_WORKSPACE}/duplicate-step.records" 0 "duplicate STEP identity"

sed '0,/^STEP /{/^STEP /d;}' "${baseline}" > "${SELF_TEST_WORKSPACE}/missing-step.records"
expect_reject missing-step "${SELF_TEST_WORKSPACE}/missing-step.records" 0 "record count mismatch"

sed '0,/ pass=6 /s// pass=5 /' "${baseline}" > "${SELF_TEST_WORKSPACE}/step-vector.records"
expect_reject step-vector "${SELF_TEST_WORKSPACE}/step-vector.records" 0 "STEP vector mismatch"

sed 's/ total=36 pass=36 / total=35 pass=36 /' "${baseline}" \
    > "${SELF_TEST_WORKSPACE}/suite-vector.records"
expect_reject suite-vector "${SELF_TEST_WORKSPACE}/suite-vector.records" 0 "SUITE vector does not reconcile"

sed '1s/reason_b64=-$/reason_b64=_/' "${baseline}" > "${SELF_TEST_WORKSPACE}/pass-reason.records"
expect_reject pass-reason "${SELF_TEST_WORKSPACE}/pass-reason.records" 0 "PASS reason must be '-'"

sed -e '1s/state=PASS reason_b64=-$/state=FAIL reason_b64=YQo/' \
    -e '0,/ step=P00 pass=6 fail=0 /s// step=P00 pass=5 fail=1 /' \
    -e '/^SUITE /s/ total=36 pass=36 fail=0 / total=36 pass=35 fail=1 /' \
    -e '/^SUITE /s/ state=PASS$/ state=FAIL/' "${baseline}" \
    > "${SELF_TEST_WORKSPACE}/trailing-newline-reason.records"
expect_reject trailing-newline-reason \
    "${SELF_TEST_WORKSPACE}/trailing-newline-reason.records" 1 \
    "non-PASS reason is not valid base64url text"

sed '1s/id=system-infra\.P00\./id=system-infra.S99./' "${baseline}" \
    > "${SELF_TEST_WORKSPACE}/identity.records"
expect_reject identity "${SELF_TEST_WORKSPACE}/identity.records" 0 \
    "TEST identity does not match suite and STEP"

expect_reject producer-status "${baseline}" 1 "SUITE PASS disagrees with vector or producer status"

ln -s -- "${baseline}" "${SELF_TEST_WORKSPACE}/symlink.records"
expect_reject symlink "${SELF_TEST_WORKSPACE}/symlink.records" 0 \
    "record file is not a readable regular file"

invalid_name_status=0
test_record_validate_file "${baseline}" system-infra system none 0 \
    'invalid[name]' validated_suite > "${SELF_TEST_WORKSPACE}/invalid-name.stdout" \
    2> "${SELF_TEST_WORKSPACE}/invalid-name.stderr" || invalid_name_status=$?
expect_status 1 "${invalid_name_status}" "invalid result variable: rejected"
expect_contains "${SELF_TEST_WORKSPACE}/invalid-name.stderr" \
    "invalid or duplicate result variable name" "invalid result variable: diagnostic"

print_summary
if (( SELF_TEST_FAILED > 0 )); then
    exit 1
fi
exit 0
