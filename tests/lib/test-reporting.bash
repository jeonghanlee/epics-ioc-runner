#!/usr/bin/env bash
#
# Shared suite reporter. Test code declares a complete catalog, records each
# observed terminal state once, and finalizes human and machine projections
# from one file-backed ledger.

declare -g REPORT_INITIALIZED=0
declare -g REPORT_CATALOG_CLOSED=0
declare -g REPORT_FINALIZED=0
declare -g REPORT_CATALOG_VALID=1
declare -g REPORT_SUITE=""
declare -g REPORT_RUN_ID=""
declare -g REPORT_SCOPE=""
declare -g REPORT_RUNNER=""
declare -g REPORT_OS=""
declare -g REPORT_ARCH=""
declare -g REPORT_LEDGER_FILE=""
declare -g REPORT_LEDGER_DIR=""
declare -g REPORT_BASE64_BIN=""
declare -g REPORT_MKTEMP_BIN=""
declare -g REPORT_RM_BIN=""
declare -g REPORT_RMDIR_BIN=""
declare -g REPORT_STAT_BIN=""
declare -g REPORT_FINAL_STATUS=1
declare -g -a REPORT_STEP_IDS=()
declare -g -a REPORT_CHECK_IDS=()
declare -g -A REPORT_STEP_SEEN=()
declare -g -A REPORT_STEP_DESCRIPTION=()
declare -g -A REPORT_CHECK_SEEN=()
declare -g -A REPORT_CHECK_STEP=()
declare -g -A REPORT_CHECK_CATEGORY=()
declare -g -A REPORT_CHECK_KIND=()
declare -g -A REPORT_CHECK_METHOD=()
declare -g -A REPORT_CHECK_DESCRIPTION=()

function _report_scalar_is_valid {
    local value="$1"

    [[ "${value}" =~ ^[A-Za-z0-9._:/+-]+$ ]]
}

function _report_text_is_valid {
    local value="$1"

    [[ -n "${value}" && "${value}" != *$'\n'* && "${value}" != *$'\r'* && "${value}" != *$'\t'* ]]
}

function _report_b64url_encode {
    local value="$1"
    local encoded=""

    encoded=$(printf '%s' "${value}" | "${REPORT_BASE64_BIN}")
    encoded="${encoded//$'\n'/}"
    encoded="${encoded//+/-}"
    encoded="${encoded//\//_}"
    encoded="${encoded//=}"
    printf '%s' "${encoded}"
}

function _report_b64url_decode {
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
    printf '%s%s' "${standard}" "${padding}" | "${REPORT_BASE64_BIN}" -d
}

function _report_append_error {
    local code="$1"
    local target_id="$2"
    local reason="$3"
    local reason_b64=""

    if ! _report_scalar_is_valid "${target_id}"; then
        target_id="-"
    fi
    if ! _report_text_is_valid "${reason}"; then
        reason="reporter error input contained invalid text"
    fi
    case "${code}" in
        catalog-*|event-before-catalog-close|event-unknown-id) REPORT_CATALOG_VALID=0 ;;
    esac
    if [[ -n "${REPORT_LEDGER_FILE}" && -w "${REPORT_LEDGER_FILE}" && -n "${REPORT_BASE64_BIN}" ]]; then
        reason_b64=$(_report_b64url_encode "${reason}")
        printf 'ERROR\t%s\t%s\t%s\n' "${code}" "${target_id}" "${reason_b64}" >> "${REPORT_LEDGER_FILE}"
    else
        printf 'REPORTING ERROR: %s\n' "${reason}" >&2
    fi
}

function _report_require_lifetime {
    local operation="$1"

    if (( ! REPORT_INITIALIZED )); then
        printf 'REPORTING ERROR: %s before report_init\n' "${operation}" >&2
        return 1
    fi
    if (( REPORT_FINALIZED )); then
        printf 'REPORTING ERROR: %s after report_finalize\n' "${operation}" >&2
        return 1
    fi
    return 0
}

