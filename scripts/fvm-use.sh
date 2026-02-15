#!/usr/bin/env bash
# Sync FVM Flutter version across the repo root and all Flutter app directories.
# Usage: ./scripts/fvm-use.sh [version]
#   If version is omitted, reads from repo root .fvmrc (key "flutter").

set -e
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [ -n "$1" ]; then
  VERSION="$1"
else
  if [ ! -f .fvmrc ]; then
    echo "No .fvmrc at repo root and no version given. Usage: $0 <version>" >&2
    exit 1
  fi
  VERSION=$(grep -o '"flutter"[[:space:]]*:[[:space:]]*"[^"]*"' .fvmrc | sed 's/.*"\([^"]*\)".*/\1/')
  if [ -z "$VERSION" ]; then
    echo "Could not read flutter version from .fvmrc" >&2
    exit 1
  fi
  echo "Using version from .fvmrc: $VERSION"
fi

echo "Setting FVM to Flutter $VERSION in repo root and all app directories..."
fvm use "$VERSION"

for dir in teleferika.app licence_server; do
  if [ -d "$dir" ] && [ -f "$dir/pubspec.yaml" ]; then
    echo "--- $dir ---"
    (cd "$dir" && fvm use "$VERSION")
  fi
done

echo "Done. All FVM configs now use Flutter $VERSION."
