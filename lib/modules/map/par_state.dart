// Unified per-gid gesture state container (One source of truth)
// Holds EMA evidence (ParEma) plus latest parallel pan veto frame (ParallelPanVetoState).
// All FEED, GATE, APPLY, and logging stages should reference the same instance
// via: final gid = currentGid; final ps = parStates[gid]!;
// Update order: FEED raw deltas -> ps.ema updated; veto module updates ps.par.
// Consumers should never construct ParEma or ParallelPanVetoState directly.

import 'package:vector_math/vector_math_64.dart';
import 'par_ema.dart';
import 'parallel_pan_veto.dart';

class ParState {
  final int gid;
  final ParEma ema; // persistent EMAs
  ParallelPanVetoState? par; // latest 9h veto state for this frame
  // Canonical pipeline fields (written in order FEED→GATE→APPLY→VETO)
  double dLogSep = 0.0; // raw per-frame log separation delta
  double dTheta = 0.0; // raw per-frame rotation delta
  bool zoomReady = false;
  bool rotateReady = false;
  // Deprecated: mode selection now owned exclusively by GestureStateMachine.
  // Keep legacy snapshots for replay parsing but avoid writes elsewhere.
  String deprecatedModeSnapshot = 'pan';
  String deprecatedModeSnapshotPrev = 'pan';
  bool veto = false; // final par veto after VETO stage
  bool parLocked =
      false; // warm-up lock flag (true during initial freeze window)
  double residualFrac =
      0.0; // instantaneous rigidity residual |r1|+|r2| normalized
  // Low-pass filtered signals (single source for readiness and apply)
  double cosParLP = 0.0;
  double dLogLP = 0.0;
  double dThetaLP = 0.0;
  double residualLP = 0.0;
  // Matrices: previous and new view transforms (world→screen)
  Matrix4? mPrev;
  Matrix4? mNew;
  // Dwell counters for rate-based readiness gating
  int zoomReadyRun = 0;
  int rotReadyRun = 0;
  // Global accumulated scale for clamping across frames
  double totalScale = 1.0;
  // Accumulated rotation in degrees for UI/snap diagnostics
  double totalRotDeg = 0.0;
  // Accumulated rotation in radians (authoritative scalar for rotation)
  double rotRad = 0.0;
  // Per-gesture scale bounds (can be injected from tunables by consumer)
  double minScale = 0.7;
  double maxScale = 20.0; // temporarily raised for zoom clamp validation
  ParState(this.gid) : ema = ParEma();
}

// Global map keyed by gesture id (gid) for current gesture lifecycle.
// Only a single gid is typically active; older entries can be purged if needed.
final Map<int, ParState> parStates = <int, ParState>{};

ParState ensureParState(int gid) {
  return parStates.putIfAbsent(gid, () => ParState(gid));
}
