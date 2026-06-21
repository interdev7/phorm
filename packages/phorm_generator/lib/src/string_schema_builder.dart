/// Schema builder
String stringSchemaBuilder({
  required List<String> columns,
  required List<String> foreignKeys,
  required String className,
  required String tableName,
  required String fileName,
  required List<String> columnNames,
  String? indexSql,
  List<Map<String, dynamic>> relationships = const [],
  bool timestamps = true,
  bool useFromJson = true,
  String primaryKey = 'id',
  bool isGeneric = false,
}) {
  final relationshipsCode = relationships
      .map((r) {
        final lk = r['localKey'];
        final lkCode = lk == 'id' ? '' : ", localKey: '$lk'";
        return "${r['type']}(model: '${r['model']}', foreignKey: '${r['foreignKey']}'$lkCode)";
      })
      .join(', ');

  final schemaVarName = '_\$Phorm${className}Schema';
  final tableClassName = '_\$Phorm${className}Table';
  final tableVarName = '${tableName}Table';

  final fromJsonValue =
      isGeneric
          ? '(json) => _\$Phorm${className}FromJson(json, (x) => x)'
          : (useFromJson
              ? '_\$Phorm${className}FromJson'
              : '$className.fromJson');

  return '''
const $schemaVarName = """
CREATE TABLE $tableName (
${[...columns, ...foreignKeys].join(',\n')}
);
${indexSql != null ? '\n$indexSql' : ''}
""";

class $tableClassName extends Table<$className${isGeneric ? '<dynamic>' : ''}> {
  $tableClassName({
    required super.schema,
    required super.name,
    required super.fromJson,
    super.relationships = const [],
    super.columns = const [],
    super.primaryKey = '$primaryKey',
    super.timestamps = true,
  }) : super(type: $className, paranoid: Table.detectSoftDelete(schema));
}

/// $className table schema
final $tableVarName = $tableClassName(
  schema: $schemaVarName,
  name: '$tableName',
  fromJson: $fromJsonValue,
  relationships: ${relationshipsCode.isNotEmpty ? "const " : ""} [$relationshipsCode],
  columns: const [${columnNames.map((c) => "'$c'").join(', ')}],
  primaryKey: '$primaryKey',
  timestamps: $timestamps,
);
''';
}
