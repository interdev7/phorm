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
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);


""";

class _$SQFlowMigrationUserTable extends Table<MigrationUser> {
  _$SQFlowMigrationUserTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
  }) : super(type: MigrationUser, paranoid: Table.detectSoftDelete(schema));
}

/// MigrationUser table schema
final migration_usersTable = _$SQFlowMigrationUserTable(
  schema: _$SQFlowMigrationUserSchema,
  name: 'migration_users',
  fromJson: MigrationUser.fromJson,
  relationships: [],
  columns: const [
    'id',
    'name',
    'email',
    'age',
    'is_active',
    'created_at',
    'updated_at'
  ],
);

mixin _$SQFlowMigrationUserMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
}

extension SQFlowMigrationUserSqlExt on MigrationUser {
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

  MigrationUser copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MigrationUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      isActive: isActive ?? this.isActive,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
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
