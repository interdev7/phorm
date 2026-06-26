import '../schema_generator.dart';

/// PostgreSQL DDL generation rules.
///
/// NOTE: This is currently a scaffold. The type mapping below reflects common
/// Postgres types, but timestamp triggers, SERIAL/identity handling and
/// identifier quoting still need to be finalised — see the TODOs.
class PostgresSchemaGenerator extends SchemaGenerator {
  const PostgresSchemaGenerator();

  @override
  String get name => 'postgres';

  @override
  String mapCoreType(String? typeName, {required bool isEnum}) {
    if (isEnum) return 'TEXT';
    switch (typeName) {
      case 'int':
        return 'INTEGER';
      case 'double':
        return 'DOUBLE PRECISION';
      case 'bool':
        return 'BOOLEAN';
      case 'String':
        return 'TEXT';
      case 'num':
        return 'NUMERIC';
      case 'DateTime':
        return 'TIMESTAMP';
      case 'Uint8List':
        return 'BYTEA';
      case 'Duration':
        return 'BIGINT';
      case 'BigInt':
        return 'NUMERIC';
      case 'Uri':
        return 'TEXT';
      default:
        return 'TEXT';
    }
  }

  @override
  String timestampColumnType() => 'TIMESTAMP';

  // TODO(postgres): use SERIAL / GENERATED ALWAYS AS IDENTITY instead of an
  // inline keyword on the PK column.
  @override
  String autoIncrementClause() => '';

  @override
  bool isAutoPkInline(String sqlType) => false;

  @override
  String formatBoolDefault(bool value) => value ? 'TRUE' : 'FALSE';

  // TODO(postgres): emit a trigger function + trigger to maintain updated_at.
  @override
  String? updatedAtTimestampDdl(String tableName) => null;

  // TODO(postgres): quote with double quotes once identifier casing is handled.
  @override
  String quoteIdentifier(String name) => name;
}
