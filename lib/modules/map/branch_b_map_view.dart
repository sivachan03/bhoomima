import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
// Controllers are exported by photo_view.dart

/// Branch B: PhotoView-based Map View
///
/// - PhotoView owns pan + pinch-zoom + rotation (gesture rotation ON).
/// - Your map content (CustomPaint + overlays) is built by [mapChildBuilder].
/// - Buttons at bottom-right: zoom in/out, rotate left/right, home.
/// - BM-200R TransformModel / SimGesture are NOT used in this branch.
class BranchBMapView extends StatefulWidget {
  const BranchBMapView({Key? key, required this.mapChildBuilder})
    : super(key: key);

  /// Build the full map canvas (CustomPaint + markers + overlays) for the
  /// given viewport size. This is everything that should pan/zoom/rotate.
  final Widget Function(Size size) mapChildBuilder;

  @override
  State<BranchBMapView> createState() => _BranchBMapViewState();
}

class _BranchBMapViewState extends State<BranchBMapView> {
  late final PhotoViewController _controller;
  late final PhotoViewScaleStateController _scaleStateController;

  double? _initialScale;
  static const double _minScaleFactor = 0.7; // tune as you like
  static const double _maxScaleFactor = 4.0;

  @override
  void initState() {
    super.initState();
    _controller = PhotoViewController();
    _scaleStateController = PhotoViewScaleStateController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleStateController.dispose();
    super.dispose();
  }

  void _ensureInitialScale(double viewWidth, double viewHeight) {
    if (_initialScale != null) return;

    // For now, treat map child as "fits" the viewport at scale = 1.0.
    // If your map content uses a different logical size, we can refine this later.
    _initialScale = 1.0;
    _controller.scale = _initialScale;
    _controller.position = Offset.zero;
    _controller.rotation = 0.0;
  }

  void _zoomByFactor(double factor) {
    final current = _controller.value.scale ?? _initialScale ?? 1.0;
    final base = _initialScale ?? current;
    final minScale = base * _minScaleFactor;
    final maxScale = base * _maxScaleFactor;
    final next = (current * factor).clamp(minScale, maxScale);
    _controller.scale = next;
    debugPrint(
      '[PV] btn zoom factor=$factor → scale=${next.toStringAsFixed(3)}',
    );
  }

  void _rotateByDegrees(double degrees) {
    final rad = degrees * math.pi / 180.0;
    final current = _controller.value.rotation;
    _controller.rotation = current + rad;
    debugPrint(
      '[PV] btn rotate dDeg=${degrees.toStringAsFixed(1)} → rot=${_controller.value.rotation.toStringAsFixed(3)}',
    );
  }

  void _home() {
    if (_initialScale == null) {
      _controller.position = Offset.zero;
      _controller.rotation = 0.0;
      debugPrint('[PV] home (pre-init)');
      return;
    }
    _controller.scale = _initialScale;
    _controller.position = Offset.zero;
    _controller.rotation = 0.0;
    debugPrint(
      '[PV] home → scale=${_initialScale!.toStringAsFixed(3)} rot=0.000 pos=0,0',
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        final Size viewSize = Size(constraints.maxWidth, constraints.maxHeight);

        _ensureInitialScale(viewSize.width, viewSize.height);

        final double base = _initialScale ?? 1.0;
        final double minScale = base * _minScaleFactor;
        final double maxScale = base * _maxScaleFactor;

        return Stack(
          children: [
            // Everything inside PhotoView will pan/zoom/rotate together.
            ClipRect(
              child: PhotoView.customChild(
                controller: _controller,
                scaleStateController: _scaleStateController,
                enableRotation: true, // R1: rotation about gesture center
                backgroundDecoration: const BoxDecoration(
                  color: Colors.black, // or your background
                ),
                minScale: minScale,
                maxScale: maxScale,
                childSize: viewSize,
                child: SizedBox(
                  width: viewSize.width,
                  height: viewSize.height,
                  child: widget.mapChildBuilder(viewSize),
                ),
              ),
            ),

            // Fixed-position controls (do not rotate/zoom with map)
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom in
                  FloatingActionButton.small(
                    heroTag: 'branchB_zoom_in',
                    onPressed: () => _zoomByFactor(1.12),
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),

                  // Zoom out
                  FloatingActionButton.small(
                    heroTag: 'branchB_zoom_out',
                    onPressed: () => _zoomByFactor(1.0 / 1.12),
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 16),

                  // Rotate left
                  FloatingActionButton.small(
                    heroTag: 'branchB_rot_left',
                    onPressed: () => _rotateByDegrees(-5),
                    child: const Icon(Icons.rotate_left),
                  ),
                  const SizedBox(height: 8),

                  // Rotate right
                  FloatingActionButton.small(
                    heroTag: 'branchB_rot_right',
                    onPressed: () => _rotateByDegrees(5),
                    child: const Icon(Icons.rotate_right),
                  ),
                  const SizedBox(height: 16),

                  // Home: reset scale/position/rotation
                  FloatingActionButton.small(
                    heroTag: 'branchB_home',
                    onPressed: _home,
                    child: const Icon(Icons.home),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
