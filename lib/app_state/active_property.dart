import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../core/db/isar_service.dart';
import '../core/models/app_settings.dart';
import '../core/models/property.dart';

final activePropertyProvider =
    StateNotifierProvider<ActiveProperty, AsyncValue<Property?>>(
      (ref) => ActiveProperty(),
    );

class ActiveProperty extends StateNotifier<AsyncValue<Property?>> {
  ActiveProperty() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final isar = await IsarService.open();
    final s = await isar.appSettings.get(1);
    if (s?.lastActivePropertyId != null) {
      final p = await isar.propertys.get(s!.lastActivePropertyId!);
      if (p != null) {
        state = AsyncValue.data(p);
        return;
      }
    }
    final all = await isar.propertys.where().findAll();
    if (all.isEmpty) {
      final p = Property()
        ..name = 'My Farm'
        ..typeCode = 'unmapped'
        ..type = 'locationOnly';
      await isar.writeTxn(() async {
        final id = await isar.propertys.put(p);
        p.id = id;
        final ns = (s ?? AppSettings())
          ..id = 1
          ..lastActivePropertyId = p.id
          ..updatedAt = DateTime.now();
        await isar.appSettings.put(ns);
      });
      state = AsyncValue.data(p);
    } else {
      state = AsyncValue.data(all.first);
    }
  }

  Future<void> setActive(Property p) async {
    state = AsyncValue.data(p);
    final isar = await IsarService.open();
    await isar.writeTxn(() async {
      final s = await isar.appSettings.get(1) ?? AppSettings()
        ..id = 1;
      s.lastActivePropertyId = p.id;
      s.updatedAt = DateTime.now();
      await isar.appSettings.put(s);
    });
  }

  Future<void> onPropertyDeleted(int deletedId) async {
    final isar = await IsarService.open();
    final current = state.value;
    if (current?.id == deletedId) {
      final all = await isar.propertys.where().findAll();
      final next = all.isNotEmpty ? all.first : null;
      state = AsyncValue.data(next);
      await isar.writeTxn(() async {
        final s = await isar.appSettings.get(1) ?? AppSettings()
          ..id = 1;
        s.lastActivePropertyId = next?.id;
        s.updatedAt = DateTime.now();
        await isar.appSettings.put(s);
      });
    }
  }
}
