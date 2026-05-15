// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'post.dart';

const _$SQFlowPostSchema = """
CREATE TABLE posts (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY(user_id) REFERENCES users(id)
);


CREATE TRIGGER update_posts_timestamp
AFTER UPDATE ON posts
FOR EACH ROW
BEGIN
    UPDATE posts SET updated_at = datetime('now') WHERE id = OLD.id;
END;
""";

class _$SQFlowPostTable extends Table<Post> {
  _$SQFlowPostTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = 'id',
    super.timestamps = true,
  }) : super(type: Post, paranoid: Table.detectSoftDelete(schema));
}

/// Post table schema
final postsTable = _$SQFlowPostTable(
  schema: _$SQFlowPostSchema,
  name: 'posts',
  fromJson: _$SQFlowPostFromJson,
  relationships: const [Join(model: 'users', foreignKey: 'user_id')],
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

mixin _$SQFlowPostMixin {
  Map<String, dynamic> toJson() => _$SQFlowPostToJson(this as Post);

  @override
  String toString() => _$SQFlowPostToString(this as Post);
  DateTime? createdAt;
  DateTime? updatedAt;
}

Map<String, dynamic> _$SQFlowPostToJson(Post instance) {
  final postJson = {
    'id': _$SQFlowToJsonValue(instance.id),
    'title': _$SQFlowToJsonValue(instance.title),
    'content': _$SQFlowToJsonValue(instance.content),
    'user_id': _$SQFlowToJsonValue(instance.userId),
    'user': _$SQFlowToJsonValue(instance.user),
    'created_at': _$SQFlowToJsonValue(instance.createdAt),
    'updated_at': _$SQFlowToJsonValue(instance.updatedAt),
  };
  _$validatePost(postJson, tableName: 'posts');

  return postJson;
}

String _$SQFlowPostToString(Post instance) {
  return """
Post(
  id: ${instance.id},
  title: ${instance.title},
  content: ${instance.content},
  userId: ${instance.userId},
  user: ${instance.user},
  createdAt: ${instance.createdAt},
  updatedAt: ${instance.updatedAt},
)""";
}

extension SQFlowPostExt on Post {
  Post copyWith({
    String? id,
    String? title,
    String? content,
    String? userId,
    User? user,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Post(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      userId: userId ?? this.userId,
      user: user ?? this.user,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }
}

void _$validatePost(Map<String, dynamic> json, {required String tableName}) {}

Post _$SQFlowPostFromJson(Map<String, dynamic> json) {
  final instance = Post(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    userId: json['user_id'] as String,
    user: json['users'] != null
        ? User.fromJson(json['users'] as Map<String, dynamic>)
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

/// Pluralized service for Post
class Posts {
  static const SqflowColumn<String> id = SqflowColumn<String>('id');
  static const SqflowColumn<String> title = SqflowColumn<String>('title');
  static const SqflowColumn<String> content = SqflowColumn<String>('content');
  static const SqflowColumn<String> userId = SqflowColumn<String>('user_id');
  static const SqflowColumn<User> user = SqflowColumn<User>('user');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at');

  static SqflowCore<Post> get _service =>
      SqflowCore<Post>(dbManager: appDb, table: postsTable);

  static SqflowQuery<Post> where(SqflowCondition condition) =>
      _service.where(condition);
  static SqflowQuery<Post> get query => _service.query;

  static Future<int> insert(Post item, {DatabaseExecutor? executor}) =>
      _service.insert(item, executor: executor);
  static Future<int> update(Post item, {DatabaseExecutor? executor}) =>
      _service.update(item, executor: executor);
  static Future<void> upsert(Post item, {DatabaseExecutor? executor}) =>
      _service.upsert(item, executor: executor);
  static Future<int> delete(Object id,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.delete(id, force: force, executor: executor);
  static Future<int> restore(Object id, {DatabaseExecutor? executor}) =>
      _service.restore(id, executor: executor);

  static Future<int> insertBatch(List<Post> items,
          {DatabaseExecutor? executor}) =>
      _service.insertBatch(items, executor: executor);
  static Future<int> updateBatch(List<Post> items,
          {DatabaseExecutor? executor}) =>
      _service.updateBatch(items, executor: executor);
  static Future<int> upsertBatch(List<Post> items,
          {DatabaseExecutor? executor}) =>
      _service.upsertBatch(items, executor: executor);
  static Future<int> deleteBatch(List<Object> ids,
          {bool force = false, DatabaseExecutor? executor}) =>
      _service.deleteBatch(ids, force: force, executor: executor);

  static Future<bool> exists(Object id,
          {bool withDeleted = false, DatabaseExecutor? executor}) =>
      _service.exists(id, withDeleted: withDeleted, executor: executor);

  static Future<Post?> readOne(Object id,
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

  static Future<Result<Post>> readAll(
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

  static Future<ResultWithCount<Post>> readAllWithCount(
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
  static Stream<Post?> watchOne(Object id, {List<Includable>? include}) =>
      _service.watchOne(id, include: include);
  static Stream<List<Post>> watchAll(
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
