# TeleferiKa Licensing Framework

This document describes the licensing framework used in TeleferiKa, which supports both full (licensed) and opensource versions of the app.

## Overview

The licensing framework consists of several components:

1. **Feature Registry** - Central registry for managing feature availability
2. **Licence Service** - Handles licence validation and management
3. **Licensed Features Loader** - Loads licensed features based on build type
4. **Licensed Features Package** - Contains premium features (full version only)

## Build Flavors

TeleferiKa supports two build flavors:

### Full Version (`full`)
- Includes the `teleferika_licensed_features` package
- Supports premium features
- Requires a valid licence for premium functionality
- Uses `licensed_features_loader_full.dart`

### Opensource Version (`opensource`)
- Does not include licensed features package
- Basic functionality only
- No licence required
- Uses `licensed_features_loader_stub.dart`

## Setup

### Switching Between Flavors

Use the provided setup scripts:

```bash
# For full version
./scripts/setup-full.sh

# For opensource version  
./scripts/setup-opensource.sh
```

### Building

```bash
# Full version
flutter build apk --flavor full

# Opensource version
flutter build apk --flavor opensource
```

## Using Licensed Features

### Checking Feature Availability

```dart
import 'package:teleferika/licensing/licensed_features_loader.dart';

// Check if licensed features are available
bool hasFeatures = LicensedFeaturesLoader.hasLicensedFeatures;

// Get list of available features
List<String> features = LicensedFeaturesLoader.licensedFeatures;

// Check specific feature
bool hasFeature = LicensedFeaturesLoader.hasLicensedFeature('premium_banner');
```

### Using the Feature Registry

```dart
import 'package:teleferika/licensing/feature_registry.dart';

// Check if a feature is available
bool hasFeature = FeatureRegistry.hasFeature('premium_banner');

// Build a licensed widget
Widget? widget = FeatureRegistry.buildWidget('premium_banner');

// Execute a licensed function
dynamic result = FeatureRegistry.executeFunction(
  'licensed_features',
  'get_licence_info',
);
```

### Building Licensed Widgets

```dart
// Build a widget if available
Widget? premiumWidget = LicensedFeaturesLoader.buildLicensedWidget('premium_banner');

if (premiumWidget != null) {
  // Use the premium widget
  return premiumWidget;
} else {
  // Fallback for opensource version
  return Text('Premium feature not available');
}
```

## Adding New Licensed Features

### 1. Update the Licensed Plugin

In `licensed_features_package/lib/licensed_plugin.dart`:

```dart
class LicensedPlugin extends FeaturePlugin {
  @override
  List<String> get availableFeatures => [
    'premium_banner',
    'premium_settings',
    'your_new_feature', // Add your feature here
  ];

  @override
  Widget? buildWidget(String widgetType) {
    switch (widgetType) {
      case 'your_new_widget':
        return YourNewWidget();
      // ... other cases
    }
  }

  @override
  dynamic executeFunction(String functionName, [Map<String, dynamic>? parameters]) {
    switch (functionName) {
      case 'your_new_function':
        return _yourNewFunction(parameters);
      // ... other cases
    }
  }
}
```

### 2. Create Your Feature Widget/Function

```dart
class YourNewWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('Your Premium Feature'),
        subtitle: Text('This is only available in the full version'),
      ),
    );
  }
}
```

### 3. Use in Your App

```dart
// In your app code
Widget? premiumWidget = LicensedFeaturesLoader.buildLicensedWidget('your_new_widget');

if (premiumWidget != null) {
  return premiumWidget;
} else {
  return Text('Upgrade to full version for this feature');
}
```

## Licence Management

### Importing a Licence

```dart
import 'package:teleferika/licensing/licence_service.dart';

final licence = await LicenceService.instance.importLicenceFromFile();
if (licence != null) {
  print('Licence imported for: ${licence.email}');
}
```

### Checking Licence Status

```dart
final status = await LicenceService.instance.getLicenceStatus();
if (status['isValid'] == true) {
  print('Licence is valid');
} else {
  print('Licence is invalid or expired');
}
```

## Example Licence File

```json
{
  "email": "user@example.com",
  "validUntil": "2025-12-31T23:59:59Z",
  "features": [
    "premium_banner",
    "premium_settings",
    "advanced_export"
  ],
  "signature": "your_signature_here"
}
```

## Troubleshooting

### Feature Not Available
- Check if you're using the full flavor
- Verify the feature is listed in `availableFeatures`
- Ensure the feature is properly implemented in the plugin

### Licence Issues
- Verify the licence file format is correct
- Check that the licence hasn't expired
- Ensure the signature is valid

### Build Issues
- Run `flutter clean` before switching flavors
- Ensure all dependencies are properly configured
- Check that the correct pubspec.yaml is being used

## Architecture

```
lib/
├── licensing/
│   ├── feature_registry.dart          # Central feature management
│   ├── licence_service.dart           # Licence validation
│   ├── licence_model.dart             # Licence data model
│   ├── licensed_features_loader.dart  # Feature loader (stub/full)
│   └── licence_status_widget.dart     # UI for licence status
├── licensed_features_package/         # Premium features (full only)
│   └── lib/
│       ├── licensed_plugin.dart       # Feature implementations
│       └── licensed_features_loader_full.dart
└── main.dart                          # App initialization
```

The framework is designed to be extensible and maintainable, allowing easy addition of new premium features while keeping the opensource version clean and functional. 