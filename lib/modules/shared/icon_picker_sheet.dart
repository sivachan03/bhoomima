import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:isar/isar.dart';
import '../../core/db/isar_service.dart';
import '../../core/models/icon_item.dart';

Future<String?> openIconPickerSheet(
  BuildContext context,
  WidgetRef ref, {
  String? initial,
}) async {
  final db = await IsarService.open();
  final items = await db.iconItems.filter().deprecatedEqualTo(false).findAll();
  if (!context.mounted) return null;
  String query = '';
  return await showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: StatefulBuilder(
        builder: (ctx, setState) {
          final filtered = items
              .where(
                (e) =>
                    query.isEmpty ||
                    (e.labelEn ?? '').toLowerCase().contains(
                      query.toLowerCase(),
                    ) ||
                    e.code.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search icons',
                  ),
                  onChanged: (v) => setState(() => query = v),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: GridView.count(
                    crossAxisCount: 5,
                    shrinkWrap: true,
                    children: [
                      for (final it in filtered)
                        InkWell(
                          onTap: () => Navigator.pop(ctx, it.code),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                it.assetPath ?? '',
                                width: 28,
                                height: 28,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                it.labelEn ?? it.code,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}
