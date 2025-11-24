import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global pointer hub capturing all active pointers at the app root.
/// Provides count + positions for widgets needing cross-surface multi-finger knowledge.
class PointerHub extends ChangeNotifier {
  final Map<int, Offset> pointers = {};

  void onEvent(PointerEvent e) {
    if (e is PointerDownEvent) {
      pointers[e.pointer] = e.position;
    } else if (e is PointerMoveEvent) {
      // Update position (screen space)
      pointers[e.pointer] = e.position;
    } else if (e is PointerUpEvent || e is PointerCancelEvent) {
      pointers.remove(e.pointer);
    }
    notifyListeners();
  }

  int get count => pointers.length;
}

/// Riverpod provider wrapping a singleton PointerHub so any widget can watch pointer count.
final pointerHubProvider = ChangeNotifierProvider<PointerHub>((ref) {
  return PointerHub();
});
