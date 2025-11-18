/// Centralized gesture tuning parameters for rotate/zoom/pan behavior.
///
/// Promote hard-coded thresholds here so they can be adjusted in one place
/// during field testing without hunting through multiple files.
class GestureTunables {
  // --- Dead-zones and movement gates ---
  static const double centroidMovePx =
      4.0; // px: consider dead-zones only if centroid moved more than this
  static const double deadZoneScaleEps =
      0.02; // |dScale-1| below this → treat as pan when centroid moved enough
  static const double deadZoneRotEps =
      0.03; // |dθ| below this → treat as pan when centroid moved enough

  // --- Per-frame clamps ---
  static const double pinchClampMin = 0.9; // min per-frame multiplicative scale
  static const double pinchClampMax = 1.1; // max per-frame multiplicative scale
  static const double rotStepClamp =
      0.15; // max per-tick rotation for buttons/animations (radians)
  static const double rotStopThreshold =
      0.02; // stop anim when remaining |Δθ| below this (radians)

  // --- Parallel-pan veto parameters ---
  static const double parMinPxPerFrame =
      0.5; // F1: minimum per-frame movement to consider a sample valid
  static const double parVMinPxS =
      5.0; // F2: minimum velocity per finger (px/s) to update EMAs
  static const int freezeMs = 100; // FREEZE window after parVeto entry

  // --- Numerical hygiene ---
  static const double detMin =
      1e-6; // determinant threshold to guard singular transforms

  // --- Safety rails for absolute scale (broad, app-agnostic) ---
  // Keep values broad; app-level UI limits should be enforced separately.
  static const double absScaleMin = 0.15;
  static const double absScaleMax = 8.0;
}
