# Core

This directory contains core application functionality used throughout the app.

## Structure

### Configuration & logging
- `app_config.dart` - Application configuration (themes, locales, angle thresholds, etc.)
- `logger.dart` - Logging system configuration

### State & settings
- `project_provider.dart` - Project selection and current project provider
- `project_state_manager.dart` - Project and points state management
- `settings_service.dart` - Persisted app settings

### UI / platform helpers
- `fix_quality_colors.dart` - GPS fix quality color mapping for UI
- `platform_gps_info.dart` - Platform-specific GPS status and accuracy info

### Utilities (`utils/`)
- `ordinal_manager.dart` - Ordinal numbering for points and images
- `uuid_generator.dart` - UUID generation utilities
