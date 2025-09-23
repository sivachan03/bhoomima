import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/property.dart';
import '../../core/models/farmer.dart';
import '../../core/repos/property_repo.dart';
import '../farmers/farmers_screen.dart' show farmerRepoProvider;
import '../shared/select_farmer_sheet.dart';

class PropertyOwnerRow extends ConsumerWidget {
  final Property property;
  const PropertyOwnerRow({super.key, required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Text('Owner:'),
        const SizedBox(width: 8),
        Expanded(
          child: FutureBuilder<Farmer?>(
            future: _loadOwner(ref, property.ownerId),
            builder: (_, snap) {
              final owner = snap.data;
              return Text(
                owner?.name ?? '(None)',
                style: const TextStyle(fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        TextButton(
          onPressed: () async {
            final selected = await openSelectFarmerSheet(context, ref);
            if (selected != null) {
              await ref
                  .read(propertyRepoProvider)
                  .linkOwner(propertyId: property.id, ownerId: selected.id);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Owner linked.')));
              }
            }
          },
          child: Text(property.ownerId == null ? 'Link' : 'Change'),
        ),
        if (property.ownerId != null)
          TextButton(
            onPressed: () async {
              final ok =
                  await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Unlink owner?'),
                      content: const Text(
                        'This will remove the link from the property.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Unlink'),
                        ),
                      ],
                    ),
                  ) ??
                  false;
              if (!ok) return;
              await ref
                  .read(propertyRepoProvider)
                  .unlinkOwner(propertyId: property.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Owner unlinked.')),
                );
              }
            },
            child: const Text('Unlink'),
          ),
      ],
    );
  }

  Future<Farmer?> _loadOwner(WidgetRef ref, int? ownerId) async {
    if (ownerId == null) return null;
    final list = await ref.read(farmerRepoProvider).listAll();
    try {
      return list.firstWhere((f) => f.id == ownerId);
    } catch (_) {
      return null;
    }
  }
}
