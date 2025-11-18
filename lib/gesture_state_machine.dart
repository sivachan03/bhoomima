// Gate selection helper: decide active intent from basic gate fields.
// Also includes a lightweight gesture state machine with mode handoff hysteresis
// and dead-zone rescue for rotate/zoom applies.

import 'dart:ui' show Offset;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show debugPrint;

// BM-200: simplify gestures — gestures pan only; zoom/rotate via buttons.
// After BM-200 ships, flip these toggles incrementally:
// - Set kPanOnlyBm200=false and kEnablePinchZoomGesture=true to allow pinch zoom only.
// - Later, set kEnableRotateGesture=true to allow two-finger rotate.
const bool kPanOnlyBm200 = true; // ship BM-200 with pan-only gestures
const bool kEnablePinchZoomGesture = false; // post-BM-200: enable pinch zoom
const bool kEnableRotateGesture = false; // post-BM-200: enable rotate gesture
// Strict gating for pinch zoom (post-BM-200): require per-frame dLog above this
// to avoid noise. ~0.006 ≈ 0.6% scale per 16.7ms frame (~0.36/s at 60fps).
const double kZoomPerFrameMinStrict = 0.006;

// Prove this file is compiled (logs once on import in debug builds).
bool _smTopLevelProbe() {
  assert(() {
    // Don't change this tag—we search for it in logs.
    debugPrint('[SM] LOADED gesture_state_machine.dart');
    return true;
  }());
  return true;
}

// ignore: unused_element
final bool _smProbeInit = _smTopLevelProbe();

enum Intent { pan, zoom, rotate, unknown }

class GateDecision {
  final Intent intent;
  final bool zoomReady;
  final bool rotateReady;
  GateDecision(this.intent, this.zoomReady, this.rotateReady);
  @override
  String toString() =>
      'GateDecision($intent, zoomReady=$zoomReady, rotateReady=$rotateReady)';
}

GateDecision decideFromPargate(
  String mode,
  bool zoomReady,
  bool rotateReady, {
  double zoomBias = 1.2,
}) {
  // Only three modes are expected now: pan | zoom | rotate (zr removed)
  switch (mode) {
    case 'zoom':
      return GateDecision(Intent.zoom, zoomReady, rotateReady);
    case 'rotate':
      return GateDecision(Intent.rotate, zoomReady, rotateReady);
    case 'pan':
      return GateDecision(Intent.pan, zoomReady, rotateReady);
    default:
      return GateDecision(Intent.unknown, zoomReady, rotateReady);
  }
}

// === State machine additions ===

enum Mode { pan, zoom, rotate }

class Estimates {
  final double dTheta; // incremental rotation (radians)
  final double dLogSep; // incremental log-scale (scale ~ exp(dLogSep))
  final Offset
  dPan; // incremental pan (screen or world units per your pipeline)
  final double? rotE; // optional rotation energy/score
  final double? zoomE; // optional zoom energy/score
  const Estimates({
    required this.dTheta,
    required this.dLogSep,
    required this.dPan,
    this.rotE,
    this.zoomE,
  });
}

class GestureStateMachine {
  // --- mode handoff hysteresis (time-based stickiness) ---
  static const int kEnterMs = 80; // dwell to enter rotate/zoom from pan
  static const int kStickMs = 150; // stick time before falling back to pan
  int? _rotateReadySinceMs;
  int? _zoomReadySinceMs;
  int _modeSinceMs = 0; // timestamp of last mode change

  // --- dead-zone rescue thresholds (tune if needed) ---
  static const double kMinRotStep = 0.004; // ~0.23°
  static const double kMaxRotStep = 0.05; // clamp rescue step
  static const double kMinZoomStep = 0.004; // ~0.4% scale
  static const double kMaxZoomStep = 0.05;

  // Keepalive injections (disabled by default)
  static const bool kInjectTinyRotate = false;
  static const bool kInjectTinyZoom = false;

  Mode mode;
  Offset _panAccum = Offset.zero;

  // Debug integrators: expected totals from SM-applied deltas
  double _debugTotalRotRad = 0.0;
  double _debugTotalScale = 1.0;
  double? get debugTotalRotRad => _debugTotalRotRad;
  double? get debugTotalScale => _debugTotalScale;

