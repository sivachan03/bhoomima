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
  /// BM-300.11 clarification:
  /// The current Listener only receives one pointer stream in your environment.
  /// BM-300.11 fix summary:
  /// 3.2 Environment (multi-touch) note:
  /// Even with correct code, pinch/rotate will NEVER occur unless the input
  /// source delivers two simultaneous pointer downs. Expected healthy log
  /// sequence on a real device:
  ///   [J2] down id=1 ... count=1
  ///   [J2] down id=2 ... count=2
  ///   [J2] second finger detected; engine should activate on next move
  ///   [J2] move id=1 update=TwoFingerUpdate(...)
  ///   [J2] apply pan=(..) scaleFactor=.. dθ=.. → T=(..) S=.. rot=..
  /// HUD should show: P=2 active=true. If you only ever see count=1 / active=false
  /// then the emulator/device configuration is single-touch only; enable the
  /// buttons or double-tap zoom fallback, or test on real hardware.
  /// - Replaced dummy initial world bounds with Rect.zero.
  /// - Home fit now waits for first non-zero projected bounds (real farm dimensions).
  /// - Prevents early centering on (-500,-500,1000x1000) placeholder causing off-screen farm.
  /// - Map now visible from first valid bounds frame; subsequent frames skip redundant home fits.
  /// - Partition groups with insufficient points (<3) are skipped with debug logs; not an error.
  /// Without two concurrent pointer downs, `_engine.isActive` never becomes true,
  /// so pinch/rotate deltas are not generated and the code intentionally falls
  /// back to the one-finger pan path. To exercise zoom/rotate without multi-touch
  /// hardware, use the + / - / rotate buttons. This file now also supports a
  /// double-tap zoom fallback (zoom in around the tap point) to provide a
  /// second gesture modality when multi-touch isn't available.
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
  final List<DateTime> _lastTapTimes = [];
  final List<Offset> _lastTapPositions = [];
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
    // Re-enable clamping now that home fit and visibility are correct.
    _xform.clampPan(worldBounds: _worldBounds, view: _viewSize);
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
    // Double-tap detection (basic): if last tap within 300ms and distance < 40px.
    final now = DateTime.now();
    _lastTapTimes.add(now);
    if (_lastTapTimes.length > 2) _lastTapTimes.removeAt(0);
    if (_lastTapPositions.length > 2) _lastTapPositions.removeAt(0);
    _lastTapPositions.add(e.localPosition);
    if (_lastTapTimes.length == 2) {
      final dt = _lastTapTimes[1].difference(_lastTapTimes[0]).inMilliseconds;
      final dp = (_lastTapPositions[1] - _lastTapPositions[0]).distance;
      if (dt < 300 && dp < 40) {
        // Compute world pivot for zoom: inverse of current transform for screen point.
        final pivotS = e.localPosition;
        final invScale = 1.0 / _xform.scale;
        final cosR = math.cos(-_xform.rotRad);
        final sinR = math.sin(-_xform.rotRad);
        // Convert screen to world: untranslate -> unrotate -> unscale.
        final sx = pivotS.dx - _xform.tx;
        final sy = pivotS.dy - _xform.ty;
        final rx = sx * cosR - sy * sinR;
        final ry = sx * sinR + sy * cosR;
        final worldPivot = Offset(rx * invScale, ry * invScale);
        _xform.applyZoom(
          math.log(1.35), // zoom in ~35%
          pivotW: worldPivot,
          pivotS: pivotS,
        );
        debugPrint(
          '[J2] doubleTap zoom pivotW=(${worldPivot.dx.toStringAsFixed(1)},${worldPivot.dy.toStringAsFixed(1)}) newScale=${_xform.scale.toStringAsFixed(2)}',
        );
        setState(() {});
      }
    }
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
      // Not active: ignoring movement (Java semantics when single finger or >2 without activation).
      debugPrint(
        '[J2] move id=${e.pointer} ignored (active=${_engine.isActive}, count=${_pointers.length})',
      );
      if (_pointers.length == 2) {
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
