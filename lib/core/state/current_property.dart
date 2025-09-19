import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final currentPropertyIdProvider =
    StateNotifierProvider<CurrentPropertyId, int?>(
      (ref) => CurrentPropertyId()..load(),
    );

class CurrentPropertyId extends StateNotifier<int?> {
  CurrentPropertyId() : super(null);
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getInt('currentPropertyId');
    // Avoid overwriting a value that may have been set during bootstrap
    if (state == null) {
      state = stored;
    }
  }

  Future<void> set(int id) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('currentPropertyId', id);
    state = id;
  }
}
