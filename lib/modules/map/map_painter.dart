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
    required this.partitionGroups,
    required this.ref,
    required this.gps,
    this.showPointLabels = false,
  });
  final ProjectionService projection;
  final Offset pan;
  final double scale;
  final double rotation;
  final List borderGroups;
  final List partitionGroups;
  final WidgetRef ref;
  final GpsSample? gps;
  final bool showPointLabels;

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
    final partitionPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 / scale
      ..color = Colors.green.withOpacity(0.8);

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

    for (final g in partitionGroups) {
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
        canvas.drawPath(path, partitionPaint);
      }
    }

    if (gps != null) {
      final xy = projection.project(
        gps!.position.latitude,
        gps!.position.longitude,
      );
      final acc = gps!.acc;
      final accPaint = Paint()..color = Colors.blue.withOpacity(0.15);
      final dot = Paint()..color = Colors.blue;
      canvas.drawCircle(xy, acc, accPaint);
      canvas.drawCircle(xy, 3.0 / scale, dot);
    }

    // Draw points (borders and partitions) as small dots; labels optional
    final pointPaint = Paint()..color = Colors.black87;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    void drawGroupPoints(dynamic g) {
      final ptsAsync = ref.read(pointsByGroupProvider(g.id));
      final pts = ptsAsync.asData?.value ?? const [];
      if (pts.isEmpty) return;
      var idx = 1;
      for (final p in pts) {
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
        gps != old.gps ||
        showPointLabels != old.showPointLabels;
  }
}
