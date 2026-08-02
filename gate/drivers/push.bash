#!/bin/bash
# Push the tree under test to a consumer, excluding exactly what git ignores at
# the source. A plain tar of the directory carries files the control host hides
# through its global excludes file, so the two sides disagree about whether the
# tree is clean (finding 1). The exclusion set is asked of git rather than kept
# by hand, so a change to the operator's global excludes needs no edit here.
#
# $1 host, as user@address   $2 repository root on the control host
# $3 destination parent directory on the host; a leading ~ is expanded there
#
# Unlike a scenario driver this one uses set -e: a failed push is a failure, not
# an observation.
set -eu

host="$1"; repo="$2"; dest="$3"
parent="$(dirname "${repo}")"; name="$(basename "${repo}")"
# -n is correct for a command-only call and wrong for the one that must read the
# archive from the pipe, so the two do not share an option list.
ssh_cmd=(ssh -n -o BatchMode=yes -o ConnectTimeout=10)
ssh_pipe=(ssh -o BatchMode=yes -o ConnectTimeout=10)

# git prints ignored entries relative to the repository root, directories with a
# trailing slash. tar excludes nothing when the pattern keeps that slash, so it
# is stripped. The repository directory is prefixed because tar matches its
# patterns against the archived name, which carries it.
excludes="$(git -C "${repo}" ls-files --others --ignored --exclude-standard --directory \
    | sed -e 's|/$||' -e "s|^|${name}/|")"
printf '%s\n' "### excluding"
printf '%s\n' "${excludes}"

# The destination is resolved on the host before it is quoted anywhere, so a
# leading ~ expands there instead of becoming a directory of that name.
dest_abs="$("${ssh_cmd[@]}" "${host}" "mkdir -p ${dest} && cd ${dest} && pwd")"
printf '%s\n' "### destination ${dest_abs}"
"${ssh_cmd[@]}" "${host}" "rm -rf '${dest_abs}/${name}'"

printf '%s\n' "${excludes}" | tar -C "${parent}" --exclude-from=- -cf - "${name}" \
    | "${ssh_pipe[@]}" "${host}" "tar -C '${dest_abs}' -xf -"
printf '%s\n' "### pushed ${name} to ${host}:${dest_abs}"

printf '%s\n' "### source porcelain"
git -C "${repo}" status --porcelain
printf '%s\n' "### pushed porcelain"
"${ssh_cmd[@]}" "${host}" "git -C '${dest_abs}/${name}' status --porcelain"
