import 'package:isar/isar.dart';
part 'point_group.g.dart';

@collection
class PointGroup {
  Id id = Isar.autoIncrement;
  late int propertyId;
  late String name;
  // border | partition | landmark | path | user
  late String category;
  // default groups locked
  late bool defaultFlag;
}
