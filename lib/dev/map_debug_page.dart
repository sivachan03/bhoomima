import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/map/java_style/java_style_map_view.dart';
import '../pointer_hub.dart';

/// Full-screen debug page to validate multi-touch delivery to JavaStyleMapView
/// without interference from other interactive overlays.
class MapDebugPage extends ConsumerWidget {
  const MapDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hub = ref.watch(pointerHubProvider);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.yellow.withOpacity(0.15),
            child: const JavaStyleMapView(),
          ),
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'GLOBAL pointers=${hub.count}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
