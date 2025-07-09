import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';

class ProjectDetailsSection extends StatefulWidget {
  final ProjectModel project;
  final bool isNew;
  final int pointsCount;

  const ProjectDetailsSection({
    super.key,
    required this.project,
    required this.isNew,
    required this.pointsCount,
  });

  @override
  State<ProjectDetailsSection> createState() => ProjectDetailsSectionState();
}

class ProjectDetailsSectionState extends State<ProjectDetailsSection>
    with StatusMixin {
  final Logger logger = Logger('ProjectDetailsSection');
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  late TextEditingController _presumedTotalLengthController;
  late TextEditingController _azimuthController;

  late ProjectModel _currentProject;
  late DateTime? _projectDate;
  bool _dirty = false;
  String _originalAzimuthValue = '';
  bool _azimuthFieldModified = false;

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;
    _projectDate =
        widget.project.date ?? (widget.isNew ? DateTime.now() : null);

    _nameController = TextEditingController(text: widget.project.name);
    _noteController = TextEditingController(text: widget.project.note);
    _presumedTotalLengthController = TextEditingController(
      text: widget.project.presumedTotalLength?.toString() ?? '',
    );
    _azimuthController = TextEditingController(
      text: widget.project.azimuth?.toString() ?? '',
    );
    _originalAzimuthValue = _azimuthController.text;

    _nameController.addListener(_onChanged);
    _noteController.addListener(_onChanged);
    _presumedTotalLengthController.addListener(_onChanged);
    _azimuthController.addListener(_onAzimuthChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _presumedTotalLengthController.dispose();
    _azimuthController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final name = _nameController.text.trim();
    final note = _noteController.text.trim();
    final presumed = double.tryParse(_presumedTotalLengthController.text);
    final azimuth = double.tryParse(_azimuthController.text);
    final dirty =
        name != widget.project.name ||
        note != widget.project.note ||
        presumed != widget.project.presumedTotalLength ||
        azimuth != widget.project.azimuth ||
        _projectDate != widget.project.date;

    setState(() {
      _dirty = dirty;
      _currentProject = _currentProject.copyWith(
        name: name,
        note: note,
        presumedTotalLength: _presumedTotalLengthController.text.trim().isEmpty
            ? null
            : presumed,
        azimuth: _azimuthController.text.trim().isEmpty ? null : azimuth,
        date: _projectDate,
      );
    });

    // Update global state
    final projectState = context.projectState;
    if (projectState.currentProject != null) {
      projectState.setProjectEditState(_currentProject, _dirty);
    }
  }

  void _onAzimuthChanged() {
    final isModified = _azimuthController.text != _originalAzimuthValue;
    if (_azimuthFieldModified != isModified) {
      setState(() {
        _azimuthFieldModified = isModified;
      });
    }
    _onChanged();
  }

  Future<void> _selectProjectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _projectDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _projectDate) {
      setState(() {
        _projectDate = pickedDate;
      });
      _onChanged();
    }
  }

  void setAzimuthFromParent(double value) {
    _azimuthController.text = value.toStringAsFixed(2);
    _originalAzimuthValue = _azimuthController.text;
    _azimuthFieldModified = true;
    _onChanged();
  }

  Future<void> _handleAzimuthCalculation() async {
    final s = S.of(context);
    final currentAzimuthValue = _azimuthController.text.trim();

    // Check if there's already a value in the azimuth field
    if (currentAzimuthValue.isNotEmpty &&
        double.tryParse(currentAzimuthValue) != null) {
      // Show confirmation dialog
      final bool? shouldOverwrite = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(s?.azimuthOverwriteTitle ?? 'Overwrite Azimuth?'),
            content: Text(
              s?.azimuthOverwriteMessage ??
                  'The azimuth field already has a value. The new calculated value will overwrite the current value. Do you want to continue?',
            ),
            actions: <Widget>[
              TextButton(
                child: Text(s?.buttonCancel ?? 'Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: Text(s?.buttonCalculate ?? 'Calculate'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      // If user cancels, return early
      if (shouldOverwrite != true) {
        return;
      }
    }

    // Proceed with azimuth calculation
    _calculateAzimuth();
  }

  void _calculateAzimuth() {
    final s = S.of(context);
    final currentPoints = context.projectState.currentPoints;
    if (currentPoints.length < 2) {
      showErrorStatus(
        s?.errorAzimuthPointsNotSet ?? 'At least two points are required',
      );
      return;
    }
    final startPoint = currentPoints.first;
    final endPoint = currentPoints.last;
    if (startPoint.id == endPoint.id) {
      showErrorStatus(
        s?.errorAzimuthPointsSame ?? 'Start and end points must be different',
      );
      return;
    }

    double degreesToRadians(double degrees) =>
        degrees * 3.141592653589793 / 180.0;
    double radiansToDegrees(double radians) =>
        radians * 180.0 / 3.141592653589793;
    double calculateBearingFromPoints(PointModel start, PointModel end) {
      final double lat1Rad = degreesToRadians(start.latitude);
      final double lon1Rad = degreesToRadians(start.longitude);
      final double lat2Rad = degreesToRadians(end.latitude);
      final double lon2Rad = degreesToRadians(end.longitude);
      final double dLon = lon2Rad - lon1Rad;
      final double y = math.sin(dLon) * math.cos(lat2Rad);
      final double x =
          math.cos(lat1Rad) * math.sin(lat2Rad) -
          math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);
      double bearingRad = math.atan2(y, x);
      double bearingDeg = radiansToDegrees(bearingRad);
      return (bearingDeg + 360) % 360;
    }

    final double calculatedAzimuth = calculateBearingFromPoints(
      startPoint,
      endPoint,
    );

    setAzimuthFromParent(calculatedAzimuth);
    showSuccessStatus(
      s?.azimuthCalculatedSnackbar(calculatedAzimuth.toStringAsFixed(2)) ??
          'Azimuth calculated: ${calculatedAzimuth.toStringAsFixed(2)}°',
    );
  }

  Widget _buildProjectStats() {
    final currentProject =
        context.projectState.currentProject ?? widget.project;
    final points = context.projectState.currentPoints;
    // Count images from the points in global state
    int totalImages = 0;
    for (final point in points) {
      // Assuming points have an images property or we can get it from global state
      // For now, we'll use a placeholder - you may need to add this to your global state
      totalImages += point.images.length;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.3),
            Theme.of(
              context,
            ).colorScheme.secondaryContainer.withValues(alpha: 0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: false,
        // Start folded
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        title: Row(
          children: [
            Icon(
              Icons.analytics,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                S.of(context)?.project_statistics_title ?? 'Project Statistics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.location_on,
                        title:
                            S.of(context)?.project_statistics_points ??
                            'Points',
                        value: '${points.length}',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.photo,
                        title:
                            S.of(context)?.project_statistics_images ??
                            'Images',
                        value: '$totalImages',
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (currentProject.presumedTotalLength != null)
                  _buildStatCard(
                    icon: Icons.straighten,
                    title:
                        S.of(context)?.formFieldPresumedTotalLengthLabel ??
                        'Presumed Length',
                    value:
                        '${currentProject.presumedTotalLength!.toStringAsFixed(1)} m',
                    color: Theme.of(context).colorScheme.tertiary,
                    fullWidth: true,
                  ),
                if (currentProject.currentRopeLength > 0)
                  _buildStatCard(
                    icon: Icons.calculate,
                    title:
                        S.of(context)?.project_statistics_current_length ??
                        'Current Length',
                    value:
                        '${currentProject.currentRopeLength.toStringAsFixed(1)} m',
                    color: Theme.of(context).colorScheme.primary,
                    fullWidth: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectState = context.projectState;
    // Update dirty state based on global state
    _updateDirtyStateFromGlobalState();

    final s = S.of(context);
    final canCalculate = (projectState.currentProject?.points.length ?? 0) >= 2;

    return Consumer<ProjectStateManager>(
      builder: (context, projectState, child) {
        final project = projectState.currentProject ?? widget.project;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Project Statistics Section
                _buildProjectStats(),
                const SizedBox(height: 20),
                // MERGED: Project Name, Date, and Notes Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        Theme.of(
                          context,
                        ).colorScheme.secondaryContainer.withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Project Name
                      Row(
                        children: [
                          Icon(
                            Icons.folder_open,
                            color: Theme.of(context).colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s?.formFieldNameLabel ?? 'Project Name',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Enter project name...',
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
                        style: Theme.of(context).textTheme.bodyLarge,
                        validator: (value) {
                          // Create temporary project with all current form values
                          final name = value?.trim() ?? '';
                          final note = _noteController.text.trim();
                          final presumed = double.tryParse(
                            _presumedTotalLengthController.text,
                          );
                          final azimuth = double.tryParse(
                            _azimuthController.text,
                          );

                          final tempProject = project.copyWith(
                            name: name,
                            note: note,
                            presumedTotalLength:
                                _presumedTotalLengthController.text
                                    .trim()
                                    .isEmpty
                                ? null
                                : presumed,
                            azimuth: _azimuthController.text.trim().isEmpty
                                ? null
                                : azimuth,
                            date: _projectDate,
                          );

                          if (!tempProject.isValid) {
                            final nameErrors = tempProject.validationErrors
                                .where(
                                  (error) =>
                                      error.contains('name') ||
                                      error.contains('Project name'),
                                )
                                .toList();
                            return nameErrors.isNotEmpty
                                ? nameErrors.first
                                : null;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Project Date
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s?.formFieldProjectDateLabel ?? 'Project Date',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => _selectProjectDate(context),
                        borderRadius: BorderRadius.circular(8.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(
                                context,
                              ).colorScheme.outline.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.event,
                                size: 20,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _projectDate != null
                                      ? DateFormat.yMMMd(
                                          Localizations.localeOf(
                                            context,
                                          ).toString(),
                                        ).format(_projectDate!)
                                      : (s?.tap_to_set_date ??
                                            'Tap to set date'),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: _projectDate != null
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.onSurface
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Notes
                      Row(
                        children: [
                          Icon(
                            Icons.note,
                            color: Theme.of(context).colorScheme.tertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            s?.formFieldNoteLabel ?? 'Notes',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: 'Add project notes...',
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
                          contentPadding: const EdgeInsets.all(16.0),
                        ),
                        maxLines: 4,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Measurements Section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
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
                            Icons.straighten,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            S.of(context)?.project_statistics_measurements ??
                                'Measurements',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Presumed Total Length
                      TextFormField(
                        controller: _presumedTotalLengthController,
                        decoration: InputDecoration(
                          labelText:
                              s?.formFieldPresumedTotalLengthLabel ??
                              'Presumed Total Length (m)',
                          hintText: 'Enter length in meters...',
                          prefixIcon: Icon(
                            Icons.straighten,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
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
                          if (value == null || value.trim().isEmpty) {
                            return null; // Optional field
                          }

                          final presumed = double.tryParse(value.trim());
                          if (presumed == null) {
                            return 'Invalid number format';
                          }

                          // Create temporary project with all current form values
                          final name = _nameController.text.trim();
                          final note = _noteController.text.trim();
                          final azimuth = double.tryParse(
                            _azimuthController.text,
                          );

                          final tempProject = project.copyWith(
                            name: name,
                            note: note,
                            presumedTotalLength: presumed,
                            azimuth: _azimuthController.text.trim().isEmpty
                                ? null
                                : azimuth,
                            date: _projectDate,
                          );

                          if (!tempProject.isValid) {
                            final presumedErrors = tempProject.validationErrors
                                .where(
                                  (error) =>
                                      error.contains('Presumed total length') ||
                                      error.contains('presumed'),
                                )
                                .toList();
                            return presumedErrors.isNotEmpty
                                ? presumedErrors.first
                                : null;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Current Rope Length (calculated from points)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Icon(
                                Icons.calculate,
                                size: 20,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s?.current_rope_length_label ??
                                        'Current Rope Length',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${project.currentRopeLength.toStringAsFixed(2)} ${s?.unit_meter ?? 'm'}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'monospace',
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Azimuth Section
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _azimuthController,
                              decoration: InputDecoration(
                                labelText:
                                    s?.formFieldAzimuthLabel ?? 'Azimuth',
                                hintText: 'Enter azimuth in degrees...',
                                prefixIcon: Icon(
                                  Icons.compass_calibration,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                suffixText: '°',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2.0,
                                  ),
                                ),
                                filled: true,
                                fillColor: Theme.of(
                                  context,
                                ).colorScheme.surface,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                    signed: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null; // Optional field
                                }

                                final azimuth = double.tryParse(value.trim());
                                if (azimuth == null) {
                                  return 'Invalid number format';
                                }

                                // Create temporary project with all current form values
                                final name = _nameController.text.trim();
                                final note = _noteController.text.trim();
                                final presumed = double.tryParse(
                                  _presumedTotalLengthController.text,
                                );

                                final tempProject = project.copyWith(
                                  name: name,
                                  note: note,
                                  presumedTotalLength:
                                      _presumedTotalLengthController.text
                                          .trim()
                                          .isEmpty
                                      ? null
                                      : presumed,
                                  azimuth: azimuth,
                                  date: _projectDate,
                                );

                                if (!tempProject.isValid) {
                                  final azimuthErrors = tempProject
                                      .validationErrors
                                      .where(
                                        (error) =>
                                            error.contains('Azimuth') ||
                                            error.contains('azimuth'),
                                      )
                                      .toList();
                                  return azimuthErrors.isNotEmpty
                                      ? azimuthErrors.first
                                      : null;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: !canCalculate
                                  ? null
                                  : () async {
                                      await _handleAzimuthCalculation();
                                    },
                              icon: const Icon(Icons.calculate, size: 20),
                              label: Text(
                                s?.buttonCalculate ?? 'Calculate',
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onSecondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0,
                                  vertical: 12.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  bool validateForm() {
    // Parse form values
    final name = _nameController.text.trim();
    final note = _noteController.text.trim();
    final presumed = double.tryParse(_presumedTotalLengthController.text);
    final azimuth = double.tryParse(_azimuthController.text);

    // Create a temporary project with current form values
    final tempProject = _currentProject.copyWith(
      name: name,
      note: note,
      presumedTotalLength: _presumedTotalLengthController.text.trim().isEmpty
          ? null
          : presumed,
      azimuth: _azimuthController.text.trim().isEmpty ? null : azimuth,
      date: _projectDate,
    );

    // Use model validation
    return tempProject.isValid;
  }

  void _updateDirtyStateFromGlobalState() {
    final globalHasUnsavedChanges =
        context.projectStateListen.hasUnsavedChanges;
    if (!globalHasUnsavedChanges && _dirty) {
      // Don't call setState during build, just update the variable
      _dirty = false;
      _originalAzimuthValue = _azimuthController.text;
      _azimuthFieldModified = false;
    }
  }

  /// Dismisses the keyboard by unfocusing the current focus node
  void dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }
}
