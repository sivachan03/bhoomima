// Per-gid persistent EMA state for anti/ortho evidence
// Resets only on [G0 BIND] for that gid; not during dropout grace and not mid-gesture.

class ParEma {
  double antiE = 0.0;
  double orthoE = 0.0;
  // EMA of angular speed magnitude for rotation intent (|dθ|)
  double rotE = 0.0;
  // EMA of logarithmic separation change magnitude for zoom intent (|d log sep|)
  double zoomE = 0.0;
  // Raw cosine parallel EMA (fed from per-frame raw deltas)
  double cosPar = 0.0;
  // Latest raw separation (screen px) for gate/log
  double sepNow = 0.0;
  // Last-frame raw values (pre-transform), useful for APPLY vs FEED consistency checks
  double dLogSep = 0.0;
  double dTheta = 0.0;
  int validN = 0;
}

// Legacy global binding removed; callers now obtain ParState via ensureParState(gid)
// and pass its ParEma instance explicitly.

void parEmaFeed(ParEma s, double anti, double ortho, {double alpha = 0.25}) {
  s.antiE += (anti - s.antiE) * alpha;
  s.orthoE += (ortho - s.orthoE) * alpha;
  s.validN++;
}

/// Anti-only raw parity feed: updates pinch (antiE) EMA and validN.
/// Does NOT modify orthoE and respects bound gid filtering.
void parEmaFeedAnti(ParEma s, double antiRaw, {double alpha = 0.25}) {
  s.antiE += (antiRaw - s.antiE) * alpha;
  s.validN++;
}

/// Rotation-only feed: updates rotE with EMA of |dThetaRaw|.
void parEmaFeedRot(ParEma s, double rotAbs, {double alpha = 0.35}) {
  s.rotE += (rotAbs - s.rotE) * alpha;
  s.validN++;
}

/// Zoom-only feed: updates zoomE with EMA of |dLogSep|.
void parEmaFeedZoom(ParEma s, double zoomAbs, {double alpha = 0.35}) {
  s.zoomE += (zoomAbs - s.zoomE) * alpha;
  s.validN++;
}

/// Unified raw pointer feed: MUST be called before any pan-cancel/filters.
/// Applies EMAs to zoomE (|dLogSep|), rotE (|dTheta|), and cosPar; stores sepNow.
void parEmaFeedRawAll(
  ParEma s, {
  required double dLogSepAbs,
  required double dThetaAbs,
  required double cosPar,
  required double sepNow,
  double? dLogSepRaw,
  double? dThetaRaw,
  double alphaZoom = 0.35,
  double alphaRot = 0.35,
  double alphaCos = 0.25,
}) {
  s.zoomE += (dLogSepAbs - s.zoomE) * alphaZoom;
  s.rotE += (dThetaAbs - s.rotE) * alphaRot;
  s.cosPar += (cosPar - s.cosPar) * alphaCos;
  s.sepNow = sepNow;
  // Store raw deltas if provided for diagnostics and downstream APPLY usage
  if (dLogSepRaw != null) s.dLogSep = dLogSepRaw;
  if (dThetaRaw != null) s.dTheta = dThetaRaw;
  s.validN++;
}

// Reset now performed by creating a new ParState (and thus new ParEma) for gid.
