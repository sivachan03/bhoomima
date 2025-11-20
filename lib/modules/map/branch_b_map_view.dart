import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
// Controllers are exported by photo_view.dart

/// Branch B: PhotoView-based Map View
///
/// After BM-200PV.5:
/// Gesture model (PhotoView defaults):
///   • 1-finger drag → pure pan.
///   • 2-finger pinch/drag → combined pan + zoom (PhotoView continuously
///     interprets distance changes; slight “zoom noise” is normal if fingers
///     aren’t perfectly parallel).
///   • Gesture rotation OFF (enableRotation=false) → eliminates accidental tilt.
///   • Rotation ONLY via buttons (±5° increments calling controller.rotation).
/// Notes:
///   - As scale grows >1.0 the farm exceeds the viewport; edges disappear
///     progressively. This is normal photo-style cropping, not a geometry bug.
///     Future tuning (if desired) could add soft clamps or dynamic margins to
///     keep more context visible.
///   - Background is solid black via backgroundDecoration; real map is painted
///     above it using CustomPaint.
///   - TransformModel / SimGesture not used; PhotoView is the sole geometry engine.
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
    // Fallback logging: schedule a post-frame callback to log controller value.
    // If PhotoViewController is a ValueNotifier in your dependency version you can
    // switch back to addListener; otherwise this passive tick ensures visibility.
    WidgetsBinding.instance.addPostFrameCallback((_) => _logController());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleStateController.dispose();
    super.dispose();
  }

  void _ensureInitialScale(double viewWidth, double viewHeight) {
    if (_initialScale != null) return;

    _initialScale = 1.0;
    _controller.scale = _initialScale;
    _controller.position = Offset.zero;
    _controller.rotation = 0.0;

    debugPrint(
      '[PV] init scale=$_initialScale view=(${viewWidth.toStringAsFixed(1)},${viewHeight.toStringAsFixed(1)})',
    );
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

  void _logController() {
    final v = _controller.value;
    final scale = (v.scale ?? _initialScale ?? 1.0).toStringAsFixed(3);
    final dx = v.position.dx.toStringAsFixed(1);
    final dy = v.position.dy.toStringAsFixed(1);
    final rot = v.rotation.toStringAsFixed(3);
    debugPrint('[PV] ctrl scale=$scale pos=($dx,$dy) rot=$rot');
    // Re-arm next frame for continuous updates while widget alive.
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _logController());
    }
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

        debugPrint(
          '[PV] build viewSize=(${viewSize.width.toStringAsFixed(1)},${viewSize.height.toStringAsFixed(1)}) '
          'minScale=${minScale.toStringAsFixed(3)} maxScale=${maxScale.toStringAsFixed(3)}',
        );

        return Stack(
          children: [
            ClipRect(
              child: PhotoView.customChild(
                controller: _controller,
                scaleStateController: _scaleStateController,
                enableRotation:
                    false, // gesture rotation OFF; buttons still rotate
                backgroundDecoration: const BoxDecoration(color: Colors.white),
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
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'branchB_zoom_in',
                    onPressed: () => _zoomByFactor(1.12),
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'branchB_zoom_out',
                    onPressed: () => _zoomByFactor(1.0 / 1.12),
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton.small(
                    heroTag: 'branchB_rot_left',
                    onPressed: () => _rotateByDegrees(-5),
                    child: const Icon(Icons.rotate_left),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'branchB_rot_right',
                    onPressed: () => _rotateByDegrees(5),
                    child: const Icon(Icons.rotate_right),
                  ),
                  const SizedBox(height: 16),
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
