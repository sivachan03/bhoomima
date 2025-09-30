import 'dart:ui' show Rect;
import '../../core/models/point.dart';
import '../../core/models/point_group.dart';
import '../../core/services/projection_service.dart';

bool pointMatchesSearch(Point p, PointGroup? group, String q) {
  if (q.trim().isEmpty) return true;
  final s = q.toLowerCase();
  if (p.name.toLowerCase().contains(s)) return true;
  if (group != null && group.name.toLowerCase().contains(s)) return true;
  return false;
}

bool pointInsideViewport(Point p, ProjectionService proj, Rect viewportWorld) {
  final xy = proj.project(p.lat, p.lon);
  return viewportWorld.contains(xy);
}
