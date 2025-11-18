// ignore_for_file: unused_field, unused_local_variable, unused_element
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:collection';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_state/active_property.dart';
import 'map_providers.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/compass_service.dart';
import '../../core/services/projection_service.dart';
import 'map_painter.dart';
import 'partition_overlay.dart';
import '../filter/global_filter.dart';
import 'map_view_controller.dart';
import 'map_points_aggregate.dart';
import '../../core/models/point_group.dart';
import 'dart:math' as math;
import 'par_ema.dart';
import 'par_state.dart';
import '../points/two_tap_picker.dart';
import '../partition/split_partition_controller.dart';
import '../../core/repos/partition_ops.dart';
import '../../core/db/isar_service.dart';
import 'bm_gestures.dart';
import 'parallel_pan_veto.dart';
import 'two_finger_sampler.dart';
import 'two_point_partition.dart';
import 'sim_transform_gesture.dart';
// State machine integration (proof-of-use heartbeat)
import '../../gesture_state_machine.dart' as sm;
import 'transform_model.dart';

// BM-200R3.2: Very gentle pan + clamp. Lower further to 0.5 if still fast.
const double kPanGain = 1.0; // world pan gain applied to screen delta / scale

// Freeze gate cause (top-level per Dart rules)
enum FreezeCause { none, twoDownChange, lifecycle }

// Simple value class replacing the (Offset, Offset) record previously used for
// debug cut line representation to satisfy older analyzer versions.
class CutLine {
  final Offset a;
  final Offset b;
  const CutLine(this.a, this.b);
}

// Apply delta container (pan-only zeroes zoom/rotate components)
class _ApplyDeltas {
  final double dLog; // ln(scale multiplier)
  final double dTheta; // radians
  final Offset pan; // translation in screen-space (already scaled)
  const _ApplyDeltas(this.dLog, this.dTheta, this.pan);
}

// EMA + hysteresis latch for Zoom/Rotate readiness based on cosPar & sep fraction
class _ZrLatch {
  double pE = 0.0, apE = 0.0, orthoE = 0.0;
  bool zoomReady = false, rotateReady = false;
  void reset() {
    pE = apE = orthoE = 0.0;
    zoomReady = rotateReady = false;
  }

  void feed(double cosPar, double sepFrac, {double alpha = 0.25}) {
    final double p = (cosPar + 1.0) * 0.5;
    final double ap = (1.0 - cosPar) * 0.5;
    final double ortho = 1.0 - cosPar.abs();
    pE += (p - pE) * alpha;
    apE += (ap - apE) * alpha;
    orthoE += (ortho - orthoE) * alpha;
    final bool bigEnough = sepFrac >= 0.04; // ~4% of min(viewW,viewH)
    // Zoom latch hysteresis (enter 0.35, exit 0.25)
    if (!zoomReady) {
      zoomReady = bigEnough && apE >= 0.35; // enter
    } else {
      zoomReady = bigEnough && apE >= 0.25; // exit
    }
    // Rotate latch hysteresis (enter 0.40, exit 0.30)
    if (!rotateReady) {
      rotateReady = bigEnough && orthoE >= 0.40;
    } else {
      rotateReady = bigEnough && orthoE >= 0.30;
    }
  }
}

// G0: Pan delta node for per-gesture queueing
class PanDelta {
  final int gid; // gestureId at enqueue time
  final int seq; // strictly increasing per gesture
  final Offset dP; // screen-space delta
  PanDelta(this.gid, this.seq, this.dP);
}

// ========================= Tunables (BM-194/195) =========================
// Central place for all gesture & logging tuning knobs. Screenshot/share this
// block during tuning. Each var includes purpose and start values.
class Tunables {
  // Hysteresis for scale win (smaller = more eager to zoom)
  static const double zoomHys =
      0.05; // retune: slightly higher so Rotate can win when intentional

  // Hysteresis for angle win (radians). 0.10 ≈ 5.7°
  static const double rotHysRad =
      0.20; // keep ~6.9° threshold; ensures deliberate rotate

  // Min finger separation to allow rotation (prevents jittery twiffst)

  // static const double minSepPx = 160.0; // larger separation reduces angle noise on small spans

  // Time above threshold before locking a mode (stabilizes intent)
  static const int dwellMs = 240; // 180–200ms dwell to stabilize lock decisions

  // Ignore re-decisions after a lock (prevents flapping)
  static const int cooldownMs = 240; // avoid rapid re-decisions after a lock

  // Max mode switches per gesture (more feels jumpy)
  static const int maxSwitches = 2; // start: 2, range: 1–2

  // Pan speed multiplier (keep = 1.0 at first)
  // Lowered slightly so tiny two-finger drift doesn't undermine rotate-only
  static const double panGain = 0.90; // retune: slightly reduce pan influence

  // Lower/upper scale clamps (app dependent)
  static const double scaleMin = 0.7; // start: 0.7×, range: 0.5–1.0
  static const double scaleMax = 6.0; // start: 6.0×, range: 3–12

  // Clamp after each update (prevent “vanish”)
  // For anchoring validation, temporarily set to false so clamping doesn't
  // nudge the view during rotation; re-enable after testing.
  static const bool keepInBounds =
      false; // re-enabled: keep view on canvas; we re-pin focal after clamp

  // Keep angle in [−π, +π] (for consistent logs)
  static const bool angleWrap = true; // start: on

  // Smoothing for dScale/dAngle (lower = smoother)
  static const double lowpassAlpha =
      0.22; // lower smoothing; apply only after lock to avoid undecided noise
  static const bool seqAllow =
      false; // tuned: off for now; prove modes independently, re-enable after tuning
  static const int seqCooldownMs =
      160; // tuned: keep higher if re-enabled later

  // On double-tap, reset to Undecided only (don’t reset rotation)
  static const bool tapResetMode = true; // start: on
  static const double tapZoomFactor = 1.35; // start: 1.35×, range: 1.2–1.6

  // How often to log FPS (perf tracing)
  static const int fpsLogIntervalMs = 500; // start: 500 ms, range: 250–1000

  static const double panGainDuringRotate = 0.0;
}
// ==========================================================================

// ================== BM-199: Detection via Accumulated Evidence ==================
// Sliding-window accumulators over a short time horizon to suggest a lock
// decision while undecided, based on sums of |dθ|, |log(sep2/sep1)| and
// non-parallel motion. Emit a single "enter" line when crossing thresholds.

enum BM199Lock { none, rotate, zoom }

class BM199Params {
  double rotHysRad; // radians
  double zoomHys; // unitless (sum of |log(sep2/sep1)|)
  double minSepPx; // pixel threshold (DPI-aware)
  int windowMs; // accumulation window
  int cooldownMs; // not used here, but kept for parity
  int
  vetoWindowMs; // window to keep veto active after a parallel-like detection
  // BM-199B.2 tunables
  double kDominance; // dominance factor
  double panParallelCosMin; // consider motion parallel if cos >= this
  double maxSepFracChange; // consider separation stable if frac change <= this
  double
  residualFracMax; // NEW: residual (|Δ1-Δ2|/sep) average threshold for veto
  double mMin; // minimum per-finger movement to consider direction (px)
  double
  minRotAbs; // absolute twist minimum in window to allow rotate lock (rad)
  double dThetaClamp; // per-frame |dθ| clamp for evidence
  // BM-200B.8-aligned minimum rates (rad/s and |log|/s)
  double minRotRate;
  double minZoomRate;

  BM199Params({
    this.rotHysRad = 0.22,
    this.zoomHys = 0.06,
    this.minSepPx = 96,
    this.windowMs = 220,
    this.cooldownMs = 240,
    this.vetoWindowMs = 120,
    this.kDominance = 1.30,
    this.panParallelCosMin = 0.90,
    this.maxSepFracChange = 0.05,
    this.residualFracMax = 0.12,
    this.mMin = 0.10,
    this.minRotAbs = 0.35,
    this.dThetaClamp = 0.12,
    this.minRotRate = 0.35,
    this.minZoomRate = 0.30,
  });
}

// Gate → BM-199 pass-through container (single source of truth from PARGATE)
class GateDecision {
  final String mode; // 'pan' | 'zoom' | 'rotate' | 'zr'
  final bool veto;
  final bool zoomReady;
  final bool rotateReady;
  final double dLogLP;
  final double dThetaLP;
  final Offset centroidW; // world-space pivot

  const GateDecision({
    required this.mode,
    required this.veto,
    required this.zoomReady,
    required this.rotateReady,
    required this.dLogLP,
    required this.dThetaLP,
    required this.centroidW,
  });
}

class BM199Telemetry {
  final String mode; // echo of gate.mode
  final bool zoomOk; // mirrors gate.zoomReady
  final bool rotateOk; // mirrors gate.rotateReady
  const BM199Telemetry({
    required this.mode,
    required this.zoomOk,
    required this.rotateOk,
  });
}

class _BM199Sample {
  final int t; // ms
  final double rotEv; // |dθ|
  final double zoomEv; // |log(sep2/sep1)|
  final double nonPan; // |Δ1 - Δ2| / max(sep,1)
  _BM199Sample(this.t, this.rotEv, this.zoomEv, this.nonPan);
}

class _BM199Window {
  final int windowMs;
  final List<_BM199Sample> q = <_BM199Sample>[];
  double rotSum = 0, zoomSum = 0, nonPanSum = 0;
  _BM199Window(this.windowMs);

  void add(_BM199Sample s) {
    q.add(s);
    rotSum += s.rotEv;
    zoomSum += s.zoomEv;
    nonPanSum += s.nonPan;
    _prune(s.t);
  }

  void reset() {
    q.clear();
    rotSum = zoomSum = nonPanSum = 0;
  }

  void _prune(int nowMs) {
    final cutoff = nowMs - windowMs;
    while (q.isNotEmpty && q.first.t < cutoff) {
      final old = q.removeAt(0);
      rotSum -= old.rotEv;
      zoomSum -= old.zoomEv;
      nonPanSum -= old.nonPan;
    }
  }
}

// Small sample for windowed parallel-pan veto averaging
class _VetoSample {
  final int t; // ms
  final double cosPar;
  final double sepFrac;
  final double resid; // |Δ1-Δ2| / max(sep,48)
  final double enough; // 1.0 if both moved >= mMin; else 0.0
  _VetoSample(this.t, this.cosPar, this.sepFrac, this.resid, this.enough);
}

class BM199Gate {
  final BM199Params p;
  final _BM199Window _w;
  double? _prevSep;
  int? _lastNowMs; // for per-frame rate logging

  BM199Gate(this.p) : _w = _BM199Window(p.windowMs);

  // Passive telemetry: logs candidate & rates each frame; never alters decisions
  BM199Telemetry telemetry(
    GateDecision gate, {
    bool freeze = false,
    int? nowMs,
  }) {
    double zoomRate = 0.0, rotRate = 0.0;
    if (nowMs != null && _lastNowMs != null) {
      final dt = (nowMs - _lastNowMs!).toDouble() / 1000.0;
      if (dt > 0) {
        zoomRate = gate.dLogLP.abs() / dt;
        rotRate = gate.dThetaLP.abs() / dt;
      }
    }
    if (nowMs != null) _lastNowMs = nowMs;
    final bool zoomOk = gate.zoomReady && zoomRate > 0.02;
    final bool rotateOk = gate.rotateReady && rotRate > 0.5;
    debugPrint(
      '[BM-199] mode=${gate.mode} zoomOk=$zoomOk rotateOk=$rotateOk veto=${gate.veto} freeze=$freeze zoomRate=${zoomRate.toStringAsFixed(3)} rotRate=${rotRate.toStringAsFixed(3)}',
    );
    return BM199Telemetry(mode: gate.mode, zoomOk: zoomOk, rotateOk: rotateOk);
  }

  void reset() {
    _w.reset();
    _prevSep = null;
  }

  BM199Lock update({
    required int nowMs,
    required double sepPx,
    required double dThetaWrapped,
    required double dx1,
    required double dy1,
    required double dx2,
    required double dy2,
  }) {
    final sepOk = sepPx >= p.minSepPx;
    double zoomEv = 0.0;
    if (_prevSep != null && _prevSep! > 0) {
      final ratio = sepPx / _prevSep!;
      if (ratio != 0) {
        zoomEv = (math.log(ratio.abs())).abs();
      }
    }
    _prevSep = sepPx;

    // BM-199B.2 -- normalized, bounded non-parallelism evidence
    final ndx = dx1 - dx2;
    final ndy = dy1 - dy2;
    final double dvDist = math.sqrt(ndx * ndx + ndy * ndy);
    final double sepSafe = math.max(sepPx, 48.0); // avoid blow-ups when close
    double nonPanEv = dvDist / sepSafe; // ~radian proxy similar to rotEv
    if (nonPanEv > 0.06) nonPanEv = 0.06; // cap noisy spikes (~3.4°/frame)

    // Parallel-pan suppression when motion is parallel and separation stable
    final double d1Len = math.sqrt(dx1 * dx1 + dy1 * dy1);
    final double d2Len = math.sqrt(dx2 * dx2 + dy2 * dy2);
    double? cos12;
    if (d1Len >= p.mMin && d2Len >= p.mMin) {
      final double dot = dx1 * dx2 + dy1 * dy2;
      final double denom = d1Len * d2Len;
      if (denom > 0) cos12 = dot / denom;
    }
    double sepFracChange = 0.0;
    if (_prevSep != null && _prevSep! > 0) {
      sepFracChange = ((sepPx - _prevSep!).abs()) / _prevSep!;
    }
    if (cos12 != null &&
        cos12 >= p.panParallelCosMin &&
        sepFracChange <= p.maxSepFracChange) {
      nonPanEv = 0.0;
    }

    // Clamp per-frame rotation evidence to reduce spikes
    final double rotEv = math.min(dThetaWrapped.abs(), p.dThetaClamp);

    _w.add(_BM199Sample(nowMs, rotEv, zoomEv, nonPanEv));
    if (!sepOk) return BM199Lock.none;

    // BM-199B.2 dominance rule with down-weighted nonPan
    final double kDominance = p.kDominance;
    const double kNonPanWeight = 0.60;

    final double rotAccum = _w.rotSum;
    final double zoomAccum = _w.zoomSum;
    final double nonPanAccum = _w.nonPanSum;

    final double competitorForRot = math.max(
      zoomAccum,
      nonPanAccum * kNonPanWeight,
    );
    final bool canLockRotate =
        (rotAccum >= p.rotHysRad) &&
        (rotAccum >= p.minRotAbs) &&
        (rotAccum >= kDominance * competitorForRot);
    if (canLockRotate) return BM199Lock.rotate;

    final double competitorForZoom = math.max(
      rotAccum,
      nonPanAccum * kNonPanWeight,
    );
    final bool canLockZoom =
        (zoomAccum >= p.zoomHys) &&
        (zoomAccum >= kDominance * competitorForZoom);
    if (canLockZoom) return BM199Lock.zoom;
    return BM199Lock.none;
  }

  double get rotAccum => _w.rotSum;
  double get zoomAccum => _w.zoomSum;
  double get nonPanAccum => _w.nonPanSum;

