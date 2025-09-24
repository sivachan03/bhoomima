import 'package:isar/isar.dart';
part 'app_settings.g.dart';

@collection
class AppSettings {
  Id id = 1;
  int? lastActivePropertyId;
  DateTime updatedAt = DateTime.now();
}
