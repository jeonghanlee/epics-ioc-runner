#!/bin/bash
# Run the canonical six-run suite matrix on two hosts and preserve separate
# machine and human evidence for every producer. The control host validates each
# machine block before aggregation, then checks the fixed identity and state
# matrix and records normalized cross-host differences.
#
# $1 first host, as user@address
# $2 absolute EPICS environment path on the first host
# $3 second host, as user@address
# $4 absolute EPICS environment path on the second host
# $5 optional --remote-repo flag
# $6 optional absolute repository path shared by both hosts
set -euo pipefail

export PATH="/usr/local/bin:/usr/bin:/bin"
unset BASH_ENV ENV CDPATH
umask 077

readonly EXPECTED_IDENTITY_SHA256="d2c25a1cfdd26f70bc4e7646bde85fc4443299d7ce95ecd4d39577641feaf1bd"
readonly DEFAULT_REMOTE_REPO="\${HOME}/gitsrc/epics-ioc-runner"
REMOTE_REPO="${DEFAULT_REMOTE_REPO}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR
DRIVER_PATH="${SCRIPT_DIR}/$(basename "$0")"
readonly DRIVER_PATH
REPO_TOP="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
readonly REPO_TOP
readonly REPORT_COUNTS_FILE="${REPO_TOP}/tests/reporting-counts.csv"
# shellcheck source=tests/lib/test-record-validator.bash
source "${REPO_TOP}/tests/lib/test-record-validator.bash"
readonly OUTPUT_ROOT="${REPO_TOP}/work"
RUN_ID="$(date -u +%Y%m%dT%H%M%SZ)-$$"
readonly RUN_ID
readonly RUN_DIR="${OUTPUT_ROOT}/gate-suites-${RUN_ID}"
readonly -a SSH_CMD=(ssh -n -o BatchMode=yes -o ConnectTimeout=10)

declare -A HOST_HEAD=()
declare -A HOST_REPO=()
CONTROL_DRIVER_SHA256=""
readonly CONTROL_STATUS_FILE="${RUN_DIR}/control.status"
readonly CONTROL_META_FILE="${RUN_DIR}/control.meta"
readonly CONTROL_DRIVER_SNAPSHOT="${RUN_DIR}/control-driver.bash"

function die {
    local message="$1"
    printf 'gate suites: %s\n' "${message}" >&2
    exit 1
}

function usage {
    printf 'Usage: %s <host-1> <epics-env-1> <host-2> <epics-env-2> [--remote-repo <absolute-path>]\n' "$0"
}

function require_command {
    local command_name="$1"
    local command_path=""

    if ! command_path="$(command -v "${command_name}")" || [[ ! -x "${command_path}" ]]; then
        die "required command is unavailable: ${command_name}"
    fi
}

function validate_host {
    local host="$1"

    if [[ ! "${host}" =~ ^[A-Za-z0-9._-]+@[A-Za-z0-9._:-]+$ ]]; then
        die "invalid host: ${host}"
    fi
}

function validate_remote_path {
    local path="$1"

    if [[ ! "${path}" =~ ^/[A-Za-z0-9._/+:-]+$ ]]; then
        die "invalid remote path: ${path}"
    fi
}

function token_for_host {
    local host="$1"
    local token="${host//@/_}"

    token="${token//:/_}"
    printf '%s\n' "${token}"
}

function preflight_host {
    local host="$1"
    local env_path="$2"
    local token="$3"
    local output=""
    local head=""
    local repo=""
    local line=""
    local remote_command=""

    remote_command="test -d ${REMOTE_REPO}/tests && test -r '${env_path}' && for c in bash awk sort sha256sum git cat date sudo stat id env; do p=\$(command -v \"\${c}\") && test -x \"\${p}\" || exit 1; done && sudo -n true && printf 'HEAD %s\\n' \"\$(git -C ${REMOTE_REPO} rev-parse HEAD)\" && printf 'REPO %s\\n' \"\$(cd ${REMOTE_REPO} && pwd)\""
    if ! output="$("${SSH_CMD[@]}" "${host}" "${remote_command}")"; then
        die "host preflight failed: ${host}"
    fi

    while IFS= read -r line; do
        if [[ "${line}" == HEAD\ * ]]; then
            head="${line#HEAD }"
        elif [[ "${line}" == REPO\ * ]]; then
            repo="${line#REPO }"
        fi
    done <<< "${output}"
    if [[ ! "${head}" =~ ^[0-9a-f]{40}$ ]]; then
        die "host preflight returned no commit identity: ${host}"
    fi
    if [[ ! "${repo}" =~ ^/[A-Za-z0-9._/+:-]+$ ]]; then
        die "host preflight returned no repository path: ${host}"
    fi
    HOST_HEAD["${token}"]="${head}"
    HOST_REPO["${token}"]="${repo}"
    printf 'PREFLIGHT host=%s env=%s head=%s repo=%s\n' "${host}" "${env_path}" "${head}" "${repo}"
}

