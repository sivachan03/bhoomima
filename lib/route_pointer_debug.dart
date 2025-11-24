import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';

/// Wrap a subtree to log pointer events at that route level.
/// Helps compare global ([GLOBAL]) vs route-level ([ROUTE]) vs widget-level logs.
class RoutePointerDebug extends StatefulWidget {
  const RoutePointerDebug({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<RoutePointerDebug> createState() => _RoutePointerDebugState();
}

class _RoutePointerDebugState extends State<RoutePointerDebug> {
  final Map<int, Offset> _active = <int, Offset>{};

  void _handle(PointerEvent e) {
    if (!widget.enabled) return;
    if (e is PointerDownEvent) {
      _active[e.pointer] = e.localPosition;
    } else if (e is PointerMoveEvent) {
      if (_active.containsKey(e.pointer)) _active[e.pointer] = e.localPosition;
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
      '[ROUTE] ${e.runtimeType} id=${e.pointer} kind=${e.kind} count=$count [$activeStr]',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handle,
      onPointerMove: _handle,
      onPointerUp: _handle,
      onPointerCancel: _handle,
      child: widget.child,
    );
  }
}
