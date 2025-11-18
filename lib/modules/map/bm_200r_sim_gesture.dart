import 'package:flutter/material.dart';

/// Simple pan + zoom (no rotation).
class SimGestureUpdate {
  final Offset pan; // delta in screen px
  final double scaleFactor; // multiplicative; 1.0 = no zoom

  const SimGestureUpdate({required this.pan, required this.scaleFactor});

  @override
  String toString() => 'SimGestureUpdate(pan=$pan, scaleFactor=$scaleFactor)';
}
