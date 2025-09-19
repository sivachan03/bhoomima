import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repos/party_repo.dart';
import '../../core/models/party.dart';

class PartyScreen extends ConsumerWidget {
  const PartyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parties = ref.watch(partiesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Workers / Parties')),
      body: parties.when(
        data: (list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final p = list[i];
            return ListTile(
              title: Text(p.name),
              subtitle: Text('${p.category}${p.phone == null ? '' : ' • ${p.phone}'}'),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _edit(ctx, ref, p);
                  if (v == 'del') _del(ref, p);
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
        onPressed: () => _edit(context, ref, Party()
          ..name = ''
          ..category = 'worker'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _del(WidgetRef ref, Party p) async {
    await ref.read(partyRepoProvider).delete(p.id);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Party p) async {
    final name = TextEditingController(text: p.name);
    final phone = TextEditingController(text: p.phone ?? '');
    String cat = p.category;

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(p.id == 0 ? 'Add Party' : 'Edit Party'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
            DropdownButtonFormField<String>(
              value: cat,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'worker', child: Text('Worker')),
                DropdownMenuItem(value: 'vendor', child: Text('Vendor')),
                DropdownMenuItem(value: 'buyer', child: Text('Buyer')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (v) => cat = v ?? 'worker',
            ),
            const SizedBox(height: 8),
            TextField(controller: TextEditingController(text: p.note ?? ''), decoration: const InputDecoration(labelText: 'Note')),
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
        ..name = name.text.trim().isEmpty ? 'Party' : name.text.trim()
        ..category = cat
        ..phone = phone.text.trim().isEmpty ? null : phone.text.trim();
      await ref.read(partyRepoProvider).upsert(p);
    }
  }
}