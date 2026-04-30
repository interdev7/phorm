// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'complex_relationships_test.dart';

const _$SQFlowUserSchema = """
CREATE TABLE users (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  name TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT
);


""";

class _$SQFlowUserTable extends Table<User> {
  _$SQFlowUserTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
  }) : super(type: User, paranoid: Table.detectSoftDelete(schema));
}

/// User table schema
final usersTable = _$SQFlowUserTable(
  schema: _$SQFlowUserSchema,
  name: 'users',
  fromJson: User.fromJson,
  relationships: const [
    HasMany(model: 'posts', foreignKey: 'user_id', localKey: 'id'),
    HasOne(model: 'profiles', foreignKey: 'user_id', localKey: 'id')
  ],
);

mixin _$SQFlowUserMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
  final List<Post> _$posts = [];
  List<Post> get posts => _$posts;
  Profile? _$profile;
  Profile? get profile => _$profile;
}

extension _$SQFlowUserSqlExt on User {
  Map<String, dynamic> _$SQFlowUserToJson() {
    return {
      'id': _$SQFlowToJsonValue(id),
      'name': _$SQFlowToJsonValue(name),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
    };
  }
}

User _$SQFlowUserFromJson(Map<String, dynamic> json) {
  final instance = User(
    id: json['id'] as String,
    name: json['name'] as String,
  );
  instance.createdAt = json['created_at'] != null
      ? DateTime.parse(json['created_at'] as String)
      : null;
  instance.updatedAt = json['updated_at'] != null
      ? DateTime.parse(json['updated_at'] as String)
      : null;
  if (json['posts'] != null) {
    instance.posts.addAll((json['posts'] as List)
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList());
  }
  instance._$profile = json['profiles'] != null
      ? Profile.fromJson(json['profiles'] as Map<String, dynamic>)
      : null;
  return instance;
}

const _$SQFlowPostSchema = """
CREATE TABLE posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT,
  user_id TEXT
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
  relationships: const [
    BelongsTo(model: 'users', foreignKey: 'user_id', localKey: 'id')
  ],
);

mixin _$SQFlowPostMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
  User? _$user;
  User? get user => _$user;
  var _$userId;
  dynamic get userId => user?.id ?? _$userId;
  set userId(dynamic value) => _$userId = value;
}

extension _$SQFlowPostSqlExt on Post {
  Map<String, dynamic> _$SQFlowPostToJson() {
    return {
      'id': _$SQFlowToJsonValue(id),
      'title': _$SQFlowToJsonValue(title),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
      'user_id': _$SQFlowToJsonValue(userId),
    };
  }
}

Post _$SQFlowPostFromJson(Map<String, dynamic> json) {
  final instance = Post(
    id: json['id'] as int,
    title: json['title'] as String,
  );
  instance.createdAt = json['created_at'] != null
      ? DateTime.parse(json['created_at'] as String)
      : null;
  instance.updatedAt = json['updated_at'] != null
      ? DateTime.parse(json['updated_at'] as String)
      : null;
  instance._$user = json['users'] != null
      ? User.fromJson(json['users'] as Map<String, dynamic>)
      : null;
  instance.userId = json['user_id'];
  return instance;
}

const _$SQFlowProfileSchema = """
CREATE TABLE profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  bio TEXT NOT NULL,
  created_at TEXT,
  updated_at TEXT,
  user_id TEXT
);


""";

class _$SQFlowProfileTable extends Table<Profile> {
  _$SQFlowProfileTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
  }) : super(type: Profile, paranoid: Table.detectSoftDelete(schema));
}

/// Profile table schema
final profilesTable = _$SQFlowProfileTable(
  schema: _$SQFlowProfileSchema,
  name: 'profiles',
  fromJson: Profile.fromJson,
  relationships: const [
    BelongsTo(model: 'users', foreignKey: 'user_id', localKey: 'id')
  ],
);

mixin _$SQFlowProfileMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
  User? _$user;
  User? get user => _$user;
  var _$userId;
  dynamic get userId => user?.id ?? _$userId;
  set userId(dynamic value) => _$userId = value;
}

extension _$SQFlowProfileSqlExt on Profile {
  Map<String, dynamic> _$SQFlowProfileToJson() {
    return {
      'id': _$SQFlowToJsonValue(id),
      'bio': _$SQFlowToJsonValue(bio),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
      'user_id': _$SQFlowToJsonValue(userId),
    };
  }
}

Profile _$SQFlowProfileFromJson(Map<String, dynamic> json) {
  final instance = Profile(
    id: json['id'] as int,
    bio: json['bio'] as String,
  );
  instance.createdAt = json['created_at'] != null
      ? DateTime.parse(json['created_at'] as String)
      : null;
  instance.updatedAt = json['updated_at'] != null
      ? DateTime.parse(json['updated_at'] as String)
      : null;
  instance._$user = json['users'] != null
      ? User.fromJson(json['users'] as Map<String, dynamic>)
      : null;
  instance.userId = json['user_id'];
  return instance;
}

dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}
