// BM-200B.9h: Parallel pan veto detector
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'par_ema.dart';
import 'par_state.dart';
// ignore_for_file: non_constant_identifier_names

// Winner-takes-all gating enum (pan/zoom/rotate) per spec
enum GMode { pan, zoom, rotate }

// --- ZR readiness latch (EMA + hysteresis) ---
class _ZrLatch {
  double pE = 0.0, apE = 0.0, orthoE = 0.0;
  bool zoomReady = false, rotateReady = false;
  bool parComputed =
      false; // becomes true once early parity condition met (e.g., validN ≥ 3)
  void feed(
    double cosPar,
    double sepFrac, {
    double alpha = 0.25,
    bool computedOK = false,
  }) {
    final double p = (cosPar + 1.0) * 0.5;
    final double ap = (1.0 - cosPar) * 0.5;
    final double ortho = 1.0 - cosPar.abs();
    pE += (p - pE) * alpha;
    apE += (ap - apE) * alpha;
    orthoE += (ortho - orthoE) * alpha;
    if (computedOK) parComputed = true;
    final bool bigEnough = sepFrac >= 0.04; // ~4% of min(viewW,viewH)
    // Zoom latch (anti-parallel)
    if (!zoomReady) {
      zoomReady = parComputed && bigEnough && apE >= 0.35;
    } else {
      zoomReady = parComputed && bigEnough && apE >= 0.25;
    }
    // Rotate latch (orthogonal)
    if (!rotateReady) {
      rotateReady = parComputed && bigEnough && orthoE >= 0.40;
    } else {
      rotateReady = parComputed && bigEnough && orthoE >= 0.30;
    }
  }

  void reset() {
    pE = apE = orthoE = 0.0;
    zoomReady = rotateReady = false;
    parComputed = false;
  }
}

// Single-source-of-truth state for BM-200B.9h per-frame outputs
class ParallelPanVetoState {
  final double cosParAvg;
  final double sepFracAvg;
  // Raw similarity channels for this frame (computed from cosParRaw before any de-pan/filters)
  final double parRaw; // (cosPar+1)/2 ∈ [0,1]
  final double antiRaw; // (1-cosPar)/2 ∈ [0,1]
  final double orthoRaw; // 1-|cosPar| ∈ [0,1]
  // Rotation evidence EMA (|dθ|) published from par_ema rotE
  final double rotE;
  // Zoom evidence EMA (|d log sep|) published from par_ema zoomE
  final double zoomE;
  final int validN;
  // true after enough accepted samples; independent of per-frame validity
  final bool computed;
  final bool parVeto; // effective veto (after overrides)
  final int tMs; // timestamp when computed
  final bool frameValid; // this frame contributed to EMAs (non-NA/tiny)
  // Readiness (latched with EMA+hysteresis):
  // - antiParReady is maintained for backward compatibility and maps to zoomReady
  final bool antiParReady; // legacy: equals zoomReady
  final bool zoomReady; // zoom latch based on anti-parallel evidence
  final bool rotateReady; // rotate latch based on orthogonal evidence
  // Winner-takes-all mode decided from energy thresholds with stickiness
  final String mode; // 'pan' | 'zoom' | 'rotate'
  // Diagnostics: gesture identity and sequencing
  final int gestureId; // monotonic per-gesture id
  final int frameSeq; // per-gesture frame sequence (1,2,3,...)
  final int stateVersion; // incremented on each state publish
  // --- Freeze window fields ---
  final bool freezeActive;
  final int freezeAgeMs;
  // Residual fraction (instantaneous rigidity residual) for VETO log
  final double residualFrac;

  const ParallelPanVetoState({
    required this.cosParAvg,
    required this.sepFracAvg,
    required this.parRaw,
    required this.antiRaw,
    required this.orthoRaw,
    required this.rotE,
    required this.zoomE,
    required this.validN,
    required this.computed,
    required this.parVeto,
    required this.tMs,
    required this.frameValid,
    required this.antiParReady,
    required this.zoomReady,
    required this.rotateReady,
    required this.mode,
    required this.gestureId,
    required this.frameSeq,
    required this.stateVersion,
    required this.freezeActive,
    required this.freezeAgeMs,
    required this.residualFrac,
  });

  // Convenience: default-initialized state
  const ParallelPanVetoState.initial()
    : cosParAvg = 0.0,
      sepFracAvg = 0.0,
      parRaw = 0.0,
      antiRaw = 0.0,
      orthoRaw = 0.0,
      rotE = 0.0,
      zoomE = 0.0,
      validN = 0,
      computed = false,
      parVeto = false,
      tMs = -1,
      frameValid = false,
      antiParReady = false,
      zoomReady = false,
      rotateReady = false,
      // Legacy snapshot only; SM owns authoritative live mode
      mode = 'pan',
      gestureId = -1,
      frameSeq = 0,
      stateVersion = 0,
      freezeActive = false,
      freezeAgeMs = 0,
      residualFrac = 0.0;

