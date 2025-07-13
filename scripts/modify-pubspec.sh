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
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  add-licensed     Add licensed_features_package dependency"
    echo "  remove-licensed  Remove licensed_features_package dependency"
    echo "  status          Show current status of licensed package in pubspec.yaml"
    echo ""
    echo "Examples:"
    echo "  $0 add-licensed"
    echo "  $0 remove-licensed"
    echo "  $0 status"
}

# Function to add licensed package dependency
add_licensed_package() {
    local pubspec_file="pubspec.yaml"
    
    if [ ! -f "$pubspec_file" ]; then
        print_error "pubspec.yaml not found"
        return 1
    fi
    
    # Check if already exists
    if grep -q "licensed_features_package:" "$pubspec_file"; then
        print_warning "Licensed package dependency already exists"
        return 0
    fi
    
    # Create temporary file
    local temp_file=$(mktemp)
    
    # Process the file line by line
    while IFS= read -r line; do
        echo "$line" >> "$temp_file"
        
        # If we find the placeholder, replace it with the actual dependency
        if [[ "$line" == *"LICENSED_PACKAGE_PLACEHOLDER"* ]]; then
            echo "  licensed_features_package:" >> "$temp_file"
            echo "    path: ./licensed_features_package" >> "$temp_file"
            echo "" >> "$temp_file"
        fi
    done < "$pubspec_file"
    
    # Replace original file
    mv "$temp_file" "$pubspec_file"
    
    print_success "Added licensed_features_package dependency"
    return 0
}

# Function to remove licensed package dependency
remove_licensed_package() {
    local pubspec_file="pubspec.yaml"
    
    if [ ! -f "$pubspec_file" ]; then
        print_error "pubspec.yaml not found"
        return 1
    fi
    
    # Check if exists
    if ! grep -q "licensed_features_package:" "$pubspec_file"; then
        print_warning "Licensed package dependency not found"
        return 0
    fi
    
    # Create temporary file
    local temp_file=$(mktemp)
    local skip_next=false
    
    # Process the file line by line
    while IFS= read -r line; do
        # Skip the licensed_features_package line and its indented content
        if [[ "$line" == *"licensed_features_package:"* ]]; then
            skip_next=true
            continue
        fi
        
        # Skip indented lines after licensed_features_package
        if [ "$skip_next" = true ]; then
            # Check if this line is indented (starts with spaces)
            if [[ "$line" =~ ^[[:space:]]+ ]]; then
                # Still indented, continue skipping
                continue
            else
                # Found a non-indented line, stop skipping
                skip_next=false
            fi
        fi
        
        echo "$line" >> "$temp_file"
    done < "$pubspec_file"
    
    # Replace original file
    mv "$temp_file" "$pubspec_file"
    
    print_success "Removed licensed_features_package dependency"
    return 0
}

# Function to show status
show_status() {
    local pubspec_file="pubspec.yaml"
    
    if [ ! -f "$pubspec_file" ]; then
        print_error "pubspec.yaml not found"
        return 1
    fi
    
    if grep -q "licensed_features_package:" "$pubspec_file"; then
        print_success "Licensed package dependency is present"
        echo "Current configuration:"
        grep -A 2 "licensed_features_package:" "$pubspec_file"
    else
        print_warning "Licensed package dependency is not present"
    fi
    
    return 0
}

# Parse command line arguments
case "${1:-}" in
    "add-licensed")
        add_licensed_package
        ;;
    "remove-licensed")
        remove_licensed_package
        ;;
    "status")
        show_status
        ;;
    "-h"|"--help"|"")
        show_usage
        ;;
    *)
        print_error "Unknown command: $1"
        show_usage
        exit 1
        ;;
esac 