function verify_remote_runner_provenance {
    local host="$1"
    local token="$2"
    local repo="${HOST_REPO[${token}]}"
    local evidence_file="${RUN_DIR}/${token}.runner"
    local remote_command=""
    local output=""

    remote_command="source_file='${repo}/bin/ioc-runner'; "
    remote_command+="installed_file='/usr/local/bin/ioc-runner'; "
    remote_command+="test -r \"\${source_file}\" && test -r \"\${installed_file}\"; "
    remote_command+="source_sha=\$(awk '\$0 !~ /^declare -g RUNNER_(GIT_HASH|COMMIT_DATE|INSTALL_DATE)=/' \"\${source_file}\" | sha256sum | awk '{print \$1}'); "
    remote_command+="installed_sha=\$(awk '\$0 !~ /^declare -g RUNNER_(GIT_HASH|COMMIT_DATE|INSTALL_DATE)=/' \"\${installed_file}\" | sha256sum | awk '{print \$1}'); "
    remote_command+="expected_identity=\$(git -C '${repo}' rev-parse --short HEAD); "
    remote_command+="if ! git -C '${repo}' diff --quiet HEAD --; then expected_identity=\"\${expected_identity}-dirty\"; fi; "
    remote_command+="actual_identity=\$(\"\${installed_file}\" -V | awk 'NR == 1 { value=\$0; sub(/^.*\\(/, \"\", value); sub(/\\).*$/, \"\", value); print value }'); "
    remote_command+="state=PASS; if [ \"\${source_sha}\" != \"\${installed_sha}\" ] || [ \"\${actual_identity}\" != \"\${expected_identity}\" ]; then state=FAIL; fi; "
    remote_command+="printf 'RUNNER_PROVENANCE host=${host} source_body_sha256=%s installed_body_sha256=%s identity=%s expected_identity=%s state=%s\\n' \"\${source_sha}\" \"\${installed_sha}\" \"\${actual_identity}\" \"\${expected_identity}\" \"\${state}\"; "
    remote_command+="test \"\${state}\" = PASS"

    if ! output="$("${SSH_CMD[@]}" "${host}" "${remote_command}")"; then
        printf '%s\n' "${output}" > "${evidence_file}"
        printf 'gate suites: runner provenance check failed: %s\n' "${host}" >&2
        return 1
    fi
    if [[ ! "${output}" =~ ^RUNNER_PROVENANCE[[:space:]]host=[A-Za-z0-9._@:-]+[[:space:]]source_body_sha256=[0-9a-f]{64}[[:space:]]installed_body_sha256=[0-9a-f]{64}[[:space:]]identity=[0-9a-f]+(-dirty)?[[:space:]]expected_identity=[0-9a-f]+(-dirty)?[[:space:]]state=PASS$ ]]; then
        printf '%s\n' "${output}" > "${evidence_file}"
        printf 'gate suites: runner provenance returned an invalid record: %s\n' "${host}" >&2
        return 1
    fi
    printf '%s\n' "${output}" | tee "${evidence_file}"
}

function capture_control_provenance {
    local control_head=""
    local control_dirty="false"
    local control_status_count=0
    local control_status_sha256=""
    local snapshot_sha256=""

    if ! control_head="$(git -C "${REPO_TOP}" rev-parse HEAD)" ||
       [[ ! "${control_head}" =~ ^[0-9a-f]{40}$ ]]; then
        die "control repository returned no commit identity"
    fi
    git -C "${REPO_TOP}" status --porcelain > "${CONTROL_STATUS_FILE}"
    control_status_count="$(wc -l < "${CONTROL_STATUS_FILE}")"
    if (( control_status_count > 0 )); then
        control_dirty="true"
    fi
    control_status_sha256="$(sha256sum "${CONTROL_STATUS_FILE}" | awk '{print $1}')"

    cp -- "${DRIVER_PATH}" "${CONTROL_DRIVER_SNAPSHOT}"
    chmod 0600 "${CONTROL_DRIVER_SNAPSHOT}"
    CONTROL_DRIVER_SHA256="$(sha256sum "${DRIVER_PATH}" | awk '{print $1}')"
    snapshot_sha256="$(sha256sum "${CONTROL_DRIVER_SNAPSHOT}" | awk '{print $1}')"
    if [[ "${CONTROL_DRIVER_SHA256}" != "${snapshot_sha256}" ]]; then
        die "control driver and evidence snapshot hashes differ"
    fi

    printf 'CONTROL repo=%s head=%s dirty=%s status_count=%d status_sha256=%s driver=%s driver_sha256=%s snapshot=%s snapshot_sha256=%s\n' \
        "${REPO_TOP}" "${control_head}" "${control_dirty}" "${control_status_count}" \
        "${control_status_sha256}" "${DRIVER_PATH}" "${CONTROL_DRIVER_SHA256}" \
        "${CONTROL_DRIVER_SNAPSHOT}" "${snapshot_sha256}" \
        > "${CONTROL_META_FILE}"
    cat "${CONTROL_META_FILE}"
}

