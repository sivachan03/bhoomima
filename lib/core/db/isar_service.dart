import 'package:isar/isar.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/property.dart' as property_model;
import '../models/farmer.dart' as farmer_model;
import '../models/point_group.dart' as point_group_model;
import '../models/point.dart' as point_model;
import '../models/party.dart' as party_model;
import '../models/parameters/log_type.dart' as log_type_model;
import '../models/parameters/log_subtype.dart' as log_subtype_model;
import '../models/parameters/point_group_category.dart' as pg_cat_model;
import '../models/parameters/property_type.dart' as prop_type_model;
import '../models/parameters/unit_def.dart' as unit_def_model;
import '../models/system_event.dart' as system_event_model;
import '../models/app_settings.dart' as app_settings_model;
import '../models/catalog_item.dart' as catalog_item_model;
import '../models/group_template.dart' as group_template_model;
import '../models/icon_item.dart' as icon_item_model;

class IsarService {
  static Isar? _isar;
  static Future<Isar> open() async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        app_settings_model.AppSettingsSchema,
        property_model.PropertyCollectionSchema,
        catalog_item_model.CatalogItemSchema,
        group_template_model.GroupTemplateSchema,
        icon_item_model.IconItemSchema,
        farmer_model.FarmerSchema,
        system_event_model.SystemEventSchema,
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
      // Enable Isar Inspector only in debug builds
      inspector: kDebugMode,
    );
    return _isar!;
  }
}