function _report_expected_category {
    local suite="$1"

    case "${suite}" in
        error-handling) printf '%s' "error-contract" ;;
        local-lifecycle|system-lifecycle) printf '%s' "lifecycle-behavior" ;;
        source-regression) printf '%s' "source-regression" ;;
        system-infra) printf '%s' "installed-conformance" ;;
        *) return 1 ;;
    esac
}

function _report_suite_dimensions_are_valid {
    local suite="$1"
    local scope="$2"
    local runner="$3"

    case "${suite}:${scope}:${runner}" in
        error-handling:none:source) return 0 ;;
        local-lifecycle:local:source) return 0 ;;
        local-lifecycle:local:installed) return 0 ;;
        source-regression:system:source) return 0 ;;
        system-infra:system:none) return 0 ;;
        system-lifecycle:system:source) return 0 ;;
        system-lifecycle:system:installed) return 0 ;;
    esac
    return 1
}

function report_init {
    local suite="$1"
    local run_id="$2"
    local scope="$3"
    local runner="$4"
    local os_id="$5"
    local arch_id="$6"
    local ledger_dir="$7"
    local expected_category=""
    local ledger_mode=""
    local ledger_owner=""
    local saved_umask=""
    local system_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

    if (( REPORT_INITIALIZED && ! REPORT_FINALIZED )); then
        printf '%s\n' "REPORTING ERROR: report_init called more than once" >&2
        return 1
    fi

    REPORT_INITIALIZED=0
    REPORT_CATALOG_CLOSED=0
    REPORT_FINALIZED=0
    REPORT_CATALOG_VALID=1
    REPORT_FINAL_STATUS=1
    REPORT_LEDGER_FILE=""
    REPORT_LEDGER_DIR=""
    REPORT_STEP_IDS=()
    REPORT_CHECK_IDS=()
    REPORT_STEP_SEEN=()
    REPORT_STEP_DESCRIPTION=()
    REPORT_CHECK_SEEN=()
    REPORT_CHECK_STEP=()
    REPORT_CHECK_CATEGORY=()
    REPORT_CHECK_KIND=()
    REPORT_CHECK_METHOD=()
    REPORT_CHECK_DESCRIPTION=()

    REPORT_BASE64_BIN=$(PATH="${system_path}" command -v base64 || true)
    REPORT_MKTEMP_BIN=$(PATH="${system_path}" command -v mktemp || true)
    REPORT_RM_BIN=$(PATH="${system_path}" command -v rm || true)
    REPORT_RMDIR_BIN=$(PATH="${system_path}" command -v rmdir || true)
    REPORT_STAT_BIN=$(PATH="${system_path}" command -v stat || true)
    if [[ -z "${REPORT_BASE64_BIN}" || ! -x "${REPORT_BASE64_BIN}" ]]; then
        printf '%s\n' "REPORTING ERROR: base64 is unavailable or not executable" >&2
        return 1
    fi
    if [[ -z "${REPORT_MKTEMP_BIN}" || ! -x "${REPORT_MKTEMP_BIN}" ]]; then
        printf '%s\n' "REPORTING ERROR: mktemp is unavailable or not executable" >&2
        return 1
    fi
    if [[ -z "${REPORT_RM_BIN}" || ! -x "${REPORT_RM_BIN}" ]]; then
        printf '%s\n' "REPORTING ERROR: rm is unavailable or not executable" >&2
        return 1
    fi
    if [[ -z "${REPORT_RMDIR_BIN}" || ! -x "${REPORT_RMDIR_BIN}" ]]; then
        printf '%s\n' "REPORTING ERROR: rmdir is unavailable or not executable" >&2
        return 1
    fi
    if [[ -z "${REPORT_STAT_BIN}" || ! -x "${REPORT_STAT_BIN}" ]]; then
        printf '%s\n' "REPORTING ERROR: stat is unavailable or not executable" >&2
        return 1
    fi
    if ! expected_category=$(_report_expected_category "${suite}"); then
        printf 'REPORTING ERROR: unsupported suite: %s\n' "${suite}" >&2
        return 1
    fi
    if ! _report_scalar_is_valid "${run_id}" || ! _report_scalar_is_valid "${os_id}" || ! _report_scalar_is_valid "${arch_id}"; then
        printf '%s\n' "REPORTING ERROR: run, os, and arch must use scalar record characters" >&2
        return 1
    fi
    case "${scope}" in
        local|system|none) ;;
        *) printf 'REPORTING ERROR: unsupported scope: %s\n' "${scope}" >&2; return 1 ;;
    esac
    case "${runner}" in
        source|installed|none) ;;
        *) printf 'REPORTING ERROR: unsupported runner: %s\n' "${runner}" >&2; return 1 ;;
    esac
    if ! _report_suite_dimensions_are_valid "${suite}" "${scope}" "${runner}"; then
        printf 'REPORTING ERROR: unsupported scope/runner combination for %s: scope=%s runner=%s\n' \
            "${suite}" "${scope}" "${runner}" >&2
        return 1
    fi
    if [[ ! -d "${ledger_dir}" || -L "${ledger_dir}" ]]; then
        printf 'REPORTING ERROR: ledger directory is unavailable or symbolic: %s\n' "${ledger_dir}" >&2
        return 1
    fi
    ledger_owner=$("${REPORT_STAT_BIN}" -c '%u' -- "${ledger_dir}") || return 1
    ledger_mode=$("${REPORT_STAT_BIN}" -c '%a' -- "${ledger_dir}") || return 1
    if [[ ! "${ledger_owner}" =~ ^[0-9]+$ || "${ledger_owner}" != "${EUID}" ]]; then
        printf 'REPORTING ERROR: ledger directory is not owned by the current user: %s\n' "${ledger_dir}" >&2
        return 1
    fi
    if [[ ! "${ledger_mode}" =~ ^[0-7]{3,4}$ ]] || (( (8#${ledger_mode} & 0022) != 0 )); then
        printf 'REPORTING ERROR: ledger directory is group- or world-writable: %s\n' "${ledger_dir}" >&2
        return 1
    fi

    saved_umask=$(umask)
    umask 077
    REPORT_LEDGER_FILE=$("${REPORT_MKTEMP_BIN}" "${ledger_dir%/}/.${suite}.${run_id}.XXXXXX.ledger") || {
        umask "${saved_umask}"
        printf 'REPORTING ERROR: cannot create ledger in %s\n' "${ledger_dir}" >&2
        return 1
    }
    umask "${saved_umask}"
    ledger_owner=$("${REPORT_STAT_BIN}" -c '%u' -- "${REPORT_LEDGER_FILE}") || ledger_owner=""
    ledger_mode=$("${REPORT_STAT_BIN}" -c '%a' -- "${REPORT_LEDGER_FILE}") || ledger_mode=""
    if [[ -L "${REPORT_LEDGER_FILE}" || ! -f "${REPORT_LEDGER_FILE}" || "${ledger_owner}" != "${EUID}" || "${ledger_mode}" != "600" ]]; then
        "${REPORT_RM_BIN}" -f -- "${REPORT_LEDGER_FILE}"
        REPORT_LEDGER_FILE=""
        printf '%s\n' "REPORTING ERROR: ledger file ownership or mode is unsafe" >&2
        return 1
    fi

    REPORT_SUITE="${suite}"
    REPORT_RUN_ID="${run_id}"
    REPORT_SCOPE="${scope}"
    REPORT_RUNNER="${runner}"
    REPORT_OS="${os_id}"
    REPORT_ARCH="${arch_id}"
    REPORT_LEDGER_DIR="${ledger_dir}"
    REPORT_INITIALIZED=1
    : "${expected_category}"
}

function report_register_step {
    local step_id="$1"
    local description="$2"

    _report_require_lifetime "report_register_step" || return 1
    if (( REPORT_CATALOG_CLOSED )); then
        _report_append_error "catalog-late-step" "-" "late STEP registration: ${step_id}"
        return 1
    fi
    if [[ ! "${step_id}" =~ ^(P00|S[0-9][0-9])$ ]]; then
        _report_append_error "catalog-step-id" "-" "invalid STEP identity: ${step_id}"
        return 1
    fi
    if ! _report_text_is_valid "${description}"; then
        _report_append_error "catalog-step-description" "-" "invalid STEP description: ${step_id}"
        return 1
    fi
    if [[ -n "${REPORT_STEP_SEEN[${step_id}]:-}" ]]; then
        _report_append_error "catalog-duplicate-step" "-" "duplicate STEP registration: ${step_id}"
        return 1
    fi

    REPORT_STEP_IDS+=("${step_id}")
    REPORT_STEP_SEEN["${step_id}"]=1
    REPORT_STEP_DESCRIPTION["${step_id}"]="${description}"
}

function report_register_check {
    local check_id="$1"
    local step_id="$2"
    local category="$3"
    local check_kind="$4"
    local test_method="$5"
    local description="$6"
    local check_id_prefix=""
    local expected_category=""

    _report_require_lifetime "report_register_check" || return 1
    if (( REPORT_CATALOG_CLOSED )); then
        _report_append_error "catalog-late-check" "${check_id}" "late check registration: ${check_id}"
        return 1
    fi
    if [[ -z "${REPORT_STEP_SEEN[${step_id}]:-}" ]]; then
        _report_append_error "catalog-unknown-step" "${check_id}" "check uses undeclared STEP ${step_id}: ${check_id}"
        return 1
    fi
    check_id_prefix="${REPORT_SUITE}.${step_id}."
    if ! _report_scalar_is_valid "${check_id}" || [[ "${check_id}" != "${check_id_prefix}"?* ]]; then
        _report_append_error "catalog-check-id" "${check_id:-'-'}" "invalid check identity: ${check_id:-<empty>}"
        return 1
    fi
    if [[ -n "${REPORT_CHECK_SEEN[${check_id}]:-}" ]]; then
        _report_append_error "catalog-duplicate-check" "${check_id}" "duplicate check registration: ${check_id}"
        return 1
    fi
    expected_category=$(_report_expected_category "${REPORT_SUITE}")
    if [[ "${category}" != "${expected_category}" ]]; then
        _report_append_error "catalog-category" "${check_id}" "invalid category ${category} for ${REPORT_SUITE}"
        return 1
    fi
    case "${check_kind}" in
        REQUIRED|PREREQUISITE|APPLICABILITY|BEHAVIOR|INTEGRITY) ;;
        *) _report_append_error "catalog-check-kind" "${check_id}" "invalid check kind ${check_kind}: ${check_id}"; return 1 ;;
    esac
    case "${test_method}" in
        real-path|direct-inspection) ;;
        *) _report_append_error "catalog-test-method" "${check_id}" "invalid test method ${test_method}: ${check_id}"; return 1 ;;
    esac
    if ! _report_text_is_valid "${description}"; then
        _report_append_error "catalog-check-description" "${check_id}" "invalid check description: ${check_id}"
        return 1
    fi

    REPORT_CHECK_IDS+=("${check_id}")
    REPORT_CHECK_SEEN["${check_id}"]=1
    REPORT_CHECK_STEP["${check_id}"]="${step_id}"
    REPORT_CHECK_CATEGORY["${check_id}"]="${category}"
    REPORT_CHECK_KIND["${check_id}"]="${check_kind}"
    REPORT_CHECK_METHOD["${check_id}"]="${test_method}"
    REPORT_CHECK_DESCRIPTION["${check_id}"]="${description}"
}

