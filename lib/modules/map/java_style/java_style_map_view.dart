import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../transform_model.dart';
import '../map_painter.dart';
import '../../../core/services/projection_service.dart';
import '../../../core/services/gps_service.dart';
import '../map_providers.dart';
import '../map_points_aggregate.dart';
import '../../../app_state/active_property.dart';
import '../../../core/models/point_group.dart';
import '../../../core/models/point.dart';
import 'two_finger_gesture.dart';
import 'gesture_apply.dart';

/// Java-style map view: direct 2-finger gesture engine (pan+zoom+rotate) without PhotoView.
/// 1 finger: ignored (could be wired for tap interactions overlay).
/// 2 fingers: per-frame deltas applied to TransformModel using focal point pivot logic.
class JavaStyleMapView extends ConsumerStatefulWidget {
  const JavaStyleMapView({super.key});

  @override
  ConsumerState<JavaStyleMapView> createState() => _JavaStyleMapViewState();
}

class _JavaStyleMapViewState extends ConsumerState<JavaStyleMapView> {
  // Tuned deadzones: higher minScaleChange reduces unintended zoom on light pan.
  final _engine = TwoFingerGestureEngine(
    minScaleChange:
        0.010, // was 0.002 (0.2%), now 1.0% per frame before zoom engages
    rotationDeadZone: 0.005, // was 0.003 (~0.17°), now ~0.29°
  );
  final Map<int, Offset> _pointers = {};
  late TransformModel _xform; // runtime mutable transform
  Rect _worldBounds = const Rect.fromLTWH(-500, -500, 1000, 1000);
  Size _viewSize = Size.zero;
  bool _didHomeFit = false;

  @override
  void initState() {
    super.initState();
    _xform = TransformModel(suppressLogs: false);
  }

  void _recomputeHome() {
    if (_viewSize.isEmpty) return;
    _xform.homeTo(
      worldBounds: _worldBounds,
      view: _viewSize,
      margin: 0.12,
    ); // increased margin to reduce initial edge cropping
    setState(() {});
  }

  void _applyTwoFinger(TwoFingerUpdate u) {
    if (u == TwoFingerUpdate.zero) return;
    applyTwoFingerUpdateToTransform(_xform, u);
    _xform.clampPan(worldBounds: _worldBounds, view: _viewSize);
    setState(() {});
  }

  void _onPointerDown(PointerDownEvent e) {
    debugPrint('[J2] down id=${e.pointer} pos=${e.localPosition}');
    _engine.onPointerDown(e.pointer, e.localPosition, _pointers);
  }

  void _onPointerMove(PointerMoveEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 2 && _engine.isActive) {
      final update = _engine.onPointerMove(_pointers);
      debugPrint('[J2] move id=${e.pointer} update=$update');
      _applyTwoFinger(update);
    } else {
      // 0/1/>2 fingers: ignore for geometry; reserve for other interactions.
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    _engine.onPointerUpOrCancel(e.pointer, _pointers);
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _engine.onPointerUpOrCancel(e.pointer, _pointers);
  }

