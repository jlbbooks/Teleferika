#!/bin/bash

# Default to open source build
BUILD_TYPE=${1:-"open"}
PLATFORM=${2:-"apk"}

echo "Building $BUILD_TYPE version for $PLATFORM..."

# Backup current pubspec
cp pubspec.yaml pubspec.yaml.backup

# Copy appropriate pubspec
if [ "$BUILD_TYPE" = "full" ]; then
    echo "Using full configuration with licensed features..."
    cp build_configs/pubspec.full.yaml pubspec.yaml
    # Copy the full licensed features loader
    cp lib/licencing/licensed_features_loader_full.dart lib/licencing/licensed_features_loader.dart
else
    echo "Using open source configuration..."
    cp build_configs/pubspec.open_source.yaml pubspec.yaml
    # Ensure we're using the stub loader (create empty stub if it doesn't exist)
    if [ ! -f "lib/licencing/licensed_features_loader_stub.dart" ]; then
        cat > lib/licencing/licensed_features_loader_stub.dart << 'EOF'
import 'feature_registry.dart';

class LicensedFeaturesLoader {
  static Future<void> registerLicensedFeatures() async {
    print('Licensed features not available in this build');
  }
}
EOF
    fi
    cp lib/licencing/licensed_features_loader_stub.dart lib/licencing/licensed_features_loader.dart
fi

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Build based on platform
case $PLATFORM in
    "apk")
        echo "Building APK..."
        flutter build apk --release
        ;;
    "appbundle")
        echo "Building appbundle..."
        flutter build appbundle --release
        ;;
    "ios")
        echo "Building iOS..."
        flutter build ios --release
        ;;
    *)
        echo "Unknown platform: $PLATFORM"
        echo "Supported platforms: apk, bundle, ios"
        exit 1
        ;;
esac

# Restore original pubspec
echo "Restoring original pubspec..."
mv pubspec.yaml.backup pubspec.yaml

# Restore original loader
git checkout lib/licencing/licensed_features_loader.dart 2>/dev/null || echo "No original loader to restore"

echo "Build complete!"