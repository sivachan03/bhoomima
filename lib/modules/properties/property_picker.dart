import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repos/property_repo.dart';
import '../../core/state/current_property.dart';
import '../../app_state/active_property.dart';
// Removed inline create flow; creation is via Properties screen

Future<void> openPropertyPicker(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(propertyRepoProvider);
  final list = await repo.watchAll().first;

  // Inline create removed; creation is handled by Properties screen add flow

  if (!context.mounted) return; // Avoid using context across async gaps
  final sel = await showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        builder: (context, controller) => ListView(
          controller: controller,
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.add_business),
                  label: const Text('Add property'),
                  onPressed: () {
                    final nav = Navigator.of(context);
                    // Close the picker and open Properties with auto-open add editor
                    nav.pop();
                    nav.pushNamed(
                      '/properties',
                      arguments: {'autoOpenAdd': true},
                    );
                  },
                ),
              ),
            ),
            for (final p in list)
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: Text(p.name),
                subtitle: Text(
                  [
                    p.city,
                    p.pin,
                  ].where((e) => (e ?? '').isNotEmpty).join(' · '),
                ),
                onTap: () => Navigator.pop(context, p.id),
              ),
            // Inline "New property" tile removed; use Add property button above
          ],
        ),
      ),
    ),
  );

  if (sel == null) return; // Either dismissed or created inline (sheet closed)

  final selected = await repo.getById(sel);
  if (selected != null) {
    await ref.read(activePropertyProvider.notifier).setActive(selected);
    await ref.read(currentPropertyIdProvider.notifier).set(selected.id);
  }
}
