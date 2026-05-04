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
    super.timestamps = true,
  }) : super(type: MigrationPost, paranoid: Table.detectSoftDelete(schema));
}

/// MigrationPost table schema
final migration_postsTable = _$SQFlowMigrationPostTable(
  schema: _$SQFlowMigrationPostSchema,
  name: 'migration_posts',
  fromJson: MigrationPost.fromJson,
  relationships: [],
  columns: const [
    'id',
    'title',
    'content',
    'user_id',
    'created_at',
    'updated_at'
  ],
  timestamps: true,
);

mixin _$SQFlowMigrationPostMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
}

extension SQFlowMigrationPostSqlExt on MigrationPost {
  Map<String, dynamic> _$SQFlowMigrationPostToJson() {
    return {
      'id': _$SQFlowToJsonValue(id),
      'title': _$SQFlowToJsonValue(title),
      'content': _$SQFlowToJsonValue(content),
      'user_id': _$SQFlowToJsonValue(userId),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
    };
  }

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

class MigrationPostTable {
  static const SqflowColumn<String> id = SqflowColumn<String>('id');
  static const SqflowColumn<String> title = SqflowColumn<String>('title');
  static const SqflowColumn<String> content = SqflowColumn<String>('content');
  static const SqflowColumn<String> userId = SqflowColumn<String>('user_id');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at');
}

dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}
