# Release playbook

Steps for tagging a release and producing a store build. Detail for Play/App Store upload lives in `teleferika.app/PLAY_STORE_BETA_GUIDE.md` and `teleferika.app/IOS_APP_STORE_BUILD.md`.

## 1. Land on `main` before tagging

1. Merge the release work into `main` (PR or fast-forward).
2. Checkout and update `main` locally.
3. Tag **from that `main` tip** (`git tag …` then `git push origin <tag>`).

One tag on the post-merge `main` tip keeps version codes and store uploads aligned; tagging earlier forces retags.

## 2. Submodule commit + push before the parent pointer

When the release includes changes in `licensed_features_package` or `licence_server`:

1. In the submodule: commit, push to its remote, note the commit SHA.
2. In the parent monorepo: update the submodule pointer to that SHA, commit, push.
3. Only then tag (or bump `pubspec` version) on the parent.

A parent commit that points at a submodule SHA that was never pushed leaves clones and CI on a missing object.

## 3. Store builds via `build-app.sh`

From `teleferika.app/`, after flavor setup (`./scripts/setup-flavor.sh full` or `./scripts/build-app.sh setup full`):

```bash
# Play Store AAB (full flavor)
./scripts/build-app.sh build full --mode release --type appbundle

# App Store IPA (full flavor)
./scripts/build-app.sh build full --mode release --type ipa
```

Upload paths, signing, and store steps: `teleferika.app/PLAY_STORE_BETA_GUIDE.md`, `teleferika.app/IOS_APP_STORE_BUILD.md`. Flag reference: `./scripts/build-app.sh --help`.
