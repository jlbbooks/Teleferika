# TeleferiKa Build Scripts

This directory contains scripts for managing the TeleferiKa project builds, flavors, and documentation generation.

## Overview

The project supports two flavors:
- **opensource**: Open source version without licensed features
- **full**: Full version with licensed features and export functionality

## Documentation System

TeleferiKa includes a comprehensive documentation system using **DartDoc**:

### 📖 API Documentation
- **Generated Documentation**: `doc/api/index.html`
- **Generate Docs**: `fvm dart doc`
- **Documentation Guide**: [DOCUMENTATION_GUIDE.md](../DOCUMENTATION_GUIDE.md)

### 🎨 UI Documentation
- **Widget Documentation**: All reusable UI widgets are fully documented
- **Usage Examples**: Complete code examples for each widget
- **Accessibility Info**: Screen reader support and keyboard navigation
- **Visual Design**: Styling guidelines and design principles

### 📋 Documentation Coverage
- ✅ **Core Classes**: Configuration, logging, state management
- ✅ **Database Models**: All data models with validation
- ✅ **UI Widgets**: Complete widget library with examples
- ✅ **Map Components**: Map-related functionality
- ✅ **Licensing System**: Feature control and license management
- ✅ **Localization**: Internationalization support

### 🔧 Documentation Standards
- **DartDoc Comments**: Triple-slash (`///`) documentation
- **Usage Examples**: Practical code examples
- **Parameter Documentation**: Detailed parameter descriptions
- **Return Values**: Clear return value documentation
- **Error Handling**: Exception and error documentation

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

### Documentation Scripts

#### Manual Documentation Generation
```bash
# Generate API documentation
fvm dart doc

# Open documentation in browser
open doc/api/index.html  # macOS
xdg-open doc/api/index.html  # Linux
start doc/api/index.html  # Windows
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
   fvm flutter run --flavor opensource
   ```

3. **Building:**
   ```bash
   ./scripts/build-app.sh build opensource --mode release --type apk
   ```

4. **Documentation:**
   ```bash
   fvm dart doc
   open doc/api/index.html
   ```

### For Full Version Development

1. **Initial Setup:**
   ```bash
   ./scripts/setup-flavor.sh full
   ```

2. **Development:**
   ```bash
   fvm flutter run --flavor full
   ```

3. **Building:**
   ```bash
   ./scripts/build-app.sh build full --mode release --type apk
   ```

4. **Documentation:**
   ```bash
   fvm dart doc
   open doc/api/index.html
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

## Documentation Configuration

### DartDoc Configuration
The project uses a comprehensive DartDoc setup with:
- **Output Directory**: `doc/api/`
- **Source Code Inclusion**: Shows actual Dart source code
- **External Links**: Links to Flutter API documentation
- **Categories**: Organized documentation structure
- **Validation**: Link validation and error checking

### Documentation Files
- `dartdoc_options.yaml`: Main DartDoc configuration
- `DOCUMENTATION_GUIDE.md`: Comprehensive documentation guidelines
- `doc/api/`: Generated documentation output
- `UI_DOCUMENTATION_SUMMARY.md`: UI widget documentation overview

## Troubleshooting

### Common Issues

1. **"modify-pubspec.sh not found"**
   - Make sure the script is executable: `chmod +x scripts/modify-pubspec.sh`

2. **"Wrong flavor setup"**
   - Run the setup script again: `./scripts/setup-flavor.sh [flavor]`

3. **Dependencies not updating**
   - Run `fvm flutter clean` and then `fvm flutter pub get`
   - Or use the clean option: `./scripts/setup-flavor.sh [flavor] true`

4. **Documentation generation issues**
   - Check DartDoc configuration: `dartdoc_options.yaml`
   - Regenerate docs: `fvm dart doc`
   - Verify file permissions and paths

### Testing

Run the test script to verify your setup:
```bash
./scripts/test-setup.sh
```

This will test both opensource and full setups and verify the configuration is correct.

## Development Guidelines

### Code Documentation
- Follow the [DOCUMENTATION_GUIDE.md](../DOCUMENTATION_GUIDE.md)
- Use DartDoc comments for all public APIs
- Include usage examples and parameter documentation
- Maintain consistent documentation style
- Update documentation when adding new features

### Build Process
- Always use FVM for Flutter commands: `fvm flutter`
- Test both flavors before committing changes
- Update documentation when adding new features
- Follow the established script patterns for consistency

### Quality Assurance
- Run tests on both flavors
- Verify documentation generation
- Check for linting issues: `fvm flutter analyze`
- Ensure all scripts are executable on Unix systems 