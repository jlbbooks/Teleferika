// project_details_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teleferika/points_tool_view.dart';

import 'compass_tool_view.dart';
import 'db/database_helper.dart'; // Ensure correct path
import 'db/models/project_model.dart'; // Ensure correct path
import 'logger.dart';
import 'map_tool_view.dart';

// At the top of project_details_page.dart, or in a separate file
enum ActiveCardTool { compass, points, map }

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

  ActiveCardTool? _activeCardTool; // To track the currently active Card button

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

  void _toggleActiveCardTool(ActiveCardTool tool) {
    setState(() {
      if (_activeCardTool == tool) {
        _activeCardTool = null; // Deactivate if already active
      } else {
        _activeCardTool = tool; // Activate the new tool
      }
      logger.info("Active Card tool toggled to: $_activeCardTool");
    });
  }

  Future<void> _saveProjectDetails() async {
    // TODO: IMPORTANT: If a card tool is active, the form is not visible.
    // Saving might not make sense or should save only what's always visible (if anything).
    // For now, let's assume save is primarily for the main form.
    if (_activeCardTool != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Close the active tool to modify project details.'),
        ),
      );
      return; // Prevent saving if a tool is active and form is hidden
    }

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
      int popupDuration = 1;

      if (projectToSave.id == null) {
        // Creating a new project
        final newId = await _dbHelper.insertProject(projectToSave);
        logger.info(
          "New project created with ID: $newId and Name: ${projectToSave.name}",
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Project "${projectToSave.name}" created.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: popupDuration),
            ),
          );
        }
        await Future.delayed(Duration(seconds: popupDuration));
        // Pop with details for the new project
        if (mounted) {
          Navigator.pop(context, {
            'modified': true,
            'id': newId,
            'isNew': true,
          });
        }
      } else {
        await _dbHelper.updateProject(projectToSave);
        setState(() {
          _lastUpdateTime = projectToSave.lastUpdate;
          widget.project.name = projectToSave.name;
          widget.project.note = projectToSave.note;
          widget.project.azimuth = projectToSave.azimuth;
          widget.project.date = projectToSave.date;
          widget.project.lastUpdate = projectToSave.lastUpdate;
        });
        logger.info("Project details updated: ${projectToSave.name}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Project "${projectToSave.name}" updated.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: popupDuration),
            ),
          );
        }
        // await Future.delayed(Duration(seconds: popupDuration)); // Optional delay
        if (mounted) {
          Navigator.pop(context, {'modified': true, 'id': projectToSave.id});
        }
      }
    } catch (e, stackTrace) {
      logger.severe("Error saving project details", e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving project: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  void _onSetPoint(String pointType) {
    logger.info("Set $pointType Point button tapped.");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Set $pointType point to be implemented.')),
    );
  }

  AppBar _appBar() {
    return AppBar(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedProjectDate;
    if (_projectDate != null) {
      // Use a common, locale-aware skeleton.
      // yMMMd() is a good general purpose format (e.g., "Sep 10, 2023" or "10 Sep 2023")
      // You can explore other skeletons like:
      // DateFormat.yMd(Localizations.localeOf(context).toString()).format(_projectDate!)
      // DateFormat.yMEd(Localizations.localeOf(context).toString()).format(_projectDate!) // Includes day of week
      // DateFormat.MMMMEEEEd(Localizations.localeOf(context).toString()).format(_projectDate!) // Very verbose

      // Get the current locale from the context
      final locale = Localizations.localeOf(context).toString();
      formattedProjectDate = DateFormat.yMMMd(locale).format(_projectDate!);
    } else {
      formattedProjectDate = 'Tap to set date';
    }
    String formattedLastUpdate = _lastUpdateTime != null
        ? DateFormat.yMMMd(
            Localizations.localeOf(context).toString(),
          ).add_Hm().format(_lastUpdateTime!) // Also localize time
        : 'Not yet saved';

    bool isMainFormVisible = _activeCardTool == null;

    return Scaffold(
      appBar: _appBar(),
      // --- WRAP MAIN CONTENT WITH FORM ---
      body: Form(
        key: _formKey, // Assign the key to the Form
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
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
                      LayoutBuilder(
                        builder:
                            (BuildContext context, BoxConstraints constraints) {
                              // Define a threshold for switching layout
                              // You might need to adjust this value based on testing
                              const double narrowLayoutThreshold =
                                  350.0; // e.g., for total width of 3 buttons
                              const double buttonSpacing =
                                  8.0; // spacing between buttons

                              bool useVerticalLayout =
                                  constraints.maxWidth < narrowLayoutThreshold;

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  _buildCardToolButton(
                                    tool: ActiveCardTool.compass,
                                    icon: Icons.explore_outlined,
                                    label: 'Compass',
                                    useVerticalLayout:
                                        useVerticalLayout, // Pass the flag
                                  ),
                                  if (useVerticalLayout)
                                    const SizedBox(width: buttonSpacing),
                                  _buildCardToolButton(
                                    tool: ActiveCardTool.points,
                                    icon: Icons.list_alt_outlined,
                                    label: 'Points',
                                    useVerticalLayout:
                                        useVerticalLayout, // Pass the flag
                                  ),
                                  if (useVerticalLayout)
                                    const SizedBox(width: buttonSpacing),
                                  _buildCardToolButton(
                                    tool: ActiveCardTool.map,
                                    icon: Icons.map_outlined,
                                    label: 'Map',
                                    useVerticalLayout:
                                        useVerticalLayout, // Pass the flag
                                  ),
                                ],
                              );
                            },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Conditional Main Form Area ---
              if (isMainFormVisible)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextFormField(
                      controller: _nameController,
                      label: "Project Name",
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Project name cannot be empty.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: "Project Date",
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 11.0,
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
                          horizontal: 0,
                          vertical: 5.0,
                        ),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(_noteController, "Notes", maxLines: 4),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
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
                            child: const Text("Calculate"),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildReadOnlyField(
                      "Last Updated",
                      formattedLastUpdate,
                      textStyle: const TextStyle(
                        fontSize: 13.0,
                        color: Colors.grey,
                      ),
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
                )
              else // Show placeholder if a card tool is active
                _buildActiveToolView(), // Call helper to display the active tool's widget
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper to build toggleable Card Tool Buttons ---
  Widget _buildCardToolButton({
    required ActiveCardTool tool,
    required IconData icon,
    required String label,
    required bool useVerticalLayout, // New parameter
  }) {
    bool isActive = _activeCardTool == tool;
    final Color? activeForegroundColor = isActive
        ? Theme.of(context).colorScheme.onPrimary
        : null;
    final Color? activeBackgroundColor = isActive
        ? Theme.of(context).colorScheme.primary
        : null;
    final ButtonStyle activeStyle = ElevatedButton.styleFrom(
      foregroundColor: activeForegroundColor,
      backgroundColor: activeBackgroundColor,
      padding: useVerticalLayout
          ? const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 4.0,
            ) // Adjust padding for vertical
          : const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ), // Original or adjusted padding
      textStyle: const TextStyle(
        fontSize: 12,
      ), // Potentially smaller text for vertical
    );

    if (useVerticalLayout) {
      return Expanded(
        // Ensure buttons take up available space in the Row
        child: ElevatedButton(
          style: activeStyle,
          onPressed: () => _toggleActiveCardTool(tool),
          child: Column(
            mainAxisSize:
                MainAxisSize.min, // So the column doesn't expand unnecessarily
            children: <Widget>[
              Icon(icon, size: 24), // Adjust size as needed
              const SizedBox(height: 4), // Space between icon and label
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    } else {
      // Using Flexible or Expanded so buttons can share space,
      // but ElevatedButton.icon already handles its sizing well.
      // If they still overflow, wrap with Expanded.
      return ElevatedButton.icon(
        style: activeStyle,
        icon: Icon(icon, size: 20),
        label: Text(label),
        onPressed: () => _toggleActiveCardTool(tool),
      );
    }
  }

  Widget _buildActiveToolView() {
    switch (_activeCardTool) {
      case ActiveCardTool.compass:
        return CompassToolView(project: widget.project); // Pass necessary data
      case ActiveCardTool.points:
        return PointsToolView(project: widget.project); // Pass necessary data
      case ActiveCardTool.map:
        return MapToolView(project: widget.project); // Pass necessary data
      case null:
        // This case should ideally not be reached if isMainFormVisible handles it,
        // but as a fallback:
        return const SizedBox.shrink(); // Or an error message
    }
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
