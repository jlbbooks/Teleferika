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

class ProjectDetailsTab extends StatefulWidget {
  final ProjectModel project;
  final bool isNew;
  final int pointsCount;

  const ProjectDetailsTab({
    super.key,
    required this.project,
    required this.isNew,
    required this.pointsCount,
  });

  @override
  State<ProjectDetailsTab> createState() => ProjectDetailsTabState();
}

class ProjectDetailsTabState extends State<ProjectDetailsTab> with StatusMixin {
  final Logger logger = Logger('ProjectDetailsTab');
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
    _noteController = TextEditingController(text: widget.project.note ?? '');
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
    context.projectState.updateEditingProject(
      _currentProject,
      hasUnsavedChanges: _dirty,
    );
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

  Future<void> _handleSave() async {
    // Parse form values
    final name = _nameController.text.trim();
    final note = _noteController.text.trim();
    final presumed = double.tryParse(_presumedTotalLengthController.text);
    final azimuth = double.tryParse(_azimuthController.text);

    // Create the project to validate
    final projectToSave = _currentProject.copyWith(
      name: name,
      note: note,
      presumedTotalLength: _presumedTotalLengthController.text.trim().isEmpty
          ? null
          : presumed,
      azimuth: _azimuthController.text.trim().isEmpty ? null : azimuth,
      date: _projectDate,
    );

    // Use model validation
    if (!projectToSave.isValid) {
      showErrorStatus(
        'Validation errors: ${projectToSave.validationErrors.join(', ')}',
      );
      return;
    }

    // Additional validation for parsing errors
    if (_presumedTotalLengthController.text.isNotEmpty && presumed == null) {
      showErrorStatus(
        'Invalid presumed total length format. Please enter a valid number.',
      );
      return;
    }

    if (_azimuthController.text.isNotEmpty && azimuth == null) {
      showErrorStatus('Invalid azimuth format. Please enter a valid number.');
      return;
    }

    final saved = await context.projectState.saveProject();
    if (saved) {
      setState(() {
        _dirty = false;
        _originalAzimuthValue = _azimuthController.text;
        _azimuthFieldModified = false;
      });

      showSuccessStatus('Project saved successfully!');
    } else {
      showErrorStatus('Error saving project.');
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

    double _degreesToRadians(double degrees) =>
        degrees * 3.141592653589793 / 180.0;
    double _radiansToDegrees(double radians) =>
        radians * 180.0 / 3.141592653589793;
    double calculateBearingFromPoints(PointModel start, PointModel end) {
      final double lat1Rad = _degreesToRadians(start.latitude);
      final double lon1Rad = _degreesToRadians(start.longitude);
      final double lat2Rad = _degreesToRadians(end.latitude);
      final double lon2Rad = _degreesToRadians(end.longitude);
      final double dLon = lon2Rad - lon1Rad;
      final double y = math.sin(dLon) * math.cos(lat2Rad);
      final double x =
          math.cos(lat1Rad) * math.sin(lat2Rad) -
          math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);
      double bearingRad = math.atan2(y, x);
      double bearingDeg = _radiansToDegrees(bearingRad);
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectStateManager>(
      builder: (context, projectState, child) {
        // Update dirty state based on global state
        _updateDirtyStateFromGlobalState();

        final s = S.of(context);
        final isDirty = _dirty;
        final canCalculate = widget.pointsCount >= 2;
        final saveButtonColor = isDirty ? Colors.green : null;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: s?.formFieldNameLabel ?? 'Project Name',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    // Create temporary project with all current form values
                    final name = value?.trim() ?? '';
                    final note = _noteController.text.trim();
                    final presumed = double.tryParse(
                      _presumedTotalLengthController.text,
                    );
                    final azimuth = double.tryParse(_azimuthController.text);

                    final tempProject = _currentProject.copyWith(
                      name: name,
                      note: note,
                      presumedTotalLength:
                          _presumedTotalLengthController.text.trim().isEmpty
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
                      return nameErrors.isNotEmpty ? nameErrors.first : null;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectProjectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: s?.formFieldProjectDateLabel ?? 'Project Date',
                      border: const OutlineInputBorder(),
                    ),
                    child: Text(
                      _projectDate != null
                          ? DateFormat.yMMMd(
                              Localizations.localeOf(context).toString(),
                            ).format(_projectDate!)
                          : (s?.tap_to_set_date ?? 'Tap to set date'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: s?.formFieldNoteLabel ?? 'Notes',
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _presumedTotalLengthController,
                  decoration: InputDecoration(
                    labelText:
                        s?.formFieldPresumedTotalLengthLabel ??
                        'Presumed Total Length (m)',
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return null; // Optional field

                    final presumed = double.tryParse(value.trim());
                    if (presumed == null) {
                      return 'Invalid number format';
                    }

                    // Create temporary project with all current form values
                    final name = _nameController.text.trim();
                    final note = _noteController.text.trim();
                    final azimuth = double.tryParse(_azimuthController.text);

                    final tempProject = _currentProject.copyWith(
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
                const SizedBox(height: 8),
                // Current rope length (calculated from points)
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.straighten,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
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
                              '${_currentProject.currentRopeLength.toStringAsFixed(2)} m',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _azimuthController,
                        decoration: InputDecoration(
                          labelText: s?.formFieldAzimuthLabel ?? 'Azimuth',
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                          signed: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return null; // Optional field

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

                          final tempProject = _currentProject.copyWith(
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
                            final azimuthErrors = tempProject.validationErrors
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
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 140,
                      child: ElevatedButton.icon(
                        onPressed: !canCalculate
                            ? null
                            : () async {
                                await _handleAzimuthCalculation();
                              },
                        icon: const Icon(Icons.calculate),
                        label: Text(s?.buttonCalculate ?? 'Calculate'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
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
}
