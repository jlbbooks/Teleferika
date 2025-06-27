# TeleferiKa File Organization Reorganization Plan

## Current Issues

1. **Mixed concerns in root**: UI pages, configuration, and utilities are all mixed together
2. **Inconsistent naming**: Some files use `_page.dart`, others use `_widget.dart`
3. **Empty directories**: `map/` directory is empty
4. **Large files**: Some files are very large (e.g., `project_page.dart` at 1183 lines)
5. **Unclear hierarchy**: Related functionality is scattered

## Proposed New Structure

```
lib/
├── core/                           # Core application functionality
│   ├── app_config.dart            # Application configuration
│   ├── logger.dart                # Logging system
│   └── utils/                     # Core utilities
│       └── uuid_generator.dart    # UUID generation utilities
│
├── ui/                            # User interface components
│   ├── pages/                     # Full page screens
│   │   ├── projects_list_page.dart
│   │   ├── project_page.dart
│   │   ├── point_details_page.dart
│   │   ├── loading_page.dart
│   │   └── export_page.dart
│   ├── widgets/                   # Reusable UI components
│   │   └── photo_manager_widget.dart
│   └── tabs/                      # Tab-specific views
│       ├── project_details_tab.dart
│       ├── points_tab.dart
│       ├── points_tool_view.dart
│       ├── compass_tool_view.dart
│       └── map_tool_view.dart
│
├── features/                      # Feature-specific functionality
│   └── export/                    # Export feature
│       └── export_utils.dart
│
├── db/                           # Database layer (unchanged)
│   ├── database_helper.dart
│   └── models/
│       ├── project_model.dart
│       ├── point_model.dart
│       └── image_model.dart
│
├── licensing/                    # Licensing system (unchanged)
│   ├── feature_registry.dart
│   ├── licence_model.dart
│   ├── licence_service.dart
│   ├── licence_status_widget.dart
│   ├── licensed_features_loader.dart
│   └── licensed_features_loader_stub.dart
│
├── l10n/                         # Localization (unchanged)
│   ├── app_en.arb
│   ├── app_it.arb
│   └── app_localizations.dart
│
└── main.dart                     # Application entry point
```

## Naming Conventions

### Files
- **Pages**: `*_page.dart` - Full screen pages that users navigate to
- **Widgets**: `*_widget.dart` - Reusable UI components
- **Tabs**: `*_tab.dart` - Tab-specific content views
- **Tools**: `*_tool_view.dart` - Tool-specific views within tabs
- **Models**: `*_model.dart` - Data models
- **Services**: `*_service.dart` - Business logic services
- **Utils**: `*_utils.dart` - Utility functions and classes

### Directories
- **core/**: Essential application functionality
- **ui/**: All user interface components
- **features/**: Feature-specific functionality
- **db/**: Database and data layer
- **licensing/**: Licensing and feature management
- **l10n/**: Localization and internationalization

## Benefits of New Structure

1. **Clear Separation of Concerns**: Each directory has a specific purpose
2. **Better Discoverability**: Related files are grouped together
3. **Scalability**: Easy to add new features without cluttering the root
4. **Maintainability**: Clear organization makes it easier to find and modify code
5. **Consistent Naming**: Predictable file names based on their purpose

## Migration Steps

1. Create new directory structure
2. Move files to appropriate locations
3. Update import statements throughout the codebase
4. Remove empty directories
5. Update documentation and README files

## Import Path Updates

All import statements need to be updated to reflect the new structure:

```dart
// Old imports
import 'app_config.dart';
import 'logger.dart';
import 'utils/uuid_generator.dart';
import 'projects_list_page.dart';

// New imports
import 'core/app_config.dart';
import 'core/logger.dart';
import 'core/utils/uuid_generator.dart';
import 'ui/pages/projects_list_page.dart';
```

## Future Considerations

1. **Feature Modules**: Consider breaking large features into separate modules
2. **State Management**: Add dedicated state management directory if needed
3. **API Layer**: Add dedicated API layer directory for external services
4. **Testing**: Organize test files to mirror the main structure
5. **Documentation**: Add README files to each major directory explaining its purpose 