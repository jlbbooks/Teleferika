# iOS App Store build (Xcode 26.3 on Sequoia)

Instructions for building a store IPA for the **full** flavor on macOS Sequoia when the App Store does not offer an Xcode update.

## Why this is needed

- This Mac is on **macOS Sequoia 15.x**. The App Store only offers the **latest** Xcode (27.x), which requires **macOS Tahoe**.
- Homebrew and current Flutter plugins expect **Xcode ≥ 26.3** (iOS SDK ≥ 26.1).
- `device_info_plus` 13.x uses `isiOSAppOnVision` (iOS **26.1** API). Xcode **26.0.1** ships iOS SDK **26.0** and fails the archive with:

  ```text
  No visible @interface for 'NSProcessInfo' declares the selector 'isiOSAppOnVision'
  ```

You do **not** need a separate **Command Line Tools for Xcode 26.3** package if you install full Xcode and point `xcode-select` at it.

## 1. Download Xcode 26.3

1. Sign in at [Apple Developer Downloads (all)](https://developer.apple.com/download/all/) (free Apple ID is enough).
2. Search for **Xcode 26.3**.
3. Download the matching `.xip`:
   - **Intel Mac** → `Xcode_26.3_Universal.xip`
   - **Apple silicon** → `Xcode_26.3_Apple_silicon.xip` (or Universal)

Do not rely on the Mac App Store for 26.3 on Sequoia.

## 2. Install and select Xcode 26.3

```bash
cd ~/Downloads
xip --expand Xcode_26.3_Universal.xip   # or the Apple silicon filename

# Optional: keep the old app
sudo mv /Applications/Xcode.app /Applications/Xcode-26.0.1.app

sudo mv ~/Downloads/Xcode.app /Applications/Xcode.app
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

Accept the license if prompted:

```bash
sudo xcodebuild -license accept
```

### Verify

```bash
xcode-select -p
# Expect: /Applications/Xcode.app/Contents/Developer

xcodebuild -version
# Expect: Xcode 26.3

xcrun --sdk iphoneos --show-sdk-version
# Expect: 26.1 or newer (26.2 is typical on 26.3)

flutter doctor
# Xcode line should be green
```

If `xcode-select -p` still shows `/Library/Developer/CommandLineTools`, switch again to the Xcode app path above.

## 3. Prepare the Teleferika full flavor

From the monorepo (sibling folders `teleferika.app`, `licensed_features_package`, `licence_server`):

```bash
cd /path/to/Teleferika/teleferika.app
./scripts/build-app.sh setup full
```

If `licensed_features_package` cannot pull (local dirt / old `xml` pin), update that repo first:

```bash
cd ../licensed_features_package
git checkout -- .gitignore
rm -f .fvmrc   # only if it blocks pull; remote brings its own
git checkout main && git pull
cd ../teleferika.app
./scripts/build-app.sh setup full
```

`licence_server` may sit on a detached submodule commit; a failed `git pull` there is usually only a warning.

## 4. Build the App Store IPA

Apple ID must be signed in for export (Xcode → **Settings → Accounts**, or `fastlane spaceauth -u YOUR_APPLE_ID`).

```bash
cd /path/to/Teleferika/teleferika.app
./scripts/build-app.sh build full --mode release --type ipa
```

Output (when successful): `build/ios/ipa/*.ipa`

### Build types (reminder)

| `--type`     | Result                                      |
|--------------|---------------------------------------------|
| `ipa`        | App Store / distribution IPA (what you want)|
| `ios`        | Device/simulator build only (no IPA)        |
| `appbundle`  | Android AAB                                 |

### If export fails (session / signing)

The archive path (if produced) can be opened in Xcode for **Distribute App**:

```bash
open build/ios/archive/Runner.xcarchive
```

Or use `./scripts/open-xcode.sh` and archive/distribute from the **full** scheme.

Always open **`ios/Runner.xcworkspace`**, not `Runner.xcodeproj`.

## 5. CocoaPods (only when iOS deps are wedged)

Normal `flutter build ipa` runs `pod install` for you. Manual reset:

```bash
cd /path/to/Teleferika/teleferika.app
fvm flutter clean   # or: flutter clean
fvm flutter pub get

cd ios
pod deintegrate
rm -rf Pods Podfile.lock
pod install
cd ..
```

## 6. Permanent `xcode-select` note

Earlier builds on this machine used Command Line Tools as the active developer directory, which produced `Application not configured for iOS`. After installing 26.3, keep:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

You can also set per-shell without sudo:

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

## Checklist

- [ ] Xcode 26.3 installed and selected
- [ ] `xcrun --sdk iphoneos --show-sdk-version` ≥ 26.1
- [ ] `./scripts/build-app.sh setup full` succeeded
- [ ] Apple ID signed in for distribution
- [ ] `./scripts/build-app.sh build full --mode release --type ipa` produced `build/ios/ipa/`
