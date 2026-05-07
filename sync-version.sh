#!/bin/sh
set -eu

# Global version source used by all project metadata.
VERSION_FILE="${VERSION_FILE:-VERSION}"

if [ ! -f "$VERSION_FILE" ]; then
  echo "Missing $VERSION_FILE" >&2
  exit 1
fi

# Trim whitespace so accidental trailing newlines do not break parsing.
VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"

# Accept numeric versions with optional suffixes like -rc1.
if ! printf '%s\n' "$VERSION" | awk '
  /^[0-9]+(\.[0-9]+)*([.-][A-Za-z0-9]+)?$/ { valid = 1 }
  END { exit(valid ? 0 : 1) }
'; then
  echo "Invalid version format in $VERSION_FILE: $VERSION" >&2
  echo "Example: 1.2.3 or 1.2.3-rc1" >&2
  exit 1
fi

update_yaml() {
  input_file="$1"
  tmp_file="$(mktemp)"

  # Replace the first matching YAML version key and preserve other content.
  awk -v version="$VERSION" '
    /^[[:space:]]*version:[[:space:]]*"/ && !done {
      print "  version: \"" version "\""
      done = 1
      next
    }
    { print }
    END {
      if (!done) {
        exit 2
      }
    }
  ' "$input_file" > "$tmp_file" || {
    rm -f "$tmp_file"
    echo "Failed to update version in $input_file" >&2
    exit 1
  }

  mv "$tmp_file" "$input_file"
}

update_xml() {
  input_file="$1"
  tmp_file="$(mktemp)"

  # Replace the first matching XML <version> tag and preserve other content.
  awk -v version="$VERSION" '
    /<version>[^<]*<\/version>/ && !done {
      print "  <version>" version "</version>"
      done = 1
      next
    }
    { print }
    END {
      if (!done) {
        exit 2
      }
    }
  ' "$input_file" > "$tmp_file" || {
    rm -f "$tmp_file"
    echo "Failed to update version in $input_file" >&2
    exit 1
  }

  mv "$tmp_file" "$input_file"
}

update_yaml "package.yaml"
update_xml "image_properties.xml"

# Confirm synchronization result for CI/log readability.
echo "Synchronized version $VERSION into package.yaml and image_properties.xml"
