# TeleferiKa Build Scripts

This directory contains scripts for managing the TeleferiKa project builds and flavors.

## Overview

The project supports two flavors:
- **opensource**: Open source version without licensed features
- **full**: Full version with licensed features and export functionality

## New Single pubspec.yaml Approach

Instead of maintaining separate `pubspec.full.yaml` and `pubspec.opensource.yaml` files, we now use a single `pubspec.yaml` file with conditional dependency management.

### How it works:

1. **Single pubspec.yaml**: Contains all common dependencies with a placeholder for the licensed package
2. **modify-pubspec scripts**: Dynamically add/remove the `licensed_features_package` dependency
3. **Setup scripts**: Use the modify-pubspec scripts to configure the correct flavor

### Benefits:

- ✅ Only one pubspec.yaml to maintain
- ✅ No duplicate dependency lists
- ✅ Easier to keep dependencies in sync
- ✅ Reduced chance of configuration drift

## Scripts

### Core Setup Scripts

#### `setup-flavor.sh` / `setup-flavor.bat`
Main setup script for configuring the project flavor.

**Usage:**
```bash
# Linux/macOS
./scripts/setup-flavor.sh opensource
./scripts/setup-flavor.sh full
./scripts/setup-flavor.sh full true  # Clean before setup

# Windows
scripts\setup-flavor.bat opensource
scripts\setup-flavor.bat full
scripts\setup-flavor.bat full true  # Clean before setup
```

#### `modify-pubspec.sh` / `modify-pubspec.bat`
Scripts for managing the licensed package dependency in pubspec.yaml.

**Usage:**
```bash
# Linux/macOS
./scripts/modify-pubspec.sh add-licensed
./scripts/modify-pubspec.sh remove-licensed
./scripts/modify-pubspec.sh status

# Windows
scripts\modify-pubspec.bat add-licensed
scripts\modify-pubspec.bat remove-licensed
scripts\modify-pubspec.bat status
```

### Build Scripts

#### `build-app.sh`
Comprehensive build script with flavor support.

**Usage:**
```bash
./scripts/build-app.sh setup opensource
./scripts/build-app.sh build opensource --mode release --type apk
./scripts/build-app.sh run full --mode debug
./scripts/build-app.sh clean
```

### Convenience Scripts

- `setup-opensource.sh` / `setup-opensource.bat`: Quick setup for opensource
- `setup-full.sh` / `setup-full.bat`: Quick setup for full version
- `test-setup.sh`: Test the setup process

## Workflow

### For Open Source Contributors

1. **Initial Setup:**
   ```bash
   ./scripts/setup-flavor.sh opensource
   ```

2. **Development:**
   ```bash
   flutter run --flavor opensource
   ```

3. **Building:**
   ```bash
   ./scripts/build-app.sh build opensource --mode release --type apk
   ```

### For Full Version Development

1. **Initial Setup:**
   ```bash
   ./scripts/setup-flavor.sh full
   ```

2. **Development:**
   ```bash
   flutter run --flavor full
   ```

3. **Building:**
   ```bash
   ./scripts/build-app.sh build full --mode release --type apk
   ```

## File Structure

```
scripts/
├── setup-flavor.sh          # Main setup script (Linux/macOS)
├── setup-flavor.bat         # Main setup script (Windows)
├── modify-pubspec.sh        # Dependency management (Linux/macOS)
├── modify-pubspec.bat       # Dependency management (Windows)
├── build-app.sh             # Build script
├── test-setup.sh            # Setup testing
├── setup-opensource.sh      # Quick opensource setup
├── setup-opensource.bat     # Quick opensource setup (Windows)
├── setup-full.sh            # Quick full setup
├── setup-full.bat           # Quick full setup (Windows)
└── README.md                # This file
```

## Migration from Old Approach

If you were using the old approach with separate pubspec files:

1. **Remove old files:**
   ```bash
   rm build_configs/pubspec.full.yaml
   rm build_configs/pubspec.opensource.yaml
   ```

2. **Use new single pubspec.yaml:**
   - The main `pubspec.yaml` now contains all dependencies
   - The `LICENSED_PACKAGE_PLACEHOLDER` comment marks where the licensed package will be added

3. **Update your workflow:**
   - Use `./scripts/setup-flavor.sh` instead of copying pubspec files
   - The scripts will automatically manage dependencies

## Troubleshooting

### Common Issues

1. **"modify-pubspec.sh not found"**
   - Make sure the script is executable: `chmod +x scripts/modify-pubspec.sh`

2. **"Wrong flavor setup"**
   - Run the setup script again: `./scripts/setup-flavor.sh [flavor]`

3. **Dependencies not updating**
   - Run `flutter clean` and then `flutter pub get`
   - Or use the clean option: `./scripts/setup-flavor.sh [flavor] true`

### Testing

Run the test script to verify your setup:
```bash
./scripts/test-setup.sh
```

This will test both opensource and full setups and verify the configuration is correct. 