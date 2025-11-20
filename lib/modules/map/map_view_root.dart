import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'java_style/java_style_map_view.dart';

/// BM-300: use pure Java-style 2-finger engine (no PhotoView).
/// - 1 finger: no geometry (reserved for taps/objects later).
/// - 2 fingers: pan + zoom + rotate via TransformModel & MapPainter.
class MapViewRoot extends ConsumerWidget {
  const MapViewRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('[J2] MapViewRoot → JavaStyleMapView ACTIVE');
    return const JavaStyleMapView();
  }
}
