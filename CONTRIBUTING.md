# Contributing Guide

Thank you for your interest in contributing to Teleferika! This guide will help you get started with development and understand our contribution process.

## 🚀 Development Environment Setup

### Prerequisites

- **Flutter SDK** (3.0 or higher): [Install Flutter](https://docs.flutter.dev/get-started/install)
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
flutter run --flavor opensource --debug

# Switch to full version if needed
./scripts/setup-flavor.sh full
flutter run --flavor full --debug
```

#### For Team Members (with access to licensed features)

```bash
# Start development with full features
./scripts/setup-flavor.sh full
flutter run --flavor full --debug

# Build for testing
flutter build apk --flavor full --debug
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
# Run the app
flutter run --flavor opensource --debug
flutter run --flavor full --release

# Build APK
flutter build apk --flavor opensource --release
flutter build apk --flavor full --debug

# Build App Bundle
flutter build appbundle --flavor opensource --release
flutter build appbundle --flavor full --release

# Analyze code
flutter analyze

# Run tests
flutter test
```

## 📝 Code Style and Conventions

### Dart/Flutter Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter analyze` to check for issues
- Format code with `dart format` or your IDE's formatter

### File Naming

- Use `snake_case` for file names: `map_tool_view.dart`
- Use `PascalCase` for class names: `MapToolView`
- Use `camelCase` for variables and methods: `selectedPointId`

### Project Structure

```
lib/
├── core/           # Core utilities, configuration, logging
├── db/             # Database models and helpers
├── l10n/           # Localization files
├── licensing/      # License management
├── main.dart       # App entry point
└── ui/             # User interface components
    ├── pages/      # Full-screen pages
    ├── tabs/       # Tab views
    └── widgets/    # Reusable widgets
```

### Widget Organization

- Keep widgets small and focused
- Extract reusable components to `widgets/` directory
- Use meaningful names for widgets and methods
- Add comments for complex logic

### Database Models

- Use clear, descriptive field names
- Include proper validation
- Add `copyWith` methods for immutable updates
- Implement proper `toString`, `==`, and `hashCode` methods

## 🧪 Testing

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
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

### Pull Request Process

1. **Create a feature branch**
   
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   
   - Follow code style guidelines
   - Add tests for new functionality
   - Update documentation if needed

3. **Test your changes**
   
   ```bash
   flutter analyze
   flutter test
   ./scripts/test-setup.sh
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

## 🐛 Bug Reports

When reporting bugs, please include:

- **Flutter version**: `flutter --version`
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

## 📚 Documentation

### Code Documentation

- Document public APIs with dartdoc comments
- Explain complex algorithms
- Add examples for usage

### User Documentation

- Update README.md for user-facing changes
- Add screenshots for UI changes
- Document new features

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
   flutter clean
   flutter pub get
   flutter analyze
   ```

5. **Permission issues**
   
   ```bash
   # On macOS/Linux
   sudo chown -R $(whoami) .
   ```

### Getting Help

- Check the [Flutter documentation](https://docs.flutter.dev/)
- Search existing issues on GitHub
- Ask questions in discussions
- Contact the maintainers

## 📋 Checklist for Contributors

Before submitting your contribution, ensure:

- [ ] Code follows style guidelines
- [ ] Tests are written and passing
- [ ] Documentation is updated
- [ ] No breaking changes (unless intentional)
- [ ] All CI checks pass
- [ ] PR description is clear and complete

## 🎉 Recognition

Contributors will be recognized in:

- Project README.md
- Release notes
- Contributor hall of fame

Thank you for contributing to Teleferika! 🚀