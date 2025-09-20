/// Streams for Properties, Groups (per property), Points (per group)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../db/isar_service.dart';
import '../models/property.dart';
import '../models/point_group.dart';
import '../models/point.dart';

final propertiesStreamProvider = StreamProvider<List<Property>>((ref) async* {
  final isar = await IsarService.open();
  yield* isar.propertys.where().watch(fireImmediately: true);
});

final groupsByPropertyProvider = StreamProvider.family<List<PointGroup>, int>((
  ref,
  propertyId,
) async* {
  final isar = await IsarService.open();
  yield* isar.pointGroups
      .filter()
      .propertyIdEqualTo(propertyId)
      .watch(fireImmediately: true);
});

final pointsByGroupProvider = StreamProvider.family<List<Point>, int>((
  ref,
  groupId,
) async* {
  final isar = await IsarService.open();
  yield* isar.points
      .filter()
      .groupIdEqualTo(groupId)
      .watch(fireImmediately: true);
});
