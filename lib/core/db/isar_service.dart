import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/property.dart' as property_model;
import '../models/point_group.dart' as point_group_model;
import '../models/point.dart' as point_model;
import '../models/party.dart' as party_model;
import '../models/parameters/log_type.dart' as log_type_model;
import '../models/parameters/log_subtype.dart' as log_subtype_model;
import '../models/parameters/point_group_category.dart' as pg_cat_model;
import '../models/parameters/property_type.dart' as prop_type_model;
import '../models/parameters/unit_def.dart' as unit_def_model;

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
        // Parameters
        log_type_model.LogTypeSchema,
        log_subtype_model.LogSubtypeSchema,
        pg_cat_model.PointGroupCategorySchema,
        prop_type_model.PropertyTypeSchema,
        unit_def_model.UnitDefSchema,
      ],
      directory: dir.path,
      inspector: false,
    );
    return _isar!;
  }
}
