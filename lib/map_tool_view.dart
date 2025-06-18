// map_tool_view.dart
import 'package:flutter/material.dart';
import 'package:teleferika/db/models/project_model.dart'; // If needed

class MapToolView extends StatelessWidget {
  final ProjectModel project;

  const MapToolView({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 60, color: Colors.orangeAccent),
          const SizedBox(height: 16),
          Text(
            'Map Tool Active',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Project: ${project.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          // Add your actual map integration here
          const Text(
            "Interactive map will be displayed here.",
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
