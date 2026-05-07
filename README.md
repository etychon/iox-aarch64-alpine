# iox-aarch64-alpine

Small Cisco IOx ARM64 Alpine base image for experiments.

## Image size optimizations

- Uses Alpine `sh` instead of installing `bash`.
- Uses a multi-stage Dockerfile so QEMU is optional.
- Uses a strict `.dockerignore` to keep the build context tiny.

The default image target is `runtime` (smallest).  
An optional `runtime-with-qemu` target is available for x86 hosts that need embedded QEMU.

## Build with Buildx

```sh
git clone https://github.com/etychon/iox-aarch64-alpine.git
cd iox-aarch64-alpine
sh ./build.sh
```

The build script automatically syncs the global version into metadata files, then uses `docker buildx build --platform linux/arm64 --load` and packages the image for IOx.
It reads the global version from `VERSION` and outputs a package like `iox-aarch64-alpine-1.1.tar`.

### Optional settings

```sh
# Build default small runtime image (uses VERSION for tag/package name)
TARGET=runtime sh ./build.sh

# Build image with qemu-aarch64-static included
TARGET=runtime-with-qemu sh ./build.sh

# Override platform if needed
PLATFORM=linux/arm64 sh ./build.sh
```

## Global version workflow

`VERSION` is the single source of truth.  
`package.yaml`, `image_properties.xml`, and the final package filename all derive from it.

```sh
# Sync VERSION into package.yaml and image_properties.xml
./sync-version.sh
```

```sh
# Bump semantic version and sync files
./bump-version.sh patch
./bump-version.sh minor
./bump-version.sh major

# Set explicit version and sync files
./bump-version.sh set 2.0.0
```

### GitHub release alignment

To keep GitHub tags in sync with the same version:

```sh
./bump-version.sh patch --tag
git push origin main --tags
```
