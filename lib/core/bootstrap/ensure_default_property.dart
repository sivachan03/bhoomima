import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../db/isar_service.dart';
import '../models/property.dart';
import '../state/current_property.dart';
import '../seed/seed_catalog.dart';

Future<void> ensureDefaultProperty(WidgetRef ref) async {
  final isar = await IsarService.open();
  // Seed global catalog/templates (idempotent)
  await SeedCatalog.run(isar);

  final count = await isar.propertys.count();

  if (count == 0) {
    final prop = Property()
      ..name = 'My Farm'
      ..type = 'locationOnly'; // Not Mapped
    late int id;
    await isar.writeTxn(() async {
      id = await isar.propertys.put(prop);
    });
    // Ensure default template-driven groups
    await SeedCatalog.ensureDefaultGroupsForProperty(isar, prop);
    await ref.read(currentPropertyIdProvider.notifier).set(id);
    return;
  }

  final cur = ref.read(currentPropertyIdProvider);
  if (cur == null) {
    final first = await isar.propertys.where().findFirst();
    if (first != null) {
      await ref.read(currentPropertyIdProvider.notifier).set(first.id);
      // Backfill default groups for existing first property (legacy install)
      await SeedCatalog.ensureDefaultGroupsForProperty(isar, first);
    }
  }

  // Optionally ensure all existing properties have default groups (migration path)
  final props = await isar.propertys.where().findAll();
  for (final p in props) {
    await SeedCatalog.ensureDefaultGroupsForProperty(isar, p);
  }
}
