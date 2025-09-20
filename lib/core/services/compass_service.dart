import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_compass/flutter_compass.dart';

final compassStreamProvider = StreamProvider<double?>((ref) async* {
  yield* FlutterCompass.events!.map((e) => e.heading);
});
