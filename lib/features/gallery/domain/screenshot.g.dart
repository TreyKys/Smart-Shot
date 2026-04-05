// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'screenshot.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetScreenshotCollection on Isar {
  IsarCollection<Screenshot> get screenshots => this.collection();
}

const ScreenshotSchema = CollectionSchema(
  name: r'Screenshot',
  id: 349355034612490177,
  properties: {
    r'actionUrl': PropertySchema(
      id: 0,
      name: r'actionUrl',
      type: IsarType.string,
    ),
    r'cleanText': PropertySchema(
      id: 1,
      name: r'cleanText',
      type: IsarType.string,
    ),
    r'cryptoAddresses': PropertySchema(
      id: 2,
      name: r'cryptoAddresses',
      type: IsarType.stringList,
    ),
    r'dates': PropertySchema(
      id: 3,
      name: r'dates',
      type: IsarType.stringList,
    ),
    r'emails': PropertySchema(
      id: 4,
      name: r'emails',
      type: IsarType.stringList,
    ),
    r'filePath': PropertySchema(
      id: 5,
      name: r'filePath',
      type: IsarType.string,
    ),
    r'isProcessed': PropertySchema(
      id: 6,
      name: r'isProcessed',
      type: IsarType.bool,
    ),
    r'ocrText': PropertySchema(
      id: 7,
      name: r'ocrText',
      type: IsarType.string,
    ),
    r'phoneNumbers': PropertySchema(
      id: 8,
      name: r'phoneNumbers',
      type: IsarType.stringList,
    ),
    r'suggestedActions': PropertySchema(
      id: 9,
      name: r'suggestedActions',
      type: IsarType.objectList,
      target: r'SuggestedAction',
    ),
    r'tags': PropertySchema(
      id: 10,
      name: r'tags',
      type: IsarType.stringList,
    ),
    r'timestamp': PropertySchema(
      id: 11,
      name: r'timestamp',
      type: IsarType.dateTime,
    ),
    r'urls': PropertySchema(
      id: 12,
      name: r'urls',
      type: IsarType.stringList,
    )
  },
  estimateSize: _screenshotEstimateSize,
  serialize: _screenshotSerialize,
  deserialize: _screenshotDeserialize,
  deserializeProp: _screenshotDeserializeProp,
  idName: r'id',
  indexes: {
    r'filePath': IndexSchema(
      id: 2918041768256347220,
      name: r'filePath',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'filePath',
          type: IndexType.value,
          caseSensitive: true,
        )
      ],
    ),
    r'timestamp': IndexSchema(
      id: 1852253767416892198,
      name: r'timestamp',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'timestamp',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'ocrText': IndexSchema(
      id: 2788190490994456436,
      name: r'ocrText',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'ocrText',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'cleanText': IndexSchema(
      id: -5976529353505723160,
      name: r'cleanText',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'cleanText',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {r'SuggestedAction': SuggestedActionSchema},
  getId: _screenshotGetId,
  getLinks: _screenshotGetLinks,
  attach: _screenshotAttach,
  version: '3.1.0+1',
);

int _screenshotEstimateSize(
  Screenshot object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.actionUrl;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.cleanText;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.cryptoAddresses;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  {
    final list = object.dates;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  {
    final list = object.emails;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  bytesCount += 3 + object.filePath.length * 3;
  {
    final value = object.ocrText;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final list = object.phoneNumbers;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  {
    final list = object.suggestedActions;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        final offsets = allOffsets[SuggestedAction]!;
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount +=
              SuggestedActionSchema.estimateSize(value, offsets, allOffsets);
        }
      }
    }
  }
  {
    final list = object.tags;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  {
    final list = object.urls;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  return bytesCount;
}

void _screenshotSerialize(
  Screenshot object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.actionUrl);
  writer.writeString(offsets[1], object.cleanText);
  writer.writeStringList(offsets[2], object.cryptoAddresses);
  writer.writeStringList(offsets[3], object.dates);
  writer.writeStringList(offsets[4], object.emails);
  writer.writeString(offsets[5], object.filePath);
  writer.writeBool(offsets[6], object.isProcessed);
  writer.writeString(offsets[7], object.ocrText);
  writer.writeStringList(offsets[8], object.phoneNumbers);
  writer.writeObjectList<SuggestedAction>(
    offsets[9],
    allOffsets,
    SuggestedActionSchema.serialize,
    object.suggestedActions,
  );
  writer.writeStringList(offsets[10], object.tags);
  writer.writeDateTime(offsets[11], object.timestamp);
  writer.writeStringList(offsets[12], object.urls);
}

Screenshot _screenshotDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Screenshot();
  object.actionUrl = reader.readStringOrNull(offsets[0]);
  object.cleanText = reader.readStringOrNull(offsets[1]);
  object.cryptoAddresses = reader.readStringList(offsets[2]);
  object.dates = reader.readStringList(offsets[3]);
  object.emails = reader.readStringList(offsets[4]);
  object.filePath = reader.readString(offsets[5]);
  object.id = id;
  object.isProcessed = reader.readBool(offsets[6]);
  object.ocrText = reader.readStringOrNull(offsets[7]);
  object.phoneNumbers = reader.readStringList(offsets[8]);
  object.suggestedActions = reader.readObjectList<SuggestedAction>(
    offsets[9],
    SuggestedActionSchema.deserialize,
    allOffsets,
    SuggestedAction(),
  );
  object.tags = reader.readStringList(offsets[10]);
  object.timestamp = reader.readDateTime(offsets[11]);
  object.urls = reader.readStringList(offsets[12]);
  return object;
}

P _screenshotDeserializeProp<P>(
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
      return (reader.readStringList(offset)) as P;
    case 3:
      return (reader.readStringList(offset)) as P;
    case 4:
      return (reader.readStringList(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readStringList(offset)) as P;
    case 9:
      return (reader.readObjectList<SuggestedAction>(
        offset,
        SuggestedActionSchema.deserialize,
        allOffsets,
        SuggestedAction(),
      )) as P;
    case 10:
      return (reader.readStringList(offset)) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (reader.readStringList(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _screenshotGetId(Screenshot object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _screenshotGetLinks(Screenshot object) {
  return [];
}

void _screenshotAttach(IsarCollection<dynamic> col, Id id, Screenshot object) {
  object.id = id;
}

extension ScreenshotByIndex on IsarCollection<Screenshot> {
  Future<Screenshot?> getByFilePath(String filePath) {
    return getByIndex(r'filePath', [filePath]);
  }

  Screenshot? getByFilePathSync(String filePath) {
    return getByIndexSync(r'filePath', [filePath]);
  }

  Future<bool> deleteByFilePath(String filePath) {
    return deleteByIndex(r'filePath', [filePath]);
  }

  bool deleteByFilePathSync(String filePath) {
    return deleteByIndexSync(r'filePath', [filePath]);
  }

  Future<List<Screenshot?>> getAllByFilePath(List<String> filePathValues) {
    final values = filePathValues.map((e) => [e]).toList();
    return getAllByIndex(r'filePath', values);
  }

  List<Screenshot?> getAllByFilePathSync(List<String> filePathValues) {
    final values = filePathValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'filePath', values);
  }

  Future<int> deleteAllByFilePath(List<String> filePathValues) {
    final values = filePathValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'filePath', values);
  }

  int deleteAllByFilePathSync(List<String> filePathValues) {
    final values = filePathValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'filePath', values);
  }

  Future<Id> putByFilePath(Screenshot object) {
    return putByIndex(r'filePath', object);
  }

  Id putByFilePathSync(Screenshot object, {bool saveLinks = true}) {
    return putByIndexSync(r'filePath', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByFilePath(List<Screenshot> objects) {
    return putAllByIndex(r'filePath', objects);
  }

  List<Id> putAllByFilePathSync(List<Screenshot> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'filePath', objects, saveLinks: saveLinks);
  }
}

extension ScreenshotQueryWhereSort
    on QueryBuilder<Screenshot, Screenshot, QWhere> {
  QueryBuilder<Screenshot, Screenshot, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhere> anyFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'filePath'),
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhere> anyTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'timestamp'),
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhere> anyOcrText() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'ocrText'),
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhere> anyCleanText() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'cleanText'),
      );
    });
  }
}

