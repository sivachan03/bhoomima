import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repos/property_repo.dart';
import '../../core/state/current_property.dart';
import '../../app_state/active_property.dart';

Future<void> openPropertyPicker(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(propertyRepoProvider);
  final list = await repo.watchAll().first;
  final sel = await showModalBottomSheet<int?>(
    context: context,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final p in list)
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(p.name),
              subtitle: Text(
                [p.city, p.pin].where((e) => (e ?? '').isNotEmpty).join(' · '),
              ),
              onTap: () => Navigator.pop(context, p.id),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('New property'),
            onTap: () => Navigator.pop(context, null),
          ),
        ],
      ),
    ),
  );

  if (sel == null) {
    // Route to Properties screen to add; do nothing else here.
    Navigator.of(context).pushNamed('/properties');
    return;
  }

  final p = await repo.getById(sel);
  if (p != null) {
    await ref.read(activePropertyProvider.notifier).setActive(p);
    // Keep legacy currentPropertyIdProvider in sync for older code paths
    await ref.read(currentPropertyIdProvider.notifier).set(p.id);
  }
}
