import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;

/// BmGestureEngine: Extracted core for two-finger rotate/zoom with anchored apply.
/// Implements BM-200B.6 windowed gating and BM-200B.8 EMA-based parallel veto.
class BmGestureEngine {
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

  void onPointerPairStart(Offset p1, Offset p2, int tMs) {
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
    // Per-frame deltas for evidence
    final int nowMs = tMs;
    // Compute zoomEv from sep change
    final double sepPrev = (_p2Prev - _p1Prev).distance; // previous frame
    final double sepNow = (p2 - p1).distance; // this frame
    double zoomEv = 0.0;
    if (sepPrev > 1e-6 && sepNow > 1e-6) {
      zoomEv = (math.log(sepNow / sepPrev)).abs();
    }
    // dTheta is not provided here; caller should set via buildLocalDelta from rm/sm
    // Maintain window
    _win.add(_Win(nowMs, _dTheta.abs(), zoomEv));
    while (_win.isNotEmpty && (nowMs - _win.first.t) > windowMs) {
      _win.removeAt(0);
    }
    rotAccum = _win.fold(0.0, (s, w) => s + w.rot);
    zoomAccum = _win.fold(0.0, (s, w) => s + w.zoom);

    // Update EMA parallel veto
    _updateParallelVeto(p1, p2, tMs.toDouble());

    // Gate and lock once
    final double sec = windowMs / 1000.0;
    final bool sepOk = sepNow >= minSepPx;
    // BM-200B.9d — Deadbands
    const double rotDeadband = 0.020; // unit: rad/s proxy over window
    final double rotRate = (rotAccum / sec);
    final double rotRateDb = (rotRate < rotDeadband) ? 0.0 : rotRate;
    final bool wantRotate =
        sepOk &&
        (rotAccum >= rotHys) &&
        (rotRateDb >= minRotRate) &&
        (zoomAccum <= 0.35 * rotAccum);
    final bool wantZoom =
        sepOk &&
        (zoomAccum >= zoomHys) && // zoom deadband applies in veto, not here
        ((zoomAccum / sec) >= minZoomRate) &&
        (rotAccum <= 0.35 * zoomAccum);
    final bool anyGate = wantRotate || wantZoom;
    // Apply deadbanded sepFrac for veto decision
    const double zoomDeadbandForVeto = 0.010; // sepFracAvg proxy
    final double sepFracAvgDb = (_sepFracAvg < zoomDeadbandForVeto)
        ? 0.0
        : _sepFracAvg;
    final bool parVetoDb = _parVeto && (sepFracAvgDb <= sepFracThresh);

    if (parVetoDb || !anyGate) {
      _gateOnSinceMs = -1;
      _gateRotate = null;
    } else {
      final bool gateNowRotate = wantRotate || (wantRotate && wantZoom);
      if (_gateRotate == null || _gateRotate != gateNowRotate) {
        _gateRotate = gateNowRotate;
        _gateOnSinceMs = nowMs;
      }
      final int held = (_gateOnSinceMs >= 0) ? (nowMs - _gateOnSinceMs) : 0;
      if (!_locked && held >= dwellMs) {
        _locked = true;
      }
    }
  }

  /// Build per-frame local delta R(dθ) and S(dScale) and pan delta.
  /// Caller provides rm/sm and tm components from gesture detector.
  void buildLocalDelta({
    required Matrix4 rm,
    required Matrix4 sm,
    required Matrix4 tm,
  }) {
    _dTheta = _angleFrom(rm);
    _dScale = _scaleFrom(sm);
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
    if (_locked && aWorldLock != null) {
      final ax = aWorldLock!.dx, ay = aWorldLock!.dy;
      final Matrix4 TposLocal = Matrix4.identity()..translate(ax, ay);
      final Matrix4 TnegLocal = Matrix4.identity()..translate(-ax, -ay);
      final Matrix4 R = Matrix4.identity()..rotateZ(_dTheta);
      final Matrix4 S = Matrix4.identity()..scale(_dScale);
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
  double get cosParAvg => _cosParAvg;
  double get sepFracAvg => _sepFracAvg;
  bool get parVeto => _parVeto;
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
    // BM-200B.9d — Parallel detector inputs
    // Absolute velocities
    final Offset v1Abs = d1 * invDt;
    final Offset v2Abs = d2 * invDt;
    // Centroid velocity
    final Offset cNow = (p1 + p2) * 0.5;
    final Offset cPrev = (_p1Prev + _p2Prev) * 0.5;
    final Offset vC = (cNow - cPrev) * invDt;
    // Centroid-relative velocities
    final Offset v1 = v1Abs - vC;
    final Offset v2 = v2Abs - vC;
    _v1E = _v1E * (1.0 - emaAlpha) + v1 * emaAlpha;
    _v2E = _v2E * (1.0 - emaAlpha) + v2 * emaAlpha;
    final double s1 = _v1E.distance, s2 = _v2E.distance;
    final double denom = s1 * s2;
    bool weak = false;
    if (s1 < vMinPxS || s2 < vMinPxS) weak = true;
    // Proof line once per frame
    debugPrint('[BM-200B.9d PARCFG] relToCentroid=true');

    double cosParRaw;
    if (denom < 1e-3) {
      cosParRaw = 0.0;
    } else {
      final double dot = _v1E.dx * _v2E.dx + _v1E.dy * _v2E.dy;
      cosParRaw = (dot / denom).clamp(-1.0, 1.0);
    }
    final double sep1 = (_p2Prev - _p1Prev).distance;
    final double sep2 = (p2 - p1).distance;
    final double sepFracRaw = ((sep2 - sep1).abs()) / (sep1 > 1.0 ? sep1 : 1.0);
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
