import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../core/db/isar_service.dart';
import '../../core/models/point.dart';
import '../../core/models/point_group.dart';
import '../filter/global_filter.dart';

class PartitionOverlay extends ConsumerWidget {
  final int propertyId;
  final Rect worldBounds; // world-space bounds to cull work (optional)
  final Offset Function(double lat, double lon) project; // lat/lon -> canvas XY

  const PartitionOverlay({
    super.key,
    required this.propertyId,
    required this.project,
    required this.worldBounds,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labelsOn = ref.watch(globalFilterProvider).partitionsIncluded;
    final legendVisible = ref.watch(globalFilterProvider).legendVisible;

    return FutureBuilder<List<_PartitionShape>>(
      future: IsarService.open().then((db) => _load(db, propertyId)),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final shapes = snap.data!;
        return Stack(
          children: [
            // Painter
            RepaintBoundary(
              child: CustomPaint(
                painter: _PartitionPainter(shapes: shapes, project: project),
                size: Size.infinite,
              ),
            ),
            // Labels (only when filter includes partitions)
            if (labelsOn) ...[
              for (final s in shapes)
                Positioned(
                  left: s.centroid.dx - 40,
                  top: s.centroid.dy - 10,
                  width: 80,
                  height: 20,
                  child: IgnorePointer(
                    ignoring: true,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            // Legend (toggle)
            if (legendVisible)
              Positioned(right: 8, top: 8, child: _Legend(shapes: shapes)),
          ],
        );
      },
    );
  }

  Future<List<_PartitionShape>> _load(Isar db, int propertyId) async {
    final parts = await db.pointGroups
        .filter()
        .propertyIdEqualTo(propertyId)
        .and()
        .categoryEqualTo('partition')
        .findAll();

    final out = <_PartitionShape>[];
    for (final g in parts) {
      final pts = await db.points
          .filter()
          .groupIdEqualTo(g.id)
          .sortByCreatedAt()
          .findAll();

      if (pts.length < 3) continue; // need at least a triangle

      final path = Path();
      Offset? first;
      for (var i = 0; i < pts.length; i++) {
        final p = pts[i];
        final xy = project(p.lat, p.lon);
        if (i == 0) {
          path.moveTo(xy.dx, xy.dy);
          first = xy;
        } else {
          path.lineTo(xy.dx, xy.dy);
        }
      }
      if (first != null) path.lineTo(first.dx, first.dy);

      final centroid = _centroid(pts);
      out.add(
        _PartitionShape(
          name: g.name,
          color: _parseColor(g.colorHex) ?? const Color(0x6680CBC4),
          path: path,
          centroid: project(centroid.$1, centroid.$2),
        ),
      );
    }
    return out;
  }

  (double, double) _centroid(List<Point> pts) {
    // Planar centroid (approx for small areas)
    double x = 0, y = 0;
    for (final p in pts) {
      x += p.lat;
      y += p.lon;
    }
    return (x / pts.length, y / pts.length);
  }

  Color? _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var h = hex.replaceAll('#', '').toUpperCase();
    if (h.length == 6) h = '66$h'; // add alpha ~40%
    if (h.length != 8) return null;
    final a = int.parse(h.substring(0, 2), radix: 16);
    final r = int.parse(h.substring(2, 4), radix: 16);
    final g = int.parse(h.substring(4, 6), radix: 16);
    final b = int.parse(h.substring(6, 8), radix: 16);
    return Color.fromARGB(a, r, g, b);
  }
}

class _PartitionShape {
  final String name;
  final Color color;
  final Path path;
  final Offset centroid;
  _PartitionShape({
    required this.name,
    required this.color,
    required this.path,
    required this.centroid,
  });
}

class _PartitionPainter extends CustomPainter {
  final List<_PartitionShape> shapes;
  final Offset Function(double lat, double lon) project;
  _PartitionPainter({required this.shapes, required this.project});

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in shapes) {
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = s.color;
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = s.color.withValues(alpha: 0.9);
      canvas.drawPath(s.path, fill);
      canvas.drawPath(s.path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _PartitionPainter oldDelegate) {
    return oldDelegate.shapes != shapes;
  }
}

class _Legend extends StatelessWidget {
  final List<_PartitionShape> shapes;
  const _Legend({required this.shapes});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Partitions',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            for (final s in shapes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: s.color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(s.name, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
