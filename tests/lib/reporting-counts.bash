#!/usr/bin/env bash
#
# Strict parser and lookup interface for expected reporting counts.

if [[ "${REPORTING_COUNTS_LOADED:-0}" == "1" ]]; then
    return 0
fi
declare -gr REPORTING_COUNTS_LOADED=1

# shellcheck source=reporting-suites.bash
source "${BASH_SOURCE[0]%/*}/reporting-suites.bash"

declare -g -A REPORTING_EXPECTED_CHECKS=()
declare -g -A REPORTING_EXPECTED_STEPS=()

function _reporting_counts_error {
    local message="$1"

    printf 'REPORTING COUNTS ERROR: %s\n' "${message}" >&2
}

function reporting_counts_load {
    local counts_file="$1"
    local line=""
    local suite=""
    local checks=""
    local steps=""
    local supported_suite=""
    local line_number=0

    REPORTING_EXPECTED_CHECKS=()
    REPORTING_EXPECTED_STEPS=()

    if [[ ! -f "${counts_file}" || ! -r "${counts_file}" ]]; then
        _reporting_counts_error "count file is not readable: ${counts_file}"
        return 1
    fi
    while IFS= read -r line || [[ -n "${line:-}" ]]; do
        line_number=$((line_number + 1))
        line="${line//$'\r'/}"
        if (( line_number == 1 )); then
            if [[ "${line}" != "suite,checks,steps" ]]; then
                _reporting_counts_error "invalid header in ${counts_file}"
                return 1
            fi
            continue
        fi
        if [[ ! "${line}" =~ ^([^,]+),([^,]+),([^,]+)$ ]]; then
            _reporting_counts_error "malformed row ${line_number} in ${counts_file}"
            return 1
        fi
        suite="${BASH_REMATCH[1]}"
        checks="${BASH_REMATCH[2]}"
        steps="${BASH_REMATCH[3]}"
        if ! reporting_suite_is_supported "${suite}"; then
            _reporting_counts_error "unknown suite on row ${line_number}: ${suite}"
            return 1
        fi
        if [[ -n "${REPORTING_EXPECTED_CHECKS[${suite}]:-}" ]]; then
            _reporting_counts_error "duplicate suite on row ${line_number}: ${suite}"
            return 1
        fi
        if [[ ! "${checks}" =~ ^[0-9]+$ || ! "${steps}" =~ ^[0-9]+$ ]]; then
            _reporting_counts_error "nonnumeric count on row ${line_number}: ${suite}"
            return 1
        fi
        REPORTING_EXPECTED_CHECKS["${suite}"]=$((10#${checks}))
        REPORTING_EXPECTED_STEPS["${suite}"]=$((10#${steps}))
    done < "${counts_file}"
    if (( line_number == 0 )); then
        _reporting_counts_error "count file is empty: ${counts_file}"
        return 1
    fi
    for supported_suite in "${REPORTING_SUPPORTED_SUITES[@]}"; do
        if [[ -z "${REPORTING_EXPECTED_CHECKS[${supported_suite}]:-}" ]]; then
            _reporting_counts_error "missing suite: ${supported_suite}"
            return 1
        fi
    done
}

function reporting_counts_lookup {
    local suite="$1"
    local checks_name="$2"
    local steps_name="$3"

    if [[ ! "${checks_name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ||
          ! "${steps_name}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
        _reporting_counts_error "invalid lookup result variable"
        return 1
    fi
    if [[ -z "${REPORTING_EXPECTED_CHECKS[${suite}]:-}" ||
          -z "${REPORTING_EXPECTED_STEPS[${suite}]:-}" ]]; then
        _reporting_counts_error "suite is not loaded: ${suite}"
        return 1
    fi
    printf -v "${checks_name}" '%d' "${REPORTING_EXPECTED_CHECKS[${suite}]}"
    printf -v "${steps_name}" '%d' "${REPORTING_EXPECTED_STEPS[${suite}]}"
}

function reporting_counts_emit_tsv {
    local suite=""

    for suite in "${REPORTING_SUPPORTED_SUITES[@]}"; do
        if [[ -z "${REPORTING_EXPECTED_CHECKS[${suite}]:-}" ||
              -z "${REPORTING_EXPECTED_STEPS[${suite}]:-}" ]]; then
            _reporting_counts_error "suite is not loaded: ${suite}"
            return 1
        fi
        printf '%s\t%d\t%d\n' "${suite}" \
            "${REPORTING_EXPECTED_CHECKS[${suite}]}" \
            "${REPORTING_EXPECTED_STEPS[${suite}]}"
    done
}
