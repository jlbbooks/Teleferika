# UI Widgets

This directory contains reusable UI widgets for the Teleferika app.

## StatusIndicator

A reusable status notification widget that provides elegant, non-intrusive user feedback.

### Features

- **Multiple status types**: Success, Error, Info, Loading
- **Smooth animations**: Fade-in/fade-out with slide effect
- **Auto-hide**: Configurable duration for automatic dismissal
- **Manual dismiss**: Close button for user control
- **Tooltips**: Full message visible on hover
- **Customizable**: Position, size, and styling options

### Usage

#### Option 1: Using StatusMixin (Recommended)

Add the mixin to your StatefulWidget and use the provided methods:

```dart
import 'package:teleferika/ui/widgets/status_indicator.dart';

class MyPage extends StatefulWidget {
  @override
  _MyPageState createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with StatusMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Your main content
          YourMainContent(),
          
          // Status indicator positioned in top-right
          Positioned(
            top: 24,
            right: 24,
            child: StatusIndicator(
              status: currentStatus,
              onDismiss: hideStatus,
            ),
          ),
        ],
      ),
    );
  }
  
  void _handleSomeAction() async {
    showLoadingStatus('Processing...');
    
    try {
      await someAsyncOperation();
      showSuccessStatus('Operation completed successfully!');
    } catch (e) {
      showErrorStatus('Error: $e');
    }
  }
}
```

#### Option 2: Direct Widget Usage

Use the StatusIndicator widget directly with your own state management:

```dart
class _MyPageState extends State<MyPage> {
  StatusInfo? _status;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          YourMainContent(),
          
          Positioned(
            top: 24,
            right: 24,
            child: StatusIndicator(
              status: _status,
              onDismiss: () => setState(() => _status = null),
              margin: EdgeInsets.all(16),
              maxWidth: 300,
            ),
          ),
        ],
      ),
    );
  }
  
  void _showStatus(String message, StatusType type) {
    setState(() {
      _status = StatusManager.success(message); // or error, info, loading
    });
  }
}
```

### StatusMixin Methods

When using the `StatusMixin`, you have access to these methods:

- `showStatus(StatusInfo status)` - Show a custom status
- `showSuccessStatus(String message)` - Show success message
- `showErrorStatus(String message)` - Show error message  
- `showInfoStatus(String message)` - Show info message
- `showLoadingStatus(String message)` - Show loading indicator
- `hideStatus()` - Hide current status
- `currentStatus` - Get current status info

### StatusIndicator Properties

- `status` - The StatusInfo to display
- `onDismiss` - Callback when user dismisses the status
- `margin` - Margin around the indicator
- `maxWidth` - Maximum width of the indicator (default: 320)
- `autoHide` - Whether to auto-hide non-loading statuses (default: true)

### Status Types

- **Success**: Green with check icon, auto-hides after 3 seconds
- **Error**: Red with error icon, auto-hides after 3 seconds  
- **Info**: Blue with info icon, auto-hides after 3 seconds
- **Loading**: Orange with spinner, doesn't auto-hide

### Best Practices

1. **Use StatusMixin** for most cases - it handles timer management automatically
2. **Position consistently** - Top-right corner is recommended
3. **Keep messages concise** - Long messages are truncated with ellipsis
4. **Use appropriate types** - Loading for async operations, success/error for results
5. **Don't overuse** - Reserve for important user feedback, not every minor action

### Example Integration

See `lib/ui/pages/project_page.dart` for a complete example of how the status system is integrated into a real page. 