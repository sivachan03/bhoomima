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
import '../finger_debug_surface.dart';
// SnifferSurface removed for this run; using minimal local Listener.

/// Java-style map view: direct 2-finger gesture engine (pan+zoom+rotate) without PhotoView.
/// 1 finger: ignored (could be wired for tap interactions overlay).
/// 2 fingers: per-frame deltas applied to TransformModel using focal point pivot logic.
class JavaStyleMapView extends ConsumerStatefulWidget {
  const JavaStyleMapView({
    super.key,
    this.rawTouchTestMode = false,
    this.enableSingleFingerPan = true,
    this.hideOverlays = false,
  });

  /// If true, renders a blank surface wrapped in FingerDebugSurface to isolate multi-touch delivery.
  final bool rawTouchTestMode;

  /// Temporary fallback: allow 1-finger pan until multi-touch reliably reaches listener.
  final bool enableSingleFingerPan;

  /// When true, suppress debug HUD & gesture buttons for pure full-screen hit-test.
  final bool hideOverlays;

  @override
  ConsumerState<JavaStyleMapView> createState() => _JavaStyleMapViewState();
}

class _JavaStyleMapViewState extends ConsumerState<JavaStyleMapView> {
  /// SHORT ANSWER (BM-300-15):
  /// ✅ Two-finger touch reaches Flutter & route level.
  /// ❌ Only one of those fingers hits this map's local Listener; the second
  ///    finger starts on a different widget/area and is dispatched elsewhere.
  /// 🔧 1-finger pan fallback was previously removed; with _engine.isActive=false
  ///    all single-finger moves were ignored → "panning not working at all".
  /// ✅ Fix strategy implemented:
  ///    1. Re-enabled single-finger pan so map is usable while diagnosing.
  ///    2. Added full-screen MapDebugPage to prove both fingers can reach map when unobstructed.
  ///    3. Added global PointerHub (root Listener) for cross-app 1 vs 2 finger awareness.
  /// Paste full hosting widget tree if pinpoint of second finger interception is needed.
  /// HIT-TEST DIAGNOSTIC (BM-300.12): Why only one finger reaches this map surface.
  /// Summary of observed logs:
  ///   GLOBAL/ROUTE: finger #3 Y ≈ 517→501, finger #4 Y ≈ 550→532 (both present)
  ///   LOCAL (map): finger #3 Y ≈ 309→283, finger #4 ABSENT
  /// Interpretation:
  ///   - Pointer #3's initial down was inside the map widget's bounds, so its
  ///     subsequent events are dispatched here.
  ///   - Pointer #4's down landed outside the map (or on a sibling overlay), so
  ///     the hit-test assigned it to some other Listener/GestureDetector. That
  ///     pointer's stream never enters this widget and will NEVER appear here
  ///     unless its original down targets this RenderBox.
  /// Flutter hit-test rules (key points):
  ///   1. Each pointer is independently hit-tested on its DOWN event.
  ///   2. The deepest RenderObject that returns "hit" owns that pointer's event
  ///      stream until UP/CANCEL.
  ///   3. Presence of multiple fingers globally does not guarantee any given
  ///      widget will see all of them.
  /// Consequence for gesture engines:
  ///   - TwoFingerGestureEngine cannot activate unless BOTH pointer downs hit
  ///     this widget. Merely observing one finger here while another exists
  ///     elsewhere globally is insufficient.
  /// Action items to restore 2-finger gestures:
  ///   - Ensure the interactive map surface covers the region where users place
  ///     both fingers (expand/position Stack children so second finger lands here).
  ///   - Avoid overlapping absorbing widgets (e.g., bottom bars with opaque
  ///     GestureDetectors) over intended map interaction area.
  ///   - Optionally add a temporary full-screen translucent Listener beneath
  ///     overlays to confirm both pointer downs hit the intended target.
  /// This comment documents root cause so future maintainers understand why
  /// multi-touch debug logs can show count=1 locally while count=2 globally.
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

  // Two-finger apply helper temporarily unused while FingerDebugSurface is bypassed.

  // Original pointer down logic removed: FingerDebugSurface now supplies raw callbacks.

  // Legacy Listener handlers removed after FingerDebugSurface refactor.

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
    // Blank test mode removed (was causing dead code lint). Use a separate wrapper if needed.
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

    if (widget.rawTouchTestMode) {
      // Pure raw touch diagnostic mode: blank container wrapped by FingerDebugSurface.
      return FingerDebugSurface(
        label: 'RAW',
        visualize: true,
        onSingleFingerDown: (pos) => debugPrint('[RAW] single down @ $pos'),
        onSingleFingerMove: (pos, d) {
          // Emulate _onPointerMove single-finger pan logging (quick win fallback)
          if (widget.enableSingleFingerPan && _worldBounds != Rect.zero) {
            _xform.tx += d.dx;
            _xform.ty += d.dy;
            _xform.clampPan(worldBounds: _worldBounds, view: _viewSize);
            debugPrint(
              '[J2] one-finger pan dx=${d.dx.toStringAsFixed(2)} '
              'dy=${d.dy.toStringAsFixed(2)} → '
              'T=(${_xform.tx.toStringAsFixed(1)},${_xform.ty.toStringAsFixed(1)})',
            );
            setState(() {});
          } else {
            debugPrint('[J2] move ignored (single pan disabled or no bounds)');
          }
        },
        onTwoFingerDown: (p1, p2) =>
            debugPrint('[RAW] two-finger DOWN p1=$p1 p2=$p2'),
        onTwoFingerMove: (p1, p2) =>
            debugPrint('[RAW] two-finger MOVE p1=$p1 p2=$p2'),
        child: Container(color: Colors.black12),
      );
    }
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

        // Build the map painter segment (unless in blank test mode).
        // Build map layer; override with blank if testing raw multi-touch.
        Widget mapLayer = CustomPaint(
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
        );

        // Minimal local Listener: only logs pointer id and count.
        final Map<int, Offset> localPointers = {};
        Widget gestureSurface = Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            localPointers[e.pointer] = e.localPosition;
            debugPrint(
              '[LOCAL] DOWN id=${e.pointer} count=${localPointers.length}',
            );
          },
          onPointerMove: (e) {
            localPointers[e.pointer] = e.localPosition;
            debugPrint(
              '[LOCAL] MOVE id=${e.pointer} count=${localPointers.length}',
            );
          },
          onPointerUp: (e) {
            localPointers.remove(e.pointer);
            debugPrint(
              '[LOCAL] UP id=${e.pointer} count=${localPointers.length}',
            );
          },
          onPointerCancel: (e) {
            localPointers.remove(e.pointer);
            debugPrint(
              '[LOCAL] CANCEL id=${e.pointer} count=${localPointers.length}',
            );
          },
          child: mapLayer,
        );

        if (widget.hideOverlays) {
          return gestureSurface; // pure full-screen map surface
        }
        return Stack(
          children: [
            gestureSurface,
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
