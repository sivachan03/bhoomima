import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../core/db/isar_service.dart';
import '../../core/models/point_group.dart';
import '../../core/models/point.dart';
import '../../core/state/current_property.dart';

final borderGroupsProvider = StreamProvider<List<PointGroup>>((ref) async* {
  final pid = ref.watch(currentPropertyIdProvider);
  if (pid == null) {
    yield <PointGroup>[];
    return;
  }
  final isar = await IsarService.open();
  yield* isar.pointGroups
      .filter()
      .propertyIdEqualTo(pid)
      .and()
      .categoryEqualTo('border')
      .watch(fireImmediately: true);
});

final partitionGroupsProvider = StreamProvider<List<PointGroup>>((ref) async* {
  final pid = ref.watch(currentPropertyIdProvider);
  if (pid == null) {
    yield <PointGroup>[];
    return;
  }
  final isar = await IsarService.open();
  yield* isar.pointGroups
      .filter()
      .propertyIdEqualTo(pid)
      .and()
      .categoryEqualTo('partition')
      .watch(fireImmediately: true);
});

final pointsByGroupProvider = StreamProvider.family<List<Point>, int>((
  ref,
  gid,
) async* {
  final isar = await IsarService.open();
  yield* isar.points.filter().groupIdEqualTo(gid).watch(fireImmediately: true);
});
