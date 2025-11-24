import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Full-screen raw pointer lab to verify two-finger delivery inside a single Listener.
class PointerLabPage extends StatefulWidget {
  const PointerLabPage({super.key});

  @override
  State<PointerLabPage> createState() => _PointerLabPageState();
}

class _PointerLabPageState extends State<PointerLabPage> {
  final Map<int, Offset> _pointers = <int, Offset>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pointer Lab')),
      body: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (PointerDownEvent e) {
          _pointers[e.pointer] = e.position;
          _log('DOWN', e);
        },
        onPointerMove: (PointerMoveEvent e) {
          _pointers[e.pointer] = e.position;
          _log('MOVE', e);
        },
        onPointerUp: (PointerUpEvent e) {
          _pointers.remove(e.pointer);
          _log('UP', e);
        },
        onPointerCancel: (PointerCancelEvent e) {
          _pointers.remove(e.pointer);
          _log('CANCEL', e);
        },
        child: const SizedBox.expand(),
      ),
    );
  }

  void _log(String tag, PointerEvent e) {
    final count = _pointers.length;
    final activeStr = _pointers.entries
        .map(
          (e2) =>
              '#${e2.key}@(${e2.value.dx.toStringAsFixed(1)},${e2.value.dy.toStringAsFixed(1)})',
        )
        .join(', ');
    debugPrint('[$tag] count=$count -> $activeStr');
  }
}
