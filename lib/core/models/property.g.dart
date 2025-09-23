// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPropertyCollection on Isar {
  IsarCollection<Property> get propertys => this.collection();
}

const PropertyCollectionSchema = CollectionSchema(
  name: r'Property',
  id: -6043426196410015316,
  properties: {
    r'address': PropertySchema(id: 0, name: r'address', type: IsarType.string),
    r'addressLine': PropertySchema(
      id: 1,
      name: r'addressLine',
      type: IsarType.string,
    ),
    r'altitude': PropertySchema(
      id: 2,
      name: r'altitude',
      type: IsarType.double,
    ),
    r'city': PropertySchema(id: 3, name: r'city', type: IsarType.string),
    r'directions': PropertySchema(
      id: 4,
      name: r'directions',
      type: IsarType.string,
    ),
    r'lat': PropertySchema(id: 5, name: r'lat', type: IsarType.double),
    r'lon': PropertySchema(id: 6, name: r'lon', type: IsarType.double),
    r'name': PropertySchema(id: 7, name: r'name', type: IsarType.string),
    r'originAlt': PropertySchema(
      id: 8,
      name: r'originAlt',
      type: IsarType.double,
    ),
    r'originLat': PropertySchema(
      id: 9,
      name: r'originLat',
      type: IsarType.double,
    ),
    r'originLon': PropertySchema(
      id: 10,
      name: r'originLon',
      type: IsarType.double,
    ),
    r'ownerId': PropertySchema(id: 11, name: r'ownerId', type: IsarType.long),
    r'pin': PropertySchema(id: 12, name: r'pin', type: IsarType.string),
    r'street': PropertySchema(id: 13, name: r'street', type: IsarType.string),
    r'type': PropertySchema(id: 14, name: r'type', type: IsarType.string),
    r'typeCode': PropertySchema(
      id: 15,
      name: r'typeCode',
      type: IsarType.string,
    ),
  },
  estimateSize: _propertyEstimateSize,
  serialize: _propertySerialize,
  deserialize: _propertyDeserialize,
  deserializeProp: _propertyDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _propertyGetId,
  getLinks: _propertyGetLinks,
  attach: _propertyAttach,
  version: '3.1.0+1',
);

