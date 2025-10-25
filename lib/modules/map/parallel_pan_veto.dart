// BM-200B.9h: Parallel pan veto detector
import 'dart:math' as math;
import 'package:flutter/material.dart';

// Single-source-of-truth state for BM-200B.9h per-frame outputs
class ParallelPanVetoState {
  final double cosParAvg;
  final double sepFracAvg;
  final int validN;
  final bool parVeto; // effective veto (after overrides)
  final int tMs; // timestamp when computed
  final bool frameValid; // this frame contributed to EMAs (non-NA/tiny)
  // Rotation eligibility: recent streak where computed=true and |cosParAvg| ≤ 0.60
  final bool
  antiParReady; // true when rotate is allowed to arm (NA streak avoided)
  // Diagnostics: gesture identity and sequencing
  final int gestureId; // monotonic per-gesture id
  final int frameSeq; // per-gesture frame sequence (1,2,3,...)
  final int stateVersion; // incremented on each state publish
  // --- Freeze window fields ---
  final bool freezeActive;
  final int freezeAgeMs;

  const ParallelPanVetoState({
    required this.cosParAvg,
    required this.sepFracAvg,
    required this.validN,
    required this.parVeto,
    required this.tMs,
    required this.frameValid,
    required this.antiParReady,
    required this.gestureId,
    required this.frameSeq,
    required this.stateVersion,
    required this.freezeActive,
    required this.freezeAgeMs,
  });

  // Convenience: default-initialized state
  const ParallelPanVetoState.initial()
    : cosParAvg = 0.0,
      sepFracAvg = 0.0,
      validN = 0,
      parVeto = false,
      tMs = -1,
      frameValid = false,
      antiParReady = false,
      gestureId = -1,
      frameSeq = 0,
      stateVersion = 0,
      freezeActive = false,
      freezeAgeMs = 0;

  // --- NA-safe stringified getters for logs/telemetry ---
  String get parVetoStr => frameValid ? (parVeto ? 'true' : 'false') : 'NA';
  String get cosParAvgStr => frameValid ? cosParAvg.toStringAsFixed(3) : 'NA';
  String get sepFracAvgStr => frameValid ? sepFracAvg.toStringAsFixed(3) : 'NA';
}

class ParallelPanVeto {
  // Tunables (you can tweak later)
  // Classification threshold: require both fingers to move at least this many px (F1 validity gate)
  double pxPerFrameStrong = 1.5; // ~1.5 px minimum per frame
  // EWMA smoothing:
  // Faster entry (reach threshold within ~60–80 ms), slower exit for stability
  double alphaEntry = 0.40; // use while evaluating entry (pre-latch)
  double alphaExit = 0.15; // use while evaluating exit (post-latch)
  // Thresholds per latest spec
  double cosParThreshold = 0.95; // enter when cosParAvg ≥ 0.95
  double sepFracThreshold = 0.02; // enter when sepFracAvg ≤ 0.02 (over ~60ms)
  // Tiny displacement threshold for safe averaging (px/frame)
  final double _emaMinMagPx = 1.0; // skip EMA updates if either mag < this
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
  double sepFracAvg = 0.0;
  // Count of valid samples that actually contributed to the rolling stats
  int validSampleCount = 0;
  // Track recent anti-parallel streak for rotate arming (|cosParAvg| ≤ 0.60 and sepFracAvg < 0.05)
  int _antiParConsec =
      0; // consecutive valid frames satisfying |cosParAvg| ≤ 0.60 and sepFracAvg < 0.05
  int? _antiParStartMs; // start time of current anti-par streak
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

