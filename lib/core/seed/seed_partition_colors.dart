import 'package:isar/isar.dart';
import '../models/point_group.dart';

class SeedPartitionColors {
  static const _palette = [
    '#A5D6A780', // green 200 + alpha
    '#90CAF980', // blue 200
    '#FFCC8080', // orange 200
    '#CE93D880', // purple 200
    '#80CBC480', // teal 200
    '#E6EE9C80', // lime 200
    '#F48FB180', // pink 200
    '#B39DDB80', // deep purple 200
  ];

  static Future<void> apply(Isar db, int propertyId) async {
    final parts = await db.pointGroups
        .filter()
        .propertyIdEqualTo(propertyId)
        .and()
        .categoryEqualTo('partition')
        .findAll();
    int idx = 0;
    await db.writeTxn(() async {
      for (final g in parts) {
        if ((g.colorHex ?? '').isEmpty) {
          g.colorHex = _palette[idx % _palette.length];
          idx++;
          await db.pointGroups.put(g);
        }
      }
    });
  }
}