  // Application/pivot hooks provided by the integrator.
  final void Function(double dTheta) _applyRotate;
  final void Function(double dLogScale) _applyZoom;
  final void Function(Offset dPan) _applyPan;
  final void Function() _startRotatePivot;
  final void Function() _startZoomPivot;

  GestureStateMachine({
    this.mode = Mode.pan,
    required void Function(double) applyRotate,
    required void Function(double) applyZoom,
    required void Function(Offset) applyPan,
    required void Function() startRotatePivot,
    required void Function() startZoomPivot,
  }) : _applyRotate = applyRotate,
       _applyZoom = applyZoom,
       _applyPan = applyPan,
       _startRotatePivot = startRotatePivot,
       _startZoomPivot = startZoomPivot;

  // Convenience constructor: accepts pan as (dx,dy) doubles
  GestureStateMachine.simple({
    this.mode = Mode.pan,
    required void Function(double) applyRotate,
    required void Function(double) applyZoom,
    required void Function(double dx, double dy) applyPan,
    void Function()? startRotatePivot,
    void Function()? startZoomPivot,
  }) : _applyRotate = applyRotate,
       _applyZoom = applyZoom,
       _applyPan = ((Offset dp) => applyPan(dp.dx, dp.dy)),
       _startRotatePivot = startRotatePivot ?? (() {}),
       _startZoomPivot = startZoomPivot ?? (() {});

  void onGate(GateDecision g, {required bool veto}) {
    updateGateAndArbitrate(g, veto: veto);
  }

  // Authoritative mode arbiter with sticky back-to-pan hysteresis.
  void updateGateAndArbitrate(GateDecision g, {required bool veto}) {
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    // BM-200: force gestures to PAN only
    if (kPanOnlyBm200) {
      if (mode != Mode.pan) {
        mode = Mode.pan;
        _modeSinceMs = nowMs;
      }
      // clear readiness timers so we don't enter other modes
      _rotateReadySinceMs = null;
      _zoomReadySinceMs = null;
      return;
    }
    if (veto) {
      // On veto, don't change mode; reset readiness timers so we require fresh dwell
      _rotateReadySinceMs = null;
      _zoomReadySinceMs = null;
      return;
    }

    // Use PARGATE-selected intent for dwell/stick, not raw booleans
    final bool rotateGate = (g.intent == Intent.rotate);
    final bool zoomGate = (g.intent == Intent.zoom);
    if (rotateGate) {
      _rotateReadySinceMs ??= nowMs;
    } else {
      _rotateReadySinceMs = null;
    }
    if (zoomGate) {
      _zoomReadySinceMs ??= nowMs;
    } else {
      _zoomReadySinceMs = null;
    }

    // Sticky decision per R.12a-4
    switch (mode) {
      case Mode.rotate:
        if (!rotateGate && (nowMs - _modeSinceMs > kStickMs)) {
          _setMode(Mode.pan, nowMs);
        }
        break;
      case Mode.zoom:
        if (!zoomGate && (nowMs - _modeSinceMs > kStickMs)) {
          _setMode(Mode.pan, nowMs);
        }
        break;
      case Mode.pan:
        // Entry prioritizes rotate over zoom
        if (rotateGate) {
          final int since = _rotateReadySinceMs ?? nowMs;
          if (nowMs - since >= kEnterMs) _setMode(Mode.rotate, nowMs);
        } else if (zoomGate) {
          final int since = _zoomReadySinceMs ?? nowMs;
          if (nowMs - since >= kEnterMs) _setMode(Mode.zoom, nowMs);
        }
        break;
    }
  }

