import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/projection_service.dart';
import '../filter/global_filter.dart';
import 'map_filtering.dart';
import '../../core/models/point_group.dart';
import '../../core/models/point.dart';
import 'transform_model.dart';

class MapPainter extends CustomPainter {
  MapPainter({
    required this.projection,
    required this.borderGroups,
    required this.partitionGroups,
    required this.borderPointsByGroup,
    required this.partitionPointsByGroup,
    required this.ref,
    required this.gps,
    required this.xform,
    this.showPointLabels = false,
    this.splitRingAWorld,
    this.splitRingBWorld,
    this.showDebugAxis = false,
  });
  final ProjectionService projection;
  final List<PointGroup> borderGroups;
  final List<PointGroup> partitionGroups;
  final Map<int, List<Point>> borderPointsByGroup;
  final Map<int, List<Point>> partitionPointsByGroup;
  final WidgetRef ref;
  final GpsSample? gps;
  final bool showPointLabels;
  // Optional split preview rings (world coordinates)
  final List<Offset>? splitRingAWorld;
  final List<Offset>? splitRingBWorld;
  final TransformModel xform; // transform model with tx,ty,scale,rotRad
  final bool showDebugAxis; // controls drawing of axis cross

  // Debug helpers (one-time logging during a session)
  static bool _loggedCountsOnce = false;
  static bool _printedSamplePtsOnce = false;
  static bool _warnedWrongCategoryOnce = false;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final filter = ref.read(globalFilterProvider);
    final m = xform;
    // Apply xform as screen = T(tx,ty) * R(rot) * S(scale) * world
    canvas.translate(m.tx, m.ty);
    canvas.rotate(m.rotRad);
    canvas.scale(m.scale);
    final double effectiveScale = m.scale;
    final double effectiveRotation = m.rotRad;

    debugPrint(
      '[MP] paint borderGroups=${borderGroups.length} '
      'partitionGroups=${partitionGroups.length} '
      'borderPtsMaps=${borderPointsByGroup.length} '
      'partitionPtsMaps=${partitionPointsByGroup.length}',
    );

    // DEBUG optional: show rotation axis so we can see rotation working
    if (showDebugAxis) {
      final axis = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / effectiveScale
        ..color = const Color(0xFFE91E63);
      canvas.drawLine(const Offset(-40, 0), const Offset(40, 0), axis);
      canvas.drawLine(const Offset(0, -40), const Offset(0, 40), axis);
    }

    // BM-190: authoritative paint log from xform only
    debugPrint(
      '[BM-190] PAINT rot=${effectiveRotation.toStringAsFixed(3)} '
      'scale=${effectiveScale.toStringAsFixed(2)} '
      'pan=(${m.tx.toStringAsFixed(1)},${m.ty.toStringAsFixed(1)})',
    );

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
      ..strokeWidth = 1.2 / effectiveScale
      ..color = const Color(0xFF1976D2); // blue edge
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 / effectiveScale
      ..color = const Color(0xFF2E7D32); // deep green for property border

    // DEV quad removed after verification

    // One-time origin print to confirm painter uses same projection origin
    // as split logic
    debugPrint(
      '[BM-178 r4] PAINT origin lat0/lon0 = ${projection.lat0}, ${projection.lon0}',
    );

    // 1) Partition fills + edges first
    Path mkPathFromRing(List<Offset> ring) {
      final p = Path()..fillType = PathFillType.evenOdd;
      if (ring.isEmpty) return p;
      p.moveTo(ring.first.dx, ring.first.dy);
      for (final pt in ring.skip(1)) {
        p.lineTo(pt.dx, pt.dy);
      }
      p.close();
      return p;
    }

    for (final g in partitionGroups) {
      // Sanity: ensure category matches expected label
      if (g.category != null && g.category != 'partition') {
        if (!_warnedWrongCategoryOnce) {
          debugPrint(
            'MapPainter: partitionGroups contains non-partition category=${g.category} id=${g.id}',
          );
          _warnedWrongCategoryOnce = true;
        }
        continue;
      }
      if (filter.groupIds.isNotEmpty && !filter.groupIds.contains(g.id)) {
        continue;
      }
      final pts = partitionPointsByGroup[g.id] ?? const <Point>[];
      if (pts.length < 3) {
        // Debug: insufficient points to form partition polygon.
        debugPrint(
          'MapPainter: partition group id=${g.id} insufficient pts=${pts.length} (<3)',
        );
        continue;
      }

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
      // Build fresh path in world space and ensure it's closed, with even-odd fill
      final ring = <Offset>[
        for (final p in pts) projection.project(p.lat, p.lon),
      ];
      final path = mkPathFromRing(ring);

      // 2) Ignore absurd bounds (projection/origin mismatch / self-intersection)
      final b = path.getBounds();
      if (!b.isFinite || b.width > 1e7 || b.height > 1e7) {
        debugPrint('SKIP partition: absurd bounds w=${b.width} h=${b.height}');
        continue;
      }

      // 3) Soft-clip to a large world rect so nothing can flood the canvas
      canvas.save();
      canvas.clipRect(const Rect.fromLTWH(-100000, -100000, 200000, 200000));
      canvas.drawPath(path, partitionFill);
      canvas.drawPath(path, partitionEdge);
      canvas.restore();
    }

