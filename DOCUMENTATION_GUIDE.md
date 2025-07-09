# Teleferika Documentation Guide

This guide explains how to document the Teleferika Flutter application code and generate comprehensive documentation.

## Overview

Teleferika uses **DartDoc** as its primary documentation system. DartDoc extracts documentation from code comments and generates HTML documentation that can be viewed in a web browser.

## Documentation Standards

### 1. DartDoc Comments

Use triple-slash (`///`) comments for all public APIs:

```dart
/// Brief description of the class/function.
/// 
/// More detailed description that can span multiple lines.
/// 
/// ## Features
/// - Feature 1
/// - Feature 2
/// 
/// ## Usage
/// ```dart
/// final example = MyClass();
/// example.doSomething();
/// ```
/// 
/// ## Parameters
/// - [param1]: Description of parameter 1
/// - [param2]: Description of parameter 2
/// 
/// ## Returns
/// Description of what the function returns
/// 
/// ## Throws
/// - [ArgumentError]: When invalid parameters are provided
/// - [StateError]: When the object is in an invalid state
class MyClass {
  /// Creates a new instance of [MyClass].
  /// 
  /// The [name] parameter is required and cannot be empty.
  MyClass(this.name);

  /// The name of this instance.
  final String name;

  /// Performs some operation.
  /// 
  /// This method does something useful with the provided [data].
  /// Returns `true` if successful, `false` otherwise.
  bool doSomething(String data) {
    // Implementation
  }
}
```

### 2. Documentation Categories

Organize documentation into logical categories:

- **Core**: Configuration, logging, utilities
- **Database**: Models, helpers, migrations
- **UI**: Widgets, screens, components
- **Map**: Map-related functionality
- **Licensing**: License management
- **Localization**: Internationalization

### 3. Required Documentation

#### Classes
- Purpose and responsibility
- Key features and capabilities
- Usage examples
- Dependencies and relationships

#### Methods/Functions
- Purpose and behavior
- Parameters and their types
- Return values
- Exceptions that may be thrown
- Usage examples

#### Properties/Fields
- Purpose and meaning
- Valid values and constraints
- When it changes
- Relationships to other properties

#### Constants
- Purpose and usage
- Valid values
- When to use vs alternatives

## Documentation Structure

### 1. File Header Documentation

Every Dart file should have a comprehensive header comment:

```dart
/// Geographic point model for cable crane line planning.
/// 
/// This class represents a geographic point within a project, containing
/// coordinates, metadata, and associated images. Points are used to define
/// the path of cable crane lines and store field measurements.
/// 
/// ## Features
/// - **Geographic Coordinates**: Latitude, longitude, and optional altitude
/// - **GPS Precision**: Optional GPS accuracy information
/// - **Ordering**: Ordinal numbers for sequence within projects
/// - **Metadata**: Notes, timestamps, and project association
/// - **Image Support**: Multiple images per point with ordering
/// - **Validation**: Built-in coordinate and data validation
/// 
/// ## Database Integration
/// The class includes database table and column name constants for
/// SQLite integration. It supports both serialization to/from maps
/// and direct database operations.
/// 
/// ## Usage Examples
/// 
/// ### Creating a new point:
/// ```dart
/// final point = PointModel(
///   projectId: 'project-123',
///   latitude: 45.12345,
///   longitude: 11.12345,
///   altitude: 1200.5,
///   ordinalNumber: 1,
///   note: 'Starting point of cable line',
/// );
/// ```
/// 
/// ### Calculating distance between points:
/// ```dart
/// double distance = point1.distanceFromPoint(point2);
/// ```
/// 
/// ## Coordinate System
/// - **Latitude**: -90 to 90 degrees (WGS84)
/// - **Longitude**: -180 to 180 degrees (WGS84)
/// - **Altitude**: Optional, in meters above sea level
/// - **GPS Precision**: Optional, in meters
/// 
/// ## Validation
/// The class includes comprehensive validation for:
/// - Coordinate ranges
/// - Required field presence
/// - Altitude bounds (-1000 to 8849 meters)
/// - GPS precision (non-negative)
/// 
/// ## Immutability
/// The class is designed to be immutable. Use [copyWith] to create
/// modified versions of points.
```

### 2. Class Documentation

Document classes with their purpose, features, and usage:

```dart
/// Application configuration and constants for Teleferika.
/// 
/// This class contains all application-wide configuration settings,
/// theme definitions, and constants used throughout the app. It provides
/// a centralized location for managing app appearance, behavior, and
/// configuration values.
/// 
/// ## Features
/// - **Theme Configuration**: Light and dark theme definitions
/// - **Localization**: Supported locales and delegates
/// - **Map Configuration**: Default map center and zoom levels
/// - **UI Constants**: Colors, icons, and styling constants
/// - **Behavior Settings**: Configurable app behavior flags
/// 
/// ## Usage
/// All configuration values are accessed as static constants:
/// ```dart
/// // Get app name
/// String name = AppConfig.appName;
/// 
/// // Get theme
/// ThemeData theme = AppConfig.lightTheme;
/// 
/// // Get default map center
/// LatLng center = AppConfig.defaultMapCenter;
/// ```
/// 
/// ## Customization
/// To modify app behavior, update the appropriate constants in this class.
/// For theme customization, modify the [lightTheme] and [darkTheme] properties.
class AppConfig {
  // Implementation
}
```

### 3. Method Documentation

Document methods with parameters, return values, and examples:

```dart
/// Calculates the 3D distance to another point using the Haversine formula.
/// 
/// This method calculates the great-circle distance between two points
/// on Earth's surface, optionally including altitude differences for
/// 3D distance calculation.
/// 
/// ## Algorithm
/// Uses the Haversine formula for horizontal distance calculation:
/// - Converts coordinates to radians
/// - Applies Haversine formula for great-circle distance
/// - Uses Pythagorean theorem for 3D distance with altitude
/// 
/// ## Parameters
/// - [other]: The target point to calculate distance to
/// - [altitude]: Optional altitude override for this point (defaults to [this.altitude])
/// - [otherAltitude]: Optional altitude override for target point (defaults to [other.altitude])
/// 
/// ## Returns
/// The distance in meters between the two points.
/// 
/// ## Examples
/// ```dart
/// final point1 = PointModel(/* ... */);
/// final point2 = PointModel(/* ... */);
/// 
/// // Calculate 2D distance (ignoring altitude)
/// double distance2D = point1.distanceFromPoint(point2);
/// 
/// // Calculate 3D distance with custom altitudes
/// double distance3D = point1.distanceFromPoint(
///   point2,
///   altitude: 1000.0,
///   otherAltitude: 1200.0,
/// );
/// ```
/// 
/// ## Mathematical Details
/// The calculation uses:
/// - Earth's radius: 6,371,000 meters
/// - Haversine formula for horizontal distance
/// - Pythagorean theorem for 3D distance
double distanceFromPoint(
  PointModel other, {
  double? altitude,
  double? otherAltitude,
}) {
  // Implementation
}
```

### 4. Property Documentation

Document properties with their purpose and constraints:

```dart
/// Latitude coordinate in decimal degrees (WGS84).
/// 
/// Must be between -90 and 90 degrees.
/// Positive values indicate North, negative values indicate South.
/// 
/// ## Validation
/// Use [isValid] to check if the coordinate is within valid bounds.
/// 
/// ## Coordinate System
/// Uses the WGS84 datum, which is the standard for GPS coordinates.
final double latitude;

