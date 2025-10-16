import 'package:isar/isar.dart';
import '../models/point.dart';
import '../models/point_group.dart';

class PartitionOps {
  PartitionOps(this.isar);
  final Isar isar;

  Future<int> createPartitionGroup({
    required int propertyId,
    required String name,
    String colorHex = '#88A5E6',
  }) async {
    final g = PointGroup()
      ..propertyId = propertyId
      ..name = name
      ..category = 'partition'
      ..defaultFlag = false
      ..colorHex = colorHex;
    return isar.writeTxn(() async {
      final id = await isar.pointGroups.put(g);
      return id;
    });
  }

  Future<void> replaceRing({
    required int groupId,
    required List<(double lat, double lon)> ring,
  }) async {
    await isar.writeTxn(() async {
      await isar.points.filter().groupIdEqualTo(groupId).deleteAll();
      for (final (lat, lon) in ring) {
        final p = Point()
          ..groupId = groupId
          ..name = ''
          ..lat = lat
          ..lon = lon
          ..createdAt = DateTime.now();
        await isar.points.put(p);
      }
    });
  }
}
