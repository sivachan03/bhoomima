import 'package:isar/isar.dart';
part 'property.g.dart';

@collection
class Property {
  Id id = Isar.autoIncrement;
  late String name;
  // mapped | locationOnly
  late String type;
  String? address;
  String? street;
  String? city;
  String? pin;
  double? lat;
  double? lon;
  String? directions;
}
