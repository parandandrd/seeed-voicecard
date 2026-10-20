#!/bin/bash
# Reports how far this fork is behind HinTak/seeed-voicecard, and changes nothing
# in the working tree. (It does fetch the newest upstream branch into .git, to
# count commits.)
#
# Upstream keeps one branch per kernel version (v6.13, v6.14, ...), each carrying
# the changes the previous one needed. Dependabot has nothing to read here: there
# are no dependency manifests, so this is the whole check. Porting a new kernel
# version is still a manual job.
set -euo pipefail

UPSTREAM="${UPSTREAM:-https://github.com/HinTak/seeed-voicecard}"

cd "$(dirname "${BASH_SOURCE[0]}")"

# This fork's default branch, which is the branch name its remote calls HEAD.
fork_branch="$(git ls-remote --symref origin HEAD | sed -n 's|^ref: refs/heads/\(.*\)\tHEAD$|\1|p')"
fork_sha="$(git ls-remote origin "refs/heads/${fork_branch}" | cut -f1)"

# Upstream's newest kernel-version branch.
up_line="$(git ls-remote --heads "${UPSTREAM}" 'refs/heads/v[0-9]*.[0-9]*' \
  | sed 's|refs/heads/||' | sort -k2 -V | tail -1)"
up_sha="$(cut -f1 <<<"${up_line}")"
up_branch="$(cut -f2 <<<"${up_line}")"

echo "this fork: ${fork_branch} at ${fork_sha:0:7}"
echo "upstream:  ${up_branch} at ${up_sha:0:7} (${UPSTREAM})"

if [ "${fork_sha}" = "${up_sha}" ]; then
  echo "up to date"
  exit 0
fi

git fetch --quiet "${UPSTREAM}" "refs/heads/${up_branch}"
if git merge-base --is-ancestor "${fork_sha}" FETCH_HEAD 2>/dev/null; then
  behind="$(git rev-list --count "${fork_sha}..FETCH_HEAD")"
  echo "BEHIND by ${behind} commit(s); the fork's tip is in upstream's ${up_branch}"
  git log --oneline -n 10 "${fork_sha}..FETCH_HEAD"
else
  echo "BEHIND, and the two have diverged: the fork's tip is not in ${up_branch}"
  echo "  compare: ${UPSTREAM}/compare/${fork_sha:0:7}...${up_branch}"
fi
