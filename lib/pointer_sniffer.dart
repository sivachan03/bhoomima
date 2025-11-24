import 'package:flutter/material.dart';

/// PointerSniffer: minimal global root Listener that logs raw pointer counts & positions.
/// Decision Test Part 1 (BM-300-DT1):
///   Answers: "Does the root Flutter tree see two simultaneous fingers?"
///   If count reaches 2 here, platform + embedding deliver multi-touch correctly.
///   If it never exceeds 1, problem is below any map/layout concerns (device/emulator/input source).
/// Attach at app root to verify multi-touch reaches Flutter irrespective of local widget hit-tests.
class PointerSniffer extends StatefulWidget {
  final Widget child;
  const PointerSniffer({super.key, required this.child});

  @override
  State<PointerSniffer> createState() => _PointerSnifferState();
}

class _PointerSnifferState extends State<PointerSniffer> {
  final Map<int, Offset> _pointers = {};

  void _onDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.position;
    _log('DOWN', e.pointer);
  }

  void _onMove(PointerMoveEvent e) {
    _pointers[e.pointer] = e.position;
    _log('MOVE', e.pointer);
  }

  void _onUp(PointerUpEvent e) {
    _log('UP', e.pointer);
    _pointers.remove(e.pointer);
  }

  void _onCancel(PointerCancelEvent e) {
    _log('CANCEL', e.pointer);
    _pointers.remove(e.pointer);
  }

  void _log(String tag, int id) {
    final entries = _pointers.entries
        .map(
          (e) =>
              '#${e.key}@(${e.value.dx.toStringAsFixed(1)},${e.value.dy.toStringAsFixed(1)})',
        )
        .join(', ');
    debugPrint(
      '[SNIFFER][$tag] id=$id count=${_pointers.length} active=[$entries]',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onDown,
      onPointerMove: _onMove,
      onPointerUp: _onUp,
      onPointerCancel: _onCancel,
      child: widget.child,
    );
  }
}