/// Optional altitude in meters above sea level.
/// 
/// Can be null if altitude data is not available.
/// When provided, should be between -1000 and 8849 meters.
/// 
/// ## Usage
/// Altitude is used for:
/// - 3D distance calculations
/// - Elevation profiles
/// - Terrain analysis
/// 
/// ## Data Sources
/// Typically obtained from:
/// - GPS altitude data
/// - Barometric sensors
/// - Manual input
/// - Digital elevation models
final double? altitude;
```

## Generating Documentation

### 1. Using the Script

Run the documentation generation script:

```bash
./scripts/generate-docs.sh
```

This script will:
- Check if dartdoc is installed
- Clean previous documentation
- Generate new documentation
- Open the documentation in your browser

### 2. Manual Generation

Generate documentation manually:

```bash
# Install dartdoc (if not already installed)
dart pub global activate dartdoc

# Generate documentation
dartdoc --config dartdoc_options.yaml

# View documentation
open doc/api/index.html
```

### 3. Continuous Integration

Add documentation generation to your CI pipeline:

```yaml
# .github/workflows/docs.yml
name: Generate Documentation

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.4'
      - run: dart pub global activate dartdoc
      - run: dartdoc --config dartdoc_options.yaml
      - uses: actions/upload-artifact@v3
        with:
          name: documentation
          path: doc/api/
```

## Documentation Best Practices

### 1. Keep Documentation Up-to-Date

- Update documentation when changing public APIs
- Review documentation during code reviews
- Test documentation examples

### 2. Use Clear Language

- Write in simple, clear English
- Avoid jargon and technical terms when possible
- Use consistent terminology throughout

### 3. Provide Examples

- Include usage examples for complex APIs
- Show common use cases
- Demonstrate error handling

### 4. Document Edge Cases

- Explain what happens with invalid input
- Document performance characteristics
- Note any limitations or constraints

### 5. Use Markdown Formatting

- Use headers for organization
- Use code blocks for examples
- Use lists for features and parameters
- Use bold for emphasis

### 6. Link Related Documentation

- Reference related classes and methods
- Link to external documentation when relevant
- Use `[ClassName]` syntax for internal links

## Documentation Tools

### 1. IDE Support

Most IDEs support DartDoc:
- **VS Code**: Install Dart extension
- **Android Studio**: Built-in Dart support
- **IntelliJ IDEA**: Install Dart plugin

### 2. Linting

Enable documentation linting in `analysis_options.yaml`:

```yaml
analyzer:
  errors:
    missing_required_param: error
    missing_return: error
    public_member_api_docs: warning
```

### 3. Documentation Coverage

Check documentation coverage:

```bash
dart pub global activate dartdoc
dartdoc --config dartdoc_options.yaml --show-progress
```

## Troubleshooting

### Common Issues

1. **Documentation not generating**
   - Check that dartdoc is installed
   - Verify dartdoc_options.yaml is valid
   - Check for syntax errors in comments

2. **Missing documentation**
   - Ensure all public APIs have documentation
   - Check that comments use `///` syntax
   - Verify documentation is not excluded

3. **Broken links**
   - Check that referenced classes exist
   - Verify method signatures match
   - Test documentation examples

### Getting Help

- Check [DartDoc documentation](https://dart.dev/tools/dartdoc)
- Review [Dart documentation guidelines](https://dart.dev/guides/language/effective-dart/documentation)
- Ask questions in the project discussions

## Next Steps

1. **Document Core Classes**: Start with the most important classes
2. **Add Examples**: Include usage examples for complex APIs
3. **Review and Update**: Regularly review and update documentation
4. **Automate**: Set up automated documentation generation
5. **Publish**: Consider publishing documentation to GitHub Pages

---

For questions or suggestions about this documentation guide, please open an issue or discussion in the project repository. 