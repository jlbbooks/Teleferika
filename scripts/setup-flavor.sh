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

# Check if Git is installed (new check)
if ! command -v git &> /dev/null; then
    print_error "Git is not installed or not in PATH."
    print_status "Please install Git: https://git-scm.com/downloads"
    exit 1
fi

# Navigate to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || exit

print_status "Project root: $PROJECT_ROOT"

# Clean if requested
if [ "$CLEAN" = "true" ]; then
    print_status "Cleaning previous build..."
    flutter clean
    rm -rf .dart_tool/
    rm -rf build/
    # Optionally remove the licensed package directory if you want a fresh clone every time with clean
    # rm -rf licensed_features_package/
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
        if [ -f "lib/licensing/licensed_features_loader_stub.dart" ]; then
            cp lib/licensing/licensed_features_loader_stub.dart lib/licensing/licensed_features_loader.dart
        else
            print_warning "Stub loader not found, creating basic one..."
            mkdir -p lib/licensing
            cat > lib/licensing/licensed_features_loader.dart << 'EOF'
class LicensedFeaturesLoader {
  static Future<void> registerLicensedFeatures() async {
    // Stub implementation
    print('Licensed features not available in this build (stub loader)');
  }
}
EOF
        fi

        print_success "✅ Open Source configuration applied"
        ;;

    "full"|"premium"|"licensed")
        FLAVOR="full"
        LICENSED_REPO_URL="git@github.com:jlbbooks/teleferika_licenced_packages.git"
        LICENSED_PACKAGE_DIR="licensed_features_package" # Directory to clone into

        print_status "⭐ Configuring for Full version with licensed features..."

        # Clone or update the licensed features repository
        if [ -d "$LICENSED_PACKAGE_DIR/.git" ]; then
            print_status "Licensed features repository already exists. Attempting to pull latest changes..."
            cd "$LICENSED_PACKAGE_DIR" || exit
            git pull
            if [ $? -ne 0 ]; then
                print_warning "Failed to pull latest changes for licensed features. Using existing version."
            else
                print_success "Pulled latest changes for licensed features."
            fi
            cd "$PROJECT_ROOT" || exit # Go back to project root
        elif [ -d "$LICENSED_PACKAGE_DIR" ]; then
             print_warning "Directory '$LICENSED_PACKAGE_DIR' exists but is not a git repository. Please remove it or ensure it's the correct repository."
             # Optionally, you could add 'rm -rf $LICENSED_PACKAGE_DIR' here to force a re-clone,
             # but be careful with automatic deletion.
        else
            print_status "Cloning licensed features from $LICENSED_REPO_URL into $LICENSED_PACKAGE_DIR..."
            git clone "$LICENSED_REPO_URL" "$LICENSED_PACKAGE_DIR"
            if [ $? -ne 0 ]; then
                print_error "Failed to clone licensed features repository from $LICENSED_REPO_URL."
                print_error "Please ensure you have access to the repository and SSH keys are set up if needed."
                exit 1
            else
                print_success "Cloned licensed features repository successfully."
            fi
        fi

        if [ ! -f "build_configs/pubspec.full.yaml" ]; then
            print_error "build_configs/pubspec.full.yaml not found!"
            exit 1
        fi

        cp build_configs/pubspec.full.yaml pubspec.yaml

        # Set up full loader - path relative to project root
        FULL_LOADER_SOURCE_PATH="$LICENSED_PACKAGE_DIR/lib/licensed_features_loader_full.dart" # Adjust if path in repo is different
        FULL_LOADER_DEST_PATH="lib/licensing/licensed_features_loader.dart"

        if [ -f "$FULL_LOADER_SOURCE_PATH" ]; then
            mkdir -p "$(dirname "$FULL_LOADER_DEST_PATH")" # Ensure destination directory exists
            cp "$FULL_LOADER_SOURCE_PATH" "$FULL_LOADER_DEST_PATH"
            print_status "Copied full loader from $FULL_LOADER_SOURCE_PATH"
        else
            print_error "Full loader not found at $FULL_LOADER_SOURCE_PATH"
            print_error "Licensed features may not work properly. Ensure the repository was cloned correctly and the file path is accurate."
            # Optionally, exit here if this file is critical
            exit 1
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
    if [ $? -ne 0 ]; then
        print_error "Build runner failed."
        exit 1
    fi
fi

# Verify setup
print_status "Verifying setup..."
flutter doctor > /dev/null 2>&1 # Suppress output unless there's an error in flutter doctor itself

# Show current configuration
print_success "🎉 Setup complete!"
echo ""
echo "Current Configuration:"
echo "  Flavor: $FLAVOR"
# A more robust way to count dependencies if pubspec.yaml format varies
# For example, count non-commented lines under 'dependencies:'
DEP_COUNT=$(awk '/^dependencies:/{flag=1;next}/^[a-zA-Z0-9_]+:/{flag=0}flag && !/^ *#/ {print}' pubspec.yaml | wc -l | tr -d ' ')
echo "  Dependencies: $DEP_COUNT packages (approx)"
echo ""
echo "Next steps:"
echo "  1. Open/Restart your IDE (Android Studio, VS Code, etc.)"
echo "  2. Run the app normally (F5 in VS Code, or Run button in Android Studio)"
echo "  3. The app will launch with $FLAVOR features"
echo ""
echo "To switch flavors, run:"
echo "  $0 opensource"
echo "  $0 full"
echo "  $0 full true  (to also clean before setup)"
