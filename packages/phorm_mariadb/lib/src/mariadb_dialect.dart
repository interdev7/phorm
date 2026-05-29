// MariaDB dialect stub — implementation coming soon.
//
// Will implement [SqlDialect] from the phorm core package.
// MariaDB is largely compatible with MySQL, but has its own
// JSON function implementations and dialect differences.
library;

import 'package:phorm/phorm.dart';

/// Placeholder MariaDB dialect.
/// 🚧 Not implemented yet.
class MariadbDialect implements SqlDialect {
  @override
  String compilePlaceholder(int index) => '?';

  @override
  String escapeIdentifier(String identifier) {
    return identifier.split('.').map((p) => '`$p`').join('.');
  }

  @override
  String compileJsonObject(Map<String, String> fields) {
    throw UnimplementedError('MariadbDialect is not yet implemented.');
  }

  @override
  String compileJsonArray(String jsonObject, String fromClause) {
    throw UnimplementedError('MariadbDialect is not yet implemented.');
  }
}
