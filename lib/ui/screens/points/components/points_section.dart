import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/core/project_state_manager.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/l10n/app_localizations.dart';
import 'package:teleferika/ui/screens/points/point_editor_screen.dart';
import 'package:teleferika/ui/screens/points/points_list_screen.dart';
import 'package:teleferika/ui/widgets/status_indicator.dart';

class PointsSection extends StatefulWidget {
  final ProjectModel project;

  const PointsSection({super.key, required this.project});

  @override
  State<PointsSection> createState() => PointsSectionState();
}

class PointsSectionState extends State<PointsSection> with StatusMixin {
  // GlobalKey to access PointsListScreen methods
  final GlobalKey<PointsListScreenState> _pointsListScreenKey =
      GlobalKey<PointsListScreenState>();

  Future<void> _addNewPoint() async {
    final currentProject =
        context.projectState.currentProject ?? widget.project;

    // Create a new point with default values
    final newPoint = PointModel(
      projectId: currentProject.id,
      latitude: 0.0,
      // Will be set by GPS
      longitude: 0.0,
      // Will be set by GPS
      altitude: null,
      ordinalNumber: 0,
      // Will be set by OrdinalManager
      note: '',
    );

    // Navigate to PointDetailsPage
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => PointEditorScreen(point: newPoint),
      ),
    );

    if (result != null && mounted) {
      final String? action = result['action'] as String?;
      if (action == 'created' || action == 'updated') {
        // The global state will automatically update, no need to refresh manually
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectStateManager>(
      builder: (context, projectState, child) {
        final currentProject = projectState.currentProject ?? widget.project;
        final points = projectState.currentPoints;
        final s = S.of(context);

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Points List Section
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.list_alt,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  S.of(context)?.points_list_title ??
                                      'Points List',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: _addNewPoint,
                                  icon: Icon(
                                    Icons.add_location_alt,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    size: 24,
                                  ),
                                  tooltip:
                                      s?.compassAddPointButton ?? 'Add Point',
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: PointsListScreen(
                              key: _pointsListScreenKey,
                              project: currentProject,
                              points: points,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 24,
              right: 24,
              child: StatusIndicator(
                status: currentStatus,
                onDismiss: hideStatus,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Public method to access PointsListScreen's onProjectSaved method
  void onProjectSaved() {
    _pointsListScreenKey.currentState?.onProjectSaved();
  }

  /// Public method to refresh points in PointsListScreen
  void refreshPoints() {
    _pointsListScreenKey.currentState?.refreshPoints();
  }

  /// Public method to undo changes in PointsListScreen
  Future<void> undoChanges() async {
    await context.projectState.undoChanges();
  }
}
