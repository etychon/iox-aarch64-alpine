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
APP_VERSION="${APP_VERSION:-${VERSION}}"
APP_NAME="${APP_NAME:-${BASE_IMAGE_NAME}}"

# Auto-select target when TARGET is not explicitly set:
# - ARM64 hosts: smallest runtime image
# - Non-ARM64 hosts (for example x86_64): runtime-with-qemu
HOST_ARCH="$(uname -m)"
if [ "${TARGET+x}" = "x" ] && [ -n "${TARGET}" ]; then
  EFFECTIVE_TARGET="${TARGET}"
  echo "Using explicit TARGET=${EFFECTIVE_TARGET}"
else
  case "${HOST_ARCH}" in
    aarch64|arm64)
      EFFECTIVE_TARGET="runtime"
      ;;
    *)
      EFFECTIVE_TARGET="runtime-with-qemu"
      ;;
  esac
  echo "Auto-selected TARGET=${EFFECTIVE_TARGET} for host architecture ${HOST_ARCH}"
fi

# Ensure metadata files reflect VERSION before building.
./sync-version.sh

# Build ARM64 image using Buildx and load it locally.
docker buildx build \
  --platform "${PLATFORM}" \
  --target "${EFFECTIVE_TARGET}" \
  --build-arg "APP_NAME=${APP_NAME}" \
  --build-arg "APP_VERSION=${APP_VERSION}" \
  --load \
  -t "${IMAGE_NAME}" \
  .

# Package built image for IOx deployment.
ioxclient docker package "${IMAGE_NAME}" . --name "${PACKAGE_NAME}"
