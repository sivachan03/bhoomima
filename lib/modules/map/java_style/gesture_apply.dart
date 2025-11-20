import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../transform_model.dart';
import 'two_finger_gesture.dart';

/// Apply a 2-finger update to TransformModel.
///
/// Assumptions:
/// - TransformModel.tx / ty are in screen logical pixels (translation).
/// - TransformModel.scale is unitless.
/// - TransformModel.rotRad is rotation in radians.
/// - MapPainter uses tx, ty, scale, rotRad consistently (e.g. translate→scale→rotate).
///
/// If MapPainter uses a different order, the feel will differ; but the math is
/// otherwise consistent and self-contained.
void applyTwoFingerUpdateToTransform(TransformModel xform, TwoFingerUpdate u) {
  if (u == TwoFingerUpdate.zero) return;

  final oldScale = xform.scale;
  final oldRot = xform.rotRad;
  final oldTx = xform.tx;
  final oldTy = xform.ty;

  double newScale = oldScale;
  double newRot = oldRot;
  double tx = oldTx;
  double ty = oldTy;

  final Offset focal = u.focalPointPx;

  // 1) Zoom around focal point (screen coordinates).
  if (u.scaleFactor != 1.0) {
    newScale = (oldScale * u.scaleFactor)
        .clamp(xform.minScale, xform.maxScale)
        .toDouble();

    final double sRatio = newScale / oldScale;
    // Keep the point under 'focal' visually stable.
    tx = focal.dx - sRatio * (focal.dx - tx);
    ty = focal.dy - sRatio * (focal.dy - ty);
  }

  // 2) Rotate around the same focal point.
  if (u.rotationDelta != 0.0) {
    newRot = oldRot + u.rotationDelta;
    final double cosD = math.cos(u.rotationDelta);
    final double sinD = math.sin(u.rotationDelta);

    final double dx = tx - focal.dx;
    final double dy = ty - focal.dy;
    final double dxR = cosD * dx - sinD * dy;
    final double dyR = sinD * dx + cosD * dy;
    tx = focal.dx + dxR;
    ty = focal.dy + dyR;
  }

  // 3) Pan in screen space.
  if (u.panDeltaPx != Offset.zero) {
    tx += u.panDeltaPx.dx;
    ty += u.panDeltaPx.dy;
  }

  // Commit back to model.
  xform.scale = newScale;
  xform.rotRad = newRot;
  xform.tx = tx;
  xform.ty = ty;

  debugPrint(
    '[J2] apply pan=(${u.panDeltaPx.dx.toStringAsFixed(2)},'
    '${u.panDeltaPx.dy.toStringAsFixed(2)}) '
    'scaleFactor=${u.scaleFactor.toStringAsFixed(3)} '
    'dθ=${u.rotationDelta.toStringAsFixed(3)} → '
    'T=(${tx.toStringAsFixed(1)},${ty.toStringAsFixed(1)}) '
    'S=${newScale.toStringAsFixed(3)} rot=${newRot.toStringAsFixed(3)}',
  );
}
