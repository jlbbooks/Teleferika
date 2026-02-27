## Running and Debugging the iOS App Over SSH

This document explains how to SSH into a macOS build host, run the Flutter iOS app on a physically connected iPhone, and monitor both Flutter and native logs to diagnose crashes.

---

### 1. One‑time setup on the macOS host (local, not over SSH)

Perform these steps once with physical access to the Mac and iPhone.

- **Install required tools**
  - **Xcode** from the App Store (and/or run `xcode-select --install` for Command Line Tools).
  - **Flutter SDK**, added to the `PATH`.
  - Verify setup:
    ```bash
    flutter doctor
    ```
    Fix any red issues, especially under **Xcode** and **iOS toolchain**.

- **Trust and enable the iPhone for development**
  - Connect the iPhone via USB.
  - Unlock the device and tap **Trust This Computer** when prompted.
  - Open **Xcode → Settings… → Accounts** and sign in with your Apple ID if needed.
  - Open **Xcode → Window → Devices and Simulators**, select the iPhone, and let Xcode finish “Preparing” the device.
  - In the app’s iOS project (e.g. open `ios/Runner.xcworkspace`), ensure:
    - The **Bundle Identifier** is correct.
    - A valid **Team** is selected in **Signing & Capabilities** for the `Runner` target.

- **Optional: extra CLI tools for native logs**
  - Recommended (for alternative logging utilities):
    ```bash
    brew install libimobiledevice ideviceinstaller
    ```

- **Ensure the CLI uses the full Xcode toolchain (for `xctrace`, etc.)**
  - Check what developer path is currently selected:
    ```bash
    xcode-select -p
    ```
    If this prints `/Library/Developer/CommandLineTools`, point it to the full Xcode app instead:
    ```bash
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
    ```
  - Accept the Xcode license if needed:
    ```bash
    sudo xcodebuild -license accept
    ```
  - Verify that `xctrace` is available:
    ```bash
    xcrun -find xctrace
    xcrun xctrace list devices
    ```
    You should see your Mac, any attached iPhones (for example `dev-iPhone2`), and available simulators listed.

- **Ensure the signing key is usable from SSH (unlock login keychain)**
  - Make sure you SSH in as the **same macOS user** that runs Xcode successfully:
    ```bash
    whoami
    ```
  - Check whether the login keychain is locked:
    ```bash
    security show-keychain-info ~/Library/Keychains/login.keychain-db
    ```
  - If the keychain is locked (or you see `errSecInternalComponent` when codesigning from Flutter), unlock it for this SSH session:
    ```bash
    security unlock-keychain -p '<macos-login-password>' ~/Library/Keychains/login.keychain-db
    ```
    Replace `<macos-login-password>` with the password you use to log into the Mac GUI. After this, the same signing identities Xcode uses interactively will be available to `flutter run` and `xcodebuild` when invoked over SSH.

Once this is complete, the remaining steps can be done over SSH.

---

### 2. SSH into the macOS host

From your Linux machine (or any other client):

```bash
ssh <mac-user>@<mac-hostname-or-ip>
```

For stable long‑running log sessions, it is recommended to use `tmux` or `screen`:

```bash
tmux new -s teleferika-debug
```

---

### 3. Go to the Flutter project

On the Mac (over SSH):

```bash
cd ~/StudioProjects/Teleferika/teleferika.app
```

Adjust the path if the project lives elsewhere.

---

### 4. Verify that the iPhone is visible to Flutter

With the iPhone connected and unlocked:

```bash
flutter devices
```

You should see something like:

```textdev-iPhone2
iPhone 15 Pro • 00008030-001C2D9E0C123456 • ios • iOS 18.1
```

Copy the **device ID** (or use the device name).

