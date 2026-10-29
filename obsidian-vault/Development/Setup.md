---
tags:
  - development
  - setup
---

# Setup

## Prerequisites

Flutter via [[FVM]], Git, Android Studio / VS Code, (macOS for iOS).

## Steps

1. `git clone --recurse-submodules <url>`
2. From repo root, ensure FVM version matches `.fvmrc` (`./scripts/fvm-use.sh`)
3. `cd teleferika.app`
4. `./scripts/setup-flavor.sh opensource` **or** `full`
5. `fvm flutter pub get`
6. `fvm flutter run --flavor <flavor>`

Verify: `./scripts/test-setup.sh`

## iOS note

Open Xcode with `./scripts/open-xcode.sh` (folder suffix `.app` confuses Finder).

## Related

- [[Flavors]] · [[Scripts]] · [[FVM]] · [[Debugging]]
