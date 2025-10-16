import 'package:flutter/material.dart';

typedef TwoTapDone = void Function(Offset p1Screen, Offset p2Screen);

class TwoTapPicker extends StatefulWidget {
  const TwoTapPicker({super.key, required this.onDone});
  final TwoTapDone onDone;

  @override
  State<TwoTapPicker> createState() => _TwoTapPickerState();
}

class _TwoTapPickerState extends State<TwoTapPicker> {
  final List<Offset> _taps = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) {
        setState(() {
          if (_taps.length < 2) _taps.add(d.localPosition);
          if (_taps.length == 2) {
            widget.onDone(_taps[0], _taps[1]);
          }
        });
      },
      child: CustomPaint(painter: _TwoTapPainter(_taps)),
    );
  }
}

class _TwoTapPainter extends CustomPainter {
  _TwoTapPainter(this.taps);
  final List<Offset> taps;

  @override
  void paint(Canvas c, Size s) {
    final dim = Paint()..color = Colors.black.withValues(alpha: 0.05);
    c.drawRect(Offset.zero & s, dim);
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFD84315);
    final dot = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFD84315);
    if (taps.isNotEmpty) c.drawCircle(taps.first, 6, dot);
    if (taps.length == 2) {
      c.drawCircle(taps.last, 6, dot);
      c.drawLine(taps.first, taps.last, guide);
    }
  }

  @override
  bool shouldRepaint(covariant _TwoTapPainter oldDelegate) =>
      oldDelegate.taps != taps;
}
