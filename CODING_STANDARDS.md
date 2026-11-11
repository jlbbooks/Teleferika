# Coding standards

Mechanical checks for the Standards axis of code review. Add entries here when a miss is easy and the fix is a fixed look-up.

## `url_launcher` / `launchUrl` schemes

When a change **adds or extends** `launchUrl` / `url_launcher` with a **new URI scheme** (e.g. `mailto`):

1. Android — under `<queries>` in `teleferika.app/android/app/src/main/AndroidManifest.xml`, add an `<intent>` with `<data android:scheme="…"/>` (package visibility). Match the existing `mailto` shape:

   ```xml
   <intent>
       <action android:name="android.intent.action.SENDTO" />
       <data android:scheme="mailto" />
   </intent>
   ```

   Swap action/scheme for the new launch (e.g. `VIEW` + `https`); copy from the nearest existing query if unsure.

2. iOS — add the scheme string to `LSApplicationQueriesSchemes` in `teleferika.app/ios/Runner/Info.plist`.

**Done when:** every new scheme in the diff is declared in both files, or the review notes why a platform does not need it.

Reference: existing `mailto` declarations for feedback.
