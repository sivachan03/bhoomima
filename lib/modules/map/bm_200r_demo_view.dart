import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4;

import 'bm_200r_gesture_layer.dart';
import 'bm_200r_transform.dart';

class BM200RDemoView extends StatelessWidget {
  const BM200RDemoView({super.key});

  @override
  Widget build(BuildContext context) {
    // Start with a modest offset so the sample rectangle is visible.
    const initial = MapTransform(tx: 200, ty: 200, scale: 1.0, theta: 0.0);

    return Scaffold(
      appBar: AppBar(title: const Text('BM‑200R Demo')),
      body: BM200RGestureLayer(
        initialTransform: initial,
        builder: (ctx, t) {
          final m = Matrix4.identity()
            ..translate(t.tx, t.ty)
            ..rotateZ(t.theta)
            ..scale(t.scale);
          return Transform(
            transform: m,
            child: CustomPaint(
              painter: _RectPainter(),
              child: const SizedBox.expand(),
            ),
          );
        },
      ),
    );
  }
}

class _RectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // World-space rectangle centered around origin (0,0)
    const w = 300.0;
    const h = 200.0;
    final rect = Rect.fromCenter(center: Offset.zero, width: w, height: h);
    canvas.drawRect(rect, paint);

    // Crosshair at origin
    canvas.drawLine(const Offset(-20, 0), const Offset(20, 0), paint);
    canvas.drawLine(const Offset(0, -20), const Offset(0, 20), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
