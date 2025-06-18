import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

import 'db/database_helper.dart'; // For potential updates
import 'db/models/project_model.dart';
import 'logger.dart'; // Your logger

class ProjectDetailsPage extends StatefulWidget {
  final ProjectModel project;

  const ProjectDetailsPage({super.key, required this.project});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  late TextEditingController _nameController;
  late TextEditingController
  _noteController; // Assuming 'note' will be part of ProjectModel
  late TextEditingController _azimuthController;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Local placeholder for notes if not in ProjectModel yet
  String _projectNoteContent = ""; //"""Initial project notes can go here...";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _noteController = TextEditingController(
      text: widget.project.note ?? _projectNoteContent,
    ); // Use project.note if available
    _azimuthController = TextEditingController(
      text: widget.project.azimuth?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _azimuthController.dispose();
    super.dispose();
  }

  Future<void> _saveProjectDetails() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project name cannot be empty.')),
      );
      return;
    }

    widget.project.name = _nameController.text;
    widget.project.note = _noteController.text.isNotEmpty
        ? _noteController.text
        : null; // Save note to model
    widget.project.azimuth = double.tryParse(_azimuthController.text);
    // lastUpdate is handled by dbHelper.updateProject

    try {
      await _dbHelper.updateProject(widget.project);
      logger.info("Project details saved: ${widget.project.name}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Project "${widget.project.name}" updated.')),
      );
      // You might want to pop or refresh previous screen if needed
      // Navigator.pop(context, true); // Indicate success
    } catch (e, stackTrace) {
      logger.severe("Error saving project details", e, stackTrace);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving project: $e')));
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
    // Add navigation or specific actions here
    // e.g., if (toolName == 'Points') Navigator.push(...PointsListPage...);
  }

  void _onSetPoint(String pointType) {
    // pointType: "Start" or "End"
    logger.info("Set $pointType Point button tapped.");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Set $pointType point to be implemented.')),
    );
    // Logic to select a point and update widget.project.startingPointId or endingPointId
    // Then call _saveProjectDetails() or a dedicated save function.
  }

  @override
  Widget build(BuildContext context) {
    String formattedLastUpdate = widget.project.lastUpdate != null
        ? DateFormat('MMM d, yyyy HH:mm:ss').format(widget.project.lastUpdate!)
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
        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
        // Adjust top padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // App Title
            Container(
              padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
              alignment: Alignment.center,
              child: const Text(
                'Teleferika',
                style: TextStyle(
                  fontSize: 30.0, // Slightly smaller if AppBar is present
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Project Tools Card
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

            // TextFields
            _buildTextField(_nameController, "Project Name"),
            const SizedBox(height: 16),
            // Assuming ProjectModel has a 'note' field that is nullable String
            // If not, you need to add it or handle notes differently.
            _buildTextField(_noteController, "Notes", maxLines: 4),
            const SizedBox(height: 16),
            _buildReadOnlyField("Last Updated", formattedLastUpdate),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              // Align items vertically
              children: [
                Expanded(
                  child: _buildTextField(
                    _azimuthController,
                    "Azimuth (°)",
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
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
            const SizedBox(height: 30),

            // Start and End Point Buttons
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
      style: ElevatedButton.styleFrom(
        // textStyle: TextStyle(fontSize: 12), // Smaller text if needed
        // padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    );
  }

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
        ), // Increased padding
      ),
      style: const TextStyle(fontSize: 18.0),
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14.0,
          vertical: 18.0,
        ), // Increased padding
      ),
      child: Text(value, style: const TextStyle(fontSize: 18.0)),
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
        // backgroundColor: Theme.of(context).colorScheme.primary,
        // foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      onPressed: onPressed,
    );
  }
}
