import 'package:isar/isar.dart';
part 'icon_item.g.dart';

@collection
class IconItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String code; // e.g., 'tree'

  String? labelEn;
  String? category;
  String? assetPath; // assets/icons/tree.svg
  bool deprecated = false;

  DateTime updatedAt = DateTime.now();
}
