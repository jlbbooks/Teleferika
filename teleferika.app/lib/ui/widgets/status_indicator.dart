/// Status indicator widget for displaying user feedback messages.
///
/// This module provides a comprehensive status notification system that displays
/// elegant, non-intrusive user feedback messages. It includes different status
/// types (success, error, info, loading) with appropriate styling and animations.
///
/// ## Features
/// - **Multiple Status Types**: Success, Error, Info, Loading with appropriate icons and colors
/// - **Smooth Animations**: Fade-in/fade-out with slide effect for smooth transitions
/// - **Auto-hide**: Configurable duration for automatic dismissal
/// - **Manual Dismiss**: Close button for user control
/// - **Tooltips**: Full message visible on hover for truncated text
/// - **Customizable**: Position, size, and styling options
/// - **Accessible**: Proper contrast and readable text
///
/// ## Usage Examples
///
/// ### Basic Usage:
/// ```dart
/// StatusIndicator(
///   status: StatusManager.success('Operation completed successfully!'),
///   onDismiss: () => print('Status dismissed'),
/// )
/// ```
///
/// ### With Custom Styling:
/// ```dart
/// StatusIndicator(
///   status: StatusManager.error('Something went wrong'),
///   margin: EdgeInsets.all(16),
///   maxWidth: 400,
///   autoHide: false,
/// )
/// ```
///
/// ### Loading State:
/// ```dart
/// StatusIndicator(
///   status: StatusManager.loading('Processing your request...'),
///   autoHide: false, // Loading states typically don't auto-hide
/// )
/// ```
///
/// ## Status Types
/// - **Success**: Green color with check icon - for successful operations
/// - **Error**: Red color with error icon - for errors and failures
/// - **Info**: Blue color with info icon - for informational messages
/// - **Loading**: Orange color with spinner - for ongoing operations
///
/// ## Accessibility
/// The widget includes proper contrast ratios, readable text sizes,
/// and tooltips for truncated messages to ensure accessibility compliance.

import 'dart:async';

import 'package:flutter/material.dart';

/// Types of status messages that can be displayed.
///
/// Each type has its own visual styling including color, icon, and behavior.
enum StatusType {
  /// Success status - green color, check icon
  success,

  /// Error status - red color, error icon
  error,

  /// Information status - blue color, info icon
  info,

  /// Loading status - orange color, spinner animation
  loading,
}

/// Configuration class for status messages.
///
/// Contains all the information needed to display a status message including
/// type, message text, visual styling, and behavior settings.
///
/// ## Properties
/// - [type]: The status type (success, error, info, loading)
/// - [message]: The text message to display
/// - [icon]: The icon to show alongside the message
/// - [color]: The background color for the status indicator
/// - [duration]: How long to show the message before auto-hiding
///
/// ## Example
/// ```dart
/// StatusInfo(
///   type: StatusType.success,
///   message: 'File saved successfully!',
///   icon: Icons.check_circle,
///   color: Colors.green,
///   duration: Duration(seconds: 5),
/// )
/// ```
class StatusInfo {
  /// The type of status message.
  final StatusType type;

  /// The text message to display to the user.
  final String message;

  /// The icon to display alongside the message.
  final IconData icon;

  /// The background color for the status indicator.
  final Color color;

  /// How long to display the message before automatically hiding it.
  ///
  /// Defaults to 3 seconds. Set to [Duration.zero] to disable auto-hide.
  final Duration duration;

  /// Creates a new status info configuration.
  ///
  /// All parameters except [duration] are required. The [duration] parameter
  /// defaults to 3 seconds for most status types, but loading statuses
  /// typically use [Duration.zero] to prevent auto-hiding.
  const StatusInfo({
    required this.type,
    required this.message,
    required this.icon,
    required this.color,
    this.duration = const Duration(seconds: 3),
  });
}