  // --- NA-safe stringified getters for logs/telemetry ---
  String get parVetoStr => frameValid ? (parVeto ? 'true' : 'false') : 'NA';
  String get cosParAvgStr => frameValid ? cosParAvg.toStringAsFixed(3) : 'NA';
  String get sepFracAvgStr => frameValid ? sepFracAvg.toStringAsFixed(3) : 'NA';
}

class ParallelPanVeto {
  static const double kParMinSepPx = 40.0; // shared min separation (px)
  // Pragmatic toggle: disable rotate gesture; keep rotate via UI button only
  static const bool kRotateGestureEnabled = false;
  // Viewport minimum dimension (logical px). Used to normalize absolute separation.
  // Must be provided by the consumer each frame or on size changes.
  double _viewportMin =
      1.0; // guard against div-by-zero; caller will set real value

  // Tunables (you can tweak later)
  // Classification threshold: require both fingers to move at least this many px (F1 validity gate)
  double pxPerFrameStrong = 1.5; // ~1.5 px minimum per frame
  // EWMA smoothing:
  // Faster entry (reach threshold within ~60–80 ms), slower exit for stability
  double alphaEntry = 0.40; // use while evaluating entry (pre-latch)
  double alphaExit = 0.15; // use while evaluating exit (post-latch)
  // Thresholds per latest spec
  double cosParThreshold = 0.95; // enter when cosParAvg ≥ 0.95
  // NOTE: Threshold below applies to change-of-separation EMA (not absolute).
  double sepFracThreshold = 0.02; // enter when sepDeltaAvg ≤ 0.02 (over ~60ms)
  // Tiny displacement threshold for safe averaging (px/frame)
  // Per spec C): compute from raw per-frame deltas; treat >0.5px as non-tiny
  final double _emaMinMagPx = 0.5; // skip EMA updates if either mag < this
  // Softer sep reset policy
  final int _sepMedianWindowMs =
      40; // window for median check (require ≥40ms span)
  final double _sepMedianThreshold = 0.12; // median ≥ 0.12 triggers reset
  final double _sepSpikeThreshold = 0.10; // individual spike threshold
  final int _sepSpikeNeedConsec = 3; // need 3 consecutive spikes to reset
  // Time-based hysteresis (ms)
  // Enter window ≈60ms via validity window; explicit dwell not needed beyond window check
  final int _minHoldMs = 100; // latch zeros for ≥100ms from entry
  // Note: validity window ratios replaced by validN≥8 entry condition
  // (Deprecated) frame-based dwell is replaced by time-based dwell

  // State (per-gesture)
  Offset? _p1Prev, _p2Prev;
  double? _sepPrev;
  bool _hasPrev = false;
  int? _lastDotSign; // +1 or -1 from last valid frame; null at start
  // Debounced flip tracking (dot sign changes)
  int _flipConsec = 0; // consecutive valid frames with flipped sign
  int? _flipStartMs; // when the flipped sign was first observed
  final int _flipWindowMs = 40; // require flip to persist ≥ 40ms
  final int _flipNeedConsec = 3; // or ≥3 consecutive valid flipped frames
  // (Deprecated) frame-based dwell counter (unused)
  // int _parLikeConsec = 0;
  int _sepSpikeConsec = 0; // consecutive sep spike frames for reset gating
  final List<(int tMs, double sepFrac)> _sepFracBuf = <(int, double)>[];
  int? _parOnSinceMs; // time when latched on
  bool _latched = false; // latched veto state before overrides
  // Validity window buffer: recent frames with validity flags for windowed ratios
  final List<(int tMs, bool valid)> _validBuf = <(int, bool)>[];

  // Smoothed signals (for logs & decision)
  double cosParAvg = 0.0;
  // Published: absolute separation fraction EMA (sep / min(viewW,viewH))
  double sepFracAvg = 0.0;
  // Internal: change-of-separation EMA for entry/exit thresholds
  double _sepDeltaAvg = 0.0;
  // Count of valid samples that actually contributed to the rolling stats
  int validSampleCount =
      0; // incremented on every accepted 2-pointer sample (delta frame)
  // Parity: minimum accepted samples before we consider state "computed"
  final int _computedN0 = 8; // ~6-10 recommended
  // Anti-parallel readiness simplified: derived directly from absolute separation.
  bool _antiParReadyNow = false; // computed per frame; published in state

  // Config flag: frozen per-gesture at beginGesture(); informational for logs
  bool relToCentroid = true;
  // One-shot per-gesture diagnostic for sign check
  bool _signLogged = false;
  // Seed parallel average from first valid sample (entry path)
  bool _seededCos = false;
  // Last update timestamp (ms)
  int _lastUpdateMs = -1;
  // Last published state
  ParallelPanVetoState? _lastState;
  // Diagnostics: gesture and state sequencing
  static int _gidCounter = 0;
  int _gestureId = -1; // assigned at beginGesture
  int _frameSeq = 0; // increments each update call
  int _stateVersion = 0; // increments each state publish

