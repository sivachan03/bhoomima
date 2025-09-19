import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/property.dart' as property_model;
import '../models/point_group.dart' as point_group_model;
import '../models/point.dart' as point_model;
import '../models/party.dart' as party_model;

class IsarService {
  static Isar? _isar;
  static Future<Isar> open() async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        property_model.PropertyCollectionSchema,
        point_group_model.PointGroupSchema,
        point_model.PointSchema,
        party_model.PartySchema,
      ],
      directory: dir.path,
      inspector: false,
    );
    return _isar!;
  }
}