  @override
  Widget build(BuildContext context) {
    // Providers (similar to BranchB logic)
    final prop = ref.watch(activePropertyProvider).asData?.value;
    final gps = ref.watch(gpsStreamProvider).asData?.value;
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

    return LayoutBuilder(
      builder: (_, constraints) {
        _viewSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (_xform.viewportSize != _viewSize) {
          _xform.viewportSize = _viewSize;
        }

        // Compute world bounds (used for home fit and clamping).
        Rect wb = const Rect.fromLTWH(-500, -500, 1000, 1000);
        void includeGroupBounds(Map<int, List<Point>> ptsByGroup) {
          bool hasAny = false;
          Offset minNow = Offset.zero;
          Offset maxNow = Offset.zero;
          for (final entry in ptsByGroup.entries) {
            for (final p in entry.value) {
              final o = proj.project(p.lat, p.lon);
              if (!hasAny) {
                minNow = o;
                maxNow = o;
                hasAny = true;
              } else {
                if (o.dx < minNow.dx) minNow = Offset(o.dx, minNow.dy);
                if (o.dy < minNow.dy) minNow = Offset(minNow.dx, o.dy);
                if (o.dx > maxNow.dx) maxNow = Offset(o.dx, maxNow.dy);
                if (o.dy > maxNow.dy) maxNow = Offset(maxNow.dx, o.dy);
              }
            }
          }
          if (hasAny) {
            final w = (maxNow.dx - minNow.dx).abs();
            final h = (maxNow.dy - minNow.dy).abs();
            if (w > 0 && h > 0) {
              wb = Rect.fromLTWH(minNow.dx, minNow.dy, w, h);
            }
          }
        }

        if (borderPtsMap.isNotEmpty) {
          includeGroupBounds(borderPtsMap);
        } else if (partitionPtsMap.isNotEmpty) {
          includeGroupBounds(partitionPtsMap);
        }
        _worldBounds = wb;

        // One-time home fit at first build.
        if (!_didHomeFit) {
          _recomputeHome();
          _didHomeFit = true;
        }

        return Stack(
          children: [
            Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              behavior: HitTestBehavior.opaque,
              child: CustomPaint(
                key: ValueKey(
                  '${_xform.rotRad.toStringAsFixed(3)}:'
                  '${_xform.scale.toStringAsFixed(3)}:'
                  '${_xform.tx.toStringAsFixed(1)}:'
                  '${_xform.ty.toStringAsFixed(1)}',
                ),
                painter: MapPainter(
                  projection: proj,
                  borderGroups: borderGroupsVal,
                  partitionGroups: partitionGroupsVal,
                  borderPointsByGroup: borderPtsMap,
                  partitionPointsByGroup: partitionPtsMap,
                  ref: ref,
                  gps: gps,
                  xform: _xform,
                ),
                child: const SizedBox.expand(),
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'java_zoom_in',
                    onPressed: () {
                      _xform.applyZoom(
                        math.log(1.12),
                        pivotW: _worldBounds.center,
                        pivotS: Offset(
                          _viewSize.width / 2,
                          _viewSize.height / 2,
                        ),
                      );
                      _xform.clampPan(
                        worldBounds: _worldBounds,
                        view: _viewSize,
                      );
                      setState(() {});
                    },
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'java_zoom_out',
                    onPressed: () {
                      _xform.applyZoom(
                        math.log(1 / 1.12),
                        pivotW: _worldBounds.center,
                        pivotS: Offset(
                          _viewSize.width / 2,
                          _viewSize.height / 2,
                        ),
                      );
                      _xform.clampPan(
                        worldBounds: _worldBounds,
                        view: _viewSize,
                      );
                      setState(() {});
                    },
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton.small(
                    heroTag: 'java_rot_left',
                    onPressed: () {
                      _xform.applyRotate(
                        -5 * math.pi / 180.0,
                        pivotW: _worldBounds.center,
                        pivotS: Offset(
                          _viewSize.width / 2,
                          _viewSize.height / 2,
                        ),
                      );
                      _xform.clampPan(
                        worldBounds: _worldBounds,
                        view: _viewSize,
                      );
                      setState(() {});
                    },
                    child: const Icon(Icons.rotate_left),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'java_rot_right',
                    onPressed: () {
                      _xform.applyRotate(
                        5 * math.pi / 180.0,
                        pivotW: _worldBounds.center,
                        pivotS: Offset(
                          _viewSize.width / 2,
                          _viewSize.height / 2,
                        ),
                      );
                      _xform.clampPan(
                        worldBounds: _worldBounds,
                        view: _viewSize,
                      );
                      setState(() {});
                    },
                    child: const Icon(Icons.rotate_right),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton.small(
                    heroTag: 'java_home',
                    onPressed: () {
                      _recomputeHome();
                    },
                    child: const Icon(Icons.home),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
