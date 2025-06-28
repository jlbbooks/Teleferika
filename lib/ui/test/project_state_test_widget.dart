import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/core/project_state_test.dart';
import 'package:teleferika/db/database_helper.dart';
import 'package:teleferika/db/models/project_model.dart';

/// Simple test widget to verify ProjectStateManager foundation
class ProjectStateTestWidget extends StatefulWidget {
  const ProjectStateTestWidget({super.key});

  @override
  State<ProjectStateTestWidget> createState() => _ProjectStateTestWidgetState();
}

class _ProjectStateTestWidgetState extends State<ProjectStateTestWidget> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<ProjectModel> _projects = [];
  bool _isRunningTests = false;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      _projects = await _dbHelper.getAllProjects();
      setState(() {});
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  Future<void> _runFoundationTests() async {
    setState(() => _isRunningTests = true);
    try {
      await ProjectStateTest.runTests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ All foundation tests passed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isRunningTests = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project State Test'),
        actions: [
          IconButton(
            icon: _isRunningTests
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            onPressed: _isRunningTests ? null : _runFoundationTests,
            tooltip: 'Run Foundation Tests',
          ),
        ],
      ),
      body: Consumer<ProjectStateManager>(
        builder: (context, projectState, child) {
          return Column(
            children: [
              // Status
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Project Loaded: ${projectState.hasProject}'),
                      Text('Loading: ${projectState.isLoading}'),
                      if (projectState.currentProject != null)
                        Text('Project: ${projectState.currentProject!.name}'),
                      Text('Points: ${projectState.currentPoints.length}'),
                    ],
                  ),
                ),
              ),

              // Project List
              Expanded(
                child: ListView.builder(
                  itemCount: _projects.length,
                  itemBuilder: (context, index) {
                    final project = _projects[index];
                    return ListTile(
                      title: Text(project.name),
                      subtitle: Text('${project.points.length} points'),
                      onTap: () => _loadProject(project.id),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _loadProject(String projectId) async {
    try {
      await context.projectState.loadProject(projectId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Project loaded!')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
