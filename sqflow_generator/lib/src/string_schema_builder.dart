/// Schema builder
String stringSchemaBuilder({
  required List<String> columns,
  required List<String> foreignKeys,
  required String className,
  required String tableName,
  required String fileName,
  String? indexSql,
  List<Map<String, dynamic>> hasMany = const [],
  List<Map<String, dynamic>> hasOne = const [],
  List<Map<String, dynamic>> belongsTo = const [],
}) {
  final hasManyCode = hasMany
      .map((r) =>
          "HasMany(model: '${r['model']}', foreignKey: '${r['foreignKey']}', localKey: '${r['localKey']}')")
      .join(', ');
  final hasOneCode = hasOne
      .map((r) =>
          "HasOne(model: '${r['model']}', foreignKey: '${r['foreignKey']}', localKey: '${r['localKey']}')")
      .join(', ');
  final belongsToCode = belongsTo
      .map((r) =>
          "BelongsTo(model: '${r['model']}', foreignKey: '${r['foreignKey']}', localKey: '${r['localKey']}')")
      .join(', ');

  return '''
// GENERATED CODE - DO NOT MODIFY BY HAND
// SQL schema for table: $tableName

part of '$fileName';

const _schema = """
CREATE TABLE $tableName (
${[
    ...columns,
    ...foreignKeys,
  ].join(',\n')}
);
${indexSql != null ? '\n$indexSql' : ''}
""";

class _${className}Table extends Table<$className> {
  _${className}Table({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.hasMany = const [],
    super.hasOne = const [],
    super.belongsTo = const [],
  }):super(paranoid: _detectSoftDelete(schema));
}


bool _detectSoftDelete(String schema) {
  final normalized = schema.toLowerCase();
  return normalized.contains('deleted_at') && normalized.contains('create table');
}

/// $className table schema
final ${tableName}Table = _${className}Table(
  schema: _schema,
  name: '$tableName',
  fromJson: $className.fromJson,
  hasMany: const [$hasManyCode],
  hasOne: const [$hasOneCode],
  belongsTo: const [$belongsToCode],
);
''';
}
