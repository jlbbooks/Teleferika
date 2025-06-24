#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
FLAVOR=${1:-"opensource"}
CLEAN=${2:-"false"}

print_status "Setting up Flutter app for $FLAVOR flavor..."

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    print_status "Please install Flutter: https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Navigate to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

print_status "Project root: $PROJECT_ROOT"

# Clean if requested
if [ "$CLEAN" = "true" ]; then
    print_status "Cleaning previous build..."
    flutter clean
    rm -rf .dart_tool/
    rm -rf build/
fi

# Backup current pubspec if it exists
if [ -f "pubspec.yaml" ]; then
    cp pubspec.yaml pubspec.yaml.backup
    print_status "Backed up current pubspec.yaml"
fi

# Configure based on flavor
case $FLAVOR in
    "opensource"|"open"|"free")
        FLAVOR="opensource"
        print_status "🆓 Configuring for Open Source version..."

        if [ ! -f "build_configs/pubspec.opensource.yaml" ]; then
            print_error "build_configs/pubspec.opensource.yaml not found!"
            exit 1
        fi

        cp build_configs/pubspec.opensource.yaml pubspec.yaml

        # Set up stub loader
        if [ -f "lib/licencing/licensed_features_loader_stub.dart" ]; then
            cp lib/licencing/licensed_features_loader_stub.dart lib/licencing/licensed_features_loader.dart
        else
            print_warning "Stub loader not found, creating basic one..."
            mkdir -p lib/licencing
            cat > lib/licencing/licensed_features_loader.dart << 'EOF'
class LicensedFeaturesLoader {
  static Future<void> registerLicensedFeatures() async {
    print('Licensed features not available in this build');
  }
}
EOF
        fi

        print_success "✅ Open Source configuration applied"
        ;;

    "full"|"premium"|"licensed")
        FLAVOR="full"
        print_status "⭐ Configuring for Full version with licensed features..."

        if [ ! -f "build_configs/pubspec.full.yaml" ]; then
            print_error "build_configs/pubspec.full.yaml not found!"
            exit 1
        fi

        cp build_configs/pubspec.full.yaml pubspec.yaml

        # Set up full loader
        if [ -f "lib/licencing/licensed_features_loader_full.dart" ]; then
            cp licensed_features_package/lib/licensed_features_loader_full.dart lib/licencing/licensed_features_loader.dart
        else
            print_error "Full loader not found at lib/licencing/licensed_features_loader_full.dart"
            print_error "Licensed features may not work properly"
        fi

        print_success "✅ Full version configuration applied"
        ;;

    *)
        print_error "Unknown flavor: $FLAVOR"
        print_status "Available flavors: opensource, full"
        exit 1
        ;;
esac

# Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    print_success "✅ Dependencies installed successfully"
else
    print_error "Failed to get dependencies"
    exit 1
fi

# Generate any necessary files
print_status "Generating code if needed..."
if grep -q "build_runner" pubspec.yaml; then
    flutter packages pub run build_runner build --delete-conflicting-outputs
fi

# Verify setup
print_status "Verifying setup..."
flutter doctor > /dev/null 2>&1

# Show current configuration
print_success "🎉 Setup complete!"
echo ""
echo "Current Configuration:"
echo "  Flavor: $FLAVOR"
echo "  Dependencies: $(grep -c "dependencies:" pubspec.yaml 2>/dev/null || echo "Unknown") packages"
echo ""
echo "Next steps:"
echo "  1. Open your IDE (Android Studio, VS Code, etc.)"
echo "  2. Run the app normally (F5 in VS Code, or Run button in Android Studio)"
echo "  3. The app will launch with $FLAVOR features"
echo ""
echo "To switch flavors, run:"
echo "  ./scripts/setup-flavor.sh opensource"
echo "  ./scripts/setup-flavor.sh full"