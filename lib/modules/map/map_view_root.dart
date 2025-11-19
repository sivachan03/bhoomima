import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'branch_b_map_view.dart';
import 'map_view.dart';
import 'map_painter.dart';
import '../../core/services/projection_service.dart';
import '../../core/services/gps_service.dart';
import 'map_providers.dart';
import 'map_points_aggregate.dart';
import '../../app_state/active_property.dart';
import 'transform_model.dart';
import '../../core/models/point_group.dart';
import '../../core/models/point.dart';

/// Always-visible debug grid for Branch B visual verification.
class DebugGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF121212);
    canvas.drawRect(Offset.zero & size, bg);

    final gridPaint = Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 1.0;

    const double step = 80.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final centerPaint = Paint()
      ..color = const Color(0xFF00FF88)
      ..strokeWidth = 2.0;
    final center = size.center(Offset.zero);
    canvas.drawLine(
      Offset(center.dx - 20, center.dy),
      Offset(center.dx + 20, center.dy),
      centerPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 20),
      Offset(center.dx, center.dy + 20),
      centerPaint,
    );

    final border = Paint()
      ..color = const Color(0xFF8888FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(Offset.zero & size, border);

    final tp = TextPainter(
      text: const TextSpan(
        text: 'Branch B / PhotoView debug grid',
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, const Offset(8, 8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// MapViewRoot: runtime toggle between legacy BM-200R MapViewScreen (Branch A)
/// and experimental PhotoView-based BranchBMapView (Branch B).
///
/// Integration strategy:
/// - Keep existing MapViewScreen untouched (Branch A).
/// - Provide a small builder wrapper for Branch B that mirrors the canvas
///   painting (MapPainter + overlays) in a neutral/home transform.
/// - Branch B does NOT mutate TransformModel; PhotoView drives its own state.
class MapViewRoot extends ConsumerWidget {
  const MapViewRoot({
    super.key,
    this.useBranchB = true,
    this.debugGrid = false, // NEW: fallback grid toggle
  });
  final bool useBranchB; // flip to true to try PhotoView branch
  final bool debugGrid; // NEW

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!useBranchB) {
      return const MapViewScreen();
    }
    debugPrint('[PV] BranchBMapView ACTIVE');

    if (debugGrid) {
      // Safety net: original debug grid path.
      return BranchBMapView(
        mapChildBuilder: (Size size) {
          debugPrint(
            '[PV] BranchB debug grid size=(${size.width}, ${size.height})',
          );
          return CustomPaint(
            painter: DebugGridPainter(),
            child: const SizedBox.expand(),
          );
        },
      );
    }

    // Gather data/providers just like the legacy map view does.
    final prop = ref.watch(activePropertyProvider).asData?.value;
    final gps = ref.watch(gpsStreamProvider).asData?.value;
    final borderGroupsVal =
        ref.watch(borderGroupsProvider).value ?? const <PointGroup>[];
    final partitionGroupsVal =
        ref.watch(partitionGroupsProvider).value ?? const <PointGroup>[];
    final borderPtsMap = ref.watch(
      pointsByGroupsReadyProvider(borderGroupsVal),
    );
    final partitionPtsMap = ref.watch(
      pointsByGroupsReadyProvider(partitionGroupsVal),
    );

    final proj = ProjectionService(
      prop?.originLat ?? prop?.lat ?? 0,
      prop?.originLon ?? prop?.lon ?? 0,
    );

    return BranchBMapView(
      mapChildBuilder: (Size size) {
        debugPrint(
          '[PV] BranchB mapChildBuilder size=(${size.width}, ${size.height})',
        );

        // Compute world bounds from data (prefer borders; fall back to partitions).
        Rect worldBounds = const Rect.fromLTWH(-500, -500, 1000, 1000);
        void includeGroupBounds(Map<int, List<Point>> ptsByGroup) {
          bool hasAny = false;
          Offset minNow = Offset.zero;
          Offset maxNow = Offset.zero;
          for (final entry in ptsByGroup.entries) {
            final pts = entry.value;
            for (final p in pts) {
              final o = proj.project(p.lat, p.lon);
              if (!hasAny) {
                minNow = o;
                maxNow = o;
                hasAny = true;
              } else {
                if (o.dx < minNow.dx) minNow = Offset(o.dx, minNow.dy);
                if (o.dy < minNow.dy) minNow = Offset(minNow.dx, o.dy);
                if (o.dx > maxNow.dx) maxNow = Offset(o.dx, maxNow.dy);
                if (o.dy > maxNow.dy) maxNow = Offset(maxNow.dx, o.dy);
              }
            }
          }
          if (hasAny) {
            final w = (maxNow.dx - minNow.dx).abs();
            final h = (maxNow.dy - minNow.dy).abs();
            if (w > 0 && h > 0) {
              worldBounds = Rect.fromLTWH(minNow.dx, minNow.dy, w, h);
            }
          }
        }

        if (borderPtsMap.isNotEmpty) {
          includeGroupBounds(borderPtsMap);
        } else if (partitionPtsMap.isNotEmpty) {
          includeGroupBounds(partitionPtsMap);
        }

        // Establish a home transform so content is centered inside the child.
        final homeXform = TransformModel(suppressLogs: true)
          ..homeTo(worldBounds: worldBounds, view: size, margin: 0.06);

        return CustomPaint(
          painter: MapPainter(
            projection: proj,
            borderGroups: borderGroupsVal,
            partitionGroups: partitionGroupsVal,
            borderPointsByGroup: borderPtsMap,
            partitionPointsByGroup: partitionPtsMap,
            ref: ref,
            gps: gps,
            xform: homeXform,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
