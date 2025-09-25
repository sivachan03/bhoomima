import 'package:isar/isar.dart';
import '../models/catalog_item.dart';
import '../models/group_template.dart';
import '../models/point_group.dart';
import '../models/property.dart';

class SeedCatalog {
  static Future<void> run(Isar db) async {
    await db.writeTxn(() async {
      // Event Types
      await _upsert(
        db,
        kind: 'EVENT_TYPE',
        code: 'EVT.EXPENSE',
        label: 'Expense',
      );
      await _upsert(
        db,
        kind: 'EVENT_TYPE',
        code: 'EVT.INCOME',
        label: 'Income',
      );
      await _upsert(
        db,
        kind: 'EVENT_TYPE',
        code: 'EVT.IRRIGATION',
        label: 'Irrigation',
      );
      await _upsert(
        db,
        kind: 'EVENT_TYPE',
        code: 'EVT.FERTILIZATION',
        label: 'Fertilization',
      );
      await _upsert(
        db,
        kind: 'EVENT_TYPE',
        code: 'EVT.HEALTH',
        label: 'Plant Health',
      );
      await _upsert(db, kind: 'EVENT_TYPE', code: 'EVT.LABOR', label: 'Labor');
      await _upsert(
        db,
        kind: 'EVENT_TYPE',
        code: 'EVT.OBS',
        label: 'Observation',
      );
      // Event Subtypes
      await _upsert(
        db,
        kind: 'EVENT_SUBTYPE',
        code: 'SUB.MANURE',
        label: 'Manure',
        parentCode: 'EVT.FERTILIZATION',
      );
      await _upsert(
        db,
        kind: 'EVENT_SUBTYPE',
        code: 'SUB.PESTICIDE_APP',
        label: 'Pesticide Application',
        parentCode: 'EVT.HEALTH',
      );
      await _upsert(
        db,
        kind: 'EVENT_SUBTYPE',
        code: 'SUB.SEED',
        label: 'Seed',
        parentCode: 'EVT.EXPENSE',
      );
      await _upsert(
        db,
        kind: 'EVENT_SUBTYPE',
        code: 'SUB.WAGE',
        label: 'Wage',
        parentCode: 'EVT.LABOR',
      );

      // Group Templates
      await _upsertTemplate(
        db,
        code: 'BORDERS',
        name: 'Borders',
        category: 'border',
        locked: true,
      );
      await _upsertTemplate(
        db,
        code: 'PARTITIONS',
        name: 'Partitions',
        category: 'partition',
        locked: true,
      );
      await _upsertTemplate(
        db,
        code: 'LANDMARKS',
        name: 'Landmarks',
        category: 'landmark',
        locked: true,
      );
      await _upsertTemplate(
        db,
        code: 'PATHS',
        name: 'Paths',
        category: 'path',
        locked: true,
      );
    });
  }

  static Future<void> ensureDefaultGroupsForProperty(
    Isar db,
    Property property,
  ) async {
    final templates = await db.groupTemplates.where().findAll();
    await db.writeTxn(() async {
      for (final t in templates) {
        final exists = await db.pointGroups
            .filter()
            .propertyIdEqualTo(property.id)
            .and()
            .templateCodeEqualTo(t.code)
            .findFirst();
        if (exists == null) {
          final g = PointGroup()
            ..propertyId = property.id
            ..name = t.nameEn
            ..category = t.category
            ..locked = t.locked
            ..templateCode = t.code
            ..defaultFlag = true;
          await db.pointGroups.put(g);
        }
      }
    });
  }

  static Future<void> _upsert(
    Isar db, {
    required String kind,
    required String code,
    required String label,
    String? parentCode,
  }) async {
    final existing = await db.catalogItems
        .filter()
        .codeEqualTo(code)
        .findFirst();
    if (existing != null) {
      existing.kind = kind;
      existing.parentCode = parentCode;
      existing.labelEn = label;
      existing.locked = true;
      existing.updatedAt = DateTime.now();
      await db.catalogItems.put(existing);
    } else {
      final it = CatalogItem()
        ..kind = kind
        ..code = code
        ..parentCode = parentCode
        ..labelEn = label
        ..locked = true
        ..updatedAt = DateTime.now();
      await db.catalogItems.put(it);
    }
  }

  static Future<void> _upsertTemplate(
    Isar db, {
    required String code,
    required String name,
    String? category,
    bool locked = true,
  }) async {
    final existing = await db.groupTemplates
        .filter()
        .codeEqualTo(code)
        .findFirst();
    if (existing != null) {
      existing.nameEn = name;
      existing.category = category;
      existing.locked = locked;
      existing.updatedAt = DateTime.now();
      await db.groupTemplates.put(existing);
    } else {
      final t = GroupTemplate()
        ..code = code
        ..nameEn = name
        ..category = category
        ..locked = locked
        ..updatedAt = DateTime.now();
      await db.groupTemplates.put(t);
    }
  }
}
