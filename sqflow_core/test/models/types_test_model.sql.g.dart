// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'types_test_model.dart';

const _$SQFlowScalarItemSchema = """
CREATE TABLE scalar_items (
  id INTEGER PRIMARY KEY,
  big_value TEXT NOT NULL,
  website TEXT NOT NULL,
  timeout INTEGER NOT NULL,
  optional_big TEXT,
  optional_uri TEXT,
  optional_duration INTEGER
);


""";

class _$SQFlowScalarItemTable extends Table<ScalarItem> {
  _$SQFlowScalarItemTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = 'id',
    super.timestamps = true,
  }) : super(type: ScalarItem, paranoid: Table.detectSoftDelete(schema));
}

/// ScalarItem table schema
final scalar_itemsTable = _$SQFlowScalarItemTable(
  schema: _$SQFlowScalarItemSchema,
  name: 'scalar_items',
  fromJson: _$SQFlowScalarItemFromJson,
  relationships: [],
  columns: const [
    'id',
    'big_value',
    'website',
    'timeout',
    'optional_big',
    'optional_uri',
    'optional_duration'
  ],
  primaryKey: 'id',
  timestamps: false,
);

mixin _$SQFlowScalarItemMixin {
  Map<String, dynamic> toJson() => _$SQFlowScalarItemToJson(this as ScalarItem);

  @override
  String toString() => _$SQFlowScalarItemToString(this as ScalarItem);
}

Map<String, dynamic> _$SQFlowScalarItemToJson(ScalarItem instance) {
  final scalaritemJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'big_value': _$SQFlowToJsonValue(instance.bigValue.toString()),
    'website': _$SQFlowToJsonValue(instance.website.toString()),
    'timeout': _$SQFlowToJsonValue(instance.timeout.inMicroseconds),
    'optional_big': _$SQFlowToJsonValue(instance.optionalBig?.toString()),
    'optional_uri': _$SQFlowToJsonValue(instance.optionalUri?.toString()),
    'optional_duration':
        _$SQFlowToJsonValue(instance.optionalDuration?.inMicroseconds),
  };

  return scalaritemJson;
}

String _$SQFlowScalarItemToString(ScalarItem instance) {
  return """
ScalarItem(
  id: ${instance.id},
  bigValue: ${instance.bigValue},
  website: ${instance.website},
  timeout: ${instance.timeout},
  optionalBig: ${instance.optionalBig},
  optionalUri: ${instance.optionalUri},
  optionalDuration: ${instance.optionalDuration},
)""";
}

extension SQFlowScalarItemExt on ScalarItem {
  ScalarItem copyWith({
    int? id,
    BigInt? bigValue,
    Uri? website,
    Duration? timeout,
    BigInt? optionalBig,
    Uri? optionalUri,
    Duration? optionalDuration,
  }) {
    return ScalarItem(
      id: id ?? this.id,
      bigValue: bigValue ?? this.bigValue,
      website: website ?? this.website,
      timeout: timeout ?? this.timeout,
      optionalBig: optionalBig ?? this.optionalBig,
      optionalUri: optionalUri ?? this.optionalUri,
      optionalDuration: optionalDuration ?? this.optionalDuration,
    );
  }
}

ScalarItem _$SQFlowScalarItemFromJson(Map<String, dynamic> json) {
  final instance = ScalarItem(
    id: json['id'] as int,
    bigValue: BigInt.parse(json['big_value'] as String),
    website: Uri.parse(json['website'] as String),
    timeout: Duration(microseconds: json['timeout'] as int),
    optionalBig: json['optional_big'] != null
        ? BigInt.parse(json['optional_big'] as String)
        : null,
    optionalUri: json['optional_uri'] != null
        ? Uri.parse(json['optional_uri'] as String)
        : null,
    optionalDuration: json['optional_duration'] != null
        ? Duration(microseconds: json['optional_duration'] as int)
        : null,
  );
  return instance;
}

/// Pluralized service for ScalarItem
class ScalarItems {
  static const SqflowColumn<int> id =
      SqflowColumn<int>('id', tableName: 'scalar_items');
  static const SqflowColumn<BigInt> bigValue =
      SqflowColumn<BigInt>('big_value', tableName: 'scalar_items');
  static const SqflowColumn<Uri> website =
      SqflowColumn<Uri>('website', tableName: 'scalar_items');
  static const SqflowColumn<Duration> timeout =
      SqflowColumn<Duration>('timeout', tableName: 'scalar_items');
  static const SqflowColumn<BigInt> optionalBig =
      SqflowColumn<BigInt>('optional_big', tableName: 'scalar_items');
  static const SqflowColumn<Uri> optionalUri =
      SqflowColumn<Uri>('optional_uri', tableName: 'scalar_items');
  static const SqflowColumn<Duration> optionalDuration =
      SqflowColumn<Duration>('optional_duration', tableName: 'scalar_items');

