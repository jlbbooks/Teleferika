import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/project_state_manager.dart';

/// Provider widget that makes the global project state available to child widgets
class ProjectProvider extends StatelessWidget {
  final Widget child;

  const ProjectProvider({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProjectStateManager>(
      create: (_) => ProjectStateManager(),
      child: child,
    );
  }
}

/// Extension to easily access the project state manager from any widget
extension ProjectStateExtension on BuildContext {
  ProjectStateManager get projectState =>
      Provider.of<ProjectStateManager>(this, listen: false);

  ProjectStateManager get projectStateListen =>
      Provider.of<ProjectStateManager>(this, listen: true);
}
