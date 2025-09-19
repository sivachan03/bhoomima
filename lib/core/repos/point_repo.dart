import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/point.dart';
import 'base_repo.dart';

final pointRepoProvider = Provider<PointRepo>((ref) => PointRepo());
final pointsByGroupProvider = StreamProvider.family<List<Point>, int>((ref, groupId) async* {
  final repo = ref.read(pointRepoProvider);
  yield* repo.watchByGroup(groupId);
});

class PointRepo extends BaseRepo {
  Future<int> upsert(Point p) async {
    final isar = await db;
    return isar.writeTxn(() => isar.points.put(p));
  }

  Future<void> delete(Id id) async {
    final isar = await db;
    await isar.writeTxn(() => isar.points.delete(id));
  }

  Stream<List<Point>> watchByGroup(int groupId) async* {
    final isar = await db;
    yield* isar.points.filter().groupIdEqualTo(groupId).watch(fireImmediately: true);
  }
}