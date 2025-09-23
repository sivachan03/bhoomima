import 'package:shared_preferences/shared_preferences.dart';

class RecipientPrefs {
  static String _key(int propertyId) => 'bm.recipient.property.$propertyId';

  static Future<void> saveLastForProperty(int propertyId, String phone) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key(propertyId), phone);
  }

  static Future<String?> getLastForProperty(int propertyId) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_key(propertyId));
  }
}
