// project_details_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'db/database_helper.dart'; // Ensure correct path
import 'db/models/project_model.dart'; // Ensure correct path
import 'logger.dart';

class ProjectDetailsPage extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailsPage({super.key, required this.project});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  late TextEditingController _azimuthController;

  late DateTime? _projectDate;
  late DateTime? _lastUpdateTime;

  // GlobalKey for the Form
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _noteController = TextEditingController(text: widget.project.note ?? '');
    _azimuthController = TextEditingController(
      text: widget.project.azimuth?.toString() ?? '',
    );
    _projectDate = widget.project.date;
    _lastUpdateTime = widget.project.lastUpdate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _azimuthController.dispose();
    super.dispose();
  }

  Future<void> _saveProjectDetails() async {
    // --- VALIDATE THE FORM ---
    if (!_formKey.currentState!.validate()) {
      // If form is not valid, display errors and stop.
      logger.warning("Form validation failed.");
      return;
    }
    // --- END FORM VALIDATION ---

    // Form is valid, proceed with saving.
    // Azimuth value is already parsed or null if empty by this point via the controller's text.
    // The validator for azimuth ensures it's a valid double if not empty.
    double? azimuthValue;
    if (_azimuthController.text.isNotEmpty) {
      azimuthValue = double.tryParse(_azimuthController.text);
      // Validator should have caught error, but as a fallback:
      if (azimuthValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Internal error: Invalid Azimuth despite validation.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    ProjectModel projectToSave = ProjectModel(
      id: widget.project.id,
      name: _nameController.text,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      azimuth: azimuthValue,
      date: _projectDate,
      startingPointId: widget.project.startingPointId,
      endingPointId: widget.project.endingPointId,
    );

    try {
      int popupDuration = 2;

      if (projectToSave.id == null) {
        // Creating a new project
        final newId = await _dbHelper.insertProject(projectToSave);
        // projectToSave.id will still be null here, newId is the actual ID.
        // projectToSave.lastUpdate might be set by dbHelper.insertProject
        logger.info(
          "New project created with ID: $newId and Name: ${projectToSave.name}",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${projectToSave.name}" created.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: popupDuration),
          ),
        );
        await Future.delayed(Duration(seconds: popupDuration));
        Navigator.pop(context, true); // Pop with true for new project creation
      } else {
        // Updating an existing project
        await _dbHelper.updateProject(projectToSave);
        // projectToSave.lastUpdate should be updated by dbHelper.updateProject
        setState(() {
          _lastUpdateTime = projectToSave.lastUpdate;
          widget.project.name = projectToSave.name;
          widget.project.note = projectToSave.note;
          widget.project.azimuth = projectToSave.azimuth;
          widget.project.date = projectToSave.date;
          widget.project.lastUpdate = projectToSave.lastUpdate;
        });
        logger.info("Project details updated: ${projectToSave.name}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${projectToSave.name}" updated.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: popupDuration),
          ),
        );
        // await Future.delayed(Duration(seconds: popupDuration)); // Optional delay before pop
        Navigator.pop(context, {
          'modified': true,
          'id': projectToSave.id,
        }); // Pop with modification details
      }
    } catch (e, stackTrace) {
      logger.severe("Error saving project details", e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        logger.info("New Project Date selected: $_projectDate");
      });
    }
  }

  void _calculateAzimuth() {
    logger.info("Calculate Azimuth button tapped.");
    // This button's function might change or be removed if validation is purely inline.
    // Or it could be used for a more complex calculation that populates the field.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Azimuth calculation to be implemented.')),
    );
  }

  void _onToolsButtonPressed(String toolName) {
    logger.info("$toolName button tapped.");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$toolName functionality to be implemented.')),
    );
  }

  void _onSetPoint(String pointType) {
    logger.info("Set $pointType Point button tapped.");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Set $pointType point to be implemented.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedProjectDate = _projectDate != null
        ? DateFormat('MMM d, yyyy').format(_projectDate!)
        : 'Tap to set date';

    String formattedLastUpdate = _lastUpdateTime != null
        ? DateFormat('MMM d, yyyy HH:mm:ss').format(_lastUpdateTime!)
        : 'Not yet saved';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.project.name.isNotEmpty && _nameController.text.isNotEmpty
              ? _nameController
                    .text // Use controller text for potentially unsaved name
              : (widget.project.name.isNotEmpty
                    ? widget.project.name
                    : "Project Details"),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Project',
            onPressed:
                _saveProjectDetails, // This will now trigger form validation first
          ),
        ],
      ),
      // --- WRAP MAIN CONTENT WITH FORM ---
      body: Form(
        key: _formKey, // Assign the key to the Form
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
                alignment: Alignment.center,
                child: const Text(
                  'Teleferika',
                  style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
                ),
              ),
              Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 10.0),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Project Tools",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          _toolButton(
                            Icons.explore_outlined,
                            'Compass',
                            () => _onToolsButtonPressed('Compass'),
                          ),
                          _toolButton(
                            Icons.list_alt_outlined,
                            'Points',
                            () => _onToolsButtonPressed('Points'),
                          ),
                          _toolButton(
                            Icons.map_outlined,
                            'Map',
                            () => _onToolsButtonPressed('Map'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- MODIFIED Project Name to TextFormField ---
              _buildTextFormField(
                controller: _nameController,
                label: "Project Name",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Project name cannot be empty.';
                  }
                  return null; // Return null if valid
                },
              ),
              const SizedBox(height: 16),

              InputDecorator(
                decoration: const InputDecoration(
                  labelText: "Project Date",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 1.0,
                    vertical: 1.0,
                  ),
                ),
                child: ListTile(
                  title: Text(
                    formattedProjectDate,
                    style: const TextStyle(fontSize: 18.0),
                  ),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () => _selectProjectDate(context),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Note field can remain TextField if no specific validation needed, or convert to TextFormField
              _buildTextField(_noteController, "Notes", maxLines: 4),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Align to start for validator message
                children: [
                  Expanded(
                    // --- MODIFIED Azimuth to TextFormField ---
                    child: _buildTextFormField(
                      controller: _azimuthController,
                      label: "Azimuth (°)",
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (double.tryParse(value) == null) {
                            return 'Invalid number format.';
                          }
                        }
                        return null; // Return null if valid or empty
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Calculate button might be less critical if direct input is validated
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    // Align with text field
                    child: ElevatedButton(
                      onPressed: _calculateAzimuth,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      child: const Text("Calculate"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildReadOnlyField(
                "Last Updated",
                formattedLastUpdate,
                textStyle: const TextStyle(fontSize: 13.0, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _majorActionButton(
                      Icons.flag_outlined,
                      'SET START',
                      () => _onSetPoint("Start"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _majorActionButton(
                      Icons.sports_score_outlined,
                      'SET END',
                      () => _onSetPoint("End"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onPressed,
    );
  }

  // Original _buildTextField for fields without form validation (like Notes)
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14.0,
          vertical: 18.0,
        ),
      ),
      style: const TextStyle(fontSize: 18.0),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  // --- New _buildTextFormField helper ---
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14.0,
          vertical: 18.0,
        ),
      ),
      style: const TextStyle(fontSize: 18.0),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: autovalidateMode, // Show errors as user interacts
    );
  }

  Widget _buildReadOnlyField(
    String label,
    String value, {
    TextStyle? textStyle,
    EdgeInsetsGeometry? contentPadding,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 14.0, vertical: 18.0),
      ),
      child: Text(value, style: textStyle ?? const TextStyle(fontSize: 18.0)),
    );
  }

  Widget _majorActionButton(
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        textStyle: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
      ),
      onPressed: onPressed,
    );
  }
}
