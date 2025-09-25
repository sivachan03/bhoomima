import 'package:isar/isar.dart';
part 'group_template.g.dart';

@collection
class GroupTemplate {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true, caseSensitive: false)
  late String code; // BORDERS, PARTITIONS, LANDMARKS, PATHS

  String nameEn = '';
  String? category; // border | partition | landmark | path | user
  bool locked = true; // template-driven default groups locked
  DateTime updatedAt = DateTime.now();
}