  static SqflowCore<ScalarItem> get _service =>
      SqflowCore<ScalarItem>(dbManager: appDb, table: scalar_itemsTable);

  static SqflowQuery<ScalarItem> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<ScalarItem> get query => _service.query;

  static Future<int> insert(ScalarItem item, {DatabaseExecutor? executor}) =>
      _service.insert(item, executor: executor);
  static Future<int> update(ScalarItem item, {DatabaseExecutor? executor}) =>
      _service.update(item, executor: executor);
  static Future<void> upsert(ScalarItem item, {DatabaseExecutor? executor}) =>
      _service.upsert(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.delete(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restore(id, executor: executor);

  static Future<int> insertBatch(List<ScalarItem> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatch(items, executor: executor);
  static Future<int> updateBatch(List<ScalarItem> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatch(items, executor: executor);
  static Future<int> upsertBatch(List<ScalarItem> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatch(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatch(ids, force: force, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.exists(id, withDeleted: withDeleted, executor: executor);

  static Future<ScalarItem?> readOne(Object id,
          {List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readOne(id,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          include: include,
          executor: executor);

  static Future<Result<ScalarItem>> readAll(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAll(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<ResultWithCount<ScalarItem>> readAllWithCount(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAllWithCount(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<int> count(
          {Object? column, WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.count(column: column, where: where, executor: executor);
  static Future<num> sum(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.sum(column, where: where, executor: executor);
  static Future<num> avg(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.avg(column, where: where, executor: executor);
  static Future<num> min(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.min(column, where: where, executor: executor);
  static Future<num> max(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.max(column, where: where, executor: executor);

  static Future<T> transaction<T>(
          Future<T> Function(DatabaseExecutor txn) action) =>
      _service.transaction(action);

  static Stream<String> get changeStream => _service.dbManager.changeStream;
  static Stream<ScalarItem?> watchOne(Object id, {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<ScalarItem>> watchAll(
          {WhereBuilder? where,
          List<Includable>? include,
          SortBuilder? sort,
          int? limit}) =>
      _service.watchAll(
          where: where, include: include, sort: sort, limit: limit);
}

const _$SQFlowCollectionItemSchema = """
CREATE TABLE collection_items (
  id INTEGER PRIMARY KEY,
  tags TEXT NOT NULL,
  scores TEXT NOT NULL,
  metadata TEXT NOT NULL
);


""";

class _$SQFlowCollectionItemTable extends Table<CollectionItem> {
  _$SQFlowCollectionItemTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = 'id',
    super.timestamps = true,
  }) : super(type: CollectionItem, paranoid: Table.detectSoftDelete(schema));
}

/// CollectionItem table schema
final collection_itemsTable = _$SQFlowCollectionItemTable(
  schema: _$SQFlowCollectionItemSchema,
  name: 'collection_items',
  fromJson: _$SQFlowCollectionItemFromJson,
  relationships: [],
  columns: const ['id', 'tags', 'scores', 'metadata'],
  primaryKey: 'id',
  timestamps: false,
);

mixin _$SQFlowCollectionItemMixin {
  Map<String, dynamic> toJson() =>
      _$SQFlowCollectionItemToJson(this as CollectionItem);

  @override
  String toString() => _$SQFlowCollectionItemToString(this as CollectionItem);
}

Map<String, dynamic> _$SQFlowCollectionItemToJson(CollectionItem instance) {
  final collectionitemJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'tags': _$SQFlowToJsonValue(instance.tags),
    'scores': _$SQFlowToJsonValue(instance.scores),
    'metadata': _$SQFlowToJsonValue(instance.metadata),
  };

  return collectionitemJson;
}

String _$SQFlowCollectionItemToString(CollectionItem instance) {
  return """
CollectionItem(
  id: ${instance.id},
  tags: ${instance.tags},
  scores: ${instance.scores},
  metadata: ${instance.metadata},
)""";
}

extension SQFlowCollectionItemExt on CollectionItem {
  CollectionItem copyWith({
    int? id,
    List<String>? tags,
    Set<int>? scores,
    Map<String, int>? metadata,
  }) {
    return CollectionItem(
      id: id ?? this.id,
      tags: tags ?? this.tags,
      scores: scores ?? this.scores,
      metadata: metadata ?? this.metadata,
    );
  }
}

CollectionItem _$SQFlowCollectionItemFromJson(Map<String, dynamic> json) {
  final instance = CollectionItem(
    id: json['id'] as int,
    tags: (_$SQFlowDecodeJson(json['tags']) as List)
        .map((e) => e as String)
        .toList(),
    scores: (_$SQFlowDecodeJson(json['scores']) as List)
        .map((e) => e as int)
        .toSet(),
    metadata: (_$SQFlowDecodeJson(json['metadata']) as Map)
        .map((k, v) => MapEntry(k as String, v as int)),
  );
  return instance;
}

/// Pluralized service for CollectionItem
class CollectionItems {
  static const SqflowColumn<int> id =
      SqflowColumn<int>('id', tableName: 'collection_items');
  static const SqflowColumn<List<String>> tags =
      SqflowColumn<List<String>>('tags', tableName: 'collection_items');
  static const SqflowColumn<Set<int>> scores =
      SqflowColumn<Set<int>>('scores', tableName: 'collection_items');
  static const SqflowColumn<Map<String, int>> metadata =
      SqflowColumn<Map<String, int>>('metadata', tableName: 'collection_items');

  static SqflowCore<CollectionItem> get _service => SqflowCore<CollectionItem>(
      dbManager: appDb, table: collection_itemsTable);

  static SqflowQuery<CollectionItem> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<CollectionItem> get query => _service.query;

  static Future<int> insert(CollectionItem item,
          {DatabaseExecutor? executor}) =>
      _service.insert(item, executor: executor);
  static Future<int> update(CollectionItem item,
          {DatabaseExecutor? executor}) =>
      _service.update(item, executor: executor);
  static Future<void> upsert(CollectionItem item,
          {DatabaseExecutor? executor}) =>
      _service.upsert(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.delete(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restore(id, executor: executor);

  static Future<int> insertBatch(List<CollectionItem> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatch(items, executor: executor);
  static Future<int> updateBatch(List<CollectionItem> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatch(items, executor: executor);
  static Future<int> upsertBatch(List<CollectionItem> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatch(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatch(ids, force: force, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.exists(id, withDeleted: withDeleted, executor: executor);

  static Future<CollectionItem?> readOne(Object id,
          {List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readOne(id,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          include: include,
          executor: executor);

  static Future<Result<CollectionItem>> readAll(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAll(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<ResultWithCount<CollectionItem>> readAllWithCount(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAllWithCount(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<int> count(
          {Object? column, WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.count(column: column, where: where, executor: executor);
  static Future<num> sum(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.sum(column, where: where, executor: executor);
  static Future<num> avg(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.avg(column, where: where, executor: executor);
  static Future<num> min(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.min(column, where: where, executor: executor);
  static Future<num> max(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.max(column, where: where, executor: executor);

  static Future<T> transaction<T>(
          Future<T> Function(DatabaseExecutor txn) action) =>
      _service.transaction(action);

  static Stream<String> get changeStream => _service.dbManager.changeStream;
  static Stream<CollectionItem?> watchOne(Object id,
          {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<CollectionItem>> watchAll(
          {WhereBuilder? where,
          List<Includable>? include,
          SortBuilder? sort,
          int? limit}) =>
      _service.watchAll(
          where: where, include: include, sort: sort, limit: limit);
}

const _$SQFlowApiResponseSchema = """
CREATE TABLE api_responses (
  id INTEGER PRIMARY KEY,
  status TEXT NOT NULL
);


""";

class _$SQFlowApiResponseTable extends Table<ApiResponse<dynamic>> {
  _$SQFlowApiResponseTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = 'id',
    super.timestamps = true,
  }) : super(type: ApiResponse, paranoid: Table.detectSoftDelete(schema));
}

/// ApiResponse table schema
final api_responsesTable = _$SQFlowApiResponseTable(
  schema: _$SQFlowApiResponseSchema,
  name: 'api_responses',
  fromJson: (json) => _$SQFlowApiResponseFromJson(json, (x) => x),
  relationships: [],
  columns: const ['id', 'status'],
  primaryKey: 'id',
  timestamps: false,
);

mixin _$SQFlowApiResponseMixin<T> {
  Map<String, dynamic> toJson([Object? Function(T value)? toJsonT]) =>
      _$SQFlowApiResponseToJson(this as ApiResponse<T>, toJsonT ?? (x) => x);

  @override
  String toString() => _$SQFlowApiResponseToString(this as ApiResponse<T>);
}

Map<String, dynamic> _$SQFlowApiResponseToJson<T>(
    ApiResponse<T> instance, Object? Function(T value) toJsonT) {
  final apiresponseJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'status': _$SQFlowToJsonValue(instance.status),
    'data': _$SQFlowToJsonValue(
        instance.data != null ? toJsonT(instance.data as T) : null),
  };

  return apiresponseJson;
}

String _$SQFlowApiResponseToString<T>(ApiResponse<T> instance) {
  return """
ApiResponse(
  id: ${instance.id},
  status: ${instance.status},
  data: ${instance.data},
)""";
}

extension SQFlowApiResponseExt<T> on ApiResponse<T> {
  ApiResponse<T> copyWith({
    int? id,
    String? status,
    T? data,
  }) {
    return ApiResponse(
      id: id ?? this.id,
      status: status ?? this.status,
      data: data ?? this.data,
    );
  }
}

ApiResponse<T> _$SQFlowApiResponseFromJson<T>(
    Map<String, dynamic> json, T Function(Object? json) fromJsonT) {
  final instance = ApiResponse(
    id: json['id'] as int,
    status: json['status'] as String,
    data: json['data'] != null ? fromJsonT(json['data']) : null,
  );
  return instance;
}

/// Pluralized service for ApiResponse
class ApiResponses {
  static const SqflowColumn<int> id =
      SqflowColumn<int>('id', tableName: 'api_responses');
  static const SqflowColumn<String> status =
      SqflowColumn<String>('status', tableName: 'api_responses');

  static SqflowCore<ApiResponse<dynamic>> get _service =>
      SqflowCore<ApiResponse<dynamic>>(
          dbManager: appDb, table: api_responsesTable);

  static SqflowQuery<ApiResponse<dynamic>> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<ApiResponse<dynamic>> get query => _service.query;

  static Future<int> insert(ApiResponse<dynamic> item,
          {DatabaseExecutor? executor}) =>
      _service.insert(item, executor: executor);
  static Future<int> update(ApiResponse<dynamic> item,
          {DatabaseExecutor? executor}) =>
      _service.update(item, executor: executor);
  static Future<void> upsert(ApiResponse<dynamic> item,
          {DatabaseExecutor? executor}) =>
      _service.upsert(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.delete(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restore(id, executor: executor);

  static Future<int> insertBatch(List<ApiResponse<dynamic>> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatch(items, executor: executor);
  static Future<int> updateBatch(List<ApiResponse<dynamic>> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatch(items, executor: executor);
  static Future<int> upsertBatch(List<ApiResponse<dynamic>> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatch(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatch(ids, force: force, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.exists(id, withDeleted: withDeleted, executor: executor);

  static Future<ApiResponse<dynamic>?> readOne(Object id,
          {List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readOne(id,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          include: include,
          executor: executor);

  static Future<Result<ApiResponse<dynamic>>> readAll(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAll(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<ResultWithCount<ApiResponse<dynamic>>> readAllWithCount(
          {int limit = 20,
          int offset = 0,
          WhereBuilder? where,
          SortBuilder? sort,
          List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          bool onlyDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readAllWithCount(
          limit: limit,
          offset: offset,
          where: where,
          sort: sort,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          onlyDeleted: onlyDeleted,
          include: include,
          executor: executor);

  static Future<int> count(
          {Object? column, WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.count(column: column, where: where, executor: executor);
  static Future<num> sum(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.sum(column, where: where, executor: executor);
  static Future<num> avg(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.avg(column, where: where, executor: executor);
  static Future<num> min(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.min(column, where: where, executor: executor);
  static Future<num> max(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.max(column, where: where, executor: executor);

  static Future<T> transaction<T>(
          Future<T> Function(DatabaseExecutor txn) action) =>
      _service.transaction(action);

  static Stream<String> get changeStream => _service.dbManager.changeStream;
  static Stream<ApiResponse<dynamic>?> watchOne(Object id,
          {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<ApiResponse<dynamic>>> watchAll(
          {WhereBuilder? where,
          List<Includable>? include,
          SortBuilder? sort,
          int? limit}) =>
      _service.watchAll(
          where: where, include: include, sort: sort, limit: limit);
}

dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  // Collections and Maps are stored as JSON strings in SQLite
  if (value is List || value is Set || value is Map) {
    return jsonEncode(value is Set ? value.toList() : value);
  }
  return value;
}

/// Decodes a value from SQLite storage.
/// JSON strings (from List/Set/Map fields) are decoded back to Dart objects.
dynamic _$SQFlowDecodeJson(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trimLeft();
    if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
      try {
        return jsonDecode(value);
      } catch (_) {}
    }
  }
  return value;
}
