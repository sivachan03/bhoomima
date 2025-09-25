// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_item.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetCatalogItemCollection on Isar {
  IsarCollection<CatalogItem> get catalogItems => this.collection();
}

const CatalogItemSchema = CollectionSchema(
  name: r'CatalogItem',
  id: 7586471786704941128,
  properties: {
    r'code': PropertySchema(
      id: 0,
      name: r'code',
      type: IsarType.string,
    ),
    r'kind': PropertySchema(
      id: 1,
      name: r'kind',
      type: IsarType.string,
    ),
    r'labelEn': PropertySchema(
      id: 2,
      name: r'labelEn',
      type: IsarType.string,
    ),
    r'locked': PropertySchema(
      id: 3,
      name: r'locked',
      type: IsarType.bool,
    ),
    r'parentCode': PropertySchema(
      id: 4,
      name: r'parentCode',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 5,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _catalogItemEstimateSize,
  serialize: _catalogItemSerialize,
  deserialize: _catalogItemDeserialize,
  deserializeProp: _catalogItemDeserializeProp,
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
    ),
    r'kind': IndexSchema(
      id: 1484550194077596484,
      name: r'kind',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'kind',
          type: IndexType.hash,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _catalogItemGetId,
  getLinks: _catalogItemGetLinks,
  attach: _catalogItemAttach,
  version: '3.1.0+1',
);

int _catalogItemEstimateSize(
  CatalogItem object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.code.length * 3;
  bytesCount += 3 + object.kind.length * 3;
  bytesCount += 3 + object.labelEn.length * 3;
  {
    final value = object.parentCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _catalogItemSerialize(
  CatalogItem object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.code);
  writer.writeString(offsets[1], object.kind);
  writer.writeString(offsets[2], object.labelEn);
  writer.writeBool(offsets[3], object.locked);
  writer.writeString(offsets[4], object.parentCode);
  writer.writeDateTime(offsets[5], object.updatedAt);
}

CatalogItem _catalogItemDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = CatalogItem();
  object.code = reader.readString(offsets[0]);
  object.id = id;
  object.kind = reader.readString(offsets[1]);
  object.labelEn = reader.readString(offsets[2]);
  object.locked = reader.readBool(offsets[3]);
  object.parentCode = reader.readStringOrNull(offsets[4]);
  object.updatedAt = reader.readDateTime(offsets[5]);
  return object;
}

P _catalogItemDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _catalogItemGetId(CatalogItem object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _catalogItemGetLinks(CatalogItem object) {
  return [];
}

void _catalogItemAttach(
    IsarCollection<dynamic> col, Id id, CatalogItem object) {
  object.id = id;
}

extension CatalogItemByIndex on IsarCollection<CatalogItem> {
  Future<CatalogItem?> getByCode(String code) {
    return getByIndex(r'code', [code]);
  }

  CatalogItem? getByCodeSync(String code) {
    return getByIndexSync(r'code', [code]);
  }

  Future<bool> deleteByCode(String code) {
    return deleteByIndex(r'code', [code]);
  }

  bool deleteByCodeSync(String code) {
    return deleteByIndexSync(r'code', [code]);
  }

  Future<List<CatalogItem?>> getAllByCode(List<String> codeValues) {
    final values = codeValues.map((e) => [e]).toList();
    return getAllByIndex(r'code', values);
  }

  List<CatalogItem?> getAllByCodeSync(List<String> codeValues) {
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

  Future<Id> putByCode(CatalogItem object) {
    return putByIndex(r'code', object);
  }

  Id putByCodeSync(CatalogItem object, {bool saveLinks = true}) {
    return putByIndexSync(r'code', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByCode(List<CatalogItem> objects) {
    return putAllByIndex(r'code', objects);
  }

  List<Id> putAllByCodeSync(List<CatalogItem> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'code', objects, saveLinks: saveLinks);
  }
}

extension CatalogItemQueryWhereSort
    on QueryBuilder<CatalogItem, CatalogItem, QWhere> {
  QueryBuilder<CatalogItem, CatalogItem, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension CatalogItemQueryWhere
    on QueryBuilder<CatalogItem, CatalogItem, QWhereClause> {
  QueryBuilder<CatalogItem, CatalogItem, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterWhereClause> idBetween(
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterWhereClause> codeEqualTo(
      String code) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'code',
        value: [code],
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterWhereClause> codeNotEqualTo(
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterWhereClause> kindEqualTo(
      String kind) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'kind',
        value: [kind],
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterWhereClause> kindNotEqualTo(
      String kind) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kind',
              lower: [],
              upper: [kind],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kind',
              lower: [kind],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kind',
              lower: [kind],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'kind',
              lower: [],
              upper: [kind],
              includeUpper: false,
            ));
      }
    });
  }
}

extension CatalogItemQueryFilter
    on QueryBuilder<CatalogItem, CatalogItem, QFilterCondition> {
  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> codeEqualTo(
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> codeGreaterThan(
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> codeLessThan(
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> codeBetween(
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> codeStartsWith(
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> codeEndsWith(
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> codeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'code',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> codeMatches(
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> codeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      codeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'code',
        value: '',
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> idBetween(
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> kindEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> kindGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> kindLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> kindBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'kind',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> kindStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> kindEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> kindContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'kind',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> kindMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'kind',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> kindIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'kind',
        value: '',
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      kindIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'kind',
        value: '',
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> labelEnEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'labelEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      labelEnGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'labelEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> labelEnLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'labelEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> labelEnBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'labelEn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      labelEnStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'labelEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> labelEnEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'labelEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> labelEnContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'labelEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> labelEnMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'labelEn',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      labelEnIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'labelEn',
        value: '',
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      labelEnIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'labelEn',
        value: '',
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition> lockedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'locked',
        value: value,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      parentCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'parentCode',
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      parentCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'parentCode',
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      parentCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      parentCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'parentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      parentCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'parentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      parentCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'parentCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      parentCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'parentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      parentCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'parentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      parentCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'parentCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      parentCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'parentCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      parentCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'parentCode',
        value: '',
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      parentCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'parentCode',
        value: '',
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
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

  QueryBuilder<CatalogItem, CatalogItem, QAfterFilterCondition>
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

extension CatalogItemQueryObject
    on QueryBuilder<CatalogItem, CatalogItem, QFilterCondition> {}

extension CatalogItemQueryLinks
    on QueryBuilder<CatalogItem, CatalogItem, QFilterCondition> {}

extension CatalogItemQuerySortBy
    on QueryBuilder<CatalogItem, CatalogItem, QSortBy> {
  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> sortByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> sortByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> sortByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> sortByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> sortByLabelEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'labelEn', Sort.asc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> sortByLabelEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'labelEn', Sort.desc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> sortByLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locked', Sort.asc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> sortByLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locked', Sort.desc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> sortByParentCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCode', Sort.asc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> sortByParentCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCode', Sort.desc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CatalogItemQuerySortThenBy
    on QueryBuilder<CatalogItem, CatalogItem, QSortThenBy> {
  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenByCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.asc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenByCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'code', Sort.desc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenByLabelEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'labelEn', Sort.asc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenByLabelEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'labelEn', Sort.desc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenByLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locked', Sort.asc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenByLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'locked', Sort.desc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenByParentCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCode', Sort.asc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenByParentCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'parentCode', Sort.desc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QAfterSortBy> thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension CatalogItemQueryWhereDistinct
    on QueryBuilder<CatalogItem, CatalogItem, QDistinct> {
  QueryBuilder<CatalogItem, CatalogItem, QDistinct> distinctByCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'code', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QDistinct> distinctByKind(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kind', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QDistinct> distinctByLabelEn(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'labelEn', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QDistinct> distinctByLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'locked');
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QDistinct> distinctByParentCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'parentCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<CatalogItem, CatalogItem, QDistinct> distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension CatalogItemQueryProperty
    on QueryBuilder<CatalogItem, CatalogItem, QQueryProperty> {
  QueryBuilder<CatalogItem, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<CatalogItem, String, QQueryOperations> codeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'code');
    });
  }

  QueryBuilder<CatalogItem, String, QQueryOperations> kindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kind');
    });
  }

  QueryBuilder<CatalogItem, String, QQueryOperations> labelEnProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'labelEn');
    });
  }

  QueryBuilder<CatalogItem, bool, QQueryOperations> lockedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'locked');
    });
  }

  QueryBuilder<CatalogItem, String?, QQueryOperations> parentCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'parentCode');
    });
  }

  QueryBuilder<CatalogItem, DateTime, QQueryOperations> updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
