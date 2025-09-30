import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/projection_service.dart';
import '../filter/global_filter.dart';
import 'map_filtering.dart';
import '../../core/models/point_group.dart';
import '../../core/models/point.dart';

class MapPainter extends CustomPainter {
  MapPainter({
    required this.projection,
    required this.pan,
    required this.scale,
    required this.rotation,
    required this.borderGroups,
    required this.partitionGroups,
    required this.borderPointsByGroup,
    required this.partitionPointsByGroup,
    required this.ref,
    required this.gps,
    this.showPointLabels = false,
  });
  final ProjectionService projection;
  final Offset pan;
  final double scale;
  final double rotation;
  final List<PointGroup> borderGroups;
  final List<PointGroup> partitionGroups;
  final Map<int, List<Point>> borderPointsByGroup;
  final Map<int, List<Point>> partitionPointsByGroup;
  final WidgetRef ref;
  final GpsSample? gps;
  final bool showPointLabels;

  // Debug helpers (one-time logging during a session)
  static bool _loggedCountsOnce = false;
  static bool _printedSamplePtsOnce = false;

  @override
  void paint(Canvas canvas, Size size) {
    final filter = ref.read(globalFilterProvider);
    final center = size.center(Offset.zero);
    canvas.translate(center.dx + pan.dx, center.dy + pan.dy);
    canvas.rotate(rotation);
    canvas.scale(scale);

    // Quick verification logs (one-time): groups and total points
    if (!_loggedCountsOnce) {
      final borderPtsTotal = borderPointsByGroup.values.fold<int>(
        0,
        (s, l) => s + (l.length),
      );
      final partPtsTotal = partitionPointsByGroup.values.fold<int>(
        0,
        (s, l) => s + (l.length),
      );
      debugPrint('BORDER groups=${borderGroups.length} pts=$borderPtsTotal');
      debugPrint('PART groups=${partitionGroups.length} pts=$partPtsTotal');
      _loggedCountsOnce = true;
    }

    // Distinct paints and styles
    final partitionFill = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(
        0xFF64B5F6,
      ).withValues(alpha: 0.30); // soft blue, 30% alpha
    final partitionEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 / scale
      ..color = const Color(0xFF1976D2); // blue edge
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 / scale
      ..color = const Color(0xFF2E7D32); // deep green for property border

    // DEV quad removed after verification

    // 1) Partition fills + edges first
    for (final g in partitionGroups) {
      if (filter.groupIds.isNotEmpty && !filter.groupIds.contains(g.id)) {
        continue;
      }
      final pts = partitionPointsByGroup[g.id] ?? const <Point>[];
      if (pts.length < 3) continue;

      // Print first few points of the first non-empty partition group (one-time)
      if (!_printedSamplePtsOnce && pts.isNotEmpty) {
        final sample = pts.take(3).toList();
        debugPrint(
          'Sample partition group id=${g.id} name=${g.name}:'
          ' category=${g.category}',
        );
        for (var i = 0; i < sample.length; i++) {
          debugPrint('  pt[$i] lat=${sample[i].lat}, lon=${sample[i].lon}');
        }
        _printedSamplePtsOnce = true;
      }
      final first = projection.project(pts.first.lat, pts.first.lon);
      final path = Path()..moveTo(first.dx, first.dy);
      for (var i = 1; i < pts.length; i++) {
        final xy = projection.project(pts[i].lat, pts[i].lon);
        path.lineTo(xy.dx, xy.dy);
      }
      path.close();
      canvas.drawPath(path, partitionFill);
      canvas.drawPath(path, partitionEdge);
    }

    // 2) Farm border outline last so it sits on top
    for (final g in borderGroups) {
      if (filter.groupIds.isNotEmpty && !filter.groupIds.contains(g.id)) {
        continue;
      }
      final pts = borderPointsByGroup[g.id] ?? const <Point>[];
      if (pts.length < 2) continue;
      final first = projection.project(pts.first.lat, pts.first.lon);
      final path = Path()..moveTo(first.dx, first.dy);
      for (var i = 1; i < pts.length; i++) {
        final xy = projection.project(pts[i].lat, pts[i].lon);
        path.lineTo(xy.dx, xy.dy);
      }
      path.close();
      canvas.drawPath(path, borderPaint);
    }

    if (gps != null) {
      final xy = projection.project(
        gps!.position.latitude,
        gps!.position.longitude,
      );
      final acc = gps!.acc;
      final accPaint = Paint()..color = Colors.blue.withValues(alpha: 0.15);
      final dot = Paint()..color = Colors.blue;
      canvas.drawCircle(xy, acc, accPaint);
      canvas.drawCircle(xy, 3.0 / scale, dot);
    }

    // Draw points (borders and partitions) as small dots; labels optional
    final pointPaint = Paint()..color = Colors.black87;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    // Approximate viewport bounds in world space (ignoring rotation)
    final viewportWorld = Rect.fromCenter(
      center: Offset.zero,
      width: size.width / scale,
      height: size.height / scale,
    );
    void drawGroupPoints(PointGroup g) {
      if (filter.groupIds.isNotEmpty && !filter.groupIds.contains(g.id)) {
        return;
      }
      final isBorder = borderGroups.contains(g);
      final pts =
          (isBorder
              ? borderPointsByGroup[g.id]
              : partitionPointsByGroup[g.id]) ??
          const <Point>[];
      if (pts.isEmpty) return;
      var idx = 1;
      for (final p in pts) {
        // Filter by search text and viewport if enabled
        if (!pointMatchesSearch(p, g, filter.search)) continue;
        if (filter.inViewportOnly &&
            !pointInsideViewport(p, projection, viewportWorld)) {
          continue;
        }
        final xy = projection.project(p.lat, p.lon);
        canvas.drawCircle(xy, 2.5 / scale, pointPaint);
        if (showPointLabels) {
          final label = (p.name.isNotEmpty) ? p.name : idx.toString();
          tp.text = TextSpan(
            style: const TextStyle(fontSize: 11, color: Colors.black87),
            text: label,
          );
          tp.layout();
          tp.paint(canvas, xy + const Offset(4, -4));
        }
        idx++;
      }
    }

    for (final g in borderGroups) {
      drawGroupPoints(g);
    }
    for (final g in partitionGroups) {
      drawGroupPoints(g);
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter old) {
    return pan != old.pan ||
        scale != old.scale ||
        rotation != old.rotation ||
        borderGroups != old.borderGroups ||
        partitionGroups != old.partitionGroups ||
        borderPointsByGroup != old.borderPointsByGroup ||
        partitionPointsByGroup != old.partitionPointsByGroup ||
        gps != old.gps ||
        showPointLabels != old.showPointLabels;
  }
}
