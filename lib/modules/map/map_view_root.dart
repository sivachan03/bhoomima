import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'branch_b_map_view.dart';
import 'map_view.dart';
import 'map_painter.dart';
import '../../core/services/projection_service.dart';
import '../../core/models/point_group.dart';
import 'transform_model.dart';

/// MapViewRoot: runtime toggle between legacy BM-200R MapViewScreen (Branch A)
/// and experimental PhotoView-based BranchBMapView (Branch B).
///
/// Integration strategy:
/// - Keep existing MapViewScreen untouched (Branch A).
/// - Provide a small builder wrapper for Branch B that mirrors the canvas
///   painting (MapPainter + overlays) in a neutral/home transform.
/// - Branch B does NOT mutate TransformModel; PhotoView drives its own state.
class MapViewRoot extends ConsumerWidget {
  const MapViewRoot({super.key, this.useBranchB = true});
  final bool useBranchB; // flip to true to try PhotoView branch

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!useBranchB) {
      return const MapViewScreen();
    }
    debugPrint('[PV] BranchBMapView ACTIVE');

    // Branch B content builder: this should replicate what MapViewScreen paints
    // WITHOUT reading gesture transforms from the SM/TransformModel. For now, we
    // instantiate a fresh TransformModel in "home" state (tx=ty=0, scale=1, rot=0).
    // If you have world bounds fitting logic, integrate it here later.
    final TransformModel homeXform = TransformModel(suppressLogs: true);

    return BranchBMapView(
      mapChildBuilder: (Size size) {
        // TODO: fetch same data sets as MapViewScreen via providers if needed.
        // Minimal placeholder: empty paint background.
        // To fully mirror Branch A, inject ProjectionService & point groups.
        // TODO: supply real projection & data (copy from MapViewScreen providers)
        final projection = ProjectionService(
          0.0,
          0.0,
        ); // placeholder origin; inject real service later
        return CustomPaint(
          painter: MapPainter(
            projection: projection,
            xform: homeXform,
            borderGroups: const <PointGroup>[],
            partitionGroups: const <PointGroup>[],
            borderPointsByGroup: const {},
            partitionPointsByGroup: const {},
            ref: ref,
            gps: null,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
