import 'package:isar/isar.dart';
import '../models/farmer.dart';
import '../models/property.dart';
import 'base_repo.dart';

class FarmerRepo extends BaseRepo {
  Stream<List<Farmer>> watchAll() async* {
    final isar = await db;
    yield* isar.farmers.where().watch(fireImmediately: true);
  }

  Future<List<Farmer>> listAll() async {
    final isar = await db;
    return isar.farmers.where().findAll();
  }

  Future<int> upsert(Farmer f) async {
    final isar = await db;
    return isar.writeTxn(() => isar.farmers.put(f));
  }

  Future<bool> delete(int id) async {
    final isar = await db;
    return isar.writeTxn(() => isar.farmers.delete(id));
  }

  Future<Farmer?> getById(int id) async {
    final isar = await db;
    return isar.farmers.get(id);
  }

  Future<bool> canDelete(int farmerId) async {
    final isar = await db;
    final cnt = await isar.propertys
        .where()
        .filter()
        .ownerIdEqualTo(farmerId)
        .count();
    return cnt == 0;
  }

  Future<void> deleteIfOrThrow(int farmerId) async {
    final isar = await db;
    final cnt = await isar.propertys
        .where()
        .filter()
        .ownerIdEqualTo(farmerId)
        .count();
    if (cnt > 0) {
      throw Exception('DELETE_BLOCKED: farmer has $cnt linked properties');
    }
    await isar.writeTxn(() => isar.farmers.delete(farmerId));
  }

  Future<List<Property>> listLinkedProperties(int farmerId) async {
    final isar = await db;
    return isar.propertys.where().filter().ownerIdEqualTo(farmerId).findAll();
  }
}
