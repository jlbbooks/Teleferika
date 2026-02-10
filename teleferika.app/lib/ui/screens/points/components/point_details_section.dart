import 'package:flutter/material.dart';
import 'package:teleferika/core/app_config.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class PointDetailsSection extends StatelessWidget {
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final TextEditingController altitudeController;
  final TextEditingController noteController;
  final TextEditingController gpsPrecisionController;

  const PointDetailsSection({
    super.key,
    required this.latitudeController,
    required this.longitudeController,
    required this.altitudeController,
    required this.noteController,
    required this.gpsPrecisionController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gps_fixed,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                S.of(context)?.pointDetailsSectionTitle ?? 'Point Details',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Latitude
          TextFormField(
            controller: latitudeController,
            decoration: InputDecoration(
              labelText: S.of(context)?.latitude_label ?? 'Latitude',
              hintText: S.of(context)?.latitude_hint ?? 'e.g. 45.12345',
              prefixIcon: const Icon(
                AppConfig.latitudeIcon,
                color: AppConfig.latitudeColor,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return S.of(context)?.latitude_empty_validator ??
                    'Latitude cannot be empty';
              }
              final n = double.tryParse(value);
              if (n == null) {
                return S.of(context)?.latitude_invalid_validator ??
                    'Invalid number format';
              }
              if (n < -90 || n > 90) {
                return S.of(context)?.latitude_range_validator ??
                    'Latitude must be between -90 and 90';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Longitude
          TextFormField(
            controller: longitudeController,
            decoration: InputDecoration(
              labelText: S.of(context)?.longitude_label ?? 'Longitude',
              hintText: S.of(context)?.longitude_hint ?? 'e.g. -12.54321',
              prefixIcon: const Icon(
                AppConfig.longitudeIcon,
                color: AppConfig.longitudeColor,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return S.of(context)?.longitude_empty_validator ??
                    'Longitude cannot be empty';
              }
              final n = double.tryParse(value);
              if (n == null) {
                return S.of(context)?.longitude_invalid_validator ??
                    'Invalid number format';
              }
              if (n < -180 || n > 180) {
                return S.of(context)?.longitude_range_validator ??
                    'Longitude must be between -180 and 180';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Altitude
          TextFormField(
            controller: altitudeController,
            decoration: InputDecoration(
              labelText: S.of(context)?.altitude_label ?? 'Altitude (m)',
              hintText:
                  S.of(context)?.altitude_hint ?? 'e.g. 1203.5 (Optional)',
              prefixIcon: const Icon(
                AppConfig.altitudeIcon,
                color: AppConfig.altitudeColor,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true, // Allow negative values
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return null; // Altitude is optional
              }
              final n = double.tryParse(value);
              if (n == null) {
                return S.of(context)?.altitude_invalid_validator ??
                    'Invalid number format';
              }
              if (n < -1000 || n > 8849) {
                return S.of(context)?.altitude_range_validator ??
                    'Altitude must be between -1000 and 8849 meters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // GPS Precision (editable)
          TextFormField(
            controller: gpsPrecisionController,
            decoration: InputDecoration(
              labelText: S.of(context)?.gpsPrecisionLabel ?? 'GPS Precision:',
              hintText: 'e.g. 3.5',
              prefixIcon: const Icon(
                AppConfig.gpsPrecisionIcon,
                color: AppConfig.gpsPrecisionColor,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: false,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return null; // GPS precision is optional
              }
              final n = double.tryParse(value);
              if (n == null) {
                return S.of(context)?.altitude_invalid_validator ??
                    'Invalid number format';
              }
              if (n < 0) {
                return 'GPS precision must be non-negative';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Note
          TextFormField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: S.of(context)?.note_label ?? 'Note (Optional)',
              hintText:
                  S.of(context)?.note_hint ?? 'Any observations or details...',
              prefixIcon: const Icon(Icons.notes, color: Colors.teal, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                ),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
            keyboardType: TextInputType.multiline,
            maxLines: null,
          ),
        ],
      ),
    );
  }
}
