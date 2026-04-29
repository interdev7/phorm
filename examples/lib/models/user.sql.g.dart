// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// SqliteSchemaGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// SQL schema for table: users

part of 'user.dart';

const _schema = """
CREATE TABLE users (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  phone TEXT NOT NULL,
  birth_date TEXT,
  age TEXT,
  gender TEXT NOT NULL CHECK(gender IN ('M', 'F', 'Other')),
  city TEXT NOT NULL,
  country TEXT NOT NULL,
  address TEXT NOT NULL,
  is_active TEXT NOT NULL DEFAULT 1,
  is_verified TEXT NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT,
  deleted_at TEXT
);

CREATE UNIQUE INDEX users_email_idx ON users(email);
CREATE INDEX users_firstName_lastName_idx ON users(firstName, lastName);
""";

class _UserTable extends Table<User> {
  _UserTable({
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

/// User table schema
final usersTable = _UserTable(
  schema: _schema,
  name: 'users',
  fromJson: User.fromJson,
  relationships: const [
    HasMany(model: 'posts', foreignKey: 'user_id', localKey: 'id')
  ],
);
