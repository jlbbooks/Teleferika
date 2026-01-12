/// Compass calibration panel widget for guiding users through device calibration.
///
/// This widget displays a full-screen overlay that guides users through the
/// process of calibrating their device's compass sensor. It shows an animated
/// figure-8 motion and provides clear instructions for the calibration process.
///
/// ## Features
/// - **Visual Guidance**: Animated GIF showing the required figure-8 motion
/// - **Clear Instructions**: Text explaining the calibration process
/// - **Dismissible**: Optional close button for manual dismissal
/// - **Full-screen Overlay**: Semi-transparent background for focus
/// - **Responsive Design**: Adapts to different screen sizes
/// - **Accessibility**: Proper contrast and readable text
///
/// ## Usage Examples
///
/// ### Basic Calibration Panel:
/// ```dart
/// CompassCalibrationPanel(
///   onClose: () {
///     // Handle manual dismissal
///     Navigator.of(context).pop();
///   },
/// )
/// ```
///
/// ### Without Close Button:
/// ```dart
/// CompassCalibrationPanel(
///   // Panel will only disappear when calibration is complete
/// )
/// ```
///
/// ### In a Dialog:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => CompassCalibrationPanel(
///     onClose: () => Navigator.of(context).pop(),
///   ),
/// );
/// ```
///
/// ## Calibration Process
/// The panel guides users through the standard device compass calibration:
/// 1. **Figure-8 Motion**: User moves device in a figure-8 pattern
/// 2. **Sensor Detection**: Device detects the calibration motion
/// 3. **Auto-dismissal**: Panel disappears when calibration is complete
/// 4. **Manual Option**: User can manually dismiss if needed
///
/// ## Visual Design
/// - **Semi-transparent Background**: Black overlay (70% opacity)
/// - **White Card**: Clean, centered card with rounded corners
/// - **Animated GIF**: Figure-8 motion demonstration
/// - **Clear Typography**: Bold title and readable instructions
/// - **Consistent Spacing**: Proper padding and margins
///
/// ## Integration
/// Designed to work with:
/// - Device compass sensors
/// - Location services
/// - Map applications
/// - Navigation features
///
/// ## Best Practices
/// - Show this panel when compass accuracy is low
/// - Allow users to dismiss if they prefer not to calibrate
/// - Provide clear, simple instructions
/// - Use consistent visual design with the app
/// - Ensure accessibility compliance

import 'package:flutter/material.dart';

/// A widget that displays compass calibration instructions to the user.
///
/// This widget shows a full-screen overlay with animated guidance for
/// calibrating the device's compass sensor. It automatically disappears
/// when calibration is complete or can be manually dismissed.
class CompassCalibrationPanel extends StatelessWidget {
  /// Optional callback function called when the user manually closes the panel.
  ///
  /// If provided, a close button will be shown that allows users to manually
  /// dismiss the calibration panel. If null, the panel can only be dismissed
  /// automatically when calibration is complete.
  final VoidCallback? onClose;

  /// Creates a compass calibration panel widget.
  ///
  /// The [onClose] parameter is optional. If provided, users can manually
  /// dismiss the panel. If not provided, the panel will only disappear
  /// when the device detects that calibration is complete.
  const CompassCalibrationPanel({this.onClose, super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/animations/figure-8-compass-calibration.gif',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              const Text(
                'Compass Calibration Needed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Move your phone in a figure-8 motion until this panel disappears.',
                textAlign: TextAlign.center,
              ),
              if (onClose != null)
                TextButton.icon(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                  label: const Text('Dismiss'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
