#!/bin/sh
set -eu

# Generate CHANGELOG.md from git tags and commit history.
# This keeps release notes reproducible and avoids manual drift.
CHANGELOG_FILE="${CHANGELOG_FILE:-CHANGELOG.md}"
REPO_ROOT="${REPO_ROOT:-.}"

cd "$REPO_ROOT"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must run inside a git repository." >&2
  exit 1
fi

tmp_file="$(mktemp)"
tags_asc="$(git tag --sort=creatordate)"
latest_tag="$(git tag --sort=-creatordate | awk 'NR==1 { print; exit }')"

{
  echo "# Changelog"
  echo
  echo "All notable changes to this project are documented in this file."
  echo
  echo "## Unreleased"

  if [ -n "${latest_tag}" ]; then
    unreleased_commits="$(git log --pretty=format:'- %s' "${latest_tag}..HEAD")"
  else
    unreleased_commits="$(git log --pretty=format:'- %s')"
  fi

  if [ -n "${unreleased_commits}" ]; then
    printf '%s\n' "${unreleased_commits}"
  else
    echo "- No changes since last release."
  fi

  echo

  if [ -n "${tags_asc}" ]; then
    prev_tag=""
    printf '%s\n' "${tags_asc}" | while IFS= read -r tag; do
      [ -n "${tag}" ] || continue

      tag_date="$(git log -1 --date=short --pretty=format:'%ad' "${tag}")"
      echo "## ${tag} - ${tag_date}"

      if [ -n "${prev_tag}" ]; then
        release_commits="$(git log --pretty=format:'- %s' "${prev_tag}..${tag}")"
      else
        release_commits="$(git log --pretty=format:'- %s' "${tag}")"
      fi

      if [ -n "${release_commits}" ]; then
        printf '%s\n' "${release_commits}"
      else
        echo "- No commit details available."
      fi

      echo
      prev_tag="${tag}"
    done
  fi
} > "${tmp_file}"

mv "${tmp_file}" "${CHANGELOG_FILE}"
echo "Updated ${CHANGELOG_FILE}"
