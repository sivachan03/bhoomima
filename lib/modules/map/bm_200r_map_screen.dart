import 'package:flutter/material.dart';

import 'bm_200r_gesture_layer.dart';
import 'bm_200r_transform.dart';

class BM200RMapScreen extends StatelessWidget {
  const BM200RMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initial transform; replace via persistence layer (e.g. last familiar view) when available.
    const MapTransform initial = MapTransform(
      tx: 0,
      ty: 0,
      scale: 1.0,
      theta: 0.0,
    );

    // Example world bounds in map units; replace with real farm bounds.
    final Rect worldBounds = Rect.fromLTWH(0, 0, 1000, 1000);

    return Scaffold(
      body: SafeArea(
        child: BM200RGestureLayer(
          initialTransform: initial,
          worldBounds: worldBounds,
          builder: (ctx, transform) {
            return CustomPaint(
              painter: FarmMapPainter(
                rot: transform.theta,
                scale: transform.scale,
                pan: Offset(transform.tx, transform.ty),
              ),
              child: Container(), // size via LayoutBuilder.
            );
          },
        ),
      ),
    );
  }
}

/// Stub – wire to your real farm painter.
class FarmMapPainter extends CustomPainter {
  final double rot;
  final double scale;
  final Offset pan;

  FarmMapPainter({required this.rot, required this.scale, required this.pan});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(pan.dx, pan.dy);
    canvas.rotate(rot);
    canvas.scale(scale);
    // Placeholder farm boundary (0..1000 square) and simple 2x2 plot grid.
    const farmRect = Rect.fromLTWH(0, 0, 1000, 1000);
    final boundary = Paint()
      ..color = Colors.green.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 / scale;
    canvas.drawRect(farmRect, boundary);

    final plotFill = Paint()
      ..color = Colors.green.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    const cellW = 500.0;
    const cellH = 500.0;
    for (int gx = 0; gx < 2; gx++) {
      for (int gy = 0; gy < 2; gy++) {
        final cell = Rect.fromLTWH(
          gx * cellW,
          gy * cellH,
          cellW,
          cellH,
        ).deflate(24);
        canvas.drawRect(cell, plotFill);
        canvas.drawRect(cell, boundary..strokeWidth = 1.2 / scale);
      }
    }

    // Origin crosshair.
    final cross = Paint()
      ..color = Colors.red
      ..strokeWidth = 2 / scale;
    canvas.drawLine(const Offset(-30, 0), const Offset(30, 0), cross);
    canvas.drawLine(const Offset(0, -30), const Offset(0, 30), cross);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FarmMapPainter oldDelegate) {
    return rot != oldDelegate.rot ||
        scale != oldDelegate.scale ||
        pan != oldDelegate.pan;
  }
}
