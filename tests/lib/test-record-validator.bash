#!/usr/bin/env bash
#
# Structural validator for one reporter machine-record block.

if [[ "${TEST_RECORD_VALIDATOR_LOADED:-0}" == "1" ]]; then
    return 0
fi
declare -gr TEST_RECORD_VALIDATOR_LOADED=1

# shellcheck source=reporting-counts.bash
source "${BASH_SOURCE[0]%/*}/reporting-counts.bash"

declare -gr TEST_RECORD_COUNTS_FILE="${BASH_SOURCE[0]%/*}/../reporting-counts.csv"
declare -gr TEST_RECORD_SYSTEM_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
declare -gr TEST_RECORD_REASON_SENTINEL=$'\036'
declare -gr TEST_RECORD_TEST_RE='^TEST suite=([A-Za-z0-9._:/+-]+) run=([A-Za-z0-9._:/+-]+) step=(P00|S[0-9][0-9]) id=([A-Za-z0-9._:/+-]+) category=([A-Za-z0-9._:/+-]+) kind=(REQUIRED|PREREQUISITE|APPLICABILITY|BEHAVIOR|INTEGRITY) method=(real-path|direct-inspection) state=(PASS|FAIL|SKIP|NA|SCRIPT_ERROR) reason_b64=(-|[A-Za-z0-9_-]+)$'
declare -gr TEST_RECORD_STEP_RE='^STEP suite=([A-Za-z0-9._:/+-]+) run=([A-Za-z0-9._:/+-]+) step=(P00|S[0-9][0-9]) pass=([0-9]+) fail=([0-9]+) skip=([0-9]+) na=([0-9]+) err=([0-9]+)$'
declare -gr TEST_RECORD_SUITE_RE='^SUITE suite=([A-Za-z0-9._:/+-]+) run=([A-Za-z0-9._:/+-]+) scope=([A-Za-z0-9._:/+-]+) runner=([A-Za-z0-9._:/+-]+) os=([A-Za-z0-9._:/+-]+) arch=([A-Za-z0-9._:/+-]+) total=([0-9]+) pass=([0-9]+) fail=([0-9]+) skip=([0-9]+) na=([0-9]+) err=([0-9]+) state=(PASS|FAIL)$'

function _test_record_error {
    local message="$1"

    printf 'TEST RECORD ERROR: %s\n' "${message}" >&2
}

function _test_record_expected_category {
    local suite="$1"

    case "${suite}" in
        error-handling) printf '%s' "error-contract" ;;
        local-lifecycle|system-lifecycle) printf '%s' "lifecycle-behavior" ;;
        source-regression) printf '%s' "source-regression" ;;
        system-infra) printf '%s' "installed-conformance" ;;
        *) return 1 ;;
    esac
}

function _test_record_decode_reason {
    local encoded="$1"
    local base64_bin="$2"
    local padding=""
    local standard=""

    standard="${encoded//-/+}"
    standard="${standard//_/\/}"
    case $((${#standard} % 4)) in
        0) padding="" ;;
        2) padding="==" ;;
        3) padding="=" ;;
        *) return 1 ;;
    esac
    if ! printf '%s%s' "${standard}" "${padding}" | "${base64_bin}" -d 2>/dev/null; then
        return 1
    fi
    printf '%s' "${TEST_RECORD_REASON_SENTINEL}"
}

