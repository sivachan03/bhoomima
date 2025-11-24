import 'package:flutter/material.dart';

/// Minimal screen that only logs 1 vs 2 finger presence locally.
/// Decision Test Part 2 (BM-300-DT2):
///   Answers: "Can a single, simple widget in this app differentiate 1 vs 2 fingers?"
///   Outcomes:
///     - count=2 here AND count=2 in PointerSniffer → Layout/hit-test issue in complex screen (map overlays too small/absorbing).
///     - count=1 here BUT count=2 in PointerSniffer → Some ancestor/sibling intercepts second finger before reaching this local Listener.
///     - count=1 here AND count=1 in PointerSniffer → Global multi-touch not delivered (device/emulator/input configuration).
/// Use this page to eliminate map / Riverpod / GPS complexity from diagnosis.
class TwoFingerTestPage extends StatefulWidget {
  const TwoFingerTestPage({super.key});

  @override
  State<TwoFingerTestPage> createState() => _TwoFingerTestPageState();
}

class _TwoFingerTestPageState extends State<TwoFingerTestPage> {
  final Map<int, Offset> _pointers = {};

  void _onDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    _log('DOWN', e.pointer);
  }

  void _onMove(PointerMoveEvent e) {
    _pointers[e.pointer] = e.localPosition;
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
      '[LOCAL-TEST][$tag] id=$id count=${_pointers.length} active=[$entries]',
    );
    setState(() {}); // update on-screen text
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: _onCancel,
        child: Container(
          color: Colors.yellow.withOpacity(0.15),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Touch with 1 or 2 fingers'),
              const SizedBox(height: 16),
              Text(
                'Active pointers: ${_pointers.length}',
                style: const TextStyle(fontSize: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
