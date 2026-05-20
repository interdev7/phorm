// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'nested_object_test_model.dart';

const _$SQFlowUserWithLocationSchema = """
CREATE TABLE users_with_location (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL
);


""";

class _$SQFlowUserWithLocationTable extends Table<UserWithLocation> {
  _$SQFlowUserWithLocationTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = 'id',
    super.timestamps = true,
  }) : super(type: UserWithLocation, paranoid: Table.detectSoftDelete(schema));
}

/// UserWithLocation table schema
final users_with_locationTable = _$SQFlowUserWithLocationTable(
  schema: _$SQFlowUserWithLocationSchema,
  name: 'users_with_location',
  fromJson: _$SQFlowUserWithLocationFromJson,
  relationships: [],
  columns: const ['id', 'name'],
  primaryKey: 'id',
  timestamps: false,
);

mixin _$SQFlowUserWithLocationMixin {
  Map<String, dynamic> toJson() =>
      _$SQFlowUserWithLocationToJson(this as UserWithLocation);

  @override
  String toString() =>
      _$SQFlowUserWithLocationToString(this as UserWithLocation);
}

Map<String, dynamic> _$SQFlowUserWithLocationToJson(UserWithLocation instance) {
  final userwithlocationJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'name': _$SQFlowToJsonValue(instance.name),
    'location': _$SQFlowToJsonValue(instance.location?.toJson()),
    'age': _$SQFlowToJsonValue(instance.age),
  };
  _$validateUserWithLocation(userwithlocationJson,
      tableName: 'users_with_location');

  return userwithlocationJson;
}

String _$SQFlowUserWithLocationToString(UserWithLocation instance) {
  return """
UserWithLocation(
  id: ${instance.id},
  name: ${instance.name},
  location: ${instance.location},
  age: ${instance.age},
)""";
}

extension SQFlowUserWithLocationExt on UserWithLocation {
  UserWithLocation copyWith({
    int? id,
    String? name,
    Location? location,
    int? age,
  }) {
    return UserWithLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      age: age ?? this.age,
    );
  }
}

void _$validateUserWithLocation(Map<String, dynamic> json,
    {required String tableName}) {}

UserWithLocation _$SQFlowUserWithLocationFromJson(Map<String, dynamic> json) {
  final instance = UserWithLocation(
    id: json['id'] as int,
    name: json['name'] as String,
    location: json['location'] != null
        ? Location.fromJson(json['location'] as Map<String, dynamic>)
        : null,
    age: json['age'] as int?,
  );
  return instance;
}

/// Pluralized service for UserWithLocation
class UsersWithLocation {
  static const SqflowColumn<int> id =
      SqflowColumn<int>('id', tableName: 'users_with_location');
  static const SqflowColumn<String> name =
      SqflowColumn<String>('name', tableName: 'users_with_location');

  static SqflowCore<UserWithLocation> get _service =>
      SqflowCore<UserWithLocation>(
          dbManager: appDb, table: users_with_locationTable);

  static SqflowQuery<UserWithLocation> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<UserWithLocation> get query => _service.query;

  static Future<int> insert(UserWithLocation item,
          {DatabaseExecutor? executor}) =>
      _service.insert(item, executor: executor);
  static Future<int> update(UserWithLocation item,
          {DatabaseExecutor? executor}) =>
      _service.update(item, executor: executor);
  static Future<void> upsert(UserWithLocation item,
          {DatabaseExecutor? executor}) =>
      _service.upsert(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.delete(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restore(id, executor: executor);

  static Future<int> insertBatch(List<UserWithLocation> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatch(items, executor: executor);
  static Future<int> updateBatch(List<UserWithLocation> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatch(items, executor: executor);
  static Future<int> upsertBatch(List<UserWithLocation> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatch(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatch(ids, force: force, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.exists(id, withDeleted: withDeleted, executor: executor);

  static Future<UserWithLocation?> readOne(Object id,
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

  static Future<Result<UserWithLocation>> readAll(
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

  static Future<ResultWithCount<UserWithLocation>> readAllWithCount(
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
  static Stream<UserWithLocation?> watchOne(Object id,
          {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<UserWithLocation>> watchAll(
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
