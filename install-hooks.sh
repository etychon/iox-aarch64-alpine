#!/bin/sh
set -eu

if [ ! -d ".git" ]; then
  echo "Run this script from the repository root." >&2
  exit 1
fi

git config core.hooksPath .githooks
echo "Configured git hooks path to .githooks"
