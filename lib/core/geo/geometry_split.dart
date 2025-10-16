import 'package:flutter/widgets.dart';

class GeometrySplit {
  static List<List<Offset>> splitPolygonByLine({
    required List<Offset> ring,
    required Offset p1,
    required Offset p2,
  }) {
    if (ring.length < 3) return [];
    final lineDir = p2 - p1;
    if (lineDir.distance == 0) return [];

    List<Offset> pts = List.of(ring);
    if (pts.first != pts.last) pts = [...pts, pts.first];

    final List<Offset> inters = [];
    final List<(int idx, Offset pt)> splice = [];

    double side(Offset p) {
      final v = p - p1;
      return lineDir.dx * v.dy - lineDir.dy * v.dx;
    }

    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i];
      final b = pts[i + 1];
      final sa = side(a);
      final sb = side(b);
      if ((sa == 0 && sb == 0)) {
        continue;
      }
      if ((sa == 0 && sb != 0) ||
          (sa != 0 && sb == 0) ||
          (sa > 0) != (sb > 0)) {
        final ab = b - a;
        final denom = (ab.dx * (-lineDir.dy) + ab.dy * (lineDir.dx));
        if (denom == 0) continue;
        final t =
            ((p1.dx - a.dx) * (-lineDir.dy) + (p1.dy - a.dy) * (lineDir.dx)) /
            denom;
        if (t >= 0 && t <= 1) {
          final ip = Offset(a.dx + t * ab.dx, a.dy + t * ab.dy);
          inters.add(ip);
          splice.add((i + 1, ip));
        }
      }
    }
    if (inters.length < 2) return [];

    final withCuts = <Offset>[];
    for (int i = 0; i < pts.length - 1; i++) {
      withCuts.add(pts[i]);
      for (final s in splice) {
        if (s.$1 == i + 1) {
          withCuts.add(s.$2);
        }
      }
    }
    withCuts.add(pts.last);

    final cutIdx = <int>[];
    for (int i = 0; i < withCuts.length; i++) {
      if (inters.any((ip) => (withCuts[i] - ip).distance <= 1e-6)) {
        cutIdx.add(i);
        if (cutIdx.length == 2) break;
      }
    }
    if (cutIdx.length < 2) return [];

    final i0 = cutIdx[0], i1 = cutIdx[1];
    List<Offset> ringA = withCuts.sublist(i0, i1 + 1);
    List<Offset> ringB = [
      withCuts[i0],
      ...withCuts.sublist(i1, withCuts.length - 1),
      withCuts[0],
      ...withCuts.sublist(0, i0 + 1),
    ];

    if (ringA.first != ringA.last) ringA = [...ringA, ringA.first];
    if (ringB.first != ringB.last) ringB = [...ringB, ringB.first];

    List<Offset> dedup(List<Offset> r) {
      final out = <Offset>[];
      for (final p in r) {
        if (out.isEmpty || (out.last - p).distance > 1e-6) out.add(p);
      }
      return out;
    }

    ringA = dedup(ringA);
    ringB = dedup(ringB);
    if (ringA.length < 4 || ringB.length < 4) return [];

    return [ringA, ringB];
  }
}
