# Teleferika

A Flutter mobile application for cable crane line planning and forest management.

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (3.0 or higher): [Install Flutter](https://docs.flutter.dev/get-started/install)
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
   ./scripts/setup-flavor.sh opensource
   ```
   
   **For Team Members (with licensed features access):**
   
   ```bash
   ./scripts/setup-flavor.sh full
   ```

4. **Run the app**
   
   ```bash
   flutter run --flavor opensource  # or 'full' for licensed version
   ```

## 📱 Project Flavors

Teleferika supports two flavors:

- **`opensource`**: Open source version without licensed features
- **`full`**: Full version with licensed features and export functionality

### Switching Between Flavors

```bash
# Switch to opensource
./scripts/setup-flavor.sh opensource

# Switch to full version
./scripts/setup-flavor.sh full

# Clean setup (removes build artifacts)
./scripts/setup-flavor.sh full true
```

## 🛠️ Development Workflow

### Using the Build Script

The `build-app.sh` script provides a convenient way to manage the project:

```bash
# Setup a flavor
./scripts/build-app.sh setup opensource

# Build the app
./scripts/build-app.sh build opensource --mode release --type apk

# Run the app
./scripts/build-app.sh run full --mode debug

# Clean build artifacts
./scripts/build-app.sh clean
```

### Manual Flutter Commands

```bash
# Run the app
flutter run --flavor opensource --debug
flutter run --flavor full --release

# Build APK
flutter build apk --flavor opensource --release
flutter build apk --flavor full --debug

# Build App Bundle
flutter build appbundle --flavor opensource --release
flutter build appbundle --flavor full --release
```

## 🧪 Testing Your Setup

Run the test script to verify your development environment:

```bash
./scripts/test-setup.sh
```

This will test both opensource and full setups and verify the configuration is correct.

## 📁 Project Structure

```
teleferika/
├── lib/                          # Main application code
│   ├── core/                     # Core utilities and configuration
│   ├── db/                       # Database models and helpers
│   ├── l10n/                     # Localization files
│   ├── licensing/                # License management
│   └── ui/                       # User interface components
├── scripts/                      # Build and setup scripts
├── licensed_features_package/    # Licensed features (full version only)
├── android/                      # Android-specific configuration
├── ios/                          # iOS-specific configuration
└── assets/                       # App assets (images, etc.)
```

## 🔧 Configuration

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
- Testing procedures
- Pull request process

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
   
   - Check Flutter version: `flutter --version`
   - Clean build: `flutter clean && flutter pub get`

### Getting Help

- Check the [Flutter documentation](https://docs.flutter.dev/)
- Review the [Contribution Guidelines](./CONTRIBUTING.md)
- Open an issue on GitHub for bugs or feature requests

## 📖 Description

Teleferika is a mobile application designed to support cable crane line planning for forest operations. The application helps technicians optimize cable crane positioning to minimize environmental impact and improve operational efficiency.

### Key Features

- **GPS-based point collection** for cable crane positioning
- **Compass integration** for directional measurements
- **Map visualization** with OpenStreetMap integration
- **Project management** for organizing multiple operations
- **Data export** capabilities (full version)
- **Offline operation** support

### Target Users

- Forest technicians and operators
- Cable crane operators
- Environmental consultants
- Forest management professionals

---

**Note**: The full version with licensed features requires access to the private licensed features repository. Open source contributors can use the opensource flavor which provides core functionality without export features.
