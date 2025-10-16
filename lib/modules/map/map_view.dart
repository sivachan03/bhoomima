import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import '../points/two_tap_picker.dart';
import '../partition/split_partition_controller.dart';
import '../../core/repos/partition_ops.dart';
import '../../core/db/isar_service.dart';

// ========================= Tunables (BM-194/195) =========================
// Central place for all gesture & logging tuning knobs. Screenshot/share this
// block during tuning. Each var includes purpose and start values.
class Tunables {
  // Hysteresis for scale win (smaller = more eager to zoom)
  static const double zoomHys =
      0.020; // retune: slightly higher so Rotate can win when intentional

  // Hysteresis for angle win (radians). 0.10 ≈ 5.7°
  static const double rotHysRad =
      0.10; // keep ~6.9° threshold; ensures deliberate rotate

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

  BM199Params({
    this.rotHysRad = 0.10,
    this.zoomHys = 0.020,
    this.minSepPx = 64,
    this.windowMs = 350,
    this.cooldownMs = 240,
    this.vetoWindowMs = 120,
    this.kDominance = 1.30,
    this.panParallelCosMin = 0.95,
    this.maxSepFracChange = 0.010,
    this.residualFracMax = 0.08,
    this.mMin = 0.10,
    this.minRotAbs = 0.35,
    this.dThetaClamp = 0.12,
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

  BM199Gate(this.p) : _w = _BM199Window(p.windowMs);

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

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});
  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen>
    with SingleTickerProviderStateMixin {
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
  Size _lastPaintSize = Size.zero;
  double _startScale = 1.0;
  double _startRotation = 0.0;
  bool _didFit = false;

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
  DateTime? _lastRotateTs; // timestamp for rotate limiter

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
  // RIGID diagnostics: continue logging a few frames post-lock
  int _rigidPostLockFrames = 0;
  bool _rigidCfgLogged = false;
  // Previous raw values
  double _prevRawScale = 1.0;
  // double _prevRawAngle = 0.0; // no longer used; pointer-derived angle used instead
  Offset _prevFocal = Offset.zero;
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
  final Rect _contentBounds = const Rect.fromLTWH(-2000, -2000, 4000, 4000);

  // Split preview/debug
  List<Offset>? _previewRingA;
  List<Offset>? _previewRingB;
  (Offset, Offset)? _debugCutLine;
  bool _splitMode = false;
  // Track active pointer positions in local (screen) space
  final Map<int, Offset> _activePointers = <int, Offset>{};
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
  double _minSepForDpi(double dpr) {
    double px;
    if (dpr < 1.5) {
      px = 88; // ~90 px → 88 (11×8)
    } else if (dpr <= 2.0) {
      px = 96; // 90–100 → pick 96
    } else if (dpr <= 2.6) {
      px = 112; // 110 → 112 (14×8)
    } else if (dpr <= 3.2) {
      px = 128; // 125 → 128 (16×8)
    } else if (dpr <= 4.0) {
      px = 144; // 140 → 144 (18×8)
    } else {
      px = 160; // very dense fallback (20×8)
    }
    return px.toDouble();
  }

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

  void _composeView(Size size) {
    _view = Matrix4.identity()
      ..translate(size.width / 2 + _pan.dx, size.height / 2 + _pan.dy)
      ..rotateZ(_rotation)
      ..scale(_scale);
  }

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

  // Extract scale from a given Matrix4 (based on 2x2 submatrix)
  double _scaleFrom(Matrix4 m) {
    final s = m.storage;
    final m00 = s[0], m10 = s[1];
    return math.sqrt(m00 * m00 + m10 * m10);
  }

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
          Listener(
            onPointerDown: (e) {
              // Positions are in local coordinates of the Listener
              _activePointers[e.pointer] = e.localPosition;
            },
            onPointerMove: (e) {
              _activePointers[e.pointer] = e.localPosition;
            },
            onPointerUp: (e) {
              _activePointers.remove(e.pointer);
            },
            onPointerCancel: (e) {
              _activePointers.remove(e.pointer);
            },
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (d) {
                _isGesturing = true;
                // Clear sticky anchors at gesture start
                _rotateAnchorWorld = null;
                _zoomAnchorWorld = null;
                // Clear BM-198 diagnostic anchor and window
                _bm198AnchorWorld = null;
                _bm198AnchorScreen0 = null;
                _bm198RotDrifts.clear();
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
                // BM-195 initialize session
                _gid++;
                _switches = 0;
                final now = DateTime.now();
                _lockTime = now;
                _lastEvidenceTime = now;
                _lastSwitchTime = now;
                _prevRawScale = 1.0; // baseline
                // _prevRawAngle = 0.0; // baseline
                _prevFocal = d.localFocalPoint;
                // no prev separation stored
                _eScale = 0.0;
                _eAngle = 0.0;
                _peakScaleDelta = 0.0;
                _peakAngle = 0.0;
                _cumAngleTotal = 0.0;
                _sAngle = 0.0;
                _sScale = 0.0;
                _lastRotateTs = null;
                _bm194LastFrameTs = null;
                _bm199PrevVeto = null;
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
                // Init BM-199: DPR-aware minSep
                // BM-199B.2: Use fixed logical minSep for gating (64 px)
                final double minSep = 64.0;
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
                debugPrint(
                  '$_tag GESTURE start count=${d.pointerCount} '
                  'scale=$_startScale rot=${_startRotation.toStringAsFixed(3)}',
                );
              },
              onScaleUpdate: (d) {
                if (_animCtrl != null) return; // ignore during animation
                // BM-194 capture previous state for per-frame logging
                final prevPanBM194 = _pan;
                final prevScaleBM194 = _scale;
                var size = _lastPaintSize;
                if (size == Size.zero) {
                  final box = context.findRenderObject() as RenderBox?;
                  size = box?.size ?? size;
                }
                // DPI-aware minSep threshold (unused for gating; kept for logs)
                final double bmDpr = MediaQuery.of(context).devicePixelRatio;
                final double bmMinSepPx = _minSepForDpi(bmDpr);
                if (d.pointerCount < 2) {
                  // 1-finger pan by focal delta (update pan directly)
                  final dp =
                      (d.localFocalPoint - _lastFocal) * Tunables.panGain;
                  _pan = _pan + dp;
                  // Clamp and compose
                  _pan = Tunables.keepInBounds
                      ? _clampPan(_pan, _scale, _rotation, size)
                      : _pan;
                  _composeView(size);
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
                      '  sep=0px focal=(${d.localFocalPoint.dx.toStringAsFixed(0)},${d.localFocalPoint.dy.toStringAsFixed(0)}) '
                      'fps=${fps.toStringAsFixed(0)}',
                    );
                  }
                } else {
                  // ================= BM-195 core logic =================
                  // Raw (relative to gesture start)
                  final double rawScale = d.scale; // 1.0 at start
                  final double rawAngle = d.rotation; // 0.0 at start (radians)
                  final Offset focal = d.localFocalPoint;
                  // Centroid/rigid-fit diagnostics
                  // (legacy parallel-like metrics removed)
                  // True separation from two raw pointers (screen space), pair locking across gesture
                  double sep = 0.0;
                  int? pid1;
                  int? pid2;
                  Offset? p1;
                  Offset? p2;
                  final activeCount = _activePointers.length;
                  if (!_pairLocked && activeCount == 2) {
                    final keys = _activePointers.keys.toList();
                    _pairId1 = keys[0];
                    _pairId2 = keys[1];
                    _pairLocked = true;
                    // BM-199 PAIR: log lock
                    debugPrint(
                      '[BM-199 PAIR] id1=#${_pairId1} id2=#${_pairId2} locked=true',
                    );
                    if (!_rigidCfgLogged) {
                      debugPrint(
                        '[BM-199 RIGID CFG] method=centroided Sx/Sy; residualFracMax=${(_bm199Gate?.p.residualFracMax ?? 0.08).toStringAsFixed(3)} '
                        'dThetaClamp=${(_bm199Gate?.p.dThetaClamp ?? 0.12).toStringAsFixed(3)} minRotAbs=${(_bm199Gate?.p.minRotAbs ?? 0.35).toStringAsFixed(2)}',
                      );
                      _rigidCfgLogged = true;
                    }
                  } else if (activeCount < 2) {
                    // BM-199 PAIR: log unlock (if previously locked)
                    if (_pairLocked) {
                      debugPrint(
                        '[BM-199 PAIR] id1=#${_pairId1} id2=#${_pairId2} locked=false',
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
                    sep = (p1 - p2).distance;
                  } else if (activeCount >= 2) {
                    final ids = _activePointers.keys.toList()..sort();
                    pid1 = ids[0];
                    pid2 = ids[1];
                    p1 = _activePointers[pid1]!;
                    p2 = _activePointers[pid2]!;
                    sep = (p1 - p2).distance;
                  }
                  // Pointer-based per-frame angle and deltas for gating
                  // Rigid-fit rotation delta between previous and current pointer pairs
                  double dThetaRigid = 0.0;
                  // Keep normalized vector-based angle for diagnostics in later logs
                  double dAnglePtrRaw = 0.0;
                  //
                  double zoomEvidence = 0.0; // |log(sep2/sep1)|
                  // panEvidence magnitude available via meanD if needed for future diagnostics
                  double nonPan = 0.0; // |diffΔ|
                  // Centroid-residual instantaneous pan veto
                  double residualFracInst = 0.0;
                  bool panVeto = false;
                  // Rigid diagnostics holders (for logs outside the inner block)
                  double rigidSxLog = 0.0, rigidSyLog = 0.0;
                  double r1LenLog = 0.0, r2LenLog = 0.0;
                  bool rigidHave = false;
                  if (p1 != null &&
                      p2 != null &&
                      _prevP1 != null &&
                      _prevP2 != null) {
                    final vPrev = _prevP2! - _prevP1!;
                    final vNow = p2 - p1;
                    final double lenPrev = vPrev.distance;
                    final double lenNow = vNow.distance;
                    if (lenPrev > 0 && lenNow > 0) {
                      final vPrevN = Offset(
                        vPrev.dx / lenPrev,
                        vPrev.dy / lenPrev,
                      );
                      final vNowN = Offset(vNow.dx / lenNow, vNow.dy / lenNow);
                      final double dot =
                          vPrevN.dx * vNowN.dx + vPrevN.dy * vNowN.dy;
                      final double cross =
                          vPrevN.dx * vNowN.dy - vPrevN.dy * vNowN.dx;
                      // Keep normalized-angle calc for diagnostics, but use rigid-fit below for evidence
                      dAnglePtrRaw = math.atan2(cross, dot); // in (-pi, pi]
                      // already wrapped (not used further)
                      // BM-199B: verification of per-frame angle delta from raw (non-normalized) vectors
                      // This should match the normalized computation since atan2(cross, dot) is scale-invariant
                      if (_twoMode == TwoFingerMode.undecided) {
                        final double dotRaw =
                            vPrev.dx * vNow.dx + vPrev.dy * vNow.dy;
                        final double crossRaw =
                            vPrev.dx * vNow.dy - vPrev.dy * vNow.dx;
                        final double dThetaRawFromRaw = math.atan2(
                          crossRaw,
                          dotRaw,
                        );
                        debugPrint(
                          '[BM-199B θ] dotN=${dot.toStringAsFixed(6)} '
                          'crossN=${cross.toStringAsFixed(6)} dθN=${dAnglePtrRaw.toStringAsFixed(5)} '
                          'dot=${dotRaw.toStringAsFixed(1)} cross=${crossRaw.toStringAsFixed(1)} '
                          'dθ=${dThetaRawFromRaw.toStringAsFixed(5)} '
                          'diff=${(dThetaRawFromRaw - dAnglePtrRaw).abs().toStringAsFixed(6)}',
                        );
                      }
                      // Rigid-fit rotation using centroided coordinates across both pointers
                      final Offset a1 = _prevP1!;
                      final Offset a2 = _prevP2!;
                      final Offset b1 = p1;
                      final Offset b2 = p2;
                      final Offset aC = Offset(
                        (a1.dx + a2.dx) * 0.5,
                        (a1.dy + a2.dy) * 0.5,
                      );
                      final Offset bC = Offset(
                        (b1.dx + b2.dx) * 0.5,
                        (b1.dy + b2.dy) * 0.5,
                      );
                      final Offset a1c = a1 - aC, a2c = a2 - aC;
                      final Offset b1c = b1 - bC, b2c = b2 - bC;
                      final double Sx =
                          a1c.dx * b1c.dx +
                          a1c.dy * b1c.dy +
                          a2c.dx * b2c.dx +
                          a2c.dy * b2c.dy;
                      final double Sy =
                          a1c.dx * b1c.dy -
                          a1c.dy * b1c.dx +
                          a2c.dx * b2c.dy -
                          a2c.dy * b2c.dx;
                      dThetaRigid = math.atan2(Sy, Sx);
                      rigidSxLog = Sx;
                      rigidSyLog = Sy;

                      final double sepPrev = _prevSep ?? lenPrev;
                      final double sepNow = lenNow;
                      if (sepPrev > 0 && sepNow > 0) {
                        zoomEvidence = (math.log(sepNow / sepPrev)).abs();
                      }
                      final d1 = p1 - _prevP1!;
                      final d2 = p2 - _prevP2!;
                      // final meanD = Offset((d1.dx + d2.dx) / 2, (d1.dy + d2.dy) / 2);
                      final diffD = Offset(d1.dx - d2.dx, d1.dy - d2.dy);
                      // mean pan magnitude available if needed: meanD.distance
                      nonPan = diffD.distance;
                      // Centroid-residual pan veto (instantaneous)
                      final Offset dAvg = Offset(
                        (d1.dx + d2.dx) * 0.5,
                        (d1.dy + d2.dy) * 0.5,
                      );
                      final Offset r1 = d1 - dAvg;
                      final Offset r2 = d2 - dAvg;
                      final double r1Len = r1.distance;
                      final double r2Len = r2.distance;
                      r1LenLog = r1Len;
                      r2LenLog = r2Len;
                      final double sepSafe = math.max(sep, 48.0);
                      residualFracInst = (r1Len + r2Len) / sepSafe;
                      final double residualMax =
                          _bm199Gate?.p.residualFracMax ?? 0.08;
                      panVeto = residualFracInst <= residualMax;
                      rigidHave = true;

                      // BM-199B.4: legacy inputs for windowed parallel-pan veto (kept for possible future use)
                      final double mag1 = d1.distance;
                      final double mag2 = d2.distance;
                      final double den = (mag1 * mag2) + 1e-6;
                      final double cosParInst = (mag1 > 0 && mag2 > 0)
                          ? ((d1.dx * d2.dx + d1.dy * d2.dy) / den)
                          : 1.0; // treat zero move as parallel-ish
                      final double sepFracInst =
                          (_prevSep != null && _prevSep! > 0)
                          ? ((sep - _prevSep!).abs() / _prevSep!)
                          : 0.0;
                      final double mMin = _bm199Gate?.p.mMin ?? 0.10;
                      final bool enoughInst = (mag1 >= mMin && mag2 >= mMin);
                      // For legacy buffer metrics, reuse the instantaneous residual
                      // Add to veto buffer and prune by window
                      final Duration frameTsV =
                          SchedulerBinding.instance.currentSystemFrameTimeStamp;
                      final int nowMsV = frameTsV.inMicroseconds > 0
                          ? frameTsV.inMilliseconds
                          : DateTime.now().millisecondsSinceEpoch;
                      final int vetoWin = _bm199Gate?.p.vetoWindowMs ?? 120;
                      _vetoBuf.add(
                        _VetoSample(
                          nowMsV,
                          cosParInst,
                          sepFracInst,
                          residualFracInst,
                          enoughInst ? 1.0 : 0.0,
                        ),
                      );
                      final int cutoff = nowMsV - vetoWin;
                      while (_vetoBuf.isNotEmpty && _vetoBuf.first.t < cutoff) {
                        _vetoBuf.removeAt(0);
                      }
                      // legacy parallel-like metrics computed but not used
                      // residual average now stored in residFracAvgLast for logs
                    } else {
                      dAnglePtrRaw = 0.0;
                    }
                  }
                  // Diagnostics accumulators for this frame (no behavior change)
                  double diagPinErrPre = 0.0;
                  double diagPinErrPost = 0.0;
                  double diagClampDx = 0.0;
                  double diagClampDy = 0.0;
                  double diagPivotMismatchPx = 0.0;

                  // Incremental deltas vs previous raws (Flutter values)
                  final double dScaleInc =
                      (rawScale / _prevRawScale) - 1.0; // +0.01 = +1%
                  // final double dAngleIncRawFlutter = rawAngle - _prevRawAngle;
                  // Wrapped flutter angle inc (kept for potential diagnostics)
                  // final double _dAngleIncFlutter = _wrapPi(dAngleIncRawFlutter);
                  // Prefer rigid-fit wrapped angle for evidence and apply, with per-frame clamp
                  double dAngleInc = dThetaRigid;
                  final double clampTheta = _bm199Gate?.p.dThetaClamp ?? 0.12;
                  if (dAngleInc > clampTheta) dAngleInc = clampTheta;
                  if (dAngleInc < -clampTheta) dAngleInc = -clampTheta;
                  final Offset dp2 = focal - _prevFocal; // two-finger pan delta

                  // Evidence: no smoothing before lock; apply minSep gate and pan gate dominance
                  _eScale = dScaleInc.abs();
                  // BM-199B STEP1: force gate open (TEMP)
                  // Use logical pixels for sep; set a local logical threshold for guard logging only
                  final double sepPx =
                      sep; // Flutter touch coords are logical px
                  final double minSepPx =
                      64.0; // TEMP reference for guard log (logical)
                  final bool sepOk =
                      sepPx >= minSepPx; // gate forced open to prove lock works
                  if (sepPx < minSepPx) {
                    debugPrint(
                      '[BM-199 GATE] blocked=sep sep=${sepPx.toStringAsFixed(1)} minSepPx=${minSepPx.toStringAsFixed(0)} units=logical',
                    );
                  }
                  // With gate forced open, evidence is always the raw |dθ| per frame
                  double angleEvidence = dAngleInc.abs();
                  // Rotate dominance: rot > rotHys and rot > 2×max(zoomEvidence, nonPan/sep)
                  final double nonPanNorm = (sep > 0) ? (nonPan / sep) : nonPan;
                  final double competitor = math.max(zoomEvidence, nonPanNorm);
                  final bool rotDominates = angleEvidence > (2.0 * competitor);
                  _eAngle = angleEvidence;

                  // BM-197: Evidence logging while undecided
                  if (_twoMode == TwoFingerMode.undecided) {
                    // Per-undecided-frame rigid diagnostics
                    if (rigidHave) {
                      debugPrint(
                        '[BM-199 RIGID] Sx=${rigidSxLog.toStringAsFixed(4)} Sy=${rigidSyLog.toStringAsFixed(4)} '
                        'dθ=${dThetaRigid.toStringAsFixed(5)} |r1|=${r1LenLog.toStringAsFixed(3)} '
                        '|r2|=${r2LenLog.toStringAsFixed(3)} '
                        'residualFrac=${residualFracInst.toStringAsFixed(3)} panVeto=${(panVeto).toString()}',
                      );
                    }
                    final nowEv = DateTime.now();
                    final dwellElapsed = nowEv
                        .difference(_lastEvidenceTime)
                        .inMilliseconds;
                    debugPrint(
                      '[BM-197 S] rotEv=${angleEvidence.toStringAsFixed(4)} '
                      'zoomEv=${zoomEvidence.toStringAsFixed(4)} nonPan=${nonPan.toStringAsFixed(4)} '
                      'nonPanNorm=${(sep > 0 ? (nonPan / sep) : nonPan).toStringAsFixed(4)} '
                      'sep=${sep.toStringAsFixed(1)} sepOk=$sepOk',
                    );
                    final bool zoomDomCand =
                        _eScale > kZoomHys && _eScale > _eAngle && sepOk;
                    final bool rotDomCand =
                        angleEvidence > kRotHysRad && rotDominates && sepOk;
                    debugPrint(
                      '  thr rotHys=${kRotHysRad.toStringAsFixed(3)} zoomHys=${kZoomHys.toStringAsFixed(3)} '
                      'minSep=${bmMinSepPx.toStringAsFixed(0)} dwellMs=$kDwellMs dwellElapsed=${dwellElapsed}ms '
                      'cand zoomDom=$zoomDomCand rotDom=$rotDomCand',
                    );
                    if (angleEvidence > kRotHysRad && sepOk && !rotDominates) {
                      debugPrint(
                        '  [BM-197 B] rotate-blocked: dominance failed (competitor='
                        '${competitor.toStringAsFixed(4)})',
                      );
                    }
                    // BM-199 removed per request
                  }

                  // Peak tracking for exit logs
                  _peakScaleDelta = math.max(
                    _peakScaleDelta,
                    (rawScale - 1.0).abs(),
                  );
                  _cumAngleTotal += dAngleInc;
                  _peakAngle = math.max(_peakAngle, _cumAngleTotal.abs());

                  // Decide/maintain mode with dwell/cooldown and optional single switch
                  final now = DateTime.now();
                  final bool cooled =
                      now.difference(_lockTime).inMilliseconds >= kCooldownMs;
                  final bool seqCooled =
                      now.difference(_lastSwitchTime).inMilliseconds >=
                      kSeqCooldownMs;
                  var decided = _twoMode;
                  String? reason;

                  if (_twoMode == TwoFingerMode.undecided) {
                    // BM-199: maintain sliding accumulators and suggest lock; also disable 2-finger pan while undecided for Test B
                    if (_bm199Gate != null && pid1 != null && pid2 != null) {
                      final pair = (pid1, pid2);
                      if (_bm199PairIds == null || _bm199PairIds != pair) {
                        _bm199Gate!.reset();
                        _bm199PairIds = pair;
                      }
                      // Per-pointer deltas (screen px)
                      double dx1 = 0, dy1 = 0, dx2 = 0, dy2 = 0;
                      if (p1 != null && _prevP1 != null) {
                        final d1 = p1 - _prevP1!;
                        dx1 = d1.dx;
                        dy1 = d1.dy;
                      }
                      if (p2 != null && _prevP2 != null) {
                        final d2 = p2 - _prevP2!;
                        dx2 = d2.dx;
                        dy2 = d2.dy;
                      }
                      // Use monotonic frame timestamp for BM-199 (avoid wall-clock jumps)
                      final Duration frameTs =
                          SchedulerBinding.instance.currentSystemFrameTimeStamp;
                      final int nowMs = frameTs.inMicroseconds > 0
                          ? frameTs.inMilliseconds
                          : DateTime.now()
                                .millisecondsSinceEpoch; // fallback once
                      final lock = _bm199Gate!.update(
                        nowMs: nowMs,
                        sepPx: sep,
                        dThetaWrapped: dAngleInc,
                        dx1: dx1,
                        dy1: dy1,
                        dx2: dx2,
                        dy2: dy2,
                      );
                      // Per-frame BM-199 state log
                      // Compute normalized, capped nonPanEv for logging
                      double nonPanEvPrint = 0.0;
                      if (p1 != null &&
                          _prevP1 != null &&
                          p2 != null &&
                          _prevP2 != null) {
                        final Offset d1p = p1 - _prevP1!;
                        final Offset d2p = p2 - _prevP2!;
                        final double sepSafe = math.max(sep, 48.0);
                        nonPanEvPrint = (d1p - d2p).distance / sepSafe;
                        if (nonPanEvPrint > 0.06) nonPanEvPrint = 0.06;
                      }
                      debugPrint(
                        '[BM-199 S] rotEv=${dAngleInc.abs().toStringAsFixed(4)} '
                        'zoomEv=${zoomEvidence.toStringAsFixed(4)} '
                        'nonPan=${nonPanEvPrint.toStringAsFixed(4)} '
                        'rotAccum=${_bm199Gate!.rotAccum.toStringAsFixed(4)} '
                        'zoomAccum=${_bm199Gate!.zoomAccum.toStringAsFixed(4)} '
                        'nonPanAccum=${_bm199Gate!.nonPanAccum.toStringAsFixed(4)} '
                        'sep=${sep.toStringAsFixed(1)} sepOk=${(sep >= bmMinSepPx)} note=undecided',
                      );

                      // BM-199 D: dominance diagnostic (rotate comparator)
                      final double kDominanceCfg =
                          _bm199Gate?.p.kDominance ?? 1.30;
                      const double kNonPanW = 0.60;
                      final double rotA = _bm199Gate!.rotAccum;
                      final double zoomA = _bm199Gate!.zoomAccum;
                      final double nonPanA = _bm199Gate!.nonPanAccum;
                      final double comp = math.max(zoomA, nonPanA * kNonPanW);
                      final bool dominanceOK = rotA >= (kDominanceCfg * comp);
                      final bool absTwistOK = rotA >= (_bm199Gate!.p.minRotAbs);
                      final bool wantRotate = dominanceOK;
                      // Use centroid-residual instantaneous pan veto
                      final bool vetoActive = panVeto;
                      // Split into three lines with explicit prefixes so filters don't hide continuation lines
                      debugPrint(
                        '[BM-199 D1] rot=${rotA.toStringAsFixed(2)} zoom=${zoomA.toStringAsFixed(2)} '
                        'nonPan=${nonPanA.toStringAsFixed(2)} comp=${comp.toStringAsFixed(2)} '
                        'k=${kDominanceCfg.toStringAsFixed(2)}',
                      );
                      debugPrint(
                        '[BM-199 D2] residualFrac=${residualFracInst.toStringAsFixed(3)} '
                        'panVeto=${vetoActive.toString()} sep=${sep.toStringAsFixed(1)}',
                      );
                      debugPrint(
                        '[BM-199 D3] residualFracMax=${(_bm199Gate?.p.residualFracMax ?? 0.08).toStringAsFixed(3)} '
                        'absTwistOK=${absTwistOK.toString()} wantRotate=${wantRotate.toString()} veto=${vetoActive.toString()}',
                      );
                      if (_bm199PrevVeto == null ||
                          _bm199PrevVeto != vetoActive) {
                        debugPrint(
                          '[BM-199 VETO] panVeto=${vetoActive.toString()} '
                          'residualFrac=${residualFracInst.toStringAsFixed(3)} '
                          'threshold=${(_bm199Gate?.p.residualFracMax ?? 0.08).toStringAsFixed(3)}',
                        );
                        _bm199PrevVeto = vetoActive;
                      }

                      if ((lock == BM199Lock.rotate ||
                          lock == BM199Lock.zoom)) {
                        final nowIso = DateTime.now().toIso8601String();
                        final bool veto = vetoActive;
                        debugPrint(
                          '[BM-199 E] ${lock == BM199Lock.rotate ? '→Rotate' : '→Zoom'} '
                          'enter=$nowIso sep=${sep.toStringAsFixed(1)} '
                          'rotAccum=${_bm199Gate!.rotAccum.toStringAsFixed(3)} '
                          'zoomAccum=${_bm199Gate!.zoomAccum.toStringAsFixed(3)} '
                          'nonPanAccum=${_bm199Gate!.nonPanAccum.toStringAsFixed(3)} '
                          'k=${_bm199Gate!.p.kDominance.toStringAsFixed(2)} veto=$veto',
                        );
                        // Force the existing decision to lock immediately per BM-199 unless vetoed by parallel-like pan
                        if (!veto) {
                          decided = (lock == BM199Lock.rotate)
                              ? TwoFingerMode.rotate
                              : TwoFingerMode.zoom;
                          reason = lock == BM199Lock.rotate
                              ? 'BM-199 accumulate rotate'
                              : 'BM-199 accumulate zoom';
                        }
                      }
                    }
                    // Disable 2-finger pan while undecided (BM-199 requirement for clean Test B)
                    // No pan injection here.
                    final bool zoomDom =
                        _eScale > kZoomHys && _eScale > _eAngle && sepOk;
                    final bool rotDom =
                        _eAngle > kRotHysRad && rotDominates && sepOk;
                    if (zoomDom || rotDom) {
                      // Apply centroid-residual pan veto here as well
                      final bool veto = panVeto;
                      if (!veto &&
                          now.difference(_lastEvidenceTime).inMilliseconds >=
                              kDwellMs) {
                        decided = zoomDom
                            ? TwoFingerMode.zoom
                            : TwoFingerMode.rotate;
                        reason = zoomDom ? 'lock zoom' : 'lock rotate';
                      }
                    } else {
                      _lastEvidenceTime =
                          now; // reset dwell when neither dominates
                    }
                  } else if (kSeqAllow &&
                      cooled &&
                      seqCooled &&
                      _switches < kMaxSwitches) {
                    if (_twoMode == TwoFingerMode.zoom &&
                        _eAngle > (1.6 * kRotHysRad) &&
                        sep >= bmMinSepPx) {
                      decided = TwoFingerMode.rotate;
                      reason = 'zoom→rotate';
                    } else if (_twoMode == TwoFingerMode.rotate &&
                        _eScale > (1.6 * kZoomHys)) {
                      decided = TwoFingerMode.zoom;
                      reason = 'rotate→zoom';
                    }
                  }

                  if (decided != _twoMode) {
                    final dwell = now.difference(_lockTime).inMilliseconds;
                    if (_twoMode != TwoFingerMode.undecided) _switches++;
                    _twoMode = decided;
                    _lockTime = now;
                    _lastSwitchTime = now;
                    // Reset cumulative angle for peak tracking in new mode segment
                    _cumAngleTotal = 0.0;
                    // Reset post-lock smoothers when we enter a new locked mode
                    _sAngle = 0.0;
                    _sScale = 0.0;
                    // Initialize/clear sticky world anchors on lock
                    if (_twoMode == TwoFingerMode.rotate) {
                      _rigidPostLockFrames = 10; // log next 10 frames
                      // Anchor at world under current focal at lock time
                      _rotateAnchorWorld = screenToWorld(
                        focal,
                        size,
                        _pan,
                        _scale,
                        _rotation,
                      );
                      _rotateAnchorScreen0 = worldToScreen(
                        _rotateAnchorWorld!,
                        size,
                        _pan,
                        _scale,
                        _rotation,
                      );
                      _zoomAnchorWorld = null;
                      _zoomAnchorScreen0 = null;
                    } else if (_twoMode == TwoFingerMode.zoom) {
                      _zoomAnchorWorld = screenToWorld(
                        focal,
                        size,
                        _pan,
                        _scale,
                        _rotation,
                      );
                      _zoomAnchorScreen0 = worldToScreen(
                        _zoomAnchorWorld!,
                        size,
                        _pan,
                        _scale,
                        _rotation,
                      );
                      _rotateAnchorWorld = null;
                      _rotateAnchorScreen0 = null;
                    } else {
                      _rotateAnchorWorld = null;
                      _zoomAnchorWorld = null;
                      _rotateAnchorScreen0 = null;
                      _zoomAnchorScreen0 = null;
                    }
                    if (kBM194Enable && kBM194EventLogs) {
                      final fromTitle = _modeTitle(
                        _twoMode == decided
                            ? TwoFingerMode.undecided
                            : _twoMode,
                      );
                      final toTitle = _modeTitle(decided);
                      final enterStr = _lockTime.toIso8601String();
                      final exitStr = now.toIso8601String();
                      final dwellMs = dwell;
                      debugPrint(
                        '[BM-194 E] gid=$_gid $fromTitle→$toTitle enter=$enterStr exit=$exitStr dwell=${dwellMs}ms',
                      );
                      debugPrint(
                        '  peakAngle=${_peakAngle.toStringAsFixed(3)}rad peakScaleΔ=${_peakScaleDelta.toStringAsFixed(3)} reason="${reason ?? ''}"',
                      );
                    }
                    debugPrint(
                      '[BM-195 E] gid=$_gid ${_twoMode == TwoFingerMode.zoom
                          ? '→Zoom'
                          : _twoMode == TwoFingerMode.rotate
                          ? '→Rotate'
                          : 'Undecided'} '
                      'enter=${now.toIso8601String()} dwellPrev=${dwell}ms reason="${reason ?? ''}" '
                      'peakAngle=${_peakAngle.toStringAsFixed(3)}rad peakScaleΔ=${_peakScaleDelta.toStringAsFixed(3)}',
                    );
                    _peakAngle = 0.0;
                    _peakScaleDelta = 0.0;
                  }

                  // Sticky world anchors drive updates; no legacy screen focal used

                  if (_twoMode == TwoFingerMode.undecided) {
                    // Pan only while undecided
                    if (dp2 != Offset.zero) {
                      final dp2g = dp2 * Tunables.panGain;
                      _pan = Tunables.keepInBounds
                          ? _clampPan(_pan + dp2g, _scale, _rotation, size)
                          : (_pan + dp2g);
                      _composeView(size);
                    }
                  } else if (_twoMode == TwoFingerMode.zoom) {
                    // Sticky-anchor zoom about A_screen; no pan during zoom frames
                    final anchor =
                        _zoomAnchorWorld ??
                        screenToWorld(focal, size, _pan, _scale, _rotation);
                    final aScreen = worldToScreen(
                      anchor,
                      size,
                      _pan,
                      _scale,
                      _rotation,
                    );
                    // Drift diag: compare to lock-time screen anchor if available
                    if (_zoomAnchorScreen0 != null) {
                      diagPivotMismatchPx =
                          (aScreen - _zoomAnchorScreen0!).distance;
                    }
                    // BM-196: drift before this frame's application
                    final double bm196ZoomDriftPre = _zoomAnchorScreen0 != null
                        ? (aScreen - _zoomAnchorScreen0!).distance
                        : 0.0;
                    // Apply low-pass only after lock (here), never to pan
                    _sScale = _lp(_sScale, dScaleInc);
                    final factor = 1.0 + _sScale;
                    if (factor != 1.0) {
                      // Build G = T(A)·S(factor)·T(-A)
                      final g = Matrix4.identity()
                        ..translate(aScreen.dx, aScreen.dy)
                        ..scale(factor, factor)
                        ..translate(-aScreen.dx, -aScreen.dy);
                      // Proposed M' = G·M
                      final startView = Matrix4.copy(_view);
                      final mPrime = g..multiply(startView);
                      // Optionally clamp by decomposing
                      if (!Tunables.keepInBounds) {
                        _view = mPrime;
                        _decomposeView(size);
                        // BM-196: after apply without clamp
                        final aAfterAll = worldToScreen(
                          anchor,
                          size,
                          _pan,
                          _scale,
                          _rotation,
                        );
                        final double bm196ZoomDriftPost =
                            _zoomAnchorScreen0 != null
                            ? (aAfterAll - _zoomAnchorScreen0!).distance
                            : 0.0;
                        debugPrint(
                          '[BM-196 L] zoomLock A_world=(${anchor.dx.toStringAsFixed(2)},${anchor.dy.toStringAsFixed(2)})',
                        );
                        debugPrint(
                          '  focal=${_zoomAnchorScreen0 != null ? '(${_zoomAnchorScreen0!.dx.toStringAsFixed(0)},${_zoomAnchorScreen0!.dy.toStringAsFixed(0)})' : '(n/a)'} '
                          'A_scr=(${aAfterAll.dx.toStringAsFixed(1)},${aAfterAll.dy.toStringAsFixed(1)}) '
                          'driftPxPre=${bm196ZoomDriftPre.toStringAsFixed(2)} driftPxPost=${bm196ZoomDriftPost.toStringAsFixed(2)}',
                        );
                        debugPrint(
                          '  dθ_raw=${dAnglePtrRaw.toStringAsFixed(3)} dθ_wrap=${dAngleInc.toStringAsFixed(3)} ds=${factor.toStringAsFixed(3)} panInject=0',
                        );
                        debugPrint(
                          '  lowpass(angle)=${_sAngle.toStringAsFixed(3)} lowpass(scale)=${_sScale.toStringAsFixed(3)}',
                        );
                        debugPrint(
                          '  clamp=no sep=${sep.toStringAsFixed(1)}px',
                        );
                      } else {
                        // Decompose M'
                        final savedView = _view;
                        _view = Matrix4.copy(mPrime);
                        _decomposeView(size);
                        // If scale clamped, rebuild view with clamped scale around same anchor
                        final startScale = _scaleFrom(savedView);
                        final mPrimeScale = _scaleFrom(mPrime);
                        final targetScale = mPrimeScale.clamp(
                          _minScale,
                          _maxScale,
                        );
                        final clampedScaleFactor = targetScale / startScale;
                        final g2 = Matrix4.identity()
                          ..translate(aScreen.dx, aScreen.dy)
                          ..scale(clampedScaleFactor, clampedScaleFactor)
                          ..translate(-aScreen.dx, -aScreen.dy);
                        final mScaled = g2..multiply(savedView);
                        // Now clamp pan
                        _view = Matrix4.copy(mScaled);
                        _decomposeView(size);
                        final unclampedPan = _pan;
                        final clampedPan = _clampPan(
                          unclampedPan,
                          _scale,
                          _rotation,
                          size,
                        );
                        // Diagnostics: clamp delta
                        diagClampDx = clampedPan.dx - unclampedPan.dx;
                        diagClampDy = clampedPan.dy - unclampedPan.dy;
                        bool bm196ClampApplied = clampedPan != unclampedPan;
                        Offset bm196CompDelta = Offset.zero;
                        if (bm196ClampApplied) {
                          // Rebuild matrix with clamped pan
                          _pan = clampedPan;
                          _composeView(size);
                          // Compensate to keep anchor screen position
                          final aAfterClamp = worldToScreen(
                            anchor,
                            size,
                            _pan,
                            _scale,
                            _rotation,
                          );
                          final delta = aScreen - aAfterClamp;
                          final tComp = Matrix4.identity()
                            ..translate(delta.dx, delta.dy);
                          bm196CompDelta = delta;
                          _view = tComp..multiply(_view);
                          _decomposeView(size);
                        }
                        // Post-check: pin error after all corrections (should be ~0)
                        final aAfterAll = worldToScreen(
                          anchor,
                          size,
                          _pan,
                          _scale,
                          _rotation,
                        );
                        diagPinErrPost = (aAfterAll - aScreen).distance;
                        final double bm196ZoomDriftPost =
                            _zoomAnchorScreen0 != null
                            ? (aAfterAll - _zoomAnchorScreen0!).distance
                            : 0.0;
                        debugPrint(
                          '[BM-196 L] zoomLock A_world=(${anchor.dx.toStringAsFixed(2)},${anchor.dy.toStringAsFixed(2)})',
                        );
                        debugPrint(
                          '  focal=${_zoomAnchorScreen0 != null ? '(${_zoomAnchorScreen0!.dx.toStringAsFixed(0)},${_zoomAnchorScreen0!.dy.toStringAsFixed(0)})' : '(n/a)'} '
                          'A_scr=(${aAfterAll.dx.toStringAsFixed(1)},${aAfterAll.dy.toStringAsFixed(1)}) '
                          'driftPxPre=${bm196ZoomDriftPre.toStringAsFixed(2)} driftPxPost=${bm196ZoomDriftPost.toStringAsFixed(2)}',
                        );
                        debugPrint(
                          '  dθ_raw=${dAnglePtrRaw.toStringAsFixed(3)} dθ_wrap=${dAngleInc.toStringAsFixed(3)} ds=${factor.toStringAsFixed(3)} panInject=0',
                        );
                        debugPrint(
                          '  lowpass(angle)=${_sAngle.toStringAsFixed(3)} lowpass(scale)=${_sScale.toStringAsFixed(3)}',
                        );
                        debugPrint(
                          '  clamp=${bm196ClampApplied ? 'yes' : 'no'} '
                          'clampΔ=(${diagClampDx.toStringAsFixed(1)},${diagClampDy.toStringAsFixed(1)}) '
                          'postClampCompΔ=(${bm196CompDelta.dx.toStringAsFixed(1)},${bm196CompDelta.dy.toStringAsFixed(1)}) '
                          'sep=${sep.toStringAsFixed(1)}px',
                        );
                      }
                    }
                  } else if (_twoMode == TwoFingerMode.rotate) {
                    // Sticky-anchor rotate about A_screen; no pan durinqg rotate frames
                    final anchor =
                        _rotateAnchorWorld ??
                        screenToWorld(focal, size, _pan, _scale, _rotation);
                    final aScreen = worldToScreen(
                      anchor,
                      size,
                      _pan,
                      _scale,
                      _rotation,
                    );
                    // Drift diag: compare to lock-time screen anchor if available
                    if (_rotateAnchorScreen0 != null) {
                      diagPivotMismatchPx =
                          (aScreen - _rotateAnchorScreen0!).distance;
                    }
                    // BM-196: drift before this frame's application
                    final double bm196RotDriftPre = _rotateAnchorScreen0 != null
                        ? (aScreen - _rotateAnchorScreen0!).distance
                        : 0.0;
                    // Pace rotation
                    // Apply low-pass only after lock (here)
                    _sAngle = _lp(_sAngle, dAngleInc);
                    double dRot = _sAngle * _rotationGain;
                    final now2 = DateTime.now();
                    double dt = 0.016;
                    if (_lastRotateTs != null) {
                      dt = now2.difference(_lastRotateTs!).inMicroseconds / 1e6;
                      if (dt < 1 / 240.0) dt = 1 / 240.0;
                      if (dt > 0.1) dt = 0.1;
                    }
                    final allowed = math.min(
                      _maxRotateRate * dt,
                      _maxRotateStep,
                    );
                    if (dRot > allowed) dRot = allowed;
                    if (dRot < -allowed) dRot = -allowed;
                    _lastRotateTs = now2;
                    if (dRot != 0.0) {
                      // Build G = T(A)·R(dRot)·T(-A)
                      final g = Matrix4.identity()
                        ..translate(aScreen.dx, aScreen.dy)
                        ..rotateZ(dRot)
                        ..translate(-aScreen.dx, -aScreen.dy);
                      final startView = Matrix4.copy(_view);
                      final mPrime = g..multiply(startView);
                      if (!Tunables.keepInBounds) {
                        _view = mPrime;
                        _decomposeView(size);
                        // BM-196: after apply without clamp
                        final aAfterAll = worldToScreen(
                          anchor,
                          size,
                          _pan,
                          _scale,
                          _rotation,
                        );
                        final double bm196RotDriftPost =
                            _rotateAnchorScreen0 != null
                            ? (aAfterAll - _rotateAnchorScreen0!).distance
                            : 0.0;
                        debugPrint(
                          '[BM-196 L] rotLock A_world=(${anchor.dx.toStringAsFixed(2)},${anchor.dy.toStringAsFixed(2)})',
                        );
                        debugPrint(
                          '  focal=${_rotateAnchorScreen0 != null ? '(${_rotateAnchorScreen0!.dx.toStringAsFixed(0)},${_rotateAnchorScreen0!.dy.toStringAsFixed(0)})' : '(n/a)'} '
                          'A_scr=(${aAfterAll.dx.toStringAsFixed(1)},${aAfterAll.dy.toStringAsFixed(1)}) '
                          'driftPxPre=${bm196RotDriftPre.toStringAsFixed(2)} driftPxPost=${bm196RotDriftPost.toStringAsFixed(2)}',
                        );
                        debugPrint(
                          '  dθ_raw=${dAnglePtrRaw.toStringAsFixed(3)} dθ_wrap=${dAngleInc.toStringAsFixed(3)} ds=1.000 panInject=0',
                        );
                        debugPrint(
                          '  lowpass(angle)=${_sAngle.toStringAsFixed(3)} lowpass(scale)=${_sScale.toStringAsFixed(3)}',
                        );
                        debugPrint(
                          '  clamp=no sep=${sep.toStringAsFixed(1)}px',
                        );
                        // BM-198: per-frame drift log + rolling window PASS/FAIL
                        final driftPx = bm196RotDriftPost;
                        _bm198RotDrifts.add(driftPx);
                        if (_bm198RotDrifts.length > _bm198WindowSize) {
                          _bm198RotDrifts.removeAt(0);
                        }
                        debugPrint(
                          '[BM-198 T] driftPx=${driftPx.toStringAsFixed(3)} '
                          'A_world=(${anchor.dx.toStringAsFixed(2)},${anchor.dy.toStringAsFixed(2)}) '
                          'A_scr=(${aAfterAll.dx.toStringAsFixed(2)},${aAfterAll.dy.toStringAsFixed(2)}) '
                          'angle=${_rotation.toStringAsFixed(3)} scale=${_scale.toStringAsFixed(3)}',
                        );
                        if (_bm198RotDrifts.length >= _bm198WindowSize) {
                          final med = _bm198Median(_bm198RotDrifts);
                          final max = _bm198RotDrifts.reduce(math.max);
                          final pass = (med <= 0.3) && (max < 0.7);
                          debugPrint(
                            '[BM-198 TEST-B] window=${_bm198RotDrifts.length} '
                            'median=${med.toStringAsFixed(3)}px max=${max.toStringAsFixed(3)}px '
                            '${pass ? 'PASS' : 'FAIL'}',
                          );
                        }
                      } else {
                        // Decompose new state
                        _view = Matrix4.copy(mPrime);
                        _decomposeView(size);
                        final unclampedPan = _pan;
                        final clampedPan = _clampPan(
                          unclampedPan,
                          _scale,
                          _rotation,
                          size,
                        );
                        // Diagnostics: clamp delta
                        diagClampDx = clampedPan.dx - unclampedPan.dx;
                        diagClampDy = clampedPan.dy - unclampedPan.dy;
                        bool bm196ClampApplied = clampedPan != unclampedPan;
                        Offset bm196CompDelta = Offset.zero;
                        if (bm196ClampApplied) {
                          _pan = clampedPan;
                          _composeView(size);
                          // Compensate to keep anchor screen position
                          final aAfterClamp = worldToScreen(
                            anchor,
                            size,
                            _pan,
                            _scale,
                            _rotation,
                          );
                          final delta = aScreen - aAfterClamp;
                          final tComp = Matrix4.identity()
                            ..translate(delta.dx, delta.dy);
                          bm196CompDelta = delta;
                          _view = tComp..multiply(_view);
                          _decomposeView(size);
                        }
                        // Post-check: pin error after all corrections (should be ~0)
                        final aAfterAll = worldToScreen(
                          anchor,
                          size,
                          _pan,
                          _scale,
                          _rotation,
                        );
                        diagPinErrPost = (aAfterAll - aScreen).distance;
                        final double bm196RotDriftPost =
                            _rotateAnchorScreen0 != null
                            ? (aAfterAll - _rotateAnchorScreen0!).distance
                            : 0.0;
                        debugPrint(
                          '[BM-196 L] rotLock A_world=(${anchor.dx.toStringAsFixed(2)},${anchor.dy.toStringAsFixed(2)})',
                        );
                        debugPrint(
                          '  focal=${_rotateAnchorScreen0 != null ? '(${_rotateAnchorScreen0!.dx.toStringAsFixed(0)},${_rotateAnchorScreen0!.dy.toStringAsFixed(0)})' : '(n/a)'} '
                          'A_scr=(${aAfterAll.dx.toStringAsFixed(1)},${aAfterAll.dy.toStringAsFixed(1)}) '
                          'driftPxPre=${bm196RotDriftPre.toStringAsFixed(2)} driftPxPost=${bm196RotDriftPost.toStringAsFixed(2)}',
                        );
                        debugPrint(
                          '  dθ_raw=${dAnglePtrRaw.toStringAsFixed(3)} dθ_wrap=${dAngleInc.toStringAsFixed(3)} ds=1.000 panInject=0',
                        );
                        debugPrint(
                          '  lowpass(angle)=${_sAngle.toStringAsFixed(3)} lowpass(scale)=${_sScale.toStringAsFixed(3)}',
                        );
                        debugPrint(
                          '  clamp=${bm196ClampApplied ? 'yes' : 'no'} '
                          'clampΔ=(${diagClampDx.toStringAsFixed(1)},${diagClampDy.toStringAsFixed(1)}) '
                          'postClampCompΔ=(${bm196CompDelta.dx.toStringAsFixed(1)},${bm196CompDelta.dy.toStringAsFixed(1)}) '
                          'sep=${sep.toStringAsFixed(1)}px',
                        );
                        // BM-198: per-frame drift log + rolling window PASS/FAIL (with clamp compensation)
                        final driftPx = bm196RotDriftPost;
                        _bm198RotDrifts.add(driftPx);
                        if (_bm198RotDrifts.length > _bm198WindowSize) {
                          _bm198RotDrifts.removeAt(0);
                        }
                        debugPrint(
                          '[BM-198 T] driftPx=${driftPx.toStringAsFixed(3)} '
                          'A_world=(${anchor.dx.toStringAsFixed(2)},${anchor.dy.toStringAsFixed(2)}) '
                          'A_scr=(${aAfterAll.dx.toStringAsFixed(2)},${aAfterAll.dy.toStringAsFixed(2)}) '
                          'angle=${_rotation.toStringAsFixed(3)} scale=${_scale.toStringAsFixed(3)} '
                          'clampComp=${bm196ClampApplied ? 'yes' : 'no'}',
                        );
                        if (_bm198RotDrifts.length >= _bm198WindowSize) {
                          final med = _bm198Median(_bm198RotDrifts);
                          final max = _bm198RotDrifts.reduce(math.max);
                          final pass = (med <= 0.3) && (max < 0.7);
                          debugPrint(
                            '[BM-198 TEST-B] window=${_bm198RotDrifts.length} '
                            'median=${med.toStringAsFixed(3)}px max=${max.toStringAsFixed(3)}px '
                            '${pass ? 'PASS' : 'FAIL'}',
                          );
                        }
                      }
                    } else {
                      // dRot == 0.0 heartbeat: still report current drift for Test B when locked
                      final anchor = _rotateAnchorWorld;
                      if (anchor != null) {
                        final aAfterAll = worldToScreen(
                          anchor,
                          size,
                          _pan,
                          _scale,
                          _rotation,
                        );
                        final double driftPx = _rotateAnchorScreen0 != null
                            ? (aAfterAll - _rotateAnchorScreen0!).distance
                            : 0.0;
                        _bm198RotDrifts.add(driftPx);
                        if (_bm198RotDrifts.length > _bm198WindowSize) {
                          _bm198RotDrifts.removeAt(0);
                        }
                        debugPrint(
                          '[BM-198 T] driftPx=${driftPx.toStringAsFixed(3)} '
                          'A_world=(${anchor.dx.toStringAsFixed(2)},${anchor.dy.toStringAsFixed(2)}) '
                          'A_scr=(${aAfterAll.dx.toStringAsFixed(2)},${aAfterAll.dy.toStringAsFixed(2)}) '
                          'angle=${_rotation.toStringAsFixed(3)} scale=${_scale.toStringAsFixed(3)}',
                        );
                        if (_bm198RotDrifts.length >= _bm198WindowSize) {
                          final med = _bm198Median(_bm198RotDrifts);
                          final max = _bm198RotDrifts.reduce(math.max);
                          final pass = (med <= 0.3) && (max < 0.7);
                          debugPrint(
                            '[BM-198 TEST-B] window=${_bm198RotDrifts.length} '
                            'median=${med.toStringAsFixed(3)}px max=${max.toStringAsFixed(3)}px '
                            '${pass ? 'PASS' : 'FAIL'}',
                          );
                        }
                      }
                    }
                  }
                  // Post-lock rigid diagnostics for a few frames to ensure smooth evolution
                  if (_rigidPostLockFrames > 0 && rigidHave) {
                    debugPrint(
                      '[BM-199 RIGID] Sx=${rigidSxLog.toStringAsFixed(4)} Sy=${rigidSyLog.toStringAsFixed(4)} '
                      'dθ=${dThetaRigid.toStringAsFixed(5)} |r1|=${r1LenLog.toStringAsFixed(3)} '
                      '|r2|=${r2LenLog.toStringAsFixed(3)} '
                      'residualFrac=${residualFracInst.toStringAsFixed(3)} panVeto=${(panVeto).toString()} postLock=${_rigidPostLockFrames}',
                    );
                    _rigidPostLockFrames--;
                  }

                  // BM-198 generic per-frame diagnostic (Undecided/Zoom):
                  // When keepInBounds is OFF, capture a sticky world anchor on first two-finger frame,
                  // then log drift each frame even if Rotate is not locked yet. This does not affect behavior.
                  if (!Tunables.keepInBounds &&
                      _twoMode != TwoFingerMode.rotate) {
                    // Capture once
                    if (_bm198AnchorWorld == null) {
                      _bm198AnchorWorld = screenToWorld(
                        focal,
                        size,
                        _pan,
                        _scale,
                        _rotation,
                      );
                      _bm198AnchorScreen0 = worldToScreen(
                        _bm198AnchorWorld!,
                        size,
                        _pan,
                        _scale,
                        _rotation,
                      );
                    }
                    if (_bm198AnchorWorld != null &&
                        _bm198AnchorScreen0 != null) {
                      final aNow = worldToScreen(
                        _bm198AnchorWorld!,
                        size,
                        _pan,
                        _scale,
                        _rotation,
                      );
                      final driftPx = (aNow - _bm198AnchorScreen0!).distance;
                      _bm198RotDrifts.add(driftPx);
                      if (_bm198RotDrifts.length > _bm198WindowSize) {
                        _bm198RotDrifts.removeAt(0);
                      }
                      debugPrint(
                        '[BM-198 T] driftPx=${driftPx.toStringAsFixed(3)} '
                        'A_world=(${_bm198AnchorWorld!.dx.toStringAsFixed(2)},${_bm198AnchorWorld!.dy.toStringAsFixed(2)}) '
                        'A_scr=(${aNow.dx.toStringAsFixed(2)},${aNow.dy.toStringAsFixed(2)}) '
                        'angle=${_rotation.toStringAsFixed(3)} scale=${_scale.toStringAsFixed(3)}',
                      );
                      if (_bm198RotDrifts.length >= _bm198WindowSize) {
                        final med = _bm198Median(_bm198RotDrifts);
                        final max = _bm198RotDrifts.reduce(math.max);
                        final pass = (med <= 0.3) && (max < 0.7);
                        debugPrint(
                          '[BM-198 TEST-B] window=${_bm198RotDrifts.length} '
                          'median=${med.toStringAsFixed(3)}px max=${max.toStringAsFixed(3)}px '
                          '${pass ? 'PASS' : 'FAIL'}',
                        );
                      }
                    }
                  }

                  // Per-frame BM-195 state log
                  debugPrint(
                    '[BM-195 S] gid=$_gid mode=${_twoMode.name} '
                    'scale=${_scale.toStringAsFixed(2)} rot=${_rotation.toStringAsFixed(3)} '
                    'pan=(${_pan.dx.toStringAsFixed(1)},${_pan.dy.toStringAsFixed(1)}) '
                    'dScale=${dScaleInc.toStringAsFixed(4)} dAngle=${dAngleInc.toStringAsFixed(4)} '
                    'sep=${sep.toStringAsFixed(1)} '
                    'focal=(${focal.dx.toStringAsFixed(0)},${focal.dy.toStringAsFixed(0)})',
                  );

                  // Per-frame BM-194 state log (after state changes applied)
                  if (kBM194Enable && kBM194StateLogs) {
                    final nowF = DateTime.now();
                    double fps = 0;
                    if (_bm194LastFrameTs != null) {
                      final dt =
                          nowF.difference(_bm194LastFrameTs!).inMicroseconds /
                          1e6;
                      if (dt > 0) fps = 1 / dt;
                    }
                    _bm194LastFrameTs = nowF;
                    final dPanApplied = _pan - prevPanBM194;
                    // Indicate ignored signal based on active mode
                    final bool ignoreAngle = _twoMode == TwoFingerMode.zoom;
                    final bool ignoreScale = _twoMode == TwoFingerMode.rotate;
                    debugPrint(
                      '[BM-194 S] gid=$_gid mode=${_modeTitle(_twoMode)} '
                      'scale=${_scale.toStringAsFixed(2)} rot=${_rotation.toStringAsFixed(3)} '
                      'pan=(${_pan.dx.toStringAsFixed(1)},${_pan.dy.toStringAsFixed(1)})',
                    );
                    debugPrint(
                      '  dScale=${_sgn(dScaleInc, frac: 3)}${ignoreScale ? ' [ignored]' : ''} (from ${prevScaleBM194.toStringAsFixed(3)}) '
                      'dAngle=${_sgn(dAngleInc, frac: 3)} rad${ignoreAngle ? ' [ignored]' : ''} dPan=(${_sgn(dPanApplied.dx)},${_sgn(dPanApplied.dy)})',
                    );
                    final nowMs = nowF.millisecondsSinceEpoch;
                    final lastMs = _bm194FpsLastTs?.millisecondsSinceEpoch ?? 0;
                    final shouldLogFps =
                        (nowMs - lastMs) >= Tunables.fpsLogIntervalMs;
                    if (shouldLogFps) {
                      _bm194FpsLastTs = nowF;
                      debugPrint(
                        '  sep=${sep.toStringAsFixed(0)}px focal=(${focal.dx.toStringAsFixed(0)},${focal.dy.toStringAsFixed(0)}) fps=${fps.toStringAsFixed(0)}',
                      );
                    } else {
                      debugPrint(
                        '  sep=${sep.toStringAsFixed(0)}px focal=(${focal.dx.toStringAsFixed(0)},${focal.dy.toStringAsFixed(0)})',
                      );
                    }
                    // Optional pointer diagnostics: IDs and positions used for sep
                    if (pid1 != null &&
                        pid2 != null &&
                        p1 != null &&
                        p2 != null) {
                      debugPrint(
                        '  [BM-195 P] pIDs=[$pid1,$pid2] p1=(${p1.dx.toStringAsFixed(0)},${p1.dy.toStringAsFixed(0)}) '
                        'p2=(${p2.dx.toStringAsFixed(0)},${p2.dy.toStringAsFixed(0)}) sep=${sep.toStringAsFixed(1)}',
                      );
                    }
                  }

                  // Update previous raw values
                  _prevRawScale = rawScale;
                  // _prevRawAngle = rawAngle;
                  _prevFocal = focal;
                  // no prev separation stored
                  if (p1 != null && p2 != null) {
                    _prevP1 = p1;
                    _prevP2 = p2;
                    _prevSep = sep;
                    // store pair angle for potential future diagnostics
                    // _prevPairAngle = math.atan2((_p2 - _p1).dy, (_p2 - _p1).dx);
                  }
                  _lastFocal = d.localFocalPoint;
                  // Extra diagnostics (requested): raw signals, pin error, clamp delta, pivot mismatch
                  debugPrint(
                    '[BM-195 L] rawScale=${rawScale.toStringAsFixed(3)} rawRot=${rawAngle.toStringAsFixed(3)} '
                    'sep=${sep.toStringAsFixed(1)} gate=${(sep >= bmMinSepPx)} '
                    'pivotMismatchPx=${diagPivotMismatchPx.toStringAsFixed(1)} '
                    'pinErrPre=${diagPinErrPre.toStringAsFixed(3)}m pinErrPost=${diagPinErrPost.toStringAsFixed(3)}m '
                    'clampΔ=(${diagClampDx.toStringAsFixed(1)},${diagClampDy.toStringAsFixed(1)})',
                  );
                }
                setState(() {
                  _didFit = true;
                });
                ref
                    .read(mapViewController)
                    .update(pan: _pan, scale: _scale, rotation: _rotation);
              },
              onScaleEnd: (_) {
                _isGesturing = false;
                // Clear anchors on gesture end
                _rotateAnchorWorld = null;
                _zoomAnchorWorld = null;
                // Clear BM-198 diagnostic
                _bm198AnchorWorld = null;
                _bm198AnchorScreen0 = null;
                _bm198RotDrifts.clear();
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
                // _prevPairAngle = null;
                _bm199Gate?.reset();
                _bm199Gate = null;
                _bm199PairIds = null;
                // BM-199 removed per request
                debugPrint(
                  '$_tag GESTURE end rot=${_rotation.toStringAsFixed(3)} '
                  'scale=${_scale.toStringAsFixed(2)} pan=(${_pan.dx.toStringAsFixed(1)},${_pan.dy.toStringAsFixed(1)})',
                );
              },
              onDoubleTapDown: (details) {
                final fp = details.localPosition;
                // Zoom in without touching rotation; re-arm mode only
                _startZoomAnim(fp, Tunables.tapZoomFactor);
                if (Tunables.tapResetMode) {
                  _twoMode = TwoFingerMode.undecided;
                }
              },
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  _lastPaintSize = size;
                  if (!_isGesturing) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _fitOnce(size, proj);
                    });
                  }
                  return CustomPaint(
                    key: ValueKey(
                      '${_rotation.toStringAsFixed(3)}:${_scale.toStringAsFixed(2)}',
                    ),
                    painter: MapPainter(
                      projection: proj,
                      pan: _pan,
                      scale: _scale,
                      rotation: _rotation,
                      borderGroups: borderGroupsVal,
                      partitionGroups: partitionGroupsVal,
                      borderPointsByGroup: borderPtsMap,
                      partitionPointsByGroup: partitionPtsMap,
                      ref: ref,
                      gps: gps.value,
                      splitRingAWorld: _previewRingA,
                      splitRingBWorld: _previewRingB,
                      matrix: _view,
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
                  painter: _CutPainter(_debugCutLine!, _pan, _scale, _rotation),
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
                    setState(() => _debugCutLine = (aWorld, bWorld));
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
                    // Reuse the same view matrix as the painter for overlays
                    final matrix = _view;
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
                  FloatingActionButton.small(
                    heroTag: 'zoom_in',
                    onPressed: () {
                      final size = _lastPaintSize;
                      final center = size.center(Offset.zero);
                      final m = Matrix4.identity()
                        ..translate(center.dx, center.dy)
                        ..scale(1.2, 1.2)
                        ..translate(-center.dx, -center.dy);
                      setState(() {
                        _view = m..multiply(_view);
                        _decomposeView(size);
                        _didFit = true;
                      });
                      ref
                          .read(mapViewController)
                          .update(
                            pan: _pan,
                            scale: _scale,
                            rotation: _rotation,
                          );
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'zoom_out',
                    onPressed: () {
                      final size = _lastPaintSize;
                      final center = size.center(Offset.zero);
                      final m = Matrix4.identity()
                        ..translate(center.dx, center.dy)
                        ..scale(1 / 1.2, 1 / 1.2)
                        ..translate(-center.dx, -center.dy);
                      setState(() {
                        _view = m..multiply(_view);
                        _decomposeView(size);
                        _didFit = true;
                      });
                      ref
                          .read(mapViewController)
                          .update(
                            pan: _pan,
                            scale: _scale,
                            rotation: _rotation,
                          );
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
    final startView = Matrix4.copy(_view);
    Size size = _lastPaintSize;
    if (size == Size.zero) {
      final box = context.findRenderObject() as RenderBox?;
      size = box?.size ?? Size.zero;
    }
    void apply(double t) {
      final f = 1.0 + (factor - 1.0) * t;
      final m = Matrix4.identity()
        ..translate(fp.dx, fp.dy)
        ..scale(f, f)
        ..translate(-fp.dx, -fp.dy);
      setState(() {
        _view = m..multiply(startView);
        _decomposeView(size);
        _didFit = true;
      });
      ref
          .read(mapViewController)
          .update(pan: _pan, scale: _scale, rotation: _rotation);
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

  @override
  void dispose() {
    _animCtrl?.dispose();
    super.dispose();
  }

  // Clamp pan by keeping the viewport's world-corner box inside content bounds.
  Offset _clampPan(Offset pan, double scale, double rot, Size size) {
    // Map the 4 screen corners into world space using current camera.
    final cornersScreen = <Offset>[
      const Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    final cornersWorld = cornersScreen
        .map((p) => screenToWorld(p, size, pan, scale, rot))
        .toList(growable: false);
    // Compute world extents of the viewport box
    double minX = cornersWorld.first.dx,
        maxX = cornersWorld.first.dx,
        minY = cornersWorld.first.dy,
        maxY = cornersWorld.first.dy;
    for (final w in cornersWorld.skip(1)) {
      if (w.dx < minX) minX = w.dx;
      if (w.dx > maxX) maxX = w.dx;
      if (w.dy < minY) minY = w.dy;
      if (w.dy > maxY) maxY = w.dy;
    }
    // Required world-space correction to keep inside bounds
    double dxWorld = 0, dyWorld = 0;
    if (minX < _contentBounds.left) {
      dxWorld += _contentBounds.left - minX;
    }
    if (maxX > _contentBounds.right) {
      dxWorld += _contentBounds.right - maxX;
    }
    if (minY < _contentBounds.top) {
      dyWorld += _contentBounds.top - minY;
    }
    if (maxY > _contentBounds.bottom) {
      dyWorld += _contentBounds.bottom - maxY;
    }
    if (dxWorld == 0 && dyWorld == 0) return pan; // already inside
    // Convert world correction to screen pan delta: Δscreen = R*S*Δworld
    final c = math.cos(rot), s = math.sin(rot);
    final dxScreen = dxWorld * scale * c - dyWorld * scale * s;
    final dyScreen = dxWorld * scale * s + dyWorld * scale * c;
    return pan + Offset(dxScreen, dyScreen);
  }

  // ignore: unused_element
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

    const margin = 24.0;
    final sx = (size.width - margin * 2) / w;
    final sy = (size.height - margin * 2) / h;
    final s = (sx < sy ? sx : sy).clamp(0.2, 20.0);

    final centerWorld = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    // Given translate(center + pan) then scale, to bring world center to screen center with rotation 0:
    // pan should be -centerWorld * s (center will be added by painter's translate)
    final pan = Offset(-centerWorld.dx * s, -centerWorld.dy * s);

    setState(() {
      _scale = s;
      _rotation = 0.0;
      _pan = pan;
      _view = Matrix4.identity()
        ..translate(size.width / 2 + _pan.dx, size.height / 2 + _pan.dy)
        ..rotateZ(_rotation)
        ..scale(_scale);
      _didFit = true;
    });
    ref
        .read(mapViewController)
        .update(pan: _pan, scale: _scale, rotation: _rotation);
  }
}

class _CutPainter extends CustomPainter {
  _CutPainter(this.line, this.pan, this.scale, this.rot);
  final (Offset aWorld, Offset bWorld) line;
  final Offset pan;
  final double scale;
  final double rot;

  @override
  void paint(Canvas c, Size s) {
    c.save();
    final center = s.center(Offset.zero);
    c.translate(center.dx + pan.dx, center.dy + pan.dy);
    c.rotate(rot);
    c.scale(scale);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1 / scale
      ..color = const Color(0xFFEF6C00);
    c.drawLine(line.$1, line.$2, p);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _CutPainter old) =>
      old.line != line ||
      old.pan != pan ||
      old.scale != scale ||
      old.rot != rot;
}

// (compass badge widget moved to inline Transform for simplicity)
// (compass badge widget moved to inline Transform for simplicity)
