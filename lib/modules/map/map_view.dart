import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/current_property.dart';
import 'map_providers.dart';
import '../../core/services/gps_service.dart';
import '../../core/services/compass_service.dart';
import '../../core/services/projection_service.dart';
import 'map_painter.dart';

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
    final gps = ref.watch(gpsStreamProvider);
    final heading = ref.watch(compassStreamProvider);

    final lat0 = gps.value?.position.latitude ?? 0.0;
    final lon0 = gps.value?.position.longitude ?? 0.0;
    final proj = ProjectionService(lat0, lon0);

    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: Stack(
        children: [
          GestureDetector(
            onScaleUpdate: (d) {
              setState(() {
                _scale = (_scale * d.scale).clamp(0.2, 20.0);
                _rotation += d.rotation;
                _pan += d.focalPointDelta;
              });
            },
            child: CustomPaint(
              painter: MapPainter(
                projection: proj,
                pan: _pan,
                scale: _scale,
                rotation: _rotation,
                borderGroups: borders.value ?? const [],
                ref: ref,
                gps: gps.value,
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: _CompassBadge(headingDeg: heading.value),
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

class _CompassBadge extends StatelessWidget {
  const _CompassBadge({required this.headingDeg});
  final double? headingDeg;
  @override
  Widget build(BuildContext context) {
    final h = headingDeg ?? 0;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Transform.rotate(
        angle: -h * 3.1415926535 / 180.0,
        child: const Icon(Icons.navigation, size: 28, color: Colors.white),
      ),
    );
  }
}
