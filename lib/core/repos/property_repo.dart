import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/property.dart';
import '../models/point.dart';
import '../models/point_group.dart';
import '../state/current_property.dart';
import '../bootstrap/ensure_default_property.dart';
import 'base_repo.dart';

final propertyRepoProvider = Provider<PropertyRepo>((ref) => PropertyRepo());
final propertiesProvider = StreamProvider<List<Property>>((ref) async* {
  final repo = ref.read(propertyRepoProvider);
  yield* repo.watchAll();
});

/// Stream the current property by id. If the id is invalid, emits null.
final currentPropertyProvider = StreamProvider.family<Property?, int>((
  ref,
  id,
) async* {
  final repo = ref.read(propertyRepoProvider);
  yield* repo.watchById(id);
});

class PropertyRepo extends BaseRepo {
  Future<int> upsert(Property p) async {
    final isar = await db;
    return isar.writeTxn(() => isar.propertys.put(p));
  }

  Future<void> delete(Id id) async {
    final isar = await db;
    await isar.writeTxn(() => isar.propertys.delete(id));
  }

  Stream<List<Property>> watchAll() async* {
    final isar = await db;
    yield* isar.propertys.where().watch(fireImmediately: true);
  }

  /// Watch a single property by id.
  Stream<Property?> watchById(int id) async* {
    final isar = await db;
    yield* isar.propertys
        .where()
        .idEqualTo(id)
        .watch(fireImmediately: true)
        .map((list) => list.isNotEmpty ? list.first : null);
  }

  /// Get a property by id, or null if missing.
  Future<Property?> getById(int id) async {
    final isar = await db;
    return isar.propertys.get(id);
  }

  /// Compute counts of groups and points for a property.
  Future<({int groupCount, int pointCount})> geometryCounts(
    int propertyId,
  ) async {
    final isar = await db;
    final groupIds = await isar.pointGroups
        .filter()
        .propertyIdEqualTo(propertyId)
        .idProperty()
        .findAll();
    final groupCount = groupIds.length;
    if (groupCount == 0) {
      return (groupCount: 0, pointCount: 0);
    }
    final pointCount = await isar.points
        .filter()
        .anyOf(groupIds, (q, gid) => q.groupIdEqualTo(gid))
        .count();
    return (groupCount: groupCount, pointCount: pointCount);
  }

  /// Guarded update of property type. Prevent switching to `locationOnly`
  /// if there are any points recorded for this property.
  Future<void> updateTypeGuarded({
    required int propertyId,
    required String newType,
  }) async {
    final isar = await db;
    final p = await isar.propertys.get(propertyId);
    if (p == null) return;
    if (p.type == newType) return;

    if (newType == 'locationOnly') {
      final counts = await geometryCounts(propertyId);
      if (counts.pointCount > 0) {
        throw PropertyTypeChangeBlocked(
          reason: 'HAS_GEOMETRY',
          groupCount: counts.groupCount,
          pointCount: counts.pointCount,
        );
      }
    }

    p.type = newType;
    await isar.writeTxn(() => isar.propertys.put(p));
  }

  /// Delete a property and cascade delete its groups and points.
  Future<void> cascadeDelete(int propertyId) async {
    final isar = await db;
    await isar.writeTxn(() async {
      final groupIds = await isar.pointGroups
          .filter()
          .propertyIdEqualTo(propertyId)
          .idProperty()
          .findAll();

      if (groupIds.isNotEmpty) {
        // Delete all points belonging to those groups
        final pointIds = await isar.points
            .filter()
            .anyOf(groupIds, (q, gid) => q.groupIdEqualTo(gid))
            .idProperty()
            .findAll();
        if (pointIds.isNotEmpty) {
          await isar.points.deleteAll(pointIds);
        }
        // Delete the groups
        await isar.pointGroups.deleteAll(groupIds);
      }
      // Finally delete the property itself
      await isar.propertys.delete(propertyId);
    });
  }

  /// Delete a property and ensure a valid current selection afterwards.
  /// If it was the current property, pick another one if available or
  /// seed a new default property.
  Future<void> deleteAndReselect(WidgetRef ref, int propertyId) async {
    final isar = await db;
    final currentId = ref.read(currentPropertyIdProvider);
    await cascadeDelete(propertyId);

    if (currentId == propertyId) {
      // Choose another property if exists
      final remaining = await isar.propertys.where().idProperty().findAll();
      if (remaining.isNotEmpty) {
        await ref.read(currentPropertyIdProvider.notifier).set(remaining.first);
      } else {
        // Seed a default property
        await ensureDefaultProperty(ref);
      }
    }
  }
}

class PropertyTypeChangeBlocked implements Exception {
  PropertyTypeChangeBlocked({
    required this.reason,
    required this.groupCount,
    required this.pointCount,
  });
  final String reason; // e.g., 'HAS_GEOMETRY'
  final int groupCount;
  final int pointCount;
  @override
  String toString() =>
      'Blocked: $reason (groups: $groupCount, points: $pointCount)';
}
