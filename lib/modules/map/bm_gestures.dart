import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;
import 'parallel_pan_veto.dart'; // BM-200B.9h single-state module

/// BmGestureEngine: Extracted core for two-finger rotate/zoom with anchored apply.
/// Implements BM-200B.6 windowed gating and BM-200B.8 EMA-based parallel veto.
class BmGestureEngine {
  // Touch-ID locking state
  int? _touchIdA;
  int? _touchIdB;
  // Tunables
  static const int windowMs = 220;
  static const int dwellMs = 180;
  static const double minSepPx = 96.0; // logical px
  static const double rotHys = 0.22; // rad (accum window)
  static const double zoomHys = 0.06; // |log| (accum window)
  static const double minRotRate = 0.35; // rad/s
  static const double minZoomRate = 0.30; // |log|/s
  // BM-200B.8 parallel veto
  static const double vMinPxS = 20.0;
  static const double emaAlpha = 0.30;
  static const double cosParThresh = 0.995; // BM-200B.9d stricter
  static const double sepFracThresh = 0.010; // BM-200B.9d tiny squeeze allowed
  static const double minPxPerFrame =
      1.5; // F1: per-frame displacement strong gate

  // State
  Matrix4 M = Matrix4.identity();
  Offset? aWorldLock; // world pivot when locked
  Offset? aScreenLock; // screen at lock time (diagnostics)
  int _gateOnSinceMs = -1;
  bool? _gateRotate;
  double rotAccum = 0.0, zoomAccum = 0.0;
  final List<_Win> _win = <_Win>[];
  // Parallel veto EMA
  double _cosParAvg = 0.0, _sepFracAvg = 0.0;
  Offset _v1E = Offset.zero, _v2E = Offset.zero;
  bool _pvHavePrev = false;
  Offset _p1Prev = Offset.zero, _p2Prev = Offset.zero;
  double _tPrevMs = 0.0;
  bool _parVeto = false;
  // Last small deltas
  double _dTheta = 0.0, _dScale = 1.0;
  Offset _panDelta = Offset.zero;
  // Mode
  bool _locked = false;

  // --- Parallel-pan (9h) state (single source of truth) ---
  // ignore: unused_field
  final ParallelPanVeto _par9h = ParallelPanVeto();
  // ignore: unused_field
  ParallelPanVetoState _parState = const ParallelPanVetoState.initial();

  void onPointerPairStart(Offset p1, Offset p2, int tMs) {
    // Example: pass true touch IDs (not array indices)
    // You must set _touchIdA/_touchIdB from your gesture recognizer's touch events
    // For demonstration, assume you receive them as arguments (update your API as needed)
    // Example log:
    debugPrint('[BM-199 IDLOCK begin: A=$_touchIdA B=$_touchIdB]');
    _win.clear();
    rotAccum = zoomAccum = 0.0;
    _gateOnSinceMs = -1;
    _gateRotate = null;
    _cosParAvg = 0.0;
    _sepFracAvg = 0.0;
    _v1E = Offset.zero;
    _v2E = Offset.zero;
    _pvHavePrev = false;
    _p1Prev = p1;
    _p2Prev = p2;
    _tPrevMs = tMs.toDouble();
    _parVeto = false;
    _locked = false;
    aWorldLock = null;
    aScreenLock = null;
    _dTheta = 0.0;
    _dScale = 1.0;
    _panDelta = Offset.zero;
  }

