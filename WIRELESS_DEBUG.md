# Wireless Debugging for Android in VSCode/Cursor

This guide explains how to set up wireless debugging for Android devices in VSCode/Cursor, similar to Android Studio's wireless debugging feature.

## Prerequisites

1. **Android Device Requirements:**
   - Android 11 (API level 30) or higher
   - Developer Options enabled
   - USB debugging enabled (initially, for first-time setup)

2. **Computer Requirements:**
   - ADB (Android Debug Bridge) installed
   - Device and computer on the same Wi-Fi network
   - Flutter SDK installed (for Flutter projects)

## Quick Setup

### Option 1: Using the Helper Script (Recommended)

We've provided a helper script to make the process easier:

```bash
cd teleferika.app
./scripts/wireless-debug.sh connect
```

The script will guide you through the pairing and connection process.

### Option 2: Manual Setup

#### Step 1: Enable Wireless Debugging on Your Device

1. Open **Settings** on your Android device
2. Go to **About phone** and tap **Build number** 7 times to enable Developer Options (if not already enabled)
3. Go back to **Settings** > **Developer options**
4. Enable **Wireless debugging**
5. Tap **Wireless debugging** to open the options
6. Tap **Pair device with pairing code**
7. Note the **IP address and port** shown (e.g., `192.168.1.100:12345`)
8. Note the **6-digit pairing code**

#### Step 2: Pair Your Device

On your computer, run:

```bash
adb pair <IP_ADDRESS>:<PORT>
```

For example:
```bash
adb pair 192.168.1.100:12345
```

When prompted, enter the 6-digit pairing code from your device.

#### Step 3: Connect to Your Device

After successful pairing, you'll see a new IP address and port on your device (usually different from the pairing port). Connect using:

```bash
adb connect <IP_ADDRESS>:<PORT>
```

For example:
```bash
adb connect 192.168.1.100:45678
```

#### Step 4: Verify Connection

Check that your device is connected:

```bash
adb devices
```

You should see your device listed with "device" status.

## Using in VSCode/Cursor

Once your device is connected via ADB:

1. **Flutter Extension:**
   - Open the Command Palette (Ctrl+Shift+P / Cmd+Shift+P)
   - Run `Flutter: Select Device`
   - Your wireless device should appear in the list
   - Select it and run/debug your app normally

2. **Device Detection:**
   - VSCode/Cursor with Flutter extension automatically detects devices connected via ADB
   - The device will appear in the status bar and device selector

## Troubleshooting

### Device Not Appearing in VSCode/Cursor

1. **Verify ADB connection:**
   ```bash
   adb devices
   ```
   If your device shows "unauthorized", check your device and accept the USB debugging prompt.

2. **Restart ADB server:**
   ```bash
   adb kill-server
   adb start-server
   ```

3. **Check Flutter device detection:**
   ```bash
   flutter devices
   ```

### Connection Issues

- **Same Network:** Ensure both device and computer are on the same Wi-Fi network
- **Firewall:** Check if your firewall is blocking ADB connections
- **Port Forwarding:** Some routers may block ADB ports; try a different network
- **Re-pair:** If connection drops, you may need to re-pair:
  ```bash
  ./scripts/wireless-debug.sh disconnect
  ./scripts/wireless-debug.sh connect
  ```

### ADB Not Found

Install Android SDK Platform Tools:

- **Linux:**
  ```bash
  sudo apt-get install android-tools-adb
  ```

- **macOS:**
  ```bash
  brew install android-platform-tools
  ```

- **Windows:**
  Download from [Android Developer](https://developer.android.com/studio/releases/platform-tools)

## Helper Script Commands

The `wireless-debug.sh` script provides several commands:

```bash
# Connect a device wirelessly
./scripts/wireless-debug.sh connect

# Disconnect all wireless devices
./scripts/wireless-debug.sh disconnect

# Check current connection status
./scripts/wireless-debug.sh status
```

## Tips

1. **Persistent Connection:** Wireless debugging may disconnect when your device goes to sleep. You may need to reconnect occasionally.

2. **First-Time Setup:** The first connection usually requires USB debugging enabled. After that, you can use wireless debugging exclusively.

3. **Multiple Devices:** You can connect multiple devices wirelessly. Each will appear in VSCode/Cursor's device list.

4. **Security:** Wireless debugging is secure and uses encrypted connections. However, only use it on trusted networks.

5. **Performance:** Wireless debugging may be slightly slower than USB, but it's usually negligible for most development tasks.

## Additional Resources

- [Android Wireless Debugging Documentation](https://developer.android.com/studio/command-line/adb#connect-to-a-device-over-wi-fi)
- [Flutter Device Selection](https://docs.flutter.dev/get-started/test-drive#selecting-a-device)
