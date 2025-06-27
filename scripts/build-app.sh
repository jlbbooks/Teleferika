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

# Function to show usage
show_usage() {
    echo "Usage: $0 [COMMAND] [FLAVOR] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  build     Build the app"
    echo "  run       Run the app"
    echo "  clean     Clean build artifacts"
    echo "  setup     Setup the specified flavor"
    echo ""
    echo "Flavors:"
    echo "  opensource  Open source version"
    echo "  full        Full version with licensed features"
    echo ""
    echo "Options:"
    echo "  --platform PLATFORM  Target platform (android-arm64, android-arm, ios)"
    echo "  --mode MODE          Build mode (debug, release, profile)"
    echo "  --type TYPE          Build type (apk, appbundle, ios)"
    echo ""
    echo "Examples:"
    echo "  $0 setup opensource"
    echo "  $0 build opensource --mode release --type apk"
    echo "  $0 run full --mode debug"
    echo "  $0 clean"
}

# Default values
COMMAND=""
FLAVOR=""
PLATFORM="android-arm64"
MODE="debug"
TYPE="apk"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        build|run|clean|setup)
            COMMAND="$1"
            shift
            ;;
        opensource|full)
            FLAVOR="$1"
            shift
            ;;
        --platform)
            PLATFORM="$2"
            shift 2
            ;;
        --mode)
            MODE="$2"
            shift 2
            ;;
        --type)
            TYPE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate command
if [ -z "$COMMAND" ]; then
    print_error "No command specified"
    show_usage
    exit 1
fi

# Handle clean command (doesn't need flavor)
if [ "$COMMAND" = "clean" ]; then
    print_status "Cleaning build artifacts..."
    flutter clean
    rm -rf build/
    rm -rf .dart_tool/
    print_success "✅ Clean completed"
    exit 0
fi

# Validate flavor for other commands
if [ -z "$FLAVOR" ]; then
    print_error "No flavor specified"
    show_usage
    exit 1
fi

# Validate flavor value
if [ "$FLAVOR" != "opensource" ] && [ "$FLAVOR" != "full" ]; then
    print_error "Invalid flavor: $FLAVOR"
    show_usage
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

# Navigate to project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT" || exit

print_status "Project root: $PROJECT_ROOT"
print_status "Command: $COMMAND"
print_status "Flavor: $FLAVOR"

# Handle setup command
if [ "$COMMAND" = "setup" ]; then
    print_status "Setting up $FLAVOR flavor..."
    if ./scripts/setup-flavor.sh "$FLAVOR"; then
        print_success "✅ Setup completed for $FLAVOR"
    else
        print_error "❌ Setup failed for $FLAVOR"
        exit 1
    fi
    exit 0
fi

# Verify the app is set up for the specified flavor
if [ ! -f "lib/licensing/licensed_features_loader.dart" ]; then
    print_error "App not set up. Run setup first: $0 setup $FLAVOR"
    exit 1
fi

# Verify the correct loader is in place
if [ "$FLAVOR" = "opensource" ]; then
    if ! grep -q "Licensed features not available" "lib/licensing/licensed_features_loader.dart"; then
        print_error "Wrong flavor setup. Run: $0 setup opensource"
        exit 1
    fi
elif [ "$FLAVOR" = "full" ]; then
    if ! grep -q "Licensed features registered successfully" "lib/licensing/licensed_features_loader.dart"; then
        print_error "Wrong flavor setup. Run: $0 setup full"
        exit 1
    fi
fi

# Handle build command
if [ "$COMMAND" = "build" ]; then
    print_status "Building $FLAVOR flavor in $MODE mode..."
    
    case $TYPE in
        apk)
            if flutter build apk --flavor "$FLAVOR" --mode "$MODE" --target-platform "$PLATFORM"; then
                print_success "✅ APK built successfully"
                print_status "APK location: build/app/outputs/flutter-apk/app-$FLAVOR-$MODE.apk"
            else
                print_error "❌ APK build failed"
                exit 1
            fi
            ;;
        appbundle)
            if flutter build appbundle --flavor "$FLAVOR" --mode "$MODE" --target-platform "$PLATFORM"; then
                print_success "✅ App bundle built successfully"
                print_status "Bundle location: build/app/outputs/bundle/${FLAVOR}Release/app-$FLAVOR-release.aab"
            else
                print_error "❌ App bundle build failed"
                exit 1
            fi
            ;;
        ios)
            if flutter build ios --flavor "$FLAVOR" --mode "$MODE"; then
                print_success "✅ iOS build completed"
            else
                print_error "❌ iOS build failed"
                exit 1
            fi
            ;;
        *)
            print_error "Unknown build type: $TYPE"
            exit 1
            ;;
    esac
fi

# Handle run command
if [ "$COMMAND" = "run" ]; then
    print_status "Running $FLAVOR flavor in $MODE mode..."
    
    if flutter run --flavor "$FLAVOR" --mode "$MODE"; then
        print_success "✅ App started successfully"
    else
        print_error "❌ App failed to start"
        exit 1
    fi
fi

print_success "🎉 Command completed successfully!" 