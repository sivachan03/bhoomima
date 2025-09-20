import 'dart:convert';
import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:isar/isar.dart';

import '../db/isar_service.dart';
import '../models/parameters/log_type.dart';
import '../models/parameters/log_subtype.dart';
import '../models/parameters/point_group_category.dart';
import '../models/parameters/property_type.dart';
import '../models/parameters/unit_def.dart';

class ParametersRepo {
  Future<Isar> get _db async => await IsarService.open();

  // --- Cached broadcast streams with replay ---
  StreamController<List<LogType>>? _logTypesCtrl;
  List<LogType>? _logTypesLast;

  Stream<List<LogType>> watchLogTypes() {
    if (_logTypesCtrl != null) return _logTypesCtrl!.stream;
    _logTypesCtrl = StreamController<List<LogType>>.broadcast(
      onListen: () {
        if (_logTypesLast != null) {
          scheduleMicrotask(() => _logTypesCtrl!.add(_logTypesLast!));
        }
      },
    );
    () async {
      final isar = await _db;
      isar.logTypes.where().watch(fireImmediately: true).listen((data) {
        _logTypesLast = data;
        _logTypesCtrl?.add(data);
      }, onError: _logTypesCtrl?.addError);
    }();
    return _logTypesCtrl!.stream;
  }

  final Map<int, StreamController<List<LogSubtype>>> _logSubtypesCtrls = {};
  final Map<int, List<LogSubtype>?> _logSubtypesLast = {};

  Stream<List<LogSubtype>> watchLogSubtypes(int typeId) {
    final existing = _logSubtypesCtrls[typeId];
    if (existing != null) return existing.stream;
    final ctrl = StreamController<List<LogSubtype>>.broadcast();
    ctrl.onListen = () {
      final cached = _logSubtypesLast[typeId];
      if (cached != null) {
        scheduleMicrotask(() => ctrl.add(cached));
      }
    };
    _logSubtypesCtrls[typeId] = ctrl;
    () async {
      final isar = await _db;
      isar.logSubtypes
          .filter()
          .typeIdEqualTo(typeId)
          .watch(fireImmediately: true)
          .listen((data) {
            _logSubtypesLast[typeId] = data;
            _logSubtypesCtrls[typeId]?.add(data);
          }, onError: ctrl.addError);
    }();
    return ctrl.stream;
  }

  StreamController<List<PointGroupCategory>>? _groupCatsCtrl;
  List<PointGroupCategory>? _groupCatsLast;
  Stream<List<PointGroupCategory>> watchGroupCats() {
    if (_groupCatsCtrl != null) return _groupCatsCtrl!.stream;
    _groupCatsCtrl = StreamController<List<PointGroupCategory>>.broadcast(
      onListen: () {
        if (_groupCatsLast != null) {
          scheduleMicrotask(() => _groupCatsCtrl!.add(_groupCatsLast!));
        }
      },
    );
    () async {
      final isar = await _db;
      isar.pointGroupCategorys.where().watch(fireImmediately: true).listen((
        data,
      ) {
        _groupCatsLast = data;
        _groupCatsCtrl?.add(data);
      }, onError: _groupCatsCtrl?.addError);
    }();
    return _groupCatsCtrl!.stream;
  }

  StreamController<List<PropertyType>>? _propTypesCtrl;
  List<PropertyType>? _propTypesLast;
  Stream<List<PropertyType>> watchPropertyTypes() {
    if (_propTypesCtrl != null) return _propTypesCtrl!.stream;
    _propTypesCtrl = StreamController<List<PropertyType>>.broadcast(
      onListen: () {
        if (_propTypesLast != null) {
          scheduleMicrotask(() => _propTypesCtrl!.add(_propTypesLast!));
        }
      },
    );
    () async {
      final isar = await _db;
      isar.propertyTypes.where().watch(fireImmediately: true).listen((data) {
        _propTypesLast = data;
        _propTypesCtrl?.add(data);
      }, onError: _propTypesCtrl?.addError);
    }();
    return _propTypesCtrl!.stream;
  }

