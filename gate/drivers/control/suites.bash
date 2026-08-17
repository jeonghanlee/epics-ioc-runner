#!/bin/bash
# Run the canonical six-run suite matrix on two hosts and preserve the complete
# evidence set on the control host. Each host writes one remote log by truncating
# it for the first suite and appending the remaining five suites. The control
# host validates the fixed machine-record identity and state matrix, then records
# the normalized TEST and STEP differences between the hosts.
#
# $1 first host, as user@address
# $2 absolute EPICS environment path on the first host
# $3 second host, as user@address
# $4 absolute EPICS environment path on the second host
set -euo pipefail

export PATH="/usr/local/bin:/usr/bin:/bin"
unset BASH_ENV ENV CDPATH
umask 077

readonly EXPECTED_IDENTITY_SHA256="bbbc445888fce6e31ec01badab78d88df53ce81a796ed119a265a2ad139c135c"
readonly REMOTE_REPO="\${HOME}/gitsrc/epics-ioc-runner"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
readonly SCRIPT_DIR
DRIVER_PATH="${SCRIPT_DIR}/$(basename "$0")"
readonly DRIVER_PATH
REPO_TOP="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
readonly REPO_TOP
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
    printf 'Usage: %s <host-1> <epics-env-1> <host-2> <epics-env-2>\n' "$0"
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

    remote_command="test -d ${REMOTE_REPO}/tests && test -r '${env_path}' && for c in bash awk sort sha256sum git cat date sudo; do p=\$(command -v \"\${c}\") && test -x \"\${p}\" || exit 1; done && sudo -n true && printf 'HEAD %s\\n' \"\$(git -C ${REMOTE_REPO} rev-parse HEAD)\" && printf 'REPO %s\\n' \"\$(cd ${REMOTE_REPO} && pwd)\""
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
    local suite="$2"
    local scope="$3"
    local runner="$4"
    local suite_command="$5"
    local redirect="$6"
    local remote_log="$7"
    local status_file="$8"
    local remote_command=""
    local output=""
    local line=""
    local candidate=""

    case "${redirect}" in
        '>'|'>>') ;;
        *)
            printf 'gate suites: invalid log redirect: %s\n' "${redirect}" >&2
            return 1
            ;;
    esac

    remote_command="t0=\$(date +%s); rc=0; { cd ${REMOTE_REPO} && ${suite_command}; } ${redirect} '${remote_log}' 2>&1 || rc=\$?; t1=\$(date +%s); printf 'RUN suite=${suite} scope=${scope} runner=${runner} rc=%s elapsed=%ss\\n' \"\${rc}\" \"\$((t1 - t0))\"; exit 0"
    if ! output="$("${SSH_CMD[@]}" "${host}" "${remote_command}")"; then
        printf 'gate suites: suite transport failed: host=%s suite=%s runner=%s\n' \
            "${host}" "${suite}" "${runner}" >&2
        return 1
    fi

    while IFS= read -r candidate; do
        if [[ "${candidate}" == RUN\ * ]]; then
            line="${candidate}"
        fi
    done <<< "${output}"
    if [[ ! "${line}" =~ ^RUN[[:space:]]suite=[A-Za-z0-9._:+/-]+[[:space:]]scope=[A-Za-z0-9._:+/-]+[[:space:]]runner=[A-Za-z0-9._:+/-]+[[:space:]]rc=[0-9]+[[:space:]]elapsed=[0-9]+s$ ]]; then
        printf 'gate suites: suite returned no valid run status: host=%s suite=%s runner=%s\n' \
            "${host}" "${suite}" "${runner}" >&2
        return 1
    fi
    printf '%s\n' "${line}" | tee -a "${status_file}"
}

