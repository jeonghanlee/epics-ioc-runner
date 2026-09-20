#!/usr/bin/env bash
#
# Static guard: every IPv4 address printed in a documentation file must lie in
# an RFC 5737 documentation range, so no operational or site address leaks into
# a tracked document. Defaults to docs/NETWORK_ENV.md; accepts explicit files.
#
# RFC 5737 ranges:
#   TEST-NET-1  192.0.2.0/24
#   TEST-NET-2  198.51.100.0/24
#   TEST-NET-3  203.0.113.0/24

set -euo pipefail

declare -gr RED='\033[0;31m'
declare -gr GREEN='\033[0;32m'
declare -gr NC='\033[0m'

REPO_TOP="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

declare -a TARGETS
if [[ "$#" -gt 0 ]]; then
    TARGETS=("$@")
else
    TARGETS=("${REPO_TOP}/docs/NETWORK_ENV.md")
fi

# An address is allowed when its first three octets name one RFC 5737 network
# and its last octet is a valid 0-255 host part.
function is_doc_range {
    local addr="$1" prefix last
    case "${addr}" in
        192.0.2.*)     prefix="192.0.2" ;;
        198.51.100.*)  prefix="198.51.100" ;;
        203.0.113.*)   prefix="203.0.113" ;;
        *) return 1 ;;
    esac
    last="${addr#"${prefix}".}"
    [[ "${last}" =~ ^[0-9]{1,3}$ ]] || return 1
    (( last >= 0 && last <= 255 )) || return 1
    return 0
}

declare -i violations=0
declare -i checked=0

for target in "${TARGETS[@]}"; do
    if [[ ! -f "${target}" ]]; then
        printf "${RED}MISSING${NC}: %s\n" "${target}" >&2
        violations+=1
        continue
    fi
    while IFS= read -r addr; do
        checked+=1
        if ! is_doc_range "${addr}"; then
            printf "${RED}OUT OF RANGE${NC}: %s in %s\n" "${addr}" "${target}" >&2
            violations+=1
        fi
    done < <(grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' "${target}" | sort -u)
done

if (( violations > 0 )); then
    printf "${RED}FAIL${NC}: %d address(es) outside the RFC 5737 documentation ranges.\n" "${violations}" >&2
    exit 1
fi

printf "${GREEN}PASS${NC}: %d unique address(es) checked, all within RFC 5737 ranges.\n" "${checked}"
