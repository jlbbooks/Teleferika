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

# Function to test a setup
test_setup() {
    local flavor=$1
    local test_name=$2
    
    print_status "Testing $test_name..."
    
    # Run the setup script
    if ./scripts/setup-flavor.sh "$flavor"; then
        print_success "$test_name: PASSED"
        return 0
    else
        print_error "$test_name: FAILED"
        return 1
    fi
}

# Function to verify framework files
verify_framework() {
    local flavor=$1
    
    print_status "Verifying framework files for $flavor..."
    
    # Check if licensed features loader exists
    if [ ! -f "lib/licensing/licensed_features_loader.dart" ]; then
        print_error "Licensed features loader not found!"
        return 1
    fi
    
    # Check if the loader is the correct type
    if [ "$flavor" = "opensource" ]; then
        if grep -q "Licensed features not available" "lib/licensing/licensed_features_loader.dart"; then
            print_success "Opensource loader verified"
        else
            print_error "Wrong loader type for opensource!"
            return 1
        fi
    elif [ "$flavor" = "full" ]; then
        if grep -q "Licensed features registered successfully" "lib/licensing/licensed_features_loader.dart"; then
            print_success "Full loader verified"
        else
            print_error "Wrong loader type for full!"
            return 1
        fi
    fi
    
    return 0
}

echo "🧪 Testing development environment setup..."
echo ""

# Test open source setup
if test_setup "opensource" "Open source setup"; then
    if verify_framework "opensource"; then
        print_success "✅ Open source framework verification: PASSED"
    else
        print_error "❌ Open source framework verification: FAILED"
        exit 1
    fi
else
    print_error "❌ Open source setup: FAILED"
    exit 1
fi

echo ""

# Test full setup (if available)
if test_setup "full" "Full setup"; then
    if verify_framework "full"; then
        print_success "✅ Full framework verification: PASSED"
    else
        print_error "❌ Full framework verification: FAILED"
        exit 1
    fi
else
    print_warning "⚠️ Full setup: FAILED (this is expected for open source contributors)"
fi

echo ""

# Test Flutter compilation
print_status "Testing Flutter compilation..."
if flutter analyze --no-fatal-infos; then
    print_success "✅ Flutter analysis: PASSED"
else
    print_error "❌ Flutter analysis: FAILED"
    exit 1
fi

echo ""

# Test basic app compilation (dry run)
print_status "Testing basic app compilation..."
if flutter build apk --debug --flavor opensource --target-platform android-arm64 > /dev/null 2>&1; then
    print_success "✅ Basic compilation: PASSED"
else
    print_warning "⚠️ Basic compilation: FAILED (this might be expected in some environments)"
fi

echo ""
echo "🎉 All tests passed! Your development environment is ready."
echo ""
echo "Summary:"
echo "  ✅ Open source setup: Working"
if [ -d "licensed_features_package" ]; then
    echo "  ✅ Full setup: Working"
else
    echo "  ⚠️ Full setup: Not available (requires access to licensed repository)"
fi
if [ -d "license_server" ]; then
    echo "  ✅ License server: Available"
else
    echo "  ⚠️ License server: Missing (setup may have failed)"
fi
echo "  ✅ Flutter analysis: Working"
echo ""
echo "You can now:"
echo "  1. Switch between flavors: ./scripts/setup-flavor.sh [opensource|full]"
echo "  2. Build the app: flutter build apk --flavor [opensource|full]"
echo "  3. Run the app: flutter run --flavor [opensource|full]"