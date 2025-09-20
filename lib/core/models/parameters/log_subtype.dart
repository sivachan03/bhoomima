import 'package:isar/isar.dart';

part 'log_subtype.g.dart';

@collection
class LogSubtype {
  Id id = Isar.autoIncrement;
  late int typeId; // parent LogType.id
  late String code; // 'FERTILIZER'
  bool locked = false;
}

// NOTE: Run build runner to generate *.g.dart files:
// dart run build_runner build --delete-conflicting-outputs
