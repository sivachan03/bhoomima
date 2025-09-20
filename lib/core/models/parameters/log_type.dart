import 'package:isar/isar.dart';

part 'log_type.g.dart';

@collection
class LogType {
  Id id = Isar.autoIncrement;
  late String code; // 'EXPENSE' (stable key)
  bool locked = false;
}

// NOTE: Run build runner to generate *.g.dart files:
// dart run build_runner build --delete-conflicting-outputs