  // DEBUG: force parVeto to true for all frames
  bool forceAlwaysTrue = false; // set true to force parVeto=true
  // DEBUG: force parVeto to false for all frames
  bool forceAlwaysFalse = false; // set true to force parVeto=false

  // Configure viewport minimum for absolute separation normalization
  void setViewportMin(double v) {
    // Ensure sane bounds; avoid zero/negative
    _viewportMin = (v.isFinite && v > 0.0) ? v : 1.0;
  }

  final _ZrLatch _zr = _ZrLatch();

  void beginGesture({int? gestureId, ParState? ps}) {
    _p1Prev = null;
    _p2Prev = null;
    _sepPrev = null;
    _hasPrev = false;
    cosParAvg = 0.0;
    sepFracAvg = 0.0;
    validSampleCount = 0;
    _antiParReadyNow = false;
    // Freeze config at gesture start and log once per gesture
    // 9i/9j request: use relToCentroid=true for PAR geometry flag (deltas remain displacement)
    relToCentroid = true;
    debugPrint('[BM-200B.9h PARCFG] active=9h relToCentroid=true');
    if (ps != null) {
      ps.par = const ParallelPanVetoState.initial();
    }
    // Reset flip tracker
    _lastDotSign = null;
    _signLogged = false;
    // frame-based dwell removed; reset time-based dwell state handled above
    _sepSpikeConsec = 0;
    _sepFracBuf.clear();
    _parOnSinceMs = null;
    _latched = false;
    _validBuf.clear();
    _seededCos = false;
    _lastUpdateMs = -1;
    _lastState = null;
    _zr.reset();
    // Assign new gesture id and reset counters; allow external binding for parity
    _gestureId = (gestureId != null) ? gestureId : (++_gidCounter);
    _frameSeq = 0;
    _stateVersion = 0;
    // One-screen verification config line
    debugPrint(
      '[PARCFG] active=9h relToCentroid=${relToCentroid ? 'true' : 'false'} gestureId=$_gestureId',
    );
  }

