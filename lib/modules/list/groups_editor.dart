import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repos/point_group_repo.dart';
import '../../core/models/point_group.dart';

final _grpRepoPv = Provider((_) => PointGroupRepo());

class GroupsEditor extends ConsumerWidget {
  final int propertyId;
  const GroupsEditor({super.key, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(_grpRepoPv);
    return Scaffold(
      appBar: AppBar(title: const Text('Groups')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, repo),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<PointGroup>>(
        stream: repo.watchByProperty(propertyId),
        builder: (context, snap) {
          final items = snap.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('No groups'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final g = items[i];
              return ListTile(
                title: Text(
                  '${g.name}  •  ${g.category}${g.defaultFlag ? " (locked)" : ""}',
                ),
                onTap: () => _openEditor(context, repo, existing: g),
                trailing: g.defaultFlag
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.delete_forever),
                        onPressed: () => repo.delete(g.id),
                      ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    PointGroupRepo repo, {
    PointGroup? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final g = existing ?? PointGroup()
      ..propertyId = propertyId
      ..name = ''
      ..category = 'user'
      ..defaultFlag = false;

    final nameCtl = TextEditingController(text: g.name);
    String? cat = g.category;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Group' : 'Edit Group'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtl,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: cat,
                items: const [
                  DropdownMenuItem(value: 'border', child: Text('Borders')),
                  DropdownMenuItem(
                    value: 'partition',
                    child: Text('Partitions'),
                  ),
                  DropdownMenuItem(value: 'landmark', child: Text('Landmarks')),
                  DropdownMenuItem(value: 'path', child: Text('Paths')),
                  DropdownMenuItem(value: 'user', child: Text('User')),
                ],
                onChanged: (v) => cat = v ?? 'user',
                decoration: const InputDecoration(labelText: 'Category *'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              g.name = nameCtl.text.trim();
              g.category = cat;
              await repo.upsert(g);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
