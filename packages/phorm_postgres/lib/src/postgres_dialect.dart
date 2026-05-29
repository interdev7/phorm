// PostgreSQL dialect stub — implementation coming soon.
//
// Will implement [SqlDialect] from the phorm core package,
// providing PostgreSQL-specific SQL syntax:
// - Placeholder style: $1, $2, ...
// - Identifier quoting: "table"."column"
// - JSON aggregation: json_agg(), jsonb_build_object()
library;

import 'package:phorm/phorm.dart';

/// Placeholder PostgreSQL dialect.
/// 🚧 Not implemented yet.
class PostgresDialect implements SqlDialect {
  @override
  String compilePlaceholder(int index) => '\$$index';

  @override
  String escapeIdentifier(String identifier) {
    return identifier.split('.').map((p) => '"$p"').join('.');
  }

  @override
  String compileJsonObject(Map<String, String> fields) {
    throw UnimplementedError('PostgresDialect is not yet implemented.');
  }

  @override
  String compileJsonArray(String jsonObject, String fromClause) {
    throw UnimplementedError('PostgresDialect is not yet implemented.');
  }
}
