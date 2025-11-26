import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modules/map/java_style/java_style_map_view.dart';
import '../pointer_sniffer.dart';

/// BM-300-FS: Absolute full-screen map (no app bars, no bottom bars) to
/// validate true two-finger hit-testing entirely inside map bounds.
class FullscreenMapPage extends ConsumerWidget {
  const FullscreenMapPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: PassivePointerSniffer(
        tag: 'mapRoot',
        child: JavaStyleMapView(hideOverlays: true),
      ),
    );
  }
}