/// Factory class for creating predefined status configurations.
///
/// Provides convenient static methods to create common status types
/// with appropriate styling and behavior. This ensures consistency
/// across the application and reduces boilerplate code.
///
/// ## Usage Examples
/// ```dart
/// // Success message
/// StatusManager.success('Operation completed!')
///
/// // Error message
/// StatusManager.error('Something went wrong')
///
/// // Info message
/// StatusManager.info('Please wait while we process your request')
///
/// // Loading message (doesn't auto-hide)
/// StatusManager.loading('Uploading files...')
/// ```
class StatusManager {
  /// Creates a success status with green styling and check icon.
  ///
  /// Success messages are typically shown after successful operations
  /// like saving files, completing forms, or successful API calls.
  ///
  /// **Auto-hide duration**: 3 seconds
  /// **Color**: Green
  /// **Icon**: Check circle
  ///
  /// Example:
  /// ```dart
  /// StatusIndicator(
  ///   status: StatusManager.success('Project saved successfully!'),
  /// )
  /// ```
  static StatusInfo success(String message) => StatusInfo(
    type: StatusType.success,
    message: message,
    icon: Icons.check_circle,
    color: Colors.green,
  );

  /// Creates an error status with red styling and error icon.
  ///
  /// Error messages should be used for failures, validation errors,
  /// or when operations cannot be completed.
  ///
  /// **Auto-hide duration**: 3 seconds
  /// **Color**: Red
  /// **Icon**: Error
  ///
  /// Example:
  /// ```dart
  /// StatusIndicator(
  ///   status: StatusManager.error('Failed to save project'),
  /// )
  /// ```
  static StatusInfo error(String message) => StatusInfo(
    type: StatusType.error,
    message: message,
    icon: Icons.error,
    color: Colors.red,
  );

  /// Creates an info status with blue styling and info icon.
  ///
  /// Info messages are for informational content, tips, or
  /// non-critical notifications.
  ///
  /// **Auto-hide duration**: 3 seconds
  /// **Color**: Blue
  /// **Icon**: Info
  ///
  /// Example:
  /// ```dart
  /// StatusIndicator(
  ///   status: StatusManager.info('New version available'),
  /// )
  /// ```
  static StatusInfo info(String message) => StatusInfo(
    type: StatusType.info,
    message: message,
    icon: Icons.info,
    color: Colors.blue,
  );

  /// Creates a loading status with orange styling and spinner.
  ///
  /// Loading messages indicate ongoing operations. They don't auto-hide
  /// and should be manually dismissed when the operation completes.
  ///
  /// **Auto-hide duration**: Never (Duration.zero)
  /// **Color**: Orange
  /// **Icon**: Hourglass (replaced by spinner in widget)
  ///
  /// Example:
  /// ```dart
  /// StatusIndicator(
  ///   status: StatusManager.loading('Processing your request...'),
  ///   autoHide: false, // Recommended for loading states
  /// )
  /// ```
  static StatusInfo loading(String message) => StatusInfo(
    type: StatusType.loading,
    message: message,
    icon: Icons.hourglass_empty,
    color: Colors.orange,
    duration: const Duration(seconds: 0), // No auto-hide for loading
  );
}

