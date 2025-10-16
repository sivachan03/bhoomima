import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/point.dart';
import '../../core/models/point_group.dart';
import 'map_providers.dart';

/// Returns a map from groupId to a list of Points that is ready (no async in paint).
final pointsByGroupsReadyProvider =
    Provider.family<Map<int, List<Point>>, List<PointGroup>>((ref, groups) {
      final out = <int, List<Point>>{};
      for (final g in groups) {
        final av = ref.watch(
          pointsByGroupProvider(g.id),
        ); // watch in widget layer
        out[g.id] = av.maybeWhen(
          data: (list) => list,
          orElse: () => const <Point>[],
        );
      }
      return out;
    });
