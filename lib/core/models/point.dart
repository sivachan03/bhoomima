import 'package:isar/isar.dart';
part 'point.g.dart';

@collection
class Point {
  Id id = Isar.autoIncrement;
  late int groupId;
  late String name; // required human label
  late double lat;
  late double lon;
  double? x;
  double? y;
  double? hAcc;
  double? stability;
  DateTime? createdAt;
  String? iconCode; // optional point-level override
}
