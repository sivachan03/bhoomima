import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Offset, Size, Rect;

// BM-200R2.2: single engine plan. When false, legacy XFORM zoom/rotate side-effects
// (including logs) are disabled. Set to false in production with SIM path enabled.
bool bm200rUseOldXform = false;

/// Single source of truth for map transform (world space pivot-based).
/// tx, ty: world-space translation of map origin.
/// scale: world->screen scaling factor.
/// rotRad: rotation in radians.
class TransformModel {
  double tx; // world translation x
  double ty; // world translation y
  double scale; // uniform scale
  double rotRad; // rotation about world origin (or chosen pivot)
  // Clamp bounds for zooming via buttons/gestures
  double minScale;
  double maxScale;
  // When true, suppress verbose [XFORM] zoom/rotate logs (used in SIM path to avoid dual-engine noise).
  bool suppressLogs;
  // Last known viewport size; optional convenience for callers that want to store it on the model.
  // Not required by clampPan (which accepts a Size), but kept for coordination with view code.
  Size viewportSize;

  TransformModel({
    this.tx = -23822033.2,
    this.ty = 3970414.1,
    this.scale = 1.0,
    this.rotRad = 0.0,
    this.minScale = 0.8, // tightened lower zoom bound per map UX guidance
    this.maxScale =
        3.0, // lowered upper zoom bound (BM-200R3.2) to reduce extreme framing
    this.suppressLogs = false,
    this.viewportSize = Size.zero,
  });

  /*
   * Zoom semantics & high-scale framing (BM-200R clarification)
   * ----------------------------------------------------------
   * "Zoom in" vs "Zoom out" in logs:
   *   We log scale values like S=3.70→3.66→3.56→3.48→3.27. Because each
   *   successive scale is LOWER, that gesture sequence is a zoom OUT.
   *   A scaleFactor < 1.0 produces a negative dLogS and shrinks S. A scaleFactor
   *   > 1.0 grows S (zoom in). Pinch gestures often start with micro jitter;
   *   a dead zone (see SimTransformGesture.zoomDeadZoneFraction) forces most
   *   tiny changes to be treated as pure pan (scaleFactor coerced to 1.0).
   *
  * maxScale (currently 3.0):
  *   We clamp target scale to [minScale, maxScale]. Once S approaches maxScale
   *   further zoom-in attempts (scaleFactor > 1) will be flattened to keep S
   *   <= maxScale. This avoids extreme magnification where almost no context
   *   remains, making navigation disorienting.
   *
   * Edges "disappearing":
   *   At high S (~3–4) the viewport simply cannot contain the entire farm. Two
   *   or more sides will move out of view; this is expected. The clamp logic
   *   centers (if content narrower than view) or keeps edges within bounds
   *   without overscroll. Apparent disappearance is just content outside the
   *   cropped window, not a rendering fault.
  *   Mitigation now: lower maxScale to 3.0 and provide a Home button to
  *   instantly refit the farm if user feels lost.
   *
   * Future refinements:
   *   - Zoom pivot: Use the gesture focal point (average of fingers) instead of
   *     the screen center so users zoom toward what they pinch.
   *   - Soft clamp / overscroll: Allow a small margin so panning at edges feels
   *     less sticky and provides subtle elastic feedback.
   *   - Adaptive maxScale: Potentially raise maxScale when viewport is large
   *     enough (desktop) while keeping mobile at 4.0.
   *
   * Diagnostic guidance:
   *   - If logs show S decreasing with scaleFactor ~0.97–0.99, it's a zoom out.
   *   - If pan feels frozen near edges during pure pan frames, ensure clamping
   *     is gated behind actual zoom (map_view.dart _applySimGesture didZoom).
   */

  // TODO(BM-200R Pivot): Use gesture focal point for pivotW/pivotS in applyZoom.
  // TODO(BM-200R SoftClamp): Introduce a soft clamp region with mild easing instead of hard boundary.

  /// Initialize the view to fit and center the given world bounds within the view size.
  /// Must be called before any rotate/zoom to establish a stable home transform.
  void homeTo({
    required Rect worldBounds,
    required Size view,
    double margin = 0.06,
  }) {
    rotRad = 0.0; // start upright
    final w = worldBounds.width;
    final h = worldBounds.height;
    if (w <= 0 || h <= 0 || view.width <= 0 || view.height <= 0) {
      return;
    }
    final sx = (view.width * (1 - margin)) / w;
    final sy = (view.height * (1 - margin)) / h;
    final s = math.min(sx, sy).clamp(1e-6, 1e6).toDouble();
    scale = s;

    // Center the world-bounds center at the view center
    final worldC = worldBounds.center;
    final viewC = Offset(view.width / 2.0, view.height / 2.0);
    final cx = scale * worldC.dx;
    final cy = scale * worldC.dy;
    tx = viewC.dx - cx;
    ty = viewC.dy - cy;
    debugPrint(
      '[HOME] rot=0 scale=${scale.toStringAsFixed(3)} T=(${tx.toStringAsFixed(1)},${ty.toStringAsFixed(1)})',
    );
  }