extension ScreenshotQueryWhere
    on QueryBuilder<Screenshot, Screenshot, QWhereClause> {
  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> idBetween(
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

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> filePathEqualTo(
      String filePath) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'filePath',
        value: [filePath],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> filePathNotEqualTo(
      String filePath) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'filePath',
              lower: [],
              upper: [filePath],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'filePath',
              lower: [filePath],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'filePath',
              lower: [filePath],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'filePath',
              lower: [],
              upper: [filePath],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> filePathGreaterThan(
    String filePath, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'filePath',
        lower: [filePath],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> filePathLessThan(
    String filePath, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'filePath',
        lower: [],
        upper: [filePath],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> filePathBetween(
    String lowerFilePath,
    String upperFilePath, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'filePath',
        lower: [lowerFilePath],
        includeLower: includeLower,
        upper: [upperFilePath],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> filePathStartsWith(
      String FilePathPrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'filePath',
        lower: [FilePathPrefix],
        upper: ['$FilePathPrefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> filePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'filePath',
        value: [''],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> filePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'filePath',
              upper: [''],
            ))
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'filePath',
              lower: [''],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'filePath',
              lower: [''],
            ))
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'filePath',
              upper: [''],
            ));
      }
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> timestampEqualTo(
      DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'timestamp',
        value: [timestamp],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> timestampNotEqualTo(
      DateTime timestamp) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [timestamp],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'timestamp',
              lower: [],
              upper: [timestamp],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> timestampGreaterThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [timestamp],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> timestampLessThan(
    DateTime timestamp, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [],
        upper: [timestamp],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> timestampBetween(
    DateTime lowerTimestamp,
    DateTime upperTimestamp, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'timestamp',
        lower: [lowerTimestamp],
        includeLower: includeLower,
        upper: [upperTimestamp],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> ocrTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ocrText',
        value: [null],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> ocrTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ocrText',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> ocrTextEqualTo(
      String? ocrText) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ocrText',
        value: [ocrText],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> ocrTextNotEqualTo(
      String? ocrText) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ocrText',
              lower: [],
              upper: [ocrText],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ocrText',
              lower: [ocrText],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ocrText',
              lower: [ocrText],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'ocrText',
              lower: [],
              upper: [ocrText],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> ocrTextGreaterThan(
    String? ocrText, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ocrText',
        lower: [ocrText],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> ocrTextLessThan(
    String? ocrText, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ocrText',
        lower: [],
        upper: [ocrText],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> ocrTextBetween(
    String? lowerOcrText,
    String? upperOcrText, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ocrText',
        lower: [lowerOcrText],
        includeLower: includeLower,
        upper: [upperOcrText],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> ocrTextStartsWith(
      String OcrTextPrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'ocrText',
        lower: [OcrTextPrefix],
        upper: ['$OcrTextPrefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> ocrTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'ocrText',
        value: [''],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> ocrTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'ocrText',
              upper: [''],
            ))
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'ocrText',
              lower: [''],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'ocrText',
              lower: [''],
            ))
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'ocrText',
              upper: [''],
            ));
      }
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> cleanTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'cleanText',
        value: [null],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> cleanTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'cleanText',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> cleanTextEqualTo(
      String? cleanText) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'cleanText',
        value: [cleanText],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> cleanTextNotEqualTo(
      String? cleanText) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cleanText',
              lower: [],
              upper: [cleanText],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cleanText',
              lower: [cleanText],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cleanText',
              lower: [cleanText],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'cleanText',
              lower: [],
              upper: [cleanText],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> cleanTextGreaterThan(
    String? cleanText, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'cleanText',
        lower: [cleanText],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> cleanTextLessThan(
    String? cleanText, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'cleanText',
        lower: [],
        upper: [cleanText],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> cleanTextBetween(
    String? lowerCleanText,
    String? upperCleanText, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'cleanText',
        lower: [lowerCleanText],
        includeLower: includeLower,
        upper: [upperCleanText],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> cleanTextStartsWith(
      String CleanTextPrefix) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'cleanText',
        lower: [CleanTextPrefix],
        upper: ['$CleanTextPrefix\u{FFFFF}'],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause> cleanTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'cleanText',
        value: [''],
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterWhereClause>
      cleanTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'cleanText',
              upper: [''],
            ))
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'cleanText',
              lower: [''],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.greaterThan(
              indexName: r'cleanText',
              lower: [''],
            ))
            .addWhereClause(IndexWhereClause.lessThan(
              indexName: r'cleanText',
              upper: [''],
            ));
      }
    });
  }
}