function control_provenance_unchanged {
    local final_driver_sha256=""
    local final_snapshot_sha256=""

    if ! final_driver_sha256="$(sha256sum "${DRIVER_PATH}" | awk '{print $1}')"; then
        printf 'gate suites: failed to hash the control driver at finalization\n' >&2
        return 1
    fi
    if [[ "${final_driver_sha256}" != "${CONTROL_DRIVER_SHA256}" ]]; then
        printf 'gate suites: control driver changed during the run: initial=%s final=%s\n' \
            "${CONTROL_DRIVER_SHA256}" "${final_driver_sha256}" >&2
        return 1
    fi
    if ! final_snapshot_sha256="$(sha256sum "${CONTROL_DRIVER_SNAPSHOT}" | awk '{print $1}')"; then
        printf 'gate suites: failed to hash the control driver snapshot at finalization\n' >&2
        return 1
    fi
    if [[ "${final_snapshot_sha256}" != "${CONTROL_DRIVER_SHA256}" ]]; then
        printf 'gate suites: control driver snapshot changed during the run: initial=%s final=%s\n' \
            "${CONTROL_DRIVER_SHA256}" "${final_snapshot_sha256}" >&2
        return 1
    fi
}

function run_remote_suite {
    local host="$1"
    local token="$2"
    local suite="$3"
    local scope="$4"
    local runner="$5"
    local suite_command="$6"
    local status_file="$7"
    local evidence_stem="${suite}.${scope}.${runner}"
    local remote_stem="/tmp/ioc-runner-gate-suites-${RUN_ID}-${token}-${evidence_stem}"
    local remote_machine="${remote_stem}.machine"
    local remote_human="${remote_stem}.human"
    local local_machine="${RUN_DIR}/${token}.${evidence_stem}.machine"
    local local_human="${RUN_DIR}/${token}.${evidence_stem}.human"
    local remote_command=""
    local output=""
    local run_line=""
    local files_line=""
    local candidate=""
    local producer_status=0
    local owner_uid=""
    local machine_uid=""
    local human_uid=""
    local remote_machine_sha=""
    local remote_human_sha=""
    local local_machine_sha=""
    local local_human_sha=""
    local evidence_state=""
    local validated_run=""
    local validated_suite=""

    remote_command="umask 077; t0=\$(date +%s); rc=0; { cd ${REMOTE_REPO} && ${suite_command}; } > '${remote_machine}' 2> '${remote_human}' || rc=\$?; t1=\$(date +%s); owner_uid=\$(id -u); machine_uid=\$(stat -c '%u' -- '${remote_machine}' 2>/dev/null || printf invalid); human_uid=\$(stat -c '%u' -- '${remote_human}' 2>/dev/null || printf invalid); machine_sha=\$(sha256sum '${remote_machine}' 2>/dev/null | awk '{print \$1}'); human_sha=\$(sha256sum '${remote_human}' 2>/dev/null | awk '{print \$1}'); evidence=PASS; if test \"\${machine_uid}\" != \"\${owner_uid}\" || test \"\${human_uid}\" != \"\${owner_uid}\" || test ! -r '${remote_machine}' || test ! -r '${remote_human}'; then evidence=FAIL; fi; printf 'RUN suite=${suite} scope=${scope} runner=${runner} rc=%s elapsed=%ss\\n' \"\${rc}\" \"\$((t1 - t0))\"; printf 'FILES suite=${suite} scope=${scope} runner=${runner} owner_uid=%s machine_uid=%s human_uid=%s machine_sha256=%s human_sha256=%s state=%s\\n' \"\${owner_uid}\" \"\${machine_uid}\" \"\${human_uid}\" \"\${machine_sha}\" \"\${human_sha}\" \"\${evidence}\"; exit 0"
    if ! output="$("${SSH_CMD[@]}" "${host}" "${remote_command}")"; then
        printf 'gate suites: suite transport failed: host=%s suite=%s runner=%s\n' \
            "${host}" "${suite}" "${runner}" >&2
        return 1
    fi

    while IFS= read -r candidate; do
        if [[ "${candidate}" == RUN\ * ]]; then
            run_line="${candidate}"
        elif [[ "${candidate}" == FILES\ * ]]; then
            files_line="${candidate}"
        fi
    done <<< "${output}"
    if [[ ! "${run_line}" =~ ^RUN[[:space:]]suite=${suite}[[:space:]]scope=${scope}[[:space:]]runner=${runner}[[:space:]]rc=([0-9]+)[[:space:]]elapsed=[0-9]+s$ ]]; then
        printf 'gate suites: suite returned no valid run status: host=%s suite=%s runner=%s\n' \
            "${host}" "${suite}" "${runner}" >&2
        return 1
    fi
    producer_status="${BASH_REMATCH[1]}"
    if [[ ! "${files_line}" =~ ^FILES[[:space:]]suite=${suite}[[:space:]]scope=${scope}[[:space:]]runner=${runner}[[:space:]]owner_uid=([0-9]+)[[:space:]]machine_uid=([0-9]+)[[:space:]]human_uid=([0-9]+)[[:space:]]machine_sha256=([0-9a-f]{64})[[:space:]]human_sha256=([0-9a-f]{64})[[:space:]]state=(PASS|FAIL)$ ]]; then
        printf 'gate suites: suite returned no valid evidence status: host=%s suite=%s runner=%s\n' \
            "${host}" "${suite}" "${runner}" >&2
        return 1
    fi
    owner_uid="${BASH_REMATCH[1]}"
    machine_uid="${BASH_REMATCH[2]}"
    human_uid="${BASH_REMATCH[3]}"
    remote_machine_sha="${BASH_REMATCH[4]}"
    remote_human_sha="${BASH_REMATCH[5]}"
    evidence_state="${BASH_REMATCH[6]}"
    if [[ "${evidence_state}" != "PASS" || "${machine_uid}" != "${owner_uid}" ||
          "${human_uid}" != "${owner_uid}" ]]; then
        printf 'gate suites: remote evidence ownership failed: host=%s suite=%s runner=%s\n' \
            "${host}" "${suite}" "${runner}" >&2
        return 1
    fi

    if ! "${SSH_CMD[@]}" "${host}" "cat '${remote_machine}'" > "${local_machine}" ||
       ! "${SSH_CMD[@]}" "${host}" "cat '${remote_human}'" > "${local_human}"; then
        printf 'gate suites: failed to copy per-run evidence: host=%s suite=%s runner=%s\n' \
            "${host}" "${suite}" "${runner}" >&2
        return 1
    fi
    local_machine_sha="$(sha256sum "${local_machine}" | awk '{print $1}')"
    local_human_sha="$(sha256sum "${local_human}" | awk '{print $1}')"
    if [[ "${local_machine_sha}" != "${remote_machine_sha}" ||
          "${local_human_sha}" != "${remote_human_sha}" ]]; then
        printf 'gate suites: remote and local evidence hashes differ: host=%s suite=%s runner=%s\n' \
            "${host}" "${suite}" "${runner}" >&2
        return 1
    fi
    if ! test_record_validate_file "${local_machine}" "${suite}" "${scope}" "${runner}" \
        "${producer_status}" validated_run validated_suite; then
        printf 'gate suites: machine evidence failed validation: host=%s suite=%s runner=%s\n' \
            "${host}" "${suite}" "${runner}" >&2
        return 1
    fi

    printf '%s\n' "${run_line}" | tee -a "${status_file}"
    printf 'EVIDENCE suite=%s scope=%s runner=%s run=%s machine=%s human=%s machine_sha256=%s human_sha256=%s\n' \
        "${suite}" "${scope}" "${runner}" "${validated_run}" \
        "${local_machine}" "${local_human}" "${local_machine_sha}" "${local_human_sha}"
    : "${validated_suite}"
}

