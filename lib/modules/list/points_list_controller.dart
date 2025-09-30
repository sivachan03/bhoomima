import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../core/db/isar_service.dart';
import '../../core/models/point.dart';
import '../../core/models/point_group.dart';
import '../filter/global_filter.dart';

final pointsListProvider = StreamProvider.family<List<Point>, int>((
  ref,
  propertyId,
) async* {
  final filter = ref.watch(globalFilterProvider);
  final isar = await IsarService.open();

  // Watch all groups for this property
  final groups = await isar.pointGroups
      .filter()
      .propertyIdEqualTo(propertyId)
      .findAll();
  final groupsById = {for (final g in groups) g.id: g};
  final groupIds = groupsById.keys.toList();

  // Watch all points and filter in memory to avoid generator method mismatch
  yield* isar.points.watchLazy().asyncMap((_) async {
    final list = await isar.points
        .filter()
        .anyOf(groupIds, (q, id) => q.groupIdEqualTo(id))
        .findAll();
    Iterable<Point> out = list;
    if (filter.groupIds.isNotEmpty) {
      out = out.where((p) => filter.groupIds.contains(p.groupId));
    }
    if (filter.search.trim().isNotEmpty) {
      final q = filter.search.toLowerCase();
      out = out.where((p) {
        if (p.name.toLowerCase().contains(q)) return true;
        final g = groupsById[p.groupId];
        if (g != null && g.name.toLowerCase().contains(q)) return true;
        return false;
      });
    }
    return out.toList();
  });
});
