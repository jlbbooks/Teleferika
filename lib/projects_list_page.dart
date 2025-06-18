import 'dart:async'; // For Timer

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'db/database_helper.dart';
import 'db/models/project_model.dart';
import 'logger.dart';
import 'project_details_page.dart';

class ProjectsListPage extends StatefulWidget {
  const ProjectsListPage({super.key});

  @override
  State<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends State<ProjectsListPage> {
  late Future<List<ProjectModel>> _projectsFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isSelectionMode = false;
  final Set<int> _selectedProjectIds = {};

  // --- For Flashing ---
  int? _flashingProjectId; // ID of the project to flash
  bool _isFlashing = false; // To control the flash state
  Timer? _flashTimer; // Timer to reset the flash
  // --- End Flashing ---

  @override
  void initState() {
    super.initState();
    _projectsFuture = _dbHelper.getAllProjects();
  }

  @override
  void dispose() {
    _flashTimer?.cancel(); // Cancel timer if page is disposed
    super.dispose();
  }

  void _refreshProjectsList() {
    setState(() {
      _projectsFuture = _dbHelper.getAllProjects();
    });
  }

  void _toggleSelection(int projectId) {
    setState(() {
      if (_selectedProjectIds.contains(projectId)) {
        _selectedProjectIds.remove(projectId);
        if (_selectedProjectIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedProjectIds.add(projectId);
      }
    });
  }

  void _onItemLongPress(ProjectModel project) {
    if (project.id == null) return;
    setState(() {
      _isSelectionMode = true;
      _toggleSelection(project.id!);
    });
  }

  void _onItemTap(ProjectModel project) async {
    if (_isSelectionMode) {
      if (project.id != null) {
        _toggleSelection(project.id!);
      }
    } else {
      logger.info("Navigating to details for project: ${project.name}");
      // Navigate to ProjectDetailsPage and wait for a result.
      // The result can be a map like {'modified': true, 'id': projectId}
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProjectDetailsPage(project: project)),
      );

      // --- Handle Result for Flashing ---
      if (result is Map<String, dynamic> &&
          result['modified'] == true &&
          result['id'] != null) {
        _startFlashing(result['id'] as int);
        _refreshProjectsList(); // Refresh list to show updated data
      } else if (result == true) {
        // Fallback for simple boolean result (e.g. from new project creation)
        _refreshProjectsList();
      }
      // --- End Handle Result ---
    }
  }

  void _startFlashing(int projectId) {
    _flashTimer?.cancel(); // Cancel any existing flash timer
    setState(() {
      _flashingProjectId = projectId;
      _isFlashing = true;
    });
    _flashTimer = Timer(const Duration(milliseconds: 700), () {
      // Duration of the flash
      setState(() {
        _isFlashing = false;
        _flashingProjectId = null; // Clear after flash
      });
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedProjectIds.clear();
    });
  }

  Future<void> _deleteSelectedProjects() async {
    if (_selectedProjectIds.isEmpty) return;

    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                "Delete Project${_selectedProjectIds.length > 1 ? 's' : ''}?",
              ),
              content: Text(
                "Are you sure you want to delete ${_selectedProjectIds.length} selected project${_selectedProjectIds.length > 1 ? 's' : ''}? This action cannot be undone.",
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: Colors.red),
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirmDelete) {
      try {
        for (int id in _selectedProjectIds) {
          await _dbHelper.deleteProject(id);
        }
        logger.info("${_selectedProjectIds.length} project(s) deleted.");
        _exitSelectionMode();
        _refreshProjectsList();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedProjectIds.length} project(s) deleted.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e, stackTrace) {
        logger.severe("Error deleting projects", e, stackTrace);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting projects: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToAddProjectPage() async {
    logger.info("Navigating to ProjectDetailsPage for a new project.");
    ProjectModel newProject = ProjectModel(name: ''); // id will be null

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailsPage(project: newProject),
      ),
    );

    if (result == true) {
      // New project was created and saved
      // Potentially, the new project could be flashed too if desired.
      // For now, just refresh. If ProjectDetailsPage pops with the new project ID,
      // you could call _startFlashing(newProjectId).
      _refreshProjectsList();
    }
  }

  Widget _buildProjectItem(ProjectModel project) {
    final dateFormat = DateFormat('MMM d, yyyy HH:mm');
    String lastUpdateText = project.lastUpdate != null
        ? dateFormat.format(project.lastUpdate!)
        : 'No updates';
    if (project.date != null) {
      lastUpdateText =
          'Proj. Date: ${DateFormat('MMM d, yyyy').format(project.date!)} | Upd: ${project.lastUpdate != null ? DateFormat('HH:mm').format(project.lastUpdate!) : "-"}';
    }

    // --- Flashing Logic ---
    Color itemColor = Theme.of(context).cardColor; // Default card color
    if (_flashingProjectId == project.id && _isFlashing) {
      itemColor = Colors.orange.shade100; // Flash color
    }
    // --- End Flashing Logic ---

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: itemColor, // Apply conditional color
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: _selectedProjectIds.contains(project.id),
                onChanged: (bool? value) {
                  if (project.id != null) {
                    _toggleSelection(project.id!);
                  }
                },
              )
            : const Icon(Icons.folder_outlined, size: 30),
        title: Text(
          project.name.isNotEmpty ? project.name : "Untitled Project",
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'ID: ${project.id ?? "New"} | $lastUpdateText',
          style: const TextStyle(fontSize: 12.0, color: Colors.grey),
        ),
        trailing: !_isSelectionMode
            ? const Icon(Icons.arrow_forward_ios, size: 16.0)
            : null,
        onTap: () => _onItemTap(project),
        onLongPress: () => _onItemLongPress(project),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              title: Text("${_selectedProjectIds.length} selected"),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: "Delete Selected",
                  onPressed: _deleteSelectedProjects,
                ),
              ],
            )
          : AppBar(
              title: const Text('Teleferika Projects'),
              actions: [
                // IconButton for future settings/search can go here
              ],
            ),
      body: FutureBuilder<List<ProjectModel>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            logger.severe(
              "Error loading projects",
              snapshot.error,
              snapshot.stackTrace,
            );
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No projects yet. Tap '+' to add one!"),
            );
          }

          final projects = snapshot.data!;
          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return _buildProjectItem(project);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddProjectPage,
        tooltip: 'Add New Project',
        child: const Icon(Icons.add),
      ),
    );
  }
}
