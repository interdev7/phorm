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


CREATE TRIGGER update_migration_users_timestamp
AFTER UPDATE ON migration_users
FOR EACH ROW
BEGIN
    UPDATE migration_users SET updated_at = datetime('now') WHERE id = OLD.id;
END;
""";

class _$SQFlowMigrationUserTable extends Table<MigrationUser> {
  _$SQFlowMigrationUserTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.timestamps = true,
  }) : super(type: MigrationUser, paranoid: Table.detectSoftDelete(schema));
}

/// MigrationUser table schema
final migration_usersTable = _$SQFlowMigrationUserTable(
  schema: _$SQFlowMigrationUserSchema,
  name: 'migration_users',
  fromJson: _$SQFlowMigrationUserFromJson,
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
  timestamps: true,
);

mixin _$SQFlowMigrationUserMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
}

extension SQFlowMigrationUserSqlExt on MigrationUser {
  Map<String, dynamic> _$SQFlowMigrationUserToJson() {
    final migrationuserJson = {
      'id': _$SQFlowToJsonValue(id),
      'name': _$SQFlowToJsonValue(name),
      'email': _$SQFlowToJsonValue(email),
      'age': _$SQFlowToJsonValue(age),
      'is_active': _$SQFlowToJsonValue(isActive),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
    };
    _$validateMigrationUser(migrationuserJson, tableName: 'migration_users');

    return migrationuserJson;
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

void _$validateMigrationUser(Map<String, dynamic> json,
    {required String tableName}) {}

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

class MigrationUserTable {
  static const SqflowColumn<String> id = SqflowColumn<String>('id');
  static const SqflowColumn<String> name = SqflowColumn<String>('name');
  static const SqflowColumn<String> email = SqflowColumn<String>('email');
  static const SqflowColumn<int> age = SqflowColumn<int>('age');
  static const SqflowColumn<bool> isActive = SqflowColumn<bool>('is_active');
  static const SqflowColumn<DateTime> createdAt =
      SqflowColumn<DateTime>('created_at');
  static const SqflowColumn<DateTime> updatedAt =
      SqflowColumn<DateTime>('updated_at');
}

dynamic _$SQFlowToJsonValue(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  if (value is bool) return value ? 1 : 0;
  return value;
}
