#!/usr/bin/env bash
#
# Public reporting-suite membership shared by catalog and count consumers.

if [[ "${REPORTING_SUITES_LOADED:-0}" == "1" ]]; then
    return 0
fi
declare -gr REPORTING_SUITES_LOADED=1
declare -gr -a REPORTING_SUPPORTED_SUITES=(
    error-handling
    local-lifecycle
    source-regression
    system-infra
    system-lifecycle
)

function reporting_supported_suites {
    printf '%s\n' "${REPORTING_SUPPORTED_SUITES[@]}"
}

function reporting_suite_is_supported {
    local suite="$1"
    local supported_suite=""

    for supported_suite in "${REPORTING_SUPPORTED_SUITES[@]}"; do
        if [[ "${suite}" == "${supported_suite}" ]]; then
            return 0
        fi
    done
    return 1
}
