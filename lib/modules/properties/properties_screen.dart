import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/streams.dart';
import '../../core/models/property.dart';
import '../../core/db/isar_service.dart';
import '../../core/state/current_property.dart';
import '../../core/repos/property_repo.dart'; // BM-08/BM-09

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final props = ref.watch(propertiesStreamProvider);
    final currentId = ref.watch(currentPropertyIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Properties')),
      body: props.when(
        data: (list) => ListView.separated(
          itemBuilder: (_, i) {
            final p = list[i];
            final selected = p.id == currentId;
            return ListTile(
              title: Text(p.name),
              subtitle: Text(p.type == 'mapped' ? 'Mapped' : 'Not Mapped'),
              leading: selected
                  ? const Icon(Icons.radio_button_checked)
                  : const Icon(Icons.radio_button_unchecked),
              onTap: () =>
                  ref.read(currentPropertyIdProvider.notifier).set(p.id),
              trailing: PopupMenuButton<String>(
                onSelected: (v) => _handleMenu(context, ref, v, p),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: list.length,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _handleMenu(
    BuildContext context,
    WidgetRef ref,
    String v,
    Property p,
  ) async {
    switch (v) {
      case 'edit':
        await _showEditDialog(context, ref, existing: p);
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete property?'),
            content: Text(
              'This will remove all groups and points under "${p.name}".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (ok == true) {
          await PropertyRepo().deleteAndReselect(ref, p.id);
        }
        break;
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref, {
    Property? existing,
  }) async {
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    String type = existing?.type ?? 'locationOnly';
    await showDialog<void>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Property' : 'Edit Property'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'locationOnly',
                        child: Text('Not Mapped'),
                      ),
                      DropdownMenuItem(value: 'mapped', child: Text('Mapped')),
                    ],
                    onChanged: (v) =>
                        setState(() => type = v ?? 'locationOnly'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final isar = await IsarService.open();
                    final name = nameCtl.text.trim().isEmpty
                        ? 'My Farm'
                        : nameCtl.text.trim();
                    if (existing == null) {
                      final p = Property()
                        ..name = name
                        ..type = type;
                      await isar.writeTxn(() async {
                        final id = await isar.propertys.put(p);
                        await ref
                            .read(currentPropertyIdProvider.notifier)
                            .set(id);
                      });
                    } else {
                      final repo = PropertyRepo();
                      try {
                        await repo.updateTypeGuarded(
                          propertyId: existing.id,
                          newType: type,
                        );
                        existing.name = name;
                        final id = existing.id;
                        await isar.writeTxn(
                          () async => await isar.propertys.put(existing),
                        );
                        await ref
                            .read(currentPropertyIdProvider.notifier)
                            .set(id);
                      } on PropertyTypeChangeBlocked catch (e) {
                        if (!context.mounted) return;
                        await showDialog<void>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Cannot set to Not Mapped'),
                            content: Text(
                              'This property has ${e.pointCount} point(s) across ${e.groupCount} group(s).\n\n'
                              'Remove geometry first or use a future Convert action.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
