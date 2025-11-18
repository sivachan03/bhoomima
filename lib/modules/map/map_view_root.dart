import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'branch_b_map_view.dart';
import 'map_view.dart';
// import 'map_painter.dart';
// import '../../core/services/projection_service.dart';
// import '../../core/models/point_group.dart';
// import 'transform_model.dart';

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
  const MapViewRoot({super.key, this.useBranchB = true});
  final bool useBranchB; // flip to true to try PhotoView branch

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!useBranchB) {
      return const MapViewScreen();
    }
    debugPrint('[PV] BranchBMapView ACTIVE');

    // Branch B content builder: this should replicate what MapViewScreen paints
    // WITHOUT reading gesture transforms from the SM/TransformModel. For now, we
    // instantiate a fresh TransformModel in "home" state (tx=ty=0, scale=1, rot=0).
    // If you have world bounds fitting logic, integrate it here later.
    // final TransformModel homeXform = TransformModel(suppressLogs: true);

    return BranchBMapView(
      mapChildBuilder: (Size size) {
        // Branch B debug: ignore MapPainter for now; just show a visible grid.
        debugPrint(
          '[PV] BranchB mapChildBuilder size=(${size.width}, ${size.height})',
        );
        return CustomPaint(
          painter: DebugGridPainter(),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
