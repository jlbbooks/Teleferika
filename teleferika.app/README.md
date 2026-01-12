# Teleferika

A Flutter mobile application for cable crane line planning and forest management.

## 📚 Documentation

Teleferika includes comprehensive documentation generated with **DartDoc**:

### 📖 API Documentation
- **Generated Documentation**: `doc/api/index.html`
- **Generate Docs**: `fvm dart doc`
- **Documentation Guide**: [DOCUMENTATION_GUIDE.md](./DOCUMENTATION_GUIDE.md)

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

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (3.0 or higher): [Install Flutter](https://docs.flutter.dev/get-started/install)
- **FVM** (Flutter Version Manager): [Install FVM](https://fvm.app/) - Recommended
- **Git**: [Install Git](https://git-scm.com/downloads)
- **IDE**: Android Studio or VS Code with Flutter extension

### First Time Setup

1. **Clone the repository**
   
   ```bash
   git clone https://github.com/your-org/teleferika.git
   cd teleferika
   ```

2. **Make scripts executable** (Unix/macOS/Linux only)
   
   ```bash
   chmod +x scripts/*.sh
   ```

3. **Set up the project for your needs**
   
   **For Open Source Contributors:**
   
   ```bash
   # Linux/macOS
   ./scripts/setup-flavor.sh opensource
   
   # Windows (PowerShell)
   .\scripts\setup-flavor.ps1 opensource
   ```
   
   **For Team Members (with licensed features access):**
   
   ```bash
   # Linux/macOS
   ./scripts/setup-flavor.sh full
   
   # Windows (PowerShell)
   .\scripts\setup-flavor.ps1 full
   ```

4. **Run the app**
   
   ```bash
   fvm flutter run --flavor opensource  # or 'full' for licensed version
   ```

## 📱 Project Flavors

Teleferika supports two flavors:

- **`opensource`**: Open source version without licensed features
- **`full`**: Full version with licensed features and export functionality

### Switching Between Flavors

```bash
# Linux/macOS
# Switch to opensource
./scripts/setup-flavor.sh opensource

# Switch to full version
./scripts/setup-flavor.sh full

# Clean setup (removes build artifacts)
./scripts/setup-flavor.sh full true

# Windows (PowerShell)
# Switch to opensource
.\scripts\setup-flavor.ps1 opensource

# Switch to full version
.\scripts\setup-flavor.ps1 full

# Clean setup (removes build artifacts)
.\scripts\setup-flavor.ps1 full true
```

## 🛠️ Development Workflow

### Using the Build Script

The `build-app.sh` / `build-app.ps1` script provides a convenient way to manage the project:

```bash
# Linux/macOS
# Setup a flavor
./scripts/build-app.sh setup opensource

# Build the app
./scripts/build-app.sh build opensource --mode release --type apk

# Run the app
./scripts/build-app.sh run full --mode debug

# Clean build artifacts
./scripts/build-app.sh clean

# Windows (PowerShell)
# Setup a flavor
.\scripts\build-app.ps1 setup opensource

# Build the app
.\scripts\build-app.ps1 build opensource --mode release --type apk

# Run the app
.\scripts\build-app.ps1 run full --mode debug

# Clean build artifacts
.\scripts\build-app.ps1 clean
```

### Manual Flutter Commands

```bash
# Run the app (using FVM)
fvm flutter run --flavor opensource --debug
fvm flutter run --flavor full --release

# Build APK
fvm flutter build apk --flavor opensource --release
fvm flutter build apk --flavor full --debug

# Build App Bundle
fvm flutter build appbundle --flavor opensource --release
fvm flutter build appbundle --flavor full --release
```

### Documentation Generation

```bash
# Generate API documentation
fvm dart doc

# Open documentation in browser
open doc/api/index.html  # macOS
xdg-open doc/api/index.html  # Linux
start doc/api/index.html  # Windows
```

## 🧪 Testing Your Setup

Run the test script to verify your development environment:

```bash
# Linux/macOS
./scripts/test-setup.sh

# Windows (PowerShell)
.\scripts\test-setup.ps1
```

This will test both opensource and full setups and verify the configuration is correct.

## 📁 Project Structure

```
teleferika/
├── lib/                          # Main application code
│   ├── core/                     # Core utilities and configuration
│   │   ├── app_config.dart       # App configuration and themes
│   │   ├── logger.dart           # Logging system
│   │   ├── project_provider.dart # Global state provider
│   │   └── utils/                # Utility functions
│   ├── db/                       # Database models and helpers
│   │   ├── database_helper.dart  # SQLite database operations
│   │   └── models/               # Data models
│   ├── l10n/                     # Localization files
│   ├── licensing/                # License management
│   ├── map/                      # Map-related functionality
│   └── ui/                       # User interface components
│       ├── screens/              # App screens
│       └── widgets/              # Reusable UI widgets
├── scripts/                      # Build and setup scripts
├── android/                      # Android-specific configuration
├── ios/                          # iOS-specific configuration
├── assets/                       # App assets (images, etc.)
├── doc/                          # Generated documentation
│   └── api/                      # DartDoc API documentation
├── dartdoc_options.yaml          # DartDoc configuration
└── DOCUMENTATION_GUIDE.md        # Documentation guidelines
```

## 🎯 Key Features

### Core Functionality
- **GPS-based point collection** for cable crane positioning
- **Compass integration** for directional measurements
- **Map visualization** with OpenStreetMap integration
- **Project management** for organizing multiple operations
- **Data export** capabilities (full version)
- **Offline operation** support

### UI Components
- **Status Indicators**: User feedback and notification widgets
- **Photo Management**: Camera integration and gallery management
- **Permission Handling**: Comprehensive permission management
- **Map Layers**: Customizable map visualization components
- **Form Elements**: Input fields and validation
- **Navigation**: App bars, tabs, and navigation components

### Technical Features
- **Global State Management**: Provider-based state management
- **Database Integration**: SQLite with automatic migrations
- **Localization**: Multi-language support (English, Italian)
- **Theme Support**: Light and dark theme configurations
- **Error Handling**: Comprehensive error management
- **Logging**: Structured logging throughout the application

## 🔧 Configuration

### DartDoc Configuration
The project uses a comprehensive DartDoc setup with:
- **Output Directory**: `doc/api/`
- **Source Code Inclusion**: Shows actual Dart source code
- **External Links**: Links to Flutter API documentation
- **Categories**: Organized documentation structure
- **Validation**: Link validation and error checking

### Android Keystore Setup (for Play Store)

1. Create a `keys` directory in the project root
2. Add your keystore file: `keys/keystore.jks`
3. Create `keys/keystore.properties`:

```properties
storePassword=your_keystore_password
keyAlias=your_key_alias
keyPassword=your_key_password
storeFile=../../keys/keystore.jks
```

## 🤝 Contributing

Please refer to our [Contribution Guidelines](./CONTRIBUTING.md) for detailed information on:

- Development environment setup
- Code style and conventions
- Documentation standards
- Testing procedures
- Pull request process

### Documentation Guidelines
- Follow the [DOCUMENTATION_GUIDE.md](./DOCUMENTATION_GUIDE.md)
- Use DartDoc comments for all public APIs
- Include usage examples and parameter documentation
- Maintain consistent documentation style
- Update documentation when adding new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Troubleshooting

### Common Issues

1. **"Script not found"**
   
   - Make scripts executable: `chmod +x scripts/*.sh`

2. **"Wrong flavor setup"**
   
   - Run setup again: `./scripts/setup-flavor.sh [flavor]`

3. **Dependencies not updating**
   
   - Clean and reinstall: `./scripts/setup-flavor.sh [flavor] true`

4. **Build failures**
   
   - Check Flutter version: `fvm flutter --version`
   - Clean build: `fvm flutter clean && fvm flutter pub get`

5. **Documentation generation issues**
   
   - Check DartDoc configuration: `dartdoc_options.yaml`
   - Regenerate docs: `fvm dart doc`
   - Verify file permissions and paths

### Getting Help

- Check the [Flutter documentation](https://docs.flutter.dev/)
- Review the [Contribution Guidelines](./CONTRIBUTING.md)
- Consult the [Documentation Guide](./DOCUMENTATION_GUIDE.md)
- Open an issue on GitHub for bugs or feature requests

## 📖 Description

Teleferika is a mobile application designed to support cable crane line planning for forest operations. The application helps technicians optimize cable crane positioning to minimize environmental impact and improve operational efficiency.

### Target Users

- **Forest Technicians**: Professionals managing cable crane operations
- **Surveyors**: Field workers collecting geographic data
- **Project Managers**: Coordinating multiple forest operations
- **Environmental Planners**: Assessing and minimizing environmental impact

### Use Cases

- **Cable Crane Planning**: Design optimal cable crane routes
- **Field Data Collection**: GPS-based point collection and measurements
- **Project Organization**: Manage multiple forest operations
- **Data Export**: Export project data for analysis and reporting
- **Offline Operation**: Work in remote areas without internet connectivity

## 🔄 Version History

See [CHANGELOG.md](./CHANGELOG.md) for a detailed history of changes and updates.
