#!/bin/sh
set -eu

# Read global version so image tag and package filename stay aligned.
VERSION_FILE="${VERSION_FILE:-VERSION}"
if [ ! -f "$VERSION_FILE" ]; then
  echo "Missing $VERSION_FILE" >&2
  exit 1
fi

VERSION="$(tr -d '[:space:]' < "$VERSION_FILE")"
# Allow overrides while keeping sensible defaults.
BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-iox-aarch64-alpine}"
IMAGE_NAME="${IMAGE_NAME:-${BASE_IMAGE_NAME}:${VERSION}}"
PACKAGE_NAME="${PACKAGE_NAME:-${BASE_IMAGE_NAME}-${VERSION}.tar}"
PLATFORM="${PLATFORM:-linux/arm64}"
TARGET="${TARGET:-runtime}"

# Ensure metadata files reflect VERSION before building.
./sync-version.sh

# Build ARM64 image using Buildx and load it locally.
docker buildx build \
  --platform "${PLATFORM}" \
  --target "${TARGET}" \
  --load \
  -t "${IMAGE_NAME}" \
  .

# Package built image for IOx deployment.
ioxclient docker package "${IMAGE_NAME}" . --name "${PACKAGE_NAME}"
