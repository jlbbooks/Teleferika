import 'dart:async'; // For Timer

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teleferika/project_page.dart';

import 'app_config.dart';
import 'db/database_helper.dart';
import 'db/models/project_model.dart';
import 'logger.dart';

class ProjectsListPage extends StatefulWidget {
  final String? appVersion;

  const ProjectsListPage({super.key, this.appVersion});

  @override
  State<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends State<ProjectsListPage> {
  late Future<List<ProjectModel>> _projectsFuture;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isSelectionMode = false;
  final Set<String> _selectedProjectIdsForMultiSelect = {};
  String? _highlightedProjectId;

  // Keep a local copy of projects to manipulate for instant UI updates
  List<ProjectModel> _currentProjects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  void _loadProjects() {
    _projectsFuture = _dbHelper.getAllProjects();
    _projectsFuture
        .then((projects) {
          if (mounted) {
            setState(() {
              _currentProjects = projects;
              // Optionally clear highlight when the whole list reloads,
              // or persist it if needed. For now, let's clear it.
              // _highlightedProjectId = null;
            });
          }
        })
        .catchError((error) {
          // Handle or log error if needed
          logger.severe("Error in _loadProjects: $error");
          if (mounted) {
            setState(() {
              _currentProjects = []; // Clear current projects on error
            });
          }
        });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // This can be used if you only want to refresh data from DB
  void _refreshProjectsListFromDb() {
    setState(() {
      _highlightedProjectId = null; // Clear highlight on full refresh
      _loadProjects();
    });
  }

  void _toggleSelection(String projectId) {
    setState(() {
      _highlightedProjectId =
          null; // Clear highlight when entering multi-selection
      if (_selectedProjectIdsForMultiSelect.contains(projectId)) {
        _selectedProjectIdsForMultiSelect.remove(projectId);
        if (_selectedProjectIdsForMultiSelect.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedProjectIdsForMultiSelect.add(projectId);
      }
    });
  }

  void _onItemLongPress(ProjectModel project) {
    if (project.id == null) return;
    setState(() {
      _isSelectionMode = true;
      _highlightedProjectId = null; // Clear single highlight
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
      // Clear any previous highlight before navigating
      setState(() {
        _highlightedProjectId = null;
      });
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectPage(project: project, isNew: false),
        ),
      );
      _handleNavigationResult(result);
    }
  }

  void _handleNavigationResult(dynamic result) {
    if (result is Map<String, dynamic>) {
      final String? action = result['action'];
      final String? id = result['id'];

      if (id == null) {
        // If ID is null, we probably don't need to do anything specific,
        // or just refresh if any background state might have changed.
        // For now, let's assume a full refresh might be safest if something non-specific happened.
        // _refreshProjectsListFromDb();
        logger.info("ProjectPage returned with no specific ID or action.");
        return;
      }

      if (action == 'saved') {
        logger.info("ProjectPage returned: project $id was saved.");
        // Option 1: Full refresh to get the latest data.
        // _refreshProjectsListFromDb();
        // setState(() {
        //   _highlightedProjectId = id;
        // });

        // Option 2: More targeted update (if you have the updated project data or can fetch it)
        // For now, let's refresh the list and then highlight.
        // We need to ensure the list is rebuilt *before* we try to scroll or ensure visibility.
        _projectsFuture = _dbHelper.getAllProjects();
        _projectsFuture.then((projects) {
          if (mounted) {
            setState(() {
              _currentProjects = projects;
              _highlightedProjectId = id; // Set highlight after data is loaded
            });
            // TODO: Optionally, scroll to the highlighted item
          }
        });
      } else if (action == 'deleted') {
        logger.info("ProjectPage returned: project $id was deleted.");
        setState(() {
          _currentProjects.removeWhere((p) => p.id == id);
          _highlightedProjectId = null; // Ensure no highlight on a deleted item
          // No need to call _dbHelper.getAllProjects() here if we manually update _currentProjects
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Project deleted.'),
              backgroundColor: Colors.orange, // Or your preferred color
            ),
          );
        }
      } else if (action == 'navigated_back') {
        // User just came back, potentially from viewing an existing project. Highlight it.
        logger.info("ProjectPage returned: navigated back from project $id.");
        setState(() {
          _highlightedProjectId = id;
        });
      } else if (result['action'] == "created" && result['id'] != null) {
        // This is your existing logic path from _onItemTap, let's integrate it.
        logger.info(
          "ProjectPage returned: project ${result['id']} was created (legacy path).",
        );
        _refreshProjectsListFromDb(); // Refresh to get the new item
        setState(() {
          _highlightedProjectId = result['id'];
        });
      } else {
        // Fallback for your existing conditions, or new unhandled ones
        logger.info(
          "ProjectPage returned with result: $result. Refreshing list.",
        );
        _refreshProjectsListFromDb();
        // If an ID is present in a generic success, highlight it
        if (result['id'] is int) {
          setState(() {
            _highlightedProjectId = result['id'];
          });
        }
      }
    } else if (result is bool && result == true) {
      // Generic true, refresh list. Maybe highlight if a context can be inferred.
      logger.info("ProjectPage returned generic true. Refreshing list.");
      _refreshProjectsListFromDb();
    } else if (result == null) {
      logger.info(
        "ProjectPage returned null (e.g. back press without action). No specific action taken on list.",
      );
      // Optionally clear highlight or leave as is
      // setState(() {
      //   _highlightedProjectId = null;
      // });
    }
    // Note: Your original _onItemTap had a FIXME to always refresh.
    // This new structure provides more granular control.
  }

  void _navigateToAddProjectPage() async {
    logger.info("Navigating to ProjectDetailsPage for a new project.");
    ProjectModel newProject = ProjectModel(name: '');

    // Clear any previous highlight before navigating
    setState(() {
      _highlightedProjectId = null;
    });

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectPage(project: newProject, isNew: true),
      ), // Ensure this is your ProjectDetailsPage
    );

