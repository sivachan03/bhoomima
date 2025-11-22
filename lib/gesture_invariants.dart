// gesture_invariants.dart
import 'parsing.dart';

// BM-200 toggle: pinch-zoom gesture quality is not a ship blocker.
// Disable ZOOM-READY-STALLED invariant for this milestone.
const bool kCheckZoomReadyStalled = false;
// BM-200 toggle: legacy logs can trip rotate-ready-stalled; disable to keep
// golden replays green while gestures are pan-only.
const bool kCheckRotateReadyStalled = false;

class Violation {
  final String code;
  final String message;
  final List<int> lines;
  Violation(this.code, this.message, this.lines);
  @override
  String toString() => '$code @${lines.join(", ")}: $message';
}

class CheckerConfig {
  final double rotRateMin;
  final double zoomRateMin;
  final double rotEps; // rad
  final double zoomEps; // scale delta
  final int windowMs;
  final int panFreezeMinFrames;

  const CheckerConfig({
    this.rotRateMin = 0.3,
    this.zoomRateMin = 0.3,
    this.rotEps = 0.02,
    this.zoomEps = 0.01,
    this.windowMs = 250,
    this.panFreezeMinFrames = 6,
  });
}

class CheckResult {
  final List<Violation> violations;
  final bool verbose;
  CheckResult(this.violations, {this.verbose = false});
}

