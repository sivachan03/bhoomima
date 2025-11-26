import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/vocab/vocab_repo.dart';
import 'core/ui/shell_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/bootstrap/ensure_default_property.dart';
import 'modules/filter/filter_persistence.dart';
import 'modules/properties/property_create_screen.dart';
import 'modules/properties/properties_screen.dart';
import 'modules/map/farm_map_view.dart';
import 'modules/map/bm_200r_demo_view.dart';
import 'modules/map/bm_200r_map_screen.dart';
import 'dev/pointer_lab_page.dart';
import 'dev/map_debug_page.dart';
import 'dev/isolated_map_debug_page.dart';
import 'dev/fullscreen_map_page.dart';
import 'pointer_hub.dart';
import 'dev/two_finger_test_page.dart';

class BhoomiMaApp extends ConsumerWidget {
  // Optional boot override for tests to avoid starting background timers/IO.
  final Future<void> Function(WidgetRef ref)? boot;
  const BhoomiMaApp({super.key, this.boot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Boot sequence: ensure default property + load persisted filters
    final boot = this.boot != null
        ? this.boot!(ref)
        : Future<void>(() async {
            await ensureDefaultProperty(ref);
            await ref.read(filterPersistence).load();
          });
    return FutureBuilder<void>(
      future: boot,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        // BM-300 flicker fix: do NOT watch pointerHubProvider here; watching causes
        // MaterialApp + entire home subtree to rebuild on every pointer move.
        // We only need the instance for the Listener callbacks, so use read.
        final hub = ref.read(pointerHubProvider);
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appName,
          routes: {
            '/property/create': (ctx) => const PropertyCreateScreen(),
            '/properties': (ctx) => const PropertiesScreen(),
            // Developer route to test MatrixGestureDetector-based sample view
            '/dev/farm': (ctx) => const FarmMapView(),
            // BM-200R: simplified 2-finger pan+zoom layer demo
            '/dev/bm200r': (ctx) => const BM200RDemoView(),
            // BM-200R: integrated with stub farm painter
            '/dev/bm200r/map': (ctx) => const BM200RMapScreen(),
            // Dev: full-screen raw pointer lab
            '/dev/pointer-lab': (ctx) => const PointerLabPage(),
            '/dev/map-debug': (ctx) => const MapDebugPage(),
            '/dev/map-isolated': (ctx) => const IsolatedMapDebugPage(),
            '/dev/map-fullscreen': (ctx) => const FullscreenMapPage(),
            '/dev/two-finger-test': (ctx) => const TwoFingerTestPage(),
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          // If the device locale is Malayalam (ml) we show ml; otherwise English.
          // You can expose a Settings toggle later.
          localeResolutionCallback: (locale, supported) {
            if (locale == null) return const Locale('en');
            for (final l in supported) {
              if (l.languageCode == locale.languageCode) return l;
            }
            // Default to Malayalam build if available, else English
            return const Locale('ml');
          },
          theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
          // Wrap home + routes with a translucent Listener to feed PointerHub
          builder: (context, child) {
            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: hub.onEvent,
              onPointerMove: hub.onEvent,
              onPointerUp: hub.onEvent,
              onPointerCancel: hub.onEvent,
              child: child!,
            );
          },
          home: const VocabBoot(child: ShellScaffold()),
        );
      },
    );
  }
}
