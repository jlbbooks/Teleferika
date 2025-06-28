import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';

class ProjectDetailsTab extends StatefulWidget {
  final ProjectModel project;
  final bool isNew;
  final int pointsCount;
  final void Function(ProjectModel updated, {bool hasUnsavedChanges}) onChanged;
  final Future<bool?> Function(ProjectModel updated)? onSaveProject;
  final void Function()? onCalculateAzimuth;

  const ProjectDetailsTab({
    super.key,
    required this.project,
    required this.isNew,
    required this.pointsCount,
    required this.onChanged,
    this.onSaveProject,
    this.onCalculateAzimuth,
  });

  @override
  State<ProjectDetailsTab> createState() => ProjectDetailsTabState();
}

class ProjectDetailsTabState extends State<ProjectDetailsTab> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  late TextEditingController _presumedTotalLengthController;
  late TextEditingController _azimuthController;
  late DateTime? _projectDate;
  late ProjectModel _currentProject;
  bool _dirty = false;
  bool _azimuthFieldModified = false;
  String? _originalAzimuthValue;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;
    _projectDate = widget.project.date;
    _nameController = TextEditingController(text: _currentProject.name);
    _noteController = TextEditingController(text: _currentProject.note ?? '');
    _presumedTotalLengthController = TextEditingController(
      text: _currentProject.presumedTotalLength?.toStringAsFixed(2) ?? '',
    );
    _azimuthController = TextEditingController(
      text: _currentProject.azimuth?.toStringAsFixed(2) ?? '',
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
        note != (widget.project.note ?? '') ||
        presumed != widget.project.presumedTotalLength ||
        azimuth != widget.project.azimuth ||
        _projectDate != widget.project.date;
    setState(() {
      _dirty = dirty;
      _currentProject = _currentProject.copyWith(
        name: name,
        note: note.isEmpty ? null : note,
        presumedTotalLength: _presumedTotalLengthController.text.trim().isEmpty
            ? null
            : presumed,
        azimuth: _azimuthController.text.trim().isEmpty ? null : azimuth,
        date: _projectDate,
      );
    });
    widget.onChanged(_currentProject, hasUnsavedChanges: _dirty);
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
      if (widget.onSaveProject != null) {
        final saved = await widget.onSaveProject!(_currentProject);
        if (saved == true) {
          setState(() {
            _dirty = false;
            _originalAzimuthValue = _azimuthController.text;
            _azimuthFieldModified = false;
          });
        }
      }
    }
  }

  void setAzimuthFromParent(double value) {
    _azimuthController.text = value.toStringAsFixed(2);
    _originalAzimuthValue = _azimuthController.text;
    _azimuthFieldModified = true;
    _onChanged();
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
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_currentProject.currentRopeLength.toStringAsFixed(2)} m',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                            } else if (widget.onCalculateAzimuth != null) {
                              widget.onCalculateAzimuth!();
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
