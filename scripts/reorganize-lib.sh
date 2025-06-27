#!/bin/bash

# TeleferiKa Lib Directory Reorganization Script
# This script helps reorganize the lib directory for better structure

set -e

LIB_DIR="lib"
BACKUP_DIR="lib_backup_$(date +%Y%m%d_%H%M%S)"

echo "🚀 Starting TeleferiKa lib directory reorganization..."

# Create backup
echo "📦 Creating backup of current lib directory..."
cp -r "$LIB_DIR" "$BACKUP_DIR"
echo "✅ Backup created: $BACKUP_DIR"

# Create new directory structure
echo "📁 Creating new directory structure..."
mkdir -p "$LIB_DIR"/{core/utils,ui/{pages,widgets,tabs},features/export}

# Move core files
echo "🔧 Moving core files..."
if [ -f "$LIB_DIR/app_config.dart" ]; then
    mv "$LIB_DIR/app_config.dart" "$LIB_DIR/core/"
    echo "  ✅ Moved app_config.dart to core/"
fi

if [ -f "$LIB_DIR/logger.dart" ]; then
    mv "$LIB_DIR/logger.dart" "$LIB_DIR/core/"
    echo "  ✅ Moved logger.dart to core/"
fi

if [ -f "$LIB_DIR/utils/uuid_generator.dart" ]; then
    mv "$LIB_DIR/utils/uuid_generator.dart" "$LIB_DIR/core/utils/"
    echo "  ✅ Moved uuid_generator.dart to core/utils/"
fi

# Move UI pages
echo "📄 Moving UI pages..."
if [ -f "$LIB_DIR/projects_list_page.dart" ]; then
    mv "$LIB_DIR/projects_list_page.dart" "$LIB_DIR/ui/pages/"
    echo "  ✅ Moved projects_list_page.dart to ui/pages/"
fi

if [ -f "$LIB_DIR/project_page.dart" ]; then
    mv "$LIB_DIR/project_page.dart" "$LIB_DIR/ui/pages/"
    echo "  ✅ Moved project_page.dart to ui/pages/"
fi

if [ -f "$LIB_DIR/point_details_page.dart" ]; then
    mv "$LIB_DIR/point_details_page.dart" "$LIB_DIR/ui/pages/"
    echo "  ✅ Moved point_details_page.dart to ui/pages/"
fi

if [ -f "$LIB_DIR/loading_page.dart" ]; then
    mv "$LIB_DIR/loading_page.dart" "$LIB_DIR/ui/pages/"
    echo "  ✅ Moved loading_page.dart to ui/pages/"
fi

# Move UI widgets
echo "🧩 Moving UI widgets..."
if [ -f "$LIB_DIR/photo_manager_widget.dart" ]; then
    mv "$LIB_DIR/photo_manager_widget.dart" "$LIB_DIR/ui/widgets/"
    echo "  ✅ Moved photo_manager_widget.dart to ui/widgets/"
fi

# Move UI tabs
echo "📑 Moving UI tabs..."
if [ -d "$LIB_DIR/project_tools" ]; then
    mv "$LIB_DIR/project_tools"/* "$LIB_DIR/ui/tabs/"
    echo "  ✅ Moved project_tools/* to ui/tabs/"
    rmdir "$LIB_DIR/project_tools"
fi

# Move export feature
echo "📤 Moving export feature..."
if [ -d "$LIB_DIR/export" ]; then
    mv "$LIB_DIR/export"/* "$LIB_DIR/features/export/"
    echo "  ✅ Moved export/* to features/export/"
    rmdir "$LIB_DIR/export"
fi

# Clean up empty directories
echo "🧹 Cleaning up empty directories..."
if [ -d "$LIB_DIR/utils" ] && [ -z "$(ls -A "$LIB_DIR/utils")" ]; then
    rmdir "$LIB_DIR/utils"
    echo "  ✅ Removed empty utils/ directory"
fi

if [ -d "$LIB_DIR/map" ] && [ -z "$(ls -A "$LIB_DIR/map")" ]; then
    rmdir "$LIB_DIR/map"
    echo "  ✅ Removed empty map/ directory"
fi

# Create README files for each major directory
echo "📝 Creating README files..."
cat > "$LIB_DIR/core/README.md" << 'EOF'
# Core

This directory contains core application functionality that is used throughout the app.

## Files

- `app_config.dart` - Application configuration (themes, locales, etc.)
- `logger.dart` - Logging system configuration
- `utils/` - Core utility functions
  - `uuid_generator.dart` - UUID generation utilities
EOF

cat > "$LIB_DIR/ui/README.md" << 'EOF'
# UI

This directory contains all user interface components.

## Structure

- `pages/` - Full page screens that users navigate to
- `widgets/` - Reusable UI components
- `tabs/` - Tab-specific content views and tools
EOF

cat > "$LIB_DIR/features/README.md" << 'EOF'
# Features

This directory contains feature-specific functionality.

## Structure

- `export/` - Export functionality for project data
EOF

echo "✅ README files created"

# Show final structure
echo ""
echo "📊 New lib directory structure:"
tree "$LIB_DIR" -I '*.g.dart' || find "$LIB_DIR" -type f -name "*.dart" | sort

echo ""
echo "🎉 Reorganization complete!"
echo ""
echo "⚠️  IMPORTANT: You need to update import statements in all files."
echo "   Run 'dart analyze' to see all the import errors that need fixing."
echo ""
echo "📦 Backup available at: $BACKUP_DIR"
echo "   You can restore the old structure with: cp -r $BACKUP_DIR/* $LIB_DIR/"
echo ""
echo "🔧 Next steps:"
echo "   1. Update import statements in all .dart files"
echo "   2. Run 'dart analyze' to check for errors"
echo "   3. Run 'flutter test' to ensure tests still pass"
echo "   4. Update any documentation that references old paths" 