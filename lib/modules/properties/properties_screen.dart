import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/property.dart';
import '../../core/repos/property_repo.dart';

class PropertiesScreen extends ConsumerStatefulWidget {
  const PropertiesScreen({super.key});

  @override
  ConsumerState<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends ConsumerState<PropertiesScreen> {
  Future<void> _edit(Property p, String name, String type) async {
    final repo = ref.read(propertyRepoProvider);
    final changingType = p.id != 0 && p.type != type;
    if (changingType) {
      try {
        await repo.updateTypeGuarded(propertyId: p.id, newType: type);
      } on PropertyTypeChangeBlocked catch (e) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Cannot set to Not Mapped'),
            content: Text(
              'This property has ${e.pointCount} point(s) across ${e.groupCount} group(s).\n\n'
              'To mark it as Not Mapped, please remove geometry first or use a future Convert action.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
    }

    // Proceed to save name/type or other edits.
    final updated = Property()
      ..id = p.id
      ..name = name
      ..type = type
      ..address = p.address
      ..street = p.street
      ..city = p.city
      ..pin = p.pin
      ..lat = p.lat
      ..lon = p.lon
      ..directions = p.directions;
    await ref.read(propertyRepoProvider).upsert(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Properties')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Properties screen – TODO'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                // Dummy call to keep _edit referenced for now
                await _edit(
                  Property()
                    ..id = 0
                    ..name = 'My Farm'
                    ..type = 'locationOnly',
                  'My Farm',
                  'locationOnly',
                );
              },
              child: const Text('No-op Edit'),
            ),
          ],
        ),
      ),
    );
  }
}
