#!/bin/bash

# Generate documentation for Teleferika project using FVM
# This script uses dartdoc (via FVM) to generate API documentation
#
# Usage:
#   ./scripts/generate-docs.sh [opensource|full]
#   - opensource: Generate docs for main project only
#   - full: Generate docs for main project and licensed features package

set -e

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
    echo "Usage: $0 [opensource|full]"
    echo ""
    echo "Parameters:"
    echo "  opensource  Generate documentation for main project only"
    echo "  full        Generate documentation for main project and licensed features package"
    echo ""
    echo "Examples:"
    echo "  $0 opensource"
    echo "  $0 full"
    echo ""
    echo "If no parameter is provided, defaults to 'opensource'"
}

# Parse command line arguments
FLAVOR=${1:-"opensource"}

# Show help if requested
if [ "$FLAVOR" = "-h" ] || [ "$FLAVOR" = "--help" ] || [ "$FLAVOR" = "help" ]; then
    show_usage
    exit 0
fi

# Validate flavor
if [ "$FLAVOR" != "opensource" ] && [ "$FLAVOR" != "full" ]; then
    print_error "Invalid flavor: $FLAVOR"
    show_usage
    exit 1
fi

print_status "📚 Generating Teleferika Documentation (FVM) for $FLAVOR flavor..."

# Check if FVM is installed
if ! command -v fvm &> /dev/null; then
    print_error "FVM is not installed. Please install FVM (https://fvm.app/) and try again."
    exit 1
fi

# Check if dartdoc is installed in the FVM environment
if ! fvm dart pub global list | grep -q dartdoc; then
    print_status "dartdoc is not installed in FVM environment. Installing..."
    fvm dart pub global activate dartdoc
fi

# Function to generate documentation for a project
generate_docs() {
    local project_name=$1
    local project_path=$2
    local output_path=$3
    
    print_status "Generating documentation for $project_name..."
    
    # Navigate to project directory
    cd "$project_path" || {
        print_error "Failed to navigate to $project_path"
        return 1
    }
    
    # Clean previous documentation
    if [ -d "$output_path" ]; then
        print_status "Cleaning previous documentation..."
        rm -rf "$output_path"
    fi
    
    # Generate documentation using FVM-managed Dart
    export PATH="$PATH":"$HOME/.pub-cache/bin"
    print_status "Generating documentation with FVM..."
    
    if fvm dart pub global run dartdoc --output "$output_path" --include-source; then
        print_success "✅ Documentation generated successfully for $project_name!"
        print_status "📁 Documentation is available at: $output_path/index.html"
        return 0
    else
        print_error "❌ Documentation generation failed for $project_name!"
        return 1
    fi
}

# Get the script directory and project root
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Generate documentation for main project
print_status "Generating documentation for main Teleferika project..."
if generate_docs "main project" "$PROJECT_ROOT" "doc/api"; then
    print_success "✅ Main project documentation completed"
    
    # Fix viewport meta tag accessibility issues
    print_status "🔧 Fixing viewport meta tag accessibility issues..."
    if "$SCRIPT_DIR/fix-docs-viewport.sh" "doc/api"; then
        print_success "✅ Viewport meta tag fixes completed"
    else
        print_warning "⚠️ Viewport meta tag fixes failed (continuing...)"
    fi
else
    print_error "❌ Main project documentation failed"
    exit 1
fi

# Generate documentation for licensed features package if full flavor
if [ "$FLAVOR" = "full" ]; then
    print_status "Generating documentation for licensed features package..."
    
    # Check if licensed features package exists
    if [ -d "$PROJECT_ROOT/licensed_features_package" ]; then
        if generate_docs "licensed features package" "$PROJECT_ROOT/licensed_features_package" "doc/api"; then
            print_success "✅ Licensed features package documentation completed"
            
            # Fix viewport meta tag accessibility issues for licensed features package
            print_status "🔧 Fixing viewport meta tag accessibility issues for licensed features package..."
            if "$SCRIPT_DIR/fix-docs-viewport.sh" "$PROJECT_ROOT/licensed_features_package/doc/api"; then
                print_success "✅ Licensed features package viewport meta tag fixes completed"
            else
                print_warning "⚠️ Licensed features package viewport meta tag fixes failed (continuing...)"
            fi
        else
            print_warning "⚠️ Licensed features package documentation failed (continuing...)"
        fi
    else
        print_warning "⚠️ Licensed features package directory not found, skipping..."
    fi
fi

# Open documentation in browser (optional)
print_status "Opening documentation in browser..."
if command -v xdg-open &> /dev/null; then
    xdg-open "$PROJECT_ROOT/doc/api/index.html"
elif command -v open &> /dev/null; then
    open "$PROJECT_ROOT/doc/api/index.html"
else
    print_warning "Could not automatically open browser. Please open: $PROJECT_ROOT/doc/api/index.html"
fi

print_success "🎉 Documentation generation complete for $FLAVOR flavor!" 