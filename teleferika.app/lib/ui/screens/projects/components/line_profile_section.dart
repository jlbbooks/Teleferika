// line_profile_section.dart
// Longitudinal profile: elevation vs. distance along the line (Section 2 — Terrain and Elevation).

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:teleferika/core/project_provider.dart';
import 'package:teleferika/db/models/point_model.dart';
import 'package:teleferika/db/models/project_model.dart';

/// Tab content showing the elevation profile of the line:
/// altitude of each point vs. cumulative distance along the line.
/// Vertical axis bounded by min/max altitude; each point shown as a dot with its name.
class LineProfileSection extends StatelessWidget {
  final ProjectModel project;
  final List<PointModel> points;

  const LineProfileSection({
    super.key,
    required this.project,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return _buildEmptyState(
        context,
        'Add at least two points to see the elevation profile.',
      );
    }

    final profileData = _computeProfileData(points);
    if (profileData == null) {
      return _buildEmptyState(
        context,
        'Add altitude to points to see the elevation profile.',
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverToBoxAdapter(
            child: _ExpandableProfileChart(
              project: project,
              profileData: profileData,
              points: points,
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
  final _ProfileData profileData;
  final List<PointModel> points;

  const _ExpandableProfileChart({
    required this.project,
    required this.profileData,
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

  late double _chartHeight;
  bool _pendingSquareInitialHeight = true;
  double? _lastLayoutWidth;

  @override
  void initState() {
    super.initState();
    final saved = widget.project.profileChartHeight;
    _chartHeight = (saved != null)
        ? saved.clamp(_minChartHeight, _maxChartHeight)
        : _defaultChartHeight;
    _pendingSquareInitialHeight = saved == null;
  }

  void _onResize(double delta) {
    final newHeight =
        (_chartHeight + delta).clamp(_minChartHeight, _maxChartHeight);
    setState(() => _chartHeight = newHeight);
    context.projectState.updateProfileChartHeightOnly(
      widget.project.id,
      newHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Title + spacing + chart container height
    const titleAndSpacingHeight = 32.0;
    const axisPaddingVertical = 72.0;
    final chartSectionHeight =
        titleAndSpacingHeight + _chartHeight + axisPaddingVertical;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth - _outerMargin * 2;
        _lastLayoutWidth = chartWidth;

        if (_pendingSquareInitialHeight) {
          _pendingSquareInitialHeight = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final w = _lastLayoutWidth ?? _defaultChartHeight;
            setState(() {
              _chartHeight = w.clamp(_minChartHeight, _maxChartHeight);
            });
          });
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: chartSectionHeight,
              child: _ProfileChart(
                profileData: widget.profileData,
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
  final _ProfileData profileData;
  final List<PointModel> points;
  final double? preferredChartHeight;

  const _ProfileChart({
    required this.profileData,
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
                'Elevation profile',
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
                          profileData: profileData,
                          points: points,
                          chartWidth: contentWidth,
                          chartHeight: contentHeight,
                          theme: Theme.of(context),
                        ),
                      ),
                    ),
                    _PointLabels(
                      profileData: profileData,
                      points: points,
                      chartWidth: contentWidth,
                      chartHeight: contentHeight,
                      paddingLeft: axisPadding.left,
                      paddingTop: axisPadding.top,
                      theme: Theme.of(context),
                    ),
                    _YAxisPointLabels(
                      profileData: profileData,
                      points: points,
                      chartHeight: contentHeight,
                      paddingTop: axisPadding.top,
                      theme: Theme.of(context),
                    ),
                    _XAxisPointLabels(
                      profileData: profileData,
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
  final _ProfileData profileData;
  final List<PointModel> points;
  final double chartWidth;
  final double chartHeight;
  final ThemeData theme;

  _ProfilePainter({
    required this.profileData,
    required this.points,
    required this.chartWidth,
    required this.chartHeight,
    required this.theme,
  });

  double _x(double distance) {
    if (profileData.totalDistance <= 0) return 0;
    return (distance / profileData.totalDistance) * chartWidth;
  }

  double _y(double altitude) {
    final range = profileData.maxAltitude - profileData.minAltitude;
    if (range <= 0) return chartHeight / 2;
    return chartHeight -
        ((altitude - profileData.minAltitude) / range) * chartHeight;
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

    for (int i = 0; i < points.length; i++) {
      final alt = profileData.altitudes[i];
      if (alt == null) continue;

      final x = _x(profileData.distances[i]);
      final y = _y(alt);

      if (!started) {
        path.moveTo(x, y);
        started = true;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, linePaint);

    const dotRadius = 6.0;
    for (int i = 0; i < points.length; i++) {
      final alt = profileData.altitudes[i];
      if (alt == null) continue;

      final xi = _x(profileData.distances[i]);
      final yi = _y(alt);

      // Dotted line from point to Y axis (horizontal)
      _drawDottedLine(
        canvas,
        Offset(0, yi),
        Offset(xi, yi),
        dottedPaint,
      );
      // Dotted line from point to X axis (vertical)
      _drawDottedLine(
        canvas,
        Offset(xi, yi),
        Offset(xi, chartHeight),
        dottedPaint,
      );

      // Y-axis tick at this point
      canvas.drawLine(Offset(0, yi), Offset(tickLen, yi), axisPaint);
      // X-axis tick at this point
      canvas.drawLine(
        Offset(xi, chartHeight),
        Offset(xi, chartHeight - tickLen),
        axisPaint,
      );

      canvas.drawCircle(Offset(xi, yi), dotRadius, dotPaint);
      canvas.drawCircle(Offset(xi, yi), dotRadius, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProfilePainter old) {
    return old.profileData != profileData ||
        old.chartWidth != chartWidth ||
        old.chartHeight != chartHeight;
  }
}

class _PointLabels extends StatelessWidget {
  final _ProfileData profileData;
  final List<PointModel> points;
  final double chartWidth;
  final double chartHeight;
  final double paddingLeft;
  final double paddingTop;
  final ThemeData theme;

  const _PointLabels({
    required this.profileData,
    required this.points,
    required this.chartWidth,
    required this.chartHeight,
    required this.paddingLeft,
    required this.paddingTop,
    required this.theme,
  });

  double _x(double distance) {
    if (profileData.totalDistance <= 0) return 0;
    return (distance / profileData.totalDistance) * chartWidth;
  }

  double _y(double altitude) {
    final range = profileData.maxAltitude - profileData.minAltitude;
    if (range <= 0) return chartHeight / 2;
    return chartHeight -
        ((altitude - profileData.minAltitude) / range) * chartHeight;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          for (int i = 0; i < points.length; i++) ...[
            _labelAt(
              profileData.distances[i],
              profileData.altitudes[i],
              points[i].name,
              i,
            ),
          ],
        ],
      ),
    );
  }

  Widget _labelAt(double distance, double? altitude, String name, int index) {
    if (altitude == null) return const SizedBox.shrink();
    final x = paddingLeft + _x(distance);
    final y = paddingTop + _y(altitude);
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
  final _ProfileData profileData;
  final List<PointModel> points;
  final double chartHeight;
  final double paddingTop;
  final ThemeData theme;

  const _YAxisPointLabels({
    required this.profileData,
    required this.points,
    required this.chartHeight,
    required this.paddingTop,
    required this.theme,
  });

  double _y(double altitude) {
    final range = profileData.maxAltitude - profileData.minAltitude;
    if (range <= 0) return chartHeight / 2;
    return chartHeight -
        ((altitude - profileData.minAltitude) / range) * chartHeight;
  }

  static String _formatAltitude(double m) {
    return '${m.toStringAsFixed(0)} m';
  }

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
            for (int i = 0; i < points.length; i++) ...[
              if (profileData.altitudes[i] != null)
                Positioned(
                  left: 0,
                  top: (_y(profileData.altitudes[i]!) - 8)
                      .clamp(0.0, chartHeight - 16),
                  width: 42,
                  height: 16,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      _formatAltitude(profileData.altitudes[i]!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _XAxisPointLabels extends StatelessWidget {
  final _ProfileData profileData;
  final List<PointModel> points;
  final double chartWidth;
  final double paddingLeft;
  final double paddingTop;
  final double chartHeight;
  final ThemeData theme;

  const _XAxisPointLabels({
    required this.profileData,
    required this.points,
    required this.chartWidth,
    required this.paddingLeft,
    required this.paddingTop,
    required this.chartHeight,
    required this.theme,
  });

  double _x(double distance) {
    if (profileData.totalDistance <= 0) return 0;
    return (distance / profileData.totalDistance) * chartWidth;
  }

  static String _formatDistance(double m) {
    if (m >= 1000) {
      return '${(m / 1000).toStringAsFixed(1)} km';
    }
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
            for (int i = 0; i < points.length; i++) ...[
              if (profileData.altitudes[i] != null)
                Positioned(
                  left: (_x(profileData.distances[i]) - 24)
                      .clamp(0.0, chartWidth - 48),
                  top: 0,
                  width: 48,
                  height: 28,
                  child: Text(
                    _formatDistance(profileData.distances[i]),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