int _propertyEstimateSize(
  Property object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.address;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.addressLine;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.city;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.directions;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.name.length * 3;
  {
    final value = object.pin;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.street;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.type.length * 3;
  {
    final value = object.typeCode;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _propertySerialize(
  Property object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.address);
  writer.writeString(offsets[1], object.addressLine);
  writer.writeDouble(offsets[2], object.altitude);
  writer.writeString(offsets[3], object.city);
  writer.writeString(offsets[4], object.directions);
  writer.writeDouble(offsets[5], object.lat);
  writer.writeDouble(offsets[6], object.lon);
  writer.writeString(offsets[7], object.name);
  writer.writeDouble(offsets[8], object.originAlt);
  writer.writeDouble(offsets[9], object.originLat);
  writer.writeDouble(offsets[10], object.originLon);
  writer.writeLong(offsets[11], object.ownerId);
  writer.writeString(offsets[12], object.pin);
  writer.writeString(offsets[13], object.street);
  writer.writeString(offsets[14], object.type);
  writer.writeString(offsets[15], object.typeCode);
}

Property _propertyDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Property();
  object.address = reader.readStringOrNull(offsets[0]);
  object.addressLine = reader.readStringOrNull(offsets[1]);
  object.altitude = reader.readDoubleOrNull(offsets[2]);
  object.city = reader.readStringOrNull(offsets[3]);
  object.directions = reader.readStringOrNull(offsets[4]);
  object.id = id;
  object.lat = reader.readDoubleOrNull(offsets[5]);
  object.lon = reader.readDoubleOrNull(offsets[6]);
  object.name = reader.readString(offsets[7]);
  object.originAlt = reader.readDoubleOrNull(offsets[8]);
  object.originLat = reader.readDoubleOrNull(offsets[9]);
  object.originLon = reader.readDoubleOrNull(offsets[10]);
  object.ownerId = reader.readLongOrNull(offsets[11]);
  object.pin = reader.readStringOrNull(offsets[12]);
  object.street = reader.readStringOrNull(offsets[13]);
  object.type = reader.readString(offsets[14]);
  object.typeCode = reader.readStringOrNull(offsets[15]);
  return object;
}

P _propertyDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readDoubleOrNull(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    case 5:
      return (reader.readDoubleOrNull(offset)) as P;
    case 6:
      return (reader.readDoubleOrNull(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDoubleOrNull(offset)) as P;
    case 9:
      return (reader.readDoubleOrNull(offset)) as P;
    case 10:
      return (reader.readDoubleOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset)) as P;
    case 12:
      return (reader.readStringOrNull(offset)) as P;
    case 13:
      return (reader.readStringOrNull(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _propertyGetId(Property object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _propertyGetLinks(Property object) {
  return [];
}

void _propertyAttach(IsarCollection<dynamic> col, Id id, Property object) {
  object.id = id;
}

extension PropertyQueryWhereSort on QueryBuilder<Property, Property, QWhere> {
  QueryBuilder<Property, Property, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PropertyQueryWhere on QueryBuilder<Property, Property, QWhereClause> {
  QueryBuilder<Property, Property, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<Property, Property, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Property, Property, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PropertyQueryFilter
    on QueryBuilder<Property, Property, QFilterCondition> {
  QueryBuilder<Property, Property, QAfterFilterCondition> addressIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'address'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'address'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'address',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'address',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'address',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'address', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'address', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressLineIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'addressLine'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition>
  addressLineIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'addressLine'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressLineEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'addressLine',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition>
  addressLineGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'addressLine',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressLineLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'addressLine',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressLineBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'addressLine',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressLineStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'addressLine',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressLineEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'addressLine',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressLineContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'addressLine',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressLineMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'addressLine',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> addressLineIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'addressLine', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition>
  addressLineIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'addressLine', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> altitudeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'altitude'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> altitudeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'altitude'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> altitudeEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'altitude',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> altitudeGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'altitude',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> altitudeLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'altitude',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> altitudeBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'altitude',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> cityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'city'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> cityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'city'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> cityEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'city',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> cityGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'city',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> cityLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'city',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> cityBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'city',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> cityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'city',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> cityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'city',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> cityContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'city',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> cityMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'city',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> cityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'city', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> cityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'city', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> directionsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'directions'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition>
  directionsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'directions'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> directionsEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'directions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> directionsGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'directions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> directionsLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'directions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> directionsBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'directions',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> directionsStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'directions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> directionsEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'directions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> directionsContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'directions',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> directionsMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'directions',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> directionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'directions', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition>
  directionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'directions', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> latIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lat'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> latIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lat'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> latEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lat',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> latGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lat',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> latLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lat',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> latBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lat',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> lonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'lon'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> lonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'lon'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> lonEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lon',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> lonGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lon',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> lonLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lon',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> lonBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lon',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'name',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> nameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'name',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> nameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'name',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'name', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originAltIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'originAlt'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originAltIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'originAlt'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originAltEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'originAlt',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originAltGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'originAlt',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originAltLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'originAlt',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originAltBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'originAlt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originLatIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'originLat'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originLatIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'originLat'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originLatEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'originLat',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originLatGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'originLat',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originLatLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'originLat',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originLatBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'originLat',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originLonIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'originLon'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originLonIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'originLon'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originLonEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'originLon',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originLonGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'originLon',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originLonLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'originLon',
          value: value,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> originLonBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'originLon',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          epsilon: epsilon,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> ownerIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'ownerId'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> ownerIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'ownerId'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> ownerIdEqualTo(
    int? value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'ownerId', value: value),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> ownerIdGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'ownerId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> ownerIdLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'ownerId',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> ownerIdBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'ownerId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> pinIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'pin'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> pinIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'pin'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> pinEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'pin',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> pinGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pin',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> pinLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pin',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> pinBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pin',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> pinStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'pin',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> pinEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'pin',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> pinContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'pin',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> pinMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'pin',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> pinIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pin', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> pinIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'pin', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> streetIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'street'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> streetIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'street'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> streetEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'street',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> streetGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'street',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> streetLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'street',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> streetBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'street',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> streetStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'street',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> streetEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'street',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> streetContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'street',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> streetMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'street',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> streetIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'street', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> streetIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'street', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'type',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'type',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'type',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'type', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeCodeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'typeCode'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeCodeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'typeCode'),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeCodeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'typeCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeCodeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'typeCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeCodeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'typeCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeCodeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'typeCode',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'typeCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'typeCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeCodeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'typeCode',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeCodeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'typeCode',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'typeCode', value: ''),
      );
    });
  }

  QueryBuilder<Property, Property, QAfterFilterCondition> typeCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'typeCode', value: ''),
      );
    });
  }
}

