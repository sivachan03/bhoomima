import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repos/point_group_repo.dart';
import '../../core/models/point_group.dart';

class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key, required this.propertyId});
  final int propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(pointGroupsProvider(propertyId));
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      body: groups.when(
        data: (list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final g = list[i];
            return ListTile(
              title: Text(g.name),
              subtitle: Text('${g.category} • ${g.defaultFlag ? 'locked' : 'editable'}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _editGroup(ctx, ref, g);
                  if (v == 'del') _deleteGroup(ref, g);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (!g.defaultFlag) const PopupMenuItem(value: 'del', child: Text('Delete')),
                ],
              ),
            );
          },
        ),

        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _editGroup(context, ref, PointGroup()
          ..propertyId = propertyId
          ..name = ''
          ..category = 'user'
          ..defaultFlag = false),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteGroup(WidgetRef ref, PointGroup g) async {
    await ref.read(pointGroupRepoProvider).delete(g.id);
  }

  Future<void> _editGroup(BuildContext context, WidgetRef ref, PointGroup g) async {
    final nameCtrl = TextEditingController(text: g.name);
    String cat = g.category;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(g.id == 0 ? 'Add Group' : 'Edit Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: cat,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'border', child: Text('Border')),
                DropdownMenuItem(value: 'partition', child: Text('Partition')),
                DropdownMenuItem(value: 'landmark', child: Text('Landmark')),
                DropdownMenuItem(value: 'path', child: Text('Path')),
                DropdownMenuItem(value: 'user', child: Text('User')),
              ],
              onChanged: (v) => cat = v ?? 'user',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok == true) {
      final repo = ref.read(pointGroupRepoProvider);
      g
        ..name = nameCtrl.text.trim().isEmpty ? 'Group' : nameCtrl.text.trim()
        ..category = cat;
      await repo.upsert(g);
    }
  }
}