/// Schema builder
String stringSchemaBuilder({
  required List<String> columns,
  required List<String> foreignKeys,
  required String className,
  required String tableName,
  required String fileName,
  String? indexSql,
  List<Map<String, dynamic>> relationships = const [],
}) {
  final relationshipsCode = relationships
      .map((r) =>
          "${r['type']}(model: '${r['model']}', foreignKey: '${r['foreignKey']}', localKey: '${r['localKey']}')")
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
    super.relationships = const [],
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
  relationships: const [$relationshipsCode],
);
''';
}
