import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

/// Global pointer diagnostics: installs a route on the GestureBinding pointerRouter
/// to log ALL pointer events before widget-level gesture recognizers.
///
/// Usage: call GlobalPointerDebug.init() early in main() before runApp().
/// Disable (comment out) for production to avoid verbose logs.
class GlobalPointerDebug {
  static bool _installed = false;
  static final Map<int, Offset> _active = <int, Offset>{};

  static void init() {
    if (_installed) return; // prevent double-install
    WidgetsFlutterBinding.ensureInitialized();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handleEvent);
    _installed = true;
    debugPrint('[GLOBAL] pointer debug installed');
  }

  static void dispose() {
    if (!_installed) return;
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handleEvent);
    _installed = false;
    _active.clear();
    debugPrint('[GLOBAL] pointer debug removed');
  }

  static void _handleEvent(PointerEvent e) {
    if (e is PointerDownEvent) {
      _active[e.pointer] = e.position;
    } else if (e is PointerMoveEvent) {
      if (_active.containsKey(e.pointer)) {
        _active[e.pointer] = e.position;
      }
    } else if (e is PointerUpEvent || e is PointerCancelEvent) {
      _active.remove(e.pointer);
    }

    final count = _active.length;
    final activeStr = _active.entries
        .map(
          (e2) =>
              '#${e2.key}@(${e2.value.dx.toStringAsFixed(1)},${e2.value.dy.toStringAsFixed(1)})',
        )
        .join(', ');

    debugPrint(
      '[GLOBAL] ${e.runtimeType} id=${e.pointer} kind=${e.kind} '
      'device=${e.device} count=$count active=[$activeStr]',
    );
  }
}
