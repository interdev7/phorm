// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'complex_relationships_test.dart';

const _$UserSchema = """
CREATE TABLE users (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  name TEXT NOT NULL
);


""";

class _$UserTable extends Table<User> {
  _$UserTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
  }) : super(type: User, paranoid: _detectSoftDelete(schema));
}

/// User table schema
final usersTable = _$UserTable(
  schema: _$UserSchema,
  name: 'users',
  fromJson: User.fromJson,
  relationships: const [
    HasMany(model: 'posts', foreignKey: 'user_id', localKey: 'id'),
    HasOne(model: 'profiles', foreignKey: 'user_id', localKey: 'id')
  ],
);

mixin _$UserMixin {
  final List<Post> _$posts = [];
  List<Post> get posts => _$posts;
  Profile? _$profile;
  Profile? get profile => _$profile;
}

extension _$UserSqlExt on User {
  Map<String, dynamic> _$UserToJson() {
    return {
      'id': _$toJsonValue(id),
      'name': _$toJsonValue(name),
    };
  }
}

User _$UserFromJson(Map<String, dynamic> json) {
  final instance = User(
    id: json['id'] as String,
    name: json['name'] as String,
  );
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

const _$PostSchema = """
CREATE TABLE posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  user_id TEXT
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
    BelongsTo(model: 'users', foreignKey: 'user_id', localKey: 'id')
  ],
);

mixin _$PostMixin {
  User? _$user;
  User? get user => _$user;
  var _$userId;
  dynamic get userId => user?.id ?? _$userId;
  set userId(dynamic value) => _$userId = value;
}

extension _$PostSqlExt on Post {
  Map<String, dynamic> _$PostToJson() {
    return {
      'id': _$toJsonValue(id),
      'title': _$toJsonValue(title),
      'user_id': _$toJsonValue(userId),
    };
  }
}

Post _$PostFromJson(Map<String, dynamic> json) {
  final instance = Post(
    id: json['id'] as int,
    title: json['title'] as String,
  );
  instance._$user = json['users'] != null
      ? User.fromJson(json['users'] as Map<String, dynamic>)
      : null;
  instance.userId = json['user_id'];
  return instance;
}

const _$ProfileSchema = """
CREATE TABLE profiles (
  id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL UNIQUE,
  bio TEXT NOT NULL,
  user_id TEXT
);


""";

class _$ProfileTable extends Table<Profile> {
  _$ProfileTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
  }) : super(type: Profile, paranoid: _detectSoftDelete(schema));
}

/// Profile table schema
final profilesTable = _$ProfileTable(
  schema: _$ProfileSchema,
  name: 'profiles',
  fromJson: Profile.fromJson,
  relationships: const [
    BelongsTo(model: 'users', foreignKey: 'user_id', localKey: 'id')
  ],
);

mixin _$ProfileMixin {
  User? _$user;
  User? get user => _$user;
  var _$userId;
  dynamic get userId => user?.id ?? _$userId;
  set userId(dynamic value) => _$userId = value;
}

extension _$ProfileSqlExt on Profile {
  Map<String, dynamic> _$ProfileToJson() {
    return {
      'id': _$toJsonValue(id),
      'bio': _$toJsonValue(bio),
      'user_id': _$toJsonValue(userId),
    };
  }
}

Profile _$ProfileFromJson(Map<String, dynamic> json) {
  final instance = Profile(
    id: json['id'] as int,
    bio: json['bio'] as String,
  );
  instance._$user = json['users'] != null
      ? User.fromJson(json['users'] as Map<String, dynamic>)
      : null;
  instance.userId = json['user_id'];
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
