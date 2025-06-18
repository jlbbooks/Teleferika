// projects_list_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'db/database_helper.dart';
import 'db/models/project_model.dart';

// You'll need a page to navigate to for adding/editing projects
// import 'add_edit_project_page.dart'; // Placeholder for now

class ProjectsListPage extends StatefulWidget {
  const ProjectsListPage({super.key});

  @override
  State<ProjectsListPage> createState() => _ProjectsListPageState();
}

class _ProjectsListPageState extends State<ProjectsListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  late Future<List<ProjectModel>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _refreshProjectsList();
  }

  void _refreshProjectsList() {
    setState(() {
      _projectsFuture = _dbHelper.getAllProjects();
    });
  }

  void _navigateToAddProjectPage() async {
    // Navigate to your Add/Edit Project Page.
    // After returning from that page, refresh the list.
    // Example:
    // final result = await Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (context) => const AddEditProjectPage()),
    // );
    // if (result == true) { // Assuming AddEditProjectPage returns true on save
    //   _refreshProjectsList();
    // }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Add New Project Tapped (Implement Navigation)'),
      ),
    );
    // For now, let's add a dummy project to see the list update
    await _dbHelper.insertProject(
      ProjectModel(name: "New Project ${DateTime.now().second}"),
    );
    _refreshProjectsList();
  }

  void _navigateToProjectDetails(ProjectModel project) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped on ${project.name} (Implement Navigation)'),
      ),
    );
    // Navigate to a page showing project details, points, etc.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          // App Title
          Container(
            padding: const EdgeInsets.only(top: 60.0, bottom: 20.0),
            // Adjust for status bar
            alignment: Alignment.center,
            child: const Text(
              'Teleferika',
              style: TextStyle(
                fontSize: 32.0,
                fontWeight: FontWeight.bold,
                // color: Theme.of(context).primaryColor, // Optional: use theme color
              ),
            ),
          ),

          // Projects List
          Expanded(
            child: FutureBuilder<List<ProjectModel>>(
              future: _projectsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
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
                    String formattedDate = project.lastUpdate != null
                        ? DateFormat(
                            'MMM d, yyyy HH:mm',
                          ).format(project.lastUpdate!)
                        : 'N/A';
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 6.0,
                      ),
                      child: ListTile(
                        title: Text(
                          project.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text('Last updated: $formattedDate'),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16.0,
                        ),
                        onTap: () {
                          _navigateToProjectDetails(project);
                        },
                        onLongPress: () async {
                          // Example: Delete on long press
                          bool? confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Delete Project?'),
                                content: Text(
                                  'Are you sure you want to delete "${project.name}"? This cannot be undone.',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text('Cancel'),
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                  ),
                                  TextButton(
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmDelete == true && project.id != null) {
                            await _dbHelper.deleteProject(project.id!);
                            _refreshProjectsList();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Project "${project.name}" deleted.',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Add Project Button
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
                // backgroundColor: Theme.of(context).primaryColor, // Optional
                // foregroundColor: Colors.white, // Optional
              ),
              onPressed: _navigateToAddProjectPage,
            ),
          ),
        ],
      ),
    );
  }
}
