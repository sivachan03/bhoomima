import 'package:flutter/material.dart';
import 'dart:math' as math; // for atan2, log
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;
import 'package:matrix_gesture_detector_pro/matrix_gesture_detector_pro.dart';

// BM-200B.5 minimal state machine
enum GMode { none, pan, rotZoom }

// TEMP: Bypass parallel veto for one run to validate lock behavior
const bool DEBUG_BYPASS_PARALLEL_VETO = false; // set to false after the test

// BM-200B.6: sliding window sample for gesture evidence
class _WinSample {
  final int tMs; // timestamp in msSinceEpoch
  final double rot; // |dTheta| evidence (rad)
  final double zoom; // |log(sep/prevSep)| evidence
  final double nonPan; // separation-normalized non-parallel evidence
  final double cosPar; // cosine of motion vector alignment
  final double sepFrac; // |sepNow - sepPrev|/max(sepPrev, eps)
  const _WinSample({
    required this.tMs,
    required this.rot,
    required this.zoom,
    required this.nonPan,
    required this.cosPar,
    required this.sepFrac,
  });
}

class _WinStats {
  final int spanMs;
  final int count;
  final double rotAccum;
  final double zoomAccum;
  final double nonPanAccum;
  final double cosParAvg;
  final double sepFracAvg;
  const _WinStats({
    required this.spanMs,
    required this.count,
    required this.rotAccum,
    required this.zoomAccum,
    required this.nonPanAccum,
    required this.cosParAvg,
    required this.sepFracAvg,
  });
}

class FarmMapView extends StatefulWidget {
  const FarmMapView({super.key});

  @override
  State<FarmMapView> createState() => _FarmMapViewState();
}

class _FarmMapViewState extends State<FarmMapView> {
  // Transform state
  Matrix4 _M = Matrix4.identity();
  Offset? _A_screen_lock; // screen px at lock
  Offset? _A_world_lock; // world pivot at lock
  int _postLockFrames = 0;

  // State machine and dwell timers
  GMode _mode = GMode.none;
  int _evidenceMs = 0; // non-parallel rot/zoom evidence dwell
  int _parallelMs = 0; // sustained parallel dwell
  DateTime? _lastTick;

  // Tunables
  static const int _dwellMs = 180; // ms to decide lock/unlock
  static const double _angleGate = 0.02; // rad/frame (~1.1°)
  static const double _scaleGate = 0.005; // unitless/frame

  // BM-200B.6 window and gating parameters
  static const int _windowMs = 200; // sliding window length
  static const double _minSepPx =
      72.0; // minimum two-finger separation to consider rot/zoom
  static const double _rotHys = 0.18; // minimum accumulated rotation (rad)
  static const double _zoomHys = 0.04; // minimum accumulated zoom (|log|)
  static const double _leakMaxRatio = 0.35; // cross-signal tolerance
  static const double _minRotRate = 0.25; // rad/sec
  static const double _minZoomRate = 0.20; // |log|/sec
  // (windowed thresholds removed; BM-200B.8 uses EMA-based veto)

  // BM-200B.8: Parallel veto via EMA velocities
  static const double _parVMinPxS = 60.0; // px/s
  static const double _parEmaAlpha = 0.30; // smoothing factor
  static const double _parCosTh = 0.95; // F4: parallelLike threshold
  static const double _parSepTh = 0.01; // F4: tiny squeeze allowed
  static const double _parMinPxPerFrame = 1.5; // F1: validity gate (px)

  // Raw pointers for simple heuristics
  final Map<int, Offset> _pointers = <int, Offset>{};
  Map<int, Offset> _prevPointers = <int, Offset>{};

  // BM-200B.6 windowed stats state
  final List<_WinSample> _win = <_WinSample>[];
  int _gateOnSinceMs =
      -1; // gate dwell start time (msSinceEpoch); -1 => no gate
  bool? _gateRotate; // true=rotate gate, false=zoom gate, null=none

