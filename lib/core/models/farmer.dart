import 'package:isar/isar.dart';

part 'farmer.g.dart';

@collection
class Farmer {
  Id id = Isar.autoIncrement;
  late String name;
  String? mobile;
  String? mobileE164;
  String? whatsapp;
  String? whatsappE164;
  String? village;
  String? taluk;
  String? preferredLanguageCode;
  String? notes;
  bool consentExport = true;
  bool consentWhatsApp = true;
}
