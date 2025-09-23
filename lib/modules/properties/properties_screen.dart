import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/location_autofill_service.dart';
import '../../core/repos/property_repo.dart';
import '../../core/models/property.dart';
import '../../core/models/farmer.dart';
import '../../core/services/share_service.dart' as share_service;
import '../../core/services/export_service.dart' as export_service;
import '../../core/services/recipient_prefs.dart';
import 'package:share_plus/share_plus.dart';
import '../farmers/farmers_screen.dart' show farmerRepoProvider;
import '../shared/select_farmer_sheet.dart';

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(propertyRepoProvider);
    final farmers = ref.watch(farmerRepoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Properties')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(context, ref, repo),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Property>>(
        stream: repo.watchAll(),
        builder: (context, snap) {
          final items = snap.data ?? const [];
          if (items.isEmpty) {
            return const Center(
              child: Text('No properties yet. Tap + to add.'),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = items[i];
              return FutureBuilder<Farmer?>(
                future: p.ownerId != null
                    ? farmers.getById(p.ownerId!)
                    : Future.value(null),
                builder: (context, fsnap) {
                  final owner = fsnap.data;
                  return ListTile(
                    title: Text('${p.name}  •  ${p.typeCode ?? p.type}'),
                    subtitle: Text(
                      [
                        if (owner != null) 'Owner: ${owner.name}',
                        [
                          p.addressLine,
                          p.street,
                          p.city,
                          p.pin,
                        ].where((e) => (e ?? '').isNotEmpty).join(', '),
                      ].where((e) => e.isNotEmpty).join('\n'),
                    ),
                    onTap: () => _openEditor(context, ref, repo, existing: p),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) =>
                          _rowAction(context, ref, repo, v, p, owner),
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'sharePropText',
                          child: Text('Share Property address (text)'),
                        ),
                        PopupMenuItem(
                          value: 'sharePropWA',
                          child: Text('Share Property address (WhatsApp)'),
                        ),
                        PopupMenuItem(
                          value: 'shareFarmerText',
                          child: Text('Share Farmer address (text)'),
                        ),
                        PopupMenuItem(
                          value: 'shareFarmerWA',
                          child: Text('Share Farmer address (WhatsApp)'),
                        ),
                        PopupMenuItem(
                          value: 'exportZip',
                          child: Text('Export Property (zip)'),
                        ),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Property p) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Delete property?'),
            content: Text('Delete "${p.name}"? This cannot be undone.'),
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

  Future<void> _rowAction(
    BuildContext context,
    WidgetRef ref,
    PropertyRepo repo,
    String action,
    Property p,
    Farmer? owner,
  ) async {
    switch (action) {
      case 'edit':
        return _openEditor(context, ref, repo, existing: p);
      case 'sharePropText':
        {
          final text = share_service.ShareService.buildPropertyAddressText(
            p: p,
            owner: owner,
          );
          return share_service.ShareService.shareText(text);
        }
      case 'sharePropWA':
        {
          final text = share_service.ShareService.buildPropertyAddressText(
            p: p,
            owner: owner,
          );
          return _shareToWhatsAppPicker(context, ref, p, owner, text);
        }
      case 'shareFarmerText':
        {
          if (owner == null) return _noOwner(context);
          final text = share_service.ShareService.buildFarmerAddressText(owner);
          return share_service.ShareService.shareText(text);
        }
      case 'shareFarmerWA':
        {
          if (owner == null) return _noOwner(context);
          final text = share_service.ShareService.buildFarmerAddressText(owner);
          return _shareToWhatsAppPicker(context, ref, p, owner, text);
        }
      case 'exportZip':
        return _exportZipDialog(context, ref, p, owner);
      case 'delete':
        {
          final ok = await _confirmDelete(context, p);
          if (ok) {
            await repo.deleteAndReselect(ref, p.id);
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Deleted property')));
            }
          }
          return;
        }
    }
  }

  Future<void> _noOwner(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const AlertDialog(
        title: Text('No owner set'),
        content: Text('Set a Farmer as the owner to use this share option.'),
      ),
    );
  }

  Future<void> _exportZipDialog(
    BuildContext context,
    WidgetRef ref,
    Property p,
    Farmer? owner,
  ) async {
    bool incFarm = false;
    bool incSys = false;
    bool anonym = true;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Export Property (zip)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: incFarm,
                onChanged: (v) => setState(() => incFarm = v ?? false),
                title: const Text('Include FarmLog (last 90 days)'),
              ),
              CheckboxListTile(
                value: incSys,
                onChanged: (v) => setState(() => incSys = v ?? false),
                title: const Text('Include SystemLog (last 90 days)'),
              ),
              CheckboxListTile(
                value: anonym,
                onChanged: (v) => setState(() => anonym = v ?? true),
                title: const Text('Anonymize contacts'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final zipPath = await export_service
                    .ExportService.exportProperty(propertyId: p.id);
                await Share.shareXFiles([XFile(zipPath)]);
              },
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareToWhatsAppPicker(
    BuildContext context,
    WidgetRef ref,
    Property p,
    Farmer? owner,
    String message,
  ) async {
    // Capture outer context for post-await UI (SnackBar) to avoid using a disposed dialog context
    final outerContext = context;
    String? last = await RecipientPrefs.getLastForProperty(p.id);
    final candidates = <String>[];
    if (owner?.whatsapp?.trim().isNotEmpty == true) {
      candidates.add(owner!.whatsapp!.trim());
    }
    if (owner?.mobile?.trim().isNotEmpty == true &&
        (owner!.mobile!.trim() != owner.whatsapp?.trim())) {
      candidates.add(owner.mobile!.trim());
    }
    if (last != null && !candidates.contains(last)) candidates.insert(0, last);

    String? chosen = last ?? (candidates.isNotEmpty ? candidates.first : null);

    if (!outerContext.mounted) return;
    await showDialog<void>(
      context: outerContext,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Send via WhatsApp'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (candidates.isEmpty)
                const Text('No WhatsApp/mobile found in Farmer profile.'),
              for (final c in candidates)
                RadioListTile<String>(
                  value: c,
                  groupValue: chosen,
                  onChanged: (v) => setState(() => chosen = v),
                  title: Text(c),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: (chosen == null)
                  ? null
                  : () async {
                      // Close the dialog using its own context before awaiting
                      Navigator.pop(dialogContext);
                      if (chosen != null) {
                        final ok =
                            await share_service
                                .ShareService.tryOpenWhatsAppToNumber(
                              chosen!,
                              message,
                            );
                        if (ok) {
                          await RecipientPrefs.saveLastForProperty(
                            p.id,
                            chosen!,
                          );
                        } else if (outerContext.mounted) {
                          ScaffoldMessenger.of(outerContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Could not open WhatsApp. Message copied.',
                              ),
                            ),
                          );
                          await share_service.ShareService.shareText(message);
                        }
                      }
                    },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref,
    PropertyRepo repo, {
    Property? existing,
  }) async {
    final formKey = GlobalKey<FormState>();
    final p = existing ?? Property()
      ..name = ''
      ..typeCode = 'locationOnly'
      ..type = 'locationOnly';

    final nameCtl = TextEditingController(text: existing?.name ?? p.name);
    final ownerIdValue = ValueNotifier<int?>(p.ownerId);
    final typeValue = ValueNotifier<String>(p.typeCode ?? 'locationOnly');
    final addressCtl = TextEditingController(text: p.addressLine ?? '');
    final streetCtl = TextEditingController(text: p.street ?? '');
    final cityCtl = TextEditingController(text: p.city ?? '');
    final pinCtl = TextEditingController(text: p.pin ?? '');
    final latCtl = TextEditingController(text: p.lat?.toStringAsFixed(6) ?? '');
    final lonCtl = TextEditingController(text: p.lon?.toStringAsFixed(6) ?? '');
    final altitudeCtl = TextEditingController(
      text: p.altitude?.toStringAsFixed(1) ?? '',
    );
    final directionsCtl = TextEditingController(text: p.directions ?? '');

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
                    existing == null ? 'Add Property' : 'Edit Property',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<int?>(
                    valueListenable: ownerIdValue,
                    builder: (context, ownerId, _) {
                      return Row(
                        children: [
                          const Text('Owner:'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FutureBuilder<Farmer?>(
                              future: ownerId == null
                                  ? Future.value(null)
                                  : ref
                                        .read(farmerRepoProvider)
                                        .getById(ownerId),
                              builder: (_, snap) {
                                final owner = snap.data;
                                return Text(
                                  owner?.name ?? '(None)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                );
                              },
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final selected = await openSelectFarmerSheet(
                                context,
                                ref,
                              );
                              if (selected == null) return;
                              if (existing != null) {
                                await ref
                                    .read(propertyRepoProvider)
                                    .linkOwner(
                                      propertyId: p.id,
                                      ownerId: selected.id,
                                    );
                              }
                              p.ownerId = selected.id;
                              ownerIdValue.value = selected.id;
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Owner linked.'),
                                  ),
                                );
                              }
                            },
                            child: Text(ownerId == null ? 'Link' : 'Change'),
                          ),
                          if (ownerId != null)
                            TextButton(
                              onPressed: () async {
                                if (existing != null) {
                                  await ref
                                      .read(propertyRepoProvider)
                                      .unlinkOwner(propertyId: p.id);
                                }
                                p.ownerId = null;
                                ownerIdValue.value = null;
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Owner unlinked.'),
                                    ),
                                  );
                                }
                              },
                              child: const Text('Unlink'),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtl,
                    decoration: const InputDecoration(labelText: 'Name *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: typeValue.value,
                    items: const [
                      DropdownMenuItem(value: 'mapped', child: Text('Mapped')),
                      DropdownMenuItem(
                        value: 'locationOnly',
                        child: Text('Not Mapped'),
                      ),
                    ],
                    onChanged: (v) => typeValue.value = v ?? 'locationOnly',
                    decoration: const InputDecoration(labelText: 'Type *'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.my_location),
                    label: const Text('Use current location'),
                    onPressed: () async {
                      try {
                        final res = await LocationAutofillService.capture();
                        latCtl.text = res.lat.toStringAsFixed(6);
                        lonCtl.text = res.lon.toStringAsFixed(6);
                        altitudeCtl.text =
                            res.altitude?.toStringAsFixed(1) ?? '';
                        if (res.addressLine != null) {
                          addressCtl.text = res.addressLine!;
                        }
                        if ((res.street ?? '').isNotEmpty) {
                          streetCtl.text = res.street!;
                        }
                        if ((res.city ?? '').isNotEmpty) {
                          cityCtl.text = res.city!;
                        }
                        if ((res.pin ?? '').isNotEmpty) {
                          pinCtl.text = res.pin!;
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Location captured. Review and Save.',
                              ),
                            ),
                          );
                        }
                      } on PermissionDeniedException catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Location permission needed: ${e.message}',
                            ),
                          ),
                        );
                      } on LocationServiceDisabledException catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Enable location services: ${e.message}',
                            ),
                          ),
                        );
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not capture location.'),
                          ),
                        );
                      }
                    },
                  ),
                  const Divider(height: 24),
                  Text(
                    'Address',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextFormField(
                    controller: addressCtl,
                    decoration: const InputDecoration(
                      labelText: 'Address line',
                    ),
                  ),
                  TextFormField(
                    controller: streetCtl,
                    decoration: const InputDecoration(labelText: 'Street'),
                  ),
                  TextFormField(
                    controller: cityCtl,
                    decoration: const InputDecoration(labelText: 'City/Town'),
                  ),
                  TextFormField(
                    controller: pinCtl,
                    decoration: const InputDecoration(
                      labelText: 'PIN/Postal code',
                    ),
                  ),
                  const Divider(height: 24),
                  Text(
                    'Reference location',
                    style: Theme.of(context).textTheme.titleMedium,
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
                            labelText: 'Latitude',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: lonCtl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: altitudeCtl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Altitude (m)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: directionsCtl,
                    decoration: const InputDecoration(
                      labelText: 'Directions (how to reach)',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          p.name = nameCtl.text.trim();
                          p.typeCode = typeValue.value;
                          p.type = typeValue.value; // mirror for compatibility
                          p.addressLine = _emptyToNull(addressCtl.text);
                          p.address = _emptyToNull(addressCtl.text);
                          p.street = _emptyToNull(streetCtl.text);
                          p.city = _emptyToNull(cityCtl.text);
                          p.pin = _emptyToNull(pinCtl.text);
                          p.lat = _parseD(latCtl.text);
                          p.lon = _parseD(lonCtl.text);
                          p.altitude = _parseD(altitudeCtl.text);
                          p.directions = _emptyToNull(directionsCtl.text);
                          await repo.upsert(p);
                          if (context.mounted) Navigator.pop(context);
                        },
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.pop(context),
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

String? _emptyToNull(String s) => s.trim().isEmpty ? null : s.trim();
double? _parseD(String? s) {
  if (s == null) return null;
  try {
    return s.trim().isEmpty ? null : double.parse(s.trim());
  } catch (_) {
    return null;
  }
}
