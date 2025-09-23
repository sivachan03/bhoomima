import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/current_property.dart';
import 'map_providers.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/compass_service.dart';
import '../../core/services/projection_service.dart';
import 'map_painter.dart';
import '../../core/repos/property_repo.dart';

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
    final pid = ref.watch(currentPropertyIdProvider);
    final borders = ref.watch(borderGroupsProvider);
    final partitions = ref.watch(partitionGroupsProvider);
    final gps = ref.watch(gpsStreamProvider);
    final heading = ref.watch(compassStreamProvider);
    final propAsync = pid != null
        ? ref.watch(currentPropertyProvider(pid))
        : null;
    // Projection origin priority: property.lat/lon -> originLat/originLon -> GPS -> (0,0)
    double lat0 = 0.0, lon0 = 0.0;
    final p = propAsync?.value;
    if (p != null) {
      if (p.lat != null && p.lon != null) {
        lat0 = p.lat!;
        lon0 = p.lon!;
      } else if (p.originLat != null && p.originLon != null) {
        lat0 = p.originLat!;
        lon0 = p.originLon!;
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
          if (pid != null)
            Positioned(
              left: 12,
              top: 12,
              child: Chip(label: Text('Property $pid')),
            ),
        ],
      ),
    );
  }
}

// (compass badge widget moved to inline Transform for simplicity)
