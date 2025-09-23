import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/repos/farmer_repo.dart';
import '../../core/models/farmer.dart';
import '../../core/services/share_service.dart' as share_service;
import '../../core/services/export_service.dart' as export_service;

final farmerRepoProvider = Provider<FarmerRepo>((ref) => FarmerRepo());

class FarmersScreen extends ConsumerWidget {
  const FarmersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(farmerRepoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Farmers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Farmer>>(
        stream: repo.watchAll(),
        builder: (_, snap) {
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const Center(child: Text('No farmers yet. Tap + to add.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final f = items[i];
              final subtitle = [
                if ((f.mobile ?? '').isNotEmpty) 'Mobile: ${f.mobile}',
                if ((f.whatsapp ?? '').isNotEmpty) 'WhatsApp: ${f.whatsapp}',
                [
                  f.village,
                  f.taluk,
                ].where((e) => (e ?? '').isNotEmpty).join(', '),
              ].where((e) => e.isNotEmpty).join('\n');
              return ListTile(
                title: Text(f.name),
                subtitle: Text(subtitle),
                onTap: () => _openEditor(context, ref, existing: f),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) => _rowAction(context, ref, v, f),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'share', child: Text('Share contact')),
                    PopupMenuItem(value: 'export', child: Text('Export JSON')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _rowAction(
    BuildContext context,
    WidgetRef ref,
    String v,
    Farmer f,
  ) async {
    final repo = ref.read(farmerRepoProvider);
    switch (v) {
      case 'edit':
        return _openEditor(context, ref, existing: f);
      case 'share':
        return share_service.ShareService.shareFarmer(f);
      case 'export':
        final file = await export_service.ExportService.exportFarmerJson(
          farmerId: f.id,
          anonymizePhones: !(f.consentExport),
        );
        await Share.shareXFiles([XFile(file.path)]);
        return;
      case 'delete':
        final ok = await _confirmDelete(context, f);
        if (ok) {
          await repo.delete(f.id);
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Deleted farmer')));
          }
        }
        return;
    }
  }

  Future<bool> _confirmDelete(BuildContext context, Farmer f) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete farmer?'),
            content: Text('Delete "${f.name}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    Farmer? existing,
  }) async {
    final repo = ref.read(farmerRepoProvider);
    final f = existing ?? Farmer()
      ..name = '';

    final formKey = GlobalKey<FormState>();
    final nameCtl = TextEditingController(text: f.name);
    final mobileCtl = TextEditingController(text: f.mobile ?? '');
    final waCtl = TextEditingController(text: f.whatsapp ?? '');
    final villageCtl = TextEditingController(text: f.village ?? '');
    final talukCtl = TextEditingController(text: f.taluk ?? '');
    final langCtl = TextEditingController(text: f.preferredLanguageCode ?? '');
    final notesCtl = TextEditingController(text: f.notes ?? '');
    bool consentExport = f.consentExport;
    bool consentWhatsApp = f.consentWhatsApp;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing == null ? 'Add Farmer' : 'Edit Farmer',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtl,
                    decoration: const InputDecoration(labelText: 'Name *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: mobileCtl,
                    decoration: const InputDecoration(labelText: 'Mobile'),
                  ),
                  TextFormField(
                    controller: waCtl,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp (optional)',
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: villageCtl,
                          decoration: const InputDecoration(
                            labelText: 'Village',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: talukCtl,
                          decoration: const InputDecoration(labelText: 'Taluk'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: langCtl,
                    decoration: const InputDecoration(
                      labelText: 'Preferred language code (e.g., en, kn, ml)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: notesCtl,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: consentExport,
                    onChanged: (v) => consentExport = v,
                    title: const Text('Allow contact in exports'),
                  ),
                  SwitchListTile(
                    value: consentWhatsApp,
                    onChanged: (v) => consentWhatsApp = v,
                    title: const Text('Allow WhatsApp sharing'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        onPressed: () async {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }
                          f.name = nameCtl.text.trim();
                          f.mobile = _nz(mobileCtl.text);
                          f.whatsapp = _nz(waCtl.text);
                          f.village = _nz(villageCtl.text);
                          f.taluk = _nz(talukCtl.text);
                          f.preferredLanguageCode = _nz(langCtl.text);
                          f.notes = _nz(notesCtl.text);
                          f.consentExport = consentExport;
                          f.consentWhatsApp = consentWhatsApp;
                          await repo.upsert(f);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'share') {
                            await share_service.ShareService.shareFarmer(f);
                          } else if (v == 'export') {
                            final file =
                                await export_service
                                    .ExportService.exportFarmerJson(
                                  farmerId: f.id,
                                  anonymizePhones: !(f.consentExport),
                                );
                            await Share.shareXFiles([XFile(file.path)]);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'share',
                            child: Text('Share contact'),
                          ),
                          PopupMenuItem(
                            value: 'export',
                            child: Text('Export JSON'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? _nz(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
