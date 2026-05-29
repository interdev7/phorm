// MySQL dialect stub — implementation coming soon.
//
// Will implement [SqlDialect] from the phorm core package,
// providing MySQL-specific SQL syntax:
// - Placeholder style: ?
// - Identifier quoting: `table`.`column`
// - JSON aggregation: JSON_ARRAYAGG(), JSON_OBJECT()
library;

import 'package:phorm/phorm.dart';

/// Placeholder MySQL dialect.
/// 🚧 Not implemented yet.
class MysqlDialect implements SqlDialect {
  @override
  String compilePlaceholder(int index) => '?';

  @override
  String escapeIdentifier(String identifier) {
    return identifier.split('.').map((p) => '`$p`').join('.');
  }

  @override
  String compileJsonObject(Map<String, String> fields) {
    throw UnimplementedError('MysqlDialect is not yet implemented.');
  }

  @override
  String compileJsonArray(String jsonObject, String fromClause) {
    throw UnimplementedError('MysqlDialect is not yet implemented.');
  }
}
