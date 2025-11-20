import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Per-frame delta from a 2-finger gesture.
/// All values are relative to the previous frame.
class TwoFingerUpdate {
  final Offset panDeltaPx; // screen-space pan delta
  final double scaleFactor; // multiplicative scale (>0), 1.0 = no zoom
  final double rotationDelta; // radians, CCW positive
  final Offset focalPointPx; // current 2-finger centroid in screen coords

  const TwoFingerUpdate({
    required this.panDeltaPx,
    required this.scaleFactor,
    required this.rotationDelta,
    required this.focalPointPx,
  });

  static const zero = TwoFingerUpdate(
    panDeltaPx: Offset.zero,
    scaleFactor: 1.0,
    rotationDelta: 0.0,
    focalPointPx: Offset.zero,
  );

  @override
  String toString() {
    String f2(double v) => v.toStringAsFixed(2);
    String f3(double v) => v.toStringAsFixed(3);
    return 'TwoFingerUpdate(pan=(${f2(panDeltaPx.dx)},${f2(panDeltaPx.dy)}), '
        'scale=${f3(scaleFactor)}, dθ=${f3(rotationDelta)}, '
        'focal=(${f2(focalPointPx.dx)},${f2(focalPointPx.dy)}))';
  }
}

/// Raw 2-pointer tracker: given pointer events, computes center, distance, angle
/// and emits frame-by-frame deltas (pan, zoom, rotate).
class TwoFingerGestureEngine {
  // Tunable deadzones (per frame) to avoid noise.
  final double minScaleChange; // e.g. 0.002 ~ 0.2% per frame
  final double rotationDeadZone; // radians, e.g. 0.003 ~ 0.17°

  bool _active = false;
  int? _idA;
  int? _idB;
  Offset _pALast = Offset.zero;
  Offset _pBLast = Offset.zero;

  TwoFingerGestureEngine({
    this.minScaleChange = 0.002,
    this.rotationDeadZone = 0.003,
  });

  bool get isActive => _active;

  void reset() {
    _active = false;
    _idA = null;
    _idB = null;
    _pALast = Offset.zero;
    _pBLast = Offset.zero;
  }

  /// Call on each pointer down.
  void onPointerDown(int pointerId, Offset pos, Map<int, Offset> allPointers) {
    allPointers[pointerId] = pos;
    if (allPointers.length == 2 && !_active) {
      // Start a new 2-finger gesture.
      final ids = allPointers.keys.toList()..sort();
      _idA = ids[0];
      _idB = ids[1];
      _pALast = allPointers[_idA]!;
      _pBLast = allPointers[_idB]!;
      _active = true;
      // No update yet on start frame.
    }
  }

  /// Call on each pointer move. Returns a delta if we have a valid 2-finger frame.
  TwoFingerUpdate onPointerMove(Map<int, Offset> allPointers) {
    if (!_active || _idA == null || _idB == null) {
      return TwoFingerUpdate.zero;
    }
    final pA = allPointers[_idA];
    final pB = allPointers[_idB];
    if (pA == null || pB == null) {
      // One of the tracked pointers vanished; end gesture.
      reset();
      return TwoFingerUpdate.zero;
    }

    // Current center, distance, angle.
    final centerNow = (pA + pB) * 0.5;
    final vecNow = pB - pA;
    final distNow = vecNow.distance;
    final angleNow = math.atan2(vecNow.dy, vecNow.dx);

    // Last center, distance, angle.
    final centerLast = (_pALast + _pBLast) * 0.5;
    final vecLast = _pBLast - _pALast;
    final distLast = vecLast.distance;
    final angleLast = math.atan2(vecLast.dy, vecLast.dx);

    // Pan = center delta.
    final panDelta = centerNow - centerLast;

    // Scale factor = distNow / distLast.
    double scaleFactor = 1.0;
    if (distLast > 0 && distNow > 0) {
      scaleFactor = distNow / distLast;
      if ((scaleFactor - 1.0).abs() < minScaleChange) {
        scaleFactor = 1.0; // ignore tiny noise
      }
    }

    // Rotation = shortest angle delta.
    double dTheta = 0.0;
    double raw = angleNow - angleLast;
    while (raw <= -math.pi) raw += 2 * math.pi;
    while (raw > math.pi) raw -= 2 * math.pi;
    if (raw.abs() >= rotationDeadZone) {
      dTheta = raw;
    }

    // Update last positions.
    _pALast = pA;
    _pBLast = pB;

    return TwoFingerUpdate(
      panDeltaPx: panDelta,
      scaleFactor: scaleFactor,
      rotationDelta: dTheta,
      focalPointPx: centerNow,
    );
  }

  /// Call on up/cancel. If we lose one of the tracked fingers, end the gesture.
  void onPointerUpOrCancel(int pointerId, Map<int, Offset> allPointers) {
    allPointers.remove(pointerId);
    if (pointerId == _idA || pointerId == _idB || allPointers.length < 2) {
      reset();
    }
  }
}
