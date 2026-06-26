import '../schema_generator.dart';

/// SQLite DDL generation rules. This is the reference (fully implemented)
/// dialect and reproduces the generator's historical behaviour exactly.
class SqliteSchemaGenerator extends SchemaGenerator {
  const SqliteSchemaGenerator();

  @override
  String get name => 'sqlite';

  @override
  String mapCoreType(String? typeName, {required bool isEnum}) {
    if (isEnum) return 'TEXT';
    switch (typeName) {
      case 'int':
        return 'INTEGER';
      case 'double':
        return 'REAL';
      case 'bool':
        return 'INTEGER';
      case 'String':
        return 'TEXT';
      case 'num':
        return 'NUMERIC';
      case 'DateTime':
        return 'TEXT';
      case 'Uint8List':
        return 'BLOB';
      case 'Duration':
        return 'INTEGER';
      case 'BigInt':
        return 'TEXT';
      case 'Uri':
        return 'TEXT';
      default:
        return 'TEXT';
    }
  }

  @override
  String timestampColumnType() => 'TEXT';

  @override
  String autoIncrementClause() => ' AUTOINCREMENT';

  @override
  bool isAutoPkInline(String sqlType) => sqlType == 'INTEGER';

  @override
  String formatBoolDefault(bool value) => value ? '1' : '0';

  @override
  String? updatedAtTimestampDdl(String tableName) {
    return '''

CREATE TRIGGER update_${tableName}_timestamp
AFTER UPDATE ON $tableName
FOR EACH ROW
BEGIN
    UPDATE $tableName SET updated_at = datetime('now') WHERE id = OLD.id;
END;''';
  }

  @override
  String quoteIdentifier(String name) => name;
}