  void onPointerPairUpdate(Offset p1, Offset p2, int tMs) {
    // === BM-200B.9h: compute, once per frame, before anything else ===
    // Pass true touch IDs for A/B (not array indices)
    // Guard: reject new pairing if locked (until both fingers lift)
    if (_locked && (_touchIdA != null && _touchIdB != null)) {
      // If locked, do not accept new pairings
      debugPrint(
        '[BM-199 IDLOCK: reject new pairing, still locked A=$_touchIdA B=$_touchIdB]',
      );
      return;
    }
    // Pass the correct touch IDs to 9h (update your API if needed)
    _parState = _par9h.updateAndGet(p1_now: p1, p2_now: p2);
    // Optional: one clean log so we can correlate:
    const bool debugLogging = true;
    if (debugLogging) {
      debugPrint(
        '[BM-200B.9h PAR] gid=${_parState.gestureId} '
        'seq=${_parState.frameSeq} ver=${_parState.stateVersion} '
        'computed=${_parState.frameValid} effective=${_parState.parVeto} '
        'cosParAvg=${_parState.cosParAvg.toStringAsFixed(3)} sepFracAvg=${_parState.sepFracAvg.toStringAsFixed(3)} '
        'validN=${_parState.validN}',
      );
    }
    // ...existing code for window, gating, apply, etc. (now use _parState everywhere)...
  }

  /// Build per-frame local delta R(dθ) and S(dScale) and pan delta.
  /// Caller provides rm/sm and tm components from gesture detector.
  void buildLocalDelta({
    required Matrix4 rm,
    required Matrix4 sm,
    required Matrix4 tm,
  }) {
    // --- Enforce freeze & veto in Apply/Lock ---
    final bool parVeto = _parState.parVeto; // single truth
    final bool freeze = _parState.freezeActive; // first ~100 ms after entry
    const bool debugLogging = true;
    if (freeze) {
      _dTheta = 0.0;
      _dScale = 0.0;
      // Pan by centroid delta if needed
      if (debugLogging)
        debugPrint(
          '[FREEZE] active t=${_parState.freezeAgeMs}ms parVeto=$parVeto → suppress {Apply, Locks}',
        );
    } else if (parVeto) {
      _dTheta = 0.0;
      _dScale = 0.0;
      // Pan is allowed
    } else {
      _dTheta = _angleFrom(rm);
      _dScale = _scaleFrom(sm);
    }
    // tm is used as pan before lock; ignored after lock
    if (!_locked) {
      final dx = tm.entry(0, 3);
      final dy = tm.entry(1, 3);
      _panDelta = Offset(dx, dy);
    } else {
      _panDelta = Offset.zero;
    }
  }

  /// Apply anchored delta in world space: M ← M · T(Aw)·R·S·T(−Aw), then add pan if any.
  void applyAnchoredDelta() {
    // --- Enforce freeze & veto in Apply/Lock ---
    final bool parVeto = _parState.parVeto;
    final bool freeze = _parState.freezeActive;
    double dTheta = _dTheta;
    double dScale = _dScale;
    if (freeze) {
      dTheta = 0.0;
      dScale = 0.0;
    } else if (parVeto) {
      dTheta = 0.0;
      dScale = 0.0;
    }
    if (_locked && aWorldLock != null) {
      final ax = aWorldLock!.dx, ay = aWorldLock!.dy;
      final Matrix4 TposLocal = Matrix4.identity()..translate(ax, ay);
      final Matrix4 TnegLocal = Matrix4.identity()..translate(-ax, -ay);
      final Matrix4 R = Matrix4.identity()..rotateZ(dTheta);
      final Matrix4 S = Matrix4.identity()..scale(dScale);
      final Matrix4 G = TposLocal * R * S * TnegLocal;
      M = M * G;
    }
    if (_panDelta != Offset.zero) {
      final Matrix4 T = Matrix4.identity()
        ..translate(_panDelta.dx, _panDelta.dy);
      M = T * M;
    }
  }

  bool get isLocked => _locked;
  // All gating/telemetry now uses _parState (single source of truth)
  String get parVetoStr => _parState.parVetoStr;
  String get cosParAvgStr => _parState.cosParAvgStr;
  String get sepFracAvgStr => _parState.sepFracAvgStr;
  bool get parVeto => _parState.parVeto;
  double get dTheta => _dTheta;
  double get dScale => _dScale;
  Offset? get worldAnchor => aWorldLock;
  // Allow external controller (e.g., MapView) to own lock decisions
  void setLocked(bool value) {
    _locked = value;
  }

