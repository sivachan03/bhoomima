// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point_group.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPointGroupCollection on Isar {
  IsarCollection<PointGroup> get pointGroups => this.collection();
}

const PointGroupSchema = CollectionSchema(
  name: r'PointGroup',
  id: 4529561067018841925,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'defaultFlag': PropertySchema(
      id: 1,
      name: r'defaultFlag',
      type: IsarType.bool,
    ),
    r'locked': PropertySchema(
      id: 2,
      name: r'locked',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 3,
      name: r'name',
      type: IsarType.string,
    ),
    r'propertyId': PropertySchema(
      id: 4,
      name: r'propertyId',
      type: IsarType.long,
    ),
    r'templateCode': PropertySchema(
      id: 5,
      name: r'templateCode',
      type: IsarType.string,
    )
  },
  estimateSize: _pointGroupEstimateSize,
  serialize: _pointGroupSerialize,
  deserialize: _pointGroupDeserialize,
  deserializeProp: _pointGroupDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _pointGroupGetId,
  getLinks: _pointGroupGetLinks,
  attach: _pointGroupAttach,
  version: '3.1.0+1',
);

int _pointGroupEstimateSize(
  PointGroup object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.category;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.templateCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _pointGroupSerialize(
  PointGroup object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeBool(offsets[1], object.defaultFlag);
  writer.writeBool(offsets[2], object.locked);
  writer.writeString(offsets[3], object.name);
  writer.writeLong(offsets[4], object.propertyId);
  writer.writeString(offsets[5], object.templateCode);
}

PointGroup _pointGroupDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PointGroup();
  object.category = reader.readStringOrNull(offsets[0]);
  object.defaultFlag = reader.readBool(offsets[1]);
  object.id = id;
  object.locked = reader.readBool(offsets[2]);
  object.name = reader.readString(offsets[3]);
  object.propertyId = reader.readLong(offsets[4]);
  object.templateCode = reader.readStringOrNull(offsets[5]);
  return object;
}

P _pointGroupDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _pointGroupGetId(PointGroup object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _pointGroupGetLinks(PointGroup object) {
  return [];
}

void _pointGroupAttach(IsarCollection<dynamic> col, Id id, PointGroup object) {
  object.id = id;
}

extension PointGroupQueryWhereSort
    on QueryBuilder<PointGroup, PointGroup, QWhere> {
  QueryBuilder<PointGroup, PointGroup, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PointGroupQueryWhere
    on QueryBuilder<PointGroup, PointGroup, QWhereClause> {
  QueryBuilder<PointGroup, PointGroup, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<PointGroup, PointGroup, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterWhereClause> idBetween(
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

extension PointGroupQueryFilter
    on QueryBuilder<PointGroup, PointGroup, QFilterCondition> {
  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> categoryEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      categoryGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> categoryLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> categoryBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'category',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      categoryStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> categoryEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> categoryContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> categoryMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      defaultFlagEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'defaultFlag',
        value: value,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> lockedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'locked',
        value: value,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> propertyIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'propertyId',
        value: value,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      propertyIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'propertyId',
        value: value,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      propertyIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'propertyId',
        value: value,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition> propertyIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'propertyId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      templateCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'templateCode',
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      templateCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'templateCode',
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      templateCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'templateCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      templateCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'templateCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      templateCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'templateCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      templateCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'templateCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      templateCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'templateCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      templateCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'templateCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      templateCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'templateCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      templateCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'templateCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      templateCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'templateCode',
        value: '',
      ));
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterFilterCondition>
      templateCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'templateCode',
        value: '',
      ));
    });
  }
}

extension PointGroupQueryObject
    on QueryBuilder<PointGroup, PointGroup, QFilterCondition> {}

extension PointGroupQueryLinks
    on QueryBuilder<PointGroup, PointGroup, QFilterCondition> {}

extension PointGroupQuerySortBy
    on QueryBuilder<PointGroup, PointGroup, QSortBy> {
  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> sortByDefaultFlag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultFlag', Sort.asc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> sortByDefaultFlagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultFlag', Sort.desc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> sortByLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locked', Sort.asc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> sortByLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locked', Sort.desc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> sortByPropertyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyId', Sort.asc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> sortByPropertyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyId', Sort.desc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> sortByTemplateCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateCode', Sort.asc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> sortByTemplateCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateCode', Sort.desc);
    });
  }
}

extension PointGroupQuerySortThenBy
    on QueryBuilder<PointGroup, PointGroup, QSortThenBy> {
  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenByDefaultFlag() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultFlag', Sort.asc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenByDefaultFlagDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'defaultFlag', Sort.desc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenByLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locked', Sort.asc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenByLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locked', Sort.desc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenByPropertyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyId', Sort.asc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenByPropertyIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'propertyId', Sort.desc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenByTemplateCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateCode', Sort.asc);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QAfterSortBy> thenByTemplateCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'templateCode', Sort.desc);
    });
  }
}

extension PointGroupQueryWhereDistinct
    on QueryBuilder<PointGroup, PointGroup, QDistinct> {
  QueryBuilder<PointGroup, PointGroup, QDistinct> distinctByCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QDistinct> distinctByDefaultFlag() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'defaultFlag');
    });
  }

  QueryBuilder<PointGroup, PointGroup, QDistinct> distinctByLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'locked');
    });
  }

  QueryBuilder<PointGroup, PointGroup, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PointGroup, PointGroup, QDistinct> distinctByPropertyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'propertyId');
    });
  }

  QueryBuilder<PointGroup, PointGroup, QDistinct> distinctByTemplateCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'templateCode', caseSensitive: caseSensitive);
    });
  }
}

extension PointGroupQueryProperty
    on QueryBuilder<PointGroup, PointGroup, QQueryProperty> {
  QueryBuilder<PointGroup, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PointGroup, String?, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<PointGroup, bool, QQueryOperations> defaultFlagProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'defaultFlag');
    });
  }

  QueryBuilder<PointGroup, bool, QQueryOperations> lockedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'locked');
    });
  }

  QueryBuilder<PointGroup, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<PointGroup, int, QQueryOperations> propertyIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'propertyId');
    });
  }

  QueryBuilder<PointGroup, String?, QQueryOperations> templateCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'templateCode');
    });
  }
}
