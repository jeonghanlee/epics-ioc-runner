#!/usr/bin/env bash
# Shared outer-boundary controls for real process-context churn tests.

function _m14_create_ps_wrapper {
    local wrapper_dir="$1"
    local real_ps="$2"
    local mode="$3"
    local hold_call="${4:-0}"

    mkdir -p -- "${wrapper_dir}"
    printf '%s\n' "${real_ps}" > "${wrapper_dir}/real-ps"
    printf '%s\n' "${mode}" > "${wrapper_dir}/mode"
    printf '%s\n' "${hold_call}" > "${wrapper_dir}/hold-call"
    cat > "${wrapper_dir}/ps" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

script_dir="${BASH_SOURCE[0]%/*}"
real_ps=$(<"${script_dir}/real-ps")
mode=$(<"${script_dir}/mode")
hold_call=$(<"${script_dir}/hold-call")
call_file="${script_dir}/call"
ready_file="${script_dir}/ready"
release_file="${script_dir}/release"
args_file="${script_dir}/args"
call=1

if [[ -r "${call_file}" ]]; then
    read -r call < "${call_file}"
    call=$((call + 1))
fi
printf '%d\n' "${call}" > "${call_file}"

case "${mode}" in
    passthrough)
        ;;
    status1)
        exit 1
        ;;
    status2)
        exit 2
        ;;
    status127)
        exit 127
        ;;
    hold)
        if (( call == hold_call )); then
            printf '%s\n' "$*" > "${args_file}"
            : > "${ready_file}"
            while [[ ! -e "${release_file}" ]]; do
                if (( PPID == 1 )) || ! kill -0 "${PPID}" 2>/dev/null; then
                    exit 125
                fi
                sleep 0.001
            done
        fi
        ;;
    *)
        printf "Error: unsupported M14 ps mode: %s\n" "${mode}" >&2
        exit 125
        ;;
esac

exec "${real_ps}" "$@"
EOF
    chmod 0755 "${wrapper_dir}/ps"
}

function _m14_wait_for_file {
    local target="$1"
    local attempt=0

    while (( attempt < 5000 )); do
        [[ -e "${target}" ]] && return 0
        sleep 0.001
        attempt=$((attempt + 1))
    done
    return 1
}

function _m14_wait_for_process_exit {
    local pid="$1"
    local stat_line=""
    local stat_tail=""
    local process_state=""
    local attempt=0

    while (( attempt < 100 )); do
        if ! kill -0 "${pid}" 2>/dev/null; then
            return 0
        fi
        if [[ -r "/proc/${pid}/stat" ]]; then
            stat_line=$(<"/proc/${pid}/stat")
            stat_tail="${stat_line##*) }"
            process_state="${stat_tail%% *}"
            [[ "${process_state}" == "Z" ]] && return 0
        fi
        sleep 0.01
        attempt=$((attempt + 1))
    done
    return 1
}

function _m14_output_has_pid_row {
    local output_file="$1"
    local pid="$2"

    awk -v wanted="${pid}" '$1 == wanted { found = 1 } END { exit !found }' "${output_file}"
}

function _m14_ps_selection {
    local args_file="$1"
    local result_name="$2"
    local previous=""
    local argument=""

    while read -r argument; do
        if [[ "${previous}" == "-p" ]]; then
            printf -v "${result_name}" '%s' "${argument}"
            return 0
        fi
        previous="${argument}"
    done < <(tr ' ' '\n' < "${args_file}")
    return 1
}

function _m14_wait_for_selected_pids_gone {
    local pid_selection="$1"
    local pid=""
    local remaining=0
    local attempt=0
    local -a pids=()

    IFS=',' read -r -a pids <<< "${pid_selection}"
    while (( attempt < 100 )); do
        remaining=0
        for pid in "${pids[@]}"; do
            if [[ "${pid}" =~ ^[1-9][0-9]*$ ]] && kill -0 "${pid}" 2>/dev/null; then
                remaining=1
                break
            fi
        done
        (( remaining == 0 )) && return 0
        sleep 0.01
        attempt=$((attempt + 1))
    done
    return 1
}
