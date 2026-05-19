// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'migration_post.dart';

const _$SQFlowMigrationPostSchema = """
CREATE TABLE migration_posts (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);


CREATE TRIGGER update_migration_posts_timestamp
AFTER UPDATE ON migration_posts
FOR EACH ROW
BEGIN
    UPDATE migration_posts SET updated_at = datetime('now') WHERE id = OLD.id;
END;
""";

class _$SQFlowMigrationPostTable extends Table<MigrationPost> {
  _$SQFlowMigrationPostTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = 'id',
    super.timestamps = true,
  }) : super(type: MigrationPost, paranoid: Table.detectSoftDelete(schema));
}

/// MigrationPost table schema
final migration_postsTable = _$SQFlowMigrationPostTable(
  schema: _$SQFlowMigrationPostSchema,
  name: 'migration_posts',
  fromJson: _$SQFlowMigrationPostFromJson,
  relationships: [],
  columns: const [
    'id',
    'title',
    'content',
    'user_id',
    'created_at',
    'updated_at'
  ],
  primaryKey: 'id',
  timestamps: true,
);

mixin _$SQFlowMigrationPostMixin {
  Map<String, dynamic> toJson() =>
      _$SQFlowMigrationPostToJson(this as MigrationPost);

  @override
  String toString() => _$SQFlowMigrationPostToString(this as MigrationPost);
  DateTime? createdAt;
  DateTime? updatedAt;
}

Map<String, dynamic> _$SQFlowMigrationPostToJson(MigrationPost instance) {
  final migrationpostJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'title': _$SQFlowToJsonValue(instance.title),
    'content': _$SQFlowToJsonValue(instance.content),
    'user_id': _$SQFlowToJsonValue(instance.userId),
    'created_at': _$SQFlowToJsonValue(instance.createdAt),
    'updated_at': _$SQFlowToJsonValue(instance.updatedAt),
  };
  _$validateMigrationPost(migrationpostJson, tableName: 'migration_posts');

  return migrationpostJson;
}

String _$SQFlowMigrationPostToString(MigrationPost instance) {
  return """
MigrationPost(
  id: ${instance.id},
  title: ${instance.title},
  content: ${instance.content},
  userId: ${instance.userId},
  createdAt: ${instance.createdAt},
  updatedAt: ${instance.updatedAt},
)""";
}

extension SQFlowMigrationPostExt on MigrationPost {
  MigrationPost copyWith({
    String? id,
    String? title,
    String? content,
    String? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MigrationPost(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      userId: userId ?? this.userId,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }
}

void _$validateMigrationPost(Map<String, dynamic> json,
    {required String tableName}) {}

MigrationPost _$SQFlowMigrationPostFromJson(Map<String, dynamic> json) {
  final instance = MigrationPost(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    userId: json['user_id'] as String,
  )
    ..createdAt = json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null
    ..updatedAt = json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null;
  return instance;
}

/// Pluralized service for MigrationPost
class MigrationPosts {
  static const SqflowColumn<String> id =
      SqflowColumn<String>('id', tableName: 'migration_posts');
  static const SqflowColumn<String> title =
      SqflowColumn<String>('title', tableName: 'migration_posts');
  static const SqflowColumn<String> content =
      SqflowColumn<String>('content', tableName: 'migration_posts');
  static const SqflowColumn<String> userId =
      SqflowColumn<String>('user_id', tableName: 'migration_posts');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at', tableName: 'migration_posts');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at', tableName: 'migration_posts');

  static SqflowCore<MigrationPost> get _service =>
      SqflowCore<MigrationPost>(dbManager: appDb, table: migration_postsTable);

  static SqflowQuery<MigrationPost> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<MigrationPost> get query => _service.query;

  static Future<int> insert(MigrationPost item, {DatabaseExecutor? executor}) =>
      _service.insert(item, executor: executor);
  static Future<int> update(MigrationPost item, {DatabaseExecutor? executor}) =>
      _service.update(item, executor: executor);
  static Future<void> upsert(MigrationPost item,
          {DatabaseExecutor? executor}) =>
      _service.upsert(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.delete(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restore(id, executor: executor);

  static Future<int> insertBatch(List<MigrationPost> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatch(items, executor: executor);
  static Future<int> updateBatch(List<MigrationPost> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatch(items, executor: executor);
  static Future<int> upsertBatch(List<MigrationPost> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatch(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatch(ids, force: force, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.exists(id, withDeleted: withDeleted, executor: executor);

  static Future<MigrationPost?> readOne(Object id,
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

  static Future<Result<MigrationPost>> readAll(
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

  static Future<ResultWithCount<MigrationPost>> readAllWithCount(
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
  static Stream<MigrationPost?> watchOne(Object id,
          {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<MigrationPost>> watchAll(
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
