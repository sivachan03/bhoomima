import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/property.dart';
import 'base_repo.dart';

final propertyRepoProvider = Provider<PropertyRepo>((ref) => PropertyRepo());
final propertiesProvider = StreamProvider<List<Property>>((ref) async* {
  final repo = ref.read(propertyRepoProvider);
  yield* repo.watchAll();
});

class PropertyRepo extends BaseRepo {
  Future<int> upsert(Property p) async {
    final isar = await db;
    return isar.writeTxn(() => isar.propertys.put(p));
  }

  Future<void> delete(Id id) async {
    final isar = await db;
    await isar.writeTxn(() => isar.propertys.delete(id));
  }


  Stream<List<Property>> watchAll() async* {
    final isar = await db;
    yield* isar.propertys.where().watch(fireImmediately: true);
  }
}