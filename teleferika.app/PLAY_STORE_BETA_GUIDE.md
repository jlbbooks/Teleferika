# Play Store Beta Publishing Guide

This guide will walk you through publishing a beta version of TeleferiKa to the Google Play Store.

## Prerequisites

1. **Google Play Console Account**
   - Sign up at https://play.google.com/console
   - Pay the one-time $25 registration fee
   - Complete developer account setup

2. **App Listing Created**
   - Create your app in Play Console (if not already created)
   - Complete store listing (app name, description, screenshots, etc.)
   - Set up content rating

3. **Keystore for Signing**
   - You need a release keystore to sign your app
   - If you don't have one, we'll create it in Step 1

## Step 1: Verify Release Keystore

Your keystore is already set up in the `keys/` directory within the app folder. The configuration is:

- **Keystore file**: `keys/keystore.jks`
- **Properties file**: `keys/keystore.properties`
- **Key alias**: `upload`

The build configuration in `android/app/build.gradle.kts` is already set to use this keystore.

**⚠️ IMPORTANT:** 
- Keep `keystore.properties` and `.jks` file secure and backed up
- The `keys/` directory is already in `.gitignore` and won't be committed
- Never commit these files to git
- If you lose the keystore, you cannot update your app on Play Store!

**If you need to create a new keystore** (not recommended if you already have one):

```bash
# Navigate to the app directory
cd /home/michael/StudioProjects/Teleferika/teleferika.app

# Create keys directory
mkdir -p keys
cd keys

# Generate the keystore
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Create keystore.properties
cat > keystore.properties << EOF
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=../keys/keystore.jks
EOF
```

## Step 2: Update App Version

Before building, ensure your version is correct in `pubspec.yaml`:

```yaml
version: 1.1.0+91
```

- `1.1.0` = version name (user-visible)
- `91` = version code (must increment for each Play Store upload)

For beta, increment the version code (e.g., `1.1.0+92`).

## Step 3: Choose Your Flavor

Your app has two flavors:
- **`full`**: Production version (com.jlbbooks.teleferika)
- **`opensource`**: Open source version (com.jlbbooks.teleferika.open)

Decide which flavor to publish. For beta, typically use `full`.

## Step 4: Build the Release App Bundle (AAB)

**Option A: Using the build script (Recommended)**

```bash
cd /home/michael/StudioProjects/Teleferika/teleferika.app

# Setup the flavor first (if not already done)
./scripts/setup-flavor.sh full

# Build the release app bundle
./scripts/build-app.sh build full release appbundle
```

**Option B: Using Flutter directly**

```bash
cd /home/michael/StudioProjects/Teleferika/teleferika.app

# Ensure you're on the correct flavor
./scripts/setup-flavor.sh full

# Build the AAB
flutter build appbundle --flavor full --release
```

The AAB will be located at:
```
build/app/outputs/bundle/fullRelease/app-full-release.aab
```

## Step 5: Prepare Release Notes

Update `play_store_changelog.txt` with your beta release notes. The file should contain:

```
<en-GB>
- Your beta release notes in English
- List key changes or fixes
</en-GB>

<it-IT>
- Le tue note di rilascio beta in italiano
- Elenca le modifiche o correzioni principali
</it-IT>
```

## Step 6: Upload to Play Store Beta

### 6.1 Access Play Console

1. Go to https://play.google.com/console
2. Select your app (TeleferiKa)
3. In the left menu, go to **Testing** → **Internal testing** (or **Closed testing** / **Open testing**)

### 6.2 Create a New Release

1. Click **Create new release** (or **Create release**)
2. Upload your AAB file:
   - Click **Upload** or drag and drop `app-full-release.aab`
   - Wait for upload and processing to complete

### 6.3 Add Release Notes

1. In the **Release notes** section, add your changelog
2. You can copy from `play_store_changelog.txt`
3. Add notes for each language you support (en-GB, it-IT)

### 6.4 Review and Rollout

1. Review the release details
2. Click **Save** (or **Review release**)
3. Review the release summary
4. Click **Start rollout to Internal testing** (or your chosen track)

## Step 7: Set Up Beta Testers

### Internal Testing (Fastest)
- Up to 100 testers
- No review process
- Testers added via email list or Google Groups

### Closed Testing
- Larger groups
- Can have multiple test tracks
- Requires review (usually quick)

### Open Testing
- Public beta
- Anyone can join
- Requires review

**To add testers:**
1. Go to **Testing** → **Internal testing** → **Testers** tab
2. Add email addresses or create a Google Group
3. Share the opt-in link with testers

## Step 8: Monitor Beta Release

1. **Check Release Status**
   - Go to **Testing** → **Internal testing** → **Releases**
   - Monitor processing status

2. **View Feedback**
   - Check **User feedback** section
   - Monitor crash reports in **Quality** → **Android vitals**

3. **Track Metrics**
   - View installs, crashes, ANRs in the dashboard

## Troubleshooting

### Build Errors

**Error: Keystore not found**
- Ensure `keys/keystore.properties` exists
- Check the path in `build.gradle.kts` matches your setup

**Error: Signing config error**
- Verify keystore passwords are correct
- Check key alias matches (`upload`)

**Error: AAR metadata check failures / compileSdk version conflicts**
- If you encounter AAR metadata check errors with plugins compiled against older SDK versions, try downgrading the Android Gradle Plugin in `android/settings.gradle.kts`:
  ```kotlin
  id("com.android.application") version "8.12.2" apply false
  ```
- Ensure `compileSdk` in `android/app/build.gradle.kts` is set appropriately (e.g., 36)

**Error: Kotlin compilation errors**
- Check for Java-style iterator usage (`hasNext()`, `next()`) and convert to Kotlin `for-in` loops
- Example: `while (iterator.hasNext())` → `for (item in iterable)`

### Upload Errors

**Error: Version code already exists**
- Increment version code in `pubspec.yaml`
- Rebuild the AAB

**Error: AAB validation failed**
- Ensure you're uploading an AAB, not APK
- Check that the AAB was built in release mode

### Play Console Issues

**App not appearing**
- Ensure you've completed all required store listing fields
- Check that content rating is complete
- Verify app is not in draft state

## Quick Reference Commands

```bash
# Setup full flavor
./scripts/setup-flavor.sh full

# Build release AAB
flutter build appbundle --flavor full --release

# Check AAB location
ls -lh build/app/outputs/bundle/fullRelease/app-full-release.aab

# Verify AAB (optional)
bundletool build-apks --bundle=build/app/outputs/bundle/fullRelease/app-full-release.aab --output=test.apks
```

## Next Steps After Beta

Once beta testing is complete:

1. **Fix any critical issues** found during beta
2. **Increment version code** for production release
3. **Update release notes** for production
4. **Promote to Production**:
   - In Play Console, go to **Production**
   - Create a new release
   - Upload the production AAB
   - Or promote directly from beta track

## Important Notes

- **Version Code**: Must always increase for each upload (even if version name stays the same)
- **Signing**: Always use the same keystore for updates
- **Testing**: Test the AAB on a device before uploading (use `bundletool` or install via Play Console internal testing)
- **Backup**: Keep your keystore safe and backed up in multiple secure locations

## Resources

- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Flutter App Signing](https://docs.flutter.dev/deployment/android#signing-the-app)
- [Play Store Beta Testing](https://support.google.com/googleplay/android-developer/answer/9845334)
- [App Bundle Format](https://developer.android.com/guide/app-bundle)
