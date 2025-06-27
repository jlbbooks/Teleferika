#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
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

print_debug() {
    echo -e "${PURPLE}[DEBUG]${NC} $1"
}

# Function to verify file exists
verify_file() {
    if [ ! -f "$1" ]; then
        print_error "Required file not found: $1"
        return 1
    fi
    return 0
}

# Function to verify directory exists
verify_directory() {
    if [ ! -d "$1" ]; then
        print_error "Required directory not found: $1"
        return 1
    fi
    return 0
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

# Check if Git is installed
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

# Verify essential directories exist
verify_directory "lib" || exit 1
verify_directory "lib/licensing" || exit 1
verify_file "pubspec.yaml" || exit 1

# Clean if requested
if [ "$CLEAN" = "true" ]; then
    print_status "Cleaning previous build..."
    flutter clean
    rm -rf .dart_tool/
    rm -rf build/
    
    # Clean up licensed features loader
    if [ -f "lib/licensing/licensed_features_loader.dart" ]; then
        rm "lib/licensing/licensed_features_loader.dart"
        print_status "Removed existing licensed features loader"
    fi
    
    # Optionally remove the licensed package directory
    if [ -d "licensed_features_package" ]; then
        print_status "Removing licensed package directory..."
    rm -rf licensed_features_package
    fi
fi

# Configure based on flavor
case $FLAVOR in
    "opensource"|"open"|"free")
        FLAVOR="opensource"
        print_status "🆓 Configuring for Open Source version..."

        # Verify required files exist
        verify_file "lib/licensing/licensed_features_loader_stub.dart" || exit 1

        # Remove licensed package dependency if present
        if [ -f "scripts/modify-pubspec.sh" ]; then
            ./scripts/modify-pubspec.sh remove-licensed
        else
            print_warning "modify-pubspec.sh not found, manually removing licensed package dependency"
        fi

        # Set up stub loader
        cp lib/licensing/licensed_features_loader_stub.dart lib/licensing/licensed_features_loader.dart
        print_success "Copied stub loader"
      
        print_success "✅ Open Source configuration applied"
        ;;

    "full"|"premium"|"licensed")
        FLAVOR="full"
        LICENSED_REPO_URL="git@github.com:jlbbooks/teleferika_licenced_packages.git"
        LICENSED_PACKAGE_DIR="licensed_features_package"

        print_status "⭐ Configuring for Full version with licensed features..."

        # Clone or update the licensed features repository
        if [ -d "$LICENSED_PACKAGE_DIR/.git" ]; then
            print_status "Licensed features repository already exists. Attempting to pull latest changes..."
            cd "$LICENSED_PACKAGE_DIR" || exit
            if git pull; then
                print_success "Pulled latest changes for licensed features."
            else
                print_warning "Failed to pull latest changes for licensed features. Using existing version."
            fi
            cd "$PROJECT_ROOT" || exit
        elif [ -d "$LICENSED_PACKAGE_DIR" ]; then
            print_warning "Directory '$LICENSED_PACKAGE_DIR' exists but is not a git repository."
            print_status "Removing existing directory and re-cloning..."
            rm -rf "$LICENSED_PACKAGE_DIR"
            git clone "$LICENSED_REPO_URL" "$LICENSED_PACKAGE_DIR"
            if [ $? -ne 0 ]; then
                print_error "Failed to clone licensed features repository from $LICENSED_REPO_URL."
                print_error "Please ensure you have access to the repository and SSH keys are set up if needed."
                exit 1
            fi
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

        # Verify the licensed package structure
        verify_directory "$LICENSED_PACKAGE_DIR/lib" || exit 1
        verify_file "$LICENSED_PACKAGE_DIR/lib/licensed_features_loader_full.dart" || exit 1
        verify_file "$LICENSED_PACKAGE_DIR/lib/licensed_plugin.dart" || exit 1

        # Add licensed package dependency
        if [ -f "scripts/modify-pubspec.sh" ]; then
            ./scripts/modify-pubspec.sh add-licensed
        else
            print_warning "modify-pubspec.sh not found, manually adding licensed package dependency"
        fi

        # Set up full loader
        cp "$LICENSED_PACKAGE_DIR/lib/licensed_features_loader_full.dart" "lib/licensing/licensed_features_loader.dart"
        print_success "Copied full loader"

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
if flutter pub get; then
    print_success "✅ Dependencies installed successfully"
else
    print_error "Failed to get dependencies"
    exit 1
fi

# Generate any necessary files
print_status "Generating code if needed..."
if grep -q "build_runner" pubspec.yaml; then
    print_status "Running build_runner..."
    if flutter packages pub run build_runner build --delete-conflicting-outputs; then
        print_success "✅ Code generation completed"
    else
        print_error "Build runner failed."
        exit 1
    fi
else
    print_status "No build_runner detected, skipping code generation"
fi

# Verify setup
print_status "Verifying setup..."
if ! flutter doctor > /dev/null 2>&1; then
    print_warning "Flutter doctor reported issues, but continuing..."
fi

# Verify the licensed features loader exists
if [ ! -f "lib/licensing/licensed_features_loader.dart" ]; then
    print_error "Licensed features loader not found after setup!"
    exit 1
fi

# Show current configuration
print_success "🎉 Setup complete!"
echo ""
echo "Current Configuration:"
echo "  Flavor: $FLAVOR"
echo "  Licensed Features Loader: $(basename lib/licensing/licensed_features_loader.dart)"

# Count dependencies
DEP_COUNT=$(awk '/^dependencies:/{flag=1;next}/^[a-zA-Z0-9_]+:/{flag=0}flag && !/^ *#/ && !/^$/{print}' pubspec.yaml | wc -l | tr -d ' ')
echo "  Dependencies: $DEP_COUNT packages (approx)"

# Show framework status
if [ "$FLAVOR" = "full" ]; then
    echo "  Framework: Full version with licensed features"
    if [ -d "licensed_features_package" ]; then
        echo "  Licensed Package: Available"
    else
        echo "  Licensed Package: Missing (setup may have failed)"
    fi
else
    echo "  Framework: Opensource version"
fi

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
echo ""
echo "To test the setup, run:"
echo "  ./scripts/test-setup.sh"