extension ScreenshotQueryFilter
    on QueryBuilder<Screenshot, Screenshot, QFilterCondition> {
  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      actionUrlIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'actionUrl',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      actionUrlIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'actionUrl',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> actionUrlEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actionUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      actionUrlGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'actionUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> actionUrlLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'actionUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> actionUrlBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'actionUrl',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      actionUrlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'actionUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> actionUrlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'actionUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> actionUrlContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'actionUrl',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> actionUrlMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'actionUrl',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      actionUrlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'actionUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      actionUrlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'actionUrl',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cleanTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cleanText',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cleanTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cleanText',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> cleanTextEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cleanText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cleanTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cleanText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> cleanTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cleanText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> cleanTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cleanText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cleanTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cleanText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> cleanTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cleanText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> cleanTextContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cleanText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> cleanTextMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cleanText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cleanTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cleanText',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cleanTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cleanText',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cryptoAddresses',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cryptoAddresses',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cryptoAddresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cryptoAddresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cryptoAddresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cryptoAddresses',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'cryptoAddresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'cryptoAddresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesElementContains(String value,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'cryptoAddresses',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesElementMatches(String pattern,
          {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'cryptoAddresses',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cryptoAddresses',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'cryptoAddresses',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'cryptoAddresses',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'cryptoAddresses',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'cryptoAddresses',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'cryptoAddresses',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'cryptoAddresses',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      cryptoAddressesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'cryptoAddresses',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> datesIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dates',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> datesIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dates',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dates',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dates',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dates',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dates',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'dates',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'dates',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'dates',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'dates',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dates',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'dates',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dates',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> datesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dates',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dates',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dates',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dates',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      datesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'dates',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> emailsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'emails',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'emails',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emails',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'emails',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'emails',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'emails',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'emails',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'emails',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'emails',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'emails',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'emails',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'emails',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'emails',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> emailsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'emails',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'emails',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'emails',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'emails',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      emailsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'emails',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> filePathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      filePathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> filePathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> filePathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'filePath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      filePathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> filePathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> filePathContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'filePath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> filePathMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'filePath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      filePathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      filePathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'filePath',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      isProcessedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isProcessed',
        value: value,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> ocrTextIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'ocrText',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      ocrTextIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'ocrText',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> ocrTextEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ocrText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      ocrTextGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'ocrText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> ocrTextLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'ocrText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> ocrTextBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'ocrText',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> ocrTextStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'ocrText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> ocrTextEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'ocrText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> ocrTextContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'ocrText',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> ocrTextMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'ocrText',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> ocrTextIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'ocrText',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      ocrTextIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'ocrText',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'phoneNumbers',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'phoneNumbers',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phoneNumbers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'phoneNumbers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'phoneNumbers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'phoneNumbers',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'phoneNumbers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'phoneNumbers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'phoneNumbers',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'phoneNumbers',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'phoneNumbers',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'phoneNumbers',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'phoneNumbers',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'phoneNumbers',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'phoneNumbers',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'phoneNumbers',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'phoneNumbers',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      phoneNumbersLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'phoneNumbers',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      suggestedActionsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'suggestedActions',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      suggestedActionsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'suggestedActions',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      suggestedActionsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'suggestedActions',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      suggestedActionsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'suggestedActions',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      suggestedActionsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'suggestedActions',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      suggestedActionsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'suggestedActions',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      suggestedActionsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'suggestedActions',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      suggestedActionsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'suggestedActions',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> tagsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tags',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> tagsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tags',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      tagsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      tagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      tagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      tagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tags',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      tagsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      tagsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      tagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'tags',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      tagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'tags',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      tagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      tagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'tags',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> tagsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> tagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> tagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      tagsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      tagsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> tagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> timestampEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      timestampGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> timestampLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'timestamp',
        value: value,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> timestampBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'timestamp',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> urlsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'urls',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> urlsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'urls',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      urlsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'urls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      urlsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'urls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      urlsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'urls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      urlsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'urls',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      urlsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'urls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      urlsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'urls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      urlsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'urls',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      urlsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'urls',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      urlsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'urls',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      urlsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'urls',
        value: '',
      ));
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> urlsLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'urls',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> urlsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'urls',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> urlsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'urls',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      urlsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'urls',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      urlsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'urls',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition> urlsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'urls',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension ScreenshotQueryObject
    on QueryBuilder<Screenshot, Screenshot, QFilterCondition> {
  QueryBuilder<Screenshot, Screenshot, QAfterFilterCondition>
      suggestedActionsElement(FilterQuery<SuggestedAction> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'suggestedActions');
    });
  }
}

