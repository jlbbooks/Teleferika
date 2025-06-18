// compass_tool_view.dart
import 'package:flutter/material.dart';
import 'package:teleferika/db/models/project_model.dart'; // If needed
import 'package:teleferika/logger.dart'; // If needed

class CompassToolView extends StatefulWidget {
  final ProjectModel project; // Pass project data if the tool needs it
  // You can add other parameters as needed, e.g., callbacks

  const CompassToolView({super.key, required this.project});

  @override
  State<CompassToolView> createState() => _CompassToolViewState();
}

class _CompassToolViewState extends State<CompassToolView> {
  // Add state variables and methods specific to the compass tool here

  @override
  void initState() {
    super.initState();
    logger.info(
      "CompassToolView initialized for project: ${widget.project.name}",
    );
    // Initialize compass specific things if necessary
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.explore_outlined,
            size: 60,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 16),
          Text(
            'Compass Tool Active',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Project: ${widget.project.name}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          // Add your actual compass UI elements here
          // For example:
          // Placeholder for compass display
          const Text(
            "Imagine a beautiful compass here!",
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Compass specific action
              logger.info("Compass action button tapped.");
            },
            child: const Text('Do Compass Thing'),
          ),
        ],
      ),
    );
  }
}
