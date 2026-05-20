// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'enum_test_model.dart';

const _$SQFlowEnumPostSchema = """
CREATE TABLE enum_posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  status TEXT NOT NULL,
  optional_status TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);


CREATE TRIGGER update_enum_posts_timestamp
AFTER UPDATE ON enum_posts
FOR EACH ROW
BEGIN
    UPDATE enum_posts SET updated_at = datetime('now') WHERE id = OLD.id;
END;
""";

class _$SQFlowEnumPostTable extends Table<EnumPost> {
  _$SQFlowEnumPostTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = 'id',
    super.timestamps = true,
  }) : super(type: EnumPost, paranoid: Table.detectSoftDelete(schema));
}

/// EnumPost table schema
final enum_postsTable = _$SQFlowEnumPostTable(
  schema: _$SQFlowEnumPostSchema,
  name: 'enum_posts',
  fromJson: _$SQFlowEnumPostFromJson,
  relationships: [],
  columns: const [
    'id',
    'title',
    'status',
    'optional_status',
    'created_at',
    'updated_at'
  ],
  primaryKey: 'id',
  timestamps: true,
);

mixin _$SQFlowEnumPostMixin {
  Map<String, dynamic> toJson() => _$SQFlowEnumPostToJson(this as EnumPost);

  @override
  String toString() => _$SQFlowEnumPostToString(this as EnumPost);
  DateTime? createdAt;
  DateTime? updatedAt;
}

Map<String, dynamic> _$SQFlowEnumPostToJson(EnumPost instance) {
  final enumpostJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'title': _$SQFlowToJsonValue(instance.title),
    'status': _$SQFlowToJsonValue(instance.status.name),
    'optional_status': _$SQFlowToJsonValue(instance.optionalStatus?.name),
    'created_at': _$SQFlowToJsonValue(instance.createdAt),
    'updated_at': _$SQFlowToJsonValue(instance.updatedAt),
  };

  return enumpostJson;
}

String _$SQFlowEnumPostToString(EnumPost instance) {
  return """
EnumPost(
  id: ${instance.id},
  title: ${instance.title},
  status: ${instance.status},
  optionalStatus: ${instance.optionalStatus},
  createdAt: ${instance.createdAt},
  updatedAt: ${instance.updatedAt},
)""";
}

extension SQFlowEnumPostExt on EnumPost {
  EnumPost copyWith({
    int? id,
    String? title,
    PostStatus? status,
    PostStatus? optionalStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EnumPost(
      id: id ?? this.id,
      title: title ?? this.title,
      status: status ?? this.status,
      optionalStatus: optionalStatus ?? this.optionalStatus,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }
}

EnumPost _$SQFlowEnumPostFromJson(Map<String, dynamic> json) {
  final instance = EnumPost(
    id: json['id'] as int,
    title: json['title'] as String,
    status: PostStatus.values.byName(json['status'] as String),
    optionalStatus: json['optional_status'] != null
        ? PostStatus.values.byName(json['optional_status'] as String)
        : null,
  )
    ..createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null
    ..updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null;
  return instance;
}

/// Pluralized service for EnumPost
class EnumPosts {
  static const SqflowColumn<int> id =
      SqflowColumn<int>('id', tableName: 'enum_posts');
  static const SqflowColumn<String> title =
      SqflowColumn<String>('title', tableName: 'enum_posts');
  static const SqflowColumn<PostStatus> status =
      SqflowColumn<PostStatus>('status', tableName: 'enum_posts');
  static const SqflowColumn<PostStatus> optionalStatus =
      SqflowColumn<PostStatus>('optional_status', tableName: 'enum_posts');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at', tableName: 'enum_posts');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at', tableName: 'enum_posts');

  static SqflowCore<EnumPost> get _service =>
      SqflowCore<EnumPost>(dbManager: appDb, table: enum_postsTable);

  static SqflowQuery<EnumPost> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<EnumPost> get query => _service.query;

  static Future<int> insert(EnumPost item, {DatabaseExecutor? executor}) =>
      _service.insert(item, executor: executor);
  static Future<int> update(EnumPost item, {DatabaseExecutor? executor}) =>
      _service.update(item, executor: executor);
  static Future<void> upsert(EnumPost item, {DatabaseExecutor? executor}) =>
      _service.upsert(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.delete(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restore(id, executor: executor);

  static Future<int> insertBatch(List<EnumPost> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatch(items, executor: executor);
  static Future<int> updateBatch(List<EnumPost> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatch(items, executor: executor);
  static Future<int> upsertBatch(List<EnumPost> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatch(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatch(ids, force: force, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.exists(id, withDeleted: withDeleted, executor: executor);

  static Future<EnumPost?> readOne(Object id,
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

  static Future<Result<EnumPost>> readAll(
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

  static Future<ResultWithCount<EnumPost>> readAllWithCount(
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
  static Stream<EnumPost?> watchOne(Object id, {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<EnumPost>> watchAll(
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