extension PropertyQueryObject
    on QueryBuilder<Property, Property, QFilterCondition> {}

extension PropertyQueryLinks
    on QueryBuilder<Property, Property, QFilterCondition> {}

extension PropertyQuerySortBy on QueryBuilder<Property, Property, QSortBy> {
  QueryBuilder<Property, Property, QAfterSortBy> sortByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByAddressLine() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addressLine', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByAddressLineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addressLine', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByAltitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'altitude', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByAltitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'altitude', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByCity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'city', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByCityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'city', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByDirections() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directions', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByDirectionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directions', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lon', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lon', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByOriginAlt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originAlt', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByOriginAltDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originAlt', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByOriginLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originLat', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByOriginLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originLat', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByOriginLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originLon', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByOriginLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originLon', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByPin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pin', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByPinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pin', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByStreet() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'street', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByStreetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'street', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByTypeCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeCode', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> sortByTypeCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeCode', Sort.desc);
    });
  }
}

extension PropertyQuerySortThenBy
    on QueryBuilder<Property, Property, QSortThenBy> {
  QueryBuilder<Property, Property, QAfterSortBy> thenByAddress() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByAddressDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'address', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByAddressLine() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addressLine', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByAddressLineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'addressLine', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByAltitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'altitude', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByAltitudeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'altitude', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByCity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'city', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByCityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'city', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByDirections() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directions', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByDirectionsDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'directions', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lat', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lon', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lon', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByOriginAlt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originAlt', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByOriginAltDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originAlt', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByOriginLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originLat', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByOriginLatDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originLat', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByOriginLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originLon', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByOriginLonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originLon', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByOwnerIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ownerId', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByPin() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pin', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByPinDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'pin', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByStreet() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'street', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByStreetDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'street', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByTypeCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeCode', Sort.asc);
    });
  }

  QueryBuilder<Property, Property, QAfterSortBy> thenByTypeCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'typeCode', Sort.desc);
    });
  }
}

extension PropertyQueryWhereDistinct
    on QueryBuilder<Property, Property, QDistinct> {
  QueryBuilder<Property, Property, QDistinct> distinctByAddress({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'address', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByAddressLine({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'addressLine', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByAltitude() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'altitude');
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByCity({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'city', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByDirections({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'directions', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lat');
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lon');
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByOriginAlt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originAlt');
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByOriginLat() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originLat');
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByOriginLon() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originLon');
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByOwnerId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ownerId');
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByPin({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pin', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByStreet({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'street', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Property, Property, QDistinct> distinctByTypeCode({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'typeCode', caseSensitive: caseSensitive);
    });
  }
}

extension PropertyQueryProperty
    on QueryBuilder<Property, Property, QQueryProperty> {
  QueryBuilder<Property, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Property, String?, QQueryOperations> addressProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'address');
    });
  }

  QueryBuilder<Property, String?, QQueryOperations> addressLineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'addressLine');
    });
  }

  QueryBuilder<Property, double?, QQueryOperations> altitudeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'altitude');
    });
  }

  QueryBuilder<Property, String?, QQueryOperations> cityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'city');
    });
  }

  QueryBuilder<Property, String?, QQueryOperations> directionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'directions');
    });
  }

  QueryBuilder<Property, double?, QQueryOperations> latProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lat');
    });
  }

  QueryBuilder<Property, double?, QQueryOperations> lonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lon');
    });
  }

  QueryBuilder<Property, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Property, double?, QQueryOperations> originAltProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originAlt');
    });
  }

  QueryBuilder<Property, double?, QQueryOperations> originLatProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originLat');
    });
  }

  QueryBuilder<Property, double?, QQueryOperations> originLonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originLon');
    });
  }

  QueryBuilder<Property, int?, QQueryOperations> ownerIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ownerId');
    });
  }

  QueryBuilder<Property, String?, QQueryOperations> pinProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pin');
    });
  }

  QueryBuilder<Property, String?, QQueryOperations> streetProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'street');
    });
  }

  QueryBuilder<Property, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<Property, String?, QQueryOperations> typeCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'typeCode');
    });
  }
}