function run_host {
    local host="$1"
    local env_path="$2"
    local token="$3"
    local status_file="${RUN_DIR}/${token}.status"
    local local_machine="${RUN_DIR}/${token}.machine"
    local local_human="${RUN_DIR}/${token}.human"
    local meta_file="${RUN_DIR}/${token}.meta"
    local command_prefix="{ . '${env_path}'; } >&2 &&"
    local specification=""
    local suite=""
    local scope=""
    local runner=""
    local evidence_stem=""
    local -a run_order=(
        "error-handling none source"
        "source-regression system source"
        "local-lifecycle local source"
        "local-lifecycle local installed"
        "system-infra system none"
        "system-lifecycle system installed"
    )

    : > "${status_file}"
    : > "${local_machine}"
    : > "${local_human}"
    printf 'HOST START host=%s env=%s machine=%s human=%s\n' \
        "${host}" "${env_path}" "${local_machine}" "${local_human}"

    run_remote_suite "${host}" "${token}" error-handling none source \
        "env REPORT_MACHINE_OUTPUT=1 bash tests/test-error-handling.bash" \
        "${status_file}" || return 1
    run_remote_suite "${host}" "${token}" source-regression system source \
        "sudo -n true >&2 && env REPORT_MACHINE_OUTPUT=1 bash tests/run-all-tests.bash --source-regression" \
        "${status_file}" || return 1
    run_remote_suite "${host}" "${token}" local-lifecycle local source \
        "${command_prefix} bash gate/drivers/remote/run-local-lifecycle.bash source" \
        "${status_file}" || return 1
    run_remote_suite "${host}" "${token}" local-lifecycle local installed \
        "${command_prefix} bash gate/drivers/remote/run-local-lifecycle.bash installed" \
        "${status_file}" || return 1
    run_remote_suite "${host}" "${token}" system-infra system none \
        "${command_prefix} IOC_RUNNER_TEST_MODE=installed sudo -nE env REPORT_MACHINE_OUTPUT=1 bash tests/test-system-infra.bash" \
        "${status_file}" || return 1
    run_remote_suite "${host}" "${token}" system-lifecycle system installed \
        "${command_prefix} IOC_RUNNER_TEST_MODE=installed sudo -nE env REPORT_MACHINE_OUTPUT=1 bash tests/test-system-lifecycle.bash" \
        "${status_file}" || return 1

    for specification in "${run_order[@]}"; do
        read -r suite scope runner <<< "${specification}"
        evidence_stem="${suite}.${scope}.${runner}"
        cat "${RUN_DIR}/${token}.${evidence_stem}.machine" >> "${local_machine}"
        cat "${RUN_DIR}/${token}.${evidence_stem}.human" >> "${local_human}"
    done

    printf 'HOST host=%s env=%s head=%s repo=%s machine=%s human=%s machine_sha256=%s human_sha256=%s\n' \
        "${host}" "${env_path}" "${HOST_HEAD[${token}]}" "${HOST_REPO[${token}]}" \
        "${local_machine}" "${local_human}" \
        "$(sha256sum "${local_machine}" | awk '{print $1}')" \
        "$(sha256sum "${local_human}" | awk '{print $1}')" \
        > "${meta_file}"
    cat "${meta_file}"
}

