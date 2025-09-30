import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../../core/db/isar_service.dart';
import '../../core/models/point_group.dart';
import 'global_filter.dart';
import 'filter_persistence.dart';

Future<void> openGlobalFilterSheet(
  BuildContext context,
  WidgetRef ref, {
  required int propertyId,
}) async {
  final db = await IsarService.open();
  final groups = await db.pointGroups
      .filter()
      .propertyIdEqualTo(propertyId)
      .findAll();
  if (!context.mounted) return;

  final state = ref.read(globalFilterProvider);
  Set<int> sel = {...state.groupIds};
  bool partitionsIncluded = state.partitionsIncluded;
  bool inViewportOnly = state.inViewportOnly;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          sel.clear();
                          partitionsIncluded = false;
                          inViewportOnly = false;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Groups',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: groups.length,
                    itemBuilder: (_, i) {
                      final g = groups[i];
                      final checked = sel.contains(g.id);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (v) => setState(
                          () => v == true ? sel.add(g.id) : sel.remove(g.id),
                        ),
                        title: Text(g.name),
                        dense: true,
                      );
                    },
                  ),
                ),
                const Divider(),
                SwitchListTile(
                  value: partitionsIncluded,
                  onChanged: (v) => setState(() => partitionsIncluded = v),
                  title: const Text('Show partition labels (map)'),
                  subtitle: const Text(
                    'Partitions are always drawn; labels show when this is ON',
                  ),
                ),
                SwitchListTile(
                  value: inViewportOnly,
                  onChanged: (v) => setState(() => inViewportOnly = v),
                  title: const Text('Only show points in current map view'),
                  subtitle: const Text('Map tab only'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Apply'),
                        onPressed: () async {
                          final next = state.copyWith(
                            groupIds: sel,
                            partitionsIncluded: partitionsIncluded,
                            inViewportOnly: inViewportOnly,
                          );
                          ref.read(globalFilterProvider.notifier).state = next;
                          await ref.read(filterPersistence).save(next);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
