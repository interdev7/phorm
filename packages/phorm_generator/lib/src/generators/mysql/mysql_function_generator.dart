import '../function_generator.dart';

/// MySQL / MariaDB custom function emission.
///
/// NOTE: scaffold. MySQL exposes user functions through
/// `CREATE FUNCTION name(args) RETURNS ret ... ` (stored functions), which
/// differs fundamentally from SQLite's native callback registration.
class MysqlFunctionGenerator extends FunctionGenerator {
  const MysqlFunctionGenerator();

  @override
  String get name => 'mysql';

  @override
  String generate(List<SqlFuncData> functions) {
    if (functions.isEmpty) return '';
    // TODO(mysql): emit CREATE FUNCTION DDL and any type-safe column helpers
    // once the MySQL runtime supports it.
    return '// TODO(mysql): custom SQL function generation not implemented.\n';
  }
}
