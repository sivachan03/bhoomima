import 'package:flutter/material.dart';

import 'bm_200r_gesture_layer.dart';
import 'bm_200r_transform.dart';

class BM200RMapScreen extends StatelessWidget {
  const BM200RMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: load this from stored "familiar view" if you persist it.
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

    // TODO: draw actual field / plots / features here.

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FarmMapPainter oldDelegate) {
    return rot != oldDelegate.rot ||
        scale != oldDelegate.scale ||
        pan != oldDelegate.pan;
  }
}
