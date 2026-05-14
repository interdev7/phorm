// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'explicit_naming.dart';

const _$SQFlowExplicitNamingSchema = """
CREATE TABLE explicit_table (
  custom_id TEXT PRIMARY KEY NOT NULL UNIQUE,
  custom_name TEXT NOT NULL,
  custom_age INTEGER NOT NULL,
  is_verified INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);


CREATE TRIGGER update_explicit_table_timestamp
AFTER UPDATE ON explicit_table
FOR EACH ROW
BEGIN
    UPDATE explicit_table SET updated_at = datetime('now') WHERE id = OLD.id;
END;
""";

class _$SQFlowExplicitNamingTable extends Table<ExplicitNaming> {
  _$SQFlowExplicitNamingTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = 'custom_id',
    super.timestamps = true,
  }) : super(type: ExplicitNaming, paranoid: Table.detectSoftDelete(schema));
}

/// ExplicitNaming table schema
final explicit_tableTable = _$SQFlowExplicitNamingTable(
  schema: _$SQFlowExplicitNamingSchema,
  name: 'explicit_table',
  fromJson: _$SQFlowExplicitNamingFromJson,
  relationships: [],
  columns: const [
    'custom_id',
    'custom_name',
    'custom_age',
    'is_verified',
    'created_at',
    'updated_at'
  ],
  primaryKey: 'custom_id',
  timestamps: true,
);

mixin _$SQFlowExplicitNamingMixin {
  Map<String, dynamic> toJson() =>
      _$SQFlowExplicitNamingToJson(this as ExplicitNaming);

  @override
  String toString() => _$SQFlowExplicitNamingToString(this as ExplicitNaming);
  DateTime? createdAt;
  DateTime? updatedAt;
}

Map<String, dynamic> _$SQFlowExplicitNamingToJson(ExplicitNaming instance) {
  final explicitnamingJson = {
    'custom_id': _$SQFlowToJsonValue(instance.id),
    'custom_name': _$SQFlowToJsonValue(instance.name),
    'custom_age': _$SQFlowToJsonValue(instance.age),
    'is_verified': _$SQFlowToJsonValue(instance.isVerified),
    'created_at': _$SQFlowToJsonValue(instance.createdAt),
    'updated_at': _$SQFlowToJsonValue(instance.updatedAt),
  };
  _$validateExplicitNaming(explicitnamingJson, tableName: 'explicit_table');

  return explicitnamingJson;
}

String _$SQFlowExplicitNamingToString(ExplicitNaming instance) {
  return """
ExplicitNaming(
  id: ${instance.id},
  name: ${instance.name},
  age: ${instance.age},
  isVerified: ${instance.isVerified},
  createdAt: ${instance.createdAt},
  updatedAt: ${instance.updatedAt},
)""";
}

extension SQFlowExplicitNamingExt on ExplicitNaming {
  ExplicitNaming copyWith({
    String? id,
    String? name,
    int? age,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExplicitNaming(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      isVerified: isVerified ?? this.isVerified,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }
}

void _$validateExplicitNaming(Map<String, dynamic> json,
    {required String tableName}) {}

ExplicitNaming _$SQFlowExplicitNamingFromJson(Map<String, dynamic> json) {
  final instance = ExplicitNaming(
    id: json['custom_id'] as String,
    name: json['custom_name'] as String,
    age: json['custom_age'] as int,
    isVerified: json['is_verified'] is bool
        ? json['is_verified'] as bool
        : (json['is_verified'] as int?) == 1,
  )
    ..createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null
    ..updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null;
  return instance;
}

/// Pluralized service for ExplicitNaming
class ExplicitTable {
  static const SqflowColumn<String> id = SqflowColumn<String>('custom_id');
  static const SqflowColumn<String> name = SqflowColumn<String>('custom_name');
  static const SqflowColumn<int> age = SqflowColumn<int>('custom_age');
  static const SqflowColumn<bool> isVerified =
      SqflowColumn<bool>('is_verified');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at');

  static SqflowCore<ExplicitNaming> get _service =>
      SqflowCore<ExplicitNaming>(dbManager: appDb, table: explicit_tableTable);

  static SqflowQuery<ExplicitNaming> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<ExplicitNaming> get query => _service.query;

  static Future<int> insert(ExplicitNaming item,
          {DatabaseExecutor? executor}) =>
      _service.insertAsync(item, executor: executor);
  static Future<int> update(ExplicitNaming item,
          {DatabaseExecutor? executor}) =>
      _service.updateAsync(item, executor: executor);
  static Future<void> upsert(ExplicitNaming item,
          {DatabaseExecutor? executor}) =>
      _service.upsertAsync(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteAsync(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restoreAsync(id, executor: executor);

  static Future<int> insertBatch(List<ExplicitNaming> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatchAsync(items, executor: executor);
  static Future<int> updateBatch(List<ExplicitNaming> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatchAsync(items, executor: executor);
  static Future<int> upsertBatch(List<ExplicitNaming> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatchAsync(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatchAsync(ids, force: force, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.existsAsync(id, withDeleted: withDeleted, executor: executor);

  static Future<ExplicitNaming?> readOne(Object id,
          {List<String>? columns,
          Attributes? attributes,
          bool withDeleted = false,
          List<Includable>? include,
          DatabaseExecutor? executor}) =>
      _service.readOneAsync(id,
          columns: columns,
          attributes: attributes,
          withDeleted: withDeleted,
          include: include,
          executor: executor);

  static Future<Result<ExplicitNaming>> readAll(
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

  static Future<ResultWithCount<ExplicitNaming>> readAllWithCount(
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
      _service.countAsync(column: column, where: where, executor: executor);
  static Future<num> sum(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.sumAsync(column, where: where, executor: executor);
  static Future<num> avg(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.avgAsync(column, where: where, executor: executor);
  static Future<num> min(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.minAsync(column, where: where, executor: executor);
  static Future<num> max(Object column,
          {WhereBuilder? where, DatabaseExecutor? executor}) =>
      _service.maxAsync(column, where: where, executor: executor);

  static Future<T> transaction<T>(
          Future<T> Function(DatabaseExecutor txn) action) =>
      _service.transaction(action);

  static Stream<String> get changeStream => _service.dbManager.changeStream;
  static Stream<ExplicitNaming?> watchOne(Object id,
          {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<ExplicitNaming>> watchAll(
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
  return value;
}
