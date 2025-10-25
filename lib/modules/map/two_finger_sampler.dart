// BM-200B.9f: Coalesced two-finger sampler for stable v1/v2
import 'package:flutter/material.dart';

class TwoFingerSample {
  final Offset p1Prev, p2Prev, p1Now, p2Now;
  final double sepPrev, sepNow;
  TwoFingerSample({
    required this.p1Prev,
    required this.p2Prev,
    required this.p1Now,
    required this.p2Now,
    required this.sepPrev,
    required this.sepNow,
  });
}

class TwoFingerSampler {
  // IDs of the locked pair (set when you lock the pair)
  int? id1, id2;

  // Latest observed positions (raw screen px)
  Offset? _p1Now, _p2Now;
  Offset? _p1Prev, _p2Prev;
  double? _sepPrev;

  // Whether we’ve seen a move for each finger since last emit
  bool _p1Moved = false, _p2Moved = false;

  // Emit at most every X ms even if only one finger moves (safety)
  int emitEveryMs = 12; // ~80 Hz max; tune 8–16ms
  int _lastEmitMs = 0;

  void beginGesture({
    required int pointerId1,
    required int pointerId2,
    required Offset p1,
    required Offset p2,
    required int nowMs,
  }) {
    id1 = pointerId1;
    id2 = pointerId2;
    _p1Now = _p1Prev = p1;
    _p2Now = _p2Prev = p2;
    _sepPrev = (p1 - p2).distance;
    _p1Moved = _p2Moved = false;
    _lastEmitMs = nowMs;
  }

  // Call this for each pointer move (both pointers)
  void onPointerMove(int pointerId, Offset pos) {
    if (pointerId == id1) {
      _p1Now = pos;
      _p1Moved = true;
    } else if (pointerId == id2) {
      _p2Now = pos;
      _p2Moved = true;
    }
  }

  // Try to emit a coalesced sample. Returns null if not ready yet.
  TwoFingerSample? tryEmit(int nowMs) {
    if (_p1Now == null ||
        _p2Now == null ||
        _p1Prev == null ||
        _p2Prev == null) {
      return null;
    }

    final bool bothMoved = _p1Moved && _p2Moved;
    final bool timeout = (nowMs - _lastEmitMs) >= emitEveryMs;

    if (!bothMoved && !timeout) return null;

    // Use the most recent positions for BOTH fingers for "now"
    final p1Now = _p1Now!;
    final p2Now = _p2Now!;
    final p1Prev = _p1Prev!;
    final p2Prev = _p2Prev!;
    final sepNow = (p1Now - p2Now).distance;
    final sepPrev = _sepPrev ?? sepNow;

    final sample = TwoFingerSample(
      p1Prev: p1Prev,
      p2Prev: p2Prev,
      p1Now: p1Now,
      p2Now: p2Now,
      sepPrev: sepPrev,
      sepNow: sepNow,
    );

    // Advance prevs only when we emit
    _p1Prev = p1Now;
    _p2Prev = p2Now;
    _sepPrev = sepNow;
    _p1Moved = _p2Moved = false;
    _lastEmitMs = nowMs;
    return sample;
  }

  void endGesture() {
    id1 = id2 = null;
    _p1Now = _p2Now = _p1Prev = _p2Prev = null;
    _sepPrev = null;
    _p1Moved = _p2Moved = false;
  }
}
