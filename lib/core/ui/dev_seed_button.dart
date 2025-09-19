import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/isar_service.dart';
import '../models/point_group.dart';
import '../models/point.dart';
import '../state/current_property.dart';

class DevSeedButton extends ConsumerWidget {
  const DevSeedButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.bug_report),
      tooltip: 'Seed sample data',

      onPressed: () async {
        final pid = ref.read(currentPropertyIdProvider);
        if (pid == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No current property selected')));
          return;
        }

        final isar = await IsarService.open();
        await isar.writeTxn(() async {
          final g = PointGroup()
            ..propertyId = pid
            ..name = 'Dev Group'
            ..category = 'landmark'
            ..defaultFlag = false;
          final gid = await isar.pointGroups.put(g);

          final p = Point()
            ..groupId = gid
            ..name = 'Dev Point 1'
            ..lat = 10.0
            ..lon = 76.0;
          await isar.points.put(p);
        });

        // feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Seeded 1 group + 1 point')));
        }
      },
    );
  }
}