  void applyFrame(Estimates e, GateDecision g, {required bool veto}) {
    if (veto) return;
    // BM-200: gestures apply only pan
    if (kPanOnlyBm200) {
      _panAccum += e.dPan;
      _applyPan(_panAccum);
      _panAccum = Offset.zero;
      return;
    }
    switch (mode) {
      case Mode.rotate:
        {
          // TEMP: tiny-nudge to escape dead-zone for rotate
          if (kInjectTinyRotate && g.rotateReady && e.dTheta.abs() < 0.0005) {
            _applyRotate(0.004); // ~0.23°
            _debugTotalRotRad += 0.004;
            debugPrint('[SM] injected tiny rotate');
            return;
          }
          double dTheta = e.dTheta;
          if (g.rotateReady && dTheta.abs() < kMinRotStep) {
            dTheta = (dTheta >= 0 ? kMinRotStep : -kMinRotStep).clamp(
              -kMaxRotStep,
              kMaxRotStep,
            );
          }
          if (dTheta.abs() >= 1e-6) {
            if (dTheta.abs() > 0.003) {
              debugPrint('[SM] rot step dθ=${dTheta.toStringAsFixed(5)}');
            }
            _applyRotate(dTheta);
            _debugTotalRotRad += dTheta;
          }
          break;
        }
      case Mode.zoom:
        {
          // TEMP: tiny-nudge to escape dead-zone for zoom
          if (kInjectTinyZoom && g.zoomReady && e.dLogSep.abs() < 0.0005) {
            _applyZoom(0.004); // ~0.4% zoom
            _debugTotalScale *= math.exp(0.004);
            debugPrint('[SM] injected tiny zoom');
            return;
          }
          double dS = e.dLogSep; // multiplicative scale in log domain
          if (g.zoomReady && dS.abs() < kMinZoomStep) {
            dS = (dS >= 0 ? kMinZoomStep : -kMinZoomStep).clamp(
              -kMaxZoomStep,
              kMaxZoomStep,
            );
          }
          if (dS.abs() >= 1e-6) {
            if (dS.abs() > 0.003) {
              debugPrint('[SM] zoom step dS=${dS.toStringAsFixed(5)}');
            }
            _applyZoom(dS);
            _debugTotalScale *= math.exp(dS);
          }
          break;
        }
      case Mode.pan:
        {
          // accumulate and apply pan; accumulator helps avoid tiny oscillations
          _panAccum += e.dPan;
          if (mode == Mode.pan && e.dPan.distance > 0.2) {
            debugPrint('[SM] pan step px=${e.dPan}');
          }
          _applyPan(_panAccum);
          _panAccum = Offset.zero;
          break;
        }
    }
  }

  // Reset streaks and accumulator on two-down changes or freezes,
  // and re-snap pivots to avoid the first step jumping.
  void onTwoDownChange() {
    _panAccum = Offset.zero;
    // Reset debug totals per two-finger gesture lifecycle
    _debugTotalRotRad = 0.0;
    _debugTotalScale = 1.0;
    // Reset stickiness timers
    _rotateReadySinceMs = null;
    _zoomReadySinceMs = null;
    _modeSinceMs = DateTime.now().millisecondsSinceEpoch;
  }

  // Helper to change mode with duplicate-enter guard and pivot capture
  void _setMode(Mode next, int nowMs) {
    if (next == mode) return; // prevent duplicate "enter"
    mode = next;
    _modeSinceMs = nowMs;
    if (mode == Mode.rotate) {
      _onEnterRotate();
    } else if (mode == Mode.zoom) {
      _onEnterZoom();
    }
  }

  // Per-frame driver: 1) arbitrate mode from gate, 2) apply motion by mode.
  void onFrame(Estimates e, GateDecision g, {required bool veto}) {
    // Build an effective gate based on feature toggles and strict gating.
    var effectiveIntent = g.intent;
    if (!kEnableRotateGesture && effectiveIntent == Intent.rotate) {
      effectiveIntent = Intent.pan;
    }
    if (!kEnablePinchZoomGesture && effectiveIntent == Intent.zoom) {
      effectiveIntent = Intent.pan;
    }
    // Strict pinch zoom gating: require noticeable per-frame dLog magnitude.
    if (effectiveIntent == Intent.zoom &&
        e.dLogSep.abs() < kZoomPerFrameMinStrict) {
      effectiveIntent = Intent.pan;
    }
    final GateDecision g2 = GateDecision(
      effectiveIntent,
      g.zoomReady,
      g.rotateReady,
    );
    updateGateAndArbitrate(g2, veto: veto);
    applyFrame(e, g2, veto: veto);
  }

  void _onEnterRotate() {
    _panAccum = Offset.zero;
    _startRotatePivot();
    debugPrint('[SM] enter ROTATE');
  }

  void _onEnterZoom() {
    _panAccum = Offset.zero;
    _startZoomPivot();
    debugPrint('[SM] enter ZOOM');
  }
}