  StreamController<List<UnitDef>>? _unitsCtrl;
  List<UnitDef>? _unitsLast;
  Stream<List<UnitDef>> watchUnits() {
    if (_unitsCtrl != null) return _unitsCtrl!.stream;
    _unitsCtrl = StreamController<List<UnitDef>>.broadcast(
      onListen: () {
        if (_unitsLast != null) {
          scheduleMicrotask(() => _unitsCtrl!.add(_unitsLast!));
        }
      },
    );
    () async {
      final isar = await _db;
      isar.unitDefs.where().watch(fireImmediately: true).listen((data) {
        _unitsLast = data;
        _unitsCtrl?.add(data);
      }, onError: _unitsCtrl?.addError);
    }();
    return _unitsCtrl!.stream;
  }

  // CRUD (minimal)
  Future<int> addLogType(String code, {bool locked = false}) async {
    final isar = await _db;
    final x = LogType()
      ..code = code
      ..locked = locked;
    return isar.writeTxn(() => isar.logTypes.put(x));
  }

  Future<int> addLogSubtype(
    int typeId,
    String code, {
    bool locked = false,
  }) async {
    final isar = await _db;
    final x = LogSubtype()
      ..typeId = typeId
      ..code = code
      ..locked = locked;
    return isar.writeTxn(() => isar.logSubtypes.put(x));
  }

  Future<void> deleteLogType(int id) async {
    final isar = await _db;
    final count = await isar.logSubtypes.filter().typeIdEqualTo(id).count();
    if (count > 0) {
      throw Exception('Has $count subtypes; reassign or delete them first.');
    }
    await isar.writeTxn(() => isar.logTypes.delete(id));
  }

  Future<void> deleteLogSubtype(int id) async {
    final isar = await _db;
    await isar.writeTxn(() => isar.logSubtypes.delete(id));
  }

  // Seed from CSV asset (e.g., assets/i18n/BM-55_parameters_seed.csv)
  Future<void> seedFromCsvAsset(String assetPath) async {
    final isar = await _db;
    final csv = await rootBundle.loadString(assetPath);
    final lines = const LineSplitter().convert(csv);
    if (lines.isEmpty) return;
    final header = lines.first.split(',').map((s) => s.trim()).toList();
    final idx = {for (var i = 0; i < header.length; i++) header[i]: i};

    await isar.writeTxn(() async {
      for (var i = 1; i < lines.length; i++) {
        final row = _safeSplit(lines[i]);
        if (row.length < header.length) continue;
        final table = row[idx['table']!];
        final code = row[idx['code']!];
        final locked = row[idx['locked']!].toLowerCase() == 'true';

        switch (table) {
          case 'PointGroupCategory':
            if (await isar.pointGroupCategorys
                    .filter()
                    .codeEqualTo(code)
                    .count() ==
                0) {
              await isar.pointGroupCategorys.put(
                PointGroupCategory()
                  ..code = code
                  ..locked = locked,
              );
            }
            break;
          case 'PropertyType':
            if (await isar.propertyTypes.filter().codeEqualTo(code).count() ==
                0) {
              await isar.propertyTypes.put(
                PropertyType()
                  ..code = code
                  ..locked = locked,
              );
            }
            break;
          case 'LogType':
            if (await isar.logTypes.filter().codeEqualTo(code).count() == 0) {
              await isar.logTypes.put(
                LogType()
                  ..code = code
                  ..locked = locked,
              );
            }
            break;
          case 'LogSubtype':
            // Here we map by known types already inserted (e.g., EXPENSE).
            final type = await isar.logTypes
                .filter()
                .codeEqualTo('EXPENSE')
                .findFirst();
            final typeId = type?.id ?? 0;
            if (typeId != 0 &&
                await isar.logSubtypes
                        .filter()
                        .typeIdEqualTo(typeId)
                        .codeEqualTo(code)
                        .count() ==
                    0) {
              await isar.logSubtypes.put(
                LogSubtype()
                  ..typeId = typeId
                  ..code = code
                  ..locked = locked,
              );
            }
            break;
          case 'UnitDef':
            final kind = row[idx['category']!]; // 'distance','area', etc.
            if (await isar.unitDefs.filter().codeEqualTo(code).count() == 0) {
              await isar.unitDefs.put(
                UnitDef()
                  ..code = code
                  ..kind = kind
                  ..locked = locked,
              );
            }
            break;
        }
      }
    });
  }

  List<String> _safeSplit(String line) {
    // naive CSV split (no quoted commas in our seed)
    return line.split(',').map((s) => s.trim()).toList();
  }
}
