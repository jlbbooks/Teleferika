// projects_list_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teleferika/project_details_page.dart';

import 'db/database_helper.dart';
import 'db/models/project_model.dart'; // Import your logger
import 'logger.dart'; // Make sure this path is correct

class ProjectsListPage extends StatefulWidget {
  const ProjectsListPage({super.key});

  @override
  State<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends State<ProjectsListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late Future<List<ProjectModel>> _projectsFuture;

  // State for multi-selection
  bool _isSelectionMode = false;
  final Set<int> _selectedProjectIds = {}; // Store IDs of selected projects

  @override
  void initState() {
    super.initState();
    _refreshProjectsList();
  }

  void _refreshProjectsList() {
    // If we are in selection mode when refreshing, exit selection mode
    // as the list items might change.
    if (_isSelectionMode) {
      _exitSelectionMode();
    }
    setState(() {
      _projectsFuture = _dbHelper.getAllProjects();
    });
  }

  void _toggleSelection(int projectId) {
    setState(() {
      if (_selectedProjectIds.contains(projectId)) {
        _selectedProjectIds.remove(projectId);
        if (_selectedProjectIds.isEmpty) {
          _isSelectionMode =
              false; // Exit selection mode if no items are selected
        }
      } else {
        _selectedProjectIds.add(projectId);
        _isSelectionMode = true; // Enter selection mode if not already
      }
    });
  }

  void _onItemLongPress(int projectId) {
    setState(() {
      _isSelectionMode = true;
      _toggleSelection(projectId);
    });
  }

  void _onItemTap(ProjectModel project) {
    if (_isSelectionMode) {
      _toggleSelection(project.id!);
    } else {
      logger.info("Navigating to details for project: ${project.name}");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProjectDetailsPage(project: project)),
      ).then((_) {
        // This 'then' block executes when ProjectDetailsPage is popped.
        // Refresh the list in case any details (like name or lastUpdate) were changed.
        _refreshProjectsList();
      });
    }
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedProjectIds.clear();
    });
  }

  Future<void> _deleteSelectedProjects() async {
    if (_selectedProjectIds.isEmpty) {
      return;
    }

    // Confirmation Dialog
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Project${_selectedProjectIds.length > 1 ? 's' : ''}?',
          ),
          content: Text(
            'Are you sure you want to delete ${_selectedProjectIds.length} selected project${_selectedProjectIds.length > 1 ? 's' : ''}? This cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        for (int projectId in _selectedProjectIds) {
          await _dbHelper.deleteProject(projectId);
        }
        logger.info("Deleted ${_selectedProjectIds.length} projects.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedProjectIds.length} project${_selectedProjectIds.length > 1 ? 's' : ''} deleted.',
            ),
          ),
        );
      } catch (e, stackTrace) {
        logger.severe("Error deleting projects", e, stackTrace);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting projects: $e')));
      } finally {
        _refreshProjectsList(); // This will also exit selection mode
      }
    }
  }

  void _navigateToAddProjectPage() async {
    // Navigate to your Add/Edit Project Page.
    // final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddEditProjectPage()));
    // if (result == true) {
    //   _refreshProjectsList();
    // }
    logger.info("Navigating to Add Project Page (Placeholder)");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add New Project Tapped (Implement Navigation)'),
      ),
    );
    // For now, let's add a dummy project to see the list update
    await _dbHelper.insertProject(
      ProjectModel(name: "New Project ${DateTime.now().millisecond}"),
    ); // More unique name
    _refreshProjectsList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              title: Text('${_selectedProjectIds.length} selected'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete selected projects',
                  onPressed: _selectedProjectIds.isNotEmpty
                      ? _deleteSelectedProjects
                      : null, // Disable if none selected
                ),
              ],
            )
          : null, // No AppBar if not in selection mode (title is in the body)
      body: Column(
        children: <Widget>[
          // App Title (only shown if not in selection mode)
          if (!_isSelectionMode)
            Container(
              padding: const EdgeInsets.only(top: 60.0, bottom: 20.0),
              alignment: Alignment.center,
              child: const Text(
                'Teleferika',
                style: TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold),
              ),
            ),

          Expanded(
            child: FutureBuilder<List<ProjectModel>>(
              future: _projectsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  logger.warning(
                    "Error loading projects: ${snapshot.error}",
                    snapshot.error,
                    snapshot.stackTrace,
                  );
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No projects yet. Tap + to add one!',
                      style: TextStyle(fontSize: 18.0),
                    ),
                  );
                }

                final projects = snapshot.data!;
                return ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final bool isSelected = _selectedProjectIds.contains(
                      project.id!,
                    );
                    String formattedDate = project.lastUpdate != null
                        ? DateFormat(
                            'MMM d, yyyy HH:mm',
                          ).format(project.lastUpdate!)
                        : 'N/A';

                    const int selectedAlpha = 26;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 6.0,
                      ),
                      elevation: isSelected ? 4.0 : 1.0,
                      // Slightly raise selected items
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: isSelected
                            ? BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              )
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        title: Text(
                          project.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('Last updated: $formattedDate'),
                        leading: _isSelectionMode
                            ? Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : null,
                              )
                            : null,
                        // No leading icon if not in selection mode
                        trailing: !_isSelectionMode
                            ? const Icon(Icons.arrow_forward_ios, size: 16.0)
                            : null,
                        // No trailing arrow if in selection mode
                        onTap: () => _onItemTap(project),
                        onLongPress: () => _onItemLongPress(project.id!),
                        selected: isSelected,
                        selectedTileColor: Theme.of(
                          context,
                        ).primaryColor.withAlpha(selectedAlpha),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Add Project Button
          if (!_isSelectionMode) // Only show if not in selection mode
            Container(
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('ADD NEW PROJECT'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _navigateToAddProjectPage,
              ),
            ),
        ],
      ),
    );
  }
}