  // BM-200B.8 parallel veto state
  double _cosParAvg = 0.0;
  double _sepFracAvg = 0.0;
  Offset _v1Ema = Offset.zero, _v2Ema = Offset.zero;
  bool _parHavePrev = false;
  Offset _p1PrevForPar = Offset.zero, _p2PrevForPar = Offset.zero;
  double _tPrevMs = 0.0;
  bool _currentParVeto = false;
  // Debug override to force-disable parallel veto without dead-code warnings
  bool _debugForceParVetoFalse = false; // set to false to use _currentParVeto

  // Helpers
  double _angleFrom(Matrix4 rm) {
    final double c = rm.entry(0, 0);
    final double s = rm.entry(1, 0);
    return math.atan2(s, c);
  }

  double _scaleFrom(Matrix4 sm) {
    final double sx = sm.entry(0, 0);
    return sx == 0.0 ? 1.0 : sx;
  }

  Offset? _centroid() {
    if (_pointers.isEmpty) return null;
    double x = 0, y = 0;
    for (final p in _pointers.values) {
      x += p.dx;
      y += p.dy;
    }
    final n = _pointers.length.toDouble();
    return Offset(x / n, y / n);
  }

  // BM-200B.8: update EMA-based parallel veto state
  void _bm200b8UpdateParallelVeto({
    required Offset p1,
    required Offset p2,
    required double tNowMs, // monotonic-ish ms
  }) {
    if (!_parHavePrev) {
      _parHavePrev = true;
      _p1PrevForPar = p1;
      _p2PrevForPar = p2;
      _tPrevMs = tNowMs;
      _cosParAvg = 0.0;
      _sepFracAvg = 0.0;
      _v1Ema = Offset.zero;
      _v2Ema = Offset.zero;
      _currentParVeto = false;
      return;
    }
    double dt = (tNowMs - _tPrevMs).abs();
    if (dt < 1.0) dt = 1.0;
    if (dt > 100.0) dt = 100.0;
    final double invDt = 1000.0 / dt; // to px/s

    final Offset d1 = p1 - _p1PrevForPar;
    final Offset d2 = p2 - _p2PrevForPar;
    // F1 validity gate: require max displacement strong enough in this frame
    final double d1Mag = d1.distance;
    final double d2Mag = d2.distance;
    if (math.max(d1Mag, d2Mag) < _parMinPxPerFrame) {
      // Skip updating averages and decision on uncertainty; leave parVeto=false
      _currentParVeto = false;
      return;
    }
    final Offset v1 = d1 * invDt;
    final Offset v2 = d2 * invDt;

    // EMA of velocities
    _v1Ema = _v1Ema * (1.0 - _parEmaAlpha) + v1 * _parEmaAlpha;
    _v2Ema = _v2Ema * (1.0 - _parEmaAlpha) + v2 * _parEmaAlpha;

    final double s1 = _v1Ema.distance;
    final double s2 = _v2Ema.distance;

    // cosParallel with safe denom
    final double denom = (s1 * s2);
    double cosParRaw;
    bool weakFinger = false;
    if (s1 < _parVMinPxS || s2 < _parVMinPxS) {
      weakFinger = true;
    }
    if (denom < 1e-3) {
      cosParRaw = 0.0; // neutral
    } else {
      final double dot = _v1Ema.dx * _v2Ema.dx + _v1Ema.dy * _v2Ema.dy;
      cosParRaw = (dot / denom).clamp(-1.0, 1.0);
    }

    // separation fraction
    final double sep1 = (_p2PrevForPar - _p1PrevForPar).distance;
    final double sep2 = (p2 - p1).distance;
    final double sepFracRaw =
        ((sep2 - sep1).abs()) / math.max(math.max(sep2, sep1), 1.0);

    // EMA averages
    _cosParAvg = (1.0 - _parEmaAlpha) * _cosParAvg + _parEmaAlpha * cosParRaw;
    _sepFracAvg =
        (1.0 - _parEmaAlpha) * _sepFracAvg + _parEmaAlpha * sepFracRaw;

    // Decision
    _currentParVeto =
        !weakFinger && (_cosParAvg >= _parCosTh) && (_sepFracAvg <= _parSepTh);
    // F4 — Anti-parallel does NOT veto
    if (_cosParAvg < -0.90) {
      _currentParVeto = false;
    }

    // Debug line
    debugPrint(
      '[BM-200B.8 PAR] parVeto=' +
          _currentParVeto.toString() +
          ' weak=' +
          weakFinger.toString() +
          ' v1=' +
          s1.toStringAsFixed(0) +
          ' v2=' +
          s2.toStringAsFixed(0) +
          ' denom=' +
          denom.toStringAsExponential(2) +
          ' cosParRaw=' +
          cosParRaw.toStringAsFixed(3) +
          ' cosParAvg=' +
          _cosParAvg.toStringAsFixed(3) +
          ' sep=' +
          sep2.toStringAsFixed(1) +
          ' sepFracRaw=' +
          sepFracRaw.toStringAsFixed(3) +
          ' sepFracAvg=' +
          _sepFracAvg.toStringAsFixed(3),
    );

    // Book-keeping
    _p1PrevForPar = p1;
    _p2PrevForPar = p2;
    _tPrevMs = tNowMs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        onPointerDown: (e) {
          _pointers[e.pointer] = e.localPosition;
          _onPointerCountChanged(_pointers.length);
        },
        onPointerMove: (e) {
          _pointers[e.pointer] = e.localPosition;
        },
        onPointerUp: (e) {
          _pointers.remove(e.pointer);
          if (_pointers.isEmpty) {
            _onGestureEnd();
            _prevPointers = {};
          }
          _onPointerCountChanged(_pointers.length);
        },
        onPointerCancel: (e) {
          _pointers.remove(e.pointer);
          if (_pointers.isEmpty) {
            _onGestureEnd();
            _prevPointers = {};
          }
          _onPointerCountChanged(_pointers.length);
        },
        child: MatrixGestureDetector(
          shouldRotate: true,
          shouldScale: true,
          shouldTranslate: true,
          onMatrixUpdate: (mDelta, tm, sm, rm) {
            // Read per-frame small deltas
            final double dTheta = _angleFrom(rm);
            final double dScale = _scaleFrom(sm);

            // Update dwell timers
            final nowTs = DateTime.now();
            int dtMs = 0;
            if (_lastTick != null)
              dtMs = nowTs.difference(_lastTick!).inMilliseconds;
            _lastTick = nowTs;
            final int nowMs = nowTs.millisecondsSinceEpoch;

            // Build BM-200B.6 window sample (still used for rotate/zoom evidence)
            double cosPar = 1.0; // default aligned if unknown
            double sepFrac = 0.0;
            double nonPanEv = 0.0;
            double sepNow = 0.0;
            if (_pointers.length >= 2 && _prevPointers.length >= 2) {
              final keysNow = _pointers.keys.toList()..sort();
              final int id1 = keysNow[0];
              final int id2 = keysNow[1];
              if (_prevPointers.containsKey(id1) &&
                  _prevPointers.containsKey(id2)) {
                final Offset p1Prev = _prevPointers[id1]!;
                final Offset p2Prev = _prevPointers[id2]!;
                final Offset p1Now = _pointers[id1]!;
                final Offset p2Now = _pointers[id2]!;
                final Offset d1 = p1Now - p1Prev;
                final Offset d2 = p2Now - p2Prev;
                final double len1 = d1.distance;
                final double len2 = d2.distance;
                final double dot = d1.dx * d2.dx + d1.dy * d2.dy;
                final double denom = (len1 * len2);
                if (denom > 0) {
                  // exact per-frame cosine of angle between motion vectors
                  cosPar = (dot / denom);
                } else {
                  // no movement → treat as parallel
                  cosPar = 1.0;
                }
                sepNow = (p1Now - p2Now).distance;
                final double sepPrev = (p1Prev - p2Prev).distance;
                // exact per-frame separation fraction relative to current separation
                final double sepDen = math.max(math.max(sepNow, sepPrev), 1.0);
                sepFrac = (sepNow - sepPrev).abs() / sepDen;
                final double sepNorm = math.max(sepNow, 48.0);
                nonPanEv = (d1 - d2).distance / sepNorm;

                // BM-200B.8: update EMA-based parallel veto using current p1/p2
                _bm200b8UpdateParallelVeto(
                  p1: p1Now,
                  p2: p2Now,
                  tNowMs: nowMs.toDouble(),
                );
              }
            }
            final double rotEv = dTheta.abs();
            double zoomEv = 0.0;
            // Prefer separation-based zoom evidence; fall back to |log(dScale)| if needed
            if (_pointers.length >= 2 && _prevPointers.length >= 2) {
              final keysNow = _pointers.keys.toList()..sort();
              final int id1 = keysNow[0];
              final int id2 = keysNow[1];
              if (_prevPointers.containsKey(id1) &&
                  _prevPointers.containsKey(id2)) {
                final Offset p1Prev = _prevPointers[id1]!;
                final Offset p2Prev = _prevPointers[id2]!;
                final Offset p1Now = _pointers[id1]!;
                final Offset p2Now = _pointers[id2]!;
                final double sepPrev = (p1Prev - p2Prev).distance;
                final double sepCurr = (p1Now - p2Now).distance;
                if (sepPrev > 1e-6 && sepCurr > 1e-6) {
                  zoomEv = (math.log(sepCurr / sepPrev)).abs();
                }
              }
            }
            if (zoomEv == 0.0) {
              final double ds = (dScale - 1.0).abs();
              if (ds > 0) zoomEv = (math.log(dScale)).abs();
            }

            // F3 — Gate order: decide parVeto before accumulating evidence
            // Prune window first (time advances regardless of adding a sample)
            while (_win.isNotEmpty && (nowMs - _win.first.tMs) > _windowMs) {
              _win.removeAt(0);
            }
            // Pre-stats before adding any new sample
            final _WinStats wBefore = _computeWinStats(nowMs);
            // Use BM-200B.8 parallel veto result with debug bypass
            final bool parallelVetoWin = DEBUG_BYPASS_PARALLEL_VETO
                ? false
                : (_debugForceParVetoFalse ? false : _currentParVeto);

            if (!parallelVetoWin) {
              // Normal frame: add evidence sample
              _win.add(
                _WinSample(
                  tMs: nowMs,
                  rot: rotEv,
                  zoom: zoomEv,
                  nonPan: nonPanEv,
                  cosPar: cosPar,
                  sepFrac: sepFrac,
                ),
              );
            }
            // Compute window stats (for rotate/zoom gates and logs) AFTER APPLY decision
            final _WinStats w = _computeWinStats(nowMs);
            // Unified APPLY log (exactly one per frame)
            final double raBefore = wBefore.rotAccum;
            final double zaBefore = wBefore.zoomAccum;
            final double raAfter = w.rotAccum;
            final double zaAfter = w.zoomAccum;
            final double dThetaApplied = parallelVetoWin ? 0.0 : dTheta;
            // In this sample app, scale apply is via sm per frame; report 0 when vetoed
            final double dScaleApplied = parallelVetoWin ? 0.0 : (dScale - 1.0);
            debugPrint(
              '[BM-200B.9h APPLY] parVeto=' +
                  parallelVetoWin.toString() +
                  ' → dθ=' +
                  dThetaApplied.toStringAsFixed(3) +
                  ' dScale=' +
                  dScaleApplied.toStringAsFixed(3) +
                  ' (rotAccum: ' +
                  raBefore.toStringAsFixed(3) +
                  '→' +
                  raAfter.toStringAsFixed(3) +
                  ', zoomAccum: ' +
                  zaBefore.toStringAsFixed(3) +
                  '→' +
                  zaAfter.toStringAsFixed(3) +
                  ')',
            );

            // Classic per-frame heuristics (kept for unlock fallback)
            final bool hasRotZoomSignal =
                (dTheta.abs() >= _angleGate) ||
                ((dScale - 1.0).abs() >= _scaleGate);
            final bool parallelLikeFrame = (cosPar >= 0.97);
            if (!parallelLikeFrame && hasRotZoomSignal) {
              _evidenceMs = (_evidenceMs + dtMs).clamp(0, 10000);
            } else {
              _evidenceMs = 0;
            }
            if (parallelVetoWin) {
              _parallelMs = (_parallelMs + dtMs).clamp(0, 10000);
            } else {
              _parallelMs = 0;
            }

            switch (_mode) {
              case GMode.none:
              case GMode.pan:
                // Pan before lock: apply screen-space translation only
                setState(() {
                  _M = tm * _M;
                });
                // BM-200B.6: Evaluate windowed gates with dwell and lock-once
                final bool sepOk = sepNow >= _minSepPx;
                final bool wantRotate =
                    sepOk &&
                    (w.rotAccum >= _rotHys) &&
                    (w.spanMs > 0 &&
                        (w.rotAccum * 1000.0 / w.spanMs) >= _minRotRate) &&
                    (w.zoomAccum <= _leakMaxRatio * w.rotAccum);
                final bool wantZoom =
                    sepOk &&
                    (w.zoomAccum >= _zoomHys) &&
                    (w.spanMs > 0 &&
                        (w.zoomAccum * 1000.0 / w.spanMs) >= _minZoomRate) &&
                    (w.rotAccum <= _leakMaxRatio * w.zoomAccum);
                final bool anyGate = wantRotate || wantZoom;
                // BM-200B.7: Minimal gate-reason print (keep until green)
                final double sec = _windowMs / 1000.0;
                final double rotRate = sec > 0 ? (w.rotAccum / sec) : 0.0;
                final double zoomRate = sec > 0 ? (w.zoomAccum / sec) : 0.0;
                final bool sepOK = sepOk;
                final bool parVeto = parallelVetoWin;
                final int dwellMs = (_gateOnSinceMs < 0)
                    ? 0
                    : (nowMs - _gateOnSinceMs);
                debugPrint(
                  '[BM-200B.7 GATE] sepOK=' +
                      sepOK.toString() +
                      ' sep=' +
                      sepNow.toStringAsFixed(1) +
                      ' parVeto=' +
                      parVeto.toString() +
                      ' cosParAvg=' +
                      _cosParAvg.toStringAsFixed(3) +
                      ' sepFracAvg=' +
                      _sepFracAvg.toStringAsFixed(3) +
                      ' rotA=' +
                      w.rotAccum.toStringAsFixed(3) +
                      ' rotRate=' +
                      rotRate.toStringAsFixed(2) +
                      ' zoomA=' +
                      w.zoomAccum.toStringAsFixed(3) +
                      ' zoomRate=' +
                      zoomRate.toStringAsFixed(2) +
                      ' dwell=' +
                      dwellMs.toString() +
                      'ms',
                );
                if (parallelVetoWin || !anyGate) {
                  // Reset gate dwell when vetoed or no clear gate
                  _gateOnSinceMs = -1;
                  _gateRotate = null;
                } else {
                  final bool gateNowRotate =
                      wantRotate || (wantRotate && wantZoom);
                  if (_gateRotate == null || _gateRotate != gateNowRotate) {
                    _gateRotate = gateNowRotate;
                    _gateOnSinceMs = nowMs;
                  }
                  final int held = (_gateOnSinceMs >= 0)
                      ? (nowMs - _gateOnSinceMs)
                      : 0;
                  if (held >= _dwellMs) {
                    final aScreen = _centroid();
                    if (aScreen != null) {
                      final inv = Matrix4.inverted(_M);
                      final aw = inv.transform3(
                        Vector3(aScreen.dx, aScreen.dy, 0),
                      );
                      _A_world_lock = Offset(aw.x, aw.y);
                      _A_screen_lock = aScreen;
                      _mode = GMode.rotZoom;
                      _postLockFrames = 0;
                      debugPrint(
                        '[BM-200B.6] →lock ${gateNowRotate ? 'Rotate' : 'Zoom'} at $aScreen, world=$_A_world_lock rotA=${w.rotAccum.toStringAsFixed(3)} zoomA=${w.zoomAccum.toStringAsFixed(3)} cosParAvg=${w.cosParAvg.toStringAsFixed(3)} sepF=${w.sepFracAvg.toStringAsFixed(3)}',
                      );
                      // lock-once guard (reset gate)
                      _gateOnSinceMs = -1;
                      _gateRotate = null;
                    }
                  }
                }
                break;
              case GMode.rotZoom:
                // Centroid-anchored rotate + scale then residual pan (prevents visual cutoff)
                if (_pointers.length >= 2 && _prevPointers.length >= 2) {
                  final keysNow = _pointers.keys.toList()..sort();
                  final int id1 = keysNow[0];
                  final int id2 = keysNow[1];
                  if (_prevPointers.containsKey(id1) &&
                      _prevPointers.containsKey(id2)) {
                    final Offset p1Prev = _prevPointers[id1]!;
                    final Offset p2Prev = _prevPointers[id2]!;
                    final Offset p1Now = _pointers[id1]!;
                    final Offset p2Now = _pointers[id2]!;
                    final Offset cPrev = (p1Prev + p2Prev) * 0.5;
                    final Offset cNow = (p1Now + p2Now) * 0.5;
                    // Raw angle delta (reuse dTheta) already computed per frame
                    // Raw log separation delta
                    final double sepPrev = (p1Prev - p2Prev).distance;
                    final double sepNow = (p1Now - p2Now).distance;
                    double dLogSep = 0.0;
                    if (sepPrev > 1e-6 && sepNow > 1e-6) {
                      dLogSep = math.log(sepNow / sepPrev); // symmetric
                    }
                    final double scaleMul = math.exp(dLogSep);
                    // Screen-space centroid to world-space (invert current matrix)
                    final invBefore = Matrix4.inverted(_M);
                    final awNowV = invBefore.transform3(
                      Vector3(cNow.dx, cNow.dy, 0),
                    );
                    final Offset aWorldNow = Offset(awNowV.x, awNowV.y);
                    // Build anchored transform: T(-centroid) * R * S * T(+centroid)
                    final Matrix4 Tneg = Matrix4.identity()
                      ..translate(-aWorldNow.dx, -aWorldNow.dy);
                    final Matrix4 R = Matrix4.identity()..rotateZ(dTheta);
                    final Matrix4 S = Matrix4.identity()..scale(scaleMul);
                    final Matrix4 Tpos = Matrix4.identity()
                      ..translate(aWorldNow.dx, aWorldNow.dy);
                    Matrix4 anchored = Tpos * R * S * Tneg;
                    // Apply residual pan AFTER anchored rotate+scale using WORLD delta of centroid
                    // screenDeltaToWorld(dCentroid): map cNow/cPrev through inverse and take the difference
                    final awPrevV = invBefore.transform3(
                      Vector3(cPrev.dx, cPrev.dy, 0),
                    );
                    final Offset aWorldPrev = Offset(awPrevV.x, awPrevV.y);
                    final Offset dWorld = aWorldNow - aWorldPrev;
                    Matrix4 panResidual = Matrix4.identity()
                      ..translate(dWorld.dx, dWorld.dy);
                    setState(() {
                      _M = panResidual * anchored * _M;
                      _postLockFrames++;
                    });
                    // Derive raw per-frame angle/separation change for logging
                    double rotAbs = dTheta.abs();
                    double zoomAbs = 0.0;
                    if (sepPrev > 1e-6 && sepNow > 1e-6) {
                      zoomAbs = (math.log(sepNow / sepPrev)).abs();
                    }
                    final String applyMode = (zoomAbs > rotAbs * 1.2)
                        ? 'zoom'
                        : (rotAbs > zoomAbs * 1.2 ? 'rotate' : 'sticky');
                    final double scaleAfter = _scaleFrom(_M);
                    final double rotRadAfter = _angleFrom(_M);
                    final double rotDegAfter = rotRadAfter * 180.0 / math.pi;
                    final double dS = scaleMul - 1.0;
                    debugPrint(
                      '[APPLY] mode=$applyMode dS=${dS.toStringAsFixed(4)} dθ=${dTheta.toStringAsFixed(4)} scale=${scaleAfter.toStringAsFixed(4)} rotDeg=${rotDegAfter.toStringAsFixed(2)}',
                    );
                    if ((_postLockFrames % 10) == 0) {
                      final v = _M.transform3(
                        Vector3(aWorldNow.dx, aWorldNow.dy, 0),
                      );
                      final drift = (Offset(v.x, v.y) - cNow).distance;
                      debugPrint(
                        '[BM-200B.6] live driftPx=${drift.toStringAsFixed(2)}',
                      );
                    }
                  }
                }
                // Unlock if sustained parallel
                if (parallelVetoWin && _parallelMs >= _dwellMs) {
                  _mode = GMode.none;
                  _A_world_lock = null;
                  _A_screen_lock = null;
                  debugPrint('[BM-200B.6] unlock rotZoom (parallel)');
                }
                break;
            }

            // Snapshot for next-frame detection
            _prevPointers = Map<int, Offset>.from(_pointers);
          },
          child: Transform(
            transform: _M,
            child: CustomPaint(
              painter: _FarmPainter(),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }

  void _onPointerCountChanged(int count) {
    if (count < 2) {
      setState(() {
        _mode = GMode.none;
        _A_world_lock = null;
        _A_screen_lock = null;
        _evidenceMs = 0;
        _parallelMs = 0;
        _postLockFrames = 0;
        _win.clear();
        _gateOnSinceMs = -1;
        _gateRotate = null;
      });
    }
  }

  void _onGestureEnd() {
    // Apply one-shot correction and verify residual
    if (_A_screen_lock == null || _A_world_lock == null) return;
    final v = _M.transform3(Vector3(_A_world_lock!.dx, _A_world_lock!.dy, 0));
    final cur = Offset(v.x, v.y);
    final dx = _A_screen_lock!.dx - cur.dx;
    final dy = _A_screen_lock!.dy - cur.dy;
    final Matrix4 C = Matrix4.identity()..translate(dx, dy);
    setState(() => _M = C * _M);

    // Verify residual after correction
    final v2 = _M.transform3(Vector3(_A_world_lock!.dx, _A_world_lock!.dy, 0));
    final cur2 = Offset(v2.x, v2.y);
    final residual = (cur2 - _A_screen_lock!).distance;
    final preDrift = Offset(dx, dy).distance;
    debugPrint(
      '[BM-200B.6] end Δ=(${dx.toStringAsFixed(2)},${dy.toStringAsFixed(2)}) preDrift=${preDrift.toStringAsFixed(2)} postDrift=${residual.toStringAsFixed(3)}',
    );

    _A_screen_lock = null;
    _A_world_lock = null;
  }

  _WinStats _computeWinStats(int nowMs) {
    if (_win.isEmpty) {
      return const _WinStats(
        spanMs: 0,
        count: 0,
        rotAccum: 0,
        zoomAccum: 0,
        nonPanAccum: 0,
        cosParAvg: 1.0,
        sepFracAvg: 0.0,
      );
    }
    int span = nowMs - _win.first.tMs;
    double rot = 0, zoom = 0, nonPan = 0, cosParSum = 0, sepFracSum = 0;
    for (final s in _win) {
      rot += s.rot;
      zoom += s.zoom;
      nonPan += s.nonPan;
      cosParSum += s.cosPar;
      sepFracSum += s.sepFrac;
    }
    final int n = _win.length;
    // Use raw averages; do not clamp here to avoid biasing toward +1.0
    final double cosAvg = n > 0 ? (cosParSum / n) : 1.0;
    final double sepAvg = n > 0 ? (sepFracSum / n) : 0.0;
    return _WinStats(
      spanMs: span,
      count: n,
      rotAccum: rot,
      zoomAccum: zoom,
      nonPanAccum: nonPan,
      cosParAvg: cosAvg,
      sepFracAvg: sepAvg,
    );
  }
}

class _FarmPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: 300,
      height: 200,
    );
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
