import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/projection_service.dart';
import 'map_providers.dart';

class MapPainter extends CustomPainter {
  MapPainter({
    required this.projection,
    required this.pan,
    required this.scale,
    required this.rotation,
    required this.borderGroups,
    required this.ref,
    required this.gps,
  });
  final ProjectionService projection;
  final Offset pan;
  final double scale;
  final double rotation;
  final List borderGroups;
  final WidgetRef ref;
  final GpsSample? gps;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.translate(center.dx + pan.dx, center.dy + pan.dy);
    canvas.rotate(rotation);
    canvas.scale(scale);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0 / scale
      ..color = Colors.green;

    for (final g in borderGroups) {
      final ptsAsync = ref.read(pointsByGroupProvider(g.id));
      final pts = ptsAsync.asData?.value ?? const [];
      if (pts.isEmpty) continue;
      final path = Path();
      var moved = false;
      for (final p in pts) {
        final xy = projection.project(p.lat, p.lon);
        if (!moved) {
          path.moveTo(xy.dx, xy.dy);
          moved = true;
        } else {
          path.lineTo(xy.dx, xy.dy);
        }
      }
      final bounds = path.getBounds();
      if (!bounds.isEmpty) {
        path.close();
        canvas.drawPath(path, borderPaint);
      }
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
  }

  @override
  bool shouldRepaint(covariant MapPainter old) {
    return pan != old.pan ||
        scale != old.scale ||
        rotation != old.rotation ||
        borderGroups != old.borderGroups ||
        gps != old.gps;
  }
}
