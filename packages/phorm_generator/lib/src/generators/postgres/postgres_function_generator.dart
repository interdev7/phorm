import '../function_generator.dart';

/// PostgreSQL custom function emission.
///
/// NOTE: scaffold. Postgres exposes user functions through
/// `CREATE [OR REPLACE] FUNCTION name(args) RETURNS ret LANGUAGE plpgsql ...`,
/// which differs fundamentally from SQLite's native callback registration.
class PostgresFunctionGenerator extends FunctionGenerator {
  const PostgresFunctionGenerator();

  @override
  String get name => 'postgres';

  @override
  String generate(List<SqlFuncData> functions) {
    if (functions.isEmpty) return '';
    // TODO(postgres): emit CREATE FUNCTION DDL (LANGUAGE plpgsql / sql) and any
    // type-safe column helpers once the Postgres runtime supports it.
    return '// TODO(postgres): custom SQL function generation not implemented.\n';
  }
}
