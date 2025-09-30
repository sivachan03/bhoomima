import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app_state/active_property.dart';
import 'map_providers.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/compass_service.dart';
import '../../core/services/projection_service.dart';
import 'map_painter.dart';
import 'partition_overlay.dart';
import '../filter/global_filter.dart';
import 'map_view_controller.dart';
import 'map_points_aggregate.dart';
import '../../core/models/point_group.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});
  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  Offset _pan = Offset.zero;
  double _scale = 1.0;
  double _rotation = 0.0;
  // Gesture start baselines
  double _startScale = 1.0;
  double _startRotation = 0.0;
  Offset _startPan = Offset.zero;
  bool _didFit = false; // one-shot auto-fit guard
  int? _lastPropertyId; // reset fit when property changes

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activePropertyProvider);
    final prop = active.asData?.value;
    if (prop?.id != _lastPropertyId) {
      // Property changed: allow a fresh auto-fit
      _lastPropertyId = prop?.id;
      _didFit = false;
    }
    final borders = ref.watch(borderGroupsProvider);
    final partitions = ref.watch(partitionGroupsProvider);
    final borderGroupsVal = borders.value ?? const <PointGroup>[]; // typed list
    final partitionGroupsVal =
        partitions.value ?? const <PointGroup>[]; // typed list
    // Aggregate points in the widget layer via provider so painter is pure
    final borderPtsMap = ref.watch(
      pointsByGroupsReadyProvider(borderGroupsVal),
    );
    final partitionPtsMap = ref.watch(
      pointsByGroupsReadyProvider(partitionGroupsVal),
    );
    final gps = ref.watch(gpsStreamProvider);
    final heading = ref.watch(compassStreamProvider);
    // Projection origin priority: property.lat/lon -> originLat/originLon -> GPS -> (0,0)
    double lat0 = 0.0, lon0 = 0.0;
    if (prop != null) {
      if (prop.lat != null && prop.lon != null) {
        lat0 = prop.lat!;
        lon0 = prop.lon!;
      } else if (prop.originLat != null && prop.originLon != null) {
        lat0 = prop.originLat!;
        lon0 = prop.originLon!;
      }
    }
    // Data-derived fallback: if still (0,0) and border groups exist, use the centroid of border points
    if ((lat0 == 0.0 && lon0 == 0.0) && (borders.value?.isNotEmpty ?? false)) {
      double sLat = 0.0, sLon = 0.0;
      int n = 0;
      for (final g in borders.value!) {
        final ptsAsync = ref.read(pointsByGroupProvider(g.id));
        final pts = ptsAsync.asData?.value ?? const [];
        for (final p in pts) {
          sLat += p.lat;
          sLon += p.lon;
          n++;
        }
      }
      if (n > 0) {
        lat0 = sLat / n;
        lon0 = sLon / n;
      }
    }
    if (lat0 == 0.0 && lon0 == 0.0) {
      lat0 = gps.value?.position.latitude ?? 0.0;
      lon0 = gps.value?.position.longitude ?? 0.0;
    }
    final proj = ProjectionService(lat0, lon0);

    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            onScaleStart: (d) {
              _startScale = _scale;
              _startRotation = _rotation;
              _startPan = _pan;
            },
            onScaleUpdate: (d) {
              setState(() {
                _scale = (_startScale * d.scale).clamp(0.2, 20.0);
                _rotation = _startRotation + d.rotation;
                // Simple pan using per-frame delta; for start-based pan, accumulate if needed
                _pan = _startPan + d.focalPointDelta;
                _didFit = true; // user interacted; disable auto-fit
              });
              // publish to controller
              ref
                  .read(mapViewController)
                  .update(pan: _pan, scale: _scale, rotation: _rotation);
            },
            onDoubleTap: () {
              setState(() {
                _pan = Offset.zero;
                _scale = 1.0;
                _rotation = 0.0;
                _didFit = true; // user explicitly reset view
              });
              ref
                  .read(mapViewController)
                  .update(pan: _pan, scale: _scale, rotation: _rotation);
            },
            child: LayoutBuilder(
              builder: (_, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                // Trigger one-shot auto-fit after first layout/data
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitOnce(size, proj);
                });
                return CustomPaint(
                  painter: MapPainter(
                    projection: proj,
                    pan: _pan,
                    scale: _scale,
                    rotation: _rotation,
                    borderGroups: borderGroupsVal,
                    partitionGroups: partitionGroupsVal,
                    borderPointsByGroup: borderPtsMap,
                    partitionPointsByGroup: partitionPtsMap,
                    ref: ref,
                    gps: gps.value,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          // Always-on partitions overlay (pastel fill + outline)
          if (prop != null)
            Positioned.fill(
              child: IgnorePointer(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    final center = Offset(size.width / 2, size.height / 2);
                    final ctrl = ref.watch(mapViewController);
                    // Build the same view transform as MapPainter: translate(center + pan) -> rotate -> scale
                    final matrix = Matrix4.identity()
                      ..translate(
                        center.dx + ctrl.pan.dx,
                        center.dy + ctrl.pan.dy,
                      )
                      ..rotateZ(ctrl.rotation)
                      ..scale(ctrl.scale);
                    return Transform(
                      transform: matrix,
                      alignment: Alignment.topLeft,
                      child: Stack(
                        children: [
                          PartitionOverlay(
                            propertyId: prop.id,
                            project: (lat, lon) => proj.project(lat, lon),
                            worldBounds: Rect.largest,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          Positioned(
            right: 12,
            top: 12,
            child: Transform.rotate(
              angle: (heading.value ?? 0) * 3.1415926535 / 180.0,
              child: const Icon(
                Icons.navigation,
                size: 28,
                color: Colors.black87,
              ),
            ),
          ),
          if (prop != null)
            Positioned(
              left: 12,
              top: 12,
              child: Chip(label: Text('Property ${prop.name}')),
            ),
          // Zoom buttons (explicit controls)
          Positioned(
            right: 12,
            bottom: 96,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    setState(() {
                      _scale = (_scale * 1.2).clamp(0.2, 20.0);
                      _didFit = true;
                    });
                    ref
                        .read(mapViewController)
                        .update(pan: _pan, scale: _scale, rotation: _rotation);
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    setState(() {
                      _scale = (_scale / 1.2).clamp(0.2, 20.0);
                      _didFit = true;
                    });
                    ref
                        .read(mapViewController)
                        .update(pan: _pan, scale: _scale, rotation: _rotation);
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          // Legend toggle button (dev placement; move to your filters later)
          Positioned(
            right: 12,
            top: 56,
            child: Consumer(
              builder: (_, ref, __) => IconButton.filledTonal(
                icon: Icon(
                  ref.watch(globalFilterProvider).legendVisible
                      ? Icons.legend_toggle
                      : Icons.legend_toggle_outlined,
                ),
                onPressed: () {
                  final s = ref.read(globalFilterProvider);
                  ref.read(globalFilterProvider.notifier).state = s.copyWith(
                    legendVisible: !s.legendVisible,
                  );
                },
                tooltip: 'Toggle legend',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _fitOnce(Size size, ProjectionService proj) {
    // Skip if already fit or user interacted
    if (_didFit) return;
    final bgAsync = ref.read(borderGroupsProvider);
    final groups = bgAsync.asData?.value ?? const [];
    if (groups.isEmpty) return;

    final allPts = <Offset>[];
    for (final g in groups) {
      final pts =
          ref.read(pointsByGroupProvider(g.id)).asData?.value ?? const [];
      for (final p in pts) {
        allPts.add(proj.project(p.lat, p.lon));
      }
    }
    if (allPts.isEmpty) return;

    double minX = allPts.first.dx, maxX = allPts.first.dx;
    double minY = allPts.first.dy, maxY = allPts.first.dy;
    for (final o in allPts) {
      if (o.dx < minX) minX = o.dx;
      if (o.dx > maxX) maxX = o.dx;
      if (o.dy < minY) minY = o.dy;
      if (o.dy > maxY) maxY = o.dy;
    }
    final w = (maxX - minX).abs();
    final h = (maxY - minY).abs();
    if (w <= 0 || h <= 0) return;

    const margin = 24.0;
    final sx = (size.width - margin * 2) / w;
    final sy = (size.height - margin * 2) / h;
    final s = (sx < sy ? sx : sy).clamp(0.2, 20.0);

    final centerWorld = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    // Given translate(center + pan) then scale, to bring world center to screen center with rotation 0:
    // pan should be -centerWorld * s (center will be added by painter's translate)
    final pan = Offset(-centerWorld.dx * s, -centerWorld.dy * s);

    setState(() {
      _scale = s;
      _rotation = 0.0;
      _pan = pan;
      _didFit = true;
    });
    ref
        .read(mapViewController)
        .update(pan: _pan, scale: _scale, rotation: _rotation);
  }
}

// (compass badge widget moved to inline Transform for simplicity)
// (compass badge widget moved to inline Transform for simplicity)
