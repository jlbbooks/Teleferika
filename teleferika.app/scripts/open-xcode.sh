#!/bin/bash

# Script to open the iOS project in Xcode on macOS
# This script handles the issue where macOS treats folders ending in .app as application bundles

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_status() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only"
    print_status "On Linux/Windows, use Flutter commands directly:"
    echo "  fvm flutter build ios --flavor [flavor]"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed or not in PATH"
    print_status "Please install Xcode from the App Store"
    exit 1
fi

# Get the script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
IOS_DIR="$PROJECT_ROOT/ios"
WORKSPACE_FILE="$IOS_DIR/Runner.xcworkspace"

# Check if workspace file exists
if [ ! -d "$WORKSPACE_FILE" ]; then
    print_error "iOS workspace not found at: $WORKSPACE_FILE"
    print_status "Make sure you're running this from the project root"
    exit 1
fi

print_status "Opening iOS project in Xcode..."
print_status "Workspace: $WORKSPACE_FILE"

# Open the workspace file directly (not the folder)
open -a Xcode "$WORKSPACE_FILE"

if [ $? -eq 0 ]; then
    print_success "Xcode opened successfully"
    print_status "Note: Always open Runner.xcworkspace (not Runner.xcodeproj) when using CocoaPods"
else
    print_error "Failed to open Xcode"
    exit 1
fi
