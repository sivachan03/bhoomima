// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_template.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetGroupTemplateCollection on Isar {
  IsarCollection<GroupTemplate> get groupTemplates => this.collection();
}

const GroupTemplateSchema = CollectionSchema(
  name: r'GroupTemplate',
  id: -2236014934308421906,
  properties: {
    r'category': PropertySchema(
      id: 0,
      name: r'category',
      type: IsarType.string,
    ),
    r'code': PropertySchema(
      id: 1,
      name: r'code',
      type: IsarType.string,
    ),
    r'locked': PropertySchema(
      id: 2,
      name: r'locked',
      type: IsarType.bool,
    ),
    r'nameEn': PropertySchema(
      id: 3,
      name: r'nameEn',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 4,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _groupTemplateEstimateSize,
  serialize: _groupTemplateSerialize,
  deserialize: _groupTemplateDeserialize,
  deserializeProp: _groupTemplateDeserializeProp,
  idName: r'id',
  indexes: {
    r'code': IndexSchema(
      id: 329780482934683790,
      name: r'code',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'code',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _groupTemplateGetId,
  getLinks: _groupTemplateGetLinks,
  attach: _groupTemplateAttach,
  version: '3.1.0+1',
);

int _groupTemplateEstimateSize(
  GroupTemplate object,
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
  bytesCount += 3 + object.code.length * 3;
  bytesCount += 3 + object.nameEn.length * 3;
  return bytesCount;
}

void _groupTemplateSerialize(
  GroupTemplate object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.category);
  writer.writeString(offsets[1], object.code);
  writer.writeBool(offsets[2], object.locked);
  writer.writeString(offsets[3], object.nameEn);
  writer.writeDateTime(offsets[4], object.updatedAt);
}

GroupTemplate _groupTemplateDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = GroupTemplate();
  object.category = reader.readStringOrNull(offsets[0]);
  object.code = reader.readString(offsets[1]);
  object.id = id;
  object.locked = reader.readBool(offsets[2]);
  object.nameEn = reader.readString(offsets[3]);
  object.updatedAt = reader.readDateTime(offsets[4]);
  return object;
}

P _groupTemplateDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _groupTemplateGetId(GroupTemplate object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _groupTemplateGetLinks(GroupTemplate object) {
  return [];
}

void _groupTemplateAttach(
    IsarCollection<dynamic> col, Id id, GroupTemplate object) {
  object.id = id;
}

extension GroupTemplateByIndex on IsarCollection<GroupTemplate> {
  Future<GroupTemplate?> getByCode(String code) {
    return getByIndex(r'code', [code]);
  }

  GroupTemplate? getByCodeSync(String code) {
    return getByIndexSync(r'code', [code]);
  }

  Future<bool> deleteByCode(String code) {
    return deleteByIndex(r'code', [code]);
  }

  bool deleteByCodeSync(String code) {
    return deleteByIndexSync(r'code', [code]);
  }

  Future<List<GroupTemplate?>> getAllByCode(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return getAllByIndex(r'code', values);
  }

  List<GroupTemplate?> getAllByCodeSync(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'code', values);
  }

  Future<int> deleteAllByCode(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'code', values);
  }

  int deleteAllByCodeSync(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'code', values);
  }

  Future<Id> putByCode(GroupTemplate object) {
    return putByIndex(r'code', object);
  }

  Id putByCodeSync(GroupTemplate object, {bool saveLinks = true}) {
    return putByIndexSync(r'code', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCode(List<GroupTemplate> objects) {
    return putAllByIndex(r'code', objects);
  }

  List<Id> putAllByCodeSync(List<GroupTemplate> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'code', objects, saveLinks: saveLinks);
  }
}

extension GroupTemplateQueryWhereSort
    on QueryBuilder<GroupTemplate, GroupTemplate, QWhere> {
  QueryBuilder<GroupTemplate, GroupTemplate, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension GroupTemplateQueryWhere
    on QueryBuilder<GroupTemplate, GroupTemplate, QWhereClause> {
  QueryBuilder<GroupTemplate, GroupTemplate, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterWhereClause> idBetween(
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

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterWhereClause> codeEqualTo(
      String code) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'code',
        value: [code],
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterWhereClause> codeNotEqualTo(
      String code) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [],
              upper: [code],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [code],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [code],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'code',
              lower: [],
              upper: [code],
              includeUpper: false,
            ));
      }
    });
  }
}

extension GroupTemplateQueryFilter
    on QueryBuilder<GroupTemplate, GroupTemplate, QFilterCondition> {
  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      categoryIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      categoryIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'category',
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      categoryEqualTo(
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

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
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

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      categoryLessThan(
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

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      categoryBetween(
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

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
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

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      categoryEndsWith(
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

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      categoryContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'category',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      categoryMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'category',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      categoryIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      categoryIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'category',
        value: '',
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition> codeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      codeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      codeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition> codeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'code',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      codeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      codeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      codeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition> codeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'code',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      codeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      codeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      idGreaterThan(
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

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition> idBetween(
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

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      lockedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'locked',
        value: value,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      nameEnEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      nameEnGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nameEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      nameEnLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nameEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      nameEnBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nameEn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      nameEnStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nameEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      nameEnEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nameEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      nameEnContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      nameEnMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameEn',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      nameEnIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameEn',
        value: '',
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      nameEnIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameEn',
        value: '',
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension GroupTemplateQueryObject
    on QueryBuilder<GroupTemplate, GroupTemplate, QFilterCondition> {}

extension GroupTemplateQueryLinks
    on QueryBuilder<GroupTemplate, GroupTemplate, QFilterCondition> {}

extension GroupTemplateQuerySortBy
    on QueryBuilder<GroupTemplate, GroupTemplate, QSortBy> {
  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> sortByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy>
      sortByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> sortByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> sortByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> sortByLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locked', Sort.asc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> sortByLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locked', Sort.desc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> sortByNameEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.asc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> sortByNameEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.desc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension GroupTemplateQuerySortThenBy
    on QueryBuilder<GroupTemplate, GroupTemplate, QSortThenBy> {
  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> thenByCategory() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.asc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy>
      thenByCategoryDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'category', Sort.desc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> thenByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> thenByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> thenByLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locked', Sort.asc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> thenByLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locked', Sort.desc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> thenByNameEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.asc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> thenByNameEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.desc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension GroupTemplateQueryWhereDistinct
    on QueryBuilder<GroupTemplate, GroupTemplate, QDistinct> {
  QueryBuilder<GroupTemplate, GroupTemplate, QDistinct> distinctByCategory(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'category', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QDistinct> distinctByCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'code', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QDistinct> distinctByLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'locked');
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QDistinct> distinctByNameEn(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameEn', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<GroupTemplate, GroupTemplate, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension GroupTemplateQueryProperty
    on QueryBuilder<GroupTemplate, GroupTemplate, QQueryProperty> {
  QueryBuilder<GroupTemplate, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<GroupTemplate, String?, QQueryOperations> categoryProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'category');
    });
  }

  QueryBuilder<GroupTemplate, String, QQueryOperations> codeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'code');
    });
  }

  QueryBuilder<GroupTemplate, bool, QQueryOperations> lockedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'locked');
    });
  }

  QueryBuilder<GroupTemplate, String, QQueryOperations> nameEnProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameEn');
    });
  }

  QueryBuilder<GroupTemplate, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
