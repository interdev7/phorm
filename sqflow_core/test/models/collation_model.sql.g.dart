// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'collation_model.dart';

const _$SQFlowCollationTestSchema = """
CREATE TABLE collation_tests (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  name_no_case TEXT COLLATE NOCASE NOT NULL,
  name_binary TEXT COLLATE BINARY NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);


CREATE TRIGGER update_collation_tests_timestamp
AFTER UPDATE ON collation_tests
FOR EACH ROW
BEGIN
    UPDATE collation_tests SET updated_at = datetime('now') WHERE id = OLD.id;
END;
""";

class _$SQFlowCollationTestTable extends Table<CollationTest> {
  _$SQFlowCollationTestTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = 'id',
    super.timestamps = true,
  }) : super(type: CollationTest, paranoid: Table.detectSoftDelete(schema));
}

/// CollationTest table schema
final collation_testsTable = _$SQFlowCollationTestTable(
  schema: _$SQFlowCollationTestSchema,
  name: 'collation_tests',
  fromJson: _$SQFlowCollationTestFromJson,
  relationships: [],
  columns: const [
    'id',
    'name_no_case',
    'name_binary',
    'created_at',
    'updated_at'
  ],
  primaryKey: 'id',
  timestamps: true,
);

mixin _$SQFlowCollationTestMixin {
  Map<String, dynamic> toJson() =>
      _$SQFlowCollationTestToJson(this as CollationTest);

  @override
  String toString() => _$SQFlowCollationTestToString(this as CollationTest);
  DateTime? createdAt;
  DateTime? updatedAt;
}

Map<String, dynamic> _$SQFlowCollationTestToJson(CollationTest instance) {
  final collationtestJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'name_no_case': _$SQFlowToJsonValue(instance.nameNoCase),
    'name_binary': _$SQFlowToJsonValue(instance.nameBinary),
    'created_at': _$SQFlowToJsonValue(instance.createdAt),
    'updated_at': _$SQFlowToJsonValue(instance.updatedAt),
  };
  _$validateCollationTest(collationtestJson, tableName: 'collation_tests');

  return collationtestJson;
}

String _$SQFlowCollationTestToString(CollationTest instance) {
  return """
CollationTest(
  id: ${instance.id},
  nameNoCase: ${instance.nameNoCase},
  nameBinary: ${instance.nameBinary},
  createdAt: ${instance.createdAt},
  updatedAt: ${instance.updatedAt},
)""";
}

extension SQFlowCollationTestExt on CollationTest {
  CollationTest copyWith({
    String? id,
    String? nameNoCase,
    String? nameBinary,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CollationTest(
      id: id ?? this.id,
      nameNoCase: nameNoCase ?? this.nameNoCase,
      nameBinary: nameBinary ?? this.nameBinary,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }
}

void _$validateCollationTest(Map<String, dynamic> json,
    {required String tableName}) {}

CollationTest _$SQFlowCollationTestFromJson(Map<String, dynamic> json) {
  final instance = CollationTest(
    id: json['id'] as String,
    nameNoCase: json['name_no_case'] as String,
    nameBinary: json['name_binary'] as String,
  )
    ..createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null
    ..updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null;
  return instance;
}

/// Pluralized service for CollationTest
class CollationTests {
  static const SqflowColumn<String> id =
      SqflowColumn<String>('id', tableName: 'collation_tests');
  static const SqflowColumn<String> nameNoCase =
      SqflowColumn<String>('name_no_case', tableName: 'collation_tests');
  static const SqflowColumn<String> nameBinary =
      SqflowColumn<String>('name_binary', tableName: 'collation_tests');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at', tableName: 'collation_tests');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at', tableName: 'collation_tests');

  static SqflowCore<CollationTest> get _service =>
      SqflowCore<CollationTest>(dbManager: appDb, table: collation_testsTable);

  static SqflowQuery<CollationTest> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<CollationTest> get query => _service.query;

  static Future<int> insert(CollationTest item, {DatabaseExecutor? executor}) =>
      _service.insert(item, executor: executor);
  static Future<int> update(CollationTest item, {DatabaseExecutor? executor}) =>
      _service.update(item, executor: executor);
  static Future<void> upsert(CollationTest item,
          {DatabaseExecutor? executor}) =>
      _service.upsert(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.delete(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restore(id, executor: executor);

  static Future<int> insertBatch(List<CollationTest> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatch(items, executor: executor);
  static Future<int> updateBatch(List<CollationTest> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatch(items, executor: executor);
  static Future<int> upsertBatch(List<CollationTest> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatch(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatch(ids, force: force, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.exists(id, withDeleted: withDeleted, executor: executor);

  static Future<CollationTest?> readOne(Object id,
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

  static Future<Result<CollationTest>> readAll(
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

  static Future<ResultWithCount<CollationTest>> readAllWithCount(
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
  static Stream<CollationTest?> watchOne(Object id,
          {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<CollationTest>> watchAll(
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
