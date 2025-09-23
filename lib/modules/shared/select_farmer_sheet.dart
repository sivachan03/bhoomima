import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/farmer.dart';
import '../farmers/farmers_screen.dart' show farmerRepoProvider;

final _localFarmerListProvider = FutureProvider<List<Farmer>>(
  (ref) async => ref.read(farmerRepoProvider).listAll(),
);

class SelectFarmerSheet extends ConsumerStatefulWidget {
  const SelectFarmerSheet({super.key});

  @override
  ConsumerState<SelectFarmerSheet> createState() => _SelectFarmerSheetState();
}

class _SelectFarmerSheetState extends ConsumerState<SelectFarmerSheet> {
  final _queryCtl = TextEditingController();
  List<Farmer> _all = [];
  List<Farmer> _filtered = [];

  void _applyFilter(String q) {
    final qq = q.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((f) {
        final name = f.name.toLowerCase();
        final phone = (f.mobile ?? '').toLowerCase();
        return name.contains(qq) || phone.contains(qq);
      }).toList();
    });
  }

  Future<void> _addNew() async {
    final nameCtl = TextEditingController();
    final phoneCtl = TextEditingController();
    final ok =
        await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Add new farmer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(labelText: 'Name *'),
                ),
                TextField(
                  controller: phoneCtl,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;
    if (nameCtl.text.trim().isEmpty) return;
    final f = Farmer()
      ..name = nameCtl.text.trim()
      ..mobile = phoneCtl.text.trim().isEmpty ? null : phoneCtl.text.trim();
    await ref.read(farmerRepoProvider).upsert(f);
    final list = await ref.read(farmerRepoProvider).listAll();
    setState(() {
      _all = list;
      _filtered = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(_localFarmerListProvider);
    return asyncList.when(
      data: (list) {
        _all = list;
        _filtered = list;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _queryCtl,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          hintText: 'Search name or phone',
                        ),
                        onChanged: _applyFilter,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _addNew,
                      icon: const Icon(Icons.add),
                      label: const Text('New'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final f = _filtered[i];
                      return ListTile(
                        title: Text(f.name),
                        subtitle: Text(f.mobile ?? '—'),
                        onTap: () => Navigator.pop(context, f),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      error: (e, st) => Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Error loading farmers: $e'),
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

Future<Farmer?> openSelectFarmerSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<Farmer>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const SelectFarmerSheet(),
  );
}
