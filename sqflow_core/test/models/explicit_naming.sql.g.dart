// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// _SqflowCombinedGenerator
// **************************************************************************

part of 'explicit_naming.dart';

const _$SQFlowExplicitNamingSchema = """
CREATE TABLE explicit_table (
  custom_id TEXT PRIMARY KEY NOT NULL UNIQUE,
  custom_name TEXT NOT NULL,
  custom_age INTEGER NOT NULL,
  is_verified INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);


""";

class _$SQFlowExplicitNamingTable extends Table<ExplicitNaming> {
  _$SQFlowExplicitNamingTable({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
  }) : super(type: ExplicitNaming, paranoid: Table.detectSoftDelete(schema));
}

/// ExplicitNaming table schema
final explicit_tableTable = _$SQFlowExplicitNamingTable(
  schema: _$SQFlowExplicitNamingSchema,
  name: 'explicit_table',
  fromJson: ExplicitNaming.fromJson,
  relationships: [],
  columns: const [
    'custom_id',
    'custom_name',
    'custom_age',
    'is_verified',
    'created_at',
    'updated_at'
  ],
);

mixin _$SQFlowExplicitNamingMixin {
  DateTime? createdAt;
  DateTime? updatedAt;
}

extension SQFlowExplicitNamingSqlExt on ExplicitNaming {
  Map<String, dynamic> _$SQFlowExplicitNamingToJson() {
    return {
      'custom_id': _$SQFlowToJsonValue(id),
      'custom_name': _$SQFlowToJsonValue(name),
      'custom_age': _$SQFlowToJsonValue(age),
      'is_verified': _$SQFlowToJsonValue(isVerified),
      'created_at': _$SQFlowToJsonValue(createdAt),
      'updated_at': _$SQFlowToJsonValue(updatedAt),
    };
  }

  ExplicitNaming copyWith({
    String? id,
    String? name,
    int? age,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExplicitNaming(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      isVerified: isVerified ?? this.isVerified,
    )
      ..createdAt = createdAt ?? this.createdAt
      ..updatedAt = updatedAt ?? this.updatedAt;
  }
}

ExplicitNaming _$SQFlowExplicitNamingFromJson(Map<String, dynamic> json) {
  final instance = ExplicitNaming(
    id: json['custom_id'] as String,
    name: json['custom_name'] as String,
    age: json['custom_age'] as int,
    isVerified: json['is_verified'] is bool
        ? json['is_verified'] as bool
        : (json['is_verified'] as int?) == 1,
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
