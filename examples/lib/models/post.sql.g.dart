// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'post.dart';

const _$PostSchema = """
CREATE TABLE posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  user_id TEXT NOT NULL
);


""";

class _$PostTable extends Table<Post> {
  _$PostTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
  }) : super(type: Post, paranoid: _detectSoftDelete(schema));
}

/// Post table schema
final postsTable = _$PostTable(
  schema: _$PostSchema,
  name: 'posts',
  fromJson: Post.fromJson,
  relationships: const [
    Join(model: 'users', foreignKey: 'user_id', localKey: 'id')
  ],
);

mixin _$PostMixin {}

extension _$PostSqlExt on Post {
  Map<String, dynamic> _$PostToJson() {
    return {
      'id': _$toJsonValue(id),
      'title': _$toJsonValue(title),
      'content': _$toJsonValue(content),
      'user_id': _$toJsonValue(userId),
    };
  }
}

Post _$PostFromJson(Map<String, dynamic> json) {
  final instance = Post(
    id: json['id'] as int,
    title: json['title'] as String,
    content: json['content'] as String,
    userId: json['user_id'] as String,
    user: json['users'] != null
        ? User.fromJson(json['users'] as Map<String, dynamic>)
        : null,
  );
  return instance;
}

dynamic _$toJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}

bool _detectSoftDelete(String schema) {
  final normalized = schema.toLowerCase();
  return normalized.contains('deleted_at') &&
      normalized.contains('create table');
}