  // Allow setting world anchor directly when lock is made outside
  void setWorldAnchor(Offset aWorld) {
    aWorldLock = aWorld;
    aScreenLock = null;
  }

  void setWorldAnchorFromScreen(Offset aScreen) {
    final inv = Matrix4.inverted(M);
    final v = inv.transform3(Vector3(aScreen.dx, aScreen.dy, 0));
    aWorldLock = Offset(v.x, v.y);
    aScreenLock = aScreen;
  }

  // --- internals ---
  double _angleFrom(Matrix4 rm) {
    final double c = rm.entry(0, 0);
    final double s = rm.entry(1, 0);
    return math.atan2(s, c);
  }

  double _scaleFrom(Matrix4 sm) {
    final double sx = sm.entry(0, 0);
    return sx == 0.0 ? 1.0 : sx;
  }

  void _updateParallelVeto(Offset p1, Offset p2, double tNowMs) {
    if (!_pvHavePrev) {
      _pvHavePrev = true;
      _p1Prev = p1;
      _p2Prev = p2;
      _tPrevMs = tNowMs;
      _cosParAvg = 0.0;
      _sepFracAvg = 0.0;
      _v1E = Offset.zero;
      _v2E = Offset.zero;
      _parVeto = false;
      return;
    }
    double dt = (tNowMs - _tPrevMs).abs();
    if (dt < 1.0) dt = 1.0;
    if (dt > 100.0) dt = 100.0;
    final double invDt = 1000.0 / dt;
    final Offset d1 = p1 - _p1Prev;
    final Offset d2 = p2 - _p2Prev;
    // F1 validity gate: require max(|Δp1|,|Δp2|) ≥ minPxPerFrame
    if (math.max(d1.distance, d2.distance) < minPxPerFrame) {
      _parVeto = false; // no opinion
      return;
    }
    // BM-200B.9h — Parallel detector inputs: use displacement velocities (not centroid-relative)
    final Offset v1 = d1 * invDt;
    final Offset v2 = d2 * invDt;
    _v1E = _v1E * (1.0 - emaAlpha) + v1 * emaAlpha;
    _v2E = _v2E * (1.0 - emaAlpha) + v2 * emaAlpha;
    final double s1 = _v1E.distance, s2 = _v2E.distance;
    final double denom = s1 * s2;
    bool weak = false;
    if (s1 < vMinPxS || s2 < vMinPxS) weak = true;
    // Legacy 9d PARCFG print suppressed to avoid duplicate PAR logs; 9h owns config logging

    double cosParRaw;
    if (denom < 1e-3) {
      cosParRaw = 0.0;
    } else {
      final double dot = _v1E.dx * _v2E.dx + _v1E.dy * _v2E.dy;
      cosParRaw = (dot / denom).clamp(-1.0, 1.0);
    }
    final double sep1 = (_p2Prev - _p1Prev).distance;
    final double sep2 = (p2 - p1).distance;
    final double sepFracRaw =
        (sep2 - sep1).abs() / math.max(math.max(sep2, sep1), 1.0);
    _cosParAvg = (1.0 - emaAlpha) * _cosParAvg + emaAlpha * cosParRaw;
    _sepFracAvg = (1.0 - emaAlpha) * _sepFracAvg + emaAlpha * sepFracRaw;
    // Require strong and use stricter thresholds for veto
    _parVeto =
        !weak && (_cosParAvg >= cosParThresh) && (_sepFracAvg <= sepFracThresh);
    _p1Prev = p1;
    _p2Prev = p2;
    _tPrevMs = tNowMs;
  }
}

class _Win {
  final int t;
  final double rot;
  final double zoom;
  _Win(this.t, this.rot, this.zoom);
}