  // BM-200B.9g: Advance time for decay without adding evidence.
  // Keeps rot/zoom accumulators from growing while allowing window pruning.
  void tickNoGrowth({required int nowMs, required double sepPx}) {
    // Maintain previous separation so subsequent zoomEv calculations stay consistent
    _prevSep = sepPx;
    // Add a zero-evidence sample at nowMs to trigger window pruning/decay
    _w.add(_BM199Sample(nowMs, 0.0, 0.0, 0.0));
  }
}
// ===============================================================================
// Tuning playbook (movement-first)
// - Pan is always on: apply translation each frame around two-finger focal.
// - Decide mode by evidence + hysteresis + dwell:
//   * If sep < min_sep_px => rotation evidence = 0 for the frame.
//   * Smooth |dScale|/|dAngle| with lowpass_alpha.
//   * If neither beats hysteresis => mode=Undecided (pan only).
//   * If one beats and stays > hysteresis for dwell_ms => lock that mode.
// - While locked:
//   * Zoom: apply scale only (+pan), ignore angle (still track peakAngle for logs).
//   * Rotate: apply angle only (+pan), ignore scale (still track peakScaleΔ for logs).
// - Switching (optional): after cooldown_ms allow up to max_switches if other signal > 1.6× its hysteresis.
// - Always clamp & keep in bounds: clamp scale to [scale_min, scale_max], clamp pan to content bounds.
// - Gesture end: emit one event line with dwell, peaks, reason="gesture end".
//
// Quick fixes:
// - Rotate -> Zoom accidentally: raise rot_hys or lower zoom_hys, raise min_sep_px.
// - Zoom -> Rotate accidentally: raise zoom_hys; ensure fingers not too close; raise min_sep_px.
// - Mode flapping: raise dwell_ms and cooldown_ms; try seq_allow=false.
// - Rotation jitter: raise rot_hys and/or lowpass_alpha; confirm angle ignored while in Zoom.
// - "Flies off": verify transform order translate→rotate/scale and clamp after compose.
// - Random zoom jumps: ensure only one of scale/angle is applied per frame; mark the other as [ignored] in logs.
// - Rotation not detected: log sep; if sep < min_sep_px, lower min_sep_px or spread fingers.
//
// Logging cadence:
// - [BM-194 S] one per frame; [BM-194 E] on transitions/end; renderer logs (e.g., [BM-190] PAINT) separate.
// Validation routine:
// - Two-finger pan: expect Undecided; only pan changes. Zoom-only: Undecided→Zoom; steady zoom; end.
// - Rotate-only: Undecided→Rotate; steady rotate; end.
// - Sequence: Rotate ~1s then squeeze; expect one Rotate→Zoom after cooldown; no further switches.

enum TwoFingerMode { undecided, rotate, zoom }

