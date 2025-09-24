import 'package:flutter/material.dart';

typedef OnTapPlaced = Future<void> Function(Offset canvasPos);

class TapToPlaceOverlay extends StatelessWidget {
  final OnTapPlaced onTapPlaced;
  const TapToPlaceOverlay({super.key, required this.onTapPlaced});
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (d) async {
          await onTapPlaced(d.localPosition);
          if (context.mounted) Navigator.pop(context);
        },
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Tap on map to place point',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
