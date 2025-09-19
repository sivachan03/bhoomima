import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import '../models/party.dart';
import 'base_repo.dart';

final partyRepoProvider = Provider<PartyRepo>((ref) => PartyRepo());
final partiesProvider = StreamProvider<List<Party>>((ref) async* {
  final repo = ref.read(partyRepoProvider);
  yield* repo.watchAll();
});

class PartyRepo extends BaseRepo {
  Future<int> upsert(Party p) async {
    final isar = await db;
    return isar.writeTxn(() => isar.partys.put(p));
  }

  Future<void> delete(Id id) async {
    final isar = await db;
    await isar.writeTxn(() => isar.partys.delete(id));
  }

  Stream<List<Party>> watchAll() async* {
    final isar = await db;
    yield* isar.partys.where().watch(fireImmediately: true);
  }
}