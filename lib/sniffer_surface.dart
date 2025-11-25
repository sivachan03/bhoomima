import 'package:flutter/material.dart';

/// PointerSnifferSurface: lightweight wrapper to log active pointer IDs within a subtree.
/// Use multiple instances at different hierarchy levels to locate where a pointer stream is lost.
class PointerSnifferSurface extends StatefulWidget {
  final String label;
  final Widget child;
  const PointerSnifferSurface({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  State<PointerSnifferSurface> createState() => _PointerSnifferSurfaceState();
}

class _PointerSnifferSurfaceState extends State<PointerSnifferSurface> {
  final Map<int, Offset> _pointers = {};

  void _down(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    _log('DOWN', e.pointer);
  }

  void _move(PointerMoveEvent e) {
    _pointers[e.pointer] = e.localPosition;
    _log('MOVE', e.pointer);
  }

  void _up(PointerUpEvent e) {
    _log('UP', e.pointer);
    _pointers.remove(e.pointer);
  }

  void _cancel(PointerCancelEvent e) {
    _log('CANCEL', e.pointer);
    _pointers.remove(e.pointer);
  }

  void _log(String tag, int id) {
    final active = _pointers.entries
        .map(
          (e) =>
              '#${e.key}@(${e.value.dx.toStringAsFixed(1)},${e.value.dy.toStringAsFixed(1)})',
        )
        .join(', ');
    debugPrint(
      '[SNIF ${widget.label}][$tag] id=$id count=${_pointers.length} active=[$active]',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: widget.child,
    );
  }
}
