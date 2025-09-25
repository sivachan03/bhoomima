import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repos/property_repo.dart';
import '../../core/state/current_property.dart';
import '../../app_state/active_property.dart';
import '../../core/models/property.dart';
import '../../core/db/isar_service.dart';
import '../../core/seed/seed_catalog.dart';

Future<void> openPropertyPicker(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(propertyRepoProvider);
  final list = await repo.watchAll().first;

  Future<void> _createInline() async {
    String name = '';
    String city = '';
    String pin = '';
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('New property'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Name'),
                  autofocus: true,
                  onChanged: (v) => name = v,
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'City (optional)',
                  ),
                  onChanged: (v) => city = v,
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'PIN (optional)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => pin = v,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: name.trim().isEmpty
                    ? null
                    : () => Navigator.pop(context, true),
                child: const Text('Create'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok || name.trim().isEmpty) return;

    final isar = await IsarService.open();
    final p = Property()
      ..name = name.trim()
      ..city = city.trim().isEmpty ? null : city.trim()
      ..pin = pin.trim().isEmpty ? null : pin.trim()
      ..type = 'locationOnly';
    await isar.writeTxn(() async {
      await isar.propertys.put(p);
    });
    // Seed default groups immediately (idempotent safe)
    await SeedCatalog.ensureDefaultGroupsForProperty(isar, p);
    // Set active + legacy current id
    await ref.read(activePropertyProvider.notifier).setActive(p);
    await ref.read(currentPropertyIdProvider.notifier).set(p.id);
    if (context.mounted) Navigator.pop(context); // Close the sheet
  }

  final sel = await showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        builder: (context, controller) => ListView(
          controller: controller,
          shrinkWrap: true,
          children: [
            for (final p in list)
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(p.name),
                subtitle: Text(
                  [
                    p.city,
                    p.pin,
                  ].where((e) => (e ?? '').isNotEmpty).join(' · '),
                ),
                onTap: () => Navigator.pop(context, p.id),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('New property'),
              onTap: _createInline,
            ),
          ],
        ),
      ),
    ),
  );

  if (sel == null) return; // Either dismissed or created inline (sheet closed)

  final p = await repo.getById(sel);
  if (p != null) {
    await ref.read(activePropertyProvider.notifier).setActive(p);
    await ref.read(currentPropertyIdProvider.notifier).set(p.id);
  }
}
