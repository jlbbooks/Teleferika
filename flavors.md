1. App Icons:
* Create flavor-specific resource directories:
* android/app/src/opensource/res/mipmap-* (for different icon densities)
* android/app/src/full/res/mipmap-
* Place the respective ic_launcher.png files in these directories.
2. Building Specific Flavors:
* First, run your setup script: ./scripts/setup-flavor.sh full or ./scripts/setup-flavor.sh opensource.
* Then build the Flutter app with the flavor:
  * flutter build appbundle --flavor full
  * flutter build appbundle --flavor opensource
  * (or apk instead of appbundle for APKs)
* The generated app bundles/APKs will be in build/app/outputs/bundle/fullRelease/ and build/app/outputs/bundle/opensourceRelease/ respectively.
3. Firebase (if used):
* If you use Firebase, each app variant (with its unique applicationId) will need to be registered as a separate app in your Firebase project.
* You'll need to place the corresponding google-services.json for each flavor:
* android/app/src/opensource/google-services.json
* android/app/src/full/google-services.json

Phase 4: App Icons (Optional)
1.Create New App Icon Sets:
* In Xcode, go to ios/Runner/Assets.xcassets.
* Right-click in the empty space of the left panel (where AppIcon is listed) and choose "New App Icon".
* Name it AppIcon-OpenSource.
* Create another one named AppIcon-Full.
* Drag your respective icon images into these new icon sets.
* 
2.Assign Icon Sets per Configuration:
* Go back to the "Runner" Target > "Build Settings".
* Search for "Primary App Icon Set Name" (or ASSETCATALOG_COMPILER_APPICON_NAME).
* Expand it and set the values for your configurations:
 * Debug-opensource: AppIcon-OpenSource
 * Release-opensource: AppIcon-OpenSource
 * Profile-opensource: AppIcon-OpenSource
 * Debug-full: AppIcon-Full
 * Release-full: AppIcon-Full
 * Profile-full: AppIcon-Full