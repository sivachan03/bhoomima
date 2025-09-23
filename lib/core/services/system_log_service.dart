import 'dart:convert';
import 'package:isar/isar.dart';
import '../models/system_event.dart';

class SystemLogService {
  final Isar db;
  SystemLogService(this.db);

  Future<void> log(
    String type,
    String subType,
    Map<String, dynamic> payload, {
    String? description,
  }) async {
    final e = SystemEvent()
      ..type = type
      ..subType = subType
      ..description = description ?? subType
      ..payloadJson = jsonEncode(payload)
      ..at = DateTime.now();
    await db.writeTxn(() => db.systemEvents.put(e));
  }

  Stream<List<SystemEvent>> watchRecent({int limit = 200}) {
    return db.systemEvents
        .where()
        .sortByAtDesc()
        .limit(limit)
        .watch(fireImmediately: true);
  }
}
