import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'global_pointer_debug.dart';
import 'pointer_sniffer.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Install global pointer diagnostics (raw multi-touch visibility)
  GlobalPointerDebug.init();

  // Crash trap: forward FlutterError to current Zone for full stack capture
  FlutterError.onError = (FlutterErrorDetails details) {
    Zone.current.handleUncaughtError(
      details.exception,
      details.stack ?? StackTrace.current,
    );
  };

  // Guard the app with a zone to catch uncaught synchronous/async errors
  runZonedGuarded(
    () {
      runApp(
        PassivePointerSniffer(
          tag: 'root',
          child: const ProviderScope(child: BhoomiMaApp()),
        ),
      );
    },
    (error, stack) {
      debugPrint('=== FATAL (zoned) ===\n$error\n$stack');
    },
  );
}
