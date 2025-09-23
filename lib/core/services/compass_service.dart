import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';

/// Streams heading in degrees normalized to [0, 360).
final compassStreamProvider = StreamProvider<double?>((ref) async* {
  yield* FlutterCompass.events!.map((e) {
    final h = e.heading;
    if (h == null) return null;
    var d = h % 360;
    if (d < 0) d += 360;
    return d;
  });
});
