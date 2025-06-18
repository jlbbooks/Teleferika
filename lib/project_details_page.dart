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

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // For potential form validation

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
    // --- AZIMUTH VALIDATION ---
    final String azimuthText = _azimuthController.text;
    double? azimuthValue;
    if (azimuthText.isNotEmpty) {
      azimuthValue = double.tryParse(azimuthText);
      if (azimuthValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Invalid Azimuth value. Please enter a valid number.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return; // Prevent saving
      }
    }
    // --- END AZIMUTH VALIDATION ---

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project name cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Create a new ProjectModel instance or update the existing one's modifiable fields.
    // We don't modify widget.project.id directly.
    ProjectModel projectToSave = ProjectModel(
      id: widget.project.id,
      // Keep existing ID if it's an update
      name: _nameController.text,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      azimuth: azimuthValue,
      date: _projectDate,
      // lastUpdate will be set by the database helper method or here before saving
      // For consistency with how updateProject likely works in dbHelper,
      // let dbHelper handle setting lastUpdate.
      // If you need to set it explicitly for insert:
      // lastUpdate: widget.project.id == null ? DateTime.now() : widget.project.lastUpdate,
      // Copy other potentially final fields if any (though typically only id is final and db assigned)
      startingPointId: widget.project.startingPointId,
      endingPointId: widget.project.endingPointId,
    );

    try {
      int popupDuration = 2;
      if (projectToSave.id == null) {
        // This is a new project, insert it
        // The insertProject method in dbHelper should set lastUpdate.
        // If project.date is null here, it will be saved as null.
        final newId = await _dbHelper.insertProject(projectToSave);
        // Now, update the state of the page to reflect that this project
        // is no longer "new" and has an ID and a lastUpdate time from the DB.
        setState(() {
          // We can't change widget.project.id.
          // Instead, we update our local state and potentially the name in AppBar.
          // For the list page to get the full new project, it's better to pop with success
          // and have the list page re-fetch or use a more robust state management.
          // For now, update what's displayed on this page:
          _lastUpdateTime =
              projectToSave.lastUpdate ??
              DateTime.now(); // Estimate if not returned by insert
          // If the title of the page depends on widget.project.name, it's already using _nameController.text
        });
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
        // Pop with true to indicate success to the calling page (ProjectsListPage)
        await Future.delayed(Duration(seconds: popupDuration));
        Navigator.pop(context, true);
      } else {
        // Existing project, update it
        await _dbHelper.updateProject(projectToSave);
        // projectToSave will have its lastUpdate field updated by dbHelper.updateProject
        setState(() {
          _lastUpdateTime = projectToSave.lastUpdate;
          // Also update widget.project if other non-final fields were modified by the DB (unlikely for update)
          widget.project.name = projectToSave.name;
          widget.project.note = projectToSave.note;
          widget.project.azimuth = projectToSave.azimuth;
          widget.project.date = projectToSave.date;
          widget.project.lastUpdate = projectToSave.lastUpdate;
        });
        logger.info(
          "Project details saved: ${projectToSave.name}, Last Update: ${projectToSave.lastUpdate}",
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Project "${projectToSave.name}" updated.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: popupDuration),
          ),
        );
        // You might want to pop or refresh previous screen if needed
        await Future.delayed(Duration(seconds: popupDuration));
        Navigator.pop(context, true); // Indicate success
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
          widget.project.name.isNotEmpty
              ? widget.project.name
              : "Project Details",
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Project',
            onPressed: _saveProjectDetails,
          ),
        ],
      ),
      body: SingleChildScrollView(
        // Wrap with Form if you want to use TextFormField's validator property
        // key: _formKey,
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
            _buildTextField(_nameController, "Project Name"),
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
            _buildTextField(_noteController, "Notes", maxLines: 4),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildTextField(
                    // Or TextFormField for built-in validation
                    _azimuthController,
                    "Azimuth (°)",
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    // validator: (value) { // Example if using TextFormField
                    //   if (value != null && value.isNotEmpty) {
                    //     if (double.tryParse(value) == null) {
                    //       return 'Invalid number';
                    //     }
                    //   }
                    //   return null;
                    // },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _calculateAzimuth,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                  child: const Text("Calculate"),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- MODIFIED Last Updated Display ---
            _buildReadOnlyField(
              "Last Updated",
              formattedLastUpdate,
              textStyle: const TextStyle(
                fontSize: 13.0,
                color: Colors.grey,
              ), // Smaller and grey
              // You could also reduce padding if needed:
              // contentPadding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            ),

            // --- END MODIFICATION ---
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
    );
  }

  Widget _toolButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 20),
      label: Text(label),
      onPressed: onPressed,
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
    // String? Function(String?)? validator, // Add if using TextFormField
  }) {
    // If using TextFormField for validation:
    // return TextFormField(
    //   controller: controller,
    //   decoration: InputDecoration( /* ... */ ),
    //   style: const TextStyle(fontSize: 18.0),
    //   maxLines: maxLines,
    //   keyboardType: keyboardType,
    //   validator: validator,
    //   autovalidateMode: AutovalidateMode.onUserInteraction, // Optional
    // );
    return TextField(
      // Current implementation
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

  // --- MODIFIED _buildReadOnlyField to accept style and padding ---
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
            contentPadding ?? // Use provided padding or default
            const EdgeInsets.symmetric(horizontal: 14.0, vertical: 18.0),
      ),
      child: Text(
        value,
        style:
            textStyle ??
            const TextStyle(fontSize: 18.0), // Use provided style or default
      ),
    );
  }

  // --- END MODIFICATION ---

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