  void applyPan(double dxWorld, double dyWorld) {
    if (dxWorld == 0.0 && dyWorld == 0.0) return;
    tx += dxWorld;
    ty += dyWorld;
  }

  /// Clamp translation so the worldBounds (scaled & rotated) continues to cover the viewport.
  /// Assumes tx,ty already updated. Uses a conservative axis-aligned bounding box after rotation.
  void clampPan({required Rect worldBounds, required Size view}) {
    if (view.isEmpty) return;
    // Compute rotated corners in screen space at current scale/rotation.
    final c = math.cos(rotRad), s = math.sin(rotRad);
    Offset toScreen(Offset w) {
      final sx = scale * w.dx, sy = scale * w.dy;
      final x = c * sx - s * sy + tx;
      final y = s * sx + c * sy + ty;
      return Offset(x, y);
    }

    final corners = <Offset>[
      toScreen(worldBounds.topLeft),
      toScreen(worldBounds.topRight),
      toScreen(worldBounds.bottomRight),
      toScreen(worldBounds.bottomLeft),
    ];
    double minX = corners.first.dx, maxX = corners.first.dx;
    double minY = corners.first.dy, maxY = corners.first.dy;
    for (final p in corners.skip(1)) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    final contentW = maxX - minX;
    final contentH = maxY - minY;
    // If content narrower than view, center; else clamp edges.
    double txAdjust = tx;
    double tyAdjust = ty;
    if (contentW <= view.width) {
      final centerX = (minX + maxX) * 0.5;
      final viewCenterX = view.width * 0.5;
      txAdjust += (viewCenterX - centerX);
    } else {
      final leftVisibleMin = view.width - contentW; // min allowed minX
      final targetMinX = minX;
      if (targetMinX > 0) {
        txAdjust -= targetMinX; // shift left to align
      } else if (targetMinX < leftVisibleMin) {
        txAdjust -= (targetMinX - leftVisibleMin); // shift right
      }
    }
    if (contentH <= view.height) {
      final centerY = (minY + maxY) * 0.5;
      final viewCenterY = view.height * 0.5;
      tyAdjust += (viewCenterY - centerY);
    } else {
      final topVisibleMin = view.height - contentH;
      final targetMinY = minY;
      if (targetMinY > 0) {
        tyAdjust -= targetMinY;
      } else if (targetMinY < topVisibleMin) {
        tyAdjust -= (targetMinY - topVisibleMin);
      }
    }
    tx = txAdjust;
    ty = tyAdjust;
  }

  void applyZoom(
    double dLogS, {
    required Offset pivotW,
    required Offset pivotS,
  }) {
    if (dLogS == 0.0) return;
    // Compute target scale and clamp to bounds to avoid excessive zoom.
    final unclamped = scale * math.exp(dLogS);
    final scaleNew = unclamped.clamp(minScale, maxScale).toDouble();
    final c = math.cos(rotRad), s = math.sin(rotRad);
    final sx = scaleNew * pivotW.dx, sy = scaleNew * pivotW.dy;
    tx = pivotS.dx - (c * sx - s * sy);
    ty = pivotS.dy - (s * sx + c * sy);
    if (!suppressLogs) {
      debugPrint(
        '[XFORM] zoom S=${scale.toStringAsFixed(3)}→${scaleNew.toStringAsFixed(3)} dLog=${dLogS.toStringAsFixed(4)}',
      );
    }
    scale = scaleNew;
  }

  void applyRotate(
    double dTheta, {
    required Offset pivotW,
    required Offset pivotS,
  }) {
    if (dTheta == 0.0) return;
    final thetaNew = rotRad + dTheta;
    final c = math.cos(thetaNew), s = math.sin(thetaNew);
    final sx = scale * pivotW.dx, sy = scale * pivotW.dy;
    tx = pivotS.dx - (c * sx - s * sy);
    ty = pivotS.dy - (s * sx + c * sy);
    if (!suppressLogs) {
      debugPrint(
        '[XFORM] rotate θ=${rotRad.toStringAsFixed(4)}→${thetaNew.toStringAsFixed(4)} dθ=${dTheta.toStringAsFixed(5)}',
      );
    }
    rotRad = thetaNew;
  }
}