  // Supply the two current finger positions in SCREEN pixels.
  // Returns parVeto: true => treat as parallel pan (block rot/zoom this frame).
  bool update({required Offset p1_now, required Offset p2_now, ParState? ps}) {
    // Never compute separation fractions on an unbound gesture (gid = -1)
    if (_gestureId < 0) {
      // Prime prev for when a gesture binds later, but do not compute or publish state
      _p1Prev = p1_now;
      _p2Prev = p2_now;
      _sepPrev = (p1_now - p2_now).distance;
      _hasPrev = true;
      return false;
    }
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
        '[BM-200B.9h PAR] parVeto=false strong=false '
        'mag1=0.0 mag2=0.0 cosParRaw=NA cosParAvg=${cosParAvg.toStringAsFixed(3)} '
        'sepFracAvg=${sepFracAvg.toStringAsFixed(3)}',
      );
      return false;
    }

    // RAW per-pointer deltas BEFORE any pan cancel or transform adjustments
    final Offset v1 = p1_now - p1_prev;
    final Offset v2 = p2_now - p2_prev;
    final double n1 = v1.distance;
    final double n2 = v2.distance;
    final double dotRaw = (v1.dx * v2.dx) + (v1.dy * v2.dy);
    final double cosParRawEarly = (n1 > 0.5 && n2 > 0.5)
        ? (dotRaw / (n1 * n2)).clamp(-1.0, 1.0)
        : 0.0;
    // RAW line vectors for separation & rotation
    final Offset aPrevEarly = (p2_prev - p1_prev);
    final Offset aNowEarly = (p2_now - p1_now);
    final double sepPrevEarly = aPrevEarly.distance;
    final double sepNowEarly = aNowEarly.distance;
    double dThetaRawEarly =
        math.atan2(aNowEarly.dy, aNowEarly.dx) -
        math.atan2(aPrevEarly.dy, aPrevEarly.dx);
    dThetaRawEarly = (dThetaRawEarly + math.pi) % (2 * math.pi) - math.pi;
    final double dLogSepEarly = (sepPrevEarly > 1.0 && sepNowEarly > 1.0)
        ? math.log(sepNowEarly / sepPrevEarly)
        : 0.0;
    if (ps != null) {
      // FEED raw deltas BEFORE any transform/filters (authoritative source)
      parEmaFeedRawAll(
        ps.ema,
        dLogSepAbs: dLogSepEarly.abs(),
        dThetaAbs: dThetaRawEarly.abs(),
        cosPar: cosParRawEarly,
        sepNow: sepNowEarly,
        dLogSepRaw: dLogSepEarly,
        dThetaRaw: dThetaRawEarly,
      );
    }

    final double mag1 = v1.distance;
    final double mag2 = v2.distance;

    // Compute separation change using coherent frame pairs
    final double sep_now = (p1_now - p2_now).distance;
    final double sep_prev = _sepPrev ?? sep_now;
    // Change-of-separation (fractional) using coherent frame pairs
    final double sepDeltaFracRaw =
        (sep_now - sep_prev).abs() / math.max(math.max(sep_now, sep_prev), 1.0);
    // Absolute separation normalized by viewport min (stable across frames)
    final double sepAbsFracRaw = sep_now / math.max(_viewportMin, 1.0);

    // F1 validity gate: consecutive frames; require max magnitude ≥ threshold
    // (Consecutiveness is enforced upstream by TwoFingerSampler; we check presence and magnitudes here.)
    // strong flag deprecated in trimmed logs; computed gating moved elsewhere

    // Compute dot/denom for sign and cos, with tiny/NA guards
    final double dot = (v1.dx * v2.dx) + (v1.dy * v2.dy);
    final double denom = (mag1 * mag2);
    final bool bothNonTiny = (mag1 >= _emaMinMagPx) && (mag2 >= _emaMinMagPx);
    // Explicit NA guard: if either magnitude is exactly zero, treat as NA and do not update EMAs
    final bool nonZero = (mag1 > 0.0) && (mag2 > 0.0);
    final bool denomOk = denom > 1e-6;
    final int currSign = (denomOk && bothNonTiny && nonZero)
        ? (dot >= 0.0 ? 1 : -1)
        : 0; // 0 => NA for sign
    // One-shot signCheck log (first valid delta frame)
    if (!_signLogged) {
      debugPrint('[BM-200B.9h SIGN] signCheck=${dot.toStringAsFixed(3)}');
      _signLogged = true;
    }

    // Debounced flip reset: track consecutive flipped-sign frames and time window
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    if (_lastDotSign != null && currSign != 0) {
      if (_lastDotSign != currSign) {
        _flipConsec += 1;
        _flipStartMs ??= nowMs;
      } else {
        _flipConsec = 0;
        _flipStartMs = null;
      }
    } else {
      _flipConsec = 0;
      _flipStartMs = null;
    }
    // Soft reset policy based on sepFracRaw history
    // Evaluate debounced flip conditions (either time-based or consecutive frames)
    final bool flipByConsec = _flipConsec >= _flipNeedConsec;
    final bool flipByWindow =
        (_flipStartMs != null) && ((nowMs - _flipStartMs!) >= _flipWindowMs);
    if (flipByConsec || flipByWindow) {
      cosParAvg = 0.0;
      sepFracAvg = 0.0;
      // Do not drop the latch if we're still within the min-hold window
      final bool inMinHold =
          (_parOnSinceMs != null) && ((nowMs - _parOnSinceMs!) < _minHoldMs);
      if (!inMinHold) {
        _latched = false;
      }
      final windowMs = (_flipStartMs == null)
          ? '0'
          : (nowMs - _flipStartMs!).toString();
      debugPrint(
        '[BM-200B.9h PARRESET] reason=dotSignFlip consec=$_flipConsec windowMs=$windowMs',
      );
      _flipConsec = 0;
      _flipStartMs = null;
    }
    // Push current value and prune buffer (keep ~200ms)
    _sepFracBuf.add((nowMs, sepDeltaFracRaw));
    final int cutoffSep = nowMs - 200;
    while (_sepFracBuf.isNotEmpty && _sepFracBuf.first.$1 < cutoffSep) {
      _sepFracBuf.removeAt(0);
    }
    // Update consecutive spike counter
    if (sepDeltaFracRaw > _sepSpikeThreshold) {
      _sepSpikeConsec++;
    } else {
      _sepSpikeConsec = 0;
    }
    // Compute median over last _sepMedianWindowMs; require a full ≥40ms span
    final int medianStart = nowMs - _sepMedianWindowMs;
    final List<double> win = <double>[];
    int? winEarliestTs;
    for (final e in _sepFracBuf) {
      if (e.$1 >= medianStart) {
        win.add(e.$2);
        winEarliestTs ??= e.$1;
      }
    }
    double median = 0.0;
    if (win.isNotEmpty) {
      win.sort();
      final int n = win.length;
      median = (n % 2 == 1)
          ? win[n >> 1]
          : ((win[(n >> 1) - 1] + win[n >> 1]) / 2.0);
    }
    final bool fullWindow =
        (winEarliestTs != null) &&
        ((nowMs - winEarliestTs) >= _sepMedianWindowMs);
    final bool resetByConsec =
        _sepSpikeConsec >= _sepSpikeNeedConsec; // ≥3 frames ≥ 0.10
    final bool resetByMedian =
        fullWindow &&
        (median >= _sepMedianThreshold); // median over ≥40ms ≥ 0.12
    if (resetByConsec || resetByMedian) {
      final int consec = _sepSpikeConsec;
      cosParAvg = 0.0;
      sepFracAvg = 0.0;
      // Do not drop the latch if we're still within the min-hold window
      final bool inMinHold =
          (_parOnSinceMs != null) && ((nowMs - _parOnSinceMs!) < _minHoldMs);
      if (!inMinHold) {
        _latched = false;
      }
      debugPrint(
        '[BM-200B.9h PARRESET] reason=sepDelta median=${median.toStringAsFixed(3)} consec=$consec',
      );
      _sepSpikeConsec = 0;
    }

    double? cosParRaw;
    bool parVeto = false;
    // Update validity window buffer for last ~200ms
    _validBuf.add((nowMs, (bothNonTiny && denomOk && nonZero)));
    // Prune entries older than 200ms
    final int cutoffBuf = nowMs - 200;
    while (_validBuf.isNotEmpty && _validBuf.first.$1 < cutoffBuf) {
      _validBuf.removeAt(0);
    }
    // Validity ratio helper removed; using validN (total EMA-contributing frames) for entry

    // Parity rule: count every accepted delta frame towards validN,
    // regardless of tiny magnitudes or EMA update eligibility.
    validSampleCount++;
    final bool computedNow = validSampleCount >= _computedN0;
    final bool frameValid = bothNonTiny && denomOk && nonZero;
    if (frameValid) {
      // Only compute/accumulate when strong AND both mags non-tiny AND denom valid
      cosParRaw = (dot / denom).clamp(-1.0, 1.0);
      // Seed cosParAvg on first valid sample; then use dual-alpha EWMA
      if (!_seededCos) {
        cosParAvg = cosParRaw;
        _seededCos = true;
      } else {
        final double a = _latched ? alphaExit : alphaEntry;
        cosParAvg = a * cosParRaw + (1 - a) * cosParAvg;
      }
      // Dual EWMAs:
      // 1) Change-of-sep (for entry/exit thresholds)
      final double aDelta = _latched ? alphaExit : alphaEntry;
      _sepDeltaAvg = aDelta * sepDeltaFracRaw + (1 - aDelta) * _sepDeltaAvg;
      // 2) Absolute normalized separation (for readiness + logs)
      const double aAbs = 0.20; // per request: ~0.2 alpha
      sepFracAvg = aAbs * sepAbsFracRaw + (1 - aAbs) * sepFracAvg;
      // Entry/Exit decisions using windowed validity ratios
      // Entry decision: thresholds + minimum valid samples (validN ≥ 6)
      final bool enterOk =
          (cosParAvg >= cosParThreshold) &&
          (_sepDeltaAvg <= sepFracThreshold) &&
          (validSampleCount >= 6);
      if (!_latched && enterOk) {
        _latched = true;
        _parOnSinceMs = nowMs;
      }
      // Exit only after minHold and with window + thresholds
      // Exit only after minHold and with strict thresholds (stronger hysteresis)
      if (_latched &&
          _parOnSinceMs != null &&
          (nowMs - _parOnSinceMs!) >= _minHoldMs) {
        final bool exitCond = (cosParAvg <= 0.85) || (_sepDeltaAvg >= 0.04);
        if (exitCond) {
          _latched = false;
        }
      }
      parVeto = _latched;
      // F4 — Non-parallel (allow rot/zoom) when strongly anti-parallel
      // Preserve the first 100ms after entry: don't cancel during min-hold
      final bool inMinHoldNow =
          (_parOnSinceMs != null) && ((nowMs - _parOnSinceMs!) < _minHoldMs);
      if (!inMinHoldNow && (cosParAvg < -0.70)) {
        parVeto = false;
      }
    } else {
      // F1: invalid frame (missing prev or too tiny deltas) — no opinion this frame
      // Skip classification; hold EMA steady; set parVeto=false
      parVeto = false;
      // On invalid frames, keep previous readiness latches (no forced reset)
    }

    // Residual fraction (instantaneous) using raw per-pointer deltas
    double residualFracInst = 0.0;
    if (frameValid) {
      final Offset d1 = v1; // same as pointer delta
      final Offset d2 = v2;
      final Offset dAvg = Offset((d1.dx + d2.dx) * 0.5, (d1.dy + d2.dy) * 0.5);
      final Offset r1 = d1 - dAvg;
      final Offset r2 = d2 - dAvg;
      final double r1Len = r1.distance;
      final double r2Len = r2.distance;
      final double sepNowPx = (p1_now - p2_now).distance;
      final double sepSafe = math.max(sepNowPx, 48.0);
      residualFracInst = (r1Len + r2Len) / sepSafe;
    }

    // Feed ZR EMA + hysteresis latch EVERY frame using a stable cosForFeed:
    // - Use fresh cosParRaw when this frame was valid; otherwise hold last cosParAvg.
    final double cosForFeed = (frameValid && (cosParRaw != null))
        ? cosParRaw
        : cosParAvg;
    _zr.feed(
      cosForFeed,
      sepAbsFracRaw,
      alpha: 0.25,
      computedOK: (validSampleCount >= 3),
    );
    // Readiness: publish hysteresis-latched readiness
    _antiParReadyNow = _zr.zoomReady; // legacy alias for zoom readiness

    // Compute effective parVeto with override wiring
    final bool? override = forceAlwaysTrue
        ? true
        : (forceAlwaysFalse ? false : null);
    final bool parVetoEffective = override ?? parVeto;

    // Logging in your exact style (show NA when cosParRaw not computed)
    // cosParRawStr no longer logged; keep cosParRaw for internal decisions
    // Raw similarity channels derived from the feed value so they remain stable on tiny frames
    final double cosLog = cosForFeed;
    final double parRaw = ((cosLog + 1.0) * 0.5).clamp(0.0, 1.0);
    final double antiRaw = ((1.0 - cosLog) * 0.5).clamp(0.0, 1.0);
    final double orthoRaw = (1.0 - cosLog.abs()).clamp(0.0, 1.0);
    // Pull unified raw-fed EMAs
    final double rotE = (ps != null) ? ps.ema.rotE : 0.0;
    final double zoomE = (ps != null) ? ps.ema.zoomE : 0.0;
    // Unified cosPar no longer logged here; external gate log uses ParPipeline.
    // final double cosParUnified = (ps != null) ? ps.ema.cosPar : cosParRawEarly;
    final double sepNowUnified = (ps != null) ? ps.ema.sepNow : sepNowEarly;
    // Increment sequence/version before publishing/logging
    _frameSeq += 1;
    _stateVersion += 1;
    // Feed persistent per-gid EMA every frame for both channels as before (kept for rotation readiness)
    if (ps != null) {
      final double cosLog2 = cosForFeed;
      final double anti = ((1.0 - cosLog2) * 0.5).clamp(0.0, 1.0);
      final double ortho = (1.0 - cosLog2.abs()).clamp(0.0, 1.0);
      parEmaFeed(ps.ema, anti, ortho, alpha: 0.25);
    }

    // Legacy readiness and ZR mode removed. Readiness and mode are decided in stepWithSample().
    const bool zoomReadyNow = false;
    const bool rotateReadyNow = false;
    const String decided = 'pan';

    // Advance "prev" for next frame
    _p1Prev = p1_now;
    _p2Prev = p2_now;
    _sepPrev = sepNowUnified;
    _hasPrev = true;
    // Track last sign when available
    if (currSign != 0) {
      _lastDotSign = currSign;
    }

    // --- Freeze window logic: freezeActive true for first 100ms after parVeto entry ---
    int freezeAgeMs = 0;
    bool freezeActive = false;
    if (_parOnSinceMs != null && parVetoEffective) {
      freezeAgeMs = nowMs - _parOnSinceMs!;
      freezeActive = freezeAgeMs < 100;
    }
    _lastUpdateMs = nowMs;
    _lastState = ParallelPanVetoState(
      cosParAvg: cosParAvg,
      sepFracAvg: sepFracAvg,
      parRaw: parRaw,
      antiRaw: antiRaw,
      orthoRaw: orthoRaw,
      rotE: rotE,
      zoomE: zoomE,
      validN: validSampleCount,
      computed: computedNow,
      parVeto: parVetoEffective,
      tMs: _lastUpdateMs,
      frameValid: frameValid,
      antiParReady: _antiParReadyNow,
      zoomReady: zoomReadyNow,
      rotateReady: rotateReadyNow,
      mode: decided,
      gestureId: _gestureId,
      frameSeq: _frameSeq,
      stateVersion: _stateVersion,
      freezeActive: freezeActive,
      freezeAgeMs: freezeAgeMs,
      residualFrac: residualFracInst,
    );

    // Unified per-frame log AFTER feed→gate→decide (apply happens elsewhere)
    // Removed verbose per-frame gate diagnostics (scaleMulRaw, rotDegRaw) per 5-line spec.
    // Suppress internal PARGATE spam; external pipeline emits canonical gate log.
    if (ps != null) {
      ps.par = _lastState;
    }
    return parVetoEffective;
  }

  // (Deprecated) rotate hysteresis and ZR handling removed in favor of rate+dwell gating.

  // Consumers can fetch the last computed state (same frame as update)
  ParallelPanVetoState? get lastState => _lastState;

  // Convenience: compute and return state in one call
  ParallelPanVetoState updateAndGet({
    required Offset p1_now,
    required Offset p2_now,
    ParState? ps,
  }) {
    final bool _ = update(p1_now: p1_now, p2_now: p2_now, ps: ps);
    return _lastState ??
        const ParallelPanVetoState(
          cosParAvg: 0.0,
          sepFracAvg: 0.0,
          parRaw: 0.0,
          antiRaw: 0.0,
          orthoRaw: 0.0,
          rotE: 0.0,
          zoomE: 0.0,
          validN: 0,
          computed: false,
          parVeto: false,
          tMs: -1,
          frameValid: false,
          antiParReady: false,
          zoomReady: false,
          rotateReady: false,
          mode: 'pan',
          gestureId: -1,
          frameSeq: 0,
          stateVersion: 0,
          freezeActive: false,
          freezeAgeMs: 0,
          residualFrac: 0.0,
        );
  }

  // Single-producer feed: consume a coalesced two-finger sample (prev, now)
  // Ensures PAR uses the same frame deltas as the sampler and is fed once.
  ParallelPanVetoState updateFromSampleAndGet({
    required Offset p1_prev,
    required Offset p2_prev,
    required Offset p1_now,
    required Offset p2_now,
    ParState? ps,
  }) {
    // Prime internal prevs from sample and mark as having prev
    _p1Prev = p1_prev;
    _p2Prev = p2_prev;
    _sepPrev = (p1_prev - p2_prev).distance;
    _hasPrev = true;
    final bool _ = update(p1_now: p1_now, p2_now: p2_now, ps: ps);
    return _lastState ??
        const ParallelPanVetoState(
          cosParAvg: 0.0,
          sepFracAvg: 0.0,
          parRaw: 0.0,
          antiRaw: 0.0,
          orthoRaw: 0.0,
          rotE: 0.0,
          zoomE: 0.0,
          validN: 0,
          computed: false,
          parVeto: false,
          tMs: -1,
          frameValid: false,
          antiParReady: false,
          zoomReady: false,
          rotateReady: false,
          mode: 'pan',
          gestureId: -1,
          frameSeq: 0,
          stateVersion: 0,
          freezeActive: false,
          freezeAgeMs: 0,
          residualFrac: 0.0,
        );
  }

  void endGesture() {
    // optional: nothing required
  }
}

