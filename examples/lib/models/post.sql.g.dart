// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'post.dart';

const _$SQFlowPostSchema = """
CREATE TABLE posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  user_id TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);


""";

class _$SQFlowPostTable extends Table<Post> {
  _$SQFlowPostTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
  }) : super(type: Post, paranoid: Table.detectSoftDelete(schema));
}

/// Post table schema
final postsTable = _$SQFlowPostTable(
  schema: _$SQFlowPostSchema,
  name: 'posts',
  fromJson: Post.fromJson,
  relationships: const [Join(model: 'users', foreignKey: 'user_id')],
);

mixin _$SQFlowPostMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
}

extension SQFlowPostSqlExt on Post {
  Map<String, dynamic> _$SQFlowPostToJson() {
    return {
      'id': _$SQFlowToJsonValue(id),
      'title': _$SQFlowToJsonValue(title),
      'content': _$SQFlowToJsonValue(content),
      'user_id': _$SQFlowToJsonValue(userId),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
    };
  }

  Post copyWith({
    int? id,
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

Post _$SQFlowPostFromJson(Map<String, dynamic> json) {
  final instance = Post(
    id: json['id'] as int,
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

dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}
