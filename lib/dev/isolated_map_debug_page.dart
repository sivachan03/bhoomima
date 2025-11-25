import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/map/java_style/java_style_map_view.dart';
import '../pointer_sniffer.dart';

/// Isolated full-screen map debug page (BM-300-ISO1)
/// Purpose: Structural isolation to verify whether both pointer downs
/// reach the map when no other parents or overlays are present.
/// Composition:
///   Scaffold.body = PointerSniffer(tag:'mapRoot', child: JavaStyleMapView())
/// NO overlays, NO global pointer HUD, NO extra Stack.
class IsolatedMapDebugPage extends ConsumerWidget {
  const IsolatedMapDebugPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: PointerSniffer(
        tag: 'mapRoot',
        child: JavaStyleMapView(hideOverlays: true),
      ),
    );
  }
}
