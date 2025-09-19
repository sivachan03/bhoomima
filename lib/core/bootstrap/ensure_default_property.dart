import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../db/isar_service.dart';
import '../models/property.dart';
import '../models/point_group.dart';
import '../state/current_property.dart';

Future<void> ensureDefaultProperty(WidgetRef ref) async {
  final isar = await IsarService.open();
  final count = await isar.propertys.count();

  if (count == 0) {
    final prop = Property()
      ..name = 'My Farm'
      ..type = 'locationOnly'; // Not Mapped
    late int id;
    await isar.writeTxn(() async {
      id = await isar.propertys.put(prop);
      for (final e in const [
        ('Borders','border'),
        ('Partitions','partition'),
        ('Landmarks','landmark'),
        ('Paths','path'),
      ]) {
        final g = PointGroup()
          ..propertyId = id
          ..name = e.$1
          ..category = e.$2
          ..defaultFlag = true;
        await isar.pointGroups.put(g);
      }
    });
    await ref.read(currentPropertyIdProvider.notifier).set(id);
    return;
  }

  final cur = ref.read(currentPropertyIdProvider);
  if (cur == null) {
    final first = await isar.propertys.where().findFirst();
    if (first != null) {
      await ref.read(currentPropertyIdProvider.notifier).set(first.id);
    }
  }
}
