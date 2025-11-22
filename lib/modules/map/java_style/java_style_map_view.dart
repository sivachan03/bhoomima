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
  /// Gesture semantics & logging expectations (BM-300.4):
  /// - Engine only activates when TWO pointers are down simultaneously.
  /// - Logs show `count=1` for single-finger interactions; these are ignored for geometry.
  /// - For a valid 2-finger gesture we expect sequence:
  ///     [J2] down id=.. count=1
  ///     [J2] down id=.. count=2   <-- second finger
  ///     [J2] move id=.. update=TwoFingerUpdate(...)
  ///     [J2] apply pan=(..) scaleFactor=.. dθ=.. → T=(..)..
  /// - If `count` never reaches 2, TransformModel won't change via gestures.
  /// - Use a real multi-touch source (device/emulator multi-touch) to generate 2-pointer events.
  /// - HUD (top-left) shows live S/T/R so non-changing values confirm no engine activation.
  // Tuned deadzones: higher minScaleChange reduces unintended zoom on light pan.
  final _engine = TwoFingerGestureEngine(
    minScaleChange:
        0.010, // was 0.002 (0.2%), now 1.0% per frame before zoom engages
    rotationDeadZone: 0.005, // was 0.003 (~0.17°), now ~0.29°
  );
  final Map<int, Offset> _pointers = {};
  late TransformModel _xform; // runtime mutable transform
  Rect _worldBounds = Rect.zero; // starts with no bounds until data projects
  Size _viewSize = Size.zero;
  bool _didHomeFit = false;

  /// Startup visual note:
  /// The initial "red cross" the user sees is likely a placeholder/error visual
  /// from MapPainter when there is no map data yet (groups empty). Once providers
  /// deliver data, we log the home fit and repaint with real geometry. This is
  /// distinct from gesture activation; a red cross followed by a successful
  /// `[J2] home → data ready;` means data arrived and transform was applied.

  @override
  void initState() {
    super.initState();
    _xform = TransformModel(suppressLogs: false);
  }

  void _recomputeHome() {
    // BM-300.10: Manual home fit (replace TransformModel.homeTo) so math is explicit.
    if (_viewSize.isEmpty) return;
    if (_worldBounds.width <= 0 || _worldBounds.height <= 0) return;

    const double marginFrac = 0.08; // slightly tighter than previous 0.12
    final double vw = _viewSize.width;
    final double vh = _viewSize.height;
    final double availW = vw * (1.0 - 2 * marginFrac);
    final double availH = vh * (1.0 - 2 * marginFrac);
    if (availW <= 0 || availH <= 0) return;

    final double sx = availW / _worldBounds.width;
    final double sy = availH / _worldBounds.height;
    final double scale = math.min(sx, sy);

    final Offset worldCenter = _worldBounds.center;
    _xform.scale = scale;
    _xform.rotRad = 0.0;
    _xform.tx = vw / 2.0 - worldCenter.dx * scale;
    _xform.ty = vh / 2.0 - worldCenter.dy * scale;

    debugPrint(
      '[J2] homeFit manual scale=${scale.toStringAsFixed(4)} centerW=(${worldCenter.dx.toStringAsFixed(1)},${worldCenter.dy.toStringAsFixed(1)}) T=(${_xform.tx.toStringAsFixed(1)},${_xform.ty.toStringAsFixed(1)})',
    );
    setState(() {});
  }

  void _applyTwoFinger(TwoFingerUpdate u) {
    if (u == TwoFingerUpdate.zero) return;
    applyTwoFingerUpdateToTransform(_xform, u);
    // TEMP BM-300.6: disable clamping while debugging gesture math.
    // _xform.clampPan(worldBounds: _worldBounds, view: _viewSize);
    setState(() {});
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    debugPrint(
      '[J2] down id=${e.pointer} pos=${e.localPosition} '
      'count=${_pointers.length}',
    );
    debugPrint(
      '[J2] down kind=${e.kind} device=${e.device} pointer=${e.pointer}',
    );
    if (_pointers.length == 2) {
      debugPrint(
        '[J2] second finger detected; engine should activate on next move',
      );
    }
    _engine.onPointerDown(e.pointer, e.localPosition, _pointers);
  }

  void _onPointerMove(PointerMoveEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_engine.isActive) {
      // True 2-finger gesture in progress: pan + zoom + rotate.
      final update = _engine.onPointerMove(_pointers);
      debugPrint('[J2] move id=${e.pointer} update=$update');
      _applyTwoFinger(update);
    } else {
      if (_pointers.length == 1) {
        // TEMP BM-300.5: allow simple 1-finger pan so map is not dead.
        final dx = e.delta.dx;
        final dy = e.delta.dy;
        _xform.tx += dx;
        _xform.ty += dy;
        // TEMP BM-300.6: disable clamping to observe raw translation.
        // _xform.clampPan(worldBounds: _worldBounds, view: _viewSize);
        debugPrint(
          '[J2] one-finger pan dx=${dx.toStringAsFixed(2)} '
          'dy=${dy.toStringAsFixed(2)} → '
          'T=(${_xform.tx.toStringAsFixed(1)},${_xform.ty.toStringAsFixed(1)})',
        );
        setState(() {});
      } else {
        // 0 or >2 pointers but engine not active: ignore for geometry.
        debugPrint(
          '[J2] move id=${e.pointer} ignored '
          '(active=${_engine.isActive}, count=${_pointers.length})',
        );
        if (_pointers.length == 2) {
          // Two pointers present but engine inactive: likely emulator not producing distinct multi-touch stream.
          final entries = _pointers.entries
              .map(
                (e2) =>
                    '#${e2.key}@(${e2.value.dx.toStringAsFixed(1)},${e2.value.dy.toStringAsFixed(1)})',
              )
              .join(', ');
          debugPrint(
            '[J2] WARN two pointers tracked but engine inactive; positions: $entries',
          );
        }
      }
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    debugPrint(
      '[J2] up id=${e.pointer} before-remove count=${_pointers.length}',
    );
    _engine.onPointerUpOrCancel(e.pointer, _pointers);
    debugPrint(
      '[J2] up id=${e.pointer} after-remove count=${_pointers.length}',
    );
  }

  void _onPointerCancel(PointerCancelEvent e) {
    debugPrint(
      '[J2] cancel id=${e.pointer} before-remove count=${_pointers.length}',
    );
    _engine.onPointerUpOrCancel(e.pointer, _pointers);
    debugPrint(
      '[J2] cancel id=${e.pointer} after-remove count=${_pointers.length}',
    );
  }

  Widget _buildDebugHud() {
    return Positioned(
      left: 8,
      top: 8,
      child: Container(
        padding: const EdgeInsets.all(6),
        color: Colors.black.withOpacity(0.5),
        child: Text(
          'S=${_xform.scale.toStringAsFixed(2)} '
          'T=(${_xform.tx.toStringAsFixed(0)},${_xform.ty.toStringAsFixed(0)}) '
          'R=${(_xform.rotRad * 180 / math.pi).toStringAsFixed(1)}° '
          'P=${_pointers.length} active=${_engine.isActive}',
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ),
    );
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
        Rect wb =
            Rect.zero; // accumulate real projected bounds when data arrives
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
        debugPrint(
          '[J2] worldBounds w=${_worldBounds.width.toStringAsFixed(1)} h=${_worldBounds.height.toStringAsFixed(1)} at (${_worldBounds.left.toStringAsFixed(1)},${_worldBounds.top.toStringAsFixed(1)}) view=(${_viewSize.width.toStringAsFixed(1)}x${_viewSize.height.toStringAsFixed(1)})',
        );

        // Home gating now purely bounds-based (BM-300.11): run once when bounds become valid.
        final hasBounds =
            _worldBounds.width > 0 &&
            _worldBounds.height > 0 &&
            _worldBounds.left.isFinite &&
            _worldBounds.top.isFinite;
        if (!_didHomeFit && hasBounds) {
          debugPrint(
            '[J2] home → bounds ready; performing initial fit (w=${_worldBounds.width.toStringAsFixed(1)} h=${_worldBounds.height.toStringAsFixed(1)})',
          );
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
            _buildDebugHud(),
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
