import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repos/point_repo.dart';
import '../../core/repos/point_group_repo.dart';
import '../../core/models/point.dart';

class PointsListScreen extends ConsumerStatefulWidget {
  const PointsListScreen({super.key, required this.propertyId});
  final int propertyId;

  @override
  ConsumerState<PointsListScreen> createState() => _PointsListScreenState();
}

class _PointsListScreenState extends ConsumerState<PointsListScreen> {
  int? _groupId;

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(pointGroupsProvider(widget.propertyId));
    return groupsAsync.when(
      data: (groups) {
        _groupId ??= groups.isNotEmpty ? groups.first.id : null;
        final pointsStream = _groupId == null ? null : ref.watch(pointsByGroupProvider(_groupId!));
        return Scaffold(
          appBar: AppBar(
            title: const Text('Points'),
            actions: [
              DropdownButton<int>(
                value: _groupId,
                hint: const Text('Group'),
                items: [for (final g in groups) DropdownMenuItem(value: g.id, child: Text(g.name))],
                onChanged: (v) => setState(() => _groupId = v),
              ),
            ],
          ),

          body: pointsStream == null
              ? const Center(child: Text('No groups'))
              : pointsStream.when(
            data: (list) => ListView.separated(
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final p = list[i];
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text('lat:${p.lat.toStringAsFixed(6)}  lon:${p.lon.toStringAsFixed(6)}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) {
                      if (v == 'edit') _editPoint(ctx, ref, p);
                      if (v == 'del') _deletePoint(ref, p);
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'del', child: Text('Delete')),
                    ],
                  ),
                );
              },
            ),

            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error: $e')),
          ),

          floatingActionButton: FloatingActionButton(
            onPressed: () => _editPoint(context, ref, Point()
              ..groupId = _groupId ?? 0
              ..name = ''
              ..lat = 0
              ..lon = 0),
            child: const Icon(Icons.add),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Future<void> _deletePoint(WidgetRef ref, Point p) async {
    await ref.read(pointRepoProvider).delete(p.id);
  }

  Future<void> _editPoint(BuildContext context, WidgetRef ref, Point p) async {
    final nameCtrl = TextEditingController(text: p.name);
    final latCtrl = TextEditingController(text: p.lat == 0 ? '' : p.lat.toString());
    final lonCtrl = TextEditingController(text: p.lon == 0 ? '' : p.lon.toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(p.id == 0 ? 'Add Point' : 'Edit Point'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            Row(children: [
              Expanded(child: TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Lat'), keyboardType: TextInputType.numberWithOptions(decimal: true))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: lonCtrl, decoration: const InputDecoration(labelText: 'Lon'), keyboardType: TextInputType.numberWithOptions(decimal: true))),
            ]),
          ],
        ),

        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );

    if (ok == true) {
      p
        ..name = nameCtrl.text.trim().isEmpty ? 'Pt' : nameCtrl.text.trim()
        ..lat = double.tryParse(latCtrl.text.trim()) ?? 0
        ..lon = double.tryParse(lonCtrl.text.trim()) ?? 0;
      await ref.read(pointRepoProvider).upsert(p);
    }
  }
}