function test_record_validate_file {
    if (( $# != 7 )); then
        _test_record_error "test_record_validate_file requires seven arguments"
        return 1
    fi

    local record_file="$1"
    local expected_suite="$2"
    local expected_scope="$3"
    local expected_runner="$4"
    local producer_status="$5"
    local run_id_name="$6"
    local suite_record_name="$7"
    local base64_bin=""
    local expected_category=""
    local expected_checks=0
    local expected_steps=0
    local line=""
    local line_number=0
    local phase="TEST"
    local suite=""
    local run_id=""
    local step_id=""
    local check_id=""
    local category=""
    local state=""
    local reason_b64=""
    local reason=""
    local record_scope=""
    local record_runner=""
    local suite_record=""
    local test_count=0
    local step_count=0
    local suite_count=0
    local pass_count=0
    local fail_count=0
    local skip_count=0
    local na_count=0
    local error_count=0
    local record_pass=0
    local record_fail=0
    local record_skip=0
    local record_na=0
    local record_error=0
    local record_total=0
    local suite_state=""
    local observed_step=""
    local -A test_seen=()
    local -A test_step=()
    local -A step_seen=()
    local -A step_pass=()
    local -A step_fail=()
    local -A step_skip=()
    local -A step_na=()
    local -A step_error=()

    if [[ ! "${run_id_name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ||
          ! "${suite_record_name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ||
          "${run_id_name}" == "${suite_record_name}" ]]; then
        _test_record_error "invalid or duplicate result variable name"
        return 1
    fi
    if ! reporting_suite_is_supported "${expected_suite}"; then
        _test_record_error "unsupported expected suite: ${expected_suite}"
        return 1
    fi
    case "${expected_scope}" in
        container|local|system|none) ;;
        *) _test_record_error "unsupported expected scope: ${expected_scope}"; return 1 ;;
    esac
    case "${expected_runner}" in
        source|installed|none) ;;
        *) _test_record_error "unsupported expected runner: ${expected_runner}"; return 1 ;;
    esac
    if [[ ! "${producer_status}" =~ ^(0|[1-9][0-9]{0,2})$ ]] ||
       (( 10#${producer_status} > 255 )); then
        _test_record_error "invalid producer status: ${producer_status}"
        return 1
    fi
    producer_status=$((10#${producer_status}))
    if [[ ! -f "${record_file}" || -L "${record_file}" || ! -r "${record_file}" ]]; then
        _test_record_error "record file is not a readable regular file: ${record_file}"
        return 1
    fi
    if [[ ! -s "${record_file}" ]]; then
        _test_record_error "record file is empty: ${record_file}"
        return 1
    fi

    base64_bin=$(PATH="${TEST_RECORD_SYSTEM_PATH}" command -v base64 || true)
    if [[ -z "${base64_bin}" || ! -x "${base64_bin}" ]]; then
        _test_record_error "base64 is unavailable or not executable"
        return 1
    fi
    expected_category=$(_test_record_expected_category "${expected_suite}") || {
        _test_record_error "category mapping is missing for ${expected_suite}"
        return 1
    }
    if ! reporting_counts_load "${TEST_RECORD_COUNTS_FILE}" ||
       ! reporting_counts_lookup "${expected_suite}" expected_checks expected_steps; then
        _test_record_error "expected counts are unavailable for ${expected_suite}"
        return 1
    fi

    while IFS= read -r line || [[ -n "${line:-}" ]]; do
        line_number=$((line_number + 1))
        if [[ "${phase}" == "DONE" ]]; then
            _test_record_error "record follows final SUITE on line ${line_number}"
            return 1
        fi
        if [[ "${line}" =~ ${TEST_RECORD_TEST_RE} ]]; then
            if [[ "${phase}" != "TEST" ]]; then
                _test_record_error "TEST record outside TEST phase on line ${line_number}"
                return 1
            fi
            suite="${BASH_REMATCH[1]}"
            if [[ -z "${run_id}" ]]; then
                run_id="${BASH_REMATCH[2]}"
            elif [[ "${BASH_REMATCH[2]}" != "${run_id}" ]]; then
                _test_record_error "TEST run ID mismatch on line ${line_number}"
                return 1
            fi
            step_id="${BASH_REMATCH[3]}"
            check_id="${BASH_REMATCH[4]}"
            category="${BASH_REMATCH[5]}"
            state="${BASH_REMATCH[8]}"
            reason_b64="${BASH_REMATCH[9]}"
            if [[ "${suite}" != "${expected_suite}" ]]; then
                _test_record_error "TEST suite mismatch on line ${line_number}"
                return 1
            fi
            if [[ "${check_id}" != "${expected_suite}.${step_id}."?* ]]; then
                _test_record_error "TEST identity does not match suite and STEP on line ${line_number}"
                return 1
            fi
            if [[ -n "${test_seen[${check_id}]:-}" ]]; then
                _test_record_error "duplicate TEST identity on line ${line_number}: ${check_id}"
                return 1
            fi
            if [[ "${category}" != "${expected_category}" ]]; then
                _test_record_error "TEST category mismatch on line ${line_number}"
                return 1
            fi
            if [[ "${state}" == "PASS" ]]; then
                if [[ "${reason_b64}" != "-" ]]; then
                    _test_record_error "PASS reason must be '-' on line ${line_number}"
                    return 1
                fi
            else
                if [[ "${reason_b64}" == "-" ]] ||
                   ! reason=$(_test_record_decode_reason "${reason_b64}" "${base64_bin}") ||
                   [[ "${reason}" != *"${TEST_RECORD_REASON_SENTINEL}" ]]; then
                    _test_record_error "non-PASS reason is not valid base64url text on line ${line_number}"
                    return 1
                fi
                reason="${reason%"${TEST_RECORD_REASON_SENTINEL}"}"
                if [[ -z "${reason}" || "${reason}" == *$'\n'* || "${reason}" == *$'\r'* || "${reason}" == *$'\t'* ]]; then
                    _test_record_error "non-PASS reason is not valid base64url text on line ${line_number}"
                    return 1
                fi
            fi

            test_seen["${check_id}"]=1
            test_step["${check_id}"]="${step_id}"
            test_count=$((test_count + 1))
            case "${state}" in
                PASS) pass_count=$((pass_count + 1)); step_pass["${step_id}"]=$((${step_pass[${step_id}]:-0} + 1)) ;;
                FAIL) fail_count=$((fail_count + 1)); step_fail["${step_id}"]=$((${step_fail[${step_id}]:-0} + 1)) ;;
                SKIP) skip_count=$((skip_count + 1)); step_skip["${step_id}"]=$((${step_skip[${step_id}]:-0} + 1)) ;;
                NA) na_count=$((na_count + 1)); step_na["${step_id}"]=$((${step_na[${step_id}]:-0} + 1)) ;;
                SCRIPT_ERROR) error_count=$((error_count + 1)); step_error["${step_id}"]=$((${step_error[${step_id}]:-0} + 1)) ;;
            esac
            continue
        fi

        if [[ "${line}" =~ ${TEST_RECORD_STEP_RE} ]]; then
            phase="STEP"
            suite="${BASH_REMATCH[1]}"
            if [[ -z "${run_id}" || "${BASH_REMATCH[2]}" != "${run_id}" ]]; then
                _test_record_error "STEP run ID mismatch on line ${line_number}"
                return 1
            fi
            step_id="${BASH_REMATCH[3]}"
            if [[ "${suite}" != "${expected_suite}" ]]; then
                _test_record_error "STEP suite mismatch on line ${line_number}"
                return 1
            fi
            if [[ -n "${step_seen[${step_id}]:-}" ]]; then
                _test_record_error "duplicate STEP identity on line ${line_number}: ${step_id}"
                return 1
            fi
            record_pass=$((10#${BASH_REMATCH[4]}))
            record_fail=$((10#${BASH_REMATCH[5]}))
            record_skip=$((10#${BASH_REMATCH[6]}))
            record_na=$((10#${BASH_REMATCH[7]}))
            record_error=$((10#${BASH_REMATCH[8]}))
            if (( record_pass != ${step_pass[${step_id}]:-0} ||
                  record_fail != ${step_fail[${step_id}]:-0} ||
                  record_skip != ${step_skip[${step_id}]:-0} ||
                  record_na != ${step_na[${step_id}]:-0} ||
                  record_error != ${step_error[${step_id}]:-0} )); then
                _test_record_error "STEP vector mismatch on line ${line_number}: ${step_id}"
                return 1
            fi
            step_seen["${step_id}"]=1
            step_count=$((step_count + 1))
            continue
        fi

        if [[ "${line}" =~ ${TEST_RECORD_SUITE_RE} ]]; then
            phase="DONE"
            suite_count=$((suite_count + 1))
            suite_record="${line}"
            suite="${BASH_REMATCH[1]}"
            if [[ -z "${run_id}" || "${BASH_REMATCH[2]}" != "${run_id}" ]]; then
                _test_record_error "SUITE run ID mismatch on line ${line_number}"
                return 1
            fi
            record_scope="${BASH_REMATCH[3]}"
            record_runner="${BASH_REMATCH[4]}"
            record_total=$((10#${BASH_REMATCH[7]}))
            record_pass=$((10#${BASH_REMATCH[8]}))
            record_fail=$((10#${BASH_REMATCH[9]}))
            record_skip=$((10#${BASH_REMATCH[10]}))
            record_na=$((10#${BASH_REMATCH[11]}))
            record_error=$((10#${BASH_REMATCH[12]}))
            suite_state="${BASH_REMATCH[13]}"
            if [[ "${suite}" != "${expected_suite}" ||
                  "${record_scope}" != "${expected_scope}" ||
                  "${record_runner}" != "${expected_runner}" ]]; then
                _test_record_error "SUITE dimensions mismatch on line ${line_number}"
                return 1
            fi
            if (( record_total != record_pass + record_fail + record_skip + record_na + record_error )); then
                _test_record_error "SUITE vector does not reconcile on line ${line_number}"
                return 1
            fi
            if (( record_total != test_count || record_pass != pass_count ||
                  record_fail != fail_count || record_skip != skip_count ||
                  record_na != na_count || record_error != error_count )); then
                _test_record_error "SUITE vector disagrees with TEST records on line ${line_number}"
                return 1
            fi
            if [[ "${suite_state}" == "PASS" ]]; then
                if (( producer_status != 0 || record_fail > 0 || record_error > 0 )); then
                    _test_record_error "SUITE PASS disagrees with vector or producer status"
                    return 1
                fi
            elif (( producer_status == 0 )); then
                _test_record_error "SUITE FAIL disagrees with producer status 0"
                return 1
            fi
            continue
        fi

        if [[ "${line}" == TEST\ * || "${line}" == STEP\ * || "${line}" == SUITE\ * ]]; then
            _test_record_error "malformed reporter record on line ${line_number}"
        else
            _test_record_error "unknown machine record on line ${line_number}"
        fi
        return 1
    done < "${record_file}"

    if [[ "${phase}" != "DONE" || ${suite_count} -ne 1 ]]; then
        _test_record_error "record file does not end with exactly one SUITE record"
        return 1
    fi
    if (( test_count != expected_checks || step_count != expected_steps )); then
        _test_record_error "record count mismatch: expected checks=${expected_checks} steps=${expected_steps}, actual checks=${test_count} steps=${step_count}"
        return 1
    fi
    for check_id in "${!test_step[@]}"; do
        observed_step="${test_step[${check_id}]}"
        if [[ -z "${step_seen[${observed_step}]:-}" ]]; then
            _test_record_error "TEST refers to missing STEP: ${check_id} -> ${observed_step}"
            return 1
        fi
    done

    printf -v "${run_id_name}" '%s' "${run_id}"
    printf -v "${suite_record_name}" '%s' "${suite_record}"
}
