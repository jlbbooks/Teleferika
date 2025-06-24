#!/bin/bash

echo "🧪 Testing development environment setup..."

# Test open source setup
echo "Testing open source setup..."
./scripts/setup-flavor.sh opensource
if [ $? -eq 0 ]; then
    echo "✅ Open source setup: PASSED"
else
    echo "❌ Open source setup: FAILED"
    exit 1
fi

# Test full setup (if available)
echo "Testing full setup..."
./scripts/setup-flavor.sh full
if [ $? -eq 0 ]; then
    echo "✅ Full setup: PASSED"
else
    echo "⚠️ Full setup: FAILED (this is expected for open source contributors)"
fi

# Test Flutter compilation
echo "Testing Flutter compilation..."
flutter analyze --no-fatal-infos
if [ $? -eq 0 ]; then
    echo "✅ Flutter analysis: PASSED"
else
    echo "❌ Flutter analysis: FAILED"
    exit 1
fi

echo ""
echo "🎉 All tests passed! Your development environment is ready."