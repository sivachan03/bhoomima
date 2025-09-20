import 'package:isar/isar.dart';

part 'point_group_category.g.dart';

@collection
class PointGroupCategory {
  Id id = Isar.autoIncrement;
  late String code; // 'border' | 'partition' | 'landmark' | 'path'
  bool locked = true;
}

// NOTE: Run build runner to generate *.g.dart files:
// dart run build_runner build --delete-conflicting-outputs
