# Flutter / embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core (deferred components / split install); safe if unused
-dontwarn com.google.android.play.core.**

# Optional OEM window extension / sidecar APIs (not on the compile classpath)
-dontwarn androidx.window.extensions.**
-dontwarn androidx.window.sidecar.**
