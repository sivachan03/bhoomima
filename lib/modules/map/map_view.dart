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

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});
  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  Offset _pan = Offset.zero;
  double _scale = 1.0;
  double _rotation = 0.0;

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(activePropertyProvider);
    final prop = active.asData?.value;
    final borders = ref.watch(borderGroupsProvider);
    final partitions = ref.watch(partitionGroupsProvider);
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
            onScaleUpdate: (d) {
              setState(() {
                _scale = (_scale * d.scale).clamp(0.2, 20.0);
                _rotation += d.rotation;
                _pan += d.focalPointDelta;
              });
            },
            onDoubleTap: () {
              setState(() {
                _pan = Offset.zero;
                _scale = 1.0;
                _rotation = 0.0;
              });
            },
            child: CustomPaint(
              painter: MapPainter(
                projection: proj,
                pan: _pan,
                scale: _scale,
                rotation: _rotation,
                borderGroups: borders.value ?? const [],
                partitionGroups: partitions.value ?? const [],
                ref: ref,
                gps: gps.value,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          // Always-on partitions overlay (pastel fill + outline)
          if (prop != null)
            Positioned.fill(
              child: IgnorePointer(
                child: PartitionOverlay(
                  propertyId: prop.id,
                  project: (lat, lon) => proj.project(lat, lon),
                  worldBounds: Rect.largest,
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
}

// (compass badge widget moved to inline Transform for simplicity)
