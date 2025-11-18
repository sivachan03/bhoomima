// golden_replay.dart

import 'dart:io';

import 'package:bhoomima/parsing.dart';
import 'package:bhoomima/gesture_invariants.dart';

void main(List<String> args) {
  stdout.writeln('[golden] args=' + args.join(' '));
  if (args.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/golden_replay.dart <logfile> [--verbose] '
      '[--rotRateMin=0.3] [--zoomRateMin=0.3] [--rotEps=0.02] [--zoomEps=0.01] [--windowMs=600]',
    );
    exit(2);
  }

  final path = args.first;
  final verbose = args.contains('--verbose') || args.contains('-v');

  // Note: Current invariants API (runInvariants) does not accept thresholds; we parse
  // flags for compatibility but ignore them. If configurable thresholds are added
  // later, wire them here.
  double getD(String name, double def) {
    final flag = args.firstWhere(
      (a) => a.startsWith('--$name='),
      orElse: () => '',
    );
    if (flag.isEmpty) return def;
    return double.tryParse(flag.split('=').last) ?? def;
  }

  int getI(String name, int def) {
    final flag = args.firstWhere(
      (a) => a.startsWith('--$name='),
      orElse: () => '',
    );
    if (flag.isEmpty) return def;
    return int.tryParse(flag.split('=').last) ?? def;
  }

  if (verbose) {
    stdout.writeln('Running replay on $path');
  }

  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('No such file: $path');
    exit(2);
  }

  final frames = parseLog(path);
  final cfg = CheckerConfig(
    rotRateMin: getD('rotRateMin', 0.3),
    zoomRateMin: getD('zoomRateMin', 0.3),
    rotEps: getD('rotEps', 0.02),
    zoomEps: getD('zoomEps', 0.01),
    windowMs: getI('windowMs', 600),
  );
  // Debug: show which invariants are enabled at runtime
  stdout.writeln(
    'invariants: ZOOM-READY-STALLED=' +
        (kCheckZoomReadyStalled ? 'ON' : 'OFF') +
        ' ROTATE-READY-STALLED=' +
        (kCheckRotateReadyStalled ? 'ON' : 'OFF'),
  );
  final res = checkInvariants(frames, cfg: cfg, verbose: verbose);
  // Apply final filtering based on milestone toggles to suppress selected checks.
  final filtered = res.violations.where((v) {
    if (!kCheckZoomReadyStalled && v.code == 'ZOOM-READY-STALLED') return false;
    if (!kCheckRotateReadyStalled && v.code == 'ROTATE-READY-STALLED')
      return false;
    return true;
  }).toList();

  if (filtered.isEmpty) {
    stdout.writeln('RESULT: PASS: No invariant failures detected in $path');
  } else {
    stdout.writeln(
      'RESULT: FAIL: ${filtered.length} invariant violation(s) in $path',
    );
    for (final v in filtered) {
      stdout.writeln(' - ${v.toString()}');
    }
    exitCode = 1;
  }
}
