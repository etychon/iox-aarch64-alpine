#!/bin/sh
set -eu

# Shared version file used across build and metadata scripts.
VERSION_FILE="${VERSION_FILE:-VERSION}"

usage() {
  echo "Usage: $0 <patch|minor|major|set> [value] [--tag]" >&2
  echo "Examples:" >&2
  echo "  $0 patch" >&2
  echo "  $0 minor --tag" >&2
  echo "  $0 set 2.0.0" >&2
  exit 1
}

if [ "${1:-}" = "" ]; then
  usage
fi

MODE="$1"
shift

WANT_TAG=0
SET_VALUE=""

# Parse optional arguments: explicit set value and --tag switch.
while [ "$#" -gt 0 ]; do
  case "$1" in
    --tag)
      WANT_TAG=1
      shift
      ;;
    *)
      if [ -z "$SET_VALUE" ]; then
        SET_VALUE="$1"
        shift
      else
        usage
      fi
      ;;
  esac
done

if [ ! -f "$VERSION_FILE" ]; then
  echo "Missing $VERSION_FILE" >&2
  exit 1
fi

CURRENT_VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"

# For auto-bump modes, require numeric semantic style x.y or x.y.z.
if ! printf '%s\n' "$CURRENT_VERSION" | awk '
  /^[0-9]+\.[0-9]+(\.[0-9]+)?$/ { valid = 1 }
  END { exit(valid ? 0 : 1) }
'; then
  echo "Current version in $VERSION_FILE must be numeric semantic style (x.y or x.y.z). Found: $CURRENT_VERSION" >&2
  exit 1
fi

IFS=.
set -- $CURRENT_VERSION
MAJOR="$1"
MINOR="$2"
PATCH="${3:-0}"
unset IFS

# Calculate the next release version.
case "$MODE" in
  patch)
    PATCH=$((PATCH + 1))
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  set)
    if [ -z "$SET_VALUE" ]; then
      echo "Missing value for set mode" >&2
      usage
    fi
    # set mode allows extended suffixes like -rc1.
    if ! printf '%s\n' "$SET_VALUE" | awk '
      /^[0-9]+(\.[0-9]+)*([.-][A-Za-z0-9]+)?$/ { valid = 1 }
      END { exit(valid ? 0 : 1) }
    '; then
      echo "Invalid version format: $SET_VALUE" >&2
      exit 1
    fi
    NEXT_VERSION="$SET_VALUE"
    ;;
  *)
    usage
    ;;
esac

if [ "$MODE" != "set" ]; then
  NEXT_VERSION="${MAJOR}.${MINOR}.${PATCH}"
fi

# Persist and synchronize derived metadata files.
printf '%s\n' "$NEXT_VERSION" > "$VERSION_FILE"
./sync-version.sh

# Optional local tag creation for GitHub release flows.
if [ "$WANT_TAG" -eq 1 ]; then
  git tag "v${NEXT_VERSION}"
  echo "Created local git tag v${NEXT_VERSION}"
fi

# Print a clear before/after summary.
echo "Bumped version: ${CURRENT_VERSION} -> ${NEXT_VERSION}"