class ParPipelineResult {
  final ParallelPanVetoState state; // includes gate decisions
  final double dLogSep; // from this frame raw pair
  final double dTheta; // from this frame raw pair
  final bool veto; // final veto after overrides
  ParPipelineResult({
    required this.state,
    required this.dLogSep,
    required this.dTheta,
    required this.veto,
  });
}

extension ParPipeline on ParallelPanVeto {
  // Run the strict per-frame pipeline with raw sample (prev,now). Always logs each stage.
  ParPipelineResult stepWithSample({
    required ParState ps,
    required Offset p1_prev,
    required Offset p2_prev,
    required Offset p1_now,
    required Offset p2_now,
    required bool twoDown,
  }) {
    // 1) PAR_FEED: feed raw deltas into EMAs and compute/update state
    final st = updateFromSampleAndGet(
      p1_prev: p1_prev,
      p2_prev: p2_prev,
      p1_now: p1_now,
      p2_now: p2_now,
      ps: ps,
    );
    // Pull raw frame deltas for APPLY_ZR from ps.ema proxies (we also recompute here for precision)
    final Offset vPrev = p2_prev - p1_prev;
    final Offset vNow = p2_now - p1_now;
    final double sepPrev = vPrev.distance;
    final double sepNow = vNow.distance;
    double dTheta =
        math.atan2(vNow.dy, vNow.dx) - math.atan2(vPrev.dy, vPrev.dx);
    dTheta = (dTheta + math.pi) % (2 * math.pi) - math.pi;
    final double dLogSep = (sepPrev > 1.0 && sepNow > 1.0)
        ? math.log(sepNow / sepPrev)
        : 0.0;
    // Write FEED deltas to ps (authoritative per-frame)
    ps.dLogSep = dLogSep;
    ps.dTheta = dTheta;
    // Stage 1 log (feed)
    debugPrint(
      '[PARFEED] dLogSep=${ps.ema.dLogSep.toStringAsFixed(5)} dTheta=${ps.ema.dTheta.toStringAsFixed(5)} cosPar=${ps.ema.cosPar.toStringAsFixed(3)} sepNow=${ps.ema.sepNow.toStringAsFixed(1)}',
    );
    // --- Readiness gating (physics-aligned, flicker-resistant) ---
    // Low-pass filtered signals (single source):
    // cosParLP   = 0.85*cosParLP   + 0.15*cosParNow;
    // dLogLP     = 0.85*dLogLP     + 0.15*dLogNow;
    // dThetaLP   = 0.85*dThetaLP   + 0.15*dThetaNow;
    // residualLP = 0.8*residualLP  + 0.2*residualNow; (residualNow already low-passed earlier to ps.residualFrac)
    ps.cosParLP = 0.85 * ps.cosParLP + 0.15 * st.cosParAvg;
    ps.dLogLP = 0.85 * ps.dLogLP + 0.15 * ps.dLogSep;
    ps.dThetaLP = 0.85 * ps.dThetaLP + 0.15 * ps.dTheta;
    ps.residualLP = 0.8 * ps.residualLP + 0.2 * ps.residualFrac;
    const double minSep = 40.0;
    // Rate-based gating with dwell per spec
    const double kPanCosMin = 0.90; // ≥0.90 considered parallel → pan
    const double kZoomRateMin = 0.60; // log-scale / sec (≈ +82%/s)
    const double kRotRateMin = 1.20; // rad/s (~69°/s)
    const int kDwellFrames = 3; // ~50 ms at 60 fps
    final double sepNowPx = ps.ema.sepNow;
    // Compute per-second rates using dt from previous published state timestamp
    final int? prevMs = ps.par?.tMs;
    final double dtSec = (st.frameValid && prevMs != null)
        ? ((st.tMs - prevMs) / 1000.0).clamp(1e-3, 1.0)
        : (1.0 / 60.0);
    final double zoomRate = (ps.dLogLP.abs()) / dtSec;
    final double rotRate = (ps.dThetaLP.abs()) / dtSec;
    final bool zoomShapeOK = ps.cosParLP < kPanCosMin;
    final bool zoomMagOK = zoomRate > kZoomRateMin;
    final bool rotMagOK = rotRate > kRotRateMin;
    // Dwell counters in ParState; reset if twoDown false or sep too small
    if (!(twoDown && sepNowPx > minSep)) {
      ps.zoomReadyRun = 0;
      ps.rotReadyRun = 0;
    } else {
      ps.zoomReadyRun = (zoomShapeOK && zoomMagOK) ? (ps.zoomReadyRun + 1) : 0;
      ps.rotReadyRun = (rotMagOK) ? (ps.rotReadyRun + 1) : 0;
    }
    final bool zoomReadyNow = ps.zoomReadyRun >= kDwellFrames;
    bool rotateReadyNow = ps.rotReadyRun >= kDwellFrames;
    if (!ParallelPanVeto.kRotateGestureEnabled) {
      // Force rotate gesture off; keep counters clean and log false
      ps.rotReadyRun = 0;
      rotateReadyNow = false;
    }
    ps.rotateReady = rotateReadyNow;
    ps.zoomReady = zoomReadyNow;
    // Mode selection without ZR: if both ready, choose by shape (cos < 0 => zoom else rotate)
    GMode next;
    if (!zoomReadyNow && !rotateReadyNow) {
      next = GMode.pan;
    } else if (zoomReadyNow && !rotateReadyNow) {
      next = GMode.zoom;
    } else if (rotateReadyNow && !zoomReadyNow) {
      next = ParallelPanVeto.kRotateGestureEnabled ? GMode.rotate : GMode.zoom;
    } else {
      // both true
      if (ParallelPanVeto.kRotateGestureEnabled) {
        next = (ps.cosParLP < 0.0) ? GMode.zoom : GMode.rotate;
      } else {
        next = GMode.zoom;
      }
    }
    // Do NOT mutate ps.mode here; SM arbiter owns authoritative mode.
    final String pargateMode = (next == GMode.zoom)
        ? 'zoom'
        : (next == GMode.rotate)
        ? 'rotate'
        : 'pan';
    ps.veto =
        st.parVeto; // carry through veto (parallel pan) from underlying state

    // Capture energy EMAs for publishing (use st.rotE/zoomE which came from ps.ema earlier)
    final double rotE = st.rotE;
    final double zoomE = st.zoomE;

    // Re-publish a state object with updated mode/readiness so external consumers remain consistent
    final updatedState = ParallelPanVetoState(
      cosParAvg: st.cosParAvg,
      sepFracAvg: st.sepFracAvg,
      parRaw: st.parRaw,
      antiRaw: st.antiRaw,
      orthoRaw: st.orthoRaw,
      rotE: rotE,
      zoomE: zoomE,
      validN: st.validN,
      computed: st.computed,
      parVeto: st.parVeto,
      tMs: st.tMs,
      frameValid: st.frameValid,
      antiParReady: st.antiParReady,
      zoomReady: ps.zoomReady,
      rotateReady: ps.rotateReady,
      mode: pargateMode,
      gestureId: st.gestureId,
      frameSeq: st.frameSeq,
      stateVersion: st.stateVersion,
      freezeActive: st.freezeActive,
      freezeAgeMs: st.freezeAgeMs,
      residualFrac: st.residualFrac,
    );
    ps.par = updatedState;
    // Low-pass residual before consumers compute veto
    final double prevResid = ps.residualFrac;
    ps.residualFrac =
        (prevResid.isFinite ? (0.8 * prevResid) : 0.0) +
        0.2 * updatedState.residualFrac;
    // Stage 2 log (gate) per spec — use dwell-filtered readiness (counters-based)
    debugPrint(
      '[PARGATE] mode=$pargateMode cosParLP=${ps.cosParLP.toStringAsFixed(3)} '
      'dLogLP=${ps.dLogLP.toStringAsFixed(4)} dThetaLP=${ps.dThetaLP.toStringAsFixed(4)} '
      'zoomReady=${zoomReadyNow} rotateReady=${rotateReadyNow}',
    );
    // Note: [BM-199 E] emissions are handled by the consumer after computing
    // the unified global veto to ensure a single source of truth.
    // Stage 3 APPLY and Stage 4 VETO are logged externally after apply

    return ParPipelineResult(
      state: updatedState,
      dLogSep: dLogSep,
      dTheta: dTheta,
      veto: updatedState.parVeto,
    );
  }
}
