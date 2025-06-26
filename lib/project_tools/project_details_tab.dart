import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../db/models/project_model.dart';
import '../l10n/app_localizations.dart';

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

  const ProjectDetailsTab({
    super.key,
    required this.project,
    required this.isNew,
    required this.projectDate,
    required this.lastUpdateTime,
    required this.onChanged,
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

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _currentProject = widget.project;
    _projectDate = widget.projectDate;
    _lastUpdateTime = widget.lastUpdateTime;
    _nameController = TextEditingController(text: _currentProject.name);
    _noteController = TextEditingController(text: _currentProject.note ?? '');
    _azimuthController = TextEditingController(
      text: _currentProject.azimuth?.toStringAsFixed(2) ?? '',
    );
    _nameController.addListener(_onChanged);
    _noteController.addListener(_onChanged);
    _azimuthController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onChanged);
    _noteController.removeListener(_onChanged);
    _azimuthController.removeListener(_onChanged);
    _nameController.dispose();
    _noteController.dispose();
    _azimuthController.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {
      _hasUnsavedChanges = true;
      _currentProject = _currentProject.copyWith(
        name: _nameController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        azimuth: double.tryParse(_azimuthController.text),
      );
    });
    widget.onChanged(
      _currentProject,
      hasUnsavedChanges: _hasUnsavedChanges,
      projectDate: _projectDate,
      lastUpdateTime: _lastUpdateTime,
    );
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

  void _calculateAzimuth() {
    // This is a placeholder. Actual azimuth calculation should be handled by ProjectPage if needed.
    // Here, we just parse and validate the field.
    final s = S.of(context);
    final value = _azimuthController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s?.formFieldAzimuthLabel ?? 'Azimuth is empty.'),
        ),
      );
      return;
    }
    final num = double.tryParse(value);
    if (num == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s?.invalid_number_validator ?? 'Invalid number.'),
        ),
      );
      return;
    }
    if (num <= -360 || num >= 360) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s?.must_be_359_validator ?? 'Must be +/-359.99'),
        ),
      );
      return;
    }
    // If valid, update the model
    setState(() {
      _currentProject = _currentProject.copyWith(azimuth: num);
      _hasUnsavedChanges = true;
    });
    widget.onChanged(
      _currentProject,
      hasUnsavedChanges: _hasUnsavedChanges,
      projectDate: _projectDate,
      lastUpdateTime: _lastUpdateTime,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s?.azimuthCalculatedSnackbar(num.toStringAsFixed(2)) ??
              'Azimuth calculated.',
        ),
      ),
    );
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
                  child: ElevatedButton(
                    onPressed: _calculateAzimuth,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    child: Text(s?.buttonCalculate ?? 'Calculate'),
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
