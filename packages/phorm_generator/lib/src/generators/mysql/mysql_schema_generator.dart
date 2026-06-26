import '../schema_generator.dart';

/// MySQL / MariaDB DDL generation rules.
///
/// NOTE: This is currently a scaffold. The type mapping below reflects common
/// MySQL types, but AUTO_INCREMENT placement, the `ON UPDATE CURRENT_TIMESTAMP`
/// timestamp mechanism and backtick quoting still need finalising — see TODOs.
class MysqlSchemaGenerator extends SchemaGenerator {
  const MysqlSchemaGenerator();

  @override
  String get name => 'mysql';

  @override
  String mapCoreType(String? typeName, {required bool isEnum}) {
    if (isEnum) return 'VARCHAR(255)';
    switch (typeName) {
      case 'int':
        return 'INT';
      case 'double':
        return 'DOUBLE';
      case 'bool':
        return 'TINYINT(1)';
      case 'String':
        return 'VARCHAR(255)';
      case 'num':
        return 'DECIMAL';
      case 'DateTime':
        return 'DATETIME';
      case 'Uint8List':
        return 'BLOB';
      case 'Duration':
        return 'BIGINT';
      case 'BigInt':
        return 'DECIMAL';
      case 'Uri':
        return 'VARCHAR(255)';
      default:
        return 'VARCHAR(255)';
    }
  }

  @override
  String timestampColumnType() => 'DATETIME';

  // TODO(mysql): AUTO_INCREMENT must follow the type and requires a KEY; revisit
  // placement once the column builder supports it.
  @override
  String autoIncrementClause() => ' AUTO_INCREMENT';

  @override
  bool isAutoPkInline(String sqlType) => sqlType == 'INT';

  @override
  String formatBoolDefault(bool value) => value ? '1' : '0';

  // TODO(mysql): prefer `ON UPDATE CURRENT_TIMESTAMP` on the updated_at column
  // instead of a separate statement.
  @override
  String? updatedAtTimestampDdl(String tableName) => null;

  // TODO(mysql): quote identifiers with backticks.
  @override
  String quoteIdentifier(String name) => name;
}