extension ScreenshotQueryLinks
    on QueryBuilder<Screenshot, Screenshot, QFilterCondition> {}

extension ScreenshotQuerySortBy
    on QueryBuilder<Screenshot, Screenshot, QSortBy> {
  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> sortByActionUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionUrl', Sort.asc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> sortByActionUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionUrl', Sort.desc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> sortByCleanText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cleanText', Sort.asc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> sortByCleanTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cleanText', Sort.desc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> sortByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> sortByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> sortByIsProcessed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProcessed', Sort.asc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> sortByIsProcessedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProcessed', Sort.desc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> sortByOcrText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ocrText', Sort.asc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> sortByOcrTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ocrText', Sort.desc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> sortByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> sortByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension ScreenshotQuerySortThenBy
    on QueryBuilder<Screenshot, Screenshot, QSortThenBy> {
  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenByActionUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionUrl', Sort.asc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenByActionUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'actionUrl', Sort.desc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenByCleanText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cleanText', Sort.asc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenByCleanTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cleanText', Sort.desc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenByFilePath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.asc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenByFilePathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'filePath', Sort.desc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenByIsProcessed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProcessed', Sort.asc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenByIsProcessedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isProcessed', Sort.desc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenByOcrText() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ocrText', Sort.asc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenByOcrTextDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'ocrText', Sort.desc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.asc);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QAfterSortBy> thenByTimestampDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'timestamp', Sort.desc);
    });
  }
}

