#!/bin/bash

# Fix viewport meta tag accessibility issue in generated documentation
# This script removes 'user-scalable=no' from viewport meta tags in HTML files
# to improve accessibility by allowing users to zoom the page

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
    echo "Usage: $0 [doc_path]"
    echo ""
    echo "Parameters:"
    echo "  doc_path    Path to documentation directory (default: doc/api)"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 doc/api"
    echo "  $0 licensed_features_package/doc/api"
    echo ""
    echo "This script fixes viewport meta tag accessibility issues by removing"
    echo "'user-scalable=no' from HTML files to allow users to zoom."
}

# Parse command line arguments
DOC_PATH=${1:-"doc/api"}

# Show help if requested
if [ "$DOC_PATH" = "-h" ] || [ "$DOC_PATH" = "--help" ] || [ "$DOC_PATH" = "help" ]; then
    show_usage
    exit 0
fi

# Check if documentation directory exists
if [ ! -d "$DOC_PATH" ]; then
    print_error "Documentation directory not found: $DOC_PATH"
    exit 1
fi

print_status "🔧 Fixing viewport meta tag accessibility issues in $DOC_PATH..."

# Count HTML files
HTML_COUNT=$(find "$DOC_PATH" -name "*.html" | wc -l)
print_status "Found $HTML_COUNT HTML files to process..."

# Use find and sed to process all HTML files at once
print_status "Processing HTML files..."

# Create a temporary script for sed
TEMP_SCRIPT=$(mktemp)
cat > "$TEMP_SCRIPT" << 'EOF'
# Remove user-scalable=no from viewport meta tags
s/<meta name="viewport" content="\([^"]*\)user-scalable=no\([^"]*\)"/<meta name="viewport" content="width=device-width, initial-scale=1.0"/g
s/<meta name="viewport" content="\([^"]*\)user-scalable=no\([^"]*\)"/<meta name="viewport" content="width=device-width, initial-scale=1.0"/g
EOF

# Process all HTML files that contain user-scalable=no (recursively)
FILES_TO_FIX=$(grep -r -l 'user-scalable=no' "$DOC_PATH" 2>/dev/null || true)

if [ -n "$FILES_TO_FIX" ]; then
    FIX_COUNT=$(echo "$FILES_TO_FIX" | wc -l)
    print_status "Found $FIX_COUNT files that need fixing..."
    
    # Process each file
    for file in $FILES_TO_FIX; do
        if [ -f "$file" ]; then
            print_status "Fixing: $(basename "$file")"
            
            # Create backup
            cp "$file" "$file.bak"
            
            # Apply the fix
            sed -f "$TEMP_SCRIPT" "$file" > "$file.tmp" && mv "$file.tmp" "$file"
            
            # Verify the fix
            if ! grep -q 'user-scalable=no' "$file"; then
                print_success "✅ Fixed: $(basename "$file")"
            else
                print_warning "⚠️ Could not fix: $(basename "$file")"
                mv "$file.bak" "$file"
            fi
        fi
    done
    
    print_success "🎉 Viewport meta tag fix complete!"
    print_status "Processed $FIX_COUNT files"
else
    print_status "ℹ️ No files found with user-scalable=no - all files are already accessible"
fi

# Clean up backup files
print_status "🧹 Cleaning up backup files..."
find "$DOC_PATH" -name "*.bak" -delete 2>/dev/null || true
print_success "✅ Backup files cleaned up"

# Clean up
rm -f "$TEMP_SCRIPT"

print_status "📁 Documentation is now accessible and users can zoom the pages" 