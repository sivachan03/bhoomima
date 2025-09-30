import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../db/isar_service.dart';
import '../models/property.dart';
import '../state/current_property.dart';
import '../seed/seed_catalog.dart';
import '../seed/seed_icons.dart';
import '../seed/seed_partition_colors.dart';
import 'dev_seed_points.dart';

Future<void> ensureDefaultProperty(WidgetRef ref) async {
  final isar = await IsarService.open();
  // Seed global catalog/templates (idempotent)
  await SeedCatalog.run(isar);
  // Seed global icons (idempotent)
  await SeedIcons.run(isar);

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
    await SeedIcons.ensureDefaultGroupIcons(isar, prop.id);
    await SeedPartitionColors.apply(isar, prop.id);
    // Dev-only: ensure a small demo polygon exists so overlays can be verified quickly
    await seedDemoPartitionIfEmpty(isar, propertyId: prop.id);
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
      await SeedIcons.ensureDefaultGroupIcons(isar, first.id);
      await SeedPartitionColors.apply(isar, first.id);
      // Dev-only: seed demo points if none exist yet
      await seedDemoPartitionIfEmpty(isar, propertyId: first.id);
    }
  }

  // Optionally ensure all existing properties have default groups (migration path)
  final props = await isar.propertys.where().findAll();
  for (final p in props) {
    await SeedCatalog.ensureDefaultGroupsForProperty(isar, p);
    await SeedIcons.ensureDefaultGroupIcons(isar, p.id);
    await SeedPartitionColors.apply(isar, p.id);
    // Dev-only: seed demo points if none exist yet
    await seedDemoPartitionIfEmpty(isar, propertyId: p.id);
  }
}
