import 'dart:math' as math;
import 'package:flutter/widgets.dart';

class ProjectionService {
  ProjectionService(this.lat0, this.lon0);
  final double lat0;
  final double lon0;
  double get _k => math.cos(lat0 * math.pi / 180.0);
  static const double earthRadius = 6378137.0; // meters

  Offset project(double lat, double lon) {
    final dx = earthRadius * ((lon - lon0) * math.pi / 180.0) * _k;
    final dy = earthRadius * ((lat - lat0) * math.pi / 180.0);
    return Offset(dx, -dy);
  }

  Offset projectDelta(double dLat, double dLon) {
    final dx = earthRadius * (dLon * math.pi / 180.0) * _k;
    final dy = earthRadius * (dLat * math.pi / 180.0);
    return Offset(dx, -dy);
  }

  (double lat, double lon) unproject(Offset xy) {
    final dy = -xy.dy;
    final dx = xy.dx;
    final dLat = (dy / earthRadius) * 180.0 / math.pi;
    final dLon = (dx / (earthRadius * _k)) * 180.0 / math.pi;
    return (lat0 + dLat, lon0 + dLon);
  }
}
