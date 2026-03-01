/// Schema builder
String stringSchemaBuilder({
  required List<String> columns,
  required List<String> foreignKeys,
  required String className,
  required String tableName,
  required String fileName,
  String? indexSql,
}) {
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
  }):super(paranoid: _detectSoftDelete(schema));
}


bool _detectSoftDelete(String schema) {
  final normalized = schema.toLowerCase();
  return normalized.contains('deleted_at') && normalized.contains('create table');
}

/// $className table schema
final _\$${tableName}Table = _${className}Table(
  schema: _schema,
  name: '$tableName',
  fromJson: $className.fromJson,
);
''';
}