function run_host {
    local host="$1"
    local env_path="$2"
    local token="$3"
    local status_file="${RUN_DIR}/${token}.status"
    local local_log="${RUN_DIR}/${token}.log"
    local meta_file="${RUN_DIR}/${token}.meta"
    local remote_log="/tmp/ioc-runner-gate-suites-${RUN_ID}-${token}.log"
    local remote_sha=""
    local local_sha=""
    local command_prefix=". '${env_path}' &&"

    : > "${status_file}"
    printf 'HOST START host=%s env=%s remote_log=%s\n' "${host}" "${env_path}" "${remote_log}"

    run_remote_suite "${host}" error-handling none source \
        "bash tests/test-error-handling.bash" '>' "${remote_log}" "${status_file}" || return 1
    run_remote_suite "${host}" source-regression system source \
        "sudo -n true && bash tests/run-all-tests.bash --source-regression" '>>' \
        "${remote_log}" "${status_file}" || return 1
    run_remote_suite "${host}" local-lifecycle local source \
        "${command_prefix} IOC_RUNNER_TEST_MODE=source bash tests/test-local-lifecycle.bash" '>>' \
        "${remote_log}" "${status_file}" || return 1
    run_remote_suite "${host}" local-lifecycle local installed \
        "${command_prefix} IOC_RUNNER_TEST_MODE=installed bash tests/test-local-lifecycle.bash" '>>' \
        "${remote_log}" "${status_file}" || return 1
    run_remote_suite "${host}" system-infra system none \
        "${command_prefix} IOC_RUNNER_TEST_MODE=installed sudo -nE bash tests/test-system-infra.bash" '>>' \
        "${remote_log}" "${status_file}" || return 1
    run_remote_suite "${host}" system-lifecycle system installed \
        "${command_prefix} IOC_RUNNER_TEST_MODE=installed sudo -nE bash tests/test-system-lifecycle.bash" '>>' \
        "${remote_log}" "${status_file}" || return 1

    if ! "${SSH_CMD[@]}" "${host}" "cat '${remote_log}'" > "${local_log}"; then
        printf 'gate suites: failed to copy the host log: %s\n' "${host}" >&2
        return 1
    fi
    if [[ ! -s "${local_log}" ]]; then
        printf 'gate suites: copied host log is empty: %s\n' "${host}" >&2
        return 1
    fi
    if ! remote_sha="$("${SSH_CMD[@]}" "${host}" "sha256sum '${remote_log}'" | awk '{print $1}')"; then
        printf 'gate suites: failed to hash the remote host log: %s\n' "${host}" >&2
        return 1
    fi
    local_sha="$(sha256sum "${local_log}" | awk '{print $1}')"
    if [[ "${remote_sha}" != "${local_sha}" ]]; then
        printf 'gate suites: remote and local log hashes differ: %s\n' "${host}" >&2
        return 1
    fi

    printf 'HOST host=%s env=%s head=%s repo=%s remote_log=%s local_log=%s sha256=%s\n' \
        "${host}" "${env_path}" "${HOST_HEAD[${token}]}" "${HOST_REPO[${token}]}" \
        "${remote_log}" "${local_log}" "${local_sha}" \
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
            want["source-regression/system/source"] = 1
            want["local-lifecycle/local/source"] = 1
            want["local-lifecycle/local/installed"] = 1
            want["system-infra/system/none"] = 1
            want["system-lifecycle/system/installed"] = 1
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
            if (count != 6 || failed != 0 || bad != 0) {
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

    awk '
        function val(n, prefix) {
            if (index($n, prefix) != 1 || length($n) == length(prefix)) {
                bad++
                return ""
            }
            return substr($n, length(prefix) + 1)
        }
        function scalar(value) {
            return value ~ /^[-A-Za-z0-9._:\/+]+$/
        }
        function own(run, suite) {
            if (run_suite[run] != "" && run_suite[run] != suite) {
                bad++
            }
            run_suite[run] = suite
        }
        BEGIN {
            want["error-handling/none/source"] = 150
            want_step["error-handling/none/source"] = 38
            want["source-regression/system/source"] = 108
            want_step["source-regression/system/source"] = 18
            want["local-lifecycle/local/source"] = 146
            want_step["local-lifecycle/local/source"] = 37
            want["local-lifecycle/local/installed"] = 146
            want_step["local-lifecycle/local/installed"] = 37
            want["system-infra/system/none"] = 36
            want_step["system-infra/system/none"] = 7
            want["system-lifecycle/system/installed"] = 102
            want_step["system-lifecycle/system/installed"] = 33
        }
        $1 == "TEST" {
            raw = $0
            if (NF != 10) {
                bad++
                next
            }
            suite = val(2, "suite=")
            run = val(3, "run=")
            step = val(4, "step=")
            id = val(5, "id=")
            category = val(6, "category=")
            kind = val(7, "kind=")
            method = val(8, "method=")
            state = val(9, "state=")
            reason = val(10, "reason_b64=")
            if (!scalar(suite) || !scalar(run) || !scalar(step) || !scalar(id) ||
                index(id, suite ".") != 1 ||
                category !~ /^(error-contract|source-regression|installed-conformance|lifecycle-behavior)$/ ||
                kind !~ /^(REQUIRED|PREREQUISITE|APPLICABILITY|BEHAVIOR|INTEGRITY)$/ ||
                method !~ /^(real-path|direct-inspection)$/ ||
                state !~ /^(PASS|FAIL|SKIP|NA|SCRIPT_ERROR)$/ ||
                (state == "PASS") != (reason == "-") ||
                (reason != "-" && reason !~ /^[A-Za-z0-9_-]+$/)) {
                bad++
            }
            own(run, suite)
            key = run SUBSEP id
            if (test_seen[key]++) {
                bad++
            }
            test_count[run]++
            test_vector[run SUBSEP state]++
            test_step = run SUBSEP step
            test_step_seen[test_step] = 1
            test_step_vector[test_step SUBSEP state]++
            if (state != "PASS") {
                exception_run[++exceptions] = run
                exception_line[exceptions] = raw
            }
            if (suite_seen[run]) {
                bad++
            }
            next
        }
        $1 == "STEP" {
            if (NF != 9) {
                bad++
                next
            }
            suite = val(2, "suite=")
            run = val(3, "run=")
            step = val(4, "step=")
            pass_count = val(5, "pass=")
            fail_count = val(6, "fail=")
            skip_count = val(7, "skip=")
            na_count = val(8, "na=")
            error_count = val(9, "err=")
            if (!scalar(suite) || !scalar(run) || !scalar(step) ||
                pass_count !~ /^[0-9]+$/ || fail_count !~ /^[0-9]+$/ ||
                skip_count !~ /^[0-9]+$/ || na_count !~ /^[0-9]+$/ || error_count !~ /^[0-9]+$/) {
                bad++
            }
            own(run, suite)
            key = run SUBSEP step
            if (step_seen[key]++) {
                bad++
            }
            step_count[run]++
            step_vector[key SUBSEP "PASS"] = pass_count + 0
            step_vector[key SUBSEP "FAIL"] = fail_count + 0
            step_vector[key SUBSEP "SKIP"] = skip_count + 0
            step_vector[key SUBSEP "NA"] = na_count + 0
            step_vector[key SUBSEP "SCRIPT_ERROR"] = error_count + 0
            if (suite_seen[run]) {
                bad++
            }
            next
        }
        $1 == "SUITE" {
            if (NF != 14) {
                bad++
                next
            }
            suite = val(2, "suite=")
            run = val(3, "run=")
            scope = val(4, "scope=")
            runner = val(5, "runner=")
            os = val(6, "os=")
            arch = val(7, "arch=")
            total = val(8, "total=")
            pass_count = val(9, "pass=")
            fail_count = val(10, "fail=")
            skip_count = val(11, "skip=")
            na_count = val(12, "na=")
            error_count = val(13, "err=")
            state = val(14, "state=")
            wanted_key = suite "/" scope "/" runner
            if (!scalar(suite) || !scalar(run) || !scalar(scope) || !scalar(runner) ||
                !scalar(os) || !scalar(arch) || total !~ /^[0-9]+$/ ||
                pass_count !~ /^[0-9]+$/ || fail_count !~ /^[0-9]+$/ ||
                skip_count !~ /^[0-9]+$/ || na_count !~ /^[0-9]+$/ ||
                error_count !~ /^[0-9]+$/ || state !~ /^(PASS|FAIL)$/ || !(wanted_key in want)) {
                bad++
            }
            own(run, suite)
            if (suite_seen[run]++ || want_seen[wanted_key]++) {
                bad++
            }
            run_key[run] = wanted_key
            run_runner[run] = runner
            suite_total[run] = total + 0
            suite_vector[run SUBSEP "PASS"] = pass_count + 0
            suite_vector[run SUBSEP "FAIL"] = fail_count + 0
            suite_vector[run SUBSEP "SKIP"] = skip_count + 0
            suite_vector[run SUBSEP "NA"] = na_count + 0
            suite_vector[run SUBSEP "SCRIPT_ERROR"] = error_count + 0
            suite_exec[run] = state
            blocks++
            next
        }
        END {
            for (key in test_step_seen) {
                if (!step_seen[key]) {
                    bad++
                }
            }
            for (key in step_seen) {
                for (i = 1; i <= 5; i++) {
                    state = (i == 1 ? "PASS" : i == 2 ? "FAIL" : i == 3 ? "SKIP" : i == 4 ? "NA" : "SCRIPT_ERROR")
                    if (step_vector[key SUBSEP state] != test_step_vector[key SUBSEP state]) {
                        bad++
                    }
                }
            }
            for (run in run_suite) {
                if (!suite_seen[run]) {
                    bad++
                }
            }
            for (wanted_key in want) {
                if (want_seen[wanted_key] != 1) {
                    bad++
                }
            }
            for (run in suite_seen) {
                wanted_key = run_key[run]
                checks += test_count[run]
                steps += step_count[run]
                if (test_count[run] != want[wanted_key] ||
                    step_count[run] != want_step[wanted_key] ||
                    suite_total[run] != test_count[run] || suite_exec[run] != "PASS") {
                    bad++
                }
                for (i = 1; i <= 5; i++) {
                    state = (i == 1 ? "PASS" : i == 2 ? "FAIL" : i == 3 ? "SKIP" : i == 4 ? "NA" : "SCRIPT_ERROR")
                    if (suite_vector[run SUBSEP state] != test_vector[run SUBSEP state]) {
                        bad++
                    }
                }
                skip += test_vector[run SUBSEP "SKIP"]
                fail += test_vector[run SUBSEP "FAIL"]
                na_total += test_vector[run SUBSEP "NA"]
                errors += test_vector[run SUBSEP "SCRIPT_ERROR"]
            }
            for (i = 1; i <= exceptions; i++) {
                print exception_line[i] " runner=" run_runner[exception_run[i]]
            }
            if (blocks == 6 && checks == 688 && steps == 170 &&
                skip == 0 && fail == 0 && errors == 0 && bad == 0) {
                print "SUITES OK (6 blocks, 688 checks, na=" na_total ")"
                exit 0
            }
            printf "SUITES FAIL blocks=%d checks=%d steps=%d skip=%d fail=%d na=%d err=%d invalid=%d\n", blocks + 0, checks + 0, steps + 0, skip + 0, fail + 0, na_total + 0, errors + 0, bad + 0
            exit 1
        }
    ' "${log}"
}

function validate_host_log {
    local log="$1"
    local status_file="$2"
    local expected_source="$3"
    local actual_sha=""

    if ! validate_run_statuses "${status_file}"; then
        return 1
    fi
    if ! validate_runner_paths "${log}" "${expected_source}"; then
        return 1
    fi
    actual_sha="$(identity_sha256 "${log}")"
    if [[ "${actual_sha}" != "${EXPECTED_IDENTITY_SHA256}" ]]; then
        printf 'SUITES FAIL identity_sha256=%s expected=%s\n' \
            "${actual_sha}" "${EXPECTED_IDENTITY_SHA256}"
        return 1
    fi
    matrix_verdict "${log}"
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
    if [[ $# -ne 4 ]]; then
        usage >&2
        return 1
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
        validate_host_log "${RUN_DIR}/${token_one}.log" "${RUN_DIR}/${token_one}.status" \
            "${HOST_REPO[${token_one}]}/tests/../bin/ioc-runner" \
            > "${verdict_one}" || verdict_one_rc=$?
    else
        printf 'SUITES FAIL driver_rc=%d host=%s\n' "${drive_one_rc}" "${host_one}" > "${verdict_one}"
        verdict_one_rc=1
    fi
    if (( drive_two_rc == 0 )); then
        validate_host_log "${RUN_DIR}/${token_two}.log" "${RUN_DIR}/${token_two}.status" \
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
        normalize_log "${RUN_DIR}/${token_one}.log" "${normalized_one}"
        normalize_log "${RUN_DIR}/${token_two}.log" "${normalized_two}"
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