    // 2) Farm border outline last so it sits on top
    for (final g in borderGroups) {
      if (filter.groupIds.isNotEmpty && !filter.groupIds.contains(g.id)) {
        continue;
      }
      final pts = borderPointsByGroup[g.id] ?? const <Point>[];
      if (pts.length < 2) {
        debugPrint(
          'MapPainter: border group id=${g.id} insufficient pts=${pts.length} (<2)',
        );
        continue;
      }
      final first = projection.project(pts.first.lat, pts.first.lon);
      final path = Path()..moveTo(first.dx, first.dy);
      for (var i = 1; i < pts.length; i++) {
        final xy = projection.project(pts[i].lat, pts[i].lon);
        path.lineTo(xy.dx, xy.dy);
      }
      path.close();
      // Ensure non-empty bounds for border ring as well
      final shifted = path.shift(Offset.zero);
      canvas.drawPath(shifted, borderPaint);
    }

    // 3) If we have split preview rings, draw them as independent, closed paths
    if (splitRingAWorld != null && splitRingBWorld != null) {
      Path pathFromRing(List<Offset> ringWorld) {
        // hygiene
        List<Offset> dedupeClose(List<Offset> pts, [double eps = 1e-6]) {
          final out = <Offset>[];
          for (final p in pts) {
            if (out.isEmpty || (out.last - p).distance > eps) out.add(p);
          }
          return out;
        }

        bool isCCW(List<Offset> pts) {
          double a = 0;
          for (int i = 0; i < pts.length; i++) {
            final p = pts[i], q = pts[(i + 1) % pts.length];
            a += (q.dx - p.dx) * (q.dy + p.dy);
          }
          return a < 0; // classic convention
        }

        final pts = dedupeClose(ringWorld);
        final ccw = isCCW(pts);
        final list = ccw ? List<Offset>.from(pts) : pts.reversed.toList();
        if (list.isNotEmpty && list.first != list.last) list.add(list.first);

        final path = Path()..fillType = PathFillType.evenOdd;
        if (list.isNotEmpty) {
          path.moveTo(list[0].dx, list[0].dy);
          for (int i = 1; i < list.length; i++) {
            path.lineTo(list[i].dx, list[i].dy);
          }
          path.close();
        }
        return path;
      }

      final pFill = Paint()
        ..style = PaintingStyle.fill
        ..color = const Color(0x552196F3);
      final pStroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 / effectiveScale
        ..color = const Color(0xFF2196F3);

      final path1 = pathFromRing(splitRingAWorld!);
      final path2 = pathFromRing(splitRingBWorld!);
      // Guard with a conservative clip to avoid accidental full-canvas floods
      canvas.save();
      canvas.clipRect(const Rect.fromLTWH(-100000, -100000, 200000, 200000));
      canvas.drawPath(path1, pFill);
      canvas.drawPath(path2, pFill);
      canvas.drawPath(path1, pStroke);
      canvas.drawPath(path2, pStroke);
      canvas.restore();
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
      canvas.drawCircle(xy, 3.0 / effectiveScale, dot);
    }

    // Draw points (borders and partitions) as small dots; labels optional
    final pointPaint = Paint()..color = Colors.black87;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    // Approximate viewport bounds in world space (ignoring rotation)
    final viewportWorld = Rect.fromCenter(
      center: Offset.zero,
      width: size.width / effectiveScale,
      height: size.height / effectiveScale,
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
        canvas.drawCircle(xy, 2.5 / effectiveScale, pointPaint);
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
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MapPainter old) {
    // Repaint when transform values or data/flags differ.
    return xform.tx != old.xform.tx ||
        xform.ty != old.xform.ty ||
        xform.scale != old.xform.scale ||
        xform.rotRad != old.xform.rotRad ||
        borderGroups != old.borderGroups ||
        partitionGroups != old.partitionGroups ||
        borderPointsByGroup != old.borderPointsByGroup ||
        partitionPointsByGroup != old.partitionPointsByGroup ||
        gps != old.gps ||
        showPointLabels != old.showPointLabels;
  }
}
