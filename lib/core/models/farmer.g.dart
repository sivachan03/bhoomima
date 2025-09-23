// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'farmer.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFarmerCollection on Isar {
  IsarCollection<Farmer> get farmers => this.collection();
}

const FarmerSchema = CollectionSchema(
  name: r'Farmer',
  id: 6642196998099944333,
  properties: {
    r'consentExport': PropertySchema(
      id: 0,
      name: r'consentExport',
      type: IsarType.bool,
    ),
    r'consentWhatsApp': PropertySchema(
      id: 1,
      name: r'consentWhatsApp',
      type: IsarType.bool,
    ),
    r'mobile': PropertySchema(
      id: 2,
      name: r'mobile',
      type: IsarType.string,
    ),
    r'mobileE164': PropertySchema(
      id: 3,
      name: r'mobileE164',
      type: IsarType.string,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'notes': PropertySchema(
      id: 5,
      name: r'notes',
      type: IsarType.string,
    ),
    r'preferredLanguageCode': PropertySchema(
      id: 6,
      name: r'preferredLanguageCode',
      type: IsarType.string,
    ),
    r'taluk': PropertySchema(
      id: 7,
      name: r'taluk',
      type: IsarType.string,
    ),
    r'village': PropertySchema(
      id: 8,
      name: r'village',
      type: IsarType.string,
    ),
    r'whatsapp': PropertySchema(
      id: 9,
      name: r'whatsapp',
      type: IsarType.string,
    ),
    r'whatsappE164': PropertySchema(
      id: 10,
      name: r'whatsappE164',
      type: IsarType.string,
    )
  },
  estimateSize: _farmerEstimateSize,
  serialize: _farmerSerialize,
  deserialize: _farmerDeserialize,
  deserializeProp: _farmerDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _farmerGetId,
  getLinks: _farmerGetLinks,
  attach: _farmerAttach,
  version: '3.1.0+1',
);

int _farmerEstimateSize(
  Farmer object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.mobile;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.mobileE164;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.notes;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.preferredLanguageCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.taluk;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.village;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.whatsapp;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.whatsappE164;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _farmerSerialize(
  Farmer object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.consentExport);
  writer.writeBool(offsets[1], object.consentWhatsApp);
  writer.writeString(offsets[2], object.mobile);
  writer.writeString(offsets[3], object.mobileE164);
  writer.writeString(offsets[4], object.name);
  writer.writeString(offsets[5], object.notes);
  writer.writeString(offsets[6], object.preferredLanguageCode);
  writer.writeString(offsets[7], object.taluk);
  writer.writeString(offsets[8], object.village);
  writer.writeString(offsets[9], object.whatsapp);
  writer.writeString(offsets[10], object.whatsappE164);
}

Farmer _farmerDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Farmer();
  object.consentExport = reader.readBool(offsets[0]);
  object.consentWhatsApp = reader.readBool(offsets[1]);
  object.id = id;
  object.mobile = reader.readStringOrNull(offsets[2]);
  object.mobileE164 = reader.readStringOrNull(offsets[3]);
  object.name = reader.readString(offsets[4]);
  object.notes = reader.readStringOrNull(offsets[5]);
  object.preferredLanguageCode = reader.readStringOrNull(offsets[6]);
  object.taluk = reader.readStringOrNull(offsets[7]);
  object.village = reader.readStringOrNull(offsets[8]);
  object.whatsapp = reader.readStringOrNull(offsets[9]);
  object.whatsappE164 = reader.readStringOrNull(offsets[10]);
  return object;
}

P _farmerDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBool(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    case 6:
      return (reader.readStringOrNull(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _farmerGetId(Farmer object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _farmerGetLinks(Farmer object) {
  return [];
}

void _farmerAttach(IsarCollection<dynamic> col, Id id, Farmer object) {
  object.id = id;
}

extension FarmerQueryWhereSort on QueryBuilder<Farmer, Farmer, QWhere> {
  QueryBuilder<Farmer, Farmer, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FarmerQueryWhere on QueryBuilder<Farmer, Farmer, QWhereClause> {
  QueryBuilder<Farmer, Farmer, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension FarmerQueryFilter on QueryBuilder<Farmer, Farmer, QFilterCondition> {
  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> consentExportEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'consentExport',
        value: value,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> consentWhatsAppEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'consentWhatsApp',
        value: value,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mobile',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mobile',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mobile',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mobile',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mobile',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobile',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mobile',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileE164IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mobileE164',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileE164IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mobileE164',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileE164EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobileE164',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileE164GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mobileE164',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileE164LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mobileE164',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileE164Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mobileE164',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileE164StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'mobileE164',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileE164EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'mobileE164',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileE164Contains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'mobileE164',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileE164Matches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'mobileE164',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileE164IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mobileE164',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> mobileE164IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'mobileE164',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> notesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> notesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notes',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> notesEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> notesGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> notesLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> notesBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notes',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> notesStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> notesEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> notesContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'notes',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> notesMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'notes',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> notesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> notesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'notes',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition>
      preferredLanguageCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'preferredLanguageCode',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition>
      preferredLanguageCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'preferredLanguageCode',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition>
      preferredLanguageCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferredLanguageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition>
      preferredLanguageCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'preferredLanguageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition>
      preferredLanguageCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'preferredLanguageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition>
      preferredLanguageCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'preferredLanguageCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition>
      preferredLanguageCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'preferredLanguageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition>
      preferredLanguageCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'preferredLanguageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition>
      preferredLanguageCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'preferredLanguageCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition>
      preferredLanguageCodeMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'preferredLanguageCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition>
      preferredLanguageCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'preferredLanguageCode',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition>
      preferredLanguageCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'preferredLanguageCode',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> talukIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'taluk',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> talukIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'taluk',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> talukEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taluk',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> talukGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taluk',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> talukLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taluk',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> talukBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taluk',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> talukStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'taluk',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> talukEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'taluk',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> talukContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'taluk',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> talukMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'taluk',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> talukIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taluk',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> talukIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'taluk',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> villageIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'village',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> villageIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'village',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> villageEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'village',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> villageGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'village',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> villageLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'village',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> villageBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'village',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> villageStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'village',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> villageEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'village',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> villageContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'village',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> villageMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'village',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> villageIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'village',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> villageIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'village',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'whatsapp',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'whatsapp',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'whatsapp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'whatsapp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'whatsapp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'whatsapp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'whatsapp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'whatsapp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'whatsapp',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'whatsapp',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'whatsapp',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'whatsapp',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappE164IsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'whatsappE164',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappE164IsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'whatsappE164',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappE164EqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'whatsappE164',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappE164GreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'whatsappE164',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappE164LessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'whatsappE164',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappE164Between(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'whatsappE164',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappE164StartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'whatsappE164',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappE164EndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'whatsappE164',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappE164Contains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'whatsappE164',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappE164Matches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'whatsappE164',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappE164IsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'whatsappE164',
        value: '',
      ));
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterFilterCondition> whatsappE164IsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'whatsappE164',
        value: '',
      ));
    });
  }
}

