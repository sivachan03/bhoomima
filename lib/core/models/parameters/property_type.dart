import 'package:isar/isar.dart';

part 'property_type.g.dart';

@collection
class PropertyType {
  Id id = Isar.autoIncrement;
  late String code; // 'mapped' | 'locationOnly'
  bool locked = true;
}

// NOTE: Run build runner to generate *.g.dart files:
// dart run build_runner build --delete-conflicting-outputs
