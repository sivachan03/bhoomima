import 'dart:math' as math;
import 'package:flutter/widgets.dart';

class ProjectionService {
  ProjectionService(this.lat0, this.lon0);
  final double lat0;
  final double lon0;
  double get _k => math.cos(lat0 * math.pi / 180.0);
  static const double _R = 6378137.0; // meters

  Offset project(double lat, double lon) {
    final dx = _R * ((lon - lon0) * math.pi / 180.0) * _k;
    final dy = _R * ((lat - lat0) * math.pi / 180.0);
    return Offset(dx, -dy);
  }

  Offset projectDelta(double dLat, double dLon) {
    final dx = _R * (dLon * math.pi / 180.0) * _k;
    final dy = _R * (dLat * math.pi / 180.0);
    return Offset(dx, -dy);
  }
}
