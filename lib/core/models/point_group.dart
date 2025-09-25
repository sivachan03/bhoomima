import 'package:isar/isar.dart';
part 'point_group.g.dart';

@collection
class PointGroup {
  Id id = Isar.autoIncrement;
  late int propertyId;
  String name = '';
  String? category; // may be null for future dynamic types
  bool locked = false; // true for system/template-created groups
  String? templateCode; // link back to GroupTemplate.code
  bool defaultFlag = false; // legacy flag kept for backward compatibility
}
