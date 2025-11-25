import 'package:flutter/material.dart';

/// PointerSniffer: minimal global root Listener that logs raw pointer counts & positions.
/// Decision Test Part 1 (BM-300-DT1):
///   Answers: "Does the root Flutter tree see two simultaneous fingers?"
///   If count reaches 2 here, platform + embedding deliver multi-touch correctly.
///   If it never exceeds 1, problem is below any map/layout concerns (device/emulator/input source).
/// Attach at app root to verify multi-touch reaches Flutter irrespective of local widget hit-tests.
/// Original stateful PointerSniffer kept for reference (multi-pointer map).
/// Use StatelessPointerSniffer for pure logging without rebuild risk.
class PointerSniffer extends StatefulWidget {
  final String tag;
  final Widget child;
  const PointerSniffer({super.key, required this.tag, required this.child});
  @override
  State<PointerSniffer> createState() => _PointerSnifferState();
}

class _PointerSnifferState extends State<PointerSniffer> {
  final Map<int, Offset> _pointers = {};
  void _log(String phase, int id) {
    final active = _pointers.entries
        .map(
          (e) =>
              '#${e.key}@(${e.value.dx.toStringAsFixed(1)},${e.value.dy.toStringAsFixed(1)})',
        )
        .join(', ');
    debugPrint(
      '[SNIF ${widget.tag}] $phase id=$id count=${_pointers.length} active=[$active]',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _pointers[e.pointer] = e.localPosition;
        _log('DOWN', e.pointer);
      },
      onPointerMove: (e) {
        if (_pointers.containsKey(e.pointer)) {
          _pointers[e.pointer] = e.localPosition;
        }
        _log('MOVE', e.pointer);
      },
      onPointerUp: (e) {
        _pointers.remove(e.pointer);
        _log('UP', e.pointer);
      },
      onPointerCancel: (e) {
        _pointers.remove(e.pointer);
        _log('CANCEL', e.pointer);
      },
      child: widget.child,
    );
  }
}

/// Stateless variant: logs events without storing pointer map (avoids any state mutation).
class StatelessPointerSniffer extends StatelessWidget {
  final String tag;
  final Widget child;
  const StatelessPointerSniffer({
    super.key,
    required this.tag,
    required this.child,
  });

  void _log(String phase, PointerEvent e) {
    debugPrint('[SNIF $tag] $phase id=${e.pointer}');
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) => _log('DOWN', e),
      onPointerMove: (e) => _log('MOVE', e),
      onPointerUp: (e) => _log('UP', e),
      onPointerCancel: (e) => _log('CANCEL', e),
      child: child,
    );
  }
}

/// PassivePointerSniffer: maintains its own pointer map for count logging
/// WITHOUT triggering ancestor rebuilds (no setState calls beyond internal map update).
class PassivePointerSniffer extends StatefulWidget {
  final String tag;
  final Widget child;
  const PassivePointerSniffer({
    super.key,
    required this.tag,
    required this.child,
  });
  @override
  State<PassivePointerSniffer> createState() => _PassivePointerSnifferState();
}

class _PassivePointerSnifferState extends State<PassivePointerSniffer> {
  final Map<int, Offset> _pointers = {};

  void _log(String phase, PointerEvent e) {
    final active = _pointers.entries
        .map(
          (p) =>
              '#${p.key}@(${p.value.dx.toStringAsFixed(1)},${p.value.dy.toStringAsFixed(1)})',
        )
        .join(', ');
    debugPrint(
      '[SNIF ${widget.tag}] $phase id=${e.pointer} count=${_pointers.length} active=[$active]',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _pointers[e.pointer] = e.localPosition;
        _log('DOWN', e);
      },
      onPointerMove: (e) {
        if (_pointers.containsKey(e.pointer)) {
          _pointers[e.pointer] = e.localPosition;
        }
        _log('MOVE', e);
      },
      onPointerUp: (e) {
        _pointers.remove(e.pointer);
        _log('UP', e);
      },
      onPointerCancel: (e) {
        _pointers.remove(e.pointer);
        _log('CANCEL', e);
      },
      child: widget.child,
    );
  }
}