extension FarmerQueryObject on QueryBuilder<Farmer, Farmer, QFilterCondition> {}

extension FarmerQueryLinks on QueryBuilder<Farmer, Farmer, QFilterCondition> {}

extension FarmerQuerySortBy on QueryBuilder<Farmer, Farmer, QSortBy> {
  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByConsentExport() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentExport', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByConsentExportDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentExport', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByConsentWhatsApp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentWhatsApp', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByConsentWhatsAppDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentWhatsApp', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByMobileE164() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileE164', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByMobileE164Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileE164', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByPreferredLanguageCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredLanguageCode', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByPreferredLanguageCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredLanguageCode', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByTaluk() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taluk', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByTalukDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taluk', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByVillage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'village', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByVillageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'village', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByWhatsapp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whatsapp', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByWhatsappDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whatsapp', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByWhatsappE164() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whatsappE164', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> sortByWhatsappE164Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whatsappE164', Sort.desc);
    });
  }
}

extension FarmerQuerySortThenBy on QueryBuilder<Farmer, Farmer, QSortThenBy> {
  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByConsentExport() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentExport', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByConsentExportDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentExport', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByConsentWhatsApp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentWhatsApp', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByConsentWhatsAppDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'consentWhatsApp', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByMobile() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByMobileDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobile', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByMobileE164() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileE164', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByMobileE164Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mobileE164', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByNotes() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByNotesDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notes', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByPreferredLanguageCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredLanguageCode', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByPreferredLanguageCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'preferredLanguageCode', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByTaluk() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taluk', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByTalukDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taluk', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByVillage() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'village', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByVillageDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'village', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByWhatsapp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whatsapp', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByWhatsappDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whatsapp', Sort.desc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByWhatsappE164() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whatsappE164', Sort.asc);
    });
  }

  QueryBuilder<Farmer, Farmer, QAfterSortBy> thenByWhatsappE164Desc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'whatsappE164', Sort.desc);
    });
  }
}

extension FarmerQueryWhereDistinct on QueryBuilder<Farmer, Farmer, QDistinct> {
  QueryBuilder<Farmer, Farmer, QDistinct> distinctByConsentExport() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'consentExport');
    });
  }

  QueryBuilder<Farmer, Farmer, QDistinct> distinctByConsentWhatsApp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'consentWhatsApp');
    });
  }

  QueryBuilder<Farmer, Farmer, QDistinct> distinctByMobile(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mobile', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Farmer, Farmer, QDistinct> distinctByMobileE164(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mobileE164', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Farmer, Farmer, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Farmer, Farmer, QDistinct> distinctByNotes(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notes', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Farmer, Farmer, QDistinct> distinctByPreferredLanguageCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'preferredLanguageCode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Farmer, Farmer, QDistinct> distinctByTaluk(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taluk', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Farmer, Farmer, QDistinct> distinctByVillage(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'village', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Farmer, Farmer, QDistinct> distinctByWhatsapp(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'whatsapp', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Farmer, Farmer, QDistinct> distinctByWhatsappE164(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'whatsappE164', caseSensitive: caseSensitive);
    });
  }
}

extension FarmerQueryProperty on QueryBuilder<Farmer, Farmer, QQueryProperty> {
  QueryBuilder<Farmer, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Farmer, bool, QQueryOperations> consentExportProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'consentExport');
    });
  }

  QueryBuilder<Farmer, bool, QQueryOperations> consentWhatsAppProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'consentWhatsApp');
    });
  }

  QueryBuilder<Farmer, String?, QQueryOperations> mobileProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mobile');
    });
  }

  QueryBuilder<Farmer, String?, QQueryOperations> mobileE164Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mobileE164');
    });
  }

  QueryBuilder<Farmer, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Farmer, String?, QQueryOperations> notesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notes');
    });
  }

  QueryBuilder<Farmer, String?, QQueryOperations>
      preferredLanguageCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'preferredLanguageCode');
    });
  }

  QueryBuilder<Farmer, String?, QQueryOperations> talukProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taluk');
    });
  }

  QueryBuilder<Farmer, String?, QQueryOperations> villageProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'village');
    });
  }

  QueryBuilder<Farmer, String?, QQueryOperations> whatsappProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'whatsapp');
    });
  }

  QueryBuilder<Farmer, String?, QQueryOperations> whatsappE164Property() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'whatsappE164');
    });
  }
}
