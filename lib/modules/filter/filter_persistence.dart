import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'global_filter.dart';

const _kKey = 'global_filter_v1';

final filterPersistence = Provider((ref) => FilterPersistence(ref));

class FilterPersistence {
  final Ref ref;
  FilterPersistence(this.ref);

  Future<void> save(GlobalFilterState state) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kKey, GlobalFilterState.encode(state));
  }

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kKey);
    final loaded = GlobalFilterState.decode(raw);
    ref.read(globalFilterProvider.notifier).state = loaded;
  }
}