function validate_run_statuses {
    local status_file="$1"

    awk '
        function val(n, p) {
            if (index($n, p) != 1 || length($n) == length(p)) {
                bad++
                return ""
            }
            return substr($n, length(p) + 1)
        }
        BEGIN {
            want["error-handling/none/source"] = 1
            want_count++
            want["source-regression/system/source"] = 1
            want_count++
            want["local-lifecycle/local/source"] = 1
            want_count++
            want["local-lifecycle/local/installed"] = 1
            want_count++
            want["system-infra/system/none"] = 1
            want_count++
            want["system-lifecycle/system/installed"] = 1
            want_count++
        }
        {
            if (NF != 6 || $1 != "RUN") {
                bad++
                next
            }
            suite = val(2, "suite=")
            scope = val(3, "scope=")
            runner = val(4, "runner=")
            rc = val(5, "rc=")
            elapsed = val(6, "elapsed=")
            key = suite "/" scope "/" runner
            if (!(key in want) || seen[key]++ || rc !~ /^[0-9]+$/ || elapsed !~ /^[0-9]+s$/) {
                bad++
            }
            if (rc != 0) {
                printf "%s\n", $0
                failed++
            }
            count++
        }
        END {
            for (key in want) {
                if (seen[key] != 1) {
                    bad++
                }
            }
            if (count != want_count || failed != 0 || bad != 0) {
                printf "SUITES FAIL run_status blocks=%d failed=%d invalid=%d\n", count + 0, failed + 0, bad + 0
                exit 1
            }
        }
    ' "${status_file}"
}

function identity_sha256 {
    local log="$1"

    awk '
        BEGIN { OFS = "|" }
        $1 == "TEST" {
            run = substr($3, 5)
            count++
            runs[count] = run
            suites[count] = substr($2, 7)
            steps[count] = substr($4, 6)
            ids[count] = substr($5, 4)
            categories[count] = substr($6, 10)
            kinds[count] = substr($7, 6)
            methods[count] = substr($8, 8)
        }
        $1 == "SUITE" {
            run = substr($3, 5)
            scopes[run] = substr($4, 7)
            runners[run] = substr($5, 8)
        }
        END {
            for (i = 1; i <= count; i++) {
                print suites[i], scopes[runs[i]], runners[runs[i]], steps[i], ids[i], categories[i], kinds[i], methods[i]
            }
        }
    ' "${log}" | LC_ALL=C sort | sha256sum | awk '{print $1}'
}

