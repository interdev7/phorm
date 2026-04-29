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

  final schemaVarName = '_\$${className}Schema';
  final tableClassName = '_\$${className}Table';
  final tableVarName = '${tableName}Table';

  return '''
const $schemaVarName = """
CREATE TABLE $tableName (
${[
    ...columns,
    ...foreignKeys,
  ].join(',\n')}
);
${indexSql != null ? '\n$indexSql' : ''}
""";

class $tableClassName extends Table<$className> {
  $tableClassName({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
  }):super(type: $className, paranoid: _detectSoftDelete(schema));
}

/// $className table schema
final $tableVarName = $tableClassName(
  schema: $schemaVarName,
  name: '$tableName',
  fromJson: $className.fromJson,
  relationships: ${relationshipsCode.isNotEmpty ? "const " : ""} [$relationshipsCode],
);
''';
}