If the device is **not** listed:
```

- Ensure the phone is **unlocked**.
- Confirm Xcode sees it in **Devices and Simulators** (may require a local macOS session once).
- Check via:
  ```bash
  xcrun xctrace list devices
  ```

---

### 5. Run the app on the iPhone with Flutter logs

From the project root on the Mac:

```bash
flutter run --flavor full --debug -d <device-id-or-name>
```

Example:

```bash
flutter run --flavor full --debug -d "dev-iPhone2"
```

- This will:
  - Build the iOS Debug build.
  - Install the app on the connected iPhone.
  - Stream **Flutter/Dart logs** to the SSH terminal.
- Use the app on the iPhone to reproduce the crash and watch for:
  - Dart exceptions and stack traces.
  - Flutter/platform channel errors.
  - Any `FATAL`, `EXC_BAD_ACCESS`, or termination messages.

If the app crashes and exits, `flutter run` usually prints the termination reason (or at least notes that the process terminated).

---

### 6. Launch app manually and attach Flutter logs (alternative flow)

Sometimes you may prefer to launch the app manually on the device and then attach logging.

1. **Build and install only**:
   ```bash
   cd ~/StudioProjects/Teleferika/teleferika.app
   flutter run --debug -d <device-id> --no-start-paused --no-resident
   ```
   Once installed, you can stop the command with `Ctrl+C` if desired.

2. On the iPhone, **start the app** by tapping its icon on the home screen.

3. On the Mac, **attach Flutter logs**:
   ```bash
   flutter attach -d <device-id>
   ```

When the attach succeeds, you will see similar logs to `flutter run` while the app is running.

---

### 7. Monitor native iOS logs for crashes

Flutter logs may not always show low‑level native crashes. Use macOS logging tools in another SSH session or another `tmux` pane.

#### 7.1 Using `log stream` (built into macOS)

First, know the app’s bundle identifier (for example `com.yourcompany.teleferika`). If unsure:

- Open `ios/Runner.xcodeproj` or `ios/Runner.xcworkspace` locally.
- Check the `Bundle Identifier` field in the `Runner` target’s **General** or **Signing & Capabilities** tab.

Then, stream logs filtered by the app’s process or bundle ID:

```bash
log stream --predicate 'process == "Runner"' --style compact
```

or (if you want to filter by bundle/subsystem):

```bash
log stream --predicate 'subsystem CONTAINS "com.yourcompany.teleferika"' --style compact
```

Useful variations:

```bash
# Everything from the device, filtered by grep
log stream --style compact | grep -i teleferika

# Focus specifically on crash events
log stream --predicate 'eventType == "crash"' --style compact
```

Reproduce the crash and look for:

- `Terminating app due to uncaught exception ...`
- `EXC_BAD_ACCESS`, `SIGABRT`, or `SIGTRAP`.
- Backtraces involving your code, plugins, or frameworks.

#### 7.2 Using `idevicesyslog` (if installed)

If `libimobiledevice` is installed:

```bash
idevicesyslog | grep -i teleferika
```

This streams the device syslog over USB, which frequently includes crash details.

---

### 8. Collect crash reports for offline analysis

After a crash, iOS stores a crash report that you can retrieve from the Mac.

- **Via Xcode GUI**
  - Open **Xcode → Window → Devices and Simulators**.
  - Select your iPhone.
  - Click **View Device Logs**.
  - Locate the relevant crash log for the app and export it as needed.

- **Via CLI (with `idevicecrashreport`)**
  ```bash
  mkdir -p ~/iphone-crashlogs
  idevicecrashreport ~/iphone-crashlogs
  ls ~/iphone-crashlogs
  ```

You will get `.ips` or `.crash` files that you can store, share, or symbolicate.

---

### 9. Recommended day‑to‑day workflow for `Teleferika`

1. **SSH into the Mac** and start a `tmux` session:
   ```bash
   ssh <mac-user>@<mac-hostname-or-ip>
   tmux new -s teleferika-debug
   ```

2. **Pane 1 (Flutter run)**:
   ```bash
   cd ~/StudioProjects/Teleferika/teleferika.app
   flutter devices
   flutter run --debug -d <device-id>
   ```

3. **Pane 2 (native logs)**:
   ```bash
   log stream --predicate 'process == "Runner"' --style compact
   # or, if known:
   # log stream --predicate 'subsystem CONTAINS "com.yourcompany.teleferika"' --style compact
   ```

4. Reproduce the crash on the iPhone and:
   - Capture the Dart/Flutter stack traces from the `flutter run` pane.
   - Capture the relevant native crash information from the `log stream` pane (or `idevicesyslog`).

5. Save these logs for further debugging or sharing with the team.

