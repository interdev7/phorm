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
  created_at TEXT,
  updated_at TEXT
);


""";

class _$SQFlowMigrationPostTable extends Table<MigrationPost> {
  _$SQFlowMigrationPostTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
  }) : super(type: MigrationPost, paranoid: Table.detectSoftDelete(schema));
}

/// MigrationPost table schema
final migration_postsTable = _$SQFlowMigrationPostTable(
  schema: _$SQFlowMigrationPostSchema,
  name: 'migration_posts',
  fromJson: MigrationPost.fromJson,
  relationships: [],
);

mixin _$SQFlowMigrationPostMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
}

extension _$SQFlowMigrationPostSqlExt on MigrationPost {
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
}

MigrationPost _$SQFlowMigrationPostFromJson(Map<String, dynamic> json) {
  final instance = MigrationPost(
    id: json['id'] as String,
    title: json['title'] as String,
    content: json['content'] as String,
    userId: json['user_id'] as String,
  );
  instance.createdAt = json['created_at'] != null
      ? DateTime.parse(json['created_at'] as String)
      : null;
  instance.updatedAt = json['updated_at'] != null
      ? DateTime.parse(json['updated_at'] as String)
      : null;
  return instance;
}

dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}
