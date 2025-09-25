import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/isar_service.dart';
import '../../core/models/property.dart';
import '../../core/models/point.dart';

Future<void> savePointAndToast({
  required BuildContext context,
  required WidgetRef ref,
  required Property property,
  required String name,
  int? groupId,
  required double lat,
  required double lon,
  String source = 'gps',
  String? iconCode,
}) async {
  final isar = await IsarService.open();
  final p = Point()
    ..groupId = (groupId ?? 0)
    ..name = name
    ..lat = lat
    ..lon = lon
    ..createdAt = DateTime.now()
    ..iconCode = iconCode;
  try {
    await isar.writeTxn(() async {
      await isar.points.put(p);
    });
    final count = await isar.points.count();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Point saved. Points in property: $count')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }
}
