import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class GpsSample {
  GpsSample(this.position, this.acc, this.stability);
  final Position position;
  final double acc; // meters
  final double stability; // meters (stddev of recent inter-sample distances)
}

class GpsService {
  final _controller = StreamController<GpsSample>.broadcast();
  Stream<GpsSample> get stream => _controller.stream;

  final _window = <Position>[];
  final int _n = 8; // sliding window

  StreamSubscription<Position>? _sub;

  Future<bool> ensurePermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  Future<void> start() async {
    final ok = await ensurePermission();
    if (!ok) return;
    await _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    ).listen(_onPos);
  }

  void _onPos(Position p) {
    _window.add(p);
    if (_window.length > _n) _window.removeAt(0);
    final acc = p.accuracy; // meters
    double stability = 0;
    if (_window.length >= 3) {
      final ds = <double>[];
      for (var i = 1; i < _window.length; i++) {
        ds.add(
          _haversine(
            _window[i - 1].latitude,
            _window[i - 1].longitude,
            _window[i].latitude,
            _window[i].longitude,
          ),
        );
      }
      final mean = ds.fold(0.0, (a, b) => a + b) / ds.length;
      final varsum = ds.fold(0.0, (a, b) => a + (b - mean) * (b - mean));
      stability = math.sqrt(varsum / ds.length);
    }
    _controller.add(GpsSample(p, acc, stability));
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    _window.clear();
  }

  void dispose() {
    _controller.close();
    _sub?.cancel();
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double d) => d * math.pi / 180.0;
}

final gpsServiceProvider = Provider<GpsService>((ref) {
  final s = GpsService();
  ref.onDispose(s.dispose);
  return s;
});

final gpsStreamProvider = StreamProvider<GpsSample?>((ref) async* {
  final svc = ref.watch(gpsServiceProvider);
  // auto-start when watched
  // ignore: discarded_futures
  svc.start();
  yield* svc.stream;
});
