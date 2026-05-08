# iox-aarch64-alpine

Small Cisco IOx ARM64 Alpine base image for experiments, built to run on ARM-based Cisco routers and switches such as Cisco IR1101, Cisco IR1800, Cisco IE3400, Cisco IE3500, and so on. 

## Purpose

The goal of this Alpine image is to run a small IOx container on a router or switch and experiment with commands and hardware integration points. Typical validation use cases include:

- Trying serial port access from inside the container.
- Validating whether USB storage mounting is working as expected.
- Testing access to digital IO ports.
- Running general Linux troubleshooting and networking commands.

## Available app

This repository delivers one IOx app:

- `iox-aarch64-alpine`

Build target selection (`runtime` or `runtime-with-qemu`) changes how the same app image is built, not the app identity.

Build output is packaged as:

- `iox-aarch64-alpine-<version>.tar`

Precompiled binaries are also published on GitHub in [Releases](https://github.com/etychon/iox-aarch64-alpine/releases).

## Install and connect

The IOx app can be installed using:

- Device CLI
- IOx Local Manager
- A management platform such as Cisco Catalyst SD-WAN

After the app is installed, activated, and running, open a shell session with:

```sh
app-hosting connect appid <app_name> session
```

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

By default, `build.sh` now auto-selects the build target from the host architecture:

- ARM64 host (`aarch64`/`arm64`) -> `runtime`
- Non-ARM64 host (for example `x86_64`) -> `runtime-with-qemu`

You can still force a target manually by setting `TARGET=...`.

### Optional settings

```sh
# Auto-select target based on host architecture
sh ./build.sh

# Force smallest runtime image
TARGET=runtime sh ./build.sh

# Force image with qemu-aarch64-static included
TARGET=runtime-with-qemu sh ./build.sh

# Override platform if needed
PLATFORM=linux/arm64 sh ./build.sh
```

### When to use `runtime-with-qemu`

`runtime-with-qemu` includes `qemu-aarch64-static`. It is useful when your build/test workflow runs on a non-ARM64 host and you want user-space ARM64 emulation available inside the container image.

Use the default `runtime` target when you want the smallest possible image/package and you do not need embedded QEMU.

### `runtime-with-qemu` examples

```sh
# Example 1: Let script auto-select target from host architecture
sh ./build.sh
```

```sh
# Example 2: Force embedded QEMU target
TARGET=runtime-with-qemu sh ./build.sh
```

```sh
# Example 3: Build with explicit platform and embedded QEMU
PLATFORM=linux/arm64 TARGET=runtime-with-qemu sh ./build.sh
```

```sh
# Example 4: Check generated package name after build
ls -1 iox-aarch64-alpine-*.tar
```

Typical flow:

1. Build using `sh ./build.sh` (auto-select), or force with `TARGET=runtime-with-qemu sh ./build.sh`.
2. Install the generated `.tar` package through CLI, IOx Local Manager, or Cisco Catalyst SD-WAN.
3. Start the app and connect to the shell:

```sh
app-hosting connect appid <app_name> session
```

## Global version workflow

`VERSION` is the single source of truth.  
`package.yaml`, `image_properties.xml`, and the final package filename all derive from it.
`CHANGELOG.md` is generated from git history and refreshed automatically when version bumps run.

```sh
# Sync VERSION into package.yaml and image_properties.xml
./sync-version.sh

# Rebuild CHANGELOG.md from git tags/commits
./update-changelog.sh
```

```sh
# Bump semantic version and sync files
./bump-version.sh patch
./bump-version.sh minor
./bump-version.sh major

# Set explicit version and sync files
./bump-version.sh set 2.0.0
```

Each `bump-version.sh` run now updates:

- `VERSION`
- `package.yaml`
- `image_properties.xml`
- `CHANGELOG.md`

## Automatic changelog updates on each commit

To refresh `CHANGELOG.md` automatically for each new commit, install the repository hooks once:

```sh
./install-hooks.sh
```

This configures git to use `.githooks/pre-commit`, which runs `./update-changelog.sh` and stages `CHANGELOG.md` if it changed.

### GitHub release alignment

To keep GitHub tags in sync with the same version:

```sh
./bump-version.sh patch --tag
git push origin main --tags
```

## Git tags (manual)

You can also create and push a tag manually:

```sh
git tag v1.0.1
git push origin v1.0.1
```

Tip: keep the tag aligned with `VERSION` (for example, if `VERSION` is `1.0.1`, use tag `v1.0.1`).

## Published release binaries (.tar)

Build the versioned binary package first:

```sh
sh ./build.sh
```

This generates a file like:

- `iox-aarch64-alpine-<version>.tar`

### Upload binary to GitHub release (manual)

After creating/pushing tag `v1.0.1`, publish the binary:

```sh
gh release create v1.0.1 iox-aarch64-alpine-1.0.1.tar --title v1.0.1 --generate-notes
```

If the release already exists:

```sh
gh release upload v1.0.1 iox-aarch64-alpine-1.0.1.tar --clobber
```

### Upload automation

Yes, binary uploads can be automated.

Example (local one-liner using `gh` and `VERSION`):

```sh
VERSION="$(tr -d '[:space:]' < VERSION)"; TAG="v${VERSION}"; ASSET="iox-aarch64-alpine-${VERSION}.tar"; git tag "${TAG}"; git push origin "${TAG}"; gh release create "${TAG}" "${ASSET}" --title "${TAG}" --generate-notes
```

You can also automate this in GitHub Actions to build and upload `*.tar` assets on every pushed tag (`v*`).
