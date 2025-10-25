// BM-199B.1 P1: two-point partition plumbing
// Provides stable two-pointer pairing and per-frame kinematics for diagnostics.

import 'package:flutter/widgets.dart';
import 'dart:math' as math;

class TwoPointState {
  final int id1;
  final int id2;
  final Offset p1;
  final Offset p2;
  final Offset centroid;
  final double sepPx;
  final double headingRad;
  final Offset d1;
  final Offset d2;

  const TwoPointState({
    required this.id1,
    required this.id2,
    required this.p1,
    required this.p2,
    required this.centroid,
    required this.sepPx,
    required this.headingRad,
    required this.d1,
    required this.d2,
  });
}

class TwoPointPartition {
  int? _id1;
  int? _id2;
  Offset? _prevP1;
  Offset? _prevP2;
  bool get active => _id1 != null && _id2 != null;
  int? get id1 => _id1;
  int? get id2 => _id2;

  void begin({
    required int id1,
    required int id2,
    required Offset p1,
    required Offset p2,
  }) {
    _id1 = id1;
    _id2 = id2;
    _prevP1 = p1;
    _prevP2 = p2;
  }

  void end() {
    _id1 = null;
    _id2 = null;
    _prevP1 = null;
    _prevP2 = null;
  }

  // Update with current positions; returns current state with deltas from previous frame.
  TwoPointState update({required Offset p1, required Offset p2}) {
    if (!active) {
      throw StateError('TwoPointPartition.update called while inactive');
    }
    final id1 = _id1!;
    final id2 = _id2!;
    final Offset d1 = _prevP1 == null ? Offset.zero : (p1 - _prevP1!);
    final Offset d2 = _prevP2 == null ? Offset.zero : (p2 - _prevP2!);
    _prevP1 = p1;
    _prevP2 = p2;
    final Offset v = p2 - p1;
    final double sep = v.distance;
    final double heading = math.atan2(v.dy, v.dx);
    final Offset c = Offset((p1.dx + p2.dx) * 0.5, (p1.dy + p2.dy) * 0.5);
    return TwoPointState(
      id1: id1,
      id2: id2,
      p1: p1,
      p2: p2,
      centroid: c,
      sepPx: sep,
      headingRad: heading,
      d1: d1,
      d2: d2,
    );
  }
}
