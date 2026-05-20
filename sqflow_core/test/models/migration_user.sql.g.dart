// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'migration_user.dart';

const _$SQFlowMigrationUserSchema = """
CREATE TABLE migration_users (
  custom_id TEXT PRIMARY KEY NOT NULL UNIQUE,
  name TEXT NOT NULL,
  email TEXT,
  age INTEGER,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);


CREATE TRIGGER update_migration_users_timestamp
AFTER UPDATE ON migration_users
FOR EACH ROW
BEGIN
    UPDATE migration_users SET updated_at = datetime('now') WHERE id = OLD.id;
END;
""";

class _$SQFlowMigrationUserTable extends Table<MigrationUser> {
  _$SQFlowMigrationUserTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = 'custom_id',
    super.timestamps = true,
  }) : super(type: MigrationUser, paranoid: Table.detectSoftDelete(schema));
}

/// MigrationUser table schema
final migration_usersTable = _$SQFlowMigrationUserTable(
  schema: _$SQFlowMigrationUserSchema,
  name: 'migration_users',
  fromJson: _$SQFlowMigrationUserFromJson,
  relationships: [],
  columns: const [
    'custom_id',
    'name',
    'email',
    'age',
    'is_active',
    'created_at',
    'updated_at'
  ],
  primaryKey: 'custom_id',
  timestamps: true,
);

mixin _$SQFlowMigrationUserMixin {
  Map<String, dynamic> toJson() =>
      _$SQFlowMigrationUserToJson(this as MigrationUser);

  @override
  String toString() => _$SQFlowMigrationUserToString(this as MigrationUser);
  DateTime? createdAt;
  DateTime? updatedAt;
}

Map<String, dynamic> _$SQFlowMigrationUserToJson(MigrationUser instance) {
  final migrationuserJson = {
    'custom_id': _$SQFlowToJsonValue(instance.id),
    'name': _$SQFlowToJsonValue(instance.name),
    'email': _$SQFlowToJsonValue(instance.email),
    'age': _$SQFlowToJsonValue(instance.age),
    'is_active': _$SQFlowToJsonValue(instance.isActive),
    'created_at': _$SQFlowToJsonValue(instance.createdAt),
    'updated_at': _$SQFlowToJsonValue(instance.updatedAt),
  };

  return migrationuserJson;
}

String _$SQFlowMigrationUserToString(MigrationUser instance) {
  return """
MigrationUser(
  id: ${instance.id},
  name: ${instance.name},
  email: ${instance.email},
  age: ${instance.age},
  isActive: ${instance.isActive},
  createdAt: ${instance.createdAt},
  updatedAt: ${instance.updatedAt},
)""";
}

extension SQFlowMigrationUserExt on MigrationUser {
  MigrationUser copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MigrationUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      isActive: isActive ?? this.isActive,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }
}

MigrationUser _$SQFlowMigrationUserFromJson(Map<String, dynamic> json) {
  final instance = MigrationUser(
    id: json['custom_id'] as String,
    name: json['name'] as String,
    email: json['email'] as String?,
    age: json['age'] as int?,
    isActive: json['is_active'] is bool
        ? json['is_active'] as bool
        : (json['is_active'] as int) == 1,
  )
    ..createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null
    ..updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null;
  return instance;
}

/// Pluralized service for MigrationUser
class MigrationUsers {
  static const SqflowColumn<String> id =
      SqflowColumn<String>('custom_id', tableName: 'migration_users');
  static const SqflowColumn<String> name =
      SqflowColumn<String>('name', tableName: 'migration_users');
  static const SqflowColumn<String> email =
      SqflowColumn<String>('email', tableName: 'migration_users');
  static const SqflowColumn<int> age =
      SqflowColumn<int>('age', tableName: 'migration_users');
  static const SqflowColumn<bool> isActive =
      SqflowColumn<bool>('is_active', tableName: 'migration_users');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at', tableName: 'migration_users');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at', tableName: 'migration_users');

  static SqflowCore<MigrationUser> get _service =>
      SqflowCore<MigrationUser>(dbManager: appDb, table: migration_usersTable);

  static SqflowQuery<MigrationUser> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<MigrationUser> get query => _service.query;

  static Future<int> insert(MigrationUser item, {DatabaseExecutor? executor}) =>
      _service.insert(item, executor: executor);
  static Future<int> update(MigrationUser item, {DatabaseExecutor? executor}) =>
      _service.update(item, executor: executor);
  static Future<void> upsert(MigrationUser item,
          {DatabaseExecutor? executor}) =>
      _service.upsert(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.delete(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restore(id, executor: executor);

  static Future<int> insertBatch(List<MigrationUser> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatch(items, executor: executor);
  static Future<int> updateBatch(List<MigrationUser> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatch(items, executor: executor);
  static Future<int> upsertBatch(List<MigrationUser> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatch(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatch(ids, force: force, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.exists(id, withDeleted: withDeleted, executor: executor);

  static Future<MigrationUser?> readOne(Object id,
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

  static Future<Result<MigrationUser>> readAll(
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

  static Future<ResultWithCount<MigrationUser>> readAllWithCount(
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
  static Stream<MigrationUser?> watchOne(Object id,
          {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<MigrationUser>> watchAll(
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
