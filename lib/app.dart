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

class BhoomiMaApp extends ConsumerWidget {
  const BhoomiMaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Boot sequence: ensure default property + load persisted filters
    final boot = Future<void>(() async {
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
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appName,
          routes: {
            '/property/create': (ctx) => const PropertyCreateScreen(),
            '/properties': (ctx) => const PropertiesScreen(),
            // Developer route to test MatrixGestureDetector-based sample view
            '/dev/farm': (ctx) => const FarmMapView(),
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
          home: const VocabBoot(child: ShellScaffold()),
        );
      },
    );
  }
}