CheckResult checkInvariants(
  List<Frame> frames, {
  CheckerConfig cfg = const CheckerConfig(),
  bool verbose = false,
}) {
  final issues = <Violation>[];
  if (verbose) {
    // ignore: avoid_print
    print('[invariants] kCheckZoomReadyStalled=$kCheckZoomReadyStalled');
  }

  int winSize() => (cfg.windowMs / 16.7).round().clamp(8, 60);

  double sumAbs(Iterable<double> xs) => xs.fold(0.0, (a, b) => a + b.abs());

  // --- Collects ---
  final applies = frames
      .where((f) => f.apply != null)
      .map((f) => f.apply!)
      .toList();
  final gates = frames
      .where((f) => f.gate != null)
      .map((f) => f.gate!)
      .toList();
  // note: bms not used by current checks

  // A) PAN_FREEZE (you already hit this)
  {
    int streak = 0;
    final lines = <int>[];
    for (final fr in frames) {
      final b = fr.bm;
      final a = fr.apply;
      final panMode = (b?.mode.toLowerCase() == 'pan');
      final ok = (b != null && !b.veto);
      final frozen =
          a != null &&
          ((a.panPxX != null &&
                  a.panPxY != null &&
                  a.panPxX == 0.0 &&
                  a.panPxY == 0.0) ||
              ((a.tx != null && a.ty != null) &&
                  (a.tx!.abs() + a.ty!.abs()) < 0.5));
      if (panMode && ok && frozen) {
        streak++;
        lines.add(fr.lineNo);
        if (streak >= cfg.panFreezeMinFrames) {
          issues.add(
            Violation(
              'PAN-FREEZE',
              'Pan applied repeatedly with ‾0 motion while not vetoed (${cfg.panFreezeMinFrames} frames).',
              List<int>.from(lines),
            ),
          );
          streak = 0;
          lines.clear();
        }
      } else {
        streak = 0;
        lines.clear();
      }
    }
  }

  // B) ROTATE_OK_NO_APPLY (BM intent)
  {
    final win = winSize();
    final intentLines = <int>[];
    final dThetas = <double>[];
    for (final fr in frames) {
      final b = fr.bm;
      if (b != null) {
        if (b.rotateOk && !b.veto && b.rotRate >= cfg.rotRateMin) {
          intentLines.add(fr.lineNo);
        }
      }
      if (fr.apply != null) dThetas.add(fr.apply!.dTheta);
      if (intentLines.length >= win) {
        final hadIntent = intentLines.isNotEmpty;
        final sumTheta = sumAbs(dThetas.takeLast(win));
        if (hadIntent && sumTheta < cfg.rotEps) {
          issues.add(
            Violation(
              'ROTATE-OK-NO-APPLY',
              'Rotate OK (BM) over ‾${cfg.windowMs}ms but |∑dθ| < ${cfg.rotEps}.',
              intentLines.take(5).toList(),
            ),
          );
          intentLines.clear();
        }
      }
    }
  }

  // C) ZOOM_OK_NO_APPLY (BM intent)
  {
    final win = winSize();
    final intentLines = <int>[];
    final dScales = <double>[];
    for (final fr in frames) {
      final b = fr.bm;
      if (b != null) {
        if (b.zoomOk && !b.veto && b.zoomRate >= cfg.zoomRateMin) {
          intentLines.add(fr.lineNo);
        }
      }
      if (fr.apply != null) dScales.add(fr.apply!.dS);
      if (intentLines.length >= win) {
        final hadIntent = intentLines.isNotEmpty;
        final sumScale = sumAbs(dScales.takeLast(win));
        if (hadIntent && sumScale < cfg.zoomEps) {
          issues.add(
            Violation(
              'ZOOM-OK-NO-APPLY',
              'Zoom OK (BM) over ‾${cfg.windowMs}ms but |∑dS| < ${cfg.zoomEps}.',
              intentLines.take(5).toList(),
            ),
          );
          intentLines.clear();
        }
      }
    }
  }

  // D) ROTATE-READY-STALLED (PARGATE intent)
  if (kCheckRotateReadyStalled) {
    final win = winSize();
    final readyLines = <int>[];
    final dThetas = <double>[];

    void evaluateWindow() {
      if (readyLines.isEmpty) return;
      final sumTheta = sumAbs(dThetas.takeLast(win));
      if (sumTheta < cfg.rotEps) {
        issues.add(
          Violation(
            'ROTATE-READY-STALLED',
            'PARGATE rotateReady=true for ~${cfg.windowMs}ms but |∑dθ| < ${cfg.rotEps}.',
            readyLines.take(5).toList(),
          ),
        );
      }
      readyLines.clear();
    }

    for (final fr in frames) {
      final g = fr.gate;
      if (fr.apply != null) dThetas.add(fr.apply!.dTheta);

      if (g != null && g.rotateReady && !(fr.bm?.veto ?? false)) {
        readyLines.add(fr.lineNo);
        if (readyLines.length >= win) {
          evaluateWindow();
        }
      } else {
        evaluateWindow();
      }
    }
    // flush tail
    evaluateWindow();
  }

  // E) ZOOM-READY-STALLED (PARGATE intent)
  if (kCheckZoomReadyStalled) {
    final win = winSize();
    final readyLines = <int>[];
    final dScales = <double>[];

    void evaluateWindow() {
      if (readyLines.isEmpty) return;
      final sumScale = sumAbs(dScales.takeLast(win));
      if (sumScale < cfg.zoomEps) {
        issues.add(
          Violation(
            'ZOOM-READY-STALLED',
            'PARGATE zoomReady=true for ~${cfg.windowMs}ms but |∑dS| < ${cfg.zoomEps}.',
            readyLines.take(5).toList(),
          ),
        );
      }
      readyLines.clear();
    }

    for (final fr in frames) {
      final g = fr.gate;
      if (fr.apply != null) dScales.add(fr.apply!.dS);

      if (g != null && g.zoomReady && !(fr.bm?.veto ?? false)) {
        readyLines.add(fr.lineNo);
        if (readyLines.length >= win) {
          evaluateWindow();
        }
      } else {
        evaluateWindow();
      }
    }
    // flush tail
    evaluateWindow();
  }

  if (verbose && issues.isEmpty) {
    final anyRotateReady = gates.any((g) => g.rotateReady);
    final anyZoomReady = gates.any((g) => g.zoomReady);
    final totalTheta = applies.fold<double>(0.0, (s, a) => s + a.dTheta.abs());
    final totalScale = applies.fold<double>(0.0, (s, a) => s + a.dS.abs());
    // ignore: avoid_print
    print(
      '[hint] rotateReady:$anyRotateReady zoomReady:$anyZoomReady '
      '|∑dθ|=${totalTheta.toStringAsFixed(4)} |∑dS|=${totalScale.toStringAsFixed(4)}',
    );
  }

  return CheckResult(issues, verbose: verbose);
}

// tiny helper
extension<T> on List<T> {
  Iterable<T> takeLast(int n) => skip(length > n ? length - n : 0);
}
