#!/usr/bin/env bash
#
# Inject git and version metadata into an installed copy of ioc-runner.
# Mirrors the metadata step setup-system-infra.bash performs for the system
# install path, used here for the Makefile user-home install path. The system
# path runs as root and drops privileges via SUDO_USER; this user-mode path
# runs as the invoking user, so git is invoked directly.
#
# Usage: inject-runner-version.bash <installed-ioc-runner> <source-repo-dir>

set -e

dest="${1:?usage: inject-runner-version.bash <installed-file> <repo-dir>}"
repo="${2:?usage: inject-runner-version.bash <installed-file> <repo-dir>}"

git_hash=$(git -C "${repo}" rev-parse --short HEAD 2>/dev/null || printf "unknown")
if [[ "${git_hash}" != "unknown" ]] && ! git -C "${repo}" diff-index --quiet HEAD -- 2>/dev/null; then
    git_hash="${git_hash}-dirty"
fi

commit_ts=$(git -C "${repo}" show -s --format=%ct HEAD 2>/dev/null || printf "")
if [[ -n "${commit_ts}" ]]; then
    commit_date=$(date -u -d "@${commit_ts}" +"%Y-%m-%dT%H:%M:%SZ")
else
    commit_date="unknown"
fi
install_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

sed -i "s/^declare -g RUNNER_GIT_HASH=.*/declare -g RUNNER_GIT_HASH=\"${git_hash}\"/" "${dest}"
sed -i "s/^declare -g RUNNER_COMMIT_DATE=.*/declare -g RUNNER_COMMIT_DATE=\"${commit_date}\"/" "${dest}"
sed -i "s/^declare -g RUNNER_INSTALL_DATE=.*/declare -g RUNNER_INSTALL_DATE=\"${install_date}\"/" "${dest}"
