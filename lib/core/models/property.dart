import 'package:isar/isar.dart';
part 'property.g.dart';

@collection
class Property {
  Id id = Isar.autoIncrement;
  late String name; // e.g., "My Farm"

  // Existing field used across the app (keep for compatibility): 'mapped' | 'locationOnly'
  late String type;
  // New flexible code (aligns with DB-backed PropertyType codes). We'll populate both when saving.
  String? typeCode;

  // Address
  String? address; // existing
  String? addressLine; // new canonical field; we'll keep both in sync
  String? street;
  String? city;
  String? pin;

  // Reference location (center/entry) in WGS84
  double? lat; // nullable until set
  double? lon;

  // Freeform directions for reaching the place
  String? directions;

  // Optional local projection origin (cached per property)
  double? originLat;
  double? originLon;
  double? originAlt;
}
