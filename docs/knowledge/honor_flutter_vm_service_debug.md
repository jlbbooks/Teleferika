# Honor: Flutter stuck on “Waiting for VM Service port…”

Status as of **2026-10-30**. Seen on **HONOR DNY-NX9** (Magic OS / Android 16) with Flutter **3.47.8** and Cursor/VS Code F5 debug.

## Symptom

Debug launch (F5) installs the app, then hangs:

```text
adb … am start … --ez start-paused true com.jlbbooks.teleferika/.MainActivity
Waiting for VM Service port to be available...
```

The phone stays on the **native Android splash** (`firstWindowDrawn=false`).  
`flutter run` without the debugger may still show a usable app, because it does **not** start paused — Dart runs even if the IDE never finds the VM Service URL.

## Root cause

Flutter finds the Dart VM Service by scraping **logcat** for a line like:

```text
I/flutter: The Dart VM service is listening on http://127.0.0.1:xxxxx/AUTH=/
```

On this Honor, app logs are **encrypted / suppressed**. `adb logcat` shows blobs such as:

```text
--------- beginning of (HKS)…hex…(HKE)
```

and **no** `The Dart VM service is listening on …` line. With `--start-paused`, the isolate never resumes, so the splash never goes away.

This is a device logging issue, not a Teleferika app bug. Similar reports: Nubia/RedMagic (`persist.log.tag`), Honor Magic OS project menu.

## Verify

```bash
adb logcat -c
# Launch the app once (F5 or flutter run), then:
adb logcat | rg -i 'Dart VM service|flutter'
```

| Result | Meaning |
|--------|---------|
| Clear `The Dart VM service is listening on http://…` | Logging OK — debugger can attach |
| Only `(HKS)…(HKE)` / no flutter VM line | Re-enable Honor logging (below) |

Optional: while stuck on splash, the process still listens on a loopback port (`adb shell cat /proc/$(pidof com.jlbbooks.teleferika)/net/tcp`) — the VM is up; Flutter just cannot discover the URL.

## Fix: enable Honor logging

1. Open the **Phone** dialer.
2. Dial: `*#*#2846579#*#*`  
   (project / engineering menu; it should open as soon as you type the last `*`).
3. Go to **Background Settings** (wording may vary by Magic OS version).
4. Enable **Log** / AP log / background logging.
5. Optionally also enable **USB debugging (Security settings)** under Developer options if present.
6. Unplug/replug USB or run `adb kill-server && adb start-server`.
7. Confirm with the verify commands above, then F5 again.

Temporary props that help on some OEM builds (may not survive reboot; on this DNY-NX9 alone they were **not** enough):

```bash
adb shell setprop log.tag I
adb shell setprop persist.log.tag I
```

## Temporary workaround (if you cannot enable logs yet)

Start **without** pause so the app leaves splash (IDE may still fail to attach for hot reload/breakpoints):

```bash
flutter run --flavor full --no-start-paused -d <device_id>
```

Or in `.vscode` / launch config (remove again once logging works):

```json
"toolArgs": ["--no-start-paused"]
```

```json
"dart.flutterRunAdditionalArgs": ["--no-start-paused"]
```

Do **not** leave this on permanently if you need normal debug attach / breakpoints at startup.

## Related host setup (Linux)

These were cleaned up at the same time; keep them in mind if device detection or emulators break:

1. **One ADB only**  
   Use `$ANDROID_HOME/platform-tools/adb` (`~/.AndroidStudio_sdk/platform-tools/adb`).  
   Do **not** put a wrapper named `adb` in `~/.local/bin` — Flutter reports it as a second binary and debug attach can fail.  
   `flutter doctor` should **not** say “Multiple adb binaries found”.

2. **Unified Android user home** (keys + AVD metadata):

   ```bash
   export ANDROID_HOME="$HOME/.AndroidStudio_sdk"
   export ANDROID_SDK_ROOT="$ANDROID_HOME"
   export ANDROID_USER_HOME="$HOME/.local/share/android"
   export ANDROID_AVD_HOME="$HOME/.local/share/android/avd"
   ```

   AVD `.ini` `path=` entries must point at the real dirs under `ANDROID_AVD_HOME`, not empty stubs under `~/.android/avd`.

3. If ADB looks confused:

   ```bash
   adb kill-server
   pkill -f '[a]db' || true
   adb start-server
   adb devices -l
   ```

## Checklist when F5 hangs again

1. `adb devices` — device `device`, not `unauthorized` / missing.
2. `flutter doctor` — no multiple adb binaries.
3. `adb logcat | rg 'Dart VM service'` — must show a plain HTTP URL.
4. If not: re-open `*#*#2846579#*#*` → Background Settings → enable Log.
5. Only then consider `--no-start-paused` as a short-term escape hatch.

## References

- Flutter tool waits on logcat VM URL (OEM filter cases): [flutter#144999](https://github.com/flutter/flutter/issues/144999)
- Honor / Magic OS project menu logging (community): dial `*#*#2846579#*#*`
- Repo wireless ADB notes: [WIRELESS_DEBUG.md](../../WIRELESS_DEBUG.md)
