// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'user.dart';

const _$UserSchema = """
CREATE TABLE users (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL,
  birth_date TEXT,
  age INTEGER,
  gender TEXT NOT NULL CHECK(gender IN ('M', 'F', 'Other')),
  city TEXT NOT NULL,
  country TEXT NOT NULL,
  address TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  is_verified INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  deleted_at TEXT
);

CREATE UNIQUE INDEX users_email_idx ON users(email);
CREATE INDEX users_firstName_lastName_idx ON users(firstName, lastName);
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
    HasMany(model: 'posts', foreignKey: 'user_id', localKey: 'id')
  ],
);

mixin _$UserMixin {}

extension _$UserSqlExt on User {
  Map<String, dynamic> _$UserToJson() {
    return {
      'id': _$toJsonValue(id),
      'first_name': _$toJsonValue(firstName),
      'last_name': _$toJsonValue(lastName),
      'email': _$toJsonValue(email),
      'phone': _$toJsonValue(phone),
      'birth_date': _$toJsonValue(birthDate),
      'age': _$toJsonValue(age),
      'gender': _$toJsonValue(gender),
      'city': _$toJsonValue(city),
      'country': _$toJsonValue(country),
      'address': _$toJsonValue(address),
      'is_active': _$toJsonValue(isActive),
      'is_verified': _$toJsonValue(isVerified),
      'created_at': _$toJsonValue(createdAt),
      'updated_at': _$toJsonValue(updatedAt),
      'deleted_at': _$toJsonValue(deletedAt),
    };
  }
}

User _$UserFromJson(Map<String, dynamic> json) {
  final instance = User(
    id: json['id'] as String,
    firstName: json['first_name'] as String,
    lastName: json['last_name'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
    gender: json['gender'] as String,
    city: json['city'] as String,
    country: json['country'] as String,
    address: json['address'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    birthDate: json['birth_date'] as String?,
    age: json['age'] as int?,
    isActive: (json['is_active'] as int?) == 1,
    isVerified: (json['is_verified'] as int?) == 1,
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,
    deletedAt: json['deleted_at'] != null
        ? DateTime.parse(json['deleted_at'] as String)
        : null,
    posts: json['posts'] != null
        ? (json['posts'] as List)
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList()
        : [],
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
