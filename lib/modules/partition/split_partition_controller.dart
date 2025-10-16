import 'package:flutter/material.dart';
import '../../core/geo/geometry_split.dart';
import '../../core/services/projection_service.dart';

typedef SaveRingsLatLon =
    Future<int> Function(
      List<(double lat, double lon)> ringA,
      List<(double lat, double lon)> ringB,
    );

class SplitPartitionController extends ChangeNotifier {
  bool active = false;
  Offset? p1World;
  Offset? p2World;

  void start() {
    active = true;
    p1World = null;
    p2World = null;
    notifyListeners();
  }

  void cancel() {
    active = false;
    p1World = null;
    p2World = null;
    notifyListeners();
  }

  Future<int?> trySplit({
    required List<Offset> targetRingWorld,
    required ProjectionService proj,
    required SaveRingsLatLon persist,
    void Function(List<Offset> ringAWorld, List<Offset> ringBWorld)? onPreview,
  }) async {
    if (!active || p1World == null || p2World == null) {
      return null;
    }
    final res = GeometrySplit.splitPolygonByLine(
      ring: targetRingWorld,
      p1: p1World!,
      p2: p2World!,
    );
    if (res.isEmpty) return null;
    // Clean rings: dedupe neighbors, ensure closed, enforce CCW
    List<Offset> cleanRing(List<Offset> r) {
      if (r.isEmpty) return r;
      final out = <Offset>[];
      const double dedupTol = 1e-6; // meters
      for (final p in r) {
        if (out.isEmpty || (out.last - p).distance > dedupTol) {
          out.add(p);
        }
      }
      // close if needed
      if (out.isNotEmpty && (out.first - out.last).distance > 1e-9) {
        out.add(out.first);
      }
      // enforce CCW via shoelace area
      double area = 0;
      for (int i = 0; i < out.length - 1; i++) {
        area += out[i].dx * out[i + 1].dy - out[i + 1].dx * out[i].dy;
      }
      if (area < 0) {
        // reverse to make CCW; keep closed by ensuring last==first after reverse
        final rev = out.reversed.toList();
        if ((rev.first - rev.last).distance > 1e-9) {
          rev.add(rev.first);
        }
        return rev;
      }
      return out;
    }

    final aClean = cleanRing(res[0]);
    final bClean = cleanRing(res[1]);

    // Allow preview of world rings prior to persist
    if (onPreview != null) {
      onPreview(aClean, bClean);
    }

    List<(double lat, double lon)> toLatLon(List<Offset> r) =>
        r.map((o) => proj.unproject(o)).toList();
    final count = await persist(toLatLon(aClean), toLatLon(bClean));
    active = false;
    p1World = p2World = null;
    notifyListeners();
    return count;
  }
}
