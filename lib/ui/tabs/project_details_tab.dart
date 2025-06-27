import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class ProjectDetailsTab extends StatefulWidget {
  final ProjectModel project;
  final bool isNew;
  final DateTime? projectDate;
  final DateTime? lastUpdateTime;
  final void Function(
    ProjectModel updatedProject, {
    bool hasUnsavedChanges,
    DateTime? projectDate,
    DateTime? lastUpdateTime,
  })
  onChanged;
  final Future<bool?> Function()? onSaveProject;

  const ProjectDetailsTab({
    super.key,
    required this.project,
    required this.isNew,
    required this.projectDate,
    required this.lastUpdateTime,
    required this.onChanged,
    this.onSaveProject,
  });

  @override
  State<ProjectDetailsTab> createState() => ProjectDetailsTabState();
}

class ProjectDetailsTabState extends State<ProjectDetailsTab> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  late TextEditingController _azimuthController;
  late DateTime? _projectDate;
  late DateTime? _lastUpdateTime;
  late ProjectModel _currentProject;
  bool _hasUnsavedChanges = false;
  bool _azimuthFieldModified = false;
  String? _originalAzimuthValue;
  bool _isUpdatingFromParent = false;

  // Store original values to detect actual changes
  String _originalName = '';
  String _originalNote = '';
  double? _originalAzimuth;
  DateTime? _originalDate;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;
    _projectDate = widget.projectDate;
    _lastUpdateTime = widget.lastUpdateTime;

    // Store original values
    _originalName = _currentProject.name;
    _originalNote = _currentProject.note ?? '';
    _originalAzimuth = _currentProject.azimuth;
    _originalDate = _currentProject.date;

    _nameController = TextEditingController(text: _currentProject.name);
    _noteController = TextEditingController(text: _currentProject.note ?? '');
    _azimuthController = TextEditingController(
      text: _currentProject.azimuth?.toStringAsFixed(2) ?? '',
    );
    _originalAzimuthValue = _azimuthController.text;
    _nameController.addListener(_onChanged);
    _noteController.addListener(_onChanged);
    _azimuthController.addListener(_onAzimuthChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onChanged);
    _noteController.removeListener(_onChanged);
    _azimuthController.removeListener(_onAzimuthChanged);
    _nameController.dispose();
    _noteController.dispose();
    _azimuthController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProjectDetailsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controllers if project data changed externally
    if (widget.project != oldWidget.project) {
      _currentProject = widget.project;
      _nameController.text = _currentProject.name;
      _noteController.text = _currentProject.note ?? '';

      // Only update azimuth field if the actual azimuth value changed (not just widget update)
      final newAzimuthValue = _currentProject.azimuth?.toStringAsFixed(2) ?? '';
      final currentFieldValue = _azimuthController.text;

      // Only update if the actual azimuth value is different from what's in the field
      // AND the field hasn't been manually modified by the user
      if (newAzimuthValue != currentFieldValue && !_azimuthFieldModified) {
        // Temporarily remove listener to prevent circular updates
        _azimuthController.removeListener(_onAzimuthChanged);
        _isUpdatingFromParent = true;

        _azimuthController.text = newAzimuthValue;
        _originalAzimuthValue = newAzimuthValue;
        _azimuthFieldModified = false;

        // Re-add listener after update
        _isUpdatingFromParent = false;
        _azimuthController.addListener(_onAzimuthChanged);
      }

      // Reset unsaved changes flag when project is updated from parent (e.g., after save)
      // This indicates the project was saved externally
      if (_hasUnsavedChanges) {
        setState(() {
          _hasUnsavedChanges = false;
          // Also reset the azimuth field modified flag when project is saved externally
          _azimuthFieldModified = false;
          _originalAzimuthValue = _azimuthController.text;
        });
      }

      // Update original values to reflect the new "saved" state
      // This prevents the form from thinking it's modified when fields are interacted with
      _originalName = _currentProject.name;
      _originalNote = _currentProject.note ?? '';
      _originalAzimuth = _currentProject.azimuth;
      _originalDate = _currentProject.date;
    }
  }

  void _onChanged() {
    if (_isUpdatingFromParent) return; // Skip if updating from parent

    // Check if any actual content has changed
    final currentName = _nameController.text.trim();
    final currentNote = _noteController.text.trim();
    final currentAzimuth = double.tryParse(_azimuthController.text);

    bool hasContentChanged =
        currentName != _originalName ||
        currentNote != _originalNote ||
        currentAzimuth != _originalAzimuth ||
        _projectDate != _originalDate;

    if (hasContentChanged) {
      setState(() {
        _hasUnsavedChanges = true;
        _currentProject = _currentProject.copyWith(
          name: currentName,
          note: currentNote.isEmpty ? null : currentNote,
          azimuth: currentAzimuth,
        );
      });

      // Use WidgetsBinding.instance.addPostFrameCallback to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChanged(
            _currentProject,
            hasUnsavedChanges: _hasUnsavedChanges,
            projectDate: _projectDate,
            lastUpdateTime: _lastUpdateTime,
          );
        }
      });
    }
  }

  void _onAzimuthChanged() {
    if (_isUpdatingFromParent) return; // Skip if updating from parent

    // Check if user manually modified the azimuth field
    final currentValue = _azimuthController.text;
    final isModified = currentValue != _originalAzimuthValue;

    if (_azimuthFieldModified != isModified) {
      setState(() {
        _azimuthFieldModified = isModified;
      });
    }

    // Also call the regular change handler
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
        _hasUnsavedChanges = true;
      });
      _currentProject = _currentProject.copyWith(date: pickedDate);
      widget.onChanged(
        _currentProject,
        hasUnsavedChanges: _hasUnsavedChanges,
        projectDate: _projectDate,
        lastUpdateTime: _lastUpdateTime,
      );
    }
  }

  void _calculateAzimuth() async {
    final s = S.of(context);
    if (_currentProject.points.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s?.errorAzimuthPointsNotSet ?? 'At least two points are required.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final startPoint = _currentProject.points.first;
    final endPoint = _currentProject.points.last;
    if (startPoint.id == endPoint.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            s?.errorAzimuthPointsSame ??
                'Start and end points must be different.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    // Calculate azimuth
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
      final double y = Math.sin(dLon) * Math.cos(lat2Rad);
      final double x =
          Math.cos(lat1Rad) * Math.sin(lat2Rad) -
          Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(dLon);
      double bearingRad = Math.atan2(y, x);
      double bearingDeg = _radiansToDegrees(bearingRad);
      return (bearingDeg + 360) % 360;
    }

    final double calculatedAzimuth = calculateBearingFromPoints(
      startPoint,
      endPoint,
    );
    // Update local state and mark as dirty
    setState(() {
      _azimuthController.text = calculatedAzimuth.toStringAsFixed(2);
      _azimuthFieldModified = true;
      _hasUnsavedChanges = true;
      _currentProject = _currentProject.copyWith(azimuth: calculatedAzimuth);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s?.azimuthCalculatedSnackbar(calculatedAzimuth.toStringAsFixed(2)) ??
              'Azimuth calculated.',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveAzimuth() async {
    if (widget.onSaveProject != null) {
      // Push the latest form state to the parent before saving
      widget.onChanged(
        _currentProject,
        hasUnsavedChanges: false,
        projectDate: _projectDate,
        lastUpdateTime: _lastUpdateTime,
      );

      // Immediately reset the button state to Calculate
      setState(() {
        _azimuthFieldModified = false;
        _originalAzimuthValue = _azimuthController.text;
      });

      final saved = await widget.onSaveProject!();

      final s = S.of(context);
      if (saved == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s?.azimuthSavedSnackbar ?? 'Azimuth saved.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // If save failed, show error but don't change button state back to Save
        // The button should remain as Calculate since the user already clicked Save
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              s?.error_saving_project('') ?? 'Error saving project.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateAzimuthField(String value) {
    _azimuthController.text = value;
    _originalAzimuthValue = value;
    _azimuthFieldModified = false;
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
    bool readOnly = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: suffixIcon,
        ),
        style: const TextStyle(fontSize: 18.0),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        autovalidateMode: autovalidateMode,
        readOnly: readOnly,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    String formattedProjectDate = _projectDate != null
        ? DateFormat.yMMMd(
            Localizations.localeOf(context).toString(),
          ).format(_projectDate!)
        : s?.tap_to_set_date ?? 'Tap to set date';
    String formattedLastUpdate = _lastUpdateTime != null
        ? DateFormat.yMMMd(
            Localizations.localeOf(context).toString(),
          ).add_Hm().format(_lastUpdateTime!)
        : s?.not_yet_saved_label ?? 'Not yet saved';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildTextFormField(
              controller: _nameController,
              label: s?.formFieldNameLabel ?? 'Project Name',
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
                child: Text(formattedProjectDate),
              ),
            ),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: _noteController,
              label: s?.formFieldNoteLabel ?? 'Note',
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: _azimuthController,
                    label: s?.formFieldAzimuthLabel ?? 'Azimuth',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final num = double.tryParse(value.trim());
                        if (num == null)
                          return s?.invalid_number_validator ??
                              'Invalid number.';
                        if (num <= -360 || num >= 360)
                          return s?.must_be_359_validator ??
                              'Must be +/-359.99';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: 120, // Fixed width for consistent button size
                    child: ElevatedButton(
                      onPressed: _currentProject.points.length < 2
                          ? null
                          : (_azimuthFieldModified
                                ? _saveAzimuth
                                : _calculateAzimuth),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        backgroundColor: _azimuthFieldModified
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        foregroundColor: _azimuthFieldModified
                            ? Theme.of(context).colorScheme.onPrimary
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _currentProject.points.length < 2
                                ? Icons.calculate_outlined
                                : (_azimuthFieldModified
                                      ? Icons.save
                                      : Icons.calculate),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _currentProject.points.length < 2
                                ? (s?.buttonCalculate ?? 'Calculate')
                                : (_azimuthFieldModified
                                      ? (s?.buttonSave ?? 'Save')
                                      : (s?.buttonCalculate ?? 'Calculate')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (!widget.isNew && _lastUpdateTime != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  s?.last_updated_label(formattedLastUpdate) ??
                      'Last updated: $formattedLastUpdate',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
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
