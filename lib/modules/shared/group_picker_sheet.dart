import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../../app_state/active_property.dart';
import '../../core/db/isar_service.dart';
import '../../core/models/point_group.dart';

class PickedGroup {
  final int id;
  final String name;
  PickedGroup(this.id, this.name);
}

Future<PickedGroup?> openGroupPickerSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final prop = ref.read(activePropertyProvider).value;
  if (prop == null) return null;
  final isar = await IsarService.open();
  final groups = await isar.pointGroups
      .filter()
      .propertyIdEqualTo(prop.id)
      .sortByName()
      .findAll();
  if (!context.mounted) return null;
  return showModalBottomSheet<PickedGroup?>(
    context: context,
    builder: (_) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          const ListTile(
            title: Text(
              'Select group',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          for (final g in groups)
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: Text(g.name),
              subtitle: Text(g.category ?? ''),
              onTap: () => Navigator.pop(context, PickedGroup(g.id, g.name)),
            ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.clear),
            title: const Text('None'),
            onTap: () => Navigator.pop(context, null),
          ),
        ],
      ),
    ),
  );
}