extension ScreenshotQueryWhereDistinct
    on QueryBuilder<Screenshot, Screenshot, QDistinct> {
  QueryBuilder<Screenshot, Screenshot, QDistinct> distinctByActionUrl(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'actionUrl', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QDistinct> distinctByCleanText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cleanText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QDistinct> distinctByCryptoAddresses() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cryptoAddresses');
    });
  }

  QueryBuilder<Screenshot, Screenshot, QDistinct> distinctByDates() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dates');
    });
  }

  QueryBuilder<Screenshot, Screenshot, QDistinct> distinctByEmails() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'emails');
    });
  }

  QueryBuilder<Screenshot, Screenshot, QDistinct> distinctByFilePath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'filePath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QDistinct> distinctByIsProcessed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isProcessed');
    });
  }

  QueryBuilder<Screenshot, Screenshot, QDistinct> distinctByOcrText(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'ocrText', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Screenshot, Screenshot, QDistinct> distinctByPhoneNumbers() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'phoneNumbers');
    });
  }

  QueryBuilder<Screenshot, Screenshot, QDistinct> distinctByTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tags');
    });
  }

  QueryBuilder<Screenshot, Screenshot, QDistinct> distinctByTimestamp() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'timestamp');
    });
  }

  QueryBuilder<Screenshot, Screenshot, QDistinct> distinctByUrls() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'urls');
    });
  }
}

