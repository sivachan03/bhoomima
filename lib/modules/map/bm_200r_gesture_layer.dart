// bm_200r_gesture_layer.dart
// Gesture layer: 2-finger pan+zoom, no gesture-rotate. Button rotate only.

import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'bm_200r_transform.dart';
import 'sim_transform_gesture.dart' as sim;

typedef MapPainterBuilder =
    Widget Function(BuildContext context, MapTransform transform);

class BM200RGestureLayer extends StatefulWidget {
  final MapTransform initialTransform;
  final MapPainterBuilder builder;

  /// Optional world bounds in "map space" if you want clamping.
  final Rect? worldBounds;
  final double minScale;
  final double maxScale;

  const BM200RGestureLayer({
    super.key,
    required this.initialTransform,
    required this.builder,
    this.worldBounds,
    this.minScale = 0.5,
    this.maxScale = 5.0,
  });

  @override
  State<BM200RGestureLayer> createState() => _BM200RGestureLayerState();
}

class _BM200RGestureLayerState extends State<BM200RGestureLayer> {
  late MapTransform _transform;

  // Track active pointer positions to compute p1/p2 for two-finger updates
  final Map<int, Offset> _pointers = <int, Offset>{};

  // BM-200R3.0: pan-only SIM; no gesture zoom/rotate.
  late final sim.SimTransformGesture _simGesture = sim.SimTransformGesture();
  // High-zoom edge disappearance (expected): at scales around 3.5–4.0 the
  // viewport physically cannot show the entire world bounds; clamp ensures some
  // portion stays visible, so opposite sides leave view. Future refinements may
  // pivot zoom at focalPoint and soften clamp; for v1 this is by design.

  @override
  void initState() {
    super.initState();
    _transform = widget.initialTransform;
  }

  void _onScaleStart(ScaleStartDetails details) {
    // Only initialize two-finger detector when exactly two pointers are down.
    if (details.pointerCount == 2) {
      final _pair = _getTwoPointerOffsets();
      if (_pair != null) {
        _simGesture.start(_pair.$1, _pair.$2);
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size viewportSize) {
    final pointerCount = details.pointerCount;

    // 1 finger: NO geometry change. No calls into the 2-finger path.
    if (pointerCount == 1) {
      return;
    }

    // 2+ fingers: feed two-pointer positions into SimTransformGesture.
    final pair = _getTwoPointerOffsets();
    if (pair == null) return; // not enough data yet
    if (!_simGesture.isActive) {
      _simGesture.start(pair.$1, pair.$2); // late start if needed
    }
    final sim.SimGestureUpdate u = _simGesture.update(pair.$1, pair.$2);
    if (identical(u, sim.SimGestureUpdate.zero)) return;

    // Apply incremental pan only; ignore zoom/rotation.
    final MapTransform next = _applySimUpdatePanOnly(u);
    debugPrint('[APPLY] sim pan-only $next');

    setState(() {
      _transform = _clampTransform(next, viewportSize);
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    // End two-finger sequence; no inertia for now.
    _simGesture.end();
  }

  /// Apply pan-only SIM update.
  MapTransform _applySimUpdatePanOnly(sim.SimGestureUpdate u) {
    return _transform.copyWith(
      tx: _transform.tx + u.panDeltaPx.dx,
      ty: _transform.ty + u.panDeltaPx.dy,
    );
  }

  MapTransform _clampTransform(MapTransform t, Size viewportSize) {
    if (widget.worldBounds == null) {
      return t;
    }

    final Rect bounds = widget.worldBounds!;
    final double S = t.scale;

    // Approx: ignore rotation when clamping, keeps math simple.
    final Rect mapScreenRect = Rect.fromLTWH(
      bounds.left * S + t.tx,
      bounds.top * S + t.ty,
      bounds.width * S,
      bounds.height * S,
    );

    double tx = t.tx;
    double ty = t.ty;

    const double margin = 32.0;

    if (mapScreenRect.right < margin) {
      tx += (margin - mapScreenRect.right);
    }
    if (mapScreenRect.left > viewportSize.width - margin) {
      tx -= (mapScreenRect.left - (viewportSize.width - margin));
    }
    if (mapScreenRect.bottom < margin) {
      ty += (margin - mapScreenRect.bottom);
    }
    if (mapScreenRect.top > viewportSize.height - margin) {
      ty -= (mapScreenRect.top - (viewportSize.height - margin));
    }

    return t.copyWith(tx: tx, ty: ty);
  }

  void _rotateBy(double dDegrees, Size viewportSize) {
    final double dTheta = dDegrees * math.pi / 180.0;
    final MapTransform next = _transform.rotatedBy(dTheta);

    debugPrint('[BM-200R] button-rotate d=$dDegrees° => $next');

    setState(() {
      _transform = _clampTransform(next, viewportSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final Size viewportSize = constraints.biggest;

        debugPrint(
          '[BM-190] PAINT rot=${_transform.theta} scale=${_transform.scale} pan=(${_transform.tx}, ${_transform.ty})',
        );

        return Stack(
          children: [
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) => _pointers[e.pointer] = e.localPosition,
              onPointerMove: (e) => _pointers[e.pointer] = e.localPosition,
              onPointerUp: (e) => _pointers.remove(e.pointer),
              onPointerCancel: (e) => _pointers.remove(e.pointer),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: _onScaleStart,
                onScaleUpdate: (details) =>
                    _onScaleUpdate(details, viewportSize),
                onScaleEnd: _onScaleEnd,
                child: widget.builder(ctx, _transform),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'bm200r_rotate_left',
                    onPressed: () => _rotateBy(-5, viewportSize),
                    child: const Icon(Icons.rotate_left),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'bm200r_rotate_right',
                    onPressed: () => _rotateBy(5, viewportSize),
                    child: const Icon(Icons.rotate_right),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // Returns the first two active pointer offsets, or null if fewer than two.
  (Offset, Offset)? _getTwoPointerOffsets() {
    if (_pointers.length < 2) return null;
    final it = _pointers.values.take(2).toList(growable: false);
    return (it[0], it[1]);
  }
}