  void beginGesture() {
    _p1Prev = null;
    _p2Prev = null;
    _sepPrev = null;
    _hasPrev = false;
    cosParAvg = 0.0;
    sepFracAvg = 0.0;
    validSampleCount = 0;
    _antiParConsec = 0;
    _antiParStartMs = null;
    _antiParReadyNow = false;
    // Freeze config at gesture start and log once per gesture
    // 9i/9j request: use relToCentroid=true for PAR geometry flag (deltas remain displacement)
    relToCentroid = true;
    debugPrint('[BM-200B.9h PARCFG] active=9h relToCentroid=true');
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
    // Assign new gesture id and reset counters
    _gestureId = (++_gidCounter);
    _frameSeq = 0;
    _stateVersion = 0;
    // One-screen verification config line
    debugPrint(
      '[PARCFG] active=9h relToCentroid=' +
          (relToCentroid ? 'true' : 'false') +
          ' gestureId=' +
          _gestureId.toString(),
    );
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
        '[BM-200B.9h PAR] parVeto=false strong=false '
        'mag1=0.0 mag2=0.0 cosParRaw=NA cosParAvg=${cosParAvg.toStringAsFixed(3)} '
        'sepFracAvg=${sepFracAvg.toStringAsFixed(3)}',
      );
      return false;
    }

    // F2 — Use displacement vectors (relToCentroid=false)
    // Simple across-frame displacements for each finger
    final Offset v1 = p1_now - p1_prev;
    final Offset v2 = p2_now - p2_prev;

    final double mag1 = v1.distance;
    final double mag2 = v2.distance;

    // Compute separation change using coherent frame pairs
    final double sep_now = (p1_now - p2_now).distance;
    final double sep_prev = _sepPrev ?? sep_now;
    final double sepFracRaw =
        (sep_now - sep_prev).abs() / math.max(math.max(sep_now, sep_prev), 1.0);

    // F1 validity gate: consecutive frames; require max magnitude ≥ threshold
    // (Consecutiveness is enforced upstream by TwoFingerSampler; we check presence and magnitudes here.)
    final bool strong = (math.max(mag1, mag2) >= pxPerFrameStrong) && _hasPrev;

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
      debugPrint('[BM-200B.9h SIGN] signCheck=' + dot.toStringAsFixed(3));
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
      debugPrint(
        '[BM-200B.9h PARRESET] reason=dotSignFlip consec=' +
            _flipConsec.toString() +
            ' windowMs=' +
            ((_flipStartMs == null) ? '0' : (nowMs - _flipStartMs!).toString()),
      );
      _flipConsec = 0;
      _flipStartMs = null;
    }
    // Push current value and prune buffer (keep ~200ms)
    _sepFracBuf.add((nowMs, sepFracRaw));
    final int cutoffSep = nowMs - 200;
    while (_sepFracBuf.isNotEmpty && _sepFracBuf.first.$1 < cutoffSep) {
      _sepFracBuf.removeAt(0);
    }
    // Update consecutive spike counter
    if (sepFracRaw > _sepSpikeThreshold) {
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
        '[BM-200B.9h PARRESET] reason=sepFrac median=' +
            median.toStringAsFixed(3) +
            ' consec=' +
            consec.toString(),
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
      // Apply matching alpha to sep fraction for comparable entry/exit tempo
      final double aSep = _latched ? alphaExit : alphaEntry;
      sepFracAvg = aSep * sepFracRaw + (1 - aSep) * sepFracAvg;
      // Count this frame as a valid sample contributing to rolling stats
      validSampleCount++;
      // Entry/Exit decisions using windowed validity ratios
      // Entry decision: thresholds + minimum valid samples (validN ≥ 6)
      final bool enterOk =
          (cosParAvg >= cosParThreshold) &&
          (sepFracAvg <= sepFracThreshold) &&
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
        final bool exitCond = (cosParAvg <= 0.85) || (sepFracAvg >= 0.04);
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
      // Rotation eligibility: maintain anti-parallel streak only on valid frames
      // Require BOTH strong anti-parallel (|cosParAvg| ≤ 0.60) and low separation change (sepFracAvg < 0.05)
      final bool antiParNow = (cosParAvg.abs() <= 0.60) && (sepFracAvg < 0.05);
      if (antiParNow) {
        _antiParConsec += 1;
        _antiParStartMs ??= nowMs;
      } else {
        _antiParConsec = 0;
        _antiParStartMs = null;
      }
      _antiParReadyNow =
          (_antiParConsec >= 4) ||
          ((_antiParStartMs != null) && ((nowMs - _antiParStartMs!) >= 40));
    } else {
      // F1: invalid frame (missing prev or too tiny deltas) — no opinion this frame
      // Skip classification; hold EMA steady; set parVeto=false
      parVeto = false;
      // Break anti-parallel streak on invalid/NA frames
      _antiParConsec = 0;
      _antiParStartMs = null;
      _antiParReadyNow = false;
    }

    // Compute effective parVeto with override wiring
    final bool? override = forceAlwaysTrue
        ? true
        : (forceAlwaysFalse ? false : null);
    final bool parVetoEffective = override ?? parVeto;

    // Logging in your exact style (show NA when cosParRaw not computed)
    final String cosParRawStr = (cosParRaw == null)
        ? 'NA'
        : cosParRaw.toStringAsFixed(3);
    // Increment sequence/version before publishing/logging
    _frameSeq += 1;
    _stateVersion += 1;
    debugPrint(
      '[BM-200B.9h PAR] gid=' +
          _gestureId.toString() +
          ' seq=' +
          _frameSeq.toString() +
          ' ver=' +
          _stateVersion.toString() +
          ' computed=' +
          frameValid.toString() +
          ' override=' +
          (override == null ? 'NA' : override.toString()) +
          ' effective=$parVetoEffective strong=$strong ' +
          'mag1=${mag1.toStringAsFixed(1)} mag2=${mag2.toStringAsFixed(1)} ' +
          'cosParRaw=$cosParRawStr cosParAvg=${cosParAvg.toStringAsFixed(3)} ' +
          'sepFracAvg=${sepFracAvg.toStringAsFixed(3)} ' +
          'validN=$validSampleCount antiParReady=${_antiParReadyNow.toString()}',
    );
    // One-screen verification PAR line
    debugPrint(
      '[PAR] gestureId=' +
          _gestureId.toString() +
          ' frameSeq=' +
          _frameSeq.toString() +
          ' stateVersion=' +
          _stateVersion.toString() +
          ' parVeto=' +
          parVetoEffective.toString() +
          ' cosParAvg=' +
          cosParAvg.toStringAsFixed(3) +
          ' sepFracAvg=' +
          sepFracAvg.toStringAsFixed(3) +
          ' validN=' +
          validSampleCount.toString(),
    );

    // Advance "prev" for next frame
    _p1Prev = p1_now;
    _p2Prev = p2_now;
    _sepPrev = sep_now;
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
      validN: validSampleCount,
      parVeto: parVetoEffective,
      tMs: _lastUpdateMs,
      frameValid: frameValid,
      antiParReady: _antiParReadyNow,
      gestureId: _gestureId,
      frameSeq: _frameSeq,
      stateVersion: _stateVersion,
      freezeActive: freezeActive,
      freezeAgeMs: freezeAgeMs,
    );

    return parVetoEffective;
  }

  // Consumers can fetch the last computed state (same frame as update)
  ParallelPanVetoState? get lastState => _lastState;

  // Convenience: compute and return state in one call
  ParallelPanVetoState updateAndGet({
    required Offset p1_now,
    required Offset p2_now,
  }) {
    final bool _ = update(p1_now: p1_now, p2_now: p2_now);
    return _lastState ??
        const ParallelPanVetoState(
          cosParAvg: 0.0,
          sepFracAvg: 0.0,
          validN: 0,
          parVeto: false,
          tMs: -1,
          frameValid: false,
          antiParReady: false,
          gestureId: -1,
          frameSeq: 0,
          stateVersion: 0,
          freezeActive: false,
          freezeAgeMs: 0,
        );
  }

  void endGesture() {
    // optional: nothing required
  }
}
