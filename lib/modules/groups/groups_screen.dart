import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/current_property.dart';
import '../../core/data/streams.dart';
import '../../core/db/isar_service.dart';
import '../../core/models/point_group.dart';
import '../../core/models/point.dart';
import '../points/points_screen.dart';

const _kGroupCats = <String, String>{
  'border': 'Borders',
  'partition': 'Partitions',
  'landmark': 'Landmarks',
  'path': 'Paths',
  'user': 'User Group',
};

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pid = ref.watch(currentPropertyIdProvider);
    if (pid == null) {
      return const Scaffold(body: Center(child: Text('No property selected.')));
    }
    final groups = ref.watch(groupsByPropertyProvider(pid));
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: groups.when(
        data: (list) => ListView.separated(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final g = list[i];
            final subtitle =
                '${_kGroupCats[g.category] ?? g.category}'
                '${g.defaultFlag ? ' • locked' : ''}';
            return ListTile(
              title: Text(g.name),
              subtitle: Text(subtitle),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PointsScreen(group: g)),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) => _handle(context, ref, v, g),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    enabled: !g.defaultFlag,
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditDialog(context, ref, pid),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    String v,
    PointGroup g,
  ) async {
    final pid = ref.read(currentPropertyIdProvider);
    switch (v) {
      case 'edit':
        await _showEditDialog(context, ref, pid!, existing: g);
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete group?'),
            content: Text('Delete "${g.name}" and its points?'),
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
          final isar = await IsarService.open();
          await isar.writeTxn(() async {
            final pts = await isar.points
                .filter()
                .groupIdEqualTo(g.id)
                .findAll();
            for (final p in pts) {
              await isar.points.delete(p.id);
            }
            await isar.pointGroups.delete(g.id);
          });
        }
        break;
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    int propertyId, {
    PointGroup? existing,
  }) async {
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    String category = existing?.category ?? 'user';
    await showDialog<void>(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (_, setState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Group' : 'Edit Group'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: _kGroupCats.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: existing?.defaultFlag == true
                        ? null
                        : (v) => setState(() => category = v ?? 'user'),
                  ),
                  if (existing?.defaultFlag == true)
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Locked group',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: existing?.defaultFlag == true
                      ? null
                      : () async {
                          final isar = await IsarService.open();
                          final name = nameCtl.text.trim().isEmpty
                              ? 'Group'
                              : nameCtl.text.trim();
                          await isar.writeTxn(() async {
                            if (existing == null) {
                              final g = PointGroup()
                                ..propertyId = propertyId
                                ..name = name
                                ..category = category
                                ..defaultFlag = false;
                              await isar.pointGroups.put(g);
                            } else {
                              existing
                                ..name = name
                                ..category = category;
                              await isar.pointGroups.put(existing);
                            }
                          });
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
