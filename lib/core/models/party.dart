import 'package:isar/isar.dart';
part 'party.g.dart';

@collection
class Party {
  Id id = Isar.autoIncrement;
  late String name;
  // worker | vendor | buyer | other
  late String category;
  String? phone;
  String? note;
}
