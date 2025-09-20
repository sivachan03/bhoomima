import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/streams.dart';
import '../../core/db/isar_service.dart';
import '../../core/models/point.dart';
import '../../core/models/point_group.dart';

class PointsScreen extends ConsumerWidget {
  const PointsScreen({super.key, required this.group});
  final PointGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pts = ref.watch(pointsByGroupProvider(group.id));
    return Scaffold(
      appBar: AppBar(title: Text('Points • ${group.name}')),
      body: pts.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('No points yet'))
            : ListView.separated(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final p = list[i];
                  final sub =
                      '(${p.lat.toStringAsFixed(6)}, ${p.lon.toStringAsFixed(6)})';
                  return ListTile(
                    title: Text(p.name.isNotEmpty ? p.name : 'Pt ${p.id}'),
                    subtitle: Text(sub),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) => _handle(context, v, p),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
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
        onPressed: () => _showEditDialog(context, group),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _handle(BuildContext context, String v, Point p) async {
    switch (v) {
      case 'edit':
        await _showEditDialog(context, group, existing: p);
        break;
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete point?'),
            content: Text('Delete "${p.name}"?'),
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
          await isar.writeTxn(() async => await isar.points.delete(p.id));
        }
        break;
    }
  }

  Future<void> _showEditDialog(
    BuildContext context,
    PointGroup group, {
    Point? existing,
  }) async {
    final nameCtl = TextEditingController(text: existing?.name ?? '');
    final latCtl = TextEditingController(
      text: existing == null ? '' : existing.lat.toStringAsFixed(7),
    );
    final lonCtl = TextEditingController(
      text: existing == null ? '' : existing.lon.toStringAsFixed(7),
    );
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Point' : 'Edit Point'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              decoration: const InputDecoration(labelText: 'Name (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: latCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Lat (optional)'),
            ),
            TextField(
              controller: lonCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Lon (optional)'),
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
              final name = nameCtl.text.trim();
              final lat =
                  double.tryParse(latCtl.text.trim()) ?? (existing?.lat ?? 0);
              final lon =
                  double.tryParse(lonCtl.text.trim()) ?? (existing?.lon ?? 0);
              await isar.writeTxn(() async {
                if (existing == null) {
                  final p = Point()
                    ..groupId = group.id
                    ..name = name.isEmpty ? 'Pt' : name
                    ..lat = lat
                    ..lon = lon;
                  await isar.points.put(p);
                } else {
                  existing
                    ..name = name.isEmpty ? existing.name : name
                    ..lat = lat
                    ..lon = lon;
                  await isar.points.put(existing);
                }
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
