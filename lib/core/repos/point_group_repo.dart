import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/point_group.dart';
import 'base_repo.dart';

final pointGroupRepoProvider = Provider<PointGroupRepo>((ref) => PointGroupRepo());
final pointGroupsProvider = StreamProvider.family<List<PointGroup>, int>((ref, propertyId) async* {
  final repo = ref.read(pointGroupRepoProvider);
  yield* repo.watchByProperty(propertyId);
});

class PointGroupRepo extends BaseRepo {
  Future<int> upsert(PointGroup g) async {
    final isar = await db;
    return isar.writeTxn(() => isar.pointGroups.put(g));
  }

  Future<void> delete(Id id) async {
    final isar = await db;
    await isar.writeTxn(() => isar.pointGroups.delete(id));
  }

  Stream<List<PointGroup>> watchByProperty(int propertyId) async* {
    final isar = await db;
    yield* isar.pointGroups.filter().propertyIdEqualTo(propertyId).watch(fireImmediately: true);
  }
}