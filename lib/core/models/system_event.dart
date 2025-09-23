import 'package:isar/isar.dart';

part 'system_event.g.dart';

@collection
class SystemEvent {
  Id id = Isar.autoIncrement;
  // STRUCTURE, GPS, PARTITION, DIARY, CROP, SYSTEM
  late String type;
  // e.g., LINK_OWNER, UNLINK_OWNER, EDIT_PROPERTY, DELETE_BLOCKED
  @Index(type: IndexType.hash)
  late String subType;

  // Short human-readable text
  String? description;

  // JSON payload as string for flexibility
  String? payloadJson;

  DateTime at = DateTime.now();
}