    _handleNavigationResult(result);
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedProjectIdsForMultiSelect.clear();
    });
  }

  Future<void> _deleteSelectedProjects() async {
    if (_selectedProjectIdsForMultiSelect.isEmpty) return;

    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(
                "Delete Project${_selectedProjectIdsForMultiSelect.length > 1 ? 's' : ''}?",
              ),
              content: Text(
                "Are you sure you want to delete ${_selectedProjectIdsForMultiSelect.length} selected project${_selectedProjectIdsForMultiSelect.length > 1 ? 's' : ''}? This action cannot be undone.",
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
        final List<String> idsToDelete = List.from(
          _selectedProjectIdsForMultiSelect,
        );
        for (String id in idsToDelete) {
          await _dbHelper.deleteProject(id);
        }
        setState(() {
          _currentProjects.removeWhere(
            (project) => idsToDelete.contains(project.id),
          );
          _isSelectionMode = false;
          _selectedProjectIdsForMultiSelect.clear();
          _highlightedProjectId = null;
        });
        logger.info("${idsToDelete.length} project(s) deleted.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${idsToDelete.length} project(s) deleted.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stackTrace) {
        logger.severe("Error deleting projects", e, stackTrace);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting projects: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildProjectItem(ProjectModel project) {
    // Get the current locale from the context for date formatting
    final locale = Localizations.localeOf(context).toString();

    // Define locale-aware date formatters
    // For "Proj. Date: MMM d, yyyy | Upd: HH:mm"
    // We'll use yMMMd for the project date part and Hm for the time part.
    final DateFormat projectDateFormat = DateFormat.yMMMd(locale);
    final DateFormat timeFormat = DateFormat.Hm(locale); // For HH:mm

    // For "Last Update: MMM d, yyyy HH:mm" (fallback if project.date is null)
    // We'll use yMMMd for the date part and Hm for the time part.
    final DateFormat lastUpdateDateTimeFormat = DateFormat.yMMMd(
      locale,
    ).add_Hm();
    String lastUpdateText;
    if (project.date != null) {
      String formattedProjectDate = projectDateFormat.format(project.date!);
      String formattedUpdateTime = project.lastUpdate != null
          ? timeFormat.format(project.lastUpdate!)
          : "-";
      lastUpdateText =
          'Proj. Date: $formattedProjectDate\nUpd: $formattedUpdateTime';
    } else {
      lastUpdateText = project.lastUpdate != null
          ? 'Last Update: ${lastUpdateDateTimeFormat.format(project.lastUpdate!)}'
          : 'No updates';
    }

    // Determine if the item should be highlighted
    bool isHighlighted =
        project.id != null && project.id == _highlightedProjectId;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: isHighlighted
          ? Theme.of(context).primaryColorLight.withOpacity(0.3)
          : null, // Highlight color
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: _selectedProjectIdsForMultiSelect.contains(project.id),
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
    String titleText = '${AppConfig.appName} Projects';
    String? version;
    if (widget.appVersion != null && widget.appVersion!.isNotEmpty) {
      version = ' [${widget.appVersion}]';
    }
    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              title: Text(
                "${_selectedProjectIdsForMultiSelect.length} selected",
              ),
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
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(titleText),

                  if (version != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(version, style: TextStyle(fontSize: 10.0)),
                    ),
                ],
              ),
              actions: [
                // IconButton for future settings/search can go here
              ],
            ),
      body: FutureBuilder<List<ProjectModel>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _currentProjects.isEmpty) {
            // Show loader only if _currentProjects is empty (initial load)
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError && _currentProjects.isEmpty) {
            logger.severe(
              "Error loading projects",
              snapshot.error,
              snapshot.stackTrace,
            );
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (_currentProjects.isEmpty) {
            // Use _currentProjects to determine if the list is empty
            return const Center(
              child: Text("No projects yet. Tap '+' to add one!"),
            );
          }

          // Use _currentProjects for building the list for instant UI updates
          return ListView.builder(
            itemCount: _currentProjects.length,
            itemBuilder: (context, index) {
              final project = _currentProjects[index];
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