extension ScreenshotQueryProperty
    on QueryBuilder<Screenshot, Screenshot, QQueryProperty> {
  QueryBuilder<Screenshot, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Screenshot, String?, QQueryOperations> actionUrlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'actionUrl');
    });
  }

  QueryBuilder<Screenshot, String?, QQueryOperations> cleanTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cleanText');
    });
  }

  QueryBuilder<Screenshot, List<String>?, QQueryOperations>
      cryptoAddressesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cryptoAddresses');
    });
  }

  QueryBuilder<Screenshot, List<String>?, QQueryOperations> datesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dates');
    });
  }

  QueryBuilder<Screenshot, List<String>?, QQueryOperations> emailsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'emails');
    });
  }

  QueryBuilder<Screenshot, String, QQueryOperations> filePathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'filePath');
    });
  }

  QueryBuilder<Screenshot, bool, QQueryOperations> isProcessedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isProcessed');
    });
  }

  QueryBuilder<Screenshot, String?, QQueryOperations> ocrTextProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'ocrText');
    });
  }

  QueryBuilder<Screenshot, List<String>?, QQueryOperations>
      phoneNumbersProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'phoneNumbers');
    });
  }

  QueryBuilder<Screenshot, List<SuggestedAction>?, QQueryOperations>
      suggestedActionsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'suggestedActions');
    });
  }

  QueryBuilder<Screenshot, List<String>?, QQueryOperations> tagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tags');
    });
  }

  QueryBuilder<Screenshot, DateTime, QQueryOperations> timestampProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'timestamp');
    });
  }

  QueryBuilder<Screenshot, List<String>?, QQueryOperations> urlsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'urls');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const SuggestedActionSchema = Schema(
  name: r'SuggestedAction',
  id: 5067764616342620424,
  properties: {
    r'intentType': PropertySchema(
      id: 0,
      name: r'intentType',
      type: IsarType.string,
    ),
    r'label': PropertySchema(
      id: 1,
      name: r'label',
      type: IsarType.string,
    ),
    r'payload': PropertySchema(
      id: 2,
      name: r'payload',
      type: IsarType.string,
    )
  },
  estimateSize: _suggestedActionEstimateSize,
  serialize: _suggestedActionSerialize,
  deserialize: _suggestedActionDeserialize,
  deserializeProp: _suggestedActionDeserializeProp,
);

int _suggestedActionEstimateSize(
  SuggestedAction object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.intentType;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.label;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.payload;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _suggestedActionSerialize(
  SuggestedAction object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.intentType);
  writer.writeString(offsets[1], object.label);
  writer.writeString(offsets[2], object.payload);
}

SuggestedAction _suggestedActionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SuggestedAction();
  object.intentType = reader.readStringOrNull(offsets[0]);
  object.label = reader.readStringOrNull(offsets[1]);
  object.payload = reader.readStringOrNull(offsets[2]);
  return object;
}

P _suggestedActionDeserializeProp<P>(
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
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension SuggestedActionQueryFilter
    on QueryBuilder<SuggestedAction, SuggestedAction, QFilterCondition> {
  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      intentTypeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'intentType',
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      intentTypeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'intentType',
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      intentTypeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'intentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      intentTypeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'intentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      intentTypeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'intentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      intentTypeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'intentType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      intentTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'intentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      intentTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'intentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      intentTypeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'intentType',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      intentTypeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'intentType',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      intentTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'intentType',
        value: '',
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      intentTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'intentType',
        value: '',
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      labelIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'label',
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      labelIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'label',
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      labelEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      labelGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      labelLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      labelBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'label',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      labelStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      labelEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      labelContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'label',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      labelMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'label',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      labelIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      labelIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'label',
        value: '',
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      payloadIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'payload',
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      payloadIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'payload',
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      payloadEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      payloadGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      payloadLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      payloadBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'payload',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      payloadStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      payloadEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      payloadContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'payload',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      payloadMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'payload',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      payloadIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'payload',
        value: '',
      ));
    });
  }

  QueryBuilder<SuggestedAction, SuggestedAction, QAfterFilterCondition>
      payloadIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'payload',
        value: '',
      ));
    });
  }
}

extension SuggestedActionQueryObject
    on QueryBuilder<SuggestedAction, SuggestedAction, QFilterCondition> {}
