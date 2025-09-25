import 'package:isar/isar.dart';
part 'catalog_item.g.dart';

@collection
class CatalogItem {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true, caseSensitive: false)
  late String code;

  @Index(caseSensitive: false)
  late String kind; // e.g. EVENT_TYPE, EVENT_SUBTYPE

  String? parentCode; // for subtype linking
  String labelEn = '';
  bool locked = true; // catalog rows are system-managed
  DateTime updatedAt = DateTime.now();
}