function report_close_catalog {
    _report_require_lifetime "report_close_catalog" || return 1
    if (( REPORT_CATALOG_CLOSED )); then
        _report_append_error "catalog-duplicate-close" "-" "catalog closed more than once"
        return 1
    fi
    if (( ${#REPORT_STEP_IDS[@]} == 0 || ${#REPORT_CHECK_IDS[@]} == 0 )); then
        _report_append_error "catalog-empty" "-" "catalog requires at least one STEP and check"
        return 1
    fi
    if (( ! REPORT_CATALOG_VALID )); then
        return 1
    fi
    REPORT_CATALOG_CLOSED=1
}

function _report_ledger_has_state {
    local target_id="$1"
    local record_type=""
    local field2=""
    local field3=""
    local field4=""
    local extra=""

    while IFS=$'\t' read -r record_type field2 field3 field4 extra || [[ -n "${record_type:-}" ]]; do
        if [[ "${record_type}" == "STATE" && "${field2}" == "${target_id}" ]]; then
            return 0
        fi
    done < "${REPORT_LEDGER_FILE}"
    return 1
}

function report_record {
    local check_id="$1"
    local state="$2"
    local reason="${3:-}"
    local reason_b64="-"

    _report_require_lifetime "report_record" || return 1
    if (( ! REPORT_CATALOG_CLOSED )); then
        _report_append_error "event-before-catalog-close" "${check_id:-'-'}" "terminal state before catalog close: ${check_id:-<empty>}"
        return 1
    fi
    if [[ -z "${REPORT_CHECK_SEEN[${check_id}]:-}" ]]; then
        _report_append_error "event-unknown-id" "${check_id:-'-'}" "unknown check identity: ${check_id:-<empty>}"
        return 1
    fi
    case "${state}" in
        PASS|FAIL|SKIP|NA|SCRIPT_ERROR) ;;
        *) _report_append_error "event-invalid-state" "${check_id}" "invalid terminal state ${state}: ${check_id}"; return 1 ;;
    esac
    if [[ "${state}" == "PASS" && -n "${reason}" ]]; then
        _report_append_error "event-pass-reason" "${check_id}" "PASS must not carry a reason: ${check_id}"
        return 1
    fi
    if [[ "${state}" != "PASS" ]] && ! _report_text_is_valid "${reason}"; then
        _report_append_error "event-missing-reason" "${check_id}" "${state} requires a one-line reason: ${check_id}"
        return 1
    fi
    if _report_ledger_has_state "${check_id}"; then
        _report_append_error "event-duplicate-state" "${check_id}" "duplicate terminal state: ${check_id}"
        return 1
    fi
    if [[ "${state}" != "PASS" ]]; then
        reason_b64=$(_report_b64url_encode "${reason}")
    fi
    printf 'STATE\t%s\t%s\t%s\n' "${check_id}" "${state}" "${reason_b64}" >> "${REPORT_LEDGER_FILE}"
}

function _report_cleanup_workspace {
    local cleanup_status=0
    local ledger_dir="${REPORT_LEDGER_DIR}"
    local ledger_file="${REPORT_LEDGER_FILE}"

    if [[ -z "${ledger_dir}" || -z "${ledger_file}" ||
          ! -d "${ledger_dir}" || -L "${ledger_dir}" ]]; then
        printf 'REPORTING ERROR: reporter workspace is unavailable or symbolic: %s\n' \
            "${ledger_dir:-<empty>}" >&2
        cleanup_status=1
    elif ! "${REPORT_RM_BIN}" -f -- "${ledger_file}" 2>/dev/null ||
         [[ -e "${ledger_file}" || -L "${ledger_file}" ]]; then
        printf 'REPORTING ERROR: failed to remove reporter ledger: %s\n' "${ledger_file}" >&2
        cleanup_status=1
    elif ! "${REPORT_RMDIR_BIN}" -- "${ledger_dir}" 2>/dev/null ||
         [[ -e "${ledger_dir}" || -L "${ledger_dir}" ]]; then
        printf 'REPORTING ERROR: failed to remove reporter workspace: %s\n' "${ledger_dir}" >&2
        cleanup_status=1
    fi

    REPORT_LEDGER_FILE=""
    REPORT_LEDGER_DIR=""
    return "${cleanup_status}"
}

function report_finalize {
    local requested_exit="${1:-0}"
    local record_type=""
    local field2=""
    local field3=""
    local field4=""
    local extra=""
    local check_id=""
    local step_id=""
    local reason=""
    local reason_b64=""
    local state=""
    local error_code=""
    local error_target=""
    local total=0
    local pass_count=0
    local fail_count=0
    local skip_count=0
    local na_count=0
    local error_count=0
    local integrity_error=0
    local invalid_projection=0
    local cleanup_error=0
    local suite_state="FAIL"
    local -a integrity_details=()
    local -A resolved_state=()
    local -A resolved_reason=()
    local -A resolved_reason_b64=()
    local -A state_seen=()
    local -A step_pass=()
    local -A step_fail=()
    local -A step_skip=()
    local -A step_na=()
    local -A step_error=()

    if (( REPORT_FINALIZED )); then
        return "${REPORT_FINAL_STATUS}"
    fi
    if (( ! REPORT_INITIALIZED )); then
        printf '%s\n' "REPORTING ERROR: report_finalize before report_init" >&2
        return 1
    fi
    if [[ ! "${requested_exit}" =~ ^(0|[1-9][0-9]{0,2})$ ]] || (( 10#${requested_exit} > 255 )); then
        REPORT_FINALIZED=1
        REPORT_FINAL_STATUS=1
        printf 'REPORTING ERROR: invalid suite exit status: %s\n' "${requested_exit}" >&2
        _report_cleanup_workspace || true
        return 1
    fi
    requested_exit=$((10#${requested_exit}))
    REPORT_FINALIZED=1

    if (( ! REPORT_CATALOG_CLOSED )); then
        integrity_error=1
        invalid_projection=1
        integrity_details+=("catalog was not closed")
    fi

    for check_id in "${REPORT_CHECK_IDS[@]}"; do
        if ! _report_text_is_valid "${REPORT_CHECK_DESCRIPTION[${check_id}]}"; then
            integrity_error=1
            invalid_projection=1
            integrity_details+=("missing catalog description: ${check_id}")
        fi
        resolved_state["${check_id}"]="OPEN"
        resolved_reason["${check_id}"]=""
        resolved_reason_b64["${check_id}"]="-"
    done
    for step_id in "${REPORT_STEP_IDS[@]}"; do
        if ! _report_text_is_valid "${REPORT_STEP_DESCRIPTION[${step_id}]}"; then
            integrity_error=1
            invalid_projection=1
            integrity_details+=("missing STEP description: ${step_id}")
        fi
        step_pass["${step_id}"]=0
        step_fail["${step_id}"]=0
        step_skip["${step_id}"]=0
        step_na["${step_id}"]=0
        step_error["${step_id}"]=0
    done

    while IFS=$'\t' read -r record_type field2 field3 field4 extra || [[ -n "${record_type:-}" ]]; do
        if [[ -n "${extra}" ]]; then
            integrity_error=1
            invalid_projection=1
            integrity_details+=("malformed ledger row")
            continue
        fi
        case "${record_type}" in
            STATE)
                check_id="${field2}"
                state="${field3}"
                reason_b64="${field4}"
                if [[ -z "${REPORT_CHECK_SEEN[${check_id}]:-}" ]]; then
                    integrity_error=1
                    invalid_projection=1
                    integrity_details+=("unknown ledger identity: ${check_id}")
                    continue
                fi
                if [[ -n "${state_seen[${check_id}]:-}" ]]; then
                    integrity_error=1
                    resolved_state["${check_id}"]="SCRIPT_ERROR"
                    resolved_reason["${check_id}"]="duplicate terminal state"
                    resolved_reason_b64["${check_id}"]=$(_report_b64url_encode "duplicate terminal state")
                    integrity_details+=("duplicate terminal state: ${check_id}")
                    continue
                fi
                state_seen["${check_id}"]=1
                case "${state}" in
                    PASS)
                        if [[ "${reason_b64}" != "-" ]]; then
                            integrity_error=1
                            state="SCRIPT_ERROR"
                            reason="PASS carried a reason"
                            reason_b64=$(_report_b64url_encode "${reason}")
                            integrity_details+=("PASS carried a reason: ${check_id}")
                        else
                            reason=""
                        fi
                        ;;
                    FAIL|SKIP|NA|SCRIPT_ERROR)
                        if [[ ! "${reason_b64}" =~ ^[A-Za-z0-9_-]+$ ]] || ! reason=$(_report_b64url_decode "${reason_b64}"); then
                            integrity_error=1
                            state="SCRIPT_ERROR"
                            reason="invalid encoded reason"
                            reason_b64=$(_report_b64url_encode "${reason}")
                            integrity_details+=("invalid encoded reason: ${check_id}")
                        fi
                        ;;
                    *)
                        integrity_error=1
                        state="SCRIPT_ERROR"
                        reason="invalid terminal state in ledger"
                        reason_b64=$(_report_b64url_encode "${reason}")
                        integrity_details+=("invalid terminal state: ${check_id}")
                        ;;
                esac
                resolved_state["${check_id}"]="${state}"
                resolved_reason["${check_id}"]="${reason}"
                resolved_reason_b64["${check_id}"]="${reason_b64}"
                ;;
            ERROR)
                error_code="${field2}"
                error_target="${field3}"
                reason_b64="${field4}"
                integrity_error=1
                if [[ "${reason_b64}" =~ ^[A-Za-z0-9_-]+$ ]] && reason=$(_report_b64url_decode "${reason_b64}"); then
                    integrity_details+=("${reason}")
                else
                    integrity_details+=("malformed reporter error")
                    invalid_projection=1
                fi
                if [[ -n "${REPORT_CHECK_SEEN[${error_target}]:-}" && "${error_code}" == event-* ]]; then
                    resolved_state["${error_target}"]="SCRIPT_ERROR"
                    resolved_reason["${error_target}"]="${reason:-reporting integrity error}"
                    resolved_reason_b64["${error_target}"]=$(_report_b64url_encode "${resolved_reason[${error_target}]}")
                    state_seen["${error_target}"]=1
                else
                    invalid_projection=1
                fi
                ;;
            "") ;;
            *)
                integrity_error=1
                invalid_projection=1
                integrity_details+=("unknown ledger record type: ${record_type}")
                ;;
        esac
    done < "${REPORT_LEDGER_FILE}"

    if ! _report_cleanup_workspace; then
        cleanup_error=1
    fi

    for check_id in "${REPORT_CHECK_IDS[@]}"; do
        if [[ "${resolved_state[${check_id}]}" == "OPEN" ]]; then
            resolved_state["${check_id}"]="SCRIPT_ERROR"
            if (( requested_exit != 0 )); then
                reason="suite exited with status ${requested_exit} before check completed"
            else
                reason="check did not reach a terminal state"
            fi
            resolved_reason["${check_id}"]="${reason}"
            resolved_reason_b64["${check_id}"]=$(_report_b64url_encode "${reason}")
            integrity_error=1
            integrity_details+=("${reason}: ${check_id}")
        fi
    done

    if (( invalid_projection || ! REPORT_CATALOG_VALID )); then
        printf '%s\n' "REPORTING ERROR: no valid projection was produced" >&2
        for reason in "${integrity_details[@]}"; do
            printf '  * %s\n' "${reason}" >&2
        done
        REPORT_FINAL_STATUS=1
        return 1
    fi

    for check_id in "${REPORT_CHECK_IDS[@]}"; do
        state="${resolved_state[${check_id}]}"
        step_id="${REPORT_CHECK_STEP[${check_id}]}"
        total=$((total + 1))
        case "${state}" in
            PASS) pass_count=$((pass_count + 1)); step_pass["${step_id}"]=$((step_pass["${step_id}"] + 1)) ;;
            FAIL) fail_count=$((fail_count + 1)); step_fail["${step_id}"]=$((step_fail["${step_id}"] + 1)) ;;
            SKIP) skip_count=$((skip_count + 1)); step_skip["${step_id}"]=$((step_skip["${step_id}"] + 1)) ;;
            NA) na_count=$((na_count + 1)); step_na["${step_id}"]=$((step_na["${step_id}"] + 1)) ;;
            SCRIPT_ERROR) error_count=$((error_count + 1)); step_error["${step_id}"]=$((step_error["${step_id}"] + 1)) ;;
            *) integrity_error=1; invalid_projection=1 ;;
        esac
    done
    if (( invalid_projection || total != pass_count + fail_count + skip_count + na_count + error_count )); then
        printf '%s\n' "REPORTING ERROR: summary invariant violated" >&2
        REPORT_FINAL_STATUS=1
        return 1
    fi

    REPORT_FINAL_STATUS=0
    if (( requested_exit != 0 || fail_count > 0 || error_count > 0 || integrity_error || cleanup_error )); then
        REPORT_FINAL_STATUS=1
    fi
    if (( REPORT_FINAL_STATUS == 0 )); then
        suite_state="PASS"
    fi

    printf '%s\n' "===================================================================================================="
    printf '%s\n' "${REPORT_SUITE} TEST SUMMARY"
    printf '%s\n' "===================================================================================================="
    printf '  %-20s : %d\n' "Total Assertions" "${total}"
    printf '  %-20s : %d\n' "Passed" "${pass_count}"
    printf '  %-20s : %d\n' "Failed" "${fail_count}"
    printf '  %-20s : %d\n' "Skipped" "${skip_count}"
    printf '  %-20s : %d\n' "Not applicable" "${na_count}"
    printf '  %-20s : %d\n' "Script Errors" "${error_count}"
    printf '  %-20s : %s\n' "Suite State" "${suite_state}"
    if (( fail_count + skip_count + na_count + error_count > 0 )); then
        printf '%s\n' ""
        printf '%s\n' "--- [ NON-PASS CHECKS ] ---"
        for check_id in "${REPORT_CHECK_IDS[@]}"; do
            state="${resolved_state[${check_id}]}"
            if [[ "${state}" != "PASS" ]]; then
                printf '  * %s [%s/%s] %s: %s\n' \
                    "${check_id}" \
                    "${REPORT_CHECK_KIND[${check_id}]}" \
                    "${REPORT_CHECK_METHOD[${check_id}]}" \
                    "${state}" \
                    "${resolved_reason[${check_id}]}"
            fi
        done
    fi
    printf '%s\n' "===================================================================================================="

    for check_id in "${REPORT_CHECK_IDS[@]}"; do
        printf 'TEST suite=%s run=%s step=%s id=%s category=%s kind=%s method=%s state=%s reason_b64=%s\n' \
            "${REPORT_SUITE}" \
            "${REPORT_RUN_ID}" \
            "${REPORT_CHECK_STEP[${check_id}]}" \
            "${check_id}" \
            "${REPORT_CHECK_CATEGORY[${check_id}]}" \
            "${REPORT_CHECK_KIND[${check_id}]}" \
            "${REPORT_CHECK_METHOD[${check_id}]}" \
            "${resolved_state[${check_id}]}" \
            "${resolved_reason_b64[${check_id}]}"
    done
    for step_id in "${REPORT_STEP_IDS[@]}"; do
        printf 'STEP suite=%s run=%s step=%s pass=%d fail=%d skip=%d na=%d err=%d\n' \
            "${REPORT_SUITE}" \
            "${REPORT_RUN_ID}" \
            "${step_id}" \
            "${step_pass[${step_id}]}" \
            "${step_fail[${step_id}]}" \
            "${step_skip[${step_id}]}" \
            "${step_na[${step_id}]}" \
            "${step_error[${step_id}]}"
    done
    printf 'SUITE suite=%s run=%s scope=%s runner=%s os=%s arch=%s total=%d pass=%d fail=%d skip=%d na=%d err=%d state=%s\n' \
        "${REPORT_SUITE}" \
        "${REPORT_RUN_ID}" \
        "${REPORT_SCOPE}" \
        "${REPORT_RUNNER}" \
        "${REPORT_OS}" \
        "${REPORT_ARCH}" \
        "${total}" \
        "${pass_count}" \
        "${fail_count}" \
        "${skip_count}" \
        "${na_count}" \
        "${error_count}" \
        "${suite_state}"

    return "${REPORT_FINAL_STATUS}"
}
