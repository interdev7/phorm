// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'migration_user.dart';

const _$SQFlowMigrationUserSchema = """
CREATE TABLE migration_users (
  id TEXT PRIMARY KEY NOT NULL UNIQUE,
  name TEXT NOT NULL,
  email TEXT,
  age INTEGER,
  is_active INTEGER NOT NULL DEFAULT 1,
  created_at TEXT,
  updated_at TEXT
);


""";

class _$SQFlowMigrationUserTable extends Table<MigrationUser> {
  _$SQFlowMigrationUserTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
  }) : super(type: MigrationUser, paranoid: Table.detectSoftDelete(schema));
}

/// MigrationUser table schema
final migration_usersTable = _$SQFlowMigrationUserTable(
  schema: _$SQFlowMigrationUserSchema,
  name: 'migration_users',
  fromJson: MigrationUser.fromJson,
  relationships: [],
);

mixin _$SQFlowMigrationUserMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
}

extension _$SQFlowMigrationUserSqlExt on MigrationUser {
  Map<String, dynamic> _$SQFlowMigrationUserToJson() {
    return {
      'id': _$SQFlowToJsonValue(id),
      'name': _$SQFlowToJsonValue(name),
      'email': _$SQFlowToJsonValue(email),
      'age': _$SQFlowToJsonValue(age),
      'is_active': _$SQFlowToJsonValue(isActive),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
    };
  }
}

MigrationUser _$SQFlowMigrationUserFromJson(Map<String, dynamic> json) {
  final instance = MigrationUser(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String?,
    age: json['age'] as int?,
    isActive: json['is_active'] is bool
        ? json['is_active'] as bool
        : (json['is_active'] as int?) == 1,
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
