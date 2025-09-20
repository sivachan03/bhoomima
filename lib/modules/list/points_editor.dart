import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repos/point_repo.dart';
import '../../core/models/point.dart';

final _ptRepoPv = Provider((_) => PointRepo());

class PointsEditor extends ConsumerWidget {
  final int groupId;
  const PointsEditor({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(_ptRepoPv);
    return Scaffold(
      appBar: AppBar(title: const Text('Points')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, repo),
        child: const Icon(Icons.add_location_alt),
      ),
      body: StreamBuilder<List<Point>>(
        stream: repo.watchByGroup(groupId),
        builder: (context, snap) {
          final items = snap.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('No points'));
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final pt = items[i];
              return ListTile(
                title: Text(pt.name),
                subtitle: Text(
                  'lat=${pt.lat.toStringAsFixed(6)}, lon=${pt.lon.toStringAsFixed(6)}'
                  '${pt.hAcc != null ? "  •  ±${pt.hAcc!.toStringAsFixed(1)}m" : ""}',
                ),
                onTap: () => _openEditor(context, repo, existing: pt),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => repo.delete(pt.id),
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
    PointRepo repo, {
    Point? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final pt = existing ?? Point()
      ..groupId = groupId
      ..name = ''
      ..lat = 0
      ..lon = 0;

    final nameCtl = TextEditingController(text: pt.name);
    final latCtl = TextEditingController(text: pt.lat.toStringAsFixed(6));
    final lonCtl = TextEditingController(text: pt.lon.toStringAsFixed(6));
    final accCtl = TextEditingController(
      text: pt.hAcc?.toStringAsFixed(1) ?? '',
    );
    final stabCtl = TextEditingController(
      text: pt.stability?.toStringAsFixed(2) ?? '',
    );

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing == null ? 'Add Point' : 'Edit Point'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtl,
                decoration: const InputDecoration(
                  labelText: 'Name * (e.g., Pt 1)',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: latCtl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Latitude *',
                      ),
                      validator: _reqNum,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: lonCtl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Longitude *',
                      ),
                      validator: _reqNum,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: accCtl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Accuracy (m)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: stabCtl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Stability'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Tip: In Map view, the + button will capture GPS and pre-fill these fields (coming soon).',
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
              pt.name = nameCtl.text.trim();
              pt.lat = double.parse(latCtl.text);
              pt.lon = double.parse(lonCtl.text);
              pt.hAcc = _parseOpt(accCtl.text);
              pt.stability = _parseOpt(stabCtl.text);
              await repo.upsert(pt);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

String? _reqNum(String? s) {
  if (s == null || s.trim().isEmpty) return 'Required';
  try {
    double.parse(s.trim());
    return null;
  } catch (_) {
    return 'Number required';
  }
}

double? _parseOpt(String s) {
  try {
    return s.trim().isEmpty ? null : double.parse(s.trim());
  } catch (_) {
    return null;
  }
}
