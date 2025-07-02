import 'package:flutter/material.dart';

class CompassCalibrationPanel extends StatelessWidget {
  final VoidCallback? onClose;

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
