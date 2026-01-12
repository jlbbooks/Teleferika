# UI Documentation Guide for Flutter Projects

This guide covers how to document UI elements in your Flutter project using DartDoc and additional tools for comprehensive UI documentation.

## Table of Contents

1. [DartDoc UI Documentation](#dartdoc-ui-documentation)
2. [UI Documentation Best Practices](#ui-documentation-best-practices)
3. [Additional UI Documentation Tools](#additional-ui-documentation-tools)
4. [Widget Storybook Approach](#widget-storybook-approach)
5. [Screenshot Documentation](#screenshot-documentation)
6. [Interactive Documentation](#interactive-documentation)

## DartDoc UI Documentation

DartDoc can document UI elements effectively with proper documentation comments. Here's how to structure your UI documentation:

### Widget Class Documentation

```dart
/// A widget that displays user status messages with animations.
/// 
/// The [StatusIndicator] provides a non-intrusive way to show feedback
/// messages with smooth slide/fade animations and appropriate styling
/// for different message types.
/// 
/// ## Features
/// - **Multiple Status Types**: Success, Error, Info, Loading
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
/// 
/// ## Visual Design
/// The widget uses Material Design principles with:
/// - Elevated card appearance with rounded corners
/// - Semi-transparent background with status color
/// - White text with proper contrast
/// - Icon + text layout with appropriate spacing
class StatusIndicator extends StatefulWidget {
  // ... implementation
}
```

### Widget Properties Documentation

```dart
/// The status configuration to display.
/// 
/// When null, the widget will be hidden. When a new status is provided,
/// the widget will animate in and display the message.
/// 
/// Example:
/// ```dart
/// status: StatusManager.success('File saved successfully!')
/// ```
final StatusInfo? status;

/// Callback function called when the user manually dismisses the status.
/// 
/// This is typically used to update the parent widget's state or
/// perform cleanup actions.
/// 
/// Example:
/// ```dart
/// onDismiss: () {
///   setState(() {
///     _showStatus = false;
///   });
/// }
/// ```
final VoidCallback? onDismiss;
```

### Enum Documentation

```dart
/// Types of status messages that can be displayed.
/// 
/// Each type has its own visual styling including color, icon, and behavior.
enum StatusType {
  /// Success status - green color, check icon
  /// Used for successful operations like saving files or completing forms
  success,
  
  /// Error status - red color, error icon
  /// Used for failures, validation errors, or operation failures
  error,
  
  /// Information status - blue color, info icon
  /// Used for informational content, tips, or non-critical notifications
  info,
  
  /// Loading status - orange color, spinner animation
  /// Used for ongoing operations that don't auto-hide
  loading,
}
```

## UI Documentation Best Practices

### 1. Structure Your Documentation

- **Overview**: Start with a clear description of what the widget does
- **Features**: List key capabilities and behaviors
- **Usage Examples**: Provide practical code examples
- **Visual Design**: Describe the appearance and styling
- **Accessibility**: Document accessibility features
- **Dependencies**: Note any required packages or setup

### 2. Include Visual Descriptions

Since DartDoc can't show screenshots, describe the visual appearance:

```dart
/// ## Visual Appearance
/// The widget displays as a rounded rectangle card with:
/// - Semi-transparent background colored according to status type
/// - White text with high contrast for readability
/// - Icon on the left, message text on the right
/// - Smooth slide-in animation from the right edge
/// - Elevation shadow for depth
/// - Maximum width of 320px with text truncation
```

### 3. Document State Changes

```dart
/// ## State Behavior
/// - **Hidden**: When [status] is null, widget is invisible
/// - **Visible**: When [status] is provided, animates in from right
/// - **Auto-hide**: After [duration], automatically animates out
/// - **Manual dismiss**: User can tap close button to dismiss immediately
/// - **Loading**: Shows spinner instead of icon, doesn't auto-hide
```

### 4. Include Accessibility Information

```dart
/// ## Accessibility
/// - High contrast text (white on colored background)
/// - Minimum touch target size of 44x44 pixels
/// - Tooltip shows full message for truncated text
/// - Screen reader announces status type and message
/// - Keyboard navigation support for dismiss button
```

## Additional UI Documentation Tools

### 1. Flutter Widgetbook

[Widgetbook](https://pub.dev/packages/widgetbook) is a Flutter package for creating interactive widget catalogs:

```yaml
# pubspec.yaml
dev_dependencies:
  widgetbook: ^3.0.0
  widgetbook_annotation: ^1.0.0
```

```dart
// lib/widgetbook/widgetbook.dart
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@WidgetbookApp.material()
class MyWidgetbook extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        StatusIndicatorStories.directory,
        // Add more widget directories
      ],
    );
  }
}

// lib/widgetbook/stories/status_indicator_stories.dart
@WidgetbookStory(name: 'StatusIndicator')
class StatusIndicatorStories extends WidgetbookWidget {
  @override
  List<Arg> get args => [
        Arg.enum_(
          name: 'statusType',
          options: StatusType.values,
        ),
        Arg.string(
          name: 'message',
          description: 'The message to display',
        ),
        Arg.boolean(
          name: 'autoHide',
          description: 'Whether to auto-hide the status',
        ),
      ];

  @override
  Widget build(BuildContext context, ArgSnapshot snapshot) {
    final statusType = snapshot.enum_<StatusType>('statusType');
    final message = snapshot.string('message');
    final autoHide = snapshot.boolean('autoHide');

    StatusInfo status;
    switch (statusType) {
      case StatusType.success:
        status = StatusManager.success(message);
        break;
      case StatusType.error:
        status = StatusManager.error(message);
        break;
      case StatusType.info:
        status = StatusManager.info(message);
        break;
      case StatusType.loading:
        status = StatusManager.loading(message);
        break;
    }

    return StatusIndicator(
      status: status,
      autoHide: autoHide,
    );
  }
}
```

### 2. Flutter Storybook

[Flutter Storybook](https://pub.dev/packages/flutter_storybook) is another option for widget documentation:

```dart
// lib/stories/status_indicator_stories.dart
import 'package:flutter_storybook/flutter_storybook.dart';

class StatusIndicatorStories {
  static List<Story> get stories => [
        Story(
          name: 'Success Status',
          builder: (context) => StatusIndicator(
            status: StatusManager.success('Operation completed successfully!'),
          ),
        ),
        Story(
          name: 'Error Status',
          builder: (context) => StatusIndicator(
            status: StatusManager.error('Something went wrong'),
          ),
        ),
        Story(
          name: 'Loading Status',
          builder: (context) => StatusIndicator(
            status: StatusManager.loading('Processing your request...'),
            autoHide: false,
          ),
        ),
        Story(
          name: 'Custom Styled',
          builder: (context) => StatusIndicator(
            status: StatusManager.info('Custom styled message'),
            margin: EdgeInsets.all(16),
            maxWidth: 400,
          ),
        ),
      ];
}
```

### 3. Screenshot Testing with Golden Tests

Create automated screenshot tests to document widget appearances:

```dart
// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/ui/widgets/status_indicator.dart';

void main() {
  group('StatusIndicator Golden Tests', () {
    testWidgets('Success status appearance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusIndicator(
              status: StatusManager.success('Success message'),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(StatusIndicator),
        matchesGoldenFile('status_indicator_success.png'),
      );
    });

    testWidgets('Error status appearance', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusIndicator(
              status: StatusManager.error('Error message'),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(StatusIndicator),
        matchesGoldenFile('status_indicator_error.png'),
      );
    });
  });
}
```

### 4. Interactive Documentation with DartPad

Create interactive examples that can be embedded in documentation:

```dart
// Create a simple example that can run in DartPad
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('StatusIndicator Demo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              StatusIndicator(
                status: StatusManager.success('Success message'),
              ),
              SizedBox(height: 16),
              StatusIndicator(
                status: StatusManager.error('Error message'),
              ),
              SizedBox(height: 16),
              StatusIndicator(
                status: StatusManager.info('Info message'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Widget Storybook Approach

Create a comprehensive widget catalog that can be run as a separate app:

```dart
// lib/widgetbook/main.dart
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

void main() {
  runApp(MyWidgetbook());
}

class MyWidgetbook extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: [
        WidgetbookFolder(
          name: 'UI Components',
          children: [
            WidgetbookFolder(
              name: 'Status',
              children: [
                WidgetbookWidget(
                  name: 'StatusIndicator',
                  useCases: [
                    WidgetbookUseCase(
                      name: 'Success',
                      builder: (context) => StatusIndicator(
                        status: StatusManager.success('Success message'),
                      ),
                    ),
                    WidgetbookUseCase(
                      name: 'Error',
                      builder: (context) => StatusIndicator(
                        status: StatusManager.error('Error message'),
                      ),
                    ),
                    WidgetbookUseCase(
                      name: 'Loading',
                      builder: (context) => StatusIndicator(
                        status: StatusManager.loading('Loading...'),
                        autoHide: false,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
```

## Screenshot Documentation

### Automated Screenshot Generation

Create a script to automatically generate screenshots of all widget states:

```dart
// tools/screenshot_generator.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:your_app/ui/widgets/status_indicator.dart';

void main() async {
  final directory = Directory('docs/screenshots');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  // Generate screenshots for different states
  await _generateScreenshot(
    'status_indicator_success',
    StatusIndicator(
      status: StatusManager.success('Success message'),
    ),
  );

  await _generateScreenshot(
    'status_indicator_error',
    StatusIndicator(
      status: StatusManager.error('Error message'),
    ),
  );

  await _generateScreenshot(
    'status_indicator_loading',
    StatusIndicator(
      status: StatusManager.loading('Loading...'),
      autoHide: false,
    ),
  );
}

Future<void> _generateScreenshot(String name, Widget widget) async {
  final testWidget = MaterialApp(
    home: Scaffold(
      body: Center(child: widget),
    ),
  );

  await expectLater(
    find.byType(StatusIndicator),
    matchesGoldenFile('docs/screenshots/$name.png'),
  );
}
```

## Interactive Documentation

### Live Widget Preview

Create a documentation page that shows live widget examples:

```dart
// lib/ui/documentation/widget_documentation.dart
import 'package:flutter/material.dart';

class WidgetDocumentation extends StatefulWidget {
  @override
  _WidgetDocumentationState createState() => _WidgetDocumentationState();
}

class _WidgetDocumentationState extends State<WidgetDocumentation> {
  StatusType selectedType = StatusType.success;
  String message = 'Sample message';
  bool autoHide = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Widget Documentation')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'StatusIndicator Widget',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16),
            
            // Live preview
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Live Preview', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 16),
                    StatusIndicator(
                      status: _getStatusInfo(),
                      autoHide: autoHide,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Controls
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Controls', style: Theme.of(context).textTheme.titleMedium),
                    SizedBox(height: 16),
                    
                    DropdownButtonFormField<StatusType>(
                      value: selectedType,
                      decoration: InputDecoration(labelText: 'Status Type'),
                      items: StatusType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    TextField(
                      decoration: InputDecoration(labelText: 'Message'),
                      value: message,
                      onChanged: (value) {
                        setState(() {
                          message = value;
                        });
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    CheckboxListTile(
                      title: Text('Auto Hide'),
                      value: autoHide,
                      onChanged: (value) {
                        setState(() {
                          autoHide = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  StatusInfo _getStatusInfo() {
    switch (selectedType) {
      case StatusType.success:
        return StatusManager.success(message);
      case StatusType.error:
        return StatusManager.error(message);
      case StatusType.info:
        return StatusManager.info(message);
      case StatusType.loading:
        return StatusManager.loading(message);
    }
  }
}
```

## Summary

For comprehensive UI documentation, combine:

1. **DartDoc comments** for code-level documentation
2. **Widgetbook or Storybook** for interactive widget catalogs
3. **Golden tests** for automated screenshot generation
4. **Live documentation pages** for interactive examples
5. **Screenshot galleries** for visual documentation

This approach provides both technical documentation (via DartDoc) and visual/interactive documentation (via additional tools) to give developers and designers a complete understanding of your UI components.

## Next Steps

1. Add comprehensive DartDoc comments to all your UI widgets
2. Set up Widgetbook for interactive widget documentation
3. Create golden tests for automated screenshot generation
4. Build a documentation website that combines all approaches
5. Include accessibility and design system documentation 