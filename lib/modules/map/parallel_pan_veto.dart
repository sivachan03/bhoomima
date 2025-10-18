// BM-200B.9e: Parallel pan veto detector
import 'dart:math' as math;
import 'package:flutter/material.dart';

class ParallelPanVeto {
  // Tunables (you can tweak later)
  double pxPerFrameStrong = 2.0; // motion strength gate (raise to avoid jitter)
  double alpha = 0.25; // EMA smoothing (≈150–200 ms feel)
  double cosParThreshold = 0.90; // parallel enough
  double sepFracThreshold = 0.008; // slightly tighter to avoid micro-zoom

  // State (per-gesture)
  Offset? _p1Prev, _p2Prev;
  double? _sepPrev;
  bool _hasPrev = false;

  // Smoothed signals (for logs & decision)
  double cosParAvg = 0.0;
  double sepFracAvg = 0.0;

  // Config: MUST be false for this detector
  bool relToCentroid = false;

  void beginGesture() {
    _p1Prev = null;
    _p2Prev = null;
    _sepPrev = null;
    _hasPrev = false;
    cosParAvg = 0.0;
    sepFracAvg = 0.0;
    debugPrint('[BM-200B.9e CFG] relToCentroid=$relToCentroid');
  }

  // Supply the two current finger positions in SCREEN pixels.
  // Returns parVeto: true => treat as parallel pan (block rot/zoom this frame).
  bool update({required Offset p1_now, required Offset p2_now}) {
    // Keep the names you asked for, for clarity:
    final Offset? p1_prev = _p1Prev;
    final Offset? p2_prev = _p2Prev;

    // Need two frames to make deltas
    if (!_hasPrev || p1_prev == null || p2_prev == null) {
      _p1Prev = p1_now;
      _p2Prev = p2_now;
      _sepPrev = (p1_now - p2_now).distance;
      _hasPrev = true;
      // First frame: no decision yet
      debugPrint(
        '[BM-200B.9e PAR] parVeto=false strong=false '
        'mag1=0.0 mag2=0.0 cosParRaw=0.000 cosParAvg=${cosParAvg.toStringAsFixed(3)} '
        'sepFracAvg=${sepFracAvg.toStringAsFixed(3)}',
      );
      return false;
    }

    // Raw per-finger deltas in SCREEN px (NO centroid subtraction)
    final Offset v1 =
        p1_now - p1_prev; // <- your requested v1 (p1_now - p1_prev)
    final Offset v2 =
        p2_now - p2_prev; // <- your requested v2 (p2_now - p2_prev)

    final double mag1 = v1.distance;
    final double mag2 = v2.distance;

    // cosParRaw = dot(v1, v2) / (|v1||v2| + 1e-6)
    final double denom = (mag1 * mag2) + 1e-6;
    final double cosParRaw = ((v1.dx * v2.dx) + (v1.dy * v2.dy)) / denom;

    // sepFracRaw = |sep_now − sep_prev| / max(sep_now, sep_prev, 1)
    final double sep_now = (p1_now - p2_now).distance;
    final double sep_prev = _sepPrev ?? sep_now;
    final double sepFracRaw =
        (sep_now - sep_prev).abs() / math.max(math.max(sep_now, sep_prev), 1.0);

    // EMA smoothing
    if (!_hasPrev) {
      cosParAvg = cosParRaw;
      sepFracAvg = sepFracRaw;
    } else {
      cosParAvg = alpha * cosParRaw + (1 - alpha) * cosParAvg;
      sepFracAvg = alpha * sepFracRaw + (1 - alpha) * sepFracAvg;
    }

    // Strength gate (ignore jittery frames)
    final bool strong =
        (mag1 >= pxPerFrameStrong) || (mag2 >= pxPerFrameStrong);

    // Decision (this is your "parallelLike")
    final bool parallelLike =
        (cosParAvg > cosParThreshold) &&
        (sepFracAvg < sepFracThreshold) &&
        strong;

    // For pan, we veto rot/zoom
    final bool parVeto = parallelLike;

    // Logging in your exact style
    debugPrint(
      '[BM-200B.9e PAR] parVeto=$parVeto strong=$strong '
      'mag1=${mag1.toStringAsFixed(1)} mag2=${mag2.toStringAsFixed(1)} '
      'cosParRaw=${cosParRaw.toStringAsFixed(3)} cosParAvg=${cosParAvg.toStringAsFixed(3)} '
      'sepFracAvg=${sepFracAvg.toStringAsFixed(3)}',
    );

    // Advance "prev" for next frame
    _p1Prev = p1_now;
    _p2Prev = p2_now;
    _sepPrev = sep_now;
    _hasPrev = true;

    return parVeto;
  }

  void endGesture() {
    // optional: nothing required
  }
}