function validate_runner_paths {
    local log="$1"
    local expected_source="$2"
    local line=""
    local path=""
    local -a paths=()

    while IFS= read -r line; do
        if [[ "${line}" == *'Runner under test: '* ]]; then
            path="${line#*Runner under test: }"
            paths+=("${path}")
        fi
    done < <(sed -e 's/\x1b\[[0-9;]*m//g' -e 's/\r//g' "${log}")

    if (( ${#paths[@]} != 3 )); then
        printf 'SUITES FAIL runner_paths count=%d expected=3\n' "${#paths[@]}"
        return 1
    fi
    if [[ "${paths[0]}" != "${expected_source}" ||
          "${paths[1]}" != "/usr/local/bin/ioc-runner" ||
          "${paths[2]}" != "/usr/local/bin/ioc-runner" ]]; then
        printf 'SUITES FAIL runner_paths source=%s local_installed=%s system_installed=%s\n' \
            "${paths[0]}" "${paths[1]}" "${paths[2]}"
        return 1
    fi
}

function matrix_verdict {
    local log="$1"

    if ! reporting_counts_load "${REPORT_COUNTS_FILE}"; then
        return 1
    fi
    awk '
        NR == FNR {
            if (NF != 3 || $1 !~ /^[-A-Za-z0-9._:+]+$/ ||
                $2 !~ /^[0-9]+$/ || $3 !~ /^[0-9]+$/ || ($1 in suite_want)) {
                config_bad++
                next
            }
            suite_want[$1] = $2 + 0
            suite_want_step[$1] = $3 + 0
            next
        }
        BEGIN {
            want_run["error-handling/none/source"] = 1
            want_run["source-regression/system/source"] = 1
            want_run["local-lifecycle/local/source"] = 1
            want_run["local-lifecycle/local/installed"] = 1
            want_run["system-infra/system/none"] = 1
            want_run["system-lifecycle/system/installed"] = 1
        }
        $1 == "TEST" {
            raw = $0
            suite = substr($2, 7)
            run = substr($3, 5)
            state = substr($9, 7)
            if (run_suite[run] != "" && run_suite[run] != suite) {
                bad++
            }
            run_suite[run] = suite
            test_count[run]++
            test_vector[run SUBSEP state]++
            if (state != "PASS") {
                exception_run[++exceptions] = run
                exception_line[exceptions] = raw
            }
            next
        }
        $1 == "STEP" {
            run = substr($3, 5)
            step_count[run]++
            next
        }
        $1 == "SUITE" {
            suite = substr($2, 7)
            run = substr($3, 5)
            scope = substr($4, 7)
            runner = substr($5, 8)
            total = substr($8, 7)
            state = substr($14, 7)
            wanted_key = suite "/" scope "/" runner
            if (!(wanted_key in want_run) || !(suite in suite_want) ||
                (run_suite[run] != "" && run_suite[run] != suite)) {
                bad++
            }
            run_suite[run] = suite
            if (suite_seen[run]++ || want_seen[wanted_key]++) {
                bad++
            }
            run_key[run] = wanted_key
            run_runner[run] = runner
            suite_total[run] = total + 0
            suite_exec[run] = state
            blocks++
            next
        }
        END {
            for (run in run_suite) {
                if (!suite_seen[run]) {
                    bad++
                }
            }
            for (wanted_key in want_run) {
                if (want_seen[wanted_key] != 1) {
                    bad++
                }
                split(wanted_key, wanted_parts, "/")
                expected_suite = wanted_parts[1]
                if (!(expected_suite in suite_want)) {
                    bad++
                } else {
                    expected_blocks++
                    expected_checks += suite_want[expected_suite]
                    expected_steps += suite_want_step[expected_suite]
                }
            }
            for (run in suite_seen) {
                checks += test_count[run]
                steps += step_count[run]
                expected_suite = run_suite[run]
                if (test_count[run] != suite_want[expected_suite] ||
                    step_count[run] != suite_want_step[expected_suite] ||
                    suite_total[run] != test_count[run] || suite_exec[run] != "PASS") {
                    bad++
                }
                skip += test_vector[run SUBSEP "SKIP"]
                fail += test_vector[run SUBSEP "FAIL"]
                na_total += test_vector[run SUBSEP "NA"]
                errors += test_vector[run SUBSEP "SCRIPT_ERROR"]
            }
            for (i = 1; i <= exceptions; i++) {
                print exception_line[i] " runner=" run_runner[exception_run[i]]
            }
            bad += config_bad
            if (blocks == expected_blocks && checks == expected_checks &&
                steps == expected_steps && skip == 0 && fail == 0 &&
                errors == 0 && bad == 0) {
                printf "SUITES OK (%d blocks, %d checks, na=%d)\n", expected_blocks, expected_checks, na_total
                exit 0
            }
            printf "SUITES FAIL blocks=%d checks=%d steps=%d skip=%d fail=%d na=%d err=%d invalid=%d\n", blocks + 0, checks + 0, steps + 0, skip + 0, fail + 0, na_total + 0, errors + 0, bad + 0
            exit 1
        }
    ' <(reporting_counts_emit_tsv) "${log}"
}

function validate_host_evidence {
    local machine_file="$1"
    local human_file="$2"
    local status_file="$3"
    local expected_source="$4"
    local actual_sha=""

    if ! validate_run_statuses "${status_file}"; then
        return 1
    fi
    if ! validate_runner_paths "${human_file}" "${expected_source}"; then
        return 1
    fi
    actual_sha="$(identity_sha256 "${machine_file}")"
    if [[ "${actual_sha}" != "${EXPECTED_IDENTITY_SHA256}" ]]; then
        printf 'SUITES FAIL identity_sha256=%s expected=%s\n' \
            "${actual_sha}" "${EXPECTED_IDENTITY_SHA256}"
        return 1
    fi
    matrix_verdict "${machine_file}"
}

function normalize_log {
    local log="$1"
    local output="$2"

    awk '
        $1 == "TEST" {
            run = substr($3, 5)
            counts[run]++
            records[run SUBSEP counts[run]] = $1 " " $2 " " $4 " " $5 " " $6 " " $7 " " $8 " " $9
        }
        $1 == "STEP" {
            run = substr($3, 5)
            counts[run]++
            records[run SUBSEP counts[run]] = $1 " " $2 " " $4 " " $5 " " $6 " " $7 " " $8 " " $9
        }
        $1 == "SUITE" {
            run = substr($3, 5)
            runners[run] = $5
        }
        END {
            for (run in counts) {
                for (i = 1; i <= counts[run]; i++) {
                    print records[run SUBSEP i], runners[run]
                }
            }
        }
    ' "${log}" | LC_ALL=C sort > "${output}"
}

function main {
    local host_one=""
    local env_one=""
    local host_two=""
    local env_two=""
    local token_one=""
    local token_two=""
    local pid_one=0
    local pid_two=0
    local drive_one_rc=0
    local drive_two_rc=0
    local verdict_one_rc=0
    local verdict_two_rc=0
    local diff_rc=0
    local diff_lines=0
    local overall_rc=0
    local drive_one=""
    local drive_two=""
    local verdict_one=""
    local verdict_two=""
    local normalized_one=""
    local normalized_two=""
    local cross_diff=""

    if [[ $# -eq 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then
        usage
        return 0
    fi
    if [[ $# -ne 4 && $# -ne 6 ]]; then
        usage >&2
        return 1
    fi
    if [[ $# -eq 6 ]]; then
        if [[ "$5" != "--remote-repo" ]]; then
            usage >&2
            return 1
        fi
        REMOTE_REPO="$6"
        validate_remote_path "${REMOTE_REPO}"
    fi

    host_one="$1"
    env_one="$2"
    host_two="$3"
    env_two="$4"
    validate_host "${host_one}"
    validate_remote_path "${env_one}"
    validate_host "${host_two}"
    validate_remote_path "${env_two}"
    if [[ "${host_one}" == "${host_two}" ]]; then
        die "the two hosts must be distinct"
    fi

    require_command ssh
    require_command awk
    require_command sort
    require_command sha256sum
    require_command diff
    require_command date
    require_command tee
    require_command cat
    require_command sed
    require_command wc
    require_command mkdir
    require_command git
    require_command cp
    require_command chmod

    token_one="$(token_for_host "${host_one}")"
    token_two="$(token_for_host "${host_two}")"
    if [[ "${token_one}" == "${token_two}" ]]; then
        die "the two hosts resolve to the same evidence token"
    fi
    mkdir -p "${OUTPUT_ROOT}"
    if [[ -e "${RUN_DIR}" ]]; then
        die "run directory already exists: ${RUN_DIR}"
    fi
    mkdir "${RUN_DIR}"
    printf 'EVIDENCE run=%s dir=%s\n' "${RUN_ID}" "${RUN_DIR}"
    capture_control_provenance

    preflight_host "${host_one}" "${env_one}" "${token_one}"
    preflight_host "${host_two}" "${env_two}" "${token_two}"
    if [[ "${HOST_HEAD[${token_one}]}" != "${HOST_HEAD[${token_two}]}" ]]; then
        die "the two host repositories must resolve to the same commit"
    fi
    verify_remote_runner_provenance "${host_one}" "${token_one}" || \
        die "runner provenance failed: ${host_one}"
    verify_remote_runner_provenance "${host_two}" "${token_two}" || \
        die "runner provenance failed: ${host_two}"

    drive_one="${RUN_DIR}/${token_one}.drive"
    drive_two="${RUN_DIR}/${token_two}.drive"
    run_host "${host_one}" "${env_one}" "${token_one}" > "${drive_one}" 2>&1 &
    pid_one=$!
    run_host "${host_two}" "${env_two}" "${token_two}" > "${drive_two}" 2>&1 &
    pid_two=$!
    wait "${pid_one}" || drive_one_rc=$?
    wait "${pid_two}" || drive_two_rc=$?
    cat "${drive_one}"
    cat "${drive_two}"

    verdict_one="${RUN_DIR}/${token_one}.verdict"
    verdict_two="${RUN_DIR}/${token_two}.verdict"
    if (( drive_one_rc == 0 )); then
        validate_host_evidence "${RUN_DIR}/${token_one}.machine" \
            "${RUN_DIR}/${token_one}.human" "${RUN_DIR}/${token_one}.status" \
            "${HOST_REPO[${token_one}]}/tests/../bin/ioc-runner" \
            > "${verdict_one}" || verdict_one_rc=$?
    else
        printf 'SUITES FAIL driver_rc=%d host=%s\n' "${drive_one_rc}" "${host_one}" > "${verdict_one}"
        verdict_one_rc=1
    fi
    if (( drive_two_rc == 0 )); then
        validate_host_evidence "${RUN_DIR}/${token_two}.machine" \
            "${RUN_DIR}/${token_two}.human" "${RUN_DIR}/${token_two}.status" \
            "${HOST_REPO[${token_two}]}/tests/../bin/ioc-runner" \
            > "${verdict_two}" || verdict_two_rc=$?
    else
        printf 'SUITES FAIL driver_rc=%d host=%s\n' "${drive_two_rc}" "${host_two}" > "${verdict_two}"
        verdict_two_rc=1
    fi
    printf 'VERDICT host=%s rc=%d file=%s\n' "${host_one}" "${verdict_one_rc}" "${verdict_one}"
    cat "${verdict_one}"
    printf 'VERDICT host=%s rc=%d file=%s\n' "${host_two}" "${verdict_two_rc}" "${verdict_two}"
    cat "${verdict_two}"

    normalized_one="${RUN_DIR}/${token_one}.normalized"
    normalized_two="${RUN_DIR}/${token_two}.normalized"
    cross_diff="${RUN_DIR}/cross-host.diff"
    if (( drive_one_rc == 0 && drive_two_rc == 0 )); then
        normalize_log "${RUN_DIR}/${token_one}.machine" "${normalized_one}"
        normalize_log "${RUN_DIR}/${token_two}.machine" "${normalized_two}"
        diff -u --label "${host_one}" --label "${host_two}" \
            "${normalized_one}" "${normalized_two}" > "${cross_diff}" || diff_rc=$?
        if (( diff_rc > 1 )); then
            printf 'gate suites: cross-host comparison failed with status %d\n' "${diff_rc}" >&2
            overall_rc=1
        fi
    else
        printf 'Cross-host comparison unavailable because a host drive failed.\n' > "${cross_diff}"
        diff_rc=2
        overall_rc=1
    fi
    diff_lines="$(wc -l < "${cross_diff}")"
    printf 'CROSS_HOST rc=%d lines=%d file=%s\n' "${diff_rc}" "${diff_lines}" "${cross_diff}"

    if (( verdict_one_rc != 0 || verdict_two_rc != 0 )); then
        overall_rc=1
    fi
    if ! control_provenance_unchanged; then
        overall_rc=1
    fi
    if (( overall_rc == 0 )); then
        printf 'GATE SUITES PASS hosts=2 evidence=%s\n' "${RUN_DIR}"
    else
        printf 'GATE SUITES FAIL host_one=%d host_two=%d diff=%d evidence=%s\n' \
            "${verdict_one_rc}" "${verdict_two_rc}" "${diff_rc}" "${RUN_DIR}"
    fi
    return "${overall_rc}"
}

main "$@"
