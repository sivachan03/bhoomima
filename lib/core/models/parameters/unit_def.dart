import 'package:isar/isar.dart';

part 'unit_def.g.dart';

@collection
class UnitDef {
  Id id = Isar.autoIncrement;
  late String code; // 'm','m2','acre','hectare','degC'
  late String kind; // 'distance','area','temperature'
  bool locked = true;
}

// NOTE: Run build runner to generate *.g.dart files:
// dart run build_runner build --delete-conflicting-outputs
