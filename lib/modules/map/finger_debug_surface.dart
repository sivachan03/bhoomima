import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// FingerDebugSurface: lightweight raw pointer diagnostic wrapper.
/// Wrap any child to log pointer counts and surface callbacks for one-/two-finger
/// down & move events. Useful to verify multi-touch delivery independent of
/// higher gesture recognizers.
class FingerDebugSurface extends StatefulWidget {
  const FingerDebugSurface({
    super.key,
    required this.child,
    this.onSingleFingerDown,
    this.onSingleFingerMove,
    this.onTwoFingerDown,
    this.onTwoFingerMove,
  });

  final Widget child;

  final void Function(Offset pos)? onSingleFingerDown;
  final void Function(Offset pos, Offset delta)? onSingleFingerMove;

  final void Function(Offset p1, Offset p2)? onTwoFingerDown;
  final void Function(Offset p1, Offset p2)? onTwoFingerMove;

  @override
  State<FingerDebugSurface> createState() => _FingerDebugSurfaceState();
}

class _FingerDebugSurfaceState extends State<FingerDebugSurface> {
  final Map<int, Offset> _pointers = {};

  void _logPointers(String tag) {
    final entries = _pointers.entries
        .map(
          (e) =>
              '#${e.key}@(${e.value.dx.toStringAsFixed(1)},${e.value.dy.toStringAsFixed(1)})',
        )
        .join(', ');
    debugPrint('[$tag] count=${_pointers.length} -> $entries');
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    _logPointers('DOWN');

    if (_pointers.length == 1) {
      widget.onSingleFingerDown?.call(e.localPosition);
    } else if (_pointers.length == 2) {
      final pts = _pointers.values.toList();
      if (pts.length == 2) {
        widget.onTwoFingerDown?.call(pts[0], pts[1]);
        debugPrint('[DEBUG] Two-finger DOWN detected');
      }
    }
  }

  void _onPointerMove(PointerMoveEvent e) {
    final prev = _pointers[e.pointer];
    _pointers[e.pointer] = e.localPosition;
    _logPointers('MOVE');

    if (_pointers.length == 1) {
      if (prev != null) {
        final delta = e.localPosition - prev;
        widget.onSingleFingerMove?.call(e.localPosition, delta);
      }
    } else if (_pointers.length == 2) {
      final pts = _pointers.values.toList();
      if (pts.length == 2) {
        widget.onTwoFingerMove?.call(pts[0], pts[1]);
        debugPrint(
          '[DEBUG] Two-finger MOVE: '
          'p1=(${pts[0].dx.toStringAsFixed(1)},${pts[0].dy.toStringAsFixed(1)}), '
          'p2=(${pts[1].dx.toStringAsFixed(1)},${pts[1].dy.toStringAsFixed(1)})',
        );
      }
    }
  }

  void _onPointerUp(PointerUpEvent e) {
    _pointers.remove(e.pointer);
    _logPointers('UP');
  }

  void _onPointerCancel(PointerCancelEvent e) {
    _pointers.remove(e.pointer);
    _logPointers('CANCEL');
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}
