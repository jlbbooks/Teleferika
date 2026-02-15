// line_profile_section.dart
// Longitudinal profile: elevation vs. distance along the line (Section 2 — Terrain and Elevation).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';

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

enum _ProfileChartMode { elevation, plan }

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
      final mode = saved == 'plan' ? _ProfileChartMode.plan : _ProfileChartMode.elevation;
      if (mounted) setState(() => _mode = mode);
    }
  }

  _ProfileChartMode _mode = _ProfileChartMode.elevation;

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
    if (_mode == _ProfileChartMode.elevation && !canShowElevation && canShowPlan) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _mode = _ProfileChartMode.plan);
          context.projectState.setProfileChartMode('plan');
        }
      });
    }

    final effectiveMode = canShowElevation && _mode == _ProfileChartMode.elevation
        ? _ProfileChartMode.elevation
        : _ProfileChartMode.plan;

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
                    child: SegmentedButton<_ProfileChartMode>(
                      segments: const [
                        ButtonSegment(
                          value: _ProfileChartMode.elevation,
                          label: Text('Elevation'),
                          icon: Icon(Icons.terrain, size: 18),
                        ),
                        ButtonSegment(
                          value: _ProfileChartMode.plan,
                          label: Text('Plan view'),
                          icon: Icon(Icons.straighten, size: 18),
                        ),
                      ],
                      selected: {effectiveMode},
                      onSelectionChanged: (Set<_ProfileChartMode> s) {
                        final v = s.first;
                        if (v == _ProfileChartMode.elevation && !canShowElevation) return;
                        setState(() => _mode = v);
                        context.projectState.setProfileChartMode(
                          v == _ProfileChartMode.elevation ? 'elevation' : 'plan',
                        );
                      },
                    ),
                  ),
                _ExpandableProfileChart(
                  project: widget.project,
                  mode: effectiveMode,
                  profileData: effectiveMode == _ProfileChartMode.elevation ? profileData : null,
                  planProfileData: effectiveMode == _ProfileChartMode.plan ? planProfileData : null,
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
  static _ProfileData? _computeProfileData(List<PointModel> points) {
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

    return _ProfileData(
      distances: distances,
      altitudes: altitudes,
      minAltitude: minAlt,
      maxAltitude: maxAlt,
      totalDistance: distances.last,
    );
  }

  /// Plan (top-view) profile: first at bottom-left, last at top-right;
  /// Y = lateral offset from the straight line (m). Returns null if fewer than 2 points.
  static _PlanProfileData? _computePlanProfileData(List<PointModel> points) {
    if (points.length < 2) return null;
    final first = points.first;
    final last = points.last;
    final bearingRefDeg = _bearingDegrees(first, last);
    final totalAlong = first.distanceFromPoint(last);
    if (totalAlong <= 0) return null;

    final alongDistances = <double>[];
    final lateralOffsets = <double>[];
    for (int i = 0; i < points.length; i++) {
      final dist = first.distanceFromPoint(points[i]);
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

    return _PlanProfileData(
      alongDistances: alongDistances,
      lateralOffsets: lateralOffsets,
      minLateral: minLateral,
      maxLateral: maxLateral,
      totalAlong: totalAlong,
    );
  }
}

class _PlanProfileData {
  final List<double> alongDistances;
  final List<double> lateralOffsets;
  final double minLateral;
  final double maxLateral;
  final double totalAlong;

  _PlanProfileData({
    required this.alongDistances,
    required this.lateralOffsets,
    required this.minLateral,
    required this.maxLateral,
    required this.totalAlong,
  });
}

class _ProfileData {
  final List<double> distances;
  final List<double?> altitudes;
  final double minAltitude;
  final double maxAltitude;
  final double totalDistance;

  _ProfileData({
    required this.distances,
    required this.altitudes,
    required this.minAltitude,
    required this.maxAltitude,
    required this.totalDistance,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ProfileData &&
          totalDistance == other.totalDistance &&
          minAltitude == other.minAltitude &&
          maxAltitude == other.maxAltitude &&
          distances.length == other.distances.length;

  @override
  int get hashCode =>
      Object.hash(totalDistance, minAltitude, maxAltitude, distances.length);
}

class _ExpandableProfileChart extends StatefulWidget {
  final ProjectModel project;
  final _ProfileChartMode mode;
  final _ProfileData? profileData;
  final _PlanProfileData? planProfileData;
  final List<PointModel> points;

  const _ExpandableProfileChart({
    required this.project,
    required this.mode,
    required this.profileData,
    required this.planProfileData,
    required this.points,
  });

  @override
  State<_ExpandableProfileChart> createState() => _ExpandableProfileChartState();
}

class _ExpandableProfileChartState extends State<_ExpandableProfileChart> {
  static const _minChartHeight = 120.0;
  static const _maxChartHeight = 500.0;
  static const _defaultChartHeight = 220.0;
  static const _outerMargin = 4.0;

  late double _elevationChartHeight;
  late double _planChartHeight;
  bool _elevationSquareApplied = false;
  bool _planSquareApplied = false;
  double? _lastLayoutWidth;

  @override
  void initState() {
    super.initState();
    _elevationChartHeight = (widget.project.profileChartHeight != null)
        ? widget.project.profileChartHeight!.clamp(_minChartHeight, _maxChartHeight)
        : _defaultChartHeight;
    _planChartHeight = (widget.project.planProfileChartHeight != null)
        ? widget.project.planProfileChartHeight!.clamp(_minChartHeight, _maxChartHeight)
        : _defaultChartHeight;
    _elevationSquareApplied = widget.project.profileChartHeight != null;
    _planSquareApplied = widget.project.planProfileChartHeight != null;
  }

  double get _chartHeight => widget.mode == _ProfileChartMode.elevation
      ? _elevationChartHeight
      : _planChartHeight;

  void _onResize(double delta) {
    final newHeight = (_chartHeight + delta).clamp(_minChartHeight, _maxChartHeight);
    setState(() {
      if (widget.mode == _ProfileChartMode.elevation) {
        _elevationChartHeight = newHeight;
      } else {
        _planChartHeight = newHeight;
      }
    });
    if (widget.mode == _ProfileChartMode.elevation) {
      context.projectState.updateProfileChartHeightOnly(widget.project.id, newHeight);
    } else {
      context.projectState.updatePlanProfileChartHeightOnly(widget.project.id, newHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    const titleAndSpacingHeight = 32.0;
    const axisPaddingVertical = 72.0;
    final chartSectionHeight =
        titleAndSpacingHeight + _chartHeight + axisPaddingVertical;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth - _outerMargin * 2;
        _lastLayoutWidth = chartWidth;

        final needSquareElevation = !_elevationSquareApplied &&
            widget.project.profileChartHeight == null &&
            widget.mode == _ProfileChartMode.elevation;
        final needSquarePlan = !_planSquareApplied &&
            widget.project.planProfileChartHeight == null &&
            widget.mode == _ProfileChartMode.plan;

        if (needSquareElevation) {
          _elevationSquareApplied = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final w = _lastLayoutWidth ?? _defaultChartHeight;
            final h = w.clamp(_minChartHeight, _maxChartHeight);
            setState(() => _elevationChartHeight = h);
            context.projectState.updateProfileChartHeightOnly(widget.project.id, h);
          });
        } else if (needSquarePlan) {
          _planSquareApplied = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final w = _lastLayoutWidth ?? _defaultChartHeight;
            final h = w.clamp(_minChartHeight, _maxChartHeight);
            setState(() => _planChartHeight = h);
            context.projectState.updatePlanProfileChartHeightOnly(widget.project.id, h);
          });
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: chartSectionHeight,
              child: _ProfileChart(
                mode: widget.mode,
                profileData: widget.profileData,
                planProfileData: widget.planProfileData,
                points: widget.points,
                preferredChartHeight: _chartHeight,
              ),
            ),
            _ChartResizeHandle(onVerticalDrag: _onResize),
          ],
        );
      },
    );
  }
}

