// line_profile_section.dart
// Longitudinal profile: elevation vs. distance along the line (Section 2 — Terrain and Elevation).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';
import 'package:teleferika/ui/screens/projects/components/profile_chart.dart';

/// Bearing from [start] to [end] in degrees (0–360).
double _bearingDegrees(PointModel start, PointModel end) {
  final lat1 = start.latitude * math.pi / 180;
  final lon1 = start.longitude * math.pi / 180;
  final lat2 = end.latitude * math.pi / 180;
  final lon2 = end.longitude * math.pi / 180;
  final dLon = lon2 - lon1;
  final y = math.sin(dLon) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  final bearingRad = math.atan2(y, x);
  final bearingDeg = bearingRad * 180 / math.pi;
  return (bearingDeg + 360) % 360;
}

/// Tab content showing elevation and plan (top-view) profiles of the line.
class LineProfileSection extends StatefulWidget {
  final ProjectModel project;
  final List<PointModel> points;

  const LineProfileSection({
    super.key,
    required this.project,
    required this.points,
  });

  @override
  State<LineProfileSection> createState() => _LineProfileSectionState();
}

class _LineProfileSectionState extends State<LineProfileSection> {
  @override
  void initState() {
    super.initState();
    _syncModeFromState();
  }

  @override
  void didUpdateWidget(covariant LineProfileSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.id != widget.project.id) _syncModeFromState();
  }

  void _syncModeFromState() {
    final saved = context.projectState.lastProfileChartMode;
    if (saved == 'plan' || saved == 'elevation') {
      final mode = saved == 'plan' ? ProfileChartMode.plan : ProfileChartMode.elevation;
      if (mounted) setState(() => _mode = mode);
    }
  }

  ProfileChartMode _mode = ProfileChartMode.elevation;

  @override
  Widget build(BuildContext context) {
    if (widget.points.length < 2) {
      return _buildEmptyState(
        context,
        'Add at least two points to see the profile.',
      );
    }

    final profileData = _computeProfileData(widget.points);
    final planProfileData = _computePlanProfileData(widget.points);
    final canShowElevation = profileData != null;
    final canShowPlan = planProfileData != null;

    if (!canShowElevation && !canShowPlan) {
      return _buildEmptyState(
        context,
        'Add altitude to points to see the elevation profile.',
      );
    }

    // If current mode is elevation but no altitude data, switch to plan
    if (_mode == ProfileChartMode.elevation && !canShowElevation && canShowPlan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _mode = ProfileChartMode.plan);
          context.projectState.setProfileChartMode('plan');
        }
      });
    }

    final effectiveMode = canShowElevation && _mode == ProfileChartMode.elevation
        ? ProfileChartMode.elevation
        : ProfileChartMode.plan;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canShowElevation && canShowPlan)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SegmentedButton<ProfileChartMode>(
                      segments: const [
                        ButtonSegment(
                          value: ProfileChartMode.elevation,
                          label: Text('Elevation'),
                          icon: Icon(Icons.terrain, size: 18),
                        ),
                        ButtonSegment(
                          value: ProfileChartMode.plan,
                          label: Text('Plan view'),
                          icon: Icon(Icons.straighten, size: 18),
                        ),
                      ],
                      selected: {effectiveMode},
                      onSelectionChanged: (Set<ProfileChartMode> s) {
                        final v = s.first;
                        if (v == ProfileChartMode.elevation && !canShowElevation) return;
                        setState(() => _mode = v);
                        context.projectState.setProfileChartMode(
                          v == ProfileChartMode.elevation ? 'elevation' : 'plan',
                        );
                      },
                    ),
                  ),
                ExpandableProfileChart(
                  project: widget.project,
                  mode: effectiveMode,
                  profileData: effectiveMode == ProfileChartMode.elevation ? profileData : null,
                  planProfileData: effectiveMode == ProfileChartMode.plan ? planProfileData : null,
                  points: widget.points,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.terrain,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Line profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns null if no point has altitude.
  static ProfileData? _computeProfileData(List<PointModel> points) {
    final distances = <double>[0.0];
    final altitudes = <double?>[];
    for (int i = 0; i < points.length; i++) {
      altitudes.add(points[i].altitude);
      if (i < points.length - 1) {
        distances.add(
          distances.last + points[i].distanceFromPoint(points[i + 1]),
        );
      }
    }

    final hasAnyAltitude = altitudes.any((a) => a != null);
    if (!hasAnyAltitude) return null;

    double minAlt = double.infinity;
    double maxAlt = double.negativeInfinity;
    for (final a in altitudes) {
      if (a != null) {
        if (a < minAlt) minAlt = a;
        if (a > maxAlt) maxAlt = a;
      }
    }
    // Avoid zero height range
    if (maxAlt <= minAlt) {
      maxAlt = minAlt + 1;
    }

    return ProfileData(
      distances: distances,
      altitudes: altitudes,
      minAltitude: minAlt,
      maxAltitude: maxAlt,
      totalDistance: distances.last,
    );
  }

  /// Plan (top-view) profile: first at bottom-left, last at top-right;
  /// Y = lateral offset from the straight line (m). Uses only lat/lon (horizontal);
  /// altitude is ignored. Returns null if fewer than 2 points.
  static PlanProfileData? _computePlanProfileData(List<PointModel> points) {
    if (points.length < 2) return null;
    final first = points.first;
    final last = points.last;
    final bearingRefDeg = _bearingDegrees(first, last);
    // Horizontal distance only (ignore altitude for plan view)
    final totalAlong = first.distanceFromPoint(last, altitude: 0, otherAltitude: 0);
    if (totalAlong <= 0) return null;

    final alongDistances = <double>[];
    final lateralOffsets = <double>[];
    for (int i = 0; i < points.length; i++) {
      final dist = first.distanceFromPoint(points[i], altitude: 0, otherAltitude: 0);
      final bearingDeg = _bearingDegrees(first, points[i]);
      final bearingRad = (bearingDeg - bearingRefDeg) * math.pi / 180;
      final along = dist * math.cos(bearingRad);
      final across = dist * math.sin(bearingRad);
      alongDistances.add(along);
      lateralOffsets.add(across);
    }

    double minLateral = lateralOffsets.reduce(math.min);
    double maxLateral = lateralOffsets.reduce(math.max);
    if (maxLateral <= minLateral) {
      maxLateral = minLateral + 1;
    }

    return PlanProfileData(
      alongDistances: alongDistances,
      lateralOffsets: lateralOffsets,
      minLateral: minLateral,
      maxLateral: maxLateral,
      totalAlong: totalAlong,
    );
  }
}
