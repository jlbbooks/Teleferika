#!/bin/bash

# Generate documentation for Teleferika project using FVM
# This script uses dartdoc (via FVM) to generate API documentation

set -e

echo "📚 Generating Teleferika Documentation (FVM)..."

# Check if FVM is installed
if ! command -v fvm &> /dev/null; then
    echo "❌ FVM is not installed. Please install FVM (https://fvm.app/) and try again."
    exit 1
fi

# Check if dartdoc is installed in the FVM environment
if ! fvm dart pub global list | grep -q dartdoc; then
    echo "❌ dartdoc is not installed in FVM environment. Installing..."
    fvm dart pub global activate dartdoc
fi

# Clean previous documentation
if [ -d "doc/api" ]; then
    echo "🧹 Cleaning previous documentation..."
    rm -rf doc/api
fi

# Generate documentation using FVM-managed Dart
export PATH="$PATH":"$HOME/.pub-cache/bin"
echo "🔨 Generating documentation with FVM..."
fvm dart pub global run dartdoc --output doc/api --include-source

# Check if generation was successful
if [ -d "doc/api" ]; then
    echo "✅ Documentation generated successfully!"
    echo "📁 Documentation is available at: doc/api/index.html"
    
    # Open documentation in browser (optional)
    if command -v xdg-open &> /dev/null; then
        echo "🌐 Opening documentation in browser..."
        xdg-open doc/api/index.html
    elif command -v open &> /dev/null; then
        echo "🌐 Opening documentation in browser..."
        open doc/api/index.html
    fi
else
    echo "❌ Documentation generation failed!"
    exit 1
fi

echo "🎉 Documentation generation complete!" 