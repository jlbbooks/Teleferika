# Teleferika Project Structure

This repository contains the Teleferika project with a modular structure consisting of the main Flutter application and two Git submodules.

## 📁 Directory Structure

```
Teleferika.fresh/
├── teleferika.app/              # Main Flutter application
│   ├── lib/                     # Dart source code
│   │   ├── core/                # Core functionality (config, logging, etc.)
│   │   ├── db/                  # Database models and helpers
│   │   ├── licensing/           # License management
│   │   ├── map/                 # Map-related functionality
│   │   ├── ui/                  # User interface components
│   │   └── l10n/                # Localization files
│   ├── android/                 # Android-specific configuration
│   ├── ios/                     # iOS-specific configuration
│   ├── assets/                  # App assets (images, animations)
│   ├── scripts/                 # Build and setup scripts
│   ├── pubspec.yaml             # Flutter dependencies
│   └── README.md                # Main app documentation
│
├── licensed_features_package/    # Git submodule - Licensed features
│   ├── lib/                     # Licensed feature implementations
│   │   ├── export/              # Export functionality (KML, CSV, GeoJSON, etc.)
│   │   ├── map_download/        # Map download features
│   │   └── widgets/             # Licensed UI widgets
│   ├── pubspec.yaml             # Package dependencies
│   └── README.md                # Package documentation
│
├── licence_server/              # Git submodule - License server
│   ├── bin/                     # Server executables
│   ├── lib/                     # Server implementation
│   ├── web/                     # Web UI assets
│   ├── pubspec.yaml             # Server dependencies
│   └── README.md                # Server documentation
│
├── .gitmodules                  # Git submodule configuration
└── README.md                    # This file
```

## 🎯 Project Components

### 1. teleferika.app/ (Main Application)

The main Flutter mobile application for cable crane line planning and forest management.

**Key Features:**
- Flutter-based cross-platform mobile app
- Project and point management
- Map visualization and interaction
- License-based feature control
- Localization support (multiple languages)

**Setup:**
- Navigate to `teleferika.app/` directory
- Run `./scripts/setup-flavor.sh [opensource|full]` to configure the project
- See `teleferika.app/README.md` for detailed documentation

### 2. licensed_features_package/ (Git Submodule)

Premium features package that extends the main application with advanced functionality.

**Features:**
- Advanced export formats (KML, CSV, GeoJSON, KMZ, Shapefile)
- Offline map tile caching
- Map area selection and download
- Batch operations
- Additional UI components

**Dependencies:**
- Depends on `teleferika.app` (path: `../teleferika.app`)
- Only available in the "full" flavor of the application

**Setup:**
- Automatically cloned when running `./scripts/setup-flavor.sh full`
- See `licensed_features_package/README.md` for package details

### 3. licence_server/ (Git Submodule)

Server application for managing licenses and validating licensed features.

**Features:**
- License generation and validation
- Web-based admin interface
- RESTful API for license management
- Secure license verification

**Setup:**
- Automatically cloned when running `./scripts/setup-flavor.sh full`
- See `licence_server/README.md` for server documentation

## 🚀 Quick Start

### Initial Setup

1. **Clone the repository with submodules:**
   ```bash
   git clone --recurse-submodules <repository-url>
   ```

   Or if already cloned:
   ```bash
   git submodule update --init --recursive
   ```

2. **Navigate to the main app:**
   ```bash
   cd teleferika.app
   ```

3. **Choose your flavor:**
   ```bash
   # For open source version
   ./scripts/setup-opensource.sh
   
   # For full version with licensed features
   ./scripts/setup-full.sh
   ```

4. **Get dependencies:**
   ```bash
   flutter pub get
   ```

5. **Run the app:**
   ```bash
   flutter run
   ```

## 📦 Flavor Configuration

The project supports two flavors:

### OpenSource Flavor
- Basic functionality only
- No licensed features
- No submodule dependencies required
- Suitable for open-source distribution

### Full Flavor
- All features including licensed ones
- Requires `licensed_features_package` submodule
- Requires `licence_server` submodule (for license management)
- Requires valid license for premium features

## 🔧 Development

### Working with Submodules

**Update submodules to latest:**
```bash
git submodule update --remote
```

**Update specific submodule:**
```bash
git submodule update --remote licensed_features_package
git submodule update --remote licence_server
```

**Switch submodule to specific branch/tag:**
```bash
cd licensed_features_package
git checkout <branch-or-tag>
cd ..
```

### Project Structure Notes

- **Main app location:** All main application code is in `teleferika.app/`
- **Submodule locations:** Submodules are at the root level, alongside `teleferika.app/`
- **Path dependencies:** 
  - `teleferika.app/pubspec.yaml` references `../licensed_features_package`
  - `licensed_features_package/pubspec.yaml` references `../teleferika.app`

## 📚 Documentation

- **Main App:** See `teleferika.app/README.md`
- **Licensed Features:** See `licensed_features_package/README.md`
- **License Server:** See `licence_server/README.md`
- **Contributing:** See `teleferika.app/CONTRIBUTING.md`
- **Documentation Guide:** See `teleferika.app/DOCUMENTATION_GUIDE.md`

## 🔐 License Management

For the full version:
- License server must be running for license validation
- See `licence_server/README.md` for server setup
- See `licence_server/ADMIN_CLIENT_README.md` for admin interface

## 🛠️ Scripts

All setup and build scripts are located in `teleferika.app/scripts/`:

- `setup-flavor.sh` / `setup-flavor.ps1` - Main setup script
- `setup-opensource.sh` / `setup-opensource.ps1` - Quick setup for opensource
- `setup-full.sh` / `setup-full.ps1` - Quick setup for full version
- `build-app.sh` / `build-app.ps1` - Build the application
- `generate-docs.sh` / `generate-docs.ps1` - Generate documentation

## 📝 Notes

- The project structure was reorganized to separate the main app from submodules
- All paths have been updated to reflect the new structure
- Submodules remain at the root level for easy access and management
- The main application is self-contained in `teleferika.app/`

## 🤝 Contributing

Please see `teleferika.app/CONTRIBUTING.md` for contribution guidelines.

## 📄 License

See individual component README files for license information.