// Winner-takes-all gating enum used for consistent veto
enum GMode { pan, zoom, rotate }

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});
  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Simple gesture pipeline feature flag (post-BM-200 experimentation)
  // Enabled: bypass legacy PARGATE/SM/READY logic for two-finger input.
  static const bool kUseSimGesture =
      true; // set false to revert to legacy pipeline
  // Simplified detector instance: rotation HARD-OFF (button-only rotation policy).
  // To reintroduce gesture rotation later, replace this with enableRotation:true and add applyRotate back.
  // Future toggle: when true AND sim rotation enabled, allow gesture rotation.
  static const bool kEnableSimRotateLater = false; // keep false for shipping
  // BM-200R3.0: pan-only SIM; no gesture zoom/rotate.
  final SimTransformGesture _sim = SimTransformGesture();
  // Zoom edge disappearance note (v1 expected behavior):
  // At higher scales (≈3.5–4.0 and above), the viewport cannot contain the full
  // farm/world bounds simultaneously. Our pan clamp keeps some portion visible,
  // so naturally two sides "disappear" (move out of view) as you zoom in.
  // This is NOT a geometry bug—it's the consequence of limited viewport size.
  // Future refinements after pan+zoom feel solid:
  //  - Use the gesture focal point as the zoom pivot instead of viewport center
  //    to reduce the apparent drift and keep the farmer's area of interest
  //    anchored.
  //  - Potentially loosen or soften clamp behavior (e.g., allow slight overscroll
  //    or implement elastic edges) so the transform doesn't over-snap when near
  //    bounds.
  //  - Consider adaptive scaling limits per property size.
  // For v1: treat the disappearance of opposite edges at high zoom as expected.

  // R.12a: Disable legacy writes; SM is single source of truth for apply
  // BM-200R2.2: legacy XFORM zoom/rotate fully disabled (single engine = SIM + button rotates).
  static const bool legacyApplyEnabled =
      false; // kept for reference; not used now.
  // Ensure global flag also off.
  // Flag init moved to initState.
  // Long-lived gesture state machine instance with no-op apply hooks (we already apply elsewhere).
  // This now drives the single-source transform model.
  final TransformModel _xform = TransformModel(
    suppressLogs: _MapViewScreenState.kUseSimGesture,
  );
  // --- Simplified gesture helper methods (SIM path) ---
  // Axis-aligned clamp ignoring rotation to keep map on-screen with a margin.
  void _clampAxisAligned({double margin = 32.0}) {
    if (_worldBounds == null || _lastPaintSize == Size.zero) return;

    // World bounds in map space and current scale.
    final Rect bounds = _worldBounds!;
    final double S = _xform.scale;

    // Map rect in screen space after transform (ignoring rotation).
    final Rect mapScreenRect = Rect.fromLTWH(
      bounds.left * S + _xform.tx,
      bounds.top * S + _xform.ty,
      bounds.width * S,
      bounds.height * S,
    );

    // Viewport size available from last paint.
    final Size viewportSize = _lastPaintSize;

    double tx = _xform.tx;
    double ty = _xform.ty;

    if (mapScreenRect.right < margin) {
      tx += (margin - mapScreenRect.right);
    }
    if (mapScreenRect.left > viewportSize.width - margin) {
      tx -= (mapScreenRect.left - (viewportSize.width - margin));
    }
    if (mapScreenRect.bottom < margin) {
      ty += (margin - mapScreenRect.bottom);
    }
    if (mapScreenRect.top > viewportSize.height - margin) {
      ty -= (mapScreenRect.top - (viewportSize.height - margin));
    }

    _xform.tx = tx;
    _xform.ty = ty;
  }

  // BM-200R2.2: Single apply for SIM updates. Ignores gesture rotation.
  void _applySimGesture(SimGestureUpdate u) {
    if (u.panDeltaPx == Offset.zero) return;
    if (_worldBounds == null || _xform.viewportSize == Size.zero) return;

    final Rect worldBounds = _worldBounds!;
    final Size view = _xform.viewportSize;

    // 1) PAN in world units, with small gain so it can't "fly away".
    final double dxWorld = (u.panDeltaPx.dx * kPanGain) / _xform.scale;
    final double dyWorld = (u.panDeltaPx.dy * kPanGain) / _xform.scale;
    _xform.applyPan(dxWorld, dyWorld);

    // 2) Clamp so at least some part of the farm stays visible.
    _xform.clampPan(worldBounds: worldBounds, view: view);

    debugPrint(
      '[APPLY] sim pan Δpx=(${u.panDeltaPx.dx.toStringAsFixed(2)},${u.panDeltaPx.dy.toStringAsFixed(2)}) '
      '→ T=(${_xform.tx.toStringAsFixed(1)},${_xform.ty.toStringAsFixed(1)}) '
      'S=${_xform.scale.toStringAsFixed(2)}',
    );
  }

  void _applyPanFromScreenDelta(Offset dPx) {
    if (dPx == Offset.zero) return;
    _xform.tx += dPx.dx;
    _xform.ty += dPx.dy;
    debugPrint(
      '[APPLY] sim pan Δpx=(${dPx.dx.toStringAsFixed(2)},${dPx.dy.toStringAsFixed(2)}) → T=(${_xform.tx.toStringAsFixed(1)},${_xform.ty.toStringAsFixed(1)})',
    );
    // Clamp after pan if world bounds known
    if (_worldBounds != null && _lastPaintSize != Size.zero) {
      _xform.clampPan(worldBounds: _worldBounds!, view: _lastPaintSize);
    }
  }

  void _applyZoomFactor(double factor) {
    if (factor == 1.0) return; // no-op
    final size = _lastPaintSize;
    if (size == Size.zero) return; // cannot pivot yet
    final center = size.center(Offset.zero);
    final pivotW = screenToWorldXform(center, _xform);
    final dLog = math.log(factor);
    _xform.applyZoom(dLog, pivotW: pivotW, pivotS: center);
    if (_worldBounds != null) {
      _xform.clampPan(worldBounds: _worldBounds!, view: size);
    }
  }

  void _applyRotationDelta(double dTheta) {
    if (dTheta == 0.0) return;
    final size = _lastPaintSize;
    if (size == Size.zero) return;
    // Buttons only: update theta via pivoted rotate; then clamp pan.
    final center = size.center(Offset.zero);
    final pivotW = screenToWorldXform(center, _xform);
    _xform.applyRotate(dTheta, pivotW: pivotW, pivotS: center);
    if (_worldBounds != null) {
      _xform.clampPan(worldBounds: _worldBounds!, view: size);
    }
  }

  // BM-200R3.0: Button zoom helper (log-scale step).
  // Field edges "disappearing" note:
  // At higher scales (≈3–4×), the world/farm spans more pixels than the viewport
  // can show simultaneously. After a zoom, we clamp pan so some portion stays
  // visible; naturally, opposite sides move out of view. This is expected for
  // any zoom+clamp scheme and not a rendering bug. Future (post‑ship) ideas:
  //  * Use last tap / gesture focal point as zoom pivot instead of viewport center.
  //  * Loosen or soften clampPan (elastic margin / slight overscroll) to reduce
  //    the feeling of snapping.
  //  * Adaptive scale limits based on property size or screen class.
  // For BM-200R3.x we keep it simple and predictable.
  void _zoomByStep(double stepLogS) {
    if (_worldBounds == null || _xform.viewportSize == Size.zero) return;
    final Rect worldBounds = _worldBounds!;
    final Size view = _xform.viewportSize;
    final Offset pivotS = Offset(view.width / 2, view.height / 2);
    final Offset pivotW = Offset(
      (pivotS.dx - _xform.tx) / _xform.scale,
      (pivotS.dy - _xform.ty) / _xform.scale,
    );
    _xform.applyZoom(stepLogS, pivotW: pivotW, pivotS: pivotS);
    _xform.clampPan(worldBounds: worldBounds, view: view);
    setState(() {});
    debugPrint(
      '[BTN] zoom step=${stepLogS.toStringAsFixed(3)} S=${_xform.scale.toStringAsFixed(3)}',
    );
  }

  // Convenience degrees-based rotate wrapper for buttons.
  void _rotateByDegrees(double dDeg) {
    final double dTheta = dDeg * math.pi / 180.0;
    _applyRotationDelta(dTheta);
    setState(() {});
    debugPrint(
      '[BTN] rotate d=${dDeg.toStringAsFixed(1)}° rot=${_xform.rotRad.toStringAsFixed(3)}',
    );
  }

  // BM-200R3.2: Home (fit-to-screen) safety net.
  void _homeView() {
    if (_worldBounds == null || _xform.viewportSize == Size.zero) return;
    _xform.homeTo(
      worldBounds: _worldBounds!,
      view: _xform.viewportSize,
      margin: 0.06,
    );
    setState(() {});
    debugPrint(
      '[BTN] home → scale=${_xform.scale.toStringAsFixed(3)} T=(${_xform.tx.toStringAsFixed(1)},${_xform.ty.toStringAsFixed(1)})',
    );
  }

  // Rotation intentionally omitted in SIM path (button-only rotate policy).
  // Pivot captured on SM mode enter (screen/world), reused until exit
  Offset? _smPivotS;
  Offset? _smPivotW;

  late final sm.GestureStateMachine _sm = sm.GestureStateMachine.simple(
    applyRotate: (double dTheta) {
      // Reuse pivot captured on mode enter to avoid per-frame drift
      final size = _lastPaintSize;
      final Offset pivotS = _smPivotS ?? (size.center(Offset.zero));
      final Offset pivotW = _smPivotW ?? screenToWorldXform(pivotS, _xform);
      _xform.applyRotate(dTheta, pivotW: pivotW, pivotS: pivotS);
      // Trigger repaint so painter reads updated SM transform
      if (mounted) setState(() {});
      debugPrint(
        '[APPLY] mode=rotate dθ=${dTheta.toStringAsFixed(5)} → rot=${_xform.rotRad.toStringAsFixed(5)}',
      );
      // Anchor consistency probe (floating-point drift should be tiny)
      assert(() {
        final w = screenToWorldXform(pivotS, _xform);
        final err = (w - pivotW).distance;
        debugPrint(
          '[ANCHOR] |world(pivotS) - pivotW| = ${err.toStringAsExponential(2)}',
        );
        return true;
      }());
    },
    applyZoom: (double dLogS) {
      final size = _lastPaintSize;
      final Offset pivotS = _smPivotS ?? (size.center(Offset.zero));
      final Offset pivotW = _smPivotW ?? screenToWorldXform(pivotS, _xform);
      _xform.applyZoom(dLogS, pivotW: pivotW, pivotS: pivotS);
      // Trigger repaint so painter reads updated SM transform
      if (mounted) setState(() {});
      assert(() {
        final w = screenToWorldXform(pivotS, _xform);
        final err = (w - pivotW).distance;
        debugPrint(
          '[ANCHOR] |world(pivotS) - pivotW| = ${err.toStringAsExponential(2)}',
        );
        return true;
      }());
      debugPrint(
        '[APPLY] mode=zoom dLogS=${dLogS.toStringAsFixed(5)} → scale=${_xform.scale.toStringAsFixed(5)}',
      );
    },
    applyPan: (dx, dy) {
      // Pan is a pure screen-translation of T; must not touch scale/rot
      final preScale = _xform.scale;
      final preRot = _xform.rotRad;
      _xform.applyPan(dx, dy);
      // Trigger repaint so painter reads updated SM transform
      if (mounted) setState(() {});
      assert(() {
        if (_xform.scale != preScale || _xform.rotRad != preRot) {
          debugPrint('[SM] PAN invariant violated: scale/rot changed');
        }
        return true;
      }());
      debugPrint(
        '[APPLY] mode=pan Δpx=(${dx.toStringAsFixed(2)},${dy.toStringAsFixed(2)}) → T=(${_xform.tx.toStringAsFixed(2)},${_xform.ty.toStringAsFixed(2)})',
      );
    },
    startRotatePivot: () {
      // Capture pivot on enter(rotate)
      final size = _lastPaintSize;
      final Offset ps = (_parCentroidNow ?? size.center(Offset.zero));
      final Offset pw = screenToWorldXform(ps, _xform);
      _smPivotS = ps;
      _smPivotW = pw;
      debugPrint(
        '[SM] pivot(rotate) S=(${ps.dx.toStringAsFixed(1)},${ps.dy.toStringAsFixed(1)})',
      );
    },
    startZoomPivot: () {
      // Capture pivot on enter(zoom)
      final size = _lastPaintSize;
      final Offset ps = (_parCentroidNow ?? size.center(Offset.zero));
      final Offset pw = screenToWorldXform(ps, _xform);
      _smPivotS = ps;
      _smPivotW = pw;
      debugPrint(
        '[SM] pivot(zoom) S=(${ps.dx.toStringAsFixed(1)},${ps.dy.toStringAsFixed(1)})',
      );
    },
  );

  // Shared minimum separation threshold (px) used across gate, veto, apply
  static const double kParMinSepPx = 40.0;
  static const String _tag = '[BM-178 r4]';
  // (legacy debug toggles removed; using structured BM-194/195 logs instead)

  // ===================== BM-195 CONFIG =====================
  static const double kZoomHys = Tunables.zoomHys;
  static const double kRotHysRad = Tunables.rotHysRad;
  static const int kDwellMs = Tunables.dwellMs;
  static const int kCooldownMs = Tunables.cooldownMs;
  static const bool kSeqAllow = Tunables.seqAllow;
  static const int kSeqCooldownMs = Tunables.seqCooldownMs;
  static const int kMaxSwitches = Tunables.maxSwitches;
  static const double kLowpass = Tunables.lowpassAlpha;
  // ==========================================================

  // ===================== BM-194 LOGGING =====================
  static const bool kBM194Enable = true; // master toggle
  static const bool kBM194StateLogs = true; // per-frame state logs
  static const bool kBM194EventLogs = true; // mode transitions & end
  DateTime? _bm194LastFrameTs; // for FPS
  DateTime? _bm194FpsLastTs; // throttle FPS prints
  // ==========================================================

  // View state
  Matrix4 _view = Matrix4.identity();
  Offset _pan = Offset.zero;
  double _scale = 1.0;
  double _rotation = 0.0;
  // PAR centroid anchored apply state (BM-200B centroid sequence)
  Offset?
  _parCentroidPrev; // screen-space centroid previous frame (from sampler)
  Offset? _parCentroidNow; // screen-space centroid current frame (from sampler)
  // Feature flag to enable new unified centroid Z/R + residual pan application
  static const bool kParCentroidApply = true;
  Size _lastPaintSize = Size.zero;
  double _startScale = 1.0;
  double _startRotation = 0.0;
  bool _didFit = false;
  // World bounds inferred from data (set in _fitOnce)
  Rect? _worldBounds;
  // Pivot anchor in world space for zoom/rotate (low-pass updated)
  Offset? _pivotWAnchor;
  // Leash logging flag
  bool _leashedLastFrame = false;

  // Gesture state
  bool _isGesturing = false;
  TwoFingerMode _twoMode = TwoFingerMode.undecided;
  // BM-195 uses incremental deltas from raw values; legacy baselines removed
  Offset _lastFocal = Offset.zero;
  AnimationController? _animCtrl;
  final double _minScale = Tunables.scaleMin;
  final double _maxScale = Tunables.scaleMax;

  // Gesture sensitivity for rotation pacing (more responsive)
  final double _rotationGain = 0.60; // faster response to twist
  final double _maxRotateStep = 0.25; // max radians per update (~14.3°)
  final double _maxRotateRate = 2.5; // max radians per second (~143°/s)
  int? _lastRotateMs; // monotonic ms for rotate limiter

  // BM-198 Test B: rolling drift window for rotate anchoring verification
  final int _bm198WindowSize = 10;
  final List<double> _bm198RotDrifts = <double>[]; // last N driftPx samples
  double _bm198Median(List<double> v) {
    if (v.isEmpty) return 0.0;
    final s = List<double>.from(v)..sort();
    final n = s.length;
    if (n % 2 == 1) return s[n >> 1];
    return (s[(n >> 1) - 1] + s[n >> 1]) / 2.0;
  }

  // BM-195 session state
  int _gid = 0; // gesture id
  bool _twoDown = false; // true while exactly two pointers are down
  // Dropout grace to avoid gid churn on brief flickers
  int _twoBelowSinceMs = -1; // ms when pointers dropped below 2; -1 = none
  static const int _twoDropoutGraceMs =
      60; // ms grace before ending gesture (pointer hygiene)
  DateTime _lockTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastEvidenceTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _switches = 0;
  DateTime _lastSwitchTime = DateTime.fromMillisecondsSinceEpoch(0);
  // Evidence accumulators and peaks
  double _eScale = 0.0; // smoothed |dScale|
  double _eAngle = 0.0; // smoothed |dAngle|
  double _peakScaleDelta = 0.0;
  double _peakAngle = 0.0;
  // Cumulative rotation (sum of wrapped dθ) for stable peakAngle tracking
  double _cumAngleTotal = 0.0;
  // Post-lock smoothing accumulators for applied deltas (not used in undecided)
  double _sAngle = 0.0; // smoothed dAngle for apply
  double _sScale = 0.0; // smoothed dScale for apply
  // BM-199B.3: remember last veto state to log flips
  bool? _bm199PrevVeto;
  // BM-199B.4: gesture-long pointer pair lock and veto averaging buffer
  bool _pairLocked = false;
  int? _pairId1;
  int? _pairId2;
  final List<_VetoSample> _vetoBuf = <_VetoSample>[];
  int _par9eLastSeq = -1;
  int _par9eLastVer = -1;
  double _par9eLastCos = 0.0;
  double _par9eLastSep = 0.0;
  // Post office: defer concise APPLY print until after GATE per frame
  // Legacy post-apply flags removed (previous concise APPLY log deprecated).
  // Removed legacy post-apply delta caches (_postApplyDAngle/_postApplyDScale)
  // PAR feed log limiter per gesture
  int _parFeedLogCount = 0;
  static const double _twoPanEps = 0.25; // px; pre-ENQ deadband
  static const double _applyPanEps = 0.75; // px; optional APPLY epsilon
  // E) Rotation/Zoom readiness gate (needs consecutive valid samples)

  // --- Missing private state (PAR 9h + readiness + smoothing + apply queue) ---
  // Single-source PAR state for the current frame (nullable until first compute)
  ParallelPanVetoState? _par9eState;
  // 9d/9e helper EMA state (centroid-independent raw deltas)
  int _tPrevMs = -1;
  Offset _p1PrevForPar = Offset.zero;
  Offset _p2PrevForPar = Offset.zero;
  bool _currentParVeto = false; // authoritative from 9h state only
  // 9h freeze-guard window and shield
  bool _par9ePrevVeto = false; // retained for legacy logging of veto edges
  FreezeCause _freezeCause = FreezeCause.none;
  DateTime _freezeUntil = DateTime.fromMillisecondsSinceEpoch(0);
  bool _gestureStable = false; // becomes true after first successful apply
  void _setFreeze(FreezeCause cause, Duration dt) {
    _freezeCause = cause;
    _freezeUntil = DateTime.now().add(dt);
    debugPrint(
      '[FREEZE] start cause=${cause.name} dt=${dt.inMilliseconds}ms until=${_freezeUntil.toIso8601String()}',
    );
  }

  bool get _freezeActive {
    final active = DateTime.now().isBefore(_freezeUntil);
    return active && !_gestureStable;
  }

  bool _par9eDidComputeThisFrame = false;
  bool _par9eShieldActive = false;
  int _par9eLastGid = -1;
  // Readiness gate tracking
  int _rdyConsec = 0;
  bool _rotZoomReady = false;
  // Per-gid EMA-based readiness latches (hysteresis)
  bool _emaZoomReady = false;
  bool _emaRotateReady = false;
  final int _rdyConsecMin = 2; // consecutive ready frames
  // Two-finger centroid EMA (micro-jitter suppression)
  final double _twoPanK = 0.35; // 0..1 EMA gain
  Offset? _cFilt;
  Offset? _cLast;
  // Residual-based veto thresholds (legacy constants kept for other paths)
  final double _residVetoEnter = 0.12;
  final double _residVetoExit = 0.08;
  // Single consumer pan apply queue helpers
  Offset _pendingPanDp = Offset.zero;
  // Two-finger pan tracking (screen pixels)
  Offset? _prevCpx; // previous two-finger centroid in screen px
  Offset _panPxLP = Offset.zero; // low-pass pan
  bool _freezePrev = false; // detect freeze transitions
  bool _computeUnifiedVeto(ParState ps, {required bool twoDown}) {
    // New unified veto: gate by twoDown & minSep, then apply residualLP hysteresis
    const double vetoEnter = 0.010; // 1.0%
    const double vetoExit = 0.006; // 0.6%
    bool vetoByResidual(bool prev, double residualLP) {
      if (prev) return residualLP >= vetoExit; // stay vetoed until below exit
      return residualLP >= vetoEnter; // enter veto above enter
    }

    final double sepNow = ps.ema.sepNow; // px
    final bool minSepOk = sepNow >= kParMinSepPx;
    final bool twoOk = twoDown;
    final bool prev = ps.veto; // last global decision (sticky)
    final double rLP = ps.residualLP; // stabilized residual
    final bool residualVeto = vetoByResidual(prev, rLP);
    return !(twoOk && minSepOk) || residualVeto;
  }

  Offset _sumPanSinceLastApply = Offset.zero;
  // Engine used for anchored rotate/zoom apply
  final BmGestureEngine _bmEngine = BmGestureEngine();

  // Apply guard: verify frame gid matches current and PAR state (if available)
  bool _applyGuardOk({required int frameGid}) {
    final s = _par9eState;
    if (s != null && s.frameValid) {
      if (s.gestureId != frameGid) {
        debugPrint(
          '[APPLY_GUARD] skip: gidMismatch par.gid=${s.gestureId} frameGid=$frameGid curGid=$_gid',
        );
        return false;
      }
    } else {
      if (frameGid != _gid) {
        debugPrint(
          '[APPLY_GUARD] skip: gidSnapshot!=_gid frameGid=$frameGid curGid=$_gid',
        );
        return false;
      }
    }
    return true;
  }

  int _seq = 0; // per-gesture sequence counter
  final Queue<PanDelta> _panQ = Queue<PanDelta>();

  void _enqPanFor(int eventGid, Offset dP) {
    // Assert and drop if cross-gid publish attempt
    assert(eventGid == _gid, 'Cross-gid event; dropping');
    if (eventGid != _gid) {
      debugPrint(
        '[G0 PANQ DROP] reason=gidMismatch eventGid=$eventGid curGid=$_gid dP=(${dP.dx.toStringAsFixed(2)},${dP.dy.toStringAsFixed(2)})',
      );
      return;
    }
    final n = PanDelta(eventGid, ++_seq, dP);
    _panQ.addLast(n);
    debugPrint(
      '[G0 PANQ ENQ] gid=${n.gid} seq=${n.seq} dP=(${dP.dx.toStringAsFixed(2)},${dP.dy.toStringAsFixed(2)}) size=${_panQ.length}',
    );
  }

  Offset _drainPanForCurrentGesture() {
    final gidNow = _gid;
    var sum = Offset.zero;
    int n = 0;
    // Discard stale (wrong gid) and accumulate current gid
    while (_panQ.isNotEmpty) {
      final head = _panQ.first;
      if (head.gid != gidNow) {
        // Drop stale nodes from previous gesture with assertion in debug
        assert(head.gid == gidNow, 'Cross-gid event; dropping');
        debugPrint(
          '[G0 PANQ DROP] reason=stale gid=${head.gid} curGid=$gidNow dP=(${head.dP.dx.toStringAsFixed(2)},${head.dP.dy.toStringAsFixed(2)})',
        );
        _panQ.removeFirst();
        continue; // drop stale from previous gesture
      }
      sum += head.dP;
      _panQ.removeFirst();
      n++;
    }
    debugPrint(
      '[G0 PANQ POP] gid=$gidNow n=$n sum=(${sum.dx.toStringAsFixed(2)},${sum.dy.toStringAsFixed(2)})',
    );
    return sum;
  }

  // BM-199 hysteresis latch for residual-based pan veto
  final bool _residualVetoLatched = false; // never reassigned; make final
  // BM-200B.9h: single per-frame, raw-delta parallel pan veto helper
  final ParallelPanVeto _par9e = ParallelPanVeto();
  // BM-200B.9f: coalesced two-finger sampler to stabilize v1/v2
  final TwoFingerSampler _sampler9f = TwoFingerSampler();
  // BM-199B.1 P1: two-point partition plumbing (stable ids + kinematics)
  final TwoPointPartition _tp = TwoPointPartition();
  // Zoom/Rotate EMA latch
  final _ZrLatch _zrLatch = _ZrLatch();
  // BM-200B.7: simple gate dwell tracking for logs (no behavior change)
  int _bm200bGateOnSinceMs = -1;
  bool? _bm200bGateRotate;
  // BM-200B.9g: throttle summary logging while parallel veto holds
  DateTime? _bm200b9gLastSum;

  // Unified readiness predicate used across MODE, BM-199, and APPLY
  // Matches: computed && validN>=8 && sepFracAvg>=0.01 && antiParReady
  bool _parReady(ParallelPanVetoState s) {
    return s.computed &&
        (s.validN >= 8) &&
        (s.sepFracAvg >= 0.01) &&
        s.antiParReady;
  }

  // Update EMA-based hysteresis latches using persistent ParEma state
  // Zoom: enter 0.35, exit 0.25; Rotate: enter 0.40, exit 0.30
  // Both gated by sepFrac >= 0.04
  void _updateEmaReady(ParEma s, double sepFrac) {
    final bool bigEnough = sepFrac >= 0.04;
    // Zoom (anti-parallel channel)
    if (!_emaZoomReady) {
      _emaZoomReady = bigEnough && (s.antiE >= 0.35);
    } else {
      _emaZoomReady = bigEnough && (s.antiE >= 0.25);
    }
    // Rotate (orthogonal channel)
    if (!_emaRotateReady) {
      _emaRotateReady = bigEnough && (s.orthoE >= 0.40);
    } else {
      _emaRotateReady = bigEnough && (s.orthoE >= 0.30);
    }
  }

  // Winner-takes-all decision (pan/zoom/rotate) with sticky ties
  GMode _decide(
    GMode prev,
    bool zoomReady,
    bool rotateReady,
    double antiE,
    double orthoE,
  ) {
    if (!zoomReady && !rotateReady) return GMode.pan;
    const double margin = 0.05;
    if (zoomReady && (!rotateReady || antiE > orthoE + margin)) {
      return GMode.zoom;
    }
    if (rotateReady && (!zoomReady || orthoE > antiE + margin)) {
      return GMode.rotate;
    }
    return prev;
  }

  // RIGID diagnostics: continue logging a few frames post-lock
  int _rigidPostLockFrames = 0;
  bool _rigidCfgLogged = false;
  // Previous raw values
  double _prevRawScale = 1.0;
  // double _prevRawAngle = 0.0; // no longer used; pointer-derived angle used instead
  // _prevFocal removed: two-finger pan now uses centroid EMA
  // prev separation not used (we gate angle by min sep via crude proxy)

  // Low-pass smoothing helper
  static double _lp(double prev, double now) => prev + kLowpass * (now - prev);
  // Angle wrap helper no longer needed; pointer-derived angle uses atan2(cross,dot)

  // Optional screen focal lock (legacy) removed; sticky world anchors used instead
  // Sticky world anchors for locked modes
  Offset? _rotateAnchorWorld;
  Offset? _zoomAnchorWorld;
  // Screen-space anchor at lock time (for drift diagnostics)
  Offset? _rotateAnchorScreen0;
  Offset? _zoomAnchorScreen0;
  // BM-198 diagnostic-only sticky anchor (independent of lock) for Test B
  Offset? _bm198AnchorWorld;
  Offset? _bm198AnchorScreen0;

  // Content bounds in world coordinates (rough default; adjust to your map)
  // final Rect _contentBounds = const Rect.fromLTWH(-2000, -2000, 4000, 4000); // unused after refactor

  // Split preview/debug
  List<Offset>? _previewRingA;
  List<Offset>? _previewRingB;
  // Replaced Dart record (Offset, Offset) with a simple class to maintain
  // compatibility with older analyzer versions used by build_runner.
  CutLine? _debugCutLine;
  bool _splitMode = false;
  // Track active pointer positions in local (screen) space
  final Map<int, Offset> _activePointers = <int, Offset>{};
  // Model A: remember last position for single-finger pan
  Offset? _lastSinglePanPos;
  // Previous two-pointer snapshot for evidence calc
  Offset? _prevP1; // previous screen pos of smaller-ID pointer
  Offset? _prevP2; // previous screen pos of larger-ID pointer
  double? _prevSep; // previous separation
  // double? _prevPairAngle; // previous atan2 angle between p2-p1 (not used)

  // Helpers
  // normalize angle helper no longer used after matrix-delta approach (kept elsewhere if needed)
  // BM-199 per-gesture gate and active pointer pair tracking
  BM199Gate? _bm199Gate;
  (int, int)?
  _bm199PairIds; // smallest two pointer IDs used for evidence; reset on change

  // DPI-aware minSepPx mapping (round to nearest multiple of 8 where applicable)
  // double _minSepForDpi(double dpr) { return 96; } // removed (unused)

  String _modeTitle(TwoFingerMode m) {
    switch (m) {
      case TwoFingerMode.rotate:
        return 'Rotate';
      case TwoFingerMode.zoom:
        return 'Zoom';
      case TwoFingerMode.undecided:
        return 'Undecided';
    }
  }

  String _sgn(double v, {int frac = 1}) {
    final s = v.toStringAsFixed(frac);
    if (s.startsWith('-')) return s; // keep negative
    return '+$s';
  }

  // Keep focal world point pinned using closed-form mapping.
  // previous focal-anchored delta helper is no longer used; replaced by matrix deltas

  // void _composeView(Size size) { /* unused after refactor */ }

  void _decomposeView(Size size) {
    // Extract rotation and scale from 2x2 submatrix, and pan from translation
    final s = _view.storage;
    final m00 = s[0], m10 = s[1];
    final tx = s[12], ty = s[13];
    final sc = math.sqrt(m00 * m00 + m10 * m10);
    final rot = math.atan2(m10, m00);
    _scale = sc;
    _rotation = rot;
    // Our composition is: T(center + pan) * R * S
    // So pan = (t - center)
    final cx = size.width / 2;
    final cy = size.height / 2;
    _pan = Offset(tx - cx, ty - cy);
  }

  // Helpers for pivot and bounds
  Offset _lerpOffset(Offset a, Offset b, double t) =>
      Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
  Offset _clampWorldToBounds(Offset p, Rect b) =>
      Offset(p.dx.clamp(b.left, b.right), p.dy.clamp(b.top, b.bottom));
  double _viewportWorldSpan(Size s) =>
      (math.min(s.width, s.height) / (_scale == 0 ? 1.0 : _scale));

  // Extract scale from a given Matrix4 (based on 2x2 submatrix)
  // double _scaleFrom(Matrix4 m) { return 1.0; } // unused

  // Convert screen-space point to world-space using current pan/scale/rotation
  Offset screenToWorld(
    Offset p,
    Size size,
    Offset pan,
    double scale,
    double rotation,
  ) {
    final center = size.center(Offset.zero);
    final v = p - (center + pan);
    final c = math.cos(-rotation);
    final s = math.sin(-rotation);
    final vx = (v.dx * c - v.dy * s) / scale;
    final vy = (v.dx * s + v.dy * c) / scale;
    return Offset(vx, vy);
  }

  // XFORM mapping helpers (invertible): screen = T(tx,ty) * R * S * world
  Offset worldToScreenXform(Offset w, TransformModel x) {
    final c = math.cos(x.rotRad), s = math.sin(x.rotRad);
    final sx = x.scale * w.dx, sy = x.scale * w.dy;
    return Offset(c * sx - s * sy + x.tx, s * sx + c * sy + x.ty);
  }

  Offset screenToWorldXform(Offset p, TransformModel x) {
    final px = p.dx - x.tx, py = p.dy - x.ty;
    final c = math.cos(x.rotRad), s = math.sin(x.rotRad);
    final rx = c * px + s * py; // R^T * (p - T)
    final ry = -s * px + c * py;
    final sc = (x.scale == 0 ? 1.0 : x.scale);
    return Offset(rx / sc, ry / sc);
  }

  // Quick diagnostics (xform-only mappings)
  void logRoundTrip(Offset pScreen, TransformModel x) {
    final w = screenToWorldXform(pScreen, x);
    final ps = worldToScreenXform(w, x);
    final err = (ps - pScreen).distance;
    debugPrint('[RT] screen→world→screen err=${err.toStringAsExponential(2)}');
  }

  void logWorldAabbOnScreen(Rect worldAabb, TransformModel x) {
    final corners = <Offset>[
      worldAabb.topLeft,
      worldAabb.topRight,
      worldAabb.bottomRight,
      worldAabb.bottomLeft,
    ].map((w) => worldToScreenXform(w, x)).toList();
    final xs = corners.map((p) => p.dx).toList()..sort();
    final ys = corners.map((p) => p.dy).toList()..sort();
    debugPrint(
      '[AABB→screen] x=[${xs.first.toStringAsFixed(1)}, ${xs.last.toStringAsFixed(1)}] y=[${ys.first.toStringAsFixed(1)}, ${ys.last.toStringAsFixed(1)}]',
    );
  }

  // Convert world-space to screen-space using current pan/scale/rotation
  Offset worldToScreen(
    Offset w,
    Size size,
    Offset pan,
    double scale,
    double rotation,
  ) {
    final center = size.center(Offset.zero);
    final c = math.cos(rotation);
    final s = math.sin(rotation);
    final rx = w.dx * c - w.dy * s;
    final ry = w.dx * s + w.dy * c;
    return center + pan + Offset(rx * scale, ry * scale);
  }

  // Explicit pan application helper to keep spaces consistent
  // M maps World -> Screen
  // panPx: screen-space delta (pixels), panW: world-space delta (map units)
  Matrix4 _applyPanMatrix(Matrix4 M, {Offset? panPx, Offset? panW}) {
    assert((panPx == null) ^ (panW == null), 'Provide exactly one');
    if (panPx != null) {
      // SCREEN-SPACE PAN: pre-multiply by screen translation
      final T = Matrix4.identity()..translate(panPx.dx, panPx.dy);
      return T..multiply(M);
    } else {
      // WORLD-SPACE PAN: post-multiply by world translation
      final w = panW!;
      final tw = Matrix4.identity()..translate(w.dx, w.dy); // lowerCamelCase
      return Matrix4.copy(M)..multiply(tw);
    }
  }

  // ================= Unified PAR APPLY (persistent angle & scale) =================

  _ApplyDeltas _deltasFor(
    String mode,
    double dLogLP,
    double dThetaLP,
    Offset panLP,
  ) {
    switch (mode) {
      case 'pan':
        return _ApplyDeltas(0.0, 0.0, panLP); // pure translation
      case 'zoom':
        return _ApplyDeltas(dLogLP, 0.0, Offset.zero);
      case 'rotate':
        return _ApplyDeltas(0.0, dThetaLP, Offset.zero);
      case 'zr': // combined zoom+rotate mode (if present)
        return _ApplyDeltas(dLogLP, dThetaLP, Offset.zero);
    }
    // Should never reach here; safeguard
    return _ApplyDeltas(0.0, 0.0, Offset.zero);
  }

  // New apply respecting mode: pan does NOT mutate scale/rotation.
  // Uses per-frame snapshots for mode/deltas/pan pivot to avoid mismatch.
  void _applyParGate({
    required ParState ps,
    required Offset pivotWorld,
    required _ApplyDeltas deltas,
  }) {
    final size = _lastPaintSize;
    if (size == Size.zero) return;
    // Kill legacy path entirely; keep stub for reference
    if (!legacyApplyEnabled) {
      // (dead code - never runs)
      // applyPan(...); applyZoom(...); applyRotate(...);
      return;
    }
    ps.mPrev ??= Matrix4.copy(_view);
    final _ApplyDeltas d = deltas;
    // Legacy apply guard — TEMP: when SM owns rotate/zoom, block legacy apply entirely
    if (_sm.mode != sm.Mode.pan) {
      debugPrint('[SM] blocked legacy apply while sm.mode=${_sm.mode}');
      return;
    }
    // Accumulate scale/rotation only if active
    if (d.dTheta != 0.0) {
      ps.rotRad += d.dTheta;
      // Optional rotation leash: keep within [-pi, pi]
      if (ps.rotRad > math.pi) ps.rotRad -= 2 * math.pi;
      if (ps.rotRad < -math.pi) ps.rotRad += 2 * math.pi;
      ps.totalRotDeg = ps.rotRad * 180.0 / math.pi;
    }
    if (d.dLog != 0.0) {
      final double sBefore = ps.totalScale;
      final double sProp = sBefore * math.exp(d.dLog);
      final double minS = ps.minScale;
      final double maxS = ps.maxScale;
      final double sClamped = sProp.clamp(minS, maxS);
      if (sClamped == maxS && sBefore < maxS) {
        debugPrint('[CLAMP] hit maxScale=$maxS');
      }
      if (sClamped == minS && sBefore > minS) {
        debugPrint('[CLAMP] hit minScale=$minS');
      }
      ps.totalScale = sClamped;
    }
    // Compose matrix: anchored zoom/rotate around snapped world pivot; pan as simple translate
    final sizeNow = size;
    Matrix4 M = ps.mPrev!;
    if (d.dTheta != 0.0 || d.dLog != 0.0) {
      final double dLogApplied =
          d.dLog; // already low-pass; clamp via ps.totalScale reconstruction
      final Matrix4 deltaZR = Matrix4.identity()
        ..translate(pivotWorld.dx, pivotWorld.dy)
        ..rotateZ(d.dTheta)
        ..scale(math.exp(dLogApplied))
        ..translate(-pivotWorld.dx, -pivotWorld.dy);
      M = deltaZR..multiply(M);
    }
    if (d.pan != Offset.zero) {
      M = _applyPanMatrix(M, panPx: d.pan);
    }
    ps.mNew = M;
    // Proper bounds leash: ensure viewport world-AABB stays within _worldBounds
    if (_worldBounds != null) {
      final stor = M.storage;
      final m00 = stor[0], m10 = stor[1];
      final tx = stor[12], ty = stor[13];
      final scNow = math.sqrt(m00 * m00 + m10 * m10);
      final rotNow = math.atan2(m10, m00);
      final cx = sizeNow.width / 2.0;
      final cy = sizeNow.height / 2.0;
      final panNow = Offset(tx - cx, ty - cy);
      // Compute world AABB of the 4 screen corners
      final tlW = screenToWorld(
        const Offset(0, 0),
        sizeNow,
        panNow,
        scNow,
        rotNow,
      );
      final trW = screenToWorld(
        Offset(sizeNow.width, 0),
        sizeNow,
        panNow,
        scNow,
        rotNow,
      );
      final brW = screenToWorld(
        Offset(sizeNow.width, sizeNow.height),
        sizeNow,
        panNow,
        scNow,
        rotNow,
      );
      final blW = screenToWorld(
        Offset(0, sizeNow.height),
        sizeNow,
        panNow,
        scNow,
        rotNow,
      );
      double minX = math.min(
        math.min(tlW.dx, trW.dx),
        math.min(brW.dx, blW.dx),
      );
      double maxX = math.max(
        math.max(tlW.dx, trW.dx),
        math.max(brW.dx, blW.dx),
      );
      double minY = math.min(
        math.min(tlW.dy, trW.dy),
        math.min(brW.dy, blW.dy),
      );
      double maxY = math.max(
        math.max(tlW.dy, trW.dy),
        math.max(brW.dy, blW.dy),
      );
      Rect viewAabbW = Rect.fromLTRB(minX, minY, maxX, maxY);
      final Rect wb = _worldBounds!;
      double dxW = 0.0, dyW = 0.0;
      // Horizontal correction
      if (viewAabbW.width <= wb.width) {
        if (viewAabbW.left < wb.left) dxW = wb.left - viewAabbW.left;
        if (viewAabbW.right > wb.right) dxW = wb.right - viewAabbW.right;
      } else {
        // If viewport wider than bounds, keep centers aligned
        dxW = wb.center.dx - viewAabbW.center.dx;
      }
      // Vertical correction
      if (viewAabbW.height <= wb.height) {
        if (viewAabbW.top < wb.top) dyW = wb.top - viewAabbW.top;
        if (viewAabbW.bottom > wb.bottom) dyW = wb.bottom - viewAabbW.bottom;
      } else {
        // If viewport taller than bounds, keep centers aligned
        dyW = wb.center.dy - viewAabbW.center.dy;
      }
      if (dxW != 0.0 || dyW != 0.0) {
        // Convert world correction to screen-space delta and pre-multiply
        final c = math.cos(rotNow);
        final s = math.sin(rotNow);
        final sx = (dxW * c - dyW * s) * scNow;
        final sy = (dxW * s + dyW * c) * scNow;
        M = (Matrix4.identity()..translate(sx, sy))..multiply(M);
        if (!_leashedLastFrame) {
          debugPrint(
            '[LEASH] corrected world Δ=(${dxW.toStringAsFixed(2)},${dyW.toStringAsFixed(2)}) '
            'viewAABB=(${viewAabbW.left.toStringAsFixed(2)},${viewAabbW.top.toStringAsFixed(2)},'
            '${viewAabbW.right.toStringAsFixed(2)},${viewAabbW.bottom.toStringAsFixed(2)}) '
            'bounds=(${wb.left.toStringAsFixed(2)},${wb.top.toStringAsFixed(2)},${wb.right.toStringAsFixed(2)},${wb.bottom.toStringAsFixed(2)})',
          );
        }
        _leashedLastFrame = true;
      } else {
        _leashedLastFrame = false;
      }
    }
    setState(() {
      _view = M;
      _decomposeView(sizeNow);
    });
    ref
        .read(mapViewController)
        .update(pan: _pan, scale: _scale, rotation: _rotation);
    final stor = M.storage;
    final tx = stor[12];
    final ty = stor[13];
    debugPrint(
      '[APPLY] mode=${ps.deprecatedModeSnapshot} panPx=(${d.pan.dx.toStringAsFixed(1)},${d.pan.dy.toStringAsFixed(1)}) dS=${d.dLog.toStringAsFixed(3)} dθ=${d.dTheta.toStringAsFixed(3)} → tx=${tx.toStringAsFixed(1)} ty=${ty.toStringAsFixed(1)} scale=${ps.totalScale.toStringAsFixed(2)} rot=${ps.totalRotDeg.toStringAsFixed(1)}°',
    );
    // Gesture stability heuristic temporarily disabled due to helper removal.
    // if (!_gestureStable &&
    //     _isGestureStable(ps.deprecatedModeSnapshot, ps.dLogLP, ps.dThetaLP)) {
    //   _gestureStable = true;
    // }
  }

  // ==== GestureStateMachine: frame adapters ====
  // Convert authoritative ParState snapshot + our pipeline deltas into
  // the state machine's GateDecision and Estimates structures.
  sm.GateDecision _smGateFromPar(ParState ps, {required bool veto}) {
    // Map ParState.mode string to an intent for gate decision
    final String m = ps.deprecatedModeSnapshot;
    final bool zr = (m == 'zr' || m == 'mixed');
    final intent = zr
        ? (ps.zoomReady
              ? sm.Intent.zoom
              : (ps.rotateReady ? sm.Intent.rotate : sm.Intent.pan))
        : (m == 'zoom'
              ? sm.Intent.zoom
              : m == 'rotate'
              ? sm.Intent.rotate
              : sm.Intent.pan);
    // We prioritize rotate when both true only if mode says so; bias can be tuned later
    final gd = sm.decideFromPargate(
      m,
      ps.zoomReady,
      ps.rotateReady,
      zoomBias: 1.1,
    );
    // Preserve ready flags from ParState but use chosen intent from helper
    return sm.GateDecision(gd.intent, ps.zoomReady, ps.rotateReady);
  }

  sm.Estimates _smEstimatesFromPipeline({
    required double dTheta,
    required double dLogSep,
    required Offset dPan,
    double? rotE,
    double? zoomE,
  }) {
    return sm.Estimates(
      dTheta: dTheta,
      dLogSep: dLogSep,
      dPan: dPan,
      rotE: rotE,
      zoomE: zoomE,
    );
  }

  // Lifecycle observer (ensure only one set of overrides)
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // BM-200R2.2: ensure legacy XFORM engine disabled.
    bm200rUseOldXform = false;
    // Early fit attempt so initial pan/zoom clamp has bounds before first gesture.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _worldBounds == null) {
        final box = context.findRenderObject() as RenderBox?;
        final size = box?.size ?? Size.zero;
        if (size != Size.zero) {
          final prop = ref.read(activePropertyProvider).asData?.value;
          final proj = ProjectionService(
            prop?.originLat ?? prop?.lat ?? 0,
            prop?.originLon ?? prop?.lon ?? 0,
          );
          _fitOnce(size, proj);
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animCtrl?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setFreeze(FreezeCause.lifecycle, const Duration(milliseconds: 60));
    } else if (state == AppLifecycleState.paused) {
      _setFreeze(FreezeCause.lifecycle, const Duration(milliseconds: 60));
    }
  }
  // ===============================================================================

  @override
  Widget build(BuildContext context) {
    final prop = ref.watch(activePropertyProvider).asData?.value;
    final gps = ref.watch(gpsStreamProvider);
    final heading = ref.watch(compassStreamProvider);

    final borderGroupsVal =
        ref.watch(borderGroupsProvider).value ?? const <PointGroup>[];
    final partitionGroupsVal =
        ref.watch(partitionGroupsProvider).value ?? const <PointGroup>[];
    final borderPtsMap = ref.watch(
      pointsByGroupsReadyProvider(borderGroupsVal),
    );
    final partitionPtsMap = ref.watch(
      pointsByGroupsReadyProvider(partitionGroupsVal),
    );

    final proj = ProjectionService(
      prop?.originLat ?? prop?.lat ?? 0,
      prop?.originLon ?? prop?.lon ?? 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(prop?.name ?? 'Map'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'gps') {
                final messenger = ScaffoldMessenger.maybeOf(context);
                messenger?.showSnackBar(
                  const SnackBar(content: Text('GPS split – coming soon')),
                );
              } else if (value == 'farm') {
                // Navigate to the MatrixGestureDetector sample view to capture [BM-200B] logs
                if (mounted) {
                  Navigator.of(context).pushNamed('/dev/farm');
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'gps', child: Text('Split via GPS')),
              PopupMenuItem(value: 'farm', child: Text('Open Farm demo')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Pointer listener (restores lost structure after zoom button insertion)
          Listener(
            onPointerDown: (e) {
              _activePointers[e.pointer] = e.localPosition;
              if (kUseSimGesture) {
                if (_activePointers.length == 1) {
                  _lastSinglePanPos = e.localPosition;
                }
                if (_activePointers.length == 2) {
                  final ids = _activePointers.keys.toList()..sort();
                  _sim.start(
                    _activePointers[ids[0]]!,
                    _activePointers[ids[1]]!,
                  );
                  _lastSinglePanPos = null;
                }
              }
              // Legacy two-finger bind logic (preserved)
              final twoNow = _activePointers.length >= 2;
              if (twoNow && !_twoDown) {
                _gid++;
                ensureParState(_gid);
                _emaZoomReady = false;
                _emaRotateReady = false;
                _seq = 0;
                _panQ.clear();
                final ids = _activePointers.keys.toList()..sort();
                final p1s = _activePointers[ids[0]]!;
                final p2s = _activePointers[ids[1]]!;
                final nowMs = DateTime.now().millisecondsSinceEpoch;
                _sampler9f.beginGesture(
                  pointerId1: ids[0],
                  pointerId2: ids[1],
                  p1: p1s,
                  p2: p2s,
                  nowMs: nowMs,
                );
                _tp.begin(id1: ids[0], id2: ids[1], p1: p1s, p2: p2s);
                final ParState psBind = ensureParState(_gid);
                _par9e.beginGesture(gestureId: _gid, ps: psBind);
                _parFeedLogCount = 0;
                debugPrint(
                  '[G0 BIND] gid=${_gid} twoDown=2 ids=[${ids[0]},${ids[1]}]',
                );
                final overrideVal =
                    (_par9e.forceAlwaysTrue
                            ? true
                            : (_par9e.forceAlwaysFalse ? false : null))
                        ?.toString() ??
                    'NA';
                debugPrint(
                  '[BM-200B.9h HANDOFF] gid=${_gid} instance=${identityHashCode(_par9e)} override=${overrideVal}',
                );
                _twoDown = true;
                _sm.onTwoDownChange();
                _setFreeze(
                  FreezeCause.twoDownChange,
                  const Duration(milliseconds: 30),
                );
                final cpxSeed = (p1s + p2s) * 0.5;
                _prevCpx = cpxSeed;
                _panPxLP = Offset.zero;
                _freezePrev = true;
                _twoBelowSinceMs = -1;
                psBind.minScale = 0.75;
                if (_activePointers.length >= 2) {
                  final ids2 = _activePointers.keys.toList()..sort();
                  final cPx =
                      (_activePointers[ids2[0]]! + _activePointers[ids2[1]]!) *
                      0.5;
                  final sizeNow = _lastPaintSize;
                  if (sizeNow != Size.zero) {
                    _pivotWAnchor = screenToWorld(
                      cPx,
                      sizeNow,
                      _pan,
                      _scale,
                      _rotation,
                    );
                  }
                }
              } else if (twoNow && _twoDown && _twoBelowSinceMs >= 0) {
                _twoBelowSinceMs = -1;
                debugPrint('[G0 BIND] gid=$_gid dropout canceled (rejoined)');
              }
            },
            onPointerMove: (e) {
              _activePointers[e.pointer] = e.localPosition;
              if (kUseSimGesture && _activePointers.length == 2) {
                final ids = _activePointers.keys.toList()..sort();
                final p1 = _activePointers[ids[0]]!;
                final p2 = _activePointers[ids[1]]!;
                final u = _sim.update(p1, p2);
                debugPrint('[SIM] update ' + u.toString());
                _applySimGesture(u);
                // Conditional rotation (future). Criteria: scaleFactor ~= 1 AND |dθ| > threshold AND feature flag true.
                if (kEnableSimRotateLater && u.rotationDelta != 0.0) {
                  final bool zoomTiny = (u.scaleFactor - 1.0).abs() < 0.0005;
                  final bool angleBig =
                      u.rotationDelta.abs() > 0.0025; // ~0.14°
                  if (zoomTiny && angleBig) {
                    // Rotation by gesture intentionally disabled.
                  }
                }
                if (mounted) setState(() {}); // repaint if anything changed
                return; // bypass legacy pipeline
              }
              if (kUseSimGesture && _activePointers.length == 1) {
                // Single-finger path is reserved for taps/selection only.
                // Do not mutate transform here.
                return;
              }
              // Feed the two-finger sampler with raw pointer moves for coalescing
              if (_sampler9f.id1 != null && _sampler9f.id2 != null) {
                _sampler9f.onPointerMove(e.pointer, e.localPosition);
                // Defer compute to onScaleUpdate to keep a single source/order per frame
              }
            },
            onPointerUp: (e) {
              _activePointers.remove(e.pointer);
              if (kUseSimGesture &&
                  _activePointers.length < 2 &&
                  _sim.isActive) {
                _sim.end();
              }
              if (kUseSimGesture && _activePointers.isEmpty) {
                _lastSinglePanPos = null;
              }
              if (_activePointers.length < 2) {
                // Start dropout grace timer; don't end gesture immediately
                if (_twoDown && _twoBelowSinceMs < 0) {
                  _twoBelowSinceMs = DateTime.now().millisecondsSinceEpoch;
                  debugPrint(
                    '[G0 BIND] gid=$_gid two<2 → start dropout grace ${_twoDropoutGraceMs}ms',
                  );
                }
              }
            },
            onPointerCancel: (e) {
              _activePointers.remove(e.pointer);
              if (kUseSimGesture &&
                  _activePointers.length < 2 &&
                  _sim.isActive) {
                _sim.end();
              }
              if (kUseSimGesture && _activePointers.isEmpty) {
                _lastSinglePanPos = null;
              }
              if (_activePointers.length < 2) {
                // Start dropout grace timer; don't end gesture immediately
                if (_twoDown && _twoBelowSinceMs < 0) {
                  _twoBelowSinceMs = DateTime.now().millisecondsSinceEpoch;
                  debugPrint(
                    '[G0 BIND] gid=$_gid two<2 → start dropout grace ${_twoDropoutGraceMs}ms',
                  );
                }
              }
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (d) {
                // Under simplified sim path, mark gesturing and skip legacy init.
                if (kUseSimGesture) {
                  _isGesturing = true;
                  return;
                }
                _isGesturing = true;
                // Clear sticky anchors at gesture start
                _rotateAnchorWorld = null;
                _zoomAnchorWorld = null;
                _gestureStable = false; // reset stability each gesture
                // Reset two-finger centroid smoother
                _cFilt = null;
                _cLast = null;
                // Reset rotation/zoom readiness gate
                _rdyConsec = 0;
                _rotZoomReady = false;
                // Clear BM-198 diagnostic anchor and window
                _bm198AnchorWorld = null;
                _bm198AnchorScreen0 = null;
                _bm198RotDrifts.clear();
                // Reset ZR latch
                _zrLatch.reset();
                // Cancel any running programmatic animation
                if (_animCtrl != null) {
                  _animCtrl!.stop();
                  _animCtrl!.dispose();
                  _animCtrl = null;
                }
                _startScale = _scale;
                _startRotation = _rotation;
                // baselines not needed for BM-195
                _twoMode = TwoFingerMode.undecided;
                _lastFocal = d.localFocalPoint;
                // BM-195 initialize session (do not bump gid here; bind on twoDown)
                _switches = 0;
                final now = DateTime.now();
                _lockTime = now;
                _lastEvidenceTime = now;
                _lastSwitchTime = now;
                _prevRawScale = 1.0; // baseline
                // _prevRawAngle = 0.0; // baseline
                // _prevFocal removed
                // no prev separation stored
                _eScale = 0.0;
                _eAngle = 0.0;
                _peakScaleDelta = 0.0;
                _peakAngle = 0.0;
                _cumAngleTotal = 0.0;
                _sAngle = 0.0;
                _sScale = 0.0;
                // BM-199B.3: remember last veto state to log flips
                _bm199PrevVeto = null;
                // BM-199B.4: gesture-long pointer pair lock and veto averaging buffer
                _pairLocked = false;
                _pairId1 = null;
                _pairId2 = null;
                _vetoBuf.clear();
                _rigidPostLockFrames = 0;
                _rigidCfgLogged = false;
                // reset previous pointer snapshot
                _prevP1 = null;
                _prevP2 = null;
                _prevSep = null;
                // _prevPairAngle = null;
                // Reset BM-200B.8 veto state
                // latch resets via _tPrevMs
                _p1PrevForPar = Offset.zero;
                _p2PrevForPar = Offset.zero;
                _tPrevMs = -1;
                _currentParVeto = false;
                // Reset 9h entry guard state
                _par9ePrevVeto = false;
                // IDs and PAR binding will occur on twoDown in the raw pointer listener
                // Init BM-199: DPR-aware minSep
                // BM-199B.2: Use fixed logical minSep for gating (48 px per tunables)
                final double minSep = 48.0;
                _bm199Gate = BM199Gate(
                  BM199Params(
                    rotHysRad: 0.10, // per BM-199
                    zoomHys: kZoomHys,
                    minSepPx: minSep,
                    windowMs: 350,
                    cooldownMs: kCooldownMs,
                  ),
                );
                _bm199Gate!.reset();
                _bm199PairIds = null;
                // Initialize engine with a synthetic pair if available
                if (_activePointers.length >= 2) {
                  final ids = _activePointers.keys.toList()..sort();
                  final p1 = _activePointers[ids[0]]!;
                  final p2 = _activePointers[ids[1]]!;
                  _bmEngine.onPointerPairStart(
                    p1,
                    p2,
                    DateTime.now().millisecondsSinceEpoch,
                  );
                  // Keep engine's transform in sync initially
                  _bmEngine.M = Matrix4.copy(_view);
                }
                debugPrint(
                  '$_tag GESTURE start gid=${_gid} count=${d.pointerCount} '
                  'scale=$_startScale rot=${_startRotation.toStringAsFixed(3)}',
                );
              },
              onScaleUpdate: (d) {
                // When using the simplified gesture path, all two-finger logic
                // (pan/zoom[/rotate]) is applied in raw pointer handlers.
                // We skip legacy SM/PARGATE processing to avoid double-apply.
                if (kUseSimGesture) {
                  return;
                }
                if (_animCtrl != null) return; // ignore during animation
                // H) Skip frames if no active pointers
                if (_activePointers.isEmpty || d.pointerCount == 0) {
                  return;
                }
                // Handle dropout grace expiration here as well
                if (_twoDown &&
                    _activePointers.length < 2 &&
                    _twoBelowSinceMs >= 0) {
                  final nowMsChk = DateTime.now().millisecondsSinceEpoch;
                  if (nowMsChk - _twoBelowSinceMs >= _twoDropoutGraceMs) {
                    // Hygiene debounce: end gesture only if both pointers are up
                    if (_activePointers.isEmpty) {
                      _par9e.endGesture();
                      _sampler9f.endGesture();
                      _tp.end();
                      _twoDown = false;
                      // Notify SM about losing two-down to reset timers
                      _sm.onTwoDownChange();
                      _twoBelowSinceMs = -1;
                      debugPrint(
                        '[G0 BIND] gid=${_gid} release due to dropout (both up)',
                      );
                    } else {
                      // Still at least one finger down: keep waiting; don't flip twoDown
                      _twoBelowSinceMs = nowMsChk; // extend window
                      debugPrint(
                        '[G0 BIND] gid=${_gid} hygiene debounce: still down=${_activePointers.length}, extend grace',
                      );
                    }
                  }
                }
                // Reset pending pan accumulator for this frame
                _pendingPanDp = Offset.zero;
                // BM-194 capture previous state for per-frame logging
                final prevPanBM194 = _pan;
                final prevScaleBM194 = _scale;
                var size = _lastPaintSize;
                if (size == Size.zero) {
                  final box = context.findRenderObject() as RenderBox?;
                  size = box?.size ?? size;
                }
                // DPI-aware minSep threshold (removed unused bmMinSepPx/frameGid after refactor)
                // final double bmMinSepPx = _minSepForDpi(MediaQuery.of(context).devicePixelRatio);
                if (d.pointerCount < 2) {
                  // 1-finger pan by focal delta (update pan directly)
                  // Reset two-finger centroid smoothing when dropping below two fingers
                  _cFilt = null;
                  _cLast = null;
                  _prevCpx = null; // reset two-finger centroid seed
                  // Reset readiness when not in two-finger state
                  _rdyConsec = 0;
                  _rotZoomReady = false;
                  final dp =
                      (d.localFocalPoint - _lastFocal) * Tunables.panGain;
                  // Producer: publish dp later via single ENQ site (no early apply)
                  _pendingPanDp += dp;
                  _lastFocal = d.localFocalPoint;
                  // BM-194 per-frame state log for 1-finger pan
                  if (kBM194Enable && kBM194StateLogs) {
                    final now = DateTime.now();
                    double fps = 0;
                    if (_bm194LastFrameTs != null) {
                      final dt =
                          now.difference(_bm194LastFrameTs!).inMicroseconds /
                          1e6;
                      if (dt > 0) fps = 1 / dt;
                    }
                    _bm194LastFrameTs = now;
                    final dPan = _pan - prevPanBM194;
                    debugPrint(
                      '[BM-194 S] gid=$_gid mode=${_modeTitle(_twoMode)} '
                      'scale=${_scale.toStringAsFixed(2)} rot=${_rotation.toStringAsFixed(3)} '
                      'pan=(${_pan.dx.toStringAsFixed(1)},${_pan.dy.toStringAsFixed(1)})',
                    );
                    debugPrint(
                      '  dScale=${_sgn(0.0, frac: 3)} (from ${prevScaleBM194.toStringAsFixed(3)}) '
                      'dAngle=${_sgn(0.0, frac: 3)} rad dPan=(${_sgn(dPan.dx)},${_sgn(dPan.dy)})',
                    );
                    debugPrint(
                      '  sep=0px focal=(${d.localFocalPoint.dx.toStringAsFixed(0)},${d.localFocalPoint.dy.toStringAsFixed(0)}) fps=${fps.toStringAsFixed(0)}',
                    );
                  }
                } else {
                  // ================= BM-195 core logic =================
                  // Raw (relative to gesture start)
                  // rawScale/rawAngle/focal locals removed; unified ParState handles deltas
                  // Centroid/rigid-fit diagnostics
                  // (legacy parallel-like metrics removed)
                  // True separation from two raw pointers (screen space), pair locking across gesture
                  // sep local removed; sampler/par state supplies separation
                  int? pid1;
                  int? pid2;
                  Offset? p1;
                  Offset? p2;
                  final activeCount = _activePointers.length;
                  // Monotonic timestamp for this frame (prefer scheduler's frame clock)
                  final Duration frameTsAll =
                      SchedulerBinding.instance.currentSystemFrameTimeStamp;
                  final int nowMsAll = frameTsAll.inMicroseconds > 0
                      ? frameTsAll.inMilliseconds
                      : DateTime.now().millisecondsSinceEpoch;
                  // Reset per-frame ordering guard at the start of two-finger processing
                  _par9eDidComputeThisFrame = false;
                  // Reset pre-veto shield flag; will be recomputed after 9h state is updated
                  _par9eShieldActive = false;
                  if (!_pairLocked && activeCount == 2) {
                    // Canonicalize finger identity once per gesture: A=lowest ID, B=other
                    final keys = _activePointers.keys.toList()..sort();
                    _pairId1 = keys[0]; // A
                    _pairId2 = keys[1]; // B
                    _pairLocked = true;
                    // BM-199 PAIR: log lock
                    debugPrint(
                      '[BM-199 PAIR] gid=${_gid} id1=#${_pairId1} id2=#${_pairId2} locked=true',
                    );
                    // ID lock log (once per gesture)
                    debugPrint(
                      '[BM-199 IDLOCK] gid=${_gid} begin: A=#${_pairId1} B=#${_pairId2}',
                    );
                    if (!_rigidCfgLogged) {
                      debugPrint(
                        '[BM-199 RIGID CFG] method=centroided Sx/Sy; residualFracMax=${(_bm199Gate?.p.residualFracMax ?? 0.12).toStringAsFixed(3)} '
                        'dThetaClamp=${(_bm199Gate?.p.dThetaClamp ?? 0.12).toStringAsFixed(3)} minRotAbs=${(_bm199Gate?.p.minRotAbs ?? 0.35).toStringAsFixed(2)}',
                      );
                      _rigidCfgLogged = true;
                    }
                  } else if (activeCount < 2) {
                    // BM-199 PAIR: log unlock (if previously locked)
                    if (_pairLocked) {
                      debugPrint(
                        '[BM-199 PAIR] gid=${_gid} id1=#${_pairId1} id2=#${_pairId2} locked=false',
                      );
                    }
                    _pairLocked = false;
                    _pairId1 = null;
                    _pairId2 = null;
                  }
                  // BM-199 PAIR: warn if framework's current two-key order differs from locked order
                  if (_pairLocked &&
                      activeCount == 2 &&
                      _pairId1 != null &&
                      _pairId2 != null) {
                    final keysNow = _activePointers.keys.toList();
                    if (keysNow.length >= 2 &&
                        (keysNow[0] != _pairId1 || keysNow[1] != _pairId2)) {
                      debugPrint(
                        '[BM-199 PAIR] WARNING frameworkOrder=#${keysNow[0]},#${keysNow[1]} lockedOrder=#${_pairId1},#${_pairId2}',
                      );
                      // Explicit ID swap warning — mapping remains locked, swap ignored
                      debugPrint(
                        '[BM-199 IDSWAP] attempt ignored: incoming=(#${keysNow[0]},#${keysNow[1]}) '
                        'locked=(A=#${_pairId1},B=#${_pairId2})',
                      );
                    }
                  }
                  if (_pairLocked &&
                      _pairId1 != null &&
                      _pairId2 != null &&
                      _activePointers.containsKey(_pairId1) &&
                      _activePointers.containsKey(_pairId2)) {
                    pid1 = _pairId1;
                    pid2 = _pairId2;
                    p1 = _activePointers[pid1]!;
                    p2 = _activePointers[pid2]!;
                    // separation handled via sampler; local sep removed
                    // BM-200B.9f: emit coalesced two-finger sample and update 9e veto
                    final sample = _sampler9f.tryEmit(nowMsAll);
                    if (_twoDown && sample != null) {
                      // Provide viewport min before updating PAR (for absolute sep normalization)
                      final double vmin = math.max(
                        1.0,
                        math.min(size.width, size.height),
                      );
                      _par9e.setViewportMin(vmin);
                      // Ordered pipeline: PAR_FEED -> PARGATE -> APPLY_ZR -> VETO
                      final ParState _psFrame = ensureParState(_gid);
                      final result = _par9e.stepWithSample(
                        ps: _psFrame,
                        p1_prev: sample.p1Prev,
                        p2_prev: sample.p2Prev,
                        p1_now: sample.p1Now,
                        p2_now: sample.p2Now,
                        twoDown: _twoDown,
                      );
                      // Capture centroid prev/now + raw deltas for APPLY stage
                      _parCentroidPrev = Offset(
                        (sample.p1Prev.dx + sample.p2Prev.dx) * 0.5,
                        (sample.p1Prev.dy + sample.p2Prev.dy) * 0.5,
                      );
                      _parCentroidNow = Offset(
                        (sample.p1Now.dx + sample.p2Now.dx) * 0.5,
                        (sample.p1Now.dy + sample.p2Now.dy) * 0.5,
                      );
                      if (_parCentroidNow != null) {
                        // Two-finger pan delta pipeline (locked path)
                        final bool freezeNow = _freezeActive;
                        if (_freezePrev && !freezeNow) {
                          _prevCpx ??= _parCentroidNow; // ensure no large jump
                          _freezePrev = false;
                        }
                        // Raw delta (screen pixels)
                        Offset panPxRaw = Offset.zero;
                        if (_prevCpx != null) {
                          panPxRaw = _parCentroidNow! - _prevCpx!;
                        }
                        _prevCpx = _parCentroidNow;
                        // Low-pass
                        const double panAlpha = 0.25;
                        _panPxLP = Offset(
                          _panPxLP.dx * (1 - panAlpha) + panPxRaw.dx * panAlpha,
                          _panPxLP.dy * (1 - panAlpha) + panPxRaw.dy * panAlpha,
                        );
                        // Small deadzone
                        const double panEpsPx = 0.10;
                        final Offset panPxUse = _panPxLP.distance < panEpsPx
                            ? Offset.zero
                            : _panPxLP;
                        // Always publish to SM; it will apply only in Mode.pan
                        _pendingPanDp += panPxUse;
                        debugPrint(
                          '[PAN] raw=' +
                              panPxRaw.dx.toStringAsFixed(2) +
                              ',' +
                              panPxRaw.dy.toStringAsFixed(2) +
                              ' lp=' +
                              _panPxLP.dx.toStringAsFixed(2) +
                              ',' +
                              _panPxLP.dy.toStringAsFixed(2) +
                              ' use=' +
                              panPxUse.dx.toStringAsFixed(2) +
                              ',' +
                              panPxUse.dy.toStringAsFixed(2) +
                              ' freeze=' +
                              freezeNow.toString(),
                        );
                        // Build gate decision from authoritative ParState
                        // _updateGateReadinessAndMode(_psFrame, _psFrame.ema.sepNow, kParMinSepPx); // helper removed
                        // Build gate decision from authoritative ParState
                        final gate = GateDecision(
                          mode: _psFrame.deprecatedModeSnapshot,
                          veto: result.veto,
                          zoomReady: _psFrame.zoomReady,
                          rotateReady: _psFrame.rotateReady,
                          dLogLP: _psFrame.dLogLP,
                          dThetaLP: _psFrame.dThetaLP,
                          centroidW: screenToWorld(
                            _parCentroidNow!,
                            size,
                            _pan,
                            _scale,
                            _rotation,
                          ),
                        );
                        // Feed SM heartbeat right after gate+estimate are known
                        final _smGate = _smGateFromPar(
                          _psFrame,
                          veto: result.veto,
                        );
                        final _smEst = _smEstimatesFromPipeline(
                          dTheta: _psFrame.dThetaLP,
                          dLogSep: _psFrame.dLogLP,
                          dPan: _pendingPanDp,
                        );
                        _sm.onFrame(_smEst, _smGate, veto: result.veto);
                        // Probe: expected vs rendered after SM apply
                        assert(() {
                          debugPrint(
                            '[SM] view-sync expected rot=' +
                                (_sm.debugTotalRotRad?.toStringAsFixed(3) ??
                                    'NA') +
                                ' scale=' +
                                ((_sm.debugTotalScale)?.toStringAsFixed(3) ??
                                    'NA') +
                                ' → rendered rot=' +
                                _xform.rotRad.toStringAsFixed(3) +
                                ' scale=' +
                                _xform.scale.toStringAsFixed(3),
                          );
                          return true;
                        }());
                        assert(() {
                          if (_psFrame.rotateReady || _psFrame.zoomReady) {
                            debugPrint(
                              '[SM] heartbeat mode=' +
                                  _sm.mode.toString() +
                                  ' rotReady=' +
                                  _psFrame.rotateReady.toString() +
                                  ' zoomReady=' +
                                  _psFrame.zoomReady.toString(),
                            );
                          }
                          return true;
                        }());
                        // Always emit BM-199 telemetry even during freeze
                        final nowMs = DateTime.now().millisecondsSinceEpoch;
                        final _ = _bm199Gate?.telemetry(
                          gate,
                          freeze: _freezeActive,
                          nowMs: nowMs,
                        );
                        // Sanity asserts
                        assert(
                          !(gate.mode == 'pan' &&
                              (_psFrame.dLogLP.abs() > 0.02 ||
                                  _psFrame.dThetaLP.abs() > 0.05)),
                          'Pan should not carry big zoom/rot deltas',
                        );
                        assert(
                          !_freezeActive || gate.veto,
                          'If FREEZE, we should be vetoing Apply',
                        );
                        // Only mutate state when not frozen and not vetoed
                        if (!_freezeActive && !gate.veto) {
                          final modeSnap = _psFrame.deprecatedModeSnapshot;
                          final dLogSnap = _psFrame.dLogLP;
                          final dThetaSnap = _psFrame.dThetaLP;
                          final panSnap = _pendingPanDp; // screen px
                          final pivotSnapW = screenToWorld(
                            _parCentroidNow!,
                            size,
                            _pan,
                            _scale,
                            _rotation,
                          );
                          final _ApplyDeltas deltas = _deltasFor(
                            modeSnap,
                            dLogSnap,
                            dThetaSnap,
                            panSnap,
                          );
                          _applyParGate(
                            ps: _psFrame,
                            pivotWorld: pivotSnapW,
                            deltas: deltas,
                          );
                        }
                      }
                      // deltas now read from ParState (psCurrent.dLogSep/dTheta)
                      _par9eState = result.state;
                      _par9eDidComputeThisFrame = true;
                      _currentParVeto = result.veto;
                      // Pre-veto shield: active while not latched and cos>=0.95 with validN<6 on a valid frame
                      _par9eShieldActive =
                          (_par9eState!.frameValid &&
                          !_currentParVeto &&
                          _par9eState!.validN < 6 &&
                          _par9eState!.cosParAvg >= 0.90);
                      // Capture invariants for this frame
                      _par9eLastGid = _par9eState!.gestureId;
                      _par9eLastSeq = _par9eState!.frameSeq;
                      _par9eLastVer = _par9eState!.stateVersion;
                      _par9eLastCos = _par9eState!.cosParAvg;
                      _par9eLastSep = _par9eState!.sepFracAvg;
                      // parVeto already reflected in _currentParVeto
                      // 9h rising edge → start guard window
                      if (!_par9ePrevVeto && _currentParVeto) {
                        // Legacy per-veto freeze removed; do not start freeze here
                      }
                      _par9ePrevVeto = _currentParVeto;
                      // Feed ZR latch from authoritative PAR state
                      if (_par9eState!.frameValid) {
                        _zrLatch.feed(
                          _par9eState!.cosParAvg,
                          _par9eState!.sepFracAvg,
                          alpha: 0.25,
                        );
                      }
                      // BM-199B.1 P1: log stable two-point kinematics using coalesced sample
                      if (_tp.active && pid1 == _tp.id1 && pid2 == _tp.id2) {
                        final st = _tp.update(
                          p1: sample.p1Now,
                          p2: sample.p2Now,
                        );
                        debugPrint(
                          '[BM-199B.1 P1] ids=(#${st.id1},#${st.id2}) '
                          'centroid=(${st.centroid.dx.toStringAsFixed(2)},${st.centroid.dy.toStringAsFixed(2)}) '
                          'sep=${st.sepPx.toStringAsFixed(2)} '
                          'heading=${st.headingRad.toStringAsFixed(3)} '
                          'd1=(${st.d1.dx.toStringAsFixed(2)},${st.d1.dy.toStringAsFixed(2)}) '
                          'd2=(${st.d2.dx.toStringAsFixed(2)},${st.d2.dy.toStringAsFixed(2)})',
                        );
                      }
                    }
                    // 9h is single source of truth; no legacy 8.x updates
                    // Compute per-frame guard state based on 9h entry time
                    // Removed legacy per-veto FREEZE suppression block
                    // Feed engine (non-authoritative in this stage)
                    _bmEngine.onPointerPairUpdate(p1, p2, nowMsAll);
                  } else if (activeCount >= 2) {
                    final ids = _activePointers.keys.toList()..sort();
                    pid1 = ids[0];
                    pid2 = ids[1];
                    p1 = _activePointers[pid1]!;
                    p2 = _activePointers[pid2]!;
                    // separation handled via sampler; local sep removed
                    // BM-200B.9f: emit coalesced two-finger sample and update 9e veto
                    final sample = _sampler9f.tryEmit(nowMsAll);
                    if (_twoDown && sample != null) {
                      // Provide viewport min before updating PAR (for absolute sep normalization)
                      final double vmin = math.max(
                        1.0,
                        math.min(size.width, size.height),
                      );
                      _par9e.setViewportMin(vmin);
                      // Ordered pipeline: PAR_FEED -> PARGATE -> APPLY_ZR -> VETO
                      final ParState _psFrame2 = ensureParState(_gid);
                      final result = _par9e.stepWithSample(
                        ps: _psFrame2,
                        p1_prev: sample.p1Prev,
                        p2_prev: sample.p2Prev,
                        p1_now: sample.p1Now,
                        p2_now: sample.p2Now,
                        twoDown: _twoDown,
                      );
                      // Capture centroid prev/now + raw deltas for APPLY stage (unlocked path)
                      _parCentroidPrev = Offset(
                        (sample.p1Prev.dx + sample.p2Prev.dx) * 0.5,
                        (sample.p1Prev.dy + sample.p2Prev.dy) * 0.5,
                      );
                      _parCentroidNow = Offset(
                        (sample.p1Now.dx + sample.p2Now.dx) * 0.5,
                        (sample.p1Now.dy + sample.p2Now.dy) * 0.5,
                      );
                      if (_parCentroidNow != null) {
                        // --- Two-finger pan delta pipeline (locked path) ---
                        final int nowMs = DateTime.now().millisecondsSinceEpoch;
                        final bool freezeNow = _freezeActive;
                        // On freeze end, guard-seed prev centroid if missing
                        if (_freezePrev && !freezeNow) {
                          _prevCpx ??= _parCentroidNow; // ensure no large jump
                          _freezePrev = false;
                        }
                        // Raw delta (screen pixels)
                        Offset panPxRaw = Offset.zero;
                        if (_prevCpx != null) {
                          panPxRaw = _parCentroidNow! - _prevCpx!;
                        }
                        _prevCpx = _parCentroidNow;
                        // Low-pass to avoid annihilating small motion
                        const double panAlpha = 0.25; // LP gain
                        _panPxLP = Offset(
                          _panPxLP.dx * (1 - panAlpha) + panPxRaw.dx * panAlpha,
                          _panPxLP.dy * (1 - panAlpha) + panPxRaw.dy * panAlpha,
                        );
                        // Deadzone tiny jitter AFTER LP
                        const double panEpsPx = 0.10;
                        final Offset panPxUse = _panPxLP.distance < panEpsPx
                            ? Offset.zero
                            : _panPxLP;
                        // Always publish to SM; it will apply only in Mode.pan
                        _pendingPanDp += panPxUse; // accumulate this frame
                        debugPrint(
                          '[PAN] raw=' +
                              panPxRaw.dx.toStringAsFixed(2) +
                              ',' +
                              panPxRaw.dy.toStringAsFixed(2) +
                              ' lp=' +
                              _panPxLP.dx.toStringAsFixed(2) +
                              ',' +
                              _panPxLP.dy.toStringAsFixed(2) +
                              ' use=' +
                              panPxUse.dx.toStringAsFixed(2) +
                              ',' +
                              panPxUse.dy.toStringAsFixed(2) +
                              ' freeze=' +
                              freezeNow.toString(),
                        );
                        // Update readiness & mode before decision (unlocked path)
                        // _updateGateReadinessAndMode(_psFrame2, _psFrame2.ema.sepNow, kParMinSepPx); // helper removed
                        final gate = GateDecision(
                          mode: _psFrame2.deprecatedModeSnapshot,
                          veto: result.veto,
                          zoomReady: _psFrame2.zoomReady,
                          rotateReady: _psFrame2.rotateReady,
                          dLogLP: _psFrame2.dLogLP,
                          dThetaLP: _psFrame2.dThetaLP,
                          centroidW: screenToWorld(
                            _parCentroidNow!,
                            size,
                            _pan,
                            _scale,
                            _rotation,
                          ),
                        );
                        // SM heartbeat in unlocked path as well
                        final _smGate2 = _smGateFromPar(
                          _psFrame2,
                          veto: result.veto,
                        );
                        final _smEst2 = _smEstimatesFromPipeline(
                          dTheta: _psFrame2.dThetaLP,
                          dLogSep: _psFrame2.dLogLP,
                          dPan: _pendingPanDp,
                        );
                        _sm.onFrame(_smEst2, _smGate2, veto: result.veto);
                        assert(() {
                          debugPrint(
                            '[SM] view-sync expected rot=' +
                                (_sm.debugTotalRotRad?.toStringAsFixed(3) ??
                                    'NA') +
                                ' scale=' +
                                ((_sm.debugTotalScale)?.toStringAsFixed(3) ??
                                    'NA') +
                                ' → rendered rot=' +
                                _xform.rotRad.toStringAsFixed(3) +
                                ' scale=' +
                                _xform.scale.toStringAsFixed(3),
                          );
                          return true;
                        }());
                        assert(() {
                          if (_psFrame2.rotateReady || _psFrame2.zoomReady) {
                            debugPrint(
                              '[SM] heartbeat mode=' +
                                  _sm.mode.toString() +
                                  ' rotReady=' +
                                  _psFrame2.rotateReady.toString() +
                                  ' zoomReady=' +
                                  _psFrame2.zoomReady.toString(),
                            );
                          }
                          return true;
                        }());
                        final nowMs2 = DateTime.now().millisecondsSinceEpoch;
                        final _ = _bm199Gate?.telemetry(
                          gate,
                          freeze: _freezeActive,
                          nowMs: nowMs2,
                        );
                        // Sanity asserts
                        assert(
                          !(gate.mode == 'pan' &&
                              (_psFrame2.dLogLP.abs() > 0.02 ||
                                  _psFrame2.dThetaLP.abs() > 0.05)),
                          'Pan should not carry big zoom/rot deltas',
                        );
                        assert(
                          !_freezeActive || gate.veto,
                          'If FREEZE, we should be vetoing Apply',
                        );
                        if (!_freezeActive && !gate.veto) {
                          final modeSnap = _psFrame2.deprecatedModeSnapshot;
                          final dLogSnap = _psFrame2.dLogLP;
                          final dThetaSnap = _psFrame2.dThetaLP;
                          final panSnap = _pendingPanDp; // screen px
                          final pivotSnapW = screenToWorld(
                            _parCentroidNow!,
                            size,
                            _pan,
                            _scale,
                            _rotation,
                          );
                          final _ApplyDeltas deltas = _deltasFor(
                            modeSnap,
                            dLogSnap,
                            dThetaSnap,
                            panSnap,
                          );
                          _applyParGate(
                            ps: _psFrame2,
                            pivotWorld: pivotSnapW,
                            deltas: deltas,
                          );
                        }
                      }
                      // deltas now read from ParState (psCurrent.dLogSep/dTheta)
                      _par9eState = result.state;
                      _par9eDidComputeThisFrame = true;
                      _currentParVeto = result.veto;
                      // Pre-veto shield for unlocked pair path
                      _par9eShieldActive =
                          (_par9eState!.frameValid &&
                          !_currentParVeto &&
                          _par9eState!.validN < 6 &&
                          _par9eState!.cosParAvg >= 0.90);
                      // Capture invariants for this frame
                      _par9eLastGid = _par9eState!.gestureId;
                      _par9eLastSeq = _par9eState!.frameSeq;
                      _par9eLastVer = _par9eState!.stateVersion;
                      _par9eLastCos = _par9eState!.cosParAvg;
                      _par9eLastSep = _par9eState!.sepFracAvg;
                      // parVeto already reflected in _currentParVeto
                      // 9h rising edge → start guard window
                      if (!_par9ePrevVeto && _currentParVeto) {
                        // Legacy per-veto freeze removed
                      }
                      _par9ePrevVeto = _currentParVeto;
                      // Feed ZR latch from authoritative PAR state
                      if (_par9eState!.frameValid) {
                        _zrLatch.feed(
                          _par9eState!.cosParAvg,
                          _par9eState!.sepFracAvg,
                          alpha: 0.25,
                        );
                      }
                      // BM-199B.1 P1: log two-point kinematics (unlocked case)
                      if (_tp.active && pid1 == _tp.id1 && pid2 == _tp.id2) {
                        final st = _tp.update(
                          p1: sample.p1Now,
                          p2: sample.p2Now,
                        );
                        debugPrint(
                          '[BM-199B.1 P1] ids=(#${st.id1},#${st.id2}) '
                          'centroid=(${st.centroid.dx.toStringAsFixed(2)},${st.centroid.dy.toStringAsFixed(2)}) '
                          'sep=${st.sepPx.toStringAsFixed(2)} '
                          'heading=${st.headingRad.toStringAsFixed(3)} '
                          'd1=(${st.d1.dx.toStringAsFixed(2)},${st.d1.dy.toStringAsFixed(2)}) '
                          'd2=(${st.d2.dx.toStringAsFixed(2)},${st.d2.dy.toStringAsFixed(2)})',
                        );
                      }
                    }
                    // 9h is single source of truth; no legacy 8.x updates
                    // Compute per-frame guard state based on 9h entry time
                    // Removed legacy per-veto FREEZE suppression block
                    // Feed engine (non-authoritative in this stage)
                    _bmEngine.onPointerPairUpdate(p1, p2, nowMsAll);
                  }
                }
                setState(() {
                  _didFit = true;
                });
                ref
                    .read(mapViewController)
                    .update(pan: _pan, scale: _scale, rotation: _rotation);
              },
              onScaleEnd: (_) {
                if (kUseSimGesture) {
                  _isGesturing = false;
                  return;
                }
                _isGesturing = false;
                // Clear anchors on gesture end
                // Reset rotate pacing timestamp (monotonic)
                _lastRotateMs = null;
                _rotateAnchorWorld = null;
                // Reset BM-200B.7 gate dwell trackers
                _bm200bGateOnSinceMs = -1;
                _bm200bGateRotate = null;
                _zoomAnchorWorld = null;
                // Clear BM-198 diagnostic
                _bm198AnchorWorld = null;
                _bm198AnchorScreen0 = null;
                _bm198RotDrifts.clear();
                // Reset pair-locked ids
                _pairLocked = false;
                _pairId1 = null;
                _pairId2 = null;
                // BM-195 end log before resetting mode
                final now = DateTime.now();
                final dwell = now.difference(_lockTime).inMilliseconds;
                if (kBM194Enable && kBM194EventLogs) {
                  final fromTitle = _modeTitle(_twoMode);
                  final enterStr = _lockTime.toIso8601String();
                  final exitStr = now.toIso8601String();
                  debugPrint(
                    '[BM-194 E] gid=$_gid $fromTitle→end enter=$enterStr exit=$exitStr dwell=${dwell}ms',
                  );
                  // Reset BM-200B.7 gate dwell trackers
                  _bm200bGateOnSinceMs = -1;
                  _bm200bGateRotate = null;
                  // Reset rotate pacing timestamp (monotonic)
                  _lastRotateMs = null;
                  debugPrint(
                    '  peakAngle=${_peakAngle.toStringAsFixed(3)}rad peakScaleΔ=${_peakScaleDelta.toStringAsFixed(3)} reason="gesture end"',
                  );
                }
                debugPrint(
                  '[BM-195 E] gid=$_gid ${_twoMode.name}→end exit=${now.toIso8601String()} '
                  'dwell=${dwell}ms peakAngle=${_peakAngle.toStringAsFixed(3)}rad '
                  'peakScaleΔ=${_peakScaleDelta.toStringAsFixed(3)} reason="gesture end"',
                );
                _twoMode = TwoFingerMode.undecided;
                // clear previous pointer snapshot
                _prevP1 = null;
                _prevP2 = null;
                _prevSep = null;
                // End BM-199B.1 partition
                _tp.end();
                // _prevPairAngle = null;
                _bm199Gate?.reset();
                _bm199Gate = null;
                _bm199PairIds = null;
                // Reset BM-200B.8 veto state
                // latch resets via _tPrevMs
                _p1PrevForPar = Offset.zero;
                _p2PrevForPar = Offset.zero;
                _tPrevMs = -1;
                _currentParVeto = false;
                _par9e.endGesture();
                _sampler9f.endGesture();
                // Reset PAR centroid apply buffers
                // reset (no-op)
                _parCentroidPrev = null;
                _parCentroidNow = null;
                // deltas maintained in ParState; no local reset needed
                // BM-199 removed per request
                debugPrint(
                  '$_tag GESTURE end rot=${_rotation.toStringAsFixed(3)} '
                  'scale=${_scale.toStringAsFixed(2)} pan=(${_pan.dx.toStringAsFixed(1)},${_pan.dy.toStringAsFixed(1)})',
                );
              },
              // TEMP: disable view-specific gestures during A/B (double-tap zoom)
              // Re-enable after validation pass by restoring this handler.
              // onDoubleTapDown: (details) {
              //   final fp = details.localPosition;
              //   _startZoomAnim(fp, Tunables.tapZoomFactor);
              //   if (Tunables.tapResetMode) {
              //     _twoMode = TwoFingerMode.undecided;
              //   }
              // },
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  _lastPaintSize = size;
                  // Keep a copy on the transform model for any helpers that consult it
                  _xform.viewportSize = size;
                  if (!_isGesturing) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _fitOnce(size, proj);
                    });
                  }
                  return CustomPaint(
                    key: ValueKey(
                      '${_xform.rotRad.toStringAsFixed(3)}:${_xform.scale.toStringAsFixed(2)}:${_xform.tx.toStringAsFixed(1)}:${_xform.ty.toStringAsFixed(1)}',
                    ),
                    painter: MapPainter(
                      projection: proj,
                      xform:
                          _xform, // SM-owned transform: single source of truth
                      borderGroups: borderGroupsVal,
                      partitionGroups: partitionGroupsVal,
                      borderPointsByGroup: borderPtsMap,
                      partitionPointsByGroup: partitionPtsMap,
                      ref: ref,
                      gps: gps.value,
                      splitRingAWorld: _previewRingA,
                      splitRingBWorld: _previewRingB,
                    ),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),
          if (_debugCutLine != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CutPainter(_debugCutLine!, _xform),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          if (_splitMode)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _isGesturing,
                child: TwoTapPicker(
                  onDone: (aScreen, bScreen) async {
                    // Convert screen taps to world-space using the current transform
                    final size = _lastPaintSize;
                    final aWorld = screenToWorld(
                      aScreen,
                      size,
                      _pan,
                      _scale,
                      _rotation,
                    );
                    final bWorld = screenToWorld(
                      bScreen,
                      size,
                      _pan,
                      _scale,
                      _rotation,
                    );
                    setState(() => _debugCutLine = CutLine(aWorld, bWorld));
                    await _runSplitWithWorldPoints(aWorld, bWorld, proj);
                    if (mounted) setState(() => _splitMode = false);
                  },
                ),
              ),
            ),
          // Always-on partitions overlay (pastel fill + outline)
          if (prop != null)
            Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Use the single-source SM transform for overlays
                    final matrix = Matrix4.identity()
                      ..translate(_xform.tx, _xform.ty)
                      ..rotateZ(_xform.rotRad)
                      ..scale(_xform.scale);
                    return Transform(
                      transform: matrix,
                      alignment: Alignment.topLeft,
                      child: Stack(
                        children: [
                          PartitionOverlay(
                            propertyId: prop.id,
                            project: (lat, lon) => proj.project(lat, lon),
                            worldBounds: Rect.largest,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          Positioned(
            right: 12,
            top: 12,
            child: IgnorePointer(
              ignoring: _isGesturing,
              child: Transform.rotate(
                angle: (heading.value ?? 0) * 3.1415926535 / 180.0,
                child: const Icon(
                  Icons.navigation,
                  size: 28,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          if (prop != null)
            Positioned(
              left: 12,
              top: 12,
              child: Chip(label: Text('Property ${prop.name}')),
            ),
          // Zoom buttons (explicit controls)
          Positioned(
            right: 12,
            bottom: 96,
            child: IgnorePointer(
              ignoring: _isGesturing,
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'rot_left_5',
                        onPressed: () {
                          final size = _lastPaintSize;
                          final center = size.center(Offset.zero);
                          final pivotW = screenToWorldXform(center, _xform);
                          _xform.applyRotate(
                            -math.pi / 36.0,
                            pivotW: pivotW,
                            pivotS: center,
                          ); // -5°
                          if (_worldBounds != null) {
                            _xform.clampPan(
                              worldBounds: _worldBounds!,
                              view: size,
                            );
                          }
                          debugPrint(
                            '[BM-200R] button-rotate d=-5° => θ=${(_xform.rotRad * 180.0 / math.pi).toStringAsFixed(1)}°',
                          );
                          if (mounted) setState(() {});
                        },
                        child: const Icon(Icons.rotate_left),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton.small(
                        heroTag: 'rot_right_5',
                        onPressed: () {
                          final size = _lastPaintSize;
                          final center = size.center(Offset.zero);
                          final pivotW = screenToWorldXform(center, _xform);
                          _xform.applyRotate(
                            math.pi / 36.0,
                            pivotW: pivotW,
                            pivotS: center,
                          ); // +5°
                          if (_worldBounds != null) {
                            _xform.clampPan(
                              worldBounds: _worldBounds!,
                              view: size,
                            );
                          }
                          debugPrint(
                            '[BM-200R] button-rotate d=+5° => θ=${(_xform.rotRad * 180.0 / math.pi).toStringAsFixed(1)}°',
                          );
                          if (mounted) setState(() {});
                        },
                        child: const Icon(Icons.rotate_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    onPressed: () {
                      // Center-stable zoom: keep current screen center mapped to same world point
                      final size = _lastPaintSize;
                      final center = size.center(Offset.zero);
                      final pivotS = center;
                      final pivotW = screenToWorldXform(pivotS, _xform);
                      final dLog = math.log(1.2);
                      _xform.applyZoom(dLog, pivotW: pivotW, pivotS: pivotS);
                      if (_worldBounds != null) {
                        _xform.clampPan(worldBounds: _worldBounds!, view: size);
                      }
                      if (mounted) setState(() {});
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'home_fit',
                    onPressed: _homeView,
                    tooltip: 'Fit farm',
                    child: const Icon(Icons.home),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    onPressed: () {
                      // Center-stable zoom: keep current screen center mapped to same world point
                      final size = _lastPaintSize;
                      final center = size.center(Offset.zero);
                      final pivotS = center;
                      final pivotW = screenToWorldXform(pivotS, _xform);
                      final dLog = math.log(1 / 1.2);
                      _xform.applyZoom(dLog, pivotW: pivotW, pivotS: pivotS);
                      if (_worldBounds != null) {
                        _xform.clampPan(worldBounds: _worldBounds!, view: size);
                      }
                      if (mounted) setState(() {});
                    },
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ),
          // Legend toggle button (dev placement; move to your filters later)
          Positioned(
            right: 12,
            top: 56,
            child: IgnorePointer(
              ignoring: _isGesturing,
              child: Consumer(
                builder: (_, ref, __) => IconButton.filledTonal(
                  icon: Icon(
                    ref.watch(globalFilterProvider).legendVisible
                        ? Icons.legend_toggle
                        : Icons.legend_toggle_outlined,
                  ),
                  onPressed: () {
                    final s = ref.read(globalFilterProvider);
                    ref.read(globalFilterProvider.notifier).state = s.copyWith(
                      legendVisible: !s.legendVisible,
                    );
                  },
                  tooltip: 'Toggle legend',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startZoomAnim(Offset fp, double factor) {
    // Cancel any existing animation
    _animCtrl?.stop();
    _animCtrl?.dispose();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final curve = CurvedAnimation(parent: _animCtrl!, curve: Curves.easeOut);
    // No legacy matrix path; animate xform directly
    void apply(double t) {
      final f = 1.0 + (factor - 1.0) * t;
      final dLog = (f > 0) ? math.log(f) : 0.0;
      final pivotS = fp;
      final pivotW = screenToWorldXform(pivotS, _xform);
      _xform.applyZoom(dLog, pivotW: pivotW, pivotS: pivotS);
      if (mounted) setState(() {});
    }

    apply(0.0);
    curve.addListener(() => apply(curve.value));
    curve.addStatusListener((st) {
      if (st == AnimationStatus.completed || st == AnimationStatus.dismissed) {
        _animCtrl?.dispose();
        _animCtrl = null;
      }
    });
    _animCtrl!.forward();
  }

  // (dispose override already declared above)

  // Finite matrix guard: ensure all entries finite and determinant not near zero
  // Removed legacy _matrixFinite/_isViewFarOffscreen/_clampPan helpers (unused)

  Future<void> _runSplitWithWorldPoints(
    Offset aWorld,
    Offset bWorld,
    ProjectionService proj,
  ) async {
    debugPrint('$_tag SPLIT origin lat0/lon0 = ${proj.lat0}, ${proj.lon0}');
    // Target: first border group for now
    final borderGroupsVal =
        ref.read(borderGroupsProvider).value ?? const <PointGroup>[];
    if (borderGroupsVal.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No border ring')));
      return;
    }
    final g = borderGroupsVal.first;
    final pts = ref.read(pointsByGroupProvider(g.id)).asData?.value ?? const [];
    if (pts.length < 3) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Border ring incomplete')));
      return;
    }
    debugPrint(
      'CUT ring points=${pts.length} first=${pts.first.lat},${pts.first.lon}',
    );
    final ringWorld = pts.map((p) => proj.project(p.lat, p.lon)).toList();
    // World-space snapping (meters)
    const double tolMeters = 8.0; // snapping tolerance in meters
    const double tVertexEps = 0.02;

    (int, double, Offset)? snapPointWorld(Offset q, List<Offset> ring) {
      int? bestEdge;
      double bestT = 0.0;
      Offset? bestP;
      double bestD = double.infinity;
      for (int i = 0; i < ring.length; i++) {
        final a = ring[i];
        final b = ring[(i + 1) % ring.length];
        final ab = b - a;
        final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
        double t = len2 == 0
            ? 0.0
            : (((q - a).dx * ab.dx + (q - a).dy * ab.dy) / len2).clamp(
                0.0,
                1.0,
              );
        final p = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
        final d = (q - p).distance;
        if (d < bestD) {
          bestD = d;
          bestEdge = i;
          bestT = t.toDouble();
          bestP = p;
        }
      }
      return (bestD <= tolMeters && bestEdge != null && bestP != null)
          ? (bestEdge, bestT, bestP)
          : null;
    }

    final sA = snapPointWorld(aWorld, ringWorld);
    final sB = snapPointWorld(bWorld, ringWorld);
    if (sA == null || sB == null) {
      if (!mounted) return;
      setState(() {
        _debugCutLine = null;
        _previewRingA = null;
        _previewRingB = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cut point too far from border')),
      );
      return;
    }

    // Vertex normalization
    int n = ringWorld.length;
    int? aVertexIdx;
    int? bVertexIdx;
    if (sA.$2 <= tVertexEps) aVertexIdx = sA.$1;
    if (sA.$2 >= 1.0 - tVertexEps) aVertexIdx = (sA.$1 + 1) % n;
    if (sB.$2 <= tVertexEps) bVertexIdx = sB.$1;
    if (sB.$2 >= 1.0 - tVertexEps) bVertexIdx = (sB.$1 + 1) % n;
    if (aVertexIdx != null && bVertexIdx != null && aVertexIdx == bVertexIdx) {
      if (!mounted) return;
      setState(() {
        _debugCutLine = null;
        _previewRingA = null;
        _previewRingB = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cut points snapped to same vertex')),
      );
      return;
    }

    // Convert snapped screen results back to world via segment interpolation (affine-safe)
    Offset useA = () {
      final aW = ringWorld[sA.$1];
      final bW = ringWorld[(sA.$1 + 1) % n];
      return Offset(
        aW.dx + (bW.dx - aW.dx) * sA.$2,
        aW.dy + (bW.dy - aW.dy) * sA.$2,
      );
    }();
    Offset useB = () {
      final aW = ringWorld[sB.$1];
      final bW = ringWorld[(sB.$1 + 1) % n];
      return Offset(
        aW.dx + (bW.dx - aW.dx) * sB.$2,
        aW.dy + (bW.dy - aW.dy) * sB.$2,
      );
    }();

    // Helper: project a world point onto a specific edge index in world meters
    (int, double, Offset) projectOntoEdgeIndexWorld(
      Offset q,
      List<Offset> ring,
      int idx,
    ) {
      final a = ring[idx];
      final b = ring[(idx + 1) % ring.length];
      final ab = b - a;
      final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
      double t = len2 == 0
          ? 0.0
          : (((q - a).dx * ab.dx + (q - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
      final p = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
      return (idx, t.toDouble(), p);
    }

    // Relaxed same-edge rule using world distance and param separation, with hysteresis near vertices
    if (sA.$1 == sB.$1) {
      const double minMeters = 1.5; // allow close but not too close
      const double minDt = 0.03; // 3% of edge length
      final dt = (sA.$2 - sB.$2).abs();
      final dWorld = (useA - useB).distance;
      bool tooClose = dt < minDt || dWorld < minMeters;
      if (tooClose) {
        // Hysteresis: if near a vertex, prefer adjacent edge in the direction of P1->P2
        const double nearVertexMeters = 3.0;
        final i = sA.$1;
        final va = ringWorld[i];
        final vb = ringWorld[(i + 1) % n];
        final da = (useB - va).distance;
        final db = (useB - vb).distance;
        if (da <= nearVertexMeters || db <= nearVertexMeters) {
          final preferPrev = da < db; // closer to start vertex => previous edge
          final candEdge = preferPrev ? ((i - 1 + n) % n) : ((i + 1) % n);
          final sB2 = projectOntoEdgeIndexWorld(bWorld, ringWorld, candEdge);
          // recompute world for the candidate
          final aW2 = ringWorld[sB2.$1];
          final bW2 = ringWorld[(sB2.$1 + 1) % n];
          final useB2 = Offset(
            aW2.dx + (bW2.dx - aW2.dx) * sB2.$2,
            aW2.dy + (bW2.dy - aW2.dy) * sB2.$2,
          );
          final dt2 = (sA.$2 - sB2.$2).abs();
          final dWorld2 = (useA - useB2).distance;
          final ok = (sA.$1 != sB2.$1) && !(dt2 < minDt || dWorld2 < minMeters);
          if (ok) {
            // adopt candidate
            useB = useB2;
            // We won't use sB again; downstream uses useB/world values.
          }
          tooClose =
              (sA.$1 == candEdge) && (dt2 < minDt || dWorld2 < minMeters);
        }
      }
      if (tooClose) {
        if (!mounted) return;
        setState(() {
          _debugCutLine = null;
          _previewRingA = null;
          _previewRingB = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cut points too close on same edge')),
        );
        return;
      }
    }
    debugPrint(
      '$_tag SNAP A seg=${sA.$1} t=${sA.$2.toStringAsFixed(3)} B seg=${sB.$1} t=${sB.$2.toStringAsFixed(3)}',
    );

    // Metric epsilon based on border ring bounds (0.01% of longest side)
    double metricEps(List<Offset> ring) {
      if (ring.isEmpty) return 1e-6;
      double minX = ring.first.dx, maxX = ring.first.dx;
      double minY = ring.first.dy, maxY = ring.first.dy;
      for (final p in ring) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
      final w = (maxX - minX).abs();
      final h = (maxY - minY).abs();
      final longest = w > h ? w : h;
      return longest * 1e-4;
    }

    final eps = metricEps(ringWorld);

    // Extend and intersect as segment for robust two crossings
    Offset normalize(Offset v) {
      final len = v.distance;
      return (len == 0) ? const Offset(0, 0) : Offset(v.dx / len, v.dy / len);
    }

    final dirSeg = normalize(useB - useA);
    const double extend = 3.0; // meters
    final q1 = useA - dirSeg * extend;
    final q2 = useB + dirSeg * extend;
    var inters = _segmentIntersectionsWithRing(
      ringWorld,
      q1,
      q2,
      dedupTol: eps,
    );
    if (inters.length != 2) {
      // Nudge off vertex tangency by a tiny perpendicular
      final perp = Offset(-dirSeg.dy, dirSeg.dx) * 1e-3;
      inters = _segmentIntersectionsWithRing(
        ringWorld,
        q1 + perp,
        q2 + perp,
        dedupTol: eps,
      );
    }
    if (inters.length != 2) {
      if (!mounted) return;
      setState(() {
        _debugCutLine = null;
        _previewRingA = null;
        _previewRingB = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cut did not intersect polygon exactly twice'),
        ),
      );
      return;
    }
    if ((inters[0] - inters[1]).distance < eps) {
      if (!mounted) return;
      setState(() {
        _debugCutLine = null;
        _previewRingA = null;
        _previewRingB = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cut intersections too close together')),
      );
      return;
    }

    // Proceed with snapped/validated world points
    final ctrl = SplitPartitionController()
      ..active = true
      ..p1World = useA
      ..p2World = useB;
    final created = await ctrl.trySplit(
      targetRingWorld: ringWorld,
      proj: proj,
      onPreview: (aW, bW) {
        if (!mounted) return;
        setState(() {
          _previewRingA = aW;
          _previewRingB = bW;
        });
      },
      persist: _persistRings,
    );
    debugPrint('CUT persist created=$created');
    if (!mounted) return;
    if (created == 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partition split into 2 rings')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cut did not produce two areas')),
      );
    }
    setState(() {
      _debugCutLine = null;
      _previewRingA = null;
      _previewRingB = null;
    });
  }

  // Old snapping helpers removed; we now snap in screen space above

  // Compute intersections of a finite segment p1->p2 with polygon edges.
  // Returns deduplicated intersection points using dedupTol (meters).
  List<Offset> _segmentIntersectionsWithRing(
    List<Offset> ring,
    Offset p1,
    Offset p2, {
    double dedupTol = 0.5,
  }) {
    if (ring.length < 2) return const [];
    final r = p2 - p1;
    if (r.distance == 0) return const [];

    double cross(Offset u, Offset v) => u.dx * v.dy - u.dy * v.dx;

    final List<Offset> hits = [];
    for (int i = 0; i < ring.length; i++) {
      final a = ring[i];
      final b = ring[(i + 1) % ring.length];
      final s = b - a;
      final denom = cross(r, s);
      if (denom == 0) {
        // Parallel (or colinear). If colinear, we could have infinite overlaps; ignore
        // here and rely on a tiny perpendicular nudge by caller when needed.
        continue;
      }
      final qp = a - p1;
      final t = cross(qp, s) / denom; // along p1->p2
      final u = cross(qp, r) / denom; // along a->b
      if (t < 0 || t > 1 || u < 0 || u > 1) {
        continue; // strictly within both segments
      }
      final ip = Offset(p1.dx + r.dx * t, p1.dy + r.dy * t);
      // Deduplicate near-equal intersections, including vertex double-hits.
      bool duplicate = false;
      for (final h in hits) {
        if ((h - ip).distance <= dedupTol) {
          duplicate = true;
          break;
        }
      }
      if (!duplicate) hits.add(ip);
    }
    return hits;
  }

  Future<int> _persistRings(
    List<(double lat, double lon)> ringA,
    List<(double lat, double lon)> ringB,
  ) async {
    final isar = await IsarService.open();
    final prop = ref.read(activePropertyProvider).asData!.value!;
    final ops = PartitionOps(isar);
    final idA = await ops.createPartitionGroup(
      propertyId: prop.id,
      name: 'P-${DateTime.now().millisecondsSinceEpoch % 1000}',
      colorHex: '#A3D5FF',
    );
    final idB = await ops.createPartitionGroup(
      propertyId: prop.id,
      name: 'P-${(DateTime.now().millisecondsSinceEpoch + 1) % 1000}',
      colorHex: '#C7F5C9',
    );
    await ops.replaceRing(groupId: idA, ring: ringA);
    await ops.replaceRing(groupId: idB, ring: ringB);
    ref.invalidate(partitionGroupsProvider);
    ref.invalidate(pointsByGroupProvider(idA));
    ref.invalidate(pointsByGroupProvider(idB));
    return 2;
  }

  void _fitOnce(Size size, ProjectionService proj) {
    // Skip if already fit or user interacted
    if (_didFit) return;
    final bgAsync = ref.read(borderGroupsProvider);
    final groups = bgAsync.asData?.value ?? const [];
    if (groups.isEmpty) return;
    final allPts = <Offset>[];
    for (final g in groups) {
      final pts =
          ref.read(pointsByGroupProvider(g.id)).asData?.value ?? const [];
      for (final p in pts) {
        allPts.add(proj.project(p.lat, p.lon));
      }
    }
    if (allPts.isEmpty) return;
    double minX = allPts.first.dx, maxX = allPts.first.dx;
    double minY = allPts.first.dy, maxY = allPts.first.dy;
    for (final o in allPts) {
      if (o.dx < minX) minX = o.dx;
      if (o.dx > maxX) maxX = o.dx;
      if (o.dy < minY) minY = o.dy;
      if (o.dy > maxY) maxY = o.dy;
    }
    final w = (maxX - minX).abs();
    final h = (maxY - minY).abs();
    if (w <= 0 || h <= 0) return;
    final bounds = Rect.fromLTWH(minX, minY, w, h);
    _worldBounds = bounds;
    _xform.homeTo(worldBounds: bounds, view: size, margin: 0.06);
    // Removed legacy sanity rotate (was introducing large world translations when scale high).
    final vc = size.center(Offset.zero);
    // Diagnostics: round-trip error and world bounds coverage
    logRoundTrip(vc, _xform);
    logWorldAabbOnScreen(bounds, _xform);

    setState(() {
      _didFit = true;
      _pivotWAnchor = bounds.center;
    });
  }
}

class _CutPainter extends CustomPainter {
  _CutPainter(this.line, this.xform);
  final CutLine line;
  final TransformModel xform;

  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(xform.tx, xform.ty);
    c.rotate(xform.rotRad);
    c.scale(xform.scale);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 / xform.scale
      ..color = const Color(0xFFEF6C00);
    c.drawLine(line.a, line.b, p);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _CutPainter old) =>
      old.line != line ||
      old.xform.tx != xform.tx ||
      old.xform.ty != xform.ty ||
      old.xform.scale != xform.scale ||
      old.xform.rotRad != xform.rotRad;
}
