import 'package:flutter/material.dart';

class SimGestureUpdate {
  final Offset panDeltaPx;
  final double scaleFactor;
  final double rotationDelta;

  const SimGestureUpdate({
    required this.panDeltaPx,
    required this.scaleFactor,
    required this.rotationDelta,
  });

  static const zero = SimGestureUpdate(
    panDeltaPx: Offset.zero,
    scaleFactor: 1.0,
    rotationDelta: 0.0,
  );

  @override
  String toString() {
    String fmt2(double v) => v.toStringAsFixed(2);
    final panStr =
        '(${panDeltaPx.dx.toStringAsFixed(2)}, ${panDeltaPx.dy.toStringAsFixed(2)})';
    return 'SimGestureUpdate(pan=$panStr, scaleFactor=${fmt2(scaleFactor)}, dθ=${rotationDelta.toStringAsFixed(3)})';
  }
}

/// FINAL: 2-finger PAN-ONLY detector.
/// No zoom, no rotate – scaleFactor always 1.0, rotationDelta always 0.0.
class SimTransformGesture {
  SimTransformGesture();

  bool _active = false;
  Offset _p1Last = Offset.zero;
  Offset _p2Last = Offset.zero;

  bool get isActive => _active;

  void start(Offset p1, Offset p2) {
    _active = true;
    _p1Last = p1;
    _p2Last = p2;
  }

  void end() {
    _active = false;
  }

  SimGestureUpdate update(Offset p1, Offset p2) {
    if (!_active) return SimGestureUpdate.zero;

    final centerNow = (p1 + p2) * 0.5;
    final centerLast = (_p1Last + _p2Last) * 0.5;
    final panDeltaPx = centerNow - centerLast;

    _p1Last = p1;
    _p2Last = p2;

    return SimGestureUpdate(
      panDeltaPx: panDeltaPx,
      scaleFactor: 1.0,
      rotationDelta: 0.0,
    );
  }
}