class _ChartResizeHandle extends StatelessWidget {
  final void Function(double delta) onVerticalDrag;

  const _ChartResizeHandle({required this.onVerticalDrag});

  @override
  Widget build(BuildContext context) {
    const handleHeight = 28.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) => onVerticalDrag(details.delta.dy),
      child: Container(
        height: handleHeight,
        alignment: Alignment.center,
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Icon(
          Icons.drag_handle,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _ProfileChart extends StatelessWidget {
  final _ProfileChartMode mode;
  final _ProfileData? profileData;
  final _PlanProfileData? planProfileData;
  final List<PointModel> points;
  final double? preferredChartHeight;

  const _ProfileChart({
    required this.mode,
    required this.profileData,
    required this.planProfileData,
    required this.points,
    this.preferredChartHeight,
  });

  @override
  Widget build(BuildContext context) {
    const axisPadding = EdgeInsets.fromLTRB(48, 24, 24, 48);
    const defaultChartHeight = 220.0;
    const outerMargin = 4.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth - outerMargin * 2;
        final chartHeight = preferredChartHeight != null
            ? preferredChartHeight!.clamp(120.0, 500.0)
            : () {
                final availableHeight = constraints.maxHeight.isFinite
                    ? constraints.maxHeight - outerMargin * 2
                    : defaultChartHeight;
                return (availableHeight - axisPadding.vertical)
                    .clamp(120.0, double.infinity);
              }();
        final contentWidth = chartWidth - axisPadding.horizontal;
        final contentHeight = chartHeight;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: outerMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mode == _ProfileChartMode.elevation
                    ? 'Elevation profile'
                    : 'Plan view (lateral offset)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.8),
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                width: chartWidth,
                height: chartHeight + axisPadding.vertical,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Positioned(
                      left: axisPadding.left,
                      top: axisPadding.top,
                      child: CustomPaint(
                        size: Size(contentWidth, contentHeight),
                        painter: _ProfilePainter(
                          mode: mode,
                          profileData: profileData,
                          planProfileData: planProfileData,
                          points: points,
                          chartWidth: contentWidth,
                          chartHeight: contentHeight,
                          theme: Theme.of(context),
                        ),
                      ),
                    ),
                    _PointLabels(
                      mode: mode,
                      profileData: profileData,
                      planProfileData: planProfileData,
                      points: points,
                      chartWidth: contentWidth,
                      chartHeight: contentHeight,
                      paddingLeft: axisPadding.left,
                      paddingTop: axisPadding.top,
                      theme: Theme.of(context),
                    ),
                    _YAxisPointLabels(
                      mode: mode,
                      profileData: profileData,
                      planProfileData: planProfileData,
                      points: points,
                      chartHeight: contentHeight,
                      paddingTop: axisPadding.top,
                      theme: Theme.of(context),
                    ),
                    _XAxisPointLabels(
                      mode: mode,
                      profileData: profileData,
                      planProfileData: planProfileData,
                      points: points,
                      chartWidth: contentWidth,
                      paddingLeft: axisPadding.left,
                      paddingTop: axisPadding.top,
                      chartHeight: contentHeight,
                      theme: Theme.of(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfilePainter extends CustomPainter {
  final _ProfileChartMode mode;
  final _ProfileData? profileData;
  final _PlanProfileData? planProfileData;
  final List<PointModel> points;
  final double chartWidth;
  final double chartHeight;
  final ThemeData theme;

  _ProfilePainter({
    required this.mode,
    required this.profileData,
    required this.planProfileData,
    required this.points,
    required this.chartWidth,
    required this.chartHeight,
    required this.theme,
  });

  double _xElevation(double distance) {
    if (profileData!.totalDistance <= 0) return 0;
    return (distance / profileData!.totalDistance) * chartWidth;
  }

  double _yElevation(double altitude) {
    final range = profileData!.maxAltitude - profileData!.minAltitude;
    if (range <= 0) return chartHeight / 2;
    return chartHeight -
        ((altitude - profileData!.minAltitude) / range) * chartHeight;
  }

  double _xPlan(double along) {
    if (planProfileData!.totalAlong <= 0) return 0;
    return (along / planProfileData!.totalAlong) * chartWidth;
  }

  double _yPlan(double lateral) {
    final range = planProfileData!.maxLateral - planProfileData!.minLateral;
    if (range <= 0) return chartHeight / 2;
    return chartHeight -
        ((lateral - planProfileData!.minLateral) / range) * chartHeight;
  }

  void _drawDottedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dotLength = 2.0;
    const gapLength = 4.0;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length <= 0) return;
    final ux = dx / length;
    final uy = dy / length;
    double t = 0;
    while (t < length) {
      final tEnd = (t + dotLength).clamp(0.0, length);
      canvas.drawLine(
        Offset(from.dx + t * ux, from.dy + t * uy),
        Offset(from.dx + tEnd * ux, from.dy + tEnd * uy),
        paint,
      );
      t += dotLength + gapLength;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final axisColor = theme.colorScheme.outline.withValues(alpha: 0.6);
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final dottedPaint = Paint()
      ..color = theme.colorScheme.outline.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const tickLen = 5.0;

    // Y axis (left edge)
    canvas.drawLine(Offset(0, 0), Offset(0, chartHeight), axisPaint);
    // X axis (bottom edge)
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(chartWidth, chartHeight),
      axisPaint,
    );

    final linePaint = Paint()
      ..color = theme.colorScheme.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = theme.colorScheme.primary
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = theme.colorScheme.onPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    bool started = false;

    if (mode == _ProfileChartMode.elevation && profileData != null) {
      for (int i = 0; i < points.length; i++) {
        final alt = profileData!.altitudes[i];
        if (alt == null) continue;
        final x = _xElevation(profileData!.distances[i]);
        final y = _yElevation(alt);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
    } else if (mode == _ProfileChartMode.plan && planProfileData != null) {
      for (int i = 0; i < points.length; i++) {
        final x = _xPlan(planProfileData!.alongDistances[i]);
        final y = _yPlan(planProfileData!.lateralOffsets[i]);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
    }

    canvas.drawPath(path, linePaint);

    const dotRadius = 6.0;
    if (mode == _ProfileChartMode.elevation && profileData != null) {
      for (int i = 0; i < points.length; i++) {
        final alt = profileData!.altitudes[i];
        if (alt == null) continue;
        final xi = _xElevation(profileData!.distances[i]);
        final yi = _yElevation(alt);
        _drawDottedLine(canvas, Offset(0, yi), Offset(xi, yi), dottedPaint);
        _drawDottedLine(canvas, Offset(xi, yi), Offset(xi, chartHeight), dottedPaint);
        canvas.drawLine(Offset(0, yi), Offset(tickLen, yi), axisPaint);
        canvas.drawLine(Offset(xi, chartHeight), Offset(xi, chartHeight - tickLen), axisPaint);
        canvas.drawCircle(Offset(xi, yi), dotRadius, dotPaint);
        canvas.drawCircle(Offset(xi, yi), dotRadius, dotBorderPaint);
      }
    } else if (mode == _ProfileChartMode.plan && planProfileData != null) {
      for (int i = 0; i < points.length; i++) {
        final xi = _xPlan(planProfileData!.alongDistances[i]);
        final yi = _yPlan(planProfileData!.lateralOffsets[i]);
        _drawDottedLine(canvas, Offset(0, yi), Offset(xi, yi), dottedPaint);
        _drawDottedLine(canvas, Offset(xi, yi), Offset(xi, chartHeight), dottedPaint);
        canvas.drawLine(Offset(0, yi), Offset(tickLen, yi), axisPaint);
        canvas.drawLine(Offset(xi, chartHeight), Offset(xi, chartHeight - tickLen), axisPaint);
        canvas.drawCircle(Offset(xi, yi), dotRadius, dotPaint);
        canvas.drawCircle(Offset(xi, yi), dotRadius, dotBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter old) {
    return old.mode != mode ||
        old.profileData != profileData ||
        old.planProfileData != planProfileData ||
        old.chartWidth != chartWidth ||
        old.chartHeight != chartHeight;
  }
}

class _PointLabels extends StatelessWidget {
  final _ProfileChartMode mode;
  final _ProfileData? profileData;
  final _PlanProfileData? planProfileData;
  final List<PointModel> points;
  final double chartWidth;
  final double chartHeight;
  final double paddingLeft;
  final double paddingTop;
  final ThemeData theme;

  const _PointLabels({
    required this.mode,
    required this.profileData,
    required this.planProfileData,
    required this.points,
    required this.chartWidth,
    required this.chartHeight,
    required this.paddingLeft,
    required this.paddingTop,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (int i = 0; i < points.length; i++) ...[
            if (mode == _ProfileChartMode.elevation && profileData != null &&
                profileData!.altitudes[i] != null)
              _labelAt(
                paddingLeft + (profileData!.totalDistance <= 0 ? 0 : (profileData!.distances[i] / profileData!.totalDistance) * chartWidth),
                paddingTop + _yElevation(profileData!.altitudes[i]!),
                points[i].name,
              ),
            if (mode == _ProfileChartMode.plan && planProfileData != null)
              _labelAt(
                paddingLeft + (planProfileData!.totalAlong <= 0 ? 0 : (planProfileData!.alongDistances[i] / planProfileData!.totalAlong) * chartWidth),
                paddingTop + _yPlan(planProfileData!.lateralOffsets[i]),
                points[i].name,
              ),
          ],
        ],
      ),
    );
  }

  double _yElevation(double altitude) {
    final range = profileData!.maxAltitude - profileData!.minAltitude;
    if (range <= 0) return chartHeight / 2;
    return chartHeight - ((altitude - profileData!.minAltitude) / range) * chartHeight;
  }

  double _yPlan(double lateral) {
    final range = planProfileData!.maxLateral - planProfileData!.minLateral;
    if (range <= 0) return chartHeight / 2;
    return chartHeight - ((lateral - planProfileData!.minLateral) / range) * chartHeight;
  }

  Widget _labelAt(double x, double y, String name) {
    return Positioned(
      left: x - 24,
      top: y + 10,
      width: 48,
      child: Text(
        name,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _YAxisPointLabels extends StatelessWidget {
  final _ProfileChartMode mode;
  final _ProfileData? profileData;
  final _PlanProfileData? planProfileData;
  final List<PointModel> points;
  final double chartHeight;
  final double paddingTop;
  final ThemeData theme;

  const _YAxisPointLabels({
    required this.mode,
    required this.profileData,
    required this.planProfileData,
    required this.points,
    required this.chartHeight,
    required this.paddingTop,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: paddingTop,
      width: 44,
      height: chartHeight,
      child: IgnorePointer(
        child: Stack(
          children: [
            if (mode == _ProfileChartMode.elevation && profileData != null)
              for (int i = 0; i < points.length; i++)
                if (profileData!.altitudes[i] != null)
                  _label(
                    _yElevation(profileData!.altitudes[i]!),
                    _formatAltitude(profileData!.altitudes[i]!),
                  ),
            if (mode == _ProfileChartMode.plan && planProfileData != null)
              for (int i = 0; i < points.length; i++)
                _label(
                  _yPlan(planProfileData!.lateralOffsets[i]),
                  _formatLateral(planProfileData!.lateralOffsets[i]),
                ),
          ],
        ),
      ),
    );
  }

  double _yElevation(double altitude) {
    final range = profileData!.maxAltitude - profileData!.minAltitude;
    if (range <= 0) return chartHeight / 2;
    return chartHeight - ((altitude - profileData!.minAltitude) / range) * chartHeight;
  }

  double _yPlan(double lateral) {
    final range = planProfileData!.maxLateral - planProfileData!.minLateral;
    if (range <= 0) return chartHeight / 2;
    return chartHeight - ((lateral - planProfileData!.minLateral) / range) * chartHeight;
  }

  Widget _label(double y, String text) {
    return Positioned(
      left: 0,
      top: (y - 8).clamp(0.0, chartHeight - 16),
      width: 42,
      height: 16,
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
      ),
    );
  }

  static String _formatAltitude(double m) => '${m.toStringAsFixed(0)} m';
  static String _formatLateral(double m) => '${m.toStringAsFixed(0)} m';
}

class _XAxisPointLabels extends StatelessWidget {
  final _ProfileChartMode mode;
  final _ProfileData? profileData;
  final _PlanProfileData? planProfileData;
  final List<PointModel> points;
  final double chartWidth;
  final double paddingLeft;
  final double paddingTop;
  final double chartHeight;
  final ThemeData theme;

  const _XAxisPointLabels({
    required this.mode,
    required this.profileData,
    required this.planProfileData,
    required this.points,
    required this.chartWidth,
    required this.paddingLeft,
    required this.paddingTop,
    required this.chartHeight,
    required this.theme,
  });

  static String _formatDistance(double m) {
    if (m >= 1000) return '${(m / 1000).toStringAsFixed(1)} km';
    return '${m.toStringAsFixed(0)} m';
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: paddingLeft,
      top: paddingTop + chartHeight + 2,
      width: chartWidth,
      height: 28,
      child: IgnorePointer(
        child: Stack(
          children: [
            if (mode == _ProfileChartMode.elevation && profileData != null)
              for (int i = 0; i < points.length; i++)
                if (profileData!.altitudes[i] != null)
                  _label(
                    (profileData!.totalDistance <= 0 ? 0 : (profileData!.distances[i] / profileData!.totalDistance) * chartWidth),
                    _formatDistance(profileData!.distances[i]),
                  ),
            if (mode == _ProfileChartMode.plan && planProfileData != null)
              for (int i = 0; i < points.length; i++)
                _label(
                  (planProfileData!.totalAlong <= 0 ? 0 : (planProfileData!.alongDistances[i] / planProfileData!.totalAlong) * chartWidth),
                  _formatDistance(planProfileData!.alongDistances[i]),
                ),
          ],
        ),
      ),
    );
  }

  Widget _label(double x, String text) {
    return Positioned(
      left: (x - 24).clamp(0.0, chartWidth - 48),
      top: 0,
      width: 48,
      height: 28,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
      ),
    );
  }
}