/// A widget that displays status messages with smooth animations and styling.
///
/// The [StatusIndicator] widget provides a non-intrusive way to show user feedback
/// messages. It supports different status types (success, error, info, loading)
/// with appropriate visual styling and smooth slide/fade animations.
///
/// ## Features
/// - **Smooth Animations**: Slide-in from right with fade effect
/// - **Auto-hide**: Configurable duration for automatic dismissal
/// - **Manual Dismiss**: Close button for user control
/// - **Tooltips**: Full message visible on hover for truncated text
/// - **Responsive**: Adapts to different screen sizes
/// - **Accessible**: High contrast text and proper sizing
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
/// ### Loading State (No Auto-hide):
/// ```dart
/// StatusIndicator(
///   status: StatusManager.loading('Processing...'),
///   autoHide: false,
/// )
/// ```
///
/// ## Widget Properties
/// - [status]: The status configuration to display
/// - [onDismiss]: Callback when user manually dismisses the status
/// - [margin]: Custom margin around the status indicator
/// - [maxWidth]: Maximum width of the status message
/// - [autoHide]: Whether to automatically hide the status after duration
///
/// ## Visual Design
/// The widget uses Material Design principles with:
/// - Elevated card appearance with rounded corners
/// - Semi-transparent background with status color
/// - White text with proper contrast
/// - Icon + text layout with appropriate spacing
/// - Smooth slide and fade animations
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

  /// Custom margin around the status indicator.
  ///
  /// Defaults to null, which uses the widget's default positioning.
  /// Useful for custom positioning or spacing requirements.
  final EdgeInsetsGeometry? margin;

  /// Maximum width of the status message container.
  ///
  /// Defaults to 320 logical pixels. Messages longer than this width
  /// will be truncated with ellipsis and a tooltip will show the full text.
  final double? maxWidth;

  /// Whether to automatically hide the status after the duration specified
  /// in the [StatusInfo.duration].
  ///
  /// Defaults to true. Set to false for loading states or when you want
  /// manual control over when the status is hidden.
  final bool autoHide;

  /// Creates a status indicator widget.
  ///
  /// The [status] parameter determines what message to display and how to style it.
  /// The [onDismiss] callback is optional and called when the user manually
  /// dismisses the status. Other parameters allow for custom styling and behavior.
  const StatusIndicator({
    super.key,
    this.status,
    this.onDismiss,
    this.margin,
    this.maxWidth = 320,
    this.autoHide = true,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator> {
  late final ValueNotifier<bool> _visible = ValueNotifier(false);
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _visible.value = false;
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.status != oldWidget.status) {
      if (widget.status != null) {
        _showStatus();
      } else {
        _hideStatus();
      }
    }
  }

  void _showStatus() {
    _visible.value = true;

    // Clear any existing timer
    _hideTimer?.cancel();

    // Set up auto-hide timer (except for loading status or if autoHide is false)
    if (widget.autoHide &&
        widget.status?.type != StatusType.loading &&
        widget.status?.duration.inSeconds != 0) {
      _hideTimer = Timer(widget.status!.duration, () {
        if (mounted) {
          _hideStatus();
        }
      });
    }
  }

  void _hideStatus() {
    _hideTimer?.cancel();
    if (mounted) {
      _visible.value = false;
    }
  }

  void _handleDismiss() {
    widget.onDismiss?.call();
    _hideStatus();
  }

  /// Gets the announcement label for screen readers.
  ///
  /// Includes the status type prefix for better context.
  String _getStatusAnnouncementLabel() {
    if (widget.status == null) return '';

    final statusType = widget.status!.type;
    final message = widget.status!.message;

    switch (statusType) {
      case StatusType.success:
        return 'Success: $message';
      case StatusType.error:
        return 'Error: $message';
      case StatusType.info:
        return 'Information: $message';
      case StatusType.loading:
        return 'Loading: $message';
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _visible.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _visible,
      builder: (context, visible, child) {
        return AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0.2, 0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: visible && widget.status != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            child: widget.status == null
                ? const SizedBox.shrink()
                : Semantics(
                    // Use liveRegion to announce status changes to screen readers
                    // This replaces deprecated announceForAccessibility methods
                    // liveRegion provides polite announcements when the widget updates
                    liveRegion: true,
                    label: _getStatusAnnouncementLabel(),
                    child: Container(
                      margin: widget.margin,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: widget.status!.color.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: BoxConstraints(
                            maxWidth: widget.maxWidth ?? 320,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.status!.type == StatusType.loading)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  widget.status!.icon,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Tooltip(
                                  message: widget.status!.message,
                                  child: Text(
                                    widget.status!.message,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              if (widget.status!.type != StatusType.loading)
                                Semantics(
                                  label: 'Dismiss ${widget.status!.message}',
                                  button: true,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    onPressed: _handleDismiss,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

// Mixin for easy status management in StatefulWidgets
mixin StatusMixin<T extends StatefulWidget> on State<T> {
  StatusInfo? _currentStatus;
  Timer? _statusTimer;

  void showStatus(StatusInfo status) {
    setState(() {
      _currentStatus = status;
    });

    // Clear any existing timer
    _statusTimer?.cancel();

    // Set up auto-hide timer (except for loading status)
    if (status.type != StatusType.loading && status.duration.inSeconds > 0) {
      _statusTimer = Timer(status.duration, () {
        if (mounted) {
          setState(() {
            _currentStatus = null;
          });
        }
      });
    }
  }

  void hideStatus() {
    _statusTimer?.cancel();
    if (mounted) {
      setState(() {
        _currentStatus = null;
      });
    }
  }

  void showSuccessStatus(String message) {
    showStatus(StatusManager.success(message));
  }

  void showErrorStatus(String message) {
    showStatus(StatusManager.error(message));
  }

  void showInfoStatus(String message) {
    showStatus(StatusManager.info(message));
  }

  void showLoadingStatus(String message) {
    showStatus(StatusManager.loading(message));
  }

  StatusInfo? get currentStatus => _currentStatus;

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
}
