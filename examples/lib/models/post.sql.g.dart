// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// SqliteSchemaGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// SQL schema for table: posts

part of 'post.dart';

const _schema = """
CREATE TABLE posts (
  id TEXT PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  user_id TEXT NOT NULL
);


""";

class _PostTable extends Table<Post> {
  _PostTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
  }) : super(paranoid: _detectSoftDelete(schema));
}

bool _detectSoftDelete(String schema) {
  final normalized = schema.toLowerCase();
  return normalized.contains('deleted_at') &&
      normalized.contains('create table');
}

/// Post table schema
final postsTable = _PostTable(
  schema: _schema,
  name: 'posts',
  fromJson: Post.fromJson,
  relationships: const [
    Join(model: 'users', foreignKey: 'user_id', localKey: 'id')
  ],
);
