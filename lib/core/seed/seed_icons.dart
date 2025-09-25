import 'package:isar/isar.dart';
import '../models/icon_item.dart';
import '../models/point_group.dart';

class SeedIcons {
  static const _items = [
    ['border', 'Border', 'general', 'assets/icons/border.svg'],
    ['partition', 'Partition', 'general', 'assets/icons/partition.svg'],
    ['landmark', 'Landmark', 'general', 'assets/icons/landmark.svg'],
    ['path', 'Path', 'general', 'assets/icons/path.svg'],
    ['water', 'Water', 'infra', 'assets/icons/water.svg'],
    ['pump', 'Pump', 'infra', 'assets/icons/pump.svg'],
    ['gate', 'Gate', 'infra', 'assets/icons/gate.svg'],
    ['hut', 'Hut', 'infra', 'assets/icons/hut.svg'],
    ['tree', 'Tree', 'plant', 'assets/icons/tree.svg'],
    ['rock', 'Rock', 'land', 'assets/icons/rock.svg'],
    ['compost', 'Compost', 'soil', 'assets/icons/compost.svg'],
    ['storage', 'Storage', 'infra', 'assets/icons/storage.svg'],
    ['danger', 'Danger', 'alert', 'assets/icons/danger.svg'],
    ['well', 'Well', 'infra', 'assets/icons/well.svg'],
    ['canal', 'Canal', 'water', 'assets/icons/canal.svg'],
    ['drip', 'Drip', 'irrigation', 'assets/icons/drip.svg'],
    ['sprayer', 'Sprayer', 'irrigation', 'assets/icons/sprayer.svg'],
    ['tractor', 'Tractor', 'equipment', 'assets/icons/tractor.svg'],
    ['animal', 'Animal', 'livestock', 'assets/icons/animal.svg'],
    ['nursery', 'Nursery', 'plant', 'assets/icons/nursery.svg'],
    ['shade', 'Shade', 'infra', 'assets/icons/shade.svg'],
    ['road', 'Road', 'infra', 'assets/icons/road.svg'],
    ['fence', 'Fence', 'infra', 'assets/icons/fence.svg'],
    ['house', 'House', 'infra', 'assets/icons/house.svg'],
  ];

  static Future<void> run(Isar db) async {
    await db.writeTxn(() async {
      for (final it in _items) {
        final row = IconItem()
          ..code = it[0]
          ..labelEn = it[1]
          ..category = it[2]
          ..assetPath = it[3]
          ..deprecated = false
          ..updatedAt = DateTime.now();
        await db.iconItems.put(row);
      }
    });
  }

  static Future<void> ensureDefaultGroupIcons(Isar db, int propertyId) async {
    final groups = await db.pointGroups
        .filter()
        .propertyIdEqualTo(propertyId)
        .findAll();
    await db.writeTxn(() async {
      for (final g in groups) {
        if ((g.iconCode ?? '').isEmpty) {
          switch ((g.category ?? '').toLowerCase()) {
            case 'border':
              g.iconCode = 'border';
              break;
            case 'partition':
              g.iconCode = 'partition';
              break;
            case 'landmark':
              g.iconCode = 'landmark';
              break;
            case 'path':
              g.iconCode = 'path';
              break;
            default:
              break;
          }
          await db.pointGroups.put(g);
        }
      }
    });
  }
}
