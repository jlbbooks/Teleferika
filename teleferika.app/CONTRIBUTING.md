# Contributing Guide

Thank you for your interest in contributing to Teleferika! This guide will help you get started with development and understand our contribution process.

## 🚀 Development Environment Setup

### Prerequisites

- **Flutter SDK** (3.0 or higher): [Install Flutter](https://docs.flutter.dev/get-started/install)
- **FVM** (Flutter Version Manager): [Install FVM](https://fvm.app/) - Recommended
- **Git**: [Install Git](https://git-scm.com/downloads)
- **IDE**: 
  - Android Studio (recommended for Android development)
  - VS Code with Flutter extension

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

4. **Verify your setup**
   
   ```bash
   ./scripts/test-setup.sh
   ```

### Daily Development Workflow

#### For Open Source Contributors

```bash
# Start development
./scripts/setup-flavor.sh opensource
fvm flutter run --flavor opensource --debug

# Switch to full version if needed
./scripts/setup-flavor.sh full
fvm flutter run --flavor full --debug
```

#### For Team Members (with access to licensed features)

```bash
# Start development with full features
./scripts/setup-flavor.sh full
fvm flutter run --flavor full --debug

# Build for testing
fvm flutter build apk --flavor full --debug
```

## 📚 Documentation System

Teleferika includes a comprehensive documentation system using **DartDoc**:

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

### Documentation Generation

```bash
# Generate API documentation
fvm dart doc

# Open documentation in browser
open doc/api/index.html  # macOS
xdg-open doc/api/index.html  # Linux
start doc/api/index.html  # Windows
```

## 🛠️ Development Tools

### Using the Build Script

The `build-app.sh` script provides convenient project management:

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
# Run the app (using FVM)
fvm flutter run --flavor opensource --debug
fvm flutter run --flavor full --release

# Build APK
fvm flutter build apk --flavor opensource --release
fvm flutter build apk --flavor full --debug

# Build App Bundle
fvm flutter build appbundle --flavor opensource --release
fvm flutter build appbundle --flavor full --release

# Analyze code
fvm flutter analyze

# Run tests
fvm flutter test
```

## 📝 Code Style and Conventions

### Dart/Flutter Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `fvm flutter analyze` to check for issues
- Format code with `dart format` or your IDE's formatter

### Documentation Standards

#### Required Documentation
- **All Public APIs**: Use DartDoc comments (`///`) for all public classes, methods, and properties
- **Usage Examples**: Include practical code examples in documentation
- **Parameter Documentation**: Document all parameters with types and descriptions
- **Return Values**: Explain what methods return and when
- **Error Handling**: Document exceptions and error conditions

#### Documentation Examples

```dart
/// A widget that displays status messages with smooth animations.
///
/// This widget provides a non-intrusive way to show user feedback
/// messages. It supports different status types (success, error, info, loading)
/// with appropriate visual styling and smooth slide/fade animations.
///
/// ## Features
/// - **Smooth Animations**: Slide-in from right with fade effect
/// - **Auto-hide**: Configurable duration for automatic dismissal
/// - **Manual Dismiss**: Close button for user control
/// - **Tooltips**: Full message visible on hover for truncated text
///
/// ## Usage Examples
///
/// ### Basic Success Message:
/// ```dart
/// StatusIndicator(
///   status: StatusManager.success('Operation completed!'),
///   onDismiss: () => print('Dismissed'),
/// )
/// ```
///
/// ### Custom Styled Error Message:
/// ```dart
/// StatusIndicator(
///   status: StatusManager.error('Something went wrong'),
///   margin: EdgeInsets.all(16),
///   maxWidth: 400,
///   autoHide: false,
/// )
/// ```
class StatusIndicator extends StatefulWidget {
  /// The status configuration to display.
  ///
  /// When null, the widget will be hidden. When a new status is provided,
  /// the widget will animate in and display the message.
  final StatusInfo? status;

  /// Callback function called when the user manually dismisses the status.
  ///
  /// This is typically used to update the parent widget's state or
  /// perform cleanup actions.
  final VoidCallback? onDismiss;

  /// Creates a status indicator widget.
  ///
  /// The [status] parameter determines what message to display and how to style it.
  /// The [onDismiss] callback is optional and called when the user manually
  /// dismisses the status.
  const StatusIndicator({
    super.key,
    this.status,
    this.onDismiss,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}
```

### File Naming

- Use `snake_case` for file names: `map_tool_view.dart`
- Use `PascalCase` for class names: `MapToolView`
- Use `camelCase` for variables and methods: `selectedPointId`

### Project Structure

```
lib/
├── core/           # Core utilities, configuration, logging
│   ├── app_config.dart       # App configuration and themes
│   ├── logger.dart           # Logging system
│   ├── project_provider.dart # Global state provider
│   └── utils/                # Utility functions
├── db/             # Database models and helpers
│   ├── database_helper.dart  # SQLite database operations
│   └── models/               # Data models
├── l10n/           # Localization files
├── licensing/      # License management
├── map/            # Map-related functionality
├── main.dart       # App entry point
└── ui/             # User interface components
    ├── screens/    # Full-screen pages
    ├── widgets/    # Reusable widgets
    └── components/ # Screen-specific components organized by feature
```

### Widget Organization

- Keep widgets small and focused
- Extract reusable components to `widgets/` directory
- Use meaningful names for widgets and methods
- Add comments for complex logic
- Document all public widgets with DartDoc comments

### Database Models

- Use clear, descriptive field names
- Include proper validation
- Add `copyWith` methods for immutable updates
- Implement proper `toString`, `==`, and `hashCode` methods
- Document all models with comprehensive DartDoc comments

## 🧪 Testing

### Running Tests

```bash
# Run all tests
fvm flutter test

# Run specific test file
fvm flutter test test/widget_test.dart

# Run with coverage
fvm flutter test --coverage
```

### Writing Tests

- Test critical business logic
- Test widget interactions
- Test database operations
- Use meaningful test names
- Follow AAA pattern (Arrange, Act, Assert)

### Example Test Structure

```dart
group('PointModel', () {
  test('should create point with correct properties', () {
    // Arrange
    const projectId = 'test-project';
    const latitude = 45.123;
    const longitude = 12.456;

    // Act
    final point = PointModel(
      projectId: projectId,
      latitude: latitude,
      longitude: longitude,
      ordinalNumber: 1,
    );

    // Assert
    expect(point.projectId, equals(projectId));
    expect(point.latitude, equals(latitude));
    expect(point.longitude, equals(longitude));
    expect(point.name, equals('P1'));
  });
});
```

## 🔄 Git Workflow

### Branch Naming

- `feature/description`: New features
- `fix/description`: Bug fixes
- `refactor/description`: Code refactoring
- `docs/description`: Documentation updates

### Commit Messages

Use conventional commit format:

```
type(scope): description

[optional body]

[optional footer]
```

Examples:

- `feat(map): add point move functionality`
- `fix(db): resolve point deletion issue`
- `docs(readme): update setup instructions`
- `docs(widgets): add comprehensive DartDoc comments`

### Pull Request Process

1. **Create a feature branch**
   
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   
   - Follow code style guidelines
   - Add tests for new functionality
   - Update documentation if needed
   - Add DartDoc comments for new public APIs

3. **Test your changes**
   
   ```bash
   fvm flutter analyze
   fvm flutter test
   ./scripts/test-setup.sh
   fvm dart doc  # Generate documentation
   ```

4. **Commit your changes**
   
   ```bash
   git add .
   git commit -m "feat(scope): description"
   ```

5. **Push and create PR**
   
   ```bash
   git push origin feature/your-feature-name
   ```

6. **PR Review**
   
   - Ensure all tests pass
   - Address review comments
   - Update PR description with changes
   - Verify documentation is complete

## 🐛 Bug Reports

When reporting bugs, please include:

- **Flutter version**: `fvm flutter --version`
- **Device/OS**: Android/iOS version
- **Steps to reproduce**: Clear, step-by-step instructions
- **Expected behavior**: What should happen
- **Actual behavior**: What actually happens
- **Screenshots**: If applicable
- **Logs**: Relevant error messages

## 💡 Feature Requests

When requesting features, please include:

- **Use case**: Why this feature is needed
- **Proposed solution**: How you think it should work
- **Alternatives considered**: Other approaches you've thought about
- **Mockups**: If applicable

## 📚 Documentation Guidelines

### Code Documentation

- Document public APIs with dartdoc comments
- Explain complex algorithms
- Add examples for usage
- Include parameter and return value documentation
- Document error conditions and exceptions

### User Documentation

- Update README.md for user-facing changes
- Add screenshots for UI changes
- Document new features
- Update [DOCUMENTATION_GUIDE.md](./DOCUMENTATION_GUIDE.md) if needed

### Documentation Maintenance

- Keep documentation up to date with code changes
- Review and update documentation regularly
- Ensure all examples are current and working
- Test documentation generation: `fvm dart doc`

## 🔧 Troubleshooting

### Common Issues

1. **"Script not found"**
   
   ```bash
   chmod +x scripts/*.sh
   ```

2. **"Wrong flavor setup"**
   
   ```bash
   ./scripts/setup-flavor.sh [flavor]
   ```

3. **Dependencies not updating**
   
   ```bash
   ./scripts/setup-flavor.sh [flavor] true
   ```

4. **Build failures**
   
   ```bash
   fvm flutter clean
   fvm flutter pub get
   fvm flutter analyze
   ```

5. **Documentation generation issues**
   
   ```bash
   # Check DartDoc configuration
   cat dartdoc_options.yaml
   
   # Regenerate docs
   fvm dart doc
   
   # Verify file permissions and paths
   ls -la doc/api/
   ```

6. **Permission issues**
   
   ```bash
   # On macOS/Linux
   sudo chown -R $(whoami) .
   ```

### Getting Help

- Check the [Flutter documentation](https://docs.flutter.dev/)
- Review the [Documentation Guide](./DOCUMENTATION_GUIDE.md)
- Search existing issues on GitHub
- Ask questions in discussions
- Contact the maintainers

## 📋 Checklist for Contributors

Before submitting your contribution, ensure:

- [ ] Code follows style guidelines
- [ ] Tests are written and passing
- [ ] Documentation is updated with DartDoc comments
- [ ] No breaking changes (unless intentional)
- [ ] All CI checks pass
- [ ] PR description is clear and complete
- [ ] Documentation generation works: `fvm dart doc`
- [ ] UI widgets are properly documented
- [ ] Examples in documentation are current and working

## 🎯 Development Standards

### Code Quality

- **Linting**: All code must pass `fvm flutter analyze`
- **Formatting**: Use `dart format` for consistent formatting
- **Testing**: Write tests for new functionality
- **Documentation**: Document all public APIs with DartDoc

### UI Development

- **Widget Documentation**: All UI widgets must be fully documented
- **Accessibility**: Ensure proper accessibility support
- **Responsive Design**: Test on different screen sizes
- **Theme Integration**: Use app themes consistently

### State Management

- **Provider Pattern**: Use Provider for global state management
- **Immutable Updates**: Use `copyWith` for state updates
- **Error Handling**: Proper error handling and user feedback
- **Performance**: Optimize for large datasets

### Database Operations

- **Validation**: Validate data before database operations
- **Error Handling**: Graceful handling of database errors
- **Migrations**: Proper database migration handling
- **Performance**: Optimize database queries

## 🎉 Recognition

Contributors will be recognized in:

- Project README.md
- Release notes
- Contributor hall of fame

Thank you for contributing to Teleferika! 🚀

## Conditional Localization for Licensed Features

This project uses a conditional export mechanism to include or exclude premium localizations (LfpLocalizations) based on the selected flavor (opensource or full):

- `licensed_features_package/lib/l10n/lfp_localizations_conditional.dart` is not edited directly. It is managed by the setup-flavor scripts and points to either the real or stub implementation.
- For the **full** flavor, it exports the real `lfp_localizations.dart`.
- For the **opensource** flavor, it exports the stub `lfp_localizations_stub.dart` (which provides no-op implementations).
- The correct file is copied by `scripts/setup-flavor.sh` or `scripts/setup-flavor.ps1` depending on the selected flavor.
- In your app, always import LfpLocalizations from `lfp_localizations_conditional.dart`.

This ensures that localization delegates and supportedLocales can be referenced safely in both flavors without build errors.

## Submodules

This project uses Git submodules for external dependencies:

### `licensed_features_package`
- **Purpose**: Contains licensed features and export functionality
- **Availability**: Only available in the **full** flavor
- **Management**: Automatically cloned/updated by setup scripts for full flavor
- **Opensource**: Not present in opensource flavor (removed during setup)

### `licence_server`
- **Purpose**: License validation and management server
- **Availability**: Only available in the **full** flavor
- **Management**: Automatically cloned/updated by setup scripts for full flavor
- **Opensource**: Not present in opensource flavor (removed during setup)