import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';

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

class ProjectDetailsTabState extends State<ProjectDetailsTab> {
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
    if (_formKey.currentState?.validate() ?? false) {
      final saved = await context.projectState.saveProject();
      if (saved) {
        setState(() {
          _dirty = false;
          _originalAzimuthValue = _azimuthController.text;
          _azimuthFieldModified = false;
        });
      }
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
      // Show error status - we'll need to implement this
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s?.errorAzimuthPointsNotSet ?? 'At least two points are required',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final startPoint = currentPoints.first;
    final endPoint = currentPoints.last;
    if (startPoint.id == endPoint.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s?.errorAzimuthPointsSame ??
                'Start and end points must be different',
          ),
          backgroundColor: Colors.red,
        ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s?.azimuthCalculatedSnackbar(calculatedAzimuth.toStringAsFixed(2)) ??
              'Azimuth calculated: ${calculatedAzimuth.toStringAsFixed(2)}°',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDirty = _dirty;
    final canCalculate = widget.pointsCount >= 2;
    final azimuthButtonIsSave = _azimuthFieldModified;
    final saveButtonColor = isDirty ? Colors.green : null;
    final azimuthButtonLabel = azimuthButtonIsSave
        ? (s?.buttonSave ?? 'Save')
        : (s?.buttonCalculate ?? 'Calculate');
    final azimuthButtonIcon = azimuthButtonIsSave
        ? Icons.save
        : Icons.calculate;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
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
                if (value == null || value.trim().isEmpty) {
                  return s?.projectNameCannotBeEmptyValidator ??
                      'Project name cannot be empty.';
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
                if (value != null && value.trim().isNotEmpty) {
                  final num = double.tryParse(value.trim());
                  if (num == null) {
                    return s?.invalid_number_validator ?? 'Invalid number.';
                  }
                  if (num < 0) {
                    return s?.must_be_positive_validator ?? 'Must be positive.';
                  }
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
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
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
                      if (value != null && value.trim().isNotEmpty) {
                        final num = double.tryParse(value.trim());
                        if (num == null) {
                          return s?.invalid_number_validator ??
                              'Invalid number.';
                        }
                        if (num <= -360 || num >= 360) {
                          return s?.must_be_359_validator ??
                              'Must be +/-359.99';
                        }
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 140,
                  child: ElevatedButton.icon(
                    onPressed: !canCalculate && !azimuthButtonIsSave
                        ? null
                        : () async {
                            if (azimuthButtonIsSave) {
                              await _handleSave();
                            } else {
                              await _handleAzimuthCalculation();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azimuthButtonIsSave && isDirty
                          ? Colors.green
                          : null,
                    ),
                    icon: Icon(azimuthButtonIcon),
                    label: Text(azimuthButtonLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }
}
