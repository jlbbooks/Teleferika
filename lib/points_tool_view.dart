// points_tool_view.dart
import 'package:flutter/material.dart';
import 'package:teleferika/db/models/project_model.dart'; // If needed

class PointsToolView extends StatelessWidget {
  // Can be StatelessWidget if no internal state
  final ProjectModel project;

  const PointsToolView({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.list_alt_outlined,
            size: 60,
            color: Colors.greenAccent,
          ),
          const SizedBox(height: 16),
          Text(
            'Points Tool Active',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Project: ${project.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          // Add your actual points list UI / management here
          const Text(
            "Points list and management UI will go here.",
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
